//======================================================================
// tb_sub_sys.sv  -  sub-system (two-clock) testbench
//----------------------------------------------------------------------
// Streams several consecutive N x M * M x N multiplies through sub_sys
// over the bus (sys_clk) while the array runs on an independent sr_clk,
// and checks every C row bit-accurately against the golden model.
//
//   make subsys                 # default clock ratio (sr faster)
//   (override -GSR_HALF=<n> on the build line to try other ratios)
//======================================================================
`timescale 1ns/1ps
import matmul_pkg::*;

module tb_sub_sys;

  localparam int DIN_WIDTH = 8;
  localparam int N         = 4;
  localparam int ACC_W     = 2*DIN_WIDTH;
  localparam int BUS_WIDTH = 2*DIN_WIDTH*N;

  // clock half-periods (overridable from the command line)
  parameter int SYS_HALF = 5;   // sys_clk period = 10 ns
  parameter int SR_HALF  = 3;   // sr_clk  period = 6  ns  (async to sys_clk)

  logic                 rst_n;
  logic                 sys_clk = 0;
  logic                 sr_clk  = 0;
  logic [7:0]           M_minus_one;
  logic [BUS_WIDTH-1:0] din;
  logic                 wr_fifo;
  logic                 rd_fifo;
  logic                 in_fifo_full;
  logic [BUS_WIDTH-1:0] dout;
  logic                 out_fifo_empty;

  sub_sys #(.DIN_WIDTH(DIN_WIDTH), .N(N), .BUS_WIDTH(BUS_WIDTH)) dut (
    .rst_n(rst_n), .sys_clk(sys_clk), .sr_clk(sr_clk),
    .M_minus_one(M_minus_one), .din(din), .wr_fifo(wr_fifo), .rd_fifo(rd_fifo),
    .in_fifo_full(in_fifo_full), .dout(dout), .out_fifo_empty(out_fifo_empty)
  );

  always #(SYS_HALF) sys_clk = ~sys_clk;
  always #(SR_HALF)  sr_clk  = ~sr_clk;

  int total_errors = 0;
  int total_rows   = 0;
  int mat_count    = 0;

  // one matrix multiply: generate, stream in, read out, check
  task automatic run_matrix(input int Mv);
    logic [DIN_WIDTH-1:0] Araw [0:N-1][0:N-1];   // A is N x Mv (cols>=Mv unused)
    logic [DIN_WIDTH-1:0] Braw [0:N-1][0:N-1];   // B is Mv x N (rows>=Mv unused)
    longint Along [MAXN][MAXN];
    longint Blong [MAXN][MAXN];
    longint Cgold [MAXN][MAXN];
    logic [BUS_WIDTH-1:0] samp [0:N-1];          // Mv samples
    logic [BUS_WIDTH-1:0] exp  [0:N-1];          // N expected C rows
    int p, r, bits, merr;

    // ---- generate operands + golden ----
    for (int i = 0; i < MAXN; i++)
      for (int j = 0; j < MAXN; j++) begin Along[i][j]=0; Blong[i][j]=0; end
    for (int i = 0; i < N; i++)
      for (int k = 0; k < Mv; k++) begin
        bits = $urandom_range(0,(1<<DIN_WIDTH)-1);
        Araw[i][k]  = bits[DIN_WIDTH-1:0];
        Along[i][k] = trunc_signed(bits, DIN_WIDTH);
      end
    for (int k = 0; k < Mv; k++)
      for (int j = 0; j < N; j++) begin
        bits = $urandom_range(0,(1<<DIN_WIDTH)-1);
        Braw[k][j]  = bits[DIN_WIDTH-1:0];
        Blong[k][j] = trunc_signed(bits, DIN_WIDTH);
      end
    golden_matmul(N, Mv, ACC_W, Along, Blong, Cgold);

    // ---- pack Mv samples : { A column k , B row k } ----
    for (int k = 0; k < Mv; k++) begin
      samp[k] = '0;
      for (int j = 0; j < N; j++)
        samp[k][j*DIN_WIDTH               +: DIN_WIDTH] = Braw[k][j];      // B row k
      for (int i = 0; i < N; i++)
        samp[k][N*DIN_WIDTH + i*DIN_WIDTH +: DIN_WIDTH] = Araw[i][k];      // A col k
    end
    // ---- pack N expected C rows ----
    for (int i = 0; i < N; i++) begin
      exp[i] = '0;
      for (int j = 0; j < N; j++)
        exp[i][j*ACC_W +: ACC_W] = Cgold[i][j][ACC_W-1:0];
    end

    // ---- set M and stream the samples in on sys_clk ----
    M_minus_one = Mv - 1;
    p = 0;
    while (p < Mv) begin
      @(posedge sys_clk); #1;
      if (!in_fifo_full) begin
        din     = samp[p];
        wr_fifo = 1'b1;
        p++;
      end else begin
        wr_fifo = 1'b0;
      end
    end
    @(posedge sys_clk); #1;
    wr_fifo = 1'b0;

    // ---- read the N result rows out on sys_clk and check ----
    merr = 0;
    r = 0;
    while (r < N) begin
      @(posedge sys_clk); #1;
      if (!out_fifo_empty) begin
        logic [BUS_WIDTH-1:0] got;
        got     = dout;         // FWFT: head word
        rd_fifo = 1'b1;
        @(posedge sys_clk); #1;
        rd_fifo = 1'b0;
        total_rows++;
        if (got !== exp[r]) begin
          merr++;
          $display("  M=%0d mat%0d row%0d MISMATCH got=%h exp=%h", Mv, mat_count, r, got, exp[r]);
        end
        r++;
      end
    end

    total_errors += merr;
    mat_count++;
    if (merr == 0)
      $display("  [mat%0d] PASS  (N=%0d, M=%0d)", mat_count-1, N, Mv);
    repeat (4) @(posedge sys_clk);
  endtask

  initial begin
    rst_n = 0; wr_fifo = 0; rd_fifo = 0; din = 0; M_minus_one = N-1;
    repeat (6) @(posedge sys_clk);
    repeat (6) @(posedge sr_clk);
    rst_n = 1;
    repeat (2) @(posedge sys_clk); #1;

    $display("=== tb_sub_sys : N=%0d DIN_WIDTH=%0d  (sys/2=%0d sr/2=%0d) ===",
             N, DIN_WIDTH, SYS_HALF, SR_HALF);

    // full square (M = N)
    for (int f = 0; f < 6; f++) run_matrix(N);
    // non-square contraction dims M < N
    for (int f = 0; f < 4; f++) run_matrix(2);
    for (int f = 0; f < 3; f++) run_matrix(3);
    for (int f = 0; f < 2; f++) run_matrix(1);

    if (total_errors == 0)
      $display("=== tb_sub_sys PASSED : %0d matrices, %0d C rows ===", mat_count, total_rows);
    else
      $display("=== tb_sub_sys FAILED : %0d row errors over %0d matrices ===",
               total_errors, mat_count);
    $finish;
  end

  initial begin
    #2000000;
    $display("=== tb_sub_sys TIMEOUT ===");
    $finish;
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("tb_sub_sys.vcd");
      $dumpvars(0, tb_sub_sys);
    end
  end

endmodule : tb_sub_sys

//======================================================================
// tb_systolic_array.sv  -  module-level test for systolic_array
//----------------------------------------------------------------------
// Constrained-random signed matrices are streamed through the array
// using the load/swap/compute protocol and every produced C row is
// checked, bit-accurately, against the matmul_pkg golden model.
//
//   make array    # N = 4
//   make array2   # N = 2  (the size worked in the PDF example)
//======================================================================
`timescale 1ns/1ps
import matmul_pkg::*;

module tb_systolic_array;

  // Overridable from the Makefile with -GN=<n>
  parameter int N         = 4;
  localparam int DIN_WIDTH = 8;
  localparam int ACC_W     = 2*DIN_WIDTH;
  localparam int M         = N;          // square operands (see README)

  logic clk = 0;
  logic rst_n;

  // DUT interface
  logic [ACC_W-1:0]     c_din  [0:N-1];
  logic [DIN_WIDTH-1:0] a_din  [0:N-1];
  logic [DIN_WIDTH-1:0] b_din  [0:N-1];
  logic                 in_valid;
  logic                 w_load_en;
  logic                 w_swap;
  logic [ACC_W-1:0]     c_dout [0:N-1];
  logic                 out_valid;

  systolic_array #(.DIN_WIDTH(DIN_WIDTH), .N(N)) dut (
    .rst_n(rst_n), .clk(clk),
    .c_din(c_din), .a_din(a_din), .b_din(b_din),
    .in_valid(in_valid), .w_load_en(w_load_en), .w_swap(w_swap),
    .c_dout(c_dout), .out_valid(out_valid)
  );

  always #5 clk = ~clk;

  int frame_errors;
  int total_errors = 0;
  int total_frames = 0;

  // per-frame storage
  logic [DIN_WIDTH-1:0] Araw [0:N-1][0:N-1];
  logic [DIN_WIDTH-1:0] Braw [0:N-1][0:N-1];
  longint Along [MAXN][MAXN];
  longint Blong [MAXN][MAXN];
  longint Cgold [MAXN][MAXN];
  logic [ACC_W-1:0] Cdut [0:N-1][0:N-1];

  task automatic clr_inputs;
    for (int i = 0; i < N; i++) begin
      c_din[i] = '0; a_din[i] = '0; b_din[i] = '0;
    end
    in_valid = 0; w_load_en = 0; w_swap = 0;
  endtask

  // Generate one random pair of matrices + its golden product
  task automatic gen_matrices(input bit identityB);
    int bits;
    for (int i = 0; i < MAXN; i++)
      for (int j = 0; j < MAXN; j++) begin
        Along[i][j] = 0; Blong[i][j] = 0;
      end
    for (int i = 0; i < N; i++)
      for (int k = 0; k < N; k++) begin
        bits = $urandom_range(0, (1<<DIN_WIDTH)-1);
        Araw[i][k]  = bits[DIN_WIDTH-1:0];
        Along[i][k] = trunc_signed(bits, DIN_WIDTH);
      end
    for (int k = 0; k < N; k++)
      for (int j = 0; j < N; j++) begin
        if (identityB) bits = (k==j) ? 1 : 0;
        else           bits = $urandom_range(0, (1<<DIN_WIDTH)-1);
        Braw[k][j]  = bits[DIN_WIDTH-1:0];
        Blong[k][j] = trunc_signed(bits, DIN_WIDTH);
      end
    golden_matmul(N, M, ACC_W, Along, Blong, Cgold);
  endtask

  // Drive one complete matrix multiply and capture the result rows
  task automatic run_frame(input bit identityB, input string tag);
    int cap;
    gen_matrices(identityB);
    total_frames++;
    frame_errors = 0;

    // ---- 1. load B (one row per cycle) ----
    for (int t = 0; t < N; t++) begin
      for (int c = 0; c < N; c++) b_din[c] = Braw[t][c];
      w_load_en = 1;
      @(posedge clk); #1;
    end
    w_load_en = 0;
    for (int c = 0; c < N; c++) b_din[c] = '0;

    // ---- 2. activate the loaded weights ----
    w_swap = 1;
    @(posedge clk); #1;
    w_swap = 0;

    // ---- 3. stream A and collect C (out_valid lags by 2N-1) ----
    cap = 0;
    for (int cyc = 0; cyc < 3*N + 8 && cap < N; cyc++) begin
      if (cyc < N) begin
        for (int k = 0; k < N; k++) a_din[k] = Araw[cyc][k];
        in_valid = 1;
      end else begin
        for (int k = 0; k < N; k++) a_din[k] = '0;
        in_valid = 0;
      end
      @(posedge clk); #1;
      if (out_valid) begin
        for (int j = 0; j < N; j++) Cdut[cap][j] = c_dout[j];
        cap++;
      end
    end
    in_valid = 0;

    // ---- 4. check ----
    if (cap != N) begin
      frame_errors++;
      $display("  [%s] FAIL: collected %0d/%0d C rows", tag, cap, N);
    end
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) begin
        longint got = trunc_signed(Cdut[i][j], ACC_W);
        if (got !== Cgold[i][j]) begin
          frame_errors++;
          if (frame_errors <= 6)
            $display("  [%s] FAIL C[%0d][%0d]=%0d exp %0d", tag, i, j, got, Cgold[i][j]);
        end
      end

    total_errors += frame_errors;
    if (frame_errors == 0)
      $display("  [%s] PASS (%0dx%0d)", tag, N, N);

    // idle a few cycles so the pipeline fully drains before next frame
    repeat (N+2) @(posedge clk);
    #1;
  endtask

  initial begin
    clr_inputs();
    rst_n = 0;
    repeat (4) @(posedge clk); #1;
    rst_n = 1;
    @(posedge clk); #1;

    $display("=== tb_systolic_array : N=%0d, DIN_WIDTH=%0d ===", N, DIN_WIDTH);

    run_frame(1, "identity");          // C should equal A
    for (int f = 0; f < 20; f++)
      run_frame(0, $sformatf("rand%0d", f));

    if (total_errors == 0)
      $display("=== tb_systolic_array PASSED : %0d frames ===", total_frames);
    else
      $display("=== tb_systolic_array FAILED : %0d errors over %0d frames ===",
               total_errors, total_frames);
    $finish;
  end

  initial begin
    #500000;
    $display("=== tb_systolic_array TIMEOUT ===");
    $finish;
  end

  // optional waveform
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("tb_array.vcd");
      $dumpvars(0, tb_systolic_array);
    end
  end

endmodule : tb_systolic_array

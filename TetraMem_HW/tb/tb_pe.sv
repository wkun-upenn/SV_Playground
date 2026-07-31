//======================================================================
// tb_pe.sv  -  unit testbench for the Processing Element
//----------------------------------------------------------------------
// Self-checking:
//   * directed weight-load / swap / MAC sequence
//   * double-buffer check (load new weight while old one is active)
//   * constrained-random MAC checks against an inline reference
// Run:  make pe
//======================================================================
`timescale 1ns/1ps
module tb_pe;

  localparam int DIN_WIDTH = 8;
  localparam int ACC_W     = 2*DIN_WIDTH;

  logic                        clk = 0;
  logic                        rst_n;
  logic signed [DIN_WIDTH-1:0]   a_in, b_in;
  logic signed [ACC_W-1:0]       c_in;
  logic                          ld_w, swap_w, en;
  logic signed [DIN_WIDTH-1:0]   a_out;
  logic signed [ACC_W-1:0]       c_out;

  int errors = 0;
  int checks = 0;

  pe #(.DIN_WIDTH(DIN_WIDTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .a_in(a_in), .b_in(b_in), .c_in(c_in),
    .ld_w(ld_w), .swap_w(swap_w), .en(en),
    .a_out(a_out), .c_out(c_out)
  );

  always #5 clk = ~clk;

  // load a weight into the inactive buffer and immediately activate it
  task automatic load_weight(input signed [DIN_WIDTH-1:0] w);
    b_in = w; ld_w = 1'b1;
    @(posedge clk); #1;
    ld_w = 1'b0;
    swap_w = 1'b1;
    @(posedge clk); #1;
    swap_w = 1'b0;
  endtask

  // preload the inactive buffer WITHOUT swapping (double-buffer test)
  task automatic preload_weight(input signed [DIN_WIDTH-1:0] w);
    b_in = w; ld_w = 1'b1;
    @(posedge clk); #1;
    ld_w = 1'b0;
  endtask

  task automatic do_swap;
    swap_w = 1'b1;
    @(posedge clk); #1;
    swap_w = 1'b0;
  endtask

  // apply one MAC step and check the registered result
  task automatic mac_check(input signed [DIN_WIDTH-1:0]  a,
                           input signed [ACC_W-1:0]      cin,
                           input signed [DIN_WIDTH-1:0]  w_exp);
    logic signed [ACC_W-1:0] exp;
    a_in = a; c_in = cin; en = 1'b1;
    @(posedge clk); #1;
    en = 1'b0;
    exp = cin + (a * w_exp);
    checks++;
    if (c_out !== exp || a_out !== a) begin
      errors++;
      $display("[%0t] FAIL: a=%0d w=%0d cin=%0d -> c_out=%0d (exp %0d), a_out=%0d (exp %0d)",
               $time, a, w_exp, cin, c_out, exp, a_out, a);
    end
  endtask

  initial begin
    a_in = 0; b_in = 0; c_in = 0; ld_w = 0; swap_w = 0; en = 0; rst_n = 0;
    repeat (3) @(posedge clk); #1;
    rst_n = 1;
    @(posedge clk); #1;

    // ---- directed: w=3 ----
    load_weight(8'sd3);
    mac_check(8'sd5,  16'sd10, 8'sd3);   // 10 + 15 = 25
    mac_check(-8'sd4, 16'sd0,  8'sd3);   // 0  - 12 = -12
    mac_check(8'sd7, -16'sd50, 8'sd3);   // -50 + 21 = -29

    // ---- directed: negative weight ----
    load_weight(-8'sd6);
    mac_check(8'sd9,  16'sd100, -8'sd6); // 100 - 54 = 46
    mac_check(-8'sd8, 16'sd0,   -8'sd6); // 48

    // ---- double buffer: preload w=10 but keep computing with -6 ----
    preload_weight(8'sd10);
    mac_check(8'sd3, 16'sd0, -8'sd6);    // still -6 -> -18
    do_swap;                             // now activate w=10
    mac_check(8'sd3, 16'sd0, 8'sd10);    // 30

    // ---- constrained random ----
    for (int t = 0; t < 200; t++) begin
      logic signed [DIN_WIDTH-1:0] w;
      w = $urandom_range(0, 255);
      load_weight(w);
      for (int s = 0; s < 4; s++) begin
        logic signed [DIN_WIDTH-1:0] a;
        logic signed [ACC_W-1:0]     cin;
        a   = $urandom_range(0, 255);
        cin = $urandom_range(0, 65535);
        mac_check(a, cin, w);
      end
    end

    if (errors == 0)
      $display("=== tb_pe PASSED : %0d checks ===", checks);
    else
      $display("=== tb_pe FAILED : %0d/%0d checks failed ===", errors, checks);
    $finish;
  end

  // safety timeout
  initial begin
    #200000;
    $display("=== tb_pe TIMEOUT ===");
    $finish;
  end

endmodule : tb_pe

// Code your testbench here
// or browse Examples
// ============================================================
// Top module: clock + stimulus + print results
// ============================================================
module top;

  logic clk = 0;
  always #5 clk = ~clk;

  cov_dut dut (.clk(clk));

  // convenience task to drive on a clock edge
  task automatic drive(op_t o, regs_t r, logic [3:0] d);
    @(negedge clk);
    dut.opc  = o;
    dut.regs = r;
    dut.data = d;
  endtask

  initial begin
    dut.cg1.start();
    // init
    dut.opc  = IDLE;
    dut.regs = REG0;
    dut.data = '0;

    // --------------------------------------------------------
    // Stimulus: hit various bins; ensure we hit cross1 at least once
    // cross1 requires: regs==REG1 AND data==2
    // --------------------------------------------------------
    drive(PLAY,  REG0, 4'd0);
    drive(PAUSE, REG2, 4'd3);
    drive(INCR,  REG3, 4'd8);
    dut.cg1.stop();
    drive(DECR,  REG1, 4'd2);   // <-- hits cross1
    drive(STOP,  REG1, 4'd2);   // hit again
    drive(REWIND,REG1, 4'd5);

    // a bit more random stimulus
    repeat (20) begin
      drive(op_t'($urandom_range(0,6)),
            regs_t'($urandom_range(0,3)),
            logic'($urandom_range(0,15)));
    end

    // let last sample occur
    @(posedge clk);

    // --------------------------------------------------------
    // Print bin counts (what the question is about)
    // --------------------------------------------------------
//     $display("==================================================");
//     $display("BIN COUNTS:");
//     $display("  c1 bins      = %0d", dut.cg1.c1.get_num_bins());
//     $display("  c2 bins      = %0d", dut.cg1.c2.get_num_bins());
//     $display("  c3 bins      = %0d", dut.cg1.c3.get_num_bins());
//     $display("  c3xc2 bins   = %0d", dut.cg1.c3xc2.get_num_bins());
//     $display("==================================================");

    // --------------------------------------------------------
    // Print coverage percentages
    // (get_coverage returns percentage 0..100)
    // --------------------------------------------------------
    $display("COVERAGE:");
    $display("  cg overall   = %0.2f%%", dut.cg1.get_coverage());
    $display("  c1           = %0.2f%%", dut.cg1.c1.get_coverage());
    $display("  c2           = %0.2f%%", dut.cg1.c2.get_coverage());
    $display("  c3           = %0.2f%%", dut.cg1.c3.get_coverage());
    $display("  c3xc2        = %0.2f%%", dut.cg1.c3xc2.get_coverage());
    $display("==================================================");

    // If your simulator supports per-bin info, you can also try:
    // $display("c3xc2.cross1 bin hits = %0d", dut.cg1.c3xc2.get_bin_coverage("cross1"));
    // (Not all simulators implement the same bin query APIs.)

    $finish;
  end

endmodule

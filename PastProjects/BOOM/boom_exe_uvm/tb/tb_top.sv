//-----------------------------------------------------------------------------
// tb_top.sv -- testbench top: clock/reset, interface, DUT, UVM run_test().
//
// To target real BOOM RTL instead of the behavioral model, generate the
// Verilog from Chipyard (`make verilog CONFIG=MediumBoomConfig`), replace
// the DUT instance below with the BoomCore/ExecutionUnit hierarchy, and
// bind `boom_exe_if` to the corresponding iss_uops / exe resp signals.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boom_exe_types_pkg::*;
  import boom_exe_pkg::*;

  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;   // 100 MHz
  end

  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  boom_exe_if vif (.clk(clk), .rst_n(rst_n));

  boom_exe_dut dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .iss_valid           (vif.iss_valid),
    .iss_ready           (vif.iss_ready),
    .iss_uopc            (vif.iss_uopc),
    .iss_rob_idx         (vif.iss_rob_idx),
    .iss_pdst            (vif.iss_pdst),
    .iss_rs1_data        (vif.iss_rs1_data),
    .iss_rs2_data        (vif.iss_rs2_data),
    .iss_br_mask         (vif.iss_br_mask),
    .iss_csr_addr        (vif.iss_csr_addr),
    .br_resolve_valid    (vif.br_resolve_valid),
    .br_resolve_mask     (vif.br_resolve_mask),
    .br_mispredict_valid (vif.br_mispredict_valid),
    .br_mispredict_mask  (vif.br_mispredict_mask),
    .wb0_valid           (vif.wb0_valid),
    .wb0_rob_idx         (vif.wb0_rob_idx),
    .wb0_pdst            (vif.wb0_pdst),
    .wb0_data            (vif.wb0_data),
    .wb0_fflags_valid    (vif.wb0_fflags_valid),
    .wb0_fflags          (vif.wb0_fflags),
    .wb1_valid           (vif.wb1_valid),
    .wb1_rob_idx         (vif.wb1_rob_idx),
    .wb1_pdst            (vif.wb1_pdst),
    .wb1_data            (vif.wb1_data),
    .wb1_fflags_valid    (vif.wb1_fflags_valid),
    .wb1_fflags          (vif.wb1_fflags),
    .div_busy            (vif.div_busy),
    .fdiv_busy           (vif.fdiv_busy)
  );

  initial begin
    uvm_config_db#(virtual boom_exe_if)::set(null, "*", "vif", vif);
    run_test();   // +UVM_TESTNAME=<test> selects the test
  end

  // waves
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("boom_exe_tb.vcd");
      $dumpvars(0, tb_top);
    end
  end

endmodule : tb_top

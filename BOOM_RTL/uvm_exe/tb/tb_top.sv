//=============================================================================
// tb_top.sv — top level: clock/reset, interfaces, DUTs, UVM entry point
//-----------------------------------------------------------------------------
// DUT = the three execution units + the integer issue queue + the CSR file of
// a Chipyard MediumBoomV3Config BOOM core, instantiated side by side (in
// silicon the register file / issue logic sits between them and is modelled
// by the UVM agents; the CSR file is wired to alu1's writeback and to the FP
// units exactly as core.scala does).
//=============================================================================
`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boom_exe_defs_pkg::*;
  import boom_exe_pkg::*;

  //---------------------------------------------------------------- clock / reset
  logic clk = 0;
  logic rst = 1;
  always #(CLK_PERIOD / 2) clk = ~clk;
  initial begin
    repeat (10) @(posedge clk);
    #1 rst = 0;
  end

  //---------------------------------------------------------------- interfaces
  boom_exu_if #(EXU_ALU0) alu0_if (.clk(clk), .rst(rst));
  boom_exu_if #(EXU_ALU1) alu1_if (.clk(clk), .rst(rst));
  boom_exu_if #(EXU_FPU)  fpu_if  (.clk(clk), .rst(rst));
  boom_iq_if              iq_if   (.clk(clk), .rst(rst));
  boom_csr_if             csr_if  (.clk(clk), .rst(rst));

  // CSRFile plumbing as in BOOM core.scala: the CSR execution unit's (alu1) writeback feeds the
  // rw port, the FP writebacks' exception flags are OR-ed into fcsr, frm goes back to the FP units
  assign csr_if.pipe_cmd   = alu1_if.iresp_valid ? alu1_if.iresp_uop.ctrl_csr_cmd : CSR_N;
  assign csr_if.pipe_addr  = alu1_if.iresp_uop.csr_addr;
  assign csr_if.pipe_wdata = alu1_if.iresp_data[63:0];
  assign csr_if.fcsr_flags_valid = fpu_if.fresp_fflags_valid |
                                   (alu0_if.ll_fresp_valid & alu0_if.ll_fresp_ready & alu0_if.ll_fresp_fflags_valid);
  assign csr_if.fcsr_flags_bits  = (fpu_if.fresp_fflags_valid ? fpu_if.fresp_fflags : 5'b0) |
                                   ((alu0_if.ll_fresp_valid & alu0_if.ll_fresp_ready & alu0_if.ll_fresp_fflags_valid) ? alu0_if.ll_fresp_fflags : 5'b0);
  assign csr_if.set_fs_dirty = 1'b0;
  assign fpu_if.fcsr_rm_csr  = csr_if.fcsr_rm;
  assign alu0_if.fcsr_rm_csr = csr_if.fcsr_rm;
  assign alu1_if.fcsr_rm_csr = csr_if.fcsr_rm;

  // inputs the drivers never touch on a given unit are tied off here
  initial begin
    alu0_if.req_valid = 0; alu1_if.req_valid = 0; fpu_if.req_valid = 0;
    alu0_if.req_uop = '0;  alu1_if.req_uop = '0;  fpu_if.req_uop = '0;
    alu0_if.rs1_data = '0; alu0_if.rs2_data = '0; alu0_if.rs3_data = '0;
    alu1_if.rs1_data = '0; alu1_if.rs2_data = '0; alu1_if.rs3_data = '0;
    fpu_if.rs1_data = '0;  fpu_if.rs2_data = '0;  fpu_if.rs3_data = '0;
    alu0_if.req_kill = 0;  alu1_if.req_kill = 0;  fpu_if.req_kill = 0;
    alu0_if.flush_bcast = 0; alu1_if.flush_bcast = 0; fpu_if.flush_bcast = 0;
    alu0_if.br_resolve_mask = '0; alu1_if.br_resolve_mask = '0; fpu_if.br_resolve_mask = '0;
    alu0_if.br_mispredict_mask = '0; alu1_if.br_mispredict_mask = '0; fpu_if.br_mispredict_mask = '0;
    alu0_if.ftq_entry_cfi_idx_valid = 0; alu0_if.ftq_entry_cfi_idx_bits = '0; alu0_if.ftq_entry_start_bank = 0;
    alu0_if.ftq_pc = '0; alu0_if.ftq_next_val = 0; alu0_if.ftq_next_pc = '0;
    alu1_if.ftq_entry_cfi_idx_valid = 0; alu1_if.ftq_entry_cfi_idx_bits = '0; alu1_if.ftq_entry_start_bank = 0;
    alu1_if.ftq_pc = '0; alu1_if.ftq_next_val = 0; alu1_if.ftq_next_pc = '0;
    fpu_if.ftq_entry_cfi_idx_valid = 0; fpu_if.ftq_entry_cfi_idx_bits = '0; fpu_if.ftq_entry_start_bank = 0;
    fpu_if.ftq_pc = '0; fpu_if.ftq_next_val = 0; fpu_if.ftq_next_pc = '0;
    alu0_if.fcsr_rm_drv = '0; alu1_if.fcsr_rm_drv = '0; fpu_if.fcsr_rm_drv = '0;
    alu0_if.use_csr_rm = 0; alu1_if.use_csr_rm = 0; fpu_if.use_csr_rm = 0;
    alu0_if.ll_iresp_ready = 1; alu1_if.ll_iresp_ready = 1; fpu_if.ll_iresp_ready = 1;
    alu0_if.ll_fresp_ready = 1; alu1_if.ll_fresp_ready = 1; fpu_if.ll_fresp_ready = 1;
    // ports a unit does not have are left at a known value for the monitors
    alu1_if.ll_iresp_valid = 0; alu1_if.ll_fresp_valid = 0; alu1_if.fresp_valid = 0; alu1_if.fresp_fflags_valid = 0; alu1_if.ll_fresp_fflags_valid = 0;
    alu0_if.ll_iresp_valid = 0; alu0_if.fresp_valid = 0; alu0_if.fresp_fflags_valid = 0;
    fpu_if.iresp_valid = 0; fpu_if.ll_fresp_valid = 0; fpu_if.ll_fresp_fflags_valid = 0; fpu_if.brinfo_valid = 0;
    foreach (fpu_if.bypass_valid[i]) fpu_if.bypass_valid[i] = 0;
    for (int i = 1; i < 3; i++) alu1_if.bypass_valid[i] = 0;
    iq_if.flush_pipeline = 0; iq_if.br_resolve_mask = '0; iq_if.br_mispredict_mask = '0; iq_if.ld_miss = 0;
    foreach (iq_if.dis_valid[i]) begin iq_if.dis_valid[i] = 0; iq_if.dis_uop[i] = '0; end
    foreach (iq_if.wakeup_valid[i]) begin iq_if.wakeup_valid[i] = 0; iq_if.wakeup_pdst[i] = '0; end
    iq_if.spec_ld_wakeup_valid[0] = 0; iq_if.spec_ld_wakeup_pdst[0] = '0;
    iq_if.fu_types[0] = 10'h10B; iq_if.fu_types[1] = 10'h031;
    csr_if.agt_valid = 0; csr_if.agt_addr = '0; csr_if.agt_cmd = CSR_N; csr_if.agt_wdata = '0; csr_if.decode_inst = '0;
    csr_if.irq_debug = 0; csr_if.irq_mtip = 0; csr_if.irq_msip = 0; csr_if.irq_meip = 0; csr_if.irq_seip = 0; csr_if.hartid = 0;
    csr_if.exception = 0; csr_if.retire = '0; csr_if.cause = '0; csr_if.pc = '0; csr_if.tval = '0;
  end

  //---------------------------------------------------------------- DUTs
  `include "boom_exe_dut_inst.svh"

  //---------------------------------------------------------------- UVM
  initial begin
    uvm_config_db#(virtual boom_exu_if #(EXU_ALU0))::set(null, "uvm_test_top", "alu0_vif", alu0_if);
    uvm_config_db#(virtual boom_exu_if #(EXU_ALU1))::set(null, "uvm_test_top", "alu1_vif", alu1_if);
    uvm_config_db#(virtual boom_exu_if #(EXU_FPU))::set(null,  "uvm_test_top", "fpu_vif",  fpu_if);
    uvm_config_db#(virtual boom_iq_if)::set(null, "uvm_test_top", "iq_vif", iq_if);
    uvm_config_db#(virtual boom_csr_if)::set(null, "uvm_test_top", "csr_vif", csr_if);
    run_test();
  end

  //---------------------------------------------------------------- waves / timeout
  initial begin
    if ($test$plusargs("dump")) begin
`ifdef VCS
      $fsdbDumpfile("waves.fsdb"); $fsdbDumpvars(0, tb_top);
`else
      $dumpfile("waves.vcd"); $dumpvars(0, tb_top);
`endif
    end
  end
  initial begin
    automatic int unsigned max_cycles = 2_000_000;
    void'($value$plusargs("max_cycles=%d", max_cycles));
    repeat (max_cycles) @(posedge clk);
    `uvm_fatal("TB", $sformatf("simulation exceeded %0d cycles", max_cycles))
  end
endmodule : tb_top

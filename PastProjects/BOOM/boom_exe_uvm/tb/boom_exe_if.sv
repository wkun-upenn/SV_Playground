//-----------------------------------------------------------------------------
// boom_exe_if.sv
//
// Interface between the UVM testbench and the BOOM execute-pipeline DUT.
// Groups the issue port, branch-resolution broadcast, both write-back
// ports, and the functional-unit readiness vector.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_IF_SV
`define BOOM_EXE_IF_SV

interface boom_exe_if
  import boom_exe_types_pkg::*;
(
  input logic clk,
  input logic rst_n
);

  // ---- Issue port ----
  logic                  iss_valid;
  logic                  iss_ready;
  uopc_e                 iss_uopc;
  logic [ROB_ID_W-1:0]   iss_rob_idx;
  logic [PREG_W-1:0]     iss_pdst;
  logic [XLEN-1:0]       iss_rs1_data;
  logic [XLEN-1:0]       iss_rs2_data;
  logic [BR_MASK_W-1:0]  iss_br_mask;
  logic [CSR_ADDR_W-1:0] iss_csr_addr;

  // ---- Branch Unit broadcast ----
  logic                  br_resolve_valid;
  logic [BR_MASK_W-1:0]  br_resolve_mask;
  logic                  br_mispredict_valid;
  logic [BR_MASK_W-1:0]  br_mispredict_mask;

  // ---- Write-back ports ----
  logic                  wb0_valid;
  logic [ROB_ID_W-1:0]   wb0_rob_idx;
  logic [PREG_W-1:0]     wb0_pdst;
  logic [XLEN-1:0]       wb0_data;
  logic                  wb0_fflags_valid;
  logic [4:0]            wb0_fflags;

  logic                  wb1_valid;
  logic [ROB_ID_W-1:0]   wb1_rob_idx;
  logic [PREG_W-1:0]     wb1_pdst;
  logic [XLEN-1:0]       wb1_data;
  logic                  wb1_fflags_valid;
  logic [4:0]            wb1_fflags;

  // ---- Readiness ----
  logic                  div_busy;
  logic                  fdiv_busy;

  //--------------------------------------------------------------------------
  // Clocking blocks
  //--------------------------------------------------------------------------
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output iss_valid, iss_uopc, iss_rob_idx, iss_pdst,
           iss_rs1_data, iss_rs2_data, iss_br_mask, iss_csr_addr,
           br_resolve_valid, br_resolve_mask,
           br_mispredict_valid, br_mispredict_mask;
    input  iss_ready, div_busy, fdiv_busy,
           wb0_valid, wb0_rob_idx, wb0_data;   // for CSR read-data capture
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input  iss_valid, iss_ready, iss_uopc, iss_rob_idx, iss_pdst,
           iss_rs1_data, iss_rs2_data, iss_br_mask, iss_csr_addr,
           br_resolve_valid, br_resolve_mask,
           br_mispredict_valid, br_mispredict_mask,
           wb0_valid, wb0_rob_idx, wb0_pdst, wb0_data,
           wb0_fflags_valid, wb0_fflags,
           wb1_valid, wb1_rob_idx, wb1_pdst, wb1_data,
           wb1_fflags_valid, wb1_fflags,
           div_busy, fdiv_busy;
  endclocking

  //--------------------------------------------------------------------------
  // Protocol assertions
  //--------------------------------------------------------------------------
  // An un-pipelined unit must apply back-pressure while busy.
  property p_div_backpressure;
    @(posedge clk) disable iff (!rst_n)
      (iss_valid && div_busy &&
       iss_uopc inside {UOPC_DIV, UOPC_DIVU, UOPC_REM, UOPC_REMU})
      |-> !iss_ready;
  endproperty
  a_div_backpressure: assert property (p_div_backpressure)
    else $error("[boom_exe_if] iss_ready asserted for a div op while iDiv busy");

  property p_fdiv_backpressure;
    @(posedge clk) disable iff (!rst_n)
      (iss_valid && fdiv_busy && iss_uopc == UOPC_FDIV_D) |-> !iss_ready;
  endproperty
  a_fdiv_backpressure: assert property (p_fdiv_backpressure)
    else $error("[boom_exe_if] iss_ready asserted for FDIV while FDiv busy");

  // Write-back data must never be X/Z when valid.
  a_wb0_known: assert property (@(posedge clk) disable iff (!rst_n)
      wb0_valid |-> (!$isunknown(wb0_data) && !$isunknown(wb0_pdst)))
    else $error("[boom_exe_if] X/Z on write-back port 0");
  a_wb1_known: assert property (@(posedge clk) disable iff (!rst_n)
      wb1_valid |-> (!$isunknown(wb1_data) && !$isunknown(wb1_pdst)))
    else $error("[boom_exe_if] X/Z on write-back port 1");

endinterface : boom_exe_if

`endif

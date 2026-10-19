//=============================================================================
// boom_csr_if.sv — interface to rocket-chip's CSRFile as instantiated in the
// BOOM core (the register file behind fcsr/fflags/frm, mstatus, mepc, ...).
//-----------------------------------------------------------------------------
// In the core the CSR read/write port is fed by the CSR execution unit
// (ALUExeUnit_2 here): cmd = maskCmd(iresp.valid, uop.ctrl.csr_cmd),
// addr = uop.csr_addr, wdata = iresp.data. The testbench keeps that path
// (pipe_*), and adds a second master for the register-abstraction-layer agent
// (agt_*). The mux gives the RAL agent priority; a sequence that wants CSR
// instructions to flow through the pipeline simply keeps the RAL agent idle.
//
// CSRFile does read-modify-write itself: W: wdata, S: rdata|wdata,
// C: rdata&~wdata (CSR.scala readModifyWriteCSR); rdata is combinational.
//=============================================================================
interface boom_csr_if
  import boom_exe_defs_pkg::*;
 (input logic clk, input logic rst);

  //---------------------------------------------------------------- rw port (what CSRFile sees)
  logic [11:0] rw_addr;
  logic [2:0]  rw_cmd;
  logic [63:0] rw_wdata;
  logic [63:0] rw_rdata;
  //---------------------------------------------------------------- RAL agent master
  logic        agt_valid;
  logic [11:0] agt_addr;
  logic [2:0]  agt_cmd;
  logic [63:0] agt_wdata;
  //---------------------------------------------------------------- pipeline master (alu1 CSR uops, wired in tb_top)
  logic [11:0] pipe_addr;
  logic [2:0]  pipe_cmd;
  logic [63:0] pipe_wdata;
  assign rw_addr  = agt_valid ? agt_addr  : pipe_addr;
  assign rw_cmd   = agt_valid ? agt_cmd   : pipe_cmd;
  assign rw_wdata = agt_valid ? agt_wdata : pipe_wdata;
  //---------------------------------------------------------------- decode port (legality of a CSR instruction)
  logic [31:0] decode_inst;
  logic        decode_fp_illegal, decode_read_illegal, decode_write_illegal, decode_write_flush, decode_system_illegal;
  //---------------------------------------------------------------- fcsr
  logic [2:0]  fcsr_rm;              // output: current frm (drives the FPU's fcsr_rm when the test asks for it)
  logic        fcsr_flags_valid;     // input: FP writeback flags (OR of the units' fflags ports, wired in tb_top)
  logic [4:0]  fcsr_flags_bits;
  logic        set_fs_dirty;
  //---------------------------------------------------------------- core-side inputs (tied off by tb_top / driver)
  logic        irq_debug, irq_mtip, irq_msip, irq_meip, irq_seip;
  logic        hartid;
  logic        exception;
  logic [1:0]  retire;
  logic [63:0] cause;
  logic [39:0] pc, tval;
  //---------------------------------------------------------------- status outputs
  logic        csr_stall, single_step, status_debug, status_mxr, status_sum, interrupt;
  logic [1:0]  status_prv, status_dprv;
  logic [3:0]  ptbr_mode;
  logic [43:0] ptbr_ppn;
  logic [39:0] evec;
  logic [63:0] interrupt_cause;

`ifndef VERILATOR
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output agt_valid, agt_addr, agt_cmd, agt_wdata, decode_inst,
           irq_debug, irq_mtip, irq_msip, irq_meip, irq_seip, hartid, exception, retire, cause, pc, tval;
    input  rw_rdata, decode_fp_illegal, decode_read_illegal, decode_write_illegal, decode_write_flush, decode_system_illegal,
           fcsr_rm, csr_stall, status_prv, interrupt;
  endclocking
  clocking mon_cb @(posedge clk);
    default input #1step;
    input rw_addr, rw_cmd, rw_wdata, rw_rdata, agt_valid, decode_inst,
          decode_fp_illegal, decode_read_illegal, decode_write_illegal, decode_write_flush, decode_system_illegal,
          fcsr_rm, fcsr_flags_valid, fcsr_flags_bits, set_fs_dirty,
          csr_stall, single_step, status_prv, status_dprv, interrupt, interrupt_cause, evec;
  endclocking
`endif

`ifndef BOOM_CSR_IF_NO_SVA
  default clocking sva_cb @(posedge clk); endclocking
  default disable iff (rst);

  // A41: the frm the FPU sees is the frm field of fcsr (read fcsr -> bits [7:5], read frm -> bits [2:0])
  A41_fcsr_rm_is_frm: assert property (
      (rw_cmd == CSR_R && rw_addr == 12'h003) |-> (rw_rdata[7:5] == fcsr_rm))
    else $error("[CSR] fcsr_rm=%0d but fcsr.frm reads %0d", fcsr_rm, rw_rdata[7:5]);
  A41b_frm_csr_is_frm: assert property (
      (rw_cmd == CSR_R && rw_addr == 12'h002) |-> (rw_rdata[2:0] == fcsr_rm))
    else $error("[CSR] fcsr_rm=%0d but frm reads %0d", fcsr_rm, rw_rdata[2:0]);
  // A42: a write to frm is visible on fcsr_rm the next cycle (CSRFile registers are updated at the edge)
  A42_frm_write_takes_effect: assert property (
      (rw_cmd == CSR_W && rw_addr == 12'h002) |=> (fcsr_rm == $past(rw_wdata[2:0])))
    else $error("[CSR] frm write not visible on fcsr_rm");
  // A43: flags accumulate, never clear, on the FP side-effect port (until software writes fflags/fcsr)
  A43_fflags_accumulate: assert property (
      (fcsr_flags_valid && rw_cmd == CSR_N) ##1 (rw_cmd == CSR_R && rw_addr == 12'h001)
      |-> ((rw_rdata[4:0] & $past(fcsr_flags_bits, 1)) == $past(fcsr_flags_bits, 1)))
    else $error("[CSR] flags reported by the FPU did not stick in fflags");
  // A44: no traps / xRET are ever issued here, so the privilege level stays Machine and the core never stalls
  A44_prv_stays_machine: assert property (status_prv == 2'b11) else $error("[CSR] privilege level left M-mode");
  A45_no_csr_stall:      assert property (!csr_stall)         else $error("[CSR] csr_stall asserted (WFI?)");
  // A46: the two masters never collide (agent has priority, pipeline command must be N while the agent drives)
  A46_single_master:     assert property (agt_valid |-> pipe_cmd == CSR_N)
    else $error("[CSR] RAL agent and pipeline CSR uop in the same cycle");

  C_csr_write:        cover property (rw_cmd inside {CSR_W, CSR_S, CSR_C});
  C_csr_set_clear:    cover property (rw_cmd inside {CSR_S, CSR_C});
  C_csr_from_pipe:    cover property (!agt_valid && rw_cmd != CSR_N);
  C_fflags_sideeffect:cover property (fcsr_flags_valid && fcsr_flags_bits != 0);
  C_read_illegal:     cover property (decode_read_illegal);
`endif
endinterface : boom_csr_if

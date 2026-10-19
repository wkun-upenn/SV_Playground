//=============================================================================
// boom_exu_if.sv — interface to one BOOM execution unit
//-----------------------------------------------------------------------------
// One instance per unit (ALUExeUnit_1 / ALUExeUnit_2 / FPUExeUnit). The
// signal set is the union of the three port lists; a unit that lacks a port
// simply leaves the corresponding signal unconnected (outputs) or driven to
// 0 (inputs) by tb_top.
//
// Protocol assertions (A_*) live here so they are checked in every test and
// are reusable at system level with `bind`.
//=============================================================================
interface boom_exu_if
  import boom_exe_defs_pkg::*;
#(parameter exu_id_e UNIT = EXU_ALU0)
 (input logic clk, input logic rst);

  //---------------------------------------------------------------- request
  logic         req_valid;
  uop_t         req_uop;
  logic [64:0]  rs1_data, rs2_data, rs3_data;
  logic         req_kill;                 // per-request kill driven by the unit driver (flush_with_req)
  logic         flush_bcast;              // pipeline flush broadcast by the brupd driver
  logic         kill_any;                 // what the DUT sees on io_req_bits_kill
  assign kill_any = req_kill | flush_bcast;
  //---------------------------------------------------------------- branch update
  logic [11:0]  br_resolve_mask;
  logic [11:0]  br_mispredict_mask;
  //---------------------------------------------------------------- FTQ model (jmp unit)
  logic         ftq_entry_cfi_idx_valid;
  logic [1:0]   ftq_entry_cfi_idx_bits;
  logic         ftq_entry_start_bank;
  logic [39:0]  ftq_pc;
  logic         ftq_next_val;
  logic [39:0]  ftq_next_pc;
  logic [2:0]   fcsr_rm;                 // what the unit sees
  logic [2:0]   fcsr_rm_drv;             // driven by the unit driver (per transaction)
  logic [2:0]   fcsr_rm_csr;             // frm from the CSRFile (wired by tb_top)
  logic         use_csr_rm;              // test selects the source (RAL tests: 1)
  assign fcsr_rm = use_csr_rm ? fcsr_rm_csr : fcsr_rm_drv;
  //---------------------------------------------------------------- responses
  logic [9:0]   fu_types;
  logic         iresp_valid;     rsp_uop_t iresp_uop;    logic [64:0] iresp_data;    logic iresp_predicated;
  logic         ll_iresp_valid, ll_iresp_ready; rsp_uop_t ll_iresp_uop; logic [64:0] ll_iresp_data; logic ll_iresp_predicated;
  logic         fresp_valid;     rsp_uop_t fresp_uop;    logic [64:0] fresp_data;    logic fresp_predicated;
  logic         fresp_fflags_valid;    logic [4:0] fresp_fflags;    logic [5:0] fresp_fflags_rob_idx;
  logic         ll_fresp_valid, ll_fresp_ready; rsp_uop_t ll_fresp_uop; logic [64:0] ll_fresp_data; logic ll_fresp_predicated;
  logic         ll_fresp_fflags_valid; logic [4:0] ll_fresp_fflags; logic [5:0] ll_fresp_fflags_rob_idx;
  logic         bypass_valid[3];
  logic [6:0]   bypass_pdst[3];
  logic [1:0]   bypass_dst_rtype[3];
  logic [64:0]  bypass_data[3];
  //---------------------------------------------------------------- branch resolution
  logic         brinfo_valid, brinfo_mispredict, brinfo_taken;
  logic [2:0]   brinfo_cfi_type;
  logic [1:0]   brinfo_pc_sel;
  logic [39:0]  brinfo_jalr_target;
  logic [20:0]  brinfo_target_offset;
  logic         brinfo_uop_is_rvc, brinfo_uop_edge_inst;
  logic [11:0]  brinfo_uop_br_mask;
  logic [3:0]   brinfo_uop_br_tag;
  logic [4:0]   brinfo_uop_ftq_idx;
  logic [5:0]   brinfo_uop_pc_lob, brinfo_uop_rob_idx;
  logic [3:0]   brinfo_uop_ldq_idx, brinfo_uop_stq_idx;

  //---------------------------------------------------------------- clocking
`ifndef VERILATOR   // clocking blocks / modports are only used by the UVM agents (Verilator runs the UVM-free smoke test)
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output req_valid, req_uop, rs1_data, rs2_data, rs3_data, req_kill, flush_bcast,
           br_resolve_mask, br_mispredict_mask,
           ftq_entry_cfi_idx_valid, ftq_entry_cfi_idx_bits, ftq_entry_start_bank, ftq_pc, ftq_next_val, ftq_next_pc,
           fcsr_rm_drv, ll_iresp_ready, ll_fresp_ready;
    input  fu_types;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input req_valid, req_uop, rs1_data, rs2_data, rs3_data, req_kill, flush_bcast, kill_any,
          br_resolve_mask, br_mispredict_mask, fcsr_rm,
          ftq_entry_cfi_idx_valid, ftq_entry_cfi_idx_bits, ftq_entry_start_bank, ftq_pc, ftq_next_val, ftq_next_pc,
          fu_types,
          iresp_valid, iresp_uop, iresp_data, iresp_predicated,
          ll_iresp_valid, ll_iresp_ready, ll_iresp_uop, ll_iresp_data, ll_iresp_predicated,
          fresp_valid, fresp_uop, fresp_data, fresp_predicated, fresp_fflags_valid, fresp_fflags, fresp_fflags_rob_idx,
          ll_fresp_valid, ll_fresp_ready, ll_fresp_uop, ll_fresp_data, ll_fresp_predicated, ll_fresp_fflags_valid, ll_fresp_fflags, ll_fresp_fflags_rob_idx,
          bypass_valid, bypass_pdst, bypass_dst_rtype, bypass_data,
          brinfo_valid, brinfo_mispredict, brinfo_taken, brinfo_cfi_type, brinfo_pc_sel, brinfo_jalr_target, brinfo_target_offset,
          brinfo_uop_is_rvc, brinfo_uop_edge_inst, brinfo_uop_br_mask, brinfo_uop_br_tag, brinfo_uop_ftq_idx,
          brinfo_uop_pc_lob, brinfo_uop_rob_idx, brinfo_uop_ldq_idx, brinfo_uop_stq_idx;
  endclocking

  modport drv (clocking drv_cb, input clk, rst);
  modport mon (clocking mon_cb, input clk, rst);
`endif

  //===========================================================================
  // Assertions — every A_* is also a coverage point (cover property below)
  //===========================================================================
`ifndef BOOM_EXU_IF_NO_SVA
  default clocking sva_cb @(posedge clk); endclocking
  default disable iff (rst);

  localparam bit HAS_IRESP    = (UNIT != EXU_FPU);
  localparam bit HAS_LL_IRESP = (UNIT == EXU_FPU);
  localparam bit HAS_FRESP    = (UNIT == EXU_FPU);
  localparam bit HAS_LL_FRESP = (UNIT == EXU_ALU0);
  localparam int ALU_STAGES   = (UNIT == EXU_ALU0) ? ALU0_STAGES : ALU1_STAGES;

  // helper: uop currently being requested is killed by this cycle's mispredict mask
  let req_killed_by_br = ((req_uop.br_mask & br_mispredict_mask) != 0);

  // ---- A01: request fu_code is one-hot and supported by this unit -----------------------------
  A01_req_fu_onehot: assert property (req_valid |-> $onehot(req_uop.fu_code))
    else $error("[%s] fu_code %b is not one-hot", UNIT.name(), req_uop.fu_code);
  A02_req_fu_supported: assert property (req_valid |-> ((req_uop.fu_code & fu_types) != 0))
    else $error("[%s] fu_code %b not accepted (fu_types=%b) — issue queue would never send this", UNIT.name(), req_uop.fu_code, fu_types);

  // ---- A03: mispredict mask must be a subset of resolve mask (BrUpdateMasks invariant) ---------
  A03_mispredict_subset_of_resolve: assert property ((br_mispredict_mask & ~br_resolve_mask) == 0)
    else $error("[%s] mispredict_mask %b not subset of resolve_mask %b", UNIT.name(), br_mispredict_mask, br_resolve_mask);
  A04_mispredict_at_most_one: assert property ($onehot0(br_mispredict_mask))
    else $error("[%s] more than one branch mispredicted in one cycle", UNIT.name());

  // ---- A05..A08: integer response port ------------------------------------------------------
  generate if (HAS_IRESP) begin : g_iresp_sva
    A05_iresp_int_bit64_zero: assert property (iresp_valid && (iresp_uop.dst_rtype == RT_FIX) |-> iresp_data[64] == 1'b0)
      else $error("[%s] integer iresp has bit 64 set", UNIT.name());
    // ALU latency: FU_ALU request (not killed) -> iresp exactly ALU_STAGES cycles later,
    // unless a flush / mispredict of one of the uop's branch-mask bits intervenes.
    property p_alu_latency;
      logic [11:0] m; logic [5:0] r;
      (req_valid && req_uop.fu_code == FU_ALU && !kill_any && !req_killed_by_br, m = req_uop.br_mask, r = req_uop.rob_idx)
      |-> (##ALU_STAGES (iresp_valid && iresp_uop.rob_idx == r)) or
          (##[1:ALU_STAGES] (kill_any || ((br_mispredict_mask & m) != 0)));
    endproperty
    A06_alu_latency: assert property (p_alu_latency)
      else $error("[%s] ALU result did not appear after %0d cycles", UNIT.name(), ALU_STAGES);
    // bypass port 0 is combinational with the ALU request
    A07_bypass0_follows_req: assert property (
        (req_valid && req_uop.fu_code == FU_ALU) |-> (bypass_valid[0] && bypass_pdst[0] == req_uop.pdst))
      else $error("[%s] bypass[0] not valid with ALU request", UNIT.name());
    A08_bypass0_only_with_req: assert property (bypass_valid[0] |-> req_valid)
      else $error("[%s] bypass[0] valid without a request", UNIT.name());
    // a response whose branch mask overlaps this cycle's mispredict is a squashed uop being written back
    A28_no_iresp_of_mispredicted: assert property (iresp_valid |-> ((iresp_uop.br_mask & br_mispredict_mask) == 0))
      else $error("[%s] iresp of a uop killed by this cycle's mispredict", UNIT.name());
  end endgenerate

  generate if (UNIT == EXU_ALU0) begin : g_alu0_sva
    // 3-stage ALU: bypass[1]/[2] are the delayed copies of bypass[0]
    A09_bypass_pipeline1: assert property (bypass_valid[0] |=> bypass_valid[1] && bypass_pdst[1] == $past(bypass_pdst[0]) && bypass_data[1] == $past(bypass_data[0]))
      else $error("[ALU0] bypass stage 1 does not follow stage 0");
    A10_bypass_pipeline2: assert property (bypass_valid[1] |=> bypass_valid[2] && bypass_data[2] == $past(bypass_data[1]))
      else $error("[ALU0] bypass stage 2 does not follow stage 1");
    // iMul: 3-cycle pipelined latency
    property p_imul_latency;
      logic [11:0] m; logic [5:0] r;
      (req_valid && req_uop.fu_code == FU_MUL && !kill_any && !req_killed_by_br, m = req_uop.br_mask, r = req_uop.rob_idx)
      |-> (##IMUL_LAT (iresp_valid && iresp_uop.rob_idx == r)) or
          (##[1:IMUL_LAT] (kill_any || ((br_mispredict_mask & m) != 0)));
    endproperty
    A11_imul_latency: assert property (p_imul_latency)
      else $error("[ALU0] iMul result did not appear after %0d cycles", IMUL_LAT);
    // FU_I2F is withdrawn from fu_types whenever the IntToFP output queue is non-empty
    A12_i2f_busy_while_queued: assert property (ll_fresp_valid |-> !fu_types[8])
      else $error("[ALU0] FU_I2F advertised while the I2F queue holds a result");
    // JMP unit: brinfo only for branches / jalr, and JAL never mispredicts
    A13_brinfo_only_for_br_jalr: assert property (brinfo_valid |-> (req_valid && (req_uop.is_br || req_uop.is_jalr)))
      else $error("[ALU0] brinfo.valid without a branch/jalr request");
    A14_jal_never_mispredicts: assert property ((req_valid && req_uop.is_jal) |-> !brinfo_mispredict)
      else $error("[ALU0] JAL reported as mispredict");
    A31_static_fu_types_alu0: assert property ((fu_types & (FU_ALU | FU_JMP | FU_MUL)) == (FU_ALU | FU_JMP | FU_MUL))
      else $error("[ALU0] static capabilities ALU/JMP/MUL disappeared from fu_types");
  end endgenerate

  generate if (UNIT == EXU_ALU1) begin : g_alu1_sva
    // divider: FU_DIV disappears from fu_types while busy, and reappears with the response
    A15_div_busy_after_req: assert property (
        (req_valid && req_uop.fu_code == FU_DIV && !kill_any && !req_killed_by_br) |=> !fu_types[4])
      else $error("[ALU1] FU_DIV still advertised while divider busy");
    A16_div_resp_restores_fu: assert property (
        (iresp_valid && iresp_uop.uopc inside {uopDIV, uopDIVU, uopREM, uopREMU, uopDIVW, uopDIVUW, uopREMW, uopREMUW})
        |=> (fu_types[4] || (req_valid && req_uop.fu_code == FU_DIV)))
      else $error("[ALU1] FU_DIV not re-advertised after a divide response");
    A17_csr_latency: assert property (
        (req_valid && req_uop.fu_code == FU_CSR && !kill_any && !req_killed_by_br)
        |=> (kill_any || (iresp_valid && iresp_uop.ctrl_csr_cmd == $past(req_uop.ctrl_csr_cmd) && iresp_uop.csr_addr == $past(req_uop.imm_packed[19:8]))))
      else $error("[ALU1] CSR uop did not produce csr_cmd/csr_addr next cycle");
    A13b_brinfo_only_for_br: assert property (brinfo_valid |-> (req_valid && req_uop.is_br))
      else $error("[ALU1] brinfo.valid without a branch request");
    A31b_static_fu_types_alu1: assert property ((fu_types & (FU_ALU | FU_CSR)) == (FU_ALU | FU_CSR))
      else $error("[ALU1] static capabilities ALU/CSR disappeared from fu_types");
  end endgenerate

  generate if (UNIT == EXU_FPU) begin : g_fpu_sva
    // FMA pipeline latency (dfmaLatency == 4)
    property p_fpu_latency;
      logic [11:0] m; logic [5:0] r;
      (req_valid && req_uop.fu_code == FU_FPU && !kill_any && !req_killed_by_br, m = req_uop.br_mask, r = req_uop.rob_idx)
      |-> (##FPU_LAT (fresp_valid && fresp_uop.rob_idx == r)) or
          (##[1:FPU_LAT] (kill_any || ((br_mispredict_mask & m) != 0)));
    endproperty
    A18_fpu_latency: assert property (p_fpu_latency)
      else $error("[FPU] FMA result did not appear after %0d cycles", FPU_LAT);
    // F2I results come out of ll_iresp, never fresp
    A19_f2i_not_on_fresp: assert property (fresp_valid |-> fresp_uop.dst_rtype == RT_FLT)
      else $error("[FPU] fresp carries a non-FP destination");
    A20_ll_iresp_is_int: assert property (ll_iresp_valid |-> (ll_iresp_uop.dst_rtype == RT_FIX && ll_iresp_data[64] == 1'b0))
      else $error("[FPU] ll_iresp carries a non-integer destination");
    // every FP-register response carries fflags. (F2I ops report their flags on fresp.fflags
    // while their data leaves on ll_iresp — that is how BOOM's core collects them, so
    // fflags_valid without fresp_valid is legal.)
    A21_fresp_has_fflags: assert property (fresp_valid |-> fresp_fflags_valid)
      else $error("[FPU] fresp without fflags");
    A22_fflags_rob_matches: assert property ((fresp_valid && fresp_fflags_valid) |-> fresp_fflags_rob_idx == fresp_uop.rob_idx)
      else $error("[FPU] fflags rob_idx mismatch");
    // FDiv/FSqrt: FU_FDV disappears while the unit is busy
    A23_fdiv_busy_after_req: assert property (
        (req_valid && req_uop.fu_code == FU_FDV && !kill_any && !req_killed_by_br) |=> !fu_types[7])
      else $error("[FPU] FU_FDV still advertised while fdiv busy");
    // ll_iresp is a Decoupled port: valid must hold and data must be stable until ready
    A24_ll_iresp_stable: assert property (
        (ll_iresp_valid && !ll_iresp_ready && !kill_any && ((ll_iresp_uop.br_mask & br_mispredict_mask) == 0))
        |=> (ll_iresp_valid && $stable(ll_iresp_data) && $stable(ll_iresp_uop.rob_idx)))
      else $error("[FPU] ll_iresp changed while stalled");
    A29_no_fresp_of_mispredicted: assert property (fresp_valid |-> ((fresp_uop.br_mask & br_mispredict_mask) == 0))
      else $error("[FPU] fresp of a uop killed by this cycle's mispredict");
    A31c_static_fu_types_fpu: assert property ((fu_types & FU_FPU) == FU_FPU)
      else $error("[FPU] static capability FPU disappeared from fu_types");
  end endgenerate

  generate if (HAS_LL_FRESP) begin : g_ll_fresp_sva
    A25_ll_fresp_stable: assert property (
        (ll_fresp_valid && !ll_fresp_ready && !kill_any && ((ll_fresp_uop.br_mask & br_mispredict_mask) == 0))
        |=> (ll_fresp_valid && $stable(ll_fresp_data) && $stable(ll_fresp_uop.rob_idx)))
      else $error("[ALU0] ll_fresp changed while stalled");
    A26_ll_fresp_is_fp: assert property (ll_fresp_valid |-> ll_fresp_uop.dst_rtype == RT_FLT)
      else $error("[ALU0] ll_fresp carries a non-FP destination");
    A27_ll_fresp_fflags_rob: assert property (ll_fresp_fflags_valid |-> ll_fresp_fflags_rob_idx == ll_fresp_uop.rob_idx)
      else $error("[ALU0] ll_fresp fflags rob_idx mismatch");
  end endgenerate

  // ---- A30: nothing valid while in reset ----------------------------------------------------
  A30_quiet_in_reset: assert property (@(posedge clk) disable iff (1'b0)
      rst |-> !(iresp_valid || fresp_valid || ll_iresp_valid || ll_fresp_valid))
    else $error("[%s] response valid during reset", UNIT.name());

  //---------------------------------------------------------------------------
  // cover properties (assertion coverage)
  //---------------------------------------------------------------------------
  C_req_killed_same_cycle: cover property (req_valid && req_killed_by_br);
  C_req_with_flush:        cover property (req_valid && kill_any);
  C_fu_types_shrinks:      cover property ($fell(fu_types[4]) || $fell(fu_types[7]) || $fell(fu_types[8]));
  generate if (HAS_LL_IRESP) begin : g_cov_ll_iresp
    C_ll_iresp_backpressure: cover property (ll_iresp_valid && !ll_iresp_ready);
  end endgenerate
  generate if (HAS_LL_FRESP) begin : g_cov_ll_fresp
    C_ll_fresp_backpressure: cover property (ll_fresp_valid && !ll_fresp_ready);
  end endgenerate
`endif

endinterface : boom_exu_if

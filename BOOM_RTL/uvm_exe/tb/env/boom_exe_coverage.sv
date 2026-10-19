//=============================================================================
// boom_exe_coverage.sv — functional coverage for the execute pipeline
//-----------------------------------------------------------------------------
// 22 covergroups (cg01..cg22). All sampling is driven by monitor items, so the
// same collector works in a passive/system-level environment.
//=============================================================================
`uvm_analysis_imp_decl(_cov_req)
`uvm_analysis_imp_decl(_cov_rsp)
`uvm_analysis_imp_decl(_cov_brinfo)
`uvm_analysis_imp_decl(_cov_brupd)

class boom_exe_coverage extends uvm_component;
  `uvm_component_utils(boom_exe_coverage)

  uvm_analysis_imp_cov_req    #(boom_exe_txn,    boom_exe_coverage) req_imp;
  uvm_analysis_imp_cov_rsp    #(boom_exe_rsp,    boom_exe_coverage) rsp_imp;
  uvm_analysis_imp_cov_brinfo #(boom_brinfo_rsp, boom_exe_coverage) brinfo_imp;
  uvm_analysis_imp_cov_brupd  #(boom_brupd_txn,  boom_exe_coverage) brupd_imp;

  boom_exe_cfg cfg;

  //------------------------------------------------------------ sampled values
  boom_exe_txn   t;              // current request
  exu_id_e       unit;
  bit [5:0]      shamt;
  int            rs1_cls, rs2_cls;
  fp_class_e     f1, f2, f3;
  bit            single;
  int            op_group;       // 0 alu 1 shift 2 cmp 3 branch 4 jump 5 mul 6 div 7 csr 8 fma 9 fdiv 10 fmisc 11 f2i 12 i2f
  int            div_cls, dvd_cls;
  int            jalr_reason;
  int            kill_kind;      // 0 none 1 same-cycle mispredict 2 in-flight mispredict 3 flush
  int            alu_gap;        // cycles since the previous ALU request on the same unit (bypass distance)
  int            last_alu_cycle[3] = '{-100, -100, -100};
  bit            div_inflight, fdiv_inflight, i2f_queued, f2i_queued;
  bit            div_collision;
  boom_exe_rsp   r;
  bit [4:0]      fl;
  bit            cvt_sat;
  boom_brinfo_rsp br;
  boom_brupd_txn  bu;
  int            inflight_cnt[3];
  bit [11:0]     live_masks[3];  // OR of br_masks in flight per unit
  bit [5:0]      rob_inflight[3][$];
  bit            kill_hit_inflight;

  //------------------------------------------------------------ covergroups
  // 1. integer op × width
  covergroup cg01_int_op;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group inside {0,1,2,5,6,7}) {
      bins ops[] = {[OP_ADD:OP_MOV], [OP_MUL:OP_CSRRCI]};
    }
    cp_unit: coverpoint unit;
    cp_dw: coverpoint t.ctrl.fcn_dw;
    x_op_unit: cross cp_op, cp_unit;
  endgroup

  // 2. ALU operand corner classes
  covergroup cg02_alu_operands;
    option.per_instance = 1;
    cp_rs1: coverpoint rs1_cls iff (op_group inside {0,1,2}) { bins zero={0}; bins one={1}; bins neg1={2}; bins max_pos={3}; bins min_neg={4}; bins pos={5}; bins neg={6}; bins bit31_set={7}; }
    cp_rs2: coverpoint rs2_cls iff (op_group inside {0,1,2}) { bins zero={0}; bins one={1}; bins neg1={2}; bins max_pos={3}; bins min_neg={4}; bins pos={5}; bins neg={6}; bins bit31_set={7}; }
    cp_grp: coverpoint op_group iff (op_group inside {0,1,2}) { bins arith_logic={0}; bins shift={1}; bins cmp={2}; }
    x_ops: cross cp_rs1, cp_rs2, cp_grp;
  endgroup

  // 3. shift amounts
  covergroup cg03_shift;
    option.per_instance = 1;
    cp_sh: coverpoint shamt iff (op_group == 1) { bins zero={0}; bins one={1}; bins mid[]={[2:30]}; bins b31={31}; bins b32={32}; bins high[]={[33:62]}; bins b63={63}; }
    cp_op: coverpoint t.op iff (op_group == 1) { bins sh[] = {OP_SLL,OP_SRL,OP_SRA,OP_SLLI,OP_SRLI,OP_SRAI,OP_SLLW,OP_SRLW,OP_SRAW,OP_SLLIW,OP_SRLIW,OP_SRAIW}; }
    x_sh_op: cross cp_sh, cp_op;
  endgroup

  // 4. multiply sign / magnitude combinations
  covergroup cg04_mul;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group == 5) { bins m[] = {OP_MUL,OP_MULH,OP_MULHU,OP_MULHSU,OP_MULW}; }
    cp_s1: coverpoint t.rs1[63] iff (op_group == 5);
    cp_s2: coverpoint t.rs2[63] iff (op_group == 5);
    cp_mag: coverpoint rs1_cls iff (op_group == 5) { bins zero={0}; bins one={1}; bins neg1={2}; bins max_pos={3}; bins min_neg={4}; bins other={5,6,7}; }
    x_mul: cross cp_op, cp_s1, cp_s2, cp_mag;
  endgroup

  // 5. divide corner cases (div by zero, overflow, signs, W forms)
  covergroup cg05_div;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group == 6) { bins d[] = {[OP_DIV:OP_REMUW]}; }
    cp_divisor: coverpoint div_cls iff (op_group == 6) { bins zero={0}; bins one={1}; bins neg1={2}; bins pos={3}; bins neg={4}; }
    cp_dividend: coverpoint dvd_cls iff (op_group == 6) { bins zero={0}; bins min_neg={1}; bins pos={2}; bins neg={3}; }
    x_div: cross cp_op, cp_divisor, cp_dividend;
  endgroup

  // 6. branches: type × actual × predicted (mispredict = actual != predicted)
  covergroup cg06_branch;
    option.per_instance = 1;
    cp_type: coverpoint t.ctrl.br_type iff (op_group == 3) { bins b[] = {BR_EQ,BR_NE,BR_LT,BR_GE,BR_LTU,BR_GEU}; }
    cp_taken: coverpoint t.exp_taken iff (op_group == 3);
    cp_pred: coverpoint t.pred_taken iff (op_group == 3);
    cp_rel: coverpoint rs1_cls iff (op_group == 3) { bins eq={8}; bins lt={9}; bins gt={10}; }
    x_br: cross cp_type, cp_taken, cp_pred;
    x_rel: cross cp_type, cp_rel;
  endgroup

  // 7. jumps: JAL / JALR / AUIPC, compressed link, JALR mispredict reasons
  covergroup cg07_jump;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group == 4) { bins j[] = {OP_JAL, OP_JALR, OP_AUIPC}; }
    cp_rvc: coverpoint t.is_rvc iff (op_group == 4);
    cp_edge: coverpoint t.edge_inst iff (op_group == 4 || t.ctrl.is_br) { bins in_block={0}; bins straddles_fetch_block={1}; }
    cp_reason: coverpoint jalr_reason iff (t.op == OP_JALR) { bins correct={0}; bins no_next={1}; bins target_mismatch={2}; bins cfi_idx_mismatch={3}; bins cfi_invalid={4}; }
    x_op_rvc: cross cp_op, cp_rvc;
    x_op_edge: cross cp_op, cp_edge;
  endgroup

  // 8. CSR data path
  covergroup cg08_csr;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group == 7) { bins c[] = {[OP_CSRRW:OP_CSRRCI]}; }
    cp_addr: coverpoint t.csr_addr iff (op_group == 7) { bins fflags={12'h001}; bins frm={12'h002}; bins fcsr={12'h003}; bins mstatus={12'h300}; bins mscratch={12'h340}; bins mepc={12'h341}; bins cycle={12'hC00}; bins other=default; }
    cp_zimm0: coverpoint (t.zimm == 0) iff (t.op inside {OP_CSRRWI,OP_CSRRSI,OP_CSRRCI});
    x_csr: cross cp_op, cp_addr;
  endgroup

  // 9. every FP op
  covergroup cg09_fp_op;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group >= 8) { bins f[] = {[OP_FADD_S:OP_FCVT_D_LU]}; }
    cp_single: coverpoint single iff (op_group >= 8);
  endgroup

  // 10/11/12. IEEE operand classes per source × op group
  covergroup cg10_fp_rs1_class;
    option.per_instance = 1;
    cp_cls: coverpoint f1 iff (op_group inside {8,9,10,11});
    cp_grp: coverpoint op_group iff (op_group inside {8,9,10,11}) { bins fma={8}; bins fdiv={9}; bins fmisc={10}; bins f2i={11}; }
    cp_op: coverpoint t.op iff (op_group inside {8,9,10,11}) { bins f[] = {[OP_FADD_S:OP_FCVT_LU_D]}; }
    x_cls_grp: cross cp_cls, cp_grp;
    x_cls_op:  cross cp_cls, cp_op;
  endgroup
  covergroup cg11_fp_rs2_class;
    option.per_instance = 1;
    cp_cls: coverpoint f2 iff (op_group inside {8,9,10,11} && t.ctrl.lrs2_rtype == RT_FLT);
    cp_grp: coverpoint op_group iff (op_group inside {8,9,10,11} && t.ctrl.lrs2_rtype == RT_FLT) { bins fma={8}; bins fdiv={9}; bins fmisc={10}; bins f2i={11}; }
    x_cls_grp: cross cp_cls, cp_grp;
    x_rs1_rs2: cross f1, f2 iff (op_group == 8);
  endgroup
  covergroup cg12_fp_rs3_class;
    option.per_instance = 1;
    cp_cls: coverpoint f3 iff (t.ctrl.frs3_en);
    cp_op: coverpoint t.op iff (t.ctrl.frs3_en) { bins fma[] = {OP_FMADD_S,OP_FMSUB_S,OP_FNMADD_S,OP_FNMSUB_S,OP_FMADD_D,OP_FMSUB_D,OP_FNMADD_D,OP_FNMSUB_D}; }
    x_cls_op: cross cp_cls, cp_op;
  endgroup

  // 13. rounding modes (static and dynamic)
  covergroup cg13_fp_rm;
    option.per_instance = 1;
    cp_rm: coverpoint t.eff_rm() iff (uses_rm(t.op)) { bins rne={0}; bins rtz={1}; bins rdn={2}; bins rup={3}; bins rmm={4}; }
    cp_dyn: coverpoint (t.rm == RM_DYN) iff (uses_rm(t.op));
    cp_grp: coverpoint op_group iff (uses_rm(t.op)) { bins fma={8}; bins fdiv={9}; bins fmisc={10}; bins f2i={11}; bins i2f={12}; }
    x_rm_grp: cross cp_rm, cp_grp;
    x_rm_dyn: cross cp_rm, cp_dyn;
  endgroup

  // 14. exception flags raised, per op group (sampled on responses)
  covergroup cg14_fp_flags;
    option.per_instance = 1;
    cp_nv: coverpoint fl[FF_NV]; cp_dz: coverpoint fl[FF_DZ]; cp_of: coverpoint fl[FF_OF]; cp_uf: coverpoint fl[FF_UF]; cp_nx: coverpoint fl[FF_NX];
    cp_grp: coverpoint op_group { bins fma={8}; bins fdiv={9}; bins fmisc={10}; bins f2i={11}; bins i2f={12}; }
    x_nv: cross cp_nv, cp_grp; x_dz: cross cp_dz, cp_grp; x_of: cross cp_of, cp_grp; x_uf: cross cp_uf, cp_grp; x_nx: cross cp_nx, cp_grp;
  endgroup

  // 15. conversions: type × saturation/NaN × sign
  covergroup cg15_fp_cvt;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (op_group inside {11,12} && t.op != OP_FMV_X_W && t.op != OP_FMV_X_D && t.op != OP_FMV_W_X && t.op != OP_FMV_D_X
                                 && !(t.op inside {OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D,OP_FCLASS_S,OP_FCLASS_D})) {
      bins cvt[] = {[OP_FCVT_W_S:OP_FCVT_LU_D], [OP_FCVT_S_W:OP_FCVT_D_LU]}; }
    cp_sat: coverpoint cvt_sat iff (op_group == 11);
    cp_sign: coverpoint t.rs1[63] iff (op_group inside {11,12});
    cp_in_cls: coverpoint f1 iff (op_group == 11) { bins nan = {FPC_QNAN, FPC_SNAN}; bins inf = {FPC_POS_INF, FPC_NEG_INF}; bins zero = {FPC_POS_ZERO, FPC_NEG_ZERO}; bins subn = {FPC_POS_SUBN, FPC_NEG_SUBN}; bins norm = {FPC_POS_NORM, FPC_NEG_NORM}; }
    x_cvt_sat: cross cp_op, cp_sat;
    x_cvt_cls: cross cp_op, cp_in_cls;
  endgroup

  // 16. compares / classify: result × NaN presence
  covergroup cg16_fp_cmp_class;
    option.per_instance = 1;
    cp_op: coverpoint t.op iff (t.op inside {OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D}) { bins c[] = {OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D}; }
    cp_res: coverpoint t.exp_data[0] iff (t.op inside {OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D});
    cp_nan: coverpoint (f1 inside {FPC_QNAN,FPC_SNAN} || f2 inside {FPC_QNAN,FPC_SNAN}) iff (t.op inside {OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D});
    cp_class_bit: coverpoint t.exp_data[9:0] iff (t.op inside {OP_FCLASS_S, OP_FCLASS_D}) { bins b[] = {10'h001,10'h002,10'h004,10'h008,10'h010,10'h020,10'h040,10'h080,10'h100,10'h200}; }
    x_cmp: cross cp_op, cp_res, cp_nan;
  endgroup

  // 17. NaN-boxing: single-precision op fed a non-boxed operand
  covergroup cg17_fp_nanbox;
    option.per_instance = 1;
    cp_unboxed1: coverpoint (f1 == FPC_UNBOXED) iff (single && t.ctrl.lrs1_rtype == RT_FLT);
    cp_unboxed2: coverpoint (f2 == FPC_UNBOXED) iff (single && t.ctrl.lrs2_rtype == RT_FLT);
    cp_grp: coverpoint op_group iff (single) { bins fma={8}; bins fdiv={9}; bins fmisc={10}; bins f2i={11}; }
    x_unboxed: cross cp_unboxed1, cp_grp;
  endgroup

  // 18. squash scenarios: how / where a uop got killed
  covergroup cg18_kill;
    option.per_instance = 1;
    cp_kind: coverpoint kill_kind { bins same_cycle_mispredict={1}; bins inflight_mispredict={2}; bins flush={3}; }
    cp_unit: coverpoint unit;
    cp_fu: coverpoint t.ctrl.fu_code { bins alu={FU_ALU}; bins jmp={FU_JMP}; bins mul={FU_MUL}; bins div={FU_DIV}; bins csr={FU_CSR}; bins fpu={FU_FPU}; bins fdv={FU_FDV}; bins i2f={FU_I2F}; bins f2i={FU_F2I}; }
    x_kill: cross cp_kind, cp_fu;
  endgroup

  // 19. backpressure / structural hazards
  covergroup cg19_backpressure;
    option.per_instance = 1;
    cp_div_busy:  coverpoint div_inflight  iff (t.ctrl.fu_code == FU_DIV);   // new div while one is in flight (driver waited)
    cp_fdiv_busy: coverpoint fdiv_inflight iff (t.ctrl.fu_code == FU_FDV);
    cp_i2f_q:     coverpoint i2f_queued    iff (t.ctrl.fu_code == FU_I2F);
    cp_f2i_q:     coverpoint f2i_queued    iff (t.ctrl.fu_code == FU_F2I);
    cp_ll_ready:  coverpoint cfg.ll_ready_pct { bins full={100}; bins throttled={[1:99]}; }
  endgroup

  // 20. write-port arbitration: divide result racing an ALU/CSR result on ALU1
  covergroup cg20_port_arb;
    option.per_instance = 1;
    cp_collision: coverpoint div_collision;
    cp_fdiv_vs_fma: coverpoint fdiv_inflight iff (t.ctrl.fu_code == FU_FPU);   // FMA issued while fdiv computes
  endgroup

  // 21. bypass network usage: distance between consecutive ALU requests (1,2,3 = bypass stages)
  covergroup cg21_bypass;
    option.per_instance = 1;
    cp_gap: coverpoint alu_gap iff (t.ctrl.fu_code inside {FU_ALU, FU_JMP, FU_CSR}) { bins back_to_back={1}; bins gap2={2}; bins gap3={3}; bins far={[4:100]}; }
    cp_unit: coverpoint unit iff (t.ctrl.fu_code inside {FU_ALU, FU_JMP, FU_CSR}) { bins alu0={EXU_ALU0}; bins alu1={EXU_ALU1}; }
    x_gap: cross cp_gap, cp_unit;
  endgroup

  // 22. concurrency: how many uops each unit has in flight when a new one issues
  covergroup cg22_inflight;
    option.per_instance = 1;
    cp_cnt: coverpoint inflight_cnt[unit] { bins none={0}; bins one={1}; bins two={2}; bins three={3}; bins many={[4:16]}; }
    cp_unit: coverpoint unit;
    cp_mask_live: coverpoint kill_hit_inflight;   // a mispredict actually found something to kill
    x_cnt_unit: cross cp_cnt, cp_unit;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_imp = new("req_imp", this); rsp_imp = new("rsp_imp", this); brinfo_imp = new("brinfo_imp", this); brupd_imp = new("brupd_imp", this);
    cg01_int_op = new(); cg02_alu_operands = new(); cg03_shift = new(); cg04_mul = new(); cg05_div = new();
    cg06_branch = new(); cg07_jump = new(); cg08_csr = new(); cg09_fp_op = new(); cg10_fp_rs1_class = new();
    cg11_fp_rs2_class = new(); cg12_fp_rs3_class = new(); cg13_fp_rm = new(); cg14_fp_flags = new(); cg15_fp_cvt = new();
    cg16_fp_cmp_class = new(); cg17_fp_nanbox = new(); cg18_kill = new(); cg19_backpressure = new(); cg20_port_arb = new();
    cg21_bypass = new(); cg22_inflight = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
  endfunction

  //------------------------------------------------------------ classification helpers
  function int int_class(bit [63:0] v);
    if (v == 0) return 0;
    if (v == 1) return 1;
    if (v == 64'hFFFF_FFFF_FFFF_FFFF) return 2;
    if (v == 64'h7FFF_FFFF_FFFF_FFFF) return 3;
    if (v == 64'h8000_0000_0000_0000) return 4;
    if (v[31] && !v[63]) return 7;
    return v[63] ? 6 : 5;
  endfunction

  function int group_of(exe_op_e op);
    case (op)
      OP_SLL,OP_SRL,OP_SRA,OP_SLLI,OP_SRLI,OP_SRAI,OP_SLLW,OP_SRLW,OP_SRAW,OP_SLLIW,OP_SRLIW,OP_SRAIW: return 1;
      OP_SLT,OP_SLTU,OP_SLTI,OP_SLTIU: return 2;
      OP_BEQ,OP_BNE,OP_BLT,OP_BGE,OP_BLTU,OP_BGEU: return 3;
      OP_JAL,OP_JALR,OP_AUIPC: return 4;
      OP_MUL,OP_MULH,OP_MULHU,OP_MULHSU,OP_MULW: return 5;
      OP_DIV,OP_DIVU,OP_REM,OP_REMU,OP_DIVW,OP_DIVUW,OP_REMW,OP_REMUW: return 6;
      OP_CSRRW,OP_CSRRS,OP_CSRRC,OP_CSRRWI,OP_CSRRSI,OP_CSRRCI: return 7;
      OP_FADD_S,OP_FSUB_S,OP_FMUL_S,OP_FMADD_S,OP_FMSUB_S,OP_FNMADD_S,OP_FNMSUB_S,
      OP_FADD_D,OP_FSUB_D,OP_FMUL_D,OP_FMADD_D,OP_FMSUB_D,OP_FNMADD_D,OP_FNMSUB_D: return 8;
      OP_FDIV_S,OP_FSQRT_S,OP_FDIV_D,OP_FSQRT_D: return 9;
      OP_FSGNJ_S,OP_FSGNJN_S,OP_FSGNJX_S,OP_FSGNJ_D,OP_FSGNJN_D,OP_FSGNJX_D,OP_FMIN_S,OP_FMAX_S,OP_FMIN_D,OP_FMAX_D,OP_FCVT_S_D,OP_FCVT_D_S: return 10;
      OP_FEQ_S,OP_FLT_S,OP_FLE_S,OP_FEQ_D,OP_FLT_D,OP_FLE_D,OP_FCLASS_S,OP_FCLASS_D,OP_FMV_X_W,OP_FMV_X_D,
      OP_FCVT_W_S,OP_FCVT_WU_S,OP_FCVT_L_S,OP_FCVT_LU_S,OP_FCVT_W_D,OP_FCVT_WU_D,OP_FCVT_L_D,OP_FCVT_LU_D: return 11;
      OP_FMV_W_X,OP_FMV_D_X,OP_FCVT_S_W,OP_FCVT_S_WU,OP_FCVT_S_L,OP_FCVT_S_LU,OP_FCVT_D_W,OP_FCVT_D_WU,OP_FCVT_D_L,OP_FCVT_D_LU: return 12;
      default: return 0;
    endcase
  endfunction

  //------------------------------------------------------------ sampling
  function void write_cov_req(boom_exe_txn tx);
    boom_exe_ref_model rm;
    t = tx; unit = t.ctrl.exu; op_group = group_of(t.op); single = is_single_op(t.op);
    // the monitor's txn has no expectation yet — compute one locally for result-based bins
    rm = boom_exe_ref_model::type_id::create("cov_ref");
    rm.predict(t);
    rs1_cls = int_class(t.rs1); rs2_cls = int_class(t.rs2);
    if (op_group == 3) rs1_cls = (t.rs1 == t.rs2) ? 8 : (($signed(t.rs1) < $signed(t.rs2)) ? 9 : 10);
    shamt = (t.ctrl.op2_sel == OP2_IMM) ? t.imm[5:0] : t.rs2[5:0];
    if (!t.ctrl.fcn_dw) shamt[5] = 0;
    f1 = single ? fp_classify32(t.rs1) : fp_classify64(t.rs1);
    f2 = single ? fp_classify32(t.rs2) : fp_classify64(t.rs2);
    f3 = single ? fp_classify32(t.rs3) : fp_classify64(t.rs3);
    if (op_group == 12) f1 = FPC_POS_NORM; // integer source
    if (t.op inside {OP_FCVT_D_S}) f1 = fp_classify32(t.rs1);
    if (t.op inside {OP_FCVT_S_D}) f1 = fp_classify64(t.rs1);
    div_cls = (t.rs2 == 0) ? 0 : (t.rs2 == 1) ? 1 : (t.rs2 == 64'hFFFF_FFFF_FFFF_FFFF || (!t.ctrl.fcn_dw && t.rs2[31:0] == 32'hFFFF_FFFF)) ? 2 : (t.rs2[63] ? 4 : 3);
    dvd_cls = (t.rs1 == 0) ? 0 : (t.rs1 == 64'h8000_0000_0000_0000 || (!t.ctrl.fcn_dw && t.rs1[31:0] == 32'h8000_0000)) ? 1 : (t.rs1[63] ? 3 : 2);
    jalr_reason = 0;
    if (t.op == OP_JALR) begin
      if (!t.ftq_next_val) jalr_reason = 1;
      else if (t.ftq_next_pc != t.exp_jalr_target) jalr_reason = 2;
      else if (!t.ftq_cfi_idx_valid) jalr_reason = 4;
      else if (t.exp_mispredict) jalr_reason = 3;
    end
    kill_kind = t.killed_same_cycle ? (t.flush_with_req ? 3 : 1) : 0;
    alu_gap = t.issue_cycle - last_alu_cycle[unit];
    if (t.ctrl.fu_code inside {FU_ALU, FU_JMP, FU_CSR}) last_alu_cycle[unit] = t.issue_cycle;
    div_collision = 0;
    // structural state
    cg01_int_op.sample(); cg02_alu_operands.sample(); cg03_shift.sample(); cg04_mul.sample(); cg05_div.sample();
    cg06_branch.sample(); cg07_jump.sample(); cg08_csr.sample(); cg09_fp_op.sample(); cg10_fp_rs1_class.sample();
    cg11_fp_rs2_class.sample(); cg12_fp_rs3_class.sample(); cg13_fp_rm.sample(); cg15_fp_cvt.sample();
    cg16_fp_cmp_class.sample(); cg17_fp_nanbox.sample(); cg19_backpressure.sample(); cg20_port_arb.sample();
    cg21_bypass.sample(); cg22_inflight.sample();
    if (kill_kind != 0) cg18_kill.sample();
    // bookkeeping
    if (!t.killed_same_cycle) begin
      inflight_cnt[unit]++; rob_inflight[unit].push_back(t.rob_idx); live_masks[unit] |= t.br_mask;
      if (t.ctrl.fu_code == FU_DIV) div_inflight = 1;
      if (t.ctrl.fu_code == FU_FDV) fdiv_inflight = 1;
      if (t.ctrl.fu_code == FU_I2F) i2f_queued = 1;
      if (t.ctrl.fu_code == FU_F2I) f2i_queued = 1;
    end
  endfunction

  function void write_cov_rsp(boom_exe_rsp rr);
    int idx[$];
    r = rr; unit = rr.unit;
    idx = rob_inflight[unit].find_index with (item == rr.uop.rob_idx);
    if (idx.size()) begin rob_inflight[unit].delete(idx[0]); if (inflight_cnt[unit] > 0) inflight_cnt[unit]--; end
    if (rr.uop.uopc inside {uopDIV,uopDIVU,uopREM,uopREMU,uopDIVW,uopDIVUW,uopREMW,uopREMUW}) div_inflight = 0;
    if (rr.uop.uopc inside {uopFDIV_S,uopFDIV_D,uopFSQRT_S,uopFSQRT_D}) fdiv_inflight = 0;
    if (rr.port == PORT_LL_FRESP) i2f_queued = 0;
    if (rr.port == PORT_LL_IRESP) f2i_queued = 0;
    if (rr.flags_valid) begin
      fl = rr.flags; op_group = group_of(op_from_uop_rsp(rr));
      cvt_sat = rr.flags[FF_NV];
      cg14_fp_flags.sample();
    end
  endfunction

  // map a response back to an op group using uopc only (rm/typ not available on the response)
  function exe_op_e op_from_uop_rsp(boom_exe_rsp rr);
    uop_t u = '0;
    u.uopc = rr.uop.uopc;
    return op_from_uop(u);
  endfunction

  function void write_cov_brinfo(boom_brinfo_rsp b);
    br = b;
  endfunction

  function void write_cov_brupd(boom_brupd_txn b);
    bu = b;
    kill_hit_inflight = 0;
    for (int u = 0; u < 3; u++) if ((live_masks[u] & b.mispredict_mask) != 0) kill_hit_inflight = 1;
    if (b.mispredict_mask != 0 && kill_hit_inflight) begin kill_kind = 2; cg18_kill.sample(); cg22_inflight.sample(); end
    if (b.flush) begin kill_kind = 3; cg18_kill.sample(); end
    for (int u = 0; u < 3; u++) begin
      if (b.flush) begin inflight_cnt[u] = 0; rob_inflight[u].delete(); live_masks[u] = 0; end
      live_masks[u] &= ~b.resolve_mask;
    end
    if (b.flush) begin div_inflight = 0; fdiv_inflight = 0; i2f_queued = 0; f2i_queued = 0; end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("\n  functional coverage: int_op %.1f%% alu_ops %.1f%% shift %.1f%% mul %.1f%% div %.1f%% branch %.1f%% jump %.1f%% csr %.1f%%\n  fp_op %.1f%% rs1cls %.1f%% rs2cls %.1f%% rs3cls %.1f%% rm %.1f%% flags %.1f%% cvt %.1f%% cmp %.1f%% nanbox %.1f%%\n  kill %.1f%% backpressure %.1f%% port_arb %.1f%% bypass %.1f%% inflight %.1f%%",
      cg01_int_op.get_inst_coverage(), cg02_alu_operands.get_inst_coverage(), cg03_shift.get_inst_coverage(), cg04_mul.get_inst_coverage(),
      cg05_div.get_inst_coverage(), cg06_branch.get_inst_coverage(), cg07_jump.get_inst_coverage(), cg08_csr.get_inst_coverage(),
      cg09_fp_op.get_inst_coverage(), cg10_fp_rs1_class.get_inst_coverage(), cg11_fp_rs2_class.get_inst_coverage(), cg12_fp_rs3_class.get_inst_coverage(),
      cg13_fp_rm.get_inst_coverage(), cg14_fp_flags.get_inst_coverage(), cg15_fp_cvt.get_inst_coverage(), cg16_fp_cmp_class.get_inst_coverage(),
      cg17_fp_nanbox.get_inst_coverage(), cg18_kill.get_inst_coverage(), cg19_backpressure.get_inst_coverage(), cg20_port_arb.get_inst_coverage(),
      cg21_bypass.get_inst_coverage(), cg22_inflight.get_inst_coverage()), UVM_LOW)
  endfunction
endclass : boom_exe_coverage

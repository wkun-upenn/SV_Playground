//=============================================================================
// boom_exe_seq_lib.sv — sequence library for the execution units
//-----------------------------------------------------------------------------
// All sequences run on the virtual sequencer and route each transaction to the
// sequencer of the unit that executes the op (decode_op(op).exu). Operand
// "policies" bias values towards the corner cases that matter for each op
// class; everything else is constrained-random.
//=============================================================================

typedef enum int { OPND_RANDOM, OPND_CORNER, OPND_MIXED, OPND_SMALL } opnd_policy_e;

//-----------------------------------------------------------------------------
// base sequence
//-----------------------------------------------------------------------------
class boom_exe_base_seq extends uvm_sequence #(boom_exe_txn);
  `uvm_object_utils(boom_exe_base_seq)
  `uvm_declare_p_sequencer(boom_exe_vsequencer)

  // knobs
  int unsigned   n            = 200;         // number of transactions
  exe_op_e       ops[$];                     // allowed ops (empty = all)
  int unsigned   max_delay    = 3;
  opnd_policy_e  policy       = OPND_MIXED;
  bit [11:0]     live_mask    = 12'h000;     // branch tags a uop may depend on
  int unsigned   tag_pct      = 50;          // % of uops that get a non-zero br_mask
  int unsigned   flush_pct    = 0;           // % of uops issued together with a flush
  int unsigned   unboxed_pct  = 0;           // % of single-precision uops with an unboxed rs1
  int unsigned   dyn_rm_pct   = 30;          // % of rm-using ops using RM_DYN
  int unsigned   csr_zimm_zero_pct = 20;

  static int     rob_ctr[3];                 // per-unit rob_idx allocator (unique among in-flight uops)
  static int     pdst_ctr = 1;

  function new(string name = "boom_exe_base_seq"); super.new(name); endfunction

  //------------------------------------------------------------ corner tables
  static bit [63:0] int_corners[] = '{
    64'h0, 64'h1, 64'h2, 64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFE,
    64'h7FFF_FFFF_FFFF_FFFF, 64'h8000_0000_0000_0000, 64'h8000_0000_0000_0001,
    64'h0000_0000_7FFF_FFFF, 64'h0000_0000_8000_0000, 64'h0000_0000_FFFF_FFFF, 64'h0000_0001_0000_0000,
    64'hFFFF_FFFF_8000_0000, 64'hFFFF_FFFF_7FFF_FFFF, 64'h0000_0000_0000_003F, 64'h0000_0000_0000_0040,
    64'h5555_5555_5555_5555, 64'hAAAA_AAAA_AAAA_AAAA, 64'h0000_0000_0000_0020, 64'h0000_0000_0000_001F };
  static bit [63:0] d_corners[] = '{
    D_POS_ZERO, D_NEG_ZERO, D_POS_INF, D_NEG_INF, D_QNAN, D_SNAN, 64'hFFF8_0000_0000_0000, 64'h7FF0_0000_0000_0001,
    D_MIN_SUBN, {1'b1, D_MIN_SUBN[62:0]}, D_MAX_SUBN, {1'b1, D_MAX_SUBN[62:0]}, D_MIN_NORM, {1'b1, D_MIN_NORM[62:0]},
    D_MAX_NORM, {1'b1, D_MAX_NORM[62:0]}, D_ONE, 64'hBFF0_0000_0000_0000, 64'h3FF8_0000_0000_0000, 64'h4000_0000_0000_0000,
    64'h3FD5_5555_5555_5555, 64'h4330_0000_0000_0000, 64'h43E0_0000_0000_0000, 64'hC3E0_0000_0000_0000,
    64'h41E0_0000_0000_0000, 64'hC1E0_0000_0000_0000, 64'h3CA0_0000_0000_0000, 64'h3FEF_FFFF_FFFF_FFFF };
  static bit [31:0] s_corners[] = '{
    S_POS_ZERO, S_NEG_ZERO, S_POS_INF, S_NEG_INF, S_QNAN, S_SNAN, 32'hFFC0_0000, 32'h7F80_0001,
    S_MIN_SUBN, 32'h8000_0001, S_MAX_SUBN, 32'h807F_FFFF, S_MIN_NORM, 32'h8080_0000, S_MAX_NORM, 32'hFF7F_FFFF,
    S_ONE, 32'hBF80_0000, 32'h3FC0_0000, 32'h4000_0000, 32'h3EAA_AAAB, 32'h4B00_0000, 32'h4F00_0000, 32'hCF00_0000,
    32'h5F00_0000, 32'hDF00_0000, 32'h3F7F_FFFF, 32'h3400_0000 };

  function bit [63:0] pick_int();
    case (policy)
      OPND_CORNER: return int_corners[$urandom_range(int_corners.size()-1)];
      OPND_SMALL : return $urandom_range(0, 255) - 128;
      OPND_MIXED : return ($urandom_range(99) < 40) ? int_corners[$urandom_range(int_corners.size()-1)] : {$urandom, $urandom};
      default    : return {$urandom, $urandom};
    endcase
  endfunction
  function bit [63:0] pick_d();
    case (policy)
      OPND_CORNER: return d_corners[$urandom_range(d_corners.size()-1)];
      OPND_MIXED : return ($urandom_range(99) < 40) ? d_corners[$urandom_range(d_corners.size()-1)] : {$urandom, $urandom};
      default    : return {$urandom, $urandom};
    endcase
  endfunction
  function bit [63:0] pick_s();
    case (policy)
      OPND_CORNER: return box_s(s_corners[$urandom_range(s_corners.size()-1)]);
      OPND_MIXED : return box_s(($urandom_range(99) < 40) ? s_corners[$urandom_range(s_corners.size()-1)] : $urandom);
      default    : return box_s($urandom);
    endcase
  endfunction

  //------------------------------------------------------------ helpers
  function exe_op_e pick_op();
    if (ops.size() == 0) return exe_op_e'($urandom_range(OP_NUM - 1));
    return ops[$urandom_range(ops.size() - 1)];
  endfunction

  function bit [11:0] pick_mask();
    bit [11:0] m = '0;
    if (live_mask == 0 || $urandom_range(99) >= tag_pct) return '0;
    for (int i = 0; i < 12; i++) if (live_mask[i] && $urandom_range(2) == 0) m[i] = 1;
    if (m == 0) begin  // at least one live tag
      for (int i = 0; i < 12; i++) if (live_mask[i]) begin m[i] = 1; break; end
    end
    return m;
  endfunction

  // fill operands according to the policy; called after randomize()
  virtual function void shape(boom_exe_txn t);
    op_ctrl_t c = decode_op(t.op);
    bit single = is_single_op(t.op);
    if (is_fp_op(t.op)) begin
      // FP register sources
      if (c.lrs1_rtype == RT_FLT) t.rs1 = single ? pick_s() : pick_d();
      else                        t.rs1 = pick_int();                 // I2F integer source
      if (c.lrs2_rtype == RT_FLT) t.rs2 = single ? pick_s() : pick_d();
      if (c.frs3_en)              t.rs3 = single ? pick_s() : pick_d();
      if (t.op == OP_FCVT_D_S) t.rs1 = pick_s();
      if (t.op == OP_FCVT_S_D) t.rs1 = pick_d();
      if (single && c.lrs1_rtype == RT_FLT && $urandom_range(99) < unboxed_pct) begin
        t.deliberately_unboxed = 1; t.rs1 = pick_d();               // a double where a single is expected
      end
      if (uses_rm(t.op)) t.rm = ($urandom_range(99) < dyn_rm_pct) ? RM_DYN : 3'($urandom_range(4));
    end else begin
      t.rs1 = pick_int(); t.rs2 = pick_int();
      if (t.op inside {OP_SLL, OP_SRL, OP_SRA, OP_SLLW, OP_SRLW, OP_SRAW} && $urandom_range(1))
        t.rs2 = {58'b0, 6'($urandom_range(63))};
    end
    t.br_mask = pick_mask();
    t.rob_idx = 6'(rob_ctr[c.exu]); rob_ctr[c.exu] = (rob_ctr[c.exu] + 1) % 64;
    t.pdst = 7'(pdst_ctr); pdst_ctr = (pdst_ctr % (NUM_INT_PREGS - 1)) + 1;
    if ($urandom_range(99) < flush_pct) t.flush_with_req = 1;
  endfunction

  virtual task send(boom_exe_txn t);
    boom_exe_sequencer s = p_sequencer.sqr_of(decode_op(t.op).exu);
    start_item(t, -1, s);
    finish_item(t);
  endtask

  virtual task body();
    for (int i = 0; i < n; i++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create($sformatf("t%0d", i));
      exe_op_e o = pick_op();
      if (!t.randomize() with { op == o; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; })
        `uvm_fatal("SEQ", "randomize failed")
      shape(t);
      send(t);
    end
  endtask
endclass : boom_exe_base_seq

//-----------------------------------------------------------------------------
// op-class sequences (thin subclasses: they only choose the op set / policy)
//-----------------------------------------------------------------------------
`define BOOM_OPSEQ(NAME, POLICY, OPLIST) \
class NAME extends boom_exe_base_seq; \
  `uvm_object_utils(NAME) \
  function new(string name = `"NAME`"); super.new(name); policy = POLICY; ops = OPLIST; endfunction \
endclass

`BOOM_OPSEQ(exe_alu_rr_seq,   OPND_MIXED,  '{OP_ADD, OP_SUB, OP_SLL, OP_SLT, OP_SLTU, OP_XOR, OP_SRL, OP_SRA, OP_OR, OP_AND, OP_MOV})
`BOOM_OPSEQ(exe_alu_imm_seq,  OPND_MIXED,  '{OP_ADDI, OP_SLTI, OP_SLTIU, OP_XORI, OP_ORI, OP_ANDI, OP_SLLI, OP_SRLI, OP_SRAI, OP_LUI})
`BOOM_OPSEQ(exe_alu_w_seq,    OPND_MIXED,  '{OP_ADDW, OP_SUBW, OP_SLLW, OP_SRLW, OP_SRAW, OP_ADDIW, OP_SLLIW, OP_SRLIW, OP_SRAIW})
`BOOM_OPSEQ(exe_shift_seq,    OPND_CORNER, '{OP_SLL, OP_SRL, OP_SRA, OP_SLLI, OP_SRLI, OP_SRAI, OP_SLLW, OP_SRLW, OP_SRAW, OP_SLLIW, OP_SRLIW, OP_SRAIW})
`BOOM_OPSEQ(exe_cmp_seq,      OPND_CORNER, '{OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU})
`BOOM_OPSEQ(exe_branch_seq,   OPND_MIXED,  '{OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU})
`BOOM_OPSEQ(exe_jump_seq,     OPND_MIXED,  '{OP_JAL, OP_JALR, OP_AUIPC})
`BOOM_OPSEQ(exe_mul_seq,      OPND_MIXED,  '{OP_MUL, OP_MULH, OP_MULHU, OP_MULHSU, OP_MULW})
`BOOM_OPSEQ(exe_div_seq,      OPND_MIXED,  '{OP_DIV, OP_DIVU, OP_REM, OP_REMU, OP_DIVW, OP_DIVUW, OP_REMW, OP_REMUW})
`BOOM_OPSEQ(exe_csr_seq,      OPND_MIXED,  '{OP_CSRRW, OP_CSRRS, OP_CSRRC, OP_CSRRWI, OP_CSRRSI, OP_CSRRCI})
`BOOM_OPSEQ(exe_int_all_seq,  OPND_MIXED,  '{OP_ADD, OP_SUB, OP_SLL, OP_SLT, OP_SLTU, OP_XOR, OP_SRL, OP_SRA, OP_OR, OP_AND, OP_ADDI, OP_SLTI, OP_SLTIU, OP_XORI, OP_ORI, OP_ANDI, OP_SLLI, OP_SRLI, OP_SRAI, OP_ADDW, OP_SUBW, OP_SLLW, OP_SRLW, OP_SRAW, OP_ADDIW, OP_SLLIW, OP_SRLIW, OP_SRAIW, OP_LUI, OP_AUIPC, OP_MOV, OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU, OP_JAL, OP_JALR, OP_MUL, OP_MULH, OP_MULHU, OP_MULHSU, OP_MULW, OP_DIV, OP_DIVU, OP_REM, OP_REMU, OP_DIVW, OP_DIVUW, OP_REMW, OP_REMUW, OP_CSRRW, OP_CSRRS, OP_CSRRC, OP_CSRRWI, OP_CSRRSI, OP_CSRRCI})
`BOOM_OPSEQ(exe_fp_add_seq,   OPND_MIXED,  '{OP_FADD_S, OP_FSUB_S, OP_FADD_D, OP_FSUB_D})
`BOOM_OPSEQ(exe_fp_mul_seq,   OPND_MIXED,  '{OP_FMUL_S, OP_FMUL_D})
`BOOM_OPSEQ(exe_fp_fma_seq,   OPND_MIXED,  '{OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D})
`BOOM_OPSEQ(exe_fp_arith_seq, OPND_MIXED,  '{OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S, OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D})
`BOOM_OPSEQ(exe_fdiv_seq,     OPND_MIXED,  '{OP_FDIV_S, OP_FSQRT_S, OP_FDIV_D, OP_FSQRT_D})
`BOOM_OPSEQ(exe_fp_sgnj_seq,  OPND_CORNER, '{OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S, OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D})
`BOOM_OPSEQ(exe_fp_minmax_seq,OPND_CORNER, '{OP_FMIN_S, OP_FMAX_S, OP_FMIN_D, OP_FMAX_D})
`BOOM_OPSEQ(exe_fp_cvt_sd_seq,OPND_CORNER, '{OP_FCVT_S_D, OP_FCVT_D_S})
`BOOM_OPSEQ(exe_fp_cmp_seq,   OPND_CORNER, '{OP_FEQ_S, OP_FLT_S, OP_FLE_S, OP_FEQ_D, OP_FLT_D, OP_FLE_D})
`BOOM_OPSEQ(exe_fp_class_seq, OPND_CORNER, '{OP_FCLASS_S, OP_FCLASS_D})
`BOOM_OPSEQ(exe_fp_mv_seq,    OPND_MIXED,  '{OP_FMV_X_W, OP_FMV_X_D, OP_FMV_W_X, OP_FMV_D_X})
`BOOM_OPSEQ(exe_f2i_cvt_seq,  OPND_CORNER, '{OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D})
`BOOM_OPSEQ(exe_i2f_cvt_seq,  OPND_CORNER, '{OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU, OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU})
`BOOM_OPSEQ(exe_fp_all_seq,   OPND_MIXED,  '{OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S, OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D, OP_FDIV_S, OP_FSQRT_S, OP_FDIV_D, OP_FSQRT_D, OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S, OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D, OP_FMIN_S, OP_FMAX_S, OP_FMIN_D, OP_FMAX_D, OP_FCVT_S_D, OP_FCVT_D_S, OP_FEQ_S, OP_FLT_S, OP_FLE_S, OP_FEQ_D, OP_FLT_D, OP_FLE_D, OP_FCLASS_S, OP_FCLASS_D, OP_FMV_X_W, OP_FMV_X_D, OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D, OP_FMV_W_X, OP_FMV_D_X, OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU, OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU})
`BOOM_OPSEQ(exe_alu0_only_seq,OPND_MIXED,  '{OP_ADD, OP_SUB, OP_XOR, OP_SLL, OP_SRA, OP_ADDI, OP_LUI, OP_MUL, OP_MULH, OP_JAL, OP_JALR, OP_AUIPC, OP_BEQ, OP_BLT, OP_FMV_D_X, OP_FCVT_S_W, OP_FCVT_D_L})
`BOOM_OPSEQ(exe_alu1_only_seq,OPND_MIXED,  '{OP_DIV, OP_DIVU, OP_REM, OP_REMU, OP_DIVW, OP_REMUW, OP_CSRRW, OP_CSRRS, OP_CSRRWI, OP_CSRRCI})
`BOOM_OPSEQ(exe_fpu_only_seq, OPND_MIXED,  '{OP_FADD_D, OP_FMUL_S, OP_FMADD_D, OP_FNMSUB_S, OP_FDIV_D, OP_FSQRT_S, OP_FMIN_D, OP_FSGNJX_S, OP_FEQ_D, OP_FCLASS_S, OP_FCVT_W_D, OP_FCVT_LU_S, OP_FMV_X_D})

//-----------------------------------------------------------------------------
// directed sequences
//-----------------------------------------------------------------------------

// every integer corner value against every other, for a list of ops
class exe_int_corner_cross_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_int_corner_cross_seq)
  function new(string name = "exe_int_corner_cross_seq"); super.new(name); policy = OPND_CORNER;
    ops = '{OP_ADD, OP_SUB, OP_SLT, OP_SLTU, OP_ADDW, OP_SUBW, OP_MULH, OP_MULHSU, OP_MULHU, OP_MULW, OP_DIV, OP_REM, OP_DIVW, OP_REMUW}; endfunction
  virtual task body();
    foreach (ops[k]) foreach (int_corners[i]) foreach (int_corners[j]) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t); t.rs1 = int_corners[i]; t.rs2 = int_corners[j];
      send(t);
    end
  endtask
endclass

// divide corner cases: /0, MIN/-1, x/1, x/x, W forms with 32-bit boundaries
class exe_div_corner_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_div_corner_seq)
  function new(string name = "exe_div_corner_seq"); super.new(name); policy = OPND_CORNER;
    ops = '{OP_DIV, OP_DIVU, OP_REM, OP_REMU, OP_DIVW, OP_DIVUW, OP_REMW, OP_REMUW}; endfunction
  virtual task body();
    bit [63:0] dividends[] = '{64'h0, 64'h1, 64'hFFFF_FFFF_FFFF_FFFF, 64'h8000_0000_0000_0000, 64'h7FFF_FFFF_FFFF_FFFF, 64'h0000_0000_8000_0000, 64'h0000_0000_7FFF_FFFF, 64'hFFFF_FFFF_8000_0000, 64'h1234_5678_9ABC_DEF0};
    bit [63:0] divisors[]  = '{64'h0, 64'h1, 64'hFFFF_FFFF_FFFF_FFFF, 64'h2, 64'h8000_0000_0000_0000, 64'h0000_0000_FFFF_FFFF, 64'h0000_0000_8000_0000, 64'h7, 64'hFFFF_FFFF_FFFF_FFF9};
    foreach (ops[k]) foreach (dividends[i]) foreach (divisors[j]) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t); t.rs1 = dividends[i]; t.rs2 = divisors[j];
      send(t);
    end
  endtask
endclass

// shift amounts 0..63 for every shift op (both register and immediate forms)
class exe_shift_sweep_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_shift_sweep_seq)
  function new(string name = "exe_shift_sweep_seq"); super.new(name); policy = OPND_CORNER;
    ops = '{OP_SLL, OP_SRL, OP_SRA, OP_SLLI, OP_SRLI, OP_SRAI, OP_SLLW, OP_SRLW, OP_SRAW, OP_SLLIW, OP_SRLIW, OP_SRAIW}; endfunction
  virtual task body();
    foreach (ops[k]) for (int sh = 0; sh < 64; sh++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      bit is_w = ops[k] inside {OP_SLLW, OP_SRLW, OP_SRAW, OP_SLLIW, OP_SRLIW, OP_SRAIW};
      bit is_imm = ops[k] inside {OP_SLLI, OP_SRLI, OP_SRAI, OP_SLLIW, OP_SRLIW, OP_SRAIW};
      if (is_w && is_imm && sh > 31) continue;
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t);
      if (is_imm) t.imm = sh; else t.rs2 = sh | (64'($urandom_range(3)) << 6);   // bits above the shamt must be ignored
      send(t);
    end
  endtask
endclass

// branches: force every (relation × predicted) combination for every branch type
class exe_branch_matrix_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_branch_matrix_seq)
  function new(string name = "exe_branch_matrix_seq"); super.new(name); ops = '{OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU}; endfunction
  virtual task body();
    bit [63:0] pairs[][2] = '{'{64'h5, 64'h5}, '{64'h5, 64'h7}, '{64'h7, 64'h5}, '{64'hFFFF_FFFF_FFFF_FFFF, 64'h1}, '{64'h1, 64'hFFFF_FFFF_FFFF_FFFF},
                              '{64'h8000_0000_0000_0000, 64'h7FFF_FFFF_FFFF_FFFF}, '{64'h7FFF_FFFF_FFFF_FFFF, 64'h8000_0000_0000_0000}, '{64'h0, 64'h0},
                              '{64'h0, 64'h8000_0000_0000_0000}, '{64'h0000_0000_FFFF_FFFF, 64'h0000_0001_0000_0000}};
    foreach (ops[k]) foreach (pairs[i]) for (int p = 0; p < 2; p++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; pred_taken == p[0]; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t); t.rs1 = pairs[i][0]; t.rs2 = pairs[i][1];
      send(t);
    end
  endtask
endclass

// JALR: every mispredict reason (correct / no next / wrong target / wrong cfi idx / cfi invalid) × rvc
class exe_jalr_matrix_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_jalr_matrix_seq)
  function new(string name = "exe_jalr_matrix_seq"); super.new(name); ops = '{OP_JALR}; endfunction
  virtual task body();
    boom_exe_ref_model rm = boom_exe_ref_model::type_id::create("rm");
    for (int i = 0; i < n; i++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      int reason = i % 5;
      bit [39:0] tgt;
      if (!t.randomize() with { op == OP_JALR; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; ftq_next_val == 1; ftq_cfi_idx_valid == 1; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t);
      // compute the real target and then build the FTQ view for the wanted outcome
      begin
        boom_exe_txn tmp = boom_exe_txn::type_id::create("tmp"); tmp.copy(t);
        tmp.uop.imm_packed = pack_imm(IS_I, t.imm); tmp.uop.pc_lob = t.pc[5:0]; tmp.ctrl = decode_op(OP_JALR);
        rm.predict(tmp); tgt = tmp.exp_jalr_target;
      end
      t.ftq_next_pc = tgt;
      begin
        bit [5:0] lob = t.pc[5:0] ^ (t.ftq_start_bank ? 6'(BANK_BYTES) : 6'd0);
        t.ftq_cfi_idx = lob[2:1];
      end
      case (reason)
        1: t.ftq_next_val = 0;
        2: t.ftq_next_pc = tgt ^ 40'h10;
        3: t.ftq_cfi_idx = t.ftq_cfi_idx ^ 2'b01;
        4: t.ftq_cfi_idx_valid = 0;
        default: ;
      endcase
      send(t);
    end
  endtask
endclass

// full cross of IEEE special operand classes for the FP ops (rs1 × rs2, and rs3 for FMA)
class exe_fp_corner_cross_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_fp_corner_cross_seq)
  bit include_rs3 = 0;
  function new(string name = "exe_fp_corner_cross_seq"); super.new(name); policy = OPND_CORNER;
    ops = '{OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMIN_D, OP_FMAX_S, OP_FEQ_D, OP_FLT_S, OP_FLE_D}; endfunction
  virtual task body();
    foreach (ops[k]) begin
      bit single = is_single_op(ops[k]);
      int nc = single ? s_corners.size() : d_corners.size();
      for (int i = 0; i < nc; i++) for (int j = 0; j < nc; j++) begin
        boom_exe_txn t = boom_exe_txn::type_id::create("t");
        if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; }) `uvm_fatal("SEQ", "randomize failed")
        shape(t);
        t.rs1 = single ? box_s(s_corners[i]) : d_corners[i];
        t.rs2 = single ? box_s(s_corners[j]) : d_corners[j];
        if (include_rs3) t.rs3 = single ? box_s(s_corners[$urandom_range(nc-1)]) : d_corners[$urandom_range(nc-1)];
        send(t);
      end
    end
  endtask
endclass

// FMA-specific: (a*b)+c with signed zero / inf / NaN interactions, all four fused forms
class exe_fma_corner_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_fma_corner_seq)
  function new(string name = "exe_fma_corner_seq"); super.new(name); policy = OPND_CORNER;
    ops = '{OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D}; endfunction
  virtual task body();
    bit [63:0] trip_d[][3] = '{'{D_POS_INF, D_POS_ZERO, D_ONE}, '{D_POS_INF, D_ONE, D_NEG_INF}, '{D_ONE, D_ONE, 64'hBFF0_0000_0000_0000},
                               '{D_NEG_ZERO, D_ONE, D_POS_ZERO}, '{D_NEG_ZERO, D_ONE, D_NEG_ZERO}, '{D_MAX_NORM, 64'h4000_0000_0000_0000, D_NEG_INF},
                               '{D_MIN_SUBN, D_MIN_SUBN, D_POS_ZERO}, '{D_QNAN, D_ONE, D_ONE}, '{D_ONE, D_SNAN, D_ONE}, '{D_POS_INF, D_POS_ZERO, D_QNAN},
                               '{64'h3FF0_0000_0000_0001, 64'h3FF0_0000_0000_0001, 64'hBFF0_0000_0000_0002}, '{D_MAX_NORM, D_MAX_NORM, D_NEG_INF}};
    foreach (ops[k]) foreach (trip_d[i]) for (int r = 0; r < 5; r++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      bit single = is_single_op(ops[k]);
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; rm == r; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t); t.rm = 3'(r);
      if (single) begin
        t.rs1 = box_s(narrow(trip_d[i][0])); t.rs2 = box_s(narrow(trip_d[i][1])); t.rs3 = box_s(narrow(trip_d[i][2]));
      end else begin
        t.rs1 = trip_d[i][0]; t.rs2 = trip_d[i][1]; t.rs3 = trip_d[i][2];
      end
      send(t);
    end
  endtask
  // crude double->single bit narrowing for the special values used above (exact for specials / small ints)
  function bit [31:0] narrow(bit [63:0] d);
    fp_class_e c = fp_classify64(d);
    case (c)
      FPC_POS_ZERO: return S_POS_ZERO; FPC_NEG_ZERO: return S_NEG_ZERO; FPC_POS_INF: return S_POS_INF; FPC_NEG_INF: return S_NEG_INF;
      FPC_QNAN: return S_QNAN; FPC_SNAN: return S_SNAN;
      FPC_POS_SUBN, FPC_NEG_SUBN: return d[63] ? 32'h8000_0001 : S_MIN_SUBN;
      default: begin
        if (d == D_MAX_NORM) return S_MAX_NORM;
        if (d == D_ONE) return S_ONE;
        if (d == 64'hBFF0_0000_0000_0000) return 32'hBF80_0000;
        if (d == 64'h4000_0000_0000_0000) return 32'h4000_0000;
        if (d == 64'h3FF0_0000_0000_0001) return 32'h3F80_0001;
        if (d == 64'hBFF0_0000_0000_0002) return 32'hBF80_0002;
        return {d[63], d[62], d[58:52], d[51:29]};
      end
    endcase
  endfunction
endclass

// conversions with saturation / NaN / inexact inputs and all rounding modes
class exe_cvt_corner_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_cvt_corner_seq)
  function new(string name = "exe_cvt_corner_seq"); super.new(name); policy = OPND_CORNER; dyn_rm_pct = 0;
    ops = '{OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D,
            OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU, OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU, OP_FCVT_S_D, OP_FCVT_D_S}; endfunction
  virtual task body();
    bit [63:0] fp_in[] = '{D_POS_ZERO, D_NEG_ZERO, D_POS_INF, D_NEG_INF, D_QNAN, D_SNAN, D_ONE, 64'hBFF0_0000_0000_0000,
                          64'h3FE0_0000_0000_0000, 64'hBFE0_0000_0000_0000, 64'h3FF8_0000_0000_0000, 64'hBFF8_0000_0000_0000,   // 0.5 -0.5 1.5 -1.5
                          64'h41DF_FFFF_FFC0_0000, 64'h41E0_0000_0000_0000, 64'hC1E0_0000_0000_0000, 64'hC1E0_0000_0020_0000,   // 2^31-1, 2^31, -2^31, -2^31-1
                          64'h41EF_FFFF_FFE0_0000, 64'h41F0_0000_0000_0000, 64'h43DF_FFFF_FFFF_FFFF, 64'h43E0_0000_0000_0000,   // 2^32-1 2^32 2^63-eps 2^63
                          64'hC3E0_0000_0000_0000, 64'hC3E0_0000_0000_0001, 64'h43EF_FFFF_FFFF_FFFF, 64'h43F0_0000_0000_0000,   // -2^63 -2^63-eps 2^64-eps 2^64
                          D_MIN_SUBN, D_MAX_NORM, 64'h4330_0000_0000_0001, 64'h3FEF_FFFF_FFFF_FFFF, 64'hBFEF_FFFF_FFFF_FFFF};
    bit [63:0] int_in[] = '{64'h0, 64'h1, 64'hFFFF_FFFF_FFFF_FFFF, 64'h7FFF_FFFF_FFFF_FFFF, 64'h8000_0000_0000_0000, 64'h0000_0000_7FFF_FFFF,
                            64'h0000_0000_8000_0000, 64'h0000_0000_FFFF_FFFF, 64'h0020_0000_0000_0001, 64'h0020_0000_0000_0003, 64'h0000_0001_0000_0001, 64'h1234_5678_9ABC_DEF1};
    foreach (ops[k]) begin
      bit to_int = ops[k] inside {OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D, OP_FCVT_S_D, OP_FCVT_D_S};
      int nin = to_int ? fp_in.size() : int_in.size();
      for (int i = 0; i < nin; i++) for (int r = 0; r < 5; r++) begin
        boom_exe_txn t = boom_exe_txn::type_id::create("t");
        if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; rm == r; }) `uvm_fatal("SEQ", "randomize failed")
        shape(t); t.rm = 3'(r);
        if (to_int) begin
          t.rs1 = fp_in[i];
          if (ops[k] inside {OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_D_S}) t.rs1 = box_s(to_single(fp_in[i]));
        end else t.rs1 = int_in[i];
        send(t);
      end
    end
  endtask
  // exact double->single for the values in fp_in (specials or representable), else round-to-nearest via DPI
  function bit [31:0] to_single(bit [63:0] d);
    longint unsigned res; int fl;
    void'(boom_fp_ref(boom_exe_ref_model::FPR_CVT_S_D, 1, 0, 0, d, 0, 0, res, fl));
    return res[31:0];
  endfunction
endclass

// every rounding mode (static and dynamic via fcsr) for every rm-using op, random operands
class exe_rm_sweep_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_rm_sweep_seq)
  function new(string name = "exe_rm_sweep_seq"); super.new(name); policy = OPND_MIXED; endfunction
  virtual task body();
    for (int o = OP_FADD_S; o < OP_NUM; o++) begin
      if (!uses_rm(exe_op_e'(o))) continue;
      for (int r = 0; r < 5; r++) for (int d = 0; d < 2; d++) for (int rep = 0; rep < 4; rep++) begin
        boom_exe_txn t = boom_exe_txn::type_id::create("t");
        if (!t.randomize() with { op == exe_op_e'(o); delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; }) `uvm_fatal("SEQ", "randomize failed")
        shape(t);
        if (d) begin t.rm = RM_DYN; t.fcsr_rm = 3'(r); end else t.rm = 3'(r);
        send(t);
      end
    end
  endtask
endclass

// single-precision ops fed with non-NaN-boxed operands: the hardware must see canonical NaN
class exe_nanbox_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_nanbox_seq)
  function new(string name = "exe_nanbox_seq"); super.new(name); policy = OPND_MIXED; unboxed_pct = 100;
    ops = '{OP_FADD_S, OP_FMUL_S, OP_FMADD_S, OP_FDIV_S, OP_FSQRT_S, OP_FSGNJ_S, OP_FMIN_S, OP_FMAX_S, OP_FEQ_S, OP_FLT_S, OP_FCLASS_S, OP_FCVT_W_S, OP_FCVT_D_S, OP_FMV_X_W}; endfunction
endclass

// back-to-back: zero idle cycles, one unit, to stress write-port arbitration and bypass stages
class exe_b2b_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_b2b_seq)
  function new(string name = "exe_b2b_seq"); super.new(name); max_delay = 0; policy = OPND_MIXED; endfunction
endclass

// divide interleaved with ALU/CSR traffic on the same unit (write-port collision on ALU1)
class exe_div_collision_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_div_collision_seq)
  function new(string name = "exe_div_collision_seq"); super.new(name); max_delay = 0; policy = OPND_MIXED;
    ops = '{OP_DIV, OP_CSRRW, OP_CSRRS, OP_CSRRWI, OP_DIVU, OP_CSRRC, OP_REM, OP_CSRRSI}; endfunction
endclass

// fdiv/fsqrt interleaved with FMA and F2I traffic (fresp arbitration, fu_types masking)
class exe_fdiv_collision_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_fdiv_collision_seq)
  function new(string name = "exe_fdiv_collision_seq"); super.new(name); max_delay = 0; policy = OPND_MIXED;
    ops = '{OP_FDIV_D, OP_FADD_D, OP_FMUL_S, OP_FEQ_D, OP_FSQRT_S, OP_FMADD_D, OP_FCVT_W_D, OP_FDIV_S, OP_FCLASS_S}; endfunction
endclass

// CSR immediates and addresses sweep
class exe_csr_sweep_seq extends boom_exe_base_seq;
  `uvm_object_utils(exe_csr_sweep_seq)
  function new(string name = "exe_csr_sweep_seq"); super.new(name); ops = '{OP_CSRRW, OP_CSRRS, OP_CSRRC, OP_CSRRWI, OP_CSRRSI, OP_CSRRCI}; endfunction
  virtual task body();
    bit [11:0] addrs[] = '{12'h001, 12'h002, 12'h003, 12'h306, 12'h304, 12'h305, 12'h340, 12'h341, 12'h342, 12'h343, 12'hC00, 12'hC02, 12'hF11, 12'h140};
    foreach (ops[k]) foreach (addrs[i]) for (int z = 0; z < 4; z++) begin
      boom_exe_txn t = boom_exe_txn::type_id::create("t");
      if (!t.randomize() with { op == ops[k]; delay <= local::max_delay; flush_with_req == 0; deliberately_unboxed == 0; csr_addr == addrs[i]; }) `uvm_fatal("SEQ", "randomize failed")
      shape(t); t.zimm = (z == 0) ? 0 : (z == 1) ? 5'h1F : 5'($urandom);
      send(t);
    end
  endtask
endclass

//-----------------------------------------------------------------------------
// branch-update sequences (run in parallel with exe traffic)
//-----------------------------------------------------------------------------
class brupd_base_seq extends uvm_sequence #(boom_brupd_txn);
  `uvm_object_utils(brupd_base_seq)
  `uvm_declare_p_sequencer(boom_exe_vsequencer)
  int unsigned n = 50;
  bit [11:0]   live_mask = 12'h0FF;     // tags that exist
  int unsigned mispredict_pct = 30;
  int unsigned flush_pct = 0;
  int unsigned max_delay = 12;
  function new(string name = "brupd_base_seq"); super.new(name); endfunction
  virtual task body();
    for (int i = 0; i < n; i++) begin
      boom_brupd_txn b = boom_brupd_txn::type_id::create("b");
      bit [11:0] tag = '0;
      int pick = $urandom_range(11);
      for (int k = 0; k < 12; k++) if (live_mask[(pick + k) % 12]) begin tag[(pick + k) % 12] = 1; break; end
      start_item(b, -1, p_sequencer.brupd_sqr);
      if (!b.randomize() with { delay <= local::max_delay; resolve_mask == tag;
                                mispredict_mask == (($urandom_range(99) < local::mispredict_pct) ? tag : 12'h0);
                                flush == ($urandom_range(99) < local::flush_pct); })
        `uvm_fatal("SEQ", "randomize failed")
      finish_item(b);
    end
  endtask
endclass

// resolve every live tag (correctly) once — used to drain speculation at the end of a test
class brupd_resolve_all_seq extends brupd_base_seq;
  `uvm_object_utils(brupd_resolve_all_seq)
  function new(string name = "brupd_resolve_all_seq"); super.new(name); endfunction
  virtual task body();
    for (int k = 0; k < 12; k++) if (live_mask[k]) begin
      boom_brupd_txn b = boom_brupd_txn::type_id::create("b");
      start_item(b, -1, p_sequencer.brupd_sqr);
      if (!b.randomize() with { delay == 1; resolve_mask == (12'h1 << k); mispredict_mask == 0; flush == 0; }) `uvm_fatal("SEQ", "randomize failed")
      finish_item(b);
    end
  endtask
endclass

// periodic pipeline flushes
class brupd_flush_seq extends brupd_base_seq;
  `uvm_object_utils(brupd_flush_seq)
  function new(string name = "brupd_flush_seq"); super.new(name); flush_pct = 100; mispredict_pct = 0; live_mask = 0; endfunction
  virtual task body();
    for (int i = 0; i < n; i++) begin
      boom_brupd_txn b = boom_brupd_txn::type_id::create("b");
      start_item(b, -1, p_sequencer.brupd_sqr);
      if (!b.randomize() with { delay <= local::max_delay; resolve_mask == 0; mispredict_mask == 0; flush == 1; }) `uvm_fatal("SEQ", "randomize failed")
      finish_item(b);
    end
  endtask
endclass

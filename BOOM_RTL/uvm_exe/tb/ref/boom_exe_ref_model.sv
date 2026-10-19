//=============================================================================
// boom_exe_ref_model.sv — golden model for the BOOM execute pipeline
//-----------------------------------------------------------------------------
// Integer / branch / jump / CSR data paths are modelled here in SystemVerilog
// (they follow rocket ALU.scala, MulDiv, and BOOM's ALUUnit semantics).
// Floating-point paths call into dpi/boom_fp_ref.c, which uses Berkeley
// SoftFloat-3e with the RISC-V specialization — the library Spike uses — so
// FP results and fflags are Spike's golden results.
//=============================================================================

// DPI-C import (see dpi/boom_fp_ref.c)
import "DPI-C" function int boom_fp_ref(input int op, input int is_double, input int rm, input int typ,
                                        input longint unsigned a, input longint unsigned b, input longint unsigned c,
                                        output longint unsigned result, output int flags);
import "DPI-C" function string boom_fp_ref_backend();

class boom_exe_ref_model extends uvm_object;
  `uvm_object_utils(boom_exe_ref_model)

  // op codes of the C model
  typedef enum int {
    FPR_ADD = 0, FPR_SUB, FPR_MUL, FPR_MADD, FPR_MSUB, FPR_NMADD, FPR_NMSUB,
    FPR_DIV, FPR_SQRT, FPR_SGNJ, FPR_SGNJN, FPR_SGNJX, FPR_MIN, FPR_MAX,
    FPR_CVT_S_D, FPR_CVT_D_S, FPR_EQ, FPR_LT, FPR_LE, FPR_CLASS, FPR_MV_X_F,
    FPR_CVT_INT_F, FPR_MV_F_X, FPR_CVT_F_INT
  } fp_op_e;

  // Known RTL deviations that the model reproduces when the waiver is on (see docs/vplan.md, "RTL findings"):
  //  W1  fdiv.s / fsqrt.s with a signalling-NaN operand do not raise NV: FDivSqrtUnit up-converts
  //      single operands with a RecFNToRecFN whose exception flags are dropped, so the double
  //      divider only ever sees the (already quiet) canonical NaN.
  bit waive_fdiv_s_snan_nv = 1;

  function new(string name = "boom_exe_ref_model");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // predict: fill t.exp_* from t.op / operands / ctrl
  //---------------------------------------------------------------------------
  function void predict(boom_exe_txn t);
    t.exp_has_data = 0; t.exp_flags_valid = 0; t.exp_flags = '0; t.exp_brinfo_valid = 0;
    t.exp_port = t.ctrl.rsp_port;
    if (is_fp_op(t.op)) predict_fp(t);
    else                predict_int(t);
  endfunction

  //---------------------------------------------------------------------------
  // integer side
  //---------------------------------------------------------------------------
  function bit [63:0] sext32(bit [31:0] x); return {{32{x[31]}}, x}; endfunction

  // rocket ALU: in1/in2 already selected by op1_sel/op2_sel
  function bit [63:0] alu(bit [4:0] fn, bit dw, bit [63:0] in1, bit [63:0] in2);
    bit [63:0] out;
    bit [5:0]  sh;
    sh = dw ? in2[5:0] : {1'b0, in2[4:0]};
    case (fn)
      FN_ADD : out = in1 + in2;
      FN_SUB : out = in1 - in2;
      FN_SL  : out = dw ? (in1 << sh) : (64'({32'b0, in1[31:0]}) << sh);
      FN_SR  : out = dw ? (in1 >> sh) : ({32'b0, in1[31:0]} >> sh);
      FN_SRA : out = dw ? ($signed(in1) >>> sh) : 64'($signed({{32{in1[31]}}, in1[31:0]}) >>> sh);
      FN_XOR : out = in1 ^ in2;
      FN_OR  : out = in1 | in2;
      FN_AND : out = in1 & in2;
      FN_SEQ : out = (in1 == in2);
      FN_SNE : out = (in1 != in2);
      FN_SLT : out = ($signed(in1) < $signed(in2));
      FN_SGE : out = ($signed(in1) >= $signed(in2));
      FN_SLTU: out = (in1 < in2);
      FN_SGEU: out = (in1 >= in2);
      default: out = '0;
    endcase
    return dw ? out : sext32(out[31:0]);
  endfunction

  function bit [63:0] muldiv(bit [4:0] fn, bit dw, bit [63:0] a, bit [63:0] b);
    bit [63:0]  r;
    bit [127:0] p;
    if (!dw) begin
      // W forms operate on the low 32 bits, sign/zero-extended per op, result sign-extended
      case (fn)
        FN_MUL : r = sext32(a[31:0] * b[31:0]);
        FN_DIV : r = (b[31:0] == 0) ? 64'hFFFF_FFFF_FFFF_FFFF :
                     (a[31:0] == 32'h8000_0000 && b[31:0] == 32'hFFFF_FFFF) ? sext32(32'h8000_0000) :
                     sext32(32'($signed(a[31:0]) / $signed(b[31:0])));
        FN_DIVU: r = (b[31:0] == 0) ? 64'hFFFF_FFFF_FFFF_FFFF : sext32(a[31:0] / b[31:0]);
        FN_REM : r = (b[31:0] == 0) ? sext32(a[31:0]) :
                     (a[31:0] == 32'h8000_0000 && b[31:0] == 32'hFFFF_FFFF) ? 64'h0 :
                     sext32(32'($signed(a[31:0]) % $signed(b[31:0])));
        FN_REMU: r = (b[31:0] == 0) ? sext32(a[31:0]) : sext32(a[31:0] % b[31:0]);
        default: r = '0;
      endcase
      return r;
    end
    case (fn)
      FN_MUL   : begin p = a * b; r = p[63:0]; end
      FN_MULH  : begin p = 128'($signed({{64{a[63]}}, a}) * $signed({{64{b[63]}}, b})); r = p[127:64]; end
      FN_MULHU : begin p = 128'(a) * 128'(b); r = p[127:64]; end
      FN_MULHSU: begin p = 128'($signed({{64{a[63]}}, a}) * $signed({64'b0, b})); r = p[127:64]; end
      FN_DIV   : r = (b == 0) ? 64'hFFFF_FFFF_FFFF_FFFF :
                     (a == 64'h8000_0000_0000_0000 && b == 64'hFFFF_FFFF_FFFF_FFFF) ? a :
                     64'($signed(a) / $signed(b));
      FN_DIVU  : r = (b == 0) ? 64'hFFFF_FFFF_FFFF_FFFF : a / b;
      FN_REM   : r = (b == 0) ? a :
                     (a == 64'h8000_0000_0000_0000 && b == 64'hFFFF_FFFF_FFFF_FFFF) ? 64'h0 :
                     64'($signed(a) % $signed(b));
      FN_REMU  : r = (b == 0) ? a : a % b;
      default  : r = '0;
    endcase
    return r;
  endfunction

  // encodeVirtualAddress for JALR targets (functional-unit.scala, vaddrBitsExtended=40, vaddrBits=39)
  function bit [39:0] encode_vaddr(bit [63:0] ea);
    bit [24:0] hi;
    bit        msb;
    hi  = ea[63:39];
    msb = (hi == 25'h0 || hi == 25'h1FF_FFFF) ? ea[39] : ~ea[38];
    return {msb, ea[38:0]};
  endfunction

  function void predict_int(boom_exe_txn t);
    bit [63:0] imm, op1, op2, pc64, alu_out;
    bit        br_eq, br_lt, br_ltu;
    bit [1:0]  pc_sel;
    bit [63:0] rs1 = t.rs1, rs2 = t.rs2;
    imm  = imm_gen(t.uop.imm_packed, t.ctrl.imm_sel);
    pc64 = {{24{t.pc[39]}}, t.pc};

    // operand muxes (ALUUnit)
    case (t.ctrl.op1_sel)
      OP1_RS1 : op1 = rs1;
      OP1_PC  : op1 = pc64;
      default : op1 = '0;
    endcase
    case (t.ctrl.op2_sel)
      OP2_RS2 : op2 = rs2;
      OP2_IMM : op2 = imm;
      OP2_IMMC: op2 = {59'b0, t.zimm};
      OP2_NEXT: op2 = t.is_rvc ? 64'd2 : 64'd4;
      default : op2 = '0;
    endcase

    if (t.ctrl.fu_code == FU_MUL || t.ctrl.fu_code == FU_DIV) begin
      t.exp_has_data = 1;
      t.exp_data = muldiv(t.ctrl.op_fcn, t.ctrl.fcn_dw, rs1, rs2);
      return;
    end

    alu_out = alu(t.ctrl.op_fcn, t.ctrl.fcn_dw, op1, op2);
    if (t.op == OP_MOV) alu_out = rs2;

    // branch resolution (ALUUnit) — compares raw rs1/rs2, not the ALU output
    br_eq  = (rs1 == rs2);
    br_ltu = (rs1 < rs2);
    br_lt  = ($signed(rs1) < $signed(rs2));
    case (t.ctrl.br_type)
      BR_N  : pc_sel = PC_PLUS4;
      BR_NE : pc_sel = !br_eq  ? PC_BRJMP : PC_PLUS4;
      BR_EQ : pc_sel =  br_eq  ? PC_BRJMP : PC_PLUS4;
      BR_GE : pc_sel = !br_lt  ? PC_BRJMP : PC_PLUS4;
      BR_GEU: pc_sel = !br_ltu ? PC_BRJMP : PC_PLUS4;
      BR_LT : pc_sel =  br_lt  ? PC_BRJMP : PC_PLUS4;
      BR_LTU: pc_sel =  br_ltu ? PC_BRJMP : PC_PLUS4;
      BR_J  : pc_sel = PC_BRJMP;
      BR_JR : pc_sel = PC_JALR;
      default: pc_sel = PC_PLUS4;
    endcase

    // the ALU pipeline responds for every uop it executes — including branches (dst_rtype = RT_X,
    // rf_wen is false downstream); the data is then the branch comparison's ALU result
    t.exp_has_data = (t.ctrl.dst_rtype == RT_FIX) || t.ctrl.is_br;
    t.exp_data     = alu_out;
    t.exp_pc_sel   = pc_sel;
    t.exp_taken    = (t.ctrl.is_br || t.ctrl.is_jal || t.ctrl.is_jalr) && (pc_sel != PC_PLUS4);
    t.exp_brinfo_valid = t.ctrl.is_br || t.ctrl.is_jalr;
    t.exp_cfi_type = t.ctrl.is_jalr ? CFI_JALR : (t.ctrl.is_br ? CFI_BR : CFI_X);
    t.exp_target_offset = imm[20:0];
    t.exp_mispredict = 0;
    if (t.ctrl.is_br) begin
      if (pc_sel == PC_PLUS4) t.exp_mispredict =  t.pred_taken;
      if (pc_sel == PC_BRJMP) t.exp_mispredict = !t.pred_taken;
    end
    if (t.ctrl.is_jalr) begin
      bit [63:0] tgt_x;
      bit [39:0] tgt;
      bit [1:0]  cfi_idx;
      bit [5:0]  lob_x;
      tgt_x = rs1 + {{43{imm[20]}}, imm[20:0]};
      tgt   = encode_vaddr(tgt_x) & ~40'h1;
      t.exp_jalr_target = tgt;
      lob_x   = t.uop.pc_lob ^ (t.ftq_start_bank ? 6'(BANK_BYTES) : 6'd0);
      cfi_idx = lob_x[2:1];          // (log2Ceil(fetchWidth), 1) with fetchWidth = 4 -> start_bank (bit 3) drops out
      t.exp_mispredict = !t.ftq_next_val || (t.ftq_next_pc != tgt) || !t.ftq_cfi_idx_valid || (t.ftq_cfi_idx != cfi_idx);
    end
  endfunction

  //---------------------------------------------------------------------------
  // floating-point side (DPI)
  //---------------------------------------------------------------------------
  function void predict_fp(boom_exe_txn t);
    int       fop, is_double, rm, typ, flags, rc;
    longint unsigned res;
    bit [63:0] a = t.rs1, b = t.rs2, c = t.rs3;
    is_double = !is_single_op(t.op);
    rm  = t.eff_rm();
    typ = cvt_typ_of(t.op);
    case (t.op)
      OP_FADD_S, OP_FADD_D:       fop = FPR_ADD;
      OP_FSUB_S, OP_FSUB_D:       fop = FPR_SUB;
      OP_FMUL_S, OP_FMUL_D:       fop = FPR_MUL;
      OP_FMADD_S, OP_FMADD_D:     fop = FPR_MADD;
      OP_FMSUB_S, OP_FMSUB_D:     fop = FPR_MSUB;
      OP_FNMADD_S, OP_FNMADD_D:   fop = FPR_NMADD;
      OP_FNMSUB_S, OP_FNMSUB_D:   fop = FPR_NMSUB;
      OP_FDIV_S, OP_FDIV_D:       fop = FPR_DIV;
      OP_FSQRT_S, OP_FSQRT_D:     fop = FPR_SQRT;
      OP_FSGNJ_S, OP_FSGNJ_D:     fop = FPR_SGNJ;
      OP_FSGNJN_S, OP_FSGNJN_D:   fop = FPR_SGNJN;
      OP_FSGNJX_S, OP_FSGNJX_D:   fop = FPR_SGNJX;
      OP_FMIN_S, OP_FMIN_D:       fop = FPR_MIN;
      OP_FMAX_S, OP_FMAX_D:       fop = FPR_MAX;
      OP_FCVT_S_D:                begin fop = FPR_CVT_S_D; is_double = 1; end // source is double
      OP_FCVT_D_S:                begin fop = FPR_CVT_D_S; is_double = 0; end // source is single
      OP_FEQ_S, OP_FEQ_D:         fop = FPR_EQ;
      OP_FLT_S, OP_FLT_D:         fop = FPR_LT;
      OP_FLE_S, OP_FLE_D:         fop = FPR_LE;
      OP_FCLASS_S, OP_FCLASS_D:   fop = FPR_CLASS;
      OP_FMV_X_W, OP_FMV_X_D:     fop = FPR_MV_X_F;
      OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S,
      OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D: fop = FPR_CVT_INT_F;
      OP_FMV_W_X, OP_FMV_D_X:     fop = FPR_MV_F_X;
      OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU,
      OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU: fop = FPR_CVT_F_INT;
      default: begin `uvm_error("REF", $sformatf("unsupported FP op %s", t.op.name())) return; end
    endcase
    rc = boom_fp_ref(fop, is_double, rm, typ, a, b, c, res, flags);
    if (rc != 0) `uvm_error("REF", $sformatf("boom_fp_ref rejected op %s", t.op.name()))
    t.exp_has_data    = 1;
    t.exp_data        = res;
    t.exp_flags       = flags[4:0];
    if (waive_fdiv_s_snan_nv && (t.op == OP_FDIV_S || t.op == OP_FSQRT_S)) begin
      bit snan_in = (fp_classify32(a) == FPC_SNAN) || (t.op == OP_FDIV_S && fp_classify32(b) == FPC_SNAN);
      if (snan_in) begin t.exp_flags[4] = 1'b0; t.waived_nv = 1; end   // W1: NV lost in the S->D up-conversion
    end
    // hardware reports fflags for every FPU/FDiv/I2F/F2I response (fflags.valid == resp.valid)
    t.exp_flags_valid = 1;
  endfunction

endclass : boom_exe_ref_model

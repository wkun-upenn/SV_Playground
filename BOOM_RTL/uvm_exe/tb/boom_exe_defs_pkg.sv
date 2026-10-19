//=============================================================================
// boom_exe_defs_pkg.sv
//-----------------------------------------------------------------------------
// Constants, encodings and pure helper functions shared by the whole BOOM
// execute-pipeline UVM environment.
//
// Every encoding below is transcribed from the BOOM v3 / rocket-chip Scala
// sources that generated the RTL under ../gen-collateral:
//   boom/v3/common/consts.scala                (uopc, OP1/OP2/IS/BR/RT codes)
//   boom/v3/exu/execution-units/functional-unit.scala (FU_* codes)
//   boom/v3/exu/register-read/func-unit-decode.scala  (uopc -> ctrl decode)
//   rocket-chip/rocket/ALU.scala                (FN_* codes)
//   rocket-chip/rocket/CSR.scala                (CSR cmd codes)
//   boom/v3/util/util.scala                     (ImmGen)
//   hardfloat/{recFNFromFN,fNFromRecFN}.scala, rocket-chip/tile/FPU.scala
//                                               (65-bit recoded FP + NaN boxing)
//=============================================================================
package boom_exe_defs_pkg;

  //---------------------------------------------------------------------------
  // Widths (MediumBoomV3Config)
  //---------------------------------------------------------------------------
  localparam int XLEN        = 64;
  localparam int DATA_W      = 65;   // regfile data is 65 bits (recoded FP)
  localparam int UOPC_W      = 7;
  localparam int FUC_W       = 10;
  localparam int BR_MASK_W   = 12;   // maxBrCount
  localparam int BR_TAG_W    = 4;
  localparam int ROB_IDX_W   = 6;    // 64-entry ROB
  localparam int PREG_W      = 7;    // 80 int / 64 fp physical regs
  localparam int FTQ_IDX_W   = 5;    // 32-entry FTQ
  localparam int LDQ_IDX_W   = 4;
  localparam int STQ_IDX_W   = 4;
  localparam int PC_LOB_W    = 6;
  localparam int VADDR_W     = 40;   // vaddrBitsExtended (Sv39 + 1)
  localparam int IMM_PACKED_W= 20;
  localparam int IC_BLOCK_BYTES = 64;
  localparam int FETCH_WIDTH = 4;
  localparam int BANK_BYTES  = 8;    // fetchBytes(16 = fetchWidth*4) / nBanks(2); XOR-ing 8 into pc_lob leaves cfi_idx = pc_lob[2:1]
  localparam int NUM_INT_PREGS = 80;
  localparam int NUM_FP_PREGS  = 64;

  // Pipeline latencies (boom/v3/common/parameters.scala)
  localparam int ALU0_STAGES = 3;    // alu_exe_unit  (has mul -> ALU padded to imulLatency)
  localparam int ALU1_STAGES = 1;    // alu_exe_unit_1 (csr + div)
  localparam int IMUL_LAT    = 3;
  localparam int I2F_LAT     = 2;
  localparam int FPU_LAT     = 4;    // dfmaLatency == sfmaLatency

  // Issue queue (int)
  localparam int IQ_INT_ENTRIES = 20;
  localparam int IQ_ISSUE_W     = 2;
  localparam int IQ_DISPATCH_W  = 2;
  localparam int IQ_WAKEUP_PORTS= 5;

  //---------------------------------------------------------------------------
  // Functional-unit codes (one-hot)
  //---------------------------------------------------------------------------
  localparam logic [FUC_W-1:0] FU_ALU = 10'd1;
  localparam logic [FUC_W-1:0] FU_JMP = 10'd2;
  localparam logic [FUC_W-1:0] FU_MEM = 10'd4;
  localparam logic [FUC_W-1:0] FU_MUL = 10'd8;
  localparam logic [FUC_W-1:0] FU_DIV = 10'd16;
  localparam logic [FUC_W-1:0] FU_CSR = 10'd32;
  localparam logic [FUC_W-1:0] FU_FPU = 10'd64;
  localparam logic [FUC_W-1:0] FU_FDV = 10'd128;
  localparam logic [FUC_W-1:0] FU_I2F = 10'd256;
  localparam logic [FUC_W-1:0] FU_F2I = 10'd512;

  //---------------------------------------------------------------------------
  // Micro-op codes (consts.scala)
  //---------------------------------------------------------------------------
  localparam logic [6:0]
    uopNOP=0, uopLD=1, uopSTA=2, uopSTD=3, uopLUI=4, uopADDI=5, uopANDI=6, uopORI=7,
    uopXORI=8, uopSLTI=9, uopSLTIU=10, uopSLLI=11, uopSRAI=12, uopSRLI=13, uopSLL=14,
    uopADD=15, uopSUB=16, uopSLT=17, uopSLTU=18, uopAND=19, uopOR=20, uopXOR=21,
    uopSRA=22, uopSRL=23, uopBEQ=24, uopBNE=25, uopBGE=26, uopBGEU=27, uopBLT=28,
    uopBLTU=29, uopCSRRW=30, uopCSRRS=31, uopCSRRC=32, uopCSRRWI=33, uopCSRRSI=34,
    uopCSRRCI=35, uopJ=36, uopJAL=37, uopJALR=38, uopAUIPC=39, uopCFLSH=41,
    uopFENCE=42, uopADDIW=43, uopADDW=44, uopSUBW=45, uopSLLIW=46, uopSLLW=47,
    uopSRAIW=48, uopSRAW=49, uopSRLIW=50, uopSRLW=51, uopMUL=52, uopMULH=53,
    uopMULHU=54, uopMULHSU=55, uopMULW=56, uopDIV=57, uopDIVU=58, uopREM=59,
    uopREMU=60, uopDIVW=61, uopDIVUW=62, uopREMW=63, uopREMUW=64, uopFENCEI=65,
    uopAMO_AG=67, uopFMV_W_X=68, uopFMV_D_X=69, uopFMV_X_W=70, uopFMV_X_D=71,
    uopFSGNJ_S=72, uopFSGNJ_D=73, uopFCVT_S_D=74, uopFCVT_D_S=75, uopFCVT_S_X=76,
    uopFCVT_D_X=77, uopFCVT_X_S=78, uopFCVT_X_D=79, uopCMPR_S=80, uopCMPR_D=81,
    uopFCLASS_S=82, uopFCLASS_D=83, uopFMINMAX_S=84, uopFMINMAX_D=85, uopFADD_S=87,
    uopFSUB_S=88, uopFMUL_S=89, uopFADD_D=90, uopFSUB_D=91, uopFMUL_D=92,
    uopFMADD_S=93, uopFMSUB_S=94, uopFNMADD_S=95, uopFNMSUB_S=96, uopFMADD_D=97,
    uopFMSUB_D=98, uopFNMADD_D=99, uopFNMSUB_D=100, uopFDIV_S=101, uopFDIV_D=102,
    uopFSQRT_S=103, uopFSQRT_D=104, uopWFI=105, uopERET=106, uopSFENCE=107,
    uopROCC=108, uopMOV=109;

  //---------------------------------------------------------------------------
  // Control encodings
  //---------------------------------------------------------------------------
  // rocket ALU function codes
  localparam logic [4:0] FN_ADD=0, FN_SL=1, FN_SEQ=2, FN_SNE=3, FN_XOR=4, FN_SR=5,
                         FN_OR=6, FN_AND=7, FN_SUB=10, FN_SRA=11, FN_SLT=12, FN_SGE=13,
                         FN_SLTU=14, FN_SGEU=15;
  localparam logic [4:0] FN_MUL=FN_ADD, FN_MULH=FN_SL, FN_MULHSU=FN_SEQ, FN_MULHU=FN_SNE,
                         FN_DIV=FN_XOR, FN_DIVU=FN_SR, FN_REM=FN_OR, FN_REMU=FN_AND;
  localparam logic [1:0] OP1_RS1=0, OP1_ZERO=1, OP1_PC=2;
  localparam logic [2:0] OP2_RS2=0, OP2_IMM=1, OP2_ZERO=2, OP2_NEXT=3, OP2_IMMC=4;
  localparam logic [2:0] IS_I=0, IS_S=1, IS_B=2, IS_U=3, IS_J=4;
  localparam logic [3:0] BR_N=0, BR_NE=1, BR_EQ=2, BR_GE=3, BR_GEU=4, BR_LT=5, BR_LTU=6,
                         BR_J=7, BR_JR=8;
  localparam logic [1:0] RT_FIX=0, RT_FLT=1, RT_X=2, RT_PAS=3;
  localparam logic       DW_32=0, DW_64=1;
  localparam logic [2:0] CSR_N=0, CSR_R=2, CSR_I=4, CSR_W=5, CSR_S=6, CSR_C=7;
  // CSR numbers a randomly generated CSR instruction may target when the CSRFile is in the loop
  localparam logic [11:0] CSR_SAFE_ADDRS[48] = '{
    12'h001, 12'h002, 12'h003,                                   // fflags frm fcsr
    12'h105, 12'h106, 12'h140, 12'h141, 12'h142, 12'h143,        // stvec scounteren sscratch sepc scause stval
    12'h302, 12'h303, 12'h304, 12'h305, 12'h306,                 // medeleg mideleg mie mtvec mcounteren
    12'h320, 12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328,
    12'h340, 12'h341, 12'h342, 12'h343, 12'h344,                 // mscratch mepc mcause mtval mip
    12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7,
    12'hB02, 12'hB03, 12'hB04, 12'hB05, 12'hB06, 12'hB07, 12'hB08,   // minstret mhpmcounter3..8
    12'hC00, 12'hC02, 12'hF11, 12'hF12, 12'hF13, 12'hF14, 12'h7C1 };  // read-only ones + chicken
  localparam logic [1:0] PC_PLUS4=0, PC_BRJMP=1, PC_JALR=2;
  localparam logic [2:0] CFI_X=0, CFI_BR=1, CFI_JAL=2, CFI_JALR=3;
  localparam logic [2:0] IQT_INT=1, IQT_MEM=2, IQT_FP=4;

  // RISC-V rounding modes
  localparam logic [2:0] RM_RNE=0, RM_RTZ=1, RM_RDN=2, RM_RUP=3, RM_RMM=4, RM_DYN=7;
  // fflags bit positions
  localparam int FF_NX=0, FF_UF=1, FF_OF=2, FF_DZ=3, FF_NV=4;

  //---------------------------------------------------------------------------
  // MicroOp structs generated from the RTL port lists (sim/gen_dut_glue.py)
  //---------------------------------------------------------------------------
  `include "boom_exe_uop_types.svh"

  //---------------------------------------------------------------------------
  // Which execution unit a transaction targets
  //---------------------------------------------------------------------------
  typedef enum int {
    EXU_ALU0 = 0,   // alu_exe_unit   : ALU + JMP + iMul + I2F   (ALUExeUnit_1.sv)
    EXU_ALU1 = 1,   // alu_exe_unit_1 : ALU + CSR + iDiv         (ALUExeUnit_2.sv)
    EXU_FPU  = 2    // fpu_exe_unit   : FMA + FDivSqrt + FPIU    (FPUExeUnit.sv)
  } exu_id_e;

  // Where a response is observed
  typedef enum int { PORT_NONE=0, PORT_IRESP=1, PORT_LL_IRESP=2, PORT_FRESP=3, PORT_LL_FRESP=4 } rsp_port_e;

  //---------------------------------------------------------------------------
  // Instruction-level operation enum used by sequences.
  // (One TB op == one RISC-V instruction; the driver lowers it to a uop.)
  //---------------------------------------------------------------------------
  typedef enum int {
    // RV64I ALU register/immediate
    OP_ADD, OP_SUB, OP_SLL, OP_SLT, OP_SLTU, OP_XOR, OP_SRL, OP_SRA, OP_OR, OP_AND,
    OP_ADDI, OP_SLTI, OP_SLTIU, OP_XORI, OP_ORI, OP_ANDI, OP_SLLI, OP_SRLI, OP_SRAI,
    OP_ADDW, OP_SUBW, OP_SLLW, OP_SRLW, OP_SRAW, OP_ADDIW, OP_SLLIW, OP_SRLIW, OP_SRAIW,
    OP_LUI, OP_AUIPC, OP_MOV,
    // branches / jumps
    OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU, OP_JAL, OP_JALR,
    // RV64M
    OP_MUL, OP_MULH, OP_MULHU, OP_MULHSU, OP_MULW,
    OP_DIV, OP_DIVU, OP_REM, OP_REMU, OP_DIVW, OP_DIVUW, OP_REMW, OP_REMUW,
    // Zicsr (data path through the CSR exe unit)
    OP_CSRRW, OP_CSRRS, OP_CSRRC, OP_CSRRWI, OP_CSRRSI, OP_CSRRCI,
    // RV64F/D arithmetic (FPU exe unit)
    OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S,
    OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D,
    OP_FDIV_S, OP_FSQRT_S, OP_FDIV_D, OP_FSQRT_D,
    OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S, OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D,
    OP_FMIN_S, OP_FMAX_S, OP_FMIN_D, OP_FMAX_D,
    OP_FCVT_S_D, OP_FCVT_D_S,
    // FP -> int (FPU exe unit, ll_iresp port)
    OP_FEQ_S, OP_FLT_S, OP_FLE_S, OP_FEQ_D, OP_FLT_D, OP_FLE_D,
    OP_FCLASS_S, OP_FCLASS_D, OP_FMV_X_W, OP_FMV_X_D,
    OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S,
    OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D,
    // int -> FP (ALU0 exe unit, ll_fresp port)
    OP_FMV_W_X, OP_FMV_D_X,
    OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU,
    OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU,
    OP_NUM
  } exe_op_e;

  //---------------------------------------------------------------------------
  // Register-read decode result (RRdCtrlSigs + the decode-stage fields we need)
  //---------------------------------------------------------------------------
  typedef struct packed {
    logic [6:0] uopc;
    logic [9:0] fu_code;
    logic [3:0] br_type;
    logic [1:0] op1_sel;
    logic [2:0] op2_sel;
    logic [2:0] imm_sel;
    logic [4:0] op_fcn;
    logic       fcn_dw;
    logic [2:0] csr_cmd;
    logic [1:0] dst_rtype;
    logic [1:0] lrs1_rtype;
    logic [1:0] lrs2_rtype;
    logic       frs3_en;
    logic       fp_val;
    logic       fp_single;
    logic       is_br;
    logic       is_jal;
    logic       is_jalr;
    logic       bypassable;
    exu_id_e    exu;         // which exe unit accepts this op
    rsp_port_e  rsp_port;    // where the result is expected
    int         latency;     // nominal cycles req -> resp (0 = iterative / unknown)
  } op_ctrl_t;

  // Returns the "instruction format" used to pack the immediate
  function automatic logic [2:0] imm_fmt_of(exe_op_e op);
    case (op)
      OP_LUI, OP_AUIPC:                         return IS_U;
      OP_JAL:                                    return IS_J;
      OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU: return IS_B;
      default:                                   return IS_I;
    endcase
  endfunction

  //---------------------------------------------------------------------------
  // decode_op: exe_op_e -> everything the driver needs to build a MicroOp.
  // Transcribed from AluRRdDecode / JmpRRdDecode / MulDivRRdDecode /
  // CsrRRdDecode / FpuRRdDecode / IfmvRRdDecode / FDivRRdDecode plus the
  // decode-stage table (fu_code, register types).
  //---------------------------------------------------------------------------
  function automatic op_ctrl_t decode_op(exe_op_e op);
    op_ctrl_t c;
    c = '0;
    c.br_type = BR_N; c.op1_sel = OP1_RS1; c.op2_sel = OP2_RS2; c.imm_sel = IS_I;
    c.op_fcn = FN_ADD; c.fcn_dw = DW_64; c.csr_cmd = CSR_N;
    c.dst_rtype = RT_FIX; c.lrs1_rtype = RT_FIX; c.lrs2_rtype = RT_FIX;
    c.fu_code = FU_ALU; c.exu = EXU_ALU0; c.rsp_port = PORT_IRESP; c.bypassable = 1;
    c.latency = ALU0_STAGES;
    case (op)
      // ---- ALU, register-register ----
      OP_ADD : begin c.uopc=uopADD;  c.op_fcn=FN_ADD;  end
      OP_SUB : begin c.uopc=uopSUB;  c.op_fcn=FN_SUB;  end
      OP_SLL : begin c.uopc=uopSLL;  c.op_fcn=FN_SL;   end
      OP_SLT : begin c.uopc=uopSLT;  c.op_fcn=FN_SLT;  end
      OP_SLTU: begin c.uopc=uopSLTU; c.op_fcn=FN_SLTU; end
      OP_XOR : begin c.uopc=uopXOR;  c.op_fcn=FN_XOR;  end
      OP_SRL : begin c.uopc=uopSRL;  c.op_fcn=FN_SR;   end
      OP_SRA : begin c.uopc=uopSRA;  c.op_fcn=FN_SRA;  end
      OP_OR  : begin c.uopc=uopOR;   c.op_fcn=FN_OR;   end
      OP_AND : begin c.uopc=uopAND;  c.op_fcn=FN_AND;  end
      OP_MOV : begin c.uopc=uopMOV;  c.op_fcn=FN_ADD;  c.op1_sel=OP1_ZERO; end
      // ---- ALU, immediate ----
      OP_ADDI : begin c.uopc=uopADDI;  c.op_fcn=FN_ADD;  c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SLTI : begin c.uopc=uopSLTI;  c.op_fcn=FN_SLT;  c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SLTIU: begin c.uopc=uopSLTIU; c.op_fcn=FN_SLTU; c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_XORI : begin c.uopc=uopXORI;  c.op_fcn=FN_XOR;  c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_ORI  : begin c.uopc=uopORI;   c.op_fcn=FN_OR;   c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_ANDI : begin c.uopc=uopANDI;  c.op_fcn=FN_AND;  c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SLLI : begin c.uopc=uopSLLI;  c.op_fcn=FN_SL;   c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SRLI : begin c.uopc=uopSRLI;  c.op_fcn=FN_SR;   c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SRAI : begin c.uopc=uopSRAI;  c.op_fcn=FN_SRA;  c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_LUI  : begin c.uopc=uopLUI;   c.op_fcn=FN_ADD;  c.op1_sel=OP1_ZERO; c.op2_sel=OP2_IMM; c.imm_sel=IS_U; c.lrs1_rtype=RT_X; c.lrs2_rtype=RT_X; end
      // ---- RV64I W variants ----
      OP_ADDW : begin c.uopc=uopADDW;  c.op_fcn=FN_ADD; c.fcn_dw=DW_32; end
      OP_SUBW : begin c.uopc=uopSUBW;  c.op_fcn=FN_SUB; c.fcn_dw=DW_32; end
      OP_SLLW : begin c.uopc=uopSLLW;  c.op_fcn=FN_SL;  c.fcn_dw=DW_32; end
      OP_SRLW : begin c.uopc=uopSRLW;  c.op_fcn=FN_SR;  c.fcn_dw=DW_32; end
      OP_SRAW : begin c.uopc=uopSRAW;  c.op_fcn=FN_SRA; c.fcn_dw=DW_32; end
      OP_ADDIW: begin c.uopc=uopADDIW; c.op_fcn=FN_ADD; c.fcn_dw=DW_32; c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SLLIW: begin c.uopc=uopSLLIW; c.op_fcn=FN_SL;  c.fcn_dw=DW_32; c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SRLIW: begin c.uopc=uopSRLIW; c.op_fcn=FN_SR;  c.fcn_dw=DW_32; c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      OP_SRAIW: begin c.uopc=uopSRAIW; c.op_fcn=FN_SRA; c.fcn_dw=DW_32; c.op2_sel=OP2_IMM; c.lrs2_rtype=RT_X; end
      // ---- branches (ALU unit, no writeback) ----
      OP_BEQ : begin c.uopc=uopBEQ;  c.br_type=BR_EQ;  c.op_fcn=FN_SUB;  c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      OP_BNE : begin c.uopc=uopBNE;  c.br_type=BR_NE;  c.op_fcn=FN_SUB;  c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      OP_BGE : begin c.uopc=uopBGE;  c.br_type=BR_GE;  c.op_fcn=FN_SLT;  c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      OP_BGEU: begin c.uopc=uopBGEU; c.br_type=BR_GEU; c.op_fcn=FN_SLTU; c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      OP_BLT : begin c.uopc=uopBLT;  c.br_type=BR_LT;  c.op_fcn=FN_SLT;  c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      OP_BLTU: begin c.uopc=uopBLTU; c.br_type=BR_LTU; c.op_fcn=FN_SLTU; c.imm_sel=IS_B; c.dst_rtype=RT_X; c.is_br=1; c.bypassable=0; end
      // ---- jumps (JMP unit == alu_exe_unit with hasJmpUnit) ----
      OP_JAL  : begin c.uopc=uopJAL;   c.fu_code=FU_JMP; c.br_type=BR_J;  c.op1_sel=OP1_PC; c.op2_sel=OP2_NEXT; c.imm_sel=IS_J; c.lrs1_rtype=RT_X; c.lrs2_rtype=RT_X; c.is_jal=1;  c.bypassable=0; end
      OP_JALR : begin c.uopc=uopJALR;  c.fu_code=FU_JMP; c.br_type=BR_JR; c.op1_sel=OP1_PC; c.op2_sel=OP2_NEXT; c.imm_sel=IS_I; c.lrs2_rtype=RT_X; c.is_jalr=1; c.bypassable=0; end
      OP_AUIPC: begin c.uopc=uopAUIPC; c.fu_code=FU_JMP; c.br_type=BR_N;  c.op1_sel=OP1_PC; c.op2_sel=OP2_IMM;  c.imm_sel=IS_U; c.lrs1_rtype=RT_X; c.lrs2_rtype=RT_X; c.bypassable=0; end
      // ---- multiply (ALU0, pipelined, 3 cycles) ----
      OP_MUL   : begin c.uopc=uopMUL;    c.fu_code=FU_MUL; c.op_fcn=FN_MUL;    c.bypassable=0; c.latency=IMUL_LAT; end
      OP_MULH  : begin c.uopc=uopMULH;   c.fu_code=FU_MUL; c.op_fcn=FN_MULH;   c.bypassable=0; c.latency=IMUL_LAT; end
      OP_MULHU : begin c.uopc=uopMULHU;  c.fu_code=FU_MUL; c.op_fcn=FN_MULHU;  c.bypassable=0; c.latency=IMUL_LAT; end
      OP_MULHSU: begin c.uopc=uopMULHSU; c.fu_code=FU_MUL; c.op_fcn=FN_MULHSU; c.bypassable=0; c.latency=IMUL_LAT; end
      OP_MULW  : begin c.uopc=uopMULW;   c.fu_code=FU_MUL; c.op_fcn=FN_MUL; c.fcn_dw=DW_32; c.bypassable=0; c.latency=IMUL_LAT; end
      // ---- divide (ALU1, iterative) ----
      OP_DIV  : begin c.uopc=uopDIV;   c.fu_code=FU_DIV; c.op_fcn=FN_DIV;  c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_DIVU : begin c.uopc=uopDIVU;  c.fu_code=FU_DIV; c.op_fcn=FN_DIVU; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_REM  : begin c.uopc=uopREM;   c.fu_code=FU_DIV; c.op_fcn=FN_REM;  c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_REMU : begin c.uopc=uopREMU;  c.fu_code=FU_DIV; c.op_fcn=FN_REMU; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_DIVW : begin c.uopc=uopDIVW;  c.fu_code=FU_DIV; c.op_fcn=FN_DIV;  c.fcn_dw=DW_32; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_DIVUW: begin c.uopc=uopDIVUW; c.fu_code=FU_DIV; c.op_fcn=FN_DIVU; c.fcn_dw=DW_32; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_REMW : begin c.uopc=uopREMW;  c.fu_code=FU_DIV; c.op_fcn=FN_REM;  c.fcn_dw=DW_32; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      OP_REMUW: begin c.uopc=uopREMUW; c.fu_code=FU_DIV; c.op_fcn=FN_REMU; c.fcn_dw=DW_32; c.exu=EXU_ALU1; c.bypassable=0; c.latency=0; end
      // ---- CSR data path (ALU1). ALU passes rs1 / zimm through with FN_ADD ----
      OP_CSRRW : begin c.uopc=uopCSRRW;  c.fu_code=FU_CSR; c.csr_cmd=CSR_W; c.op2_sel=OP2_ZERO; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      OP_CSRRS : begin c.uopc=uopCSRRS;  c.fu_code=FU_CSR; c.csr_cmd=CSR_S; c.op2_sel=OP2_ZERO; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      OP_CSRRC : begin c.uopc=uopCSRRC;  c.fu_code=FU_CSR; c.csr_cmd=CSR_C; c.op2_sel=OP2_ZERO; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      OP_CSRRWI: begin c.uopc=uopCSRRWI; c.fu_code=FU_CSR; c.csr_cmd=CSR_W; c.op1_sel=OP1_ZERO; c.op2_sel=OP2_IMMC; c.lrs1_rtype=RT_PAS; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      OP_CSRRSI: begin c.uopc=uopCSRRSI; c.fu_code=FU_CSR; c.csr_cmd=CSR_S; c.op1_sel=OP1_ZERO; c.op2_sel=OP2_IMMC; c.lrs1_rtype=RT_PAS; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      OP_CSRRCI: begin c.uopc=uopCSRRCI; c.fu_code=FU_CSR; c.csr_cmd=CSR_C; c.op1_sel=OP1_ZERO; c.op2_sel=OP2_IMMC; c.lrs1_rtype=RT_PAS; c.lrs2_rtype=RT_X; c.exu=EXU_ALU1; c.bypassable=0; c.latency=ALU1_STAGES; end
      // ---- FPU arithmetic (fresp) ----
      OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S,
      OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D,
      OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S, OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D,
      OP_FMIN_S, OP_FMAX_S, OP_FMIN_D, OP_FMAX_D, OP_FCVT_S_D, OP_FCVT_D_S: begin
        c.fu_code=FU_FPU; c.exu=EXU_FPU; c.rsp_port=PORT_FRESP; c.bypassable=0; c.latency=FPU_LAT;
        c.dst_rtype=RT_FLT; c.lrs1_rtype=RT_FLT; c.lrs2_rtype=RT_FLT; c.fp_val=1;
        case (op)
          OP_FADD_S: c.uopc=uopFADD_S;   OP_FSUB_S: c.uopc=uopFSUB_S;   OP_FMUL_S: c.uopc=uopFMUL_S;
          OP_FMADD_S: begin c.uopc=uopFMADD_S; c.frs3_en=1; end   OP_FMSUB_S: begin c.uopc=uopFMSUB_S; c.frs3_en=1; end
          OP_FNMADD_S: begin c.uopc=uopFNMADD_S; c.frs3_en=1; end OP_FNMSUB_S: begin c.uopc=uopFNMSUB_S; c.frs3_en=1; end
          OP_FADD_D: c.uopc=uopFADD_D;   OP_FSUB_D: c.uopc=uopFSUB_D;   OP_FMUL_D: c.uopc=uopFMUL_D;
          OP_FMADD_D: begin c.uopc=uopFMADD_D; c.frs3_en=1; end   OP_FMSUB_D: begin c.uopc=uopFMSUB_D; c.frs3_en=1; end
          OP_FNMADD_D: begin c.uopc=uopFNMADD_D; c.frs3_en=1; end OP_FNMSUB_D: begin c.uopc=uopFNMSUB_D; c.frs3_en=1; end
          OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S: c.uopc=uopFSGNJ_S;
          OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D: c.uopc=uopFSGNJ_D;
          OP_FMIN_S, OP_FMAX_S: c.uopc=uopFMINMAX_S;
          OP_FMIN_D, OP_FMAX_D: c.uopc=uopFMINMAX_D;
          OP_FCVT_S_D: begin c.uopc=uopFCVT_S_D; c.lrs2_rtype=RT_X; end
          OP_FCVT_D_S: begin c.uopc=uopFCVT_D_S; c.lrs2_rtype=RT_X; end
          default: ;
        endcase
        c.fp_single = is_single_op(op);
      end
      // ---- FDiv / FSqrt (fresp, iterative) ----
      OP_FDIV_S, OP_FSQRT_S, OP_FDIV_D, OP_FSQRT_D: begin
        c.fu_code=FU_FDV; c.exu=EXU_FPU; c.rsp_port=PORT_FRESP; c.bypassable=0; c.latency=0;
        c.dst_rtype=RT_FLT; c.lrs1_rtype=RT_FLT; c.lrs2_rtype=RT_FLT; c.fp_val=1;
        case (op)
          OP_FDIV_S : c.uopc=uopFDIV_S;   OP_FDIV_D : c.uopc=uopFDIV_D;
          OP_FSQRT_S: begin c.uopc=uopFSQRT_S; c.lrs2_rtype=RT_X; end
          OP_FSQRT_D: begin c.uopc=uopFSQRT_D; c.lrs2_rtype=RT_X; end
          default: ;
        endcase
        c.fp_single = is_single_op(op);
      end
      // ---- FP -> int (FPU exe unit, ll_iresp) ----
      OP_FEQ_S, OP_FLT_S, OP_FLE_S, OP_FEQ_D, OP_FLT_D, OP_FLE_D, OP_FCLASS_S, OP_FCLASS_D,
      OP_FMV_X_W, OP_FMV_X_D, OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S,
      OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D: begin
        c.fu_code=FU_F2I; c.exu=EXU_FPU; c.rsp_port=PORT_LL_IRESP; c.bypassable=0; c.latency=FPU_LAT;
        c.dst_rtype=RT_FIX; c.lrs1_rtype=RT_FLT; c.lrs2_rtype=RT_X; c.fp_val=1;
        case (op)
          OP_FEQ_S, OP_FLT_S, OP_FLE_S: begin c.uopc=uopCMPR_S; c.lrs2_rtype=RT_FLT; end
          OP_FEQ_D, OP_FLT_D, OP_FLE_D: begin c.uopc=uopCMPR_D; c.lrs2_rtype=RT_FLT; end
          OP_FCLASS_S: c.uopc=uopFCLASS_S;  OP_FCLASS_D: c.uopc=uopFCLASS_D;
          OP_FMV_X_W : c.uopc=uopFMV_X_W;   OP_FMV_X_D : c.uopc=uopFMV_X_D;
          OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S: c.uopc=uopFCVT_X_S;
          OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D: c.uopc=uopFCVT_X_D;
          default: ;
        endcase
        c.fp_single = is_single_op(op);
      end
      // ---- int -> FP (ALU0 exe unit, ll_fresp) ----
      OP_FMV_W_X, OP_FMV_D_X, OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU,
      OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU: begin
        c.fu_code=FU_I2F; c.exu=EXU_ALU0; c.rsp_port=PORT_LL_FRESP; c.bypassable=0; c.latency=I2F_LAT;
        c.dst_rtype=RT_FLT; c.lrs1_rtype=RT_FIX; c.lrs2_rtype=RT_X; c.fp_val=1;
        case (op)
          OP_FMV_W_X: c.uopc=uopFMV_W_X;   OP_FMV_D_X: c.uopc=uopFMV_D_X;
          OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU: c.uopc=uopFCVT_S_X;
          OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU: c.uopc=uopFCVT_D_X;
          default: ;
        endcase
        c.fp_single = is_single_op(op);
      end
      default: c.uopc = uopNOP;
    endcase
    return c;
  endfunction

  function automatic bit is_single_op(exe_op_e op);
    case (op)
      OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S,
      OP_FDIV_S, OP_FSQRT_S, OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S, OP_FMIN_S, OP_FMAX_S,
      OP_FCVT_S_D, OP_FEQ_S, OP_FLT_S, OP_FLE_S, OP_FCLASS_S, OP_FMV_X_W,
      OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S,
      OP_FMV_W_X, OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU: return 1;
      default: return 0;
    endcase
  endfunction

  function automatic bit is_fp_op(exe_op_e op);
    return (op >= OP_FADD_S);
  endfunction

  // rm field (inst[14:12]) implied by the op for ops that encode a sub-function in rm
  function automatic logic [2:0] fixed_rm_of(exe_op_e op);
    case (op)
      OP_FSGNJ_S, OP_FSGNJ_D:   return 3'd0;
      OP_FSGNJN_S, OP_FSGNJN_D: return 3'd1;
      OP_FSGNJX_S, OP_FSGNJX_D: return 3'd2;
      OP_FMIN_S, OP_FMIN_D:     return 3'd0;
      OP_FMAX_S, OP_FMAX_D:     return 3'd1;
      OP_FLE_S, OP_FLE_D:       return 3'd0;
      OP_FLT_S, OP_FLT_D:       return 3'd1;
      OP_FEQ_S, OP_FEQ_D:       return 3'd2;
      OP_FCLASS_S, OP_FCLASS_D: return 3'd1;
      OP_FMV_X_W, OP_FMV_X_D, OP_FMV_W_X, OP_FMV_D_X: return 3'd0;
      default:                  return 3'd7; // "use the transaction's rm"
    endcase
  endfunction

  // conversion type field inst[21:20]: 00 W, 01 WU, 10 L, 11 LU
  function automatic logic [1:0] cvt_typ_of(exe_op_e op);
    case (op)
      OP_FCVT_W_S, OP_FCVT_W_D, OP_FCVT_S_W, OP_FCVT_D_W:     return 2'b00;
      OP_FCVT_WU_S, OP_FCVT_WU_D, OP_FCVT_S_WU, OP_FCVT_D_WU: return 2'b01;
      OP_FCVT_L_S, OP_FCVT_L_D, OP_FCVT_S_L, OP_FCVT_D_L:     return 2'b10;
      OP_FCVT_LU_S, OP_FCVT_LU_D, OP_FCVT_S_LU, OP_FCVT_D_LU: return 2'b11;
      default: return 2'b00;
    endcase
  endfunction

  // ops whose result depends on rounding mode (RM_DYN legal)
  function automatic bit uses_rm(exe_op_e op);
    case (op)
      OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FMADD_S, OP_FMSUB_S, OP_FNMADD_S, OP_FNMSUB_S,
      OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FMADD_D, OP_FMSUB_D, OP_FNMADD_D, OP_FNMSUB_D,
      OP_FDIV_S, OP_FSQRT_S, OP_FDIV_D, OP_FSQRT_D, OP_FCVT_S_D,
      OP_FCVT_W_S, OP_FCVT_WU_S, OP_FCVT_L_S, OP_FCVT_LU_S,
      OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_L_D, OP_FCVT_LU_D,
      OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU,
      OP_FCVT_D_W, OP_FCVT_D_WU, OP_FCVT_D_L, OP_FCVT_D_LU: return 1;
      default: return 0;
    endcase
  endfunction

  //---------------------------------------------------------------------------
  // Reverse decode: MicroOp -> exe_op_e (used by the monitor so that the
  // scoreboard and coverage never depend on the driver's view)
  //---------------------------------------------------------------------------
  function automatic exe_op_e op_from_uop(uop_t u);
    logic [2:0] rm  = u.imm_packed[2:0];
    logic [1:0] typ = u.imm_packed[9:8];
    case (u.uopc)
      uopADD: return OP_ADD;   uopSUB: return OP_SUB;   uopSLL: return OP_SLL;   uopSLT: return OP_SLT;
      uopSLTU: return OP_SLTU; uopXOR: return OP_XOR;   uopSRL: return OP_SRL;   uopSRA: return OP_SRA;
      uopOR: return OP_OR;     uopAND: return OP_AND;   uopMOV: return OP_MOV;
      uopADDI: return OP_ADDI; uopSLTI: return OP_SLTI; uopSLTIU: return OP_SLTIU; uopXORI: return OP_XORI;
      uopORI: return OP_ORI;   uopANDI: return OP_ANDI; uopSLLI: return OP_SLLI; uopSRLI: return OP_SRLI;
      uopSRAI: return OP_SRAI; uopLUI: return OP_LUI;   uopAUIPC: return OP_AUIPC;
      uopADDW: return OP_ADDW; uopSUBW: return OP_SUBW; uopSLLW: return OP_SLLW; uopSRLW: return OP_SRLW;
      uopSRAW: return OP_SRAW; uopADDIW: return OP_ADDIW; uopSLLIW: return OP_SLLIW; uopSRLIW: return OP_SRLIW;
      uopSRAIW: return OP_SRAIW;
      uopBEQ: return OP_BEQ;   uopBNE: return OP_BNE;   uopBLT: return OP_BLT;   uopBGE: return OP_BGE;
      uopBLTU: return OP_BLTU; uopBGEU: return OP_BGEU; uopJAL: return OP_JAL;   uopJALR: return OP_JALR;
      uopMUL: return OP_MUL;   uopMULH: return OP_MULH; uopMULHU: return OP_MULHU; uopMULHSU: return OP_MULHSU;
      uopMULW: return OP_MULW; uopDIV: return OP_DIV;   uopDIVU: return OP_DIVU; uopREM: return OP_REM;
      uopREMU: return OP_REMU; uopDIVW: return OP_DIVW; uopDIVUW: return OP_DIVUW; uopREMW: return OP_REMW;
      uopREMUW: return OP_REMUW;
      uopCSRRW: return OP_CSRRW; uopCSRRS: return OP_CSRRS; uopCSRRC: return OP_CSRRC;
      uopCSRRWI: return OP_CSRRWI; uopCSRRSI: return OP_CSRRSI; uopCSRRCI: return OP_CSRRCI;
      uopFADD_S: return OP_FADD_S; uopFSUB_S: return OP_FSUB_S; uopFMUL_S: return OP_FMUL_S;
      uopFMADD_S: return OP_FMADD_S; uopFMSUB_S: return OP_FMSUB_S; uopFNMADD_S: return OP_FNMADD_S; uopFNMSUB_S: return OP_FNMSUB_S;
      uopFADD_D: return OP_FADD_D; uopFSUB_D: return OP_FSUB_D; uopFMUL_D: return OP_FMUL_D;
      uopFMADD_D: return OP_FMADD_D; uopFMSUB_D: return OP_FMSUB_D; uopFNMADD_D: return OP_FNMADD_D; uopFNMSUB_D: return OP_FNMSUB_D;
      uopFDIV_S: return OP_FDIV_S; uopFSQRT_S: return OP_FSQRT_S; uopFDIV_D: return OP_FDIV_D; uopFSQRT_D: return OP_FSQRT_D;
      uopFSGNJ_S: return (rm == 1) ? OP_FSGNJN_S : (rm == 2) ? OP_FSGNJX_S : OP_FSGNJ_S;
      uopFSGNJ_D: return (rm == 1) ? OP_FSGNJN_D : (rm == 2) ? OP_FSGNJX_D : OP_FSGNJ_D;
      uopFMINMAX_S: return rm[0] ? OP_FMAX_S : OP_FMIN_S;
      uopFMINMAX_D: return rm[0] ? OP_FMAX_D : OP_FMIN_D;
      uopFCVT_S_D: return OP_FCVT_S_D; uopFCVT_D_S: return OP_FCVT_D_S;
      uopCMPR_S: return (rm == 2) ? OP_FEQ_S : (rm == 1) ? OP_FLT_S : OP_FLE_S;
      uopCMPR_D: return (rm == 2) ? OP_FEQ_D : (rm == 1) ? OP_FLT_D : OP_FLE_D;
      uopFCLASS_S: return OP_FCLASS_S; uopFCLASS_D: return OP_FCLASS_D;
      uopFMV_X_W: return OP_FMV_X_W; uopFMV_X_D: return OP_FMV_X_D;
      uopFCVT_X_S: return (typ == 0) ? OP_FCVT_W_S : (typ == 1) ? OP_FCVT_WU_S : (typ == 2) ? OP_FCVT_L_S : OP_FCVT_LU_S;
      uopFCVT_X_D: return (typ == 0) ? OP_FCVT_W_D : (typ == 1) ? OP_FCVT_WU_D : (typ == 2) ? OP_FCVT_L_D : OP_FCVT_LU_D;
      uopFMV_W_X: return OP_FMV_W_X; uopFMV_D_X: return OP_FMV_D_X;
      uopFCVT_S_X: return (typ == 0) ? OP_FCVT_S_W : (typ == 1) ? OP_FCVT_S_WU : (typ == 2) ? OP_FCVT_S_L : OP_FCVT_S_LU;
      uopFCVT_D_X: return (typ == 0) ? OP_FCVT_D_W : (typ == 1) ? OP_FCVT_D_WU : (typ == 2) ? OP_FCVT_D_L : OP_FCVT_D_LU;
      default: return OP_NUM;
    endcase
  endfunction

  // Control view taken from the MicroOp itself (what the RTL will really do)
  function automatic op_ctrl_t ctrl_from_uop(uop_t u, exu_id_e unit);
    op_ctrl_t c;
    c = '0;
    c.uopc = u.uopc; c.fu_code = u.fu_code; c.br_type = u.ctrl_br_type;
    c.op1_sel = u.ctrl_op1_sel; c.op2_sel = u.ctrl_op2_sel; c.imm_sel = u.ctrl_imm_sel;
    c.op_fcn = u.ctrl_op_fcn; c.fcn_dw = u.ctrl_fcn_dw; c.csr_cmd = u.ctrl_csr_cmd;
    c.dst_rtype = u.dst_rtype; c.lrs1_rtype = u.lrs1_rtype; c.lrs2_rtype = u.lrs2_rtype;
    c.frs3_en = u.frs3_en; c.fp_val = u.fp_val; c.fp_single = u.fp_single;
    c.is_br = u.is_br; c.is_jal = u.is_jal; c.is_jalr = u.is_jalr; c.bypassable = u.bypassable;
    c.exu = unit;
    case (u.fu_code)
      FU_FPU, FU_FDV: c.rsp_port = PORT_FRESP;
      FU_F2I:         c.rsp_port = PORT_LL_IRESP;
      FU_I2F:         c.rsp_port = PORT_LL_FRESP;
      default:        c.rsp_port = PORT_IRESP;
    endcase
    case (u.fu_code)
      FU_ALU, FU_JMP: c.latency = (unit == EXU_ALU0) ? ALU0_STAGES : ALU1_STAGES;
      FU_CSR:         c.latency = ALU1_STAGES;
      FU_MUL:         c.latency = IMUL_LAT;
      FU_FPU, FU_F2I: c.latency = FPU_LAT;
      FU_I2F:         c.latency = I2F_LAT;
      default:        c.latency = 0;   // iterative: DIV / FDV
    endcase
    return c;
  endfunction

  // Clock period of tb_top — used to derive a cycle number without hierarchical refs
  localparam time CLK_PERIOD = 10ns;
  function automatic int cur_cycle(); return int'($time / CLK_PERIOD); endfunction

  //---------------------------------------------------------------------------
  // Immediate packing / generation (decode.scala:584 + util.scala ImmGen)
  //   imm_packed = Cat(inst(31,25), di24_20, inst(19,12))
  //   di24_20    = (IS_B || IS_S) ? inst(11,7) : inst(24,20)
  //---------------------------------------------------------------------------
  // Build imm_packed from an immediate *value* of the given format.
  //   IS_I : imm[11:0]      IS_S : imm[11:0]    IS_B : imm[12:0] (bit0 ignored)
  //   IS_U : imm[31:12]     IS_J : imm[20:0]    (bit0 ignored)
  // The low byte (inst[19:12]) is used by FP ops for rm/typ; pass it in 'low8'.
  function automatic logic [IMM_PACKED_W-1:0] pack_imm(logic [2:0] fmt, logic [31:0] imm, logic [7:0] low8 = 8'h00);
    logic [31:0] inst;
    logic [4:0]  di24_20;
    inst = '0;
    case (fmt)
      IS_I: inst[31:20] = imm[11:0];
      IS_S: begin inst[31:25] = imm[11:5]; inst[11:7] = imm[4:0]; end
      IS_B: begin inst[31] = imm[12]; inst[30:25] = imm[10:5]; inst[11:8] = imm[4:1]; inst[7] = imm[11]; end
      IS_U: inst[31:12] = imm[31:12];
      IS_J: begin inst[31] = imm[20]; inst[30:21] = imm[10:1]; inst[20] = imm[11]; inst[19:12] = imm[19:12]; end
      default: ;
    endcase
    di24_20 = (fmt == IS_B || fmt == IS_S) ? inst[11:7] : inst[24:20];
    return {inst[31:25], di24_20, (inst[19:12] | low8)};
  endfunction

  // ImmGen: sign-extended immediate the ALU sees (util.scala:269)
  function automatic logic [XLEN-1:0] imm_gen(logic [IMM_PACKED_W-1:0] ip, logic [2:0] isel);
    logic        sign;
    logic [10:0] i30_20;
    logic [7:0]  i19_12;
    logic        i11;
    logic [4:0]  i10_5;
    logic [4:0]  i4_1;
    logic        i0;
    logic [31:0] imm32;
    sign   = ip[19];
    i30_20 = (isel == IS_U) ? ip[18:8] : {11{sign}};
    i19_12 = (isel == IS_U || isel == IS_J) ? ip[7:0] : {8{sign}};
    i11    = (isel == IS_U) ? 1'b0 : ((isel == IS_J || isel == IS_B) ? ip[8] : sign);
    i10_5  = (isel == IS_U) ? 5'b0 : ip[18:14];
    i4_1   = (isel == IS_U) ? 5'b0 : ip[13:9];
    i0     = (isel == IS_S || isel == IS_I) ? ip[8] : 1'b0;
    imm32  = {sign, i30_20, i19_12, i11, i10_5, i4_1, i0};
    return {{32{imm32[31]}}, imm32};
  endfunction

  //---------------------------------------------------------------------------
  // hardfloat recoded format helpers
  //---------------------------------------------------------------------------
  function automatic int clz_n(logic [63:0] v, int width);
    for (int i = width-1; i >= 0; i--) if (v[i]) return (width-1-i);
    return width-1; // hardfloat PriorityEncoder of all-zero returns width-1
  endfunction

  // recFNFromFN(E,S): IEEE (E+S bits) -> recoded (E+S+1 bits)
  function automatic logic [64:0] recfn_from_fn(int E, int S, logic [63:0] in);
    logic        sign;
    logic [11:0] expIn;         // E bits (max 11)
    logic [63:0] fractIn;       // S-1 bits
    logic        isZeroExpIn, isZeroFractIn, isZero, isSpecial, isNaN;
    int          normDist;
    logic [63:0] subnormFract;
    logic [12:0] adjustedExp;   // E+1 bits (max 12)
    logic [12:0] mask;
    logic [2:0]  top3;
    logic [64:0] out;
    sign          = in[E+S-1];
    expIn         = (in >> (S-1)) & ((64'd1 << E) - 1);
    fractIn       = in & ((64'd1 << (S-1)) - 1);
    isZeroExpIn   = (expIn == 0);
    isZeroFractIn = (fractIn == 0);
    normDist      = clz_n(fractIn, S-1);
    subnormFract  = ((fractIn << normDist) & ((64'd1 << (S-2)) - 1)) << 1;
    mask          = (13'd1 << (E+1)) - 1;
    adjustedExp   = ((isZeroExpIn ? (13'(normDist) ^ mask) : 13'(expIn)) +
                     ((13'd1 << (E-1)) | (isZeroExpIn ? 13'd2 : 13'd1))) & mask;
    isZero        = isZeroExpIn && isZeroFractIn;
    isSpecial     = (adjustedExp[E -: 2] == 2'b11);
    isNaN         = isSpecial && !isZeroFractIn;
    top3          = (isZero ? 3'b000 : adjustedExp[E -: 3]) | {2'b00, isNaN};
    out           = '0;
    out           = (65'(sign) << (E+S)) |
                    (65'(top3) << (E+S-3)) |
                    (65'(adjustedExp & ((13'd1 << (E-2)) - 1)) << (S-1)) |
                    65'(isZeroExpIn ? subnormFract : fractIn);
    return out;
  endfunction

  // fNFromRecFN(E,S): recoded (E+S+1 bits) -> IEEE (E+S bits)
  function automatic logic [63:0] fn_from_recfn(int E, int S, logic [64:0] in);
    logic [12:0] exp;           // E+1 bits
    logic        isZero, isSpecial, isNaN, isInf, sign, isSubnormal;
    logic [64:0] sig;           // S+1 bits
    int          minNormExp, k;
    logic [7:0]  denormShiftDist;
    logic [63:0] denormFract, expOut, fractOut;
    exp        = (in >> (S-1)) & ((13'd1 << (E+1)) - 1);
    isZero     = (exp[E -: 3] == 3'b000);
    isSpecial  = (exp[E -: 2] == 2'b11);
    isNaN      = isSpecial &&  exp[E-2];
    isInf      = isSpecial && !exp[E-2];
    sign       = in[E+S];
    sig        = (65'(!isZero) << (S-1)) | (in & ((65'd1 << (S-1)) - 1));
    minNormExp = (1 << (E-1)) + 2;
    isSubnormal= (exp < minNormExp);
    k          = (S == 53) ? 6 : 5;                        // log2Up(S-1)
    denormShiftDist = (8'd1 - 8'(exp & ((13'd1 << k) - 1))) & ((8'd1 << k) - 1);
    denormFract= ((sig >> 1) >> denormShiftDist) & ((64'd1 << (S-1)) - 1);
    expOut     = (isSubnormal ? 64'd0 : ((exp & ((13'd1 << E) - 1)) - ((1 << (E-1)) + 1)) & ((64'd1 << E) - 1))
                 | ((isNaN || isInf) ? ((64'd1 << E) - 1) : 64'd0);
    fractOut   = isSubnormal ? denormFract : (isInf ? 64'd0 : (sig & ((64'd1 << (S-1)) - 1)));
    return (64'(sign) << (E+S-1)) | (expOut << (S-1)) | fractOut;
  endfunction

  function automatic bit rec_is_nan_d(logic [64:0] x); return (x[63:61] == 3'b111); endfunction

  // rocket FPU box(x_D, D, y_S, S) swizzle (FPU.scala:334)
  function automatic logic [64:0] box_swizzle(logic [64:0] x, logic [32:0] y);
    logic [64:0] sw;
    sw = { x[64:61],           // 4
           &x[51:32],          // 1
           x[59:53],           // 7
           y[31],              // 1
           x[51:32],           // 20
           y[32],              // 1
           y[30:0] };          // 31   = 65
    return rec_is_nan_d(x) ? sw : x;
  endfunction

  // recode(x, tag): what the FP regfile holds after FLD/FLW/fmv.*.x (FPU.scala:419)
  //   helper(x, D) = box(D.recode(x), D, S.recode(x), S)
  // i.e. the recoded double is *always* swizzled when it is a NaN so that the
  // low 32 bits carry a recoded single. That is what makes NaN-boxing work.
  function automatic logic [64:0] fp_recode(logic [63:0] x);
    logic [64:0] xd;
    logic [32:0] xs;
    xd = recfn_from_fn(11, 53, x);
    xs = recfn_from_fn(8, 24, 64'(x[31:0]));
    return box_swizzle(xd, xs);
  endfunction
  function automatic logic [64:0] fp_recode_d(logic [63:0] x); return fp_recode(x); endfunction
  function automatic logic [64:0] fp_recode_s(logic [31:0] x); return fp_recode({32'hFFFF_FFFF, x}); endfunction

  // ieee(x, D): recoded 65-bit regfile value -> 64-bit IEEE (single results NaN-boxed)
  function automatic logic [63:0] fp_ieee(logic [64:0] x);
    logic [63:0] unrec;
    logic [32:0] prevRec;
    logic [63:0] prevUnrec;
    unrec     = fn_from_recfn(11, 53, x);
    prevRec   = {x[31], x[52], x[30:0]};
    prevUnrec = fn_from_recfn(8, 24, 65'(prevRec));
    return {unrec[63:32], rec_is_nan_d(x) ? prevUnrec[31:0] : unrec[31:0]};
  endfunction

  //---------------------------------------------------------------------------
  // IEEE classification helpers (used by coverage and stimulus)
  //---------------------------------------------------------------------------
  typedef enum int {
    FPC_POS_ZERO, FPC_NEG_ZERO, FPC_POS_INF, FPC_NEG_INF, FPC_QNAN, FPC_SNAN,
    FPC_POS_SUBN, FPC_NEG_SUBN, FPC_POS_NORM, FPC_NEG_NORM, FPC_UNBOXED
  } fp_class_e;

  function automatic fp_class_e fp_classify64(logic [63:0] v);
    logic s; logic [10:0] e; logic [51:0] f;
    s = v[63]; e = v[62:52]; f = v[51:0];
    if (e == 11'h7FF) begin
      if (f == 0) return s ? FPC_NEG_INF : FPC_POS_INF;
      return f[51] ? FPC_QNAN : FPC_SNAN;
    end
    if (e == 0) begin
      if (f == 0) return s ? FPC_NEG_ZERO : FPC_POS_ZERO;
      return s ? FPC_NEG_SUBN : FPC_POS_SUBN;
    end
    return s ? FPC_NEG_NORM : FPC_POS_NORM;
  endfunction

  function automatic fp_class_e fp_classify32(logic [63:0] v);
    logic s; logic [7:0] e; logic [22:0] f;
    if (v[63:32] != 32'hFFFF_FFFF) return FPC_UNBOXED;
    s = v[31]; e = v[30:23]; f = v[22:0];
    if (e == 8'hFF) begin
      if (f == 0) return s ? FPC_NEG_INF : FPC_POS_INF;
      return f[22] ? FPC_QNAN : FPC_SNAN;
    end
    if (e == 0) begin
      if (f == 0) return s ? FPC_NEG_ZERO : FPC_POS_ZERO;
      return s ? FPC_NEG_SUBN : FPC_POS_SUBN;
    end
    return s ? FPC_NEG_NORM : FPC_POS_NORM;
  endfunction

  // Canonical special values
  localparam logic [63:0] D_POS_ZERO = 64'h0000_0000_0000_0000;
  localparam logic [63:0] D_NEG_ZERO = 64'h8000_0000_0000_0000;
  localparam logic [63:0] D_POS_INF  = 64'h7FF0_0000_0000_0000;
  localparam logic [63:0] D_NEG_INF  = 64'hFFF0_0000_0000_0000;
  localparam logic [63:0] D_QNAN     = 64'h7FF8_0000_0000_0000;
  localparam logic [63:0] D_SNAN     = 64'h7FF4_0000_0000_0000;
  localparam logic [63:0] D_MIN_SUBN = 64'h0000_0000_0000_0001;
  localparam logic [63:0] D_MAX_SUBN = 64'h000F_FFFF_FFFF_FFFF;
  localparam logic [63:0] D_MIN_NORM = 64'h0010_0000_0000_0000;
  localparam logic [63:0] D_MAX_NORM = 64'h7FEF_FFFF_FFFF_FFFF;
  localparam logic [63:0] D_ONE      = 64'h3FF0_0000_0000_0000;
  localparam logic [31:0] S_POS_ZERO = 32'h0000_0000;
  localparam logic [31:0] S_NEG_ZERO = 32'h8000_0000;
  localparam logic [31:0] S_POS_INF  = 32'h7F80_0000;
  localparam logic [31:0] S_NEG_INF  = 32'hFF80_0000;
  localparam logic [31:0] S_QNAN     = 32'h7FC0_0000;
  localparam logic [31:0] S_SNAN     = 32'h7FA0_0000;
  localparam logic [31:0] S_MIN_SUBN = 32'h0000_0001;
  localparam logic [31:0] S_MAX_SUBN = 32'h007F_FFFF;
  localparam logic [31:0] S_MIN_NORM = 32'h0080_0000;
  localparam logic [31:0] S_MAX_NORM = 32'h7F7F_FFFF;
  localparam logic [31:0] S_ONE      = 32'h3F80_0000;

  function automatic logic [63:0] box_s(logic [31:0] s); return {32'hFFFF_FFFF, s}; endfunction

endpackage : boom_exe_defs_pkg

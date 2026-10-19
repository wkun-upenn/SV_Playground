//-----------------------------------------------------------------------------
// boom_exe_types_pkg.sv
//
// Shared types for the BOOM execute-pipeline behavioral DUT and the UVM
// testbench.  Mirrors the structure described in the BOOM documentation
// ("The Execute Pipeline"): each Execution Unit owns one issue port and a
// mix of Functional Units (ALU, iMul, iDiv, FPU, FDiv), and the CSR file
// is reached through a serialized ("unique") CSR micro-op.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_TYPES_PKG_SV
`define BOOM_EXE_TYPES_PKG_SV

package boom_exe_types_pkg;

  //--------------------------------------------------------------------------
  // Parameters (BOOM MediumBoom-ish flavor, scaled down for the sample TB)
  //--------------------------------------------------------------------------
  parameter int unsigned XLEN        = 64;
  parameter int unsigned FLEN        = 64;
  parameter int unsigned PREG_W      = 7;   // 128 physical registers
  parameter int unsigned LREG_W      = 5;   // 32 logical (ISA) registers
  parameter int unsigned BR_MASK_W   = 8;   // max 8 inflight branches
  parameter int unsigned ROB_ID_W    = 8;
  parameter int unsigned CSR_ADDR_W  = 12;

  parameter int unsigned ALU_LATENCY  = 1;  // cycles
  parameter int unsigned IMUL_LATENCY = 3;  // pipelined
  parameter int unsigned FPU_LATENCY  = 4;  // pipelined (all FP padded equal)

  //--------------------------------------------------------------------------
  // Micro-op codes handled by the execute pipeline sample
  //--------------------------------------------------------------------------
  typedef enum logic [5:0] {
    UOPC_NOP      = 6'd0,
    // -- Integer ALU (pipelined, 1 cycle, bypassable) --
    UOPC_ADD      = 6'd1,
    UOPC_SUB      = 6'd2,
    UOPC_AND      = 6'd3,
    UOPC_OR       = 6'd4,
    UOPC_XOR      = 6'd5,
    UOPC_SLT      = 6'd6,
    UOPC_SLTU     = 6'd7,
    UOPC_SLL      = 6'd8,
    UOPC_SRL      = 6'd9,
    UOPC_SRA      = 6'd10,
    // -- Integer multiply (pipelined, IMUL_LATENCY) --
    UOPC_MUL      = 6'd16,
    UOPC_MULH     = 6'd17,
    UOPC_MULHU    = 6'd18,
    // -- Integer divide (un-pipelined, variable latency, RV M semantics) --
    UOPC_DIV      = 6'd20,
    UOPC_DIVU     = 6'd21,
    UOPC_REM      = 6'd22,
    UOPC_REMU     = 6'd23,
    // -- FPU, double precision IEEE-754 (pipelined, FPU_LATENCY) --
    UOPC_FADD_D   = 6'd32,
    UOPC_FSUB_D   = 6'd33,
    UOPC_FMUL_D   = 6'd34,
    UOPC_FMIN_D   = 6'd35,
    UOPC_FMAX_D   = 6'd36,
    UOPC_FSGNJ_D  = 6'd37,
    UOPC_FCLASS_D = 6'd38,
    // -- FDiv (un-pipelined, variable latency, like BOOM's FDiv/Sqrt unit) --
    UOPC_FDIV_D   = 6'd40,
    // -- CSR file ops (serialized / "unique" in BOOM) --
    UOPC_CSRRW    = 6'd48,
    UOPC_CSRRS    = 6'd49,
    UOPC_CSRRC    = 6'd50
  } uopc_e;

  //--------------------------------------------------------------------------
  // IEEE-754 (binary64) helper constants
  //--------------------------------------------------------------------------
  parameter logic [63:0] F64_POS_ZERO  = 64'h0000_0000_0000_0000;
  parameter logic [63:0] F64_NEG_ZERO  = 64'h8000_0000_0000_0000;
  parameter logic [63:0] F64_POS_INF   = 64'h7FF0_0000_0000_0000;
  parameter logic [63:0] F64_NEG_INF   = 64'hFFF0_0000_0000_0000;
  parameter logic [63:0] F64_CANON_NAN = 64'h7FF8_0000_0000_0000; // RISC-V canonical qNaN
  parameter logic [63:0] F64_SNAN      = 64'h7FF0_0000_0000_0001; // a signaling NaN
  parameter logic [63:0] F64_MIN_DENOM = 64'h0000_0000_0000_0001; // smallest subnormal
  parameter logic [63:0] F64_MAX_DENOM = 64'h000F_FFFF_FFFF_FFFF; // largest  subnormal
  parameter logic [63:0] F64_MIN_NORM  = 64'h0010_0000_0000_0000;
  parameter logic [63:0] F64_MAX_NORM  = 64'h7FEF_FFFF_FFFF_FFFF;
  parameter logic [63:0] F64_ONE       = 64'h3FF0_0000_0000_0000;

  // fflags bit positions: {NV, DZ, OF, UF, NX}
  parameter int unsigned FFLAG_NX = 0; // inexact
  parameter int unsigned FFLAG_UF = 1; // underflow
  parameter int unsigned FFLAG_OF = 2; // overflow
  parameter int unsigned FFLAG_DZ = 3; // divide-by-zero
  parameter int unsigned FFLAG_NV = 4; // invalid

  //--------------------------------------------------------------------------
  // FP value classification (matches RISC-V FCLASS bit positions)
  //--------------------------------------------------------------------------
  typedef enum logic [3:0] {
    FCLASS_NEG_INF    = 4'd0,
    FCLASS_NEG_NORM   = 4'd1,
    FCLASS_NEG_DENOM  = 4'd2,
    FCLASS_NEG_ZERO   = 4'd3,
    FCLASS_POS_ZERO   = 4'd4,
    FCLASS_POS_DENOM  = 4'd5,
    FCLASS_POS_NORM   = 4'd6,
    FCLASS_POS_INF    = 4'd7,
    FCLASS_SNAN       = 4'd8,
    FCLASS_QNAN       = 4'd9
  } fclass_e;

  function automatic fclass_e f64_classify (logic [63:0] v);
    logic        sign = v[63];
    logic [10:0] e    = v[62:52];
    logic [51:0] m    = v[51:0];
    if (e == 11'h7FF) begin
      if (m == 0)         return sign ? FCLASS_NEG_INF : FCLASS_POS_INF;
      else if (m[51])     return FCLASS_QNAN;
      else                return FCLASS_SNAN;
    end
    else if (e == 0) begin
      if (m == 0)         return sign ? FCLASS_NEG_ZERO  : FCLASS_POS_ZERO;
      else                return sign ? FCLASS_NEG_DENOM : FCLASS_POS_DENOM;
    end
    return sign ? FCLASS_NEG_NORM : FCLASS_POS_NORM;
  endfunction

  function automatic bit f64_is_nan (logic [63:0] v);
    return (v[62:52] == 11'h7FF) && (v[51:0] != 0);
  endfunction

  function automatic bit f64_is_snan (logic [63:0] v);
    return (v[62:52] == 11'h7FF) && (v[51:0] != 0) && !v[51];
  endfunction

  function automatic bit f64_is_inf (logic [63:0] v);
    return (v[62:52] == 11'h7FF) && (v[51:0] == 0);
  endfunction

  function automatic bit f64_is_zero (logic [63:0] v);
    return (v[62:0] == 0);
  endfunction

  //--------------------------------------------------------------------------
  // RISC-V CSR addresses modeled in the sample CSR file / RAL
  //--------------------------------------------------------------------------
  parameter logic [11:0] CSR_FFLAGS    = 12'h001;
  parameter logic [11:0] CSR_FRM       = 12'h002;
  parameter logic [11:0] CSR_FCSR      = 12'h003;
  parameter logic [11:0] CSR_MSTATUS   = 12'h300;
  parameter logic [11:0] CSR_MISA      = 12'h301;
  parameter logic [11:0] CSR_MIE       = 12'h304;
  parameter logic [11:0] CSR_MTVEC     = 12'h305;
  parameter logic [11:0] CSR_MSCRATCH  = 12'h340;
  parameter logic [11:0] CSR_MEPC      = 12'h341;
  parameter logic [11:0] CSR_MCAUSE    = 12'h342;
  parameter logic [11:0] CSR_MTVAL     = 12'h343;
  parameter logic [11:0] CSR_MIP       = 12'h344;
  parameter logic [11:0] CSR_MCYCLE    = 12'hB00;
  parameter logic [11:0] CSR_MINSTRET  = 12'hB02;
  parameter logic [11:0] CSR_MVENDORID = 12'hF11;
  parameter logic [11:0] CSR_MARCHID   = 12'hF12;
  parameter logic [11:0] CSR_MIMPID    = 12'hF13;
  parameter logic [11:0] CSR_MHARTID   = 12'hF14;

  // misa: MXL=2 (RV64), extensions IMAFDC + U
  parameter logic [63:0] MISA_RESET_VAL   = 64'h8000_0000_0010_112D;
  parameter logic [63:0] MARCHID_BOOM     = 64'd2; // open-source arch ID for BOOM

endpackage : boom_exe_types_pkg

`endif

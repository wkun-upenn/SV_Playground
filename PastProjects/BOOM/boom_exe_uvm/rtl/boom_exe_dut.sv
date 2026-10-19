//-----------------------------------------------------------------------------
// boom_exe_dut.sv
//
// Behavioral stand-in for a BOOM Execution Unit cluster, faithful to the
// micro-architecture described in the BOOM docs ("The Execute Pipeline"):
//
//   * One issue port feeding a mix of Functional Units.
//   * Pipelined units (ALU / iMul / FPU / CSR) are all padded to the same
//     latency (FPU_LATENCY) so write-port scheduling is trivial -- exactly
//     the trick BOOM uses ("the ALU is padded with pipeline registers to
//     match latencies with the FPU and iMul units").
//   * Un-pipelined units (iDiv, FDiv) have variable latency and de-assert
//     readiness while busy, like BOOM's divider and FDiv/Sqrt units.
//   * Branch speculation: every in-flight uop carries a branch mask.
//     A branch-resolve broadcast clears mask bits; a mispredict broadcast
//     kills any uop still speculated under the offending branch (its
//     response is gated off, as in BOOM's abstract FunctionalUnit wrapper).
//   * A CSR file executes CSRRW/CSRRS/CSRRC atomically and models the real
//     RISC-V CSRs (mstatus, misa, mepc, mcause, mtvec, fcsr, counters...).
//     FP writebacks accumulate exception flags into fflags as a side effect.
//
// FP arithmetic is IEEE-754 binary64. NaN/inf/zero corner cases are handled
// explicitly per RISC-V semantics (canonical qNaN 0x7ff8000000000000).
//-----------------------------------------------------------------------------
module boom_exe_dut
  import boom_exe_types_pkg::*;
(
  input  logic                  clk,
  input  logic                  rst_n,

  // ---- Issue port (from Issue Queue / Register Read) ----
  input  logic                  iss_valid,
  output logic                  iss_ready,
  input  uopc_e                 iss_uopc,
  input  logic [ROB_ID_W-1:0]   iss_rob_idx,
  input  logic [PREG_W-1:0]     iss_pdst,
  input  logic [XLEN-1:0]       iss_rs1_data,
  input  logic [XLEN-1:0]       iss_rs2_data,
  input  logic [BR_MASK_W-1:0]  iss_br_mask,
  input  logic [CSR_ADDR_W-1:0] iss_csr_addr,

  // ---- Branch resolution broadcast (from the Branch Unit) ----
  input  logic                  br_resolve_valid,
  input  logic [BR_MASK_W-1:0]  br_resolve_mask,    // branches resolved OK
  input  logic                  br_mispredict_valid,
  input  logic [BR_MASK_W-1:0]  br_mispredict_mask, // kill matching uops

  // ---- Write-back port 0 : shared by all pipelined units ----
  output logic                  wb0_valid,
  output logic [ROB_ID_W-1:0]   wb0_rob_idx,
  output logic [PREG_W-1:0]     wb0_pdst,
  output logic [XLEN-1:0]       wb0_data,
  output logic                  wb0_fflags_valid,
  output logic [4:0]            wb0_fflags,

  // ---- Write-back port 1 : shared by the un-pipelined units ----
  output logic                  wb1_valid,
  output logic [ROB_ID_W-1:0]   wb1_rob_idx,
  output logic [PREG_W-1:0]     wb1_pdst,
  output logic [XLEN-1:0]       wb1_data,
  output logic                  wb1_fflags_valid,
  output logic [4:0]            wb1_fflags,

  // ---- Functional-unit readiness (BOOM's "scheduling readiness" vector) ----
  output logic                  div_busy,
  output logic                  fdiv_busy
);

  //==========================================================================
  // CSR file (Rocket-style, reached only by serialized CSR uops)
  //==========================================================================
  logic [63:0] csr_mstatus, csr_mie, csr_mtvec, csr_mscratch;
  logic [63:0] csr_mepc, csr_mcause, csr_mtval, csr_mip;
  logic [63:0] csr_mcycle, csr_minstret;
  logic [4:0]  csr_fflags;
  logic [2:0]  csr_frm;

  // Writable bit masks (WARL behavior, simplified)
  localparam logic [63:0] MSTATUS_WMASK = 64'h0000_0000_0000_7888; // FS,MPP,MPIE,MIE
  localparam logic [63:0] MTVEC_WMASK   = ~64'h2;                  // MODE<=1
  localparam logic [63:0] MEPC_WMASK    = ~64'h1;                  // IALIGN

  function automatic logic [63:0] csr_read_val (logic [11:0] addr);
    case (addr)
      CSR_FFLAGS:    return {59'b0, csr_fflags};
      CSR_FRM:       return {61'b0, csr_frm};
      CSR_FCSR:      return {56'b0, csr_frm, csr_fflags};
      CSR_MSTATUS:   begin
        // SD (bit 63) is derived: set when FS == 2'b11 (dirty)
        logic [63:0] v = csr_mstatus;
        v[63] = (csr_mstatus[14:13] == 2'b11);
        return v;
      end
      CSR_MISA:      return MISA_RESET_VAL;
      CSR_MIE:       return csr_mie;
      CSR_MTVEC:     return csr_mtvec;
      CSR_MSCRATCH:  return csr_mscratch;
      CSR_MEPC:      return csr_mepc & MEPC_WMASK;
      CSR_MCAUSE:    return csr_mcause;
      CSR_MTVAL:     return csr_mtval;
      CSR_MIP:       return csr_mip;
      CSR_MCYCLE:    return csr_mcycle;
      CSR_MINSTRET:  return csr_minstret;
      CSR_MVENDORID: return 64'd0;
      CSR_MARCHID:   return MARCHID_BOOM;
      CSR_MIMPID:    return 64'd0;
      CSR_MHARTID:   return 64'd0;
      default:       return 64'd0;
    endcase
  endfunction

  // Apply a CSR write (returns nothing; RO CSRs ignore writes)
  task automatic csr_write_val (input logic [11:0] addr, input logic [63:0] wval);
    case (addr)
      CSR_FFLAGS:   csr_fflags   <= wval[4:0];
      CSR_FRM:      csr_frm      <= wval[2:0];
      CSR_FCSR:     begin csr_fflags <= wval[4:0]; csr_frm <= wval[7:5]; end
      CSR_MSTATUS:  csr_mstatus  <= (csr_mstatus & ~MSTATUS_WMASK) | (wval & MSTATUS_WMASK);
      CSR_MIE:      csr_mie      <= wval & 64'h0000_0000_0000_0AAA;
      CSR_MTVEC:    csr_mtvec    <= wval & MTVEC_WMASK;
      CSR_MSCRATCH: csr_mscratch <= wval;
      CSR_MEPC:     csr_mepc     <= wval & MEPC_WMASK;
      CSR_MCAUSE:   csr_mcause   <= wval;
      CSR_MTVAL:    csr_mtval    <= wval;
      CSR_MCYCLE:   csr_mcycle   <= wval;
      CSR_MINSTRET: csr_minstret <= wval;
      default: ;  // misa / mip / M-info CSRs: writes ignored (WARL -> hardwired)
    endcase
  endtask

  //==========================================================================
  // IEEE-754 binary64 helpers
  //==========================================================================
  typedef struct packed {
    logic [4:0]  flags;   // {NV,DZ,OF,UF,NX}
    logic [63:0] data;
  } fp_result_t;

  function automatic fp_result_t fp_arith (uopc_e op, logic [63:0] a, logic [63:0] b);
    fp_result_t r;
    real ra, rb, rr;
    bit any_snan = f64_is_snan(a) || f64_is_snan(b);
    bit any_nan  = f64_is_nan(a)  || f64_is_nan(b);
    r.flags = '0;
    r.data  = '0;

    unique case (op)
      UOPC_FADD_D, UOPC_FSUB_D: begin
        logic [63:0] bb = (op == UOPC_FSUB_D) ? {~b[63], b[62:0]} : b;
        if (any_nan) begin
          r.data = F64_CANON_NAN;
          if (any_snan) r.flags[FFLAG_NV] = 1'b1;
        end
        else if (f64_is_inf(a) && f64_is_inf(bb) && (a[63] != bb[63])) begin
          r.data = F64_CANON_NAN;              // (+inf) + (-inf) = qNaN, NV
          r.flags[FFLAG_NV] = 1'b1;
        end
        else if (f64_is_inf(a))  r.data = a;
        else if (f64_is_inf(bb)) r.data = bb;
        else begin
          ra = $bitstoreal(a); rb = $bitstoreal(bb);
          rr = ra + rb;
          r.data = $realtobits(rr);
          if (f64_is_inf(r.data)) begin        // finite + finite overflowed
            r.flags[FFLAG_OF] = 1'b1; r.flags[FFLAG_NX] = 1'b1;
          end
          // exact-zero sum of nonzero operands: IEEE says +0 (RNE)
          if (f64_is_zero(r.data) && !f64_is_zero(a) && !f64_is_zero(bb))
            r.data = F64_POS_ZERO;
        end
      end

      UOPC_FMUL_D: begin
        if (any_nan) begin
          r.data = F64_CANON_NAN;
          if (any_snan) r.flags[FFLAG_NV] = 1'b1;
        end
        else if ((f64_is_inf(a) && f64_is_zero(b)) ||
                 (f64_is_zero(a) && f64_is_inf(b))) begin
          r.data = F64_CANON_NAN;              // inf * 0 = qNaN, NV
          r.flags[FFLAG_NV] = 1'b1;
        end
        else if (f64_is_inf(a) || f64_is_inf(b))
          r.data = {a[63]^b[63], F64_POS_INF[62:0]};
        else begin
          ra = $bitstoreal(a); rb = $bitstoreal(b);
          rr = ra * rb;
          r.data = $realtobits(rr);
          if (f64_is_inf(r.data)) begin
            r.flags[FFLAG_OF] = 1'b1; r.flags[FFLAG_NX] = 1'b1;
          end
          else if (!f64_is_zero(a) && !f64_is_zero(b) &&
                   (f64_is_zero(r.data) ||
                    f64_classify(r.data) inside {FCLASS_NEG_DENOM, FCLASS_POS_DENOM})) begin
            r.flags[FFLAG_UF] = 1'b1; r.flags[FFLAG_NX] = 1'b1;
            if (f64_is_zero(r.data)) r.data = {a[63]^b[63], 63'b0};
          end
        end
      end

      UOPC_FDIV_D: begin
        if (any_nan) begin
          r.data = F64_CANON_NAN;
          if (any_snan) r.flags[FFLAG_NV] = 1'b1;
        end
        else if (f64_is_zero(a) && f64_is_zero(b)) begin
          r.data = F64_CANON_NAN; r.flags[FFLAG_NV] = 1'b1;   // 0/0
        end
        else if (f64_is_inf(a) && f64_is_inf(b)) begin
          r.data = F64_CANON_NAN; r.flags[FFLAG_NV] = 1'b1;   // inf/inf
        end
        else if (f64_is_zero(b)) begin
          r.data = {a[63]^b[63], F64_POS_INF[62:0]};          // x/0 = inf, DZ
          r.flags[FFLAG_DZ] = 1'b1;
        end
        else if (f64_is_inf(a))  r.data = {a[63]^b[63], F64_POS_INF[62:0]};
        else if (f64_is_inf(b))  r.data = {a[63]^b[63], 63'b0};
        else if (f64_is_zero(a)) r.data = {a[63]^b[63], 63'b0};
        else begin
          ra = $bitstoreal(a); rb = $bitstoreal(b);
          rr = ra / rb;
          r.data = $realtobits(rr);
          if (f64_is_inf(r.data)) begin
            r.flags[FFLAG_OF] = 1'b1; r.flags[FFLAG_NX] = 1'b1;
          end
          else if (f64_is_zero(r.data) ||
                   f64_classify(r.data) inside {FCLASS_NEG_DENOM, FCLASS_POS_DENOM}) begin
            r.flags[FFLAG_UF] = 1'b1; r.flags[FFLAG_NX] = 1'b1;
            if (f64_is_zero(r.data)) r.data = {a[63]^b[63], 63'b0};
          end
        end
      end

      UOPC_FMIN_D, UOPC_FMAX_D: begin
        bit take_a;
        if (any_snan) r.flags[FFLAG_NV] = 1'b1;
        if (f64_is_nan(a) && f64_is_nan(b)) r.data = F64_CANON_NAN;
        else if (f64_is_nan(a))             r.data = b;
        else if (f64_is_nan(b))             r.data = a;
        else begin
          // -0 < +0 for min/max purposes
          if (f64_is_zero(a) && f64_is_zero(b))
            take_a = (op == UOPC_FMIN_D) ? a[63] : ~a[63];
          else begin
            ra = $bitstoreal(a); rb = $bitstoreal(b);
            take_a = (op == UOPC_FMIN_D) ? (ra < rb) : (ra > rb);
          end
          r.data = take_a ? a : b;
        end
      end

      UOPC_FSGNJ_D:  r.data = {b[63], a[62:0]};

      UOPC_FCLASS_D: r.data = 64'd1 << f64_classify(a);

      default: ;
    endcase
    return r;
  endfunction

  //==========================================================================
  // Integer helpers (RV64 M-extension semantics)
  //==========================================================================
  function automatic logic [63:0] int_arith (uopc_e op, logic [63:0] a, logic [63:0] b);
    unique case (op)
      UOPC_ADD:   return a + b;
      UOPC_SUB:   return a - b;
      UOPC_AND:   return a & b;
      UOPC_OR:    return a | b;
      UOPC_XOR:   return a ^ b;
      UOPC_SLT:   return {63'b0, $signed(a) < $signed(b)};
      UOPC_SLTU:  return {63'b0, a < b};
      UOPC_SLL:   return a << b[5:0];
      UOPC_SRL:   return a >> b[5:0];
      UOPC_SRA:   return $signed(a) >>> b[5:0];
      UOPC_MUL:   return a * b;
      UOPC_MULH:  begin
        logic signed [127:0] p = $signed(a) * $signed(b);
        return p[127:64];
      end
      UOPC_MULHU: begin
        logic [127:0] p = a * b;
        return p[127:64];
      end
      UOPC_DIV:   begin
        if (b == 0)                                   return '1;            // -1
        if (a == 64'h8000_0000_0000_0000 && b == '1)  return a;             // overflow
        return $signed(a) / $signed(b);
      end
      UOPC_DIVU:  return (b == 0) ? '1 : (a / b);
      UOPC_REM:   begin
        if (b == 0)                                   return a;
        if (a == 64'h8000_0000_0000_0000 && b == '1)  return '0;
        return $signed(a) % $signed(b);
      end
      UOPC_REMU:  return (b == 0) ? a : (a % b);
      default:    return '0;
    endcase
  endfunction

  function automatic bit is_div_op  (uopc_e op);
    return op inside {UOPC_DIV, UOPC_DIVU, UOPC_REM, UOPC_REMU};
  endfunction
  function automatic bit is_fp_op (uopc_e op);
    return op inside {UOPC_FADD_D, UOPC_FSUB_D, UOPC_FMUL_D, UOPC_FMIN_D,
                      UOPC_FMAX_D, UOPC_FSGNJ_D, UOPC_FCLASS_D};
  endfunction
  function automatic bit is_csr_op (uopc_e op);
    return op inside {UOPC_CSRRW, UOPC_CSRRS, UOPC_CSRRC};
  endfunction

  //==========================================================================
  // Pipelined path: unified pipe, all ops padded to FPU_LATENCY
  //==========================================================================
  typedef struct packed {
    logic                 valid;
    logic [ROB_ID_W-1:0]  rob_idx;
    logic [PREG_W-1:0]    pdst;
    logic [XLEN-1:0]      data;
    logic                 fflags_valid;
    logic [4:0]           fflags;
    logic [BR_MASK_W-1:0] br_mask;
  } pipe_entry_t;

  pipe_entry_t pipe_q [FPU_LATENCY];

  //==========================================================================
  // Un-pipelined units: iDiv and FDiv
  //==========================================================================
  typedef struct packed {
    logic                 busy;
    logic [7:0]           cycles_left;
    logic [ROB_ID_W-1:0]  rob_idx;
    logic [PREG_W-1:0]    pdst;
    logic [XLEN-1:0]      data;
    logic                 fflags_valid;
    logic [4:0]           fflags;
    logic [BR_MASK_W-1:0] br_mask;
  } unpiped_t;

  unpiped_t div_u, fdiv_u;

  assign div_busy  = div_u.busy;
  assign fdiv_busy = fdiv_u.busy;

  // Issue-side readiness: un-pipelined units apply back-pressure
  assign iss_ready = !( (is_div_op(iss_uopc)      && div_u.busy ) ||
                        (iss_uopc == UOPC_FDIV_D  && fdiv_u.busy) );

  wire iss_fire = iss_valid && iss_ready;

  // Kill check against the *current cycle* mispredict broadcast
  function automatic bit killed_now (logic [BR_MASK_W-1:0] mask);
    return br_mispredict_valid && |(mask & br_mispredict_mask);
  endfunction

  function automatic logic [BR_MASK_W-1:0] next_mask (logic [BR_MASK_W-1:0] mask);
    return br_resolve_valid ? (mask & ~br_resolve_mask) : mask;
  endfunction

  //==========================================================================
  // Main sequential process
  //==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < FPU_LATENCY; i++) pipe_q[i] <= '0;
      div_u        <= '0;
      fdiv_u       <= '0;
      wb0_valid    <= 1'b0; wb0_rob_idx <= '0; wb0_pdst <= '0; wb0_data <= '0;
      wb0_fflags_valid <= 1'b0; wb0_fflags <= '0;
      wb1_valid    <= 1'b0; wb1_rob_idx <= '0; wb1_pdst <= '0; wb1_data <= '0;
      wb1_fflags_valid <= 1'b0; wb1_fflags <= '0;
      csr_mstatus  <= 64'h0000_0000_0000_1800;  // MPP=M
      csr_mie      <= '0;  csr_mtvec   <= '0;  csr_mscratch <= '0;
      csr_mepc     <= '0;  csr_mcause  <= '0;  csr_mtval    <= '0;
      csr_mip      <= '0;  csr_mcycle  <= '0;  csr_minstret <= '0;
      csr_fflags   <= '0;  csr_frm     <= '0;
    end
    else begin
      pipe_entry_t head;
      pipe_entry_t new_entry;
      logic [4:0]  acc_fflags;
      logic [1:0]  retire_cnt;

      // ---- free-running cycle counter ----
      csr_mcycle <= csr_mcycle + 1;
      acc_fflags = csr_fflags;
      retire_cnt = '0;

      // ================= Write-back port 0 : pipelined pipe ================
      head = pipe_q[FPU_LATENCY-1];
      if (head.valid && !killed_now(head.br_mask)) begin
        wb0_valid        <= 1'b1;
        wb0_rob_idx      <= head.rob_idx;
        wb0_pdst         <= head.pdst;
        wb0_data         <= head.data;
        wb0_fflags_valid <= head.fflags_valid;
        wb0_fflags       <= head.fflags;
        if (head.fflags_valid) begin
          acc_fflags = acc_fflags | head.fflags;      // fflags side effect
          csr_mstatus[14:13] <= 2'b11;                // FS = dirty
        end
        retire_cnt = retire_cnt + 1;
      end
      else begin
        wb0_valid        <= 1'b0;
        wb0_fflags_valid <= 1'b0;
      end

      // ---- advance the pipe (with kill + mask update at every stage) ----
      for (int i = FPU_LATENCY-1; i > 0; i--) begin
        pipe_q[i]         <= pipe_q[i-1];
        pipe_q[i].valid   <= pipe_q[i-1].valid && !killed_now(pipe_q[i-1].br_mask);
        pipe_q[i].br_mask <= next_mask(pipe_q[i-1].br_mask);
      end
      pipe_q[0] <= '0;

      // ================= Write-back port 1 : un-pipelined units ============
      wb1_valid        <= 1'b0;
      wb1_fflags_valid <= 1'b0;

      // iDiv
      if (div_u.busy) begin
        if (killed_now(div_u.br_mask)) div_u <= '0;
        else begin
          div_u.br_mask <= next_mask(div_u.br_mask);
          if (div_u.cycles_left == 0) begin
            wb1_valid   <= 1'b1;
            wb1_rob_idx <= div_u.rob_idx;
            wb1_pdst    <= div_u.pdst;
            wb1_data    <= div_u.data;
            retire_cnt = retire_cnt + 1;
            div_u       <= '0;
          end
          else div_u.cycles_left <= div_u.cycles_left - 1;
        end
      end

      // FDiv (only one of the two un-pipelined units can write back per
      // cycle; FDiv stalls one extra cycle on a collision, modeling the
      // shared write port arbitration)
      if (fdiv_u.busy) begin
        if (killed_now(fdiv_u.br_mask)) fdiv_u <= '0;
        else begin
          fdiv_u.br_mask <= next_mask(fdiv_u.br_mask);
          if (fdiv_u.cycles_left == 0) begin
            if (!(div_u.busy && div_u.cycles_left == 0 && !killed_now(div_u.br_mask))) begin
              wb1_valid        <= 1'b1;
              wb1_rob_idx      <= fdiv_u.rob_idx;
              wb1_pdst         <= fdiv_u.pdst;
              wb1_data         <= fdiv_u.data;
              wb1_fflags_valid <= 1'b1;
              wb1_fflags       <= fdiv_u.fflags;
              acc_fflags = acc_fflags | fdiv_u.fflags;
              csr_mstatus[14:13] <= 2'b11;
              retire_cnt = retire_cnt + 1;
              fdiv_u       <= '0;
            end
          end
          else fdiv_u.cycles_left <= fdiv_u.cycles_left - 1;
        end
      end

      // ========================== Issue / accept ==========================
      if (iss_fire && !killed_now(iss_br_mask)) begin
        if (is_div_op(iss_uopc)) begin
          div_u.busy         <= 1'b1;
          // variable latency, derived from the operand (deterministic)
          div_u.cycles_left  <= 8'd8 + {4'b0, iss_rs2_data[3:0]};
          div_u.rob_idx      <= iss_rob_idx;
          div_u.pdst         <= iss_pdst;
          div_u.data         <= int_arith(iss_uopc, iss_rs1_data, iss_rs2_data);
          div_u.fflags_valid <= 1'b0;
          div_u.fflags       <= '0;
          div_u.br_mask      <= next_mask(iss_br_mask);
        end
        else if (iss_uopc == UOPC_FDIV_D) begin
          fp_result_t fr;
          fr = fp_arith(UOPC_FDIV_D, iss_rs1_data, iss_rs2_data);
          fdiv_u.busy         <= 1'b1;
          fdiv_u.cycles_left  <= 8'd10 + {4'b0, iss_rs1_data[3:0]};
          fdiv_u.rob_idx      <= iss_rob_idx;
          fdiv_u.pdst         <= iss_pdst;
          fdiv_u.data         <= fr.data;
          fdiv_u.fflags_valid <= 1'b1;
          fdiv_u.fflags       <= fr.flags;
          fdiv_u.br_mask      <= next_mask(iss_br_mask);
        end
        else if (iss_uopc != UOPC_NOP) begin
          new_entry              = '0;
          new_entry.valid        = 1'b1;
          new_entry.rob_idx      = iss_rob_idx;
          new_entry.pdst         = iss_pdst;
          new_entry.br_mask      = next_mask(iss_br_mask);
          new_entry.fflags_valid = 1'b0;

          if (is_fp_op(iss_uopc)) begin
            fp_result_t fr;
            fr = fp_arith(iss_uopc, iss_rs1_data, iss_rs2_data);
            new_entry.data         = fr.data;
            new_entry.fflags       = fr.flags;
            new_entry.fflags_valid = 1'b1;
          end
          else if (is_csr_op(iss_uopc)) begin
            logic [63:0] old_val;
            old_val = csr_read_val(iss_csr_addr);
            new_entry.data = old_val;
            unique case (iss_uopc)
              UOPC_CSRRW: csr_write_val(iss_csr_addr, iss_rs1_data);
              UOPC_CSRRS: if (iss_rs1_data != 0)
                            csr_write_val(iss_csr_addr, old_val |  iss_rs1_data);
              UOPC_CSRRC: if (iss_rs1_data != 0)
                            csr_write_val(iss_csr_addr, old_val & ~iss_rs1_data);
              default: ;
            endcase
          end
          else begin
            new_entry.data = int_arith(iss_uopc, iss_rs1_data, iss_rs2_data);
          end
          pipe_q[0] <= new_entry;
        end
      end

      // fflags accumulation (side effect of FP write-backs). A same-cycle
      // CSR write to fflags/fcsr wins over accumulation, matching the
      // serialized ("unique") execution of CSR uops in BOOM: a CSR uop is
      // never in flight at the same time as an FP uop.
      if (!(iss_fire && is_csr_op(iss_uopc) &&
            (iss_csr_addr inside {CSR_FFLAGS, CSR_FCSR})))
        csr_fflags <= acc_fflags;

      // retired-instruction counter (single NBA so simultaneous wb0+wb1
      // retires both count; a same-cycle CSR write to minstret wins)
      if (!(iss_fire && is_csr_op(iss_uopc) && iss_csr_addr == CSR_MINSTRET))
        csr_minstret <= csr_minstret + {62'b0, retire_cnt};
    end
  end

endmodule : boom_exe_dut

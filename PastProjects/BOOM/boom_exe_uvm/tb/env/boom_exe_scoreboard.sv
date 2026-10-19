//-----------------------------------------------------------------------------
// boom_exe_scoreboard.sv
//
// Self-checking reference model for the execute pipeline:
//   * predicts the result (and fflags) of every accepted uop,
//   * tracks branch speculation: a mispredict broadcast retires the
//     expectations of every in-flight uop speculated under the killed
//     branch -- if such a uop DOES write back, that is an error
//     (BOOM must gate off misspeculated responses),
//   * checks every write-back against the prediction (data + fflags),
//   * at end of test, any leftover non-killed expectation = lost uop.
//
// The integer model implements RV64 M-extension semantics (div-by-zero,
// MIN_INT/-1 overflow).  The FP model implements IEEE-754 binary64 with
// RISC-V NaN handling (canonical qNaN 0x7ff8_0000_0000_0000).
// Flag note: NV/DZ/OF/UF are modeled exactly for the covered ops; NX is
// modeled only when raised together with OF/UF.  Against real BOOM RTL,
// swap `predict_fp` for a bit-accurate softfloat DPI reference.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_SCOREBOARD_SV
`define BOOM_EXE_SCOREBOARD_SV

`uvm_analysis_imp_decl(_issued)
`uvm_analysis_imp_decl(_wb)

class boom_exe_expect;
  uopc_e                uopc;
  logic [XLEN-1:0]      exp_data;
  logic [4:0]           exp_fflags;
  bit                   exp_fflags_valid;
  logic [PREG_W-1:0]    pdst;
  logic [BR_MASK_W-1:0] br_mask;
  bit                   killed;
endclass

class boom_exe_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(boom_exe_scoreboard)

  uvm_analysis_imp_issued #(boom_exe_txn, boom_exe_scoreboard) imp_issued;
  uvm_analysis_imp_wb     #(boom_exe_txn, boom_exe_scoreboard) imp_wb;

  // outstanding expectations, keyed by rob_idx
  boom_exe_expect expect_q [int unsigned];

  int unsigned n_checked, n_killed, n_errors;

  function new (string name, uvm_component parent);
    super.new(name, parent);
    imp_issued = new("imp_issued", this);
    imp_wb     = new("imp_wb", this);
  endfunction

  //-------------------------------------------------------------------------
  // Reference model : integer
  //-------------------------------------------------------------------------
  function logic [XLEN-1:0] predict_int (uopc_e op, logic [63:0] a, logic [63:0] b);
    logic signed [63:0]  sa = a, sb = b;
    logic signed [127:0] sp;
    logic [127:0]        up;
    case (op)
      UOPC_ADD:   predict_int = a + b;
      UOPC_SUB:   predict_int = a - b;
      UOPC_AND:   predict_int = a & b;
      UOPC_OR:    predict_int = a | b;
      UOPC_XOR:   predict_int = a ^ b;
      UOPC_SLT:   predict_int = {63'b0, sa < sb};
      UOPC_SLTU:  predict_int = {63'b0, a < b};
      UOPC_SLL:   predict_int = a << b[5:0];
      UOPC_SRL:   predict_int = a >> b[5:0];
      UOPC_SRA:   predict_int = sa >>> b[5:0];
      UOPC_MUL:   predict_int = a * b;
      UOPC_MULH:  begin sp = sa * sb;  predict_int = sp[127:64]; end
      UOPC_MULHU: begin up = a * b;    predict_int = up[127:64]; end
      UOPC_DIV:   predict_int = (b == 0) ? '1
                              : (a == 64'h8000_0000_0000_0000 && b == '1) ? a
                              : (sa / sb);
      UOPC_DIVU:  predict_int = (b == 0) ? '1 : (a / b);
      UOPC_REM:   predict_int = (b == 0) ? a
                              : (a == 64'h8000_0000_0000_0000 && b == '1) ? '0
                              : (sa % sb);
      UOPC_REMU:  predict_int = (b == 0) ? a : (a % b);
      default:    predict_int = '0;
    endcase
  endfunction

  //-------------------------------------------------------------------------
  // Reference model : IEEE-754 binary64 with RISC-V semantics
  //-------------------------------------------------------------------------
  function void predict_fp (uopc_e op, logic [63:0] a, logic [63:0] b,
                            output logic [63:0] data, output logic [4:0] flags);
    bit a_nan   = f64_is_nan(a),  b_nan  = f64_is_nan(b);
    bit any_sn  = f64_is_snan(a) || f64_is_snan(b);
    bit a_inf   = f64_is_inf(a),  b_inf  = f64_is_inf(b);
    bit a_zero  = f64_is_zero(a), b_zero = f64_is_zero(b);
    real ra, rb, rr;
    logic [63:0] eff_b;

    data  = '0;
    flags = '0;

    case (op)
      UOPC_FADD_D, UOPC_FSUB_D: begin
        eff_b = (op == UOPC_FSUB_D) ? {~b[63], b[62:0]} : b;
        if (a_nan || b_nan) begin
          data = F64_CANON_NAN;
          flags[FFLAG_NV] = any_sn;
        end
        else if (a_inf && f64_is_inf(eff_b) && (a[63] != eff_b[63])) begin
          data = F64_CANON_NAN;  flags[FFLAG_NV] = 1;
        end
        else if (a_inf)              data = a;
        else if (f64_is_inf(eff_b))  data = eff_b;
        else begin
          ra = $bitstoreal(a);  rb = $bitstoreal(eff_b);
          rr = ra + rb;
          data = $realtobits(rr);
          if (f64_is_inf(data)) begin
            flags[FFLAG_OF] = 1;  flags[FFLAG_NX] = 1;
          end
          if (f64_is_zero(data) && !a_zero && !f64_is_zero(eff_b))
            data = F64_POS_ZERO;   // RNE: exact cancellation gives +0
        end
      end

      UOPC_FMUL_D: begin
        if (a_nan || b_nan) begin
          data = F64_CANON_NAN;  flags[FFLAG_NV] = any_sn;
        end
        else if ((a_inf && b_zero) || (a_zero && b_inf)) begin
          data = F64_CANON_NAN;  flags[FFLAG_NV] = 1;
        end
        else if (a_inf || b_inf)
          data = {a[63]^b[63], F64_POS_INF[62:0]};
        else begin
          ra = $bitstoreal(a);  rb = $bitstoreal(b);
          rr = ra * rb;
          data = $realtobits(rr);
          if (f64_is_inf(data)) begin
            flags[FFLAG_OF] = 1;  flags[FFLAG_NX] = 1;
          end
          else if (!a_zero && !b_zero &&
                   (f64_is_zero(data) || is_denorm(data))) begin
            flags[FFLAG_UF] = 1;  flags[FFLAG_NX] = 1;
            if (f64_is_zero(data)) data = {a[63]^b[63], 63'b0};
          end
        end
      end

      UOPC_FDIV_D: begin
        if (a_nan || b_nan) begin
          data = F64_CANON_NAN;  flags[FFLAG_NV] = any_sn;
        end
        else if (a_zero && b_zero) begin data = F64_CANON_NAN; flags[FFLAG_NV] = 1; end
        else if (a_inf  && b_inf)  begin data = F64_CANON_NAN; flags[FFLAG_NV] = 1; end
        else if (b_zero) begin
          data = {a[63]^b[63], F64_POS_INF[62:0]};  flags[FFLAG_DZ] = 1;
        end
        else if (a_inf)  data = {a[63]^b[63], F64_POS_INF[62:0]};
        else if (b_inf)  data = {a[63]^b[63], 63'b0};
        else if (a_zero) data = {a[63]^b[63], 63'b0};
        else begin
          ra = $bitstoreal(a);  rb = $bitstoreal(b);
          rr = ra / rb;
          data = $realtobits(rr);
          if (f64_is_inf(data)) begin
            flags[FFLAG_OF] = 1;  flags[FFLAG_NX] = 1;
          end
          else if (f64_is_zero(data) || is_denorm(data)) begin
            flags[FFLAG_UF] = 1;  flags[FFLAG_NX] = 1;
            if (f64_is_zero(data)) data = {a[63]^b[63], 63'b0};
          end
        end
      end

      UOPC_FMIN_D, UOPC_FMAX_D: begin
        bit take_a;
        flags[FFLAG_NV] = any_sn;
        if (a_nan && b_nan)  data = F64_CANON_NAN;
        else if (a_nan)      data = b;
        else if (b_nan)      data = a;
        else begin
          if (a_zero && b_zero)
            take_a = (op == UOPC_FMIN_D) ? a[63] : ~a[63];
          else begin
            ra = $bitstoreal(a);  rb = $bitstoreal(b);
            take_a = (op == UOPC_FMIN_D) ? (ra < rb) : (ra > rb);
          end
          data = take_a ? a : b;
        end
      end

      UOPC_FSGNJ_D:  data = {b[63], a[62:0]};
      UOPC_FCLASS_D: data = 64'd1 << f64_classify(a);
      default: ;
    endcase
  endfunction

  function bit is_denorm (logic [63:0] v);
    return (v[62:52] == 0) && (v[51:0] != 0);
  endfunction

  //-------------------------------------------------------------------------
  // Analysis-imp: accepted uops / branch broadcasts
  //-------------------------------------------------------------------------
  function void write_issued (boom_exe_txn tx);
    boom_exe_expect exp_i;

    if (tx.kind == boom_exe_txn::KIND_BR_UPDATE) begin
      if (tx.br_mispredict_valid) begin
        foreach (expect_q[idx]) begin
          if (|(expect_q[idx].br_mask & tx.br_mispredict_mask)) begin
            expect_q[idx].killed = 1;
            n_killed++;
            `uvm_info(get_type_name(),
                      $sformatf("rob=%0d marked KILLED by mispredict mask %02h",
                                idx, tx.br_mispredict_mask), UVM_HIGH)
          end
        end
      end
      if (tx.br_resolve_valid) begin
        foreach (expect_q[idx])
          expect_q[idx].br_mask &= ~tx.br_resolve_mask;
      end
      return;
    end

    exp_i          = new();
    exp_i.uopc     = tx.uopc;
    exp_i.pdst     = tx.pdst;
    exp_i.br_mask  = tx.br_mask;
    exp_i.killed   = 0;
    exp_i.exp_fflags_valid = 0;
    exp_i.exp_fflags       = '0;

    if (tx.is_fp()) begin
      predict_fp(tx.uopc, tx.rs1_data, tx.rs2_data,
                 exp_i.exp_data, exp_i.exp_fflags);
      exp_i.exp_fflags_valid = 1;
    end
    else if (tx.is_csr()) begin
      // CSR read-data is checked by the RAL mirror; the scoreboard only
      // tracks that the uop completes exactly once.
      exp_i.exp_fflags_valid = 0;
      exp_i.exp_data         = 'x;   // don't-care marker
    end
    else begin
      exp_i.exp_data = predict_int(tx.uopc, tx.rs1_data, tx.rs2_data);
    end

    if (expect_q.exists(tx.rob_idx))
      `uvm_error(get_type_name(),
                 $sformatf("rob_idx %0d reused while still outstanding", tx.rob_idx))
    expect_q[tx.rob_idx] = exp_i;
  endfunction

  //-------------------------------------------------------------------------
  // Analysis-imp: write-backs
  //-------------------------------------------------------------------------
  function void write_wb (boom_exe_txn tx);
    boom_exe_expect exp_i;

    if (!expect_q.exists(tx.rob_idx)) begin
      `uvm_error(get_type_name(),
                 $sformatf("unexpected write-back rob=%0d pdst=p%0d data=%016h",
                           tx.rob_idx, tx.pdst, tx.result))
      n_errors++;
      return;
    end

    exp_i = expect_q[tx.rob_idx];

    if (exp_i.killed) begin
      `uvm_error(get_type_name(),
                 $sformatf("KILLED uop wrote back! rob=%0d %s data=%016h -- misspeculated response must be gated off",
                           tx.rob_idx, exp_i.uopc.name(), tx.result))
      n_errors++;
      expect_q.delete(tx.rob_idx);
      return;
    end

    if (exp_i.pdst !== tx.pdst) begin
      `uvm_error(get_type_name(),
                 $sformatf("rob=%0d pdst mismatch: exp p%0d got p%0d",
                           tx.rob_idx, exp_i.pdst, tx.pdst))
      n_errors++;
    end

    // CSR result checked via RAL mirror -> only completion is tracked here
    if (!(exp_i.uopc inside {UOPC_CSRRW, UOPC_CSRRS, UOPC_CSRRC})) begin
      if (exp_i.exp_data !== tx.result) begin
        `uvm_error(get_type_name(),
                   $sformatf("rob=%0d %s DATA mismatch: exp %016h got %016h",
                             tx.rob_idx, exp_i.uopc.name(),
                             exp_i.exp_data, tx.result))
        n_errors++;
      end
      if (exp_i.exp_fflags_valid) begin
        if (!tx.fflags_valid) begin
          `uvm_error(get_type_name(),
                     $sformatf("rob=%0d %s expected fflags update but none seen",
                               tx.rob_idx, exp_i.uopc.name()))
          n_errors++;
        end
        else if (exp_i.exp_fflags !== tx.fflags) begin
          `uvm_error(get_type_name(),
                     $sformatf("rob=%0d %s FFLAGS mismatch: exp %05b got %05b",
                               tx.rob_idx, exp_i.uopc.name(),
                               exp_i.exp_fflags, tx.fflags))
          n_errors++;
        end
      end
    end

    n_checked++;
    expect_q.delete(tx.rob_idx);
  endfunction

  //-------------------------------------------------------------------------
  // End of test: killed uops may (must) be missing; anything else is lost
  //-------------------------------------------------------------------------
  virtual function void check_phase (uvm_phase phase);
    super.check_phase(phase);
    foreach (expect_q[idx]) begin
      if (!expect_q[idx].killed) begin
        `uvm_error(get_type_name(),
                   $sformatf("uop rob=%0d (%s) never wrote back",
                             idx, expect_q[idx].uopc.name()))
        n_errors++;
      end
    end
  endfunction

  virtual function void report_phase (uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("checked=%0d killed=%0d errors=%0d",
                        n_checked, n_killed, n_errors), UVM_LOW)
  endfunction

endclass : boom_exe_scoreboard

`endif

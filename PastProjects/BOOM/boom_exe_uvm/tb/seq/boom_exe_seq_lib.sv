//-----------------------------------------------------------------------------
// boom_exe_seq_lib.sv -- sequence library for the execute-pipeline TB.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_SEQ_LIB_SV
`define BOOM_EXE_SEQ_LIB_SV

//===========================================================================
// Base sequence: rob_idx bookkeeping shared by all stimulus sequences
//===========================================================================
class boom_exe_base_seq extends uvm_sequence #(boom_exe_txn);
  `uvm_object_utils(boom_exe_base_seq)

  static int unsigned g_rob_idx = 0;   // monotonically increasing tag

  function new (string name = "boom_exe_base_seq");
    super.new(name);
  endfunction

  function int unsigned next_rob_idx ();
    g_rob_idx = (g_rob_idx + 1) % (1 << ROB_ID_W);
    return g_rob_idx;
  endfunction
endclass : boom_exe_base_seq

//===========================================================================
// Random integer ALU traffic
//===========================================================================
class boom_alu_rand_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_alu_rand_seq)

  rand int unsigned num_txns;
  constraint c_num { num_txns inside {[20:60]}; }

  function new (string name = "boom_alu_rand_seq");
    super.new(name);
  endfunction

  virtual task body ();
    boom_exe_txn tx;
    int unsigned ridx;
    repeat (num_txns) begin
      tx = boom_exe_txn::type_id::create("tx");
      ridx = next_rob_idx();
      start_item(tx);
      if (!tx.randomize() with {
            kind == boom_exe_txn::KIND_UOP;
            uopc inside {UOPC_ADD, UOPC_SUB, UOPC_AND, UOPC_OR, UOPC_XOR,
                         UOPC_SLT, UOPC_SLTU, UOPC_SLL, UOPC_SRL, UOPC_SRA};
            rob_idx == local::ridx;
          })
        `uvm_fatal(get_type_name(), "randomize failed")
      finish_item(tx);
    end
  endtask
endclass : boom_alu_rand_seq

//===========================================================================
// Integer multiply / divide, including the RISC-V M corner cases:
// divide-by-zero (quotient = -1, remainder = dividend) and the
// signed-overflow case MIN_INT / -1.
//===========================================================================
class boom_muldiv_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_muldiv_seq)

  rand int unsigned num_rand;
  constraint c_num { num_rand inside {[10:30]}; }

  function new (string name = "boom_muldiv_seq");
    super.new(name);
  endfunction

  task drive_op (uopc_e op, logic [63:0] a, logic [63:0] b);
    boom_exe_txn tx = boom_exe_txn::type_id::create("tx");
    int unsigned ridx = next_rob_idx();
    start_item(tx);
    if (!tx.randomize() with {
          kind     == boom_exe_txn::KIND_UOP;
          uopc     == local::op;
          rs1_data == local::a;
          rs2_data == local::b;
          rob_idx  == local::ridx;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(tx);
  endtask

  virtual task body ();
    boom_exe_txn tx;
    int unsigned ridx;

    // ---- directed corners ----
    drive_op(UOPC_DIV,  64'd42,                  64'd0);  // div by zero -> -1
    drive_op(UOPC_DIVU, 64'd42,                  64'd0);  // -> all ones
    drive_op(UOPC_REM,  64'd42,                  64'd0);  // -> dividend
    drive_op(UOPC_REMU, 64'd42,                  64'd0);  // -> dividend
    drive_op(UOPC_DIV,  64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF); // overflow -> MIN_INT
    drive_op(UOPC_REM,  64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF); // -> 0
    drive_op(UOPC_MULH, 64'h8000_0000_0000_0000, 64'h8000_0000_0000_0000);
    drive_op(UOPC_MUL,  64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF);

    // ---- random traffic ----
    repeat (num_rand) begin
      tx = boom_exe_txn::type_id::create("tx");
      ridx = next_rob_idx();
      start_item(tx);
      if (!tx.randomize() with {
            kind == boom_exe_txn::KIND_UOP;
            uopc inside {UOPC_MUL, UOPC_MULH, UOPC_MULHU,
                         UOPC_DIV, UOPC_DIVU, UOPC_REM, UOPC_REMU};
            rob_idx == local::ridx;
          })
        `uvm_fatal(get_type_name(), "randomize failed")
      finish_item(tx);
    end
  endtask
endclass : boom_muldiv_seq

//===========================================================================
// IEEE-754 corner-case FP sequence.
// Crosses a curated list of special operand encodings (+-0, +-inf,
// qNaN, sNaN, subnormals, max/min normal) across FP ops, then adds
// constrained-random traffic biased toward special values.
//===========================================================================
class boom_fp_corner_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_fp_corner_seq)

  rand int unsigned num_rand;
  constraint c_num { num_rand inside {[30:80]}; }

  // The corner menagerie
  static logic [63:0] specials[] = '{
    F64_POS_ZERO, F64_NEG_ZERO,
    F64_POS_INF,  F64_NEG_INF,
    F64_CANON_NAN, F64_SNAN,
    F64_MIN_DENOM, F64_MAX_DENOM,
    F64_MIN_NORM,  F64_MAX_NORM,
    F64_ONE,       64'hBFF0_0000_0000_0000  // -1.0
  };

  function new (string name = "boom_fp_corner_seq");
    super.new(name);
  endfunction

  task drive_op (uopc_e op, logic [63:0] a, logic [63:0] b);
    boom_exe_txn tx = boom_exe_txn::type_id::create("tx");
    int unsigned ridx = next_rob_idx();
    start_item(tx);
    if (!tx.randomize() with {
          kind     == boom_exe_txn::KIND_UOP;
          uopc     == local::op;
          rs1_data == local::a;
          rs2_data == local::b;
          rob_idx  == local::ridx;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(tx);
  endtask

  virtual task body ();
    boom_exe_txn tx;
    int unsigned ridx;
    uopc_e fp_ops[] = '{UOPC_FADD_D, UOPC_FSUB_D, UOPC_FMUL_D,
                        UOPC_FMIN_D, UOPC_FMAX_D, UOPC_FDIV_D};

    // ---- full cross of specials for add/mul/div (the interesting ones) ----
    foreach (fp_ops[k]) begin
      foreach (specials[i]) begin
        foreach (specials[j])
          drive_op(fp_ops[k], specials[i], specials[j]);
      end
    end

    // ---- classify every special ----
    foreach (specials[i])
      drive_op(UOPC_FCLASS_D, specials[i], 64'd0);

    // ---- targeted extras ----
    drive_op(UOPC_FADD_D, F64_POS_INF,  F64_NEG_INF);   // qNaN + NV
    drive_op(UOPC_FMUL_D, F64_POS_INF,  F64_POS_ZERO);  // qNaN + NV
    drive_op(UOPC_FDIV_D, F64_ONE,      F64_POS_ZERO);  // +inf + DZ
    drive_op(UOPC_FDIV_D, F64_ONE,      F64_NEG_ZERO);  // -inf + DZ
    drive_op(UOPC_FDIV_D, F64_POS_ZERO, F64_POS_ZERO);  // qNaN + NV
    drive_op(UOPC_FMUL_D, F64_MAX_NORM, F64_MAX_NORM);  // +inf + OF,NX
    drive_op(UOPC_FMUL_D, F64_MIN_DENOM, F64_MIN_DENOM);// -> 0  + UF,NX
    drive_op(UOPC_FSGNJ_D, F64_ONE,     F64_NEG_ZERO);  // -1.0, no flags

    // ---- random, biased toward specials ----
    repeat (num_rand) begin
      tx = boom_exe_txn::type_id::create("tx");
      ridx = next_rob_idx();
      start_item(tx);
      if (!tx.randomize() with {
            kind == boom_exe_txn::KIND_UOP;
            uopc inside {UOPC_FADD_D, UOPC_FSUB_D, UOPC_FMUL_D, UOPC_FMIN_D,
                         UOPC_FMAX_D, UOPC_FSGNJ_D, UOPC_FCLASS_D, UOPC_FDIV_D};
            rs1_data dist { F64_POS_INF   := 2, F64_NEG_INF  := 2,
                            F64_CANON_NAN := 2, F64_SNAN     := 2,
                            F64_NEG_ZERO  := 2, F64_MIN_DENOM:= 2,
                            [64'h0:64'hFFFF_FFFF_FFFF_FFFF] :/ 8 };
            rs2_data dist { F64_POS_INF   := 2, F64_NEG_INF  := 2,
                            F64_CANON_NAN := 2, F64_SNAN     := 2,
                            F64_NEG_ZERO  := 2, F64_MIN_DENOM:= 2,
                            [64'h0:64'hFFFF_FFFF_FFFF_FFFF] :/ 8 };
            rob_idx == local::ridx;
          })
        `uvm_fatal(get_type_name(), "randomize failed")
      finish_item(tx);
    end
  endtask
endclass : boom_fp_corner_seq

//===========================================================================
// Raw CSR smoke sequence (frontdoor traffic without RAL, exercising the
// serialized CSRRW/CSRRS/CSRRC path directly)
//===========================================================================
class boom_csr_smoke_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_csr_smoke_seq)

  function new (string name = "boom_csr_smoke_seq");
    super.new(name);
  endfunction

  task csr_op (uopc_e op, logic [11:0] addr, logic [63:0] wdata);
    boom_exe_txn tx = boom_exe_txn::type_id::create("tx");
    int unsigned ridx = next_rob_idx();
    start_item(tx);
    if (!tx.randomize() with {
          kind     == boom_exe_txn::KIND_UOP;
          uopc     == local::op;
          csr_addr == local::addr;
          rs1_data == local::wdata;
          rob_idx  == local::ridx;
          gap_cycles inside {[4:8]};   // serialized: keep pipe drained
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(tx);
  endtask

  virtual task body ();
    csr_op(UOPC_CSRRW, CSR_MSCRATCH, 64'hDEAD_BEEF_CAFE_F00D);
    csr_op(UOPC_CSRRS, CSR_MSCRATCH, 64'h0000_0000_0000_00FF);
    csr_op(UOPC_CSRRC, CSR_MSCRATCH, 64'hFF00_0000_0000_0000);
    csr_op(UOPC_CSRRS, CSR_MSCRATCH, 64'd0);            // pure read
    csr_op(UOPC_CSRRW, CSR_MEPC,     64'h0000_0000_8000_01FF); // bit0 -> WARL 0
    csr_op(UOPC_CSRRW, CSR_MTVEC,    64'h0000_0000_8000_0001);
    csr_op(UOPC_CSRRS, CSR_MISA,     64'd0);            // read RO
    csr_op(UOPC_CSRRS, CSR_MARCHID,  64'd0);            // BOOM's arch id (2)
    csr_op(UOPC_CSRRS, CSR_MCYCLE,   64'd0);
    csr_op(UOPC_CSRRW, CSR_FCSR,     64'h0000_0000_0000_00E5); // frm=7,fflags=5
    csr_op(UOPC_CSRRS, CSR_FFLAGS,   64'd0);
    csr_op(UOPC_CSRRC, CSR_FFLAGS,   64'h1F);           // clear flags
  endtask
endclass : boom_csr_smoke_seq

//===========================================================================
// Branch speculation / kill sequence.
// Issues uops speculated under branch tags, then either resolves the
// branch (uops complete) or broadcasts a mispredict (uops must be killed
// and never write back).
//===========================================================================
class boom_branch_spec_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_branch_spec_seq)

  rand int unsigned num_rounds;
  constraint c_rounds { num_rounds inside {[4:8]}; }

  function new (string name = "boom_branch_spec_seq");
    super.new(name);
  endfunction

  virtual task body ();
    boom_exe_txn tx;
    int unsigned ridx;

    repeat (num_rounds) begin
      logic [BR_MASK_W-1:0] tag = 1 << $urandom_range(0, BR_MASK_W-1);
      bit mispredict = $urandom_range(0, 1);

      // a few uops speculated under `tag` (long-latency ones included so
      // they are still in flight when the branch resolves)
      repeat ($urandom_range(2, 4)) begin
        tx = boom_exe_txn::type_id::create("tx");
        ridx = next_rob_idx();
        start_item(tx);
        if (!tx.randomize() with {
              kind == boom_exe_txn::KIND_UOP;
              uopc inside {UOPC_ADD, UOPC_MUL, UOPC_FADD_D, UOPC_DIV};
              br_mask == local::tag;
              gap_cycles == 0;
              rob_idx == local::ridx;
            })
          `uvm_fatal(get_type_name(), "randomize failed")
        finish_item(tx);
      end

      // Branch Unit broadcast: resolve OK or mispredict
      tx = boom_exe_txn::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
            kind == boom_exe_txn::KIND_BR_UPDATE;
            br_resolve_valid    == !local::mispredict;
            br_resolve_mask     == local::tag;
            br_mispredict_valid == local::mispredict;
            br_mispredict_mask  == local::tag;
            gap_cycles inside {[0:2]};
          })
        `uvm_fatal(get_type_name(), "randomize failed")
      finish_item(tx);

      // drain
      tx = boom_exe_txn::type_id::create("tx");
      ridx = next_rob_idx();
      start_item(tx);
      if (!tx.randomize() with {
            kind == boom_exe_txn::KIND_UOP;
            uopc == UOPC_ADD;
            br_mask == '0;
            gap_cycles inside {[6:10]};
            rob_idx == local::ridx;
          })
        `uvm_fatal(get_type_name(), "randomize failed")
      finish_item(tx);
    end
  endtask
endclass : boom_branch_spec_seq

`endif

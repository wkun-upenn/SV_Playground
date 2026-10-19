//-----------------------------------------------------------------------------
// boom_exe_coverage.sv -- functional coverage for the execute pipeline:
// opcode coverage, IEEE-754 operand-class coverage (incl. +-inf, +-0,
// qNaN/sNaN, subnormals) crossed with FP ops, fflags coverage, CSR
// address coverage, and branch-speculation events.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_COVERAGE_SV
`define BOOM_EXE_COVERAGE_SV

class boom_exe_coverage extends uvm_subscriber #(boom_exe_txn);
  `uvm_component_utils(boom_exe_coverage)

  boom_exe_txn tr;

  covergroup cg_uop;
    option.per_instance = 1;
    cp_uopc: coverpoint tr.uopc {
      bins alu[]    = {UOPC_ADD, UOPC_SUB, UOPC_AND, UOPC_OR, UOPC_XOR,
                       UOPC_SLT, UOPC_SLTU, UOPC_SLL, UOPC_SRL, UOPC_SRA};
      bins muldiv[] = {UOPC_MUL, UOPC_MULH, UOPC_MULHU,
                       UOPC_DIV, UOPC_DIVU, UOPC_REM, UOPC_REMU};
      bins fp[]     = {UOPC_FADD_D, UOPC_FSUB_D, UOPC_FMUL_D, UOPC_FMIN_D,
                       UOPC_FMAX_D, UOPC_FSGNJ_D, UOPC_FCLASS_D, UOPC_FDIV_D};
      bins csr[]    = {UOPC_CSRRW, UOPC_CSRRS, UOPC_CSRRC};
    }
    cp_spec: coverpoint (|tr.br_mask) {
      bins speculated     = {1};
      bins non_speculated = {0};
    }
  endgroup

  covergroup cg_fp;
    option.per_instance = 1;
    cp_op: coverpoint tr.uopc {
      bins fadd  = {UOPC_FADD_D};  bins fsub   = {UOPC_FSUB_D};
      bins fmul  = {UOPC_FMUL_D};  bins fdiv   = {UOPC_FDIV_D};
      bins fmin  = {UOPC_FMIN_D};  bins fmax   = {UOPC_FMAX_D};
      bins fsgnj = {UOPC_FSGNJ_D}; bins fclass = {UOPC_FCLASS_D};
    }
    cp_cls_a: coverpoint f64_classify(tr.rs1_data) {
      bins neg_inf   = {FCLASS_NEG_INF};   bins pos_inf   = {FCLASS_POS_INF};
      bins neg_norm  = {FCLASS_NEG_NORM};  bins pos_norm  = {FCLASS_POS_NORM};
      bins neg_denom = {FCLASS_NEG_DENOM}; bins pos_denom = {FCLASS_POS_DENOM};
      bins neg_zero  = {FCLASS_NEG_ZERO};  bins pos_zero  = {FCLASS_POS_ZERO};
      bins snan      = {FCLASS_SNAN};      bins qnan      = {FCLASS_QNAN};
    }
    cp_cls_b: coverpoint f64_classify(tr.rs2_data) {
      bins neg_inf   = {FCLASS_NEG_INF};   bins pos_inf   = {FCLASS_POS_INF};
      bins neg_norm  = {FCLASS_NEG_NORM};  bins pos_norm  = {FCLASS_POS_NORM};
      bins neg_denom = {FCLASS_NEG_DENOM}; bins pos_denom = {FCLASS_POS_DENOM};
      bins neg_zero  = {FCLASS_NEG_ZERO};  bins pos_zero  = {FCLASS_POS_ZERO};
      bins snan      = {FCLASS_SNAN};      bins qnan      = {FCLASS_QNAN};
    }
    x_op_cls: cross cp_op, cp_cls_a, cp_cls_b {
      // fclass doesn't meaningfully consume rs2
      ignore_bins no_rs2 = binsof(cp_op.fclass);
    }
  endgroup

  covergroup cg_csr;
    option.per_instance = 1;
    cp_op: coverpoint tr.uopc {
      bins rw = {UOPC_CSRRW};  bins rs = {UOPC_CSRRS};  bins rc = {UOPC_CSRRC};
    }
    cp_addr: coverpoint tr.csr_addr {
      bins fflags    = {CSR_FFLAGS};    bins frm      = {CSR_FRM};
      bins fcsr      = {CSR_FCSR};      bins mstatus  = {CSR_MSTATUS};
      bins misa      = {CSR_MISA};      bins mie      = {CSR_MIE};
      bins mtvec     = {CSR_MTVEC};     bins mscratch = {CSR_MSCRATCH};
      bins mepc      = {CSR_MEPC};      bins mcause   = {CSR_MCAUSE};
      bins mtval     = {CSR_MTVAL};     bins mip      = {CSR_MIP};
      bins mcycle    = {CSR_MCYCLE};    bins minstret = {CSR_MINSTRET};
      bins mvendorid = {CSR_MVENDORID}; bins marchid  = {CSR_MARCHID};
      bins mimpid    = {CSR_MIMPID};    bins mhartid  = {CSR_MHARTID};
    }
    x_op_addr: cross cp_op, cp_addr;
  endgroup

  covergroup cg_br;
    option.per_instance = 1;
    cp_event: coverpoint {tr.br_mispredict_valid, tr.br_resolve_valid} {
      bins resolve    = {2'b01};
      bins mispredict = {2'b10};
      bins both       = {2'b11};
    }
  endgroup

  function new (string name, uvm_component parent);
    super.new(name, parent);
    cg_uop = new();
    cg_fp  = new();
    cg_csr = new();
    cg_br  = new();
  endfunction

  virtual function void write (boom_exe_txn t);
    tr = t;
    if (t.kind == boom_exe_txn::KIND_BR_UPDATE) begin
      cg_br.sample();
      return;
    end
    cg_uop.sample();
    if (t.is_fp())  cg_fp.sample();
    if (t.is_csr()) cg_csr.sample();
  endfunction

endclass : boom_exe_coverage

`endif

//-----------------------------------------------------------------------------
// boom_exe_txn.sv -- sequence item for one execute-pipeline micro-op.
//
// A txn is either a uop issued to the Execution Unit or a Branch-Unit
// broadcast (resolve / mispredict), selected by `kind`.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_TXN_SV
`define BOOM_EXE_TXN_SV

class boom_exe_txn extends uvm_sequence_item;

  typedef enum { KIND_UOP, KIND_BR_UPDATE } kind_e;

  rand kind_e                 kind;

  // ---- uop fields ----
  rand uopc_e                 uopc;
  rand logic [ROB_ID_W-1:0]   rob_idx;
  rand logic [PREG_W-1:0]     pdst;
  rand logic [XLEN-1:0]       rs1_data;
  rand logic [XLEN-1:0]       rs2_data;
  rand logic [BR_MASK_W-1:0]  br_mask;
  rand logic [CSR_ADDR_W-1:0] csr_addr;

  // ---- branch update fields ----
  rand logic                  br_resolve_valid;
  rand logic [BR_MASK_W-1:0]  br_resolve_mask;
  rand logic                  br_mispredict_valid;
  rand logic [BR_MASK_W-1:0]  br_mispredict_mask;

  // ---- captured by the monitor on write-back ----
  logic [XLEN-1:0]            result;
  logic [4:0]                 fflags;
  bit                         fflags_valid;
  int unsigned                wb_port;

  // ---- helper knobs for constraint control ----
  rand int unsigned           gap_cycles;   // idle cycles before driving

  constraint c_kind_default   { soft kind == KIND_UOP; }
  constraint c_gap            { gap_cycles inside {[0:3]}; }
  constraint c_no_nop         { uopc != UOPC_NOP; }
  constraint c_csr_addr_valid {
    csr_addr inside {CSR_FFLAGS, CSR_FRM, CSR_FCSR, CSR_MSTATUS, CSR_MISA,
                     CSR_MIE, CSR_MTVEC, CSR_MSCRATCH, CSR_MEPC, CSR_MCAUSE,
                     CSR_MTVAL, CSR_MIP, CSR_MCYCLE, CSR_MINSTRET,
                     CSR_MVENDORID, CSR_MARCHID, CSR_MIMPID, CSR_MHARTID};
  }
  constraint c_spec_default   { soft br_mask == '0; }
  constraint c_br_fields      {
    if (kind == KIND_UOP) {
      br_resolve_valid    == 1'b0;
      br_mispredict_valid == 1'b0;
    }
  }

  `uvm_object_utils_begin(boom_exe_txn)
    `uvm_field_enum(kind_e, kind,          UVM_ALL_ON)
    `uvm_field_enum(uopc_e, uopc,          UVM_ALL_ON)
    `uvm_field_int(rob_idx,                UVM_ALL_ON)
    `uvm_field_int(pdst,                   UVM_ALL_ON)
    `uvm_field_int(rs1_data,               UVM_ALL_ON)
    `uvm_field_int(rs2_data,               UVM_ALL_ON)
    `uvm_field_int(br_mask,                UVM_ALL_ON)
    `uvm_field_int(csr_addr,               UVM_ALL_ON)
    `uvm_field_int(br_resolve_valid,       UVM_ALL_ON)
    `uvm_field_int(br_resolve_mask,        UVM_ALL_ON)
    `uvm_field_int(br_mispredict_valid,    UVM_ALL_ON)
    `uvm_field_int(br_mispredict_mask,     UVM_ALL_ON)
    `uvm_field_int(result,                 UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(fflags,                 UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new (string name = "boom_exe_txn");
    super.new(name);
  endfunction

  function bit is_fp ();
    return uopc inside {UOPC_FADD_D, UOPC_FSUB_D, UOPC_FMUL_D, UOPC_FMIN_D,
                        UOPC_FMAX_D, UOPC_FSGNJ_D, UOPC_FCLASS_D, UOPC_FDIV_D};
  endfunction

  function bit is_csr ();
    return uopc inside {UOPC_CSRRW, UOPC_CSRRS, UOPC_CSRRC};
  endfunction

  function bit is_unpipelined ();
    return uopc inside {UOPC_DIV, UOPC_DIVU, UOPC_REM, UOPC_REMU, UOPC_FDIV_D};
  endfunction

  function string convert2string ();
    if (kind == KIND_BR_UPDATE)
      return $sformatf("BR_UPDATE resolve=%0b(%02h) mispredict=%0b(%02h)",
                       br_resolve_valid, br_resolve_mask,
                       br_mispredict_valid, br_mispredict_mask);
    return $sformatf("%s rob=%0d pdst=p%0d rs1=%016h rs2=%016h brmask=%02h csr=%03h",
                     uopc.name(), rob_idx, pdst, rs1_data, rs2_data,
                     br_mask, csr_addr);
  endfunction

endclass : boom_exe_txn

`endif

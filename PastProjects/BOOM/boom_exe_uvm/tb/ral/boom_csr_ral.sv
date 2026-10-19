//-----------------------------------------------------------------------------
// boom_csr_ral.sv -- UVM register model (RAL) for the CSRs reachable from
// BOOM's execute pipeline.  The map's "address" is the 12-bit RISC-V CSR
// number itself (byte_addressing = 0), matching how CSR uops address the
// CSRFile.  WARL behavior and hardware side effects (fflags accumulation
// from FP write-backs, free-running counters, mstatus.FS/SD) are modeled
// with volatile fields.
//
// BOOM note: CSRs are NOT renamed.  A CSR instruction is marked "unique"
// (serializing) -- the ROB must drain before it issues.  The RAL frontdoor
// sequence below reproduces that by spacing CSR ops apart.
//-----------------------------------------------------------------------------
`ifndef BOOM_CSR_RAL_SV
`define BOOM_CSR_RAL_SV

//===========================================================================
// Floating-point CSRs
//===========================================================================
class boom_reg_fflags extends uvm_reg;
  `uvm_object_utils(boom_reg_fflags)
  rand uvm_reg_field NX, UF, OF, DZ, NV;

  function new (string name = "fflags");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    NX = uvm_reg_field::type_id::create("NX");
    UF = uvm_reg_field::type_id::create("UF");
    OF = uvm_reg_field::type_id::create("OF");
    DZ = uvm_reg_field::type_id::create("DZ");
    NV = uvm_reg_field::type_id::create("NV");
    //            parent size lsb access  volatile reset has_reset rand accessible
    NX.configure(this, 1, 0, "RW", 1, 1'b0, 1, 1, 1);
    UF.configure(this, 1, 1, "RW", 1, 1'b0, 1, 1, 1);
    OF.configure(this, 1, 2, "RW", 1, 1'b0, 1, 1, 1);
    DZ.configure(this, 1, 3, "RW", 1, 1'b0, 1, 1, 1);
    NV.configure(this, 1, 4, "RW", 1, 1'b0, 1, 1, 1);
  endfunction
endclass

class boom_reg_frm extends uvm_reg;
  `uvm_object_utils(boom_reg_frm)
  rand uvm_reg_field rm;

  function new (string name = "frm");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    rm = uvm_reg_field::type_id::create("rm");
    rm.configure(this, 3, 0, "RW", 1, 3'b000, 1, 1, 1);
  endfunction
endclass

// fcsr = {frm[7:5], fflags[4:0]} -- an architectural alias of the two above.
class boom_reg_fcsr extends uvm_reg;
  `uvm_object_utils(boom_reg_fcsr)
  rand uvm_reg_field fflags, frm;

  function new (string name = "fcsr");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    fflags = uvm_reg_field::type_id::create("fflags");
    frm    = uvm_reg_field::type_id::create("frm");
    fflags.configure(this, 5, 0, "RW", 1, 5'b0, 1, 1, 1);
    frm.configure   (this, 3, 5, "RW", 1, 3'b0, 1, 1, 1);
  endfunction
endclass

//===========================================================================
// Machine-mode CSRs
//===========================================================================
class boom_reg_mstatus extends uvm_reg;
  `uvm_object_utils(boom_reg_mstatus)
  rand uvm_reg_field MIE, MPIE, MPP, FS;
  uvm_reg_field SD;

  function new (string name = "mstatus");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    MIE  = uvm_reg_field::type_id::create("MIE");
    MPIE = uvm_reg_field::type_id::create("MPIE");
    MPP  = uvm_reg_field::type_id::create("MPP");
    FS   = uvm_reg_field::type_id::create("FS");
    SD   = uvm_reg_field::type_id::create("SD");
    MIE.configure (this, 1,  3, "RW", 0, 1'b0,  1, 1, 1);
    MPIE.configure(this, 1,  7, "RW", 0, 1'b0,  1, 1, 1);
    MPP.configure (this, 2, 11, "RW", 0, 2'b11, 1, 1, 1);
    FS.configure  (this, 2, 13, "RW", 1, 2'b00, 1, 1, 1); // set dirty by FP wb
    SD.configure  (this, 1, 63, "RO", 1, 1'b0,  1, 0, 1); // derived from FS
  endfunction
endclass

class boom_reg_misa extends uvm_reg;
  `uvm_object_utils(boom_reg_misa)
  uvm_reg_field value;

  function new (string name = "misa");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    // RV64 IMAFDC + U, MXL = 2 (WARL, writes ignored -> model as RO)
    value.configure(this, 64, 0, "RO", 0, MISA_RESET_VAL, 1, 0, 1);
  endfunction
endclass

class boom_reg_mie extends uvm_reg;
  `uvm_object_utils(boom_reg_mie)
  rand uvm_reg_field SSIE, MSIE, STIE, MTIE, SEIE, MEIE;

  function new (string name = "mie");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    SSIE = uvm_reg_field::type_id::create("SSIE");
    MSIE = uvm_reg_field::type_id::create("MSIE");
    STIE = uvm_reg_field::type_id::create("STIE");
    MTIE = uvm_reg_field::type_id::create("MTIE");
    SEIE = uvm_reg_field::type_id::create("SEIE");
    MEIE = uvm_reg_field::type_id::create("MEIE");
    SSIE.configure(this, 1,  1, "RW", 0, 1'b0, 1, 1, 1);
    MSIE.configure(this, 1,  3, "RW", 0, 1'b0, 1, 1, 1);
    STIE.configure(this, 1,  5, "RW", 0, 1'b0, 1, 1, 1);
    MTIE.configure(this, 1,  7, "RW", 0, 1'b0, 1, 1, 1);
    SEIE.configure(this, 1,  9, "RW", 0, 1'b0, 1, 1, 1);
    MEIE.configure(this, 1, 11, "RW", 0, 1'b0, 1, 1, 1);
  endfunction
endclass

class boom_reg_mtvec extends uvm_reg;
  `uvm_object_utils(boom_reg_mtvec)
  rand uvm_reg_field MODE, BASE;

  function new (string name = "mtvec");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    MODE = uvm_reg_field::type_id::create("MODE");
    BASE = uvm_reg_field::type_id::create("BASE");
    MODE.configure(this, 1,  0, "RW", 0, 1'b0,  1, 1, 1); // WARL: mode<=1
    BASE.configure(this, 62, 2, "RW", 0, 62'b0, 1, 1, 1);
  endfunction
endclass

class boom_reg_rw64 extends uvm_reg;
  `uvm_object_utils(boom_reg_rw64)
  rand uvm_reg_field value;

  function new (string name = "rw64");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    value.configure(this, 64, 0, "RW", 0, 64'b0, 1, 1, 1);
  endfunction
endclass

class boom_reg_mepc extends uvm_reg;
  `uvm_object_utils(boom_reg_mepc)
  rand uvm_reg_field value;

  function new (string name = "mepc");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    // WARL: bit 0 always reads 0 (IALIGN); keep bit 1 for RVC
    value.configure(this, 63, 1, "RW", 0, 63'b0, 1, 1, 1);
  endfunction
endclass

class boom_reg_ro_volatile extends uvm_reg;
  `uvm_object_utils(boom_reg_ro_volatile)
  uvm_reg_field value;

  function new (string name = "ro_volatile");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    value.configure(this, 64, 0, "RO", 1, 64'b0, 1, 0, 1);
  endfunction
endclass

class boom_reg_counter64 extends uvm_reg;
  `uvm_object_utils(boom_reg_counter64)
  rand uvm_reg_field value;

  function new (string name = "counter64");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    value.configure(this, 64, 0, "RW", 1, 64'b0, 1, 1, 1); // volatile
  endfunction
endclass

class boom_reg_ro_const extends uvm_reg;
  `uvm_object_utils(boom_reg_ro_const)
  uvm_reg_field value;
  protected uvm_reg_data_t m_reset_val;

  function new (string name = "ro_const");
    super.new(name, 64, UVM_NO_COVERAGE);
  endfunction

  function void set_reset_val (uvm_reg_data_t v);
    m_reset_val = v;
  endfunction

  virtual function void build ();
    value = uvm_reg_field::type_id::create("value");
    value.configure(this, 64, 0, "RO", 0, m_reset_val, 1, 0, 1);
  endfunction
endclass

//===========================================================================
// The CSR register block
//===========================================================================
class boom_csr_reg_block extends uvm_reg_block;
  `uvm_object_utils(boom_csr_reg_block)

  rand boom_reg_fflags      fflags;
  rand boom_reg_frm         frm;
  rand boom_reg_fcsr        fcsr;
  rand boom_reg_mstatus     mstatus;
  boom_reg_misa             misa;
  rand boom_reg_mie         mie;
  rand boom_reg_mtvec       mtvec;
  rand boom_reg_rw64        mscratch;
  rand boom_reg_mepc        mepc;
  rand boom_reg_rw64        mcause;
  rand boom_reg_rw64        mtval;
  boom_reg_ro_volatile      mip;
  rand boom_reg_counter64   mcycle;
  rand boom_reg_counter64   minstret;
  boom_reg_ro_const         mvendorid;
  boom_reg_ro_const         marchid;
  boom_reg_ro_const         mimpid;
  boom_reg_ro_const         mhartid;

  uvm_reg_map csr_map;

  function new (string name = "boom_csr_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build ();
    fflags    = boom_reg_fflags::type_id::create("fflags");
    frm       = boom_reg_frm::type_id::create("frm");
    fcsr      = boom_reg_fcsr::type_id::create("fcsr");
    mstatus   = boom_reg_mstatus::type_id::create("mstatus");
    misa      = boom_reg_misa::type_id::create("misa");
    mie       = boom_reg_mie::type_id::create("mie");
    mtvec     = boom_reg_mtvec::type_id::create("mtvec");
    mscratch  = boom_reg_rw64::type_id::create("mscratch");
    mepc      = boom_reg_mepc::type_id::create("mepc");
    mcause    = boom_reg_rw64::type_id::create("mcause");
    mtval     = boom_reg_rw64::type_id::create("mtval");
    mip       = boom_reg_ro_volatile::type_id::create("mip");
    mcycle    = boom_reg_counter64::type_id::create("mcycle");
    minstret  = boom_reg_counter64::type_id::create("minstret");
    mvendorid = boom_reg_ro_const::type_id::create("mvendorid");
    marchid   = boom_reg_ro_const::type_id::create("marchid");
    mimpid    = boom_reg_ro_const::type_id::create("mimpid");
    mhartid   = boom_reg_ro_const::type_id::create("mhartid");

    mvendorid.set_reset_val(64'd0);
    marchid.set_reset_val(MARCHID_BOOM);   // open-source arch ID 2 = BOOM
    mimpid.set_reset_val(64'd0);
    mhartid.set_reset_val(64'd0);

    fflags.configure(this);       fflags.build();
    frm.configure(this);          frm.build();
    fcsr.configure(this);         fcsr.build();
    mstatus.configure(this);      mstatus.build();
    misa.configure(this);         misa.build();
    mie.configure(this);          mie.build();
    mtvec.configure(this);        mtvec.build();
    mscratch.configure(this);     mscratch.build();
    mepc.configure(this);         mepc.build();
    mcause.configure(this);       mcause.build();
    mtval.configure(this);        mtval.build();
    mip.configure(this);          mip.build();
    mcycle.configure(this);       mcycle.build();
    minstret.configure(this);     minstret.build();
    mvendorid.configure(this);    mvendorid.build();
    marchid.configure(this);      marchid.build();
    mimpid.configure(this);       mimpid.build();
    mhartid.configure(this);      mhartid.build();

    // Address = 12-bit CSR number (unit stride, not byte-scaled)
    csr_map = create_map("csr_map", 'h0, 8, UVM_LITTLE_ENDIAN, 0);
    default_map = csr_map;

    csr_map.add_reg(fflags,    CSR_FFLAGS,    "RW");
    csr_map.add_reg(frm,       CSR_FRM,       "RW");
    csr_map.add_reg(fcsr,      CSR_FCSR,      "RW");
    csr_map.add_reg(mstatus,   CSR_MSTATUS,   "RW");
    csr_map.add_reg(misa,      CSR_MISA,      "RO");
    csr_map.add_reg(mie,       CSR_MIE,       "RW");
    csr_map.add_reg(mtvec,     CSR_MTVEC,     "RW");
    csr_map.add_reg(mscratch,  CSR_MSCRATCH,  "RW");
    csr_map.add_reg(mepc,      CSR_MEPC,      "RW");
    csr_map.add_reg(mcause,    CSR_MCAUSE,    "RW");
    csr_map.add_reg(mtval,     CSR_MTVAL,     "RW");
    csr_map.add_reg(mip,       CSR_MIP,       "RO");
    csr_map.add_reg(mcycle,    CSR_MCYCLE,    "RW");
    csr_map.add_reg(minstret,  CSR_MINSTRET,  "RW");
    csr_map.add_reg(mvendorid, CSR_MVENDORID, "RO");
    csr_map.add_reg(marchid,   CSR_MARCHID,   "RO");
    csr_map.add_reg(mimpid,    CSR_MIMPID,    "RO");
    csr_map.add_reg(mhartid,   CSR_MHARTID,   "RO");

    // WARL registers: exclude from bit-bash style built-in sequences
    uvm_resource_db#(bit)::set({"REG::", mstatus.get_full_name()},
                               "NO_REG_BIT_BASH_TEST", 1);
    uvm_resource_db#(bit)::set({"REG::", mtvec.get_full_name()},
                               "NO_REG_BIT_BASH_TEST", 1);
    uvm_resource_db#(bit)::set({"REG::", mepc.get_full_name()},
                               "NO_REG_BIT_BASH_TEST", 1);
    uvm_resource_db#(bit)::set({"REG::", mie.get_full_name()},
                               "NO_REG_BIT_BASH_TEST", 1);

    lock_model();
  endfunction

endclass : boom_csr_reg_block

//===========================================================================
// Adapter: uvm_reg_bus_op <-> boom_exe_txn (CSR micro-ops)
//
//   RAL write -> CSRRW  (rs1 = data)
//   RAL read  -> CSRRS  (rs1 = x0/0: pure read, no side effect)
//
// The driver completes a CSR uop only after its write-back returns the old
// CSR value, so read data is available in the request item (provides_responses = 0).
//===========================================================================
class boom_csr_adapter extends uvm_reg_adapter;
  `uvm_object_utils(boom_csr_adapter)

  function new (string name = "boom_csr_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
    boom_exe_txn tx = boom_exe_txn::type_id::create("csr_tx");
    if (!tx.randomize() with {
          kind       == boom_exe_txn::KIND_UOP;
          br_mask    == '0;
          gap_cycles inside {[4:8]};   // BOOM: CSR uops are serialized
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    tx.csr_addr = rw.addr[11:0];
    if (rw.kind == UVM_WRITE) begin
      tx.uopc     = UOPC_CSRRW;
      tx.rs1_data = rw.data;
    end
    else begin
      tx.uopc     = UOPC_CSRRS;
      tx.rs1_data = '0;
    end
    return tx;
  endfunction

  virtual function void bus2reg (uvm_sequence_item bus_item,
                                 ref uvm_reg_bus_op rw);
    boom_exe_txn tx;
    if (!$cast(tx, bus_item)) begin
      `uvm_fatal(get_type_name(), "bus_item is not a boom_exe_txn")
      return;
    end
    rw.kind   = (tx.uopc == UOPC_CSRRW) ? UVM_WRITE : UVM_READ;
    rw.addr   = tx.csr_addr;
    rw.data   = (rw.kind == UVM_READ) ? tx.result : tx.rs1_data;
    rw.status = UVM_IS_OK;
  endfunction

endclass : boom_csr_adapter

`endif

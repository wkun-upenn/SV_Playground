//=============================================================================
// boom_csr_adapter.sv — uvm_reg_bus_op <-> boom_csr_txn, plus the predictors
//-----------------------------------------------------------------------------
// Two prediction paths keep the register model in sync with the hardware:
//   * uvm_reg_predictor #(boom_csr_txn) on the CSR monitor: every access on the
//     rw port — whether the RAL agent or a CSR instruction executed by
//     ALUExeUnit_2 caused it — updates the mirror through bus2reg().
//   * boom_csr_fflags_predictor on the monitor's fflags_ap: the FPU's exception
//     flags are OR-ed into fflags by the hardware without any bus access, so
//     the model has to be told (fflags |= flags, mstatus.FS -> Dirty).
//=============================================================================
class boom_csr_adapter extends uvm_reg_adapter;
  `uvm_object_utils(boom_csr_adapter)
  function new(string name = "boom_csr_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;      // the driver fills rdata into the request item
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    boom_csr_txn t = boom_csr_txn::type_id::create("ral_txn");
    t.addr  = rw.addr[11:0];
    t.cmd   = (rw.kind == UVM_WRITE) ? CSR_W : CSR_R;
    t.wdata = rw.data;
    return t;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    boom_csr_txn t;
    if (!$cast(t, bus_item)) `uvm_fatal("ADAPT", "bus item is not a boom_csr_txn")
    rw.addr   = t.addr;
    rw.byte_en = '1;
    rw.status = (t.read_illegal || t.write_illegal) ? UVM_NOT_OK : UVM_IS_OK;
    if (t.cmd == CSR_R) begin
      rw.kind = UVM_READ;  rw.data = t.rdata;
    end else begin
      // S / C are read-modify-write inside CSRFile: present the *resulting* value as the write,
      // so the predictor mirrors what the register really holds afterwards
      rw.kind = UVM_WRITE; rw.data = t.new_value();
    end
  endfunction
endclass : boom_csr_adapter

//-----------------------------------------------------------------------------
`uvm_analysis_imp_decl(_fflags_evt)
class boom_csr_fflags_predictor extends uvm_component;
  `uvm_component_utils(boom_csr_fflags_predictor)
  uvm_analysis_imp_fflags_evt #(boom_csr_fflags_evt, boom_csr_fflags_predictor) imp;
  boom_csr_reg_block regmodel;
  int unsigned n_events;
  function new(string name, uvm_component parent); super.new(name, parent); imp = new("imp", this); endfunction

  function void write_fflags_evt(boom_csr_fflags_evt e);
    uvm_reg_data_t cur, nxt;
    if (regmodel == null) return;
    n_events++;
    cur = regmodel.fflags.get_mirrored_value();
    nxt = cur | e.flags;
    if (nxt != cur) begin
      // predict through the register so the alias callbacks carry it into fcsr
      void'(regmodel.fflags.predict(nxt, -1, UVM_PREDICT_DIRECT));
      `uvm_info("FFLAGS", $sformatf("hardware set flags %05b -> fflags mirror %05b @%0d", e.flags, nxt[4:0], e.cycle), UVM_MEDIUM)
    end
    // CSRFile: set_fs_dirty when flags are written -> mstatus.FS = 3 (SD follows on the next read)
    if (regmodel.mstatus.FS.get_mirrored_value() != 3) begin
      void'(regmodel.mstatus.FS.predict(3, -1, UVM_PREDICT_DIRECT));
      void'(regmodel.mstatus.SD.predict(1, -1, UVM_PREDICT_DIRECT));
    end
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("FFLAGS", $sformatf("fflags side-effect events: %0d", n_events), UVM_LOW)
  endfunction
endclass : boom_csr_fflags_predictor

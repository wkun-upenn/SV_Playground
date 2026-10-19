//-----------------------------------------------------------------------------
// boom_exe_monitor.sv -- observes the issue port, branch broadcasts and both
// write-back ports.  Publishes:
//   ap_issued : accepted uops / branch updates (for the scoreboard's
//               reference model and for coverage)
//   ap_wb     : completed write-backs
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_MONITOR_SV
`define BOOM_EXE_MONITOR_SV

class boom_exe_monitor extends uvm_monitor;
  `uvm_component_utils(boom_exe_monitor)

  virtual boom_exe_if vif;

  uvm_analysis_port #(boom_exe_txn) ap_issued;
  uvm_analysis_port #(boom_exe_txn) ap_wb;

  function new (string name, uvm_component parent);
    super.new(name, parent);
    ap_issued = new("ap_issued", this);
    ap_wb     = new("ap_wb", this);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual boom_exe_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not found in config DB")
  endfunction

  virtual task run_phase (uvm_phase phase);
    @(posedge vif.rst_n);
    forever begin
      @(vif.mon_cb);

      // NOTE: write-backs are processed BEFORE the branch broadcast of the
      // same cycle: a wb asserted concurrently with a mispredict was decided
      // by the DUT one cycle earlier and is legitimate.
      // ---- write-back port 0 (pipelined units) ----
      if (vif.mon_cb.wb0_valid) begin
        boom_exe_txn tx = boom_exe_txn::type_id::create("wb0_tx");
        tx.kind         = boom_exe_txn::KIND_UOP;
        tx.rob_idx      = vif.mon_cb.wb0_rob_idx;
        tx.pdst         = vif.mon_cb.wb0_pdst;
        tx.result       = vif.mon_cb.wb0_data;
        tx.fflags_valid = vif.mon_cb.wb0_fflags_valid;
        tx.fflags       = vif.mon_cb.wb0_fflags;
        tx.wb_port      = 0;
        ap_wb.write(tx);
      end

      // ---- write-back port 1 (un-pipelined units) ----
      if (vif.mon_cb.wb1_valid) begin
        boom_exe_txn tx = boom_exe_txn::type_id::create("wb1_tx");
        tx.kind         = boom_exe_txn::KIND_UOP;
        tx.rob_idx      = vif.mon_cb.wb1_rob_idx;
        tx.pdst         = vif.mon_cb.wb1_pdst;
        tx.result       = vif.mon_cb.wb1_data;
        tx.fflags_valid = vif.mon_cb.wb1_fflags_valid;
        tx.fflags       = vif.mon_cb.wb1_fflags;
        tx.wb_port      = 1;
        ap_wb.write(tx);
      end
      // ---- accepted uop ----
      if (vif.mon_cb.iss_valid && vif.mon_cb.iss_ready &&
          vif.mon_cb.iss_uopc != UOPC_NOP) begin
        boom_exe_txn tx = boom_exe_txn::type_id::create("iss_tx");
        tx.kind     = boom_exe_txn::KIND_UOP;
        tx.uopc     = uopc_e'(vif.mon_cb.iss_uopc);
        tx.rob_idx  = vif.mon_cb.iss_rob_idx;
        tx.pdst     = vif.mon_cb.iss_pdst;
        tx.rs1_data = vif.mon_cb.iss_rs1_data;
        tx.rs2_data = vif.mon_cb.iss_rs2_data;
        tx.br_mask  = vif.mon_cb.iss_br_mask;
        tx.csr_addr = vif.mon_cb.iss_csr_addr;
        ap_issued.write(tx);
      end

      // ---- branch broadcast (mispredict / resolve) ----
      if (vif.mon_cb.br_resolve_valid || vif.mon_cb.br_mispredict_valid) begin
        boom_exe_txn tx = boom_exe_txn::type_id::create("br_tx");
        tx.kind                = boom_exe_txn::KIND_BR_UPDATE;
        tx.br_resolve_valid    = vif.mon_cb.br_resolve_valid;
        tx.br_resolve_mask     = vif.mon_cb.br_resolve_mask;
        tx.br_mispredict_valid = vif.mon_cb.br_mispredict_valid;
        tx.br_mispredict_mask  = vif.mon_cb.br_mispredict_mask;
        ap_issued.write(tx);
      end

    end
  endtask

endclass : boom_exe_monitor

`endif

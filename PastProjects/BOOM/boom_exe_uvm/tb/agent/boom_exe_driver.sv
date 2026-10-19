//-----------------------------------------------------------------------------
// boom_exe_driver.sv -- drives uops onto the issue port and Branch-Unit
// broadcasts onto the branch channel, honoring iss_ready back-pressure
// (BOOM's "scheduling readiness" for un-pipelined units).
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_DRIVER_SV
`define BOOM_EXE_DRIVER_SV

class boom_exe_driver extends uvm_driver #(boom_exe_txn);
  `uvm_component_utils(boom_exe_driver)

  virtual boom_exe_if vif;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual boom_exe_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not found in config DB")
  endfunction

  virtual task run_phase (uvm_phase phase);
    idle();
    @(posedge vif.rst_n);
    forever begin
      seq_item_port.get_next_item(req);
      repeat (req.gap_cycles) @(vif.drv_cb);
      if (req.kind == boom_exe_txn::KIND_BR_UPDATE) drive_br_update(req);
      else                                          drive_uop(req);
      seq_item_port.item_done();
    end
  endtask

  task idle ();
    vif.drv_cb.iss_valid           <= 1'b0;
    vif.drv_cb.iss_uopc            <= UOPC_NOP;
    vif.drv_cb.iss_rob_idx         <= '0;
    vif.drv_cb.iss_pdst            <= '0;
    vif.drv_cb.iss_rs1_data        <= '0;
    vif.drv_cb.iss_rs2_data        <= '0;
    vif.drv_cb.iss_br_mask         <= '0;
    vif.drv_cb.iss_csr_addr        <= '0;
    vif.drv_cb.br_resolve_valid    <= 1'b0;
    vif.drv_cb.br_resolve_mask     <= '0;
    vif.drv_cb.br_mispredict_valid <= 1'b0;
    vif.drv_cb.br_mispredict_mask  <= '0;
  endtask

  task drive_uop (boom_exe_txn tx);
    vif.drv_cb.iss_valid    <= 1'b1;
    vif.drv_cb.iss_uopc     <= tx.uopc;
    vif.drv_cb.iss_rob_idx  <= tx.rob_idx;
    vif.drv_cb.iss_pdst     <= tx.pdst;
    vif.drv_cb.iss_rs1_data <= tx.rs1_data;
    vif.drv_cb.iss_rs2_data <= tx.rs2_data;
    vif.drv_cb.iss_br_mask  <= tx.br_mask;
    vif.drv_cb.iss_csr_addr <= tx.csr_addr;
    // hold until accepted (un-pipelined units may back-pressure)
    do @(vif.drv_cb); while (vif.drv_cb.iss_ready !== 1'b1);
    vif.drv_cb.iss_valid    <= 1'b0;
    vif.drv_cb.iss_uopc     <= UOPC_NOP;

    // CSR uops are used by the RAL frontdoor: block until the write-back
    // returns the old CSR value so the adapter can hand it to the register
    // model (BOOM serializes CSR ops anyway -- nothing else is in flight).
    if (tx.is_csr()) begin
      int unsigned timeout = 100;
      while (!(vif.drv_cb.wb0_valid === 1'b1 &&
               vif.drv_cb.wb0_rob_idx == tx.rob_idx)) begin
        @(vif.drv_cb);
        if (--timeout == 0)
          `uvm_fatal(get_type_name(), "timeout waiting for CSR write-back")
      end
      tx.result = vif.drv_cb.wb0_data;
    end
  endtask

  task drive_br_update (boom_exe_txn tx);
    vif.drv_cb.br_resolve_valid    <= tx.br_resolve_valid;
    vif.drv_cb.br_resolve_mask     <= tx.br_resolve_mask;
    vif.drv_cb.br_mispredict_valid <= tx.br_mispredict_valid;
    vif.drv_cb.br_mispredict_mask  <= tx.br_mispredict_mask;
    @(vif.drv_cb);
    vif.drv_cb.br_resolve_valid    <= 1'b0;
    vif.drv_cb.br_mispredict_valid <= 1'b0;
  endtask

endclass : boom_exe_driver

`endif

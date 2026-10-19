//=============================================================================
// boom_brupd_agent.sv — branch-update / flush broadcaster
//-----------------------------------------------------------------------------
// BOOM broadcasts brupdate (resolve / mispredict masks) and the pipeline-flush
// kill to every execution unit and issue queue in the same cycle. This agent
// owns that broadcast: a sequence sends boom_brupd_txn items, the driver puts
// them on all interfaces at once and drives zeros in idle cycles.
//=============================================================================
class boom_brupd_sequencer extends uvm_sequencer #(boom_brupd_txn);
  `uvm_component_utils(boom_brupd_sequencer)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
endclass

class boom_brupd_driver extends uvm_driver #(boom_brupd_txn);
  `uvm_component_utils(boom_brupd_driver)
  boom_exe_cfg cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
  endfunction

  function void put(bit [11:0] res, bit [11:0] mis, bit flush);
    cfg.alu0_vif.drv_cb.br_resolve_mask    <= res;
    cfg.alu0_vif.drv_cb.br_mispredict_mask <= mis;
    cfg.alu0_vif.drv_cb.flush_bcast        <= flush;
    cfg.alu1_vif.drv_cb.br_resolve_mask    <= res;
    cfg.alu1_vif.drv_cb.br_mispredict_mask <= mis;
    cfg.alu1_vif.drv_cb.flush_bcast        <= flush;
    cfg.fpu_vif.drv_cb.br_resolve_mask     <= res;
    cfg.fpu_vif.drv_cb.br_mispredict_mask  <= mis;
    cfg.fpu_vif.drv_cb.flush_bcast         <= flush;
    if (cfg.has_iq) begin
      cfg.iq_vif.drv_cb.br_resolve_mask    <= res;
      cfg.iq_vif.drv_cb.br_mispredict_mask <= mis;
      cfg.iq_vif.drv_cb.flush_pipeline     <= flush;
    end
  endfunction

  task run_phase(uvm_phase phase);
    put('0, '0, 0);
    @(negedge cfg.alu0_vif.rst);
    @(cfg.alu0_vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      repeat (req.delay) begin put('0, '0, 0); @(cfg.alu0_vif.drv_cb); end
      put(req.resolve_mask, req.mispredict_mask, req.flush);
      `uvm_info("BRUPD", req.convert2string(), UVM_HIGH)
      @(cfg.alu0_vif.drv_cb);
      put('0, '0, 0);
      seq_item_port.item_done();
    end
  endtask
endclass : boom_brupd_driver

class boom_brupd_agent extends uvm_agent;
  `uvm_component_utils(boom_brupd_agent)
  boom_brupd_sequencer sqr;
  boom_brupd_driver    drv;
  boom_exe_cfg         cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (cfg.brupd_active == UVM_ACTIVE) begin
      sqr = boom_brupd_sequencer::type_id::create("sqr", this);
      drv = boom_brupd_driver::type_id::create("drv", this);
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    if (drv != null) drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass : boom_brupd_agent

//=============================================================================
// boom_iq_agent.sv — sequencer / driver / monitor / agent for the int issue queue
//=============================================================================
class boom_iq_sequencer extends uvm_sequencer #(boom_iq_txn);
  `uvm_component_utils(boom_iq_sequencer)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
endclass

class boom_iq_driver extends uvm_driver #(boom_iq_txn);
  `uvm_component_utils(boom_iq_driver)
  virtual boom_iq_if vif;
  boom_exe_cfg cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_iq_if)::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction

  function uop_t to_uop(boom_iq_uop q, bit [11:0] resolve_now);
    uop_t u = '0;
    u.uopc = q.uopc; u.fu_code = q.fu_code; u.iq_type = IQT_INT; u.iw_state = 2'd1;
    u.rob_idx = q.rob_idx; u.pdst = q.pdst; u.prs1 = q.prs1; u.prs2 = q.prs2; u.prs3 = q.prs3;
    u.prs1_busy = q.prs1_busy; u.prs2_busy = q.prs2_busy; u.prs3_busy = q.prs3_busy;
    // the core applies GetNewBrMask to dispatching uops in the same cycle as a resolve
    u.br_mask = q.br_mask & ~resolve_now; u.br_tag = q.br_tag;
    u.is_br = q.is_br; u.is_jal = q.is_jal; u.is_jalr = q.is_jalr;
    u.dst_rtype = RT_FIX; u.lrs1_rtype = q.lrs1_rtype; u.lrs2_rtype = q.lrs2_rtype; u.ldst_val = 1;
    u.ctrl_op_fcn = FN_ADD; u.bypassable = (q.fu_code == FU_ALU);
    return u;
  endfunction

  // Raw (non-clocking) drives, applied a fraction of a cycle after the edge so
  // that the branch-update broadcast of the same cycle (driven through a
  // clocking block with #1 skew by boom_brupd_driver) is already visible.
  function void idle();
    foreach (vif.dis_valid[i]) vif.dis_valid[i] = 0;
    foreach (vif.wakeup_valid[i]) vif.wakeup_valid[i] = 0;
    vif.spec_ld_wakeup_valid[0] = 0;
    vif.ld_miss = 0;
  endfunction

  task run_phase(uvm_phase phase);
    idle();
    vif.fu_types[0] = 10'h10B; vif.fu_types[1] = 10'h031;
    foreach (vif.dis_uop[i]) vif.dis_uop[i] = '0;
    foreach (vif.wakeup_pdst[i]) vif.wakeup_pdst[i] = '0;
    vif.spec_ld_wakeup_pdst[0] = '0;
    @(negedge vif.rst);
    forever begin
      bit pending[IQ_DISPATCH_W];
      bit any;
      seq_item_port.get_next_item(req);
      foreach (req.dis_valid[i]) pending[i] = req.dis_valid[i];
      do begin
        @(posedge vif.clk);
        #(CLK_PERIOD / 5);
        req.cycle = cur_cycle();
        any = 0;
        foreach (pending[i]) begin
          // dis_ready is registered: the value visible now is what the DUT applies at the next edge
          if (pending[i] && vif.dis_ready[i]) begin
            vif.dis_valid[i] = 1;
            vif.dis_uop[i]   = to_uop(req.dis_uop[i], vif.br_resolve_mask);
            pending[i] = 0;
          end else vif.dis_valid[i] = 0;
          any |= pending[i];
        end
        foreach (req.wakeup_valid[i]) begin
          vif.wakeup_valid[i] = req.wakeup_valid[i];
          vif.wakeup_pdst[i]  = req.wakeup_pdst[i];
        end
        vif.spec_ld_wakeup_valid[0] = req.spec_ld_valid;
        vif.spec_ld_wakeup_pdst[0]  = req.spec_ld_pdst;
        vif.ld_miss     = req.ld_miss;
        vif.fu_types[0] = req.fu_types[0];
        vif.fu_types[1] = req.fu_types[1];
        // single-cycle events must not repeat while a dispatch is being held
        foreach (req.wakeup_valid[i]) req.wakeup_valid[i] = 0;
        req.spec_ld_valid = 0; req.ld_miss = 0;
      end while (any);
      seq_item_port.item_done();
    end
  endtask
endclass : boom_iq_driver

//-----------------------------------------------------------------------------
class boom_iq_monitor extends uvm_monitor;
  `uvm_component_utils(boom_iq_monitor)
  virtual boom_iq_if vif;
  boom_exe_cfg cfg;
  uvm_analysis_port #(boom_iq_txn)   stim_ap;   // dispatch fires + wakeups seen (per cycle, only when something happened)
  uvm_analysis_port #(boom_iq_issue) iss_ap;    // issue ports (every cycle)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    stim_ap = new("stim_ap", this); iss_ap = new("iss_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_iq_if)::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction

  task run_phase(uvm_phase phase);
    @(negedge vif.rst);
    forever begin
      boom_iq_txn   s;
      boom_iq_issue is;
      bit           something;
      @(vif.mon_cb);
      if (vif.rst) continue;
      s = boom_iq_txn::type_id::create("iq_stim"); s.cycle = cur_cycle(); something = 0;
      foreach (s.dis_valid[i]) begin
        s.dis_fire[i] = vif.mon_cb.dis_valid[i] && vif.mon_cb.dis_ready[i];
        s.dis_valid[i] = vif.mon_cb.dis_valid[i];
        if (s.dis_fire[i]) begin
          uop_t u = vif.mon_cb.dis_uop[i];
          s.dis_uop[i].rob_idx = u.rob_idx; s.dis_uop[i].fu_code = u.fu_code; s.dis_uop[i].pdst = u.pdst;
          s.dis_uop[i].prs1 = u.prs1; s.dis_uop[i].prs2 = u.prs2; s.dis_uop[i].prs3 = u.prs3;
          s.dis_uop[i].prs1_busy = u.prs1_busy; s.dis_uop[i].prs2_busy = u.prs2_busy; s.dis_uop[i].prs3_busy = u.prs3_busy;
          s.dis_uop[i].br_mask = u.br_mask; s.dis_uop[i].br_tag = u.br_tag; s.dis_uop[i].uopc = u.uopc;
          s.dis_uop[i].is_br = u.is_br; s.dis_uop[i].is_jal = u.is_jal; s.dis_uop[i].is_jalr = u.is_jalr;
          s.dis_uop[i].dispatch_cycle = s.cycle;
          something = 1;
        end
      end
      foreach (s.wakeup_valid[i]) begin
        s.wakeup_valid[i] = vif.mon_cb.wakeup_valid[i]; s.wakeup_pdst[i] = vif.mon_cb.wakeup_pdst[i];
        something |= s.wakeup_valid[i];
      end
      s.spec_ld_valid = vif.mon_cb.spec_ld_wakeup_valid[0]; s.spec_ld_pdst = vif.mon_cb.spec_ld_wakeup_pdst[0];
      s.ld_miss = vif.mon_cb.ld_miss;
      s.fu_types[0] = vif.mon_cb.fu_types[0]; s.fu_types[1] = vif.mon_cb.fu_types[1];
      something |= s.spec_ld_valid | s.ld_miss;
      if (something) stim_ap.write(s);
      is = boom_iq_issue::type_id::create("iq_issue"); is.cycle = cur_cycle();
      foreach (is.iss_valid[w]) begin is.iss_valid[w] = vif.mon_cb.iss_valid[w]; is.iss_uop[w] = vif.mon_cb.iss_uop[w]; is.fu_types[w] = vif.mon_cb.fu_types[w]; end
      is.ld_miss = vif.mon_cb.ld_miss; is.resolve_mask = vif.mon_cb.br_resolve_mask; is.mispredict_mask = vif.mon_cb.br_mispredict_mask;
      is.flush = vif.mon_cb.flush_pipeline;
      iss_ap.write(is);
    end
  endtask
endclass : boom_iq_monitor

//-----------------------------------------------------------------------------
class boom_iq_agent extends uvm_agent;
  `uvm_component_utils(boom_iq_agent)
  boom_iq_sequencer sqr;
  boom_iq_driver    drv;
  boom_iq_monitor   mon;
  boom_exe_cfg      cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    mon = boom_iq_monitor::type_id::create("mon", this);
    if (cfg.iq_active == UVM_ACTIVE) begin
      sqr = boom_iq_sequencer::type_id::create("sqr", this);
      drv = boom_iq_driver::type_id::create("drv", this);
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    if (drv != null) drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass : boom_iq_agent

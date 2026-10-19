//=============================================================================
// boom_exe_agent.sv — sequencer / driver / monitor / agent for one execution
// unit. Parameterised by the unit so the virtual-interface type matches.
//=============================================================================

typedef class boom_exe_driver;
typedef class boom_exe_monitor;

//-----------------------------------------------------------------------------
class boom_exe_sequencer extends uvm_sequencer #(boom_exe_txn);
  `uvm_component_utils(boom_exe_sequencer)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
endclass

//-----------------------------------------------------------------------------
// Driver: instruction-level txn -> MicroOp + recoded operands, one-cycle request.
//-----------------------------------------------------------------------------
class boom_exe_driver #(exu_id_e UNIT = EXU_ALU0) extends uvm_driver #(boom_exe_txn);
  `uvm_component_param_utils(boom_exe_driver #(UNIT))

  virtual boom_exu_if #(UNIT) vif;
  boom_exe_cfg cfg;
  int unsigned drop_ready_pct = 0;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_exu_if #(UNIT))::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction

  //--------------------------------------------------------------- run
  task run_phase(uvm_phase phase);
    idle();
    fork
      drive_ready();
    join_none
    @(negedge vif.rst);
    @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      req.lower();
      repeat (req.delay) @(vif.drv_cb);
      // issue-queue rule: only send a uop whose FU is currently advertised (div/fdiv/i2f/f2i busy)
      while ((vif.drv_cb.fu_types & req.ctrl.fu_code) == 0) @(vif.drv_cb);
      drive_req(req);
      @(vif.drv_cb);
      idle();
      `uvm_info("DRV", $sformatf("%s issued: %s", UNIT.name(), req.convert2string()), UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask

  function void drive_req(boom_exe_txn t);
    vif.drv_cb.req_valid  <= 1'b1;
    vif.drv_cb.req_uop    <= t.uop;
    vif.drv_cb.rs1_data   <= t.rs1_rec;
    vif.drv_cb.rs2_data   <= t.rs2_rec;
    vif.drv_cb.rs3_data   <= t.rs3_rec;
    vif.drv_cb.req_kill   <= t.flush_with_req;
    vif.drv_cb.fcsr_rm_drv <= t.fcsr_rm;   // ignored by the mux when the test selects the CSRFile's frm
    // FTQ model: ftq_pc is the fetch-block PC of the uop (of its second half for a straddling
    // instruction), next_pc the predicted target
    vif.drv_cb.ftq_pc                  <= t.edge_inst ? t.pc + 40'd2 : t.pc;
    vif.drv_cb.ftq_next_val            <= t.ftq_next_val;
    vif.drv_cb.ftq_next_pc             <= t.ftq_next_pc;
    vif.drv_cb.ftq_entry_cfi_idx_valid <= t.ftq_cfi_idx_valid;
    vif.drv_cb.ftq_entry_cfi_idx_bits  <= t.ftq_cfi_idx;
    vif.drv_cb.ftq_entry_start_bank    <= t.ftq_start_bank;
    t.issue_cycle = cur_cycle() + 1;
  endfunction

  function void idle();
    vif.drv_cb.req_valid <= 1'b0;
    vif.drv_cb.req_kill  <= 1'b0;
  endfunction

  // Decoupled response ports: model a consumer that is sometimes not ready
  task drive_ready();
    forever begin
      @(vif.drv_cb);
      vif.drv_cb.ll_iresp_ready <= ($urandom_range(99) < cfg.ll_ready_pct);
      vif.drv_cb.ll_fresp_ready <= ($urandom_range(99) < cfg.ll_ready_pct);
    end
  endtask
endclass : boom_exe_driver


//-----------------------------------------------------------------------------
// Monitor: reconstructs instruction-level requests from the MicroOp and
// publishes every response / bypass / brinfo event.
//-----------------------------------------------------------------------------
class boom_exe_monitor #(exu_id_e UNIT = EXU_ALU0) extends uvm_monitor;
  `uvm_component_param_utils(boom_exe_monitor #(UNIT))

  virtual boom_exu_if #(UNIT) vif;
  boom_exe_cfg cfg;

  uvm_analysis_port #(boom_exe_txn)    req_ap;      // one item per accepted request
  uvm_analysis_port #(boom_exe_rsp)    rsp_ap;      // one item per response-port handshake
  uvm_analysis_port #(boom_exe_rsp)    fflags_ap;   // fresp/ll_fresp fflags (may be without data)
  uvm_analysis_port #(boom_exe_rsp)    bypass_ap;   // bypass port 0 samples
  uvm_analysis_port #(boom_brinfo_rsp) brinfo_ap;
  uvm_analysis_port #(boom_brupd_txn)  brupd_ap;    // masks / flush seen on this unit each cycle (non-zero only)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap = new("req_ap", this); rsp_ap = new("rsp_ap", this); fflags_ap = new("fflags_ap", this);
    bypass_ap = new("bypass_ap", this); brinfo_ap = new("brinfo_ap", this); brupd_ap = new("brupd_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_exu_if #(UNIT))::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction

  task run_phase(uvm_phase phase);
    @(negedge vif.rst);
    forever begin
      @(vif.mon_cb);
      if (vif.rst) continue;
      sample_request();
      sample_responses();
    end
  endtask

  //--------------------------------------------------------------- request
  function void sample_request();
    boom_exe_txn t;
    uop_t u;
    boom_brupd_txn b;
    // branch update seen this cycle (published even without a request)
    if (vif.mon_cb.br_resolve_mask != 0 || vif.mon_cb.br_mispredict_mask != 0 || vif.mon_cb.kill_any) begin
      b = boom_brupd_txn::type_id::create("brupd");
      b.resolve_mask = vif.mon_cb.br_resolve_mask; b.mispredict_mask = vif.mon_cb.br_mispredict_mask;
      b.flush = vif.mon_cb.kill_any; b.cycle = cur_cycle();
      brupd_ap.write(b);
    end
    if (!vif.mon_cb.req_valid) return;
    u = vif.mon_cb.req_uop;
    t = boom_exe_txn::type_id::create("mon_req");
    t.op        = op_from_uop(u);
    t.uop       = u;
    t.ctrl      = ctrl_from_uop(u, UNIT);
    t.rs1_rec   = vif.mon_cb.rs1_data;
    t.rs2_rec   = vif.mon_cb.rs2_data;
    t.rs3_rec   = vif.mon_cb.rs3_data;
    t.rs1       = (u.lrs1_rtype == RT_FLT) ? fp_ieee(t.rs1_rec) : t.rs1_rec[63:0];
    t.rs2       = (u.lrs2_rtype == RT_FLT) ? fp_ieee(t.rs2_rec) : t.rs2_rec[63:0];
    t.rs3       = u.frs3_en ? fp_ieee(t.rs3_rec) : t.rs3_rec[63:0];
    t.rm        = u.imm_packed[2:0];
    t.fcsr_rm   = vif.mon_cb.fcsr_rm;
    t.zimm      = u.prs1[4:0];
    t.csr_addr  = u.imm_packed[19:8];
    t.br_mask   = u.br_mask;  t.br_tag = u.br_tag;  t.rob_idx = u.rob_idx;  t.pdst = u.pdst;  t.ftq_idx = u.ftq_idx;
    t.pred_taken= u.taken;    t.is_rvc = u.is_rvc;  t.edge_inst = u.edge_inst;
    // PC as the JMP unit reconstructs it: (block_pc | pc_lob) - (edge_inst ? 2 : 0)
    t.pc        = ((vif.mon_cb.ftq_pc & ~40'h3F) | 40'(u.pc_lob)) - (u.edge_inst ? 40'd2 : 40'd0);
    t.ftq_next_val = vif.mon_cb.ftq_next_val; t.ftq_next_pc = vif.mon_cb.ftq_next_pc;
    t.ftq_cfi_idx_valid = vif.mon_cb.ftq_entry_cfi_idx_valid; t.ftq_cfi_idx = vif.mon_cb.ftq_entry_cfi_idx_bits;
    t.ftq_start_bank = vif.mon_cb.ftq_entry_start_bank;
    t.flush_with_req = vif.mon_cb.kill_any;
    t.killed_same_cycle = vif.mon_cb.kill_any || ((u.br_mask & vif.mon_cb.br_mispredict_mask) != 0);
    t.issue_cycle = cur_cycle();
    // rocket's imm view (for coverage / printing)
    t.imm = imm_gen(u.imm_packed, u.ctrl_imm_sel);
    `uvm_info("MON", $sformatf("%s req: %s", UNIT.name(), t.convert2string()), UVM_HIGH)
    req_ap.write(t);
    // bypass port 0 (same cycle as the ALU request)
    if (vif.mon_cb.bypass_valid[0]) begin
      boom_exe_rsp b0 = boom_exe_rsp::type_id::create("bypass0");
      b0.unit = UNIT; b0.port = PORT_IRESP; b0.uop.pdst = vif.mon_cb.bypass_pdst[0];
      b0.uop.dst_rtype = vif.mon_cb.bypass_dst_rtype[0]; b0.uop.rob_idx = u.rob_idx;
      b0.data_raw = vif.mon_cb.bypass_data[0]; b0.data = b0.data_raw[63:0]; b0.cycle = cur_cycle();
      bypass_ap.write(b0);
    end
    // branch resolution (same cycle as the request)
    if (vif.mon_cb.brinfo_valid) begin
      boom_brinfo_rsp br = boom_brinfo_rsp::type_id::create("brinfo");
      br.unit = UNIT; br.rob_idx = vif.mon_cb.brinfo_uop_rob_idx; br.mispredict = vif.mon_cb.brinfo_mispredict;
      br.taken = vif.mon_cb.brinfo_taken; br.cfi_type = vif.mon_cb.brinfo_cfi_type; br.pc_sel = vif.mon_cb.brinfo_pc_sel;
      br.jalr_target = vif.mon_cb.brinfo_jalr_target; br.target_offset = vif.mon_cb.brinfo_target_offset;
      br.br_mask = vif.mon_cb.brinfo_uop_br_mask; br.br_tag = vif.mon_cb.brinfo_uop_br_tag; br.cycle = cur_cycle();
      brinfo_ap.write(br);
    end
  endfunction

  //--------------------------------------------------------------- responses
  function void publish(rsp_port_e port, rsp_uop_t uop, logic [64:0] data_raw, bit predicated,
                        bit fl_valid, logic [4:0] fl, logic [5:0] fl_rob);
    boom_exe_rsp r = boom_exe_rsp::type_id::create("rsp");
    r.unit = UNIT; r.port = port; r.uop = uop; r.data_raw = data_raw; r.predicated = predicated;
    r.data = (uop.dst_rtype == RT_FLT) ? fp_ieee(data_raw) : data_raw[63:0];
    r.flags_valid = fl_valid; r.flags = fl; r.cycle = cur_cycle();
    if (fl_valid && fl_rob != uop.rob_idx) r.flags_valid = 0; // flags belong to another uop (F2I case)
    rsp_ap.write(r);
    `uvm_info("MON", $sformatf("%s", r.convert2string()), UVM_HIGH)
  endfunction

  function void sample_responses();
    if (UNIT != EXU_FPU) begin
      if (vif.mon_cb.iresp_valid)
        publish(PORT_IRESP, vif.mon_cb.iresp_uop, vif.mon_cb.iresp_data, vif.mon_cb.iresp_predicated, 0, '0, '0);
    end
    if (UNIT == EXU_ALU0) begin
      if (vif.mon_cb.ll_fresp_valid && vif.mon_cb.ll_fresp_ready)
        publish(PORT_LL_FRESP, vif.mon_cb.ll_fresp_uop, vif.mon_cb.ll_fresp_data, vif.mon_cb.ll_fresp_predicated,
                vif.mon_cb.ll_fresp_fflags_valid, vif.mon_cb.ll_fresp_fflags, vif.mon_cb.ll_fresp_fflags_rob_idx);
    end
    if (UNIT == EXU_FPU) begin
      if (vif.mon_cb.fresp_valid)
        publish(PORT_FRESP, vif.mon_cb.fresp_uop, vif.mon_cb.fresp_data, vif.mon_cb.fresp_predicated,
                vif.mon_cb.fresp_fflags_valid, vif.mon_cb.fresp_fflags, vif.mon_cb.fresp_fflags_rob_idx);
      if (vif.mon_cb.ll_iresp_valid && vif.mon_cb.ll_iresp_ready)
        publish(PORT_LL_IRESP, vif.mon_cb.ll_iresp_uop, vif.mon_cb.ll_iresp_data, vif.mon_cb.ll_iresp_predicated, 0, '0, '0);
      // fflags stream (F2I ops report flags here while their data leaves on ll_iresp)
      if (vif.mon_cb.fresp_fflags_valid) begin
        boom_exe_rsp f = boom_exe_rsp::type_id::create("fflags");
        f.unit = UNIT; f.port = PORT_FRESP; f.uop.rob_idx = vif.mon_cb.fresp_fflags_rob_idx;
        f.flags_valid = 1; f.flags = vif.mon_cb.fresp_fflags; f.cycle = cur_cycle();
        fflags_ap.write(f);
      end
    end
  endfunction
endclass : boom_exe_monitor


//-----------------------------------------------------------------------------
class boom_exe_agent #(exu_id_e UNIT = EXU_ALU0) extends uvm_agent;
  `uvm_component_param_utils(boom_exe_agent #(UNIT))
  boom_exe_sequencer         sqr;
  boom_exe_driver  #(UNIT)   drv;
  boom_exe_monitor #(UNIT)   mon;
  boom_exe_cfg               cfg;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    mon = boom_exe_monitor #(UNIT)::type_id::create("mon", this);
    if (cfg.exu_active[UNIT] == UVM_ACTIVE) begin
      sqr = boom_exe_sequencer::type_id::create("sqr", this);
      drv = boom_exe_driver #(UNIT)::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (drv != null) drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass : boom_exe_agent

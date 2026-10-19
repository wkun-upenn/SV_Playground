//=============================================================================
// boom_exe_env.sv — top-level environment + virtual sequencer
//=============================================================================
class boom_exe_vsequencer extends uvm_sequencer;
  `uvm_component_utils(boom_exe_vsequencer)
  boom_exe_sequencer    alu0_sqr, alu1_sqr, fpu_sqr;
  boom_brupd_sequencer  brupd_sqr;
  boom_iq_sequencer     iq_sqr;
  boom_csr_sequencer    csr_sqr;
  boom_csr_reg_block    regmodel;     // register model (RAL) — null when cfg.has_csr == 0
  boom_spike_oracle     spike;        // expectation table for Spike-trace replay (always built, cheap)
  boom_exe_cfg          cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function boom_exe_sequencer sqr_of(exu_id_e u);
    case (u)
      EXU_ALU0: return alu0_sqr;
      EXU_ALU1: return alu1_sqr;
      default:  return fpu_sqr;
    endcase
  endfunction
endclass : boom_exe_vsequencer

class boom_exe_env extends uvm_env;
  `uvm_component_utils(boom_exe_env)

  boom_exe_cfg                 cfg;
  boom_exe_agent #(EXU_ALU0)   alu0_agt;
  boom_exe_agent #(EXU_ALU1)   alu1_agt;
  boom_exe_agent #(EXU_FPU)    fpu_agt;
  boom_brupd_agent             brupd_agt;
  boom_iq_agent                iq_agt;
  boom_csr_agent               csr_agt;
  boom_exe_scoreboard          sb[3];
  boom_iq_scoreboard           iq_sb;
  boom_exe_coverage            cov;
  boom_iq_coverage             iq_cov;
  boom_exe_vsequencer          vsqr;
  // register abstraction layer
  boom_csr_reg_block                       regmodel;
  boom_csr_adapter                         csr_adapter;
  uvm_reg_predictor #(boom_csr_txn)        csr_predictor;
  boom_csr_fflags_predictor                fflags_predictor;
  // Spike-trace replay: expectation table + CSR read checker
  boom_spike_oracle                        spike;
  boom_spike_csr_checker                   spike_csr_chk;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    uvm_config_db#(boom_exe_cfg)::set(this, "*", "cfg", cfg);
    uvm_config_db#(virtual boom_exu_if #(EXU_ALU0))::set(this, "alu0_agt.*", "vif", cfg.alu0_vif);
    uvm_config_db#(virtual boom_exu_if #(EXU_ALU1))::set(this, "alu1_agt.*", "vif", cfg.alu1_vif);
    uvm_config_db#(virtual boom_exu_if #(EXU_FPU))::set(this,  "fpu_agt.*",  "vif", cfg.fpu_vif);
    uvm_config_db#(virtual boom_iq_if)::set(this, "iq_agt.*", "vif", cfg.iq_vif);
    uvm_config_db#(virtual boom_csr_if)::set(this, "csr_agt.*", "vif", cfg.csr_vif);

    alu0_agt  = boom_exe_agent #(EXU_ALU0)::type_id::create("alu0_agt", this);
    alu1_agt  = boom_exe_agent #(EXU_ALU1)::type_id::create("alu1_agt", this);
    fpu_agt   = boom_exe_agent #(EXU_FPU)::type_id::create("fpu_agt", this);
    brupd_agt = boom_brupd_agent::type_id::create("brupd_agt", this);
    if (cfg.has_iq) iq_agt = boom_iq_agent::type_id::create("iq_agt", this);
    if (cfg.has_csr) begin
      csr_agt = boom_csr_agent::type_id::create("csr_agt", this);
      regmodel = boom_csr_reg_block::type_id::create("regmodel");
      regmodel.build();
      regmodel.attach_callbacks();
      csr_adapter      = boom_csr_adapter::type_id::create("csr_adapter");
      csr_predictor    = uvm_reg_predictor #(boom_csr_txn)::type_id::create("csr_predictor", this);
      fflags_predictor = boom_csr_fflags_predictor::type_id::create("fflags_predictor", this);
    end
    spike = boom_spike_oracle::type_id::create("spike");
    if (cfg.has_csr) spike_csr_chk = boom_spike_csr_checker::type_id::create("spike_csr_chk", this);
    if (cfg.has_scoreboard) begin
      foreach (sb[i]) begin
        sb[i] = boom_exe_scoreboard::type_id::create($sformatf("sb_%s", exu_id_e'(i).name()), this);
        sb[i].unit = exu_id_e'(i);
        sb[i].oracle = spike;
      end
      if (cfg.has_iq) iq_sb = boom_iq_scoreboard::type_id::create("iq_sb", this);
    end
    if (cfg.has_coverage) begin
      cov = boom_exe_coverage::type_id::create("cov", this);
      if (cfg.has_iq) iq_cov = boom_iq_coverage::type_id::create("iq_cov", this);
    end
    vsqr = boom_exe_vsequencer::type_id::create("vsqr", this);
    vsqr.cfg = cfg;
    vsqr.regmodel = regmodel;
    vsqr.spike    = spike;
  endfunction

  function void connect_phase(uvm_phase phase);
    boom_exe_monitor #(EXU_ALU0) m0 = alu0_agt.mon;
    boom_exe_monitor #(EXU_ALU1) m1 = alu1_agt.mon;
    boom_exe_monitor #(EXU_FPU)  m2 = fpu_agt.mon;
    if (cfg.has_scoreboard) begin
      m0.req_ap.connect(sb[0].req_imp); m0.rsp_ap.connect(sb[0].rsp_imp); m0.fflags_ap.connect(sb[0].fflags_imp);
      m0.bypass_ap.connect(sb[0].bypass_imp); m0.brinfo_ap.connect(sb[0].brinfo_imp); m0.brupd_ap.connect(sb[0].brupd_imp);
      m1.req_ap.connect(sb[1].req_imp); m1.rsp_ap.connect(sb[1].rsp_imp); m1.fflags_ap.connect(sb[1].fflags_imp);
      m1.bypass_ap.connect(sb[1].bypass_imp); m1.brinfo_ap.connect(sb[1].brinfo_imp); m1.brupd_ap.connect(sb[1].brupd_imp);
      m2.req_ap.connect(sb[2].req_imp); m2.rsp_ap.connect(sb[2].rsp_imp); m2.fflags_ap.connect(sb[2].fflags_imp);
      m2.bypass_ap.connect(sb[2].bypass_imp); m2.brinfo_ap.connect(sb[2].brinfo_imp); m2.brupd_ap.connect(sb[2].brupd_imp);
      if (cfg.has_iq) begin
        iq_agt.mon.stim_ap.connect(iq_sb.stim_imp); iq_agt.mon.iss_ap.connect(iq_sb.iss_imp);
      end
    end
    if (cfg.has_coverage) begin
      m0.req_ap.connect(cov.req_imp); m0.rsp_ap.connect(cov.rsp_imp); m0.brinfo_ap.connect(cov.brinfo_imp); m0.brupd_ap.connect(cov.brupd_imp);
      m1.req_ap.connect(cov.req_imp); m1.rsp_ap.connect(cov.rsp_imp); m1.brinfo_ap.connect(cov.brinfo_imp);
      m2.req_ap.connect(cov.req_imp); m2.rsp_ap.connect(cov.rsp_imp);
      if (cfg.has_iq) begin
        iq_agt.mon.stim_ap.connect(iq_cov.stim_imp); iq_agt.mon.iss_ap.connect(iq_cov.iss_imp);
      end
    end
    if (alu0_agt.sqr != null) vsqr.alu0_sqr = alu0_agt.sqr;
    if (alu1_agt.sqr != null) vsqr.alu1_sqr = alu1_agt.sqr;
    if (fpu_agt.sqr  != null) vsqr.fpu_sqr  = fpu_agt.sqr;
    if (brupd_agt.sqr != null) vsqr.brupd_sqr = brupd_agt.sqr;
    if (cfg.has_iq && iq_agt.sqr != null) vsqr.iq_sqr = iq_agt.sqr;
    if (cfg.has_csr) begin
      if (csr_agt.sqr != null) begin
        vsqr.csr_sqr = csr_agt.sqr;
        // frontdoor accesses of the model go through the CSR agent
        regmodel.csr_map.set_sequencer(csr_agt.sqr, csr_adapter);
      end
      // the mirror is updated only by what the monitor sees (no auto-predict): this covers
      // RAL accesses *and* CSR instructions executed by the pipeline alike
      regmodel.csr_map.set_auto_predict(0);
      csr_predictor.map     = regmodel.csr_map;
      csr_predictor.adapter = csr_adapter;
      csr_agt.mon.ap.connect(csr_predictor.bus_in);
      fflags_predictor.regmodel = regmodel;
      csr_agt.mon.fflags_ap.connect(fflags_predictor.imp);
      spike_csr_chk.oracle = spike;
      csr_agt.mon.ap.connect(spike_csr_chk.analysis_export);
    end
  endfunction
endclass : boom_exe_env

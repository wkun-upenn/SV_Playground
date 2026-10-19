//-----------------------------------------------------------------------------
// boom_exe_env.sv -- top-level environment: agent + scoreboard + coverage
// + the CSR register model (RAL) with its adapter.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_ENV_SV
`define BOOM_EXE_ENV_SV

class boom_exe_env extends uvm_env;
  `uvm_component_utils(boom_exe_env)

  boom_exe_agent      agent;
  boom_exe_scoreboard sb;
  boom_exe_coverage   cov;

  // RAL
  boom_csr_reg_block  regmodel;
  boom_csr_adapter    adapter;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    agent = boom_exe_agent::type_id::create("agent", this);
    sb    = boom_exe_scoreboard::type_id::create("sb", this);
    cov   = boom_exe_coverage::type_id::create("cov", this);

    regmodel = boom_csr_reg_block::type_id::create("regmodel");
    regmodel.build();
    adapter = boom_csr_adapter::type_id::create("adapter");
  endfunction

  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap_issued.connect(sb.imp_issued);
    agent.mon.ap_wb.connect(sb.imp_wb);
    agent.mon.ap_issued.connect(cov.analysis_export);

    // RAL frontdoor rides the execute agent's sequencer as CSR uops
    if (agent.get_is_active() == UVM_ACTIVE) begin
      regmodel.csr_map.set_sequencer(agent.sqr, adapter);
      regmodel.csr_map.set_auto_predict(1);
    end
    regmodel.csr_map.set_base_addr('h0);
  endfunction

endclass : boom_exe_env

`endif

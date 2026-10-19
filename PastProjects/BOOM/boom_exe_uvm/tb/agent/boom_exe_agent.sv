//-----------------------------------------------------------------------------
// boom_exe_agent.sv -- standard active/passive agent bundling the
// sequencer, driver and monitor for one Execution Unit issue port.
// (A multi-issue BOOM would instantiate one agent per issue port.)
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_AGENT_SV
`define BOOM_EXE_AGENT_SV

typedef uvm_sequencer #(boom_exe_txn) boom_exe_sequencer;

class boom_exe_agent extends uvm_agent;
  `uvm_component_utils(boom_exe_agent)

  boom_exe_sequencer sqr;
  boom_exe_driver    drv;
  boom_exe_monitor   mon;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    mon = boom_exe_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = boom_exe_sequencer::type_id::create("sqr", this);
      drv = boom_exe_driver::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : boom_exe_agent

`endif

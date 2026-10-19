// sa_agent.svh  -  systolic_array agent

`ifndef SA_AGENT_SVH
`define SA_AGENT_SVH

class sa_agent extends uvm_agent;
  `uvm_component_utils(sa_agent)
  uvm_sequencer #(matmul_item) sqr;
  sa_driver                    drv;
  sa_in_monitor                imon;
  sa_out_monitor               omon;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    sqr  = uvm_sequencer#(matmul_item)::type_id::create("sqr", this);
    drv  = sa_driver::type_id::create("drv", this);
    imon = sa_in_monitor::type_id::create("imon", this);
    omon = sa_out_monitor::type_id::create("omon", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

`endif // SA_AGENT_SVH

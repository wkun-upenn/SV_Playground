//======================================================================
// ss_agent.svh  -  sub_sys channel agents (write & read)
//======================================================================
`ifndef SS_AGENT_SVH
`define SS_AGENT_SVH

class ss_wr_agent extends uvm_agent;
  `uvm_component_utils(ss_wr_agent)
  uvm_sequencer #(matmul_item) sqr;
  ss_wr_driver                 drv;
  ss_in_monitor                mon;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    sqr = uvm_sequencer#(matmul_item)::type_id::create("sqr", this);
    drv = ss_wr_driver::type_id::create("drv", this);
    mon = ss_in_monitor::type_id::create("mon", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

class ss_rd_agent extends uvm_agent;
  `uvm_component_utils(ss_rd_agent)
  uvm_sequencer #(read_item) sqr;
  ss_rd_driver               drv;
  ss_out_monitor             mon;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    sqr = uvm_sequencer#(read_item)::type_id::create("sqr", this);
    drv = ss_rd_driver::type_id::create("drv", this);
    mon = ss_out_monitor::type_id::create("mon", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

`endif // SS_AGENT_SVH

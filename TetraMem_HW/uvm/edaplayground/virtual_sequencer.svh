`ifndef VIRTUAL_SEQUENCER_SVH
`define VIRTUAL_SEQUENCER_SVH

class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(virtual_sequencer)
  uvm_sequencer #(matmul_item) sa_sqr;   // array channel
  uvm_sequencer #(matmul_item) wr_sqr;   // sub-system write channel
  uvm_sequencer #(read_item)   rd_sqr;   // sub-system read  channel
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass

`endif

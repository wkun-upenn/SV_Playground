
// Samples the ss_if bus pins every sys_clk: contraction dim, write/read
// strobes, and the input-FIFO-full / output-FIFO-empty flags.

`ifndef SS_COVERAGE_SVH
`define SS_COVERAGE_SVH

class ss_coverage extends uvm_component;
  `uvm_component_utils(ss_coverage)
  virtual ss_if #(`DW,`NN,`BUSW) vif;
  int mv, wr, rd, full, empty;

  covergroup cg;
    option.per_instance = 1;
    cp_m:     coverpoint mv    { bins mval[] = {[1:`NN]}; }
    cp_wr:    coverpoint wr    { bins idle = {0}; bins write = {1}; }
    cp_rd:    coverpoint rd    { bins idle = {0}; bins read  = {1}; }
    cp_full:  coverpoint full  { bins notfull = {0}; bins full = {1}; }   // input FIFO
    cp_empty: coverpoint empty { bins data = {0};    bins empty = {1}; }  // output FIFO
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::get(this,"","ss_vif",vif))
      `uvm_fatal("NOVIF","ss_vif not set for ss_coverage")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon);
      mv    = vif.mon.M_minus_one + 1;
      wr    = vif.mon.wr_fifo;
      rd    = vif.mon.rd_fifo;
      full  = vif.mon.in_fifo_full;
      empty = vif.mon.out_fifo_empty;
      cg.sample();
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("SUBSYS signal coverage = %0.2f%%", cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass

`endif // SS_COVERAGE_SVH

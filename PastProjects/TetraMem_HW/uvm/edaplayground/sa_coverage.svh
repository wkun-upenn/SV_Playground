// Samples the sa_if pins every array clock: the in_valid / out_valid
// handshake and the sign of the streamed-out c_dout.

`ifndef SA_COVERAGE_SVH
`define SA_COVERAGE_SVH

class sa_coverage extends uvm_component;
  `uvm_component_utils(sa_coverage)
  virtual sa_if #(`DW,`NN) vif;
  int iv, ov, cout_sgn;

  covergroup cg;
    option.per_instance = 1;
    cp_in_valid:  coverpoint iv { bins idle = {0}; bins active = {1}; }
    cp_out_valid: coverpoint ov { bins idle = {0}; bins active = {1}; }
    // sign of the first C element, sampled only while a row is valid
    cp_cout: coverpoint cout_sgn iff (ov) { bins neg = {-1}; bins zero = {0}; bins pos = {1}; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual sa_if #(`DW,`NN))::get(this,"","sa_vif",vif))
      `uvm_fatal("NOVIF","sa_vif not set for sa_coverage")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon);
      iv = vif.mon.in_valid;
      ov = vif.mon.out_valid;
      cout_sgn = ($signed(vif.mon.c_dout[`ACCW-1:0]) < 0) ? -1 :
                 (($signed(vif.mon.c_dout[`ACCW-1:0]) > 0) ? 1 : 0);
      cg.sample();
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("ARRAY signal coverage = %0.2f%%", cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass

`endif // SA_COVERAGE_SVH

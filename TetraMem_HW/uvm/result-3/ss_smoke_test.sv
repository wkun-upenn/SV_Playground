//======================================================================
// ss_smoke_test.sv  -  sub-system: a single M=N multiply, write+read
//======================================================================
`ifndef SS_SMOKE_TEST_SV
`define SS_SMOKE_TEST_SV

class ss_smoke_test extends base_test;
  `uvm_component_utils(ss_smoke_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_seqs(uvm_phase phase);
    ss_vseq v = ss_vseq::type_id::create("v");
    v.num_matrices = 1; v.fixed_m = `NN;
    v.start(env.vseqr);
    wait_sb(env.ss_sb, 1);
  endtask
endclass

`endif // SS_SMOKE_TEST_SV

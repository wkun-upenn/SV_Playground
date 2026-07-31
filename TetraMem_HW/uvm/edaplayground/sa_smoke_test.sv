// Basic smoke test

`ifndef SA_SMOKE_TEST_SV
`define SA_SMOKE_TEST_SV

class sa_smoke_test extends base_test;
  `uvm_component_utils(sa_smoke_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_seqs(uvm_phase phase);
    matrix_seq s = matrix_seq::type_id::create("s");
    s.num = 3; s.fixed_m = `NN;
    s.start(env.sa_agt.sqr);
    wait_sb(env.sa_sb, 3);
  endtask
endclass

`endif // SA_SMOKE_TEST_SV

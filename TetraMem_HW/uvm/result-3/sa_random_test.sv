//======================================================================
// sa_random_test.sv  -  module level: constrained-random matrices, random M
//======================================================================
`ifndef SA_RANDOM_TEST_SV
`define SA_RANDOM_TEST_SV

class sa_random_test extends base_test;
  `uvm_component_utils(sa_random_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_seqs(uvm_phase phase);
    matrix_seq s = matrix_seq::type_id::create("s");
    s.num = 12; s.fixed_m = 0;         // random M in [1..N]
    s.start(env.sa_agt.sqr);
    wait_sb(env.sa_sb, 12);
  endtask
endclass

`endif // SA_RANDOM_TEST_SV

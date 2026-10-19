// base_test.sv  -  every other tests will now extend this test. 

`ifndef BASE_TEST_SV
`define BASE_TEST_SV

class base_test extends uvm_test;
  `uvm_component_utils(base_test)
  systolic_env env;

  function new(string name, uvm_component parent);
    super.new(name,parent); 
  endfunction

  function void build_phase(uvm_phase phase);
    env = systolic_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    run_seqs(phase);
    #200ns; // drain time set for scoreboard
    phase.drop_objection(this);
  endtask

  // override in each test
  virtual task run_seqs(uvm_phase phase);
  endtask

  // block until a scoreboard has processed n matrices, which is parameterized by specific test
  task wait_sb(matmul_scoreboard sb, int n);
    wait ((sb.matched + sb.errors) >= n);
  endtask
endclass

`endif

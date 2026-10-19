//======================================================================
// ss_multichannel_test.sv  -  sub-system: streamed matrices, write & read
//                             channels running concurrently (M = N)
//======================================================================
`ifndef SS_MULTICHANNEL_TEST_SV
`define SS_MULTICHANNEL_TEST_SV

class ss_multichannel_test extends base_test;
  `uvm_component_utils(ss_multichannel_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_seqs(uvm_phase phase);
    ss_vseq v = ss_vseq::type_id::create("v");
    v.num_matrices = 10; v.fixed_m = `NN;
    v.start(env.vseqr);
    wait_sb(env.ss_sb, 10);
  endtask
endclass

`endif // SS_MULTICHANNEL_TEST_SV

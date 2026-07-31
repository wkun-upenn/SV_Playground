//======================================================================
// ss_random_test.sv  -  sub-system: random batches (random M, random
//                       count), drained between M changes
//======================================================================
`ifndef SS_RANDOM_TEST_SV
`define SS_RANDOM_TEST_SV

class ss_random_test extends base_test;
  `uvm_component_utils(ss_random_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_seqs(uvm_phase phase);
    int total = 0;
    for (int b = 0; b < 6; b++) begin
      int mm = $urandom_range(1, `NN);       // random contraction dim
      int nm = $urandom_range(2, 5);         // random matrices this batch
      ss_vseq v = ss_vseq::type_id::create($sformatf("v%0d", b));
      v.num_matrices = nm;
      v.fixed_m      = mm;
      total += nm;
      `uvm_info("SS_RANDOM", $sformatf("batch %0d: M=%0d x %0d matrices", b, mm, nm), UVM_LOW)
      v.start(env.vseqr);
      wait_sb(env.ss_sb, total);
    end
  endtask
endclass

`endif // SS_RANDOM_TEST_SV

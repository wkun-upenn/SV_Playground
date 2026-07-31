//======================================================================
// regression_test.sv  -  long randomized run over BOTH levels; drives
//                        functional coverage toward closure
//----------------------------------------------------------------------
// Vary the seed to get different stimulus, e.g. Xcelium:  -svseed random
//======================================================================
`ifndef REGRESSION_TEST_SV
`define REGRESSION_TEST_SV

class regression_test extends base_test;
  `uvm_component_utils(regression_test)
  int sa_count = 40;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  task run_seqs(uvm_phase phase);
    int total = 0;
    // ---- array: many random matrices (per-matrix random M) ----
    matrix_seq sa = matrix_seq::type_id::create("sa");
    sa.num = sa_count; sa.fixed_m = 0;
    sa.start(env.sa_agt.sqr);
    wait_sb(env.sa_sb, sa_count);

    // ---- sub-system: random batches (random M, random count) ----
    for (int b = 0; b < 6; b++) begin
      int mm = $urandom_range(1, `NN);
      int nm = $urandom_range(3, 6);
      ss_vseq v = ss_vseq::type_id::create($sformatf("v%0d", b));
      v.num_matrices = nm; v.fixed_m = mm;
      total += nm;
      v.start(env.vseqr);
      wait_sb(env.ss_sb, total);
    end
  endtask
endclass

`endif // REGRESSION_TEST_SV

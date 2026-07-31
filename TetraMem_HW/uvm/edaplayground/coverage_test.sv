
// Part 1 drives directed matrices through the ARRAY that between them hit
// every bin of matmul_coverage (M, operand sign/magnitude, result sign,
// overflow, and the M x A-sign / A-sign x B-sign crosses) and of
// sa_coverage (in_valid/out_valid/c_dout).
// Part 2 sweeps M through the SUB-SYSTEM to close ss_coverage (M, wr/rd,
// FIFO full/empty).  So this single test closes ALL THREE covergroups.

`ifndef COVERAGE_TEST_SV
`define COVERAGE_TEST_SV

class coverage_test extends base_test;
  `uvm_component_utils(coverage_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function matmul_item mk(int mv, int a00, int b00, int mode);
    matmul_item it = matmul_item::type_id::create("dit");
    it.gen_cov(mv, a00, b00, mode);
    return it;
  endfunction

  task run_seqs(uvm_phase phase);
    matrix_directed_seq ds = matrix_directed_seq::type_id::create("ds");
    int n = 0;
    // per-M : hits cp_m and the M x A-sign cross (a_sign neg/zero/pos)
    for (int mv = 1; mv <= `NN; mv++) begin
      ds.items.push_back(mk(mv, -5, +5, 0)); // a neg
      ds.items.push_back(mk(mv, +5, +5, 0)); // a pos
      ds.items.push_back(mk(mv,  0, +5, 1)); // a zero (row0 zero)
      n += 3;
    end
    // all 9 A-sign x B-sign combos (at M=N)
    ds.items.push_back(mk(`NN, -5, -5, 0)); // n,n
    ds.items.push_back(mk(`NN, -5, +5, 0)); // n,p
    ds.items.push_back(mk(`NN, -5,  0, 2)); // n,z  (B col0 zero)
    ds.items.push_back(mk(`NN, +5, -5, 0)); // p,n
    ds.items.push_back(mk(`NN, +5, +5, 0)); // p,p
    ds.items.push_back(mk(`NN, +5,  0, 2)); // p,z
    ds.items.push_back(mk(`NN,  0, -5, 1)); // z,n  (A row0 zero)
    ds.items.push_back(mk(`NN,  0, +5, 1)); // z,p
    ds.items.push_back(mk(`NN,  0,  0, 3)); // z,z  (both zero)
    n += 9;
    // operand magnitude buckets: mid (|a|=60) and large (|a|=120)
    ds.items.push_back(mk(`NN, +60,  +5, 0)); // mid
    ds.items.push_back(mk(`NN, +120, +5, 0)); // large
    n += 2;
    // accumulator overflow (max operands, M=N)
    ds.items.push_back(mk(`NN, 0, 0, 4));
    n += 1;

    ds.start(env.sa_agt.sqr);       // array handles any M cleanly
    wait_sb(env.sa_sb, n);

    // part 2: sub-system M sweep -> ss_coverage (M, wr/rd, full/empty) ----
    begin
      int st = 0;
      for (int mm = 1; mm <= `NN; mm++) begin
        ss_vseq v = ss_vseq::type_id::create($sformatf("cv%0d", mm));
        v.num_matrices = 3; v.fixed_m = mm;
        st += 3;
        v.start(env.vseqr);
        wait_sb(env.ss_sb, st);
      end
    end
  endtask
endclass

`endif

//=============================================================================
// boom_exe_tests.sv — the regression test list (94 tests)
//-----------------------------------------------------------------------------
// A test = exe sequence × count × idle-cycle spread × ll-port backpressure ×
// branch-update background × issue-queue sequence × repetitions. The macro
// keeps each test to one line so the list doubles as the test plan.
// Categories: T01–T11 RV64I ALU, T12–T16 branches/jumps, T17–T22 RV64M,
// T23–T24 CSR, T25–T45 FP (single/double, FMA, div/sqrt, conversions,
// rounding modes, NaN boxing), T46–T55 OoO / speculation (branch kills,
// flushes, killing iterative units), T56–T61 stress, T62–T75 issue queue,
// T76–T78 full-system random, T79–T82 sweeps & coverage closure, T83–T92 register model (RAL)
// on the CSR file: reset values, bit-bash, random access + WARL, fflags side effects, frm ->
// dynamic rounding, CSR instructions through the pipeline with passive prediction, aliases,
// illegal accesses, backdoor, random mix.
//=============================================================================
`define BOOM_TEST(NAME, EXESEQ, N, DLY, LL, BRM, IQSEQ, REP) \
class NAME extends boom_exe_base_test; \
  `uvm_component_utils(NAME) \
  function new(string name, uvm_component parent); super.new(name, parent); \
    exe_seq_name = EXESEQ; n_txn = N; max_delay = DLY; ll_ready_pct = LL; brmode = BRM; iq_seq_name = IQSEQ; repeat_seq = REP; \
  endfunction \
endclass

//------------------------------------------------------------------ RV64I ALU
`BOOM_TEST(t01_alu_rr_smoke,          "exe_alu_rr_seq",            200, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t02_alu_rr_random,         "exe_alu_rr_seq",           3000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t03_alu_imm_random,        "exe_alu_imm_seq",          3000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t04_alu_w_random,          "exe_alu_w_seq",            3000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t05_shift_sweep,           "exe_shift_sweep_seq",         0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t06_shift_random,          "exe_shift_seq",            2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t07_cmp_corner,            "exe_cmp_seq",              1500, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t08_int_corner_cross,      "exe_int_corner_cross_seq",    0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t09_lui_auipc,             "exe_alu_imm_seq",          1000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t10_int_all_random,        "exe_int_all_seq",          5000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t11_int_all_b2b,           "exe_int_all_seq",          3000, 0, 100, BR_NONE,    "", 1)
//------------------------------------------------------------------ branches / jumps
`BOOM_TEST(t12_branch_random,         "exe_branch_seq",           3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t13_branch_matrix,         "exe_branch_matrix_seq",       0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t14_jump_random,           "exe_jump_seq",             3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t15_jalr_matrix,           "exe_jalr_matrix_seq",         0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t16_branch_under_mispredict,"exe_branch_seq",          3000, 2, 100, BR_MISPRED, "", 1)
//------------------------------------------------------------------ RV64M
`BOOM_TEST(t17_mul_random,            "exe_mul_seq",              3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t18_mul_b2b,               "exe_mul_seq",              3000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t19_div_random,            "exe_div_seq",              1000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t20_div_corner,            "exe_div_corner_seq",          0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t21_div_collision,         "exe_div_collision_seq",    1500, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t22_div_b2b,               "exe_div_seq",              1000, 0, 100, BR_NONE,    "", 1)
//------------------------------------------------------------------ CSR
`BOOM_TEST(t23_csr_random,            "exe_csr_seq",              2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t24_csr_sweep,             "exe_csr_sweep_seq",           0, 1, 100, BR_NONE,    "", 1)
//------------------------------------------------------------------ FP
`BOOM_TEST(t25_fp_add_random,         "exe_fp_add_seq",           3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t26_fp_mul_random,         "exe_fp_mul_seq",           3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t27_fp_fma_random,         "exe_fp_fma_seq",           4000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t28_fp_corner_cross,       "exe_fp_corner_cross_seq",     0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t29_fma_corner,            "exe_fma_corner_seq",          0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t30_fdiv_random,           "exe_fdiv_seq",             1000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t31_fdiv_collision,        "exe_fdiv_collision_seq",   1500, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t32_fp_sgnj,               "exe_fp_sgnj_seq",          1500, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t33_fp_minmax,             "exe_fp_minmax_seq",        2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t34_fp_cvt_sd,             "exe_fp_cvt_sd_seq",        2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t35_fp_cmp,                "exe_fp_cmp_seq",           2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t36_fp_class,              "exe_fp_class_seq",         1500, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t37_fp_mv,                 "exe_fp_mv_seq",            2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t38_f2i_cvt,               "exe_f2i_cvt_seq",          3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t39_i2f_cvt,               "exe_i2f_cvt_seq",          3000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t40_cvt_corner,            "exe_cvt_corner_seq",          0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t41_rm_sweep,              "exe_rm_sweep_seq",            0, 1, 100, BR_NONE,    "", 1)
`BOOM_TEST(t42_nanbox,                "exe_nanbox_seq",           2000, 2, 100, BR_NONE,    "", 1)
`BOOM_TEST(t43_fp_all_random,         "exe_fp_all_seq",           5000, 3, 100, BR_NONE,    "", 1)
`BOOM_TEST(t44_fp_all_b2b,            "exe_fp_all_seq",           3000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t45_fp_all_backpressure,   "exe_fp_all_seq",           3000, 1,  50, BR_NONE,    "", 1)
//------------------------------------------------------------------ OoO / speculation
`BOOM_TEST(t46_int_all_br_resolve,    "exe_int_all_seq",          3000, 2, 100, BR_RESOLVE, "", 1)
`BOOM_TEST(t47_int_all_br_mispred,    "exe_int_all_seq",          3000, 2, 100, BR_MISPRED, "", 1)
`BOOM_TEST(t48_fp_all_br_mispred,     "exe_fp_all_seq",           3000, 2, 100, BR_MISPRED, "", 1)
`BOOM_TEST(t49_int_all_flush,         "exe_int_all_seq",          3000, 2, 100, BR_FLUSH,   "", 1)
`BOOM_TEST(t50_fp_all_flush,          "exe_fp_all_seq",           3000, 2, 100, BR_FLUSH,   "", 1)
`BOOM_TEST(t51_all_heavy_br,          "boom_exe_base_seq",        4000, 1, 100, BR_HEAVY,   "", 1)
`BOOM_TEST(t52_div_br_mispred,        "exe_div_seq",              1000, 2, 100, BR_MISPRED, "", 1)
`BOOM_TEST(t53_fdiv_br_mispred,       "exe_fdiv_seq",             1000, 2, 100, BR_MISPRED, "", 1)
`BOOM_TEST(t54_fdiv_flush,            "exe_fdiv_seq",             1000, 2, 100, BR_FLUSH,   "", 1)
`BOOM_TEST(t55_mul_br_mispred,        "exe_mul_seq",              2000, 1, 100, BR_MISPRED, "", 1)
//------------------------------------------------------------------ stress
`BOOM_TEST(t56_alu0_only_stress,      "exe_alu0_only_seq",        4000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t57_alu1_only_stress,      "exe_alu1_only_seq",        2000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t58_fpu_only_stress,       "exe_fpu_only_seq",         4000, 0,  70, BR_NONE,    "", 1)
`BOOM_TEST(t59_all_units_stress,      "exe_b2b_seq",              6000, 0, 100, BR_NONE,    "", 1)
`BOOM_TEST(t60_all_units_backpressure,"exe_b2b_seq",              4000, 0,  30, BR_NONE,    "", 1)
`BOOM_TEST(t61_all_random_long,       "boom_exe_base_seq",       12000, 3,  90, BR_MISPRED, "", 1)
//------------------------------------------------------------------ issue queue
`BOOM_TEST(t62_iq_smoke,              "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "boom_iq_base_seq",          1)
`BOOM_TEST(t63_iq_random,             "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "boom_iq_base_seq",          1)
`BOOM_TEST(t64_iq_fill_drain,         "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_fill_drain_seq",         1)
`BOOM_TEST(t65_iq_age_order,          "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_age_order_seq",          1)
`BOOM_TEST(t66_iq_dual_issue,         "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_dual_issue_seq",         1)
`BOOM_TEST(t67_iq_spec_load,          "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_spec_load_seq",          1)
`BOOM_TEST(t68_iq_ld_miss_storm,      "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_ld_miss_storm_seq",      1)
`BOOM_TEST(t69_iq_wakeup_storm,       "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_wakeup_storm_seq",       1)
`BOOM_TEST(t70_iq_fu_mask,            "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_fu_mask_seq",            1)
`BOOM_TEST(t71_iq_branch_kill,        "exe_alu_rr_seq",            300, 3, 100, BR_MISPRED, "iq_branch_kill_seq",        1)
`BOOM_TEST(t72_iq_branch_flush,       "exe_alu_rr_seq",            300, 3, 100, BR_FLUSH,   "iq_branch_kill_seq",        1)
`BOOM_TEST(t73_iq_sparse,             "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_sparse_seq",             1)
`BOOM_TEST(t74_iq_same_cycle_wakeup,  "exe_alu_rr_seq",             50, 3, 100, BR_NONE,    "iq_same_cycle_wakeup_seq",  1)
`BOOM_TEST(t75_iq_heavy_br,           "exe_alu_rr_seq",            300, 3, 100, BR_HEAVY,   "iq_branch_kill_seq",        1)
//------------------------------------------------------------------ full-system random
`BOOM_TEST(t76_full_random,           "boom_exe_base_seq",        3000, 3, 100, BR_MISPRED, "boom_iq_base_seq",          1)
`BOOM_TEST(t77_full_random_heavy,     "exe_b2b_seq",              4000, 0,  60, BR_HEAVY,   "iq_wakeup_storm_seq",       1)
`BOOM_TEST(t78_full_random_long,      "boom_exe_base_seq",       12000, 3,  90, BR_FLUSH,   "iq_fu_mask_seq",            1)
//------------------------------------------------------------------ sweeps
`BOOM_TEST(t79_int_seed_sweep,        "exe_int_all_seq",          1000, 2, 100, BR_MISPRED, "", 5)
`BOOM_TEST(t80_fp_seed_sweep,         "exe_fp_all_seq",           1000, 2,  80, BR_MISPRED, "", 5)

//------------------------------------------------------------------ register model (RAL)
`define BOOM_RAL_TEST(NAME, RALSEQ, WHICH, EXESEQ, N, CSRRM) \
class NAME extends boom_exe_base_test; \
  `uvm_component_utils(NAME) \
  function new(string name, uvm_component parent); super.new(name, parent); \
    ral_seq_name = RALSEQ; ral_which = WHICH; exe_seq_name = EXESEQ; n_txn = N; csr_rm = CSRRM; max_delay = 2; \
  endfunction \
endclass

`BOOM_RAL_TEST(t83_ral_reset,          "ral_builtin_seq",      "reset",   "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t84_ral_bit_bash,       "ral_builtin_seq",      "bitbash", "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t85_ral_access_warl,    "ral_access_seq",       "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t86_ral_fflags,         "ral_fflags_seq",       "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t87_ral_frm_dynamic_rm, "ral_frm_seq",          "",        "exe_fp_all_seq",  500, 1)
`BOOM_RAL_TEST(t88_ral_pipeline_csr,   "ral_pipeline_csr_seq", "",        "exe_csr_seq",     500, 0)
`BOOM_RAL_TEST(t89_ral_alias,          "ral_alias_seq",        "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t90_ral_warl_directed,  "ral_warl_seq",         "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t91_ral_illegal_access, "ral_illegal_seq",      "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t92_ral_backdoor,       "ral_backdoor_seq",     "",        "exe_alu_rr_seq",   20, 0)
`BOOM_RAL_TEST(t93_ral_random_mix,     "ral_random_mix_seq",   "",        "exe_fp_all_seq",  300, 0)
`BOOM_RAL_TEST(t94_ral_fp_random_csr_rm,"ral_frm_seq",         "",        "exe_fp_all_seq", 3000, 1)

//------------------------------------------------------------------ hand-written tests
// t81: execution units without the issue queue built at all (agent/scoreboard/coverage absent)
class t81_no_iq_int_all extends boom_exe_base_test;
  `uvm_component_utils(t81_no_iq_int_all)
  function new(string name, uvm_component parent); super.new(name, parent);
    exe_seq_name = "exe_int_all_seq"; n_txn = 2000; use_iq = 0; endfunction
endclass

// t82: coverage closure — every directed sequence once, then the random classes, all with branch traffic
class t82_coverage_closure extends boom_exe_base_test;
  `uvm_component_utils(t82_coverage_closure)
  function new(string name, uvm_component parent); super.new(name, parent);
    n_txn = 800; brmode = BR_MISPRED; iq_seq_name = "boom_iq_base_seq"; endfunction
  virtual task run_exe_traffic();
    string seqs[] = '{"exe_int_corner_cross_seq", "exe_div_corner_seq", "exe_shift_sweep_seq", "exe_branch_matrix_seq",
                      "exe_jalr_matrix_seq", "exe_fp_corner_cross_seq", "exe_fma_corner_seq", "exe_cvt_corner_seq",
                      "exe_rm_sweep_seq", "exe_nanbox_seq", "exe_csr_sweep_seq", "exe_div_collision_seq",
                      "exe_fdiv_collision_seq", "exe_b2b_seq", "exe_int_all_seq", "exe_fp_all_seq", "boom_exe_base_seq"};
    foreach (seqs[i]) begin
      boom_exe_base_seq s = make_exe_seq(seqs[i]);
      `uvm_info("TEST", $sformatf("--- running %s", seqs[i]), UVM_LOW)
      s.start(env.vsqr);
    end
  endtask
endclass

//-----------------------------------------------------------------------------
// Spike-trace replay tests (t95..t100): real programs — the riscv-tests ISA
// suite Chipyard runs on Spike — replayed through the execution units, with
// Spike's committed results as a second golden reference next to SoftFloat.
// LIST is a file in sim/spike_logs (one commit log per line); the constrained
// random tests above are untouched.
//-----------------------------------------------------------------------------
`define BOOM_SPIKE_TEST(NAME, LIST, DLY, LL, BRM) \
class NAME extends boom_exe_base_test; \
  `uvm_component_utils(NAME) \
  function new(string name, uvm_component parent); super.new(name, parent); \
    spike_list = LIST; max_delay = DLY; ll_ready_pct = LL; brmode = BRM; use_iq = 0; \
  endfunction \
endclass

`BOOM_SPIKE_TEST(t95_spike_rv64ui,             "rv64ui.list", 2, 100, BR_NONE)
`BOOM_SPIKE_TEST(t96_spike_rv64um,             "rv64um.list", 2, 100, BR_NONE)
`BOOM_SPIKE_TEST(t97_spike_rv64uf,             "rv64uf.list", 2, 100, BR_NONE)
`BOOM_SPIKE_TEST(t98_spike_rv64ud,             "rv64ud.list", 2, 100, BR_NONE)
`BOOM_SPIKE_TEST(t99_spike_all_backpressure,   "all.list",    0,  40, BR_NONE)
`BOOM_SPIKE_TEST(t100_spike_all_br_resolve,    "all.list",    1, 100, BR_RESOLVE)

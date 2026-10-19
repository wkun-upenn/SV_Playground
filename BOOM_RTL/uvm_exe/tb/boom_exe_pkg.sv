//=============================================================================
// boom_exe_pkg.sv — the UVM testbench package (everything except the
// definitions package, the interfaces and tb_top)
//=============================================================================
package boom_exe_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boom_exe_defs_pkg::*;

  // transactions
  `include "seq/boom_exe_txn.sv"
  `include "seq/boom_iq_txn.sv"
  `include "seq/boom_csr_txn.sv"
  // configuration + golden model
  `include "env/boom_exe_cfg.sv"
  `include "ref/boom_exe_ref_model.sv"
  // agents
  `include "agent/boom_exe_agent.sv"
  `include "agent/boom_brupd_agent.sv"
  `include "agent/boom_iq_agent.sv"
  `include "agent/boom_csr_agent.sv"
  // register model (RAL)
  `include "ral/boom_csr_reg_cbs.sv"
  `include "ral/boom_csr_reg_block.sv"
  `include "ral/boom_csr_adapter.sv"
  // checkers + coverage
  `include "env/boom_spike_oracle.sv"
  `include "env/boom_exe_scoreboard.sv"
  `include "env/boom_exe_coverage.sv"
  `include "env/boom_iq_scoreboard.sv"
  // environment
  `include "env/boom_exe_env.sv"
  // sequences
  `include "seq/boom_exe_seq_lib.sv"
  `include "seq/boom_iq_seq_lib.sv"
  `include "seq/boom_ral_seq_lib.sv"
  `include "seq/boom_spike_seq_lib.sv"
  // tests
  `include "test/boom_exe_base_test.sv"
  `include "test/boom_exe_tests.sv"
endpackage : boom_exe_pkg

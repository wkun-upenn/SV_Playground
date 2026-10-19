//-----------------------------------------------------------------------------
// boom_exe_pkg.sv -- single compilation unit for the whole UVM environment.
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_PKG_SV
`define BOOM_EXE_PKG_SV

package boom_exe_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import boom_exe_types_pkg::*;

  // forward declarations (used across files)
  typedef class boom_fp_flag_kick_seq;

  // sequence item + sequences
  `include "seq/boom_exe_txn.sv"
  `include "seq/boom_exe_seq_lib.sv"

  // agent
  `include "agent/boom_exe_driver.sv"
  `include "agent/boom_exe_monitor.sv"
  `include "agent/boom_exe_agent.sv"

  // register model (RAL) + adapter
  `include "ral/boom_csr_ral.sv"

  // analysis
  `include "env/boom_exe_scoreboard.sv"
  `include "env/boom_exe_coverage.sv"

  // environment + tests
  `include "env/boom_exe_env.sv"
  `include "test/boom_exe_tests.sv"

endpackage : boom_exe_pkg

`endif

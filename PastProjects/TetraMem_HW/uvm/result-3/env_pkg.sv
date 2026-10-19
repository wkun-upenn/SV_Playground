//======================================================================
// env_pkg.sv  -  environment package
//======================================================================
`ifndef ENV_PKG_SV
`define ENV_PKG_SV
package env_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  import matmul_pkg::*;
  import sa_pkg::*;
  import ss_pkg::*;
  `include "matmul_scoreboard.svh"
  `include "matmul_coverage.svh"
  `include "sa_coverage.svh"
  `include "ss_coverage.svh"
  `include "virtual_sequencer.svh"
  `include "systolic_env.svh"
endpackage : env_pkg
`endif // ENV_PKG_SV

//======================================================================
// ss_pkg.sv  -  sub_sys agent package
//======================================================================
`ifndef SS_PKG_SV
`define SS_PKG_SV
package ss_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  import matmul_pkg::*;
  `include "ss_driver.svh"
  `include "ss_monitor.svh"
  `include "ss_agent.svh"
endpackage : ss_pkg
`endif // SS_PKG_SV

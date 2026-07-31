//======================================================================
// sa_pkg.sv  -  systolic_array agent package
//======================================================================
`ifndef SA_PKG_SV
`define SA_PKG_SV
package sa_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  import matmul_pkg::*;
  `include "sa_driver.svh"
  `include "sa_monitor.svh"
  `include "sa_agent.svh"
endpackage : sa_pkg
`endif // SA_PKG_SV

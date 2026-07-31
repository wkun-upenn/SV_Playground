//======================================================================
// matmul_pkg.sv  -  common transaction package (reused by both levels)
//======================================================================
`ifndef MATMUL_PKG_SV
`define MATMUL_PKG_SV
package matmul_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  `include "matmul_item.svh"
endpackage : matmul_pkg
`endif // MATMUL_PKG_SV

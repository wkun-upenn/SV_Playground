//======================================================================
// test_pkg.sv  -  test package (base test + one file per test)
//======================================================================
`ifndef TEST_PKG_SV
`define TEST_PKG_SV
package test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  import matmul_pkg::*;
  import sa_pkg::*;
  import ss_pkg::*;
  import env_pkg::*;
  import seq_pkg::*;

  `include "base_test.sv"
  `include "sa_smoke_test.sv"
  `include "sa_random_test.sv"
  `include "ss_smoke_test.sv"
  `include "ss_multichannel_test.sv"
  `include "ss_param_test.sv"
  `include "ss_backpressure_test.sv"
  `include "ss_random_test.sv"
  `include "regression_test.sv"
  `include "coverage_test.sv"
endpackage : test_pkg
`endif // TEST_PKG_SV

// The transaction + golden model, compiled without UVM (Verilator smoke test).
package boom_exe_smoke_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import boom_exe_defs_pkg::*;
  `include "seq/boom_exe_txn.sv"
  `include "ref/boom_exe_ref_model.sv"
endpackage

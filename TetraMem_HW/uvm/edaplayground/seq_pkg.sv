//======================================================================
// seq_pkg.sv  -  sequence package
//======================================================================
`ifndef SEQ_PKG_SV
`define SEQ_PKG_SV
package seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "systolic_defines.svh"
  import matmul_pkg::*;
  import env_pkg::*;          // for virtual_sequencer (used by ss_vseq)
  `include "matmul_sequences.svh"
endpackage : seq_pkg
`endif // SEQ_PKG_SV

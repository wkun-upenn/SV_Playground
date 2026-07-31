// A uvm_subscriber connected to both input monitors, so it samples every
// matrix from either level.  Covers the contraction dimension, operand sign and
// magnitude, result sign and accumulator overflow.

// NOTE: This coverage is covering the matmul operation. There is seperate scoreboard for module level and subsystem level design.

`ifndef MATMUL_COVERAGE_SVH
`define MATMUL_COVERAGE_SVH

class matmul_coverage extends uvm_subscriber #(matmul_item);
  `uvm_component_utils(matmul_coverage)
  int sampled = 0;
  int mv, asgn, bsgn, csgn, amag, ovf;   // sampled attributes

// Here we consider different modes in matmul, the coverages are collecting data from randomly generated matrices.
// On a subsystem level, we could verify the integrity of the entire design as a black box verification.
  covergroup cg;
    option.per_instance = 1;
    cp_m:    coverpoint mv   { bins mval[] = {[1:`NN]}; }              // M = 1..N
    cp_a:    coverpoint asgn { bins neg = {-1}; bins zero = {0}; bins pos = {1}; }
    cp_b:    coverpoint bsgn { bins neg = {-1}; bins zero = {0}; bins pos = {1}; }
    cp_c:    coverpoint csgn { bins neg = {-1}; bins zero = {0}; bins pos = {1}; }
    cp_amag: coverpoint amag { bins mz = {0}; bins sml = {1}; bins mid = {2}; bins lrg = {3}; }
    cp_ovf:  coverpoint ovf  { bins no = {0};  bins yes = {1}; }       // C[0][0] wrapped
    x_m_a:   cross cp_m, cp_a;      // every M against every A sign
    x_a_b:   cross cp_a, cp_b;      // every A sign against every B sign
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function int sgn(bit [`DW-1:0] v);
    int s = $signed(v);
    return (s < 0) ? -1 : (s > 0) ? 1 : 0;
  endfunction
  function int mag(bit [`DW-1:0] v);
    int s = $signed(v); if (s < 0) s = -s;
    return (s == 0) ? 0 : (s <= 42) ? 1 : (s <= 85) ? 2 : 3;
  endfunction

  function void write(matmul_item t);
    sampled++;
    mv   = int'(t.m);
    asgn = sgn(t.a[0][0]);
    bsgn = sgn(t.b[0][0]);
    csgn = sgn(t.c[0][0]);
    amag = mag(t.a[0][0]);
    ovf  = t.ovf;
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("TXN coverage = %0.2f%% over %0d matrices",
                               cg.get_inst_coverage(), sampled), UVM_NONE)
  endfunction
endclass

`endif

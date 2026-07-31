// The top level defines clock, which is modifiable.
// DUTs and IFs are instantiated here, run_test is start of everything
// The mapping of design

`timescale 1ns/1ps
`include "systolic_defines.svh"

module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import test_pkg::*;

  logic clk = 0, sys_clk = 0, sr_clk = 0, rst_n;

  always #5 clk     = ~clk;      // systolic array clock
  always #5 sys_clk = ~sys_clk;  // sub-system bus clock
  always #7 sr_clk  = ~sr_clk;   // sub-system compute clock

  // interfaces (instances only; definitions live in tb/interfaces)
  sa_if #(`DW,`NN)        said (clk);
  ss_if #(`DW,`NN,`BUSW)  ssif (sys_clk, sr_clk);

  assign said.rst_n = rst_n;
  assign ssif.rst_n = rst_n;

  wire [`DW-1:0]   sa_a_din  [0:`NN-1];
  wire [`DW-1:0]   sa_b_din  [0:`NN-1];
  wire [`ACCW-1:0] sa_c_din  [0:`NN-1];
  wire [`ACCW-1:0] sa_c_dout [0:`NN-1];
  genvar gi;
  generate
    for (gi = 0; gi < `NN; gi++) begin : G_MAP
      assign sa_a_din[gi] = said.a_din[gi*`DW   +: `DW];
      assign sa_b_din[gi] = said.b_din[gi*`DW   +: `DW];
      assign sa_c_din[gi] = said.c_din[gi*`ACCW +: `ACCW];
      assign said.c_dout[gi*`ACCW +: `ACCW] = sa_c_dout[gi];
    end
  endgenerate

  // DUTs
  systolic_array #(.DIN_WIDTH(`DW), .N(`NN)) dut_sa (
    .rst_n(said.rst_n), .clk(clk),
    .c_din(sa_c_din), .a_din(sa_a_din), .b_din(sa_b_din),
    .in_valid(said.in_valid), .c_dout(sa_c_dout), .out_valid(said.out_valid)
  );

  sub_sys #(.DIN_WIDTH(`DW), .N(`NN), .BUS_WIDTH(`BUSW)) dut_ss (
    .rst_n(ssif.rst_n), .sys_clk(sys_clk), .sr_clk(sr_clk),
    .M_minus_one(ssif.M_minus_one), .din(ssif.din),
    .wr_fifo(ssif.wr_fifo), .rd_fifo(ssif.rd_fifo),
    .in_fifo_full(ssif.in_fifo_full), .dout(ssif.dout), .out_fifo_empty(ssif.out_fifo_empty)
  );

  // reset
  initial begin
    rst_n = 0;
    repeat (10) @(posedge sys_clk);
    rst_n = 1;
  end

  // publish vifs + launch
  initial begin
    uvm_config_db#(virtual sa_if #(`DW,`NN))::set(null, "*", "sa_vif", said);
    uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::set(null, "*", "ss_vif", ssif);
    run_test("ss_multichannel_test");   // default; override with +UVM_TESTNAME
  end

  // waves + watchdog
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
  initial begin
    #2ms;
    `uvm_fatal("TIMEOUT","global watchdog expired")
  end
endmodule

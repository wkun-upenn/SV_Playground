`timescale 1ns/1ps
/* verilator lint_off DECLFILENAME */
module tb;
/* verilator lint_on DECLFILENAME */
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  polymorph dut(.clk(clk));

  initial begin
    #50;
    $finish;
  end
endmodule

`timescale 1ns/1ps
module tb;
  logic clk = 0;
  always #5 clk = ~clk;

  polymorph dut(.clk(clk));

  initial begin
    #50;
    $finish;
  end
endmodule

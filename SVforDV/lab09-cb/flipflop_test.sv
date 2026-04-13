`timescale 1ns/1ps

`define period 10

module testFlop;
  logic clk = 1'b0, reset;
  logic [7:0] qin, qout;
  logic [1:0] epoch = 0;
  logic [7:0] exp = 0;
  
  always #(`period/2) clk = ~clk;
  
  flipflop DUV(.*);
  
  default clocking cb @(posedge clk);
    default input #1 output #4;
    input qout;
    output qin, reset;
  endclocking
  
  task automatic expect_out (input logic [7:0] exp_i);
    assert (cb.qout === exp_i) begin
      $display("[PASS]Assertion successful at %tns: qout=%h, qin == %h", $time*0.001, cb.qout, qin);
    end else begin
      $fatal(1, "[FAIL]Assertion failed at %tns: qout=%h, qin == %h, expected %h", $time*0.001, cb.qout, qin, exp_i);
    end
  endtask
  
//   initial begin
//     $timeformat ( -9, 1, " ns", 9 );
//     $monitor ( "time=%t exp=%h qin=%h qout=%h rst=%b",$time, exp, qin, cb.qout, reset);
//   end
  
  initial begin
    
    cb.qin <= 0;
    cb.reset <= 1;
    ##2 cb.reset <= 0;
    
    for (epoch = 0; epoch < 3; epoch = epoch +1) begin
      $display("Starting test epoch %d", epoch);
      repeat (5) begin
        logic [7:0] num;
        num = $urandom;
        exp = num;
        
        cb.qin <= num;
        ##2;
        expect_out(num);
      end
      $display("Epoch %d Finished Successfully", epoch);
    end
    
    $display("GRAND SUCCESS");
    $finish;
  end
endmodule
  
  
//      // verilator_coverage annotation
        `timescale 1ns/1ps
        
        `define period 10
        
        /* verilator lint_off DECLFILENAME */
        module testFlop;
        /* verilator lint_on DECLFILENAME */
~000049   logic clk, reset;
%000005   logic [7:0] qin, qout;
%000002   logic [1:0] epoch = 0;
        
%000001   initial clk = 1'b0;
 000097   always #(`period/2) clk = ~clk;
        
          flipflop DUV(.*);
        
          /* verilator lint_off UNDRIVEN */
          /* verilator lint_off UNUSEDSIGNAL */
          default clocking cb @(posedge clk);
            default input #1 output #4;
            input qout;
            output qin, reset;
          endclocking
          /* verilator lint_on UNUSEDSIGNAL */
          /* verilator lint_on UNDRIVEN */
        
          task automatic expect_out (input logic [7:0] exp_i);
            assert (cb.qout === exp_i) begin
              $display("[PASS]Assertion successful at %tns: qout=%h, qin == %h", $time*0.001, cb.qout, qin);
            end else begin
              $fatal(1, "[FAIL]Assertion failed at %tns: qout=%h, qin == %h, expected %h", $time*0.001, cb.qout, qin, exp_i);
            end
          endtask
        
        //   initial begin
        //     $timeformat ( -9, 1, " ns", 9 );
        //     $monitor ( "time=%t qin=%h qout=%h rst=%b",$time, qin, cb.qout, reset);
        //   end
        
%000001   initial begin
        
%000001     cb.qin <= 0;
%000001     cb.reset <= 1;
%000001     ##3 cb.reset <= 0;
%000001     ##1;
        
%000003     for (epoch = 0; epoch < 3; epoch = epoch +1) begin
%000003       $display("Starting test epoch %d", epoch);
~000015       repeat (5) begin
 000015         logic [7:0] num;
 000015         num = 8'($urandom_range(255, 0));
        
 000015         cb.qin <= num;
 000015         ##3;
 000015         expect_out(num);
              end
%000003       $display("Epoch %d Finished Successfully", epoch);
            end
        
%000001     $display("GRAND SUCCESS");
%000001     $finish;
          end
        endmodule
        

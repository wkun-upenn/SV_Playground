//      // verilator_coverage annotation
        // flip flop.sv
        
        /* verilator lint_off DECLFILENAME */
~000049 module flipflop (input logic clk, reset,
%000005                  input logic [7:0] qin,
%000005                  output logic [7:0] qout);
        /* verilator lint_on DECLFILENAME */
        timeunit 1ns;
        
 000050 always @(posedge clk or posedge reset)
~000047   if (reset)
%000003     qout <= '0;
          else
 000047     qout <= qin;
        
        endmodule
        

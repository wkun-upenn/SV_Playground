module cnt_abstract_eg   (input logic clk,
                          input logic rst_n,           // interface control
                          output logic A,
                          output logic B,           // serial data control
                          output logic C,         // tristate enable for serial data
                          output logic D
                          );        // serial to parallel shift enable

  logic [31:0] cntr; //Giant counter

  wire  cntr_full =  &cntr;

  always@(posedge clk or negedge rst_n)
    begin
       if (~rst_n)
          begin
            cntr <= 0;
            A <= 1'b0;
            B <= 1'b0;
            C <= 1'b0;
            D <= 1'b0;
          end
       else
          begin
            cntr <= cntr + 1;

            if ( cntr == ((2**23) - 19346 ) )
               A <= 1'b1;

            if ( cntr == ((2**28) - 27311 ) )
               B <= 1'b1;

            if (cntr_full)
               C <= 1'b1;
         end
    end
/////////////////////////
default clocking MY_DEF_CLK @(posedge clk);
endclocking

NEVER_A_2_CYCLES : assert property (A |=> !A);
NEVER_B_2_CYCLES : assert property (B |=> !B);
NEVER_C_2_CYCLES : assert property (C |=> !C);

endmodule

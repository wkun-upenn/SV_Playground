//
//Check of restrict keywords in JG
module fr_cnt #( CNTR_SIZE = 3, SPECIFIC_VAL = 16'h000A) (
	input wire  CLK,
	input wire  rst_n,
        input wire  CNT_ENB,
	output reg[CNTR_SIZE-1:0]  CNT_VAL
	);

reg [1:0] NUM_SPECIFIC_VALS;
//*********************************************************/
always @(posedge CLK or negedge rst_n)
 begin: FREE_RUNNING_CNT
  if(!rst_n) 
    begin
	CNT_VAL <= 0;
	NUM_SPECIFIC_VALS <= 0;
    end 
  else 
     begin
       if ( (CNT_VAL == SPECIFIC_VAL) && (NUM_SPECIFIC_VALS != 2'b10) )
         NUM_SPECIFIC_VALS <= NUM_SPECIFIC_VALS + 1'b1;
                
       if (CNT_ENB && (NUM_SPECIFIC_VALS != 2'b10))
          CNT_VAL <= CNT_VAL + 1'b1;
     end
 end


endmodule


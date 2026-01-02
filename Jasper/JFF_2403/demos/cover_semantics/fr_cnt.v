//
//Check of restrict keywords in JG
module fr_cnt #( CNTR_SIZE = 3) (
	input wire  CLK,
	input wire  rst_n,
        input wire  CNT_ENB,
	output reg[CNTR_SIZE-1:0]  CNT_VAL
	);


//*********************************************************/
always @(posedge CLK or negedge rst_n)
 begin: FREE_RUNNING_CNT
  if(!rst_n) 
    begin
	CNT_VAL <= 0;
    end 
  else 
     begin
       if (CNT_ENB)
          CNT_VAL <= CNT_VAL + 1'b1;
     end
 end


endmodule


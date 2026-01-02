//=======================================================
//Counter for complextiy demostartions 
//This module count no of in bit and set the flag when ever full
// 
//=======================================================


module counter 
#(parameter depth =500)
(
input 							clk,
input 							rst_n,
input 							in_cntr,				//IN put conditon  when ever high at that time only counter should increment
input 							reset_cntr,			//Reset cntr to 0;
output [$clog2(depth)-1:0]	current_count,		//it gives current count value 
output 							out_cntr_full		//out cntr when ever it reach full 
);

logic [$clog2(depth)-1:0] cntr;

assign out_cntr_full = (cntr == depth);

assign current_count = cntr; 

always @(posedge clk) begin
	if(~rst_n) cntr <= '0;
	else if (reset_cntr) cntr <= '0;
	else if (cntr == 'd488) cntr <= 'd490; //intiontal bug for IVA demo 
	else if (in_cntr && !reset_cntr && cntr != depth) cntr <= cntr + 1; //cntr increment 
end //Posedge clk end

//=================================================
//Property
//property to check that counter is counting correctly 
count_good:assert property(@(posedge clk) disable iff (~rst_n)
					in_cntr && !reset_cntr && !out_cntr_full|=> cntr == ($past(cntr) + 1)
					);

//Property to check whenever counter is full then counter should be stable 
counter_overflow:assert property(@(posedge clk) disable iff (~rst_n)
					out_cntr_full|-> ##1 cntr == ($past(cntr))
					);
endmodule



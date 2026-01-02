
module FSM_IF_TEST;

wire 		clk, reset;                 
reg  [5:0] 	count40;  
wire 		tclk, 	trst, dq_en, sr_en; 


  FSM_IF U1 (.clk(clk), .reset(reset), .count40(count40), .tclk(tclk), .trst(trst), .dq_en(dq_en), .sr_en(sr_en));

  always @(posedge clk or negedge reset)    // generate the count
    if (~reset)  // active high reset
      //count40 <= 6'b0;
      count40 <= 38;
    else if (count40 == 39)
      count40 <= 6'b0;
    else
      count40 <= count40 + 6'b1;

     
endmodule

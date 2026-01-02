/************************************************************************* 
**************************************************************************/
module test (
	input clk,
	input rst_n,
        input A,
        input B,
        input C,
        input D,
        input E,
        input F,
        input G,
        input H,
        input I,
        input J,
        input K
	); 

/********************  Assertion Defininition  ********************/
`ifdef ABV_ON
default clocking DEFCLK @(posedge clk);
endclocking


//Property Set 1
PROP_SET1: assert property(A |=> strong(!D[*] ##1 C)) ;

//Property Set 2
PROP_SET2: assume property( A |=> (!D s_until C ));


`endif // ABV_ON

endmodule

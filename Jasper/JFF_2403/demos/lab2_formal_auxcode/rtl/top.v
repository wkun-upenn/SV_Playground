//A wrapper to hold a bind statement
//Not yet supported in IFV but is in IES 
//You can work around this with the extbind switch
//but it is tool specific.

module top (	
        input wire  clk,
	input wire  rst_n,
	input wire  lfsr_enb,
	input wire  req,
	output wire ack
	);

reqack_duv  duv_inst  (.req(req), .ack(ack), .clk(clk), .rst_n(rst_n), .lfsr_enb(lfsr_enb) );
bind reqack_duv reqack_vcomp vcomp_inst(.req(req), .ack(ack), .clk(clk), .rst_n(rst_n), .lfsr_enb(lfsr_enb) );
	
endmodule

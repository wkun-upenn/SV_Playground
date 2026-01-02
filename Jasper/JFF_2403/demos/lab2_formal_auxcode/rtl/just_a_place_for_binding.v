//This module will be elaborated seperatly from the rest of the design
//It merely provides a container for the binding of our vcomp to the duv
//The problem with SVA bind statements is that you need some place to put them
//IFV does not currently allow elaboration of this, but IES (the simulator) does
module just_place_for_binding;
   bind reqack_duv reqack_vcomp vcomp_inst(.req(req), .ack(ack), .clk(clk), .rst_n(rst_n), .lfsr_enb(lfsr_enb) );
endmodule

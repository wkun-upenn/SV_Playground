module reqack_vcomp (
	input wire  clk,
	input wire  rst_n,
	input wire  lfsr_enb,
	input wire  req,
	input reg ack
	);

//@@@@@@@@@ Code relating to Assertion Based Verification @@@@@@@@@@@@@
`ifdef ABV_ON 

//////////////   Put your Auxiliary code here ////////////////////////
//#### EDIT ###




//#### END OF EDIT ###
//////////////  End of Auxiliary code ///////////////////////////////

/////////////   Put your SVA Assertions here ////////////////////////
//#### EDIT ###




//#### END OF EDIT ###
//---------------- End of Assertions ------------------------------


//----------------  Define your Coverage Here  --------------------
//#### EDIT ###




//#### END OF EDIT ###

//---------------- End of Coverage ------------------------------
 
//####################################################################################################
//####################################################################################################
//##################  PLEASE DO NOT EDIT BELOW THIS LINE                 #############################
//####################################################################################################
//####################################################################################################






















                    
//---------------- Assumptions ----------------------------------
//Without this assumption a property which states every req must have an ack
//probably fail.
//Formal will cause the trigger for the property to occur,
//making the unacknowledged req counter above its starting value,
//and then it will just keep sending reqs so the counter never gets back
//to its starting value.
//This constraint says "at every cycle, to infinity, there must 
//always be 9 cycles where req is held at 0 in the future."		    
//This gives time for the outstanding acks to be sent and
//the property passes.

assume_req_fairness : assume property (
   @( posedge clk)
                   (s_eventually !req[*9]) );
//Bow explored with depth 	226 after 25 minutes on my machine   
/////////////   End of SVA Properties ////////////////////////////////
`endif // ABV_ON

//@@@@@ End of Code relating to Assertion Based Verification @@@@@@@@@


endmodule

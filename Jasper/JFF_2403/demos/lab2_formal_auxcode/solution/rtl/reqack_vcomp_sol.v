//////////////////////////////////////////////////////////////////////
//
// File name: reqack_vcomp.v
// Version  : 2.0
// Date     : 24/8/2012
// Author   : Mike Avery
// Company  : Cadence Design Systems
//
//////////////////////////////////////////////////////////////////////
//
// Revision history
//
// Rev:  Date;         Author:      Comments:
// 1.1   20/5/2010    Mike Avery   Seperate verification code into vcomp
// 2.0   24/8/2012    Mike Avery   Updated for INCISIV12.1

//This file defines SVA properties and AUX code


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
`define MAX_CNT_INDEX 2
reg[`MAX_CNT_INDEX:0] NUM_HSHAKES ;
//Offset the counter so that we can use a vector
//instead of an integer. It is much more efficient for formal
localparam HSHAKE_START_CNT = 3'h1;

always @(posedge clk or negedge rst_n)
 begin: MYPROC
  if  (!rst_n)
  //Offset the counter to a mid value in order that an array
  //can be used instead of an integer.
  //This is more efficient for formal
    NUM_HSHAKES <=  HSHAKE_START_CNT;
  else 
     begin
        if (req & !ack)
           NUM_HSHAKES <= NUM_HSHAKES + 1;
        if  (ack & !req)
           NUM_HSHAKES <= NUM_HSHAKES - 1;
      end
 end
//#### END OF EDIT ###
//////////////  End of Auxiliary code ///////////////////////////////

/////////////   Put your SVA Assertions here ////////////////////////
//#### EDIT ###
default clocking DEFCLK @(posedge clk);
endclocking

//---------------- Define your Assertions Here  ---------------------

//Check that if we have no oustanding transactions and a request
//that we see the counter being the value representing no 
//outstanding transactions again
property NUM_ACKS_REQS_EQUAL;
  ( req && (NUM_HSHAKES== HSHAKE_START_CNT )  |=> s_eventually (NUM_HSHAKES == HSHAKE_START_CNT) );
endproperty

//Check our counter never goes below its starting level,
//i.e. we never have more acks than reqs
property ONLY_ACK_IF_REQ;
  not (NUM_HSHAKES < HSHAKE_START_CNT );
   endproperty

//Instance those properties
ACK_FOR_EVERY_REQ : assert property (NUM_ACKS_REQS_EQUAL);
NO_SPURIOUS_ACKS  : assert property (ONLY_ACK_IF_REQ);

//Check that the number of outstanding acks cannot be greater than 4
never_5_outstanding_reqs: assert property( NUM_HSHAKES <= (HSHAKE_START_CNT+4));

//Check ack cannot occur without a prior(hence an outstanding) req
never_5_ack_b4_req: assert property( req && ack |-> (NUM_HSHAKES != HSHAKE_START_CNT));



property CONSEC_REPS_OF_SIG (a_sig, num_reps);
   (a_sig[*num_reps]) ; 
endproperty

property SIG_EQUAL_NUM(a_sig, a_num); 
    (a_sig == a_num);
endproperty
//#### END OF EDIT ###
//---------------- End of Assertions ------------------------------


//----------------  Define your Coverage Here  --------------------
//#### EDIT ###
//Define coverage to check our formal environment is OK
//Check that it is possible to have 4 consecutive reqs
cov_4_consec_reqs: cover property(CONSEC_REPS_OF_SIG(req, 4));

//Check that it is possible to have 4 oustanding reqs
cov_4_outstanding_reqs: cover property(SIG_EQUAL_NUM(NUM_HSHAKES, HSHAKE_START_CNT+4));

//Checks that its possible to go from zero oustanding reqs, 
//to 3 oustanding reqs and back again
cov_4_OS_reqs_to_0_to_4: 
       cover property ( 
         ( (NUM_HSHAKES == HSHAKE_START_CNT+4) ##[0:$]  (NUM_HSHAKES == HSHAKE_START_CNT) ##[0:$] 
	          (NUM_HSHAKES == HSHAKE_START_CNT+4)  ));

//Check that it is possible to have 2 consecutive acks
cov_2_consec_acks: cover property(CONSEC_REPS_OF_SIG(ack, 2));

cov_req_ack_same_cycle: 
       cover property (  req && ack );
       

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
   
/////////////   End of SVA Properties ////////////////////////////////
`endif // ABV_ON

//@@@@@ End of Code relating to Assertion Based Verification @@@@@@@@@


endmodule

//////////////////////////////////////////////////////////////////////
//
// File name: reqack_duv.v
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
// 1.0   27/4/2010    Mike Avery   CDN Live MUC 2010
// 1.1   20/5/2010    Mike Avery   Seperate verification code into vcomp
// 2.0   24/8/2012    Mike Avery   Updated for INCISIV12.1

//This file defines RTL design code, for a design which responds with 
//an ack to every req.
//It should not be possible to have more than 4 oustanding reqs 
// at any given cycle


module reqack_duv (
	input wire  clk,
	input wire  rst_n,
	input wire  lfsr_enb,
	input wire  req,
	output reg ack
	);

//##########  RTL Design HDL Code ####################################

///////////  Declarations for Counter  ////////////////////////////////
reg [2:0] cnt;
///////  End of declarations for Counter //////////////////////////////

///////////////// Combinational Logic ////////////////////////////////
//Choose some random element of counter to indicate when to acknowledge
//after some [pseudo]random delay
wire ok_2_send_oustanding_ack;
wire ok_2_send_immediate_ack;

//Set this wire to the same bit of counter to reduce state space
assign ok_2_send_oustanding_ack = cnt[0];
assign ok_2_send_immediate_ack  = cnt[0];
/////////////  End of combinational Logic ////////////////////////////

////////////////  Counter Block /////////////////////////////////////////

always @(posedge clk or negedge rst_n)

begin: LFSR_PROC
    if(!rst_n) 
        cnt <= 2'h0;
    else if (lfsr_enb) 
          cnt <= cnt + 1;
end 

//////////// Ack sending block  /////////////////////////////////////

reg [2:0] unacked_reqs;

always @(posedge clk or negedge rst_n)

begin : ACK_SENDER_PROC
  if(!rst_n) 
     begin
        ack <= 1'b0;
	unacked_reqs = 3'h0;
     end 
  else  
     begin  
        if (req && !ack)
            unacked_reqs = unacked_reqs + 1;
        else if (!req && ack)
            unacked_reqs = unacked_reqs - 1;  

	if (req && (unacked_reqs == 4))   
            ack <= 1'b1;           	
        else if ((unacked_reqs != 0) && (ok_2_send_immediate_ack || ok_2_send_oustanding_ack) )
            ack <= 1'b1;           
        else           
           ack <= 1'b0; 
      end   //if(!rst_n)... else...                  
end //always @(posedge clk or negedge rst_n)


//########## End of RTL Design HDL Code ##############################


endmodule

//////////////////////////////////////////////////////////////////////
//
// Original Code Copyright (c)2006-2014 by Cadence Design Systems (www.cadence.com)
//
// All rights reserved.
//
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains this copyright notice.
//
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
//
// File name: frame.v
// Version  : 2.0
// Date     : 27/10/2014
// Author   : Mike Avery
// Company  : Cadence Design Systems
//
//////////////////////////////////////////////////////////////////////
//
// Revision history
//
// Rev:  Date;         Author:      Comments:
// 1.0   19/1/2006    Mike Avery   Initial issue
// 2.0   27/10/2014   Mike Avery   2009 and 2012 SV LRM update and Jasper support
// 2.1   1/8/2016     Mike Avery   Removed rst_n from combinatorial expressions
// 3.0   16/11/2021   Mike Avery   Put rst_n back in combinational expressions, 
//                                 in case reset behaviour needs checking 

//Description.
//Correct Start of Packet and end of packet errors.
//**************************************************************************/

module frame (
	input wire  clk,
	input wire  rst_n,
	input wire  valid_in,
	input wire  sop_in,
	input wire  eop_in,
	output wire valid_out,
	output wire sop_out,
	output wire eop_out
	);


//################################ EDIT HERE #########################//
/***********  Declarations ***************************************/
// calculate when sop should not be passed through
reg mask_sop; 
// calculate when eop should not be passed through
reg mask_eop;


/********************  Combinational Logic     ********************/
//Replicate valid signal to valid_out port
assign valid_out = valid_in;

//Put your combinational logic here
assign sop_out  = valid_out && sop_in && !mask_sop;
assign eop_out  = valid_out && eop_in && (sop_in?1:(!mask_eop &&  mask_sop));

/********************  End Combinational Logic ********************/

/********************  Sequential Logic        ********************/
always @(posedge clk or negedge rst_n) begin
  
  if(!rst_n) begin
  		mask_sop <= 0;
		mask_eop <= 0;
	//Put asynchronus reset actions here
  end 
  else begin
		if (valid_in && sop_in && !eop_in)
  		begin
  			mask_sop <= 1;
		//put any state you need to remember here
  		end
  		else if (valid_in && eop_in && mask_sop)
  		begin
  			mask_sop <= 0;	
  		end
  		//EOP
  		if (valid_in && eop_in && !sop_in)
  		begin 
  			mask_eop <= 1;
		end

		else if (valid_in && !eop_in && sop_in)
  		begin 
  			mask_eop <= 0;
		end
	end
end
/********************  End Sequential Logic ********************/


`ifdef ABV_ON 
/////////////   Put your assertions here /////////////////////
reg sop_flag;
reg eop_flag;

always@(posedge clk)
begin
  if(!rst_n) begin
	sop_flag <= 0;
  end 
  else if (sop_out && !eop_out)
  begin
	sop_flag <=1;
  end
  else if (eop_out && !sop_out)
  begin
  	sop_flag <= 0;
  end
end

SOP_NSOP:assert property (@(posedge clk) disable iff (~rst_n)
									sop_flag |-> !sop_out);

EOP_AFTER_SOP:assert property (@(posedge clk) disable iff (~rst_n)
									sop_flag  |-> ##[0:$] eop_out);

NEOP_WO_NSOP:assert property (@(posedge clk) disable iff (~rst_n)
									!sop_flag && !sop_out  |-> !eop_out);


SOP_VALID:assert property (@(posedge clk) disable iff (~rst_n) 
									eop_out || sop_out |-> valid_out);
















//################################ END OF EDIT  #########################//






/******************************************************************/
/********************  DO NOT EDIT BELOW THIS LINE   **************/
/******************************************************************/

///////////////////////////////////////////////////////////////////////////////////////

//Conditionally instance a VCOMP module if we are performing the predefined ACID_TEST.

`ifdef ACID_TEST
    bind frame frame_vcomp frame_vcomp_acid_inst(
    .vc_clk(clk),
    .vc_rst_n(rst_n),
    .vc_valid_in(valid_in),
    .vc_sop_in(sop_in),
    .vc_eop_in(eop_in),
    .vc_valid_out(valid_out),
    .vc_sop_out(sop_out),
    .vc_eop_out(eop_out)
    );
`endif //ACID_TEST
///////////////////////////////////////////////////////////////////////////////////////

`endif // ABV_ON

endmodule


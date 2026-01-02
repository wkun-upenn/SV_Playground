// This is a wrapper module that is used to instantiate the Jasper Scoreboard Proof Accelerator
module sb_wrapper (
   input clk,
   input rstN,
   input push,
   input [7:0] data_in,
   input pop,
   input [7:0] data_out
);

//Connect these debug wires to the Scoreboard *_selected signals
   wire  selData_in;
   wire  selData_out;

//
// Jasper Scoreboard PA
//To make available the `JS3_IN_ORDER and `JS3_OUT_OF_ORDER macros which 
//are passed as parameters to the scoreboard parameter ORDERING,
//you will have to use the Tcl command "jasper_scoreboard_3 -init" in
//your JG Tcl script. Its a FIFO - Which value do you use for parameter ORDERING?
//The command needs executing before analyzing source files which use the macros
//
//As the DUT is a FIFO, The parameter MAX_PENDING should be set to the fifo depth
//#### EDIT ###################################################################
//TODO: connect up the Scoreboard PA ports, parameters
jasper_scoreboard_3 #(
  .CHUNK_WIDTH(8),
  .IN_CHUNKS(1),
  .OUT_CHUNKS(1),
  .SINGLE_CLOCK(1),
  .ORDERING(`JS3_IN_ORDER),
  .MAX_PENDING(4)
   ) jg (
      .clk(clk),
      .rstN(rstN),
      .incoming_vld(push),
      .incoming_data(data_in),
      .outgoing_vld(pop),
      .outgoing_data(data_out),
      .incoming_selected(selData_in),
      .outgoing_selected(selData_out)
   );
//#### END OF EDIT ############################################################


endmodule

// Bind the SB wrapper to the fifo
//This binding could be in any file but for convenience
//it is placed here.
bind fifo sb_wrapper sb (.*);

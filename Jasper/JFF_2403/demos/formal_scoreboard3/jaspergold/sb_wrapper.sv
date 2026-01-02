// This is a wrapper module that is used to instantiate the Jasper Scoreboard Proof Accelerator
module sb_wrapper (
   input clk,
   input rstN,
   input push,
   input [7:0] data_in,
   input pop,
   input [7:0] data_out
);

//Connect these debug wires to the Scoreboard *coming_selected signals
   wire  selData_in;
   wire  selData_out;

//
// Jasper Scoreboard PA
//To make available the `JS3_IN_ORDER and `JS3_OUT_OF_ORDER macros which 
//are passed as parameters to the scoreboard parameter ORDERING,
//you will have to use the Tcl command "jasper_scoreboard_3 -init" in
//your JG Tcl script. TIP-Its a FIFO - Which value do you use for parameter ORDERING?
//The command needs executing before analyzing source files which use the macros
//
//As the DUT is a FIFO, The parameter MAX_PENDING should be set to the fifo depth
//#### EDIT ###################################################################
//TODO: connect up the Scoreboard PA ports, parameters
jasper_scoreboard_3 #(
  .CHUNK_WIDTH(??),
  .IN_CHUNKS(??),
  .OUT_CHUNKS(??),
  .SINGLE_CLOCK(??),
  .ORDERING(??),
  .MAX_PENDING(??)
   ) jg (
      .clk(??),
      .rstN(??),
      .incoming_vld(??),
      .incoming_data(??),
      .outgoing_vld(??),
      .outgoing_data(??),
      .incoming_selected(??),
      .outgoing_selected(??)
   );
//#### END OF EDIT ############################################################


endmodule

// Bind the SB wrapper to the fifo
//This binding could be in any file but for convenience
//it is placed here.
bind fifo sb_wrapper sb (.*);

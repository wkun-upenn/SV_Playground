module top;

`include "header_def.inc"

reg clk = 0, rst = 0;
wire frame, serial, suspend;

//We could use @(posedge suspendclk) but that requires creating an
//extra wire. It's simpler to use @(posedge clk iff !suspend)
//wire #1 suspendclk = clk && !suspend;
//wire suspendclk = clk && !suspend;

always #5 clk <= !clk;

spi_test tb 
    (.frame(frame), .serial(serial), .suspend(suspend), .clk(clk), .rst(rst));
spi dut
    (.frame(frame), .serial(serial), .suspend(suspend), .clk(clk), .rst(rst));

initial begin
  #10 rst = 1'b1;
  #10 rst = 1'b0;
end  

////////////////////////////////////////////////////////////////////
////////////  Define your SVA sequences and properties here ////////
////////////////////////////////////////////////////////////////////
//#### EDIT ###
sequence framestart;
  $rose(frame);
endsequence

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!! Interesting Solution Example     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//To implement this would be really tricky if you are new to SVA
//Alternative and equivalent solutions are also descibed here.
//This shows how to pass values from a sequence back up to its parent using a typed parmeter.
//Note that 3 of the 4 sequence parmaters are untyped
//Also note that we have to ensure that the "thread" calling this sequence does not start mutliple
//copies of this mutli-cycle sequence or the local variable of the parent, to which the value
//gets returned, will be overwritten by the newest sequence started.
//You would probably need a fews week of experience with SVA after this course before
//being able to construct this solution from memory.
//However you are encouaged to ask questions about the solution and experiment to ensure that 
//you understand how the solution works.
//
sequence capturehead(frame_sig, data_sig, num_cycles, logic [7:0] the_header );
  logic [7:0] seq_header = 8'hAA;
  int i = 0;
   ( framestart ##1 (frame_sig, seq_header[i] = data_sig, i++)[*num_cycles] ##0 (1, the_header = seq_header) ); 
endsequence
/////////////////////////////////////////////////////

sequence startcomplete(dat);
  (!frame && (dat == start));
endsequence 

sequence configcomplete(dat);
  frame[*8] ##1 (!frame && (dat == cfg), $display("dat is %x", dat) );
endsequence 

sequence readcomplete(dat);
  frame[*10] ##1 (!frame && (dat == read));
endsequence


property framecheck;
logic [7:0] head = 0;
int i = 0;
  @(posedge clk iff !suspend)
    (framestart, i=0) |=>  
    ( frame , head[i] = serial, i++, $display("Time is %t, Head is %b, Head[i] is %x, Serial is %x, i is %d", $time, head, head[i], serial, i) )[*8] ##1
    ( (configcomplete(head) or startcomplete(head) or readcomplete(head)) , $display("Head is %x, i is %d", head, i) ) ;
endproperty

//Instance the property and demonstrate pass/fail blocks for assertions
FRMCHK :assert property(framecheck) 
   $display("Assertion FRMCHK passed!"); //put any number of non time consuming statements here. Use begin-end if more than one
 else
   $display("Assertion FRMCHK failed!"); //put any number of non time consuming statements here. Use begin-end if more than one


//This assertion uses the "capturehead" sequence described above,
//and is functionally equivalent to the property framecheck above.
//However, the property framecheck_best is arguably the most elegant solution.
//Notice that same cycle implication is used because the capturehead sequence 
//detects the rise of frame. Indeed it needs to otherwise we would get the 
//sequence capturehead start on every cycle frame occurs (8 in total) inside property
property framecheck_best;
  logic [7:0] a_header = 0;
  @(posedge clk iff !suspend)
     framestart |-> capturehead(frame, serial, 8, a_header) ##1 
           (configcomplete(a_header) or startcomplete(a_header) or readcomplete(a_header));
endproperty  

FRMCHK_BEST :  assert property(framecheck_best);


//Generic property to check that a signal is not high for more than X cycles
property SIG_NOT_HIGH_FOR_X_CYCLES(a_sig, num_cycles);
   @(posedge clk) not a_sig[*num_cycles];
endproperty

//Check suspend is not high for 4 cycles
CHK_SUS_NOT_HIGH_4_CYCLES: assert property(SIG_NOT_HIGH_FOR_X_CYCLES(suspend, 4));
//#### END OF EDIT ###

///////////////  Add your coverage statements here /////////////////////
//#### EDIT ###
//This assertion uses the "capturehead" sequence described above. 

sequence num_starts_best(num_head_cycles);
  logic [7:0] head = 0;
   @(posedge clk iff !suspend)
  ( capturehead(frame, serial, num_head_cycles, head) ##1 startcomplete(head) );
endsequence

COV_START_BEST        : cover property ( num_starts_best(8));

sequence num_starts;
logic [7:0] head = 0;
int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1
    startcomplete(head);
endsequence

sequence num_configs;
logic [7:0] head = 0; 
int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1
    configcomplete(head);
endsequence

sequence num_reads;
logic [7:0] head = 0;
int i = 0;
  @(posedge clk iff !suspend)
  framestart ##1 (frame, head[i] = serial, i++)[*8] ##1
    readcomplete(head);
endsequence

sequence illegal_txn;
  logic [7:0] head = 0;
  int i = 0;
  @(posedge clk iff !suspend)  
   framestart ##1 (frame, head[i] = serial, i++)[*8] ##1 (head != start) && (head != cfg) && (head != read);
endsequence

COV_START        : cover property (num_starts);
COV_CONFIG       : cover property (num_configs);
COV_READS        : cover property (num_reads);
COV_ILLEGAL_HEAD : cover property (illegal_txn);

//#### END OF EDIT ###

endmodule : top

module top;

`include "header_def.inc"

logic [7:0] a_header;
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


////////////  Define your SVA sequences and properties here ////////
//#### EDIT ###





//#### END OF EDIT ###

///////////////  Add your coverage statements here /////////////////////
//#### EDIT ###





//#### END OF EDIT ###

endmodule : top

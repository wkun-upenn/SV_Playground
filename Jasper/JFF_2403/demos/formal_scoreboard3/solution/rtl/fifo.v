
module fifo (
        clk, rstN,
        push, data_in,
        pop, data_out,
        is_empty, is_full
);
parameter fifo_depth = 8;
parameter fifo_width = 128;
parameter fifo_ptr_width =
        (fifo_depth<   2) ?  1 :
        (fifo_depth<   4) ?  2 :
        (fifo_depth<   8) ?  3 :
        (fifo_depth<  16) ?  4 :
        (fifo_depth<  32) ?  5 :
        (fifo_depth<  64) ?  6 :
        (fifo_depth< 128) ?  7 :
        (fifo_depth< 256) ?  8 :
        (fifo_depth< 512) ?  9 :
        (fifo_depth<1024) ? 10 :
        (fifo_depth<2048) ? 11 : 16;

input       clk, rstN;
input       push, pop ;
input  [fifo_width-1:0] data_in;
output [fifo_width-1:0] data_out;
output      is_empty, is_full;

reg [fifo_width-1:0] fifo[fifo_depth-1:0];
reg [fifo_ptr_width-1:0]rd_ptr;
reg [fifo_ptr_width-1:0]wr_ptr;
wire write_flag ;
wire read_flag  ;

assign is_empty = (rd_ptr == wr_ptr) ;
assign is_full  = (rd_ptr == ((wr_ptr + 1'b1)%fifo_depth)) ;

assign write_flag = is_full ? (push && pop) : push ;
assign read_flag  = is_empty ? 1'b0 : pop ;

always@(posedge clk) begin
    if(rstN==0) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
    end
    else begin
        if(write_flag) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= (wr_ptr + 1'b1) % fifo_depth ;
        end
        if (read_flag) begin
            rd_ptr <= (rd_ptr + 1'b1)%fifo_depth;
        end
    end
end

assign data_out = fifo[rd_ptr] ;

default clocking DEFCLK @(posedge clk);
endclocking
//#### EDIT ###################################################################
//Write assumptions to ensure that we don't read an 
//empty FIFO or write to a full fifo
asm_dont_read_mt    : assume property (is_empty |-> !pop);
asm_dont_write_full : assume property (is_full |-> !push);

//#### END OF EDIT ############################################################

endmodule

//--------------------------------------------------------------------
// module
module tags (
   input logic             clk,
   input logic             rst_n,

   input logic             rx_valid,
   input logic             rx_ready,
   input logic [2:0]       rx_tag,

   input logic             tx_valid,
   input logic             tx_ready,
   input logic [2:0]       tx_tag,

   input logic            dut_full,
   input logic            dut_empty
);

default clocking def_clk @(posedge clk); endclocking

//-----------------------------------------------------------------------------
// tracking logic - which locations are currently occupied
//-----------------------------------------------------------------------------
logic [7:0] used_tag;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      used_tag <= 8'h00;
   else begin
      if (rx_valid & rx_ready) used_tag[rx_tag] <= 1'b1;
      if (tx_valid & tx_ready) used_tag[tx_tag] <= 1'b0;
   end
end

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// tracking logic - which locations have previously been occupied
//required to enforce a "write once" only scheme
//Only difference to used tag is that the bits are sticky when high
//-----------------------------------------------------------------------------
logic [7:0] prev_been_used_tag;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      prev_been_used_tag <= 8'h00;
   else begin
      if (rx_valid & rx_ready) prev_been_used_tag[rx_tag] <= 1'b1;
   end
end

//-----------------------------------------------------------------------------


// Mimic the behaviour of DUT fill and emtpy signals
logic vc_full;
logic vc_empty;

assign vc_full  = &used_tag;
assign vc_empty = ~|used_tag;

//-----------------------------------------------------------------------------
// transaction counters
//-----------------------------------------------------------------------------
logic [3:0]               tx_cnt;
logic [3:0]               rx_cnt;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      begin
         tx_cnt <= 4'b0000;
         rx_cnt <= 4'b0000;
      end
   else 
      begin
         if (tx_valid & tx_ready) tx_cnt <= tx_cnt + 1'b1;
         if (rx_valid & rx_ready) rx_cnt <= rx_cnt + 1'b1;
      end
end

//-----------------------------------------------------------------------------
// properties
//-----------------------------------------------------------------------------
//Follow valid/ready rules
asm_rx_valid_hold:       assume property ((rx_valid & ~rx_ready) |=> rx_valid);
asm_tx_valid_hold:       assume property ((tx_valid & ~tx_ready) |=> tx_valid);
ast_rx_id_stable:        assume property ((rx_valid & ~rx_ready) |=> $stable(rx_tag));
ast_tx_id_stable:        assume property ((tx_valid & ~tx_ready) |=> $stable(tx_tag));

//The constraint below prevents the location being overwriiten but does not prevent
//the location being written to twice or more, with an interveining read.
asm_rx_tag_overwrite:    assume property ((rx_valid & rx_ready)  |-> ~used_tag[rx_tag]);
//The constrint below prevents reading a tag before it has even been written into the DUT
asm_tx_tag_check:        assume property ((tx_valid & tx_ready)  |-> used_tag[tx_tag]);
//This assumption enforces that each location can only be used once
//Without this single property every locstion can be written to and read from indefinatly
asm_dont_use_rx_tag_twice: assume property ((rx_valid & rx_ready)  |-> ~prev_been_used_tag[rx_tag]);

asm_no_push_when_full:   assume property (vc_full              |-> ~rx_valid);
asm_no_pop_when_empty:   assume property (vc_empty             |-> ~tx_valid);

ast_no_full_empty:       assert property (not (vc_full & vc_empty));
ast_full_no_pop:         assert property (vc_full  & ~tx_valid |=> vc_full);
ast_empty_no_push:       assert property (vc_empty & ~rx_valid |=> vc_empty);

//When we have a DUT then these properties should always hold
//Without a DUT clearly they will fail as dut_full and dut_empty are unconstrained
ast_vc_full_same_as_dut_full  : assert property (dut_full == vc_full);
ast_vc_empty_same_as_dut_empty: assert property (dut_empty == vc_empty);

//-----------------------------------------------------------------------------
////////////////   Covers /////////////////////////////////////
//-----------------------------------------------------------------------------
cov_going_full:      cover property (~vc_full  ##1     vc_full);
cov_going_empty:     cover property (~vc_empty ##1     vc_empty);
cov_empty_to_full:   cover property ( vc_empty ##[1:$] vc_full);
cov_full_to_empty:   cover property ( vc_full  ##[1:$] vc_empty);

//Note that if the constraints which prevent each location being written to
//more than once are correct then it should be impossible to see rx_cnt or
//tx_cnt exceeding 8.
genvar cnt;
for (cnt=1; cnt<11; cnt++) begin
   cov_tx_cnt: cover property (tx_cnt == cnt);
   cov_rx_cnt: cover property (rx_cnt == cnt);
end

genvar tag_cnt;
  for (tag_cnt=1;tag_cnt<=8;tag_cnt++) cov_fullness: 
        cover property ($countones(used_tag)==tag_cnt);
//-----------------------------------------------------------------------------

endmodule




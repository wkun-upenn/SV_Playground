// © 2018 Cadence Design Systems, Inc. All rights reserved worldwide.
// 
// ----------------------------------------
// 
// This file is being provided as part of a reference example to showcase
// Cadence's JasperGold Formal IP Signoff methodology. They are the proprietary
// and confidential information of Cadence or its licensors, and are supplied
// subject to, and may be used only by Cadence's customer in accordance with a
// previously executed agreements between Cadence and that customer.
// 
// Further, they may only be used with JasperGold and cannot be used with any
// other Formal Verification Tools.
// 
// ALL MATERIALS FURNISHED BY CADENCE HEREUNDER ARE PROVIDED "AS IS" WITHOUT
// WARRANTY OF ANY KIND, AND CADENCE SPECIFICALLY DISCLAIMS ANY WARRANTY OF
// NONINFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE OR MERCHANTABILITY.
// CADENCE SHALL NOT BE LIABLE FOR ANY COSTS OF PROCUREMENT OF SUBSTITUTES,
// LOSS OF PROFITS, INTERRUPTION OF BUSINESS, OR FOR ANY OTHER SPECIAL,
// CONSEQUENTIAL OR INCIDENTAL DAMAGES, HOWEVER CAUSED, WHETHER FOR BREACH OF
// WARRANTY, CONTRACT, TORT, NEGLIGENCE, STRICT LIABILITY OR OTHERWISE.
// 
// ----------------------------------------

`include "pp.vh"

module pp_payload_mem #(
  parameter DATA_W = 8,
  parameter PTR_W = 6
) (
  input bit clk,
  input bit rstn,

  input bit payload_valid,
  input bit payload_sop,
  input bit payload_eop,
  input bit [DATA_W-1:0] payload_data,

  output bit ig_alloc,
  input bit [PTR_W-1:0] ig_alloc_ptr,

  input bit resp_valid,
  input bit [PTR_W-1:0] resp_head,
  input bit [PTR_W-1:0] resp_tail,
  input bit resp_drop,
  input bit resp_thr_empty,
  input bit [PTR_W-1:0] resp_thr_tail,

  input bit eg_start,
  input bit [PTR_W-1:0] eg_start_ptr,

  output bit eg_valid,
  output bit eg_sop,
  output bit eg_eop,
  output bit [DATA_W-1:0] eg_data,
  output bit [PTR_W-1:0] eg_next,

  input bit eg_stall,

  output bit eg_dealloc,
  output bit [PTR_W-1:0] eg_dealloc_ptr,

  input bit drop_empty,
  input bit [PTR_W-1:0] drop_head,
  input bit [PTR_W-1:0] drop_tail,
  output bit [PTR_W-1:0] drop_next,

  input bit cfg_cg_en
);

  typedef struct packed {
    bit [DATA_W-1:0] data;
    bit sop, eop;
    bit [PTR_W-1:0] next;
  } payload_mem_t;

  localparam MEM_W = $bits(payload_mem_t);

  payload_mem_t rd0_data, wr0_data, wr0_mask;
  bit [PTR_W-1:0] rd0_addr, wr0_addr;
  bit rd0, wr0;
  payload_mem_t rd1_data, wr1_data, wr1_mask;
  bit [PTR_W-1:0] rd1_addr, wr1_addr;
  bit rd1, wr1;

  bit hold_valid;
  bit hold_sop;
  bit hold_eop;
  bit [DATA_W-1:0] hold_data;
  bit [PTR_W-1:0] hold_ptr;

  bit resp_valid_q;
  bit resp_drop_q;
  bit [PTR_W-1:0] resp_head_q;
  bit [PTR_W-1:0] resp_tail_q;

  bit eg_go;
  bit eg_hold;
  bit [PTR_W-1:0] eg_hold_ptr;

  bit clk_hold;
  bit clk_hold_en;
  bit clk_resp;
  bit clk_resp_en;
  assign clk_hold_en = payload_valid || hold_valid;
  assign clk_resp_en = resp_valid || resp_valid_q;
  pp_cg cg_hold (clk, rstn, clk_hold_en, cfg_cg_en, clk_hold);
  pp_cg cg_resp (clk, rstn, clk_resp_en, cfg_cg_en, clk_resp);

  always @(posedge clk_hold or negedge rstn) begin
    if (!rstn) begin
      hold_valid <= 1'b0;
    end else begin
      if (payload_valid) begin
        hold_valid <= 1'b1;
        hold_sop <= payload_sop;
        hold_eop <= payload_eop;
        hold_data <= payload_data;
        hold_ptr <= ig_alloc_ptr;
      end else if (hold_valid && hold_eop) begin
        hold_valid <= 1'b0;
      end
    end
  end

  always @(posedge clk_resp or negedge rstn) begin
    if (!rstn) begin
      resp_valid_q <= 1'b0;
    end else begin
      resp_valid_q <= resp_valid;
      resp_drop_q <= resp_drop;
      resp_head_q <= resp_head;
      resp_tail_q <= resp_tail;
    end
  end

  pp_mem_2r2w #(MEM_W, PTR_W) mem (
    .clk(clk),
    .rstn(rstn),
    .wr0(wr0),
    .wr0addr(wr0_addr),
    .wr0data(wr0_data),
    .wr0mask(wr0_mask),
    .rd0(rd0),
    .rd0addr(rd0_addr),
    .rd0data(rd0_data),
    .wr1(wr1),
    .wr1addr(wr1_addr),
    .wr1data(wr1_data),
    .wr1mask(wr1_mask),
    .rd1(rd1),
    .rd1addr(rd1_addr),
    .rd1data(rd1_data),
    .cfg_cg_en(cfg_cg_en)
  );

  assign wr0 = hold_valid && (payload_valid || hold_eop);
  assign wr0_mask = {MEM_W{1'b1}};
  assign wr0_data.data = hold_data;
  assign wr0_data.sop = hold_sop;
  assign wr0_data.eop = hold_eop;
  assign wr0_data.next = hold_eop ? hold_ptr : ig_alloc_ptr;
  assign wr0_addr = hold_ptr;

  assign ig_alloc = payload_valid;

  assign wr1 = resp_valid_q && ((resp_drop_q && ~drop_empty) || (~resp_drop_q && ~resp_thr_empty));
  assign wr1_mask.data = {DATA_W{1'b0}};
  assign wr1_mask.sop = 1'b0;
  assign wr1_mask.eop = 1'b0;
  assign wr1_mask.next = {PTR_W{1'b1}};
  assign wr1_data.data = {DATA_W{1'bx}};
  assign wr1_data.sop = 1'bx;
  assign wr1_data.eop = 1'bx;
  assign wr1_data.next = resp_head_q;
  assign wr1_addr = resp_drop_q ? drop_tail : resp_thr_tail;

  assign rd1 = (resp_valid_q && resp_drop_q) || (~drop_empty && (drop_next != drop_tail));
  assign rd1_addr = (resp_valid_q && resp_drop_q && (drop_empty || (drop_head == drop_tail))) ? resp_head_q : drop_next;
  assign drop_next = rd1_data.next;

  assign rd0 = eg_go && !eg_stall;
  assign rd0_addr = eg_next;

  assign eg_dealloc = rd0;
  assign eg_dealloc_ptr = rd0_addr;

  assign eg_go = (eg_start || eg_hold || (eg_valid && ~eg_eop));

  always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      eg_valid <= 1'b0;
      eg_hold <= 1'b0;
    end else begin
      eg_valid <= rd0;
      if (eg_go && eg_stall) begin
        eg_hold <= 1'b1;
        eg_hold_ptr <= eg_next;
      end else begin
        eg_hold <= 1'b0;
      end
    end
  end

  assign eg_data = rd0_data.data;
  assign eg_sop = rd0_data.sop;
  assign eg_eop = rd0_data.eop;
  assign eg_next =
    eg_start ? eg_start_ptr :
    eg_hold ? eg_hold_ptr :
    rd0_data.next;

endmodule

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

module pp_route_ctrl #(
  parameter DATA_W = 8,
  parameter PTR_W = 6,
  parameter THR_W = 2,
  parameter PROC_FIFO_DEPTH = 4
) (
  input bit clk,
  input bit rstn,

  output bit route_req_valid,
  output bit [3:0] route_req_header_valid,
  output bit [4*DATA_W-1:0] route_req_header,

  input bit route_resp_valid,
  input bit route_resp_drop,
  input bit [THR_W-1:0] route_resp_thr,

  output bit resp_valid,
  output bit [PTR_W-1:0] resp_head,
  output bit [PTR_W-1:0] resp_tail,
  output bit resp_drop,
  output bit [THR_W-1:0] resp_thr,

  output bit eg_assign, 
  output bit [THR_W-1:0] eg_assign_thr,

  input bit header_valid,
  input bit [DATA_W-1:0] header_data,

  input bit payload_valid,
  input bit payload_sop,
  input bit payload_eop,

  input bit ig_alloc,
  input bit [PTR_W-1:0] ig_alloc_ptr,

  input bit checksum_error,
  output bit new_packet,
  
  input bit cfg_checksum_drop,
  input bit cfg_checksum_enable,
  input bit cfg_auto_drop,
  input bit cfg_auto_assign,
  input bit [THR_W-1:0] cfg_auto_assign_thr,
  input bit [2:0] cfg_header_length,
  input bit cfg_cg_en
);

  typedef struct packed {
    bit [PTR_W-1:0] head, tail;
    bit bypass;
    bit bypass_drop;
    bit [THR_W-1:0] bypass_thr;
  } req_t;
  typedef struct packed {
    bit drop;
    bit [THR_W-1:0] thr;
  } resp_t;

  localparam REQ_W = $bits(req_t);
  localparam RESP_W = $bits(resp_t);

  req_t req_fifo_in;
  req_t req_fifo_out;
  bit req_fifo_pop;
  bit req_fifo_push;
  bit req_fifo_empty;
  bit req_fifo_full;

  resp_t resp_fifo_in;
  resp_t resp_fifo_out;
  bit resp_fifo_pop;
  bit resp_fifo_push;
  bit resp_fifo_empty;
  bit resp_fifo_full;

  bit [1:0] header_cnt;

  bit [PTR_W-1:0] head_hold;

  bit clk_pipe;
  bit clk_pipe_en;
`ifdef SEC_BUG3
  assign clk_pipe_en = route_req_valid || header_valid;
`else
  assign clk_pipe_en = route_req_valid || header_valid || (payload_valid && payload_sop);
`endif
  pp_cg cg_pipe (clk, rstn, clk_pipe_en, cfg_cg_en, clk_pipe);

  always @(posedge clk_pipe or negedge rstn) begin
    if (!rstn) begin
      header_cnt <= 2'd0;
    end else begin
      if (route_req_valid) header_cnt <= 2'd0;
      if (header_valid) begin
        header_cnt <= header_cnt + 1'b1;
        route_req_header <= (route_req_header << DATA_W) | header_data;
      end
      if (payload_valid && payload_sop) begin
        head_hold <= ig_alloc_ptr;
      end
    end
  end

  always_comb begin
    req_fifo_in.bypass = 1'b0;
    req_fifo_in.bypass_drop = 1'bx;
    req_fifo_in.bypass_thr = {THR_W{1'bx}};
    if (cfg_auto_assign) begin
      req_fifo_in.bypass = 1'b1;
      req_fifo_in.bypass_drop = 1'b0;
      req_fifo_in.bypass_thr = cfg_auto_assign_thr;
    end
    if (cfg_auto_drop || (cfg_checksum_drop && checksum_error)) begin
      req_fifo_in.bypass = 1'b1;
      req_fifo_in.bypass_drop = 1'b1;
    end
    req_fifo_in.head = (payload_valid && payload_sop) ? ig_alloc_ptr : head_hold;
    req_fifo_in.tail = ig_alloc_ptr;
    req_fifo_push = (payload_valid && payload_eop);
    req_fifo_pop = resp_valid;
    new_packet = payload_valid && payload_eop && !cfg_auto_drop && !(cfg_checksum_drop && checksum_error);
  end

  always_comb begin
    resp_fifo_in.drop = route_resp_drop;
    resp_fifo_in.thr = route_resp_thr;
    resp_fifo_push = route_resp_valid;
    resp_fifo_pop = !resp_fifo_empty && !req_fifo_out.bypass;
  end

  always_comb begin
    resp_valid = 1'b0;
    resp_head = {PTR_W{1'bx}};
    resp_tail = {PTR_W{1'bx}};
    resp_drop = 1'bx;
    resp_thr = {THR_W{1'bx}};
    if (!req_fifo_empty && req_fifo_out.bypass) begin
      resp_valid = 1'b1;
      resp_head = req_fifo_out.head;
      resp_tail = req_fifo_out.tail;
      resp_drop = req_fifo_out.bypass_drop;
      resp_thr = req_fifo_out.bypass_thr;
    end else if (!resp_fifo_empty) begin
      resp_valid = 1'b1;
      resp_head = req_fifo_out.head;
      resp_tail = req_fifo_out.tail;
      resp_drop = resp_fifo_out.drop;
      resp_thr = resp_fifo_out.thr;
    end
  end

  assign eg_assign = resp_valid && !resp_drop;
  assign eg_assign_thr = resp_thr;

  always_comb begin
    route_req_valid = (payload_valid && payload_eop && !req_fifo_in.bypass);
    case (cfg_header_length)
      3'b000: route_req_header_valid = 4'b0000;
      3'b001: route_req_header_valid = 4'b0001;
      3'b010: route_req_header_valid = 4'b0011;
      3'b011: route_req_header_valid = 4'b0111;
      3'b100: route_req_header_valid = 4'b1111;
      default: route_req_header_valid = {4{1'bx}};
    endcase
  end

  pp_fifo #(.DEPTH(PROC_FIFO_DEPTH), .WIDTH(REQ_W)) req_fifo (
    .clk(clk), .rstn(rstn),
    .data_in(req_fifo_in),
    .data_front(req_fifo_out),
    .pop(req_fifo_pop),
    .push(req_fifo_push),
    .empty(req_fifo_empty),
    .full(req_fifo_full),
    .cfg_cg_en(cfg_cg_en)
  );
  pp_fifo #(.DEPTH(PROC_FIFO_DEPTH), .WIDTH(RESP_W)) resp_fifo (
    .clk(clk), .rstn(rstn),
    .data_in(resp_fifo_in),
    .data_front(resp_fifo_out),
    .pop(resp_fifo_pop),
    .push(resp_fifo_push),
    .empty(resp_fifo_empty),
    .full(resp_fifo_full),
    .cfg_cg_en(cfg_cg_en)
  );

endmodule

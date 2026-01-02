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

module pp #(
  parameter DATA_W = 8,
  parameter DATA_MEM_SIZE = 64,
  parameter NUM_THR = 4,
  parameter PROC_FIFO_DEPTH = 4,
  localparam PTR_W = $clog2(DATA_MEM_SIZE),
  localparam THR_W = $clog2(NUM_THR)
) (
  input bit clk, rstn,

  input bit ig_valid,
  input bit [DATA_W-1:0] ig_data,
  input bit ig_sop, ig_eop,
  output bit [PTR_W:0] ig_avail,

  output bit eg_assign,
  output bit [THR_W-1:0] eg_assign_thr,
  input bit eg_req,
  input bit [THR_W-1:0] eg_req_thr,
  output bit eg_valid,
  output bit [DATA_W-1:0] eg_data,
  output bit eg_sop, eg_eop,

  output bit route_req_valid,
  output bit [3:0] route_req_header_valid,
  output bit [4*DATA_W-1:0] route_req_header,

  input bit route_resp_valid,
  input bit route_resp_drop,
  input bit [THR_W-1:0] route_resp_thr,

  input bit PCLK, PRESETn,
  input bit [15:0] PADDR,
  input bit PSEL,
  input bit PENABLE,
  input bit PWRITE,
  input bit [31:0] PWDATA,
  output bit PREADY,
  output bit [31:0] PRDATA,
  output bit PSLVERR,

  output bit intr

);

  bit [PTR_W-1:0] eg_next;
  bit eg_dealloc;
  bit [PTR_W-1:0] eg_dealloc_ptr;
  bit eg_start;
  bit [PTR_W-1:0] eg_start_ptr;
  bit eg_stall;
  bit drop_empty;
  bit [PTR_W-1:0] drop_head;
  bit [PTR_W-1:0] drop_tail;
  bit [PTR_W-1:0] drop_next;
  bit drop_dealloc;
  bit [PTR_W-1:0] drop_dealloc_ptr;
  bit header_valid;
  bit [DATA_W-1:0] header_data;
  bit payload_valid;
  bit payload_sop;
  bit payload_eop;
  bit [DATA_W-1:0] payload_data;
  bit ig_alloc;
  bit [PTR_W-1:0] ig_alloc_ptr;
  bit resp_valid;
  bit [PTR_W-1:0] resp_head;
  bit [PTR_W-1:0] resp_tail;
  bit resp_drop;
  bit [THR_W-1:0] resp_thr;
  bit [PTR_W:0] ptr_avail;
  bit [NUM_THR-1:0][PTR_W:0] thr_packets;
  bit new_packet;
  bit checksum_error;
  bit resp_thr_empty;
  bit [PTR_W-1:0] resp_thr_tail;
  bit list_init_done;
  bit thr_init_done;

  bit cfg_auto_drop;
  bit cfg_auto_assign;
  bit [THR_W-1:0] cfg_auto_assign_thr;
  bit [2:0] cfg_header_length;
  bit cfg_header_filter;
  bit [PTR_W:0] cfg_list_almost_empty_level;
  bit [PTR_W:0] cfg_list_almost_full_level;
  bit [PTR_W:0] cfg_thr_almost_empty_level;
  bit [PTR_W:0] cfg_thr_almost_full_level;
  bit cfg_checksum_enable;
  bit cfg_checksum_filter;
  bit cfg_checksum_drop;
  bit cfg_list_init;
  bit cfg_thr_init;
  bit [31:0] cfg_intr_mask;
  bit [31:0] cfg_intr_clear;
  bit cfg_cg_en;
  bit cfg_updated;

  bit [31:0] intr_status;
  bit [THR_W-1:0] intr_thr_empty_thr;
  bit [THR_W-1:0] intr_thr_almost_empty_thr;
  bit [THR_W-1:0] intr_thr_almost_full_thr;

  pp_ig_parse #(.DATA_W(DATA_W)) ig_parse (
    .clk(clk), .rstn(rstn),
    .ig_valid(ig_valid),
    .ig_sop(ig_sop),
    .ig_eop(ig_eop),
    .ig_data(ig_data),
    .payload_valid(payload_valid),
    .payload_sop(payload_sop),
    .payload_eop(payload_eop),
    .payload_data(payload_data),
    .header_valid(header_valid),
    .header_data(header_data),
    .checksum_error(checksum_error),
    .cfg_header_length(cfg_header_length),
    .cfg_header_filter(cfg_header_filter),
    .cfg_checksum_enable(cfg_checksum_enable),
    .cfg_checksum_filter(cfg_checksum_filter),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_route_ctrl #(.DATA_W(DATA_W), .PTR_W(PTR_W), .PROC_FIFO_DEPTH(PROC_FIFO_DEPTH), .THR_W(THR_W)) route_ctrl (
    .clk(clk), .rstn(rstn),
    .header_valid(header_valid),
    .header_data(header_data),
    .payload_valid(payload_valid),
    .payload_sop(payload_sop),
    .payload_eop(payload_eop),
    .ig_alloc(ig_alloc),
    .ig_alloc_ptr(ig_alloc_ptr),
    .route_req_valid(route_req_valid),
    .route_req_header_valid(route_req_header_valid),
    .route_req_header(route_req_header),
    .route_resp_valid(route_resp_valid),
    .route_resp_drop(route_resp_drop),
    .route_resp_thr(route_resp_thr),
    .resp_valid(resp_valid),
    .resp_drop(resp_drop),
    .resp_head(resp_head),
    .resp_tail(resp_tail),
    .resp_thr(resp_thr),
    .eg_assign(eg_assign),
    .eg_assign_thr(eg_assign_thr),
    .checksum_error(checksum_error),
    .new_packet(new_packet),
    .cfg_header_length(cfg_header_length),
    .cfg_auto_drop(cfg_auto_drop),
    .cfg_auto_assign(cfg_auto_assign),
    .cfg_auto_assign_thr(cfg_auto_assign_thr),
    .cfg_checksum_enable(cfg_checksum_enable),
    .cfg_checksum_drop(cfg_checksum_drop),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_payload_mem #(.DATA_W(DATA_W), .PTR_W(PTR_W)) payload_mem (
    .clk(clk), .rstn(rstn),
    .payload_valid(payload_valid),
    .payload_sop(payload_sop),
    .payload_eop(payload_eop),
    .payload_data(payload_data),
    .ig_alloc(ig_alloc),
    .ig_alloc_ptr(ig_alloc_ptr),
    .resp_valid(resp_valid),
    .resp_drop(resp_drop),
    .resp_head(resp_head),
    .resp_tail(resp_tail),
    .resp_thr_empty(resp_thr_empty),
    .resp_thr_tail(resp_thr_tail),
    .drop_empty(drop_empty),
    .drop_head(drop_head),
    .drop_tail(drop_tail),
    .drop_next(drop_next),
    .eg_start(eg_start),
    .eg_start_ptr(eg_start_ptr),
    .eg_valid(eg_valid),
    .eg_sop(eg_sop),
    .eg_eop(eg_eop),
    .eg_data(eg_data),
    .eg_next(eg_next),
    .eg_stall(eg_stall),
    .eg_dealloc(eg_dealloc),
    .eg_dealloc_ptr(eg_dealloc_ptr),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_thr_mem #(.PTR_W(PTR_W), .THR_W(THR_W), .NUM_THR(NUM_THR)) thr_mem (
    .clk(clk), .rstn(rstn),
    .resp_valid(resp_valid),
    .resp_drop(resp_drop),
    .resp_head(resp_head),
    .resp_tail(resp_tail),
    .resp_thr(resp_thr),
    .resp_thr_empty(resp_thr_empty),
    .resp_thr_tail(resp_thr_tail),
    .eg_req(eg_req),
    .eg_req_thr(eg_req_thr),
    .eg_next(eg_next),
    .eg_start(eg_start),
    .eg_start_ptr(eg_start_ptr),
    .eg_stall(eg_stall),
    .eg_valid(eg_valid),
    .eg_sop(eg_sop),
    .eg_eop(eg_eop),
    .thr_packets(thr_packets),
    .cfg_thr_init(cfg_thr_init),
    .thr_init_done(thr_init_done),
    .cfg_cg_en(cfg_cg_en)
  );


  pp_stall #(.PTR_W(PTR_W), .THR_W(THR_W)) stall (
    .clk(clk), .rstn(rstn),
    .resp_valid(resp_valid),
    .resp_drop(resp_drop),
    .resp_thr(resp_thr),
    .route_resp_valid(route_resp_valid),
    .route_resp_drop(route_resp_drop),
    .route_resp_thr(route_resp_thr),
    .eg_req(eg_req),
    .eg_req_thr(eg_req_thr),
    .eg_valid(eg_valid),
    .eg_eop(eg_eop),
    .eg_stall(eg_stall),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_drop_ctrl #(.PTR_W(PTR_W)) drop_ctrl (
    .clk(clk), .rstn(rstn),
    .resp_valid(resp_valid),
    .resp_drop(resp_drop),
    .resp_head(resp_head),
    .resp_tail(resp_tail),
    .drop_empty(drop_empty),
    .drop_head(drop_head),
    .drop_tail(drop_tail),
    .drop_next(drop_next),
    .drop_dealloc(drop_dealloc),
    .drop_dealloc_ptr(drop_dealloc_ptr),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_list_ctrl #(.PTR_W(PTR_W)) list_ctrl (
    .clk(clk), .rstn(rstn),
    .ig_alloc(ig_alloc),
    .ig_alloc_ptr(ig_alloc_ptr),
    .eg_dealloc(eg_dealloc),
    .eg_dealloc_ptr(eg_dealloc_ptr),
    .drop_dealloc(drop_dealloc),
    .drop_dealloc_ptr(drop_dealloc_ptr),
    .ig_avail(ig_avail),
    .ptr_avail(ptr_avail),
    .cfg_list_init(cfg_list_init),
    .list_init_done(list_init_done),
    .cfg_cg_en(cfg_cg_en)
  );

  pp_cfg #(.PTR_W(PTR_W), .THR_W(THR_W), .NUM_THR(NUM_THR)) cfg (
    .PCLK(PCLK), .PRESETn(PRESETn),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PREADY(PREADY),
    .PRDATA(PRDATA),
    .PSLVERR(PSLVERR),
    .clk(clk),
    .rstn(rstn),
    .ptr_avail(ptr_avail),
    .thr_packets(thr_packets),
    .list_init_done(list_init_done),
    .thr_init_done(thr_init_done),
    .cfg_auto_drop(cfg_auto_drop),
    .cfg_auto_assign(cfg_auto_assign),
    .cfg_auto_assign_thr(cfg_auto_assign_thr),
    .cfg_header_length(cfg_header_length),
    .cfg_header_filter(cfg_header_filter),
    .cfg_checksum_enable(cfg_checksum_enable),
    .cfg_checksum_filter(cfg_checksum_filter),
    .cfg_checksum_drop(cfg_checksum_drop),
    .cfg_list_almost_empty_level(cfg_list_almost_empty_level),
    .cfg_list_almost_full_level(cfg_list_almost_full_level),
    .cfg_thr_almost_empty_level(cfg_thr_almost_empty_level),
    .cfg_thr_almost_full_level(cfg_thr_almost_full_level),
    .cfg_list_init(cfg_list_init),
    .cfg_thr_init(cfg_thr_init),
    .cfg_intr_mask(cfg_intr_mask),
    .cfg_intr_clear(cfg_intr_clear),
    .intr_status(intr_status),
    .intr_thr_empty_thr(intr_thr_empty_thr),
    .intr_thr_almost_empty_thr(intr_thr_almost_empty_thr),
    .intr_thr_almost_full_thr(intr_thr_almost_full_thr),
    .cfg_cg_en(cfg_cg_en),
    .cfg_updated(cfg_updated)
  );

  pp_intr #(.PTR_W(PTR_W), .THR_W(THR_W), .NUM_THR(NUM_THR)) intr_ctrl (
    .clk(clk), .rstn(rstn),
    .new_packet(new_packet),
    .checksum_error(checksum_error),
    .ptr_avail(ptr_avail),
    .list_init_done(list_init_done),
    .thr_init_done(thr_init_done),
    .thr_packets(thr_packets),
    .cfg_auto_assign(cfg_auto_assign),
    .cfg_auto_assign_thr(cfg_auto_assign_thr),
    .cfg_list_almost_empty_level(cfg_list_almost_empty_level),
    .cfg_list_almost_full_level(cfg_list_almost_full_level),
    .cfg_thr_almost_empty_level(cfg_thr_almost_empty_level),
    .cfg_thr_almost_full_level(cfg_thr_almost_full_level),
    .cfg_intr_mask(cfg_intr_mask),
    .cfg_intr_clear(cfg_intr_clear),
    .intr_status(intr_status),
    .intr_thr_empty_thr(intr_thr_empty_thr),
    .intr_thr_almost_empty_thr(intr_thr_almost_empty_thr),
    .intr_thr_almost_full_thr(intr_thr_almost_full_thr),
    .intr(intr),
    .cfg_cg_en(cfg_cg_en),
    .cfg_updated(cfg_updated)
  );

endmodule

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

module pp_stall #(
  parameter PTR_W = 6,
  parameter THR_W = 2
) (
  input bit clk,
  input bit rstn,

  input bit route_resp_valid,
  input bit route_resp_drop,
  input bit [THR_W-1:0] route_resp_thr,

  input bit resp_valid,
  input bit resp_drop,
  input bit [THR_W-1:0] resp_thr,

  input bit eg_req,
  input bit [THR_W-1:0] eg_req_thr,
  input bit eg_valid,
  input bit eg_eop,

  output bit eg_stall,

  input bit cfg_cg_en
);

  bit route_resp_valid_q;
  bit route_resp_valid_qq;
  bit [THR_W-1:0] route_resp_thr_q;
  bit [THR_W-1:0] route_resp_thr_qq;

  bit resp_valid_q;
  bit resp_valid_qq;
  bit [THR_W-1:0] resp_thr_q;
  bit [THR_W-1:0] resp_thr_qq;

  bit eg_req_q;
  bit [THR_W-1:0] eg_req_thr_q;
  bit eg_req_qual;
  bit [THR_W-1:0] eg_req_thr_qual;

  bit clk_route_resp;
  bit clk_route_resp_en;
  bit clk_resp;
  bit clk_resp_en;
  bit clk_eg;
  bit clk_eg_en;
  assign clk_route_resp_en = (route_resp_valid || route_resp_valid_q || route_resp_valid_qq);
  assign clk_resp_en = (resp_valid || resp_valid_q || resp_valid_qq);
  assign clk_eg_en = (eg_req || eg_req_q);
  pp_cg cg_route_resp_pipe (clk, rstn, clk_route_resp_en, cfg_cg_en, clk_route_resp);
  pp_cg cg_resp_pipe (clk, rstn, clk_resp_en, cfg_cg_en, clk_resp);
  pp_cg cg_eg_pipe (clk, rstn, clk_eg_en, cfg_cg_en, clk_eg);

  always @(posedge clk_resp or negedge rstn) begin
    if (!rstn) begin
      resp_valid_q <= 1'b0;
      resp_valid_qq <= 1'b0;
    end else begin
      resp_valid_q <= resp_valid && !resp_drop;
      resp_valid_qq <= resp_valid_q;
      resp_thr_q <= resp_thr;
      resp_thr_qq <= resp_thr_q;
    end
  end

  always @(posedge clk_route_resp or negedge rstn) begin
    if (!rstn) begin
      route_resp_valid_q <= 1'b0;
      route_resp_valid_qq <= 1'b0;
    end else begin
      route_resp_valid_q <= route_resp_valid && !route_resp_drop;
      route_resp_valid_qq <= route_resp_valid_q;
      route_resp_thr_q <= route_resp_thr;
      route_resp_thr_qq <= route_resp_thr_q;
    end
  end

  always @(posedge clk_eg or negedge rstn) begin
    if (!rstn) begin
      eg_req_q <= 1'b0;
    end else begin
      if (eg_req) eg_req_q <= 1'b1;
      if (eg_valid && eg_eop) eg_req_q <= 1'b0;
      if (eg_req) eg_req_thr_q <= eg_req_thr;
    end
  end

  assign eg_req_qual = eg_req || eg_req_q;
  assign eg_req_thr_qual = eg_req ? eg_req_thr : eg_req_thr_q;

  assign eg_stall =
    (eg_req_qual && route_resp_valid && eg_req_thr_qual == route_resp_thr && !route_resp_drop) ||
    (eg_req_qual && route_resp_valid_q && eg_req_thr_qual == route_resp_thr_q) ||
    (eg_req_qual && route_resp_valid_qq && eg_req_thr_qual == route_resp_thr_qq) ||
    (eg_req_qual && resp_valid && eg_req_thr_qual == resp_thr && !resp_drop) ||
    (eg_req_qual && resp_valid_q && eg_req_thr_qual == resp_thr_q) ||
    (eg_req_qual && resp_valid_qq && eg_req_thr_qual == resp_thr_qq);

endmodule

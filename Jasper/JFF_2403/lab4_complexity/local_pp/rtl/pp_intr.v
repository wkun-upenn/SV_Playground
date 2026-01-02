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

module pp_intr #(
  parameter PTR_W = 6,
  parameter NUM_THR = 4,
  parameter THR_W = 2
) (
  input bit clk,
  input bit rstn,

  input bit [PTR_W:0] ptr_avail,
  input bit [NUM_THR-1:0][PTR_W:0] thr_packets,
  input bit checksum_error,
  input bit new_packet,
  input bit list_init_done,
  input bit thr_init_done,

  input bit [PTR_W:0] cfg_list_almost_empty_level,
  input bit [PTR_W:0] cfg_list_almost_full_level,
  input bit [PTR_W:0] cfg_thr_almost_empty_level,
  input bit [PTR_W:0] cfg_thr_almost_full_level,

  input bit cfg_auto_assign,
  input bit [THR_W-1:0] cfg_auto_assign_thr,

  input bit [31:0] cfg_intr_mask,
  input bit [31:0] cfg_intr_clear,
  output bit [31:0] intr_status,
  output bit [THR_W-1:0] intr_thr_empty_thr,
  output bit [THR_W-1:0] intr_thr_almost_empty_thr,
  output bit [THR_W-1:0] intr_thr_almost_full_thr,

  output bit intr,

  input bit cfg_cg_en,
  input bit cfg_updated
);

  bit ptr_avail_toggle;
  bit [1:0] ptr_avail_q;
  bit thr_packets_toggle;
  bit [NUM_THR-1:0] thr_packets_q;
  bit list_init_done_toggle;
  bit list_init_done_q;
  bit thr_init_done_toggle;
  bit thr_init_done_q;
  bit [1:0] reset_pipe;

  bit clk_intr;
  bit clk_intr_en;
`ifdef SEC_NO_INTR_CG
  assign clk_intr_en = 1'b1
`else
  assign clk_intr_en = list_init_done_toggle || thr_init_done_toggle || new_packet || checksum_error || ptr_avail_toggle || thr_packets_toggle || cfg_intr_clear || cfg_updated || |reset_pipe;
`endif
  pp_cg cg_pipe (clk, rstn, clk_intr_en, cfg_cg_en, clk_intr);

  always @(posedge clk) begin
    reset_pipe <= {reset_pipe[0],~rstn};
    ptr_avail_q <= ptr_avail[1:0];
    for (int i = 0; i < NUM_THR; i++) begin
      thr_packets_q[i] <= thr_packets[i][0];
    end
    list_init_done_q <= list_init_done;
    thr_init_done_q <= thr_init_done;
  end
  always_comb begin
    ptr_avail_toggle = (ptr_avail_q != ptr_avail[1:0]);
    thr_packets_toggle = 1'b0;
    for (int i = 0; i < NUM_THR; i++) begin
      thr_packets_toggle = thr_packets_toggle | (thr_packets_q[i] ^ thr_packets[i][0]);
    end
    list_init_done_toggle = (list_init_done_q != list_init_done);
    thr_init_done_toggle = (thr_init_done_q != thr_init_done);
  end

  always @(posedge clk_intr or negedge rstn) begin
    if (~rstn) begin
      intr_status <= 32'h0;
    end else begin
      intr_status <= intr_status & ~cfg_intr_clear;
      intr_thr_empty_thr <= {THR_W{1'b0}};
      intr_thr_almost_empty_thr <= {THR_W{1'b0}};
      intr_thr_almost_full_thr <= {THR_W{1'b0}};
      if (~list_init_done_q && list_init_done) intr_status[`PP_CFG_INTR_LIST_INIT_DONE] <= 1'b1;
      if (ptr_avail == 0) intr_status[`PP_CFG_INTR_LIST_EMPTY] <= 1'b1;
      if (ptr_avail <= cfg_list_almost_empty_level) intr_status[`PP_CFG_INTR_LIST_ALMOST_EMPTY] <= 1'b1;
      if (ptr_avail >= cfg_list_almost_full_level) intr_status[`PP_CFG_INTR_LIST_ALMOST_FULL] <= 1'b1;
      if (ptr_avail == {1'b1,{PTR_W{1'b0}}}) intr_status[`PP_CFG_INTR_LIST_FULL] <= 1'b1;
      if (~thr_init_done_q && thr_init_done) intr_status[`PP_CFG_INTR_THR_INIT_DONE] <= 1'b1;
      for (int i = 0; i < NUM_THR; i++) begin
        if ((!cfg_auto_assign || (cfg_auto_assign && i == cfg_auto_assign_thr)) && thr_packets[i] == 0) begin
          intr_status[`PP_CFG_INTR_THR_EMPTY] <= 1'b1;
          intr_thr_empty_thr <= i;
        end
        if ((!cfg_auto_assign || (cfg_auto_assign && i == cfg_auto_assign_thr)) && thr_packets[i] <= cfg_thr_almost_empty_level) begin
          intr_status[`PP_CFG_INTR_THR_ALMOST_EMPTY] <= 1'b1;
          intr_thr_almost_empty_thr <= i;
        end
        if ((!cfg_auto_assign || (cfg_auto_assign && i == cfg_auto_assign_thr)) && thr_packets[i] >= cfg_thr_almost_full_level) begin
          intr_status[`PP_CFG_INTR_THR_ALMOST_FULL] <= 1'b1;
          intr_thr_almost_full_thr <= i;
        end
      end
      if (new_packet) intr_status[`PP_CFG_INTR_NEW_PACKET] <= 1'b1;
      if (checksum_error) intr_status[`PP_CFG_INTR_CHECKSUM_ERROR] <= 1'b1;
    end
  end

  assign intr = |(intr_status & cfg_intr_mask);

endmodule

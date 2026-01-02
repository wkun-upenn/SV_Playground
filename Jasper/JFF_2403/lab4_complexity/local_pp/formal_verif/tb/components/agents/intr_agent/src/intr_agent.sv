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

`include "fv_defines.svh"
`include "pp.vh"

module intr_agent #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  intr_port_intf.monitor intr_port,
  intr_txn_intf.driver intr_txn,
  packet_txn_intf.monitor ig_packet_txn,
  route_port_intf.monitor route_port,
  fl_probe_intf.monitor fl_probe,
  level_trk_intf.monitor level_trk,
  cfg_probe_intf.monitor cfg_probe,
  apb_txn_intf.monitor apb_txn
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  bit [8:0] cfg_list_almost_empty_level_stable;
  bit [8:0] cfg_list_almost_full_level_stable;
  bit [8:0] cfg_thr_almost_empty_level_stable;
  bit [8:0] cfg_thr_almost_full_level_stable;
  bit list_init_done_q;
  bit thr_init_done_q;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cfg_list_almost_empty_level_stable <= 9'b0;
      cfg_list_almost_full_level_stable <= 9'b0;
      cfg_thr_almost_empty_level_stable <= 9'b0;
      cfg_thr_almost_full_level_stable <= 9'b0;
      list_init_done_q <= 1'b0;
      thr_init_done_q <= 1'b0;
    end else begin
      cfg_list_almost_empty_level_stable <= {cfg_list_almost_empty_level_stable[7:0],$stable(cfg_probe.cfg_list_almost_empty_level)};
      cfg_list_almost_full_level_stable <= {cfg_list_almost_full_level_stable[7:0],$stable(cfg_probe.cfg_list_almost_full_level)};
      cfg_thr_almost_empty_level_stable <= {cfg_thr_almost_empty_level_stable[7:0],$stable(cfg_probe.cfg_thr_almost_empty_level)};
      cfg_thr_almost_full_level_stable <= {cfg_thr_almost_full_level_stable[7:0],$stable(cfg_probe.cfg_thr_almost_full_level)};
      list_init_done_q <= cfg_probe.list_init_done;
      thr_init_done_q <= cfg_probe.thr_init_done;
    end
  end

  bit [31:0] intr_trigger;
  bit [NUM_THR-1:0] thr_empty, thr_almost_empty, thr_almost_full;
  assign intr_trigger[`PP_CFG_INTR_LIST_INIT_DONE] = ~list_init_done_q && cfg_probe.list_init_done;
  assign intr_trigger[`PP_CFG_INTR_THR_INIT_DONE] = ~thr_init_done_q && cfg_probe.thr_init_done;
  assign intr_trigger[`PP_CFG_INTR_LIST_EMPTY] = (fl_probe.ptr_avail == 0);
  assign intr_trigger[`PP_CFG_INTR_LIST_ALMOST_EMPTY] = (fl_probe.ptr_avail <= cfg_probe.cfg_list_almost_empty_level);
  assign intr_trigger[`PP_CFG_INTR_LIST_ALMOST_FULL] = (fl_probe.ptr_avail >= cfg_probe.cfg_list_almost_full_level);
  assign intr_trigger[`PP_CFG_INTR_LIST_FULL] = (fl_probe.ptr_avail == DATA_MEM_SIZE);
  always_comb begin
    intr_trigger[`PP_CFG_INTR_THR_EMPTY] = 1'b0;
    intr_trigger[`PP_CFG_INTR_THR_ALMOST_EMPTY] = 1'b0;
    intr_trigger[`PP_CFG_INTR_THR_ALMOST_FULL] = 1'b0;
    thr_empty = 0;
    thr_almost_empty = 0;
    thr_almost_full = 0;
    if (cfg_probe.cfg_auto_assign) begin
      if (level_trk.thr_pkts[cfg_probe.cfg_auto_assign_thr] == 0) begin
        thr_empty[cfg_probe.cfg_auto_assign_thr] = 1'b1;
        intr_trigger[`PP_CFG_INTR_THR_EMPTY] = 1'b1;
      end
      if (level_trk.thr_pkts[cfg_probe.cfg_auto_assign_thr] <= cfg_probe.cfg_thr_almost_empty_level) begin
        thr_almost_empty[cfg_probe.cfg_auto_assign_thr] = 1'b1;
        intr_trigger[`PP_CFG_INTR_THR_ALMOST_EMPTY] = 1'b1;
      end
      if (level_trk.thr_pkts[cfg_probe.cfg_auto_assign_thr] >= cfg_probe.cfg_thr_almost_full_level) begin
        thr_almost_full[cfg_probe.cfg_auto_assign_thr] = 1'b1;
        intr_trigger[`PP_CFG_INTR_THR_ALMOST_FULL] = 1'b1;
      end
    end else begin
      for (int i = 0; i < NUM_THR; i++) begin
        if (level_trk.thr_pkts[i] == 0) begin
          thr_empty[i] = 1'b1;
          intr_trigger[`PP_CFG_INTR_THR_EMPTY] = 1'b1;
        end
        if (level_trk.thr_pkts[i] <= cfg_probe.cfg_thr_almost_empty_level) begin
          thr_almost_empty[i] = 1'b1;
          intr_trigger[`PP_CFG_INTR_THR_ALMOST_EMPTY] = 1'b1;
        end
        if (level_trk.thr_pkts[i] >= cfg_probe.cfg_thr_almost_full_level) begin
          thr_almost_full[i] = 1'b1;
          intr_trigger[`PP_CFG_INTR_THR_ALMOST_FULL] = 1'b1;
        end
      end
    end
  end
  assign intr_trigger[`PP_CFG_INTR_NEW_PACKET] = ig_packet_txn.valid && !ig_packet_txn.auto_drop;
  assign intr_trigger[`PP_CFG_INTR_CHECKSUM_ERROR] = ig_packet_txn.valid && ig_packet_txn.has_checksum && !ig_packet_txn.checksum_ok;

  // Asserts

  intr_check      intr_list_init_done (clk, rstn, intr_trigger[`PP_CFG_INTR_LIST_INIT_DONE], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_LIST_INIT_DONE], cfg_probe.intr_status[`PP_CFG_INTR_LIST_INIT_DONE], 1'b0);
  intr_check      intr_thr_init_done (clk, rstn, intr_trigger[`PP_CFG_INTR_THR_INIT_DONE], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_THR_INIT_DONE], cfg_probe.intr_status[`PP_CFG_INTR_THR_INIT_DONE], 1'b0);
  intr_check #(0) intr_list_empty (clk, rstn, intr_trigger[`PP_CFG_INTR_LIST_EMPTY], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_LIST_EMPTY], cfg_probe.intr_status[`PP_CFG_INTR_LIST_EMPTY], 1'b0);
  intr_check #(0) intr_list_almost_empty (clk, rstn, intr_trigger[`PP_CFG_INTR_LIST_ALMOST_EMPTY], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_LIST_ALMOST_EMPTY], cfg_probe.intr_status[`PP_CFG_INTR_LIST_ALMOST_EMPTY], ~&cfg_list_almost_empty_level_stable);
  intr_check #(0) intr_list_almost_full (clk, rstn, intr_trigger[`PP_CFG_INTR_LIST_ALMOST_FULL], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_LIST_ALMOST_FULL], cfg_probe.intr_status[`PP_CFG_INTR_LIST_ALMOST_FULL], ~&cfg_list_almost_full_level_stable);
  intr_check #(0) intr_list_full (clk, rstn, intr_trigger[`PP_CFG_INTR_LIST_FULL], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_LIST_FULL], cfg_probe.intr_status[`PP_CFG_INTR_LIST_FULL], 1'b0);
  intr_check #(0) intr_thr_empty (clk, rstn, intr_trigger[`PP_CFG_INTR_THR_EMPTY], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_THR_EMPTY], cfg_probe.intr_status[`PP_CFG_INTR_THR_EMPTY], 1'b0);
  intr_check #(0) intr_thr_almost_empty (clk, rstn, intr_trigger[`PP_CFG_INTR_THR_ALMOST_EMPTY], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_THR_ALMOST_EMPTY], cfg_probe.intr_status[`PP_CFG_INTR_THR_ALMOST_EMPTY], ~&cfg_thr_almost_empty_level_stable || cfg_probe.cfg_auto_assign);
  intr_check #(0) intr_thr_almost_full (clk, rstn, intr_trigger[`PP_CFG_INTR_THR_ALMOST_FULL], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_THR_ALMOST_FULL], cfg_probe.intr_status[`PP_CFG_INTR_THR_ALMOST_FULL], ~&cfg_thr_almost_full_level_stable || cfg_probe.cfg_auto_assign);
  intr_check      intr_new_packet (clk, rstn, intr_trigger[`PP_CFG_INTR_NEW_PACKET], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_NEW_PACKET], cfg_probe.intr_status[`PP_CFG_INTR_NEW_PACKET], 1'b0);
  intr_check      intr_checksum_error (clk, rstn, intr_trigger[`PP_CFG_INTR_CHECKSUM_ERROR], cfg_probe.cfg_intr_clear[`PP_CFG_INTR_CHECKSUM_ERROR], cfg_probe.intr_status[`PP_CFG_INTR_CHECKSUM_ERROR], 1'b0);

  AST_interrupt: assert property (intr_port.intr == |(cfg_probe.intr_status & cfg_probe.cfg_intr_mask));

  assign intr_txn.list_init_done = cfg_probe.intr_status[`PP_CFG_INTR_LIST_INIT_DONE];
  assign intr_txn.list_empty = cfg_probe.intr_status[`PP_CFG_INTR_LIST_EMPTY];
  assign intr_txn.list_almost_empty = cfg_probe.intr_status[`PP_CFG_INTR_LIST_ALMOST_EMPTY];
  assign intr_txn.list_almost_full = cfg_probe.intr_status[`PP_CFG_INTR_LIST_ALMOST_FULL];
  assign intr_txn.list_full = cfg_probe.intr_status[`PP_CFG_INTR_LIST_FULL];
  assign intr_txn.thr_init_done = cfg_probe.intr_status[`PP_CFG_INTR_THR_INIT_DONE];
  assign intr_txn.thr_empty = cfg_probe.intr_status[`PP_CFG_INTR_THR_EMPTY];
  assign intr_txn.thr_almost_empty = cfg_probe.intr_status[`PP_CFG_INTR_THR_ALMOST_EMPTY];
  assign intr_txn.thr_almost_full = cfg_probe.intr_status[`PP_CFG_INTR_THR_ALMOST_FULL];
  assign intr_txn.new_packet = cfg_probe.intr_status[`PP_CFG_INTR_NEW_PACKET];
  assign intr_txn.checksum_error = cfg_probe.intr_status[`PP_CFG_INTR_CHECKSUM_ERROR];

endmodule





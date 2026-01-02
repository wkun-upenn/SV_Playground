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

module level_chk #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  packet_txn_intf.monitor ig_packet_txn,
  packet_txn_intf.monitor eg_packet_txn,
  eg_port_intf.monitor eg_port, // needed for eg_assign
  route_port_intf.monitor route_port,
  resp_txn_intf.monitor resp_txn, // needed for pending
  fl_probe_intf.monitor fl_probe,
  cfg_probe_intf.monitor cfg_probe,
  level_trk_intf.driver level_trk
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  struct packed {
    bit [PTR_W:0] total_pkts;
    bit [PTR_W:0] pending_pkts;
    bit [PTR_W:0] assigned_pkts;
    bit [NUM_THR-1:0][PTR_W:0] thr_pkts;
    bit eg_pkts;
  } level_q, level_nx;

/*
  bit resp_valid_q, resp_valid_qq;
  bit resp_drop_q, resp_drop_qq;
  bit [THR_W-1:0] resp_thr_q, resp_thr_qq;
  bit eg_packet_valid_q, eg_packet_valid_qq;
  bit [THR_W-1:0] eg_packet_thr_q, eg_packet_thr_qq;
  bit eg_assign_q, eg_assign_qq;
  bit [THR_W-1:0] eg_assign_thr_q, eg_assign_thr_qq;
*/

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      level_q.total_pkts <= 0;
      level_q.pending_pkts <= 0;
      level_q.assigned_pkts <= 0;
      level_q.eg_pkts <= 1'b0;
      for (int i=0; i<NUM_THR; i++) level_q.thr_pkts[i] <= 0;
    end else begin
      level_q <= level_nx;
    end
  end

  always_comb begin
    level_nx = level_q;
    if (ig_packet_txn.valid && !ig_packet_txn.auto_drop) begin
      level_nx.total_pkts++;
      level_nx.pending_pkts++;
    end
    if (route_port.resp_valid && route_port.resp_drop) begin
      level_nx.pending_pkts--;
      level_nx.total_pkts--;
    end
    if (eg_port.assign_) begin
      level_nx.pending_pkts--;
      level_nx.thr_pkts[eg_port.assign_thr]++;
    end
    if (eg_port.req) begin
      level_nx.thr_pkts[eg_port.req_thr]--;
      level_nx.eg_pkts = 1'b1;
    end
    if (eg_packet_txn.valid) begin
      level_nx.total_pkts--;
      level_nx.eg_pkts = 1'b0;
    end
    level_nx.assigned_pkts = level_nx.total_pkts - level_nx.pending_pkts - level_nx.eg_pkts;
  end

  assign level_trk.total_pkts = level_q.total_pkts;
  assign level_trk.pending_pkts = level_q.pending_pkts;
  assign level_trk.assigned_pkts = level_q.assigned_pkts;
  assign level_trk.eg_pkts = level_q.eg_pkts;
  assign level_trk.thr_pkts = level_q.thr_pkts;
  for (genvar g = 0; g < NUM_THR; g++) begin: GEN_THR_EMPTY
    assign level_trk.thr_empty[g] = (level_trk.thr_pkts[g] == 0);
  end

  bit idle;
  assign idle = (level_trk.total_pkts == 0) && !ig_port.valid && !fl_probe.drop_dealloc && (resp_txn.pending == 0);
  assign level_trk.idle = idle;

  // Asserts
  AST_idle_ig_avail: assert property (cfg_probe.list_init_done && idle [*6] |-> ig_port.avail == DATA_MEM_SIZE);
  AST_idle_ptr_avail: assert property (cfg_probe.list_init_done && idle [*6] |-> fl_probe.ptr_avail == DATA_MEM_SIZE);

endmodule

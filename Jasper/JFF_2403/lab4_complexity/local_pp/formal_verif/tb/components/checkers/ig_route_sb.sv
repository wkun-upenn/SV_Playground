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

module ig_route_sb #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  header_txn_intf.monitor ig_header_txn,
  header_txn_intf.monitor route_header_txn,
  cfg_probe_intf.monitor cfg_probe
);

  localparam HEADER_W = 4*DATA_W;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  bit [HEADER_W-1:0] ig_header_mask;
  bit [HEADER_W-1:0] route_header_mask;
  bit [3:0] incoming_vld_header_valid;
  bit [HEADER_W-1:0] incoming_vld_header;
  bit [3:0] outgoing_vld_header_valid;
  bit [HEADER_W-1:0] outgoing_vld_header;
  bit ig_checksum_ok;
  bit ig_no_req;

  assign ig_checksum_ok = `GET_CHECKSUM_TAG(ig_header_txn.header);
  assign ig_no_req =
    cfg_probe.cfg_auto_drop ||
    cfg_probe.cfg_auto_assign ||
    (!ig_checksum_ok && cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_drop);

  always_comb begin
    for (int i=0; i<4; i++) begin
      ig_header_mask[DATA_W*i +: DATA_W] = {DATA_W{ig_header_txn.header_valid[i]}};
      route_header_mask[DATA_W*i +: DATA_W] = {DATA_W{route_header_txn.header_valid[i]}};
    end
  end

  jasper_scoreboard_3 #(
    .CHUNK_WIDTH(4+HEADER_W),
    .MAX_PENDING(2),
    .LATENCY_CHECK(1),
    .DYNAMIC(DYNAMIC_SCB)
  ) sb (
    .clk, .rstN(rstn),
    .incoming_vld(ig_header_txn.valid && !ig_no_req),
    .incoming_data({ig_header_txn.header_valid,ig_header_txn.header} & {4'b1111,ig_header_mask}),
    .outgoing_vld(route_header_txn.valid),
    .outgoing_data({route_header_txn.header_valid,route_header_txn.header} & {4'b1111,route_header_mask})
  );

endmodule







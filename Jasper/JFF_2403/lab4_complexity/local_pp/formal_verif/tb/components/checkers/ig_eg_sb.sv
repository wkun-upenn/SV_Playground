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

module ig_eg_sb #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  payload_txn_intf.monitor ig_payload_txn,
  payload_txn_intf.monitor eg_payload_txn,
  cfg_probe_intf.monitor cfg_probe
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  for (genvar t=0; t<NUM_THR; t++) begin: THR_SB

    jasper_scoreboard_3 #(
      .CHUNK_WIDTH(DATA_W+1),
      .MAX_PENDING(DATA_MEM_SIZE+1),
      .DYNAMIC(DYNAMIC_SCB)
    ) sb (
      .clk, .rstN(rstn),
      .incoming_vld(ig_payload_txn.valid && ig_payload_txn.tag_thr==t && !ig_payload_txn.tag_drop),
      .incoming_data({ig_payload_txn.last,ig_payload_txn.payload}),
      .outgoing_vld(eg_payload_txn.valid && eg_payload_txn.thr==t),
      .outgoing_data({eg_payload_txn.last,eg_payload_txn.payload})
    );

  end

endmodule

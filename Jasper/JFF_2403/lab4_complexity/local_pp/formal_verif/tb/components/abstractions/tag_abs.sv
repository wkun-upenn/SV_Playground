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

module tag_abs #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  ig_port_intf.monitor ig_port,
  route_port_intf.monitor route_port,
  cfg_probe_intf.monitor cfg_probe
);

  localparam FIFO_WIDTH = 1+THR_W;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  bit ig_drop;
  bit ig_checksum_ok;
  bit [THR_W-1:0] ig_thr;
  bit ig_no_req;
  bit ig_is_checksum;
  bit tag_drop;
  bit tag_checksum_ok;
  bit [THR_W-1:0] tag_thr;
  bit [DATA_W-1:0] checksum, checksum_q;
  bit checksum_ok;

  assign ig_drop = `GET_DROP_TAG(ig_port.data);
  assign ig_checksum_ok = `GET_CHECKSUM_TAG(ig_port.data);
  assign ig_thr = `GET_THR_TAG(ig_port.data);
  assign ig_no_req =
    cfg_probe.cfg_auto_drop ||
    cfg_probe.cfg_auto_assign ||
    (!ig_checksum_ok && cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_drop);
  assign ig_is_checksum = ig_port.valid && ig_port.eop && cfg_probe.cfg_checksum_enable;

  always @(posedge clk) begin
    if (ig_port.valid && ig_port.sop) begin
      tag_drop <= ig_drop;
      tag_checksum_ok <= ig_checksum_ok;
      tag_thr <= ig_thr;
    end
    checksum_q <= checksum;
  end

  always_comb begin
    checksum = checksum_q;
    if (ig_port.valid) begin
      if (ig_port.sop) checksum = ig_port.data;
      else checksum = (checksum ^ ig_port.data);
    end
    checksum_ok = (checksum == 0);
  end

  bit fifo_full, fifo_empty;
  bit fifo_out_drop;
  bit [THR_W-1:0] fifo_out_thr;

  jasper_fifo #(.WIDTH(FIFO_WIDTH), .DEPTH(PROC_FIFO_DEPTH), .ASSUME_NO_OVERFLOW(1), .ASSERT_NO_UNDERFLOW(1)) tag_fifo (
    .clk, .rstN(rstn),
    .data_in({ig_drop,ig_thr}),
    .push(ig_port.valid && ig_port.sop && !ig_no_req),
    .data_front({fifo_out_drop,fifo_out_thr}),
    .pop(route_port.resp_valid),
    .empty(fifo_empty)
  );

  ASM_TAG_checksum_drop: assume property (ig_port.valid && ig_port.sop && !ig_checksum_ok && cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_drop |-> ig_drop);
  ASM_TAG_auto_drop: assume property (ig_port.valid && ig_port.sop && cfg_probe.cfg_auto_drop |-> ig_drop);
  ASM_TAG_auto_assign: assume property (ig_port.valid && ig_port.sop && (!cfg_probe.cfg_checksum_enable || !cfg_probe.cfg_checksum_drop || ig_checksum_ok) && !cfg_probe.cfg_auto_drop && cfg_probe.cfg_auto_assign |-> !ig_drop && ig_thr == cfg_probe.cfg_auto_assign_thr);
  ASM_TAG_hold: assume property (ig_port.valid && !ig_port.sop && !ig_is_checksum |-> ig_drop == tag_drop && ig_thr == tag_thr && ig_checksum_ok == tag_checksum_ok);
  ASM_TAG_checksum: assume property (ig_port.valid && ig_is_checksum |-> checksum_ok == tag_checksum_ok);

  ASM_TAG_resp: assume property (route_port.resp_valid |-> route_port.resp_drop == fifo_out_drop && route_port.resp_thr == fifo_out_thr);

endmodule

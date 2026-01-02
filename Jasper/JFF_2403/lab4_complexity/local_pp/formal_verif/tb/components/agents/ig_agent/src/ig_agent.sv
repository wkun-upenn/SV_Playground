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

module ig_agent #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  ig_port_intf.monitor ig_port,
  payload_txn_intf.driver ig_payload_txn,
  header_txn_intf.driver ig_header_txn,
  packet_txn_intf.driver ig_packet_txn,
  cfg_probe_intf.monitor cfg_probe
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  bit [`PKT_LEN_W:0] beat_count, beat_count_q;
  bit transfer;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      beat_count <= 0;
      transfer <= 1'b0;
    end else begin
      if (ig_port.valid) begin
        if (ig_port.eop) begin
          beat_count <= 0;
        end else if (~&beat_count) begin
          beat_count <= (beat_count + 1'b1);
        end
        if (ig_port.sop) transfer <= 1'b1;
        if (ig_port.eop) transfer <= 1'b0;
      end
    end
  end

  bit payload_valid, payload_valid_q;
  bit [DATA_W-1:0] payload, payload_q;
  bit payload_eop, payload_eop_q;
  bit [3:0] header_valid, header_valid_q;
  bit [4*DATA_W-1:0] header, header_q;
  bit [DATA_W-1:0] checksum, checksum_q;
  bit checksum_ok, checksum_ok_q;
  bit [PTR_W:0] avail_init, avail_init_q;
  bit [`PKT_LEN_W:0] min_length;
  bit [THR_W-1:0] ig_thr_tag, ig_thr_tag_q;
  bit ig_drop_tag, ig_drop_tag_q;
  bit ig_checksum_tag, ig_checksum_tag_q;

  always_comb begin
    header_valid = header_valid_q;
    header = header_q;
    avail_init = avail_init_q;
    if (ig_port.valid) begin
      if (ig_port.sop) begin
        header_valid = 0;
        header = 0;
        avail_init = ig_port.avail;
      end
      if (beat_count < cfg_probe.cfg_header_length) begin
        header_valid = (header_valid << 1) | 1'b1;
        header = (header << DATA_W) | ig_port.data;
      end
    end
  end
  always_comb begin
    payload_valid = (
      ig_port.valid &&
      (
        (beat_count >= cfg_probe.cfg_header_length && !ig_port.eop) ||
        (ig_port.eop && (!cfg_probe.cfg_checksum_filter || !cfg_probe.cfg_checksum_enable))
      )
    );
    payload = ig_port.data;
    payload_eop = ig_port.eop;
  end
  always_comb begin
    checksum = checksum_q;
    if (ig_port.valid) begin
      if (ig_port.sop) checksum = ig_port.data;
      else checksum = (checksum ^ ig_port.data);
    end
    checksum_ok = (checksum == 0);
  end

  assign min_length = ({`PKT_LEN_W+1{1'b0}} + (cfg_probe.cfg_header_filter ? 1'b0 : cfg_probe.cfg_header_length) + cfg_probe.cfg_checksum_enable + 1'b1);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      payload_valid_q <= 1'b0;
      payload_q <= 0;
      payload_eop_q <= 1'b0;
      checksum_q <= 0;
      checksum_ok_q <= 1'b0;
      header_valid_q <= 0;
      header_q <= 0;
      avail_init_q <= 0;
      beat_count_q <= 0;
    end else begin
      payload_valid_q <= payload_valid;
      payload_q <= payload;
      payload_eop_q <= payload_eop;
      checksum_q <= checksum;
      checksum_ok_q <= checksum_ok;
      header_valid_q <= header_valid;
      header_q <= header;
      avail_init_q <= avail_init;
      beat_count_q <= beat_count;
    end
  end

  always @(posedge clk) begin
    if (ig_port.valid && ig_port.sop) {ig_checksum_tag_q,ig_thr_tag_q,ig_drop_tag_q} <= {ig_checksum_tag,ig_thr_tag,ig_drop_tag};
  end
  assign ig_thr_tag = (ig_port.valid && ig_port.sop) ? `GET_THR_TAG(ig_port.data) : ig_thr_tag_q;
  assign ig_drop_tag = (ig_port.valid && ig_port.sop) ? `GET_DROP_TAG(ig_port.data) : ig_drop_tag_q;
  assign ig_checksum_tag = (ig_port.valid && ig_port.sop) ? `GET_CHECKSUM_TAG(ig_port.data) : ig_checksum_tag_q;

  assign ig_payload_txn.valid = payload_valid_q;
  assign ig_payload_txn.thr = 0;
  assign ig_payload_txn.payload = payload_q;
  assign ig_payload_txn.first = cfg_probe.cfg_header_filter ? (beat_count_q == cfg_probe.cfg_header_length) : (beat_count_q == 0);
  assign ig_payload_txn.last = (!cfg_probe.cfg_checksum_filter || !cfg_probe.cfg_checksum_enable) ? payload_eop_q : ig_port.eop;
  assign ig_payload_txn.tag_drop = ig_drop_tag_q;
  assign ig_payload_txn.tag_thr = ig_thr_tag_q;
  assign ig_payload_txn.tag_checksum_ok = ig_checksum_tag_q;

  assign ig_header_txn.valid = ig_port.valid && ig_port.eop;
  assign ig_header_txn.header_valid = header_valid;
  assign ig_header_txn.header = header;

  assign ig_packet_txn.valid = ig_port.valid && ig_port.eop;
  assign ig_packet_txn.length = beat_count + 1'b1;
  assign ig_packet_txn.header_length = cfg_probe.cfg_header_length;
  assign ig_packet_txn.payload_length = ig_packet_txn.length - cfg_probe.cfg_header_length - (cfg_probe.cfg_checksum_filter && cfg_probe.cfg_checksum_enable);
  assign ig_packet_txn.has_checksum = cfg_probe.cfg_checksum_enable;
  assign ig_packet_txn.checksum_ok = checksum_ok;
  assign ig_packet_txn.auto_drop = cfg_probe.cfg_auto_drop || (cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_drop && !checksum_ok);
  assign ig_packet_txn.avail = avail_init;
  assign ig_packet_txn.thr = 0;
  assign ig_packet_txn.tag_drop = ig_drop_tag;
  assign ig_packet_txn.tag_thr = ig_thr_tag;
  assign ig_packet_txn.tag_checksum_ok = ig_checksum_tag;
  
  // Coverage

  localparam DATA_MEM_SIZE_MINUS_1 = DATA_MEM_SIZE - 1;
  localparam PP_MAX_PKT_LEN_MINUS_1 = `PP_MAX_PKT_LEN - 1;
  covergroup cg_ig @(posedge clk);
    cp_avail: coverpoint ig_port.avail {
      bins level_trk[4] = {[1:DATA_MEM_SIZE_MINUS_1]};
      bins min = {0};
      bins max = {DATA_MEM_SIZE};
    }
    cp_length: coverpoint ig_packet_txn.length iff ig_packet_txn.valid {
      bins length[4] = {[3:PP_MAX_PKT_LEN_MINUS_1]};
      bins min = {2};
      bins max = {`PP_MAX_PKT_LEN};
    }
    cp_checksum: coverpoint ig_packet_txn.checksum_ok iff (ig_packet_txn.valid && ig_packet_txn.has_checksum);
  endgroup
  cg_ig cov_ig = new;

  COV_use_all_avail: cover property (ig_port.valid && ig_port.eop && avail_init == (beat_count + 1));
  COV_b2b_pkts: cover property (ig_port.valid && ig_port.eop ##1 ig_port.valid && ig_port.sop);

  // Asserts

  AST_M_no_gaps: assert property (ig_port.valid && !ig_port.eop |=> ig_port.valid);
  AST_M_sop_ok: assert property (ig_port.valid |-> ig_port.sop == ~transfer);
  AST_M_no_short_packet: assert property (ig_packet_txn.valid |-> ig_packet_txn.length >= (1 + cfg_probe.cfg_header_length + cfg_probe.cfg_checksum_enable));
  AST_M_no_long_packet: assert property (ig_packet_txn.valid |-> ig_packet_txn.length  <= `PP_MAX_PKT_LEN);
  AST_M_no_ig: assert property (ig_port.avail < min_length && !transfer |-> !ig_port.valid);
  AST_M_no_overflow: assert property (ig_port.valid && ig_port.avail == 1 |-> ig_port.eop);

endmodule







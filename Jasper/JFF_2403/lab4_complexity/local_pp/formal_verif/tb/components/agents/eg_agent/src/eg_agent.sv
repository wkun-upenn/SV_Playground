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

module eg_agent #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  eg_port_intf.monitor eg_port,
  payload_txn_intf.driver eg_payload_txn,
  packet_txn_intf.driver eg_packet_txn,
  cfg_probe_intf.monitor cfg_probe
);

  default disable iff (!rstn);
  default clocking @(posedge clk); endclocking

  // Glue logic
  bit [`PKT_LEN_W:0] beat_count, beat_count_q;
  bit req;
  bit [THR_W-1:0] req_thr;
  bit transfer;
  bit [NUM_THR-1:0][`PKT_LEN_W:0] cnt, cnt_nx;
  bit cnt_overflow, cnt_underflow;
  bit [NUM_THR-1:0] cnt_empty, cnt_empty_nx;
  bit eg_assign_q, eg_assign_qq;
  bit [THR_W-1:0] eg_assign_thr_q, eg_assign_thr_qq;
  bit payload_valid, payload_valid_q;
  bit [DATA_W-1:0] payload, payload_q;
  bit payload_eop, payload_eop_q;
  bit [3:0] header_valid, header_valid_q;
  bit [4*DATA_W-1:0] header, header_q;
  bit [DATA_W-1:0] checksum, checksum_q;
  bit checksum_ok, checksum_ok_q;
  bit [PTR_W:0] avail_init, avail_init_q;
  bit [`PKT_LEN_W:0] min_length;
  bit [THR_W-1:0] eg_thr_tag, eg_thr_tag_q;
  bit eg_drop_tag, eg_drop_tag_q;
  bit eg_checksum_tag, eg_checksum_tag_q;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cnt <= {NUM_THR*(`PKT_LEN_W+1){1'b0}};
      cnt_empty <= {NUM_THR{1'b1}};
      req <= 1'b0;
      req_thr <= 0;
      transfer <= 1'b0;
      beat_count <= 0;
      eg_assign_q <= 1'b0;
      eg_assign_qq <= 1'b0;
    end else begin
      eg_assign_q <= eg_port.assign_;
      eg_assign_qq <= eg_assign_q;
      eg_assign_thr_q <= eg_port.assign_thr;
      eg_assign_thr_qq <= eg_assign_thr_q;
      cnt <= cnt_nx;
      cnt_empty <= cnt_empty_nx;
      if (eg_port.req) begin
        req_thr <= eg_port.req_thr;
        req <= 1'b1;
      end
      if (eg_port.valid && eg_port.eop) begin
        req <= 1'b0;
      end
      if (eg_port.valid && eg_port.sop) transfer <= 1'b1;
      if (eg_port.valid && eg_port.eop) transfer <= 1'b0;
      if (eg_port.valid) begin
        if (eg_port.eop) begin
          beat_count <= 0;
        end else if (~&beat_count) begin
          beat_count <= (beat_count + 1'b1);
        end
      end
    end
  end
  always_comb begin
    cnt_nx = cnt;
    cnt_empty_nx = {NUM_THR{1'b1}};
    cnt_underflow = 1'b0;
    cnt_overflow = 1'b0;
    for (int i=0; i<NUM_THR; i++) begin
      if (eg_port.req && eg_port.req_thr==i) begin
        if (cnt_nx[i]==0) cnt_underflow = 1'b1;
        cnt_nx[i]--;
      end
      if (eg_assign_qq && eg_assign_thr_qq==i) begin
        if (&cnt_nx[i]) cnt_overflow = 1'b1;
        cnt_nx[i]++;
      end
      if (cnt_nx[i]) cnt_empty_nx[i] = 1'b0;
    end
  end

  always @(posedge clk) begin
    if (eg_port.valid && eg_port.sop) {eg_checksum_tag_q,eg_thr_tag_q,eg_drop_tag_q} <= {eg_checksum_tag,eg_thr_tag,eg_drop_tag};
  end
  assign eg_thr_tag = (eg_port.valid && eg_port.sop) ? `GET_THR_TAG(eg_port.data) : eg_thr_tag_q;
  assign eg_drop_tag = (eg_port.valid && eg_port.sop) ? `GET_DROP_TAG(eg_port.data) : eg_drop_tag_q;
  assign eg_checksum_tag = (eg_port.valid && eg_port.sop) ? `GET_CHECKSUM_TAG(eg_port.data) : eg_checksum_tag_q;
  
  
  always_comb begin
    header_valid = header_valid_q;
    header = header_q;
    if (eg_port.valid) begin
      if (eg_port.sop) begin
        header_valid = 0;
        header = 0;
      end
      if (beat_count < cfg_probe.cfg_header_length) begin
        header_valid = (header_valid << 1) | 1'b1;
        header = (header << DATA_W) | eg_port.data;
      end
    end
  end
  always_comb begin
    payload_valid = (
      eg_port.valid &&
      (
        (beat_count < cfg_probe.cfg_header_length && cfg_probe.cfg_header_filter) ||
        (beat_count >= cfg_probe.cfg_header_length && !eg_port.eop) ||
        (eg_port.eop)
      )
    );
    payload = eg_port.data;
    payload_eop = eg_port.eop;
  end
  always_comb begin
    checksum = checksum_q;
    if (eg_port.valid) begin
      if (eg_port.sop) checksum = eg_port.data;
      else checksum = (checksum ^ eg_port.data);
    end
    checksum_ok = (checksum == 0);
  end

  assign min_length = ({`PKT_LEN_W+1{1'b0}} + cfg_probe.cfg_header_length + cfg_probe.cfg_checksum_enable + 1'b1);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      payload_valid_q <= 1'b0;
      payload_q <= 0;
      payload_eop_q <= 1'b0;
      checksum_q <= 0;
      checksum_ok_q <= 1'b0;
      header_valid_q <= 0;
      header_q <= 0;
      beat_count_q <= 0;
    end else begin
      payload_valid_q <= payload_valid;
      payload_q <= payload;
      payload_eop_q <= payload_eop;
      checksum_q <= checksum;
      checksum_ok_q <= checksum_ok;
      header_valid_q <= header_valid;
      header_q <= header;
      beat_count_q <= beat_count;
    end
  end

  assign eg_payload_txn.valid = payload_valid_q;
  assign eg_payload_txn.thr = req_thr;
  assign eg_payload_txn.payload = payload_q;
  assign eg_payload_txn.first = beat_count_q == cfg_probe.cfg_header_length;
  assign eg_payload_txn.last = payload_eop_q;
  assign eg_payload_txn.tag_drop = eg_drop_tag_q;
  assign eg_payload_txn.tag_thr = eg_thr_tag_q;
  assign eg_payload_txn.tag_checksum_ok = eg_checksum_tag_q;

  assign eg_packet_txn.valid = eg_port.valid && eg_port.eop;
  assign eg_packet_txn.length = beat_count + 1'b1;
  assign eg_packet_txn.header_length = cfg_probe.cfg_header_filter ? 3'd0 : cfg_probe.cfg_header_length;
  assign eg_packet_txn.payload_length = beat_count + 1'b1;
  assign eg_packet_txn.has_checksum = cfg_probe.cfg_checksum_enable && !cfg_probe.cfg_checksum_filter;
  assign eg_packet_txn.checksum_ok = 1'b1;
  assign eg_packet_txn.auto_drop = 1'b0;
  assign eg_packet_txn.avail = 0;
  assign eg_packet_txn.thr = req_thr;
  assign eg_packet_txn.tag_drop = eg_drop_tag;
  assign eg_packet_txn.tag_thr = eg_thr_tag;
  assign eg_packet_txn.tag_checksum_ok = eg_checksum_tag;

  // Coverage

  covergroup cg_eg @(posedge clk);
    cp_length: coverpoint beat_count iff eg_port.valid {
      bins length[8] = {[1:`PP_MAX_PKT_LEN]};
    }
    cp_empty: coverpoint cnt_empty;
  endgroup
  cg_eg cov_eg = new;

  // Asserts

  AST_S_sop_ok: assert property (eg_port.valid |-> eg_port.sop == ~transfer);
  AST_S_resp_eventually: assert property (eg_port.req |-> s_eventually (eg_port.valid && eg_port.eop));
  AST_M_wait: assert property (req |-> !eg_port.req);
  AST_M_thr_valid: assert property (eg_port.req |-> cnt[eg_port.req_thr] > 0);
  AST_M_req_eventually: assert property (|cnt |-> s_eventually eg_port.req);

endmodule





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

module covers #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  ig_port_intf.monitor ig_port,
  packet_txn_intf.monitor ig_packet_txn,
  eg_port_intf.monitor eg_port,
  packet_txn_intf.monitor eg_packet_txn,
  route_port_intf.monitor route_port,
  resp_txn_intf.monitor resp_txn,
  intr_txn_intf.monitor intr_txn,
  fl_probe_intf.monitor fl_probe,
  level_trk_intf.monitor level_trk,
  cfg_probe_intf.monitor cfg_probe
);
  import fv_pkg::*;

  localparam _M_NORMAL = M_NORMAL;
  localparam _M_ASSIGN = M_ASSIGN;
  localparam _M_DROP = M_DROP;
  localparam _H_1 = H_1;
  localparam _H_2 = H_2;
  localparam _H_3 = H_3;
  localparam _H_4 = H_4;
  localparam _U_ALL = U_ALL;
  localparam _U_ALLM1 = U_ALLM1;
  localparam _U_OTHER = U_OTHER;
  localparam _A_MIN = A_MIN;
  localparam _A_LOW = A_LOW;
  localparam _A_MID = A_MID;
  localparam _A_MAX = A_MAX;
  localparam _L_MIN = L_MIN;
  //localparam _L_MINP1 = L_MINP1;
  localparam _L_MID = L_MID;
  //localparam _L_MAXM1 = L_MAXM1;
  localparam _L_MAX = L_MAX;
  localparam _D_DROP = D_DROP;
  localparam _D_EMPTY_THR = D_EMPTY_THR;
  localparam _D_USED_THR = D_USED_THR;
  localparam _G_FIRST = G_FIRST;
  localparam _G_0 = G_0;
  localparam _G_1 = G_1;
  localparam _G_N = G_N;
  localparam _C_NONE = C_NONE;
  localparam _C_OK = C_OK;
  localparam _C_FAIL = C_FAIL;
  localparam _S_SINGLE = S_SINGLE;
  localparam _S_MULTI = S_MULTI;
  localparam _TP_LOW = TP_LOW;
  localparam _TP_MID = TP_MID;
  localparam _TP_HIGH = TP_HIGH;
  localparam _PP_LOW = PP_LOW;
  localparam _PP_MID = PP_MID;
  localparam _PP_HIGH = PP_HIGH;
  localparam _UT_0 = UT_0;
  localparam _UT_1 = UT_1;
  localparam _UT_MID = UT_MID;
  localparam _UT_ALL = UT_ALL;
  localparam _TW_0 = TW_0;
  //localparam _TW_1 = TW_1;
  localparam _TW_MID = TW_MID;
  //localparam _TW_MAXM1 = TW_MAXM1;
  localparam _TW_MAX = TW_MAX;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  gap_t         ig_gap;
  len_t         ig_len;
  use_t         ig_use;
  avail_t       ig_avail;
  dec_t         ig_dec;
  checksum_t    ig_checksum;
  gap_t         route_gap;
  dec_t         route_dec;
  gap_t         eg_gap;
  len_t         eg_len;
  source_t      eg_source;
  mode_t        cfg_mode;
  header_t      cfg_header_length;
  bit           cfg_header_filter;
  bit           cfg_checksum_drop;
  bit           cfg_checksum_filter;
  total_pkts_t  lvl_total_pkts;
  pend_pkts_t   lvl_pend_pkts;
  used_thrs_t   lvl_used_thrs;
  total_words_t lvl_total_words;

  bit intr_list_init_done;
  bit intr_list_empty;
  bit intr_list_almost_empty;
  bit intr_list_almost_full;
  bit intr_list_full;
  bit intr_thr_init_done;
  bit intr_thr_empty;
  bit intr_thr_almost_empty;
  bit intr_thr_almost_full;
  bit intr_new_packet;
  bit intr_checksum_error;
  assign intr_list_init_done = intr_txn.list_init_done;
  assign intr_list_empty = intr_txn.list_empty;
  assign intr_list_almost_empty = intr_txn.list_almost_empty;
  assign intr_list_almost_full = intr_txn.list_almost_full;
  assign intr_list_full = intr_txn.list_full;
  assign intr_thr_init_done = intr_txn.thr_init_done;
  assign intr_thr_empty = intr_txn.thr_empty;
  assign intr_thr_almost_empty = intr_txn.thr_almost_empty;
  assign intr_thr_almost_full = intr_txn.thr_almost_full;
  assign intr_new_packet = intr_txn.new_packet;
  assign intr_checksum_error = intr_txn.checksum_error;

  bit [`PKT_LEN_W:0] ig_len_min;
  bit [`PKT_LEN_W:0] ig_len_minp1;
  bit [`PKT_LEN_W:0] ig_len_maxm1;
  bit [`PKT_LEN_W:0] ig_len_max;
  bit [`PKT_LEN_W:0] eg_len_min;
  bit [`PKT_LEN_W:0] eg_len_minp1;
  bit [`PKT_LEN_W:0] eg_len_maxm1;
  bit [`PKT_LEN_W:0] eg_len_max;

  always_comb begin
    ig_len_max = {`PKT_LEN_W+1{1'b0}} + `PP_MAX_PKT_LEN;
    ig_len_min = {`PKT_LEN_W+1{1'b0}} + cfg_probe.cfg_header_length + 1'b1 + cfg_probe.cfg_checksum_enable;
    eg_len_max = {`PKT_LEN_W+1{1'b0}} + ig_len_max - (cfg_probe.cfg_header_filter ? cfg_probe.cfg_header_length : 1'b0) - ((cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_filter) ? 1'b1 : 1'b0);
    eg_len_min = {`PKT_LEN_W+1{1'b0}} + 1'b1 + (cfg_probe.cfg_header_filter ? 1'b0 : cfg_probe.cfg_header_length) + ((cfg_probe.cfg_checksum_enable && !cfg_probe.cfg_checksum_filter) ? 1'b1 : 1'b0);
    ig_len_maxm1 = ig_len_max-1'b1;
    ig_len_minp1 = ig_len_min+1'b1;
    eg_len_maxm1 = eg_len_max-1'b1;
    eg_len_minp1 = eg_len_min+1'b1;
  end

  bit [1:0] ig_gap_cnt, route_gap_cnt, eg_gap_cnt;
  bit eg_pend;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      // 3 = first
      ig_gap_cnt <= 2'd3;
      route_gap_cnt <= 2'd3;
      eg_gap_cnt <= 2'd3;
      eg_pend <= 1'b0;
      eg_source <= S_SINGLE;
    end else begin
      if (ig_port.valid && ig_port.eop) ig_gap_cnt <= 2'd0;
      else if (!ig_port.valid && ig_gap_cnt < 2) ig_gap_cnt <= (ig_gap_cnt + 2'd1);
      if (route_port.resp_valid) route_gap_cnt <= 2'd0;
      else if (route_gap_cnt < 2) route_gap_cnt <= (route_gap_cnt + 2'd1);
      if (eg_port.valid && eg_port.eop) eg_gap_cnt <= 2'd0;
      else if (!eg_port.req && !eg_pend && eg_gap_cnt < 2) eg_gap_cnt <= (eg_gap_cnt + 2'd1);
      if (eg_port.req) eg_pend <= 1'b1;
      if (eg_port.valid && eg_port.eop) eg_pend <= 1'b0;
      // thr_pkts gets decremented at eg_req, so have to sample now not at EOP
      if (eg_port.req) begin
        if (level_trk.thr_pkts[eg_port.req_thr] <= 1) eg_source = S_SINGLE;
        else eg_source = S_MULTI;
      end
    end
  end

  always_comb begin
    // Ingress
    case (ig_gap_cnt)
      2'd0: ig_gap = G_0;
      2'd1: ig_gap = G_1;
      2'd2: ig_gap = G_N;
      default: ig_gap = G_FIRST;
    endcase
    case (ig_packet_txn.length)
      ig_len_min: ig_len = L_MIN;
      //ig_len_minp1: ig_len = L_MINP1;
      //ig_len_maxm1: ig_len = L_MAXM1;
      ig_len_max: ig_len = L_MAX;
      default: ig_len = L_MID;
    endcase
    if (!cfg_probe.cfg_checksum_enable) ig_checksum = C_NONE;
    else if (ig_packet_txn.checksum_ok) ig_checksum = C_OK;
    else ig_checksum = C_FAIL;
    if (ig_packet_txn.length == ig_packet_txn.avail) ig_use = U_ALL;
    else if (ig_packet_txn.length == (ig_packet_txn.avail-1)) ig_use = U_ALLM1;
    else ig_use = U_OTHER;
    case (ig_port.avail)
      DATA_MEM_SIZE: ig_avail = A_MAX;
      (DATA_MEM_SIZE/2): ig_avail = A_LOW;
      0: ig_avail = A_MIN;
      default: ig_avail = A_MID;
    endcase
    if (ig_packet_txn.tag_drop) begin
      ig_dec = D_DROP;
    end else begin
      if (level_trk.thr_empty[ig_packet_txn.tag_thr]) begin
        ig_dec = D_EMPTY_THR;
      end else begin
        ig_dec = D_USED_THR;
      end
    end
    // Route
    case (route_gap_cnt)
      2'd0: route_gap = G_0;
      2'd1: route_gap = G_1;
      2'd2: route_gap = G_N;
      default: route_gap = G_FIRST;
    endcase
    if (resp_txn.drop) begin
      route_dec = D_DROP;
    end else begin
      if (level_trk.thr_empty[resp_txn.thr]) begin
        route_dec = D_EMPTY_THR;
      end else begin
        route_dec = D_USED_THR;
      end
    end
    // Egress
    case (eg_gap_cnt)
      2'd0: eg_gap = G_0;
      2'd1: eg_gap = G_1;
      2'd2: eg_gap = G_N;
      default: eg_gap = G_FIRST;
    endcase
    case (eg_packet_txn.length)
      eg_len_min: eg_len = L_MIN;
      //eg_len_minp1: eg_len = L_MINP1;
      //eg_len_maxm1: eg_len = L_MAXM1;
      eg_len_max: eg_len = L_MAX;
      default: eg_len = L_MID;
    endcase
    // Config
    if (cfg_probe.cfg_auto_drop) cfg_mode = M_DROP;
    else if (cfg_probe.cfg_auto_assign) cfg_mode = M_ASSIGN;
    else cfg_mode = M_NORMAL;
    case (cfg_probe.cfg_header_length)
      3'd1: cfg_header_length = H_1;
      3'd2: cfg_header_length = H_2;
      3'd3: cfg_header_length = H_3;
      3'd4: cfg_header_length = H_4;
      default: cfg_header_length = H_4;
    endcase
    cfg_header_filter = cfg_probe.cfg_header_filter;
    cfg_checksum_filter = cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_filter;
    cfg_checksum_drop = cfg_probe.cfg_checksum_enable && cfg_probe.cfg_checksum_drop;
    // Level
    if (level_trk.total_pkts <= 2) lvl_total_pkts = TP_LOW;
    else if (level_trk.total_pkts >= (DATA_MEM_SIZE/4)) lvl_total_pkts = TP_HIGH;
    else lvl_total_pkts = TP_MID;
    if (level_trk.pending_pkts <= 1) lvl_pend_pkts = PP_LOW;
    else if (level_trk.pending_pkts >= 4) lvl_pend_pkts = PP_HIGH;
    else lvl_pend_pkts = PP_MID;
    case ($countones(level_trk.thr_empty))
      NUM_THR: lvl_used_thrs = UT_0;
      (NUM_THR-1): lvl_used_thrs = UT_1;
      0: lvl_used_thrs = UT_ALL;
      default: lvl_used_thrs = UT_MID;
    endcase
    case (DATA_MEM_SIZE - fl_probe.ptr_avail)
      0: lvl_total_words = TW_0;
      //1: lvl_total_words = TW_1;
      //(DATA_MEM_SIZE-1): lvl_total_words = TW_MAXM1;
      DATA_MEM_SIZE: lvl_total_words = TW_MAX;
      default: lvl_total_words = TW_MID;
    endcase
  end

  `CG_CLOCK(clk,ig_packet_txn.valid,clk_ig);
  `CG_CLOCK(clk,eg_packet_txn.valid,clk_eg);
  `CG_CLOCK(clk,resp_txn.valid,clk_resp);

  covergroup cg_ig @(posedge clk_ig);
    cp_ig_gap: coverpoint ig_gap {
      ignore_bins ignore = {G_FIRST};
    }
    cp_ig_len: coverpoint ig_len;
    cp_ig_checksum: coverpoint ig_checksum;
    cp_ig_use: coverpoint ig_use;
    cp_ig_dec: coverpoint ig_dec;
    cp_cfg_mode: coverpoint cfg_mode;
    cp_cfg_header_length: coverpoint cfg_header_length;
    cp_cfg_header_filter: coverpoint cfg_header_filter;
    cp_cfg_checksum_drop: coverpoint cfg_checksum_drop;
    cp_cfg_checksum_filter: coverpoint cfg_checksum_filter;
    cr_ig_mode: cross cp_ig_gap, cp_ig_len, cp_ig_checksum, cp_ig_use, cp_ig_dec, cp_cfg_mode {
      // in auto-drop mode the decision is always to drop
      ignore_bins auto_drop_dec = binsof(cp_ig_dec) intersect { _D_USED_THR, _D_EMPTY_THR } && binsof(cp_cfg_mode) intersect { _M_DROP };
      // in auto-drop mode it's not possible to use all or all-1
      ignore_bins auto_drop_use = binsof(cp_ig_use) intersect { _U_ALLM1, _U_ALL } && binsof(cp_cfg_mode) intersect { _M_DROP };
      // in auto-assign mode the decision is never to drop if checksum is good (or disabled)
      ignore_bins auto_assign_checksum_ok = binsof(cp_ig_dec) intersect { _D_DROP } && binsof(cp_cfg_mode) intersect { _M_ASSIGN } && binsof(cp_ig_checksum) intersect { _C_NONE, _C_OK };
      // in auto-assign cannot use all and assign to empty thread 
      ignore_bins auto_assign_empty_thr = binsof(cp_ig_dec) intersect { _D_EMPTY_THR } && binsof(cp_cfg_mode) intersect { _M_ASSIGN } && binsof(cp_ig_use) intersect { _U_ALL, _U_ALLM1 };
    }
    cr_ig_header: cross cp_ig_gap, cp_ig_len, cp_ig_checksum, cp_cfg_mode, cp_cfg_header_length, cp_cfg_header_filter;
    cr_ig_checksum: cross cp_ig_gap, cp_ig_len, cp_ig_checksum, cp_cfg_mode, cp_cfg_checksum_drop, cp_cfg_checksum_filter {
      ignore_bins no_checksum_drop = binsof(cp_ig_checksum) intersect { _C_NONE } && binsof(cp_cfg_checksum_drop) intersect { 1 };
      ignore_bins no_checksum_filter = binsof(cp_ig_checksum) intersect { _C_NONE } && binsof(cp_cfg_checksum_filter) intersect { 1 };
    }
  endgroup
  covergroup cg_ig_trans @(posedge clk_ig);
    cp_ig_len: coverpoint ig_len {
      bins T[] = (L_MIN,L_MID,L_MAX => L_MIN,L_MID,L_MAX);
    }
    cp_ig_checksum: coverpoint ig_checksum[0] { // 0=error, 1=ok (or no checksum)
      bins T[] = (0,1 => 0,1);
    }
    cp_ig_dec: coverpoint ig_dec[0] { // 0=drop, 1=assign
      bins T[] = (0,1 => 0,1);
    }
    cp_cfg_mode: coverpoint cfg_mode {
      bins T[] = (M_NORMAL,M_ASSIGN,M_DROP => M_NORMAL,M_ASSIGN,M_DROP);
    }
    cp_cfg_header_length: coverpoint cfg_header_length {
      bins T[] = (H_1,H_4 => H_2,H_3);
    }
    cp_cfg_header_filter: coverpoint cfg_header_filter {
      bins T[] = (0,1 => 0,1);
    }
    cp_cfg_checksum_drop: coverpoint cfg_checksum_drop {
      bins T[] = (0,1 => 0,1);
    }
    cp_cfg_checksum_filter: coverpoint cfg_checksum_filter {
      bins T[] = (0,1 => 0,1);
    }
  endgroup
  covergroup cg_ig_avail @(posedge clk);
    cr_ig_avail: cross ig_avail, cfg_mode, cfg_header_length, cfg_header_filter, cfg_checksum_drop, cfg_checksum_filter {
      ignore_bins auto_drop = binsof(cfg_mode) intersect { _M_DROP } && binsof(ig_avail) intersect { _A_MIN, _A_LOW };
      ignore_bins header_filter = binsof(cfg_header_filter) intersect { 1 } && binsof(ig_avail) intersect { _A_MIN };
      ignore_bins checksum_filter = binsof(cfg_checksum_filter) intersect { 1 } && binsof(ig_avail) intersect { _A_MIN };
    }
  endgroup
  covergroup cg_route @(posedge clk_resp);
    cp_cfg_header_length: coverpoint cfg_header_length;
    cp_cfg_header_filter: coverpoint cfg_header_filter;
    cp_cfg_checksum_drop: coverpoint cfg_checksum_drop;
    cp_cfg_checksum_filter: coverpoint cfg_checksum_filter;
    cp_route_gap: coverpoint route_gap {
      ignore_bins ignore = {G_FIRST};
    }
    cp_route_dec: coverpoint route_dec {
      bins drop = {D_DROP};
      bins asgn = {D_USED_THR, D_EMPTY_THR}; // clubbing both here
    }
    cr_route: cross cp_route_gap, cp_route_dec, cp_cfg_header_length, cp_cfg_header_filter, cp_cfg_checksum_drop, cp_cfg_checksum_filter;
  endgroup
  covergroup cg_eg @(posedge clk_eg);
    cp_cfg_mode: coverpoint cfg_mode {
      ignore_bins ignore = {M_DROP};
    }
    cp_cfg_header_length: coverpoint cfg_header_length;
    cp_cfg_header_filter: coverpoint cfg_header_filter;
    cp_cfg_checksum_drop: coverpoint cfg_checksum_drop;
    cp_cfg_checksum_filter: coverpoint cfg_checksum_filter;
    cp_eg_gap: coverpoint eg_gap {
      ignore_bins ignore = {G_FIRST};
    }
    cp_eg_len: coverpoint eg_len;
    cp_eg_source: coverpoint eg_source;
    cr_eg_gap: cross cp_eg_len, cp_eg_gap, cp_cfg_mode, cp_cfg_header_length, cp_cfg_header_filter, cp_cfg_checksum_filter;
    cr_eg_source: cross cp_eg_len, cp_eg_source, cp_cfg_mode, cp_cfg_header_length, cp_cfg_header_filter, cp_cfg_checksum_filter;
  endgroup
  covergroup cg_lvl @(posedge clk);
    cp_cfg_mode: coverpoint cfg_mode {
      ignore_bins ignore = {M_DROP};
    }
    cp_cfg_header_length: coverpoint cfg_header_length;
    cp_cfg_header_filter: coverpoint cfg_header_filter;
    cp_cfg_checksum_drop: coverpoint cfg_checksum_drop;
    cp_cfg_checksum_filter: coverpoint cfg_checksum_filter;
    cp_lvl_total_pkts: coverpoint lvl_total_pkts;
    cp_lvl_pend_pkts: coverpoint lvl_pend_pkts iff (cfg_mode == _M_NORMAL);
    cp_lvl_used_thrs: coverpoint lvl_used_thrs;
    cp_lvl_total_words: coverpoint lvl_total_words {
      ignore_bins ignore = {TW_0};
    }
    cr_total_pkts: cross cp_lvl_total_pkts, cp_lvl_total_words, cp_cfg_mode {
      ignore_bins tp_low_tw_high = binsof(cp_lvl_total_pkts) intersect { _TP_LOW } && binsof(cp_lvl_total_words) intersect { /*_TW_MAXM1,*/ _TW_MAX };
      //ignore_bins tp_high_tw_low = binsof(cp_lvl_total_pkts) intersect { _TP_MID, _TP_HIGH } && binsof(cp_lvl_total_words) intersect { /*_TW_0,*/ _TW_1 };
    }
    cr_used_thrs: cross cp_lvl_used_thrs, cp_lvl_total_words iff (cfg_mode == _M_NORMAL) {
      ignore_bins ut_low_tw_high = binsof(cp_lvl_used_thrs) intersect { _UT_0, _UT_1 } && binsof(cp_lvl_total_words) intersect { /*_TW_MAXM1,*/ _TW_MAX };
      //ignore_bins ut_high_tw_low = binsof(cp_lvl_used_thrs) intersect { _UT_ALL } && binsof(cp_lvl_total_words) intersect { _TW_0 /*, _TW_1*/ };
    }
  endgroup
  covergroup cg_intr @(posedge clk);
    cp_cfg_mode: coverpoint cfg_mode;
    cp_list_init_done: coverpoint intr_list_init_done {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_list_empty: coverpoint intr_list_empty {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_list_almost_empty: coverpoint intr_list_almost_empty {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_list_almost_full: coverpoint intr_list_almost_full {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_list_full: coverpoint intr_list_full {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_thr_init_done: coverpoint intr_thr_init_done {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_thr_empty: coverpoint intr_thr_empty {
      bins intr_high = {1};
      bins intr_low = {0};
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_thr_almost_empty: coverpoint intr_thr_almost_empty {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_thr_almost_full: coverpoint intr_thr_almost_full {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_new_packet: coverpoint intr_new_packet {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cp_checksum_error: coverpoint intr_checksum_error {
      bins intr_up = (0=>1);
      bins intr_down = (1=>0);
    }
    cr_list_init_done: cross cp_list_init_done, cp_cfg_mode;
    cr_list_empty: cross cp_list_empty, cp_cfg_mode {
      ignore_bins auto_drop = binsof(cp_cfg_mode) intersect { _M_DROP };
    }
    cr_list_almost_empty: cross cp_list_almost_empty, cp_cfg_mode;
    cr_list_almost_full: cross cp_list_almost_full, cp_cfg_mode;
    cr_list_full: cross cp_list_full, cp_cfg_mode;
    cr_thr_init_done: cross cp_thr_init_done, cp_cfg_mode;
    cr_thr_empty: cross cp_thr_empty, cp_cfg_mode {
      ignore_bins auto_drop = binsof(cp_cfg_mode) intersect { _M_DROP };
    }
    cr_thr_almost_empty: cross cp_thr_almost_empty, cp_cfg_mode {
      ignore_bins auto_drop = binsof(cp_cfg_mode) intersect { _M_DROP };
    }
    cr_thr_almost_full: cross cp_thr_almost_full, cp_cfg_mode {
      ignore_bins auto_drop = binsof(cp_cfg_mode) intersect { _M_DROP };
    }
    cr_new_packet: cross cp_new_packet, cp_cfg_mode {
      ignore_bins auto_drop = binsof(cp_cfg_mode) intersect { _M_DROP };
    }
    cr_checksum_error: cross cp_checksum_error, cp_cfg_mode;
  endgroup

  cg_ig cov_ig = new;
  cg_ig_trans cov_ig_trans = new;
  cg_ig_avail cov_ig_avail = new;
  cg_eg cov_eg = new;
  cg_route cov_route = new;
  cg_lvl cov_lvl = new;
  cg_intr cov_intr = new;

endmodule

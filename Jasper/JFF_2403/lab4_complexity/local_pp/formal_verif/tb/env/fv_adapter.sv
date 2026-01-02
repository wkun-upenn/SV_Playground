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

module fv_adapter #(`FV_PARAM_DECL) (
  input bit clk, rstn,

  input bit ig_valid,
  input bit [DATA_W-1:0] ig_data,
  input bit ig_sop, ig_eop,
  input bit [PTR_W:0] ig_avail,

  input bit route_req_valid,
  input bit [3:0] route_req_header_valid,
  input bit [4*DATA_W-1:0] route_req_header,
  input bit route_resp_valid,
  input bit route_resp_drop,
  input bit [THR_W-1:0] route_resp_thr,

  input bit eg_assign,
  input bit [THR_W-1:0] eg_assign_thr,
  input bit eg_req,
  input bit [THR_W-1:0] eg_req_thr,
  input bit eg_valid,
  input bit [DATA_W-1:0] eg_data,
  input bit eg_sop, eg_eop,

  input bit PCLK, PRESETn,
  input bit [15:0] PADDR,
  input bit PSEL,
  input bit PENABLE,
  input bit PWRITE,
  input bit [31:0] PWDATA,
  input bit PREADY,
  input bit [31:0] PRDATA,
  input bit PSLVERR,

  input bit intr,

  ig_port_intf.driver ig_port,
  route_port_intf.driver route_port,
  eg_port_intf.driver eg_port,
  apb_port_intf.driver apb_port,
  intr_port_intf.driver intr_port,
  fl_probe_intf.driver fl_probe,
  cfg_probe_intf.driver cfg_probe

);

  bit eg_dealloc;
  bit [PTR_W-1:0] eg_dealloc_ptr;
  bit drop_dealloc;
  bit [PTR_W-1:0] drop_dealloc_ptr;
  bit ig_alloc;
  bit [PTR_W-1:0] ig_alloc_ptr;
  bit [PTR_W:0] ptr_avail;
  bit cfg_auto_assign;
  bit [THR_W-1:0] cfg_auto_assign_thr;
  bit cfg_auto_drop;
  bit cfg_checksum_drop;
  bit cfg_checksum_enable;
  bit cfg_checksum_filter;
  bit cfg_header_filter;
  bit [2:0] cfg_header_length;
  bit [PTR_W:0] cfg_list_almost_empty_level;
  bit [PTR_W:0] cfg_list_almost_full_level;
  bit [PTR_W:0] cfg_thr_almost_empty_level;
  bit [PTR_W:0] cfg_thr_almost_full_level;
  bit cfg_list_init;
  bit cfg_thr_init;
  bit [31:0] cfg_intr_mask;
  bit [31:0] cfg_intr_clear;
  bit cfg_cg_en;
  bit list_init_done;
  bit thr_init_done;
  bit [31:0] intr_status;

  assign eg_dealloc = pp.eg_dealloc;
  assign eg_dealloc_ptr = pp.eg_dealloc_ptr;
  assign drop_dealloc = pp.drop_dealloc;
  assign drop_dealloc_ptr = pp.drop_dealloc_ptr;
  assign ig_alloc = pp.ig_alloc;
  assign ig_alloc_ptr = pp.ig_alloc_ptr;
  assign ptr_avail = pp.ptr_avail;
  assign cfg_auto_assign = pp.cfg_auto_assign;
  assign cfg_auto_assign_thr = pp.cfg_auto_assign_thr;
  assign cfg_auto_drop = pp.cfg_auto_drop;
  assign cfg_checksum_drop = pp.cfg_checksum_drop;
  assign cfg_checksum_enable = pp.cfg_checksum_enable;
  assign cfg_checksum_filter = pp.cfg_checksum_filter;
  assign cfg_header_filter = pp.cfg_header_filter;
  assign cfg_header_length = pp.cfg_header_length;
  assign cfg_list_almost_empty_level = pp.cfg_list_almost_empty_level;
  assign cfg_list_almost_full_level = pp.cfg_list_almost_full_level;
  assign cfg_thr_almost_empty_level = pp.cfg_thr_almost_empty_level;
  assign cfg_thr_almost_full_level = pp.cfg_thr_almost_full_level;
  assign cfg_list_init = pp.cfg_list_init;
  assign cfg_thr_init = pp.cfg_thr_init;
  assign cfg_intr_mask = pp.cfg_intr_mask;
  assign cfg_intr_clear = pp.cfg_intr_clear;
  assign cfg_cg_en = pp.cfg_cg_en;
  assign list_init_done = pp.list_init_done;
  assign thr_init_done = pp.thr_init_done;
  assign intr_status = pp.intr_status;

  assign {ig_port.valid,ig_port.sop,ig_port.eop,ig_port.data,ig_port.avail} = {ig_valid,ig_sop,ig_eop,ig_data,ig_avail};
  assign {eg_port.valid,eg_port.sop,eg_port.eop,eg_port.data,eg_port.req,eg_port.req_thr,eg_port.assign_,eg_port.assign_thr} = {eg_valid,eg_sop,eg_eop,eg_data,eg_req,eg_req_thr,eg_assign,eg_assign_thr};
  assign {route_port.req_valid,route_port.req_header_valid,route_port.req_header} = {route_req_valid,route_req_header_valid,route_req_header};
  assign {route_port.resp_valid,route_port.resp_drop,route_port.resp_thr} = {route_resp_valid,route_resp_drop,route_resp_thr};
  assign {apb_port.PADDR,apb_port.PSEL,apb_port.PENABLE,apb_port.PWRITE,apb_port.PWDATA,apb_port.PREADY,apb_port.PRDATA,apb_port.PSLVERR} = {PADDR,PSEL,PENABLE,PWRITE,PWDATA,PREADY,PRDATA,PSLVERR};

  assign intr_port.intr = intr;

  assign fl_probe.init_start = cfg_list_init;
  assign fl_probe.init_done = list_init_done;
  assign fl_probe.eg_dealloc = eg_dealloc;
  assign fl_probe.eg_dealloc_ptr = eg_dealloc_ptr;
  assign fl_probe.drop_dealloc = drop_dealloc;
  assign fl_probe.drop_dealloc_ptr = drop_dealloc_ptr;
  assign fl_probe.ig_alloc = ig_alloc;
  assign fl_probe.ig_alloc_ptr = ig_alloc_ptr;
  assign fl_probe.ptr_avail = ptr_avail;

  assign cfg_probe.cfg_auto_assign = cfg_auto_assign;
  assign cfg_probe.cfg_auto_assign_thr = cfg_auto_assign_thr;
  assign cfg_probe.cfg_auto_drop = cfg_auto_drop;
  assign cfg_probe.cfg_checksum_drop = cfg_checksum_drop;
  assign cfg_probe.cfg_checksum_enable = cfg_checksum_enable;
  assign cfg_probe.cfg_checksum_filter = cfg_checksum_filter;
  assign cfg_probe.cfg_header_filter = cfg_header_filter;
  assign cfg_probe.cfg_header_length = cfg_header_length;
  assign cfg_probe.cfg_list_almost_empty_level = cfg_list_almost_empty_level;
  assign cfg_probe.cfg_list_almost_full_level = cfg_list_almost_full_level;
  assign cfg_probe.cfg_thr_almost_empty_level = cfg_thr_almost_empty_level;
  assign cfg_probe.cfg_thr_almost_full_level = cfg_thr_almost_full_level;
  assign cfg_probe.cfg_list_init = cfg_list_init;
  assign cfg_probe.cfg_thr_init = cfg_thr_init;
  assign cfg_probe.cfg_intr_mask = cfg_intr_mask;
  assign cfg_probe.cfg_intr_clear = cfg_intr_clear;
  assign cfg_probe.cfg_cg_en = cfg_cg_en;
  assign cfg_probe.list_init_done = list_init_done;
  assign cfg_probe.thr_init_done = thr_init_done;
  assign cfg_probe.intr_status = intr_status;

endmodule

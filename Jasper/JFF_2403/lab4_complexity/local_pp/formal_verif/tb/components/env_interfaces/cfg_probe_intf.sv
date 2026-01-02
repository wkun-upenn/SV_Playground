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

interface cfg_probe_intf #(`FV_PARAM_DECL);
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
  `define cfg_probe_intf_fields(prefix=) \
    ``prefix``cfg_auto_assign, \
    ``prefix``cfg_auto_assign_thr, \
    ``prefix``cfg_auto_drop, \
    ``prefix``cfg_checksum_drop, \
    ``prefix``cfg_checksum_enable, \
    ``prefix``cfg_checksum_filter, \
    ``prefix``cfg_header_filter, \
    ``prefix``cfg_header_length, \
    ``prefix``cfg_list_almost_empty_level, \
    ``prefix``cfg_list_almost_full_level, \
    ``prefix``cfg_thr_almost_empty_level, \
    ``prefix``cfg_thr_almost_full_level, \
    ``prefix``cfg_list_init, \
    ``prefix``cfg_thr_init, \
    ``prefix``cfg_intr_mask, \
    ``prefix``cfg_intr_clear, \
    ``prefix``cfg_cg_en, \
    ``prefix``list_init_done, \
    ``prefix``thr_init_done, \
    ``prefix``intr_status
  modport driver (output `cfg_probe_intf_fields());
  modport monitor (input `cfg_probe_intf_fields());
endinterface

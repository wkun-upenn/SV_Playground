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

interface fl_probe_intf #(`FV_PARAM_DECL);
  bit init_start;
  bit init_done;
  bit eg_dealloc, drop_dealloc, ig_alloc;
  bit [PTR_W-1:0] eg_dealloc_ptr, drop_dealloc_ptr, ig_alloc_ptr;
  bit [PTR_W:0] ptr_avail;
  `define fl_probe_intf_fields(prefix=) \
    ``prefix``init_start, ``prefix``init_done, \
    ``prefix``eg_dealloc, ``prefix``drop_dealloc, ``prefix``ig_alloc, \
    ``prefix``eg_dealloc_ptr, ``prefix``drop_dealloc_ptr, ``prefix``ig_alloc_ptr, \
    ``prefix``ptr_avail
  modport driver (output `fl_probe_intf_fields());
  modport monitor (input `fl_probe_intf_fields());
endinterface

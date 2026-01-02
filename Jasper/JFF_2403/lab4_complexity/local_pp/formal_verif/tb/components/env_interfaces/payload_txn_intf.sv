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

interface payload_txn_intf #(`FV_PARAM_DECL);
  bit valid;
  bit [THR_W-1:0] thr;
  bit [DATA_W-1:0] payload;
  bit tag_drop;
  bit tag_checksum_ok;
  bit [THR_W-1:0] tag_thr;
  bit first, last;
  `define payload_txn_intf_fields(prefix=) \
    ``prefix``valid, ``prefix``thr, ``prefix``payload, ``prefix``first, ``prefix``last, \
    ``prefix``tag_drop, ``prefix``tag_checksum_ok, ``prefix``tag_thr
  modport driver (output `payload_txn_intf_fields());
  modport monitor (input `payload_txn_intf_fields());
endinterface

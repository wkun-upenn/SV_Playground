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

interface packet_txn_intf #(`FV_PARAM_DECL);
  bit valid;
  bit [`PKT_LEN_W:0] length;
  bit [2:0] header_length;
  bit [`PKT_LEN_W:0] payload_length;
  bit has_checksum;
  bit checksum_ok;
  bit auto_drop;
  bit [THR_W-1:0] thr;
  bit [PTR_W:0] avail;
  bit tag_drop;
  bit tag_checksum_ok;
  bit [THR_W-1:0] tag_thr;
  `define packet_txn_intf_fields(prefix=) \
    ``prefix``valid, ``prefix``length, ``prefix``header_length, ``prefix``payload_length, \
    ``prefix``has_checksum, ``prefix``checksum_ok, ``prefix``auto_drop, ``prefix``thr, \
    ``prefix``avail, ``prefix``tag_drop, ``prefix``tag_checksum_ok, ``prefix``tag_thr
  modport driver (output `packet_txn_intf_fields());
  modport monitor (input `packet_txn_intf_fields());
endinterface

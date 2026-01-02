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

interface intr_txn_intf #(`FV_PARAM_DECL);
  bit list_init_done;
  bit list_empty;
  bit list_almost_empty;
  bit list_almost_full;
  bit list_full;
  bit thr_init_done;
  bit thr_empty;
  bit thr_almost_empty;
  bit thr_almost_full;
  bit new_packet;
  bit checksum_error;
  `define intr_txn_intf_fields(prefix=) \
    ``prefix``list_init_done, \
    ``prefix``list_empty, \
    ``prefix``list_almost_empty, \
    ``prefix``list_almost_full, \
    ``prefix``list_full, \
    ``prefix``thr_init_done, \
    ``prefix``thr_empty, \
    ``prefix``thr_almost_empty, \
    ``prefix``thr_almost_full, \
    ``prefix``new_packet, \
    ``prefix``checksum_error
  modport driver (output `intr_txn_intf_fields());
  modport monitor (input `intr_txn_intf_fields());
endinterface

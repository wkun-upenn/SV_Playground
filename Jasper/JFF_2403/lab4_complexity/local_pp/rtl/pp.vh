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

`ifndef PP_MAX_PKT_LEN
  `define PP_MAX_PKT_LEN 16
`endif

`default_nettype none

`define PP_CFG_AUTO_ADDR          16'h0000
`define PP_CFG_CHECKSUM_ADDR      16'h0004
`define PP_CFG_HEADER_ADDR        16'h0008
`define PP_CFG_LIST_LEVEL_ADDR    16'h0010
`define PP_CFG_THR_LEVEL_ADDR     16'h0014
`define PP_CFG_INIT_ADDR          16'h0020
`define PP_CFG_INTR_MASK_ADDR     16'h0030
`define PP_CFG_INTR_CLEAR_ADDR    16'h0034
`define PP_CFG_INTR_STATUS_ADDR   16'h0038
`define PP_CFG_INTR_THR_NUM_ADDR  16'h003c
`define PP_CFG_LIST_AVAIL_ADDR    16'h0200
`define PP_CFG_THR_PACKETS_ADDR   16'h0400
`define PP_CFG_CG_ENABLE_ADDR     16'h0500

`define PP_CFG_AUTO_ASSIGN_ENABLE         0
`define PP_CFG_AUTO_ASSIGN_THR            8
`define PP_CFG_AUTO_DROP                  16

`define PP_CFG_CHECKSUM_ENABLE            0
`define PP_CFG_CHECKSUM_FILTER            8
`define PP_CFG_CHECKSUM_DROP              16

`define PP_CFG_HEADER_LENGTH              0
`define PP_CFG_HEADER_FILTER              8

`define PP_CFG_LIST_LEVEL_ALMOST_EMPTY    0
`define PP_CFG_LIST_LEVEL_ALMOST_FULL     16

`define PP_CFG_THR_LEVEL_ALMOST_EMPTY     0
`define PP_CFG_THR_LEVEL_ALMOST_FULL      16

`define PP_CFG_INIT_LIST_START            0
`define PP_CFG_INIT_LIST_DONE             1
`define PP_CFG_INIT_THR_START             8
`define PP_CFG_INIT_THR_DONE              9

`define PP_CFG_INTR_LIST_INIT_DONE        0
`define PP_CFG_INTR_LIST_EMPTY            1
`define PP_CFG_INTR_LIST_ALMOST_EMPTY     2
`define PP_CFG_INTR_LIST_ALMOST_FULL      3
`define PP_CFG_INTR_LIST_FULL             4
`define PP_CFG_INTR_THR_INIT_DONE         8
`define PP_CFG_INTR_THR_EMPTY             9
`define PP_CFG_INTR_THR_ALMOST_EMPTY      10
`define PP_CFG_INTR_THR_ALMOST_FULL       11
`define PP_CFG_INTR_NEW_PACKET            12
`define PP_CFG_INTR_CHECKSUM_ERROR        13

`define PP_CFG_INTR_THR_NUM_EMPTY         0
`define PP_CFG_INTR_THR_NUM_ALMOST_EMPTY  8
`define PP_CFG_INTR_THR_NUM_ALMOST_FULL   16


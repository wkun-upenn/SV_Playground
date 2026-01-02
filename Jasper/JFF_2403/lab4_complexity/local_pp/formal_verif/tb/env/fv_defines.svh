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

`define FV_PARAM_DECL \
  parameter DATA_W = 8, \
  parameter DATA_MEM_SIZE = 64, \
  parameter NUM_THR = 4, \
  parameter PROC_FIFO_DEPTH = 4, \
  parameter DYNAMIC_SCB = 1, \
  localparam PTR_W = $clog2(DATA_MEM_SIZE), \
  localparam DATA_MEM_ADDR_W = PTR_W, \
  localparam DATA_MEM_W = DATA_W + 1 + 1 + PTR_W, \
  localparam THR_W = $clog2(NUM_THR), \
  localparam THR_MEM_ADDR_W = THR_W, \
  localparam THR_MEM_W = PTR_W + PTR_W

`define FV_PARAM .DATA_W(DATA_W), .DATA_MEM_SIZE(DATA_MEM_SIZE), .NUM_THR(NUM_THR), .PROC_FIFO_DEPTH(PROC_FIFO_DEPTH)

`define PKT_LEN_W $clog2(`PP_MAX_PKT_LEN)

`define GET_DROP_TAG(data) data[fv_pkg::TAG_DROP_BIT]
`define GET_CHECKSUM_TAG(data) data[fv_pkg::TAG_CHECKSUM_BIT]
`define GET_THR_TAG(data) data[fv_pkg::TAG_THR_BIT +: THR_W]

`define CG_CLOCK(clk,en,gclk) \
  bit ``gclk``_en, ``gclk``; \
  always_latch if (~clk) ``gclk``_en <= en; \
  assign gclk = ``gclk``_en && clk;


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

module apb_agent #(
  parameter FV_CSR = 0,
  `FV_PARAM_DECL
) (
  input bit clk, rstn,
  input bit PCLK, PRESETn,
  apb_port_intf.monitor apb_port,
  apb_txn_intf.driver apb_txn
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  apb3_master #(
`ifdef FV_CSR
    .CONFIG_CSR_INTERFACE(1),
`endif
    .ABUS_WIDTH(16),
    .DBUS_WIDTH(32)
  ) apb3_master (
    .pclk(PCLK),
    .presetn(PRESETn),
    .penable(apb_port.PENABLE),
    .psel(apb_port.PSEL),
    .paddr(apb_port.PADDR),
    .pwrite(apb_port.PWRITE),
    .pwdata(apb_port.PWDATA),
    .pready(apb_port.PREADY),
    .prdata(apb_port.PRDATA),
    .pslverr(apb_port.PSLVERR)
  );

  // Glue logic

  assign apb_txn.valid = (apb_port.PSEL && apb_port.PENABLE && apb_port.PREADY);
  assign apb_txn.psel = apb_port.PSEL;
  assign apb_txn.penable = apb_port.PENABLE;
  assign apb_txn.pready = apb_port.PREADY;
  assign apb_txn.write = apb_port.PWRITE;
  assign apb_txn.data = apb_port.PWRITE ? apb_port.PWDATA : apb_port.PRDATA;
  assign apb_txn.error = apb_port.PSLVERR;
  always_comb begin
    case (apb_port.PADDR)
      `PP_CFG_AUTO_ADDR: apb_txn.addr = fv_pkg::AUTO;
      `PP_CFG_CHECKSUM_ADDR: apb_txn.addr = fv_pkg::CHECKSUM;
      `PP_CFG_HEADER_ADDR: apb_txn.addr = fv_pkg::HEADER;
      `PP_CFG_LIST_LEVEL_ADDR: apb_txn.addr = fv_pkg::LIST_LEVEL;
      `PP_CFG_THR_LEVEL_ADDR: apb_txn.addr = fv_pkg::THR_LEVEL;
      `PP_CFG_INIT_ADDR: apb_txn.addr = fv_pkg::INIT;
      `PP_CFG_CG_ENABLE_ADDR: apb_txn.addr = fv_pkg::CG_ENABLE;
      `PP_CFG_INTR_MASK_ADDR: apb_txn.addr = fv_pkg::INTR_MASK;
      `PP_CFG_INTR_CLEAR_ADDR: apb_txn.addr = fv_pkg::INTR_CLEAR;
      `PP_CFG_INTR_STATUS_ADDR: apb_txn.addr = fv_pkg::INTR_STATUS;
      `PP_CFG_INTR_THR_NUM_ADDR: apb_txn.addr = fv_pkg::INTR_THR_NUM;
      `PP_CFG_LIST_AVAIL_ADDR: apb_txn.addr = fv_pkg::LIST_AVAIL;
      default: apb_txn.addr = fv_pkg::INVALID;
    endcase
  end

  // Coverage

  covergroup cg_apb @(posedge clk);
    cp_apb_write: coverpoint apb_txn.addr iff (apb_txn.valid && apb_txn.write);
    cp_apb_read: coverpoint apb_txn.addr iff (apb_txn.valid && !apb_txn.write);
  endgroup
  cg_apb cov_apb = new;

endmodule





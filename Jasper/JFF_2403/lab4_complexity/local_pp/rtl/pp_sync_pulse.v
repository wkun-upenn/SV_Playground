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

`include "pp.vh"

module pp_sync_pulse (
  input bit clk1,
  input bit clk2,
  input bit rstn1,
  input bit rstn2,
  input bit in,
  output bit out,
  output bit busy
);

  bit a1, a2, a3;
  bit b1, b2, b3;

  always @(posedge clk1 or negedge rstn1) begin
    if (!rstn1) begin
      a1 <= 1'b0;
      a2 <= 1'b0;
      a3 <= 1'b0;
    end else begin
      a1 <= in ? 1'b1 : (a3 ? 1'b0 : a1);
      a2 <= b2;
      a3 <= a2;
    end
  end
  always @(posedge clk2 or negedge rstn2) begin
    if (!rstn2) begin
      b1 <= 1'b0;
      b2 <= 1'b0;
      b3 <= 1'b0;
    end else begin
      b1 <= a1;
      b2 <= b1;
      b3 <= b2;
    end
  end

  assign busy = a3 | a1;
  assign out = b2 & ~b3;

endmodule

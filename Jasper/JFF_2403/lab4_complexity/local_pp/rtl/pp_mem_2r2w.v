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

module pp_mem_2r2w #(DATA_W=1, ADDR_W=1) (
  input bit clk, rstn,
  input bit wr0, wr1, rd0, rd1,
  input bit [DATA_W-1:0] wr0data, wr1data,
  input bit [DATA_W-1:0] wr0mask, wr1mask,
  input bit [ADDR_W-1:0] wr0addr, wr1addr, rd0addr, rd1addr,
  output bit [DATA_W-1:0] rd0data, rd1data,
  input bit cfg_cg_en
);

  localparam SIZE = 2**ADDR_W;

  bit [SIZE-1:0][DATA_W-1:0] mem, mem_nx;

  bit clk_wr;
  bit clk_wr_en;
  bit clk_rd0;
  bit clk_rd0_en;
  bit clk_rd1;
  bit clk_rd1_en;
  assign clk_wr_en = wr0 || wr1;
  assign clk_rd0_en = rd0;
  assign clk_rd1_en = rd1;
  pp_cg cg_wr (clk, rstn, clk_wr_en, cfg_cg_en, clk_wr);
  pp_cg cg_rd0 (clk, rstn, clk_rd0_en, cfg_cg_en, clk_rd0);
  pp_cg cg_rd1 (clk, rstn, clk_rd1_en, cfg_cg_en, clk_rd1);

  always_comb begin
    mem_nx = mem;
    if (wr0) begin
      mem_nx[wr0addr] = (mem[wr0addr] & ~wr0mask) | (((wr1 && wr0addr == wr1addr) ? {DATA_W{1'bx}} : wr0data) & wr0mask);
    end
    if (wr1) begin
      mem_nx[wr1addr] = (mem[wr1addr] & ~wr1mask) | (((wr0 && wr0addr == wr1addr) ? {DATA_W{1'bx}} : wr1data) & wr1mask);
    end
  end

  always @(posedge clk_wr) begin
    mem <= mem_nx;
  end
  always @(posedge clk_rd0) begin
    if (rd0) begin
      rd0data <= mem_nx[rd0addr];
    end
  end
  always @(posedge clk_rd1) begin
    if (rd1) begin
      rd1data <= mem_nx[rd1addr];
    end
  end

endmodule

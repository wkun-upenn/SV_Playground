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

module pp_fifo #(
  WIDTH=8,
  DEPTH=4
) (
  input bit clk, rstn,
  input bit push,
  input bit [WIDTH-1:0] data_in,
  input bit pop,
  output bit [WIDTH-1:0] data_front,
  output bit full, empty,
  input bit cfg_cg_en
);

  bit [DEPTH-1:0][WIDTH-1:0] mem, mem_nx;
  bit [DEPTH-1:0]            vld, vld_nx;

  bit [DEPTH:0] level;

  bit clk_gated;
  bit clk_gated_en;
  assign clk_gated_en = push || pop;
  pp_cg cg (clk, rstn, clk_gated_en, cfg_cg_en, clk_gated);

  always @(posedge clk_gated or negedge rstn) begin
    if (!rstn) begin
      vld <= {DEPTH{1'b0}};
    end else begin
      vld <= vld_nx;
    end
  end

  always @(posedge clk_gated or negedge rstn) begin
    if (!rstn) begin
      mem <= {WIDTH*DEPTH{1'b0}};
    end else begin
      mem <= mem_nx;
    end
  end

  assign full = &vld;
  assign empty = !vld[0];

  always_comb begin
    mem_nx = mem;
    vld_nx = vld;
    level = 0;
    if (pop) begin
      mem_nx = mem_nx >> WIDTH;
      vld_nx = vld_nx >> 1;
    end
    if (push) begin
      for (int i=0; i<DEPTH; i++) begin
        if (!vld_nx[i]) mem_nx[i] = data_in;
      end
      for (int i=0; i<DEPTH; i++) begin
        if (!vld_nx[i]) begin
          vld_nx[i] = 1'b1;
          break;
        end else begin
          level++;
        end
      end
    end
  end

  assign data_front = mem[0];

endmodule

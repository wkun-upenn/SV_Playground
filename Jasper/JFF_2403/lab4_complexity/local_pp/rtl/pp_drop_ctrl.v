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

module pp_drop_ctrl #(
  parameter PTR_W = 6
) (
  input bit clk,
  input bit rstn,

  input bit resp_valid,
  input bit [PTR_W-1:0] resp_head,
  input bit [PTR_W-1:0] resp_tail,
  input bit resp_drop,

  output bit drop_empty,
  output bit [PTR_W-1:0] drop_head,
  output bit [PTR_W-1:0] drop_tail,
  input bit [PTR_W-1:0] drop_next,

  output bit drop_dealloc,
  output bit [PTR_W-1:0] drop_dealloc_ptr,

  input bit cfg_cg_en
);

  bit resp_valid_q;
  bit resp_drop_q;
  bit [PTR_W-1:0] resp_head_q;
  bit [PTR_W-1:0] resp_tail_q;

  bit clk_resp;
  bit clk_resp_en;
  bit clk_drop;
  bit clk_drop_en;
  assign clk_resp_en = (resp_valid || resp_valid_q);
  assign clk_drop_en = (!drop_empty || (resp_valid_q && resp_drop_q));
  pp_cg cg_resp_pipe (clk, rstn, clk_resp_en, cfg_cg_en, clk_resp);
  pp_cg cg_drop_fsm (clk, rstn, clk_drop_en, cfg_cg_en, clk_drop);

  always @(posedge clk_resp or negedge rstn) begin
    if (!rstn) begin
      resp_valid_q <= 1'b0;
    end else begin
      resp_valid_q <= resp_valid;
      resp_drop_q <= resp_drop;
      resp_head_q <= resp_head;
      resp_tail_q <= resp_tail;
    end
  end

  always @(posedge clk_drop or negedge rstn) begin
    if (~rstn) begin
      drop_empty <= 1'b1;
    end else begin
      case ({drop_empty,resp_valid_q && resp_drop_q})
        2'b00: begin
          drop_empty <= (drop_head == drop_tail);
          drop_head <= drop_next;
        end
        2'b01: begin
          drop_empty <= 1'b0;
          drop_head <= (drop_head == drop_tail) ? resp_head_q : drop_next;
          drop_tail <= resp_tail_q;
        end
        2'b10: begin
          // Idle
        end
        2'b11: begin
          drop_empty <= 1'b0;
          drop_head <= resp_head_q;
          drop_tail <= resp_tail_q;
        end
      endcase
    end
  end

  assign drop_dealloc = ~drop_empty;
  assign drop_dealloc_ptr = drop_head;

endmodule

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

module pp_list_ctrl #(
  parameter PTR_W = 6
) (
  input bit clk,
  input bit rstn,

  input bit eg_dealloc,
  input bit [PTR_W-1:0] eg_dealloc_ptr,

  input bit drop_dealloc,
  input bit [PTR_W-1:0] drop_dealloc_ptr,

  input bit ig_alloc,
  output bit [PTR_W-1:0] ig_alloc_ptr,

  output bit [PTR_W:0] ig_avail,
  output bit [PTR_W:0] ptr_avail,
  
  input bit cfg_list_init,
  output bit list_init_done,

  input bit cfg_cg_en
);

  localparam SIZE = 2**PTR_W;
  localparam SIZE_DIV_2 = SIZE/2;

  bit [PTR_W-1:0] mem [SIZE-1:0];
  bit [PTR_W:0] rdptr, wrptr;

  bit push0;
  bit push1;
  bit [PTR_W-1:0] ptrin0;
  bit [PTR_W-1:0] ptrin1;

  bit init;
  enum bit [1:0] { IDLE, BUSY, DONE } init_st;
  bit [PTR_W-2:0] init_cnt;

  bit clk_wr;
  bit clk_wr_en;
  bit clk_rd;
  bit clk_rd_en;
  bit clk_init;
  bit clk_init_en;
  assign clk_wr_en = push0 || push1;
  assign clk_rd_en = ig_alloc;
  assign clk_init_en = cfg_list_init || (init_st == BUSY);
  pp_cg cg_wr (clk, rstn, clk_wr_en, cfg_cg_en, clk_wr);
  pp_cg cg_rd (clk, rstn, clk_rd_en, cfg_cg_en, clk_rd);
  pp_cg cg_init (clk, rstn, clk_init_en, cfg_cg_en, clk_init);

  always @(posedge clk_wr or negedge rstn) begin
    if (~rstn) begin
      wrptr <= 0;
    end else begin
      case ({push0,push1})
        2'b00: begin
        end
        2'b10: begin
          mem[wrptr[PTR_W-1:0]] <= ptrin0;
          wrptr <= (wrptr + 1'b1);
        end
        2'b01: begin
          mem[wrptr[PTR_W-1:0]] <= ptrin1;
          wrptr <= (wrptr + 1'b1);
        end
        2'b11: begin
          mem[wrptr[PTR_W-1:0]] <= ptrin0;
          mem[wrptr[PTR_W-1:0]+1'b1] <= ptrin1;
          wrptr <= (wrptr + 2'd2);
        end
      endcase
    end
  end

  always @(posedge clk_rd or negedge rstn) begin
    if (~rstn) begin
      rdptr <= 0;
    end else begin
      if (ig_alloc) begin
        rdptr <= (rdptr + 1'b1);
      end
    end
  end

  always @(posedge clk_init or negedge rstn) begin
    if (!rstn) begin
      init_st <= IDLE;
    end else begin
      if (cfg_list_init) begin
         init_st <= BUSY;
         init_cnt <= 0;
       end
      if (init_st == BUSY) begin
        if (&init_cnt) init_st <= DONE;
        init_cnt <= init_cnt + 1'b1;
      end
    end
  end
  assign init = (init_st == BUSY);
  assign list_init_done = (init_st == DONE);

  assign push0 = init | eg_dealloc;
  assign push1 = init | drop_dealloc;
  assign ptrin0 = init ? {init_cnt,1'b0} : eg_dealloc_ptr;
  assign ptrin1 = init ? {init_cnt,1'b1} : drop_dealloc_ptr;

  assign ptr_avail = (wrptr - rdptr);
`ifdef BUG
  assign ig_avail = ptr_avail;
`else
  assign ig_avail = ptr_avail - ig_alloc;
`endif

  assign ig_alloc_ptr = mem[rdptr[PTR_W-1:0]];

endmodule

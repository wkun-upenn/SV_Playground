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

module pp_thr_mem #(
  parameter PTR_W = 6,
  parameter NUM_THR = 4,
  parameter THR_W = 2
) (
  input bit clk,
  input bit rstn,

  input bit resp_valid,
  input bit [PTR_W-1:0] resp_head,
  input bit [PTR_W-1:0] resp_tail,
  input bit resp_drop,
  input bit [THR_W-1:0] resp_thr,
  output bit resp_thr_empty,
  output bit [PTR_W-1:0] resp_thr_tail,

  input bit eg_req,
  input bit [THR_W-1:0] eg_req_thr,
  output bit eg_start,
  output bit [PTR_W-1:0] eg_start_ptr,
  input bit [PTR_W-1:0] eg_next,
  
  input bit eg_valid,
  input bit eg_sop,
  input bit eg_eop,

  input bit eg_stall,

  output bit [NUM_THR-1:0][PTR_W:0] thr_packets,

  input bit cfg_thr_init,
  output bit thr_init_done,
  
  input bit cfg_cg_en
);

  typedef struct packed {
    bit empty;
    bit [PTR_W-1:0] head, tail;
  } thr_mem_t;

  localparam MEM_W = $bits(thr_mem_t);

  thr_mem_t rd0_data, wr0_data, wr0_mask;
  bit [THR_W-1:0] rd0_addr, wr0_addr;
  bit rd0, wr0;
  thr_mem_t rd1_data, wr1_data, wr1_mask;
  bit [THR_W-1:0] rd1_addr, wr1_addr;
  bit rd1, wr1;
  thr_mem_t wri_data, wri_mask;

  bit resp_valid_q;
  bit resp_drop_q;
  bit [PTR_W-1:0] resp_head_q;
  bit [PTR_W-1:0] resp_tail_q;
  bit [THR_W-1:0] resp_thr_q;

  bit eg_req_q;
  bit [THR_W-1:0] eg_req_thr_q;
  bit [PTR_W-1:0] eg_next_q;

  bit init;
  enum bit [1:0] { IDLE, BUSY, DONE} init_st;
  bit [THR_W-2:0] init_cnt;

  bit clk_resp;
  bit clk_resp_en;
  bit clk_eg;
  bit clk_eg_en;
  bit clk_init;
  bit clk_init_en;
  bit clk_thr;
  bit clk_thr_en;
  assign clk_resp_en = resp_valid || resp_valid_q;
  assign clk_eg_en = eg_req || eg_req_q || eg_valid || eg_start;
  assign clk_init_en = cfg_thr_init || (init == BUSY);
  assign clk_thr_en = eg_req || resp_valid;
  pp_cg cg_wr (clk, rstn, clk_resp_en, cfg_cg_en, clk_resp);
  pp_cg cg_rd (clk, rstn, clk_eg_en, cfg_cg_en, clk_eg);
  pp_cg cg_init (clk, rstn, clk_init_en, cfg_cg_en, clk_init);
  pp_cg cg_thr (clk, rstn, clk_thr_en, cfg_cg_en, clk_thr);

  always @(posedge clk_init or negedge rstn) begin
    if (!rstn) begin
      init_st <= IDLE;
    end else begin
      if (cfg_thr_init) begin
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
  assign thr_init_done = (init_st == DONE);

  always @(posedge clk_resp or negedge rstn) begin
    if (!rstn) begin
      resp_valid_q <= 1'b0;
    end else begin
      resp_valid_q <= resp_valid;
      resp_drop_q <= resp_drop;
      resp_head_q <= resp_head;
      resp_tail_q <= resp_tail;
      resp_thr_q <= resp_thr;
    end
  end

  always @(posedge clk_eg or negedge rstn) begin
    if (~rstn) begin
      eg_req_q <= 1'b0;
      eg_start <= 1'b0;
    end else begin
      eg_req_q <= (eg_req || eg_req_q) && eg_stall;
`ifdef HACK
      if (eg_req_q) eg_req_thr_q <= eg_req_thr;
`else
      if (eg_req) eg_req_thr_q <= eg_req_thr;
`endif
      eg_next_q <= eg_next;
      eg_start <= rd1;
    end
  end
  assign eg_start_ptr = rd1_data.head;

  pp_mem_2r2w #(MEM_W, THR_W) mem (
    .clk(clk),
    .rstn(rstn),
    .wr0(wr0),
    .wr0addr(wr0_addr),
    .wr0data(init ? wri_data : wr0_data),
    .wr0mask(init ? wri_mask : wr0_mask),
    .rd0(rd0),
    .rd0addr(rd0_addr),
    .rd0data(rd0_data),
    .wr1(wr1),
    .wr1addr(wr1_addr),
    .wr1data(init ? wri_data : wr1_data),
    .wr1mask(init ? wri_mask : wr1_mask),
    .rd1(rd1),
    .rd1addr(rd1_addr),
    .rd1data(rd1_data),
    .cfg_cg_en(cfg_cg_en)
  );

  always_comb begin
    resp_thr_empty = rd0_data.empty;
    resp_thr_tail = rd0_data.tail;
    //if (wr1 && wr1_addr == wr0_addr && wr1_mask.empty) begin
    //  resp_thr_empty = wr1_data.empty;
    //end
  end

  assign rd0 = resp_valid && ~resp_drop;
  assign rd0_addr = resp_thr;

  assign rd1 = (eg_req || eg_req_q) && !eg_stall;
  assign rd1_addr = eg_req ? eg_req_thr : eg_req_thr_q;

  assign wr0 = (resp_valid_q && ~resp_drop_q) || init;
  assign wr0_addr = init ? {init_cnt,1'b0} : resp_thr_q;
  assign wr0_mask.empty = 1'b1;
  assign wr0_mask.head = {PTR_W{resp_thr_empty}};
  assign wr0_mask.tail = {PTR_W{1'b1}};
  assign wr0_data.empty = 1'b0;
  assign wr0_data.head = resp_head_q;
  assign wr0_data.tail = resp_tail_q;

  assign wr1 = (eg_valid && eg_eop) || init;
  assign wr1_addr = init ? {init_cnt,1'b1} : eg_req_thr_q;
  assign wr1_mask.empty = 1'b1;
  assign wr1_mask.head = {PTR_W{1'b1}};
  assign wr1_mask.tail = {PTR_W{1'b0}};
  assign wr1_data.empty = (eg_next_q == eg_next);
  assign wr1_data.head = eg_next;
  assign wr1_data.tail = {PTR_W{1'bx}};

  assign wri_mask.empty = 1'b1;
  assign wri_mask.head = {PTR_W{1'b0}};
  assign wri_mask.tail = {PTR_W{1'b0}};
  assign wri_data.empty = 1'b1;
  assign wri_data.head = {PTR_W{1'bx}};
  assign wri_data.tail = {PTR_W{1'bx}};

  always @(posedge clk_thr or negedge rstn) begin
    if (~rstn) begin
      thr_packets <= 0;
    end else begin
      for (int i = 0; i < NUM_THR; i++) begin
        thr_packets[i] <= thr_packets[i] + (resp_valid && ~resp_drop && resp_thr == i) - (eg_req && eg_req_thr == i);
      end
    end
  end

endmodule

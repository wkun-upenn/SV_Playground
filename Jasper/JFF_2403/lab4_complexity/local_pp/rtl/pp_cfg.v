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

module pp_cfg #(
  parameter PTR_W = 6,
  parameter THR_W = 2,
  parameter NUM_THR = 4
) (
  input bit PCLK,
  input bit PRESETn,
  input bit PSEL,
  input bit PENABLE,
  input bit [15:0] PADDR,
  input bit PWRITE,
  input bit [31:0] PWDATA,
  output bit [31:0] PRDATA,
  output bit PREADY,
  output bit PSLVERR,

  input bit clk,
  input bit rstn,

  input bit [PTR_W:0] ptr_avail,
  input bit [NUM_THR-1:0][PTR_W:0] thr_packets,
  input bit list_init_done,
  input bit thr_init_done,

  output bit cfg_auto_assign,
  output bit [THR_W-1:0] cfg_auto_assign_thr,
  output bit cfg_auto_drop,
  output bit cfg_checksum_drop,
  output bit cfg_checksum_enable,
  output bit cfg_checksum_filter,
  output bit cfg_header_filter,
  output bit [2:0] cfg_header_length,
  output bit [PTR_W:0] cfg_list_almost_empty_level,
  output bit [PTR_W:0] cfg_list_almost_full_level,
  output bit [PTR_W:0] cfg_thr_almost_empty_level,
  output bit [PTR_W:0] cfg_thr_almost_full_level,
  output bit cfg_list_init,
  output bit cfg_thr_init,

  output bit [31:0] cfg_intr_mask,
  output bit [31:0] cfg_intr_clear,
  input bit [31:0] intr_status,
  input bit [THR_W-1:0] intr_thr_empty_thr,
  input bit [THR_W-1:0] intr_thr_almost_empty_thr,
  input bit [THR_W-1:0] intr_thr_almost_full_thr,

  output bit cfg_cg_en,
  output bit cfg_updated
);

  bit [PTR_W:0] ptr_avail__PCLK;
  bit [NUM_THR-1:0][PTR_W:0] thr_packets__PCLK;
  bit list_init_done__PCLK;
  bit thr_init_done__PCLK;
  bit cfg_list_init__PCLK;
  bit cfg_list_init__busy;
  bit cfg_thr_init__PCLK;
  bit cfg_thr_init__busy;
  bit [31:0] cfg_intr_clear__PCLK;
  bit [31:0] cfg_intr_clear__busy;
  bit [31:0] intr_status__PCLK;
  bit [THR_W-1:0] intr_thr_empty_thr__PCLK;
  bit [THR_W-1:0] intr_thr_almost_empty_thr__PCLK;
  bit [THR_W-1:0] intr_thr_almost_full_thr__PCLK;
  bit cfg_updated__PCLK;
  bit cfg_updated__busy;
  bit cfg_updated__pulse;

  bit PCLK_gated;
  bit PCLK_gated_en;
  assign PCLK_gated_en = PSEL || cfg_list_init__PCLK || cfg_thr_init__PCLK || cfg_intr_clear__PCLK || cfg_updated__PCLK;
  pp_cg cg_pipe (PCLK, PRESETn, PCLK_gated_en, cfg_cg_en, PCLK_gated);

  // PCLK => clk
  pp_sync_pulse sync_cfg_list_init (PCLK, clk, PRESETn, rstn, cfg_list_init__PCLK, cfg_list_init, cfg_list_init__busy);
  pp_sync_pulse sync_cfg_thr_init (PCLK, clk, PRESETn, rstn, cfg_thr_init__PCLK, cfg_thr_init, cfg_thr_init__busy);
  for (genvar g=0; g<32; g++) begin: GEN_INTR_CLEAR_SYNC
    pp_sync_pulse sync_cfg_intr_clear (PCLK, clk, PRESETn, rstn, cfg_intr_clear__PCLK[g], cfg_intr_clear[g], cfg_intr_clear__busy[g]);
  end
  pp_sync_pulse sync_cfg_updated (PCLK, clk, PRESETn, rstn, cfg_updated__PCLK, cfg_updated__pulse, cfg_updated__busy);
  pp_sync sync_cfg_updated_delay (clk, cfg_updated__pulse, cfg_updated);
  // clk => PCLK
  pp_sync #(PTR_W+1) sync_ptr_avail (PCLK, ptr_avail, ptr_avail__PCLK);
  pp_sync #(NUM_THR*(PTR_W+1)) sync_thr_packets (PCLK, thr_packets, thr_packets__PCLK);
  pp_sync_pulse sync_list_init_done (clk, PCLK, rstn, PRESETn, list_init_done, list_init_done__PCLK, );
  pp_sync_pulse sync_thr_init_done (clk, PCLK, rstn, PRESETn, thr_init_done, thr_init_done__PCLK, );
  pp_sync #(32) sync_intr_status (PCLK, intr_status, intr_status__PCLK);
  pp_sync #(THR_W) sync_intr_thr_empty_thr (PCLK, intr_thr_empty_thr, intr_thr_empty_thr__PCLK);
  pp_sync #(THR_W) sync_intr_thr_almost_empty_thr (PCLK, intr_thr_almost_empty_thr, intr_thr_almost_empty_thr__PCLK);
  pp_sync #(THR_W) sync_intr_thr_almost_full_thr (PCLK, intr_thr_almost_full_thr, intr_thr_almost_full_thr__PCLK);

  assign PREADY = ~|{cfg_updated__busy,cfg_list_init__busy,cfg_thr_init__busy,cfg_intr_clear__busy};
  assign PSLVERR = 1'b0;

  always @(posedge PCLK_gated or negedge PRESETn) begin
    if (~PRESETn) begin
      PRDATA <= 32'b0;
      cfg_auto_assign <= 1'b0;
      cfg_auto_assign_thr <= {THR_W{1'b0}};
      cfg_auto_drop <= 1'b0;
      cfg_checksum_drop <= 1'b0;
      cfg_checksum_enable <= 1'b0;
      cfg_checksum_filter <= 1'b0;
      cfg_header_filter <= 1'b0;
      cfg_header_length <= 3'd1;
      cfg_list_almost_empty_level <= {PTR_W+1{1'b0}};
      cfg_list_almost_full_level <= {1'b1,{PTR_W{1'b0}}};
      cfg_thr_almost_empty_level <= {PTR_W+1{1'b0}};
      cfg_thr_almost_full_level <= {1'b1,{PTR_W{1'b0}}};
      cfg_list_init__PCLK <= 1'b0;
      cfg_thr_init__PCLK <= 1'b0;
      cfg_intr_mask <= 32'h0;
      cfg_intr_clear__PCLK <= 32'h0;
      cfg_cg_en <= 1'b1;
      cfg_updated__PCLK <= 1'b1;
    end else begin
      cfg_list_init__PCLK <= 1'b0;
      cfg_thr_init__PCLK <= 1'b0;
      cfg_intr_clear__PCLK <= 32'h0;
      cfg_updated__PCLK <= (PSEL && PENABLE && PWRITE && PREADY);
      if (PWRITE ? (PSEL && PENABLE && PREADY) : (PSEL)) begin
        case (PADDR)
          `PP_CFG_AUTO_ADDR: begin
            if (PWRITE) begin
              cfg_auto_assign <= PWDATA[`PP_CFG_AUTO_ASSIGN_ENABLE];
              cfg_auto_assign_thr <= PWDATA[`PP_CFG_AUTO_ASSIGN_THR +: THR_W];
              cfg_auto_drop <= PWDATA[`PP_CFG_AUTO_DROP];
            end
            PRDATA[`PP_CFG_AUTO_ASSIGN_ENABLE] <= cfg_auto_assign;
            PRDATA[`PP_CFG_AUTO_ASSIGN_THR +: 8] <= {{8-THR_W{1'b0}},cfg_auto_assign_thr};
            PRDATA[`PP_CFG_AUTO_DROP] <= cfg_auto_drop;
          end
          `PP_CFG_CHECKSUM_ADDR: begin
            if (PWRITE) begin
              cfg_checksum_enable <= PWDATA[`PP_CFG_CHECKSUM_ENABLE];
              cfg_checksum_filter <= PWDATA[`PP_CFG_CHECKSUM_FILTER];
              cfg_checksum_drop <= PWDATA[`PP_CFG_CHECKSUM_DROP];
            end
            PRDATA[`PP_CFG_CHECKSUM_ENABLE] <= cfg_checksum_enable;
            PRDATA[`PP_CFG_CHECKSUM_FILTER] <= cfg_checksum_filter;
            PRDATA[`PP_CFG_CHECKSUM_DROP] <= cfg_checksum_drop;
          end
          `PP_CFG_HEADER_ADDR: begin
            if (PWRITE) begin
              cfg_header_length <=
                (PWDATA[`PP_CFG_HEADER_LENGTH +: 3] < 3'd1) ? 3'd1 :
                (PWDATA[`PP_CFG_HEADER_LENGTH +: 3] > 3'd4) ? 3'd4 :
                PWDATA[`PP_CFG_HEADER_LENGTH +: 3];
              cfg_header_filter <= PWDATA[`PP_CFG_HEADER_FILTER];
            end
            PRDATA[`PP_CFG_HEADER_LENGTH +: 3] <= cfg_header_length;
            PRDATA[`PP_CFG_HEADER_FILTER] <= cfg_header_filter;
          end
          `PP_CFG_LIST_LEVEL_ADDR: begin
            if (PWRITE) begin
              cfg_list_almost_empty_level <= PWDATA[`PP_CFG_LIST_LEVEL_ALMOST_EMPTY +: (PTR_W+1)];
              cfg_list_almost_full_level <= PWDATA[`PP_CFG_LIST_LEVEL_ALMOST_FULL +: (PTR_W+1)];
            end
            PRDATA[`PP_CFG_LIST_LEVEL_ALMOST_EMPTY +: (PTR_W+1)] <= cfg_list_almost_empty_level;
            PRDATA[`PP_CFG_LIST_LEVEL_ALMOST_FULL +: (PTR_W+1)] <= cfg_list_almost_full_level;
          end
          `PP_CFG_THR_LEVEL_ADDR: begin
            if (PWRITE) begin
              cfg_thr_almost_empty_level <= PWDATA[`PP_CFG_THR_LEVEL_ALMOST_EMPTY +: (PTR_W+1)];
              cfg_thr_almost_full_level <= PWDATA[`PP_CFG_THR_LEVEL_ALMOST_FULL +: (PTR_W+1)];
            end
            PRDATA[`PP_CFG_THR_LEVEL_ALMOST_EMPTY +: (PTR_W+1)] <= cfg_thr_almost_empty_level;
            PRDATA[`PP_CFG_THR_LEVEL_ALMOST_FULL +: (PTR_W+1)] <= cfg_thr_almost_full_level;
          end
          `PP_CFG_INIT_ADDR: begin
            if (PWRITE) begin
              cfg_list_init__PCLK <= PWDATA[`PP_CFG_INIT_LIST_START];
              cfg_thr_init__PCLK <= PWDATA[`PP_CFG_INIT_THR_START];
            end
            PRDATA[`PP_CFG_INIT_LIST_DONE] <= list_init_done__PCLK;
            PRDATA[`PP_CFG_INIT_THR_DONE] <= thr_init_done__PCLK;
          end
          `PP_CFG_CG_ENABLE_ADDR: begin
            if (PWRITE) begin
              cfg_cg_en <= PWDATA[0];
            end
            PRDATA[0] <= cfg_cg_en;
          end
          `PP_CFG_INTR_MASK_ADDR: begin
            if (PWRITE) begin
              cfg_intr_mask <= PWDATA;
            end
            PRDATA <= cfg_intr_mask;
          end
          `PP_CFG_INTR_CLEAR_ADDR: begin
            if (PWRITE) begin
              cfg_intr_clear__PCLK <= PWDATA;
            end
          end
          `PP_CFG_INTR_STATUS_ADDR: begin
            PRDATA <= intr_status__PCLK;
          end
          `PP_CFG_INTR_THR_NUM_ADDR: begin
            PRDATA[`PP_CFG_INTR_THR_NUM_EMPTY +: THR_W] <= intr_thr_empty_thr__PCLK;
            PRDATA[`PP_CFG_INTR_THR_NUM_ALMOST_EMPTY +: THR_W] <= intr_thr_almost_empty_thr__PCLK;
            PRDATA[`PP_CFG_INTR_THR_NUM_ALMOST_FULL +: THR_W] <= intr_thr_almost_full_thr__PCLK;
          end
          `PP_CFG_LIST_AVAIL_ADDR: begin
            PRDATA[PTR_W:0] <= ptr_avail__PCLK;
          end
        endcase
        if ((PADDR & 16'hff00) == `PP_CFG_THR_PACKETS_ADDR) begin
          PRDATA[PTR_W:0] <= thr_packets__PCLK[PADDR[THR_W+1:2]];
        end
      end
    end
  end

endmodule


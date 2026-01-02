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

module pp_ig_parse #(
  parameter DATA_W = 8,
  parameter PTR_W = 6,
  parameter THR_W = 2
) (
  input bit clk,
  input bit rstn,

  input bit ig_valid,
  input bit ig_sop,
  input bit ig_eop,
  input bit [DATA_W-1:0] ig_data,

  output bit header_valid,
  output bit [DATA_W-1:0] header_data,

  output bit payload_valid,
  output bit payload_sop,
  output bit payload_eop,
  output bit [DATA_W-1:0] payload_data,

  output bit checksum_error,

  input bit cfg_header_filter,
  input bit [2:0] cfg_header_length,
  input bit cfg_checksum_enable,
  input bit cfg_checksum_filter,
  input bit cfg_cg_en
);

  enum bit [1:0] { IDLE, HEADER, DATA, CHECKSUM } parse_st, parse_st_nx;
  bit [2:0] word_cnt;
  bit is_payload;
  bit is_payload_q;
  bit ig_sop_q;
  bit ig_eop_q;

  bit [DATA_W-1:0] checksum, checksum_q;

  bit clk_ig;
  bit clk_ig_en;
  bit clk_header;
  bit clk_header_en;
  bit clk_payload;
  bit clk_payload_en;
`ifdef SEC_BUG1
  assign clk_ig_en = ig_valid;
`else
  assign clk_ig_en = ig_valid || (parse_st != IDLE);
`endif
`ifdef SEC_BUG2
  assign clk_header_en = (ig_valid && ig_sop) || header_valid;
`else
  assign clk_header_en = (ig_valid && (parse_st_nx == HEADER)) || header_valid;
`endif
  assign clk_payload_en = (ig_valid && is_payload) || payload_valid;
  pp_cg cg_ig (clk, rstn, clk_ig_en, cfg_cg_en, clk_ig);
  pp_cg cg_header (clk, rstn, clk_header_en, cfg_cg_en, clk_header);
  pp_cg cg_payload (clk, rstn, clk_payload_en, cfg_cg_en, clk_payload);

  assign is_payload = ((parse_st_nx == DATA) || ((parse_st_nx == HEADER) && !cfg_header_filter) || ((parse_st_nx == CHECKSUM) && !cfg_checksum_filter));

  always @(posedge clk_ig or negedge rstn) begin
    if (!rstn) begin
      parse_st <= IDLE;
      word_cnt <= 3'd0;
      ig_sop_q <= 1'b0;
      ig_eop_q <= 1'b0;
      is_payload_q <= 1'b0;
    end else begin
      parse_st <= parse_st_nx;
      ig_sop_q <= ig_sop;
      ig_eop_q <= ig_eop;
      if (ig_valid) begin
        if (word_cnt < 3'd4) word_cnt <= word_cnt + 1'b1;
        if (ig_eop) word_cnt <= 3'd0;
      end
      is_payload_q <= is_payload;
    end
  end

  always_comb begin
    parse_st_nx = parse_st;
    if (ig_valid) begin
      case (parse_st_nx)
        IDLE: begin
          if (ig_sop) parse_st_nx = HEADER;
        end
        HEADER: begin
          if (word_cnt == cfg_header_length) parse_st_nx = DATA;
        end
        DATA: begin
          if (ig_sop) parse_st_nx = HEADER;
          else if (ig_eop) begin
            if (cfg_checksum_enable) parse_st_nx = CHECKSUM;
          end
        end
        CHECKSUM: begin
          if (ig_sop) parse_st_nx = HEADER;
          else parse_st_nx = IDLE;
        end
      endcase
    end else begin
      parse_st_nx = IDLE;
    end
  end

  always @(posedge clk_header or negedge rstn) begin
    if (!rstn) begin
      header_valid <= 1'b0;
    end else begin
      header_valid <= ig_valid && (parse_st_nx == HEADER);
      header_data <= ig_data;
    end
  end

  always @(posedge clk_payload or negedge rstn) begin
    if (!rstn) begin
      payload_valid <= 1'b0;
    end else begin
      payload_valid <= ig_valid && is_payload;
      payload_data <= ig_data;
      payload_sop <= cfg_header_filter ? ((parse_st_nx == DATA) && (parse_st == HEADER)) : ig_sop;
    end
  end

  assign payload_eop = (cfg_checksum_enable && cfg_checksum_filter) ? (parse_st_nx == CHECKSUM) : ig_eop_q;

  always @(posedge clk_ig) begin
    if (ig_valid) begin
      checksum_q <= checksum;
    end
  end
  always_comb begin
    if (ig_sop) checksum <= ig_data;
    else checksum <= ig_data ^ checksum_q;
  end

  assign checksum_error = cfg_checksum_enable && (cfg_checksum_filter ? ((parse_st_nx == CHECKSUM) && checksum != 0) : ((parse_st == CHECKSUM) && checksum_q != 0));

endmodule

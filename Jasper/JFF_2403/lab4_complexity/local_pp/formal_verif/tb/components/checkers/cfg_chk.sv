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

module cfg_chk #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  apb_txn_intf.monitor apb_txn,
  level_trk_intf.monitor level_trk,
  cfg_probe_intf.monitor cfg_probe
);
  import fv_pkg::*;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  cfg_probe_intf #(`FV_PARAM) cfg_new ();
  always_comb begin
    {`cfg_probe_intf_fields(cfg_new.)} = {`cfg_probe_intf_fields(cfg_probe.)};
    if (apb_txn.valid && apb_txn.write) begin
      case (apb_txn.addr)
        AUTO: begin
          cfg_new.cfg_auto_assign = apb_txn.data[0];
          cfg_new.cfg_auto_assign_thr = apb_txn.data[THR_W-1+8:8];
          cfg_new.cfg_auto_drop = apb_txn.data[16];
        end
        CHECKSUM: begin
          cfg_new.cfg_checksum_enable = apb_txn.data[0];
          cfg_new.cfg_checksum_filter = apb_txn.data[8];
          cfg_new.cfg_checksum_drop = apb_txn.data[16];
        end
        HEADER: begin
          cfg_new.cfg_header_filter = apb_txn.data[8];
          cfg_new.cfg_header_length = apb_txn.data[2:0];
        end
        LIST_LEVEL: begin
          cfg_new.cfg_list_almost_empty_level = apb_txn.data[PTR_W:0];
          cfg_new.cfg_list_almost_full_level = apb_txn.data[PTR_W+16:16];
        end
        THR_LEVEL: begin
          cfg_new.cfg_thr_almost_empty_level = apb_txn.data[PTR_W:0];
          cfg_new.cfg_thr_almost_full_level = apb_txn.data[PTR_W+16:16];
        end
        INIT: begin
          cfg_new.cfg_list_init = apb_txn.data[0];
          cfg_new.cfg_thr_init = apb_txn.data[8];
        end
        INTR_CLEAR: begin
          cfg_new.cfg_intr_clear = apb_txn.data[31:0];
        end
        INTR_MASK: begin
          cfg_new.cfg_intr_mask = apb_txn.data[31:0];
        end
        CG_ENABLE: begin
          cfg_new.cfg_cg_en = apb_txn.data[0];
        end
      endcase
    end
  end

  bit list_init_start;
  bit thr_init_start;
  bit list_init_done;
  bit thr_init_done;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      list_init_start <= 1'b0;
      thr_init_start <= 1'b0;
      list_init_done <= 1'b0;
      thr_init_done <= 1'b0;
    end else begin
      if (cfg_probe.cfg_list_init) begin
        list_init_start <= 1'b1;
        list_init_done <= 1'b0;
      end
      if (cfg_probe.cfg_thr_init) begin
        thr_init_start <= 1'b1;
        thr_init_done <= 1'b0;
      end
      if (cfg_probe.list_init_done) begin
        list_init_done <= 1'b1;
      end
      if (cfg_probe.thr_init_done) begin
        thr_init_done <= 1'b1;
      end
    end
  end

  // Coverage

  covergroup cg_cfg @(posedge clk);
    cp_auto_assign: coverpoint cfg_probe.cfg_auto_assign;
    cp_auto_assign_thr: coverpoint cfg_probe.cfg_auto_assign_thr iff (cfg_probe.cfg_auto_assign);
    cp_auto_drop: coverpoint cfg_probe.cfg_auto_drop;
    cp_cg_en: coverpoint cfg_probe.cfg_cg_en;
    cp_header_length: coverpoint cfg_probe.cfg_header_length {
      bins lens[] = {[1:4]};
    }
    cp_header_filter: coverpoint cfg_probe.cfg_header_filter;
    cp_checksum_filter: coverpoint cfg_probe.cfg_checksum_filter iff (cfg_probe.cfg_checksum_enable);
    cp_checksum_drop: coverpoint cfg_probe.cfg_checksum_drop iff (cfg_probe.cfg_checksum_enable);
    cr_auto: cross cp_auto_drop, cp_auto_assign;
    cr_header: cross cp_header_length, cp_header_filter;
    cr_checksum: cross cp_checksum_filter, cp_checksum_drop;
    cr_auto_checksum: cross cp_checksum_drop, cp_auto_assign, cp_auto_drop iff (cfg_probe.cfg_checksum_enable);
  endgroup
  cg_cfg cov_cfg = new;

  // Assertions
  AST_config_header_length_valid: assert property (cfg_probe.cfg_header_length >= 1 && cfg_probe.cfg_header_length <= 4);

  AST_no_config_change_probe: assert property (
    !level_trk.idle
    |=>
    $stable(cfg_probe.cfg_auto_assign) &&
    $stable(cfg_probe.cfg_auto_assign_thr) &&
    $stable(cfg_probe.cfg_auto_drop) &&
    $stable(cfg_probe.cfg_checksum_drop) &&
    $stable(cfg_probe.cfg_checksum_enable) &&
    $stable(cfg_probe.cfg_checksum_filter) &&
    $stable(cfg_probe.cfg_header_filter) &&
    $stable(cfg_probe.cfg_header_length) &&
    $stable(cfg_probe.cfg_cg_en)
  );
  AST_no_config_change_apb: assert property (
    !level_trk.idle
    |->
    !((apb_txn.psel || apb_txn.penable) && apb_txn.write && (
      apb_txn.addr == fv_pkg::AUTO          ||
      apb_txn.addr == fv_pkg::CHECKSUM      ||
      apb_txn.addr == fv_pkg::HEADER        ||
      apb_txn.addr == fv_pkg::INIT          ||
      apb_txn.addr == fv_pkg::CG_ENABLE
    ))
  );
  AST_init_done: assert property (!list_init_done || !thr_init_done |-> !ig_port.valid);
  AST_init_list_multi_init: assert property (list_init_start |-> !cfg_probe.cfg_list_init);
  AST_init_thr_multi_init: assert property (thr_init_start |-> !cfg_probe.cfg_thr_init);

endmodule

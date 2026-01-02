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

module fl_chk #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  fl_probe_intf.monitor fl_probe
);
  localparam DATA_MEM_SIZE_MINUS_1 = DATA_MEM_SIZE - 1;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  bit [DATA_MEM_SIZE-1:0] ptrs, ptrs_nx;
  bit initialized;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      ptrs <= {DATA_MEM_SIZE{1'b0}};
      initialized <= 1'b0;
    end else begin
      ptrs <= ptrs_nx;
      if (fl_probe.init_done) initialized <= 1'b1;
    end
  end
  
  always_comb begin
    ptrs_nx = ptrs;
    if (fl_probe.init_done && !initialized) ptrs_nx = {DATA_MEM_SIZE{1'b1}};
    if (fl_probe.eg_dealloc) ptrs_nx[fl_probe.eg_dealloc_ptr] = 1'b1;
    if (fl_probe.drop_dealloc) ptrs_nx[fl_probe.drop_dealloc_ptr] = 1'b1;
    if (fl_probe.ig_alloc) ptrs_nx[fl_probe.ig_alloc_ptr] = 1'b0;
  end

  // Coverage

  covergroup cg_fl @(posedge clk);
    cp_eg_dealloc: coverpoint fl_probe.eg_dealloc iff fl_probe.eg_dealloc_ptr {
      bins ptr[3] = {[0:DATA_MEM_SIZE_MINUS_1]};
    }
    cp_drop_dealloc: coverpoint fl_probe.drop_dealloc iff fl_probe.drop_dealloc_ptr {
      bins ptr[3] = {[0:DATA_MEM_SIZE_MINUS_1]};
    }
    cp_ig_alloc: coverpoint fl_probe.ig_alloc iff fl_probe.ig_alloc_ptr {
      bins ptr[3] = {[0:DATA_MEM_SIZE_MINUS_1]};
    }
  endgroup
  cg_fl cov_fl = new;

  // Asserts

`ifdef FV_INIT_CHECKS
  AST_no_activity_before_init: assert property (!initialized |-> !fl_probe.ig_alloc && !fl_probe.eg_dealloc && !fl_probe.drop_dealloc);
  AST_init_done: assert property (##1 $rose(fl_probe.init_done) |=> fl_probe.ptr_avail == DATA_MEM_SIZE);
`endif
  AST_full_ok: assert property (initialized && &ptrs |-> fl_probe.ptr_avail == DATA_MEM_SIZE);
  AST_empty_ok: assert property (initialized && ~|ptrs |-> fl_probe.ptr_avail == 0);
  AST_no_duplicate: assert property (fl_probe.eg_dealloc && fl_probe.drop_dealloc |-> fl_probe.eg_dealloc_ptr != fl_probe.drop_dealloc_ptr);
  AST_eg_not_in_list: assert property (fl_probe.eg_dealloc |-> !ptrs[fl_probe.eg_dealloc_ptr]);
  AST_drop_not_in_list: assert property (fl_probe.drop_dealloc |-> !ptrs[fl_probe.drop_dealloc_ptr]);

endmodule





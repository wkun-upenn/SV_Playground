//=============================================================================
// boom_iq_if.sv — interface to the integer issue queue (IssueUnitCollapsing_2)
//-----------------------------------------------------------------------------
// 20-entry age-ordered collapsing queue, 2 dispatch ports, 2 issue ports,
// 5 wakeup ports, 1 speculative-load wakeup port.
//=============================================================================
interface boom_iq_if
  import boom_exe_defs_pkg::*;
 (input logic clk, input logic rst);

  // dispatch (Decoupled, ready is RegNext(num_available > w))
  logic         dis_valid[IQ_DISPATCH_W];
  logic         dis_ready[IQ_DISPATCH_W];
  uop_t         dis_uop[IQ_DISPATCH_W];
  // issue
  logic         iss_valid[IQ_ISSUE_W];
  uop_t         iss_uop[IQ_ISSUE_W];
  logic [9:0]   fu_types[IQ_ISSUE_W];
  // wakeups
  logic         wakeup_valid[IQ_WAKEUP_PORTS];
  logic [6:0]   wakeup_pdst[IQ_WAKEUP_PORTS];
  logic         spec_ld_wakeup_valid[1];
  logic [6:0]   spec_ld_wakeup_pdst[1];
  logic         ld_miss;
  // control
  logic [11:0]  br_resolve_mask, br_mispredict_mask;
  logic         flush_pipeline;

`ifndef VERILATOR   // clocking blocks / modports are only used by the UVM agents (Verilator runs the UVM-free smoke test)
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output dis_valid, dis_uop, fu_types, wakeup_valid, wakeup_pdst,
           spec_ld_wakeup_valid, spec_ld_wakeup_pdst, ld_miss,
           br_resolve_mask, br_mispredict_mask, flush_pipeline;
    input  dis_ready, iss_valid, iss_uop;
  endclocking
  clocking mon_cb @(posedge clk);
    default input #1step;
    input dis_valid, dis_ready, dis_uop, iss_valid, iss_uop, fu_types,
          wakeup_valid, wakeup_pdst, spec_ld_wakeup_valid, spec_ld_wakeup_pdst, ld_miss,
          br_resolve_mask, br_mispredict_mask, flush_pipeline;
  endclocking
  modport drv (clocking drv_cb, input clk, rst);
  modport mon (clocking mon_cb, input clk, rst);
`endif

`ifndef BOOM_IQ_IF_NO_SVA
  default clocking sva_cb @(posedge clk); endclocking
  default disable iff (rst);

  genvar w;
  generate for (w = 0; w < IQ_ISSUE_W; w++) begin : g_iss
    // A32: an issued uop's fu_code must be accepted by the port's fu_types
    A32_iss_fu_match: assert property (iss_valid[w] |-> ((iss_uop[w].fu_code & fu_types[w]) != 0))
      else $error("[IQ] port %0d issued fu_code %b but fu_types=%b", w, iss_uop[w].fu_code, fu_types[w]);
    // A33: the queue may still grant a uop in the very cycle its branch is mispredicted
    //      (IssueSlot.request is not gated by IsKilledByBranch — register-read kills it).
    //      Guard the *following* cycle instead: a mispredicted uop must be gone.
    A33_killed_uop_not_issued_later: assert property (
        iss_valid[w] |-> ((iss_uop[w].br_mask & $past(br_mispredict_mask)) == 0))
      else $error("[IQ] port %0d issued a uop that was mispredicted last cycle", w);
    // A34: issued uop carries no branch-mask bit that was resolved in an earlier cycle
    A34_iss_mask_resolved_cleared: assert property (iss_valid[w] |-> ((iss_uop[w].br_mask & $past(br_resolve_mask)) == 0))
      else $error("[IQ] port %0d issued a uop whose br_mask still has a bit resolved last cycle", w);
    // A35: an issued uop is in a valid issue state (s_valid_1 / s_valid_2)
    A35_iss_state_valid: assert property (iss_valid[w] |-> (iss_uop[w].iw_state inside {2'd1, 2'd2}))
      else $error("[IQ] port %0d issued a uop in state %0d", w, iss_uop[w].iw_state);
    // A36: nothing issues the cycle after a pipeline flush
    A36_flush_silences_issue: assert property (flush_pipeline |=> !iss_valid[w])
      else $error("[IQ] port %0d issued right after flush", w);
  end endgenerate

  // A37: the two issue ports never issue the same uop (rob_idx) in one cycle
  A37_no_double_issue: assert property ((iss_valid[0] && iss_valid[1]) |-> (iss_uop[0].rob_idx != iss_uop[1].rob_idx))
    else $error("[IQ] both ports issued rob_idx %0d", iss_uop[0].rob_idx);
  // A38: dispatch ready is a registered function of occupancy: it can only drop after a dispatch or stay (TB sanity)
  A38_dis_ready1_implies_ready0: assert property (dis_ready[1] |-> dis_ready[0])
    else $error("[IQ] dis_ready[1] without dis_ready[0]");
  // A39: wakeup to pdst 0 is illegal (x0 is never renamed)
  generate for (w = 0; w < IQ_WAKEUP_PORTS; w++) begin : g_wk
    A39_wakeup_pdst_nonzero: assert property (wakeup_valid[w] |-> wakeup_pdst[w] != 0)
      else $error("[IQ] wakeup port %0d woke pdst 0", w);
  end endgenerate
  A40_spec_ld_pdst_nonzero: assert property (spec_ld_wakeup_valid[0] |-> spec_ld_wakeup_pdst[0] != 0)
    else $error("[IQ] speculative load wakeup of pdst 0");

  C_iq_dual_issue:   cover property (iss_valid[0] && iss_valid[1]);
  C_iq_full:         cover property (!dis_ready[0]);
  C_iq_flush:        cover property (flush_pipeline);
  C_iq_ldmiss_poison:cover property (ld_miss);
  C_iq_grant_in_kill_cycle: cover property (iss_valid[0] && ((iss_uop[0].br_mask & br_mispredict_mask) != 0));
`endif
endinterface : boom_iq_if

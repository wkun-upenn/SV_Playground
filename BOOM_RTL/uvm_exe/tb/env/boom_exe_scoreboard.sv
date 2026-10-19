//=============================================================================
// boom_exe_scoreboard.sv — per-execution-unit scoreboard
//-----------------------------------------------------------------------------
// Predictor style: every request observed by the monitor is run through the
// reference model at issue time; the expectation is parked in an in-flight
// table keyed by rob_idx and retired when the response shows up (or when a
// branch mispredict / pipeline flush squashes it). Checks:
//   * data (bit-exact, IEEE view for FP), fflags, response port, latency
//   * squashed uops must not write back; live uops must write back
//   * bypass port data == eventual ALU result
//   * branch resolution info (mispredict / taken / pc_sel / cfi / targets)
//=============================================================================
`uvm_analysis_imp_decl(_req)
`uvm_analysis_imp_decl(_rsp)
`uvm_analysis_imp_decl(_fflags)
`uvm_analysis_imp_decl(_bypass)
`uvm_analysis_imp_decl(_brinfo)
`uvm_analysis_imp_decl(_brupd)

class boom_exe_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(boom_exe_scoreboard)

  uvm_analysis_imp_req    #(boom_exe_txn,    boom_exe_scoreboard) req_imp;
  uvm_analysis_imp_rsp    #(boom_exe_rsp,    boom_exe_scoreboard) rsp_imp;
  uvm_analysis_imp_fflags #(boom_exe_rsp,    boom_exe_scoreboard) fflags_imp;
  uvm_analysis_imp_bypass #(boom_exe_rsp,    boom_exe_scoreboard) bypass_imp;
  uvm_analysis_imp_brinfo #(boom_brinfo_rsp, boom_exe_scoreboard) brinfo_imp;
  uvm_analysis_imp_brupd  #(boom_brupd_txn,  boom_exe_scoreboard) brupd_imp;

  exu_id_e            unit;
  boom_exe_cfg        cfg;
  boom_exe_ref_model  ref_model;
  boom_spike_oracle   oracle;                      // second opinion from a Spike trace (null = not in use)

  boom_exe_txn        inflight[bit [5:0]];       // keyed by rob_idx
  boom_exe_txn        pending_brinfo[bit [5:0]];
  boom_exe_txn        await_flags[bit [5:0]];    // F2I: data seen, flags still expected
  bit [4:0]           early_flags[bit [5:0]];    // flags seen before data
  boom_exe_txn        last_req;                  // for bypass compare (same cycle)

  // statistics
  int unsigned n_req, n_rsp, n_killed_br, n_killed_flush, n_ambiguous, n_brinfo, n_bypass, n_flags;
  int unsigned n_data_err, n_flag_err, n_port_err, n_lat_err, n_unexpected, n_missing, n_brinfo_err, n_bypass_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_imp = new("req_imp", this); rsp_imp = new("rsp_imp", this); fflags_imp = new("fflags_imp", this);
    bypass_imp = new("bypass_imp", this); brinfo_imp = new("brinfo_imp", this); brupd_imp = new("brupd_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    ref_model = boom_exe_ref_model::type_id::create("ref_model");
  endfunction

  //--------------------------------------------------------------- helpers
  function bit both_nan(bit [63:0] a, bit [63:0] b, bit single);
    if (single) return (a[63:32] == 32'hFFFF_FFFF && b[63:32] == 32'hFFFF_FFFF &&
                        a[30:23] == 8'hFF && a[22:0] != 0 && b[30:23] == 8'hFF && b[22:0] != 0);
    return (a[62:52] == 11'h7FF && a[51:0] != 0 && b[62:52] == 11'h7FF && b[51:0] != 0);
  endfunction

  function void purge_ambiguous(int now);
    bit [5:0] dead[$];
    foreach (inflight[k]) if (inflight[k].flush_ambiguous && inflight[k].rsp_cycle < now) dead.push_back(k);
    foreach (dead[i]) begin
      `uvm_info("SB", $sformatf("%s rob=%0d completed in the flush cycle without a response (allowed)", unit.name(), dead[i]), UVM_MEDIUM)
      inflight.delete(dead[i]); n_ambiguous++;
    end
  endfunction

  //--------------------------------------------------------------- request
  function void write_req(boom_exe_txn t);
    purge_ambiguous(t.issue_cycle);
    n_req++;
    ref_model.predict(t);
    if (oracle != null) oracle.attach(unit, t);
    last_req = t;
    `uvm_info("SB", $sformatf("%s REQ  %s%s", unit.name(), t.convert2string(), t.killed_same_cycle ? " [killed@issue]" : ""), UVM_HIGH)
    if (t.killed_same_cycle) begin
      if (t.flush_with_req) n_killed_flush++; else n_killed_br++;
      if (oracle != null && t.spike_valid) oracle.retire(unit);
      return;
    end
    if (inflight.exists(t.rob_idx)) begin
      `uvm_error("SB", $sformatf("%s rob_idx %0d re-issued while still in flight (%s)", unit.name(), t.rob_idx, inflight[t.rob_idx].op.name()))
      inflight.delete(t.rob_idx);
    end
    inflight[t.rob_idx] = t;
    if (t.exp_brinfo_valid && cfg.check_brinfo) pending_brinfo[t.rob_idx] = t;
  endfunction

  //--------------------------------------------------------------- branch update / flush
  function void write_brupd(boom_brupd_txn b);
    bit [5:0] dead[$];
    foreach (inflight[k]) begin
      boom_exe_txn t = inflight[k];
      if ((t.br_mask & b.mispredict_mask) != 0) begin
        dead.push_back(k); n_killed_br++;
        `uvm_info("SB", $sformatf("%s rob=%0d %s squashed by mispredict mask %03h", unit.name(), k, t.op.name(), b.mispredict_mask), UVM_MEDIUM)
        continue;
      end
      t.br_mask &= ~b.resolve_mask;
      if (b.flush) begin
        // Verified on the RTL (sim/smoke: "kill/flush timing" table):
        //  * pipelined results that complete exactly in the flush cycle still write back
        //    (PipelinedFunctionalUnit gates the *next* stage, not the current output);
        //  * the queued ll_iresp / ll_fresp ports behave the same way, and a result that already
        //    sits in the BranchKillableQueue is never flushed (io.flush only drops uses_ldq entries);
        //  * only the iterative units (div / fdiv / fsqrt) are left ambiguous.
        bit pipelined = (t.ctrl.latency > 0);
        int done_at   = t.issue_cycle + t.ctrl.latency;
        if (pipelined && done_at <= b.cycle) continue;                         // response still expected
        if (pipelined && done_at > b.cycle) begin dead.push_back(k); n_killed_flush++; continue; end
        t.flush_ambiguous = 1; t.rsp_cycle = b.cycle;
      end
    end
    foreach (dead[i]) begin
      if (oracle != null && inflight[dead[i]].spike_valid) oracle.retire(unit);
      pending_brinfo.delete(dead[i]);
      await_flags.delete(dead[i]);
      inflight.delete(dead[i]);
    end
  endfunction

  //--------------------------------------------------------------- Spike second opinion
  // Data: Spike's rd value must equal the writeback (CSR instructions excepted: their rd is the
  // CSRFile's read data, checked by boom_spike_csr_checker on the CSR port).
  function void spike_check_data(boom_exe_txn t, bit [63:0] got);
    bit ok;
    if (oracle == null || !t.spike_valid || !t.spike_has_rd || t.ctrl.fu_code == FU_CSR) return;
    oracle.n_data_chk++;
    ok = (got === t.spike_rd_val);
    if (!ok && !cfg.strict_nan_payload && t.is_fp() && both_nan(got, t.spike_rd_val, t.is_single())) ok = 1;
    if (!ok) begin
      oracle.n_data_err++;
      `uvm_error("SPIKE", $sformatf("%s DATA vs SPIKE trace #%0d %s rob=%0d rs1=%016h rs2=%016h rs3=%016h imm=%08h: got %016h, Spike %016h (SoftFloat/ALU model said %016h)",
                 unit.name(), t.spike_idx, t.op.name(), t.rob_idx, t.rs1, t.rs2, t.rs3, t.imm, got, t.spike_rd_val, t.exp_data))
    end
  endfunction

  // Flags: Spike logs the fflags accumulator, the DUT reports per-instruction flags, so
  // (acc_before | flags) must equal acc_after. Bits already set before the instruction cannot be
  // attributed, which is why the per-op SoftFloat check above stays the primary one.
  function void spike_check_flags(boom_exe_txn t, bit [4:0] got);
    bit [4:0] acc, exp_acc;
    if (oracle == null || !t.spike_valid || !t.exp_flags_valid) return;
    acc = t.spike_fl_before | got; exp_acc = t.spike_fl_after;
    if (t.waived_nv) begin acc[4] = 0; exp_acc[4] = 0; end
    oracle.n_flag_chk++;
    if (acc !== exp_acc) begin
      oracle.n_flag_err++;
      `uvm_error("SPIKE", $sformatf("%s FFLAGS vs SPIKE trace #%0d %s rob=%0d: acc %05b | dut %05b = %05b, Spike acc after = %05b",
                 unit.name(), t.spike_idx, t.op.name(), t.rob_idx, t.spike_fl_before, got, acc, t.spike_fl_after))
    end
  endfunction

  // Control flow: taken iff Spike's next pc is not the fall-through; JALR target must be Spike's next pc
  function void spike_check_branch(boom_exe_txn t, boom_brinfo_rsp br);
    bit exp_taken;
    bit [63:0] fallthrough = {{24{t.pc[39]}}, t.pc} + (t.is_rvc ? 64'd2 : 64'd4);
    if (oracle == null || !t.spike_valid) return;
    exp_taken = (t.spike_next_pc != fallthrough);
    oracle.n_br_chk++;
    if (br.taken !== exp_taken || (t.ctrl.is_jalr && exp_taken && br.jalr_target !== (ref_model.encode_vaddr(t.spike_next_pc) & ~40'h1))) begin
      oracle.n_br_err++;
      `uvm_error("SPIKE", $sformatf("%s BRANCH vs SPIKE trace #%0d %s rob=%0d pc=%010h: taken=%0b jalr_tgt=%010h, Spike next pc %016h (taken=%0b)",
                 unit.name(), t.spike_idx, t.op.name(), t.rob_idx, t.pc, br.taken, br.jalr_target, t.spike_next_pc, exp_taken))
    end
  endfunction

  //--------------------------------------------------------------- response
  function void write_rsp(boom_exe_rsp r);
    boom_exe_txn t;
    n_rsp++;
    if (!inflight.exists(r.uop.rob_idx)) begin
      n_unexpected++;
      `uvm_error("SB", $sformatf("%s unexpected response (squashed or never issued): %s", unit.name(), r.convert2string()))
      return;
    end
    t = inflight[r.uop.rob_idx];
    inflight.delete(r.uop.rob_idx);
    t.rsp_port = r.port; t.rsp_data = r.data; t.rsp_cycle = r.cycle; t.rsp_flags_valid = r.flags_valid; t.rsp_flags = r.flags;
    if (t.flush_ambiguous) n_ambiguous++;
    if (oracle != null && t.spike_valid) begin oracle.retire(unit); spike_check_data(t, r.data); end
    // port
    if (r.port != t.exp_port) begin
      n_port_err++;
      `uvm_error("SB", $sformatf("%s %s rob=%0d responded on %s, expected %s", unit.name(), t.op.name(), t.rob_idx, r.port.name(), t.exp_port.name()))
    end
    // latency (fixed-latency ports only; ll_* ports depend on the ready model)
    if (t.ctrl.latency > 0 && r.port inside {PORT_IRESP, PORT_FRESP} && (r.cycle - t.issue_cycle) != t.ctrl.latency) begin
      n_lat_err++;
      `uvm_error("SB", $sformatf("%s %s rob=%0d latency %0d, expected %0d", unit.name(), t.op.name(), t.rob_idx, r.cycle - t.issue_cycle, t.ctrl.latency))
    end
    // pdst / dst_rtype must travel with the result
    if (r.uop.pdst != t.pdst || r.uop.dst_rtype != t.ctrl.dst_rtype)
      `uvm_error("SB", $sformatf("%s %s rob=%0d pdst/rtype corrupted: got %0d/%0d exp %0d/%0d", unit.name(), t.op.name(), t.rob_idx, r.uop.pdst, r.uop.dst_rtype, t.pdst, t.ctrl.dst_rtype))
    // data
    if (t.exp_has_data) begin
      bit ok = (r.data === t.exp_data);
      if (!ok && !cfg.strict_nan_payload && t.is_fp() && both_nan(r.data, t.exp_data, t.is_single())) ok = 1;
      if (!ok) begin
        n_data_err++;
        `uvm_error("SB", $sformatf("%s DATA MISMATCH %s rob=%0d rs1=%016h rs2=%016h rs3=%016h imm=%08h rm=%0d: got %016h expected %016h",
                   unit.name(), t.op.name(), t.rob_idx, t.rs1, t.rs2, t.rs3, t.imm, t.eff_rm(), r.data, t.exp_data))
      end else
        `uvm_info("SB", $sformatf("%s ok   %s rob=%0d -> %016h (%0d cyc)", unit.name(), t.op.name(), t.rob_idx, r.data, r.cycle - t.issue_cycle), UVM_HIGH)
    end
    // flags
    if (t.exp_flags_valid && cfg.check_fflags) begin
      if (r.flags_valid) check_flags(t, r.flags);
      else if (early_flags.exists(t.rob_idx)) begin check_flags(t, early_flags[t.rob_idx]); early_flags.delete(t.rob_idx); end
      else await_flags[t.rob_idx] = t;   // F2I: flags arrive on fresp.fflags (same cycle, published after)
    end
  endfunction

  function void check_flags(boom_exe_txn t, bit [4:0] got);
    n_flags++;
    spike_check_flags(t, got);
    if (got !== t.exp_flags) begin
      n_flag_err++;
      `uvm_error("SB", $sformatf("%s FFLAGS MISMATCH %s rob=%0d rs1=%016h rs2=%016h rs3=%016h rm=%0d: got NV%0b DZ%0b OF%0b UF%0b NX%0b expected NV%0b DZ%0b OF%0b UF%0b NX%0b",
                 unit.name(), t.op.name(), t.rob_idx, t.rs1, t.rs2, t.rs3, t.eff_rm(),
                 got[4], got[3], got[2], got[1], got[0], t.exp_flags[4], t.exp_flags[3], t.exp_flags[2], t.exp_flags[1], t.exp_flags[0]))
    end
  endfunction

  function void write_fflags(boom_exe_rsp f);
    if (await_flags.exists(f.uop.rob_idx)) begin
      check_flags(await_flags[f.uop.rob_idx], f.flags);
      await_flags.delete(f.uop.rob_idx);
    end else if (inflight.exists(f.uop.rob_idx) && inflight[f.uop.rob_idx].exp_port == PORT_LL_IRESP) begin
      early_flags[f.uop.rob_idx] = f.flags;   // data still waiting for ll_iresp_ready
    end
    // flags with a matching fresp are checked in write_rsp (they arrive in the same rsp item)
  endfunction

  //--------------------------------------------------------------- bypass
  function void write_bypass(boom_exe_rsp b);
    if (!cfg.check_bypass || last_req == null) return;
    if (b.uop.rob_idx != last_req.rob_idx) return;
    n_bypass++;
    if (last_req.exp_has_data && last_req.ctrl.fu_code inside {FU_ALU, FU_JMP, FU_CSR} && b.data !== last_req.exp_data) begin
      n_bypass_err++;
      `uvm_error("SB", $sformatf("%s BYPASS MISMATCH %s rob=%0d: bypass[0]=%016h expected %016h", unit.name(), last_req.op.name(), last_req.rob_idx, b.data, last_req.exp_data))
    end
  endfunction

  //--------------------------------------------------------------- branch info
  function void write_brinfo(boom_brinfo_rsp br);
    boom_exe_txn t;
    if (!cfg.check_brinfo) return;
    if (!pending_brinfo.exists(br.rob_idx)) begin
      if (last_req != null && last_req.rob_idx == br.rob_idx && last_req.killed_same_cycle)
        `uvm_error("SB", $sformatf("%s brinfo for a uop killed in its issue cycle: %s", unit.name(), br.convert2string()))
      else
        `uvm_error("SB", $sformatf("%s unexpected brinfo: %s", unit.name(), br.convert2string()));
      n_brinfo_err++;
      return;
    end
    t = pending_brinfo[br.rob_idx];
    pending_brinfo.delete(br.rob_idx);
    n_brinfo++;
    spike_check_branch(t, br);
    if (br.mispredict !== t.exp_mispredict || br.taken !== t.exp_taken || br.pc_sel !== t.exp_pc_sel || br.cfi_type !== t.exp_cfi_type ||
        br.target_offset !== t.exp_target_offset || (t.ctrl.is_jalr && br.jalr_target !== t.exp_jalr_target)) begin
      n_brinfo_err++;
      `uvm_error("SB", $sformatf("%s BRINFO MISMATCH %s rob=%0d rs1=%016h rs2=%016h pred_taken=%0b: got mispred=%0b taken=%0b pc_sel=%0d cfi=%0d off=%06h tgt=%010h | exp mispred=%0b taken=%0b pc_sel=%0d cfi=%0d off=%06h tgt=%010h",
                 unit.name(), t.op.name(), t.rob_idx, t.rs1, t.rs2, t.pred_taken,
                 br.mispredict, br.taken, br.pc_sel, br.cfi_type, br.target_offset, br.jalr_target,
                 t.exp_mispredict, t.exp_taken, t.exp_pc_sel, t.exp_cfi_type, t.exp_target_offset, t.exp_jalr_target))
    end
  endfunction

  //--------------------------------------------------------------- watchdog
  task run_phase(uvm_phase phase);
    forever begin
      #(CLK_PERIOD * 50);
      foreach (inflight[k]) begin
        boom_exe_txn t = inflight[k];
        if (!t.flush_ambiguous && (cur_cycle() - t.issue_cycle) > cfg.resp_timeout_cycles) begin
          n_missing++;
          `uvm_error("SB", $sformatf("%s MISSING RESPONSE %s rob=%0d issued @%0d (%0d cycles ago)", unit.name(), t.op.name(), k, t.issue_cycle, cur_cycle() - t.issue_cycle))
          if (oracle != null && t.spike_valid) oracle.retire(unit);
          inflight.delete(k);
        end
      end
      foreach (pending_brinfo[k]) begin
        if (cur_cycle() - pending_brinfo[k].issue_cycle > 2) begin
          n_brinfo_err++;
          `uvm_error("SB", $sformatf("%s MISSING BRINFO %s rob=%0d", unit.name(), pending_brinfo[k].op.name(), k))
          pending_brinfo.delete(k);
        end
      end
    end
  endtask

  function void check_phase(uvm_phase phase);
    purge_ambiguous(cur_cycle() + 1);
    foreach (inflight[k]) begin
      n_missing++;
      `uvm_error("SB", $sformatf("%s end of test: %s rob=%0d never responded", unit.name(), inflight[k].op.name(), k))
    end
    foreach (await_flags[k]) begin
      n_flag_err++;
      `uvm_error("SB", $sformatf("%s end of test: %s rob=%0d never reported fflags", unit.name(), await_flags[k].op.name(), k))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("\n  [%s] req=%0d rsp=%0d killed(br)=%0d killed(flush)=%0d flush-ambiguous=%0d brinfo=%0d bypass=%0d fflags=%0d\n  [%s] errors: data=%0d flags=%0d port=%0d latency=%0d unexpected=%0d missing=%0d brinfo=%0d bypass=%0d",
              unit.name(), n_req, n_rsp, n_killed_br, n_killed_flush, n_ambiguous, n_brinfo, n_bypass, n_flags,
              unit.name(), n_data_err, n_flag_err, n_port_err, n_lat_err, n_unexpected, n_missing, n_brinfo_err, n_bypass_err), UVM_LOW)
  endfunction
endclass : boom_exe_scoreboard

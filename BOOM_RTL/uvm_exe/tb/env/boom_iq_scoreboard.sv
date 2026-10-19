//=============================================================================
// boom_iq_scoreboard.sv — reference model + checker for the int issue queue
//-----------------------------------------------------------------------------
// Mirrors IssueSlot / IssueUnitCollapsing at transaction level:
//   * a dispatched uop enters the model with its busy bits
//   * wakeups (registered: effective next cycle) clear busy bits
//   * speculative load wakeups clear a bit but "poison" it for one cycle;
//     ld_miss in that cycle re-sets the bit and squashes any grant of that cycle
//   * branch mispredict / flush remove entries
// Checks on every issue-port sample:
//   C1 an issued uop exists in the model and is ready (all operands woken)
//   C2 age order: no older ready uop that the same port could serve was left behind
//   C3 a uop is issued exactly once (squashed ld-miss grants excepted)
//   C4 every dispatched uop that is not squashed eventually issues (end of test / timeout)
//   C5 occupancy never exceeds 20 entries
//=============================================================================
`uvm_analysis_imp_decl(_iq_stim)
`uvm_analysis_imp_decl(_iq_iss)

class boom_iq_entry;
  bit [5:0]  rob_idx;
  bit [9:0]  fu_code;
  bit [6:0]  prs1, prs2, prs3;
  bit        p1, p2, p3;           // operand ready
  bit        p1_poison, p2_poison; // woken speculatively this cycle
  bit [11:0] br_mask;
  int        age;                  // dispatch order (monotonic)
  int        dispatch_cycle;
  int        ready_cycle;          // first cycle the uop was ready to issue
  function bit ready(); return p1 && p2 && p3; endfunction
endclass

class boom_iq_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(boom_iq_scoreboard)
  uvm_analysis_imp_iq_stim #(boom_iq_txn,   boom_iq_scoreboard) stim_imp;
  uvm_analysis_imp_iq_iss  #(boom_iq_issue, boom_iq_scoreboard) iss_imp;

  boom_exe_cfg  cfg;
  boom_iq_entry q[$];              // oldest first
  int           age_ctr;
  int           last_cycle = -1;
  // wakeups take effect the cycle after they are seen (slot p1/p2 are registers)
  bit [6:0]     pend_wakeup[$];
  bit [6:0]     pend_spec[$];
  bit           squash_next;       // ld_miss seen this cycle applies to poisoned bits set last cycle

  int unsigned n_dispatch, n_issue, n_squashed_grant, n_killed, n_flushed, n_err_unknown, n_err_notready, n_err_age, n_err_double, n_err_lost, n_err_cap, max_occ;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    stim_imp = new("stim_imp", this); iss_imp = new("iss_imp", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
  endfunction

  //---------------------------------------------------------------- cycle boundary
  // Issue samples arrive every cycle (after the stimulus of the same cycle). We use them
  // as the cycle tick: apply last cycle's wakeups before evaluating this cycle's issues.
  function void advance_to(int cycle);
    if (cycle == last_cycle) return;
    last_cycle = cycle;
    // registered effects of the previous cycle
    foreach (pend_wakeup[i]) foreach (q[j]) begin
      if (q[j].prs1 == pend_wakeup[i]) q[j].p1 = 1;
      if (q[j].prs2 == pend_wakeup[i]) q[j].p2 = 1;
      if (q[j].prs3 == pend_wakeup[i]) q[j].p3 = 1;
    end
    pend_wakeup.delete();
    foreach (q[j]) begin q[j].p1_poison = 0; q[j].p2_poison = 0; end
    foreach (pend_spec[i]) foreach (q[j]) begin
      if (q[j].prs1 == pend_spec[i] && q[j].prs1 != 0) begin q[j].p1 = 1; q[j].p1_poison = 1; end
      if (q[j].prs2 == pend_spec[i] && q[j].prs2 != 0) begin q[j].p2 = 1; q[j].p2_poison = 1; end
    end
    pend_spec.delete();
    foreach (q[j]) if (q[j].ready() && q[j].ready_cycle < 0) q[j].ready_cycle = cycle;
  endfunction

  //---------------------------------------------------------------- stimulus
  function void write_iq_stim(boom_iq_txn s);
    advance_to(s.cycle);
    foreach (s.dis_fire[i]) if (s.dis_fire[i]) begin
      boom_iq_entry e = new();
      boom_iq_uop u = s.dis_uop[i];
      e.rob_idx = u.rob_idx; e.fu_code = u.fu_code; e.prs1 = u.prs1; e.prs2 = u.prs2; e.prs3 = u.prs3;
      e.p1 = !u.prs1_busy; e.p2 = !u.prs2_busy; e.p3 = !u.prs3_busy; e.br_mask = u.br_mask;
      e.age = age_ctr++; e.dispatch_cycle = s.cycle; e.ready_cycle = -1;
      // wakeups broadcast in the dispatch cycle also hit the dispatching uop (slot samples next_uop)
      q.push_back(e);
      n_dispatch++;
      if (q.size() > max_occ) max_occ = q.size();
      if (q.size() > IQ_INT_ENTRIES) begin n_err_cap++; `uvm_error("IQSB", $sformatf("occupancy %0d exceeds %0d entries", q.size(), IQ_INT_ENTRIES)) end
    end
    foreach (s.wakeup_valid[i]) if (s.wakeup_valid[i]) pend_wakeup.push_back(s.wakeup_pdst[i]);
    if (s.spec_ld_valid) pend_spec.push_back(s.spec_ld_pdst);
  endfunction

  //---------------------------------------------------------------- issue ports
  function void write_iq_iss(boom_iq_issue is);
    int idx[$];
    bit issued_this_cycle[$];
    advance_to(is.cycle);
    // ld_miss: any operand woken speculatively last cycle (poisoned now) goes busy again,
    // and a grant this cycle for such a uop is squashed (the uop stays in the queue)
    if (is.ld_miss) foreach (q[j]) begin
      if (q[j].p1_poison) q[j].p1 = 0;
      if (q[j].p2_poison) q[j].p2 = 0;
    end
    // issues
    for (int w = 0; w < IQ_ISSUE_W; w++) if (is.iss_valid[w]) begin
      uop_t u = is.iss_uop[w];
      bit squashed = is.ld_miss && (u.iw_p1_poisoned || u.iw_p2_poisoned);
      idx = q.find_index with (item.rob_idx == u.rob_idx);
      if (idx.size() == 0) begin
        n_err_unknown++;
        `uvm_error("IQSB", $sformatf("port %0d issued rob=%0d which is not in the queue model @%0d", w, u.rob_idx, is.cycle))
        continue;
      end
      begin
        boom_iq_entry e = q[idx[0]];
        bit ready_now = (e.p1 || e.p1_poison) && (e.p2 || e.p2_poison) && e.p3;
        if (!ready_now) begin
          n_err_notready++;
          `uvm_error("IQSB", $sformatf("port %0d issued rob=%0d with operands not ready (p1=%0b p2=%0b p3=%0b) @%0d", w, u.rob_idx, e.p1, e.p2, e.p3, is.cycle))
        end
        // age order: every older ready uop that this port could have served must issue this cycle too
        foreach (q[j]) begin
          if (q[j].age < e.age && q[j].ready() && q[j].dispatch_cycle < is.cycle && ((q[j].fu_code & is.fu_types[w]) != 0)) begin
            bit older_issued = 0;
            for (int v = 0; v < IQ_ISSUE_W; v++) if (is.iss_valid[v] && is.iss_uop[v].rob_idx == q[j].rob_idx) older_issued = 1;
            if (!older_issued) begin
              n_err_age++;
              `uvm_error("IQSB", $sformatf("age-order violation: port %0d issued rob=%0d (age %0d) while older ready rob=%0d (age %0d, fu=%03h) waited @%0d",
                         w, u.rob_idx, e.age, q[j].rob_idx, q[j].age, q[j].fu_code, is.cycle))
            end
          end
        end
        if (squashed) begin
          n_squashed_grant++;
          `uvm_info("IQSB", $sformatf("grant of rob=%0d squashed by ld_miss @%0d (stays queued)", u.rob_idx, is.cycle), UVM_MEDIUM)
        end else begin
          n_issue++;
          q.delete(idx[0]);
          `uvm_info("IQSB", $sformatf("issued rob=%0d on port %0d, waited %0d cycles after ready", u.rob_idx, w, is.cycle - e.ready_cycle), UVM_HIGH)
        end
      end
    end
    // branch kills / resolves / flush (seen in the same cycle; the slot state changes next cycle,
    // which is exactly when our next evaluation happens)
    if (is.flush) begin
      n_flushed += q.size(); q.delete();
    end else begin
      int dead[$];
      foreach (q[j]) begin
        if ((q[j].br_mask & is.mispredict_mask) != 0) dead.push_back(j);
        else q[j].br_mask &= ~is.resolve_mask;
      end
      for (int k = dead.size() - 1; k >= 0; k--) begin q.delete(dead[k]); n_killed++; end
    end
    // C4: starvation watchdog
    foreach (q[j]) if (q[j].ready() && q[j].ready_cycle >= 0 && (is.cycle - q[j].ready_cycle) > 64) begin
      n_err_lost++;
      `uvm_error("IQSB", $sformatf("rob=%0d ready since cycle %0d never issued (fu=%03h, fu_types=%03h/%03h)", q[j].rob_idx, q[j].ready_cycle, q[j].fu_code, is.fu_types[0], is.fu_types[1]))
      q[j].ready_cycle = is.cycle; // report once per 64 cycles
    end
  endfunction

  function void check_phase(uvm_phase phase);
    foreach (q[j]) if (q[j].ready()) begin
      n_err_lost++;
      `uvm_error("IQSB", $sformatf("end of test: rob=%0d dispatched @%0d is ready but was never issued", q[j].rob_idx, q[j].dispatch_cycle))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("IQSB", $sformatf("\n  [IQ] dispatched=%0d issued=%0d squashed-grants=%0d killed(br)=%0d flushed=%0d max-occupancy=%0d\n  [IQ] errors: unknown=%0d not-ready=%0d age=%0d lost=%0d capacity=%0d",
              n_dispatch, n_issue, n_squashed_grant, n_killed, n_flushed, max_occ, n_err_unknown, n_err_notready, n_err_age, n_err_lost, n_err_cap), UVM_LOW)
  endfunction
endclass : boom_iq_scoreboard


//=============================================================================
// boom_iq_coverage — issue-queue functional coverage (cg23..cg26)
//=============================================================================
`uvm_analysis_imp_decl(_iqcov_stim)
`uvm_analysis_imp_decl(_iqcov_iss)
class boom_iq_coverage extends uvm_component;
  `uvm_component_utils(boom_iq_coverage)
  uvm_analysis_imp_iqcov_stim #(boom_iq_txn,   boom_iq_coverage) stim_imp;
  uvm_analysis_imp_iqcov_iss  #(boom_iq_issue, boom_iq_coverage) iss_imp;
  int occupancy, n_iss, dis_cnt, wk_cnt;
  bit dual, port0_div_masked, spec, ldmiss, killed_any, flush;
  bit [9:0] iss_fu[2];
  boom_iq_txn   s;
  boom_iq_issue is;

  covergroup cg23_iq_occupancy;
    option.per_instance = 1;
    cp_occ: coverpoint occupancy { bins empty={0}; bins low={[1:5]}; bins mid={[6:14]}; bins high={[15:19]}; bins full={20}; }
    cp_dis: coverpoint dis_cnt { bins none={0}; bins one={1}; bins two={2}; }
    cp_iss: coverpoint n_iss { bins none={0}; bins one={1}; bins two={2}; }
    x_occ_dis: cross cp_occ, cp_dis;
    x_occ_iss: cross cp_occ, cp_iss;
  endgroup
  covergroup cg24_iq_wakeup;
    option.per_instance = 1;
    cp_wk: coverpoint wk_cnt { bins n[] = {[0:5]}; }
    cp_spec: coverpoint spec;
    cp_ldmiss: coverpoint ldmiss;
    x_spec_miss: cross cp_spec, cp_ldmiss;
  endgroup
  covergroup cg25_iq_issue;
    option.per_instance = 1;
    cp_fu0: coverpoint iss_fu[0] iff (is.iss_valid[0]) { bins alu={FU_ALU}; bins jmp={FU_JMP}; bins mul={FU_MUL}; bins csr={FU_CSR}; bins div={FU_DIV}; }
    cp_fu1: coverpoint iss_fu[1] iff (is.iss_valid[1]) { bins alu={FU_ALU}; bins jmp={FU_JMP}; bins mul={FU_MUL}; bins csr={FU_CSR}; bins div={FU_DIV}; }
    cp_dual: coverpoint dual;
    cp_div_masked: coverpoint port0_div_masked;   // fu_types[1] without DIV while a DIV uop is queued
    x_dual: cross cp_fu0, cp_fu1;
  endgroup
  covergroup cg26_iq_kill;
    option.per_instance = 1;
    cp_kill: coverpoint killed_any;
    cp_flush: coverpoint flush;
    cp_occ: coverpoint occupancy { bins empty={0}; bins some={[1:10]}; bins many={[11:20]}; }
    x_kill_occ: cross cp_kill, cp_occ;
    x_flush_occ: cross cp_flush, cp_occ;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    stim_imp = new("stim_imp", this); iss_imp = new("iss_imp", this);
    cg23_iq_occupancy = new(); cg24_iq_wakeup = new(); cg25_iq_issue = new(); cg26_iq_kill = new();
  endfunction
  function void write_iqcov_stim(boom_iq_txn t);
    s = t; dis_cnt = 0; wk_cnt = 0;
    foreach (t.dis_fire[i]) dis_cnt += t.dis_fire[i];
    foreach (t.wakeup_valid[i]) wk_cnt += t.wakeup_valid[i];
    spec = t.spec_ld_valid; ldmiss = t.ld_miss;
    occupancy += dis_cnt;
    cg24_iq_wakeup.sample();
  endfunction
  function void write_iqcov_iss(boom_iq_issue i);
    is = i; n_iss = 0;
    for (int w = 0; w < 2; w++) begin n_iss += i.iss_valid[w]; iss_fu[w] = i.iss_uop[w].fu_code; end
    dual = i.iss_valid[0] && i.iss_valid[1];
    port0_div_masked = !i.fu_types[1][4];
    killed_any = (i.mispredict_mask != 0); flush = i.flush;
    cg23_iq_occupancy.sample(); cg25_iq_issue.sample(); cg26_iq_kill.sample();
    occupancy -= n_iss; if (occupancy < 0) occupancy = 0;
    if (flush) occupancy = 0;
    dis_cnt = 0;
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("\n  IQ coverage: occupancy %.1f%% wakeup %.1f%% issue %.1f%% kill %.1f%%",
      cg23_iq_occupancy.get_inst_coverage(), cg24_iq_wakeup.get_inst_coverage(), cg25_iq_issue.get_inst_coverage(), cg26_iq_kill.get_inst_coverage()), UVM_LOW)
  endfunction
endclass : boom_iq_coverage

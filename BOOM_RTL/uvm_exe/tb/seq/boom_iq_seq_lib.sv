//=============================================================================
// boom_iq_seq_lib.sv — sequence library for the integer issue queue
//-----------------------------------------------------------------------------
// The base sequence is a small "rest of the core" model: it hands out physical
// registers, remembers which ones it promised to wake up, and later produces
// the wakeups (regular or speculative-load + optional ld_miss). Everything the
// scoreboard needs is observed on the interface, so the sequence only has to
// be *plausible*, not exact.
//=============================================================================
class boom_iq_base_seq extends uvm_sequence #(boom_iq_txn);
  `uvm_object_utils(boom_iq_base_seq)
  `uvm_declare_p_sequencer(boom_exe_vsequencer)

  // knobs
  int unsigned n_cycles     = 300;   // stimulus cycles (drain cycles are added on top)
  int unsigned dispatch_pct = 60;    // % of cycles with at least one dispatch
  int unsigned dual_pct     = 40;    // % of dispatching cycles that use both ports
  int unsigned busy_pct     = 50;    // % of operands that are not ready at dispatch
  int unsigned wakeup_pct   = 50;    // % chance per cycle to wake up outstanding registers
  int unsigned max_wakeups  = 2;     // wakeups per cycle (<= 5)
  int unsigned spec_pct     = 0;     // % of wake events done through the speculative-load port
  int unsigned ld_miss_pct  = 50;    // % of speculative wakeups followed by ld_miss
  int unsigned fu_random_pct= 0;     // % of cycles in which fu_types of the ports change
  bit [11:0]   live_mask    = 12'h000;
  int unsigned tag_pct      = 0;     // % of uops carrying a branch mask
  bit [9:0]    fu_pool[$]   = '{FU_ALU, FU_ALU, FU_ALU, FU_JMP, FU_MUL, FU_DIV, FU_CSR};
  int unsigned drain_cycles = 120;

  // state
  bit [6:0]    outstanding[$];       // registers promised to wake up
  bit [6:0]    spec_pending;         // register woken speculatively last cycle (0 = none)
  bit [9:0]    cur_fu[IQ_ISSUE_W];
  static int   rob_ctr;

  function new(string name = "boom_iq_base_seq"); super.new(name); cur_fu[0] = 10'h10B; cur_fu[1] = 10'h031; endfunction

  //------------------------------------------------------------ helpers
  function bit [6:0] alloc_preg();
    bit [6:0] p;
    int guard = 0;
    do begin p = 7'($urandom_range(1, NUM_INT_PREGS - 1)); guard++; end
    while (outstanding.size() < NUM_INT_PREGS - 2 && (p inside {outstanding}) && guard < 200);
    return p;
  endfunction
  function bit [6:0] ready_preg();
    bit [6:0] p;
    int guard = 0;
    if ($urandom_range(7) == 0) return 0;              // x0-like: never busy
    do begin p = 7'($urandom_range(1, NUM_INT_PREGS - 1)); guard++; end
    while ((p inside {outstanding}) && guard < 200);
    return p;
  endfunction
  function bit [11:0] pick_mask();
    bit [11:0] m = '0;
    if (live_mask == 0 || $urandom_range(99) >= tag_pct) return '0;
    for (int i = 0; i < 12; i++) if (live_mask[i] && $urandom_range(2) == 0) m[i] = 1;
    if (m == 0) for (int i = 0; i < 12; i++) if (live_mask[i]) begin m[i] = 1; break; end
    return m;
  endfunction
  function void pick_fu_types();
    bit [9:0] p0[] = '{10'h10B, 10'h003, 10'h001, 10'h009, 10'h10B, 10'h00B};
    bit [9:0] p1[] = '{10'h031, 10'h021, 10'h001, 10'h011, 10'h031};
    cur_fu[0] = p0[$urandom_range(p0.size() - 1)];
    cur_fu[1] = p1[$urandom_range(p1.size() - 1)];
  endfunction

  virtual function void fill_uop(boom_iq_uop u);
    u.fu_code = fu_pool[$urandom_range(fu_pool.size() - 1)];
    u.rob_idx = 6'(rob_ctr); rob_ctr = (rob_ctr + 1) % 64;
    u.pdst = 7'($urandom_range(1, NUM_INT_PREGS - 1));
    u.prs1_busy = ($urandom_range(99) < busy_pct);
    u.prs2_busy = ($urandom_range(99) < busy_pct);
    u.prs3_busy = 0; u.prs3 = 0;
    if (u.prs1_busy) begin u.prs1 = alloc_preg(); outstanding.push_back(u.prs1); end else u.prs1 = ready_preg();
    if (u.prs2_busy) begin u.prs2 = alloc_preg(); outstanding.push_back(u.prs2); end else u.prs2 = ready_preg();
    u.br_mask = pick_mask(); u.br_tag = 0;
    u.is_br = (u.fu_code == FU_JMP) && $urandom_range(1); u.is_jal = 0; u.is_jalr = (u.fu_code == FU_JMP) && !u.is_br;
    u.lrs1_rtype = RT_FIX; u.lrs2_rtype = RT_FIX;
    case (u.fu_code)
      FU_MUL: u.uopc = uopMUL;
      FU_DIV: u.uopc = uopDIV;
      FU_CSR: u.uopc = uopCSRRW;
      FU_JMP: u.uopc = u.is_br ? uopBEQ : uopJALR;
      default: u.uopc = uopADD;
    endcase
  endfunction

  // one cycle of stimulus
  virtual function void fill_cycle(boom_iq_txn t, bit allow_dispatch);
    int nw;
    foreach (t.dis_valid[i]) t.dis_valid[i] = 0;
    foreach (t.wakeup_valid[i]) begin t.wakeup_valid[i] = 0; t.wakeup_pdst[i] = 7'($urandom_range(1, NUM_INT_PREGS - 1)); end
    t.spec_ld_valid = 0; t.spec_ld_pdst = 7'($urandom_range(1, NUM_INT_PREGS - 1)); t.ld_miss = 0;
    // ld_miss follows a speculative wakeup by exactly one cycle
    if (spec_pending != 0) begin
      if ($urandom_range(99) < ld_miss_pct) t.ld_miss = 1;              // register stays outstanding
      else begin int idx[$] = outstanding.find_index with (item == spec_pending); if (idx.size()) outstanding.delete(idx[0]); end
      spec_pending = 0;
    end
    // dispatch
    if (allow_dispatch && $urandom_range(99) < dispatch_pct) begin
      t.dis_valid[0] = 1; fill_uop(t.dis_uop[0]);
      if ($urandom_range(99) < dual_pct) begin t.dis_valid[1] = 1; fill_uop(t.dis_uop[1]); end
    end
    // wakeups
    if (outstanding.size() > 0 && $urandom_range(99) < wakeup_pct) begin
      nw = $urandom_range(1, max_wakeups);
      for (int k = 0; k < nw && outstanding.size() > 0; k++) begin
        int pick = $urandom_range(outstanding.size() - 1);
        bit [6:0] p = outstanding[pick];
        if (k == 0 && spec_pct > 0 && $urandom_range(99) < spec_pct && !t.ld_miss) begin
          t.spec_ld_valid = 1; t.spec_ld_pdst = p; spec_pending = p;   // resolved next cycle
        end else begin
          t.wakeup_valid[k] = 1; t.wakeup_pdst[k] = p;
          outstanding.delete(pick);
        end
      end
    end
    if ($urandom_range(99) < fu_random_pct) pick_fu_types();
    t.fu_types[0] = cur_fu[0]; t.fu_types[1] = cur_fu[1];
  endfunction

  virtual task send_cycle(bit allow_dispatch);
    boom_iq_txn t = boom_iq_txn::type_id::create("iq_t");
    start_item(t, -1, p_sequencer.iq_sqr);
    fill_cycle(t, allow_dispatch);
    finish_item(t);
  endtask

  // wake up everything still outstanding and give the queue time to empty
  virtual task drain();
    int guard = 0;
    while ((outstanding.size() > 0 || spec_pending != 0) && guard++ < 400) begin
      boom_iq_txn t = boom_iq_txn::type_id::create("iq_drain");
      start_item(t, -1, p_sequencer.iq_sqr);
      fill_cycle(t, 0);
      // force progress: regular wakeups for up to 5 registers
      foreach (t.wakeup_valid[i]) if (!t.wakeup_valid[i] && outstanding.size() > 0) begin
        t.wakeup_valid[i] = 1; t.wakeup_pdst[i] = outstanding.pop_front();
      end
      t.spec_ld_valid = 0;
      finish_item(t);
    end
    cur_fu[0] = 10'h10B; cur_fu[1] = 10'h031;      // every op class accepted somewhere
    for (int i = 0; i < drain_cycles; i++) begin
      boom_iq_txn t = boom_iq_txn::type_id::create("iq_idle");
      start_item(t, -1, p_sequencer.iq_sqr);
      fill_cycle(t, 0);
      t.ld_miss = 0; t.spec_ld_valid = 0;
      finish_item(t);
    end
  endtask

  virtual task body();
    for (int i = 0; i < n_cycles; i++) send_cycle(1);
    drain();
  endtask
endclass : boom_iq_base_seq

//-----------------------------------------------------------------------------
// fill the queue to capacity (dispatch stalls on dis_ready), then drain it
//-----------------------------------------------------------------------------
class iq_fill_drain_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_fill_drain_seq)
  function new(string name = "iq_fill_drain_seq"); super.new(name);
    dispatch_pct = 100; dual_pct = 100; busy_pct = 100; wakeup_pct = 0; endfunction
  virtual task body();
    repeat (3) begin
      for (int i = 0; i < 14; i++) send_cycle(1);   // 28 uops offered into 20 slots: driver holds until ready
      wakeup_pct = 100; max_wakeups = 1;
      for (int i = 0; i < 40; i++) send_cycle(0);
      wakeup_pct = 0;
    end
    drain();
  endtask
endclass

//-----------------------------------------------------------------------------
// age order: only port 0 accepts MUL, two MULs dispatched per cycle -> backlog
//-----------------------------------------------------------------------------
class iq_age_order_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_age_order_seq)
  function new(string name = "iq_age_order_seq"); super.new(name);
    dispatch_pct = 100; dual_pct = 100; busy_pct = 0; fu_pool = '{FU_MUL, FU_MUL, FU_MUL, FU_ALU}; n_cycles = 60; endfunction
endclass

//-----------------------------------------------------------------------------
// both ports every cycle: all-ready ALU uops, dual dispatch
//-----------------------------------------------------------------------------
class iq_dual_issue_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_dual_issue_seq)
  function new(string name = "iq_dual_issue_seq"); super.new(name);
    dispatch_pct = 100; dual_pct = 100; busy_pct = 0; fu_pool = '{FU_ALU}; n_cycles = 200; endfunction
endclass

//-----------------------------------------------------------------------------
// speculative load wakeups with ld_miss squashes
//-----------------------------------------------------------------------------
class iq_spec_load_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_spec_load_seq)
  function new(string name = "iq_spec_load_seq"); super.new(name);
    busy_pct = 80; wakeup_pct = 70; spec_pct = 70; ld_miss_pct = 50; max_wakeups = 1; endfunction
endclass

class iq_ld_miss_storm_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_ld_miss_storm_seq)
  function new(string name = "iq_ld_miss_storm_seq"); super.new(name);
    busy_pct = 100; wakeup_pct = 100; spec_pct = 100; ld_miss_pct = 90; max_wakeups = 1; n_cycles = 200; endfunction
endclass

//-----------------------------------------------------------------------------
// wakeup storm: many busy operands, up to five wakeups per cycle
//-----------------------------------------------------------------------------
class iq_wakeup_storm_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_wakeup_storm_seq)
  function new(string name = "iq_wakeup_storm_seq"); super.new(name);
    busy_pct = 100; wakeup_pct = 100; max_wakeups = 5; dispatch_pct = 90; dual_pct = 80; endfunction
endclass

//-----------------------------------------------------------------------------
// fu_types masking: the units keep changing what they accept
//-----------------------------------------------------------------------------
class iq_fu_mask_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_fu_mask_seq)
  function new(string name = "iq_fu_mask_seq"); super.new(name);
    fu_random_pct = 40; fu_pool = '{FU_ALU, FU_MUL, FU_DIV, FU_CSR, FU_JMP}; busy_pct = 30; endfunction
endclass

//-----------------------------------------------------------------------------
// branch-tagged uops (paired with brupd sequences in the test)
//-----------------------------------------------------------------------------
class iq_branch_kill_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_branch_kill_seq)
  function new(string name = "iq_branch_kill_seq"); super.new(name);
    live_mask = 12'h0FF; tag_pct = 70; busy_pct = 60; wakeup_pct = 40; endfunction
endclass

//-----------------------------------------------------------------------------
// sparse traffic: one uop now and then (checks nothing is lost when idle)
//-----------------------------------------------------------------------------
class iq_sparse_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_sparse_seq)
  function new(string name = "iq_sparse_seq"); super.new(name);
    dispatch_pct = 10; dual_pct = 0; busy_pct = 50; wakeup_pct = 20; endfunction
endclass

//-----------------------------------------------------------------------------
// one-cycle-apart dispatch of a producer/consumer pair: consumer waits for the
// producer's pdst to be woken (dispatch-cycle wakeup hits next_uop)
//-----------------------------------------------------------------------------
class iq_same_cycle_wakeup_seq extends boom_iq_base_seq;
  `uvm_object_utils(iq_same_cycle_wakeup_seq)
  function new(string name = "iq_same_cycle_wakeup_seq"); super.new(name); busy_pct = 100; wakeup_pct = 0; endfunction
  virtual task body();
    for (int i = 0; i < 100; i++) begin
      boom_iq_txn t = boom_iq_txn::type_id::create("iq_t");
      start_item(t, -1, p_sequencer.iq_sqr);
      fill_cycle(t, 1);
      // wake one of the operands of a uop being dispatched *in this very cycle*
      if (t.dis_valid[0] && t.dis_uop[0].prs1_busy) begin
        int idx[$] = outstanding.find_index with (item == t.dis_uop[0].prs1);
        t.wakeup_valid[0] = 1; t.wakeup_pdst[0] = t.dis_uop[0].prs1;
        if (idx.size()) outstanding.delete(idx[0]);
      end
      finish_item(t);
    end
    drain();
  endtask
endclass

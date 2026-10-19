//=============================================================================
// boom_iq_txn.sv — one cycle of stimulus for the integer issue queue
//-----------------------------------------------------------------------------
// The issue queue has no "instruction" abstraction: what matters is which
// uops are dispatched, which physical registers wake up, what the execution
// units advertise, and when loads speculatively wake consumers. One item
// therefore describes one cycle on all those ports.
//=============================================================================
class boom_iq_uop extends uvm_object;
  `uvm_object_utils(boom_iq_uop)
  rand bit [5:0]  rob_idx;
  rand bit [9:0]  fu_code;        // one-hot: ALU/JMP/MUL/DIV/CSR
  rand bit [6:0]  pdst, prs1, prs2, prs3;
  rand bit        prs1_busy, prs2_busy, prs3_busy;
  rand bit [11:0] br_mask;
  rand bit [3:0]  br_tag;
  rand bit        is_br, is_jal, is_jalr;
  rand bit [1:0]  lrs1_rtype, lrs2_rtype;
  rand bit [6:0]  uopc;
  int             dispatch_cycle;
  constraint c_fu    { fu_code inside {FU_ALU, FU_JMP, FU_MUL, FU_DIV, FU_CSR}; }
  constraint c_regs  { pdst != 0; prs1 < NUM_INT_PREGS; prs2 < NUM_INT_PREGS; prs3 < NUM_INT_PREGS; pdst < NUM_INT_PREGS;
                       (prs1 == 0) -> !prs1_busy; (prs2 == 0) -> !prs2_busy; soft prs3_busy == 0; soft prs3 == 0; }
  constraint c_rtype { lrs1_rtype == RT_FIX; lrs2_rtype == RT_FIX; }
  constraint c_br    { (is_br + is_jal + is_jalr) <= 1; soft is_br dist {0 := 4, 1 := 1}; soft is_jal == 0; soft is_jalr == 0; }
  constraint c_uopc  { uopc inside {uopADD, uopSUB, uopAND, uopOR, uopXOR, uopSLL, uopSRL, uopSRA, uopSLT, uopSLTU,
                                    uopADDI, uopANDI, uopLUI, uopMUL, uopDIV, uopBEQ, uopJAL, uopJALR, uopCSRRW}; }
  constraint c_mask  { $countones(br_mask) <= 3; }
  function new(string name = "boom_iq_uop"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("rob=%0d fu=%03h pdst=%0d prs1=%0d%s prs2=%0d%s mask=%03h", rob_idx, fu_code, pdst,
                     prs1, prs1_busy ? "(busy)" : "", prs2, prs2_busy ? "(busy)" : "", br_mask);
  endfunction
endclass : boom_iq_uop

class boom_iq_txn extends uvm_sequence_item;
  `uvm_object_utils(boom_iq_txn)
  rand bit          dis_valid[IQ_DISPATCH_W];
  boom_iq_uop       dis_uop[IQ_DISPATCH_W];
  rand bit          wakeup_valid[IQ_WAKEUP_PORTS];
  rand bit [6:0]    wakeup_pdst[IQ_WAKEUP_PORTS];
  rand bit          spec_ld_valid;
  rand bit [6:0]    spec_ld_pdst;
  rand bit          ld_miss;
  rand bit [9:0]    fu_types[IQ_ISSUE_W];
  int               cycle;          // filled by driver/monitor
  bit               dis_fire[IQ_DISPATCH_W];   // monitor: dispatch accepted

  constraint c_fu_types { fu_types[0] inside {10'h00B, 10'h003, 10'h001, 10'h009}; fu_types[1] inside {10'h031, 10'h021, 10'h001, 10'h011}; }
  constraint c_wk       { foreach (wakeup_pdst[i]) { wakeup_pdst[i] != 0; wakeup_pdst[i] < NUM_INT_PREGS; } spec_ld_pdst != 0; spec_ld_pdst < NUM_INT_PREGS; }
  constraint c_default  { soft ld_miss == 0; soft spec_ld_valid == 0; }

  function new(string name = "boom_iq_txn");
    super.new(name);
    foreach (dis_uop[i]) dis_uop[i] = boom_iq_uop::type_id::create($sformatf("dis_uop%0d", i));
  endfunction
  function string convert2string();
    string s = $sformatf("@%0d fu_types=%03h/%03h", cycle, fu_types[0], fu_types[1]);
    foreach (dis_valid[i]) if (dis_valid[i]) s = {s, $sformatf(" DIS%0d[%s]", i, dis_uop[i].convert2string())};
    foreach (wakeup_valid[i]) if (wakeup_valid[i]) s = {s, $sformatf(" WK%0d=p%0d", i, wakeup_pdst[i])};
    if (spec_ld_valid) s = {s, $sformatf(" SPECWK=p%0d", spec_ld_pdst)};
    if (ld_miss) s = {s, " LD_MISS"};
    return s;
  endfunction
endclass : boom_iq_txn

// what the monitor saw on the issue ports in one cycle
class boom_iq_issue extends uvm_sequence_item;
  `uvm_object_utils(boom_iq_issue)
  bit        iss_valid[IQ_ISSUE_W];
  uop_t      iss_uop[IQ_ISSUE_W];
  bit [9:0]  fu_types[IQ_ISSUE_W];
  bit        ld_miss;
  bit [11:0] resolve_mask, mispredict_mask;
  bit        flush;
  int        cycle;
  function new(string name = "boom_iq_issue"); super.new(name); endfunction
endclass : boom_iq_issue

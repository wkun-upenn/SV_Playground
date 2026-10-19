//=============================================================================
// boom_exe_txn.sv — one instruction-level transaction for an execution unit
//-----------------------------------------------------------------------------
// A sequence produces the "instruction" view (op + operand values + imm/rm);
// the driver lowers it to a BOOM MicroOp (uop_t) and 65-bit recoded operands;
// the reference model fills in exp_*; the monitor fills in rsp_*.
//=============================================================================
class boom_exe_txn extends uvm_sequence_item;
  `uvm_object_utils(boom_exe_txn)

  //------------------------------------------------------------- stimulus
  rand exe_op_e      op;
  rand bit [63:0]    rs1, rs2, rs3;      // register images (IEEE for FP, NaN-boxed for S)
  rand bit [31:0]    imm;                // I/S/B: imm[11:0] (B: [12:1]), U: imm[31:12], J: imm[20:1]
  rand bit [2:0]     rm;                 // rounding mode field (RM_DYN allowed where legal)
  rand bit [2:0]     fcsr_rm;            // value of fcsr.frm presented with the op
  rand bit [4:0]     zimm;               // CSRRxI immediate (BOOM carries it in prs1[4:0])
  rand bit [11:0]    csr_addr;
  rand bit [39:0]    pc;                 // uop PC (jumps / branches / auipc)
  rand bit           pred_taken;         // uop.taken — front-end prediction for branches
  rand bit           is_rvc;             // compressed instruction (JAL/JALR link = pc+2)
  rand bit           edge_inst;          // 32-bit instruction whose first half sits in the previous fetch block
  // FTQ model inputs (JALR mispredict decision)
  rand bit           ftq_next_val;
  rand bit [39:0]    ftq_next_pc;
  rand bit           ftq_cfi_idx_valid;
  rand bit [1:0]     ftq_cfi_idx;
  rand bit           ftq_start_bank;
  // branch speculation tagging
  rand bit [11:0]    br_mask;
  rand bit [3:0]     br_tag;
  rand bit [5:0]     rob_idx;
  rand bit [6:0]     pdst;
  rand bit [4:0]     ftq_idx;
  // pacing / kill
  rand int unsigned  delay;              // idle cycles before the request
  rand bit           flush_with_req;     // assert io_req_bits_kill together with the request
  rand bit           deliberately_unboxed; // for S ops: feed a non-NaN-boxed rs1 (must read as qNaN)

  //------------------------------------------------------------- lowered (driver)
  op_ctrl_t          ctrl;
  uop_t              uop;
  bit [64:0]         rs1_rec, rs2_rec, rs3_rec;
  int                issue_cycle;

  //------------------------------------------------------------- expected (ref model)
  bit                exp_has_data;       // a writeback is expected on exp_port
  rsp_port_e         exp_port;
  bit [63:0]         exp_data;
  bit                exp_flags_valid;
  bit [4:0]          exp_flags;
  bit                exp_brinfo_valid, exp_mispredict, exp_taken;
  bit [1:0]          exp_pc_sel;
  bit [2:0]          exp_cfi_type;
  bit [39:0]         exp_jalr_target;
  bit [20:0]         exp_target_offset;

  //------------------------------------------------------------- second golden opinion (Spike trace replay)
  // Filled by boom_spike_trace_seq from a Spike commit log, attached to the monitor's copy by the
  // scoreboard via boom_spike_oracle. Independent of the SoftFloat/ALU reference model above.
  bit                spike_valid;
  int                spike_idx;          // index in the trace (for messages)
  bit                spike_has_rd;       // Spike logged an rd write (x0 excluded)
  bit [63:0]         spike_rd_val;
  bit [63:0]         spike_next_pc;      // pc of the next committed instruction (branch / jump outcome)
  bit [4:0]          spike_fl_before, spike_fl_after;   // fflags accumulator around the instruction
  bit                waived_nv;          // reference model dropped NV under waiver W1 -> Spike check does too

  //------------------------------------------------------------- observed (monitor / scoreboard)
  rsp_port_e         rsp_port;
  bit [63:0]         rsp_data;
  bit                rsp_flags_valid;
  bit [4:0]          rsp_flags;
  int                rsp_cycle;
  bit                killed;             // squashed by branch / flush (no response expected)
  bit                flush_ambiguous;    // completes in the flush cycle: response optional
  bit                killed_same_cycle;  // killed in the request cycle itself

  //------------------------------------------------------------- constraints
  constraint c_rm_legal {
    rm inside {RM_RNE, RM_RTZ, RM_RDN, RM_RUP, RM_RMM, RM_DYN};
    fcsr_rm inside {RM_RNE, RM_RTZ, RM_RDN, RM_RUP, RM_RMM};
  }
  constraint c_delay_default { soft delay inside {[0:3]}; }
  constraint c_flush_rare    { soft flush_with_req dist {0 := 97, 1 := 3}; }
  constraint c_unboxed_rare  { soft deliberately_unboxed dist {0 := 95, 1 := 5}; }
  constraint c_pc_aligned    { pc[0] == 1'b0; ftq_next_pc[0] == 1'b0; }
  constraint c_edge          { edge_inst -> !is_rvc; soft edge_inst dist {0 := 85, 1 := 15}; }
  constraint c_shift_imm     { (op inside {OP_SLLI, OP_SRLI, OP_SRAI}) -> imm[11:6] == 0;
                               (op inside {OP_SLLIW, OP_SRLIW, OP_SRAIW}) -> imm[11:5] == 0; }
  constraint c_br_mask_bits  { $countones(br_mask) <= 4; }
  constraint c_pdst_range    { pdst != 0; pdst < NUM_INT_PREGS; }
  constraint c_ftq_default   { soft ftq_next_val == 1; soft ftq_cfi_idx_valid == 1; }
  // CSR instructions only touch registers that exist and whose value does not change how the
  // rest of the environment behaves (never mstatus.FS, misa, satp, pmpcfg locks, debug CSRs)
  constraint c_csr_addr_safe { soft csr_addr inside {CSR_SAFE_ADDRS}; }
  // single-precision operands are NaN-boxed unless the test deliberately breaks it
  constraint c_nanbox {
    if (is_single_op(op) && !deliberately_unboxed) {
      (op inside {OP_FMV_W_X, OP_FCVT_S_W, OP_FCVT_S_WU, OP_FCVT_S_L, OP_FCVT_S_LU}) || rs1[63:32] == 32'hFFFF_FFFF;
      rs2[63:32] == 32'hFFFF_FFFF;
      rs3[63:32] == 32'hFFFF_FFFF;
    }
  }

  function new(string name = "boom_exe_txn");
    super.new(name);
  endfunction

  //------------------------------------------------------------- helpers
  function bit is_fp();        return is_fp_op(op); endfunction
  function bit is_single();    return is_single_op(op); endfunction
  function bit uses_rm_f();    return uses_rm(op); endfunction
  function bit [2:0] eff_rm(); // rounding mode the hardware will actually use
    logic [2:0] f = fixed_rm_of(op);
    if (f != 3'd7) return f;
    return (rm == RM_DYN) ? fcsr_rm : rm;
  endfunction
  function exu_id_e unit();    return decode_op(op).exu; endfunction

  //--------------------------------------------------------------- lowering
  // Build the MicroOp exactly the way BOOM's decode + register-read stages would
  // (used by the driver; the monitor reconstructs the txn independently from the uop).
  function void lower();
    op_ctrl_t c = decode_op(op);
    uop_t     u;
    logic [2:0] rmf;
    ctrl = c;
    u = '0;
    u.uopc         = c.uopc;
    u.fu_code      = c.fu_code;
    u.iq_type      = (c.exu == EXU_FPU) ? IQT_FP : IQT_INT;
    u.ctrl_br_type = c.br_type;
    u.ctrl_op1_sel = c.op1_sel;
    u.ctrl_op2_sel = c.op2_sel;
    u.ctrl_imm_sel = c.imm_sel;
    u.ctrl_op_fcn  = c.op_fcn;
    u.ctrl_fcn_dw  = c.fcn_dw;
    u.ctrl_csr_cmd = c.csr_cmd;
    u.iw_state     = 2'd1;
    u.is_br        = c.is_br;
    u.is_jal       = c.is_jal;
    u.is_jalr      = c.is_jalr;
    u.br_mask      = br_mask;
    u.br_tag       = br_tag;
    u.ftq_idx      = ftq_idx;
    // a straddling instruction is recorded by the *second* half's position: the front end reports
    // the block that holds pc+2, and the JMP unit reconstructs pc = (block | pc_lob) - 2
    u.pc_lob       = edge_inst ? 6'(pc[5:0] + 6'd2) : pc[5:0];
    u.edge_inst    = edge_inst;
    u.is_rvc       = is_rvc;
    u.taken        = pred_taken;
    u.rob_idx      = rob_idx;
    u.pdst         = pdst;
    u.prs1         = (c.op2_sel == OP2_IMMC) ? {2'b0, zimm} : 7'd1;
    u.prs2         = 7'd2;
    u.prs3         = 7'd3;
    u.dst_rtype    = c.dst_rtype;
    u.lrs1_rtype   = c.lrs1_rtype;
    u.lrs2_rtype   = c.lrs2_rtype;
    u.ldst_val     = (c.dst_rtype != RT_X);
    u.ldst         = 6'd5;
    u.frs3_en      = c.frs3_en;
    u.fp_val       = c.fp_val;
    u.fp_single    = c.fp_single;
    u.bypassable   = c.bypassable;
    u.debug_pc     = pc;
    // immediate / rm / typ packing
    if (is_fp_op(op)) begin
      rmf = fixed_rm_of(op);
      if (rmf == 3'd7) rmf = rm;
      u.imm_packed = pack_imm(IS_I, {30'b0, cvt_typ_of(op)}, {5'b0, rmf});
    end else if (c.fu_code == FU_CSR) begin
      u.imm_packed = pack_imm(IS_I, {20'b0, csr_addr});
      u.csr_addr   = csr_addr;
    end else begin
      u.imm_packed = pack_imm(imm_fmt_of(op), imm);
    end
    uop = u;
    // operands: FP register sources are recoded 65-bit values, integers are zero-extended
    rs1_rec = (c.lrs1_rtype == RT_FLT) ? fp_recode(rs1) : {1'b0, rs1};
    rs2_rec = (c.lrs2_rtype == RT_FLT) ? fp_recode(rs2) : {1'b0, rs2};
    rs3_rec = c.frs3_en ? fp_recode(rs3) : 65'b0;
  endfunction


  function string convert2string();
    string s;
    s = $sformatf("%-11s rob=%0d pdst=%0d rs1=%016h rs2=%016h", op.name(), rob_idx, pdst, rs1, rs2);
    if (ctrl.frs3_en) s = {s, $sformatf(" rs3=%016h", rs3)};
    if (ctrl.op2_sel == OP2_IMM || ctrl.imm_sel != IS_I) s = {s, $sformatf(" imm=%08h", imm)};
    if (is_fp()) s = {s, $sformatf(" rm=%0d(eff %0d)", rm, eff_rm())};
    if (ctrl.is_br || ctrl.is_jal || ctrl.is_jalr || op == OP_AUIPC) s = {s, $sformatf(" pc=%010h taken=%0b%s%s", pc, pred_taken, is_rvc ? " rvc" : "", edge_inst ? " edge" : "")};
    s = {s, $sformatf(" brmask=%03h delay=%0d%s", br_mask, delay, flush_with_req ? " FLUSH" : "")};
    if (exp_has_data) s = {s, $sformatf(" | exp[%s]=%016h fl=%05b", exp_port.name(), exp_data, exp_flags)};
    if (exp_brinfo_valid) s = {s, $sformatf(" | exp_br: mispred=%0b taken=%0b pc_sel=%0d", exp_mispredict, exp_taken, exp_pc_sel)};
    if (spike_valid) s = {s, $sformatf(" | spike#%0d rd=%016h(%0b) next_pc=%010h fl %05b->%05b", spike_idx, spike_rd_val, spike_has_rd, spike_next_pc[39:0], spike_fl_before, spike_fl_after)};
    return s;
  endfunction

  function void do_copy(uvm_object rhs);
    boom_exe_txn t;
    super.do_copy(rhs);
    if (!$cast(t, rhs)) `uvm_fatal("CPY", "bad cast")
    op = t.op; rs1 = t.rs1; rs2 = t.rs2; rs3 = t.rs3; imm = t.imm; rm = t.rm; fcsr_rm = t.fcsr_rm;
    zimm = t.zimm; csr_addr = t.csr_addr; pc = t.pc; pred_taken = t.pred_taken; is_rvc = t.is_rvc;
    ftq_next_val = t.ftq_next_val; ftq_next_pc = t.ftq_next_pc; ftq_cfi_idx_valid = t.ftq_cfi_idx_valid;
    ftq_cfi_idx = t.ftq_cfi_idx; ftq_start_bank = t.ftq_start_bank;
    br_mask = t.br_mask; br_tag = t.br_tag; rob_idx = t.rob_idx; pdst = t.pdst; ftq_idx = t.ftq_idx;
    delay = t.delay; flush_with_req = t.flush_with_req; deliberately_unboxed = t.deliberately_unboxed;
    ctrl = t.ctrl; uop = t.uop; rs1_rec = t.rs1_rec; rs2_rec = t.rs2_rec; rs3_rec = t.rs3_rec; issue_cycle = t.issue_cycle;
    exp_has_data = t.exp_has_data; exp_port = t.exp_port; exp_data = t.exp_data; exp_flags_valid = t.exp_flags_valid; exp_flags = t.exp_flags;
    exp_brinfo_valid = t.exp_brinfo_valid; exp_mispredict = t.exp_mispredict; exp_taken = t.exp_taken; exp_pc_sel = t.exp_pc_sel;
    exp_cfi_type = t.exp_cfi_type; exp_jalr_target = t.exp_jalr_target; exp_target_offset = t.exp_target_offset;
    rsp_port = t.rsp_port; rsp_data = t.rsp_data; rsp_flags_valid = t.rsp_flags_valid; rsp_flags = t.rsp_flags; rsp_cycle = t.rsp_cycle;
    killed = t.killed; flush_ambiguous = t.flush_ambiguous; killed_same_cycle = t.killed_same_cycle;
    spike_valid = t.spike_valid; spike_idx = t.spike_idx; spike_has_rd = t.spike_has_rd; spike_rd_val = t.spike_rd_val;
    spike_next_pc = t.spike_next_pc; spike_fl_before = t.spike_fl_before; spike_fl_after = t.spike_fl_after; waived_nv = t.waived_nv;
  endfunction

  // copy only the Spike expectation (scoreboard: sequence's txn -> monitor's txn)
  function void copy_spike_from(boom_exe_txn t);
    spike_valid = t.spike_valid; spike_idx = t.spike_idx; spike_has_rd = t.spike_has_rd; spike_rd_val = t.spike_rd_val;
    spike_next_pc = t.spike_next_pc; spike_fl_before = t.spike_fl_before; spike_fl_after = t.spike_fl_after;
  endfunction
endclass : boom_exe_txn


//=============================================================================
// boom_exe_rsp — what the monitor observed on one response port in one cycle
//=============================================================================
class boom_exe_rsp extends uvm_sequence_item;
  `uvm_object_utils(boom_exe_rsp)
  exu_id_e     unit;
  rsp_port_e   port;
  rsp_uop_t    uop;
  bit [64:0]   data_raw;      // 65-bit as seen on the port
  bit [63:0]   data;          // decoded: IEEE for FP ports, integer for int ports
  bit          flags_valid;
  bit [4:0]    flags;
  bit          predicated;
  int          cycle;
  function new(string name = "boom_exe_rsp"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("%s.%s rob=%0d pdst=%0d rtype=%0d data=%016h flags=%05b(%0b) @%0d",
                     unit.name(), port.name(), uop.rob_idx, uop.pdst, uop.dst_rtype, data, flags, flags_valid, cycle);
  endfunction
endclass : boom_exe_rsp


//=============================================================================
// boom_brinfo_rsp — branch resolution observed on an ALU unit
//=============================================================================
class boom_brinfo_rsp extends uvm_sequence_item;
  `uvm_object_utils(boom_brinfo_rsp)
  exu_id_e    unit;
  bit [5:0]   rob_idx;
  bit         mispredict, taken;
  bit [2:0]   cfi_type;
  bit [1:0]   pc_sel;
  bit [39:0]  jalr_target;
  bit [20:0]  target_offset;
  bit [11:0]  br_mask;
  bit [3:0]   br_tag;
  int         cycle;
  function new(string name = "boom_brinfo_rsp"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("%s brinfo rob=%0d mispred=%0b taken=%0b cfi=%0d pc_sel=%0d jalr_tgt=%010h off=%06h @%0d",
                     unit.name(), rob_idx, mispredict, taken, cfi_type, pc_sel, jalr_target, target_offset, cycle);
  endfunction
endclass : boom_brinfo_rsp


//=============================================================================
// boom_brupd_txn — one cycle of branch-update broadcast (resolve / mispredict)
//=============================================================================
class boom_brupd_txn extends uvm_sequence_item;
  `uvm_object_utils(boom_brupd_txn)
  rand bit [11:0]   resolve_mask;
  rand bit [11:0]   mispredict_mask;
  rand bit          flush;            // io_req_bits_kill / flush_pipeline broadcast
  rand int unsigned delay;            // idle cycles before this update
  int               cycle;            // filled by monitor
  constraint c_legal { (mispredict_mask & ~resolve_mask) == 0; $countones(mispredict_mask) <= 1; }
  constraint c_delay { soft delay inside {[0:8]}; }
  constraint c_flush_rare { soft flush dist {0 := 95, 1 := 5}; }
  function new(string name = "boom_brupd_txn"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("brupd resolve=%03h mispredict=%03h flush=%0b delay=%0d", resolve_mask, mispredict_mask, flush, delay);
  endfunction
endclass : boom_brupd_txn

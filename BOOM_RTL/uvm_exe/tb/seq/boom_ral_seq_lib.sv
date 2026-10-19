//=============================================================================
// boom_ral_seq_lib.sv — sequences that drive the CSR file through the
// register model (RAL) and check it against the hardware
//-----------------------------------------------------------------------------
// Every sequence runs on the virtual sequencer, which owns the register model
// handle; frontdoor accesses reach the CSRFile through boom_csr_agent, while
// the mirror is maintained by the passive predictor (see boom_csr_adapter.sv).
//=============================================================================
class boom_ral_base_seq extends uvm_sequence #(boom_exe_txn);
  `uvm_object_utils(boom_ral_base_seq)
  `uvm_declare_p_sequencer(boom_exe_vsequencer)
  boom_csr_reg_block rm;
  uvm_status_e       status;
  int unsigned       n_checked, n_err;

  function new(string name = "boom_ral_base_seq"); super.new(name); endfunction

  virtual task pre_body();
    rm = p_sequencer.regmodel;
    if (rm == null) `uvm_fatal("RAL", "no register model (cfg.has_csr = 0?)")
  endtask

  function void chk(uvm_status_e st, string what);
    n_checked++;
    if (st != UVM_IS_OK) begin n_err++; `uvm_error("RAL", {what, ": status NOT_OK"}) end
  endfunction

  // read a register through the frontdoor and compare hardware vs. mirror (volatile fields excluded by UVM)
  task mirror_check(uvm_reg r);
    r.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
    chk(status, {"mirror ", r.get_name()});
  endtask

  // send one FP instruction through the execution-unit agent (result checked by the exe scoreboard)
  task fp_op(exe_op_e op, bit [63:0] rs1, bit [63:0] rs2 = 0, bit [63:0] rs3 = 0, bit [2:0] rm_field = RM_RNE, bit [2:0] fcsr_rm = RM_RNE);
    boom_exe_txn t = boom_exe_txn::type_id::create("fp");
    boom_exe_sequencer s;
    if (!t.randomize() with { op == local::op; delay <= 2; flush_with_req == 0; deliberately_unboxed == 0; br_mask == 0; })
      `uvm_fatal("RAL", "randomize failed")
    t.rs1 = rs1; t.rs2 = rs2; t.rs3 = rs3; t.rm = rm_field; t.fcsr_rm = fcsr_rm;
    t.rob_idx = 6'($urandom); t.pdst = 7'($urandom_range(1, NUM_INT_PREGS - 1));
    s = p_sequencer.sqr_of(decode_op(op).exu);
    start_item(t, -1, s); finish_item(t);
  endtask

  task settle(int cycles = 40);
    repeat (cycles) @(posedge p_sequencer.cfg.csr_vif.clk);
  endtask

  virtual task post_body();
    `uvm_info("RAL", $sformatf("%s: %0d checks, %0d errors", get_type_name(), n_checked, n_err), UVM_LOW)
  endtask
endclass : boom_ral_base_seq

//-----------------------------------------------------------------------------
// what boot code does before the first FP instruction: mstatus.FS = Initial.
// CSRFile asserts (CSR.scala:1203) if FP flags arrive while FS == Off, so every
// test that runs FP traffic with the CSR file in the loop starts with this.
//-----------------------------------------------------------------------------
class ral_csr_init_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_csr_init_seq)
  bit [2:0] frm = RM_RNE;
  function new(string name = "ral_csr_init_seq"); super.new(name); endfunction
  virtual task body();
    uvm_reg_data_t v;
    rm.mstatus.FS.write(status, 1, UVM_FRONTDOOR, null, this); chk(status, "mstatus.FS <= Initial");
    rm.fcsr.write(status, {frm, 5'b0}, UVM_FRONTDOOR, null, this);  chk(status, "fcsr <= {frm, 0}");
    rm.mstatus.read(status, v, UVM_FRONTDOOR, null, this);          chk(status, "mstatus read");
    if (v[14:13] == 0) begin n_err++; `uvm_error("RAL", $sformatf("mstatus.FS still Off after init: %016h", v)) end
    `uvm_info("RAL", $sformatf("CSR init done: mstatus=%016h fcsr.frm=%0d", v, frm), UVM_LOW)
  endtask
endclass

//-----------------------------------------------------------------------------
// built-in UVM register tests, wrapped so the test list can name them
//-----------------------------------------------------------------------------
class ral_builtin_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_builtin_seq)
  string which = "reset";     // reset | bitbash
  function new(string name = "ral_builtin_seq"); super.new(name); endfunction
  virtual task body();
    case (which)
      "reset": begin
        uvm_reg_hw_reset_seq s = uvm_reg_hw_reset_seq::type_id::create("hw_reset");
        s.model = rm; s.start(null, this);
      end
      "bitbash": begin
        uvm_reg_bit_bash_seq s = uvm_reg_bit_bash_seq::type_id::create("bit_bash");
        s.model = rm; s.start(null, this);
        // bit-bashing left the CSRs in a random state; put the FP unit back to a usable one
        rm.mstatus.FS.write(status, 1, UVM_FRONTDOOR, null, this);
      end
      default: `uvm_fatal("RAL", {"unknown builtin ", which})
    endcase
    n_checked++;
  endtask
endclass

//-----------------------------------------------------------------------------
// write every writable register with random data, then mirror-check the whole
// block: exercises the WARL callbacks against the hardware for all CSRs
//-----------------------------------------------------------------------------
class ral_access_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_access_seq)
  int unsigned rounds = 3;
  function new(string name = "ral_access_seq"); super.new(name); endfunction
  virtual task body();
    uvm_reg regs[$];
    rm.get_registers(regs);
    for (int r = 0; r < rounds; r++) begin
      regs.shuffle();
      foreach (regs[i]) begin
        bit skip;
        uvm_reg_data_t v = {$urandom, $urandom};
        if (regs[i].get_rights() != "RW") continue;
        if (uvm_resource_db#(bit)::read_by_name({"REG::", regs[i].get_full_name()}, "NO_REG_TESTS", skip) && skip) continue;
        if (regs[i].get_name() == "mstatus" || regs[i].get_name() == "sstatus") v[14:13] = 2'd1 + $urandom_range(1); // keep FP on
        regs[i].write(status, v, UVM_FRONTDOOR, null, this); chk(status, {"write ", regs[i].get_name()});
      end
      foreach (regs[i]) mirror_check(regs[i]);
    end
  endtask
endclass

//-----------------------------------------------------------------------------
// fflags is updated by the FPU behind the register model's back: the side-effect
// predictor must track it. DZ from fdiv 1/0, NX from an inexact add, NV from
// sqrt(-1), OF/UF from huge/tiny multiplies, and the alu0 I2F path (ll_fresp).
//-----------------------------------------------------------------------------
class ral_fflags_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_fflags_seq)
  function new(string name = "ral_fflags_seq"); super.new(name); endfunction
  // fflags fields are volatile (UVM skips them in mirror checks), so compare explicitly:
  // the mirror maintained by the side-effect predictor, and the hardware, must both equal exp
  task expect_fflags(bit [4:0] exp, string what);
    uvm_reg_data_t v, m;
    settle();
    m = rm.fflags.get_mirrored_value();
    rm.fflags.read(status, v, UVM_FRONTDOOR, null, this); chk(status, "fflags read");
    n_checked++;
    if (v[4:0] != exp) begin n_err++; `uvm_error("RAL", $sformatf("%s: hardware fflags = %05b, expected %05b", what, v[4:0], exp)) end
    else if (m[4:0] != exp) begin n_err++; `uvm_error("RAL", $sformatf("%s: fflags mirror = %05b, expected %05b (predictor missed a side effect)", what, m[4:0], exp)) end
    else `uvm_info("RAL", $sformatf("%s: fflags = %05b (hardware and mirror)", what, v[4:0]), UVM_LOW)
    if ((rm.fcsr.get_mirrored_value() & 64'h1F) != exp) begin n_err++; `uvm_error("RAL", $sformatf("%s: fcsr mirror %02h does not carry the flags (alias)", what, rm.fcsr.get_mirrored_value())) end
  endtask
  virtual task body();
    uvm_reg_data_t v;
    rm.fcsr.write(status, 0, UVM_FRONTDOOR, null, this); chk(status, "clear fcsr");
    fp_op(OP_FDIV_S, box_s(S_ONE), box_s(S_POS_ZERO));                  expect_fflags(5'b01000, "fdiv.s 1/0 (DZ)");
    fp_op(OP_FADD_D, D_ONE, 64'h3CA0_0000_0000_0000);                   expect_fflags(5'b01001, "+ inexact fadd.d (NX)");
    fp_op(OP_FSQRT_D, 64'hBFF0_0000_0000_0000);                         expect_fflags(5'b11001, "+ fsqrt.d(-1) (NV)");
    fp_op(OP_FMUL_D, D_MAX_NORM, D_MAX_NORM);                           expect_fflags(5'b11101, "+ overflow (OF)");
    fp_op(OP_FMUL_D, D_MIN_NORM, 64'h3CA0_0000_0000_0000);              expect_fflags(5'b11111, "+ underflow (UF)");
    rm.fflags.write(status, 0, UVM_FRONTDOOR, null, this);              expect_fflags(5'b00000, "software clear");
    fp_op(OP_FCVT_S_L, 64'h7FFF_FFFF_FFFF_FFFF);                        expect_fflags(5'b00001, "fcvt.s.l inexact via alu0 ll_fresp (NX)");
    fp_op(OP_FCVT_W_S, box_s(32'h4F00_0000));                            expect_fflags(5'b10001, "+ fcvt.w.s overflow (NV) via F2I");
    // fcsr must show the same flags (alias) and mstatus.FS must have gone Dirty
    mirror_check(rm.fcsr);
    rm.mstatus.read(status, v, UVM_FRONTDOOR, null, this); chk(status, "mstatus read");
    n_checked++;
    if (v[14:13] != 3 || !v[63]) begin n_err++; `uvm_error("RAL", $sformatf("mstatus after FP flags: FS=%0d SD=%0b (expected Dirty/1)", v[14:13], v[63])) end
  endtask
endclass

//-----------------------------------------------------------------------------
// frm written through the model steers dynamic rounding in the FPU / I2F unit
//-----------------------------------------------------------------------------
class ral_frm_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_frm_seq)
  int unsigned n_per_rm = 40;
  function new(string name = "ral_frm_seq"); super.new(name); endfunction
  virtual task body();
    boom_exe_cfg cfg = p_sequencer.cfg;
    exe_op_e ops[] = '{OP_FCVT_W_S, OP_FCVT_L_D, OP_FADD_D, OP_FMUL_S, OP_FMADD_D, OP_FCVT_S_D, OP_FCVT_D_L, OP_FDIV_D, OP_FSQRT_S};
    cfg.fpu_vif.use_csr_rm = 1; cfg.alu0_vif.use_csr_rm = 1;
    for (int r = 0; r < 5; r++) begin
      rm.frm.write(status, r, UVM_FRONTDOOR, null, this); chk(status, "frm write");
      mirror_check(rm.fcsr);
      for (int i = 0; i < n_per_rm; i++) begin
        exe_op_e o = ops[$urandom_range(ops.size() - 1)];
        bit single = is_single_op(o);
        bit [63:0] a = single ? box_s($urandom) : {$urandom, $urandom};
        bit [63:0] b = single ? box_s($urandom) : {$urandom, $urandom};
        if (o inside {OP_FCVT_W_S}) a = box_s(32'h3FC0_0000 + $urandom_range(0, 32'h00FF_FFFF));   // 1.5 .. ~3.9
        if (o inside {OP_FCVT_L_D}) a = 64'h3FF8_0000_0000_0000 + {$urandom_range(0, 32'hFFFF), $urandom};
        if (o == OP_FCVT_D_L) a = {$urandom, $urandom};
        if (o == OP_FCVT_S_D) a = {$urandom, $urandom};
        // rm = DYN in the instruction, so the hardware must pick frm from the CSR; the monitor
        // observes the real fcsr_rm so the scoreboard predicts with it
        fp_op(o, a, b, {$urandom, $urandom}, RM_DYN, 3'(r));
      end
      settle();
    end
    cfg.fpu_vif.use_csr_rm = 0; cfg.alu0_vif.use_csr_rm = 0;
    rm.frm.write(status, 0, UVM_FRONTDOOR, null, this);
  endtask
endclass

//-----------------------------------------------------------------------------
// CSR instructions executed by the pipeline (alu1) — the RAL agent stays idle,
// the passive predictor keeps the mirror in step, and a final mirror check
// proves it. Uses the regular exe CSR sequences.
//-----------------------------------------------------------------------------
class ral_pipeline_csr_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_pipeline_csr_seq)
  int unsigned n = 300;
  function new(string name = "ral_pipeline_csr_seq"); super.new(name); endfunction
  virtual task body();
    uvm_reg regs[$];
    exe_csr_seq cs = exe_csr_seq::type_id::create("cs");
    cs.n = n; cs.max_delay = 2;
    cs.start(p_sequencer, this);
    settle();
    rm.get_registers(regs);
    foreach (regs[i]) mirror_check(regs[i]);
    // and once more with the sweep (every op x every address x zimm corners)
    begin
      exe_csr_sweep_seq sw = exe_csr_sweep_seq::type_id::create("sw");
      sw.start(p_sequencer, this);
    end
    settle();
    foreach (regs[i]) mirror_check(regs[i]);
  endtask
endclass

//-----------------------------------------------------------------------------
// aliases: one physical register, several CSR numbers
//-----------------------------------------------------------------------------
class ral_alias_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_alias_seq)
  function new(string name = "ral_alias_seq"); super.new(name); endfunction
  task expect_reg(uvm_reg r, uvm_reg_data_t exp, string what);
    uvm_reg_data_t v;
    r.read(status, v, UVM_FRONTDOOR, null, this); chk(status, {"read ", r.get_name()});
    n_checked++;
    if (v != exp) begin n_err++; `uvm_error("RAL", $sformatf("%s: %s = %016h, expected %016h", what, r.get_name(), v, exp)) end
    if (r.get_mirrored_value() != exp) begin n_err++; `uvm_error("RAL", $sformatf("%s: %s mirror = %016h, expected %016h", what, r.get_name(), r.get_mirrored_value(), exp)) end
  endtask
  virtual task body();
    uvm_reg_data_t v;
    // fcsr = {frm, fflags}
    rm.fcsr.write(status, 64'hE7, UVM_FRONTDOOR, null, this);
    expect_reg(rm.fflags, 64'h07, "fcsr=e7"); expect_reg(rm.frm, 64'h07, "fcsr=e7");
    rm.frm.write(status, 2, UVM_FRONTDOOR, null, this); rm.fflags.write(status, 64'h11, UVM_FRONTDOOR, null, this);
    expect_reg(rm.fcsr, 64'h51, "frm=2,fflags=11");
    // sstatus is a view of mstatus
    rm.mstatus.write(status, 64'h0000_0000_0000_2000, UVM_FRONTDOOR, null, this);        // FS = Initial, everything else 0
    rm.sstatus.write(status, 64'h0000_0000_000C_0122, UVM_FRONTDOOR, null, this);        // MXR SUM SPP SPIE SIE (FS -> 0 from this write!)
    rm.sstatus.write(status, 64'h0000_0000_000C_2122, UVM_FRONTDOOR, null, this);        // ... and FS back to Initial
    expect_reg(rm.mstatus, 64'h0000_000A_000C_2122, "sstatus write reflected in mstatus");
    rm.mstatus.write(status, 64'h0000_0000_0000_3800, UVM_FRONTDOOR, null, this);        // MPP=3 FS=1
    expect_reg(rm.sstatus, 64'h0000_0002_0000_2000, "mstatus write reflected in sstatus");
    // sie/sip are mie/mip masked by mideleg
    rm.mideleg.write(status, 0, UVM_FRONTDOOR, null, this);
    rm.mie.write(status, 64'hAAA, UVM_FRONTDOOR, null, this);
    expect_reg(rm.sie, 64'h000, "mideleg=0: sie hides everything");
    rm.mideleg.write(status, 64'h222, UVM_FRONTDOOR, null, this);
    expect_reg(rm.sie, 64'h222, "mideleg=222: sie shows delegated bits");
    rm.sie.write(status, 64'h000, UVM_FRONTDOOR, null, this);
    expect_reg(rm.mie, 64'h888, "sie write clears only delegated bits of mie");
    rm.mip.write(status, 64'h222, UVM_FRONTDOOR, null, this);
    expect_reg(rm.sip, 64'h222, "mip -> sip");
    rm.sip.write(status, 64'h000, UVM_FRONTDOOR, null, this);
    expect_reg(rm.mip, 64'h220, "sip write clears only SSIP");
    rm.mip.write(status, 0, UVM_FRONTDOOR, null, this); rm.mie.write(status, 0, UVM_FRONTDOOR, null, this); rm.mideleg.write(status, 0, UVM_FRONTDOOR, null, this);
    // cycle mirrors mcycle (volatile: compare loosely — the counter runs)
    rm.mcycle.write(status, 64'h1000_0000, UVM_FRONTDOOR, null, this);
    rm.cycle.read(status, v, UVM_FRONTDOOR, null, this); chk(status, "cycle read"); n_checked++;
    if (v < 64'h1000_0000 || v > 64'h1000_0100) begin n_err++; `uvm_error("RAL", $sformatf("cycle = %016h after mcycle <= 10000000", v)) end
  endtask
endclass

//-----------------------------------------------------------------------------
// WARL: write illegal / out-of-range values, the model's legalisation must
// agree with the hardware
//-----------------------------------------------------------------------------
class ral_warl_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_warl_seq)
  function new(string name = "ral_warl_seq"); super.new(name); endfunction
  task w_and_check(uvm_reg r, uvm_reg_data_t v, string what, bit exp_ok = 1);
    r.write(status, v, UVM_FRONTDOOR, null, this);
    n_checked++;
    if ((status == UVM_IS_OK) != exp_ok) begin n_err++; `uvm_error("RAL", $sformatf("write %s: status %s, expected %s", r.get_name(), status.name(), exp_ok ? "OK" : "NOT_OK (read-only)")) end
    mirror_check(r);
    `uvm_info("RAL", $sformatf("%s: %s <= %016h -> mirror %016h", what, r.get_name(), v, r.get_mirrored_value()), UVM_LOW)
  endtask
  virtual task body();
    w_and_check(rm.mepc,    64'h0000_0080_0000_0001, "mepc: sign-extend from bit 39, clear bit 0");
    w_and_check(rm.mepc,    64'h1234_5678_9ABC_DEF0, "mepc: high bits dropped");
    w_and_check(rm.sepc,    64'h0000_00C0_0000_0003, "sepc");
    w_and_check(rm.mtval,   64'h0000_0080_0000_0000, "mtval: sign-extend from bit 39");
    w_and_check(rm.stval,   64'hFFFF_FF7F_FFFF_FFFF, "stval: bit 39 clear -> zero-extended");
    w_and_check(rm.stvec,   64'h0000_0040_0000_0003, "stvec: 39-bit base, mode bit 1 dropped");
    w_and_check(rm.mtvec,   64'h0000_0001_FFFF_FFFF, "mtvec: 32-bit base");
    w_and_check(rm.mstatus, 64'h0000_0000_0000_3000, "mstatus: MPP=2 -> U (FS kept Initial)");
    w_and_check(rm.mstatus, 64'h0000_0000_0000_3800, "mstatus: MPP=3 legal");
    w_and_check(rm.medeleg, 64'hFFFF_FFFF_FFFF_FFFF, "medeleg: legal-bit mask");
    w_and_check(rm.mideleg, 64'hFFFF_FFFF_FFFF_FFFF, "mideleg: legal-bit mask");
    w_and_check(rm.mideleg, 0, "mideleg: back to 0");
    w_and_check(rm.satp,    64'h8FFF_FFFF_FFFF_FFFF, "satp: Sv39, asid dropped, 20-bit ppn");
    w_and_check(rm.satp,    64'h9000_0000_0000_0001, "satp: unsupported mode -> write dropped");
    w_and_check(rm.satp,    64'h0000_0000_0000_0001, "satp: Bare");
    w_and_check(rm.mcause,  64'h8000_0000_0000_00FF, "mcause: 4-bit code");
    w_and_check(rm.scause,  64'h8000_0000_0000_00FF, "scause: 5-bit code");
    w_and_check(rm.mhpmevent3, 64'hFFFF_FFFF_FFFF_FFFF, "mhpmevent: mask 3f03");
    w_and_check(rm.pmpaddr0, 64'hFFFF_FFFF_FFFF_FFFF, "pmpaddr: 30 bits");
    w_and_check(rm.mcountinhibit, 64'hFFFF_FFFF_FFFF_FFFF, "mcountinhibit: TM hardwired");
    w_and_check(rm.mcountinhibit, 0, "mcountinhibit: back to 0");
    w_and_check(rm.misa,    0, "misa: read-only");
    w_and_check(rm.mvendorid, 64'h1234, "mvendorid: read-only (decode flags the write)", 0);
  endtask
endclass

//-----------------------------------------------------------------------------
// CSR numbers that do not exist / are debug-only must decode as illegal, and
// the driver must not perform the access
//-----------------------------------------------------------------------------
class ral_illegal_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_illegal_seq)
  function new(string name = "ral_illegal_seq"); super.new(name); endfunction
  virtual task body();
    foreach (rm.illegal_addrs[i]) begin
      boom_csr_txn t = boom_csr_txn::type_id::create("ill");
      start_item(t, -1, p_sequencer.csr_sqr);
      if (!t.randomize() with { addr == rm.illegal_addrs[i]; cmd == CSR_R; }) `uvm_fatal("RAL", "randomize failed")
      finish_item(t);
      n_checked++;
      if (!t.read_illegal) begin n_err++; `uvm_error("RAL", $sformatf("CSR %03h decoded as legal", t.addr)) end
      else `uvm_info("RAL", $sformatf("CSR %03h: read_illegal as expected", t.addr), UVM_LOW)
    end
    // read-only CSRs: a write must be flagged by decode, and never reach the register
    begin
      bit [11:0] ro[] = '{12'hF11, 12'hF12, 12'hF13, 12'hF14, 12'hC00, 12'hC02};
      foreach (ro[i]) begin
        boom_csr_txn t = boom_csr_txn::type_id::create("ro");
        start_item(t, -1, p_sequencer.csr_sqr);
        if (!t.randomize() with { addr == ro[i]; cmd == CSR_W; }) `uvm_fatal("RAL", "randomize failed")
        finish_item(t);
        n_checked++;
        if (!t.write_illegal) begin n_err++; `uvm_error("RAL", $sformatf("write to read-only CSR %03h not flagged", t.addr)) end
      end
    end
  endtask
endclass

//-----------------------------------------------------------------------------
// backdoor (hdl paths into CSRFile): poke -> frontdoor read, frontdoor write -> peek
//-----------------------------------------------------------------------------
class ral_backdoor_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_backdoor_seq)
  function new(string name = "ral_backdoor_seq"); super.new(name); endfunction
  virtual task body();
    uvm_reg regs[$];
    uvm_reg_data_t v, w;
    rm.get_registers(regs);
    foreach (regs[i]) begin
      if (!regs[i].has_hdl_path()) continue;
      if (regs[i].get_name() inside {"mstatus", "sstatus"}) continue;
      w = {$urandom, $urandom};
      regs[i].poke(status, w, "", this); chk(status, {"poke ", regs[i].get_name()});
      regs[i].read(status, v, UVM_FRONTDOOR, null, this); chk(status, {"read ", regs[i].get_name()});
      mirror_check(regs[i]);                     // mirror was updated by the poke (legalised by the callbacks) and by the read
      w = {$urandom, $urandom};
      regs[i].write(status, w, UVM_FRONTDOOR, null, this); chk(status, {"write ", regs[i].get_name()});
      regs[i].peek(status, v, "", this); chk(status, {"peek ", regs[i].get_name()});
      n_checked++;
      if (v != regs[i].get_mirrored_value()) begin n_err++; `uvm_error("RAL", $sformatf("%s: peek %016h != mirror %016h", regs[i].get_name(), v, regs[i].get_mirrored_value())) end
    end
  endtask
endclass

//-----------------------------------------------------------------------------
// random mix: RAL accesses, FP traffic (flags side effects) and pipeline CSR
// instructions interleaved, then a full mirror check
//-----------------------------------------------------------------------------
class ral_random_mix_seq extends boom_ral_base_seq;
  `uvm_object_utils(ral_random_mix_seq)
  int unsigned n = 400;
  function new(string name = "ral_random_mix_seq"); super.new(name); endfunction
  virtual task body();
    uvm_reg regs[$], rw[$];
    rm.get_registers(regs);
    foreach (regs[i]) begin
      bit skip;
      if (regs[i].get_rights() != "RW") continue;
      if (uvm_resource_db#(bit)::read_by_name({"REG::", regs[i].get_full_name()}, "NO_REG_TESTS", skip) && skip) continue;
      if (regs[i].get_name() inside {"mstatus", "sstatus", "misa", "satp"}) continue;
      rw.push_back(regs[i]);
    end
    for (int i = 0; i < n; i++) begin
      case ($urandom_range(3))
        0: begin uvm_reg r = rw[$urandom_range(rw.size() - 1)]; r.write(status, {$urandom, $urandom}, UVM_FRONTDOOR, null, this); chk(status, "write"); end
        1: begin uvm_reg r = regs[$urandom_range(regs.size() - 1)]; mirror_check(r); end
        2: begin
             exe_op_e fo[] = '{OP_FADD_D, OP_FMUL_S, OP_FDIV_S, OP_FSQRT_D, OP_FCVT_W_S, OP_FCVT_S_L, OP_FMADD_D};
             fp_op(fo[$urandom_range(fo.size() - 1)], {$urandom, $urandom}, {$urandom, $urandom}, {$urandom, $urandom}, 3'($urandom_range(4)));
           end
        3: begin
             // one CSR instruction through the pipeline (the RAL agent is idle while it completes)
             exe_csr_seq cs = exe_csr_seq::type_id::create("cs"); cs.n = 1; cs.max_delay = 0;
             cs.start(p_sequencer, this); settle(8);
           end
      endcase
    end
    settle();
    foreach (regs[i]) mirror_check(regs[i]);
  endtask
endclass

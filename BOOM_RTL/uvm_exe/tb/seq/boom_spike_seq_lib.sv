//=============================================================================
// boom_spike_seq_lib.sv — trace-driven stimulus from a Spike commit log
//-----------------------------------------------------------------------------
// Spike (riscv-isa-sim) executes a real program — the riscv-tests ISA suite
// that Chipyard runs on it — and logs every committed instruction with its
// architectural effects. The DPI-C library dpi/boom_spike_trace.c replays that
// log, keeps the architectural register state, decodes each instruction and
// returns (operands, expected result). This sequence turns every replayable
// instruction into a boom_exe_txn:
//   * operands come from the replayed register state (the DUT has no register
//     file — the testbench is the rest of the core),
//   * the transaction goes through the same driver / monitor / scoreboard as
//     the constrained-random sequences, so the SoftFloat/ALU model still
//     checks it, and
//   * Spike's rd value / fflags / next pc are parked in boom_spike_oracle for
//     the scoreboard's second-opinion check.
// CSR instructions are serialised (pipeline drained before and after) exactly
// as BOOM does, so the CSRFile sees them in program order and the fflags a
// later `frflags` reads back have really accumulated in the hardware.
// Loads, stores, fences, ecall/mret are not replayable on this DUT: their
// results still update the replayed state, so later instructions get the
// right operands.
//=============================================================================
import "DPI-C" function int    spike_trace_register_op(input int id, input string name);
import "DPI-C" function int    spike_trace_load(input string path);
import "DPI-C" function int    spike_trace_num();
import "DPI-C" function int    spike_trace_replayable();
import "DPI-C" function int    spike_trace_class_count(input int cls);
import "DPI-C" function int    spike_trace_get(input int i, output longint pc, output int insn, output int kind, output int op, output int is_csr,
                                               output longint rs1, output longint rs2, output longint rs3,
                                               output int imm, output int rm, output int zimm, output int csr,
                                               output int rd, output int has_rd, output int dst_fp, output longint rd_val, output longint next_pc,
                                               output int fl_before, output int fl_after, output int frm,
                                               output int csr_wr_valid, output int csr_wr_num, output longint csr_wr_val);
import "DPI-C" function string spike_trace_opname(input int i);

class boom_spike_trace_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_spike_trace_seq)

  // knobs
  string        logs[$];                 // Spike commit logs, replayed one after the other
  int unsigned  max_insns     = 0;       // stop after this many replayed instructions (0 = all)
  bit           serialize_csr = 1;       // drain the pipeline around CSR instructions (as BOOM does)
  bit           use_csr_rm    = 1;       // FPU / I2F take frm from the real CSRFile (the trace's CSR writes set it)
  bit           random_pred   = 1;       // front-end prediction for branches is random (mispredict outcome checked)
  int unsigned  jalr_hint_pct = 50;      // % of JALRs whose FTQ entry predicts the right target
  int unsigned  drain_timeout = 800;     // cycles

  // statistics
  int unsigned  n_replayed, n_skipped, n_csr, n_drains, n_logs;
  static bit    ops_registered = 0;

  function new(string name = "boom_spike_trace_seq"); super.new(name); endfunction

  // tell the C side what the SV op enum looks like (by name, so the two can never drift silently)
  static function void register_ops();
    if (ops_registered) return;
    for (int k = 0; k < OP_NUM; k++) begin
      exe_op_e o = exe_op_e'(k);
      void'(spike_trace_register_op(k, o.name()));
    end
    ops_registered = 1;
  endfunction

  // wait until every request this sequence sent has been answered or squashed
  virtual task drain(string why);
    int waited = 0;
    boom_spike_oracle orc = p_sequencer.spike;
    n_drains++;
    while (orc.total_outstanding() != 0 && waited < drain_timeout) begin
      #(CLK_PERIOD); waited++;
    end
    if (waited >= drain_timeout)
      `uvm_error("SPIKE", $sformatf("drain (%s) timed out with %0d requests outstanding", why, orc.total_outstanding()))
    repeat (2) #(CLK_PERIOD);   // let the CSRFile write of a CSR instruction land before the next request
  endtask

  virtual function boom_exe_txn make_txn(int i);
    longint pc, rs1, rs2, rs3, rd_val, next_pc, csr_wr_val;
    int insn, kind, op, is_csr, imm, rm, zimm, csr, rd, has_rd, dst_fp, fl_before, fl_after, frm, csr_wr_valid, csr_wr_num;
    boom_exe_txn t;
    op_ctrl_t c;
    if (!spike_trace_get(i, pc, insn, kind, op, is_csr, rs1, rs2, rs3, imm, rm, zimm, csr, rd, has_rd, dst_fp, rd_val, next_pc,
                         fl_before, fl_after, frm, csr_wr_valid, csr_wr_num, csr_wr_val)) return null;
    if (kind == 0) return null;
    t = boom_exe_txn::type_id::create($sformatf("spike%0d", i));
    t.op = exe_op_e'(op);
    c = decode_op(t.op);
    t.rs1 = rs1; t.rs2 = rs2; t.rs3 = rs3;
    t.imm = imm; t.rm = rm[2:0]; t.zimm = zimm[4:0]; t.csr_addr = csr[11:0];
    t.fcsr_rm = frm[2:0];
    t.pc = pc[39:0]; t.is_rvc = 0; t.edge_inst = 0;
    t.pred_taken = random_pred ? $urandom_range(1) : (next_pc != pc + 4);
    // FTQ entry for JALR: predict the real target `jalr_hint_pct` % of the time
    t.ftq_next_val = 1; t.ftq_cfi_idx_valid = 1; t.ftq_start_bank = $urandom_range(1);
    if (t.op == OP_JALR && $urandom_range(99) < jalr_hint_pct) begin
      bit [5:0] lob_x = t.pc[5:0] ^ (t.ftq_start_bank ? 6'(BANK_BYTES) : 6'd0);
      t.ftq_next_pc = {next_pc[39:1], 1'b0}; t.ftq_cfi_idx = lob_x[2:1];
    end else begin
      t.ftq_next_pc = {$urandom(), $urandom()} & 40'hFF_FFFF_FFFE; t.ftq_cfi_idx = 2'($urandom());
    end
    t.br_mask = '0; t.br_tag = '0; t.ftq_idx = 5'($urandom());
    t.delay = $urandom_range(max_delay); t.flush_with_req = 0; t.deliberately_unboxed = 0;
    t.rob_idx = 6'(rob_ctr[c.exu]); rob_ctr[c.exu] = (rob_ctr[c.exu] + 1) % 64;
    t.pdst = 7'(pdst_ctr); pdst_ctr = (pdst_ctr % (NUM_INT_PREGS - 1)) + 1;
    // Spike's verdict
    t.spike_valid = 1; t.spike_idx = i; t.spike_has_rd = has_rd; t.spike_rd_val = rd_val; t.spike_next_pc = next_pc;
    t.spike_fl_before = fl_before[4:0]; t.spike_fl_after = fl_after[4:0];
    return t;
  endfunction

  virtual task replay_log(string path);
    int n;
    boom_spike_oracle orc = p_sequencer.spike;
    n = spike_trace_load(path);
    if (n < 0) `uvm_fatal("SPIKE", $sformatf("cannot open Spike log '%s'", path))
    n_logs++;
    `uvm_info("SPIKE", $sformatf("log %s: %0d committed instructions, %0d replayable (alu=%0d br/jmp=%0d muldiv=%0d csr=%0d fp=%0d f2i=%0d i2f=%0d, not replayable=%0d)",
              path, n, spike_trace_replayable(), spike_trace_class_count(0), spike_trace_class_count(1), spike_trace_class_count(2),
              spike_trace_class_count(3), spike_trace_class_count(4), spike_trace_class_count(5), spike_trace_class_count(6), spike_trace_class_count(7)), UVM_LOW)
    for (int i = 0; i < n; i++) begin
      boom_exe_txn t = make_txn(i);
      if (t == null) begin n_skipped++; continue; end
      if (decode_op(t.op).fu_code == FU_CSR) begin
        n_csr++;
        if (serialize_csr) drain("before CSR instruction");
        orc.csr_q.push_back(t);
        orc.park(t);
        send(t);
        if (serialize_csr) drain("after CSR instruction");
      end else begin
        orc.park(t);
        send(t);
      end
      n_replayed++;
      if (max_insns != 0 && n_replayed >= max_insns) break;
    end
    drain("end of log");
  endtask

  virtual task body();
    boom_exe_cfg cfg = p_sequencer.cfg;
    register_ops();
    if (logs.size() == 0) `uvm_fatal("SPIKE", "no Spike log given (+spike_log=<file>[,<file>...])")
    if (use_csr_rm) begin cfg.fpu_vif.use_csr_rm = 1; cfg.alu0_vif.use_csr_rm = 1; cfg.alu1_vif.use_csr_rm = 1; end
    foreach (logs[i]) begin
      replay_log(logs[i]);
      if (max_insns != 0 && n_replayed >= max_insns) break;
    end
    `uvm_info("SPIKE", $sformatf("replayed %0d instructions from %0d log(s) (%0d CSR, %0d not replayable, %0d drains)", n_replayed, n_logs, n_csr, n_skipped, n_drains), UVM_LOW)
  endtask
endclass : boom_spike_trace_seq

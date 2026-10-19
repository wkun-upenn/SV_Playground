//=============================================================================
// smoke_top.sv — UVM-free cross-check of the golden model against the RTL
//-----------------------------------------------------------------------------
// Runs under Verilator (no simulator licence needed):
//   * every exe_op_e op, N times, operands biased towards corner cases
//   * one request at a time, lowered by boom_exe_txn::lower() (the same code
//     the UVM driver uses), predicted by boom_exe_ref_model (same DPI/SoftFloat)
//   * checks response port, data, fflags, brinfo, and reports the observed
//     request->response latency per op against op_ctrl_t.latency
// It is the fast "does the reference model agree with the hardware" loop that
// runs on every commit; the UVM environment adds concurrency, kills, flushes,
// backpressure, the issue queue, coverage and assertions on top of it.
//=============================================================================
`timescale 1ns/1ps
module smoke_top;
  import boom_exe_defs_pkg::*;
  import boom_exe_smoke_pkg::*;

  logic clk = 0, rst = 1;
  always #(CLK_PERIOD / 2) clk = ~clk;

  boom_exu_if #(EXU_ALU0) alu0_if (.clk(clk), .rst(rst));
  boom_exu_if #(EXU_ALU1) alu1_if (.clk(clk), .rst(rst));
  boom_exu_if #(EXU_FPU)  fpu_if  (.clk(clk), .rst(rst));
  boom_iq_if              iq_if   (.clk(clk), .rst(rst));
  boom_csr_if             csr_if  (.clk(clk), .rst(rst));
  `include "boom_exe_dut_inst.svh"

  // CSRFile plumbing as in BOOM core.scala: the CSR execution unit's writeback feeds rw,
  // the FP writebacks' flags are OR-ed into fcsr_flags
  assign csr_if.pipe_cmd   = alu1_if.iresp_valid ? alu1_if.iresp_uop.ctrl_csr_cmd : CSR_N;
  assign csr_if.pipe_addr  = alu1_if.iresp_uop.csr_addr;
  assign csr_if.pipe_wdata = alu1_if.iresp_data[63:0];
  assign csr_if.fcsr_flags_valid = (fpu_if.fresp_valid & fpu_if.fresp_fflags_valid) | fpu_if.fresp_fflags_valid |
                                   (alu0_if.ll_fresp_valid & alu0_if.ll_fresp_ready & alu0_if.ll_fresp_fflags_valid);
  assign csr_if.fcsr_flags_bits  = (fpu_if.fresp_fflags_valid ? fpu_if.fresp_fflags : 5'b0) |
                                   ((alu0_if.ll_fresp_valid & alu0_if.ll_fresp_ready & alu0_if.ll_fresp_fflags_valid) ? alu0_if.ll_fresp_fflags : 5'b0);
  assign csr_if.set_fs_dirty = 1'b0;
  assign fpu_if.fcsr_rm_csr  = csr_if.fcsr_rm;
  assign alu0_if.fcsr_rm_csr = csr_if.fcsr_rm;
  assign alu1_if.fcsr_rm_csr = csr_if.fcsr_rm;

  //---------------------------------------------------------------- knobs
  int n_per_op = 200;
  int seed     = 1;
  int max_errors = 50;
  string only_op = "";
  string spike_log = "";
  bit    spike_only = 0;
  int errors   = 0, checked = 0, lat_mismatch = 0;
  int lat_hist[exe_op_e][int];

  //---------------------------------------------------------------- operand generation
  bit [63:0] int_corners[] = '{64'h0, 64'h1, 64'h2, 64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFE, 64'h7FFF_FFFF_FFFF_FFFF,
    64'h8000_0000_0000_0000, 64'h8000_0000_0000_0001, 64'h0000_0000_7FFF_FFFF, 64'h0000_0000_8000_0000, 64'h0000_0000_FFFF_FFFF,
    64'h0000_0001_0000_0000, 64'hFFFF_FFFF_8000_0000, 64'h0000_0000_0000_003F, 64'h0000_0000_0000_0040, 64'h0000_0000_0000_0020};
  bit [63:0] d_corners[] = '{D_POS_ZERO, D_NEG_ZERO, D_POS_INF, D_NEG_INF, D_QNAN, D_SNAN, 64'hFFF8_0000_0000_0000, 64'h7FF0_0000_0000_0001,
    D_MIN_SUBN, D_MAX_SUBN, D_MIN_NORM, D_MAX_NORM, D_ONE, 64'hBFF0_0000_0000_0000, 64'h4000_0000_0000_0000, 64'h43E0_0000_0000_0000,
    64'hC3E0_0000_0000_0000, 64'h41E0_0000_0000_0000, 64'h3FEF_FFFF_FFFF_FFFF, 64'h3CA0_0000_0000_0000};
  bit [31:0] s_corners[] = '{S_POS_ZERO, S_NEG_ZERO, S_POS_INF, S_NEG_INF, S_QNAN, S_SNAN, 32'hFFC0_0000, 32'h7F80_0001, S_MIN_SUBN,
    S_MAX_SUBN, S_MIN_NORM, S_MAX_NORM, S_ONE, 32'hBF80_0000, 32'h4000_0000, 32'h4F00_0000, 32'hCF00_0000, 32'h5F00_0000, 32'h3F7F_FFFF};

  function bit [63:0] rnd64(); return {$urandom(), $urandom()}; endfunction
  function bit [63:0] pick_int(); return ($urandom_range(99) < 40) ? int_corners[$urandom_range(int_corners.size()-1)] : rnd64(); endfunction
  function bit [63:0] pick_d();   return ($urandom_range(99) < 40) ? d_corners[$urandom_range(d_corners.size()-1)] : rnd64(); endfunction
  function bit [63:0] pick_s();   return box_s(($urandom_range(99) < 40) ? s_corners[$urandom_range(s_corners.size()-1)] : $urandom()); endfunction

  function automatic void fill(boom_exe_txn t, exe_op_e o);
    op_ctrl_t c;
    bit single;
    c = decode_op(o);
    single = is_single_op(o);
    t.op = o;
    t.rs1 = pick_int(); t.rs2 = pick_int(); t.rs3 = '0;
    if (is_fp_op(o)) begin
      if (c.lrs1_rtype == RT_FLT) t.rs1 = single ? pick_s() : pick_d();
      if (c.lrs2_rtype == RT_FLT) t.rs2 = single ? pick_s() : pick_d();
      if (c.frs3_en)              t.rs3 = single ? pick_s() : pick_d();
      if (o == OP_FCVT_D_S) t.rs1 = pick_s();
      if (o == OP_FCVT_S_D) t.rs1 = pick_d();
    end else if (o inside {OP_SLL, OP_SRL, OP_SRA, OP_SLLW, OP_SRLW, OP_SRAW} && $urandom_range(1))
      t.rs2 = {58'b0, 6'($urandom_range(63))};
    t.imm = $urandom();
    if (o inside {OP_SLLI, OP_SRLI, OP_SRAI}) t.imm[11:6] = 0;
    if (o inside {OP_SLLIW, OP_SRLIW, OP_SRAIW}) t.imm[11:5] = 0;
    t.rm = ($urandom_range(99) < 30) ? RM_DYN : 3'($urandom_range(4));
    t.fcsr_rm = 3'($urandom_range(4));
    t.zimm = 5'($urandom());
    t.csr_addr = 12'($urandom());
    t.pc = {$urandom(), $urandom()} & 40'hFF_FFFF_FFFE;
    t.pred_taken = $urandom_range(1); t.is_rvc = $urandom_range(1);
    t.edge_inst = !t.is_rvc && ($urandom_range(3) == 0);      // 32-bit instruction straddling two fetch blocks
    t.ftq_next_val = ($urandom_range(9) != 0); t.ftq_next_pc = {$urandom(), $urandom()} & 40'hFF_FFFF_FFFE;
    t.ftq_cfi_idx_valid = ($urandom_range(9) != 0); t.ftq_cfi_idx = 2'($urandom()); t.ftq_start_bank = $urandom_range(1);
    t.br_mask = '0; t.br_tag = '0; t.rob_idx = 6'($urandom()); t.pdst = 7'($urandom_range(1, NUM_INT_PREGS - 1)); t.ftq_idx = 5'($urandom());
    t.delay = 0; t.flush_with_req = 0; t.deliberately_unboxed = 0;
    // JALR: make the FTQ agree with the real target half of the time (exercises both mispredict outcomes)
    if (o == OP_JALR && $urandom_range(1)) begin
      bit [63:0] tgt;
      bit [5:0] lob_x;
      tgt = t.rs1 + {{52{t.imm[11]}}, t.imm[11:0]};
      lob_x = t.pc[5:0] ^ (t.ftq_start_bank ? 6'(BANK_BYTES) : 6'd0);
      t.ftq_next_pc = {tgt[39:1], 1'b0}; t.ftq_next_val = 1; t.ftq_cfi_idx_valid = 1; t.ftq_cfi_idx = lob_x[2:1];
    end
  endfunction

  //---------------------------------------------------------------- per-unit drive / observe
  // observed response
  bit        got_rsp, got_flags, got_br;
  rsp_port_e obs_port; bit [63:0] obs_data; bit [4:0] obs_flags; int obs_lat;
  bit        obs_mispred, obs_taken; bit [1:0] obs_pc_sel; bit [2:0] obs_cfi; bit [39:0] obs_jalr; bit [20:0] obs_toff;

  function automatic void note_rsp(rsp_port_e p, rsp_uop_t u, logic [64:0] d, int lat);
    if (got_rsp) begin errors++; $display("ERROR: duplicate response on %s", p.name()); return; end
    got_rsp = 1; obs_port = p; obs_lat = lat;
    obs_data = (u.dst_rtype == RT_FLT) ? fp_ieee(d) : d[63:0];
  endfunction

`define SMOKE_UNIT(TASKNAME, IF, HAS_IRESP, HAS_LLI, HAS_FRESP, HAS_LLF, HAS_BR) \
  /* kind: 0 = plain, 1 = branch mispredict of the uop's tag k cycles after issue, 2 = flush k cycles after issue */ \
  task automatic TASKNAME(boom_exe_txn t, int kind = 0, int k = 0); \
    int lat = 0; \
    got_rsp = 0; got_flags = 0; got_br = 0; \
    /* wait until the unit advertises the FU (div/fdiv/i2f/f2i busy) */ \
    @(posedge clk); #2; \
    while ((IF.fu_types & t.ctrl.fu_code) == 0) begin @(posedge clk); #2; end \
    IF.req_valid = 1; IF.req_uop = t.uop; IF.rs1_data = t.rs1_rec; IF.rs2_data = t.rs2_rec; IF.rs3_data = t.rs3_rec; \
    IF.fcsr_rm_drv = t.fcsr_rm; IF.ftq_pc = t.edge_inst ? t.pc + 40'd2 : t.pc; IF.ftq_next_val = t.ftq_next_val; IF.ftq_next_pc = t.ftq_next_pc; \
    IF.ftq_entry_cfi_idx_valid = t.ftq_cfi_idx_valid; IF.ftq_entry_cfi_idx_bits = t.ftq_cfi_idx; IF.ftq_entry_start_bank = t.ftq_start_bank; \
    IF.br_mispredict_mask = (kind == 1 && k == 0) ? t.br_mask : 12'h0; IF.br_resolve_mask = IF.br_mispredict_mask; \
    IF.flush_bcast = (kind == 2 && k == 0); \
    for (int cyc = 0; cyc < 130; cyc++) begin \
      @(negedge clk); \
      if (HAS_BR && IF.brinfo_valid && IF.brinfo_uop_rob_idx == t.rob_idx) begin \
        got_br = 1; obs_mispred = IF.brinfo_mispredict; obs_taken = IF.brinfo_taken; obs_pc_sel = IF.brinfo_pc_sel; \
        obs_cfi = IF.brinfo_cfi_type; obs_jalr = IF.brinfo_jalr_target; obs_toff = IF.brinfo_target_offset; \
      end \
      if (HAS_IRESP && IF.iresp_valid && IF.iresp_uop.rob_idx == t.rob_idx) note_rsp(PORT_IRESP, IF.iresp_uop, IF.iresp_data, lat); \
      if (HAS_LLI && IF.ll_iresp_valid && IF.ll_iresp_uop.rob_idx == t.rob_idx) note_rsp(PORT_LL_IRESP, IF.ll_iresp_uop, IF.ll_iresp_data, lat); \
      if (HAS_FRESP && IF.fresp_valid && IF.fresp_uop.rob_idx == t.rob_idx) note_rsp(PORT_FRESP, IF.fresp_uop, IF.fresp_data, lat); \
      if (HAS_FRESP && IF.fresp_fflags_valid && IF.fresp_fflags_rob_idx == t.rob_idx) begin got_flags = 1; obs_flags = IF.fresp_fflags; end \
      if (HAS_LLF && IF.ll_fresp_valid && IF.ll_fresp_uop.rob_idx == t.rob_idx) begin \
        note_rsp(PORT_LL_FRESP, IF.ll_fresp_uop, IF.ll_fresp_data, lat); \
        if (IF.ll_fresp_fflags_valid) begin got_flags = 1; obs_flags = IF.ll_fresp_fflags; end \
      end \
      @(posedge clk); #2; \
      IF.req_valid = 0; \
      lat++; \
      IF.br_mispredict_mask = (kind == 1 && k == lat) ? t.br_mask : 12'h0; IF.br_resolve_mask = IF.br_mispredict_mask; \
      IF.flush_bcast = (kind == 2 && k == lat); \
      if (kind != 0) begin if (cyc >= 129 || (cyc > k + 3 && (IF.fu_types & t.ctrl.fu_code) != 0 && got_rsp)) break; else continue; end \
      /* the request cycle is done: keep sampling until the unit is quiet again */ \
      if (got_rsp && (!t.exp_flags_valid || got_flags) && cyc >= 1 && (IF.fu_types & t.ctrl.fu_code) != 0) break; \
      if (!t.exp_has_data && (!t.exp_flags_valid || got_flags) && cyc >= 6) break; \
    end \
    IF.br_mispredict_mask = 0; IF.br_resolve_mask = 0; IF.flush_bcast = 0; \
  endtask

  `SMOKE_UNIT(run_alu0, alu0_if, 1, 0, 0, 1, 1)
  `SMOKE_UNIT(run_alu1, alu1_if, 1, 0, 0, 0, 1)
  `SMOKE_UNIT(run_fpu,  fpu_if,  0, 1, 1, 0, 0)

  //---------------------------------------------------------------- compare
  function automatic void check(boom_exe_txn t);
    string tag;
    tag = $sformatf("%s rs1=%016h rs2=%016h rs3=%016h imm=%08h rm=%0d/%0d%s", t.op.name(), t.rs1, t.rs2, t.rs3, t.imm, t.rm, t.fcsr_rm, t.edge_inst ? " edge" : "");
    checked++;
    if (t.exp_has_data) begin
      if (!got_rsp) begin errors++; $display("ERROR: %s -> no response (expected %s)", tag, t.exp_port.name()); return; end
      if (obs_port != t.exp_port) begin errors++; $display("ERROR: %s -> port %s, expected %s", tag, obs_port.name(), t.exp_port.name()); end
      if (obs_data != t.exp_data) begin errors++; $display("ERROR: %s -> data %016h, expected %016h", tag, obs_data, t.exp_data); end
      if (t.ctrl.latency != 0 && obs_lat != t.ctrl.latency) lat_mismatch++;
      lat_hist[t.op][obs_lat]++;
    end else if (got_rsp) begin
      errors++; $display("ERROR: %s -> unexpected response on %s data=%016h", tag, obs_port.name(), obs_data);
    end
    if (t.exp_flags_valid) begin
      if (!got_flags) begin errors++; $display("ERROR: %s -> no fflags (expected %05b)", tag, t.exp_flags); end
      else if (obs_flags != t.exp_flags) begin errors++; $display("ERROR: %s -> fflags %05b, expected %05b", tag, obs_flags, t.exp_flags); end
    end
    if (t.exp_brinfo_valid) begin
      if (!got_br) begin errors++; $display("ERROR: %s -> no brinfo", tag); end
      else begin
        if (obs_mispred != t.exp_mispredict || obs_taken != t.exp_taken || obs_pc_sel != t.exp_pc_sel || obs_cfi != t.exp_cfi_type) begin
          errors++; $display("ERROR: %s pc=%010h taken=%0b ftq(next_val=%0b next_pc=%010h cfi_valid=%0b cfi_idx=%0d bank=%0b) -> brinfo mispred=%0b taken=%0b pc_sel=%0d cfi=%0d jalr_tgt=%010h, expected %0b/%0b/%0d/%0d tgt=%010h",
                             tag, t.pc, t.pred_taken, t.ftq_next_val, t.ftq_next_pc, t.ftq_cfi_idx_valid, t.ftq_cfi_idx, t.ftq_start_bank,
                             obs_mispred, obs_taken, obs_pc_sel, obs_cfi, obs_jalr, t.exp_mispredict, t.exp_taken, t.exp_pc_sel, t.exp_cfi_type, t.exp_jalr_target);
        end
        if (t.ctrl.is_jalr && obs_jalr != t.exp_jalr_target) begin
          errors++; $display("ERROR: %s -> jalr_target %010h, expected %010h", tag, obs_jalr, t.exp_jalr_target);
        end
        if (t.ctrl.is_br && obs_toff != t.exp_target_offset) begin
          errors++; $display("ERROR: %s -> target_offset %06h, expected %06h", tag, obs_toff, t.exp_target_offset);
        end
      end
    end else if (got_br) begin
      errors++; $display("ERROR: %s -> unexpected brinfo", tag);
    end
  endfunction

  // +dbg: per-cycle trace of the FPU integer response path
  initial begin
    if ($test$plusargs("dbg")) forever begin
      @(negedge clk);
      $display("  [dbg %0t] fpu req_v=%0b ll_iresp v=%0b r=%0b rob=%0d | q.deq_v=%0b q.empty=%0b arb.in0_r=%0b | fu_types=%03h",
               $time, fpu_if.req_valid, fpu_if.ll_iresp_valid, fpu_if.ll_iresp_ready, fpu_if.ll_iresp_uop.rob_idx,
               u_fpu._queue_io_deq_valid, u_fpu._queue_io_empty, u_fpu._resp_arb_io_in_0_ready, fpu_if.fu_types);
    end
  end

  //---------------------------------------------------------------- CSR access helpers (RAL-agent path)
  // one-cycle command on the rw port; rdata is combinational and sampled in the same cycle
  task automatic csr_op(input bit [2:0] cmd, input bit [11:0] addr, input bit [63:0] wdata, output bit [63:0] rdata,
                        output bit rd_ill, output bit wr_ill);
    @(posedge clk); #2;
    // decode first (what the core's decode stage would ask): CSRRW rd=x1, rs1=x1 with this address
    csr_if.decode_inst = {addr, 5'd1, 3'b001, 5'd1, 7'b1110011};
    #1; rd_ill = csr_if.decode_read_illegal; wr_ill = csr_if.decode_write_illegal;
    csr_if.agt_valid = 1; csr_if.agt_addr = addr; csr_if.agt_cmd = cmd; csr_if.agt_wdata = wdata;
    @(negedge clk); rdata = csr_if.rw_rdata;
    @(posedge clk); #2;
    csr_if.agt_valid = 0; csr_if.agt_cmd = CSR_N;
  endtask
  task automatic csr_read(input bit [11:0] addr, output bit [63:0] rdata);
    bit a, b; csr_op(CSR_R, addr, 0, rdata, a, b);
  endtask
  task automatic csr_write(input bit [11:0] addr, input bit [63:0] wdata);
    bit [63:0] r; bit a, b; csr_op(CSR_W, addr, wdata, r, a, b);
  endtask

  typedef struct { bit [11:0] addr; string name; } csr_desc_t;
  typedef struct { bit [11:0] addr; bit [63:0] v; } probe_t;
  csr_desc_t csr_list[] = '{
    '{12'h001, "fflags"}, '{12'h002, "frm"}, '{12'h003, "fcsr"},
    '{12'h100, "sstatus"}, '{12'h104, "sie"}, '{12'h105, "stvec"}, '{12'h106, "scounteren"}, '{12'h140, "sscratch"},
    '{12'h141, "sepc"}, '{12'h142, "scause"}, '{12'h143, "stval"}, '{12'h144, "sip"}, '{12'h180, "satp"},
    '{12'hF11, "mvendorid"}, '{12'hF12, "marchid"}, '{12'hF13, "mimpid"}, '{12'hF14, "mhartid"},
    '{12'h300, "mstatus"}, '{12'h301, "misa"}, '{12'h302, "medeleg"}, '{12'h303, "mideleg"}, '{12'h304, "mie"},
    '{12'h305, "mtvec"}, '{12'h306, "mcounteren"}, '{12'h320, "mcountinhibit"}, '{12'h323, "mhpmevent3"}, '{12'h328, "mhpmevent8"},
    '{12'h340, "mscratch"}, '{12'h341, "mepc"}, '{12'h342, "mcause"}, '{12'h343, "mtval"}, '{12'h344, "mip"},
    '{12'h3B0, "pmpaddr0"}, '{12'h3B7, "pmpaddr7"}, '{12'h3A0, "pmpcfg0"}, '{12'h3A2, "pmpcfg2"},
    '{12'hB00, "mcycle"}, '{12'hB02, "minstret"}, '{12'hB03, "mhpmcounter3"}, '{12'hB08, "mhpmcounter8"},
    '{12'h7A0, "tselect"}, '{12'h7A1, "tdata1"}, '{12'h7A2, "tdata2"}, '{12'h7B0, "dcsr"}, '{12'h7B1, "dpc"}, '{12'h7B2, "dscratch0"},
    '{12'h7C1, "custom_7c1"}, '{12'hC00, "cycle"}, '{12'hC01, "time"}, '{12'hC02, "instret"}, '{12'hC03, "hpmcounter3"},
    '{12'h008, "vstart(absent)"}, '{12'h7FF, "unknown_7ff"} };

  bit [63:0] csr_reset_val[64];

  task automatic csr_phase();
    bit [63:0] r0, r1, r2, r3, x;
    bit rd_ill, wr_ill, a, b;
    boom_exe_txn t;
    $display("\nCSR characterisation (value at reset, decode legality, read-back after W(all-ones) / after W(0)):");
    $display("  %-14s %-5s %-18s %-6s %-6s %-18s %-18s", "name", "addr", "reset", "rd_ill", "wr_ill", "after_W(ones)", "after_W(zeros)");
    foreach (csr_list[i]) begin
      csr_op(CSR_R, csr_list[i].addr, 0, r0, rd_ill, wr_ill);
      if (rd_ill) begin
        $display("  %-14s %03h   %-18s %-6b %-6b", csr_list[i].name, csr_list[i].addr, "-", rd_ill, wr_ill);
        continue;
      end
      if (csr_list[i].addr == 12'h3A0) begin   // pmpcfg0: all-ones would set the lock bits for good -> probe without L
        csr_write(csr_list[i].addr, 64'h7F7F_7F7F_7F7F_7F7F); csr_read(csr_list[i].addr, r1);
      end else begin
        csr_write(csr_list[i].addr, '1);  csr_read(csr_list[i].addr, r1);
      end
      csr_write(csr_list[i].addr, '0);  csr_read(csr_list[i].addr, r2);
      csr_write(csr_list[i].addr, r0);  csr_read(csr_list[i].addr, r3);
      $display("  %-14s %03h   %016h   %-6b %-6b %016h   %016h%s", csr_list[i].name, csr_list[i].addr, csr_reset_val[i], rd_ill, wr_ill,
               r1, r2, (r3 != r0 && csr_list[i].addr != 12'hB00 && csr_list[i].addr != 12'hC00) ? "  (restore differs!)" : "");
    end
    // satp is WARL on the mode field: only Bare(0) / Sv39(8) are accepted, asid not implemented, ppn 20 bits
    begin
      bit [63:0] probes[] = '{64'h8000_0000_000F_FFFF, 64'h8FFF_FFFF_FFFF_FFFF, 64'h9000_0000_0000_0001, 64'h0000_0000_0000_0001, 64'h0800_0000_0000_0000};
      foreach (probes[i]) begin csr_write(12'h180, probes[i]); csr_read(12'h180, r1); $display("  satp <= %016h -> %016h", probes[i], r1); end
      csr_write(12'h180, 0);
    end
    // WARL probes: sign extension widths of the address-holding CSRs, MPP legalisation, sie/sip vs mideleg
    begin
      probe_t pr[] = '{ '{12'h341, 64'h0000_0080_0000_0000}, '{12'h341, 64'h0000_007F_FFFF_FFFE}, '{12'h341, 64'h0000_0040_0000_0000},
                        '{12'h141, 64'h0000_0080_0000_0000}, '{12'h141, 64'h0000_007F_FFFF_FFFE},
                        '{12'h343, 64'h0000_0080_0000_0000}, '{12'h343, 64'h0000_007F_FFFF_FFFF}, '{12'h143, 64'h0000_0080_0000_0000},
                        '{12'h105, 64'h0000_0040_0000_0000}, '{12'h105, 64'h0000_003F_FFFF_FFFD}, '{12'h105, 64'h0000_0000_0000_0003},
                        '{12'h305, 64'h0000_0001_0000_0000}, '{12'h305, 64'h0000_0000_FFFF_FFFF}, '{12'h305, 64'h0000_0000_0000_0003},
                        '{12'h305, 64'h0000_0000_FFFF_FFFE}, '{12'h105, 64'h0000_003F_FFFF_FFFE}, '{12'h305, 64'h0000_0000_0000_00FD},
                        '{12'h300, 64'h0000_0000_0000_1000}, '{12'h300, 64'h0000_0000_0000_0800}, '{12'h300, 64'h0000_0000_0000_1800},
                        '{12'h300, 64'h0000_0000_0000_6000}, '{12'h300, 64'h0000_0000_0000_2000}, '{12'h300, 64'h0000_0000_0000_4000},
                        '{12'h342, 64'h8000_0000_0000_00FF}, '{12'h142, 64'h8000_0000_0000_00FF},
                        '{12'h3A0, 64'h0000_0000_0000_0080}, '{12'h3A0, 64'h0000_0000_0000_0018},
                        '{12'h104, 64'h0000_0000_0000_0222}, '{12'h303, 64'h0000_0000_0000_0222}, '{12'h104, 64'h0000_0000_0000_0FFF},
                        '{12'h144, 64'h0000_0000_0000_0FFF}, '{12'h344, 64'h0000_0000_0000_0FFF}, '{12'h144, 64'h0000_0000_0000_0000},
                        '{12'h344, 64'h0}, '{12'h303, 64'h0}, '{12'h304, 64'h0FFF}, '{12'h104, 64'h0}, '{12'h304, 64'h0},
                        '{12'h323, 64'hFFFF_FFFF_FFFF_FFFF}, '{12'h7C1, 64'hFFFF_FFFF_FFFF_FFFF}, '{12'h7C1, 64'h0}, '{12'h323, 64'h0},
                        '{12'h300, 64'h0000_0000_0000_3800} };
      foreach (pr[i]) begin
        csr_write(pr[i].addr, pr[i].v); csr_read(pr[i].addr, r1);
        $display("  probe %03h <= %016h -> %016h%s", pr[i].addr, pr[i].v, r1, (pr[i].addr == 12'h104 || pr[i].addr == 12'h144) ? "  (sie/sip)" : "");
        if (pr[i].addr == 12'h104) begin csr_read(12'h304, r2); $display("        mie = %016h", r2); end
        if (pr[i].addr == 12'h144) begin csr_read(12'h344, r2); $display("        mip = %016h", r2); end
      end
      csr_write(12'h341, 0); csr_write(12'h141, 0); csr_write(12'h343, 0); csr_write(12'h143, 0); csr_write(12'h105, 0); csr_write(12'h305, 0);
      csr_write(12'h342, 0); csr_write(12'h142, 0);
    end
    // --- RMW semantics on mscratch
    csr_write(12'h340, 64'hF0); csr_op(CSR_S, 12'h340, 64'h0F, x, a, b); csr_read(12'h340, r1);
    csr_op(CSR_C, 12'h340, 64'hF0, x, a, b); csr_read(12'h340, r2);
    if (r1 != 64'hFF || r2 != 64'h0F || x != 64'hFF) begin errors++; $display("ERROR: CSR set/clear semantics: after S %016h (exp ff), after C %016h (exp 0f), C rdata %016h", r1, r2, x); end
    else $display("  RMW ok: W f0, S 0f -> %02h, C f0 -> %02h (rdata of C = %02h = old value)", r1, r2, x);
    // --- fcsr aliasing: fflags = fcsr[4:0], frm = fcsr[7:5]
    csr_write(12'h003, 64'hE7); csr_read(12'h001, r1); csr_read(12'h002, r2); csr_read(12'h003, r3);
    if (r1 != 64'h07 || r2 != 64'h07 || r3 != 64'hE7) begin errors++; $display("ERROR: fcsr alias: fcsr=e7 -> fflags %0h frm %0h fcsr %0h", r1, r2, r3); end
    csr_write(12'h002, 64'h2); csr_write(12'h001, 64'h11); csr_read(12'h003, r3);
    if (r3 != 64'h51) begin errors++; $display("ERROR: fcsr alias: frm=2, fflags=11 -> fcsr %0h (exp 51)", r3); end
    if (csr_if.fcsr_rm != 3'd2) begin errors++; $display("ERROR: fcsr_rm output %0d after frm=2", csr_if.fcsr_rm); end
    $display("  fcsr alias ok: fcsr=e7 -> fflags=%0h frm=%0h; frm=2,fflags=11 -> fcsr=%0h; fcsr_rm=%0d", r1, r2, r3, csr_if.fcsr_rm);
    // --- flags side effect: fdiv.s 1/0 -> DZ, then fadd inexact -> NX accumulates
    csr_write(12'h003, 64'h0);
    t = new("t"); fill(t, OP_FDIV_S); t.rs1 = box_s(S_ONE); t.rs2 = box_s(S_POS_ZERO); t.rm = RM_RNE; t.lower(); ref_model.predict(t); run_fpu(t); check(t);
    csr_read(12'h001, r1);
    t = new("t"); fill(t, OP_FADD_D); t.rs1 = D_ONE; t.rs2 = 64'h3CA0_0000_0000_0000; t.rm = RM_RNE; t.lower(); ref_model.predict(t); run_fpu(t); check(t);
    csr_read(12'h001, r2);
    t = new("t"); fill(t, OP_FCVT_S_L); t.rs1 = 64'h7FFF_FFFF_FFFF_FFFF; t.rm = RM_RNE; t.lower(); ref_model.predict(t); run_alu0(t); check(t);   // I2F on alu0 -> NX via ll_fresp
    csr_read(12'h001, r3);
    if (r1 != 64'h08 || r2 != 64'h09 || r3 != 64'h09) begin errors++; $display("ERROR: fflags accumulation: after fdiv %0h (exp 8), after fadd %0h (exp 9), after fcvt %0h (exp 9)", r1, r2, r3); end
    else $display("  fflags side effect ok: fdiv.s 1/0 -> %02h, + inexact fadd.d -> %02h, + inexact fcvt.s.l (alu0 ll_fresp) -> %02h", r1, r2, r3);
    // --- frm from the CSR drives dynamic rounding: fcvt.w.s(1.5) RM_DYN with frm = RTZ -> 1, RUP -> 2
    fpu_if.use_csr_rm = 1;
    csr_write(12'h002, RM_RTZ);
    t = new("t"); fill(t, OP_FCVT_W_S); t.rs1 = box_s(32'h3FC0_0000); t.rm = RM_DYN; t.fcsr_rm = RM_RTZ; t.lower(); ref_model.predict(t); run_fpu(t); check(t); r1 = obs_data;
    csr_write(12'h002, RM_RUP);
    t = new("t"); fill(t, OP_FCVT_W_S); t.rs1 = box_s(32'h3FC0_0000); t.rm = RM_DYN; t.fcsr_rm = RM_RUP; t.lower(); ref_model.predict(t); run_fpu(t); check(t); r2 = obs_data;
    fpu_if.use_csr_rm = 0;
    if (r1 != 1 || r2 != 2) begin errors++; $display("ERROR: dynamic rm from CSR: RTZ -> %0d (exp 1), RUP -> %0d (exp 2)", r1, r2); end
    else $display("  frm -> FPU ok: fcvt.w.s(1.5, rm=DYN) with frm=RTZ -> %0d, frm=RUP -> %0d", r1, r2);
    // --- CSR instruction through the pipeline (alu1 CSR uop -> CSRFile rw port), rdata = old value
    csr_write(12'h340, 64'hDEAD_BEEF_0000_1234);
    t = new("t"); fill(t, OP_CSRRW); t.csr_addr = 12'h340; t.rs1 = 64'hCAFE_F00D_5555_AAAA; t.lower(); ref_model.predict(t);
    fork
      run_alu1(t);
      begin : watch_rw
        x = 0;
        repeat (10) begin @(negedge clk); if (csr_if.rw_cmd == CSR_W && csr_if.rw_addr == 12'h340) x = csr_if.rw_rdata; end
      end
    join
    check(t);
    csr_read(12'h340, r1);
    if (r1 != 64'hCAFE_F00D_5555_AAAA || x != 64'hDEAD_BEEF_0000_1234) begin errors++; $display("ERROR: pipeline csrrw: mscratch %016h (exp cafef00d5555aaaa), old value seen %016h", r1, x); end
    else $display("  pipeline CSRRW ok: alu1 iresp -> CSRFile: mscratch=%016h, rd(old)=%016h", r1, x);
    t = new("t"); fill(t, OP_CSRRSI); t.csr_addr = 12'h340; t.zimm = 5'h11; t.lower(); ref_model.predict(t); run_alu1(t); check(t);
    csr_read(12'h340, r2);
    if (r2 != (64'hCAFE_F00D_5555_AAAA | 64'h11)) begin errors++; $display("ERROR: pipeline csrrsi: %016h", r2); end
    else $display("  pipeline CSRRSI ok: mscratch=%016h", r2);
  endtask

  //---------------------------------------------------------------- phase 4: Spike trace replay
  // Real programs (riscv-tests) executed by Spike, replayed instruction by instruction through the
  // execution units with operands from the replayed architectural state; Spike's committed rd /
  // fflags / next-pc are the second golden reference (dpi/boom_spike_trace.c). CSR instructions go
  // through ALU1 into the real CSRFile, and the value the core would write to rd (rw_rdata) is
  // compared with Spike's — so the fflags a program reads back with frflags must have really
  // accumulated in the hardware from the FPU / I2F flag side effects.
  import "DPI-C" function int    spike_trace_register_op(input int id, input string name);
  import "DPI-C" function int    spike_trace_load(input string path);
  import "DPI-C" function int    spike_trace_replayable();
  import "DPI-C" function int    spike_trace_class_count(input int cls);
  import "DPI-C" function int    spike_trace_get(input int i, output longint pc, output int insn, output int kind, output int op, output int is_csr,
                                                 output longint rs1, output longint rs2, output longint rs3,
                                                 output int imm, output int rm, output int zimm, output int csr,
                                                 output int rd, output int has_rd, output int dst_fp, output longint rd_val, output longint next_pc,
                                                 output int fl_before, output int fl_after, output int frm,
                                                 output int csr_wr_valid, output int csr_wr_num, output longint csr_wr_val);

  int sp_replayed = 0, sp_skipped = 0, sp_csr = 0, sp_data_chk = 0, sp_flag_chk = 0, sp_br_chk = 0, sp_csr_chk = 0, sp_errors = 0;
  bit [11:0] sp_csr_cmp[] = '{12'h001, 12'h002, 12'h003, 12'h140, 12'h141, 12'h143, 12'h340, 12'h341, 12'h343, 12'hF14};

  function automatic bit sp_csr_comparable(bit [11:0] a);
    foreach (sp_csr_cmp[i]) if (sp_csr_cmp[i] == a) return 1;
    return 0;
  endfunction

  task automatic spike_phase(string path);
    int n;
    longint pc, rs1, rs2, rs3, rd_val, next_pc, csr_wr_val;
    int insn, kind, op, is_csr, imm, rm, zimm, csr, rd, has_rd, dst_fp, fl_before, fl_after, frm, csr_wr_valid, csr_wr_num;
    boom_exe_txn t;
    bit [63:0] rw_seen;
    bit rw_hit;
    for (int k = 0; k < OP_NUM; k++) begin exe_op_e o = exe_op_e'(k); void'(spike_trace_register_op(k, o.name())); end
    n = spike_trace_load(path);
    if (n < 0) begin errors++; $display("ERROR: cannot open Spike log %s", path); return; end
    $display("\nSpike trace replay: %s — %0d committed instructions, %0d replayable (alu=%0d br/jmp=%0d muldiv=%0d csr=%0d fp=%0d f2i=%0d i2f=%0d, not replayable=%0d)",
             path, n, spike_trace_replayable(), spike_trace_class_count(0), spike_trace_class_count(1), spike_trace_class_count(2),
             spike_trace_class_count(3), spike_trace_class_count(4), spike_trace_class_count(5), spike_trace_class_count(6), spike_trace_class_count(7));
    fpu_if.use_csr_rm = 1; alu0_if.use_csr_rm = 1; alu1_if.use_csr_rm = 1;
    for (int i = 0; i < n; i++) begin
      string tag;
      if (!spike_trace_get(i, pc, insn, kind, op, is_csr, rs1, rs2, rs3, imm, rm, zimm, csr, rd, has_rd, dst_fp, rd_val, next_pc,
                           fl_before, fl_after, frm, csr_wr_valid, csr_wr_num, csr_wr_val)) break;
      if (kind == 0) begin sp_skipped++; continue; end
      t = new("t");
      fill(t, exe_op_e'(op));                       // random rob/pdst/ftq/prediction, then overwrite the architectural part
      t.rs1 = rs1; t.rs2 = rs2; t.rs3 = rs3; t.imm = imm; t.rm = rm[2:0]; t.zimm = zimm[4:0]; t.csr_addr = csr[11:0];
      t.fcsr_rm = frm[2:0]; t.pc = pc[39:0]; t.is_rvc = 0; t.edge_inst = 0; t.deliberately_unboxed = 0;
      if (t.op == OP_JALR && $urandom_range(1)) begin
        bit [5:0] lob_x = t.pc[5:0] ^ (t.ftq_start_bank ? 6'(BANK_BYTES) : 6'd0);
        t.ftq_next_pc = {next_pc[39:1], 1'b0}; t.ftq_next_val = 1; t.ftq_cfi_idx_valid = 1; t.ftq_cfi_idx = lob_x[2:1];
      end
      t.lower();
      ref_model.predict(t);
      tag = $sformatf("trace#%0d pc=%016h %s", i, pc, t.op.name());
      sp_replayed++;
      if (is_csr) begin
        sp_csr++;
        rw_hit = 0; rw_seen = 0;
        fork
          run_alu1(t);
          begin : watch_rw
            repeat (12) begin
              @(negedge clk);
              if (csr_if.rw_cmd != CSR_N && !csr_if.agt_valid && csr_if.rw_addr == t.csr_addr) begin rw_hit = 1; rw_seen = csr_if.rw_rdata; end
            end
          end
        join
        check(t);
        if (!rw_hit) begin errors++; sp_errors++; $display("ERROR: %s: CSR instruction never reached the CSRFile rw port", tag); end
        else if (has_rd && sp_csr_comparable(t.csr_addr)) begin
          sp_csr_chk++;
          if (rw_seen != rd_val) begin errors++; sp_errors++; $display("ERROR: %s csr=%03h: CSRFile rdata %016h, Spike rd %016h", tag, t.csr_addr, rw_seen, rd_val); end
        end
        repeat (2) @(posedge clk);
      end else begin
        case (t.ctrl.exu)
          EXU_ALU0: run_alu0(t);
          EXU_ALU1: run_alu1(t);
          default:  run_fpu(t);
        endcase
        check(t);                                   // SoftFloat / ALU model
        if (has_rd) begin                           // Spike's rd
          bit ok;
          sp_data_chk++;
          ok = got_rsp && (obs_data == rd_val);
          if (!ok) begin errors++; sp_errors++; $display("ERROR: %s rs1=%016h rs2=%016h rs3=%016h imm=%08h: DUT %016h, Spike rd %016h (model %016h)", tag, t.rs1, t.rs2, t.rs3, t.imm, obs_data, rd_val, t.exp_data); end
        end
        if (t.exp_flags_valid && got_flags) begin  // Spike's fflags accumulator
          bit [4:0] acc = fl_before[4:0] | obs_flags, exp_acc = fl_after[4:0];
          if (t.waived_nv) begin acc[4] = 0; exp_acc[4] = 0; end
          sp_flag_chk++;
          if (acc != exp_acc) begin errors++; sp_errors++; $display("ERROR: %s: fflags acc %05b | dut %05b != Spike acc %05b", tag, fl_before[4:0], obs_flags, fl_after[4:0]); end
        end
        if (t.exp_brinfo_valid && got_br) begin     // Spike's next pc
          bit exp_taken = (next_pc != pc + 4);
          sp_br_chk++;
          if (obs_taken != exp_taken || (t.ctrl.is_jalr && exp_taken && obs_jalr != (ref_model.encode_vaddr(next_pc) & ~40'h1))) begin
            errors++; sp_errors++; $display("ERROR: %s: taken=%0b jalr_tgt=%010h, Spike next pc %016h", tag, obs_taken, obs_jalr, next_pc);
          end
        end
      end
      if (errors > max_errors) begin $display("too many errors, stopping"); break; end
    end
    fpu_if.use_csr_rm = 0; alu0_if.use_csr_rm = 0; alu1_if.use_csr_rm = 0;
    $display("  replayed=%0d (csr=%0d) not-replayable=%0d | spike checks: data=%0d flags=%0d branch=%0d csr_rd=%0d | spike errors=%0d",
             sp_replayed, sp_csr, sp_skipped, sp_data_chk, sp_flag_chk, sp_br_chk, sp_csr_chk, sp_errors);
  endtask

  //---------------------------------------------------------------- main
  boom_exe_ref_model ref_model;
  initial begin
    exe_op_e o;
    boom_exe_txn t;
    void'($value$plusargs("n=%d", n_per_op));
    void'($value$plusargs("seed=%d", seed));
    void'($value$plusargs("max_errors=%d", max_errors));
    void'($value$plusargs("op=%s", only_op));
    void'($value$plusargs("spike_log=%s", spike_log));
    spike_only = $test$plusargs("spike_only");
    void'($urandom(seed));
    $display("smoke: %0d ops x %0d, seed %0d, fp backend: %s", OP_NUM, n_per_op, seed, boom_fp_ref_backend());
    ref_model = new();
    alu0_if.req_valid = 0; alu1_if.req_valid = 0; fpu_if.req_valid = 0;
    alu0_if.req_kill = 0; alu1_if.req_kill = 0; fpu_if.req_kill = 0;
    alu0_if.flush_bcast = 0; alu1_if.flush_bcast = 0; fpu_if.flush_bcast = 0;
    alu0_if.br_resolve_mask = 0; alu1_if.br_resolve_mask = 0; fpu_if.br_resolve_mask = 0;
    alu0_if.br_mispredict_mask = 0; alu1_if.br_mispredict_mask = 0; fpu_if.br_mispredict_mask = 0;
    alu0_if.ll_fresp_ready = 1; fpu_if.ll_iresp_ready = 1; alu0_if.ll_iresp_ready = 1; alu1_if.ll_iresp_ready = 1;
    alu0_if.req_uop = '0; alu1_if.req_uop = '0; fpu_if.req_uop = '0;
    alu0_if.rs1_data = 0; alu0_if.rs2_data = 0; alu0_if.rs3_data = 0; alu1_if.rs1_data = 0; alu1_if.rs2_data = 0; alu1_if.rs3_data = 0;
    fpu_if.rs1_data = 0; fpu_if.rs2_data = 0; fpu_if.rs3_data = 0;
    alu0_if.fcsr_rm_drv = 0; alu1_if.fcsr_rm_drv = 0; fpu_if.fcsr_rm_drv = 0;
    alu0_if.use_csr_rm = 0; alu1_if.use_csr_rm = 0; fpu_if.use_csr_rm = 0;
    alu0_if.ftq_pc = 0; alu0_if.ftq_next_val = 0; alu0_if.ftq_next_pc = 0; alu0_if.ftq_entry_cfi_idx_valid = 0; alu0_if.ftq_entry_cfi_idx_bits = 0; alu0_if.ftq_entry_start_bank = 0;
    alu1_if.ftq_pc = 0; alu1_if.ftq_next_val = 0; alu1_if.ftq_next_pc = 0; alu1_if.ftq_entry_cfi_idx_valid = 0; alu1_if.ftq_entry_cfi_idx_bits = 0; alu1_if.ftq_entry_start_bank = 0;
    fpu_if.ftq_pc = 0; fpu_if.ftq_next_val = 0; fpu_if.ftq_next_pc = 0; fpu_if.ftq_entry_cfi_idx_valid = 0; fpu_if.ftq_entry_cfi_idx_bits = 0; fpu_if.ftq_entry_start_bank = 0;
    iq_if.flush_pipeline = 0; iq_if.br_resolve_mask = 0; iq_if.br_mispredict_mask = 0; iq_if.ld_miss = 0;
    foreach (iq_if.dis_valid[i]) begin iq_if.dis_valid[i] = 0; iq_if.dis_uop[i] = '0; end
    foreach (iq_if.wakeup_valid[i]) begin iq_if.wakeup_valid[i] = 0; iq_if.wakeup_pdst[i] = 0; end
    iq_if.spec_ld_wakeup_valid[0] = 0; iq_if.spec_ld_wakeup_pdst[0] = 0; iq_if.fu_types[0] = 10'h10B; iq_if.fu_types[1] = 10'h031;
    csr_if.agt_valid = 0; csr_if.agt_addr = 0; csr_if.agt_cmd = CSR_N; csr_if.agt_wdata = 0; csr_if.decode_inst = 0;
    csr_if.irq_debug = 0; csr_if.irq_mtip = 0; csr_if.irq_msip = 0; csr_if.irq_meip = 0; csr_if.irq_seip = 0; csr_if.hartid = 0;
    csr_if.exception = 0; csr_if.retire = 0; csr_if.cause = 0; csr_if.pc = 0; csr_if.tval = 0;
    repeat (10) @(posedge clk);
    #1 rst = 0;
    repeat (5) @(posedge clk);
    // CSRFile: mstatus.FS resets to 0 (FP off). The core would trap on any FP instruction, and
    // CSRFile asserts (CSR.scala:1203) if FP flags arrive while FS == 0 -> enable FP first, as the
    // boot code / OS would (mstatus.FS = 1 "Initial").
    foreach (csr_list[i]) begin bit a, b; csr_op(CSR_R, csr_list[i].addr, 0, csr_reset_val[i], a, b); end
    begin
      bit [63:0] ms;
      csr_read(12'h300, ms);
      $display("mstatus at reset = %016h (FS=%0d) -> writing FS=1", ms, ms[14:13]);
      csr_write(12'h300, ms | 64'h2000);
    end

    if (spike_only) n_per_op = 0;
    for (int k = 0; k < OP_NUM; k++) begin
      o = exe_op_e'(k);
      if (only_op != "" && o.name() != only_op) continue;
      for (int i = 0; i < n_per_op; i++) begin
        t = new("t");
        fill(t, o);
        t.lower();
        ref_model.predict(t);
        case (t.ctrl.exu)
          EXU_ALU0: run_alu0(t);
          EXU_ALU1: run_alu1(t);
          default:  run_fpu(t);
        endcase
        check(t);
        if (errors > max_errors) begin $display("too many errors, stopping"); break; end
      end
      if (errors > max_errors) break;
    end
    //------------------------------------------------------------ phase 2: kill / flush timing
    // For every representative op and every k in 0..lat+2: branch-mispredict (kind 1) or flush
    // (kind 2) the uop k cycles after issue and record whether a response still appears.
    // Pipelined units must: drop the uop for a mispredict at any k <= lat, drop it for a flush
    // at k < lat, and still respond for a flush in the response cycle (k == lat).
    if (!spike_only) begin
      exe_op_e kops[] = '{OP_ADD, OP_MUL, OP_JAL, OP_ADDI, OP_CSRRW, OP_DIV, OP_FADD_D, OP_FMADD_S, OP_FEQ_D, OP_FCVT_W_S, OP_FCVT_D_W, OP_FMV_W_X, OP_FDIV_S, OP_FSQRT_D};
      $display("\nkill/flush timing (r = response seen, - = squashed; k = cycles after issue):");
      foreach (kops[i]) begin
        string row_br = "", row_fl = "";
        int lat_nom = decode_op(kops[i]).latency;
        int kmax = (lat_nom == 0) ? 8 : lat_nom + 2;
        bit pipelined = (lat_nom > 0) && (decode_op(kops[i]).rsp_port inside {PORT_IRESP, PORT_FRESP});
        for (int kind = 1; kind <= 2; kind++) for (int kk = 0; kk <= kmax; kk++) begin
          t = new("t"); fill(t, kops[i]); t.br_mask = 12'h001; t.lower(); ref_model.predict(t);
          case (t.ctrl.exu) EXU_ALU0: run_alu0(t, kind, kk); EXU_ALU1: run_alu1(t, kind, kk); default: run_fpu(t, kind, kk); endcase
          if (kind == 1) row_br = {row_br, got_rsp ? "r" : "-"}; else row_fl = {row_fl, got_rsp ? "r" : "-"};
          if (pipelined) begin
            bit exp_rsp = (kind == 1) ? (kk > lat_nom) : (kk >= lat_nom);
            if (got_rsp != exp_rsp) begin
              errors++;
              $display("ERROR: %s %s at k=%0d: response %s, expected %s", kops[i].name(), kind == 1 ? "mispredict" : "flush", kk, got_rsp ? "seen" : "squashed", exp_rsp ? "seen" : "squashed");
            end
          end
          if (got_rsp && obs_data != t.exp_data) begin errors++; $display("ERROR: %s (kill test) data %016h expected %016h", kops[i].name(), obs_data, t.exp_data); end
        end
        $display("  %-12s lat=%0d %-11s mispredict@k: %s   flush@k: %s", kops[i].name(), lat_nom, decode_op(kops[i]).rsp_port.name(), row_br, row_fl);
      end
    end

    //------------------------------------------------------------ phase 3: CSRFile characterisation
    if (!spike_only) csr_phase();

    //------------------------------------------------------------ phase 4: Spike trace replay (+spike_log=a.log[,b.log])
    if (spike_log != "") begin
      string cur = "";
      for (int i = 0; i <= spike_log.len(); i++) begin
        if (i == spike_log.len() || spike_log[i] == ",") begin
          if (cur != "") spike_phase(cur);
          cur = "";
        end else cur = {cur, string'(spike_log[i])};
      end
    end

    $display("\nlatency (op: cycles=count):");
    foreach (lat_hist[op]) begin
      string s;
      s = "";
      foreach (lat_hist[op][l]) s = {s, $sformatf(" %0d=%0d", l, lat_hist[op][l])};
      $display("  %-12s nominal=%0d :%s", op.name(), decode_op(op).latency, s);
    end
    $display("\nsmoke: checked=%0d errors=%0d model_errors=%0d latency-mismatches=%0d -> %s",
             checked, errors, uvm_pkg::uvm_shim_errors, lat_mismatch, (errors + uvm_pkg::uvm_shim_errors) == 0 ? "PASS" : "FAIL");
    $finish;
  end
endmodule

//=============================================================================
// boom_spike_oracle.sv — expectation table for Spike-trace replay
//-----------------------------------------------------------------------------
// The sequence (boom_spike_trace_seq) knows what Spike computed for every
// instruction; the scoreboards only see what the monitors reconstruct from the
// bus. This object is the hand-over point:
//   * exp[unit][rob_idx]  — the sequence parks its transaction (with spike_*
//                           filled) before sending it; the unit's scoreboard
//                           picks it up when the monitor reports the request
//                           and attaches the Spike expectation to its own copy
//   * csr_q               — pipeline CSR instructions in program order; the
//                           CSR checker compares the CSRFile's rdata (= what
//                           the core would write to rd) with Spike's rd value
//   * outstanding         — requests sent but not yet answered / squashed, so
//                           the sequence can drain the pipeline before a CSR
//                           instruction (BOOM serialises them the same way)
// It also owns the result counters that the base test prints.
//=============================================================================
class boom_spike_oracle extends uvm_object;
  `uvm_object_utils(boom_spike_oracle)

  boom_exe_txn exp[3][bit [5:0]];
  boom_exe_txn csr_q[$];
  int          outstanding[3];

  // CSRs whose value is architecturally identical between Spike and the RTL in this
  // environment (no counters, no implementation-defined id / misa / mstatus layout)
  bit [11:0] csr_cmp_addrs[$] = '{12'h001, 12'h002, 12'h003, 12'h140, 12'h141, 12'h143, 12'h340, 12'h341, 12'h343, 12'hF14};

  int unsigned n_attached, n_data_chk, n_data_err, n_flag_chk, n_flag_err, n_br_chk, n_br_err, n_csr_chk, n_csr_err, n_csr_skipped, n_orphan;

  function new(string name = "boom_spike_oracle"); super.new(name); endfunction

  function void park(boom_exe_txn t);
    exu_id_e u = t.unit();
    if (exp[u].exists(t.rob_idx)) begin
      n_orphan++;
      `uvm_warning("SPIKE", $sformatf("%s rob=%0d: expectation overwritten before the monitor consumed it (trace #%0d)", u.name(), t.rob_idx, exp[u][t.rob_idx].spike_idx))
    end
    exp[u][t.rob_idx] = t;
    outstanding[u]++;
  endfunction

  // called by the scoreboard for every request the monitor reports on `unit`
  function void attach(exu_id_e unit, boom_exe_txn mon_t);
    if (!exp[unit].exists(mon_t.rob_idx)) return;
    mon_t.copy_spike_from(exp[unit][mon_t.rob_idx]);
    exp[unit].delete(mon_t.rob_idx);
    n_attached++;
  endfunction

  function void retire(exu_id_e unit);
    if (outstanding[unit] > 0) outstanding[unit]--;
  endfunction

  function int total_outstanding();
    return outstanding[0] + outstanding[1] + outstanding[2];
  endfunction

  function bit csr_comparable(bit [11:0] addr);
    foreach (csr_cmp_addrs[i]) if (csr_cmp_addrs[i] == addr) return 1;
    return 0;
  endfunction

  function int unsigned n_err();
    return n_data_err + n_flag_err + n_br_err + n_csr_err;
  endfunction

  function string summary();
    return $sformatf("spike: attached=%0d data=%0d/%0d flags=%0d/%0d branch=%0d/%0d csr_rd=%0d/%0d (csr skipped=%0d) errors=%0d",
                     n_attached, n_data_chk - n_data_err, n_data_chk, n_flag_chk - n_flag_err, n_flag_chk,
                     n_br_chk - n_br_err, n_br_chk, n_csr_chk - n_csr_err, n_csr_chk, n_csr_skipped, n_err());
  endfunction
endclass : boom_spike_oracle


//=============================================================================
// boom_spike_csr_checker — compares the CSRFile's read data for pipeline CSR
// instructions with the rd value Spike logged (end-to-end: FP flags raised by
// the FPU / I2F units must have accumulated in the real fflags register by the
// time the program reads it back with frflags / csrr fcsr)
//=============================================================================
class boom_spike_csr_checker extends uvm_subscriber #(boom_csr_txn);
  `uvm_component_utils(boom_spike_csr_checker)
  boom_spike_oracle oracle;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void write(boom_csr_txn t);
    boom_exe_txn e;
    if (oracle == null || !t.from_pipeline || oracle.csr_q.size() == 0) return;
    e = oracle.csr_q.pop_front();
    if (e.csr_addr != t.addr) begin
      oracle.n_csr_err++;
      `uvm_error("SPIKE", $sformatf("CSR access order: CSRFile saw %03h, trace #%0d expected %s %03h", t.addr, e.spike_idx, e.op.name(), e.csr_addr))
      return;
    end
    if (!e.spike_has_rd) return;                          // rd = x0: nothing to compare
    if (!oracle.csr_comparable(t.addr)) begin oracle.n_csr_skipped++; return; end
    oracle.n_csr_chk++;
    if (t.rdata !== e.spike_rd_val) begin
      oracle.n_csr_err++;
      `uvm_error("SPIKE", $sformatf("CSR READ MISMATCH trace #%0d %s csr=%03h: CSRFile rdata %016h, Spike rd %016h", e.spike_idx, e.op.name(), t.addr, t.rdata, e.spike_rd_val))
    end else
      `uvm_info("SPIKE", $sformatf("csr ok trace #%0d %s csr=%03h -> %016h", e.spike_idx, e.op.name(), t.addr, t.rdata), UVM_HIGH)
  endfunction
endclass : boom_spike_csr_checker

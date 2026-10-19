//=============================================================================
// boom_exe_base_test.sv — base test: builds cfg + env, orchestrates sequences
//-----------------------------------------------------------------------------
// Most tests only differ in *which* sequences run and with *which* knobs, so
// the base test owns the whole run flow and derived tests just set a few
// strings/integers (see boom_exe_tests.sv). Everything can also be overridden
// from the command line:
//   +n_txn=<n>            number of execute-unit transactions
//   +max_delay=<n>        max idle cycles between requests
//   +ll_ready_pct=<n>     backpressure on the long-latency response ports
//   +brmode=<0..4>        branch-update background traffic (see brmode_e)
//   +exe_seq=<class>      sequence class to run on the execution units
//   +iq_seq=<class>       sequence class to run on the issue queue
//   +ral_seq=<class>      register-model sequence run before the exe/iq traffic
//   +no_iq / +no_cov / +no_sb / +no_csr (integer-only tests: with the CSR file out of the
//                         loop nothing sets mstatus.FS, and CSRFile asserts on FP flags)
//   +spike_log=<f>[,<f>..] replay Spike commit logs instead of the constrained-random exe sequence
//                         (boom_spike_trace_seq; Spike's results become a second golden reference)
//   +spike_max=<n>        replay at most n instructions; +spike_no_csr_rm: keep the per-txn frm
//=============================================================================
typedef enum int { BR_NONE = 0, BR_RESOLVE = 1, BR_MISPRED = 2, BR_FLUSH = 3, BR_HEAVY = 4 } brmode_e;

class boom_exe_base_test extends uvm_test;
  `uvm_component_utils(boom_exe_base_test)

  boom_exe_cfg cfg;
  boom_exe_env env;

  // per-test settings (derived tests override in new())
  string       exe_seq_name   = "boom_exe_base_seq";
  string       iq_seq_name    = "";                 // "" = no issue-queue traffic
  string       ral_seq_name   = "";                 // "" = none; runs after csr init, before the traffic
  string       ral_which      = "";                 // for ral_builtin_seq: reset | bitbash
  bit          csr_rm         = 0;                  // FP units take frm from the CSR file
  int unsigned n_txn          = 300;
  int unsigned max_delay      = 3;
  int unsigned ll_ready_pct   = 100;
  brmode_e     brmode         = BR_NONE;
  int unsigned repeat_seq     = 1;                  // run the exe sequence this many times back to back
  int unsigned drain_cycles   = 300;                // idle cycles before the objection drops
  bit          use_iq         = 1;
  // Spike-trace replay (set by +spike_log or by a derived test)
  string       spike_logs     = "";                 // comma-separated Spike commit logs
  string       spike_list     = "";                 // or: a text file with one log per line (relative to +spike_dir)
  string       spike_dir      = "";                 // +spike_dir: directory the Makefile passes (sim/spike_logs)
  int unsigned spike_max      = 0;
  bit          spike_csr_rm   = 1;
  int unsigned spike_repeat   = 1;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  //---------------------------------------------------------------- build
  function void build_phase(uvm_phase phase);
    int v;
    super.build_phase(phase);
    cfg = boom_exe_cfg::type_id::create("cfg");
    if (!uvm_config_db#(virtual boom_exu_if #(EXU_ALU0))::get(this, "", "alu0_vif", cfg.alu0_vif)) `uvm_fatal("VIF", "alu0_vif not set")
    if (!uvm_config_db#(virtual boom_exu_if #(EXU_ALU1))::get(this, "", "alu1_vif", cfg.alu1_vif)) `uvm_fatal("VIF", "alu1_vif not set")
    if (!uvm_config_db#(virtual boom_exu_if #(EXU_FPU))::get(this,  "", "fpu_vif",  cfg.fpu_vif))  `uvm_fatal("VIF", "fpu_vif not set")
    if (!uvm_config_db#(virtual boom_iq_if)::get(this, "", "iq_vif", cfg.iq_vif)) `uvm_fatal("VIF", "iq_vif not set")
    if (!uvm_config_db#(virtual boom_csr_if)::get(this, "", "csr_vif", cfg.csr_vif)) `uvm_fatal("VIF", "csr_vif not set")
    // command-line overrides
    if ($value$plusargs("n_txn=%d", v))        n_txn = v;
    if ($value$plusargs("max_delay=%d", v))    max_delay = v;
    if ($value$plusargs("ll_ready_pct=%d", v)) ll_ready_pct = v;
    if ($value$plusargs("brmode=%d", v))       brmode = brmode_e'(v);
    void'($value$plusargs("exe_seq=%s", exe_seq_name));
    void'($value$plusargs("iq_seq=%s", iq_seq_name));
    void'($value$plusargs("ral_seq=%s", ral_seq_name));
    if ($test$plusargs("no_iq"))  use_iq = 0;
    if ($test$plusargs("no_csr")) cfg.has_csr = 0;
    if ($test$plusargs("csr_rm")) csr_rm = 1;
    cfg.fcsr_rm_from_csr = csr_rm;
    void'($value$plusargs("spike_log=%s", spike_logs));
    void'($value$plusargs("spike_list=%s", spike_list));
    void'($value$plusargs("spike_dir=%s", spike_dir));
    if (spike_list != "") spike_logs = read_list(spike_list);
    if ($value$plusargs("spike_max=%d", v)) spike_max = v;
    if ($test$plusargs("spike_no_csr_rm")) spike_csr_rm = 0;
    if ($test$plusargs("no_cov")) cfg.has_coverage = 0;
    if ($test$plusargs("no_sb"))  cfg.has_scoreboard = 0;
    cfg.has_iq        = use_iq;
    cfg.ll_ready_pct  = ll_ready_pct;
    cfg.max_delay     = max_delay;
    configure_cfg();
    uvm_config_db#(boom_exe_cfg)::set(this, "env", "cfg", cfg);
    env = boom_exe_env::type_id::create("env", this);
  endfunction

  virtual function void configure_cfg(); endfunction   // hook for derived tests

  function void end_of_elaboration_phase(uvm_phase phase);
    `uvm_info("TEST", $sformatf("exe_seq=%s x%0d n_txn=%0d max_delay=%0d ll_ready=%0d%% brmode=%s iq_seq=%s ral_seq=%s%s csr=%0d csr_rm=%0d spike_log=%s",
              spike_logs == "" ? exe_seq_name : "boom_spike_trace_seq", repeat_seq, n_txn, max_delay, ll_ready_pct, brmode.name(), iq_seq_name == "" ? "-" : iq_seq_name,
              ral_seq_name == "" ? "-" : ral_seq_name, ral_which == "" ? "" : {"/", ral_which}, cfg.has_csr, csr_rm, spike_logs == "" ? "-" : spike_logs), UVM_LOW)
    if (uvm_report_enabled(UVM_HIGH)) uvm_top.print_topology();
  endfunction

  //---------------------------------------------------------------- helpers
  function bit [11:0] live_mask_for(brmode_e m);
    return (m == BR_NONE) ? 12'h000 : 12'h0FF;
  endfunction

  virtual function boom_exe_base_seq make_exe_seq(string name);
    uvm_object o = uvm_factory::get().create_object_by_name(name, "", name);
    boom_exe_base_seq s;
    if (o == null || !$cast(s, o)) `uvm_fatal("TEST", $sformatf("cannot create exe sequence '%s'", name))
    s.n = n_txn; s.max_delay = max_delay; s.live_mask = live_mask_for(brmode);
    s.tag_pct   = (brmode == BR_NONE) ? 0 : (brmode == BR_HEAVY ? 80 : 50);
    s.flush_pct = (brmode == BR_FLUSH) ? 3 : (brmode == BR_HEAVY ? 5 : 0);
    return s;
  endfunction

  virtual function boom_iq_base_seq make_iq_seq(string name);
    uvm_object o = uvm_factory::get().create_object_by_name(name, "", name);
    boom_iq_base_seq s;
    if (o == null || !$cast(s, o)) `uvm_fatal("TEST", $sformatf("cannot create iq sequence '%s'", name))
    s.live_mask = live_mask_for(brmode);
    if (brmode != BR_NONE && s.tag_pct == 0) s.tag_pct = 40;
    return s;
  endfunction

  virtual function brupd_base_seq make_brupd_seq();
    brupd_base_seq b = brupd_base_seq::type_id::create("brupd");
    b.n = 1 << 30;                           // runs until killed
    b.live_mask = live_mask_for(brmode);
    case (brmode)
      BR_RESOLVE: begin b.mispredict_pct = 0;  b.flush_pct = 0;  b.max_delay = 10; end
      BR_MISPRED: begin b.mispredict_pct = 30; b.flush_pct = 0;  b.max_delay = 10; end
      BR_FLUSH:   begin b.mispredict_pct = 20; b.flush_pct = 10; b.max_delay = 12; end
      BR_HEAVY:   begin b.mispredict_pct = 50; b.flush_pct = 15; b.max_delay = 4;  end
      default:    ;
    endcase
    return b;
  endfunction

  function string with_dir(string f);
    if (spike_dir == "" || f[0] == "/") return f;
    return {spike_dir, "/", f};
  endfunction

  // "rv64ui.list": one log file name per line -> "a.log,b.log,..."
  function string read_list(string list);
    int fd; string line, acc = "";
    fd = $fopen(with_dir(list), "r");
    if (fd == 0) `uvm_fatal("TEST", $sformatf("cannot open Spike log list '%s'", with_dir(list)))
    while (!$feof(fd)) begin
      void'($fgets(line, fd));
      line = strip(line);
      if (line == "" || line[0] == "#") continue;
      acc = (acc == "") ? line : {acc, ",", line};
    end
    $fclose(fd);
    return acc;
  endfunction

  function string strip(string s);
    int a = 0, b = s.len();
    while (a < b && (s[a] == " " || s[a] == "\n" || s[a] == 8'h0D || s[a] == "\t")) a++;
    while (b > a && (s[b-1] == " " || s[b-1] == "\n" || s[b-1] == 8'h0D || s[b-1] == "\t")) b--;
    return (a < b) ? s.substr(a, b - 1) : "";
  endfunction

  // split "a.log,b.log" into a queue
  function void split_csv(string s, ref string q[$]);
    string cur = "";
    for (int i = 0; i < s.len(); i++) begin
      if (s[i] == ",") begin if (cur != "") q.push_back(with_dir(cur)); cur = ""; end
      else cur = {cur, string'(s[i])};
    end
    if (cur != "") q.push_back(with_dir(cur));
  endfunction

  virtual function boom_spike_trace_seq make_spike_seq();
    boom_spike_trace_seq s = boom_spike_trace_seq::type_id::create("spike_trace");
    split_csv(spike_logs, s.logs);
    s.max_insns = spike_max; s.max_delay = max_delay; s.use_csr_rm = spike_csr_rm;
    return s;
  endfunction

  //---------------------------------------------------------------- run
  virtual task run_exe_traffic();
    if (spike_logs != "") begin
      for (int r = 0; r < spike_repeat; r++) begin
        boom_spike_trace_seq s = make_spike_seq();
        s.start(env.vsqr);
      end
      return;
    end
    for (int r = 0; r < repeat_seq; r++) begin
      boom_exe_base_seq s = make_exe_seq(exe_seq_name);
      s.start(env.vsqr);
    end
  endtask

  virtual task run_iq_traffic();
    boom_iq_base_seq s;
    if (!use_iq || iq_seq_name == "") return;
    s = make_iq_seq(iq_seq_name);
    s.start(env.vsqr);
  endtask

  // CSR file in the loop: enable the FP unit (mstatus.FS) through the register model before any
  // FP instruction, exactly as boot code would — CSRFile asserts otherwise. Then the test's RAL sequence.
  virtual task run_ral_traffic();
    if (!cfg.has_csr) return;
    begin
      ral_csr_init_seq init = ral_csr_init_seq::type_id::create("csr_init");
      init.start(env.vsqr);
    end
    cfg.fpu_vif.use_csr_rm = csr_rm; cfg.alu0_vif.use_csr_rm = csr_rm; cfg.alu1_vif.use_csr_rm = csr_rm;
    if (ral_seq_name != "") begin
      uvm_object o = uvm_factory::get().create_object_by_name(ral_seq_name, "", ral_seq_name);
      boom_ral_base_seq s;
      ral_builtin_seq b;
      if (o == null || !$cast(s, o)) `uvm_fatal("TEST", $sformatf("cannot create ral sequence '%s'", ral_seq_name))
      if ($cast(b, s) && ral_which != "") b.which = ral_which;
      s.start(env.vsqr);
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    process brupd_p;
    phase.raise_objection(this, "boom_exe_base_test");
    @(negedge cfg.alu0_vif.rst);
    repeat (5) @(posedge cfg.alu0_vif.clk);
    run_ral_traffic();
    fork
      begin
        brupd_p = process::self();
        if (brmode != BR_NONE) begin brupd_base_seq b = make_brupd_seq(); b.start(env.vsqr); end
        else wait (0);
      end
      begin
        fork
          run_exe_traffic();
          run_iq_traffic();
        join
      end
    join_any
    // let the background branch traffic finish its current item, then stop it
    repeat (20) @(posedge cfg.alu0_vif.clk);
    brupd_p.kill();
    if (brmode != BR_NONE) begin
      brupd_resolve_all_seq r = brupd_resolve_all_seq::type_id::create("resolve_all");
      r.live_mask = live_mask_for(brmode);
      r.start(env.vsqr);
    end
    repeat (drain_cycles) @(posedge cfg.alu0_vif.clk);
    phase.drop_objection(this, "boom_exe_base_test");
  endtask

  //---------------------------------------------------------------- summary
  function void report_phase(uvm_phase phase);
    uvm_report_server srv = uvm_report_server::get_server();
    if (spike_logs != "") `uvm_info("TEST", env.spike.summary(), UVM_LOW)
    if (srv.get_severity_count(UVM_FATAL) + srv.get_severity_count(UVM_ERROR) == 0)
      `uvm_info("TEST", "\n\n  ==========  TEST PASSED  ==========\n", UVM_NONE)
    else
      `uvm_info("TEST", $sformatf("\n\n  ==========  TEST FAILED  (%0d errors)  ==========\n", srv.get_severity_count(UVM_ERROR)), UVM_NONE)
  endfunction
endclass : boom_exe_base_test

//=============================================================================
// boom_exe_cfg.sv — environment configuration ("all the knobs in one place")
//=============================================================================
class boom_exe_cfg extends uvm_object;
  `uvm_object_utils(boom_exe_cfg)

  // virtual interfaces (set by tb_top through config_db, collected here by the test)
  virtual boom_exu_if #(EXU_ALU0) alu0_vif;
  virtual boom_exu_if #(EXU_ALU1) alu1_vif;
  virtual boom_exu_if #(EXU_FPU)  fpu_vif;
  virtual boom_iq_if              iq_vif;
  virtual boom_csr_if             csr_vif;

  // agent activity
  uvm_active_passive_enum exu_active[3] = '{UVM_ACTIVE, UVM_ACTIVE, UVM_ACTIVE};
  uvm_active_passive_enum iq_active     = UVM_ACTIVE;
  uvm_active_passive_enum brupd_active  = UVM_ACTIVE;
  uvm_active_passive_enum csr_active    = UVM_ACTIVE;

  // what to build
  bit has_scoreboard = 1;
  bit has_coverage   = 1;
  bit has_iq         = 1;          // instantiate the issue-queue agent/scoreboard
  bit has_csr        = 1;          // CSRFile in the loop: csr agent + register model (RAL) + predictors
  bit fcsr_rm_from_csr = 0;        // FPU/I2F units take frm from the CSRFile instead of the per-txn driver value

  // response-port backpressure model (ll_iresp / ll_fresp ready)
  int unsigned ll_ready_pct = 100;  // probability (%) that ready is high in a cycle

  // checking strictness
  bit strict_nan_payload = 1;      // compare NaN results bit-exactly (RISC-V mandates canonical NaN)
  bit check_fflags       = 1;
  bit check_brinfo       = 1;
  bit check_bypass       = 1;      // compare bypass data with the eventual iresp data (ALU units)
  int unsigned resp_timeout_cycles = 400; // max cycles a request may stay in flight (div ~70)

  // stimulus defaults (sequences read these as soft defaults)
  int unsigned max_delay = 3;

  // simple cycle counter shared by monitors (kept here to avoid hierarchical refs)
  int unsigned cycle = 0;

  function new(string name = "boom_exe_cfg");
    super.new(name);
  endfunction
endclass : boom_exe_cfg

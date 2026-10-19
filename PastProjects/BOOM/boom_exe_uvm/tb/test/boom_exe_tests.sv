//-----------------------------------------------------------------------------
// boom_exe_tests.sv -- test library for the BOOM execute-pipeline TB.
//
//   +UVM_TESTNAME=boom_alu_test          random integer ALU traffic
//   +UVM_TESTNAME=boom_muldiv_test       iMul/iDiv incl. RV-M corner cases
//   +UVM_TESTNAME=boom_fp_ieee754_test   IEEE-754 corner-case storm
//   +UVM_TESTNAME=boom_csr_ral_test      RAL-driven CSR read/write + checks
//   +UVM_TESTNAME=boom_branch_kill_test  speculation / mispredict kills
//   +UVM_TESTNAME=boom_full_test         all of the above back-to-back
//-----------------------------------------------------------------------------
`ifndef BOOM_EXE_TESTS_SV
`define BOOM_EXE_TESTS_SV

//===========================================================================
// Base test
//===========================================================================
class boom_exe_base_test extends uvm_test;
  `uvm_component_utils(boom_exe_base_test)

  boom_exe_env env;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    env = boom_exe_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase (uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  // let long-latency (div) uops drain before dropping the objection
  task drain (int cycles = 60);
    repeat (cycles) @(posedge env.agent.drv.vif.clk);
  endtask

  virtual function void report_phase (uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    super.report_phase(phase);
    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0)
      `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
    else
      `uvm_error(get_type_name(), "*** TEST FAILED ***")
  endfunction
endclass : boom_exe_base_test

//===========================================================================
// Integer ALU
//===========================================================================
class boom_alu_test extends boom_exe_base_test;
  `uvm_component_utils(boom_alu_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    boom_alu_rand_seq seq;
    phase.raise_objection(this);
    seq = boom_alu_rand_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "seq randomize failed")
    seq.start(env.agent.sqr);
    drain();
    phase.drop_objection(this);
  endtask
endclass : boom_alu_test

//===========================================================================
// Multiply / divide corner cases (div-by-zero, MIN_INT/-1, ...)
//===========================================================================
class boom_muldiv_test extends boom_exe_base_test;
  `uvm_component_utils(boom_muldiv_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    boom_muldiv_seq seq;
    phase.raise_objection(this);
    seq = boom_muldiv_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "seq randomize failed")
    seq.start(env.agent.sqr);
    drain();
    phase.drop_objection(this);
  endtask
endclass : boom_muldiv_test

//===========================================================================
// IEEE-754 corner cases through the FPU / FDiv units
//===========================================================================
class boom_fp_ieee754_test extends boom_exe_base_test;
  `uvm_component_utils(boom_fp_ieee754_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    boom_fp_corner_seq seq;
    phase.raise_objection(this);
    seq = boom_fp_corner_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "seq randomize failed")
    seq.start(env.agent.sqr);
    drain();
    phase.drop_objection(this);
  endtask
endclass : boom_fp_ieee754_test

//===========================================================================
// RAL-driven CSR test: frontdoor reads/writes of the real BOOM CSRs
// through serialized CSR uops, with mirror checking.
//===========================================================================
class boom_csr_ral_test extends boom_exe_base_test;
  `uvm_component_utils(boom_csr_ral_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    uvm_status_e      status;
    uvm_reg_data_t    rdata, rdata2;
    boom_csr_reg_block m;

    phase.raise_objection(this);
    m = env.regmodel;

    //---------------------------------------------------------------------
    // 1. Reset values: read every non-volatile CSR and compare to the
    //    modeled reset (mirror check does this for us).
    //---------------------------------------------------------------------
    `uvm_info(get_type_name(), "---- RAL: reset-value checks ----", UVM_LOW)
    m.misa.mirror(status, UVM_CHECK);
    m.mvendorid.mirror(status, UVM_CHECK);
    m.marchid.mirror(status, UVM_CHECK);     // expect 2 = BOOM
    m.mimpid.mirror(status, UVM_CHECK);
    m.mhartid.mirror(status, UVM_CHECK);
    m.mstatus.mirror(status, UVM_CHECK);     // MPP=11, rest 0
    m.mtvec.mirror(status, UVM_CHECK);
    m.mscratch.mirror(status, UVM_CHECK);

    m.marchid.read(status, rdata);
    if (rdata != MARCHID_BOOM)
      `uvm_error(get_type_name(),
                 $sformatf("marchid: exp %0d (BOOM) got %0d", MARCHID_BOOM, rdata))

    //---------------------------------------------------------------------
    // 2. Write/read-back of scratch & trap CSRs via the register model.
    //    write() updates the DUT; mirror(UVM_CHECK) re-reads and compares
    //    against the model's predicted value.
    //---------------------------------------------------------------------
    `uvm_info(get_type_name(), "---- RAL: write/read-back ----", UVM_LOW)
    m.mscratch.write(status, 64'hDEAD_BEEF_CAFE_F00D);
    m.mscratch.mirror(status, UVM_CHECK);

    m.mepc.write(status, 64'h0000_0000_8000_0200);   // aligned -> exact
    m.mepc.mirror(status, UVM_CHECK);

    m.mcause.write(status, 64'h8000_0000_0000_000B); // machine ext. interrupt
    m.mcause.mirror(status, UVM_CHECK);

    m.mtval.write(status, 64'h0000_0000_DEAD_4000);
    m.mtval.mirror(status, UVM_CHECK);

    m.mtvec.write(status, 64'h0000_0000_8000_0000);  // MODE=0 (direct)
    m.mtvec.mirror(status, UVM_CHECK);

    // field-level access: flip mstatus.MIE only
    m.mstatus.MIE.write(status, 1'b1);
    m.mstatus.mirror(status, UVM_CHECK);

    m.mie.MTIE.write(status, 1'b1);
    m.mie.MSIE.write(status, 1'b1);
    m.mie.mirror(status, UVM_CHECK);

    //---------------------------------------------------------------------
    // 3. FP CSRs and the fcsr = {frm, fflags} architectural alias.
    //---------------------------------------------------------------------
    `uvm_info(get_type_name(), "---- RAL: fcsr aliasing ----", UVM_LOW)
    m.fcsr.write(status, 64'h0000_0000_0000_00E5);   // frm=7, fflags=00101
    m.fflags.read(status, rdata);
    m.frm.read(status, rdata2);
    if (rdata[4:0] != 5'b00101)
      `uvm_error(get_type_name(),
                 $sformatf("fcsr alias: fflags exp 00101 got %05b", rdata[4:0]))
    if (rdata2[2:0] != 3'd7)
      `uvm_error(get_type_name(),
                 $sformatf("fcsr alias: frm exp 7 got %0d", rdata2[2:0]))

    m.fflags.write(status, 64'h0);                   // clear via fflags
    m.frm.write(status, 64'h0);
    m.fcsr.read(status, rdata);
    if (rdata[7:0] != 8'h00)
      `uvm_error(get_type_name(),
                 $sformatf("fcsr alias: fcsr exp 00 got %02h", rdata[7:0]))

    //---------------------------------------------------------------------
    // 4. Hardware side effect: run one FP uop that raises flags, then
    //    confirm fflags accumulated (this is why fflags is volatile).
    //---------------------------------------------------------------------
    `uvm_info(get_type_name(), "---- RAL: fflags side-effect from FPU ----", UVM_LOW)
    begin
      boom_fp_flag_kick_seq kick = boom_fp_flag_kick_seq::type_id::create("kick");
      kick.start(env.agent.sqr);
      drain(20);
    end
    m.fflags.read(status, rdata);
    if (rdata[FFLAG_NV] !== 1'b1)
      `uvm_error(get_type_name(),
                 $sformatf("expected NV accumulated in fflags, got %05b", rdata[4:0]))

    //---------------------------------------------------------------------
    // 5. Counters: mcycle must advance between two reads; minstret must
    //    count the retired uops.
    //---------------------------------------------------------------------
    `uvm_info(get_type_name(), "---- RAL: counter CSRs ----", UVM_LOW)
    m.mcycle.read(status, rdata);
    m.mcycle.read(status, rdata2);
    if (!(rdata2 > rdata))
      `uvm_error(get_type_name(),
                 $sformatf("mcycle did not advance: %0d -> %0d", rdata, rdata2))
    m.minstret.read(status, rdata);
    if (rdata == 0)
      `uvm_error(get_type_name(), "minstret stayed at 0 after retired uops")

    drain();
    phase.drop_objection(this);
  endtask
endclass : boom_csr_ral_test

//===========================================================================
// Branch speculation / kill
//===========================================================================
class boom_branch_kill_test extends boom_exe_base_test;
  `uvm_component_utils(boom_branch_kill_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    boom_branch_spec_seq seq;
    phase.raise_objection(this);
    seq = boom_branch_spec_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "seq randomize failed")
    seq.start(env.agent.sqr);
    drain();
    phase.drop_objection(this);
  endtask
endclass : boom_branch_kill_test

//===========================================================================
// Everything back-to-back
//===========================================================================
class boom_full_test extends boom_exe_base_test;
  `uvm_component_utils(boom_full_test)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);
    boom_alu_rand_seq    s_alu;
    boom_muldiv_seq      s_md;
    boom_fp_corner_seq   s_fp;
    boom_csr_smoke_seq   s_csr;
    boom_branch_spec_seq s_br;

    phase.raise_objection(this);
    s_alu = boom_alu_rand_seq::type_id::create("s_alu");
    s_md  = boom_muldiv_seq::type_id::create("s_md");
    s_fp  = boom_fp_corner_seq::type_id::create("s_fp");
    s_csr = boom_csr_smoke_seq::type_id::create("s_csr");
    s_br  = boom_branch_spec_seq::type_id::create("s_br");
    void'(s_alu.randomize());
    void'(s_md.randomize());
    void'(s_fp.randomize());
    void'(s_br.randomize());

    s_alu.start(env.agent.sqr);  drain(20);
    s_md.start(env.agent.sqr);   drain(40);
    s_fp.start(env.agent.sqr);   drain(40);
    s_csr.start(env.agent.sqr);  drain(20);
    s_br.start(env.agent.sqr);   drain();
    phase.drop_objection(this);
  endtask
endclass : boom_full_test

//===========================================================================
// Tiny helper sequence used by the RAL test to provoke an NV flag
//===========================================================================
class boom_fp_flag_kick_seq extends boom_exe_base_seq;
  `uvm_object_utils(boom_fp_flag_kick_seq)

  function new (string name = "boom_fp_flag_kick_seq");
    super.new(name);
  endfunction

  virtual task body ();
    boom_exe_txn tx = boom_exe_txn::type_id::create("tx");
    int unsigned ridx = next_rob_idx();
    start_item(tx);
    if (!tx.randomize() with {
          kind     == boom_exe_txn::KIND_UOP;
          uopc     == UOPC_FADD_D;
          rs1_data == F64_POS_INF;   // (+inf) + (-inf) -> qNaN, NV
          rs2_data == F64_NEG_INF;
          br_mask  == '0;
          rob_idx  == local::ridx;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(tx);
  endtask
endclass : boom_fp_flag_kick_seq

`endif

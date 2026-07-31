// The system is serially processing matmul, so no error should occur when 6 matrices comes in.

`ifndef SS_BACKPRESSURE_TEST_SV
`define SS_BACKPRESSURE_TEST_SV

class ss_backpressure_test extends base_test;
  `uvm_component_utils(ss_backpressure_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    // configure the read driver before it is built
    uvm_config_db#(int unsigned)::set(this, "env.ss_rd_agt.drv", "read_delay", 3);
    super.build_phase(phase);
  endfunction

  task run_seqs(uvm_phase phase);
    ss_vseq v = ss_vseq::type_id::create("v");
    v.num_matrices = 6; v.fixed_m = `NN;
    v.start(env.vseqr);
    wait_sb(env.ss_sb, 6);
  endtask
endclass

`endif // SS_BACKPRESSURE_TEST_SV

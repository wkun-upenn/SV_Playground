//======================================================================
// ss_param_test.sv  -  sub-system: sweep the contraction dim M = 1..N,
//                      one M per drained batch (parameter coverage)
//======================================================================
`ifndef SS_PARAM_TEST_SV
`define SS_PARAM_TEST_SV

class ss_param_test extends base_test;
  `uvm_component_utils(ss_param_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_seqs(uvm_phase phase);
    int total = 0;
    for (int mm = 1; mm <= `NN; mm++) begin
      ss_vseq v = ss_vseq::type_id::create($sformatf("v_m%0d", mm));
      v.num_matrices = 4; v.fixed_m = mm;
      total += 4;
      v.start(env.vseqr);
      wait_sb(env.ss_sb, total);       // drain this M before changing M
    end
  endtask
endclass

`endif // SS_PARAM_TEST_SV

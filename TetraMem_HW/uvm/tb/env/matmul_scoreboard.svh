// Scoreboard that compares observed C (output monitor) against golden C (input monitor),
// matrix by matrix in order.  Reports IDLE (not an error) if it received nothing.
`ifndef MATMUL_SCOREBOARD_SVH
`define MATMUL_SCOREBOARD_SVH

class matmul_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(matmul_scoreboard)
  uvm_tlm_analysis_fifo #(matmul_item) exp_fifo;
  uvm_tlm_analysis_fifo #(matmul_item) act_fifo;
  int matched = 0, errors = 0;

  function new(string name, uvm_component parent);
    super.new(name,parent);
    exp_fifo = new("exp_fifo", this);
    act_fifo = new("act_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    matmul_item e, a;
    forever begin
      exp_fifo.get(e);
      act_fifo.get(a);
      compare(e, a);
    end
  endtask

  function void compare(matmul_item e, matmul_item a);
    bit    ok = 1;
    string s  = "";
    for (int i = 0; i < `NN; i++)
      for (int j = 0; j < `NN; j++)
        if (e.c[i][j] !== a.c[i][j]) ok = 0;
    if (ok) begin
      matched++;
      `uvm_info("SCB", $sformatf("MATCH  #%0d (m=%0d)", matched, e.m), UVM_MEDIUM)
    end else begin
      errors++;
      for (int i = 0; i < `NN; i++) begin
        for (int j = 0; j < `NN; j++)
          s = {s, $sformatf(" (%0d/%0d)", $signed(a.c[i][j]), $signed(e.c[i][j]))};
        s = {s, "\n"};
      end
      `uvm_error("SCB", $sformatf("MISMATCH (got/exp):\n%s", s))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    if (matched == 0 && errors == 0)
      `uvm_info("SCB", $sformatf("%s: IDLE (not exercised this test)", get_full_name()), UVM_LOW)
    else if (errors == 0)
      `uvm_info("SCB", $sformatf("%s: PASSED : %0d matrices matched", get_full_name(), matched), UVM_NONE)
    else
      `uvm_error("SCB", $sformatf("%s: FAILED : %0d matched, %0d errors", get_full_name(), matched, errors))
  endfunction
endclass

`endif // MATMUL_SCOREBOARD_SVH

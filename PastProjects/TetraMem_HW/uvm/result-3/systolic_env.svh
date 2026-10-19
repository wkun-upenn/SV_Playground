
// Contains the module-level array agent and the two sub-system channel
// agents, one scoreboard per level.

`ifndef SYSTOLIC_ENV_SVH
`define SYSTOLIC_ENV_SVH

class systolic_env extends uvm_env;
  `uvm_component_utils(systolic_env)

  sa_agent            sa_agt;      // systolic_array level
  ss_wr_agent         ss_wr_agt;   // sub-system write channel
  ss_rd_agent         ss_rd_agt;   // sub-system read  channel
  matmul_scoreboard   sa_sb;       // array-level scoreboard
  matmul_scoreboard   ss_sb;       // sub-system scoreboard
  matmul_coverage     cov;         // transaction coverage (both levels)
  sa_coverage         sa_cov;      // array-signal coverage
  ss_coverage         ss_cov;      // sub-system-signal coverage
  virtual_sequencer   vseqr;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    sa_agt    = sa_agent::type_id::create("sa_agt", this);
    ss_wr_agt = ss_wr_agent::type_id::create("ss_wr_agt", this);
    ss_rd_agt = ss_rd_agent::type_id::create("ss_rd_agt", this);
    sa_sb     = matmul_scoreboard::type_id::create("sa_sb", this);
    ss_sb     = matmul_scoreboard::type_id::create("ss_sb", this);
    cov       = matmul_coverage::type_id::create("cov", this);
    sa_cov    = sa_coverage::type_id::create("sa_cov", this);
    ss_cov    = ss_coverage::type_id::create("ss_cov", this);
    vseqr     = virtual_sequencer::type_id::create("vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    // array level
    sa_agt.imon.ap.connect(sa_sb.exp_fifo.analysis_export);
    sa_agt.omon.ap.connect(sa_sb.act_fifo.analysis_export);
    // sub-system
    ss_wr_agt.mon.ap.connect(ss_sb.exp_fifo.analysis_export);
    ss_rd_agt.mon.ap.connect(ss_sb.act_fifo.analysis_export);
    // functional coverage sees every driven matrix (both levels)
    sa_agt.imon.ap.connect(cov.analysis_export);
    ss_wr_agt.mon.ap.connect(cov.analysis_export);
    // virtual sequencer handles
    vseqr.sa_sqr = sa_agt.sqr;
    vseqr.wr_sqr = ss_wr_agt.sqr;
    vseqr.rd_sqr = ss_rd_agt.sqr;
  endfunction
endclass

`endif // SYSTOLIC_ENV_SVH

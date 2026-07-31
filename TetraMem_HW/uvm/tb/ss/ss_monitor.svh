//======================================================================
// ss_monitor.svh  -  sub_sys channel monitors
//----------------------------------------------------------------------
//  ss_in_monitor  : rebuild driven matrices from din -> GOLDEN C (expected)
//  ss_out_monitor : collect read-back C rows from dout -> OBSERVED C (actual)
//======================================================================
`ifndef SS_MONITOR_SVH
`define SS_MONITOR_SVH

class ss_in_monitor extends uvm_monitor;
  `uvm_component_utils(ss_in_monitor)
  virtual ss_if #(`DW,`NN,`BUSW) vif;
  uvm_analysis_port #(matmul_item) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::get(this,"","ss_vif",vif))
      `uvm_fatal("NOVIF","ss_vif not set for ss_in_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    int cnt = 0, curM = 0;
    bit [`BUSW-1:0] samps [$];
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon);
      if (vif.mon.wr_fifo && !vif.mon.in_fifo_full) begin
        if (cnt == 0) begin
          curM = vif.mon.M_minus_one + 1;
          if (curM > `NN) curM = `NN;
          samps.delete();
        end
        samps.push_back(vif.mon.din);
        cnt++;
        if (cnt == curM) begin
          matmul_item e = matmul_item::type_id::create("exp");
          e.m = curM;
          for (int k = 0; k < curM; k++) begin
            for (int j = 0; j < `NN; j++) e.b[k][j] = samps[k][j*`DW          +: `DW];
            for (int i = 0; i < `NN; i++) e.a[i][k] = samps[k][`NN*`DW + i*`DW +: `DW];
          end
          e.compute();
          ap.write(e);
          `uvm_info("SS_IN_MON", $sformatf("expected %s", e.convert2string()), UVM_HIGH)
          cnt = 0;
        end
      end
    end
  endtask
endclass


class ss_out_monitor extends uvm_monitor;
  `uvm_component_utils(ss_out_monitor)
  virtual ss_if #(`DW,`NN,`BUSW) vif;
  uvm_analysis_port #(matmul_item) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::get(this,"","ss_vif",vif))
      `uvm_fatal("NOVIF","ss_vif not set for ss_out_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    int rcnt = 0;
    matmul_item a = matmul_item::type_id::create("act");
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon);
      if (vif.mon.rd_fifo && !vif.mon.out_fifo_empty) begin
        for (int j = 0; j < `NN; j++) a.c[rcnt][j] = vif.mon.dout[j*`ACCW +: `ACCW];
        rcnt++;
        if (rcnt == `NN) begin
          ap.write(a);
          a = matmul_item::type_id::create("act");
          rcnt = 0;
        end
      end
    end
  endtask
endclass

`endif // SS_MONITOR_SVH

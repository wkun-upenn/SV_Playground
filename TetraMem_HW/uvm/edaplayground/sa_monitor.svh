`ifndef SA_MONITOR_SVH
`define SA_MONITOR_SVH


// We define two monitors that tracks data in and out of systolic array.

class sa_in_monitor extends uvm_monitor;
  `uvm_component_utils(sa_in_monitor)
  virtual sa_if #(`DW,`NN) vif;
  uvm_analysis_port #(matmul_item) ap;

  function new(string name, uvm_component parent); 
    super.new(name,parent); 
    ap=new("ap",this); 
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual sa_if #(`DW,`NN))::get(this,"","sa_vif",vif))
      `uvm_fatal("NOVIF","sa_vif not set for sa_in_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    int k;
    matmul_item e;
    wait (vif.rst_n === 1'b1);
    forever begin
      // wait for the input window to start
      @(vif.mon);
      if (vif.mon.in_valid) begin
        e = matmul_item::type_id::create("exp");
        k = 0;
        // collect columns of A / rows of B while in_valid is high
        while (vif.mon.in_valid) begin
          if (k < `NN) begin
            for (int i = 0; i < `NN; i++) e.a[i][k] = vif.mon.a_din[i*`DW +: `DW];
            for (int j = 0; j < `NN; j++) e.b[k][j] = vif.mon.b_din[j*`DW +: `DW];
          end
          k++;
          @(vif.mon);
        end
        e.m = (k > `NN) ? `NN : k;
        e.compute();
        ap.write(e);
        `uvm_info("SA_IN_MON", $sformatf("expected %s", e.convert2string()), UVM_HIGH)
      end
    end
  endtask
endclass


class sa_out_monitor extends uvm_monitor;
  `uvm_component_utils(sa_out_monitor)
  virtual sa_if #(`DW,`NN) vif;
  uvm_analysis_port #(matmul_item) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual sa_if #(`DW,`NN))::get(this,"","sa_vif",vif))
      `uvm_fatal("NOVIF","sa_vif not set for sa_out_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    int rcnt = 0;
    matmul_item a = matmul_item::type_id::create("act");
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon);
      if (vif.mon.out_valid) begin
        for (int j = 0; j < `NN; j++) a.c[rcnt][j] = vif.mon.c_dout[j*`ACCW +: `ACCW];
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

`endif

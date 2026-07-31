
// Streams one matmul_item as M cycles of (a_din = A column k, b_din = B
// row k) with in_valid high, then drops in_valid and lets the array drain.

`ifndef SA_DRIVER_SVH
`define SA_DRIVER_SVH

class sa_driver extends uvm_driver #(matmul_item);
  `uvm_component_utils(sa_driver)
  virtual sa_if #(`DW,`NN) vif;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual sa_if #(`DW,`NN))::get(this,"","sa_vif",vif))
      `uvm_fatal("NOVIF","sa_vif not set for sa_driver")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rst_n === 1'b1);
    vif.init_drv();
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  task drive(matmul_item mi);
    logic [`NN*`DW-1:0] a_col, b_row;
    // stream M rank-1 updates: a_din = A column k, b_din = B row k
    for (int k = 0; k < mi.m; k++) begin
      a_col = '0; b_row = '0;
      for (int i = 0; i < `NN; i++) a_col[i*`DW +: `DW] = mi.a[i][k];
      for (int j = 0; j < `NN; j++) b_row[j*`DW +: `DW] = mi.b[k][j];
      @(vif.drv);
      vif.drv.a_din    <= a_col;
      vif.drv.b_din    <= b_row;
      vif.drv.c_din    <= '0;
      vif.drv.in_valid <= 1'b1;
    end
    @(vif.drv);
    vif.drv.in_valid <= 1'b0;
    // let the result stream out before the next matrix
    repeat (`NN + 3) @(vif.drv);
  endtask
endclass

`endif // SA_DRIVER_SVH

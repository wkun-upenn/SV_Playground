//======================================================================
// ss_driver.svh  -  sub_sys channel drivers
//----------------------------------------------------------------------
//  ss_wr_driver : matmul_item -> M bus samples on din/wr_fifo (sets M-1)
//  ss_rd_driver : one read_item -> pop one C row from the output FIFO
//======================================================================
`ifndef SS_DRIVER_SVH
`define SS_DRIVER_SVH

class ss_wr_driver extends uvm_driver #(matmul_item);
  `uvm_component_utils(ss_wr_driver)
  virtual ss_if #(`DW,`NN,`BUSW) vif;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::get(this,"","ss_vif",vif))
      `uvm_fatal("NOVIF","ss_vif not set for ss_wr_driver")
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
    // present M and let it settle (static per-stream config value)
    @(vif.wr);
    vif.wr.M_minus_one <= 8'(mi.m - 1);
    vif.wr.wr_fifo     <= 1'b0;
    repeat (3) @(vif.wr);
    // push M samples (respecting back-pressure)
    for (int k = 0; k < mi.m; ) begin
      @(vif.wr);
      if (!vif.wr.in_fifo_full) begin
        vif.wr.din     <= pack_sample(mi, k);
        vif.wr.wr_fifo <= 1'b1;
        k++;
      end else begin
        vif.wr.wr_fifo <= 1'b0;
      end
    end
    @(vif.wr);
    vif.wr.wr_fifo <= 1'b0;
  endtask

  function bit [`BUSW-1:0] pack_sample(matmul_item mi, int k);
    bit [`BUSW-1:0] s = '0;
    for (int j = 0; j < `NN; j++) s[j*`DW          +: `DW] = mi.b[k][j];   // B row k
    for (int i = 0; i < `NN; i++) s[`NN*`DW + i*`DW +: `DW] = mi.a[i][k];   // A col k
    return s;
  endfunction
endclass


class ss_rd_driver extends uvm_driver #(read_item);
  `uvm_component_utils(ss_rd_driver)
  virtual ss_if #(`DW,`NN,`BUSW) vif;
  int unsigned read_delay = 0;   // idle cycles before each pop (back-pressure knob)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual ss_if #(`DW,`NN,`BUSW))::get(this,"","ss_vif",vif))
      `uvm_fatal("NOVIF","ss_vif not set for ss_rd_driver")
    void'(uvm_config_db#(int unsigned)::get(this,"","read_delay",read_delay));
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rst_n === 1'b1);
    @(vif.rd);
    vif.rd.rd_fifo <= 1'b0;
    forever begin
      seq_item_port.get_next_item(req);
      repeat (read_delay) begin @(vif.rd); vif.rd.rd_fifo <= 1'b0; end
      do @(vif.rd); while (vif.rd.out_fifo_empty);   // wait for a row
      vif.rd.rd_fifo <= 1'b1;                          // pop exactly one
      @(vif.rd);
      vif.rd.rd_fifo <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // SS_DRIVER_SVH

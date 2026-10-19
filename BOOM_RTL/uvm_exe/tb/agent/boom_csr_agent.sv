//=============================================================================
// boom_csr_agent.sv — sequencer / driver / monitor / agent for the CSRFile port
//=============================================================================
class boom_csr_sequencer extends uvm_sequencer #(boom_csr_txn);
  `uvm_component_utils(boom_csr_sequencer)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
endclass

//-----------------------------------------------------------------------------
// Driver: first asks the decode port whether the core would even issue this
// CSR instruction (privilege / existence / read-only checks — the core traps
// instead of accessing), then performs the one-cycle rw access. The response
// (rdata, illegal flags) travels back through the sequencer so the RAL
// adapter can turn it into UVM_IS_OK / UVM_NOT_OK.
//-----------------------------------------------------------------------------
class boom_csr_driver extends uvm_driver #(boom_csr_txn);
  `uvm_component_utils(boom_csr_driver)
  virtual boom_csr_if vif;
  boom_exe_cfg cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_csr_if)::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction

  // CSRRW rd=x1, rs1=x1 (or CSRRS rs1=x0 for a pure read) with this csr number
  function bit [31:0] decode_inst_of(boom_csr_txn t);
    return (t.cmd == CSR_R) ? {t.addr, 5'd0, 3'b010, 5'd1, 7'b1110011} : {t.addr, 5'd1, 3'b001, 5'd1, 7'b1110011};
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.agt_valid <= 0; vif.drv_cb.agt_cmd <= CSR_N; vif.drv_cb.agt_addr <= 0; vif.drv_cb.agt_wdata <= 0; vif.drv_cb.decode_inst <= 0;
    vif.drv_cb.irq_debug <= 0; vif.drv_cb.irq_mtip <= 0; vif.drv_cb.irq_msip <= 0; vif.drv_cb.irq_meip <= 0; vif.drv_cb.irq_seip <= 0;
    vif.drv_cb.hartid <= 0; vif.drv_cb.exception <= 0; vif.drv_cb.retire <= 0; vif.drv_cb.cause <= 0; vif.drv_cb.pc <= 0; vif.drv_cb.tval <= 0;
    @(negedge vif.rst);
    @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      // 1. decode
      vif.drv_cb.decode_inst <= decode_inst_of(req);
      @(vif.drv_cb);
      req.read_illegal  = vif.drv_cb.decode_read_illegal;
      req.write_illegal = (req.cmd != CSR_R) && vif.drv_cb.decode_write_illegal;
      if (req.read_illegal || req.write_illegal) begin
        `uvm_info("CSRDRV", $sformatf("decode says illegal, access suppressed: %s", req.convert2string()), UVM_MEDIUM)
        req.rdata = '0;
      end else begin
        // 2. the access itself (one cycle); rdata is combinational and is what the core would write to rd
        vif.drv_cb.agt_valid <= 1; vif.drv_cb.agt_addr <= req.addr; vif.drv_cb.agt_cmd <= req.cmd; vif.drv_cb.agt_wdata <= req.wdata;
        @(vif.drv_cb);
        req.rdata = vif.drv_cb.rw_rdata;
        req.cycle = cur_cycle();
        vif.drv_cb.agt_valid <= 0; vif.drv_cb.agt_cmd <= CSR_N;
        // one idle cycle: the monitor (and through it the predictor) has then certainly seen this
        // access before the sequence gets the item back and looks at the mirror
        @(vif.drv_cb);
      end
      `uvm_info("CSRDRV", req.convert2string(), UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask
endclass : boom_csr_driver

//-----------------------------------------------------------------------------
// Monitor: publishes every non-N command on the rw port (either master) and
// every fflags side-effect event.
//-----------------------------------------------------------------------------
class boom_csr_monitor extends uvm_monitor;
  `uvm_component_utils(boom_csr_monitor)
  virtual boom_csr_if vif;
  boom_exe_cfg cfg;
  uvm_analysis_port #(boom_csr_txn)        ap;
  uvm_analysis_port #(boom_csr_fflags_evt) fflags_ap;
  // cg27: CSR access coverage
  bit [2:0]  cov_cmd; bit [11:0] cov_addr; bit cov_pipe, cov_illegal;
  covergroup cg27_csr_access;
    option.per_instance = 1;
    cp_cmd:  coverpoint cov_cmd { bins read={CSR_R}; bins write={CSR_W}; bins set={CSR_S}; bins clear={CSR_C}; }
    cp_addr: coverpoint cov_addr {
      bins fp[]       = {12'h001, 12'h002, 12'h003};
      bins s_trap     = {[12'h100:12'h144]};
      bins satp       = {12'h180};
      bins m_info     = {[12'hF11:12'hF14]};
      bins m_trap     = {[12'h300:12'h344]};
      bins pmp        = {[12'h3A0:12'h3BF]};
      bins counters   = {[12'hB00:12'hB1F], [12'hC00:12'hC1F]};
      bins events     = {[12'h320:12'h33F]};
      bins custom     = {12'h7C1};
      bins other      = default;
    }
    cp_src:  coverpoint cov_pipe { bins ral_agent={0}; bins pipeline_uop={1}; }
    x_cmd_addr: cross cp_cmd, cp_addr;
    x_cmd_src:  cross cp_cmd, cp_src;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent); ap = new("ap", this); fflags_ap = new("fflags_ap", this);
    cg27_csr_access = new();
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    if (!uvm_config_db#(virtual boom_csr_if)::get(this, "", "vif", vif)) `uvm_fatal("VIF", "no vif")
  endfunction
  task run_phase(uvm_phase phase);
    @(negedge vif.rst);
    forever begin
      @(vif.mon_cb);
      if (vif.rst) continue;
      // flags side effect first: when a CSR write to fflags lands in the same cycle, the hardware's
      // write wins (last assignment in CSR.scala), and so must the prediction order
      if (vif.mon_cb.fcsr_flags_valid) begin
        boom_csr_fflags_evt e = boom_csr_fflags_evt::type_id::create("fflags_evt");
        e.flags = vif.mon_cb.fcsr_flags_bits; e.cycle = cur_cycle();
        fflags_ap.write(e);
      end
      if (vif.mon_cb.rw_cmd != CSR_N) begin
        boom_csr_txn t = boom_csr_txn::type_id::create("csr_mon");
        t.addr = vif.mon_cb.rw_addr; t.cmd = vif.mon_cb.rw_cmd; t.wdata = vif.mon_cb.rw_wdata; t.rdata = vif.mon_cb.rw_rdata;
        t.from_pipeline = !vif.mon_cb.agt_valid; t.cycle = cur_cycle();
        `uvm_info("CSRMON", t.convert2string(), UVM_HIGH)
        if (cfg.has_coverage) begin cov_cmd = t.cmd; cov_addr = t.addr; cov_pipe = t.from_pipeline; cg27_csr_access.sample(); end
        ap.write(t);
      end
    end
  endtask
endclass : boom_csr_monitor

//-----------------------------------------------------------------------------
class boom_csr_agent extends uvm_agent;
  `uvm_component_utils(boom_csr_agent)
  boom_csr_sequencer sqr;
  boom_csr_driver    drv;
  boom_csr_monitor   mon;
  boom_exe_cfg       cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boom_exe_cfg)::get(this, "", "cfg", cfg)) `uvm_fatal("CFG", "no cfg")
    mon = boom_csr_monitor::type_id::create("mon", this);
    if (cfg.csr_active == UVM_ACTIVE) begin
      sqr = boom_csr_sequencer::type_id::create("sqr", this);
      drv = boom_csr_driver::type_id::create("drv", this);
    end
  endfunction
  function void connect_phase(uvm_phase phase);
    if (drv != null) drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass : boom_csr_agent

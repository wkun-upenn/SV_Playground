// © 2018 Cadence Design Systems, Inc. All rights reserved worldwide.
// 
// ----------------------------------------
// 
// This file is being provided as part of a reference example to showcase
// Cadence's JasperGold Formal IP Signoff methodology. They are the proprietary
// and confidential information of Cadence or its licensors, and are supplied
// subject to, and may be used only by Cadence's customer in accordance with a
// previously executed agreements between Cadence and that customer.
// 
// Further, they may only be used with JasperGold and cannot be used with any
// other Formal Verification Tools.
// 
// ALL MATERIALS FURNISHED BY CADENCE HEREUNDER ARE PROVIDED "AS IS" WITHOUT
// WARRANTY OF ANY KIND, AND CADENCE SPECIFICALLY DISCLAIMS ANY WARRANTY OF
// NONINFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE OR MERCHANTABILITY.
// CADENCE SHALL NOT BE LIABLE FOR ANY COSTS OF PROCUREMENT OF SUBSTITUTES,
// LOSS OF PROFITS, INTERRUPTION OF BUSINESS, OR FOR ANY OTHER SPECIAL,
// CONSEQUENTIAL OR INCIDENTAL DAMAGES, HOWEVER CAUSED, WHETHER FOR BREACH OF
// WARRANTY, CONTRACT, TORT, NEGLIGENCE, STRICT LIABILITY OR OTHERWISE.
// 
// ----------------------------------------

`include "fv_defines.svh"
`include "pp.vh"

module init_chk #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  ig_port_intf.monitor ig_port,
  cfg_probe_intf.monitor cfg_probe
);

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Asserts

`ifdef FV_INIT_CHECKS
  AST_init_list_done: assert property (cfg_probe.cfg_list_init |-> ##[0:40] cfg_probe.list_init_done);
  AST_init_list_ok: assert property ($rose(cfg_probe.list_init_done) |-> ig_port.avail == DATA_MEM_SIZE);
  AST_init_thr_done: assert property (cfg_probe.cfg_thr_init |-> ##[0:10] cfg_probe.thr_init_done);
  for (genvar g=0; g<NUM_THR; g++) begin: GEN_THR_OK
    AST_init_thr_ok: assert property ($rose(cfg_probe.thr_init_done) |=> pp.thr_mem.mem.mem[g][12]); // list is empty
  end
`endif

endmodule





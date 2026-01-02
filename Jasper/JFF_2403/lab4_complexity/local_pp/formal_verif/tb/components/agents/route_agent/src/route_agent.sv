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

module route_agent #(`FV_PARAM_DECL) (
  input bit clk, rstn,
  route_port_intf.monitor route_port,
  header_txn_intf.driver route_header_txn,
  resp_txn_intf.driver resp_txn,
  cfg_probe_intf.monitor cfg_probe
);
  localparam NUM_THR_MINUS_1 = NUM_THR - 1;

  default disable iff (!rstn);
  default clocking cb @(posedge clk); endclocking

  // Glue logic

  bit [`PKT_LEN_W:0] req_count;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      req_count <= 0;
    end else begin
      req_count <= req_count + route_port.req_valid - route_port.resp_valid;
    end
  end

  assign route_header_txn.valid = route_port.req_valid;
  assign route_header_txn.header_valid = route_port.req_header_valid;
  assign route_header_txn.header = route_port.req_header;

  assign resp_txn.valid = route_port.resp_valid;
  assign resp_txn.drop = route_port.resp_drop;
  assign resp_txn.thr = route_port.resp_thr;
  assign resp_txn.pending = req_count;

  // Coverage

  covergroup cg_resp @(posedge clk);
    cp_req_header: coverpoint route_port.req_header_valid iff route_port.req_valid {
      bins header[] = {4'b000, 4'b0001, 4'b0011, 4'b0111, 4'b1111};
    }
    cp_resp_drop: coverpoint route_port.resp_drop iff route_port.resp_valid {
      bins no_drop = {1'b0};
      bins drop = {1'b1};
    }
    cp_resp_thr: coverpoint route_port.resp_thr iff (route_port.resp_valid && !route_port.resp_drop) {
      bins thrs[] = {[0:NUM_THR_MINUS_1]};
    }
    cp_resp_pending: coverpoint resp_txn.pending {
      bins pending[] = {[0:PROC_FIFO_DEPTH]};
    }
  endgroup
  cg_resp cov_resp = new;

  // Asserts

  AST_S_delay: assert property (req_count > 0 |-> ##[0:7] route_port.resp_valid);
  AST_M_max_req: assert property (req_count >= PROC_FIFO_DEPTH |-> !route_port.req_valid);
  AST_S_no_resp: assert property (req_count == 0 |-> !route_port.resp_valid);
  AST_S_resp_eventually: assert property (req_count != 0 |-> s_eventually route_port.resp_valid);
  AST_M_auto: assert property (cfg_probe.cfg_auto_assign || cfg_probe.cfg_auto_drop |-> !route_port.req_valid);

endmodule





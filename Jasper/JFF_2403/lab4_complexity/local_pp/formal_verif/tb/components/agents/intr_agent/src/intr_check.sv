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

module intr_check #(
  parameter PULSE = 1,
  parameter LOOKAHEAD = 6,
  parameter LOOKBACK = 6,
  localparam PIPE_WIDTH = LOOKBACK+LOOKAHEAD+1,
  localparam MIDDLE = LOOKAHEAD,
  localparam LOOKBACK_LEFT = PIPE_WIDTH-1,
  localparam LOOKBACK_RIGHT = MIDDLE+1,
  localparam LOOKAHEAD_LEFT = MIDDLE-1,
  localparam LOOKAHEAD_RIGTH = 0
) (
  input bit clk, rstn, trigger, clear, status, abort
);

  bit [PIPE_WIDTH-1:0] trigger_pipe, status_pipe, clear_pipe, abort_pipe;

  default disable iff (!rstn || abort_pipe);
  default clocking cb @(posedge clk); endclocking

  assign trigger_pipe[0] = trigger;
  assign status_pipe[0] = status;
  assign clear_pipe[0] = clear;
  assign abort_pipe[0] = abort;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      trigger_pipe[PIPE_WIDTH-1:1] <= {PIPE_WIDTH-1{1'b0}};
      status_pipe[PIPE_WIDTH-1:1] <= {PIPE_WIDTH-1{1'b0}};
      clear_pipe[PIPE_WIDTH-1:1] <= {PIPE_WIDTH-1{1'b0}};
      abort_pipe[PIPE_WIDTH-1:1] <= {PIPE_WIDTH-1{1'b0}};
    end else begin
      trigger_pipe[PIPE_WIDTH-1:1] <= {trigger_pipe[PIPE_WIDTH-2:0]};
      status_pipe[PIPE_WIDTH-1:1] <= {status_pipe[PIPE_WIDTH-2:0]};
      clear_pipe[PIPE_WIDTH-1:1] <= {clear_pipe[PIPE_WIDTH-2:0]};
      abort_pipe[PIPE_WIDTH-1:1] <= {abort_pipe[PIPE_WIDTH-2:0]};
    end
  end

  AST_status_rose_implies_trigger: assert property (
    ##PIPE_WIDTH $rose(status_pipe[MIDDLE]) && !clear_pipe |-> trigger_pipe
  );
  AST_status_fell_implies_clear: assert property (
    ##PIPE_WIDTH $fell(status_pipe[MIDDLE]) |-> clear_pipe
  );
  if (!PULSE) begin
    AST_trigger_implies_status_rose: assert property (
      ##PIPE_WIDTH &trigger_pipe && !clear_pipe |-> status_pipe
    );
  end else begin
    AST_trigger_implies_status_rose: assert property (
      ##PIPE_WIDTH trigger_pipe[MIDDLE] && !clear_pipe |-> status_pipe
    );
  end
  AST_clear_implies_status_low: assert property (
    ##PIPE_WIDTH clear_pipe[MIDDLE] && !trigger_pipe |-> ~status_pipe
  );
  AST_interrupt_stable: assert property (
    ##PIPE_WIDTH !clear_pipe && !trigger_pipe |-> $stable(status_pipe[MIDDLE])
  );

  COV_trigger: cover property (trigger);
  COV_trigger_then_clear: cover property (trigger ##[1:$] clear);

endmodule

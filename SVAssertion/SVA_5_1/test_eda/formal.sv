// ============================================================
// formal.sv  (EDA Playground simulation harness + SVA via bind)
// Key changes:
//  - All logging uses sampled registers (state_q / ops_q)
//  - Output decode assertions use |=> (1-cycle later) to avoid delta races
// ============================================================


// ---------- Assertions live here ----------
module fsm_if_sva (
    input logic        clk,
    input logic        rst_n,
    input logic [5:0]  count40,
    input logic [2:0]  state,
    input logic [3:0]  ops
);

  // Sampled copies (match clock edges)
  logic [2:0] state_q;
  logic [3:0] ops_q;
  logic [5:0] count40_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q   <= '0;
      ops_q     <= '0;
      count40_q <= '0;
    end else begin
      state_q   <= state;
      ops_q     <= ops;
      count40_q <= count40;
    end
  end

  // Helpful one-line trace (optional; comment out if too noisy)
  // always_ff @(posedge clk) if (rst_n)
  //   $display("[%0t] TRACE: state=%0d ops=%b count40=%0d", $time, state_q, ops_q, count40_q);

  // ------------------------------------------------------------
  // Output decode checks (robust style):  (state==X) |=> (ops==Y)
  //
  // Meaning:
  //   If we are in state X at this posedge, then by next posedge
  //   the decoded outputs must match the expected ops for X.
  // ------------------------------------------------------------

  // init:         ops = 1000
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd0) |=> (ops == 4'b1000))
    $display("[%0t] OP_init PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_init FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // load_command: ops = 1000
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd1) |=> (ops == 4'b1000))
    $display("[%0t] OP_load_command PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_load_command FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // start_frame:  ops = 1100
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd2) |=> (ops == 4'b1100))
    $display("[%0t] OP_start_frame PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_start_frame FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // wrc_low:      ops = 0111
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd3) |=> (ops == 4'b0111))
    $display("[%0t] OP_wrc_low PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_wrc_low FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // wrc_high:     ops = 1110
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd4) |=> (ops == 4'b1110))
    $display("[%0t] OP_wrc_high PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_wrc_high FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // end_frame:    ops = 1000
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd5) |=> (ops == 4'b1000))
    $display("[%0t] OP_end_frame PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_end_frame FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // rdc_low:      ops = 0101
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd6) |=> (ops == 4'b0101))
    $display("[%0t] OP_rdc_low PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_rdc_low FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);

  // rdc_high:     ops = 1100
  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd7) |=> (ops == 4'b1100))
    $display("[%0t] OP_rdc_high PASS (sampled: state=%0d ops=%b)", $time, state_q, ops_q);
  else
    $error("[%0t] OP_rdc_high FAIL (sampled: state=%0d ops=%b)", $time, state_q, ops_q);


  // ------------------------------------------------------------
  // Transition checks (next-cycle state): use |=> on state
  // ------------------------------------------------------------

  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd0 && count40 == 6'd39) |=> (state == 3'd1))
  else
    $error("[%0t] TR_init_to_load_command FAIL (sampled: state=%0d count40=%0d)",
           $time, state_q, count40_q);

  assert property (@(posedge clk) disable iff (!rst_n)
                   (state == 3'd1) |=> (state == 3'd2))
  else
    $error("[%0t] TR_load_to_start FAIL (sampled: state=%0d)", $time, state_q);

endmodule



// ---------- Top-level harness (replaces testbench.sv) ----------
module FORMAL_TOP;

  logic        clk;
  logic        rst_n;
  logic [5:0]  count40;

  wire tclk, trst, dq_en, sr_en;

  // DUT
  FSM_IF dut (
    .clk(clk),
    .rst_n(rst_n),
    .count40(count40),
    .tclk(tclk),
    .trst(trst),
    .dq_en(dq_en),
    .sr_en(sr_en)
  );

  // Recreate ops exactly like DUT does (matches DUT ordering)
  wire [3:0] ops = {tclk, trst, dq_en, sr_en};

  // Bind assertions onto the DUT internal state + observable ops
  bind FSM_IF fsm_if_sva sva_i (
    .clk    (clk),
    .rst_n  (rst_n),
    .count40(count40),
    .state  (state),
    .ops    (ops)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset + stop
  initial begin
    rst_n = 0;
    count40 = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    repeat (200) @(posedge clk);
    $finish;
  end

  // Count40 environment
  always @(posedge clk or negedge rst_n)
    if (!rst_n)
      count40 <= 6'd38;
    else if (count40 == 6'd39)
      count40 <= 6'd0;
    else
      count40 <= count40 + 6'd1;

endmodule
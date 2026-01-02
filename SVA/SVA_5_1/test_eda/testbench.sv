`include "formal.sv"

/*

module FSM_IF_TEST;

  logic        clk;
  logic        rst_n;
  logic [5:0]  count40;

  wire tclk, trst, dq_en, sr_en;

  FSM_IF U1 (
    .clk(clk),
    .rst_n(rst_n),
    .count40(count40),
    .tclk(tclk),
    .trst(trst),
    .dq_en(dq_en),
    .sr_en(sr_en)
  );

  // 1) Clock generator
  initial clk = 0;
  always #5 clk = ~clk;

  // 2) Reset sequence + end simulation
  initial begin
    rst_n   = 0;
    count40 = 0;
    repeat (2) @(posedge clk);
    rst_n   = 1;

    // run long enough to see init->load_command etc.
    repeat (120) @(posedge clk);
    $finish;
  end

  // 3) Counter behavior (this is your "environment constraint" in simulation)
  always @(posedge clk or negedge rst_n)
    if (!rst_n)
      count40 <= 6'd38;           // matches your lab trick to hit 39 quickly
    else if (count40 == 6'd39)
      count40 <= 6'd0;
    else
      count40 <= count40 + 6'd1;

endmodule

*/
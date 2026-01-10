// ============================================================
// Full runnable SystemVerilog demo
// - Includes the slide code "intact" (same declarations + covergroup)
// - Wraps it in a module with clk + signals
// - Top testbench generates stimulus and prints bin counts + coverage
// ============================================================
`timescale 1ns/1ps

// ---------- Slide code types ----------
typedef enum bit[2:0] {IDLE, PLAY, PAUSE, INCR, DECR, STOP, REWIND} op_t;
typedef enum bit[1:0] {REG0, REG1, REG2, REG3} regs_t;

// ============================================================
// DUT-ish wrapper that contains the slide code (covergroup)
// ============================================================
module cov_dut (input logic clk);

  // ----- Slide code declarations (intact) -----
  op_t        opc;
  regs_t      regs;
  logic[3:0]  data;

  covergroup cg @(posedge clk);

    c1: coverpoint opc { bins op[] = { [PLAY:$] }; }

    c2: coverpoint regs;

    c3: coverpoint data {
      bins low[]  = { [0:'h03] };
      bins high   = { ['h4:'h8] };
    }

    c3xc2: cross c3,c2 {
      bins cross1 = binsof(c2) intersect {REG1} && binsof(c3) intersect {2};
    }

  endgroup

  cg cg1 = new();

endmodule



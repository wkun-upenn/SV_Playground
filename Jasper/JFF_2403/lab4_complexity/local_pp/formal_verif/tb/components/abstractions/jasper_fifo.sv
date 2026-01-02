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

module jasper_fifo #(
  WIDTH=8,
  DEPTH=4,
  BYPASS=1,
  ASSERTS=0,
  ASSERT_NO_UNDERFLOW=0,
  ASSERT_NO_OVERFLOW=0,
  ASSUMES=0,
  ASSUME_NO_UNDERFLOW=0,
  ASSUME_NO_OVERFLOW=0
) (
  input bit clk, rstN,
  input bit push,
  input bit [WIDTH-1:0] data_in,
  input bit pop,
  output bit data_front_valid,
  output bit [WIDTH-1:0] data_front,
  output bit data_out_valid,
  output bit [WIDTH-1:0] data_out,
  output bit [DEPTH:0] level,
  output bit full, empty,
  output bit overflow, underflow
);

  default disable iff (!rstN);
  default clocking cb @(posedge clk); endclocking

  bit [DEPTH-1:0][WIDTH-1:0] mem, mem_nx;
  bit [DEPTH-1:0]            vld, vld_nx;

  bit [WIDTH-1:0] data_front_free;

  always @(posedge clk or negedge rstN) begin
    if (!rstN) begin
      vld <= {DEPTH{1'b0}};
      mem <= {WIDTH*DEPTH{1'b0}};
      data_out_valid <= 1'b0;
    end else begin
      mem <= mem_nx;
      vld <= vld_nx;
      data_out <= data_front;
      data_out_valid <= (data_front_valid && pop);
    end
  end

  assign full = &vld;
  assign empty = !vld[0];

  always_comb begin
    mem_nx = mem;
    vld_nx = vld;
    level = 0;
    if (pop) begin
      mem_nx = mem_nx >> WIDTH;
      vld_nx = vld_nx >> 1;
    end
    if (push) begin
      for (int i=0; i<DEPTH; i++) begin
        if (!vld_nx[i]) mem_nx[i] = data_in;
      end
      for (int i=0; i<DEPTH; i++) begin
        if (!vld_nx[i]) begin
          vld_nx[i] = 1'b1;
          break;
        end else begin
          level++;
        end
      end
    end
  end

  if (BYPASS) begin
    assign data_front = (empty && push && pop) ? data_in :
                        (!empty) ? mem[0] :
                        data_front_free;
    assign data_front_valid = (!empty) || (empty && push && pop);
    assign underflow = empty && pop && !push;
  end else begin
    assign data_front = (!empty) ? mem[0] : data_front_free;
    assign data_front_valid = (!empty);
    assign underflow = empty && pop;
  end
  assign overflow = full && push && !pop;

  if (ASSERTS || ASSERT_NO_OVERFLOW) begin: GEN_AST_NO_OVERFLOW
    AST_no_overflow: assert property (!overflow);
  end
  if (ASSERTS || ASSERT_NO_UNDERFLOW) begin: GEN_AST_NO_UNDERFLOW
    AST_no_underflow: assert property (!underflow);
  end
  if (ASSUMES || ASSUME_NO_OVERFLOW) begin: GEN_ASM_NO_OVERFLOW
    ASM_no_overflow: assume property (!overflow);
  end
  if (ASSUMES || ASSUME_NO_UNDERFLOW) begin: GEN_ASM_NO_UNDERFLOW
    ASM_no_underflow: assume property (!underflow);
  end

endmodule




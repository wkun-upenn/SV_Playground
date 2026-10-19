// Here we must define some basic data flow and operations involved in the design
// otherwise UVM is going to compute nothing. WHen in_valid is HIGH, we start buffering
// the input matching what the instructions said.


`timescale 1ns/1ps
module systolic_array #(parameter int DIN_WIDTH = 8, parameter int N = 4) (
  input  logic                    rst_n,
  input  logic                    clk,
  input  logic [2*DIN_WIDTH-1:0]  c_din  [0:N-1],
  input  logic [DIN_WIDTH-1:0]    a_din  [0:N-1],
  input  logic [DIN_WIDTH-1:0]    b_din  [0:N-1],
  input  logic                    in_valid,
  output logic [2*DIN_WIDTH-1:0]  c_dout [0:N-1],
  output logic                    out_valid
);
  localparam int ACC_W = 2*DIN_WIDTH;

  logic signed [ACC_W-1:0] acc  [0:N-1][0:N-1];   // live accumulator
  logic signed [ACC_W-1:0] cout [0:N-1][0:N-1];   // latched result for streaming
  logic                    accumulating;
  int                      ecnt, eidx;            // output stream counters

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accumulating <= 1'b0; ecnt <= 0; eidx <= 0; out_valid <= 1'b0;
      for (int i = 0; i < N; i++) begin
        c_dout[i] <= '0;
        for (int j = 0; j < N; j++) begin acc[i][j] <= '0; cout[i][j] <= '0; end
      end
    end else begin
      out_valid <= 1'b0;

      // ---- accumulate one rank-1 update per input cycle ----
      if (in_valid) begin
        for (int i = 0; i < N; i++)
          for (int j = 0; j < N; j++) begin
            if (!accumulating)  // first cycle of the matrix: seed with c_din
              acc[i][j] <= $signed(c_din[j]) + ($signed(a_din[i]) * $signed(b_din[j]));
            else
              acc[i][j] <= acc[i][j] + ($signed(a_din[i]) * $signed(b_din[j]));
          end
        accumulating <= 1'b1;
      end
      // ---- input window ended: latch result, begin streaming ----
      else if (accumulating) begin
        for (int i = 0; i < N; i++)
          for (int j = 0; j < N; j++) cout[i][j] <= acc[i][j];
        accumulating <= 1'b0;
        ecnt <= N;
        eidx <= 0;
      end

      // ---- stream one C row per cycle ----
      if (ecnt != 0) begin
        out_valid <= 1'b1;
        for (int j = 0; j < N; j++) c_dout[j] <= cout[eidx][j];
        eidx <= eidx + 1;
        ecnt <= ecnt - 1;
      end
    end
  end
endmodule : systolic_array

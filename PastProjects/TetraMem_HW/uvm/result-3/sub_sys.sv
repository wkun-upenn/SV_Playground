
// From HW Page 12, we can derive an behavioural model for the subsystem level design.
// We have input FIFO from bus and output FIFO taking in output from systolic array.
// However, to simplify the modeling for both systolic_array and subsystem, we are seperating
// the two designs here and it could narrow the design of UVM environment down to seperate
// components.

`timescale 1ns/1ps
module sub_sys #(parameter int DIN_WIDTH = 8, parameter int N = 4,
                 parameter int BUS_WIDTH = 2*DIN_WIDTH*N) (
  input  logic                  rst_n,
  input  logic                  sys_clk, // bus read/write clock
  input  logic                  sr_clk, // systolic-array clock
  input  logic [7:0]            M_minus_one,
  input  logic [BUS_WIDTH-1:0]  din,
  input  logic                  wr_fifo,
  input  logic                  rd_fifo,
  output logic                  in_fifo_full,
  output logic [BUS_WIDTH-1:0]  dout,
  output logic                  out_fifo_empty
);
  localparam int ACC_W = 2*DIN_WIDTH;
  localparam int DEPTH = 4; // FIFO depth
  localparam int AW    = $clog2(DEPTH);

  // input FIFO (mem + pointers)
  logic [BUS_WIDTH-1:0] imem [0:DEPTH-1];
  logic [AW:0]          iwr, ird; // write=sys, read=sr
  assign in_fifo_full = ((iwr - ird) >= DEPTH[AW:0]);

  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) iwr <= '0;
    else if (wr_fifo && !in_fifo_full) begin
      imem[iwr[AW-1:0]] <= din;
      iwr <= iwr + 1'b1;
    end
  end

  // output FIFO (mem + pointers)
  logic [BUS_WIDTH-1:0] omem [0:DEPTH-1];
  logic [AW:0]          owr, ord; // write=sr, read=sys
  assign out_fifo_empty = (owr == ord);
  assign dout           = omem[ord[AW-1:0]];

  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) ord <= '0;
    else if (rd_fifo && !out_fifo_empty) ord <= ord + 1'b1;
  end

  // compute engine
  // read M samples, accumulate C, stream N result rows into the output
  // FIFO one row per cycle.
  logic [BUS_WIDTH-1:0] hold [0:N-1];
  int   emit_cnt, emit_idx, Mv;
  logic [BUS_WIDTH-1:0] s, row;
  logic [AW-1:0]        idx;
  logic signed [DIN_WIDTH-1:0] Amat [0:N-1][0:N-1];
  logic signed [DIN_WIDTH-1:0] Bmat [0:N-1][0:N-1];
  longint acc;

  wire out_full = ((owr - ord) >= DEPTH[AW:0]);   // output FIFO full (compute-side view)

  always @(posedge sr_clk or negedge rst_n) begin
    if (!rst_n) begin
      ird <= '0; owr <= '0; emit_cnt <= 0; emit_idx <= 0;
    end else if (emit_cnt != 0) begin
      // stream one held C row into the output FIFO, stalling if it is full
      if (!out_full) begin
        omem[owr[AW-1:0]] <= hold[emit_idx];
        owr      <= owr + 1'b1;
        emit_idx <= emit_idx + 1;
        emit_cnt <= emit_cnt - 1;
      end
    end else begin
      Mv = M_minus_one + 1;
      if (Mv > N) Mv = N;
      if ((iwr - ird) >= Mv[AW:0]) begin
        // unpack Mv samples  { A column , B row }
        for (int k = 0; k < Mv; k++) begin
          idx = ird[AW-1:0] + k[AW-1:0];
          s   = imem[idx];
          for (int j = 0; j < N; j++) Bmat[k][j] = $signed(s[j*DIN_WIDTH               +: DIN_WIDTH]);
          for (int i = 0; i < N; i++) Amat[i][k] = $signed(s[N*DIN_WIDTH + i*DIN_WIDTH +: DIN_WIDTH]);
        end
        for (int k = Mv; k < N; k++)
          for (int j = 0; j < N; j++) Bmat[k][j] = '0;
        for (int i = 0; i < N; i++)
          for (int k = Mv; k < N; k++) Amat[i][k] = '0;
        // multiply -> hold[]
        for (int i = 0; i < N; i++) begin
          row = '0;
          for (int j = 0; j < N; j++) begin
            acc = 0;
            for (int k = 0; k < Mv; k++) acc += Amat[i][k] * Bmat[k][j];
            row[j*ACC_W +: ACC_W] = acc[ACC_W-1:0];
          end
          hold[i] = row;
        end
        ird      <= ird + Mv[AW:0];
        emit_cnt <= N;
        emit_idx <= 0;
      end
    end
  end
endmodule : sub_sys

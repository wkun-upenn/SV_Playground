//======================================================================
// data_align.sv  -  A-matrix alignment / transpose buffer
//----------------------------------------------------------------------
// The bus delivers A one COLUMN at a time (sample k carries A[:,k]) but
// the systolic array consumes A one ROW at a time (compute cycle s needs
// A[s,:]).  This unit stores the incoming columns and reads them back as
// rows, zero-padding any contraction index k > M-1 so an N x M operand
// maps cleanly onto the N x N array.
//
//   amem[i][k] = A[i][k]
//   write : wr_col=1 stores col_data (=A[:,wr_idx]) into column wr_idx
//   read  : row_data[k] = (k <= m_minus_one) ? amem[rd_row][k] : 0
//
// (Column->row reorder is the "transpose"; the array itself applies the
//  systolic skew, so no skew logic is needed here.)
//======================================================================
module data_align #(
  parameter int DIN_WIDTH = 8,
  parameter int N         = 4
)(
  input  logic                    clk,
  input  logic                    rst_n,
  // write (one A column per sample)
  input  logic                    wr_col,
  input  logic [$clog2(N)-1:0]    wr_idx,
  input  logic [DIN_WIDTH-1:0]    col_data [0:N-1],
  // read (one A row per compute cycle)
  input  logic [7:0]              m_minus_one,
  input  logic [$clog2(N)-1:0]    rd_row,
  output logic [DIN_WIDTH-1:0]    row_data [0:N-1]
);

  logic [DIN_WIDTH-1:0] amem [0:N-1][0:N-1];   // amem[row][col]

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < N; i++)
        for (int k = 0; k < N; k++)
          amem[i][k] <= '0;
    end else if (wr_col) begin
      for (int i = 0; i < N; i++)
        amem[i][wr_idx] <= col_data[i];
    end
  end

  always_comb begin
    for (int k = 0; k < N; k++)
      row_data[k] = (k <= int'(m_minus_one)) ? amem[rd_row][k] : '0;
  end

endmodule : data_align

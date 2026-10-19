//======================================================================
// sub_sys.sv  -  streaming matrix-multiply sub-system (page 12)
//----------------------------------------------------------------------
// Integrates, around the N x N systolic array:
//   * input  async FIFO  (sys_clk -> sr_clk)   : buffers bus samples
//   * systolic_ctrl       (sr_clk)             : sequences the array
//   * data_align          (sr_clk)             : A column -> row reorder
//   * systolic_array      (sr_clk)             : the compute engine
//   * output async FIFO  (sr_clk -> sys_clk)   : buffers C result rows
//
// Bus formats (BUS_WIDTH = 2*DIN_WIDTH*N)
//   din  sample : [ N*DIN_WIDTH-1 : 0 ]            = B row  k (elem j)
//                 [ 2*N*DIN_WIDTH-1 : N*DIN_WIDTH] = A column k (elem i)
//   dout word   : N elements of one C row, 2*DIN_WIDTH bits each.
//
// sys_clk and sr_clk are independent; the FIFOs perform the CDC.
//======================================================================
module sub_sys #(
  parameter int DIN_WIDTH = 8,
  parameter int N         = 4,
  parameter int BUS_WIDTH = 2*DIN_WIDTH*N
)(
  input  logic                  rst_n,       // active-low reset
  input  logic                  sys_clk,     // bus read/write clock
  input  logic                  sr_clk,      // systolic-array clock
  input  logic [7:0]            M_minus_one, // (M-1) for the N x M / M x N op
  input  logic [BUS_WIDTH-1:0]  din,         // input sample (A col + B row)
  input  logic                  wr_fifo,     // write input FIFO (active high)
  input  logic                  rd_fifo,     // read output FIFO (active high)
  output logic                  in_fifo_full,
  output logic [BUS_WIDTH-1:0]  dout,        // one C row
  output logic                  out_fifo_empty
);

  localparam int ACC_W = 2*DIN_WIDTH;
  localparam int CW    = (N > 1) ? $clog2(N) : 1;

  // -------- input FIFO (sys_clk -> sr_clk) --------
  logic                 in_empty;
  logic [BUS_WIDTH-1:0] in_rdata;
  logic                 in_rd;

  async_fifo #(.WIDTH(BUS_WIDTH), .DEPTH(16)) u_in_fifo (
    .wclk(sys_clk), .wrst_n(rst_n), .wr_en(wr_fifo), .wdata(din), .full(in_fifo_full),
    .rclk(sr_clk),  .rrst_n(rst_n), .rd_en(in_rd),   .rdata(in_rdata), .empty(in_empty)
  );

  // -------- output FIFO (sr_clk -> sys_clk) --------
  logic                 out_full;
  logic                 out_wr;
  logic [BUS_WIDTH-1:0] out_wdata;

  async_fifo #(.WIDTH(BUS_WIDTH), .DEPTH(16)) u_out_fifo (
    .wclk(sr_clk),  .wrst_n(rst_n), .wr_en(out_wr),  .wdata(out_wdata), .full(out_full),
    .rclk(sys_clk), .rrst_n(rst_n), .rd_en(rd_fifo), .rdata(dout),      .empty(out_fifo_empty)
  );

  // -------- controller <-> data_align / array wiring --------
  logic                 dal_wr;
  logic [CW-1:0]        dal_wr_idx;
  logic [DIN_WIDTH-1:0] dal_col   [0:N-1];
  logic [CW-1:0]        dal_rd_row;
  logic [7:0]           dal_m;
  logic [DIN_WIDTH-1:0] align_row [0:N-1];

  logic [DIN_WIDTH-1:0] ctrl_bdin [0:N-1];
  logic                 ctrl_in_valid;
  logic                 ctrl_wload_en;
  logic                 ctrl_wswap;
  logic [ACC_W-1:0]     arr_cdout [0:N-1];
  logic                 arr_ovalid;

  logic [ACC_W-1:0]     arr_cdin  [0:N-1];
  always_comb for (int j = 0; j < N; j++) arr_cdin[j] = '0;  // no loop-back (M<=N)

  systolic_ctrl #(.DIN_WIDTH(DIN_WIDTH), .N(N), .BUS_WIDTH(BUS_WIDTH)) u_ctrl (
    .clk(sr_clk), .rst_n(rst_n), .m_minus_one(M_minus_one),
    .in_empty(in_empty), .in_rdata(in_rdata), .in_rd(in_rd),
    .out_full(out_full), .out_wr(out_wr), .out_wdata(out_wdata),
    .dal_wr(dal_wr), .dal_wr_idx(dal_wr_idx), .dal_col(dal_col),
    .dal_rd_row(dal_rd_row), .dal_m(dal_m),
    .b_din(ctrl_bdin), .in_valid(ctrl_in_valid),
    .w_load_en(ctrl_wload_en), .w_swap(ctrl_wswap),
    .c_dout(arr_cdout), .out_valid(arr_ovalid)
  );

  data_align #(.DIN_WIDTH(DIN_WIDTH), .N(N)) u_align (
    .clk(sr_clk), .rst_n(rst_n),
    .wr_col(dal_wr), .wr_idx(dal_wr_idx), .col_data(dal_col),
    .m_minus_one(dal_m), .rd_row(dal_rd_row), .row_data(align_row)
  );

  systolic_array #(.DIN_WIDTH(DIN_WIDTH), .N(N)) u_array (
    .rst_n(rst_n), .clk(sr_clk),
    .c_din(arr_cdin), .a_din(align_row), .b_din(ctrl_bdin),
    .in_valid(ctrl_in_valid), .w_load_en(ctrl_wload_en), .w_swap(ctrl_wswap),
    .c_dout(arr_cdout), .out_valid(arr_ovalid)
  );

endmodule : sub_sys

//======================================================================
// systolic_array.sv  -  N x N weight-stationary systolic array
//----------------------------------------------------------------------
// Computes  C = A x B   for square operands (M = N, see ASSUMPTIONS).
//   A : N x N   (row  i streamed on a_din, one row per compute cycle)
//   B : N x N   (row  k loaded  on b_din, one row per load    cycle)
//   C : N x N   (row  i produced on c_dout, one row per output cycle)
//
// Dataflow (page 3-9 of the assignment)
// -------------------------------------
//   * Weights are STATIONARY: PE(r,c) holds B[r][c].
//   * Activations flow LEFT -> RIGHT     (a_out = a_in, registered).
//   * Partial sums flow TOP -> BOTTOM    (c_out = a*b + c_in).
//   * Column c of the mesh therefore reduces   sum_r A[i][r]*B[r][c]
//     = C[i][c], read out of the bottom.
//
// Internal skew / de-skew
// -----------------------
// To keep the *external* interface clean (whole rows in, whole rows out)
// the array skews the activations and de-skews the results internally:
//   * a_din[r] is delayed by  r      cycles before entering row r
//   * column c result is delayed by (N-1-c) cycles on the way out
// so every c_dout bus carries one aligned row of C.  With this scheme
// row i of C appears (2N-1) cycles after row i of A was applied, hence
//   out_valid = in_valid delayed by (2N-1).
//
// Double-buffered weights (page 10)
// ---------------------------------
// Each PE holds two weight registers.  b_din/w_load_en write the
// *inactive* buffer while the array keeps computing with the active one;
// a single w_swap pulse activates the new B with zero stall.
//
// ASSUMPTIONS / control
// ---------------------
// The assignment lists only rst_n/clk/c_din/a_din/b_din/in_valid/
// c_dout/out_valid but explicitly notes "control signals etc. are not
// listed".  This model adds the two implied control strobes:
//     w_load_en : qualifies b_din as sequential weight-load rows
//     w_swap    : activates the freshly loaded weight buffer
// The surrounding controller (see sub_sys / testbench) drives them so
// that a weight swap never occurs while a previous frame is still
// draining (M = N assumed; general M>N would loop c_dout back to c_din).
//======================================================================
module systolic_array #(
  parameter int DIN_WIDTH = 8,
  parameter int N         = 4
)(
  input  logic                          rst_n,     // active-low reset
  input  logic                          clk,
  input  logic [2*DIN_WIDTH-1:0]        c_din  [0:N-1], // top-row partial-sum seed (0, or loop-back)
  input  logic [DIN_WIDTH-1:0]          a_din  [0:N-1], // one row of A per compute cycle
  input  logic [DIN_WIDTH-1:0]          b_din  [0:N-1], // one row of B per weight-load cycle
  input  logic                          in_valid,  // activation stream is valid this cycle
  input  logic                          w_load_en, // latch b_din into inactive weight buffer
  input  logic                          w_swap,    // activate loaded weights
  output logic [2*DIN_WIDTH-1:0]        c_dout [0:N-1], // one aligned row of C per output cycle
  output logic                          out_valid  // c_dout carries a valid row of C
);

  localparam int ACC_W = 2*DIN_WIDTH;

  // ---------------- weight-load row pointer ----------------
  // wl_cnt selects which PE row latches b_din this cycle.  It is reset
  // whenever loading is idle so a new load window always starts at row 0.
  localparam int CW = (N > 1) ? $clog2(N) : 1;
  logic [CW-1:0] wl_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)                wl_cnt <= '0;
    else if (!w_load_en)       wl_cnt <= '0;
    else if (wl_cnt != CW'(N-1)) wl_cnt <= wl_cnt + 1'b1;
  end

  // ---------------- activation input skew ----------------
  // a_in_m[r] = masked activation (0 unless a valid compute cycle).
  logic signed [DIN_WIDTH-1:0] a_in_m [0:N-1];
  always_comb begin
    for (int i = 0; i < N; i++)
      a_in_m[i] = in_valid ? $signed(a_din[i]) : '0;
  end

  // a_sk[r] = a_in_m[r] delayed by r cycles (triangular skew network)
  logic signed [DIN_WIDTH-1:0] a_sk [0:N-1];

  genvar gr, gc, gd;
  generate
    for (gr = 0; gr < N; gr++) begin : G_SKEW
      if (gr == 0) begin : G_SK0
        assign a_sk[0] = a_in_m[0];
      end else begin : G_SKR
        logic signed [DIN_WIDTH-1:0] sr [0:gr-1];
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            for (int d = 0; d < gr; d++) sr[d] <= '0;
          end else begin
            sr[0] <= a_in_m[gr];
            for (int d = 1; d < gr; d++) sr[d] <= sr[d-1];
          end
        end
        assign a_sk[gr] = sr[gr-1];
      end
    end
  endgenerate

  // ---------------- PE mesh ----------------
  // ah[r][c]   : activation entering PE(r,c)  (ah[r][0] = skewed input)
  // cv[r][c]   : partial sum entering PE(r,c) (cv[0][c] = c_din seed)
  logic signed [DIN_WIDTH-1:0] ah [0:N-1][0:N];
  logic signed [ACC_W-1:0]     cv [0:N][0:N-1];

  generate
    for (gr = 0; gr < N; gr++) begin : G_ROW
      assign ah[gr][0] = a_sk[gr];
    end
    for (gc = 0; gc < N; gc++) begin : G_COL
      assign cv[0][gc] = $signed(c_din[gc]);   // top-row seed
    end
    for (gr = 0; gr < N; gr++) begin : G_PR
      for (gc = 0; gc < N; gc++) begin : G_PC
        pe #(.DIN_WIDTH(DIN_WIDTH)) u_pe (
          .clk    (clk),
          .rst_n  (rst_n),
          .a_in   (ah[gr][gc]),
          .b_in   ($signed(b_din[gc])),
          .c_in   (cv[gr][gc]),
          .ld_w   (w_load_en && (wl_cnt == CW'(gr))),
          .swap_w (w_swap),
          .en     (1'b1),
          .a_out  (ah[gr][gc+1]),
          .c_out  (cv[gr+1][gc])
        );
      end
    end
  endgenerate

  // ---------------- output de-skew ----------------
  // column c bottom result is delayed by (N-1-c) so all columns align.
  generate
    for (gc = 0; gc < N; gc++) begin : G_DESKEW
      localparam int DLY = N-1-gc;
      if (DLY == 0) begin : G_DK0
        assign c_dout[gc] = cv[N][gc];
      end else begin : G_DKR
        logic signed [ACC_W-1:0] dsr [0:DLY-1];
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            for (int d = 0; d < DLY; d++) dsr[d] <= '0;
          end else begin
            dsr[0] <= cv[N][gc];
            for (int d = 1; d < DLY; d++) dsr[d] <= dsr[d-1];
          end
        end
        assign c_dout[gc] = dsr[DLY-1];
      end
    end
  endgenerate

  // ---------------- out_valid = in_valid delayed by (2N-1) ----------------
  localparam int OVD = 2*N-1;
  logic [OVD-1:0] ov_sr;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ov_sr <= '0;
    else        ov_sr <= {ov_sr[OVD-2:0], in_valid};
  end
  assign out_valid = ov_sr[OVD-1];

endmodule : systolic_array

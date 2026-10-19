//======================================================================
// systolic_ctrl.sv  -  sub-system controller (sr_clk domain)
//----------------------------------------------------------------------
// Orchestrates one matrix multiply at a time:
//
//   S_RD  : pop M (= m_minus_one+1) samples from the input FIFO.
//           Each sample = { A column k , B row k }.  B rows are latched
//           locally; A columns are pushed into the data_align buffer.
//   S_WLD : drive N weight-load cycles into the array (rows >= M_eff are
//           zero so an N x M operand works on the N x N mesh).
//   S_SWP : pulse w_swap to activate the freshly loaded weights.
//   S_CMP : stream N rows of A (from data_align) with in_valid.
//   S_COL : capture the N result rows as out_valid streams them out.
//   S_WR  : push the N C rows into the output FIFO (with back-pressure).
//
// Weight-load and result-capture are staged in local registers, so an
// empty input FIFO or a full output FIFO can never corrupt array timing.
//
// M_eff = min(M, N).  M > N (which needs c_din loop-back accumulation)
// is out of scope for this model and is clamped to N (see README).
//======================================================================
module systolic_ctrl #(
  parameter int DIN_WIDTH = 8,
  parameter int N         = 4,
  parameter int BUS_WIDTH = 2*DIN_WIDTH*N
)(
  input  logic                    clk,       // sr_clk
  input  logic                    rst_n,
  input  logic [7:0]              m_minus_one,

  // input FIFO (read side, FWFT)
  input  logic                    in_empty,
  input  logic [BUS_WIDTH-1:0]    in_rdata,
  output logic                    in_rd,

  // output FIFO (write side)
  input  logic                    out_full,
  output logic                    out_wr,
  output logic [BUS_WIDTH-1:0]    out_wdata,

  // data_align interface
  output logic                    dal_wr,
  output logic [$clog2(N)-1:0]    dal_wr_idx,
  output logic [DIN_WIDTH-1:0]    dal_col [0:N-1],
  output logic [$clog2(N)-1:0]    dal_rd_row,
  output logic [7:0]              dal_m,

  // systolic array interface
  output logic [DIN_WIDTH-1:0]    b_din [0:N-1],
  output logic                    in_valid,
  output logic                    w_load_en,
  output logic                    w_swap,
  input  logic [2*DIN_WIDTH-1:0]  c_dout [0:N-1],
  input  logic                    out_valid
);

  localparam int ACC_W = 2*DIN_WIDTH;
  localparam int CW    = (N > 1) ? $clog2(N) : 1;

  typedef enum logic [2:0] {S_RD, S_WLD, S_SWP, S_CMP, S_COL, S_WR} state_t;
  state_t st;

  logic [8:0]  samp_total;          // latched M (1..256)
  logic [8:0]  k;                   // samples popped so far
  logic [CW:0] t, s, rcv, wr_i;     // phase counters
  logic [8:0]  m_eff;               // min(M,N)

  logic [DIN_WIDTH-1:0] Bmat [0:N-1][0:N-1];  // Bmat[row][col]
  logic [ACC_W-1:0]     Cmat [0:N-1][0:N-1];  // Cmat[row][col]

  // ---- combinational unpack of the current input sample ----
  logic [DIN_WIDTH-1:0] samp_Brow [0:N-1];
  logic [DIN_WIDTH-1:0] samp_Acol [0:N-1];
  always_comb begin
    for (int j = 0; j < N; j++) begin
      samp_Brow[j] = in_rdata[j*DIN_WIDTH               +: DIN_WIDTH];
      samp_Acol[j] = in_rdata[N*DIN_WIDTH + j*DIN_WIDTH +: DIN_WIDTH];
    end
  end

  wire [8:0] m_full    = m_minus_one + 9'd1;             // M
  wire [8:0] m_eff_w   = (m_full > 9'(N)) ? 9'(N) : m_full;
  wire [8:0] cur_total = (k == 9'd0) ? m_full : samp_total;
  wire       last_samp = (k == cur_total - 9'd1);

  // ---------------- combinational outputs ----------------
  always_comb begin
    in_rd      = 1'b0;
    out_wr     = 1'b0;
    out_wdata  = '0;
    dal_wr     = 1'b0;
    dal_wr_idx = k[CW-1:0];
    dal_rd_row = s[CW-1:0];
    dal_m      = m_eff[7:0] - 8'd1;
    in_valid   = 1'b0;
    w_load_en  = 1'b0;
    w_swap     = 1'b0;
    for (int j = 0; j < N; j++) begin
      b_din[j]   = '0;
      dal_col[j] = samp_Acol[j];
    end

    unique case (st)
      S_RD: begin
        if (!in_empty) begin
          in_rd = 1'b1;
          if (k < 9'(N)) dal_wr = 1'b1;   // store A column k
        end
      end
      S_WLD: begin
        w_load_en = 1'b1;
        for (int j = 0; j < N; j++)
          b_din[j] = ({{(9-CW-1){1'b0}}, t} < m_eff) ? Bmat[t[CW-1:0]][j] : '0;
      end
      S_SWP:  w_swap   = 1'b1;
      S_CMP:  in_valid = 1'b1;             // a_din is data_align.row_data
      S_WR: begin
        if (!out_full) begin
          out_wr = 1'b1;
          for (int j = 0; j < N; j++)
            out_wdata[j*ACC_W +: ACC_W] = Cmat[wr_i[CW-1:0]][j];
        end
      end
      default: ;
    endcase
  end

  // ---------------- sequential FSM ----------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st         <= S_RD;
      k          <= '0;
      t          <= '0;
      s          <= '0;
      rcv        <= '0;
      wr_i       <= '0;
      samp_total <= 9'd1;
      m_eff      <= 9'd1;
    end else begin
      unique case (st)
        //-----------------------------------------------------
        S_RD: begin
          if (k == 9'd0) begin              // latch M at matrix start
            samp_total <= m_full;
            m_eff      <= m_eff_w;
          end
          if (!in_empty) begin
            if (k < 9'(N))
              for (int j = 0; j < N; j++) Bmat[k[CW-1:0]][j] <= samp_Brow[j];
            if (last_samp) begin
              st <= S_WLD;
              t  <= '0;
              k  <= '0;
            end else begin
              k <= k + 9'd1;
            end
          end
        end
        //-----------------------------------------------------
        S_WLD: begin
          if (t == CW'(N-1)) st <= S_SWP;
          t <= t + 1'b1;
        end
        //-----------------------------------------------------
        S_SWP: begin
          st <= S_CMP;
          s  <= '0;
        end
        //-----------------------------------------------------
        S_CMP: begin
          if (s == CW'(N-1)) begin
            st  <= S_COL;
            rcv <= '0;
          end
          s <= s + 1'b1;
        end
        //-----------------------------------------------------
        S_COL: begin
          if (out_valid) begin
            for (int j = 0; j < N; j++) Cmat[rcv[CW-1:0]][j] <= c_dout[j];
            if (rcv == CW'(N-1)) begin
              st   <= S_WR;
              wr_i <= '0;
            end
            rcv <= rcv + 1'b1;
          end
        end
        //-----------------------------------------------------
        S_WR: begin
          if (!out_full) begin
            if (wr_i == CW'(N-1)) begin
              st <= S_RD;
              k  <= '0;
            end
            wr_i <= wr_i + 1'b1;
          end
        end
        default: st <= S_RD;
      endcase
    end
  end

endmodule : systolic_ctrl

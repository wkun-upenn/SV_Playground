//======================================================================
// matmul_pkg.sv
//----------------------------------------------------------------------
// Golden reference model + shared verification helpers for the TetraMem
// systolic-array assignment.
//
// The systolic array computes  C = A x B  where
//     A is (N x M),  B is (M x N),  C is (N x N)
// and every element of A/B is a DIN_WIDTH-bit *signed* value.  Each
// element of C is 2*DIN_WIDTH bits (matching the RTL c_dout width).
//
// The hardware accumulators are 2*DIN_WIDTH wide and therefore wrap
// (two's-complement) if an accumulation overflows that width.  The
// golden model reproduces that exact wrapping via trunc_signed() so the
// scoreboard comparison is bit-accurate for *any* input, not just the
// non-overflowing subset.
//======================================================================
package matmul_pkg;

  // Largest N/M the helpers support (arrays are statically sized so the
  // model is fully Verilator-synthesizable/elaboratable).
  localparam int MAXN = 16;

  //--------------------------------------------------------------------
  // trunc_signed : take the low OW bits of v and sign-extend back to 64b
  // so the returned longint compares equal to the RTL's 2*DIN_WIDTH reg.
  //--------------------------------------------------------------------
  function automatic longint trunc_signed(input longint v, input int OW);
    longint mask;
    longint t;
    mask = (longint'(1) << OW) - 1;
    t    = v & mask;
    if (t[OW-1]) t = t - (longint'(1) << OW); // restore sign
    return t;
  endfunction

  //--------------------------------------------------------------------
  // golden_matmul : C = A x B  (signed), each C element truncated to OW.
  //   N  : rows of A / cols of B / dimension of the square result C
  //   M  : contraction dimension (cols of A / rows of B)
  //   OW : output element width = 2*DIN_WIDTH
  //--------------------------------------------------------------------
  function automatic void golden_matmul(
      input  int     N,
      input  int     M,
      input  int     OW,
      input  longint A [MAXN][MAXN],
      input  longint B [MAXN][MAXN],
      output longint C [MAXN][MAXN]);
    longint acc;
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        acc = 0;
        for (int k = 0; k < M; k++) begin
          acc += A[i][k] * B[k][j];
        end
        C[i][j] = trunc_signed(acc, OW);
      end
    end
  endfunction

  //--------------------------------------------------------------------
  // sign_ext : interpret the low W bits of a value as signed, return
  // it as a longint (used when unpacking bus words in the scoreboards).
  //--------------------------------------------------------------------
  function automatic longint sign_ext(input longint v, input int W);
    return trunc_signed(v, W);
  endfunction

endpackage : matmul_pkg

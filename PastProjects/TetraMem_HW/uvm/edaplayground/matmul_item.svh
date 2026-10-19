//======================================================================
// matmul_item.svh  -  shared sequence items (reused at both levels)
//----------------------------------------------------------------------
//  matmul_item : one matrix multiply  C[NxN] = A[NxM] * B[MxN], plus the
//                golden result.  Reused by the array and the sub-system.
//  read_item   : one "read a C row" token for the sub-system read channel.
//======================================================================
`ifndef MATMUL_ITEM_SVH
`define MATMUL_ITEM_SVH

class matmul_item extends uvm_sequence_item;
  // Constrained-random content is filled in gen()
  bit [`DW-1:0]    a [`NN][`NN];   // A: cols 0..m-1 used  (a[i][k] = A[i][k])
  bit [`DW-1:0]    b [`NN][`NN];   // B: rows 0..m-1 used  (b[k][j] = B[k][j])
  int unsigned     m;              // contraction dim M (1..N)
  bit [`ACCW-1:0]  c [`NN][`NN];   // result (golden or observed)
  bit              ovf;            // check if C[0][0] overflow the 2*DW accumulator

  `uvm_object_utils(matmul_item)
  function new(string name = "matmul_item"); super.new(name); endfunction

  function void gen(int mval);
    m = (mval > 0) ? mval : $urandom_range(1, `NN);
    for (int i = 0; i < `NN; i++)
      for (int k = 0; k < `NN; k++) a[i][k] = $urandom;
    for (int k = 0; k < `NN; k++)
      for (int j = 0; j < `NN; j++) b[k][j] = $urandom;
    compute();
  endfunction

  // Directed builder for coverage closure. Forces the sign of A[0][0],
  // B[0][0] and (hence) C[0][0] to fill the covergroup's neg/zero/pos bins.
  function void gen_cov(int mval, int a00, int b00, int mode);
    m = mval;
    for (int i = 0; i < `NN; i++)
      for (int k = 0; k < `NN; k++) a[i][k] = $urandom;   // random background
    for (int k = 0; k < `NN; k++)
      for (int j = 0; j < `NN; j++) b[k][j] = $urandom;
    case (mode)
      1: begin
           for (int k = 0; k < `NN; k++) a[0][k] = '0;     // A[0][0]=0, C[0][0]=0
           b[0][0] = b00[`DW-1:0];
         end
      2: begin
           for (int k = 0; k < `NN; k++) b[k][0] = '0;     // B[0][0]=0, C[0][0]=0
           a[0][0] = a00[`DW-1:0];
         end
      3: begin                                              // both zero
           for (int k = 0; k < `NN; k++) a[0][k] = '0;
           for (int k = 0; k < `NN; k++) b[k][0] = '0;
         end
      4: begin                                              // force C[0][0] overflow
           for (int k = 0; k < `NN; k++) a[0][k] = 8'sd127;
           for (int k = 0; k < `NN; k++) b[k][0] = 8'sd127; // C[0][0]=m*127*127
         end
      default: begin                                        // C[0][0] = a00*b00
           for (int k = 1; k < `NN; k++) a[0][k] = '0;
           a[0][0] = a00[`DW-1:0];
           b[0][0] = b00[`DW-1:0];
         end
    endcase
    compute();
  endfunction

  // signed matmul, truncated to 2*DW.
  // Also flags whether C[0][0] overflowed that width.
  function void compute();
    ovf = 1'b0;
    for (int i = 0; i < `NN; i++)
      for (int j = 0; j < `NN; j++) begin
        longint acc = 0;
        for (int k = 0; k < m; k++)
          acc += $signed(a[i][k]) * $signed(b[k][j]);
        c[i][j] = acc[`ACCW-1:0];
        if (i == 0 && j == 0)
          ovf = (longint'($signed(c[0][0])) != acc);   // truncation changed value
      end
  endfunction

  function string convert2string();
    return $sformatf("matmul_item m=%0d c[0][0]=%0d", m, $signed(c[0][0]));
  endfunction
endclass


class read_item extends uvm_sequence_item;
  `uvm_object_utils(read_item)
  function new(string name = "read_item"); super.new(name); endfunction
endclass

`endif

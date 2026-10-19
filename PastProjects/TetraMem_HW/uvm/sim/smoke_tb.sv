`timescale 1ns/1ps
module smoke_tb;
  localparam int DW=8, N=4, ACCW=16, BUSW=2*DW*N;
  int errors=0;
  function automatic longint tr(input longint v,input int OW);
    longint m=(longint'(1)<<OW)-1; longint t=v&m; if(t[OW-1]) t=t-(longint'(1)<<OW); return t;
  endfunction

  // ---- array ----
  logic clk=0; always #5 clk=~clk;
  logic rst_n;
  logic [ACCW-1:0] c_din[0:N-1], c_dout[0:N-1];
  logic [DW-1:0]   a_din[0:N-1], b_din[0:N-1];
  logic in_valid, out_valid;
  systolic_array #(.DIN_WIDTH(DW),.N(N)) arr(.rst_n,.clk,.c_din,.a_din,.b_din,.in_valid,.c_dout,.out_valid);

  task automatic arr_test(int Mv, int f);
    logic [DW-1:0] A[0:N-1][0:N-1], B[0:N-1][0:N-1];
    longint Cg[0:N-1][0:N-1]; logic [ACCW-1:0] Cd[0:N-1][0:N-1];
    int cap; longint a2;
    for(int i=0;i<N;i++) for(int k=0;k<Mv;k++) A[i][k]=$urandom;
    for(int k=0;k<Mv;k++) for(int j=0;j<N;j++) B[k][j]=$urandom;
    for(int i=0;i<N;i++) for(int j=0;j<N;j++) begin a2=0; for(int k=0;k<Mv;k++) a2+=tr(A[i][k],DW)*tr(B[k][j],DW); Cg[i][j]=tr(a2,ACCW); end
    // stream Mv cycles: a_din=column k, b_din=row k
    for(int i=0;i<N;i++) c_din[i]='0;
    for(int k=0;k<Mv;k++) begin
      @(negedge clk);
      for(int i=0;i<N;i++) a_din[i]=A[i][k];
      for(int j=0;j<N;j++) b_din[j]=B[k][j];
      in_valid=1;
    end
    @(negedge clk); in_valid=0;
    cap=0;
    for(int c=0;c<3*N+10 && cap<N;c++) begin
      @(posedge clk); #1;
      if(out_valid) begin for(int j=0;j<N;j++) Cd[cap][j]=c_dout[j]; cap++; end
    end
    if(cap!=N) begin errors++; $display("ARR f%0d M%0d got %0d rows",f,Mv,cap); end
    for(int i=0;i<N;i++) for(int j=0;j<N;j++) if(tr(Cd[i][j],ACCW)!==Cg[i][j]) begin errors++; if(errors<8) $display("ARR f%0d C[%0d][%0d]=%0d exp %0d",f,i,j,tr(Cd[i][j],ACCW),Cg[i][j]); end
    repeat(N+3) @(negedge clk);
  endtask

  // ---- sub_sys ----
  logic sys_clk=0; always #5 sys_clk=~sys_clk;
  logic sr_clk=0;  always #3 sr_clk=~sr_clk;
  logic srst;
  logic [7:0] Mm1; logic [BUSW-1:0] din, dout;
  logic wr,rd,full,empty;
  sub_sys #(.DIN_WIDTH(DW),.N(N),.BUS_WIDTH(BUSW)) ss(.rst_n(srst),.sys_clk,.sr_clk,.M_minus_one(Mm1),.din,.wr_fifo(wr),.rd_fifo(rd),.in_fifo_full(full),.dout,.out_fifo_empty(empty));

  task automatic ss_test(int Mv, int f);
    logic [DW-1:0] A[0:N-1][0:N-1], B[0:N-1][0:N-1];
    longint Cg[0:N-1][0:N-1]; logic [BUSW-1:0] samp[0:N-1], exp[0:N-1], got;
    int p,r; longint a2;
    for(int i=0;i<N;i++) for(int k=0;k<Mv;k++) A[i][k]=$urandom;
    for(int k=0;k<Mv;k++) for(int j=0;j<N;j++) B[k][j]=$urandom;
    for(int i=0;i<N;i++) for(int j=0;j<N;j++) begin a2=0; for(int k=0;k<Mv;k++) a2+=tr(A[i][k],DW)*tr(B[k][j],DW); Cg[i][j]=tr(a2,ACCW); end
    for(int k=0;k<Mv;k++) begin samp[k]='0; for(int j=0;j<N;j++) samp[k][j*DW+:DW]=B[k][j]; for(int i=0;i<N;i++) samp[k][N*DW+i*DW+:DW]=A[i][k]; end
    for(int i=0;i<N;i++) begin exp[i]='0; for(int j=0;j<N;j++) exp[i][j*ACCW+:ACCW]=Cg[i][j][ACCW-1:0]; end
    Mm1=Mv-1; p=0;
    while(p<Mv) begin @(negedge sys_clk); if(!full) begin din=samp[p]; wr=1; p++; end else wr=0; end
    @(negedge sys_clk); wr=0;
    r=0;
    while(r<N) begin
      @(negedge sys_clk);
      if(!empty) begin got=dout; rd=1; end else rd=0;
      @(posedge sys_clk); #1;
      if(rd) begin if(got!==exp[r]) begin errors++; $display("SS f%0d M%0d row%0d got=%h exp=%h",f,Mv,r,got,exp[r]); end r++; end
    end
    @(negedge sys_clk); rd=0; repeat(4) @(negedge sys_clk);
  endtask

  initial begin
    rst_n=0; srst=0; in_valid=0; wr=0; rd=0; din=0; Mm1=N-1;
    for(int i=0;i<N;i++) begin a_din[i]=0; b_din[i]=0; c_din[i]=0; end
    repeat(5) @(negedge clk); rst_n=1;
    repeat(5) @(negedge sys_clk); srst=1;
    // array: random M
    for(int f=0;f<6;f++) arr_test(N,f);
    arr_test(2,90); arr_test(3,91); arr_test(1,92);
    // sub_sys
    for(int f=0;f<5;f++) ss_test(N,f);
    ss_test(2,90); ss_test(3,91); ss_test(1,92);
    if(errors==0) $display("=== smoke PASSED (array + sub_sys, exact PDF interface) ===");
    else          $display("=== smoke FAILED : %0d errors ===",errors);
    $finish;
  end
  initial begin #500000; $display("=== smoke TIMEOUT ==="); $finish; end
endmodule

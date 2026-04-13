
// -------------------  n-bit flipflop --------------
module DFF (q,d,clk);
    parameter BusWidth=8; 	// default width
    output [BusWidth-1:0] q;
    input [BusWidth-1:0] d;
    input clk;
    
wire [BusWidth-1:0] q;
wire [BusWidth-1:0] d; //surefire lint_off_line RD_WRT
reg [BusWidth-1:0] QI;

//initial QI = 0;
always @(posedge clk)
    begin
	QI <= d;
    end

assign q = QI;

endmodule

// ---------------  n-bit flipflop with reset -------
module DFFR (q,d,clk,reset);
    parameter BusWidth=8; 	// default width
    // surefire lint_off MCATPA
    parameter [BusWidth-1:0] ResetVal = {BusWidth{1'b0}}; 	// default reset
    // surefire lint_on  MCATPA
    output [BusWidth-1:0] q;
    input [BusWidth-1:0] d;
    input clk;
    input reset; //surefire lint_off_line RD_WRT 
    
wire [BusWidth-1:0] q;
wire [BusWidth-1:0] d; //surefire lint_off_line RD_WRT
reg [BusWidth-1:0] QI;

always @(posedge clk)
    begin
       // This code was changed from a case construct to an if-else construct
       // in the interest of simulation performance.  The if expressions
       // initially used ===, but Synopsys choked on it.  In this context,
       // == has the same simulation result, so we now use it instead.
       // == is not believed to have any simulation performance penalty.
       if (reset == 1'b1) QI <= d;
       else if (reset == 1'b0) QI <= ResetVal[BusWidth-1:0];
       else QI <= {BusWidth{1'bx}};
    end
assign q = QI;

endmodule

// -------------------  n-bit flipflop with enable --
module EDFF (q,d,en,clk);

    parameter BusWidth=8; 	// default width

    output [BusWidth-1:0] q;
    input [BusWidth-1:0] d;
    input en;
    input clk;
    
wire [BusWidth-1:0] q,d;
reg [BusWidth-1:0] QI;

always @(posedge clk)
    begin
	if(en)
	    QI <= d;
    end
assign q = QI;

endmodule

// ------  n-bit flipflop with enable and reset ----
module EDFFR (q,d,en,clk,reset);

    parameter BusWidth=8; 	// default width
    // surefire lint_off MCATPA
    parameter [BusWidth-1:0] ResetVal = {BusWidth{1'b0}}; // default reset
    // surefire lint_on  MCATPA


    output [BusWidth-1:0] q;
    input [BusWidth-1:0] d; //surefire lint_off_line UDDICU
    input en;
    input clk;
    input reset; //surefire lint_off_line RD_WRT
    
wire [BusWidth-1:0] q;
wire [BusWidth-1:0] d; //surefire lint_off_line RD_WRT UDDICU
reg [BusWidth-1:0] QI;

always @(posedge clk)
    begin
      casez ({~reset,en})
        2'b00:;
	2'b01: QI <= d;
	2'b1?: QI <= ResetVal[BusWidth-1:0];
	default: QI <= {BusWidth{1'bx}};
      endcase
    end
assign q = QI;

endmodule
// -------------------  n-bit adder --------------
module ADD (s,a,b,ci);  
  
    parameter Width=8;		// default
    input  [Width-1:0]  a;
    input  [Width-1:0]  b;
    input              ci; 
    output [Width:0]  s;
 
assign	s = a + b + ci; // surefire lint_off_line ASWESB ASWESS

endmodule

// -------------------  n-bit 1's Complement Adder --------------
module ADD1C (s,a,b);  
  
    parameter Width=16;		// default
    input  [Width-1:0]  a;
    input  [Width-1:0]  b;
    output [Width-1:0]  s;

   wire [Width:0] 	s_nc;   // Sum No Carry
   wire [Width-1:0] 	s_wc;   // Sum w/Carry
   
   assign 		s_nc = {{1'b0, a} + {1'b0, b}};
   assign 		s_wc[Width-1:0] = {a + b + 1'b1};

   assign 		s = (s_nc[Width] ?       // Carry Out = 1
			     s_wc[Width-1:0] :   // Add back in Cout
			     s_nc[Width-1:0]);   // Normal Path

endmodule

// -------------------  n-bit incrementer --------------
module INC (s,a);  
  
    parameter Width=8;		// default
    input  [Width-1:0]  a;
    output [Width-1:0]  s;
 
assign	s[Width-1:0]={a[Width-1:0] + 1'b1};

endmodule

// -------------------  n-bit decrementer --------------
module DEC (s,a);  
  
    parameter Width=8;		// default
    input  [Width-1:0]  a;
    output [Width-1:0]  s;
 
assign	s[Width-1:0]={a[Width-1:0] - 1'b1};

endmodule
// ------------------- n-bit bit comparator ------------------

module CMP (aeqb,a, b);  
 
    parameter Width=8;		// default width
    input  [Width-1:0]  a;
    input  [Width-1:0]  b;
    output	        aeqb;	// a equal to b
 
assign aeqb = ( a[Width-1:0] == b[Width-1:0] ) ; 

endmodule

// ------------------- n-bit bit mux 2 -----------------------

module MUX2 (
    mo, 
    in1,
    in0,
    sel) ;

    parameter Width=8; 		// default
    output [Width-1:0] mo;
    input [Width-1:0] in1;
    input [Width-1:0] in0;
    input sel; // surefire lint_off_line UDDICU

reg [Width-1:0] mo;

always @(sel or in1 or in0 )
begin  
    case (sel)
    1'b1: mo = in1;
    1'b0: mo = in0;
    default: mo = {Width{1'bx}};
    endcase 
end 

endmodule

// ------------------- n-bit bit mux 3 -----------------------
module MUX3 (
    mo,
    in2,
    in1,
    in0,
    sel) ;

    parameter Width = 8; 	// default
    output [Width-1:0] mo;
    input [Width-1:0] in2;
    input [Width-1:0] in1;
    input [Width-1:0] in0;
    input [2:0] sel;

reg [Width-1:0] mo;
always @(sel or in2 or in1 or in0 )
begin
case (sel)
    3'b100: mo = in2;
    3'b010: mo = in1;
    3'b001: mo = in0;
    default: mo = {Width{1'bx}};
    endcase
end

endmodule

// ------------------- n-bit bit mux 4 -----------------------
module MUX4 (
    mo,
    in3,
    in2,
    in1,
    in0,
    sel) ;

    parameter Width = 8; 	// default
    output [Width-1:0] mo;
    input [Width-1:0] in3;
    input [Width-1:0] in2;
    input [Width-1:0] in1;
    input [Width-1:0] in0;
    input [3:0] sel;

reg [Width-1:0] mo;
always @(sel or in2 or in1 or in0 or in3)
begin
     case (sel)
    4'b1000: mo = in3;
    4'b0100: mo = in2;
    4'b0010: mo = in1;
    4'b0001: mo = in0;
    default: mo = {Width{1'bx}};
    endcase
end

endmodule

module MUX4S2 (
    mo,
    in3,
    in2,
    in1,
    in0,
    sel) ;

    parameter Width = 8; 	// default
    output [Width-1:0] mo;
    input [Width-1:0] in3; // surefire lint_off_line UDDICU
    input [Width-1:0] in2; // surefire lint_off_line UDDICU
    input [Width-1:0] in1;
    input [Width-1:0] in0;
    input [1:0] sel;

reg [Width-1:0] mo;
always @(sel or in2 or in1 or in0 or in3)
begin
     case (sel)
    2'b11: mo = in3;
    2'b10: mo = in2;
    2'b01: mo = in1;
    2'b00: mo = in0;
    default: mo = {Width{1'bx}};
    endcase
end

endmodule

// -------------------  2 to 4 decoder --------------
module DEC2x4 (i, o);
    output [3:0] o;
    input  [1:0] i;
    
   assign o[0] = ~i[1] & ~i[0]; // 00
   assign o[1] = ~i[1] &  i[0]; // 01
   assign o[2] =  i[1] & ~i[0]; // 10
   assign o[3] =  i[1] &  i[0]; // 11
   
endmodule

// -------------------  3 to 7 decoder --------------
module DEC3x7 (i, o);
    output [7:1] o;
    input  [2:0] i;
    
   assign o[1] = ~i[2] & ~i[1] &  i[0]; // 001
   assign o[2] = ~i[2] &  i[1] & ~i[0]; // 010
   assign o[3] = ~i[2] &  i[1] &  i[0]; // 011
   assign o[4] =  i[2] & ~i[1] & ~i[0]; // 100
   assign o[5] =  i[2] & ~i[1] &  i[0]; // 101
   assign o[6] =  i[2] &  i[1] & ~i[0]; // 110
   assign o[7] =  i[2] &  i[1] &  i[0]; // 110
   
endmodule

// -------------------  3 to 8 decoder --------------
module DEC3x8 (i, o);
    output [7:0] o;
    input  [2:0] i;
    
   assign o[0] = ~i[2] & ~i[1] & ~i[0]; // 000
   assign o[1] = ~i[2] & ~i[1] &  i[0]; // 001
   assign o[2] = ~i[2] &  i[1] & ~i[0]; // 010
   assign o[3] = ~i[2] &  i[1] &  i[0]; // 011
   assign o[4] =  i[2] & ~i[1] & ~i[0]; // 100
   assign o[5] =  i[2] & ~i[1] &  i[0]; // 101
   assign o[6] =  i[2] &  i[1] & ~i[0]; // 110
   assign o[7] =  i[2] &  i[1] &  i[0]; // 111
   
endmodule

// -------------------  4 to 16 decoder --------------
module DEC4x16 (i, o);
    output [15:0] o;
    input  [3:0]  i;
    
   assign o[0]  = ~i[3] & ~i[2] & ~i[1] & ~i[0]; // 0000
   assign o[1]  = ~i[3] & ~i[2] & ~i[1] &  i[0]; // 0001
   assign o[2]  = ~i[3] & ~i[2] &  i[1] & ~i[0]; // 0010
   assign o[3]  = ~i[3] & ~i[2] &  i[1] &  i[0]; // 0011
   assign o[4]  = ~i[3] &  i[2] & ~i[1] & ~i[0]; // 0100
   assign o[5]  = ~i[3] &  i[2] & ~i[1] &  i[0]; // 0101
   assign o[6]  = ~i[3] &  i[2] &  i[1] & ~i[0]; // 0110
   assign o[7]  = ~i[3] &  i[2] &  i[1] &  i[0]; // 0111
   assign o[8]  =  i[3] & ~i[2] & ~i[1] & ~i[0]; // 1000
   assign o[9]  =  i[3] & ~i[2] & ~i[1] &  i[0]; // 1001
   assign o[10] =  i[3] & ~i[2] &  i[1] & ~i[0]; // 1010
   assign o[11] =  i[3] & ~i[2] &  i[1] &  i[0]; // 1011
   assign o[12] =  i[3] &  i[2] & ~i[1] & ~i[0]; // 1100
   assign o[13] =  i[3] &  i[2] & ~i[1] &  i[0]; // 1101
   assign o[14] =  i[3] &  i[2] &  i[1] & ~i[0]; // 1110
   assign o[15] =  i[3] &  i[2] &  i[1] &  i[0]; // 1111

endmodule

// -------------------  4 to 14 decoder --------------
module DEC4x14 (i, o);
    output [15:2] o;
    input  [3:0]  i;
    
   assign o[2]  = ~i[3] & ~i[2] &  i[1] & ~i[0]; // 0010
   assign o[3]  = ~i[3] & ~i[2] &  i[1] &  i[0]; // 0011
   assign o[4]  = ~i[3] &  i[2] & ~i[1] & ~i[0]; // 0100
   assign o[5]  = ~i[3] &  i[2] & ~i[1] &  i[0]; // 0101
   assign o[6]  = ~i[3] &  i[2] &  i[1] & ~i[0]; // 0110
   assign o[7]  = ~i[3] &  i[2] &  i[1] &  i[0]; // 0111
   assign o[8]  =  i[3] & ~i[2] & ~i[1] & ~i[0]; // 1000
   assign o[9]  =  i[3] & ~i[2] & ~i[1] &  i[0]; // 1001
   assign o[10] =  i[3] & ~i[2] &  i[1] & ~i[0]; // 1010
   assign o[11] =  i[3] & ~i[2] &  i[1] &  i[0]; // 1011
   assign o[12] =  i[3] &  i[2] & ~i[1] & ~i[0]; // 1100
   assign o[13] =  i[3] &  i[2] & ~i[1] &  i[0]; // 1101
   assign o[14] =  i[3] &  i[2] &  i[1] & ~i[0]; // 1101
   assign o[15] =  i[3] &  i[2] &  i[1] &  i[0]; // 1101

endmodule


// -------------------  5 to 32 decoder --------------
module DEC5x32 (i, o);
    output [31:0] o;
    input  [4:0]  i;

   wire [3:0] dechi;
   wire [7:0] declo;

   DEC2x4 u_dh (.o(dechi), .i(i[4:3]));
   DEC3x8 u_dl (.o(declo), .i(i[2:0]));

   assign o = {{8{dechi[3]}} & declo,
	       {8{dechi[2]}} & declo,
	       {8{dechi[1]}} & declo,
	       {8{dechi[0]}} & declo};

endmodule
// -------------------  6 to 64 decoder --------------
module DEC6x64 (i, o);
    output [63:0] o;
    input  [5:0]  i;
    
   wire [7:0] dechi;
   wire [7:0] declo;

   DEC3x8 u_dh (.o(dechi), .i(i[5:3]));
   DEC3x8 u_dl (.o(declo), .i(i[2:0]));

   assign o = {{8{dechi[7]}} & declo,
	       {8{dechi[6]}} & declo,
	       {8{dechi[5]}} & declo,
	       {8{dechi[4]}} & declo,
	       {8{dechi[3]}} & declo,
	       {8{dechi[2]}} & declo,
	       {8{dechi[1]}} & declo,
	       {8{dechi[0]}} & declo};
endmodule
// -------------------  6 to 56 decoder --------------
module DEC6x56 (i, o);
    output [55:0] o;
    input  [5:0]  i;
    
   wire [7:1] dechi;
   wire [7:0] declo;

   DEC3x7 u_dh (.o(dechi), .i(i[5:3]));
   DEC3x8 u_dl (.o(declo), .i(i[2:0]));

   assign o = { {8{dechi[7]}} & declo,
	             {8{dechi[6]}} & declo,
	             {8{dechi[5]}} & declo,
	             {8{dechi[4]}} & declo,
	             {8{dechi[3]}} & declo,
	             {8{dechi[2]}} & declo,
	             {8{dechi[1]}} & declo};
endmodule



// -------------------  7 to 128 decoder --------------
module DEC7x128 (i, o);
    output [127:0] o;
    input  [6:0]  i;
    
   wire [7:0]  dechi;
   wire [15:0] declo;

   DEC3x8  u_dh (.o(dechi), .i(i[6:4]));
   DEC4x16 u_dl (.o(declo), .i(i[3:0]));

   assign o = {{16{dechi[7]}} & declo,
	       {16{dechi[6]}} & declo,
	       {16{dechi[5]}} & declo,
	       {16{dechi[4]}} & declo,
	       {16{dechi[3]}} & declo,
	       {16{dechi[2]}} & declo,
	       {16{dechi[1]}} & declo,
	       {16{dechi[0]}} & declo};
endmodule

// -------------------  8 to 256 decoder --------------
module DEC8x256 (i, o);

   output [255:0] o;
   input  [7:0]   i;

   wire [15:0] dechi;
   wire [15:0] declo;

   DEC4x16 u_dh (.o(dechi), .i(i[7:4]));
   DEC4x16 u_dl (.o(declo), .i(i[3:0]));

   assign o = {{16{dechi[15]}} & declo,
               {16{dechi[14]}} & declo,
               {16{dechi[13]}} & declo,
               {16{dechi[12]}} & declo,
               {16{dechi[11]}} & declo,
               {16{dechi[10]}} & declo,
               {16{dechi[9]}}  & declo,
               {16{dechi[8]}}  & declo,
               {16{dechi[7]}}  & declo,
               {16{dechi[6]}}  & declo,
               {16{dechi[5]}}  & declo,
               {16{dechi[4]}}  & declo,
               {16{dechi[3]}}  & declo,
               {16{dechi[2]}}  & declo,
               {16{dechi[1]}}  & declo,
               {16{dechi[0]}}  & declo};


endmodule // DEC8x256

// -------------------  8 to 224 decoder --------------
module DEC8x224 (i, o);

   output [223:0] o;
   input  [7:0]   i;

   wire [15:2] dechi;
   wire [15:0] declo;

   DEC4x14 u_dh (.o(dechi), .i(i[7:4]));
   DEC4x16 u_dl (.o(declo), .i(i[3:0]));

   assign o = {{16{dechi[15]}} & declo,
               {16{dechi[14]}} & declo,
               {16{dechi[13]}} & declo,
               {16{dechi[12]}} & declo,
               {16{dechi[11]}}  & declo,
               {16{dechi[10]}}  & declo,
               {16{dechi[9]}}  & declo,
               {16{dechi[8]}}  & declo,
               {16{dechi[7]}}  & declo,
               {16{dechi[6]}}  & declo,
               {16{dechi[5]}}  & declo,
               {16{dechi[4]}}  & declo,
               {16{dechi[3]}}  & declo,
               {16{dechi[2]}}  & declo};


endmodule // DEC8x224
// -------------------  8 to 224 decoder with Enable --------------
module DEC8x224E (i, o, en);

   output [223:0] o;
   input  [7:0]   i;
   input         en;

   wire [15:2] dechi;
   wire [15:0] declo;
   wire [15:0] decloe;

   DEC4x14 u_dh (.o(dechi), .i(i[7:4]));
   DEC4x16 u_dl (.o(declo), .i(i[3:0]));
   assign decloe = declo & {16{en}};

   assign o = {{16{dechi[15]}} & decloe,
               {16{dechi[14]}} & decloe,
               {16{dechi[13]}} & decloe,
               {16{dechi[12]}} & decloe,
               {16{dechi[11]}} & decloe,
               {16{dechi[10]}} & decloe,
               {16{dechi[9]}}  & decloe,
               {16{dechi[8]}}  & decloe,
               {16{dechi[7]}}  & decloe,
               {16{dechi[6]}}  & decloe,
               {16{dechi[5]}}  & decloe,
               {16{dechi[4]}}  & decloe,
               {16{dechi[3]}}  & decloe,
               {16{dechi[2]}}  & decloe};


endmodule // DEC8x224

// -------------------  16 Input Priority Decoder --------------
module PENC16(i, o);
   output [15:0] o;
   input [15:0]  i;

   assign o[15] = i[15];
   assign o[14] = i[14] & ~|i[15:15];
   assign o[13] = i[13] & ~|i[15:14];
   assign o[12] = i[12] & ~|i[15:13];
   assign o[11] = i[11] & ~|i[15:12];
   assign o[10] = i[10] & ~|i[15:11];
   assign o[9]  = i[9]  & ~|i[15:10];
   assign o[8]  = i[8]  & ~|i[15:9];
   assign o[7]  = i[7]  & ~|i[15:8];
   assign o[6]  = i[6]  & ~|i[15:7];
   assign o[5]  = i[5]  & ~|i[15:6];
   assign o[4]  = i[4]  & ~|i[15:5];
   assign o[3]  = i[3]  & ~|i[15:4];
   assign o[2]  = i[2]  & ~|i[15:3];
   assign o[1]  = i[1]  & ~|i[15:2];
   assign o[0]  = i[0]  & ~|i[15:1];

endmodule

//PENC64
module PENC64(i, o);
   output [63:0] o;
   input [63:0]  i;
   assign o[63] = i[63];
   assign o[62] = i[62] & ~i[63];
   assign o[61] = i[61] & ~|i[63:62];
   assign o[60] = i[60] & ~|i[63:61];
   assign o[59] = i[59] & ~|i[63:60];
   assign o[58] = i[58] & ~|i[63:59];
   assign o[57] = i[57] & ~|i[63:58];
   assign o[56] = i[56] & ~|i[63:57];
   assign o[55] = i[55] & ~|i[63:56];
   assign o[54] = i[54] & ~|i[63:55];
   assign o[53] = i[53] & ~|i[63:54];
   assign o[52] = i[52] & ~|i[63:53];
   assign o[51] = i[51] & ~|i[63:52];
   assign o[50] = i[50] & ~|i[63:51];
   assign o[49] = i[49] & ~|i[63:50];
   assign o[48] = i[48] & ~|i[63:49];
   assign o[47] = i[47] & ~|i[63:48];
   assign o[46] = i[46] & ~|i[63:47];
   assign o[45] = i[45] & ~|i[63:46];
   assign o[44] = i[44] & ~|i[63:45];
   assign o[43] = i[43] & ~|i[63:44];
   assign o[42] = i[42] & ~|i[63:43];
   assign o[41] = i[41] & ~|i[63:42];
   assign o[40] = i[40] & ~|i[63:41];
   assign o[39] = i[39] & ~|i[63:40];
   assign o[38] = i[38] & ~|i[63:39];
   assign o[37] = i[37] & ~|i[63:38];
   assign o[36] = i[36] & ~|i[63:37];
   assign o[35] = i[35] & ~|i[63:36];
   assign o[34] = i[34] & ~|i[63:35];
   assign o[33] = i[33] & ~|i[63:34];
   assign o[32] = i[32] & ~|i[63:33];
   assign o[31] = i[31] & ~|i[63:32];
   assign o[30] = i[30] & ~|i[63:31];
   assign o[29] = i[29] & ~|i[63:30];
   assign o[28] = i[28] & ~|i[63:29];
   assign o[27] = i[27] & ~|i[63:28];
   assign o[26] = i[26] & ~|i[63:27];
   assign o[25] = i[25] & ~|i[63:26];
   assign o[24] = i[24] & ~|i[63:25];
   assign o[23] = i[23] & ~|i[63:24];
   assign o[22] = i[22] & ~|i[63:23];
   assign o[21] = i[21] & ~|i[63:22];
   assign o[20] = i[20] & ~|i[63:21];
   assign o[19] = i[19] & ~|i[63:20];
   assign o[18] = i[18] & ~|i[63:19];
   assign o[17] = i[17] & ~|i[63:18];
   assign o[16] = i[16] & ~|i[63:17];
   assign o[15] = i[15] & ~|i[63:16];
   assign o[14] = i[14] & ~|i[63:15];
   assign o[13] = i[13] & ~|i[63:14];
   assign o[12] = i[12] & ~|i[63:13];
   assign o[11] = i[11] & ~|i[63:12];
   assign o[10] = i[10] & ~|i[63:11];
   assign o[9]  = i[9]  & ~|i[63:10];
   assign o[8]  = i[8]  & ~|i[63:9];
   assign o[7]  = i[7]  & ~|i[63:8];
   assign o[6]  = i[6]  & ~|i[63:7];
   assign o[5]  = i[5]  & ~|i[63:6];
   assign o[4]  = i[4]  & ~|i[63:5];
   assign o[3]  = i[3]  & ~|i[63:4];
   assign o[2]  = i[2]  & ~|i[63:3];
   assign o[1]  = i[1]  & ~|i[63:2];
   assign o[0]  = i[0]  & ~|i[63:1];
endmodule

//PENC65
module PENC65(i, o);
   output [64:0] o;
   input [64:0]  i;
   assign o[64] = i[64];
   assign o[63] = i[63] & ~i[64];
   assign o[62] = i[62] & ~|i[64:63];
   assign o[61] = i[61] & ~|i[64:62];
   assign o[60] = i[60] & ~|i[64:61];
   assign o[59] = i[59] & ~|i[64:60];
   assign o[58] = i[58] & ~|i[64:59];
   assign o[57] = i[57] & ~|i[64:58];
   assign o[56] = i[56] & ~|i[64:57];
   assign o[55] = i[55] & ~|i[64:56];
   assign o[54] = i[54] & ~|i[64:55];
   assign o[53] = i[53] & ~|i[64:54];
   assign o[52] = i[52] & ~|i[64:53];
   assign o[51] = i[51] & ~|i[64:52];
   assign o[50] = i[50] & ~|i[64:51];
   assign o[49] = i[49] & ~|i[64:50];
   assign o[48] = i[48] & ~|i[64:49];
   assign o[47] = i[47] & ~|i[64:48];
   assign o[46] = i[46] & ~|i[64:47];
   assign o[45] = i[45] & ~|i[64:46];
   assign o[44] = i[44] & ~|i[64:45];
   assign o[43] = i[43] & ~|i[64:44];
   assign o[42] = i[42] & ~|i[64:43];
   assign o[41] = i[41] & ~|i[64:42];
   assign o[40] = i[40] & ~|i[64:41];
   assign o[39] = i[39] & ~|i[64:40];
   assign o[38] = i[38] & ~|i[64:39];
   assign o[37] = i[37] & ~|i[64:38];
   assign o[36] = i[36] & ~|i[64:37];
   assign o[35] = i[35] & ~|i[64:36];
   assign o[34] = i[34] & ~|i[64:35];
   assign o[33] = i[33] & ~|i[64:34];
   assign o[32] = i[32] & ~|i[64:33];
   assign o[31] = i[31] & ~|i[64:32];
   assign o[30] = i[30] & ~|i[64:31];
   assign o[29] = i[29] & ~|i[64:30];
   assign o[28] = i[28] & ~|i[64:29];
   assign o[27] = i[27] & ~|i[64:28];
   assign o[26] = i[26] & ~|i[64:27];
   assign o[25] = i[25] & ~|i[64:26];
   assign o[24] = i[24] & ~|i[64:25];
   assign o[23] = i[23] & ~|i[64:24];
   assign o[22] = i[22] & ~|i[64:23];
   assign o[21] = i[21] & ~|i[64:22];
   assign o[20] = i[20] & ~|i[64:21];
   assign o[19] = i[19] & ~|i[64:20];
   assign o[18] = i[18] & ~|i[64:19];
   assign o[17] = i[17] & ~|i[64:18];
   assign o[16] = i[16] & ~|i[64:17];
   assign o[15] = i[15] & ~|i[64:16];
   assign o[14] = i[14] & ~|i[64:15];
   assign o[13] = i[13] & ~|i[64:14];
   assign o[12] = i[12] & ~|i[64:13];
   assign o[11] = i[11] & ~|i[64:12];
   assign o[10] = i[10] & ~|i[64:11];
   assign o[9]  = i[9]  & ~|i[64:10];
   assign o[8]  = i[8]  & ~|i[64:9];
   assign o[7]  = i[7]  & ~|i[64:8];
   assign o[6]  = i[6]  & ~|i[64:7];
   assign o[5]  = i[5]  & ~|i[64:6];
   assign o[4]  = i[4]  & ~|i[64:5];
   assign o[3]  = i[3]  & ~|i[64:4];
   assign o[2]  = i[2]  & ~|i[64:3];
   assign o[1]  = i[1]  & ~|i[64:2];
   assign o[0]  = i[0]  & ~|i[64:1];
endmodule


// -------------------  8-bit One-Hot to 3-bit Encode --------------
module OHtoENC8(i, o);
   output [2:0] o;
   input [7:0] i;
   
   assign o[2] = i[7]  | i[6]  | i[5] | i[4];
   assign o[1] = i[7]  | i[6]  | i[3] | i[2];
   assign o[0] = i[7]  | i[5]  | i[3] | i[1];

endmodule // OHtoENC8


// -------------------  16-bit One-Hot to 4-bit Encode --------------
module OHtoENC16(i, o);
   // surefire lint_off UDDIDN
   output [3:0] o;
   input [15:0] i;
   
   assign o[3] = i[15] | i[14] | i[13] | i[12] | i[11] | i[10] | i[9] | i[8];
   assign o[2] = i[15] | i[14] | i[13] | i[12] | i[7]  | i[6]  | i[5] | i[4];
   assign o[1] = i[15] | i[14] | i[11] | i[10] | i[7]  | i[6]  | i[3] | i[2];
   assign o[0] = i[15] | i[13] | i[11] | i[9]  | i[7]  | i[5]  | i[3] | i[1];
   // surefire lint_on UDDIDN
   
endmodule // OHtoENC16

// -------------------  14 to 1 One-Hot Mux --------------
module OHMUX14(mo, i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, sel);
   parameter width = 4;

   output [width-1:0] mo;
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13;
   input [13:0]       sel;

   assign mo = ((i0  & {width{sel[0]}}) |
		(i1  & {width{sel[1]}}) |
		(i2  & {width{sel[2]}}) |
		(i3  & {width{sel[3]}}) |
		(i4  & {width{sel[4]}}) |
		(i5  & {width{sel[5]}}) |
		(i6  & {width{sel[6]}}) |
		(i7  & {width{sel[7]}}) |
		(i8  & {width{sel[8]}}) |
		(i9  & {width{sel[9]}}) |
		(i10 & {width{sel[10]}}) |
		(i11 & {width{sel[11]}}) |
		(i12 & {width{sel[12]}}) |
		(i13 & {width{sel[13]}})) ;
   
endmodule // OHMUX14

// -------------------  16 to 1 One-Hot Mux --------------
module OHMUX16(mo, i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, sel);
   parameter width = 4;

   output [width-1:0] mo;
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15;
   input [15:0]       sel;

   assign mo = ((i0  & {width{sel[0]}}) |
		(i1  & {width{sel[1]}}) |
		(i2  & {width{sel[2]}}) |
		(i3  & {width{sel[3]}}) |
		(i4  & {width{sel[4]}}) |
		(i5  & {width{sel[5]}}) |
		(i6  & {width{sel[6]}}) |
		(i7  & {width{sel[7]}}) |
		(i8  & {width{sel[8]}}) |
		(i9  & {width{sel[9]}}) |
		(i10 & {width{sel[10]}}) |
		(i11 & {width{sel[11]}}) |
		(i12 & {width{sel[12]}}) |
		(i13 & {width{sel[13]}}) |
		(i14 & {width{sel[14]}}) |
		(i15 & {width{sel[15]}}));
   
endmodule // OHMUX16

module OHMUX64(mo,
               i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
               i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
               i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
               i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
               i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
               i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
               i60, i61, i62, i63, sel);
   parameter width = 4;

   output [width-1:0] mo;
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
                      i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
                      i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
                      i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
                      i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
                      i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
                      i60, i61, i62, i63;
   input [63:0]       sel;

   assign mo = (
      (i0  & {width{sel[0]}}) |
      (i1  & {width{sel[1]}}) |
      (i2  & {width{sel[2]}}) |
      (i3  & {width{sel[3]}}) |
      (i4  & {width{sel[4]}}) |
      (i5  & {width{sel[5]}}) |
      (i6  & {width{sel[6]}}) |
      (i7  & {width{sel[7]}}) |
      (i8  & {width{sel[8]}}) |
      (i9  & {width{sel[9]}}) |
      (i10 & {width{sel[10]}}) |
      (i11 & {width{sel[11]}}) |
      (i12 & {width{sel[12]}}) |
      (i13 & {width{sel[13]}}) |
      (i14 & {width{sel[14]}}) |
      (i15 & {width{sel[15]}}) |
      (i16 & {width{sel[16]}}) |
      (i17 & {width{sel[17]}}) |
      (i18 & {width{sel[18]}}) |
      (i19 & {width{sel[19]}}) |
      (i20 & {width{sel[20]}}) |
      (i21 & {width{sel[21]}}) |
      (i22 & {width{sel[22]}}) |
      (i23 & {width{sel[23]}}) |
      (i24 & {width{sel[24]}}) |
      (i25 & {width{sel[25]}}) |
      (i26 & {width{sel[26]}}) |
      (i27 & {width{sel[27]}}) |
      (i28 & {width{sel[28]}}) |
      (i29 & {width{sel[29]}}) |
      (i30 & {width{sel[30]}}) |
      (i31 & {width{sel[31]}}) |
      (i32 & {width{sel[32]}}) |
      (i33 & {width{sel[33]}}) |
      (i34 & {width{sel[34]}}) |
      (i35 & {width{sel[35]}}) |
      (i36 & {width{sel[36]}}) |
      (i37 & {width{sel[37]}}) |
      (i38 & {width{sel[38]}}) |
      (i39 & {width{sel[39]}}) |
      (i40 & {width{sel[40]}}) |
      (i41 & {width{sel[41]}}) |
      (i42 & {width{sel[42]}}) |
      (i43 & {width{sel[43]}}) |
      (i44 & {width{sel[44]}}) |
      (i45 & {width{sel[45]}}) |
      (i46 & {width{sel[46]}}) |
      (i47 & {width{sel[47]}}) |
      (i48 & {width{sel[48]}}) |
      (i49 & {width{sel[49]}}) |
      (i50 & {width{sel[50]}}) |
      (i51 & {width{sel[51]}}) |
      (i52 & {width{sel[52]}}) |
      (i53 & {width{sel[53]}}) |
      (i54 & {width{sel[54]}}) |
      (i55 & {width{sel[55]}}) |
      (i56 & {width{sel[56]}}) |
      (i57 & {width{sel[57]}}) |
      (i58 & {width{sel[58]}}) |
      (i59 & {width{sel[59]}}) |
      (i60 & {width{sel[60]}}) |
      (i61 & {width{sel[61]}}) |
      (i62 & {width{sel[62]}}) |
      (i63 & {width{sel[63]}}));
endmodule // OHMUX64

module OHMUX65(mo,
               i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
               i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
               i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
               i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
               i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
               i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
               i60, i61, i62, i63,i64, sel);
   parameter width = 4;

   output [width-1:0] mo;
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
                      i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
                      i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
                      i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
                      i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
                      i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
                      i60, i61, i62, i63, i64;
   input [64:0]       sel;

   assign mo = (
      (i0  & {width{sel[0]}}) |
      (i1  & {width{sel[1]}}) |
      (i2  & {width{sel[2]}}) |
      (i3  & {width{sel[3]}}) |
      (i4  & {width{sel[4]}}) |
      (i5  & {width{sel[5]}}) |
      (i6  & {width{sel[6]}}) |
      (i7  & {width{sel[7]}}) |
      (i8  & {width{sel[8]}}) |
      (i9  & {width{sel[9]}}) |
      (i10 & {width{sel[10]}}) |
      (i11 & {width{sel[11]}}) |
      (i12 & {width{sel[12]}}) |
      (i13 & {width{sel[13]}}) |
      (i14 & {width{sel[14]}}) |
      (i15 & {width{sel[15]}}) |
      (i16 & {width{sel[16]}}) |
      (i17 & {width{sel[17]}}) |
      (i18 & {width{sel[18]}}) |
      (i19 & {width{sel[19]}}) |
      (i20 & {width{sel[20]}}) |
      (i21 & {width{sel[21]}}) |
      (i22 & {width{sel[22]}}) |
      (i23 & {width{sel[23]}}) |
      (i24 & {width{sel[24]}}) |
      (i25 & {width{sel[25]}}) |
      (i26 & {width{sel[26]}}) |
      (i27 & {width{sel[27]}}) |
      (i28 & {width{sel[28]}}) |
      (i29 & {width{sel[29]}}) |
      (i30 & {width{sel[30]}}) |
      (i31 & {width{sel[31]}}) |
      (i32 & {width{sel[32]}}) |
      (i33 & {width{sel[33]}}) |
      (i34 & {width{sel[34]}}) |
      (i35 & {width{sel[35]}}) |
      (i36 & {width{sel[36]}}) |
      (i37 & {width{sel[37]}}) |
      (i38 & {width{sel[38]}}) |
      (i39 & {width{sel[39]}}) |
      (i40 & {width{sel[40]}}) |
      (i41 & {width{sel[41]}}) |
      (i42 & {width{sel[42]}}) |
      (i43 & {width{sel[43]}}) |
      (i44 & {width{sel[44]}}) |
      (i45 & {width{sel[45]}}) |
      (i46 & {width{sel[46]}}) |
      (i47 & {width{sel[47]}}) |
      (i48 & {width{sel[48]}}) |
      (i49 & {width{sel[49]}}) |
      (i50 & {width{sel[50]}}) |
      (i51 & {width{sel[51]}}) |
      (i52 & {width{sel[52]}}) |
      (i53 & {width{sel[53]}}) |
      (i54 & {width{sel[54]}}) |
      (i55 & {width{sel[55]}}) |
      (i56 & {width{sel[56]}}) |
      (i57 & {width{sel[57]}}) |
      (i58 & {width{sel[58]}}) |
      (i59 & {width{sel[59]}}) |
      (i60 & {width{sel[60]}}) |
      (i61 & {width{sel[61]}}) |
      (i62 & {width{sel[62]}}) |
      (i63 & {width{sel[63]}}) |
      (i64 & {width{sel[64]}}));
endmodule // OHMUX65

// -------------------  67-bit MUX 7 bit Select ---------------
module MUX67(mo,
               i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
               i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
               i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
               i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
               i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
               i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
               i60, i61, i62, i63, i64, i65, i66, sel);
   parameter width = 4;

   output [width-1:0] mo;
//surefire lint_off UDDICU
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
                      i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
                      i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
                      i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
                      i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
                      i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
                      i60, i61, i62, i63, i64, i65, i66;
//surefire lint_on UDDICU
   input [6:0]       sel;

   reg [width-1:0] mo;

always @ (/*AS*/i0 or i1 or i10 or i11 or i12 or i13 or i14 or i15
	  or i16 or i17 or i18 or i19 or i2 or i20 or i21 or i22
	  or i23 or i24 or i25 or i26 or i27 or i28 or i29 or i3
	  or i30 or i31 or i32 or i33 or i34 or i35 or i36 or i37
	  or i38 or i39 or i4 or i40 or i41 or i42 or i43 or i44
	  or i45 or i46 or i47 or i48 or i49 or i5 or i50 or i51
	  or i52 or i53 or i54 or i55 or i56 or i57 or i58 or i59
	  or i6 or i60 or i61 or i62 or i63 or i64 or i65 or i66 or i7
	  or i8 or i9 or sel)
 begin
   mo = {width{1'b0}};  
   // surefire lint_off ASWEMS
   case (sel) //synopsys full_case parallel_case
    7'h42   :  mo = i66;
    7'h41   :  mo = i65;
    7'h40   :  mo = i64;
    7'h3f   :  mo = i63;
    7'h3e   :  mo = i62;
    7'h3d   :  mo = i61;
    7'h3c   :  mo = i60;
    7'h3b   :  mo = i59;
    7'h3a   :  mo = i58;
    7'h39   :  mo = i57;
    7'h38   :  mo = i56;
    7'h37   :  mo = i55;
    7'h36   :  mo = i54;
    7'h35   :  mo = i53;
    7'h34   :  mo = i52;
    7'h33   :  mo = i51;
    7'h32   :  mo = i50;
    7'h31   :  mo = i49;
    7'h30   :  mo = i48;
    7'h2f   :  mo = i47;
    7'h2e   :  mo = i46;
    7'h2d   :  mo = i45;
    7'h2c   :  mo = i44;
    7'h2b   :  mo = i43;
    7'h2a   :  mo = i42;
    7'h29   :  mo = i41;
    7'h28   :  mo = i40;
    7'h27   :  mo = i39;
    7'h26   :  mo = i38;
    7'h25   :  mo = i37;
    7'h24   :  mo = i36;
    7'h23   :  mo = i35;
    7'h22   :  mo = i34;
    7'h21   :  mo = i33;
    7'h20   :  mo = i32;
    7'h1f   :  mo = i31;
    7'h1e   :  mo = i30;
    7'h1d   :  mo = i29;
    7'h1c   :  mo = i28;
    7'h1b   :  mo = i27;
    7'h1a   :  mo = i26;
    7'h19   :  mo = i25;
    7'h18   :  mo = i24;
    7'h17   :  mo = i23;
    7'h16   :  mo = i22;
    7'h15   :  mo = i21;
    7'h14   :  mo = i20;
    7'h13   :  mo = i19;
    7'h12   :  mo = i18;
    7'h11   :  mo = i17;
    7'h10   :  mo = i16;
    7'h0f   :  mo = i15;
    7'h0e   :  mo = i14;
    7'h0d   :  mo = i13;
    7'h0c   :  mo = i12;
    7'h0b   :  mo = i11;
    7'h0a   :  mo = i10;
    7'h09   :  mo = i9;
    7'h08   :  mo = i8;
    7'h07   :  mo = i7;
    7'h06   :  mo = i6;
    7'h05   :  mo = i5;
    7'h04   :  mo = i4;
    7'h03   :  mo = i3;
    7'h02   :  mo = i2;
    7'h01   :  mo = i1;
    7'h00   :  mo = i0;
    default :  mo = {width{1'b0}};  
   endcase
   // surefire lint_on ASWEMS
 end //always
endmodule // MUX67

// -------------------  65-bit MUX 7 bit Select ---------------
module MUX65(mo,
               i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
               i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
               i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
               i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
               i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
               i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
               i60, i61, i62, i63,i64, sel);
   parameter width = 4;

   output [width-1:0] mo;
   input [width-1:0]  i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
                      i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
                      i20, i21, i22, i23, i24, i25, i26, i27, i28, i29,
                      i30, i31, i32, i33, i34, i35, i36, i37, i38, i39,
                      i40, i41, i42, i43, i44, i45, i46, i47, i48, i49,
                      i50, i51, i52, i53, i54, i55, i56, i57, i58, i59,
                      i60, i61, i62, i63, i64;
   input [6:0]       sel;

   reg [width-1:0] mo;

always @ (/*AS*/i0 or i1 or i10 or i11 or i12 or i13 or i14 or i15
	  or i16 or i17 or i18 or i19 or i2 or i20 or i21 or i22
	  or i23 or i24 or i25 or i26 or i27 or i28 or i29 or i3
	  or i30 or i31 or i32 or i33 or i34 or i35 or i36 or i37
	  or i38 or i39 or i4 or i40 or i41 or i42 or i43 or i44
	  or i45 or i46 or i47 or i48 or i49 or i5 or i50 or i51
	  or i52 or i53 or i54 or i55 or i56 or i57 or i58 or i59
	  or i6 or i60 or i61 or i62 or i63 or i64 or i7 or i8 or i9
	  or sel)
 begin
               mo = {width{1'b0}};  
   // surefire lint_off ASWEMS
   case (sel) //synopsys full_case parallel_case
    7'h40   :  mo = i64;
    7'h3f   :  mo = i63;
    7'h3e   :  mo = i62;
    7'h3d   :  mo = i61;
    7'h3c   :  mo = i60;
    7'h3b   :  mo = i59;
    7'h3a   :  mo = i58;
    7'h39   :  mo = i57;
    7'h38   :  mo = i56;
    7'h37   :  mo = i55;
    7'h36   :  mo = i54;
    7'h35   :  mo = i53;
    7'h34   :  mo = i52;
    7'h33   :  mo = i51;
    7'h32   :  mo = i50;
    7'h31   :  mo = i49;
    7'h30   :  mo = i48;
    7'h2f   :  mo = i47;
    7'h2e   :  mo = i46;
    7'h2d   :  mo = i45;
    7'h2c   :  mo = i44;
    7'h2b   :  mo = i43;
    7'h2a   :  mo = i42;
    7'h29   :  mo = i41;
    7'h28   :  mo = i40;
    7'h27   :  mo = i39;
    7'h26   :  mo = i38;
    7'h25   :  mo = i37;
    7'h24   :  mo = i36;
    7'h23   :  mo = i35;
    7'h22   :  mo = i34;
    7'h21   :  mo = i33;
    7'h20   :  mo = i32;
    7'h1f   :  mo = i31;
    7'h1e   :  mo = i30;
    7'h1d   :  mo = i29;
    7'h1c   :  mo = i28;
    7'h1b   :  mo = i27;
    7'h1a   :  mo = i26;
    7'h19   :  mo = i25;
    7'h18   :  mo = i24;
    7'h17   :  mo = i23;
    7'h16   :  mo = i22;
    7'h15   :  mo = i21;
    7'h14   :  mo = i20;
    7'h13   :  mo = i19;
    7'h12   :  mo = i18;
    7'h11   :  mo = i17;
    7'h10   :  mo = i16;
    7'h0f   :  mo = i15;
    7'h0e   :  mo = i14;
    7'h0d   :  mo = i13;
    7'h0c   :  mo = i12;
    7'h0b   :  mo = i11;
    7'h0a   :  mo = i10;
    7'h09   :  mo = i9;
    7'h08   :  mo = i8;
    7'h07   :  mo = i7;
    7'h06   :  mo = i6;
    7'h05   :  mo = i5;
    7'h04   :  mo = i4;
    7'h03   :  mo = i3;
    7'h02   :  mo = i2;
    7'h01   :  mo = i1;
    7'h00   :  mo = i0;
    default :  mo = {width{1'b0}};  
   endcase
   // surefire lint_on ASWEMS
 end //always
endmodule // MUX65

// -------------------  64-bit Wide EDFFR (64-bit Enable) --------------
module EDFFR64 (q, d, en, clk, reset);
   input                                clk;
   input                                reset;
   input [63:0]                         d;
   input [63:0]                         en;
   
   output [63:0]                        q;
  EDFFR16 U_3 (.q(q[63:48]), .d(d[63:48]), .en(en[63:48]), .clk(clk), .reset(reset));
  EDFFR16 U_2 (.q(q[47:32]), .d(d[47:32]), .en(en[47:32]), .clk(clk), .reset(reset));
  EDFFR16 U_1 (.q(q[31:16]), .d(d[31:16]), .en(en[31:16]), .clk(clk), .reset(reset));
  EDFFR16 U_0 (.q(q[15:0]), .d(d[15:0]), .en(en[15:0]), .clk(clk), .reset(reset));
endmodule // EDFFR64


// -------------------  16-bit Wide EDFFR (16-bit Enable) --------------
module EDFFR16 (q, d, en, clk, reset);

   input                                clk;
   input                                reset;
   input [15:0]                         d;
   input [15:0]                         en;
   
   output [15:0]                        q;
   
   reg [15:0]                           q;
   
   always @(posedge clk) begin
      if (~reset) begin
         q <= 16'h0;
      end
      else begin
         q[0]  <= (en[0]  ? d[0]  : q[0]);
         q[1]  <= (en[1]  ? d[1]  : q[1]);
         q[2]  <= (en[2]  ? d[2]  : q[2]);
         q[3]  <= (en[3]  ? d[3]  : q[3]);
         q[4]  <= (en[4]  ? d[4]  : q[4]);
         q[5]  <= (en[5]  ? d[5]  : q[5]);
         q[6]  <= (en[6]  ? d[6]  : q[6]);
         q[7]  <= (en[7]  ? d[7]  : q[7]);
         q[8]  <= (en[8]  ? d[8]  : q[8]);
         q[9]  <= (en[9]  ? d[9]  : q[9]);
         q[10] <= (en[10] ? d[10] : q[10]);
         q[11] <= (en[11] ? d[11] : q[11]);
         q[12] <= (en[12] ? d[12] : q[12]);
         q[13] <= (en[13] ? d[13] : q[13]);
         q[14] <= (en[14] ? d[14] : q[14]);
         q[15] <= (en[15] ? d[15] : q[15]);
      end
   end

endmodule // EDFFR16
// -------------------  8-bit Wide EDFFR (16-bit Enable) --------------
module EDFFR8 (q, d, en, clk, reset);

   input                                clk;
   input                                reset;
   input [7:0]                         d;
   input [7:0]                         en;
   
   output [7:0]                        q;
   
   reg [7:0]                           q;
   
   always @(posedge clk) begin
      if (~reset) begin
         q <= 8'h0;
      end
      else begin
         q[0]  <= (en[0]  ? d[0]  : q[0]);
         q[1]  <= (en[1]  ? d[1]  : q[1]);
         q[2]  <= (en[2]  ? d[2]  : q[2]);
         q[3]  <= (en[3]  ? d[3]  : q[3]);
         q[4]  <= (en[4]  ? d[4]  : q[4]);
         q[5]  <= (en[5]  ? d[5]  : q[5]);
         q[6]  <= (en[6]  ? d[6]  : q[6]);
         q[7]  <= (en[7]  ? d[7]  : q[7]);
      end
   end

endmodule // EDFFR8



// ------------------- Single Bit 256 EDFFR's having 256 Enables --------------
module EDFFR256 (q, d, en, clk, reset);

   input                                clk;
   input                                reset;
   input [255:0]                        d;
   input [255:0]                        en;
   
   output [255:0]                       q;
   
   wire [15:0] d15,d14,d13,d12,d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0;
   wire [15:0] e15,e14,e13,e12,e11,e10,e9,e8,e7,e6,e5,e4,e3,e2,e1,e0;
   wire [15:0] q15,q14,q13,q12,q11,q10,q9,q8,q7,q6,q5,q4,q3,q2,q1,q0;

   assign {d15,d14,d13,d12,d11,d10,d9,d8,d7,d6,d5,d4,d3,d2,d1,d0} = d;
   assign {e15,e14,e13,e12,e11,e10,e9,e8,e7,e6,e5,e4,e3,e2,e1,e0} = en;

   EDFFR16 U0_edffr16  (.q(q0),  .d(d0),  .en(e0),  .clk(clk), .reset(reset));
   EDFFR16 U1_edffr16  (.q(q1),  .d(d1),  .en(e1),  .clk(clk), .reset(reset));
   EDFFR16 U2_edffr16  (.q(q2),  .d(d2),  .en(e2),  .clk(clk), .reset(reset));
   EDFFR16 U3_edffr16  (.q(q3),  .d(d3),  .en(e3),  .clk(clk), .reset(reset));
   EDFFR16 U4_edffr16  (.q(q4),  .d(d4),  .en(e4),  .clk(clk), .reset(reset));
   EDFFR16 U5_edffr16  (.q(q5),  .d(d5),  .en(e5),  .clk(clk), .reset(reset));
   EDFFR16 U6_edffr16  (.q(q6),  .d(d6),  .en(e6),  .clk(clk), .reset(reset));
   EDFFR16 U7_edffr16  (.q(q7),  .d(d7),  .en(e7),  .clk(clk), .reset(reset));
   EDFFR16 U8_edffr16  (.q(q8),  .d(d8),  .en(e8),  .clk(clk), .reset(reset));
   EDFFR16 U9_edffr16  (.q(q9),  .d(d9),  .en(e9),  .clk(clk), .reset(reset));
   EDFFR16 U10_edffr16 (.q(q10), .d(d10), .en(e10), .clk(clk), .reset(reset));
   EDFFR16 U11_edffr16 (.q(q11), .d(d11), .en(e11), .clk(clk), .reset(reset));
   EDFFR16 U12_edffr16 (.q(q12), .d(d12), .en(e12), .clk(clk), .reset(reset));
   EDFFR16 U13_edffr16 (.q(q13), .d(d13), .en(e13), .clk(clk), .reset(reset));
   EDFFR16 U14_edffr16 (.q(q14), .d(d14), .en(e14), .clk(clk), .reset(reset));
   EDFFR16 U15_edffr16 (.q(q15), .d(d15), .en(e15), .clk(clk), .reset(reset));
   
   assign q = {q15,q14,q13,q12,q11,q10,q9,q8,q7,q6,q5,q4,q3,q2,q1,q0};

endmodule // EDFFR256


// ------------------- 256 to 8 Priority Encoder --------------
module PENC256x8 (o, v, i);

   // NOTE: Synthesis result shows this priority encoder to have 16 levels
   //       of logic, and 2.4ns delay Flop-to-flop (slow corner)
   
   
   input [255:0]                        i;            // Input Vector
   output [7:0]                         o;            // Encoded Output
   output                               v;            // Valid Bit

   wire [15:0] i15,i14,i13,i12,i11,i10,i9,i8,i7,i6,i5,i4,i3,i2,i1,i0;
   wire [15:0] p15,p14,p13,p12,p11,p10,p9,p8,p7,p6,p5,p4,p3,p2,p1,p0;
   wire [3:0]  e15,e14,e13,e12,e11,e10,e9,e8,e7,e6,e5,e4,e3,e2,e1,e0;
   
   wire [15:0] sel, psel;
   
   // Split up the 256-bit vector into groups of 16
   assign {i15,i14,i13,i12,i11,i10,i9,i8,i7,i6,i5,i4,i3,i2,i1,i0} = i;

   // Generate the selector
   assign sel = {|i15,|i14,|i13,|i12,|i11,|i10,|i9,|i8,|i7,|i6,|i5,|i4,|i3,|i2,|i1,|i0};

   assign v = |sel;
   
   // Prioritize the Selector
   PENC16   U_pencmsel    (.o(psel), .i(sel));
   
   // Prioritize each of 16 segment
   PENC16   U0_penc16     (.o(p0),  .i(i0));
   PENC16   U1_penc16     (.o(p1),  .i(i1));
   PENC16   U2_penc16     (.o(p2),  .i(i2));
   PENC16   U3_penc16     (.o(p3),  .i(i3));
   PENC16   U4_penc16     (.o(p4),  .i(i4));
   PENC16   U5_penc16     (.o(p5),  .i(i5));
   PENC16   U6_penc16     (.o(p6),  .i(i6));
   PENC16   U7_penc16     (.o(p7),  .i(i7));
   PENC16   U8_penc16     (.o(p8),  .i(i8));
   PENC16   U9_penc16     (.o(p9),  .i(i9));
   PENC16   U10_penc16    (.o(p10), .i(i10));
   PENC16   U11_penc16    (.o(p11), .i(i11));
   PENC16   U12_penc16    (.o(p12), .i(i12));
   PENC16   U13_penc16    (.o(p13), .i(i13));
   PENC16   U14_penc16    (.o(p14), .i(i14));
   PENC16   U15_penc16    (.o(p15), .i(i15));

   // Encode the winning bit in each of the 16 segments
   OHtoENC16 U0_OHtoENC16   (.o(e0),  .i(p0));
   OHtoENC16 U1_OHtoENC16   (.o(e1),  .i(p1));
   OHtoENC16 U2_OHtoENC16   (.o(e2),  .i(p2));
   OHtoENC16 U3_OHtoENC16   (.o(e3),  .i(p3));
   OHtoENC16 U4_OHtoENC16   (.o(e4),  .i(p4));
   OHtoENC16 U5_OHtoENC16   (.o(e5),  .i(p5));
   OHtoENC16 U6_OHtoENC16   (.o(e6),  .i(p6));
   OHtoENC16 U7_OHtoENC16   (.o(e7),  .i(p7));
   OHtoENC16 U8_OHtoENC16   (.o(e8),  .i(p8));
   OHtoENC16 U9_OHtoENC16   (.o(e9),  .i(p9));
   OHtoENC16 U10_OHtoENC16  (.o(e10), .i(p10));
   OHtoENC16 U11_OHtoENC16  (.o(e11), .i(p11));
   OHtoENC16 U12_OHtoENC16  (.o(e12), .i(p12));
   OHtoENC16 U13_OHtoENC16  (.o(e13), .i(p13));
   OHtoENC16 U14_OHtoENC16  (.o(e14), .i(p14));
   OHtoENC16 U15_OHtoENC16  (.o(e15), .i(p15));

   // Finally, use a 16 to 1 One-Hot Mux to select the winner
   OHMUX16 #(8) U_muxout
     (.mo (o),
      .i0 ({4'h0, e0}),   .i1 ({4'h1, e1}),   .i2 ({4'h2, e2}),   .i3 ({4'h3, e3}),
      .i4 ({4'h4, e4}),   .i5 ({4'h5, e5}),   .i6 ({4'h6, e6}),   .i7 ({4'h7, e7}),
      .i8 ({4'h8, e8}),   .i9 ({4'h9, e9}),   .i10({4'ha, e10}),  .i11({4'hb, e11}),
      .i12({4'hc, e12}),  .i13({4'hd, e13}),  .i14({4'he, e14}),  .i15({4'hf, e15}),
      .sel(psel));

endmodule // PENC256x8

module OHtoENC64(i, o);
   output [5:0] o;
   input [63:0] i;
   reg [5:0] o;
   always @(i) begin
      o = 6'h00;
    case (1'b1)
      i[63] : o = 6'h3f;
      i[62] : o = 6'h3e;
      i[61] : o = 6'h3d;
      i[60] : o = 6'h3c;
      i[59] : o = 6'h3b;
      i[58] : o = 6'h3a;
      i[57] : o = 6'h39;
      i[56] : o = 6'h38;
      i[55] : o = 6'h37;
      i[54] : o = 6'h36;
      i[53] : o = 6'h35;
      i[52] : o = 6'h34;
      i[51] : o = 6'h33;
      i[50] : o = 6'h32;
      i[49] : o = 6'h31;
      i[48] : o = 6'h30;
      i[47] : o = 6'h2f;
      i[46] : o = 6'h2e;
      i[45] : o = 6'h2d;
      i[44] : o = 6'h2c;
      i[43] : o = 6'h2b;
      i[42] : o = 6'h2a;
      i[41] : o = 6'h29;
      i[40] : o = 6'h28;
      i[39] : o = 6'h27;
      i[38] : o = 6'h26;
      i[37] : o = 6'h25;
      i[36] : o = 6'h24;
      i[35] : o = 6'h23;
      i[34] : o = 6'h22;
      i[33] : o = 6'h21;
      i[32] : o = 6'h20;
      i[31] : o = 6'h1f;
      i[30] : o = 6'h1e;
      i[29] : o = 6'h1d;
      i[28] : o = 6'h1c;
      i[27] : o = 6'h1b;
      i[26] : o = 6'h1a;
      i[25] : o = 6'h19;
      i[24] : o = 6'h18;
      i[23] : o = 6'h17;
      i[22] : o = 6'h16;
      i[21] : o = 6'h15;
      i[20] : o = 6'h14;
      i[19] : o = 6'h13;
      i[18] : o = 6'h12;
      i[17] : o = 6'h11;
      i[16] : o = 6'h10;
      i[15] : o = 6'h0f;
      i[14] : o = 6'h0e;
      i[13] : o = 6'h0d;
      i[12] : o = 6'h0c;
      i[11] : o = 6'h0b;
      i[10] : o = 6'h0a;
      i[9] : o = 6'h09;
      i[8] : o = 6'h08;
      i[7] : o = 6'h07;
      i[6] : o = 6'h06;
      i[5] : o = 6'h05;
      i[4] : o = 6'h04;
      i[3] : o = 6'h03;
      i[2] : o = 6'h02;
      i[1] : o = 6'h01;
      i[0] : o = 6'h00;
    endcase //(1'b1)
   end //always 
endmodule // OHtoENC64



module OHtoENC65(i, o);
   output [6:0] o;
   input [64:0] i;
   reg [6:0] o;
   always @(i) begin
      o = 7'h00;
    case (1'b1)
      i[64]   : o = 7'h40;
      i[63]   : o = 7'h3f;
      i[62]   : o = 7'h3e;
      i[61]   : o = 7'h3d;
      i[60]   : o = 7'h3c;
      i[59]   : o = 7'h3b;
      i[58]   : o = 7'h3a;
      i[57]   : o = 7'h39;
      i[56]   : o = 7'h38;
      i[55]   : o = 7'h37;
      i[54]   : o = 7'h36;
      i[53]   : o = 7'h35;
      i[52]   : o = 7'h34;
      i[51]   : o = 7'h33;
      i[50]   : o = 7'h32;
      i[49]   : o = 7'h31;
      i[48]   : o = 7'h30;
      i[47]   : o = 7'h2f;
      i[46]   : o = 7'h2e;
      i[45]   : o = 7'h2d;
      i[44]   : o = 7'h2c;
      i[43]   : o = 7'h2b;
      i[42]   : o = 7'h2a;
      i[41]   : o = 7'h29;
      i[40]   : o = 7'h28;
      i[39]   : o = 7'h27;
      i[38]   : o = 7'h26;
      i[37]   : o = 7'h25;
      i[36]   : o = 7'h24;
      i[35]   : o = 7'h23;
      i[34]   : o = 7'h22;
      i[33]   : o = 7'h21;
      i[32]   : o = 7'h20;
      i[31]   : o = 7'h1f;
      i[30]   : o = 7'h1e;
      i[29]   : o = 7'h1d;
      i[28]   : o = 7'h1c;
      i[27]   : o = 7'h1b;
      i[26]   : o = 7'h1a;
      i[25]   : o = 7'h19;
      i[24]   : o = 7'h18;
      i[23]   : o = 7'h17;
      i[22]   : o = 7'h16;
      i[21]   : o = 7'h15;
      i[20]   : o = 7'h14;
      i[19]   : o = 7'h13;
      i[18]   : o = 7'h12;
      i[17]   : o = 7'h11;
      i[16]   : o = 7'h10;
      i[15]   : o = 7'h0f;
      i[14]   : o = 7'h0e;
      i[13]   : o = 7'h0d;
      i[12]   : o = 7'h0c;
      i[11]   : o = 7'h0b;
      i[10]   : o = 7'h0a;
      i[9]    : o = 7'h09;
      i[8]    : o = 7'h08;
      i[7]    : o = 7'h07;
      i[6]    : o = 7'h06;
      i[5]    : o = 7'h05;
      i[4]    : o = 7'h04;
      i[3]    : o = 7'h03;
      i[2]    : o = 7'h02;
      i[1]    : o = 7'h01;
      i[0]    : o = 7'h00;
      default : o = {7{1'b0}};
    endcase //(1'b1)
   end //always 
endmodule // OHtoENC6

// ------------------ 256-entry Single Bit Vector with Priority Encoder --------------
module RFPENC256x8 (PENC, VLD, CLK, RESET, WRADDR, WRDATA, WREN);

   input                               CLK;    // Tte Unit Clock
   input                               RESET;  // Global Reset
   
   input [7:0] 				WRADDR; // Write Address
   input                                WRDATA; // Write Data
   input                                WREN;   // Write Enable (Active Hi)

   output [7:0] 			PENC;   // Priority Encoded
   output                               VLD;    // Valid
   
   wire [255:0] 			WRADDRDEC, WRENDEC, BITVEC;

   // Decode the Write Address
   DEC8x256 U_dec256 (.o(WRADDRDEC), .i(WRADDR));
   assign WRENDEC = (WRADDRDEC & {256{WREN}});
   
   // Generate a 256-bit DFF (single bit)
   EDFFR256 U_edffr256 (.q(BITVEC),
                        .clk(CLK),
                        .reset(RESET),
                        .en(WRENDEC),
                        .d({256{WRDATA}}));
   
   PENC256x8 U_penc256 (.v(VLD), .o(PENC), .i(BITVEC));
   
endmodule // RFPENC256x8


// ---------- 16-entry Parameterizable Width Register File ----------
module RF16x1 (RDDATA, CLK, RESET, RDADDR, WRADDR, WRDATA, WREN);
   
   parameter                            REGFILE_WIDTH = 8;

   input                                CLK;    // Tte Unit Clock
   input                                RESET;  // Global Reset
   input [3:0] 				RDADDR; // Read Address
   input [3:0] 				WRADDR; // Write Address
   input [REGFILE_WIDTH-1:0]            WRDATA; // Write Data
   input                                WREN;   // Write Enable

   output [REGFILE_WIDTH-1:0]           RDDATA; // Read Data

   wire [REGFILE_WIDTH-1:0]             RD0,  RD1,  RD2,  RD3,  RD4,  RD5,  RD6,  RD7,
                                        RD8,  RD9,  RD10, RD11, RD12, RD13, RD14, RD15;

   wire [15:0] 				WRADDRDEC, WRENDEC; // RDADDRDEC;
   
   // We'll decode the stream ID to use as write enable.
   DEC4x16 U_wrdec(.o(WRADDRDEC), .i(WRADDR));
   assign WRENDEC = (WRADDRDEC & {16{WREN}});     // Counter Write Enable

   EDFFR #(REGFILE_WIDTH) U0_dff  (.q(RD0), .d(WRDATA),.en(WRENDEC[0]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U1_dff  (.q(RD1), .d(WRDATA),.en(WRENDEC[1]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U2_dff  (.q(RD2), .d(WRDATA),.en(WRENDEC[2]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U3_dff  (.q(RD3), .d(WRDATA),.en(WRENDEC[3]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U4_dff  (.q(RD4), .d(WRDATA),.en(WRENDEC[4]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U5_dff  (.q(RD5), .d(WRDATA),.en(WRENDEC[5]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U6_dff  (.q(RD6), .d(WRDATA),.en(WRENDEC[6]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U7_dff  (.q(RD7), .d(WRDATA),.en(WRENDEC[7]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U8_dff  (.q(RD8), .d(WRDATA),.en(WRENDEC[8]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U9_dff  (.q(RD9), .d(WRDATA),.en(WRENDEC[9]), .clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U10_dff (.q(RD10),.d(WRDATA),.en(WRENDEC[10]),.clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U11_dff (.q(RD11),.d(WRDATA),.en(WRENDEC[11]),.clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U12_dff (.q(RD12),.d(WRDATA),.en(WRENDEC[12]),.clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U13_dff (.q(RD13),.d(WRDATA),.en(WRENDEC[13]),.clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U14_dff (.q(RD14),.d(WRDATA),.en(WRENDEC[14]),.clk(CLK),.reset(RESET));
   EDFFR #(REGFILE_WIDTH) U15_dff (.q(RD15),.d(WRDATA),.en(WRENDEC[15]),.clk(CLK),.reset(RESET));

/* -----\/----- EXCLUDED -----\/-----
   DEC4x16 U_rddec (.o(RDADDRDEC), .i(RDADDR));
     
   OHMUX16 #(REGFILE_WIDTH) U_muxout
     (.mo (RDDATA),
      .i0 (RD0),  .i1 (RD1),  .i2 (RD2),  .i3 (RD3), 
      .i4 (RD4),  .i5 (RD5),  .i6 (RD6),  .i7 (RD7),
      .i8 (RD8),  .i9 (RD9),  .i10(RD10), .i11(RD11),
      .i12(RD12), .i13(RD13),  .i14(RD14), .i15(RD15),
      .sel(RDADDRDEC));
 -----/\----- EXCLUDED -----/\----- */

   MUX16X1 #(REGFILE_WIDTH) U_muxout
     (.mo (RDDATA),
      .in0 (RD0),  .in1 (RD1),   .in2 (RD2),  .in3 (RD3), 
      .in4 (RD4),  .in5 (RD5),   .in6 (RD6),  .in7 (RD7),
      .in8 (RD8),  .in9 (RD9),   .in10(RD10), .in11(RD11),
      .in12(RD12), .in13(RD13),  .in14(RD14), .in15(RD15),
      .sel(RDADDR));
   
endmodule // RF16x1


// --------------- 256-entry Parameterizable Width Register File ---------------
module RF256x1 (RDDATA, CLK, RESET, RDADDR, WRADDR, WRDATA, WREN);
   
   parameter                            REGFILE_WIDTH = 8;

   input                                CLK;    // Tte Unit Clock
   input                                RESET;  // Global Reset
   input [7:0] 				RDADDR; // Read Address
   input [7:0] 				WRADDR; // Write Address
   input [REGFILE_WIDTH-1:0]            WRDATA; // Write Data
   input                                WREN;   // Write Enable

   output [REGFILE_WIDTH-1:0]           RDDATA; // Read Data

   wire [REGFILE_WIDTH-1:0]             RD0,  RD1,  RD2,  RD3,  RD4,  RD5,  RD6,  RD7,
                                        RD8,  RD9,  RD10, RD11, RD12, RD13, RD14, RD15;

   wire [15:0] 				WRADDRDEC, WRENDEC; // RDADDRDEC;
   
   // Decode the upper 4 bits
   DEC4x16 U_wrdec(.o(WRADDRDEC), .i(WRADDR[7:4]));
   assign WRENDEC = (WRADDRDEC & {16{WREN}});

   // surefire lint_off PORNAM
   RF16x1 #(REGFILE_WIDTH) U0_rf16x1  (RD0, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[0]);
   RF16x1 #(REGFILE_WIDTH) U1_rf16x1  (RD1, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[1]);
   RF16x1 #(REGFILE_WIDTH) U2_rf16x1  (RD2, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[2]);
   RF16x1 #(REGFILE_WIDTH) U3_rf16x1  (RD3, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[3]);
   RF16x1 #(REGFILE_WIDTH) U4_rf16x1  (RD4, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[4]);
   RF16x1 #(REGFILE_WIDTH) U5_rf16x1  (RD5, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[5]);
   RF16x1 #(REGFILE_WIDTH) U6_rf16x1  (RD6, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[6]);
   RF16x1 #(REGFILE_WIDTH) U7_rf16x1  (RD7, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[7]);
   RF16x1 #(REGFILE_WIDTH) U8_rf16x1  (RD8, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[8]);
   RF16x1 #(REGFILE_WIDTH) U9_rf16x1  (RD9, CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[9]);
   RF16x1 #(REGFILE_WIDTH) U10_rf16x1 (RD10,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[10]);
   RF16x1 #(REGFILE_WIDTH) U11_rf16x1 (RD11,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[11]);
   RF16x1 #(REGFILE_WIDTH) U12_rf16x1 (RD12,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[12]);
   RF16x1 #(REGFILE_WIDTH) U13_rf16x1 (RD13,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[13]);
   RF16x1 #(REGFILE_WIDTH) U14_rf16x1 (RD14,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[14]);
   RF16x1 #(REGFILE_WIDTH) U15_rf16x1 (RD15,CLK,RESET,RDADDR[3:0],WRADDR[3:0],WRDATA,WRENDEC[15]);
   // surefire lint_on PORNAM

/* -----\/----- EXCLUDED -----\/-----
   DEC4x16 U_rddec(.o(RDADDRDEC), .i(RDADDR[7:4]));

   OHMUX16 #(REGFILE_WIDTH) U_muxout
     (.mo (RDDATA),
      .i0 (RD0),  .i1 (RD1),  .i2 (RD2),  .i3 (RD3), 
      .i4 (RD4),  .i5 (RD5),  .i6 (RD6),  .i7 (RD7),
      .i8 (RD8),  .i9 (RD9),  .i10(RD10), .i11(RD11),
      .i12(RD12), .i13(RD13), .i14(RD14), .i15(RD15),
      .sel(RDADDRDEC));
 -----/\----- EXCLUDED -----/\----- */

   MUX16X1 #(REGFILE_WIDTH) U_muxout
     (.mo (RDDATA),
      .in0 (RD0),  .in1 (RD1),   .in2 (RD2),  .in3 (RD3), 
      .in4 (RD4),  .in5 (RD5),   .in6 (RD6),  .in7 (RD7),
      .in8 (RD8),  .in9 (RD9),   .in10(RD10), .in11(RD11),
      .in12(RD12), .in13(RD13),  .in14(RD14), .in15(RD15),
      .sel(RDADDR[7:4]));

endmodule // RF256x1


module FIFO(
   // Outputs
   EMPTY, FULL, COUNT, Q, 
   // Inputs
   CLK, RESET, PUSH, POP, D
   );
   
   parameter FIFO_DATA_WIDTH = 16;
   parameter FIFO_DEPTH      = 4;
   parameter FIFO_ADDR_WIDTH = 16;
   parameter FIFO_FULL_LEVEL = 8;

   /* 0in assert -clock CLK -reset ~RESET
                 -var ((1<<FIFO_ADDR_WIDTH) >= FIFO_DEPTH) */
   /* 0in assert -clock CLK -reset ~RESET
                 -var (FIFO_FULL_LEVEL <= FIFO_DEPTH) */

   input                                CLK;
   input 				RESET;

   input 				PUSH;
   input 				POP;
   output 				EMPTY;
   output 				FULL; // surefire lint_off_line UDDODN
   output [FIFO_ADDR_WIDTH  :0] 	COUNT; // surefire lint_off_line UDDODN
   
   input  [FIFO_DATA_WIDTH-1:0] 	D;
   output [FIFO_DATA_WIDTH-1:0]         Q;

   // 0in kndr -clock CLK -reset ~RESET -var PUSH
   // 0in kndr -clock CLK -reset ~RESET -var POP
   // 0in kndr -clock CLK -reset ~RESET -var EMPTY
   // 0in kndr -clock CLK -reset ~RESET -var FULL
   // 0in kndr -clock CLK -reset ~RESET -var COUNT

   reg	  [FIFO_ADDR_WIDTH  :0]		cnt;
   reg	  [FIFO_ADDR_WIDTH-1:0] 	rptr;
   reg	  [FIFO_ADDR_WIDTH-1:0] 	wptr;

   wire					read;
   wire					write;
   wire					REALFULL;

   assign EMPTY = cnt == {(FIFO_ADDR_WIDTH+1){1'b0}};
// surefire lint_off CWECSM CWECSB
   assign FULL  = cnt >= FIFO_FULL_LEVEL;
   assign REALFULL  = cnt >= FIFO_DEPTH;
// surefire lint_on CWECSM CWECSB
   assign COUNT = cnt;

   assign write = PUSH & ~REALFULL;
   assign read = POP & ~EMPTY;

   /* 0in fifo -clock CLK
               -reset ~RESET
               -depth FIFO_DEPTH
               -high_water FIFO_FULL_LEVEL
               -enq write
               -enq_data D
               -deq read
               -deq_data Q
               -latency 1 */

   always @(posedge CLK) begin
     if (~RESET) 
       wptr <= {FIFO_ADDR_WIDTH{1'b0}};
     else
// surefire lint_off ASWEMB CWECSM CWECSB XWECSX CWECSS
       wptr <= write ? (((wptr+1'b1) == FIFO_DEPTH) ? {FIFO_ADDR_WIDTH{1'b0}} : (wptr+1'b1)) 
       		     : wptr;
// surefire lint_on ASWEMB CWECSM CWECSB XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       rptr <= {FIFO_ADDR_WIDTH{1'b0}};
     else
// surefire lint_off ASWEMB CWECSM CWECSB XWECSX CWECSS
       rptr <= read ? (((rptr+1'b1) == FIFO_DEPTH) ? {FIFO_ADDR_WIDTH{1'b0}} : (rptr+1'b1))
       		    : rptr;
// surefire lint_on ASWEMB CWECSM CWECSB XWECSX CWECSS
   end

   SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,FIFO_ADDR_WIDTH) FIFO_SPRF(
     .QA(Q[FIFO_DATA_WIDTH-1:0]),
     .AA(rptr[FIFO_ADDR_WIDTH-1:0]),
     .CLKA(CLK),
     .CENA(~read),
     .AB(wptr[FIFO_ADDR_WIDTH-1:0]),
     .DB(D[FIFO_DATA_WIDTH-1:0]),
     .CLKB(CLK),
     .CENB(~write)
   );

   always @(posedge CLK) begin
     if (~RESET) begin
// surefire lint_off ASWIMB
       cnt <= {(FIFO_ADDR_WIDTH+1){1'b0}};
// surefire lint_on ASWIMB
     end else begin
//surefire lint_off CSEDFT CSEBYP
       case ({write,read})
         2'b00: cnt <= cnt;
	 2'b11: cnt <= cnt;
// surefire lint_off ASWIMB
	 2'b01: cnt <= cnt - 1'b1;
	 2'b10: cnt <= cnt + 1'b1;
// surefire lint_on ASWIMB
	 // synopsys translate_off
	 default: cnt <= {(FIFO_ADDR_WIDTH+1){1'bx}};
	 // synopsys translate_on
//surefire lint_on CSEDFT CSEBYP
       endcase
     end
   end
   
endmodule // FIFO

// Lookahead Fifo
module FIFO_LA (
   // Outputs
   EMPTY, FULL, Q, WRPTR, RDPTR,
   // Inputs
   CLK, RESET, PUSH, POP, D
   );
   
   parameter FIFO_DATA_WIDTH = 32;
   parameter FIFO_DEPTH      = 8;
   parameter FIFO_ADDR_WIDTH = 8;

   /* 0in assert -clock CLK -reset ~RESET
                 -var ((1<<FIFO_ADDR_WIDTH) >= FIFO_DEPTH) */

   input                                CLK;
   input 				RESET; //surefire lint_off_line RD_WRT

   input 				PUSH;
   input 				POP;
   output 				EMPTY;
   output 				FULL;
   output [FIFO_ADDR_WIDTH  :0]         WRPTR; // surefire lint_off_line UDDODN
   output [FIFO_ADDR_WIDTH  :0]         RDPTR; // surefire lint_off_line UDDODN
 
   input  [FIFO_DATA_WIDTH-1:0] 	D;
   output [FIFO_DATA_WIDTH-1:0] 	Q;

   // 0in kndr -clock CLK -reset ~RESET -var PUSH
   // 0in kndr -clock CLK -reset ~RESET -var POP
   // 0in kndr -clock CLK -reset ~RESET -var EMPTY
   // 0in kndr -clock CLK -reset ~RESET -var FULL
   // 0in kndr -clock CLK -reset ~RESET -var WRPTR
   // 0in kndr -clock CLK -reset ~RESET -var RDPTR

   reg	  [FIFO_ADDR_WIDTH  :0]		rptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		rptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		fifrptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr;
   reg	  [FIFO_DATA_WIDTH-1:0]		regd;
   reg					regwr;
   reg					regvld;

   wire   [FIFO_DATA_WIDTH-1:0]		ramd;
   wire					read;
   wire					write;
   wire					fifrd;
   wire					fifempty;

   assign WRPTR = wptr;
   assign RDPTR = rptr;

   assign write = PUSH & ~FULL;
   assign read = POP & ~EMPTY;

   /* 0in fifo -clock CLK
               -reset ~RESET
               -depth FIFO_DEPTH
               -high_water FIFO_DEPTH
               -enq write
               -enq_data D
               -deq read
               -deq_data Q
               -latency 0 */

   always @(posedge CLK) begin
     if (~RESET) 
       wptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
   // surefire lint_off ASWEMB CWECSM XWECSX CWECSS
       wptr[FIFO_ADDR_WIDTH:0] <= write ? (((wptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
 		     			? {~wptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		     			: (wptr[FIFO_ADDR_WIDTH:0]+1'b1))
		     			: wptr[FIFO_ADDR_WIDTH:0];
   // surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(rptr_q or read) begin
   // surefire lint_off ASWEMB CWECSM XWECSX CWECSS
     rptr[FIFO_ADDR_WIDTH:0]  = read ? (((rptr_q[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH)
     		 		     ? {~rptr_q[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		 		     : (rptr_q[FIFO_ADDR_WIDTH:0]+1'b1))
		 		     : rptr_q[FIFO_ADDR_WIDTH:0];
   // surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       rptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       rptr_q[FIFO_ADDR_WIDTH:0] <= rptr[FIFO_ADDR_WIDTH:0];
   end

   SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,FIFO_ADDR_WIDTH) FIFO_SPRF(
     .QA(ramd[FIFO_DATA_WIDTH-1:0]),
     .AA(fifrptr[FIFO_ADDR_WIDTH-1:0]),
     .CLKA(CLK),
     .CENA(~fifrd),
     .AB(wptr[FIFO_ADDR_WIDTH-1:0]),
     .DB(D[FIFO_DATA_WIDTH-1:0]),
     .CLKB(CLK),
     .CENB(~write)
   );

   always @(posedge CLK) begin
     if (~RESET)
       wptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       wptr_q[FIFO_ADDR_WIDTH:0] <= wptr[FIFO_ADDR_WIDTH:0];
   end
   
   assign EMPTY = wptr_q[FIFO_ADDR_WIDTH:0] == rptr_q[FIFO_ADDR_WIDTH:0];
   assign FULL  = ((wptr[FIFO_ADDR_WIDTH] != rptr_q[FIFO_ADDR_WIDTH]) &
   		   (wptr[FIFO_ADDR_WIDTH-1:0] == rptr_q[FIFO_ADDR_WIDTH-1:0]));

   assign fifempty = wptr[FIFO_ADDR_WIDTH:0] == fifrptr[FIFO_ADDR_WIDTH:0];
   assign fifrd = ((~regvld & ~regwr)| (~regvld & regwr & read) | (regvld & read)) & ~fifempty;

   always @(posedge CLK) begin
     if (~RESET) 
       fifrptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
   // surefire lint_off ASWEMB CWECSM XWECSX CWECSS
       fifrptr[FIFO_ADDR_WIDTH:0] <= fifrd ? (((fifrptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
                                      ? {~fifrptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
                                      : (fifrptr[FIFO_ADDR_WIDTH:0]+1'b1))
                                      : fifrptr[FIFO_ADDR_WIDTH:0];
   // surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       regwr <= 1'b0;
     else
       regwr <= fifrd;
   end

   always @(posedge CLK) begin
     if (regwr)
       regd <= ramd;
   end

   always @(posedge CLK) begin
     if (~RESET) 
       regvld <= 1'b0;
     else
       regvld <= (regvld | regwr) & ~read;
   end

   assign Q = regvld ? regd : ramd;

endmodule // fifo_la

// Lookahead Fifo with flush
module FIFO_LA_FLUSH (
   // Outputs
   EMPTY, FULL, Q, WRPTR, RDPTR,
   // Inputs
   CLK, RESET, PUSH, POP, D, FLUSH
   );
   
   parameter FIFO_DATA_WIDTH = 32;
   parameter FIFO_DEPTH      = 8;
   parameter FIFO_ADDR_WIDTH = 8;

   /* 0in assert -clock CLK -reset ~RESET
                 -var ((1<<FIFO_ADDR_WIDTH) >= FIFO_DEPTH) */

   input                                CLK;
   input 				RESET;

   input 				PUSH;
   input 				POP;
   // surefire lint_off UDDODN
   output 				EMPTY;
   output 				FULL;
   output [FIFO_ADDR_WIDTH  :0]         WRPTR;
   output [FIFO_ADDR_WIDTH  :0]         RDPTR;
   // surefire lint_on  UDDODN
 
   input  [FIFO_DATA_WIDTH-1:0] 	D;
   output [FIFO_DATA_WIDTH-1:0] 	Q;

   input                                FLUSH;

   // 0in kndr -clock CLK -reset ~RESET -var PUSH
   // 0in kndr -clock CLK -reset ~RESET -var POP
   // 0in kndr -clock CLK -reset ~RESET -var EMPTY
   // 0in kndr -clock CLK -reset ~RESET -var FULL
   // 0in kndr -clock CLK -reset ~RESET -var WRPTR
   // 0in kndr -clock CLK -reset ~RESET -var RDPTR

   reg	  [FIFO_ADDR_WIDTH  :0]		rptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		rptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		fifrptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr;
   reg	  [FIFO_DATA_WIDTH-1:0]		regd;
   reg					regwr;
   reg					regvld;

   wire   [FIFO_DATA_WIDTH-1:0]		ramd;
   wire					read;
   wire					write;
   wire					fifrd;
   wire					fifempty;

   assign WRPTR = wptr;
   assign RDPTR = rptr;

   assign write = PUSH & ~FULL;
   assign read = POP & ~EMPTY;

   /* 0in fifo -clock CLK
               -reset ~RESET
               -depth FIFO_DEPTH
               -high_water FIFO_DEPTH
               -enq write
               -enq_data D
               -deq read
               -deq_data Q
               -latency 0 */

   always @(posedge CLK) begin
     if (~RESET | FLUSH) 
       wptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       // surefire lint_off ASWEMB CWECSB XWECSX CWECSS
       wptr[FIFO_ADDR_WIDTH:0] <= write ? (((wptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
 		     			? {~wptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		     			: (wptr[FIFO_ADDR_WIDTH:0]+1'b1))
		     			: wptr[FIFO_ADDR_WIDTH:0];
       // surefire lint_on  ASWEMB CWECSB XWECSX CWECSS
   end

   always @(rptr_q or read) begin
     // surefire lint_off ASWEMB CWECSB XWECSX CWECSS
     rptr[FIFO_ADDR_WIDTH:0]  = read ? (((rptr_q[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH)
     		 		     ? {~rptr_q[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		 		     : (rptr_q[FIFO_ADDR_WIDTH:0]+1'b1))
		 		     : rptr_q[FIFO_ADDR_WIDTH:0];
     // surefire lint_on  ASWEMB CWECSB XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET | FLUSH)
       rptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       rptr_q[FIFO_ADDR_WIDTH:0] <= rptr[FIFO_ADDR_WIDTH:0];
   end

   SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,FIFO_ADDR_WIDTH) FIFO_SPRF(
     .QA(ramd[FIFO_DATA_WIDTH-1:0]),
     .AA(fifrptr[FIFO_ADDR_WIDTH-1:0]),
     .CLKA(CLK),
     .CENA(~fifrd),
     .AB(wptr[FIFO_ADDR_WIDTH-1:0]),
     .DB(D[FIFO_DATA_WIDTH-1:0]),
     .CLKB(CLK),
     .CENB(~write)
   );

   always @(posedge CLK) begin
     if (~RESET | FLUSH)
       wptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       wptr_q[FIFO_ADDR_WIDTH:0] <= wptr[FIFO_ADDR_WIDTH:0];
   end
   
   assign EMPTY = wptr_q[FIFO_ADDR_WIDTH:0] == rptr_q[FIFO_ADDR_WIDTH:0];
   assign FULL  = ((wptr[FIFO_ADDR_WIDTH] != rptr_q[FIFO_ADDR_WIDTH]) &
   		   (wptr[FIFO_ADDR_WIDTH-1:0] == rptr_q[FIFO_ADDR_WIDTH-1:0]));

   assign fifempty = wptr[FIFO_ADDR_WIDTH:0] == fifrptr[FIFO_ADDR_WIDTH:0];
   assign fifrd = ((~regvld & ~regwr)| (~regvld & regwr & read) | (regvld & read)) & ~fifempty;

   always @(posedge CLK) begin
     if (~RESET | FLUSH) 
       fifrptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       // surefire lint_off ASWEMB CWECSB XWECSX CWECSS
       fifrptr[FIFO_ADDR_WIDTH:0] <= fifrd ? (((fifrptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
                                      ? {~fifrptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
                                      : (fifrptr[FIFO_ADDR_WIDTH:0]+1'b1))
                                      : fifrptr[FIFO_ADDR_WIDTH:0];
       // surefire lint_on  ASWEMB CWECSB XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET | FLUSH)
       regwr <= 1'b0;
     else
       regwr <= fifrd;
   end

   always @(posedge CLK) begin
     if (regwr)
       regd <= ramd;
   end

   always @(posedge CLK) begin
     if (~RESET | FLUSH) 
       regvld <= 1'b0;
     else
       regvld <= (regvld | regwr) & ~read;
   end

   assign Q = regvld ? regd : ramd;

endmodule // fifo_la_flush

// Two port read/write SRAM 
module DPR (
   QA,
   CLKA,
   CENA,
   WENA,
   AA,
   DA,
   QB,
   CLKB,
   CENB,
   WENB,
   AB,
   DB
);
   parameter		   BITS = 16;
   parameter		   word_depth = 1024;
   parameter		   addr_width = 10;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};

   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN UDDINN
   output [BITS-1:0] QA;
   input CLKA;
   input CENA;
   input WENA;
   input [addr_width-1:0] AA;
   input [BITS-1:0] DA;
   output [BITS-1:0] QB;
   input CLKB;
   input CENB;
   input WENB;
   input [addr_width-1:0] AB;
   input [BITS-1:0] DB;
   // surefire lint_on UDDIDN UDDONU UDDICN UDDONN UDDINN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AAQ, ABQ;
   reg [BITS-1:0] 	DAQ, DBQ;
   reg 			WENAQ, WENBQ;
   wire 		AIA = CENA & (AAQ!==AA);
   wire 		AIB = CENB & (ABQ!==AB);
   wire 		DIA = CENA & (DAQ!==DA);
   wire 		DIB = CENB & (DBQ!==DB);
   wire 		WIA = CENA & (WENAQ!==WENA);
   wire 		WIB = CENB & (WENBQ!==WENB);
   initial $display ("MEMPWR DPR: %m(A) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, 1'b0);
   initial $display ("MEMPWR DPR: %m(B) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, 1'b0);
   always @(posedge CLKA) begin
      $display ("MEMPWR DPR: %m(A) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENA,WENA,AIA,DIA,WIA,(AIA|DIA|WIA), $time);
      AAQ   <= AA;
      DAQ   <= DA;
      WENAQ <= WENA;
   end
   always @(posedge CLKB) begin
      $display ("MEMPWR DPR: %m(B) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENB,WENB,AIB,DIB,WIB,(AIB|DIB|WIB), $time);
      ABQ   <= AB;
      DBQ   <= DB;
      WENBQ <= WENB;
   end
  `endif
   
   reg [BITS-1:0]	   mem [word_depth-1:0];


   reg			   LATCHED_CENA;
   reg	                  LATCHED_WENA;
   reg [addr_width-1:0]	   LATCHED_AA;
   reg [BITS-1:0]	   LATCHED_DA;
   reg			   LATCHED_CENB;
   reg	                  LATCHED_WENB;
   reg [addr_width-1:0]	   LATCHED_AB;
   reg [BITS-1:0]	   LATCHED_DB;

   reg			   CENAi;
   reg           	   WENAi;
   reg [addr_width-1:0]	   AAi;
   reg [BITS-1:0]	   DAi;
   reg [BITS-1:0]	   QAi;
   reg [BITS-1:0]	   QA;
   reg [BITS-1:0]	   LAST_QAi;
   reg			   CENBi;
   reg           	   WENBi;
   reg [addr_width-1:0]	   ABi;
   reg [BITS-1:0]	   DBi;
   reg [BITS-1:0]	   QBi;
   reg [BITS-1:0]	   QB;
   reg [BITS-1:0]	   LAST_QBi;

   reg			   LAST_CLKA;
   reg			   LAST_CLKB;

   reg                     valid_cycleA;
   reg                     valid_cycleB;

   task mem_cycleA;
   begin
      valid_cycleA = 1'bx;
      casez({WENAi,CENAi})

	2'b10: begin
	   valid_cycleA = 1;
	   read_memA(1,0);
	end
	2'b00: begin
	   valid_cycleA = 0;
	   write_mem(AAi,DAi);
	   read_memA(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   valid_cycleA = 1;
	   read_memA(0,1);
	end
	2'bx0: begin
	   valid_cycleA = 0;
	   write_mem_x(AAi);
	   read_memA(0,1);
	end
	2'b0x,
	2'bxx: begin
	   valid_cycleA = 0;
	   write_mem_x(AAi);
	   read_memA(0,1);
	end
      endcase
   end
   endtask
   task mem_cycleB;
   begin
      valid_cycleB = 1'bx;
      casez({WENBi,CENBi})

	2'b10: begin
	   valid_cycleB = 1;
	   read_memB(1,0);
	end
	2'b00: begin
	   valid_cycleB = 0;
	   write_mem(ABi,DBi);
	   read_memB(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   valid_cycleB = 1;
	   read_memB(0,1);
	end
	2'bx0: begin
	   valid_cycleB = 0;
	   write_mem_x(ABi);
	   read_memB(0,1);
	end
	2'b0x,
	2'bxx: begin
	   valid_cycleB = 0;
	   write_mem_x(ABi);
	   read_memB(0,1);
	end
      endcase
   end
   endtask
      

   task latch_Ainputs;
   begin
      LATCHED_AA = AA ;
      LATCHED_DA = DA ;
      LATCHED_WENA = WENA ;
      LATCHED_CENA = CENA ;
      LAST_QAi = QAi;
   end
   endtask
   task latch_Binputs;
   begin
      LATCHED_AB = AB ;
      LATCHED_DB = DB ;
      LATCHED_WENB = WENB ;
      LATCHED_CENB = CENB ;
      LAST_QBi = QBi;
   end
   endtask


   task update_Alogic;
   begin
      CENAi = LATCHED_CENA;
      WENAi = LATCHED_WENA;
      AAi = LATCHED_AA;
      DAi = LATCHED_DA;
   end
   endtask
   task update_Blogic;
   begin
      CENBi = LATCHED_CENB;
      WENBi = LATCHED_WENB;
      ABi = LATCHED_AB;
      DBi = LATCHED_DB;
   end
   endtask

   task read_memA;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(AAi))
	       begin
                     QAi=mem[AAi];
	       end
	    else
	       begin
		  QAi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  QAi=wordx;
	       end
	    else
	       begin
	          QAi=DAi;
	       end
	 end
   end
   endtask
   task read_memB;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(ABi))
	       begin
                     QBi=mem[ABi];
	       end
	    else
	       begin
		  QBi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  QBi=wordx;
	       end
	    else
	       begin
	          QBi=DBi;
	       end
	 end
   end
   endtask

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
 
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=d;
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=wordx;
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask


   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction
   
   always @(QAi) begin
     QA <= QAi;
   end
   always @(QBi) begin
     QB <= QBi;
   end

   always @( CLKA )
      begin
         casez({LAST_CLKA,CLKA})
	   2'b01: begin
	      latch_Ainputs;
	      update_Alogic;
	      mem_cycleA;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_memA(0,1);
	   end
	   
	 endcase
	 LAST_CLKA = CLKA;
      end
   always @( CLKB )
      begin
         casez({LAST_CLKB,CLKB})
	   2'b01: begin
	      latch_Binputs;
	      update_Blogic;
	      mem_cycleB;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_memB(0,1);
	   end
	   
	 endcase
	 LAST_CLKB = CLKB;
      end
//synopsys translate_on
endmodule

// Two port read/write SRAM with bit mask
module DPRBM (
   QA,
   CLKA,
   CENA,
   WENA,
   AA,
   DA,
   QB,
   CLKB,
   CENB,
   WENB,
   AB,
   DB
);
   parameter		   BITS = 16;
   parameter		   word_depth = 4096;
   parameter		   addr_width = 12;
   parameter               mask_width = 2 ;
   parameter               wp_size    = BITS-1 ;
   parameter		   maskx = {mask_width{1'bx}};
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN
   output [BITS-1:0] QA;
   input CLKA;
   input CENA;
   input [mask_width-1:0] WENA;
   input [addr_width-1:0] AA;
   input [BITS-1:0] DA;
   output [BITS-1:0] QB;
   input CLKB;
   input CENB;
   input [mask_width-1:0] WENB;
   input [addr_width-1:0] AB;
   input [BITS-1:0] DB;
   // surefire lint_on UDDIDN UDDONU UDDICN UDDONN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AAQ, ABQ;
   reg [BITS-1:0] 	DAQ, DBQ;
   reg [mask_width-1:0] WENAQ, WENBQ;
   wire 		AIA = CENA & (AAQ!==AA);
   wire 		AIB = CENB & (ABQ!==AB);
   wire 		DIA = CENA & (DAQ!==DA);
   wire 		DIB = CENB & (DBQ!==DB);
   wire 		WIA = CENA & (WENAQ!==WENA);
   wire 		WIB = CENB & (WENBQ!==WENB);   
   initial $display ("MEMPWR DPRBM: %m(A) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, mask_width);
   initial $display ("MEMPWR DPRBM: %m(B) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, mask_width);
   always @(posedge CLKA) begin
      $display ("MEMPWR DPRBM: %m(A) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENA,&WENA,AIA,DIA,WIA,(AIA|DIA|WIA),$time);
      AAQ <= AA;
      DAQ <= DA;
      WENAQ <= WENA;
   end
   always @(posedge CLKB) begin
      $display ("MEMPWR DPRBM: %m(B) CEN: %b WEN :%b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENB,&WENB,AIB,DIB,WIB,(AIB|DIB|WIB), $time);
      ABQ <= AB;
      DBQ <= DB;
      WENBQ <= WENB;
   end
  `endif

   reg [BITS-1:0]	   mem [word_depth-1:0];

   wire [BITS-1:0]   _QA;
   wire [addr_width-1:0]   _AA;
   wire			   _CLKA;
   wire			   _CENA;
   wire [mask_width-1:0]   _WENA;

   wire [BITS-1:0]   _DA;

   wire [BITS-1:0]   _QB;
   wire [addr_width-1:0]   _AB;
   wire			   _CLKB;
   wire			   _CENB;
   wire [mask_width-1:0]   _WENB;

   wire [BITS-1:0]   _DB;

   reg			   LATCHED_CENA;
   reg	[mask_width-1:0]  LATCHED_WENA;
   reg [addr_width-1:0]	   LATCHED_AA;
   reg [BITS-1:0]	   LATCHED_DA;
   reg			   LATCHED_CENB;
   reg	[mask_width-1:0]  LATCHED_WENB;
   reg [addr_width-1:0]	   LATCHED_AB;
   reg [BITS-1:0]	   LATCHED_DB;

   reg			   CENAi;
   reg [mask_width-1:0]	   WENAi;
   reg [addr_width-1:0]	   AAi;
   reg [BITS-1:0]	   DAi;
   reg [BITS-1:0]	   QAi;
   reg [BITS-1:0]	   QA;
   reg [BITS-1:0]	   LAST_QAi;
   reg			   CENBi;
   reg [mask_width-1:0]	   WENBi;
   reg [addr_width-1:0]	   ABi;
   reg [BITS-1:0]	   DBi;
   reg [BITS-1:0]	   QBi;
   reg [BITS-1:0]	   QB;
   reg [BITS-1:0]	   LAST_QBi;



   reg			   LAST_CLKA;
   reg			   LAST_CLKB;

   reg [BITS-1:0]          dummy;
   integer mask_section ;
   integer lsb, msb  ;


   reg [mask_width-1:0]    valid_cycleA;
   reg [mask_width-1:0]    valid_cycleB;


   task mem_cycleA;
   begin
      valid_cycleA = maskx;
    for (mask_section=0;mask_section<mask_width; mask_section=mask_section+1)
    begin
      lsb = (mask_section)*(wp_size) ;
      msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
      casez({WENAi[mask_section],CENAi})

	2'b10: begin
	   valid_cycleA[mask_section] = 1;
	   read_memA(1,0);
	end
	2'b00: begin
	   valid_cycleA[mask_section] = 0;
	   write_mem(AAi,DAi);
	   read_memA(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   valid_cycleA[mask_section] = 1;
	   read_memA(0,1);
	end
	2'bx0: begin
	   valid_cycleA[mask_section] = 0;
	   write_mem_x(AAi);
	   read_memA(0,1);
	end
	2'b0x,
	2'bxx: begin
	   valid_cycleA[mask_section] = 0;
	   write_mem_x(AAi);
	   read_memA(0,1);
	end
      endcase
   end
   end
   endtask
   task mem_cycleB;
   begin
      valid_cycleB = maskx;
    for (mask_section=0;mask_section<mask_width; mask_section=mask_section+1)
    begin
      lsb = (mask_section)*(wp_size) ;
      msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
      casez({WENBi[mask_section],CENBi})

	2'b10: begin
	   valid_cycleB[mask_section] = 1;
	   read_memB(1,0);
	end
	2'b00: begin
	   valid_cycleB[mask_section] = 0;
	   write_mem(ABi,DBi);
	   read_memB(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   valid_cycleB[mask_section] = 1;
	   read_memB(0,1);
	end
	2'bx0: begin
	   valid_cycleB[mask_section] = 0;
	   write_mem_x(ABi);
	   read_memB(0,1);
	end
	2'b0x,
	2'bxx: begin
	   valid_cycleB[mask_section] = 0;
	   write_mem_x(ABi);
	   read_memB(0,1);
	end
      endcase
   end
   end
   endtask
      
   task latch_Ainputs;
   begin
      LATCHED_AA = _AA ;
      LATCHED_DA = _DA ;
      LATCHED_WENA = _WENA ;
      LATCHED_CENA = _CENA ;
      LAST_QAi = QAi;
   end
   endtask
   task latch_Binputs;
   begin
      LATCHED_AB = _AB ;
      LATCHED_DB = _DB ;
      LATCHED_WENB = _WENB ;
      LATCHED_CENB = _CENB ;
      LAST_QBi = QBi;
   end
   endtask

   task update_Alogic;
   begin
      CENAi = LATCHED_CENA;
      WENAi = LATCHED_WENA;
      AAi = LATCHED_AA;
      DAi = LATCHED_DA;
   end
   endtask
   task update_Blogic;
   begin
      CENBi = LATCHED_CENB;
      WENBi = LATCHED_WENB;
      ABi = LATCHED_AB;
      DBi = LATCHED_DB;
   end
   endtask

   task read_memA;
      input r_wb;
      input xflag;
      integer i ;
   begin
      if (r_wb)
	 begin
	    if (valid_address(AAi))
	       begin
                  dummy = mem[AAi] ;
                  for (i=lsb;i<=msb;i=i+1) QAi[i] = dummy[i] ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) QAi[i] = 1'bx ;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
                  for (i=lsb;i<=msb;i=i+1) QAi[i] = 1'bx ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) QAi[i] = dummy[i] ;
	       end
	 end
   end
   endtask
   task read_memB;
      input r_wb;
      input xflag;
      integer i ;
   begin
      if (r_wb)
	 begin
	    if (valid_address(ABi))
	       begin
                  dummy = mem[ABi] ;
                  for (i=lsb;i<=msb;i=i+1) QBi[i] = dummy[i] ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) QBi[i] = 1'bx ;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
                  for (i=lsb;i<=msb;i=i+1) QBi[i] = 1'bx ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) QBi[i] = dummy[i] ;
	       end
	 end
   end
   endtask

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
   integer i;
 
   begin
      casez({valid_address(a)})
	1'b0: 
		begin
			x_mem;
                	for (i=lsb; i<=msb; i=i+1)  dummy[i] = d[i] ;
		end
        1'b1 : begin
		dummy= mem[a];
                for (i=lsb; i<=msb; i=i+1)  dummy[i] = d[i] ;
                mem[a]=dummy;
              end
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
   integer i;
   begin
      casez({valid_address(a)})
	1'b0: 
		begin
			x_mem;
                	for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
		end
        1'b1 : begin
		dummy= mem[a];
                for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
                mem[a]=dummy;
              end
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask


   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction

   always @(_QA) begin
     QA <=  _QA;
   end
   assign _DA = DA;
   assign _AA = AA;
   assign _WENA = WENA;
   assign _CLKA = CLKA;
   assign _CENA = CENA;

   always @(_QB) begin
     QB <= _QB;
   end
   assign _DB = DB;
   assign _AB = AB;
   assign _WENB = WENB;
   assign _CLKB = CLKB;
   assign _CENB = CENB;

   assign _QA = QAi;
   assign _QB = QBi;

   always @( _CLKA )
      begin
         casez({LAST_CLKA,_CLKA})
	   2'b01: begin
	      latch_Ainputs;
	      update_Alogic;
	      mem_cycleA;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_memA(0,1);
	   end
	   
	 endcase
	 LAST_CLKA = _CLKA;
      end
   always @( _CLKB )
      begin
         casez({LAST_CLKB,_CLKB})
	   2'b01: begin
	      latch_Binputs;
	      update_Blogic;
	      mem_cycleB;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_memB(0,1);
	   end
	   
	 endcase
	 LAST_CLKB = _CLKB;
      end
//synopsys translate_on
endmodule

// Single read/write port SRAM 
module SPR (
   Q,
   CLK,
   CEN,
   WEN,
   A,
   D
);
   parameter		   BITS = 16;
   parameter		   word_depth = 1024;
   parameter		   addr_width = 10;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN
   output [BITS-1:0] Q;

   input CLK;
   input CEN;
   input WEN;
   input [addr_width-1:0] A;
   input [BITS-1:0] D;
   // surefire lint_on UDDIDN UDDONU UDDICN UDDONN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AQ;
   reg [BITS-1:0] 	DQ;
   reg 			WENQ;
   wire 		AI = CEN & (AQ!==A);
   wire 		DI = CEN & (DQ!==D);
   wire 		WI = CEN & (WENQ!==WEN);
   initial $display ("MEMPWR SPR: %m A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, 1'b0);
   always @(posedge CLK) begin
      $display ("MEMPWR SPR: %m CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CEN,WEN,AI,DI,WI,(AI|DI|WI), $time);
      AQ <= A;
      DQ <= D;
      WENQ <= WEN;
   end
  `endif
   
   
   reg [BITS-1:0]	   mem [word_depth-1:0];

   reg			   LATCHED_CEN;
   reg	                  LATCHED_WEN;
   reg [addr_width-1:0]	   LATCHED_A;
   reg [BITS-1:0]	   LATCHED_D;

   reg			   CENi;
   reg           	   WENi;
   reg [addr_width-1:0]	   Ai;
   reg [BITS-1:0]	   Di;
   reg [BITS-1:0]	   Qi;
   reg [BITS-1:0]	   Q;
   reg [BITS-1:0]	   LAST_Qi;

   reg			   LAST_CLK;

   task mem_cycle;
   begin
      casez({WENi,CENi})

	2'b10: begin
	   read_mem(1,0);
	end
	2'b00: begin
	   write_mem(Ai,Di);
	   read_mem(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   read_mem(0,1);
	end
	2'bx0: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
	2'b0x,
	2'bxx: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
      endcase
   end
   endtask
      

   task latch_inputs;
   begin
      LATCHED_A = A ;
      LATCHED_D = D ;
      LATCHED_WEN = WEN ;
      LATCHED_CEN = CEN ;
      LAST_Qi = Qi;
   end
   endtask


   task update_logic;
   begin
      CENi = LATCHED_CEN;
      WENi = LATCHED_WEN;
      Ai = LATCHED_A;
      Di = LATCHED_D;
   end
   endtask

   task read_mem;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(Ai))
	       begin
                     Qi=mem[Ai];
	       end
	    else
	       begin
		  Qi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  Qi=wordx;
	       end
	    else
	       begin
	          Qi=Di;
	       end
	 end
   end
   endtask

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
 
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=d;
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
   begin
      casez({valid_address(a)})
	1'b0: 
		x_mem;
	1'b1: mem[a]=wordx;
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask


   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction

   always @(Qi) begin
     Q <= Qi;
   end

   always @( CLK )
      begin
         casez({LAST_CLK,CLK})
	   2'b01: begin
	      latch_inputs;
	      update_logic;
	      mem_cycle;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_mem(0,1);
	   end
	   
	 endcase
	 LAST_CLK = CLK;
      end
//synopsys translate_on
endmodule

// Single read/write port SRAM with bit mask
module SPRBM (
   Q,
   CLK,
   CEN,
   WEN,
   A,
   D
);
   parameter		   BITS = 16;
   parameter		   word_depth = 4096;
   parameter		   addr_width = 12;
   parameter               mask_width = 2 ;
   parameter               wp_size    = BITS-1 ;
   parameter		   maskx = {mask_width{1'bx}};
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN
   output [BITS-1:0] Q;
   input CLK;
   input CEN;
   input [mask_width-1:0] WEN;
   input [addr_width-1:0] A;
   input [BITS-1:0] D;
   // surefire lint_on UDDIDN UDDONU UDDICN UDDONN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AQ;
   reg [BITS-1:0] 	DQ;
   reg [mask_width-1:0] WENQ;
   wire 		AI = CEN & (AQ!==A);
   wire 		DI = CEN & (DQ!==D);
   wire 		WI = CEN & (WENQ!==WEN);
   initial $display ("MEMPWR SPRBM: %m A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, mask_width);
   always @(posedge CLK) begin
      $display ("MEMPWR SPRBM: %m CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CEN,&WEN,AI,DI,WI,(AI|DI|WI), $time);
      AQ <= A;
      DQ <= D;
      WENQ <= WEN;
   end
  `endif
   
   reg [BITS-1:0]	   mem [word_depth-1:0];

   wire [BITS-1:0]   _Q;
   wire [addr_width-1:0]   _A;
   wire			   _CLK;
   wire			   _CEN;
   wire [mask_width-1:0]   _WEN;

   wire [BITS-1:0]   _D;


   reg			   LATCHED_CEN;
   reg	[mask_width-1:0]  LATCHED_WEN;
   reg [addr_width-1:0]	   LATCHED_A;
   reg [BITS-1:0]	   LATCHED_D;

   reg			   CENi;
   reg [mask_width-1:0]	   WENi;
   reg [addr_width-1:0]	   Ai;
   reg [BITS-1:0]	   Di;
   reg [BITS-1:0]	   Qi;
   reg [BITS-1:0]	   Q;
   reg [BITS-1:0]	   LAST_Qi;



   reg			   LAST_CLK;

   reg [BITS-1:0]          dummy;
   integer mask_section ;
   integer lsb, msb  ;

   task mem_cycle;
   begin
    for (mask_section=0;mask_section<mask_width; mask_section=mask_section+1)
    begin
      lsb = (mask_section)*(wp_size) ;
      msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
      casez({WENi[mask_section],CENi})

	2'b10: begin
	   read_mem(1,0);
	end
	2'b00: begin
	   write_mem(Ai,Di);
	   read_mem(0,0);
	end
	2'b?1: ;
	2'b1x: begin
	   read_mem(0,1);
	end
	2'bx0: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
	2'b0x,
	2'bxx: begin
	   write_mem_x(Ai);
	   read_mem(0,1);
	end
      endcase
   end
   end
   endtask
      
   task latch_inputs;
   begin
      LATCHED_A = _A ;
      LATCHED_D = _D ;
      LATCHED_WEN = _WEN ;
      LATCHED_CEN = _CEN ;
      LAST_Qi = Qi;
   end
   endtask


   task update_logic;
   begin
      CENi = LATCHED_CEN;
      WENi = LATCHED_WEN;
      Ai = LATCHED_A;
      Di = LATCHED_D;
   end
   endtask


   task read_mem;
      input r_wb;
      input xflag;
      integer i ;
   begin
      if (r_wb)
	 begin
	    if (valid_address(Ai))
	       begin
                  dummy = mem[Ai] ;
                  for (i=lsb;i<=msb;i=i+1) Qi[i] = dummy[i] ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) Qi[i] = 1'bx ;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
                  for (i=lsb;i<=msb;i=i+1) Qi[i] = 1'bx ;
	       end
	    else
	       begin
                  for (i=lsb;i<=msb;i=i+1) Qi[i] = dummy[i] ;
	       end
	 end
   end
   endtask

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
   integer i;
 
   begin
      casez({valid_address(a)})
	1'b0: 
		begin
			x_mem;
                	for (i=lsb; i<=msb; i=i+1)  dummy[i] = d[i] ;
		end
        1'b1 : begin
		dummy= mem[a];
                for (i=lsb; i<=msb; i=i+1)  dummy[i] = d[i] ;
                mem[a]=dummy;
              end
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
   integer i;
   begin
      casez({valid_address(a)})
	1'b0: 
		begin
			x_mem;
                	for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
		end
        1'b1 : begin
		dummy= mem[a];
                for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
                mem[a]=dummy;
              end
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask

   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction
   
   always @(_Q) begin
     Q <=  _Q;
   end
   assign _D =  D;
   assign _A =  A;
   assign _WEN = WEN;
   assign _CLK = CLK;
   assign _CEN = CEN;

   assign _Q = Qi;

   always @( _CLK )
      begin
         casez({LAST_CLK,_CLK})
	   2'b01: begin
	      latch_inputs;
	      update_logic;
	      mem_cycle;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_mem(0,1);
	   end
	   
	 endcase
	 LAST_CLK = _CLK;
      end
//synopsys translate_on
endmodule

// Single port Register file with dedicated read and dedicated write ports
module SPRF (
   QA,
   AA,
   CLKA,
   CENA,
   AB,
   DB,
   CLKB,
   CENB
);
   parameter		   BITS = 8;
   parameter		   word_depth = 16;
   parameter		   addr_width = 4;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};

   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN
   output [BITS-1:0] QA;
   input [addr_width-1:0] AA;
   input CLKA;
   input CENA;
   input [addr_width-1:0] AB;
   input [BITS-1:0] DB;
   input CLKB;
   input CENB;
   // surefire lint_on  UDDIDN UDDONU UDDICN UDDONN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AAQ, ABQ;
   reg [BITS-1:0] 	DAQ, DBQ;
   wire 		AIA = CENA & (AAQ!==AA);
   wire 		AIB = CENB & (ABQ!==AB);
   wire 		DIA = 1'b0;
   wire 		DIB = CENB & (DBQ!==DB);
   wire 		WIA = 1'b0;
   wire 		WIB = 1'b0;
   initial $display ("MEMPWR SPRF: %m(A) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, 1'b0);
   initial $display ("MEMPWR SPRF: %m(B) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, 1'b0);
   always @(posedge CLKA) begin
      $display ("MEMPWR SPRF: %m(A) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENA,1'b1,AIA,DIA,WIA,(AIA|DIA|WIA),$time);
      AAQ <= AA;
   end
   always @(posedge CLKB) begin
      $display ("MEMPWR SPRF: %m(B) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENB,1'b0,AIB,DIB,WIB,(AIB|DIB|WIB), $time);
      ABQ <= AB;
      DBQ <= DB;
   end
  `endif
   
   reg [BITS-1:0]	   mem [word_depth-1:0];

   wire [BITS-1:0]         _QA;
   reg  [BITS-1:0]          QA;
   wire [addr_width-1:0]   _AA;
   wire [addr_width-1:0]   _AB;
   wire			   _CLKA;
   wire			   _CLKB;
   wire			   _CENA;


   wire			   _CENB;
   wire [BITS-1:0]         _DB;

   reg			   LATCHED_CENA;


   reg			   LATCHED_CENB;
   reg [addr_width-1:0]	   LATCHED_AA;
   reg [addr_width-1:0]	   LATCHED_AB;
   reg [BITS-1:0]	   LATCHED_DB;

   reg			   CENAi;
   reg			   CENBi;


   reg [addr_width-1:0]	   AAi;
   reg [addr_width-1:0]	   ABi;
   reg [BITS-1:0]	   DBi;
   reg [BITS-1:0]	   QAi;
   reg [BITS-1:0]	   LAST_QAi;


   reg			   LAST_CLKA;
   reg			   LAST_CLKB;

   reg                     valid_cycleA;
   reg                     valid_cycleB;


   task mem_cycleA;
   begin
      valid_cycleA = 1'bx;
      casez({CENAi})
	1'b0: begin
	   valid_cycleA = 1;
	   read_memA(1,0);
	end
	1'b1: ;
	1'bx: begin
	   valid_cycleA = 1;
	   read_memA(0,1);
	end
      endcase
   end
   endtask
      
   task mem_cycleB;
   begin
      valid_cycleB = 1'bx;
      casez(CENBi)
     	1'b0: begin
	   valid_cycleB = 0;
	   write_mem(ABi,DBi);
	end
        1'b1: ;
        1'bx: begin
	   valid_cycleB = 0;
	   write_mem_x(ABi);
	end
      endcase
   end
   endtask
      
   task contentionA;
   begin
      casez(valid_cycleB)
	1'bx: ;
	1'b0:begin
	   read_memA(0,1);
	end
	1'b1: ;
      endcase
   end
   endtask

   task contentionB;
   begin
      casez(valid_cycleA)
	1'bx: ;
	1'b1:begin
	   read_memA(0,1);
	end
	1'b0: ;
      endcase
   end
   endtask

   task latch_Ainputs;
   begin
      LATCHED_AA = _AA ;
      LATCHED_CENA = _CENA ;
      LAST_QAi = QAi;
   end
   endtask

   task latch_Binputs;
   begin
      LATCHED_AB = _AB ;
      LATCHED_DB = _DB ;
      LATCHED_CENB = _CENB ;
   end
   endtask

   task update_Alogic;
      integer n;
   begin
      CENAi = LATCHED_CENA;
      AAi = LATCHED_AA;
   end
   endtask

   task update_Blogic;
      integer n;
   begin
      CENBi = LATCHED_CENB;
      ABi = LATCHED_AB;
      DBi = LATCHED_DB;
   end
   endtask

   task read_memA;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(AAi))
	       begin
	          QAi=mem[AAi];
	       end
	    else
	       begin
		  QAi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  QAi=wordx;
	       end
	    else
	       begin
	          QAi=QAi;
	       end
	 end
   end
   endtask


   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
					 x_mem;
			     end
	1'b1: begin
					 mem[a]=d;
			      end
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
					 x_mem;
			     end
	1'b1: begin
					 mem[a]=wordx;
			      end
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask

   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction

   always @(QAi) begin
     QA <= QAi;
   end
   assign _AA = AA;
   assign _CLKA = CLKA;
   assign _CENA = CENA;

   assign _DB = DB;
   assign _AB = AB;
   assign _CLKB = CLKB;
   assign _CENB = CENB;

   always @( _CLKA )
      begin
         casez({LAST_CLKA,_CLKA})
	   2'b01: begin
	      latch_Ainputs;
	      update_Alogic;
	      mem_cycleA;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
              read_memA(0,1);
	   end
	   
	 endcase
	 LAST_CLKA = _CLKA;
      end

   always @( _CLKB )
      begin
         casez({LAST_CLKB,_CLKB})
	   2'b01: begin
	      latch_Binputs;
	      update_Blogic;
	      mem_cycleB;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
	   end
	   
	 endcase
	 LAST_CLKB = _CLKB;
      end
//synopsys translate_on
endmodule

// Dedicated read and write single port register file with bit mask
module SPRFBM (
   QA,
   AA,
   CLKA,
   CENA,
   WENB,
   AB,
   DB,
   CLKB,
   CENB
);
   parameter		   BITS = 32;
   parameter		   word_depth = 32;
   parameter		   addr_width = 5;
   parameter               mask_width = 2 ;
   parameter               wp_size    = BITS-1 ;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   // surefire lint_off UDDIDN UDDONU UDDICN UDDONN
   output [BITS-1:0] QA;
   input [addr_width-1:0] AA;
   input CLKA;
   input CENA;
   input [mask_width-1:0] WENB;
   input [addr_width-1:0] AB;
   input [BITS-1:0] DB;
   input CLKB;
   input CENB;
   // surefire lint_on UDDIDN UDDONU UDDICN UDDONN

   //synopsys translate_off
  `ifdef MEMPWR
   // This is used for memory power estimation. Do NOT remove. - Yoichiro
   reg [addr_width-1:0] AAQ, ABQ;
   reg [BITS-1:0] 	DAQ, DBQ;
   reg [mask_width-1:0] WENBQ;
   wire 		AIA = CENA & (AAQ!==AA);
   wire 		AIB = CENB & (ABQ!==AB);
   wire 		DIA = 1'b0;
   wire 		DIB = CENB & (DBQ!==DB);
   wire 		WIA = 1'b0;
   wire 		WIB = CENB & (WENBQ!==WENB);
   initial $display ("MEMPWR SPRFBM: %m(A) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, mask_width);
   initial $display ("MEMPWR SPRFBM: %m(B) A: %d W: %d D: %d M: %d", addr_width, word_depth, BITS, mask_width);
   always @(posedge CLKA) begin
      $display ("MEMPWR SPRFBM: %m(A) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENA,1'b0,AIA,DIA,WIA,(AIA|DIA|WIA), $time);
      AAQ <= AA;
   end
   always @(posedge CLKB) begin
      $display ("MEMPWR SPRFBM: %m(B) CEN: %b WEN: %b AI: %b DI: %b WI: %b TI: %b (%d)",
		CENB,&WENB,AIB,DIB,WIB,(AIB|DIB|WIB), $time);
      ABQ   <= AB;
      DBQ   <= DB;
      WENBQ <= WENB;
   end
  `endif

   reg [BITS-1:0]	   mem [word_depth-1:0];

   wire [addr_width-1:0]   _AA;
   wire [addr_width-1:0]   _AB;
   wire			   _CLKA;
   wire			   _CLKB;
   wire			   _CENA;

   wire [mask_width-1:0]   _WENB;

   wire			   _CENB;
   wire [BITS-1:0]         _DB;

   reg			   LATCHED_CENA;

   reg  [mask_width-1:0]  LATCHED_WENB;

   reg			   LATCHED_CENB;
   reg [addr_width-1:0]	   LATCHED_AA;
   reg [addr_width-1:0]	   LATCHED_AB;
   reg [BITS-1:0]	   LATCHED_DB;

   reg			   CENAi;
   reg			   CENBi;

   reg [mask_width-1:0]    WENBi;

   reg [addr_width-1:0]	   AAi;
   reg [addr_width-1:0]	   ABi;
   reg [BITS-1:0]	   DBi;
   reg [BITS-1:0]	   QAi;
   reg [BITS-1:0]	   QA;
   reg [BITS-1:0]	   LAST_QAi;



   reg			   LAST_CLKA;
   reg			   LAST_CLKB;

   reg                     valid_cycleA;
   reg                     valid_cycleB;


   task mem_cycleA;
   begin
      valid_cycleA = 1'bx;
      casez({CENAi})
	1'b0: begin
	   valid_cycleA = 1;
	   read_memA(1,0);
	end
	1'b1: ;
	1'bx: begin
	   valid_cycleA = 1;
	   read_memA(0,1);
	end
      endcase
   end
   endtask
      
   task mem_cycleB;
   begin
      valid_cycleB = 1'bx;
      casez(CENBi)
     	1'b0: begin
	   valid_cycleB = 0;
	   write_mem(ABi,DBi);
	end
        1'b1: ;
        1'bx: begin
	   valid_cycleB = 0;
	   write_mem_x(ABi);
	end
      endcase
   end
   endtask
      

   task latch_Ainputs;
   begin
      LATCHED_AA = _AA ;
      LATCHED_CENA = _CENA ;
      LAST_QAi = QAi;
   end
   endtask

   task latch_Binputs;
   begin
      LATCHED_AB = _AB ;
      LATCHED_DB = _DB ;
      LATCHED_CENB = _CENB ;
      LATCHED_WENB = _WENB ;
   end
   endtask

   task update_Alogic;
      integer n;
   begin
      CENAi = LATCHED_CENA;
      AAi = LATCHED_AA;
   end
   endtask

   task update_Blogic;
      integer n;
   begin
      WENBi = LATCHED_WENB;
      CENBi = LATCHED_CENB;
      ABi = LATCHED_AB;
      DBi = LATCHED_DB;
   end
   endtask

   task read_memA;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(AAi))
	       begin
	          QAi=mem[AAi];
	       end
	    else
	       begin
		  QAi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  QAi=wordx;
	       end
	    else
	       begin
	          QAi=QAi;
	       end
	 end
   end
   endtask

   task read_x;
      integer n;
      integer i;
      integer lsb;
      integer msb;
      begin
	 for (n=0; n<mask_width; n=n+1)
	 begin
            lsb = n*(wp_size) ;
            msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
	    casez({WENBi[n]})
	      1'b0,
	      1'bx: begin
                 for (i=lsb; i<=msb; i=i+1)
		 begin
		    QAi[i] = 1'bx ;
		 end
              end
	      1'b1 : ;
	    endcase
	 end
      end
   endtask // read_x

   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
      integer i, n, lsb, msb ;
      reg [BITS-1:0] dummy;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
		                for (n=0; n<mask_width; n=n+1)
		  begin
			casez({WENBi[n]})
			 	1'b0, 1'bx : x_partial_mem(n) ;
				1'b1       : ;
			endcase
		  end
			     end
	1'b1: begin
		                for (n=0; n<mask_width; n=n+1)
		  begin
                        lsb = n*(wp_size) ;
                        msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
			casez({WENBi[n]})
			 	1'b0 : begin
				          dummy= mem[a];
                			  for (i=lsb; i<=msb; i=i+1)  dummy[i] = d[i] ;
                			  mem[a]=dummy;
                                       end
				1'b1 : ;
				1'bx : begin
					  dummy = mem[a] ;
                			  for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
                			  mem[a]=dummy;
                                       end
			endcase
		  end
			      end
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
      integer i, n, lsb, msb ;
      reg [BITS-1:0] dummy;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
		                for (n=0; n<mask_width; n=n+1)
		  begin
			casez({WENBi[n]})
			 	1'b0, 1'bx : x_partial_mem(n) ;
				1'b1       : ;
			endcase
		  end
			     end
	1'b1: begin
		                for (n=0; n<mask_width; n=n+1)
		  begin
                        lsb = n*(wp_size) ;
                        msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
			casez({WENBi[n]})
			 	1'b0 , 1'bx : begin
				          dummy= mem[a];
                			  for (i=lsb; i<=msb; i=i+1)  dummy[i] = 1'bx ;
                			  mem[a]=dummy;
                                       end
				1'b1 : ;
			endcase
		  end
			      end
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask

   task x_partial_mem;
      input [63:0] section ;
      integer i, n;
      integer lsb, msb ;
      reg [BITS-1:0] dummy ;
      
   begin
       lsb = (section)*(wp_size) ;
       msb = BITS <= (lsb+wp_size-1) ? (BITS-1) : (lsb+wp_size-1) ;
       for (n=0; n<word_depth; n=n+1)
          begin
		dummy = mem[n];	
         	for (i=lsb; i<=msb; i=i+1)
			dummy[i] = 1'bx;	
                mem[n]=dummy ;
	  end
   end
   endtask

   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction

   always @(QAi) begin
     QA <= QAi;
   end
   assign _AA = AA;
   assign _CLKA = CLKA;
   assign _CENA = CENA;
   assign _DB = DB;
   assign _AB = AB;
   assign _CLKB = CLKB;
   assign _CENB = CENB;
   assign _WENB = WENB;


   always @( _CLKA )
      begin
         casez({LAST_CLKA,_CLKA})
	   2'b01: begin
	      latch_Ainputs;
	      update_Alogic;
	      mem_cycleA;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
              read_memA(0,1);
	   end
	   
	 endcase
	 LAST_CLKA = _CLKA;
      end

   always @( _CLKB )
      begin
         casez({LAST_CLKB,_CLKB})
	   2'b01: begin
	      latch_Binputs;
	      update_Blogic;
	      mem_cycleB;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
	   end
	   
	 endcase
	 LAST_CLKB = _CLKB;
      end

//synopsys translate_on
endmodule


module memrqarb(/*AUTOARG*/
   // Outputs
   Rdy4Txn, RdRdy, RdData, MemCen, MemWen, MemAddr, MemWrData, 
   // Inputs
   clk, reset, freeze, RdEn, RdAddr, WrEn, WrAddr, WrData, 
   PriCntrVld, PriCntr, BlkCen, BlkWen, BlkAddr, BlkWrData, 
   MemRdData
   );

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 16;
parameter CNTR_WIDTH = 5;

input			     clk;
input			     reset;
input			     freeze;
// pci
input			     RdEn;
input   [ADDR_WIDTH-1:0]     RdAddr;
input			     WrEn;
input   [ADDR_WIDTH-1:0]     WrAddr;
input   [DATA_WIDTH-1:0]     WrData;
input			     PriCntrVld; // surefire lint_off_line UDDICU
input	[CNTR_WIDTH-1:0]     PriCntr; // surefire lint_off_line UDDINU UDDICU
// regular
input			     BlkCen;
input			     BlkWen; // surefire lint_off_line UDDICU
input	[ADDR_WIDTH-1:0]     BlkAddr;
input   [DATA_WIDTH-1:0]     BlkWrData; // surefire lint_off_line UDDINU
// SRAM
input	[DATA_WIDTH-1:0]     MemRdData;
// outputs
output			     Rdy4Txn;
output			     RdRdy;
output  [DATA_WIDTH-1:0]     RdData;
// SRAM
output			     MemCen;
output			     MemWen;
output  [ADDR_WIDTH-1:0]     MemAddr;
output  [DATA_WIDTH-1:0]     MemWrData;

wire	[ADDR_WIDTH-1:0]     NewCpuAddr;
wire	[ADDR_WIDTH-1:0]     CpuAddr;
wire			     NewCpuEn;
wire	[DATA_WIDTH-1:0]     NewCpuData;
wire	[DATA_WIDTH-1:0]     CpuData;
wire			     CpuWrClr;
wire			     CpuRdClr;
wire	[CNTR_WIDTH-1:0]     CpuCntr;
wire	[CNTR_WIDTH-1:0]     DecCpuCntr;
wire	[CNTR_WIDTH-1:0]     NewPriCntr;
wire			     CntExp;
wire			     CpuReq;
wire			     CpuGrant;
wire			     NewWrVal;
wire			     NewRdVal;
wire			     wrhold;
wire			     rdhold;
wire			     CpuWrEn;
wire			     CpuRdEn;
wire			     stopwr;

assign NewCpuAddr = RdEn ? RdAddr : WrAddr;
assign NewCpuEn   = RdEn | WrEn;
assign NewCpuData = WrData;

// hold addr, Data, Wr/Rd, Priority Cnt
EDFFR #(ADDR_WIDTH) DFF0 (
		.d(NewCpuAddr),
		.q(CpuAddr),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

EDFFR #(DATA_WIDTH) DFF1 (
		.d(NewCpuData),
		.q(CpuData),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

assign wrhold = ~WrEn & ~CpuWrClr;
assign NewWrVal = (WrEn & 1'b1) |
		  (CpuWrClr & 1'b0) |
		  (wrhold & CpuWrEn);
DFFR #(1) DFF2 (.d(NewWrVal), .q(CpuWrEn), .reset(reset), .clk(clk));
assign rdhold = ~RdEn & ~CpuRdClr;
assign NewRdVal = (RdEn & 1'b1) |
		  (CpuRdClr & 1'b0) |
		  (rdhold & CpuRdEn);
DFFR #(1) DFF3 (.d(NewRdVal), .q(CpuRdEn), .reset(reset), .clk(clk));

assign DecCpuCntr = {CpuCntr - 1'b1};
assign NewPriCntr = (PriCntr & {CNTR_WIDTH{NewCpuEn}}) |
		    (DecCpuCntr & {CNTR_WIDTH{~NewCpuEn}}) ;
DFFR #(CNTR_WIDTH) DFF4 (.d(NewPriCntr),.q(CpuCntr),.reset(reset),.clk(clk));
assign CntExp = CpuCntr == {CNTR_WIDTH{1'b0}};

assign CpuReq = CpuWrEn | CpuRdEn;
assign CpuGrant = CpuReq & (BlkCen | (CntExp & PriCntrVld));
assign CpuWrClr = CpuWrEn & CpuGrant;
assign CpuRdClr = CpuRdEn & CpuGrant;
assign Rdy4Txn = ~CpuReq;

// generate SRAM request
assign MemWrData = CpuGrant ? CpuData : BlkWrData;
assign MemAddr = CpuGrant ? CpuAddr : BlkAddr;
assign MemWen =  (CpuGrant ? ~CpuWrEn : BlkWen) | stopwr;
assign MemCen =  ~CpuGrant & BlkCen;

DFFR #(1) DFF5 (.d(CpuRdClr),.q(RdRdy),.reset(reset),.clk(clk)); 
assign RdData = MemRdData;
DFFR #(1) DFF6 (.d(freeze), .q(stopwr), .reset(reset),.clk(clk));

endmodule

module rfreqarb (/*AUTOARG*/
   // Outputs
   Rdy4Txn, RdRdy, RdData, MemWen, MemRen, MemWAddr, MemRAddr, 
   MemWrData, 
   // Inputs
   clk, reset, freeze, RdEn, RdAddr, WrEn, WrAddr, WrData, 
   PriCntrVld, PriCntr, BlkWen, BlkRen, BlkWAddr, BlkRAddr, 
   BlkWrData, MemRdData
   );

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 16;
parameter CNTR_WIDTH = 5;

input			     clk;
input			     reset;
input			     freeze;
// pci
input			     RdEn;
input   [ADDR_WIDTH-1:0]     RdAddr;
input			     WrEn;
input   [ADDR_WIDTH-1:0]     WrAddr;
input   [DATA_WIDTH-1:0]     WrData;
input			     PriCntrVld;
input	[CNTR_WIDTH-1:0]     PriCntr;
// regular
input			     BlkWen;
input			     BlkRen;
input	[ADDR_WIDTH-1:0]     BlkWAddr;
input	[ADDR_WIDTH-1:0]     BlkRAddr;
input   [DATA_WIDTH-1:0]     BlkWrData;
// SRAM
input	[DATA_WIDTH-1:0]     MemRdData;
// outputs
output			     Rdy4Txn;
output			     RdRdy;
output  [DATA_WIDTH-1:0]     RdData;
// SRAM
output			     MemWen;
output			     MemRen;
output  [ADDR_WIDTH-1:0]     MemWAddr;
output  [ADDR_WIDTH-1:0]     MemRAddr;
output  [DATA_WIDTH-1:0]     MemWrData;

wire	[ADDR_WIDTH-1:0]     NewCpuAddr;
wire	[ADDR_WIDTH-1:0]     CpuAddr;
wire			     NewCpuEn;
wire	[DATA_WIDTH-1:0]     NewCpuData;
wire	[DATA_WIDTH-1:0]     CpuData;
wire			     CpuWrClr;
wire			     CpuRdClr;
wire	[CNTR_WIDTH-1:0]     CpuCntr;
wire	[CNTR_WIDTH-1:0]     DecCpuCntr;
wire	[CNTR_WIDTH-1:0]     NewPriCntr;
wire			     CntExp;
wire			     CpuReq;
wire			     CpuGrant;
wire			     NewWrVal;
wire			     NewRdVal;
wire			     wrhold;
wire			     rdhold;
wire			     CpuWrEn;
wire			     CpuRdEn;
wire			     stopwr;

assign NewCpuAddr = RdEn ? RdAddr : WrAddr;
assign NewCpuEn   = RdEn | WrEn;
assign NewCpuData = WrData;

// hold addr, Data, Wr/Rd, Priority Cnt
EDFFR #(ADDR_WIDTH) DFF0 (
		.d(NewCpuAddr),
		.q(CpuAddr),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

EDFFR #(DATA_WIDTH) DFF1 (
		.d(NewCpuData),
		.q(CpuData),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

assign wrhold = ~WrEn & ~CpuWrClr;
assign NewWrVal = (WrEn & 1'b1) |
		  (CpuWrClr & 1'b0) |
		  (wrhold & CpuWrEn);
DFFR #(1) DFF2 (.d(NewWrVal), .q(CpuWrEn), .reset(reset), .clk(clk));
assign rdhold = ~RdEn & ~CpuRdClr;
assign NewRdVal = (RdEn & 1'b1) |
		  (CpuRdClr & 1'b0) |
		  (rdhold & CpuRdEn);
DFFR #(1) DFF3 (.d(NewRdVal), .q(CpuRdEn), .reset(reset), .clk(clk));

assign DecCpuCntr = {CpuCntr - 1'b1};
assign NewPriCntr = (PriCntr & {CNTR_WIDTH{NewCpuEn}}) |
		    (DecCpuCntr & {CNTR_WIDTH{~NewCpuEn}}) ;
DFFR #(CNTR_WIDTH) DFF4 (.d(NewPriCntr),.q(CpuCntr),.reset(reset),.clk(clk));
assign CntExp = CpuCntr == {CNTR_WIDTH{1'b0}};

assign CpuReq = CpuWrEn | CpuRdEn;
assign CpuGrant = CpuReq & ((BlkWen&&BlkRen) | (CntExp & PriCntrVld));
assign CpuWrClr = CpuWrEn & CpuGrant;
assign CpuRdClr = CpuRdEn & CpuGrant;
assign Rdy4Txn = ~CpuReq;

// generate SRAM request
assign MemWrData = CpuGrant ? CpuData : BlkWrData;
assign MemWAddr = CpuGrant ? CpuAddr : BlkWAddr;
assign MemRAddr = CpuGrant ? CpuAddr : BlkRAddr;
assign MemWen =  (CpuGrant ? ~CpuWrEn : BlkWen) | stopwr;
assign MemRen =  (CpuGrant ? ~CpuGrant : BlkRen);

DFFR #(1) DFF5 (.d(CpuRdClr),.q(RdRdy),.reset(reset),.clk(clk)); 
assign RdData = MemRdData;
DFFR #(1) DFF6 (.d(freeze), .q(stopwr), .reset(reset),.clk(clk));

endmodule

module dmemreqarb (/*AUTOARG*/
   // Outputs
   Rdy4Txn, RdRdy, RdData, MemWen, MemRen, MemCWen, MemCRen, 
   MemWAddr, MemRAddr, MemWrData, 
   // Inputs
   clk, reset, freeze, RdEn, RdAddr, WrEn, WrAddr, WrData, 
   PriCntrVld, PriCntr, BlkWen, BlkCWen, BlkRen, BlkCRen, BlkWAddr, 
   BlkRAddr, BlkWrData, MemRdData
   );

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 16;
parameter CNTR_WIDTH = 5;

input			     clk;
input			     reset;
input			     freeze;
// pci
input			     RdEn;
input   [ADDR_WIDTH-1:0]     RdAddr;
input			     WrEn;
input   [ADDR_WIDTH-1:0]     WrAddr;
input   [DATA_WIDTH-1:0]     WrData;
input			     PriCntrVld;
input	[CNTR_WIDTH-1:0]     PriCntr;
// regular
input			     BlkWen;
input			     BlkCWen;
input			     BlkRen;
input			     BlkCRen;
input	[ADDR_WIDTH-1:0]     BlkWAddr;
input	[ADDR_WIDTH-1:0]     BlkRAddr;
input   [DATA_WIDTH-1:0]     BlkWrData;
// SRAM
input	[DATA_WIDTH-1:0]     MemRdData;
// outputs
output			     Rdy4Txn;
output			     RdRdy;
output  [DATA_WIDTH-1:0]     RdData;
// SRAM
output			     MemWen;
output			     MemRen;
output			     MemCWen;
output			     MemCRen;
output  [ADDR_WIDTH-1:0]     MemWAddr;
output  [ADDR_WIDTH-1:0]     MemRAddr;
output  [DATA_WIDTH-1:0]     MemWrData;

wire	[ADDR_WIDTH-1:0]     NewCpuAddr;
wire	[ADDR_WIDTH-1:0]     CpuAddr;
wire			     NewCpuEn;
wire	[DATA_WIDTH-1:0]     NewCpuData;
wire	[DATA_WIDTH-1:0]     CpuData;
wire			     CpuWrClr;
wire			     CpuRdClr;
wire	[CNTR_WIDTH-1:0]     CpuCntr;
wire	[CNTR_WIDTH-1:0]     DecCpuCntr;
wire	[CNTR_WIDTH-1:0]     NewPriCntr;
wire			     CntExp;
wire			     CpuReq;
wire			     CpuGrant;
wire			     NewWrVal;
wire			     NewRdVal;
wire			     wrhold;
wire			     rdhold;
wire			     CpuWrEn;
wire			     CpuRdEn;
wire			     stopwr;

assign NewCpuAddr = RdEn ? RdAddr : WrAddr;
assign NewCpuEn   = RdEn | WrEn;
assign NewCpuData = WrData;

// hold addr, Data, Wr/Rd, Priority Cnt
EDFFR #(ADDR_WIDTH) DFF0 (
		.d(NewCpuAddr),
		.q(CpuAddr),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

EDFFR #(DATA_WIDTH) DFF1 (
		.d(NewCpuData),
		.q(CpuData),
		.en(NewCpuEn),
		.clk(clk),
		.reset(reset));

assign wrhold = ~WrEn & ~CpuWrClr;
assign NewWrVal = (WrEn & 1'b1) |
		  (CpuWrClr & 1'b0) |
		  (wrhold & CpuWrEn);
DFFR #(1) DFF2 (.d(NewWrVal), .q(CpuWrEn), .reset(reset), .clk(clk));
assign rdhold = ~RdEn & ~CpuRdClr;
assign NewRdVal = (RdEn & 1'b1) |
		  (CpuRdClr & 1'b0) |
		  (rdhold & CpuRdEn);
DFFR #(1) DFF3 (.d(NewRdVal), .q(CpuRdEn), .reset(reset), .clk(clk));

assign DecCpuCntr = {CpuCntr - 1'b1};
assign NewPriCntr = (PriCntr & {CNTR_WIDTH{NewCpuEn}}) |
		    (DecCpuCntr & {CNTR_WIDTH{~NewCpuEn}}) ;
DFFR #(CNTR_WIDTH) DFF4 (.d(NewPriCntr),.q(CpuCntr),.reset(reset),.clk(clk));
assign CntExp = CpuCntr == {CNTR_WIDTH{1'b0}};

assign CpuReq = CpuWrEn | CpuRdEn;
assign CpuGrant = CpuReq & ((BlkCWen&&BlkCRen) | (CntExp & PriCntrVld));
assign CpuWrClr = CpuWrEn & CpuGrant;
assign CpuRdClr = CpuRdEn & CpuGrant;
assign Rdy4Txn = ~CpuReq;

// generate SRAM request
assign MemWrData = CpuGrant ? CpuData : BlkWrData;
assign MemWAddr = CpuGrant ? CpuAddr : BlkWAddr;
assign MemRAddr = CpuGrant ? CpuAddr : BlkRAddr;
assign MemWen =  (CpuGrant ? ~CpuWrEn : BlkWen) | stopwr;
assign MemCWen =  (CpuGrant ? ~CpuWrEn : BlkCWen) | stopwr;
assign MemRen =  (CpuGrant ? CpuGrant : BlkRen);
assign MemCRen =  (CpuGrant ? ~CpuGrant : BlkCRen);

DFFR #(1) DFF5 (.d(CpuRdClr),.q(RdRdy),.reset(reset),.clk(clk)); 
assign RdData = MemRdData;
DFFR #(1) DFF6 (.d(freeze), .q(stopwr), .reset(reset),.clk(clk));

endmodule

// ------------------- Parameterizable find first --------------
module findfirst (/*AUTOARG*/
   // Outputs
   PTR, PTR_VLD, 
   // Inputs
   DATA
   );

   parameter DATA_WIDTH = 128;
   parameter PTR_WIDTH  = 7;
   
   input [DATA_WIDTH-1:0] DATA;
   output [PTR_WIDTH-1:0] PTR;
   output 		  PTR_VLD;
   
   reg [PTR_WIDTH-1:0] 	  PTR;
   reg 			  PTR_VLD;
   reg [PTR_WIDTH:0] 	  i;
   
   // surefire lint_off CWECSS CWECSM CWEEBB RNGSZB ASWCBS ASWIBB CWECSB
   always @(/*AS*/DATA) begin
      PTR[PTR_WIDTH-1:0] = {PTR_WIDTH{1'b0}};
      PTR_VLD = 1'b0;
      for (i = 0; i < DATA_WIDTH; i = i + 1)
	if((DATA[i[PTR_WIDTH-1:0]] == 1'b1) && !PTR_VLD) begin
	   PTR[PTR_WIDTH-1:0] = i[PTR_WIDTH-1:0];
	   PTR_VLD = 1'b1;
	end
   end
   // surefire lint_on CWECSS CWECSM CWEEBB RNGSZB ASWCBS ASWIBB CWECSB
endmodule

// ------------------- Parameterizable round robin --------------
// Requires external start_ptr increment and flop
module findvalid (/*AUTOARG*/
   // Outputs
   PTR, PTR_VLD, 
   // Inputs
   DATA, START_PTR
   );

   parameter DATA_WIDTH = 512;
   parameter PTR_WIDTH  = 9;
   
   input [DATA_WIDTH-1:0] DATA;
   input [PTR_WIDTH-1:0]  START_PTR;
   output [PTR_WIDTH-1:0] PTR;
   output 		  PTR_VLD;
   
   reg [PTR_WIDTH:0] 	  i;
   reg [DATA_WIDTH-1:0]   DATASHIFT;
   wire [PTR_WIDTH-1:0]   PTR0;
   wire 		  PTR0_VLD;
   wire [PTR_WIDTH-1:0]   PTR1;
   wire 		  PTR1_VLD;
   wire [PTR_WIDTH-1:0]   PTR;
   wire 		  PTR_VLD;

   // surefire lint_off CWECSS CWECSM CWEEBB RNGSZB ASWCBS ASWIBB CWECSB
   always @(/*AS*/DATA or START_PTR) begin 
      DATASHIFT[DATA_WIDTH-1:0] = DATA[DATA_WIDTH-1:0];
      for (i = 0; i < DATA_WIDTH; i = i + 1)
	if (i < START_PTR) begin
	   DATASHIFT[i] = 1'b0;
	end
   end
   // surefire lint_on CWECSS CWECSM CWEEBB RNGSZB ASWCBS ASWIBB CWECSB
   
   /* findfirst AUTO_TEMPLATE (
    .PTR		(PTR@[PTR_WIDTH-1:0]),
    .PTR_VLD		(PTR@_VLD),
    .DATA		(DATA[DATA_WIDTH-1:0]),
    ); */
   findfirst #(DATA_WIDTH,PTR_WIDTH) u0_findfirst
     (/*AUTOINST*/
      // Outputs
      .PTR				(PTR0[PTR_WIDTH-1:0]),	 // Templated
      .PTR_VLD				(PTR0_VLD),		 // Templated
      // Inputs
      .DATA				(DATA[DATA_WIDTH-1:0]));	 // Templated
   /* findfirst AUTO_TEMPLATE (
    .PTR		(PTR@[PTR_WIDTH-1:0]),
    .PTR_VLD		(PTR@_VLD),
    .DATA		(DATASHIFT[DATA_WIDTH-1:0]),
    ); */
   findfirst #(DATA_WIDTH,PTR_WIDTH) u1_findfirst
     (/*AUTOINST*/
      // Outputs
      .PTR				(PTR1[PTR_WIDTH-1:0]),	 // Templated
      .PTR_VLD				(PTR1_VLD),		 // Templated
      // Inputs
      .DATA				(DATASHIFT[DATA_WIDTH-1:0])); // Templated
   assign PTR[PTR_WIDTH-1:0] = (PTR1_VLD ?
				PTR1[PTR_WIDTH-1:0] :
				PTR0[PTR_WIDTH-1:0]);
   assign PTR_VLD = (PTR1_VLD | PTR0_VLD); 
endmodule // findvalid

module MeuDescriptorDecode (/*AUTOARG*/
   // Outputs
   Length, StartChannel, EOP, 
   // Inputs
   Descriptor, DoubleBuffer, StartChannelLSB
   );

   output [10:0] Length;
   output [3:0]  StartChannel;
   output        EOP;
   
   input [12:0]  Descriptor;
   input 	 DoubleBuffer;
   input 	 StartChannelLSB;
   
   reg 		 EOP;
   reg [10:5] 	 DecLength;
   reg [3:0] 	 StartChannel;
   wire 	 SecondBuffer;	 

   assign SecondBuffer = (DoubleBuffer & Descriptor[12]);
   
   // Determine Length
   always @(/*AS*/Descriptor or SecondBuffer) begin
      casez ({SecondBuffer,Descriptor[11:7]})
	6'b01????, 
	6'b0011?? : DecLength[10:5] = {2'b00,   Descriptor[8:5]}; // 0-511B
	6'b0001??,
	6'b000001 : DecLength[10:5] = {4'b0100, Descriptor[6:5]}; // 512-640B
	6'b?010??,
	6'b?00000 : DecLength[10:5] = {4'b0000, Descriptor[6:5]}; // 0-128 chunks
	6'b?00010,
	6'b?00011 : DecLength[10:5] = 6'b000100; // 128-160 chunks  
	6'b11????, 
	6'b1011?? : DecLength[10:5] = ({2'b00,Descriptor[8:5]} + 5'b10100); // 641-1152B
	6'b1001??,
	6'b100001 : DecLength[10:5] = {4'b1001, Descriptor[6:5]}; // 1153-1280B
	default : DecLength[10:5] = 6'b000000;
      endcase
   end
   
   assign Length[10:0] = {DecLength[10:5],Descriptor[4:0]};

   // Determine StartChannel
   always @(/*AS*/Descriptor or StartChannelLSB) begin
      casez (Descriptor[11:7])
	5'b1???? : StartChannel[3:0] = {1'b0,Descriptor[10:9],StartChannelLSB}; // 0-3
	5'b010??,
	  5'b001?? : StartChannel[3:0] = {1'b0,Descriptor[8:7],StartChannelLSB};  // 0-3
	5'b00010 : StartChannel[3:0] = {1'b0,Descriptor[6:5],StartChannelLSB};  // 0-3
	5'b011??,
	  5'b00001,
	  5'b00000,
	  5'b00011 : StartChannel[3:0] = {3'b100,StartChannelLSB}; // 4
	default : StartChannel[3:0] = 4'b0;
      endcase
   end

   // Determine EOP
   always @(/*AS*/Descriptor) begin
      casez (Descriptor[11:7])
	5'b1????,
	5'b011??,
	5'b001??,
	5'b00001 : EOP = 1'b1; // Length indicates Byte count
	5'b010??,
	  5'b00000,
	  5'b00010,
	  5'b00011 : EOP = 1'b0; // Length indicates packet chunk count
	default : EOP = 1'b1;
      endcase
   end
   
endmodule // MeuDescriptorDecode

module MeuDescriptorEncode (/*AUTOARG*/
   // Outputs
   Descriptor, 
   // Inputs
   Buffer, Length, StartChannel, EOP, DoubleBuffer, FiveChannel
   );

  output [34:0] Descriptor;
  
  input [21:0]  Buffer;
  input [10:0] 	Length;
  input [3:0] 	StartChannel;
  input 	EOP; 		//surefire lint_off_line UDDICU
  input 	DoubleBuffer;
  input 	FiveChannel; 	//surefire lint_off_line UDDIDN
   
  reg  [34:0] 	Descriptor;

  wire 		LengthOver;
  wire [9:0] 	Length640;
  wire 		LengthHigh;
  wire 		ChannelHigh;
  
  /* In DoubleBuffer mode, the incoming length might be greater than
   640 (up to 1280).  In this case, subtract 640, and set descriptor bit[12] */
  assign LengthOver = (Length[10] | (Length[9] & (Length[8] | Length[7])));
  assign Length640[4:0] = Length[4:0]; 
// surefire lint_off ASWEBB
  assign Length640[9:5] = (LengthOver ? (Length[10:5] - 6'b010100) :
			   Length[9:5]);
// surefire lint_on ASWEBB

  assign LengthHigh = (EOP ? Length640[9] : Length640[7]); // Length > 15
  assign ChannelHigh = StartChannel[3];              // Channel > 7

  // Encode Descriptor
  always @(/*AS*/Buffer or ChannelHigh or DoubleBuffer or EOP
	   or Length640 or LengthHigh or LengthOver or StartChannel) begin
     Descriptor[34]    = StartChannel[0];
     Descriptor[33:13] = Buffer[21:1];
     Descriptor[12]    = ((DoubleBuffer)? LengthOver :
			  Buffer[0]);
     Descriptor[4:0]   = Length640[4:0];
  
      casez ({EOP,LengthHigh,ChannelHigh})
	3'b100 : Descriptor[11:5] = {1'b1, StartChannel[2:1],        Length640[8:5]};
	3'b110 : Descriptor[11:5] = {1'b0, 2'b01, StartChannel[2:1], Length640[6:5]};
	3'b101 : Descriptor[11:5] = {1'b0, 2'b11,                    Length640[8:5]};
	3'b111 : Descriptor[11:5] = {1'b0, 2'b00, 2'b01,             Length640[6:5]};
	3'b000 : Descriptor[11:5] = {1'b0, 2'b10, StartChannel[2:1], Length640[6:5]};
	3'b010 : Descriptor[11:5] = {1'b0, 2'b00, 2'b10,             StartChannel[2:1]};
	3'b001 : Descriptor[11:5] = {1'b0, 2'b00, 2'b00,             Length640[6:5]}; 
	3'b011 : Descriptor[11:5] = {1'b0, 2'b00, 2'b11,             2'b00};
	default : Descriptor[11:5] = {1'b0, 2'b00, 2'b00,             2'b00}; // This is fully decoded, so it should never get here.
      endcase
  end

  
endmodule // MeuDescriptorEncode

module DivByFive (/*AUTOARG*/
   // Outputs
   Quotient, Remainder, 
   // Inputs
   Dividend
   );
   output       Quotient;
   output [2:0] Remainder;
   
   input [3:0] 	Dividend;
   
   wire [3:0] 	Intermediate;
   wire 	Overflow;
   
   assign Intermediate[3:0] = {Dividend[3:0] - 3'd5};
   assign Overflow  = Intermediate[3];
   
   assign Remainder[2:0] = (Overflow ? Dividend[2:0] : Intermediate[2:0]);
   assign Quotient = ~Overflow;
endmodule // DivByFive


// Eight bit Divide by Five
// Input assumed to be less than 144
module DivByFive8 (/*AUTOARG*/
   // Outputs
   Quotient, 
   // Inputs
   Dividend, Clk, Reset
   );
   output [4:0] Quotient;
   input [7:0] 	Dividend;
   input 	Clk;
   input 	Reset;

   wire [2:0]	Remainder4;
   wire [2:0]	Remainder3;
   wire [2:0]	Remainder3_1;
   wire [2:0]	Remainder2;
   wire [2:0]	Remainder1;
   wire [2:0]	Remainder0;
   wire [4:3] 	Quotient_0;
   wire [2:0] 	Dividend_1;
   
   DivByFive U4_dbf
     (.Dividend(Dividend[7:4]),
      .Quotient(Quotient_0[4]),
      .Remainder(Remainder4[2:0]));
   DivByFive U3_dbf
     (.Dividend({Remainder4[2:0],Dividend[3]}),
      .Quotient(Quotient_0[3]),
      .Remainder(Remainder3[2:0]));

   DFFR #(8,{8{1'b0}}) Div5_dff (.q({Quotient[4:3],  Remainder3_1[2:0],Dividend_1[2:0]}),
		      .d({Quotient_0[4:3],Remainder3[2:0],  Dividend[2:0]}),
		      .clk(Clk),
		      .reset(Reset));

   DivByFive U2_dbf
     (.Dividend({Remainder3_1[2:0],Dividend_1[2]}),
      .Quotient(Quotient[2]),
      .Remainder(Remainder2[2:0]));
   DivByFive U1_dbf
     (.Dividend({Remainder2[2:0],Dividend_1[1]}),
      .Quotient(Quotient[1]),
      .Remainder(Remainder1[2:0]));
   DivByFive U0_dbf
     (.Dividend({Remainder1[2:0],Dividend_1[0]}),
      .Quotient(Quotient[0]),
      .Remainder(Remainder0[2:0]));

endmodule
		 
// HALFSYNC
// *Complaints to: Eric Masson
// *module transfers d of domain clkin into q of domain clkout
// *module assumes d is glitch free or flopped output and retimes d only twice,
//  only one clock needs to be given (the output clock).
// *d must last at least two clock cycles if frequency clkin
//  is equal to frequency of clkout.
// *there are no resets to any of the flops in this module

module HALFSYNC(
   // Outputs
   q, 
   // Inputs
   clk, d
   );

   parameter BusWidth=1;              // the bus width of data to sync up

   input  clk;                        // desired output clock domain
   input  [BusWidth-1:0] d;           // input data to synchronize

   output [BusWidth-1:0] q;           // synchronized data 

   wire   [BusWidth-1:0] stage1; 
   wire   [BusWidth-1:0] q;

   DFF #(BusWidth) U_DFF1 (.q(stage1), .d(d),      .clk(clk));
   DFF #(BusWidth) U_DFF2 (.q(q),      .d(stage1), .clk(clk)); 

endmodule // HALFSYNC

// FULLSYNC
// *Complaints to: Eric Masson
// *module transfers d of domain clkin into q of domain clkout
// *module does not assume d is glitch free or flopped output (has 3 stages),
//  both incoming and outgoing clocks must be given.
// *d must last at least two clock cycles if frequency clkin
//  is equal to frequency of clkout.
// *there are no resets to any of the flops in this module

module FULLSYNC(
   // Outputs
   q, 
   // Inputs
   clkin, clkout, d
   );

   parameter BusWidth=1;             // the bus width of the data to sync up

   input  clkin;                     // clock domain for input d
   input  clkout;                    // clock domain for output q
   input  [BusWidth-1:0] d;          // data to be synced 

   output [BusWidth-1:0] q;          // synced up data

   wire   [BusWidth-1:0] stage1;
   wire   [BusWidth-1:0] q;

   DFF      #(BusWidth) U_DFF     (.q(stage1),  .d(d),      .clk(clkin));
   HALFSYNC #(BusWidth) U_HALFSYNC(.q(q),       .d(stage1), .clk(clkout));
   
endmodule // FULLSYNC

// RESETSYNC
//
// *Complaints to: Eric Masson
//
// *The intent of this macro is to have a unique reset synchronization
//  macro that is differentiable to other macros in the design when some
//  processing must be done. Furthermore, if changes need to be done
//  then they can be localized to one place.
//
//  There are two global contexts in which this macro may be used: 
//
//     (a) If the subdesign uses flops with synchronous resets (current default)
//     (b) If the subdesign uses flops with asynchronous resets
//
//  The following details the two parameters you may need to pass under
//  the various scenarios: ClockCrossing and Strech. 
// 
//  Under all circumstances this macro assumes resets are ACTIVE LOW.
//
//  The clock input is always relative to the clock domain of the output
//  reset (syncreset).
//
//  Test enable is no longer an input to the module, it is assumed the
//  tool vendor will automatically place this signal.
//
//  -----------------------------------
//  With synchronously resetable flops:    (Teradiant Default -- NEW)
//  -----------------------------------
//      
//  parameter [0:0] ClockCrossing = 1'b0 or 1'b1
//
//  When this parameter is set to zero then the synchronization macro
//  defaults to a single flop and should be used to retime resets along
//  the reset tree. This is the case that should be used when retiming
//  the reset in the same clock domain at the input of your module. This
//  is the default setting.
//
//  Set the ClockCrossing parameter to 1'b1 if you are synchronizing resets
//  across clock domains. In this case the reset signal is passed across 
//  at least three flops to be synchronized across clock domains before 
//  it is used. No gate is placed on the outgoing synchronized reset signal.
//  The chain of synchronization flops can be made longer by passing a 
//  non-zero value on the Strecth parameter. In that case the length
//  of the synchronization chain becomes: 3+Stretch. The default for stretch
//  is zero. Use a value greater than zero if you want to strech the reset
//  in the other clock domain or if you want to reduce the probability
//  of metastability even further more.
//
// ------------------------------------
// With Asynchronously resetable flops:   (No longer the default)
// ------------------------------------
//
// The parameters ClockCrossing and Stretch convey the same meaning
// as before and once again Stretch is only significant if ClockCrossing 
// is asserted. If clock Crossing is not asserted then a simple asynchonously
// resetable flop is used.
//
// In this case the macro is used to generate a rising edge synchronous
// resets across the design. In this particular usage, the ouput is
// ANDED with the raw incoming active low reset. Also
// the flops in the chain are all reset with the incoming asynchronous reset.
//
// ---
// ETC
// ---
//
// NOTE: The parameter FlopsAsync should not be changed by the end user
//       unless there is a very rare situation in which the reset is
//       different than the company wide directive of synchronous resets
//       (PCI interfaces, IOs, etc). This parameter determines if the 
//       
// NOTE: There no longer is a testenable input to the macro since the field is 
//       assumed to be automatically placed by the Mentor tools.
//  

module RESETSYNC(/*AUTOARG*/
   // Outputs
   syncreset, 
   // Inputs
   inreset, clk
   );

parameter [0:0] ClockCrossing= 1'b0; // Determines if clock domain is crossed
parameter       Stretch      = 0;    // Determines if reset is stretched

// Do not set these parameters unless you are absolutely certain you should
parameter [0:0] FlopsAsync = 1'b0;  // determines if flops have async resets
parameter Links = Stretch*ClockCrossing + ClockCrossing*2;

////// input   testenable; // set high during scan test, low otherwise
input   inreset;     // incoming reset
input   clk;         // clock domain of output reset
output  syncreset;   // outgoing synchronized reset

reg  [Links:0] flopchain, shift;
integer i;

// surefire lint_off ASWIMB ALWMTR 
always @(/*AS*/flopchain or inreset)
begin
    shift[Links] = inreset;
    for (i=0; i<Links; i=i+1) shift[i]=flopchain[i+1]; 
end 
// surefire lint_on  ASWIMB ALWMTR

wire areset = ~FlopsAsync[0] | inreset; 

always @(posedge clk or negedge areset )
begin
   if (areset==1'b0) flopchain <= {Links+1{1'b0}};
   else              flopchain <= shift;
end

assign syncreset=flopchain[0] & (inreset |~FlopsAsync[0] |~ClockCrossing[0]);
       // | testenable;

endmodule // RESETSYNC

//
// SPIRESETGEN: SPI interface reset generator
//
// The purpose of this macro is to stretch the reset so that power
// up and down can be used arbitrarily on the LVDS macros of a live
// system. Reset for the SPI4 domain becomes CoreClk & PortVld .
// The reset should be stretched long enough after activation of port 
// valid so that clean fast domain clocks have time to reach
// the fast clock domain logic after the reactivation of the LVDS macros.
//
// The output reset (SPIRESET) of this macro should be used to reset 
// the SPI 4 fast clock domain. The COREAFIFORESET signal should be used
// to reset the core clock domain of ASYNC FIFOs to SPI4 domain.
//
// The following are input: 
//
//          CORECLK     Core clock 
//          SPICLK      SPI 4.2 clock
//          CORERESET   Core reset
//          PORTVLD     Port valid signal
// 
// Two parameters are expected:
//
//          stretch_width =   8   Width for counting the stretch
//          stretch_count = 255   Stretch of reset in core clock cycles
//
// Currently the reset is stretched 255 clock cycles. This exceeds
// the traning logic reset time as well as the small element of parser logic
// in the fast clock domain.  This is also well within the margin of the
// LVDS macro warm up time (less than 1ns). Other unit will need
// to pass their own parameter if the need be.
//
// At this point in time the macro expects to be in an entirely 
// synchronous reset domain for both clock domains.
//
// THE STRETCHED RESET FROM THIS MACRO SHOULD NOT BE USED TO POWER DOWN
// THE LVDS PINS! AN UNSTRETCHED PORT VALID SHOULD BE USED TO POWER
// UP AND DOWN THE LVDS MACROS, THE LVDS MACROS DON'T HAVE A RESET.
//

module SPIRESETGEN(CORECLK, 
                   SPICLK, 
                   CORERESET, 
                   PORTVLD, 
                   SPIRESET, 
                   COREAFIFORESET);

parameter  stretch_width = 8;
parameter [stretch_width-1:0] stretch_count = 8'hFF;

input CORECLK;      // core clock
input SPICLK;       // SPI 4.2 clock
input CORERESET;    // core reset
input PORTVLD;      // port valid signal

output SPIRESET;        // SPI4.2 reset
output COREAFIFORESET;  // Async FIFO core clock reset

// internal signals
wire portvld;                    // port valid
reg  [stretch_width-1:0] countD; // D input to stretch counter
wire [stretch_width-1:0] countQ; // Q output to stretch counter
wire resetQ;                     // a retimed reset signal 
wire saturated;                  // count has reached stretch count
wire spi_reset;                  // spi reset signal before retime

///////////////////////
// Retime the inputs //
///////////////////////

DFF  #(1) U_DFF1   (.clk(CORECLK), .d(PORTVLD), .q(portvld));
RESETSYNC U_retime (.clk(CORECLK), .inreset(CORERESET), .syncreset(resetQ));

/////////////////////////
// Calculate the reset //
/////////////////////////

assign saturated= countQ==stretch_count;

always @(countQ or portvld or saturated)
   if      (!portvld)   countD= {stretch_width{1'b0}};
   else if (!saturated) countD= {countQ + 1'b1};
   else                 countD=  countQ;

DFFR #(stretch_width,{stretch_width{1'b0}}) U_DFF2 
      (.clk(CORECLK), 
       .reset(CORERESET), 
       .d(countD),
       .q(countQ));

////////////////////
// FIRE UP RESETS //
////////////////////

assign spi_reset= resetQ & saturated;

RESETSYNC U_afifo (.clk(CORECLK), 
                   .inreset(spi_reset), 
                   .syncreset(COREAFIFORESET));

RESETSYNC #(1'b1, 1) U_spi42 (.clk(SPICLK), 
                             .inreset(spi_reset),
                             .syncreset(SPIRESET));

endmodule


// *SAMPLEBUSIN
// *Complaints to: Eric Masson
// *Samples a bus of size width every period clock cycles and produces 
//  a level change in the SAMPLELEVEL signal 180 out of phase with input 
//  sampling time.
//  The bus is initalized with the value reset_val.
//  A fourth parameter is required beyond with and period, the number
//  of bits needed to encode the period in binary: period_width.
// *Choose period to be an even number to keep things simple for yourself.

module SAMPLEBUSIN(/*AUTOARG*/
   // Outputs
   Q, SAMPLELEVEL, 
   // Inputs
   CLK, RST, D
   );

   parameter width                 = 1;  // bus width
   parameter [width-1:0] reset_val = 0;  // the reset value of the bus
   parameter period                = 8;  // sampling period in clock cycles
   parameter period_width          = 3;  // ceiling(log2(period))

   // internal parameters
   parameter  period_width_less_1  = period_width-1;
   parameter [period_width_less_1:0] max_count       = period-1;
   parameter [period_width_less_1:0] half_max_count  = period>>1;

   input              CLK;
   input              RST;
   input  [width-1:0] D;
   output [width-1:0] Q;
   output             SAMPLELEVEL;

   wire [period_width_less_1:0] countS;
   wire [period_width_less_1:0] countC;

   assign countC = {countS + {{period_width_less_1{1'b0}},1'b1}};

   // reset value must be all zeroes 
   DFFR #(period_width, {period_width{1'b0}}) U_DFFR0 (.q(countS), 
                                                       .d(countC), 
                                                       .clk(CLK), 
                                                       .reset(RST));

   wire sample_level = countS==half_max_count[period_width-1:0] ^ SAMPLELEVEL; 

   DFFR #(1,1'b0) U_DFFR1 (.q(SAMPLELEVEL), 
                           .d(sample_level), 
                           .clk(CLK),
                           .reset(RST));

   wire load = countS=={period_width{1'b0}};

   // load even during reset since count is reset to 0
   EDFFR #(width, reset_val[width-1:0]) U_EDFFR0(
                         .q(Q),
                         .d(D),
                         .en(load),
                         .clk(CLK),
                         .reset(RST));

endmodule // SAMPLEBUSIN

// *SAMPLEBUSOUT
// *Complaints to: Eric Masson
// *Loads in a bus from an incoming clock domain when a transition is
//  detect on the sample level signal.

module SAMPLEBUSOUT(/*AUTOARG*/
   // Outputs
   Q, 
   // Inputs
   CLK, RST, D, SAMPLELEVEL
   );

   parameter  width = 1;
   parameter [width-1:0] reset_val = 0;
  
   input  CLK;
   input  RST; 
   input  [width-1:0] D;
   input  SAMPLELEVEL;

   output [width-1:0] Q;

   wire sample_level;

   DFFR #(1,1'b0) U_DFFR1 (.q(sample_level), 
                           .d(SAMPLELEVEL), 
                           .clk(CLK),
                           .reset(RST));

   wire load= SAMPLELEVEL ^ sample_level;

   EDFFR #(width, reset_val[width-1:0]) U_EDFFR0(
                 .q(Q),
                 .d(D),
                 .en(load),
                 .clk(CLK),
                 .reset(RST));
 
endmodule // SAMPLEBUSOUT

// *BUSSYNC
// *Complaints to: Eric Masson
// *Samples a bus of size width every period clock cycles in the input 
//  clock domain and produces an output sampling  signal 180
//  out of phase with the input. The bus in synched into the CLKOUT domain 
//  and sampled only when a transition is detected on the SAMPLOUT signal. 
//  Therefore  period should be chosen so that holding an input for half a 
//  period in the input clock domain is sufficient to synchronize in the output
//  clock domain. Four parameters need to be passed: the width of the bus,
//  the reset value reset_val of the bus, the sampling period in input
//  clock cycles and the number of bits needed to encode the period: 
/// #(width, reset_val, period, period_width).

module BUSSYNC(/*AUTOARG*/
   // Outputs
   Q, 
   // Inputs
   CLKIN, CLKOUT, RSTIN, RSTOUT, D
   );

   parameter width                 = 1;  // bus width
   parameter [width-1:0] reset_val = 0;  // reset value of bus on output only
   parameter period                = 8;  // sampling period in clock cycles
   parameter period_width          = 3;  // ceiling(log2(period))

   input CLKIN;    // input clock
   input CLKOUT;   // output clock domain
   input RSTIN;    // reset in the input clock domain
   input RSTOUT;   // reset in output clock domain
   input [width-1:0] D; // the input data bus

   output [width-1:0] Q; // the output data bus in the clkout domain

   wire SAMPLELEVEL_1;
   wire [width-1:0] Q_1;

     SAMPLEBUSIN #(width, reset_val[width-1:0], period, period_width)
   U_SAMPLEBUSIN 
              (.Q(Q_1), 
               .SAMPLELEVEL(SAMPLELEVEL_1), 
               .CLK(CLKIN), 
               .RST(RSTIN), 
               .D(D));

   wire SAMPLELEVEL_2;
   wire [width-1:0] Q_2;

   HALFSYNC #(width+1) U_HALFSYNC(
   .q({SAMPLELEVEL_2,Q_2}), 
   .clk(CLKOUT),
   .d({SAMPLELEVEL_1,Q_1}));

   SAMPLEBUSOUT #(width, reset_val[width-1:0]) U_SAMPLEBUSOUT
       (.Q(Q), 
        .CLK(CLKOUT), 
        .RST(RSTOUT), 
        .D(Q_2), 
        .SAMPLELEVEL(SAMPLELEVEL_2));

endmodule // BUSSYNC


// *POLARSTRETCH
// *Complaints to: Eric Masson
// *Module stretches a polarity value to be last at least (n-1) clock cycles
//  more than when it is set. If polarity is set to 1, a one clock cycle high 
//  pulse will last at least n clock cycles. An x clock cycle high pulse will
//  stretch to x + (n-1) cycles.
// *This block is particularly useful if a value needs to be passed
//  from clock domain to another and a value needs to be stretched over
//  a few cycles. It should be used in pair with a FULLSYNCHRONIZER.
// *Note this block uses a combinational input and produces a combinational
//  output.
// *The block requires at least three parameters: n the guaranteed with
//  of polarity, width computed as the ceiling(log2(n)), and polarity: the value
//  to be stretched to the detriment of the other.

module POLARSTRETCH(/*AUTOARG*/
   // Outputs
   OUT, 
   // Inputs
   CLK, RST, IN
   );

parameter n=1;                 // n=1
parameter width=1;             // ceiling(log2(n))
parameter [0:0] polarity=1'b1; // value to be stretched 1 or 0 ?

// do not program this value
parameter [width-1:0] m=(n-1);

input CLK;
input RST;
input IN;

output OUT;

wire [width-1:0] stateD;
wire [width-1:0] stateQ;
wire [width-1:0] sum;

assign sum = {stateQ + 1'b1};

assign stateD =  IN==polarity[0] ?       // if (IN==polarity[0])
                   {width{1'b0}} 
               : stateQ==m[width-1:0] ?  // else if (stateQ==m[width-1:0]) 
                    stateQ 
               :                         // else
                    sum;
                                  
DFFR #(width, m[width-1:0]) U_DFFR (.q(stateQ), 
                                    .d(stateD), 
                                    .clk(CLK), 
                                    .reset(RST));

assign OUT =  stateQ==m[width-1:0] ? IN : polarity[0];

endmodule // POLARSTRETCH

// *POLARSYNC
// *Complaints to: Eric Masson
// *Module stretches a polarity value to be last at least n clock cycles
//  more than when it is set in order to synchronize it to an adjacent
//  clock domain.
// *This block is particularly used if a value needs to be passed
//  from clock domain to another and a value needs to be stretched over
//  n cycles. 
// *The block requires at three parameters: n the guaranteed duration of n 
//  in clock cycles of polarity, width computed as the ceiling(log2(n)), 
//  and polarity: the value to be stretched to the detriment of the other.
// *The reset is in the input clock domain.

module POLARSYNC(/*AUTOARG*/
   // Outputs
   OUT, 
   // Inputs
   CLKIN, CLKOUT, RST, IN
   );

parameter n=1;                 // n=1
parameter width=1;             // ceiling(log2(n))
parameter [0:0] polarity=1'b1; // value to be stretched 1 or 0 ?

input  CLKIN;
input  CLKOUT;
input  RST;
input  IN;

output OUT;

wire stretched_in;

POLARSTRETCH #(n,width,polarity[0]) U_POLARSTRETCH
  (// Outputs
   .OUT(stretched_in), 
   // Inputs
   .CLK(CLKIN), 
   .RST(RST), 
   .IN(IN));

FULLSYNC #(1) U_FULLSYNC
              ( // Outputs
                .q(OUT), 
                // Inputs
                .clkin(CLKIN), 
                .clkout(CLKOUT), 
                .d(stretched_in));

endmodule // POLARSYNC

// *POLARINTRSYNC
// *Complaints to: Eric Masson
// *Module stretches a polarity value p=0 or p=1 to last at least n clock cycles
//  in the input clock domain before synchronizing to the output clock domain. 
//  Once synchronized to the output clock domain the signal is toggle every 
//  second clock cycle if it is held at polarity.
// *This block is particularly used if a value needs to be passed
//  from clock domain to another and a value needs to be stretched over
//  n cycles. 
// *The block requires at three parameters: n the guaranteed duration of n 
//  in clock cycles of polarity in input clock doamin, width computed as 
//  the ceiling(log2(n)), 
//  and polarity: the value to be stretched to the detriment of the other.
// *The reset is needed in both clock domain.

module POLARINTRSYNC(/*AUTOARG*/
   // Outputs
   OUT, 
   // Inputs
   CLKIN, CLKOUT, RSTIN, RSTOUT, IN
   );

parameter n=1;                 // n=1
parameter width=1;             // ceiling(log2(n))
parameter [0:0] polarity=1'b1; // value to be stretched 1 or 0 ?
parameter [0:0] inv_polarity=~polarity[0];

input  CLKIN;
input  CLKOUT;
input  RSTIN;
input  RSTOUT;
input  IN;

output OUT;

wire stretched_in;

POLARSTRETCH #(n,width,polarity[0]) U_POLARSTRETCH
  (// Outputs
   .OUT(stretched_in), 
   // Inputs
   .CLK(CLKIN), 
   .RST(RSTIN), 
   .IN(IN));

wire level_out;

FULLSYNC #(1) U_FULLSYNC(// Outputs
                         .q(level_out), 
                         // Inputs
                         .clkin(CLKIN), 
                         .clkout(CLKOUT), 
                         .d(stretched_in));

wire pulse_in= (OUT==polarity[0]) ? inv_polarity[0]:level_out;

DFFR #(1,inv_polarity[0]) DFFR(.q(OUT), 
                            .d(pulse_in), 
                            .clk(CLKOUT), 
                            .reset(RSTOUT));

endmodule // POLARINTRSYNC

// FOURPORTBUFFER
// Complaints to: Eric Masson
// *A buffer with 2 read ports and 2 write ports all in a unique clock domain.
// *Write enables are active low for consistency with TSMC memories.
// *It is assumed that the inputs to this block are already flopped,
//  otherwise you'll have to do some work to meet timing. 
// *If both write addresses are the same and both are enabled at the same
//  time then the value placed on port 0 gets to be placed in memory.
// *The read ports have a transparent write mode. If a read is conducted at
//  an address for which a write is simultaneously being performed then the 
//  read value reflects the new value being written (when the T0 or T1 signal
//  is set high). If transparency is not set then the old value is read. Here 
//  T0 is transparency for read port 0, T1 is transparency for read port 1.
// *The latency of the module is 1 (output requires one clock cycle).

module FOURPORTBUFFER(/*AUTOARG*/
   // Outputs
   RD0, RD1, 
   // Inputs
   CLK, T0, RA0, WE0, WA0, WD0, T1, RA1, WE1, WA1, WD1
   );

parameter Width        = 11; // 11 bits wide
parameter Depth        = 64; // 64 entries deep
parameter AddressWidth =  6; // Address space is 6 bits = ceiling(log2(64))

// All in a single clock domain
input CLK;

// Port 0 
// surefire lint_off UDDICU
input  T0;                       // Read port 0 uses transparent write
// surefire lint_on  UDDICU
input  [AddressWidth-1:0] RA0;   // Read address  on read  port 0
input  WE0;                      // Write enable  on write port 0
input  [AddressWidth-1:0] WA0;   // Write address on write port 0
input  [Width-1:0] WD0;          // Write data    on write port 0
// surefire lint_off NBAJAM
output [Width-1:0] RD0;          // Read data from   read  port 0
// surefire lint_on  NBAJAM

// Port 1
// surefire lint_off UDDICU
input  T1;                       // Read port 1 uses transparent write
// surefire lint_on  UDDICU
input  [AddressWidth-1:0] RA1;   // Read address  on read  port 1
input  WE1;                      // Write enable  on write port 1
input  [AddressWidth-1:0] WA1;   // Write address on write port 1
input  [Width-1:0] WD1;          // Write data    on write port 1
// surefire lint_off NBAJAM
output [Width-1:0] RD1;          // Read data from   read  port 1
// surefire lint_on  NBAJAM

// surefire lint_off NBAJAM
reg  [Width-1:0] buffer [0:Depth-1];
// surefire lint_on  NBAJAM
reg  [Width-1:0] RD0;
reg  [Width-1:0] RD1;

always @(posedge CLK)
begin

   {RD0, RD1} <= {buffer[RA0], buffer[RA1]};

   if (T0)
   begin
      if      (RA0==WA0 && ~WE0) RD0 <= WD0;
      else if (RA0==WA1 && ~WE1) RD0 <= WD1;
   end

   if (T1)
   begin
      if      (RA1==WA0 && ~WE0) RD1 <= WD0;
      else if (RA1==WA1 && ~WE1) RD1 <= WD1;
   end

   if (~WE0)                      buffer[WA0] <= WD0;
   if (~WE1 && (WE0 | WA0!=WA1))  buffer[WA1] <= WD1;

end

endmodule // FOURPORTBUFFER

// ------------------- n-bit mux 16 -----------------------
module MUX16X1 (  
    sel, 
    in0,
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
    in10,
    in11,
    in12,
    in13,
    in14,
    in15,
    mo) ;

    parameter Width=8;     // default
    output [Width-1:0] mo;
    input [Width-1:0] in0;
    input [Width-1:0] in1; 
    input [Width-1:0] in2;
    input [Width-1:0] in3;
    input [Width-1:0] in4;
    input [Width-1:0] in5;
    input [Width-1:0] in6;
    input [Width-1:0] in7;
    input [Width-1:0] in8;
    input [Width-1:0] in9;
    input [Width-1:0] in10;
    input [Width-1:0] in11;
    input [Width-1:0] in12;
    input [Width-1:0] in13;
    input [Width-1:0] in14;
    input [Width-1:0] in15;
    input [3:0] sel;
    
reg [Width-1:0] mo;

always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7 or in8 or in9 or in10 or in11 or in12 or in13 
         or in14 or in15 )
begin  
    case (sel)
    4'h0: mo = in0;
    4'h1: mo = in1;
    4'h2: mo = in2;
    4'h3: mo = in3;
    4'h4: mo = in4;
    4'h5: mo = in5;
    4'h6: mo = in6;
    4'h7: mo = in7;
    4'h8: mo = in8;
    4'h9: mo = in9;
    4'ha: mo = in10;
    4'hb: mo = in11;
    4'hc: mo = in12;
    4'hd: mo = in13;
    4'he: mo = in14;
    4'hf: mo = in15;
    default: mo = {Width{1'bx}};
    endcase 
end 
    
endmodule

// ------------------- n-bit mux 8 -----------------------
module MUX8X1 (  
    mo,
    in0,
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    sel) ;

    parameter Width=8;     // default
    output [Width-1:0] mo;
    input [Width-1:0] in0;
    input [Width-1:0] in1; 
    input [Width-1:0] in2;
    input [Width-1:0] in3;
    input [Width-1:0] in4;
    input [Width-1:0] in5;
    input [Width-1:0] in6;
    input [Width-1:0] in7;

    input [2:0] sel;
    
reg [Width-1:0] mo;

always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7)
begin  
    case (sel)
    3'h0: mo = in0;
    3'h1: mo = in1;
    3'h2: mo = in2;
    3'h3: mo = in3;
    3'h4: mo = in4;
    3'h5: mo = in5;
    3'h6: mo = in6;
    3'h7: mo = in7;
    default: mo = {Width{1'bx}};
    endcase 
end 
endmodule
    
// ------------------- n-bit mux 128 -----------------------
module MUX128X1 (
    mo,
    in0,
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    in8,
    in9,
    in10,
    in11,
    in12,
    in13,
    in14,
    in15,
    in16,
    in17,
    in18,
    in19,
    in20,
    in21,
    in22,
    in23,
    in24,
    in25,
    in26,
    in27,
    in28,
    in29,
    in30,
    in31,
    in32,
    in33,
    in34,
    in35,
    in36,
    in37,
    in38,
    in39,
    in40,
    in41,
    in42,
    in43,
    in44,
    in45,
    in46,
    in47,
    in48,
    in49,
    in50,
    in51,
    in52,
    in53,
    in54,
    in55,
    in56,
    in57,
    in58,
    in59,
    in60,
    in61,
    in62,
    in63,
    in64,
    in65,
    in66,
    in67,
    in68,
    in69,
    in70,
    in71,
    in72,
    in73,
    in74,
    in75,
    in76,
    in77,
    in78,
    in79,
    in80,
    in81,
    in82,
    in83,
    in84,
    in85,
    in86,
    in87,
    in88,
    in89,
    in90,
    in91,
    in92,
    in93,
    in94,
    in95,
    in96,
    in97,
    in98,
    in99,
    in100,
    in101,
    in102,
    in103,
    in104,
    in105,
    in106,
    in107,
    in108,
    in109,
    in110,
    in111,
    in112,
    in113,
    in114,
    in115,
    in116,
    in117,
    in118,
    in119,
    in120,
    in121,
    in122,
    in123,
    in124,
    in125,
    in126,
    in127,
    sel) ;

    parameter Width=8;     // default
    output [Width-1:0] mo;
    input [Width-1:0] in0;
    input [Width-1:0] in1;
    input [Width-1:0] in2;
    input [Width-1:0] in3;
    input [Width-1:0] in4;
    input [Width-1:0] in5;
    input [Width-1:0] in6;
    input [Width-1:0] in7;
    input [Width-1:0] in8;
    input [Width-1:0] in9;
    input [Width-1:0] in10;
    input [Width-1:0] in11;
    input [Width-1:0] in12;
    input [Width-1:0] in13;
    input [Width-1:0] in14;
    input [Width-1:0] in15;
    input [Width-1:0] in16;
    input [Width-1:0] in17;
    input [Width-1:0] in18;
    input [Width-1:0] in19;
    input [Width-1:0] in20;
    input [Width-1:0] in21;
    input [Width-1:0] in22;
    input [Width-1:0] in23;
    input [Width-1:0] in24;
    input [Width-1:0] in25;
    input [Width-1:0] in26;
    input [Width-1:0] in27;
    input [Width-1:0] in28;
    input [Width-1:0] in29;
    input [Width-1:0] in30;
    input [Width-1:0] in31;
    input [Width-1:0] in32;
    input [Width-1:0] in33;
    input [Width-1:0] in34;
    input [Width-1:0] in35;
    input [Width-1:0] in36;
    input [Width-1:0] in37;
    input [Width-1:0] in38;
    input [Width-1:0] in39;
    input [Width-1:0] in40;
    input [Width-1:0] in41;
    input [Width-1:0] in42;
    input [Width-1:0] in43;
    input [Width-1:0] in44;
    input [Width-1:0] in45;
    input [Width-1:0] in46;
    input [Width-1:0] in47;
    input [Width-1:0] in48;
    input [Width-1:0] in49;
    input [Width-1:0] in50;
    input [Width-1:0] in51;
    input [Width-1:0] in52;
    input [Width-1:0] in53;
    input [Width-1:0] in54;
    input [Width-1:0] in55;
    input [Width-1:0] in56;
    input [Width-1:0] in57;
    input [Width-1:0] in58;
    input [Width-1:0] in59;
    input [Width-1:0] in60;
    input [Width-1:0] in61;
    input [Width-1:0] in62;
    input [Width-1:0] in63;
    input [Width-1:0] in64;
    input [Width-1:0] in65;
    input [Width-1:0] in66;
    input [Width-1:0] in67;
    input [Width-1:0] in68;
    input [Width-1:0] in69;
    input [Width-1:0] in70;
    input [Width-1:0] in71;
    input [Width-1:0] in72;
    input [Width-1:0] in73;
    input [Width-1:0] in74;
    input [Width-1:0] in75;
    input [Width-1:0] in76;
    input [Width-1:0] in77;
    input [Width-1:0] in78;
    input [Width-1:0] in79;
    input [Width-1:0] in80;
    input [Width-1:0] in81;
    input [Width-1:0] in82;
    input [Width-1:0] in83;
    input [Width-1:0] in84;
    input [Width-1:0] in85;
    input [Width-1:0] in86;
    input [Width-1:0] in87;
    input [Width-1:0] in88;
    input [Width-1:0] in89;
    input [Width-1:0] in90;
    input [Width-1:0] in91;
    input [Width-1:0] in92;
    input [Width-1:0] in93;
    input [Width-1:0] in94;
    input [Width-1:0] in95;
    input [Width-1:0] in96;
    input [Width-1:0] in97;
    input [Width-1:0] in98;
    input [Width-1:0] in99;
    input [Width-1:0] in100;
    input [Width-1:0] in101;
    input [Width-1:0] in102;
    input [Width-1:0] in103;
    input [Width-1:0] in104;
    input [Width-1:0] in105;
    input [Width-1:0] in106;
    input [Width-1:0] in107;
    input [Width-1:0] in108;
    input [Width-1:0] in109;
    input [Width-1:0] in110;
    input [Width-1:0] in111;
    input [Width-1:0] in112;
    input [Width-1:0] in113;
    input [Width-1:0] in114;
    input [Width-1:0] in115;
    input [Width-1:0] in116;
    input [Width-1:0] in117;
    input [Width-1:0] in118;
    input [Width-1:0] in119;
    input [Width-1:0] in120;
    input [Width-1:0] in121;
    input [Width-1:0] in122;
    input [Width-1:0] in123;
    input [Width-1:0] in124;
    input [Width-1:0] in125;
    input [Width-1:0] in126;
    input [Width-1:0] in127;

    input [6:0] sel;

wire [Width-1:0] mo0;
wire [Width-1:0] mo1;
wire [Width-1:0] mo2;
wire [Width-1:0] mo3;
wire [Width-1:0] mo4;
wire [Width-1:0] mo5;
wire [Width-1:0] mo6;
wire [Width-1:0] mo7;

wire [Width-1:0] mo;

MUX16X1 #(Width) U0_16 (.sel(sel[3:0]),
                 .in0 (in0),
                 .in1 (in1),
                 .in2 (in2),
                 .in3 (in3),
                 .in4 (in4),
                 .in5 (in5),
                 .in6 (in6),
                 .in7 (in7),
                 .in8 (in8),
                 .in9 (in9),
                 .in10 (in10),
                 .in11 (in11),
                 .in12 (in12),
                 .in13 (in13),
                 .in14 (in14),
                 .in15 (in15),
                 .mo (mo0) );
                    
MUX16X1 #(Width) U1_16 (.sel(sel[3:0]),
                 .in0 (in16),
                 .in1 (in17),
                 .in2 (in18),
                 .in3 (in19),
                 .in4 (in20),
                 .in5 (in21),
                 .in6 (in22),
                 .in7 (in23),
                 .in8 (in24),
                 .in9 (in25),
                 .in10 (in26),
                 .in11 (in27),
                 .in12 (in28),
                 .in13 (in29),
                 .in14 (in30),
                 .in15 (in31),
                 .mo (mo1) );

MUX16X1 #(Width) U2_16 (.sel(sel[3:0]),
                 .in0 (in32),
                 .in1 (in33),
                 .in2 (in34),
                 .in3 (in35),
                 .in4 (in36),
                 .in5 (in37),
                 .in6 (in38),
                 .in7 (in39),
                 .in8 (in40),
                 .in9 (in41),
                 .in10 (in42),
                 .in11 (in43),
                 .in12 (in44),
                 .in13 (in45),
                 .in14 (in46),
                 .in15 (in47),
                 .mo (mo2) );

MUX16X1 #(Width) U3_16 (.sel(sel[3:0]),
                 .in0 (in48),
                 .in1 (in49),
                 .in2 (in50),
                 .in3 (in51),
                 .in4 (in52),
                 .in5 (in53),
                 .in6 (in54),
                 .in7 (in55),
                 .in8 (in56),
                 .in9 (in57),
                 .in10 (in58),
                 .in11 (in59),
                 .in12 (in60),
                 .in13 (in61),
                 .in14 (in62),
                 .in15 (in63),
                 .mo (mo3) );

MUX16X1 #(Width) U4_16 (.sel(sel[3:0]),
                 .in0 (in64),
                 .in1 (in65),
                 .in2 (in66),
                 .in3 (in67),
                 .in4 (in68),
                 .in5 (in69),
                 .in6 (in70),
                 .in7 (in71),
                 .in8 (in72),
                 .in9 (in73),
                 .in10 (in74),
                 .in11 (in75),
                 .in12 (in76),
                 .in13 (in77),
                 .in14 (in78),
                 .in15 (in79),
                 .mo (mo4) );

MUX16X1 #(Width) U5_16 (.sel(sel[3:0]),
                 .in0 (in80),
                 .in1 (in81),
                 .in2 (in82),
                 .in3 (in83),
                 .in4 (in84),
                 .in5 (in85),
                 .in6 (in86),
                 .in7 (in87),
                 .in8 (in88),
                 .in9 (in89),
                 .in10 (in90),
                 .in11 (in91),
                 .in12 (in92),
                 .in13 (in93),
                 .in14 (in94),
                 .in15 (in95),
                 .mo (mo5) );

MUX16X1 #(Width) U6_16 (.sel(sel[3:0]),
                 .in0 (in96),
                 .in1 (in97),
                 .in2 (in98),
                 .in3 (in99),
                 .in4 (in100),
                 .in5 (in101),
                 .in6 (in102),
                 .in7 (in103),
                 .in8 (in104),
                 .in9 (in105),
                 .in10 (in106),
                 .in11 (in107),
                 .in12 (in108),
                 .in13 (in109),
                 .in14 (in110),
                 .in15 (in111),
                 .mo (mo6) );

MUX16X1 #(Width) U7_16 (.sel(sel[3:0]),
                 .in0 (in112),
                 .in1 (in113),
                 .in2 (in114),
                 .in3 (in115),
                 .in4 (in116),
                 .in5 (in117),
                 .in6 (in118),
                 .in7 (in119),
                 .in8 (in120),
                 .in9 (in121),
                 .in10 (in122),
                 .in11 (in123),
                 .in12 (in124),
                 .in13 (in125),
                 .in14 (in126),
                 .in15 (in127),
                 .mo (mo7) );

MUX8X1 #(Width) U0_8 (.sel(sel[6:4]),
                        .in0 (mo0), 
                        .in1 (mo1), 
                        .in2 (mo2), 
                        .in3 (mo3), 
                        .in4 (mo4), 
                        .in5 (mo5), 
                        .in6 (mo6), 
                        .in7 (mo7),
                        .mo (mo));

endmodule

// FIFO w/GMI
module FIFO_GMI(
   // Outputs
   EMPTY, FULL, COUNT, Q, 
   // Inputs
   CLK, RESET, PUSH, POP, D, GMIRD, GMIWR, GMIWRDATA,
   GMIRDRDY, GMIRDY4TXN
   );
   
   parameter FIFO_DATA_WIDTH = 8;
   parameter FIFO_DEPTH      = 16;
   parameter FIFO_ADDR_WIDTH = 4;
   parameter FIFO_FULL_LEVEL = 16;

   input                                CLK;
   input 				RESET;

   input 				PUSH;
   input  [FIFO_DATA_WIDTH-1:0] 	D;
   input 				POP;

   input				GMIRD;
   input				GMIWR; // surefire lint_off_line UDDICU
   input  [FIFO_DATA_WIDTH-1:0]		GMIWRDATA; // surefire lint_off_line UDDICU

   output 				EMPTY;
   output 				FULL; // surefire lint_off_line UDDODN
   output [FIFO_ADDR_WIDTH  :0] 	COUNT; // surefire lint_off_line UDDODN
   
   output [FIFO_DATA_WIDTH-1:0] 	Q;

   output				GMIRDRDY; // surefire lint_off_line UDDODN
   output				GMIRDY4TXN; // surefire lint_off_line UDDODN

   reg	  [FIFO_ADDR_WIDTH  :0]		cnt;
   reg	  [FIFO_ADDR_WIDTH-1:0] 	rptr;
   reg	  [FIFO_ADDR_WIDTH-1:0] 	wptr;
   wire	  [FIFO_ADDR_WIDTH-1:0] 	MemArbRptr;
   wire	  				MemArbRcen;

   wire					read;
   wire					write;
   wire					REALFULL;

   wire					valid_wr;
   wire	  [FIFO_DATA_WIDTH-1:0]		wdata;

   assign EMPTY = cnt == {(FIFO_ADDR_WIDTH+1){1'b0}};
//surefire lint_off CWECSB CWECSM
   assign FULL  = cnt >= FIFO_FULL_LEVEL;
   assign REALFULL  = cnt >= FIFO_DEPTH;
//surefire lint_on CWECSB CWECSM
   assign COUNT = cnt;

   assign write = PUSH & ~REALFULL;
   assign read = POP & ~EMPTY;

   assign valid_wr = write | GMIWR;
   assign wdata = GMIWR ? GMIWRDATA : D;

   always @(posedge CLK) begin
     if (~RESET) 
       wptr <= {FIFO_ADDR_WIDTH{1'b0}};
     else
//surefire lint_off ASWEMB CWECSM CWECSB XWECSX CWECSS
       wptr <= valid_wr ? (((wptr+1'b1) == FIFO_DEPTH) ? {FIFO_ADDR_WIDTH{1'b0}} : (wptr+1'b1)) : wptr;
//surefire lint_on ASWEMB CWECSM CWECSB XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       rptr <= {FIFO_ADDR_WIDTH{1'b0}};
     else
//surefire lint_off ASWEMB CWECSM CWECSB XWECSX CWECSS
       rptr <= read ? (((rptr+1'b1) == FIFO_DEPTH) ? {FIFO_ADDR_WIDTH{1'b0}} : (rptr+1'b1)) : rptr;
//surefire lint_on ASWEMB CWECSM CWECSB XWECSX CWECSS
   end

  fifarb #(FIFO_ADDR_WIDTH,FIFO_DEPTH) rqarb(
  	.clk(CLK),
	.reset(RESET),
	.gmirden(GMIRD),
	.blkpop(read),
	.blkrptr(rptr[FIFO_ADDR_WIDTH-1:0]),
	.blkcnt(cnt[FIFO_ADDR_WIDTH:0]),
	.blkempty(EMPTY),
	.rdrdy(GMIRDRDY),
	.rdy4txn(GMIRDY4TXN),
	.memrcen(MemArbRcen),
	.memraddr(MemArbRptr[FIFO_ADDR_WIDTH-1:0])
  	);

   SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,FIFO_ADDR_WIDTH) FIFO_SPRF(
     .QA(Q[FIFO_DATA_WIDTH-1:0]),
     .AA(MemArbRptr[FIFO_ADDR_WIDTH-1:0]),
     .CLKA(CLK),
     .CENA(MemArbRcen),
     .AB(wptr[FIFO_ADDR_WIDTH-1:0]),
     .DB(wdata[FIFO_DATA_WIDTH-1:0]),
     .CLKB(CLK),
     .CENB(~valid_wr)
   );

   always @(posedge CLK) begin
     if (~RESET) begin
       cnt <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     end else begin
//surefire lint_off CSEDFT CSEBYP
       case ({valid_wr,read})
         2'b00: cnt <= cnt;
	 2'b11: cnt <= cnt;
// surefire lint_off ASWIMB
	 2'b01: cnt <= cnt - 1'b1;
	 2'b10: cnt <= cnt + 1'b1;
// surefire lint_on ASWIMB
	 // synopsys translate_off
	 default: cnt <= {(FIFO_ADDR_WIDTH+1){1'bx}};
	 // synopsys translate_on
//surefire lint_on CSEDFT CSEBYP
       endcase
     end
   end
   
endmodule // FIFO_GMI

module fifarb(/*AUTOARG*/
   // Outputs
   rdrdy, rdy4txn, memrcen, memraddr, 
   // Inputs
   clk, reset, gmirden, blkpop, blkrptr, blkcnt, blkempty
   );

parameter ADDR_WIDTH = 5;
parameter FIFO_DEPTH = 8;

input 			clk;
input			reset;

input			gmirden;

input			blkpop;
input  [ADDR_WIDTH-1:0] blkrptr;
input  [ADDR_WIDTH:0]   blkcnt;
input			blkempty;

output			rdrdy;
output			rdy4txn;

output			memrcen;
output [ADDR_WIDTH-1:0]	memraddr;

wire			rdhld;
wire			newrdval;
wire			cpurgt;
wire			memrcen;
wire			cpurd;
wire			gmiempty;
wire  [ADDR_WIDTH-1:0]  cpurptr;
wire  [ADDR_WIDTH-1:0]  inccpurptr;
wire  [ADDR_WIDTH-1:0]  incblkrptr;
wire  [ADDR_WIDTH-1:0]  newcpurptr;
wire			lstrq;
wire			newlstrq;
wire			hold;
wire  [ADDR_WIDTH:0]	cpucnt;
wire  [ADDR_WIDTH:0]	newcpucnt;
wire  [ADDR_WIDTH:0]	deccnt;
wire  [ADDR_WIDTH:0]	decblkcnt;

assign rdhld = ~gmirden & ~cpurgt;
assign newrdval = (gmirden & 1'b1) |
		 (cpurgt & 1'b0) |
		 (rdhld & cpurd);
DFFR #(1) dff0(.d(newrdval),.q(cpurd),.clk(clk),.reset(reset));

assign cpurgt = ~blkpop & cpurd & ~gmiempty & ~blkempty; 
assign memrcen = cpurgt ? 1'b0 : ~blkpop;
assign memraddr = (cpurgt & lstrq) ? cpurptr : blkrptr;

DFFR #(1) dff1(.d(cpurgt),.q(rdrdy),.reset(reset),.clk(clk));
assign rdy4txn = ~cpurd;

// store last rq type
assign newlstrq = (cpurgt & 1'b1) |
                  (blkpop & 1'b0);
DFFR #(1) dff2(.d(newlstrq),.q(lstrq),.reset(reset),.clk(clk));

// rd ptr 
//surefire lint_off ASWEMB CWECSM CWECSB XWECSX CWECSS
assign inccpurptr = (((cpurptr+1'b1) == FIFO_DEPTH) ? {ADDR_WIDTH{1'b0}} : (cpurptr+1'b1)) ;
assign incblkrptr = (((blkrptr+1'b1) == FIFO_DEPTH) ? {ADDR_WIDTH{1'b0}} : (blkrptr+1'b1)) ;
//surefire lint_on ASWEMB CWECSM CWECSB XWECSX CWECSS
assign hold = ~cpurgt;
assign newcpurptr = ({ADDR_WIDTH{cpurgt & lstrq}} & inccpurptr) |
		    ({ADDR_WIDTH{cpurgt & ~lstrq}} & incblkrptr) |
		    ({ADDR_WIDTH{hold}} & cpurptr);
DFFR #(ADDR_WIDTH) dff3(.d(newcpurptr),.q(cpurptr),.reset(reset),.clk(clk));

// gmi empty
//surefire lint_off ASWEMB ASWEBB
assign deccnt = cpucnt - 1'b1;
assign decblkcnt = blkcnt - 1'b1;
//surefire lint_on ASWEMB ASWEBB
assign newcpucnt = ({(ADDR_WIDTH+1){cpurgt & lstrq}} & deccnt) |
		   ({(ADDR_WIDTH+1){cpurgt & ~lstrq}} & decblkcnt) |
		   ({(ADDR_WIDTH+1){hold}} & cpucnt);
DFFR #(ADDR_WIDTH+1) dff4(.d(newcpucnt),.q(cpucnt),.reset(reset),.clk(clk));
//surefire lint_off CWECSB
assign gmiempty = cpucnt == 0;
//surefire lint_on CWECSB

endmodule

// Lookahead Fifo w/GMI
module FIFO_LA_GMI (
   // Outputs
   EMPTY, FULL, Q, WRPTR, RDPTR, COUNT,
   // Inputs
   CLK, RESET, PUSH, POP, D, GMIRD, GMIWR, GMIWRDATA, 
   GMIRDRDY, GMIRDY4TXN, GMISTATUS
   );
   
   parameter FIFO_DATA_WIDTH = 32;
   parameter FIFO_DEPTH      = 8;
   parameter FIFO_ADDR_WIDTH = 8;

   input                                CLK;
   input 				RESET;

   input 				PUSH;
   input 				POP;
   output 				EMPTY;
   output 				FULL;
   output [FIFO_ADDR_WIDTH  :0]         WRPTR; //surefire lint_off_line UDDODN
   output [FIFO_ADDR_WIDTH  :0]         RDPTR; //surefire lint_off_line UDDODN
   output [FIFO_ADDR_WIDTH  :0]         COUNT;

   output 				GMIRDRDY; // surefire lint_off_line UDDODN
   output				GMIRDY4TXN; //surefire lint_off_line UDDOCU UDDOCN
   output				GMISTATUS; //surefire lint_off_line UDDODN
 
   input  [FIFO_DATA_WIDTH-1:0] 	D;
   output [FIFO_DATA_WIDTH-1:0] 	Q;

   input				GMIRD;
   input				GMIWR;	//surefile lint_off_line UDDICU
   input  [FIFO_DATA_WIDTH-1:0]		GMIWRDATA;	//surefile lint_off_line UDDINU

   reg	  [FIFO_ADDR_WIDTH  :0]		rptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		fifrptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		rptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr_q;
   reg	  [FIFO_ADDR_WIDTH  :0]		wptr;
   reg	  [FIFO_ADDR_WIDTH  :0]		COUNT;

   wire					read;
   wire					write;
   wire	  [FIFO_DATA_WIDTH-1:0]		wrdata;
   wire   [FIFO_DATA_WIDTH-1:0]		ramd;
   wire					fifrd;
   wire					fifempty;

   reg	  [FIFO_DATA_WIDTH-1:0]		regd;
   reg					regwr;
   reg					regvld;
   reg					GMIRDRDY;

   assign WRPTR = wptr;
   assign RDPTR = rptr;

   assign write = (PUSH|GMIWR) & ~FULL;
   assign read = (POP|GMIRD) & ~EMPTY;

   assign wrdata = GMIWR ? GMIWRDATA : D;

   always @(posedge CLK) begin
     if (~RESET) 
       wptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
//surefire lint_off ASWEMB CWECSM XWECSX CWECSS
       wptr[FIFO_ADDR_WIDTH:0] <= write ? (((wptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
 		     			? {~wptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		     			: (wptr[FIFO_ADDR_WIDTH:0]+1'b1))
		     			: wptr[FIFO_ADDR_WIDTH:0];
//surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(rptr_q or read) begin
//surefire lint_off ASWEMB CWECSM XWECSX CWECSS
     rptr[FIFO_ADDR_WIDTH:0]  = read ? (((rptr_q[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH)
     		 		     ? {~rptr_q[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
		 		     : (rptr_q[FIFO_ADDR_WIDTH:0]+1'b1))
		 		     : rptr_q[FIFO_ADDR_WIDTH:0];
//surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       rptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       rptr_q[FIFO_ADDR_WIDTH:0] <= rptr[FIFO_ADDR_WIDTH:0];
   end

   SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,FIFO_ADDR_WIDTH) FIFO_SPRF(
     .QA(ramd[FIFO_DATA_WIDTH-1:0]),
     .AA(fifrptr[FIFO_ADDR_WIDTH-1:0]),
     .CLKA(CLK),
     .CENA(~fifrd),
     .AB(wptr[FIFO_ADDR_WIDTH-1:0]),
     .DB(wrdata[FIFO_DATA_WIDTH-1:0]),
     .CLKB(CLK),
     .CENB(~write)
   );

   always @(posedge CLK) begin
     if (~RESET)
       wptr_q[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       wptr_q[FIFO_ADDR_WIDTH:0] <= wptr[FIFO_ADDR_WIDTH:0];
   end
   
   assign EMPTY = wptr_q[FIFO_ADDR_WIDTH:0] == rptr_q[FIFO_ADDR_WIDTH:0];
   assign FULL  = ((wptr[FIFO_ADDR_WIDTH] != rptr_q[FIFO_ADDR_WIDTH]) &
   		   (wptr[FIFO_ADDR_WIDTH-1:0] == rptr_q[FIFO_ADDR_WIDTH-1:0]));

   assign fifempty = wptr[FIFO_ADDR_WIDTH:0] == fifrptr[FIFO_ADDR_WIDTH:0];
   assign fifrd = ((~regvld & ~regwr)| (~regvld & regwr & read) | (regvld & read)) & ~fifempty;

   always @(posedge CLK) begin
     if (~RESET) 
       fifrptr[FIFO_ADDR_WIDTH:0] <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
//surefire lint_off ASWEMB CWECSM XWECSX CWECSS
       fifrptr[FIFO_ADDR_WIDTH:0] <= fifrd ? (((fifrptr[FIFO_ADDR_WIDTH-1:0]+1'b1) == FIFO_DEPTH) 
                                      ? {~fifrptr[FIFO_ADDR_WIDTH],{FIFO_ADDR_WIDTH{1'b0}}}
                                      : (fifrptr[FIFO_ADDR_WIDTH:0]+1'b1))
                                      : fifrptr[FIFO_ADDR_WIDTH:0];
//surefire lint_on ASWEMB CWECSM XWECSX CWECSS
   end

   always @(posedge CLK) begin
     if (~RESET)
       regwr <= 1'b0;
     else
       regwr <= fifrd;
   end

   always @(posedge CLK) begin
     if (regwr)
       regd <= ramd;
   end

   always @(posedge CLK) begin
     if (~RESET) 
       regvld <= 1'b0;
     else
       regvld <= (regvld | regwr) & ~read;
   end

   assign Q = regvld ? regd : ramd;


   always @(posedge CLK) begin
     if (~RESET)
       GMIRDRDY <= 1'b0;
     else
       GMIRDRDY <= GMIRD;
   end

   assign GMIRDY4TXN = 1'b1;
   assign GMISTATUS = EMPTY;

   always @(posedge CLK) begin
     if (~RESET)
       COUNT <= {(FIFO_ADDR_WIDTH+1){1'b0}};
     else
       case ({write, read})
         2'b00: COUNT <= COUNT;
//surefire lint_off ASWIBB
         2'b01: COUNT <= COUNT - 1;
         2'b10: COUNT <= COUNT + 1;
//surefire lint_on ASWIBB
         2'b11: COUNT <= COUNT;
         default: COUNT <= {(FIFO_ADDR_WIDTH+1){1'bx}};
       endcase
   end

endmodule // fifo_la_gmi

module ASYNCFIFO
  (
   RESET_RDCLK, RESET_WRCLK, RDCLK, READ,RDDATA,
   WRCLK, WRITE, WRDATA,
   EMPTY, FULL, RDPTR_WRCLK, WRPTR_WRCLK,
   RDPTR_RDCLK, WRPTR_RDCLK	 
   );

  parameter FIFO_DATA_WIDTH = 8;
  parameter FIFO_DEPTH      = 16;
  parameter ADBITS = 4;
  parameter [0:0] REG_RADDR = 1'b0;
  
  /* 0in assert -clock WRCLK -reset ~RESET_WRCLK
                -var ((1<<ADBITS) == FIFO_DEPTH)
                -message "FIFO_DEPTH does not equal exactly 2^ADBITS" */
  
  // input ports
  input 	     			RESET_RDCLK; //surefire lint_off_line RD_WRT
  input 	     			RESET_WRCLK; //surefire lint_off_line RD_WRT
  input 	     			RDCLK;
  input 	     			READ;
  input 	     			WRCLK;
  input 	     			WRITE;
  input 	[FIFO_DATA_WIDTH-1:0] 	WRDATA;

  // output ports
  output 	[FIFO_DATA_WIDTH-1:0] 	RDDATA;
  output        			EMPTY;
  output        			FULL;
// surefire lint_off UDDODN
  output	[ADBITS:0]		WRPTR_WRCLK;
  output	[ADBITS:0]		RDPTR_WRCLK;
  output	[ADBITS:0]		WRPTR_RDCLK;
  output	[ADBITS:0]		RDPTR_RDCLK;
// surefire lint_on UDDODN

  // 0in kndr -clock WRCLK -reset ~RESET_WRCLK -var WRITE
  // 0in kndr -clock WRCLK -reset ~RESET_WRCLK -var FULL
  // 0in kndr -clock WRCLK -reset ~RESET_WRCLK -var WRPTR_WRCLK
  // 0in kndr -clock WRCLK -reset ~RESET_WRCLK -var RDPTR_WRCLK

  // 0in kndr -clock RDCLK -reset ~RESET_RDCLK -var READ
  // 0in kndr -clock RDCLK -reset ~RESET_RDCLK -var EMPTY
  // 0in kndr -clock RDCLK -reset ~RESET_RDCLK -var WRPTR_RDCLK
  // 0in kndr -clock RDCLK -reset ~RESET_RDCLK -var RDPTR_RDCLK

  // register declarations
  reg   [ADBITS:0] 		rdptr_wrclk1;
  reg   [ADBITS:0] 		rdptr_wrclk2;
  reg   [ADBITS:0] 		wrptr_rdclk1;
  reg   [ADBITS:0] 		wrptr_rdclk2;
  reg   [ADBITS:0] 		wrptr_gray;
  reg   [ADBITS:0] 		rdptr_gray;
  reg	[ADBITS:0]		wrptr_bin;
  reg	[ADBITS:0]		rdptr_bin;
  reg	[ADBITS:0]		wrptr_bnext;
  reg	[ADBITS:0]		wrptr_gnext;
  
  // wire declarations
  wire  	     		valid_wr;
  wire  	     		valid_rd;
  wire	     			FULL;
  wire	     			EMPTY;
  wire	[ADBITS-1:0] 		rdptr;
  wire	[ADBITS-1:0] 		wrptr;
  wire	[ADBITS:0]		rdptr_g2b;
  wire	[ADBITS:0]		wrptr_g2b;
  wire	[ADBITS:0]		rdptr_inc;
  wire  [ADBITS:0]              rdptr_bnext;
  wire  [ADBITS:0]		rdptr_gnext;
  wire	[ADBITS-1:0]		rdptr_arr;

  // synopsys translate_off
  `define zykwidth ((FIFO_DEPTH > 8192) ? 14 : (FIFO_DEPTH > 4096) ? 13 : (FIFO_DEPTH > 2048) ? 12: (FIFO_DEPTH > 1024) ? 11: (FIFO_DEPTH > 512) ? 10 : (FIFO_DEPTH > 256) ? 9 : (FIFO_DEPTH > 128) ? 8 : (FIFO_DEPTH > 64) ? 7 : (FIFO_DEPTH > 32) ? 6 : (FIFO_DEPTH > 16) ? 5 : (FIFO_DEPTH > 8) ? 4 : (FIFO_DEPTH > 4) ? 3 : (FIFO_DEPTH > 2) ? 2 : 1)

  `define zykwidth1 ((FIFO_DEPTH+1 > 8192) ? 14 : (FIFO_DEPTH+1 > 4096) ? 13 : (FIFO_DEPTH+1 > 2048) ? 12: (FIFO_DEPTH+1 > 1024) ? 11: (FIFO_DEPTH+1 > 512) ? 10 : (FIFO_DEPTH+1 > 256) ? 9 : (FIFO_DEPTH+1 > 128) ? 8 : (FIFO_DEPTH+1 > 64) ? 7 : (FIFO_DEPTH+1 > 32) ? 6 : (FIFO_DEPTH+1 > 16) ? 5 : (FIFO_DEPTH+1 > 8) ? 4 : (FIFO_DEPTH+1 > 4) ? 3 : (FIFO_DEPTH+1 > 2) ? 2 : 1)

  initial begin
    if (`zykwidth1 == `zykwidth) begin
      $display("Width = %d, zykwidth = %b, zykwidth1 = %b", FIFO_DEPTH, `zykwidth,`zykwidth1);
      $display("ASYNCFIFO only supports 2**n depth");
      $finish;
    end
  end
  // synopsys translate_on

  // functions
  function [ADBITS:0] b2g;
  input [ADBITS:0] binary;
  begin
    b2g[ADBITS:0] = (binary[ADBITS:0]>>1)^binary[ADBITS:0];
  end
  endfunction

  function [ADBITS:0] g2b;
  input [ADBITS:0] gray; 
  integer i;
  begin
// surefire lint_off ASWIMB
    for (i=0;i<=ADBITS;i=i+1) begin
// surefire lint_on ASWIMB
      g2b[i] = ^(gray>>i);
    end
  end
  endfunction

  assign valid_rd = READ & ~EMPTY;
  assign valid_wr = WRITE & ~FULL;
  assign wrptr[ADBITS-1:0] = wrptr_bin[ADBITS-1:0];
  assign rdptr[ADBITS-1:0] = rdptr_bin[ADBITS-1:0];
  assign WRPTR_WRCLK[ADBITS:0] = wrptr_bin[ADBITS:0];
  assign RDPTR_WRCLK[ADBITS:0] = rdptr_g2b[ADBITS:0];
  assign WRPTR_RDCLK[ADBITS:0] = wrptr_g2b[ADBITS:0];
  assign RDPTR_RDCLK[ADBITS:0] = rdptr_bin[ADBITS:0];

   /* 0in multi_clock_fifo -depth FIFO_DEPTH
                           -enq_clock WRCLK
                           -enq_reset ~RESET_WRCLK
                           -enq valid_wr
                           -enq_data WRDATA
                           -deq_clock RDCLK
                           -deq_reset ~RESET_RDCLK
                           -deq valid_rd
                           -deq_data RDDATA
                           -latency REG_RADDR */

  SPRF #(FIFO_DATA_WIDTH,FIFO_DEPTH,ADBITS) FIFO_SPRF(
     .QA(RDDATA[FIFO_DATA_WIDTH-1:0]),
     .AA(rdptr_arr[ADBITS-1:0]),
     .CLKA(RDCLK),
     .CENA(1'b0),
     .AB(wrptr[ADBITS-1:0]),
     .DB(WRDATA[FIFO_DATA_WIDTH-1:0]),
     .CLKB(WRCLK),
     .CENB(~valid_wr)
  );

  /// rdptr
// surefire lint_off CNDWID
  assign rdptr_arr[ADBITS-1:0] = REG_RADDR ? rdptr[ADBITS-1:0]
					    : rdptr_bnext[ADBITS-1:0];
// surefire lint_on CNDWID

  /// wrptr 
  always @(valid_wr or wrptr_bin[ADBITS:0]) begin
// surefire lint_off ASWEMB CWECSM XWECSX CWECSS
    wrptr_bnext[ADBITS:0] = valid_wr ? (((wrptr_bin[ADBITS-1:0]+1'b1) == FIFO_DEPTH) ?
  					{~wrptr_bin[ADBITS], {ADBITS{1'b0}}} :
					(wrptr_bin[ADBITS:0]+1'b1)) :
  			    wrptr_bin[ADBITS:0];
    wrptr_gnext[ADBITS:0] = b2g(wrptr_bnext[ADBITS:0]);
// surefire lint_on ASWEMB CWECSM XWECSX CWECSS
  end

  always @(posedge WRCLK) begin
    if (~RESET_WRCLK) begin
      wrptr_gray[ADBITS:0] <= {(ADBITS+1){1'b0}};
      wrptr_bin[ADBITS:0] <= {(ADBITS+1){1'b0}};
    end else begin
      wrptr_gray[ADBITS:0] <= wrptr_gnext[ADBITS:0];
      wrptr_bin[ADBITS:0] <= wrptr_bnext[ADBITS:0];
    end
  end
  // 0in gray_code -clock WRCLK -reset ~RESET_WRCLK -var wrptr_gray

  /// rdptr
// surefire lint_off ASWEMB
  assign rdptr_inc[ADBITS:0] = rdptr_bin[ADBITS:0] + 1'b1;
// surefire lint_on ASWEMB
  assign rdptr_bnext[ADBITS:0] = valid_rd ? rdptr_inc[ADBITS:0] :
  				            rdptr_bin[ADBITS:0];
  assign rdptr_gnext[ADBITS:0] = valid_rd ? b2g(rdptr_inc[ADBITS:0]) :
                                            rdptr_gray[ADBITS:0];
 
  always @(posedge RDCLK) begin
    if (~RESET_RDCLK) begin
      rdptr_gray[ADBITS:0] <= {(ADBITS+1){1'b0}};
      rdptr_bin[ADBITS:0] <= {(ADBITS+1){1'b0}};
    end else begin
      rdptr_gray[ADBITS:0] <= rdptr_gnext[ADBITS:0];
      rdptr_bin[ADBITS:0]  <= rdptr_bnext[ADBITS:0];
    end
  end
  // 0in gray_code -clock RDCLK -reset ~RESET_RDCLK -var rdptr_gray

  /// EMPTY 
  always @(posedge RDCLK) begin
    wrptr_rdclk1[ADBITS:0] <= wrptr_gray[ADBITS:0];
  end
  always @(posedge RDCLK) begin
    wrptr_rdclk2[ADBITS:0] <= wrptr_rdclk1[ADBITS:0];
  end

  assign wrptr_g2b[ADBITS:0] = g2b(wrptr_rdclk2[ADBITS:0]);
  
  assign EMPTY = (rdptr_gray[ADBITS:0] == wrptr_rdclk2[ADBITS:0]);
  
  /// FULL 
  always @(posedge WRCLK) begin
    rdptr_wrclk1[ADBITS:0] <= rdptr_gray[ADBITS:0];
  end
  always @(posedge WRCLK) begin
    rdptr_wrclk2[ADBITS:0] <= rdptr_wrclk1[ADBITS:0];
  end

  assign rdptr_g2b[ADBITS:0] = g2b(rdptr_wrclk2[ADBITS:0]);

  assign FULL = ((wrptr_bin[ADBITS]   != rdptr_g2b[ADBITS]) &
               (wrptr_bin[ADBITS-1:0] == rdptr_g2b[ADBITS-1:0]));

endmodule


module CLKGATE (
    DomainClkIn,
    UnitClkEn,
    UnitGatedDomainClk,
    UnitUngatedDomainClk) ;

    output UnitGatedDomainClk;
    output UnitUngatedDomainClk;
    input DomainClkIn;
    input UnitClkEn;

    wire DomainClkBar;
    wire UnitClkEnSyn;
    wire UnitClkEnDel;
    wire UnitClkEnDelLo;

assign DomainClkBar = ~DomainClkIn;

// surefire lint_off CLKBED
// When both edges of clock are used. Could be a problem in the scan chain unless
// special care is taken (Mentor takes care of this. The low phase latches are put
// earlier than the high phase in the scan chain automatically)

// surefire lint_off CLKEDM
// When different clocks are mixed in the logic. Similar considerations to the
// above apply. DFT tools can also insert lockup latches if the two clocks are
// unrelated. In this case they are related so a mere reordering will suffice.

// Synchronize the enable to the local clock domain first

HALFSYNC EnSync(.q(UnitClkEnSyn),.clk(DomainClkIn),.d(UnitClkEn));

DFF #(1) dffa(.d(UnitClkEnSyn),.q(UnitClkEnDel),.clk(DomainClkIn));

//Low phase flop to make sure that enable is stable during clock high phase
//Special consideration needed for mindelay here.

DFF #(1) dffb(.d(UnitClkEnDel),.q(UnitClkEnDelLo),.clk(DomainClkBar));

// surefire lint_on CLKBED
// surefire lint_on CLKEDM

// surefire lint_off GATCLK
// Gated clock warning.

assign UnitGatedDomainClk = UnitClkEnDelLo &&  DomainClkIn;

// surefire lint_on GATCLK

assign UnitUngatedDomainClk = DomainClkIn;


endmodule


module QDRCLKGEN(CLK, RESET, QDR_K, QDR_K_n, QIF_DIV2);
   output QDR_K, QDR_K_n, QIF_DIV2;
   input  CLK, RESET;

   reg    QDR_K, QIF_DIV2;
   wire   QDR_K_n;
   
   always @(negedge CLK)
     if (~RESET)
       QDR_K <= 1'b0;
     else
       QDR_K <= ~QDR_K;

   assign QDR_K_n = ~QDR_K;
   
// Lint complains that this posedge here is inconsistent with the negedge above
// surefire lint_off CLKEDG CLKEDM
   always @(posedge CLK)
     QIF_DIV2 <= ~QDR_K;
// surefire lint_on CLKEDG CLKEDM

endmodule

// *Complaints to: Eric Masson 
// *SATADD
// *Adder with staturation
// *Accepts a parameter called: Width
// *Accepts two inputs A and B of (Width) bits
// *Produces an output X also  of (Width) bits
// *Whole block is combinational.
// 
// A, B and X are integers. If the sum of A and B exceeds Width bits (overflow)
// then response is all ones X.
// 

module SATADD(/*AUTOARG*/
   // Outputs
   X, 
   // Inputs
   A, B
   );

parameter Width = 8;

input  [Width-1:0]  A;
input  [Width-1:0]  B;
output [Width-1:0]  X;

// perform +/- in parallel
wire [Width-1:0] AaddB = {A[Width-1:0] + B[Width-1:0]};
wire overflow = (A[Width-1] | B[Width-1]) & ~AaddB[Width-1];
assign X = AaddB | {Width{overflow}};

endmodule

// *Complaints to: Eric Masson 
// *GETSHORTY
// *Expects several register inputs.
// *The purpose of this macro is to rate limit small packets into the 
//  chip since they may cause overflows. Up to four streams of small
//  packets are considered (the number of ports we support).
// *Two parameters are provided: 
//      (a) Width  -- the width of packet sizes in bits
//      (b) TMmode -- 1'b1 -> TM format for packet sizes ((size-1) % max_size)
//                    1'b0 -> PP format for packet sizes (   size  % max_size)
//
// *Two sets of programmable register values are needed 
//
//  [Width-1:0]  PKTSIZESHORT        threshold packet size (in PP format)
//  [14:0]       INTERVALSHORT       duration of interval in core cycles
//  [14:0]       PACKETLIMITSHORT    packet limit on interval
// 
//  [Width-1:0]  PKTSIZELONG         threshold packet size (in PP format)
//  [14:0]       INTERVALLONG        interval, 64 core cycles per unit
//  [14:0]       PACKETLIMITLONG     packet limit on interval
//
//  The first set of parameters allow for short term tiny packet filtering.
//  Within repeated windows of INTERVALSHORT core clock cycles there will 
//  be no more than PACKETLIMITSHORT packets of size PKTSIZESHORT or smaller
//  that will be let through. Note that it is still possible that 
//  more than PACKETLIMITSHORT packets appear within any given window of 
//  INTERVALSHORT since we do not use a sliding window but fixed windows
//  in time.
// 
//  The second set of parameters allow for long term tiny packet filtering.
//  Within repeated windows of INTERVALLONG*64 core clock cycles there will
//  be no more than PACKETLIMITLONG packets of size PKTSIZELONG or smaller
//  that will be let through. Again, a sliding window is not used. So
//  divide PACKETLIMITLONG by 2 if you want a guarantee of no more than
//  PACKETLIMITLONG on ANY given time window of INTERVALLONG length.
// 
//  The input:
//
//      [3:0]       PORTENABLE;   // indexed by port number
//
//  is a control register to determine on which ports the filtering is
//  enabled.
//
//  The output is KILLSHORTY a four bit bus indexed by port number.
//  It determines whether or not an outgoing packet should be 
//  killed or not by filetering criteria. The output is combinational and
//  within the same clock cycle as input SIZEP<0-3> and SIZEVLD[3:0].
//  To achieve this the module makes four predictive guesses per clock
//  cycle of which one is chosen in the next clock cycle depending
//  on the input pattern.
//
//  Programming the PKTLIMIT register with an all ones value will
//  allow an unlimited number of packets to flow through.
// 

module GETSHORTY(/*AUTOARG*/
   // Outputs
   KILLSHORTY, 
   // Inputs
   CLK, RESET, PKTSIZESHORT, INTERVALSHORT, PACKETLIMITSHORT, 
   PKTSIZELONG, INTERVALLONG, PACKETLIMITLONG, PORTENABLE, SIZEP0, 
   SIZEP1, SIZEP2, SIZEP3, SIZEVLD
   );

parameter Width = 6;             // width in bits of sizes to compare
parameter [0:0] TMmode = 1'b1;   // tm offsets are passed, not sizes

input              CLK;          // core clock
input              RESET;        // core clock reset

input [Width-1:0]  PKTSIZESHORT;      // threshold packet size
input [14:0]       INTERVALSHORT;     // duration of interval in unit intervals
input [14:0]       PACKETLIMITSHORT;  // packet limit on interval

input [Width-1:0]  PKTSIZELONG;       // threshold packet size
input [14:0]       INTERVALLONG;      // duration of interval in unit intervals
input [14:0]       PACKETLIMITLONG;   // packet limit on interval

input  [3:0]       PORTENABLE;   // 3 is port 3, ..., 0 is port 0.

input  [Width-1:0] SIZEP0;       // incoming packet size on port 0
input  [Width-1:0] SIZEP1;       // incoming packet size on port 1
input  [Width-1:0] SIZEP2;       // incoming packet size on port 2
input  [Width-1:0] SIZEP3;       // incoming packet size on port 3

input  [3:0]       SIZEVLD;      // incoming packet size is valid

output [3:0]       KILLSHORTY;   // kill short packet on port 0,1,2,3

wire [3:0] KILLSHORTYSHORT, KILLSHORTYLONG;

HALFSHORTY #(7,7'd64,Width,TMmode)  HALFSHORTYLONG
  (.KILLSHORTY(KILLSHORTYLONG), 
   .CLK(CLK), 
   .RESET(RESET), 
   .PKTSIZE(PKTSIZELONG), 
   .INTERVAL(INTERVALLONG), 
   .PACKETLIMIT(PACKETLIMITLONG), 
   .PORTENABLE(PORTENABLE), 
   .SIZEP0(SIZEP0), 
   .SIZEP1(SIZEP1), 
   .SIZEP2(SIZEP2), 
   .SIZEP3(SIZEP3),    
   .SIZEVLD(SIZEVLD));

HALFSHORTY #(1,1'd1,Width,TMmode)  HALFSHORTYSHORT
  (.KILLSHORTY(KILLSHORTYSHORT), 
   .CLK(CLK), 
   .RESET(RESET), 
   .PKTSIZE(PKTSIZESHORT), 
   .INTERVAL(INTERVALSHORT), 
   .PACKETLIMIT(PACKETLIMITSHORT), 
   .PORTENABLE(PORTENABLE), 
   .SIZEP0(SIZEP0), 
   .SIZEP1(SIZEP1), 
   .SIZEP2(SIZEP2), 
   .SIZEP3(SIZEP3),    
   .SIZEVLD(SIZEVLD));

assign KILLSHORTY = KILLSHORTYSHORT | KILLSHORTYLONG;

endmodule

// *Complaints to: Eric Masson 
// *HALFSHORTY
// *A macro to be used internally within get shorty.
//  Calculates a clamp on small packets for one of long or short interval.
// *Please see the GETSHORTY macro for details.

module HALFSHORTY(/*AUTOARG*/
   // Outputs
   KILLSHORTY, 
   // Inputs
   CLK, RESET, PKTSIZE, INTERVAL, PACKETLIMIT, PORTENABLE, SIZEP0, 
   SIZEP1, SIZEP2, SIZEP3, SIZEVLD
   );

parameter Cycle_Width = 1;                 // # of bits needed for Cycles
parameter [Cycle_Width-1:0] Cycles = 1'b1; // # of core clocks per unit interval

parameter Width = 6;             // width in bits of sizes to compare
parameter [0:0] TMmode = 1'b1;   // tm offsets are passed, not sizes

input              CLK;          // core clock
input              RESET;        // core clock reset

input [Width-1:0]  PKTSIZE;      // threshold packet size

input [14:0]       INTERVAL;     // duration of interval in unit intervals
input [14:0]       PACKETLIMIT;  // packet limit on interval
input  [3:0]       PORTENABLE;   // 3 is port 3, ..., 0 is port 0.

input  [Width-1:0] SIZEP0;       // incoming size on port 0
input  [Width-1:0] SIZEP1;       // incoming size on port 1
input  [Width-1:0] SIZEP2;       // incoming size on port 2
input  [Width-1:0] SIZEP3;       // incoming size on port 3

input  [3:0]       SIZEVLD;      // incoming size is valid

output [3:0]       KILLSHORTY;   // kill short packet on port 0,1,2,3
reg    [3:0]       KILLSHORTY;

////////////////////////
// PKTSIZE TO COMPARE // (returns packet size, the packet size to compare)
////////////////////////

wire [Width-1:0] pktsize_raw;
wire [Width:0] pktsize; 

DFF #(Width) U_SIZE0 (.q(pktsize_raw), .d(PKTSIZE), .clk(CLK));

// programmed packet size is 0==64 (this is the exception).
//                           1==1
//                           2==2 
//                            ...
//                          63==63
//
// For TM, pktsize 0 -> 63
//                 1 -> 0
//                 2 -> 1
//                  ...
//                63 -> 62
//

wire [Width:0] pktsizeD = {TMmode ? {1'b0,pktsize_raw - 1'b1} : 
                                    {~|pktsize_raw, pktsize_raw}};

DFF #(Width+1) U_SIZE1 (.q(pktsize), .d(pktsizeD), .clk(CLK));

//////////////////////////
// PORT VALID and TIMER //
//////////////////////////

wire [3:0] portenable;
wire [14:0] interval;

DFF #(4) U_PEN (.q(portenable), .d(PORTENABLE), .clk(CLK));
DFF #(15) U_INTERVAL (.q(interval), .d(INTERVAL), .clk(CLK)); 

// Don't reflop, the path of comparison also goes through an adder!
wire [14:0] pktlimit_raw;
DFF #(15) U_RAWLIMIT (.q(pktlimit_raw), .d(PACKETLIMIT), .clk(CLK));
wire [14:0] pktlimit = {&pktlimit_raw ? {15{1'b1}} : pktlimit_raw + 1'b1};

///////////////////
// CYCLE COUNTER // (returns interval_unit to determine)
///////////////////

wire [Cycle_Width-1:0] cycle_countQ;
wire interval_unit = cycle_countQ==(Cycles-1'b1);
wire [Cycle_Width-1:0] cycle_countD = {interval_unit ?
                                      {Cycle_Width{1'b0}}:cycle_countQ+1'b1};

DFFR #(Cycle_Width, {Cycle_Width{1'b0}}) U_CYCLE
  (.q(cycle_countQ), .d(cycle_countD), .clk(CLK), .reset(RESET));

//////////////////////
// INTERVAL COUNTER //  (returns period to refresh limit counters)
//////////////////////

wire [14:0] interval_countQ;
wire periodD = (interval_countQ==interval) & interval_unit;
wire [14:0] interval_countD = {periodD ?
                               15'b1: interval_countQ + interval_unit};

DFFR #(15,15'b1) U_INTCOUNT
   (.q(interval_countQ), .d(interval_countD), .clk(CLK), .reset(RESET));

wire period;
DFFR #(1,1'b0) U_PERIOD (.q(period), .d(periodD), .clk(CLK), .reset(RESET));

/////////////////////////
// COUNT SMALL PACKETS //
/////////////////////////

wire [14:0] pktcountQ;
wire [14:0] pktcountD;
DFFR #(15,15'b0) U_PKTCOUNT (.q(pktcountQ), .d(pktcountD), 
                             .clk(CLK),     .reset(RESET));

// Keep track of sum 
// Must store addition results in flops, does not meet timing otherwise.
wire [14:0] pktcountplus1Q;
wire [14:0] pktcountplus2Q;
wire [14:0] pktcountplus3Q;
wire [14:0] pktcountplus4Q;

wire [14:0] pktcountplus1D;
wire [14:0] pktcountplus2D;
wire [14:0] pktcountplus3D;
wire [14:0] pktcountplus4D;

DFFR #(15,15'd1) U_PKTP1 (.q(pktcountplus1Q), .d(pktcountplus1D),
                          .clk(CLK),          .reset(RESET));
DFFR #(15,15'd2) U_PKTP2 (.q(pktcountplus2Q), .d(pktcountplus2D),
                          .clk(CLK),          .reset(RESET));
DFFR #(15,15'd3) U_PKTP3 (.q(pktcountplus3Q), .d(pktcountplus3D),
                          .clk(CLK),          .reset(RESET));
DFFR #(15,15'd4) U_PKTP4 (.q(pktcountplus4Q), .d(pktcountplus4D),
                          .clk(CLK),          .reset(RESET));

/////////////////////////////////////////////
// Determine if tiny packets are coming in // (and how many)
/////////////////////////////////////////////

wire [3:0] pkttiny= ({SIZEP3<=pktsize[Width-1:0], SIZEP2<=pktsize[Width-1:0], 
                      SIZEP1<=pktsize[Width-1:0], SIZEP0<=pktsize[Width-1:0]}
                  | {4{pktsize[Width]}})  // can only be true in non-TM mode
                  & portenable & SIZEVLD;

wire [2:0] tinyadd;

assign tinyadd[2] =   &pkttiny;
assign tinyadd[1] = (~&pkttiny) &  |pkttiny[2:0] & |pkttiny[3:1]  
                                & (|pkttiny[1:0]   | pkttiny[3])
                                & (|pkttiny[3:2]   | pkttiny[0]);
assign tinyadd[0] =   ^pkttiny;

// actual count to add
SATADD #(15) U0_SATADD 
   (.X(pktcountD),      .A(period ? 15'd0 : pktcountQ), 
                        .B({12'b0,tinyadd & {3{~period}}}));

// predicted value in case of 0, 1, 2, 3, or 4 small packets.
SATADD #(15) U1_SATADD
   (.X(pktcountplus1D), .A(period ? 15'd1 : pktcountplus1Q), 
                        .B({12'b0,tinyadd & {3{~period}}}));
SATADD #(15) U2_SATADD
   (.X(pktcountplus2D), .A(period ? 15'd2 : pktcountplus2Q), 
                        .B({12'b0,tinyadd & {3{~period}}}));
SATADD #(15) U3_SATADD
   (.X(pktcountplus3D), .A(period ? 15'd3 : pktcountplus3Q), 
                        .B({12'b0,tinyadd & {3{~period}}}));
SATADD #(15) U4_SATADD
   (.X(pktcountplus4D), .A(period ? 15'd4 : pktcountplus4Q), 
                        .B({12'b0,tinyadd & {3{~period}}}));

reg  limitreachedD; 
wire limitreachedQ;

wire pktcountplus1kill = pktcountplus1Q==pktlimit | limitreachedQ;
wire pktcountplus2kill = pktcountplus2Q==pktlimit | pktcountplus1kill;
wire pktcountplus3kill = pktcountplus3Q==pktlimit | pktcountplus2kill;
wire pktcountplus4kill = pktcountplus4Q==pktlimit | pktcountplus3kill;

always @(/*AS*/limitreachedQ or period or pktcountplus1kill
	 or pktcountplus2kill or pktcountplus3kill
	 or pktcountplus4kill or tinyadd)
begin
   if (period)   limitreachedD = 1'b0;
   else
      case (tinyadd[1:0])
       2'b00:   limitreachedD = limitreachedQ | pktcountplus4kill & tinyadd[2];
       2'b01:   limitreachedD = limitreachedQ | pktcountplus1kill;
       2'b10:   limitreachedD = limitreachedQ | pktcountplus2kill;
       2'b11:   limitreachedD = limitreachedQ | pktcountplus3kill;
       default: limitreachedD = 1'bx;
      endcase
end

DFFR #(1,1'b0) U_LR (.q(limitreachedQ), .d(limitreachedD), 
                     .clk(CLK),         .reset(RESET));

always @(/*AS*/pktcountplus1kill or pktcountplus2kill
	 or pktcountplus3kill or pktcountplus4kill or pkttiny)
begin
 case (pkttiny)
   4'b0000: KILLSHORTY = 4'b0000;
   4'b0001: KILLSHORTY = {3'b0, pktcountplus1kill};
   4'b0010: KILLSHORTY = {2'b0, pktcountplus1kill, 1'b0};
   4'b0011: KILLSHORTY = {2'b0, pktcountplus2kill, pktcountplus1kill};

   4'b0100: KILLSHORTY = {1'b0, pktcountplus1kill, 2'b0};
   4'b0101: KILLSHORTY = {1'b0, pktcountplus2kill, 1'b0, pktcountplus1kill};
   4'b0110: KILLSHORTY = {1'b0, pktcountplus2kill, pktcountplus1kill, 1'b0};
   4'b0111: KILLSHORTY = {1'b0, pktcountplus3kill, pktcountplus2kill,
                                pktcountplus1kill};

   4'b1000: KILLSHORTY = {pktcountplus1kill, 3'b0};
   4'b1001: KILLSHORTY = {pktcountplus2kill, 2'b0, pktcountplus1kill};
   4'b1010: KILLSHORTY = {pktcountplus2kill, 1'b0, pktcountplus1kill, 1'b0};
   4'b1011: KILLSHORTY = {pktcountplus3kill, 1'b0, pktcountplus2kill,
                          pktcountplus1kill};

   4'b1100: KILLSHORTY = {pktcountplus2kill, pktcountplus1kill, 2'b0};
   4'b1101: KILLSHORTY = {pktcountplus3kill, pktcountplus2kill, 1'b0,
                          pktcountplus1kill};
   4'b1110: KILLSHORTY = {pktcountplus3kill, pktcountplus2kill,
                          pktcountplus1kill, 1'b0};
   4'b1111: KILLSHORTY = {pktcountplus4kill, pktcountplus3kill, 
                          pktcountplus2kill, pktcountplus1kill};

   default: KILLSHORTY = 4'bxxxx;
 endcase
end

endmodule

// *Complaints to: Eric Masson 
// *FLUSHMETER
// *A macro to determine whether flush should be activated or inactivated
//  based on FIFO fill level. The flush mechanisms kicks in when a high
//  watermark is reached and it is only deactivated once the low watermark
//  is reached. By reached it is implied 'equal to'.
// *Accepts a parameter:
//                    
//               Width  -- the address width of the FIFO size to compare
//
// *The following are inputs
//
//               HISTART    The high watermark level to start flushing
//               LOWSTOP    The low  watermark level to stop  flushing
//               FIFOLEVEL  The current FIFO level.
//               CLK        Clock
//               RESET      Soft Reset, active low.
//
// *The following is an output
//
//               FLUSH      Signal that flush should be executed
//
//  To disable the mechanism, program all ones on both watermarks.
//  To force flushing, program all HISTART=1, LOWSTOP=0 on watermarks.
//  To have a single watermark at HISTART, program LOWSTOP to be HISTART-1.
//  NEVER program LOWSTOP >= HISTART, it may cause oscillation on FLUSH.
//

module FLUSHMETER(/*AUTOARG*/
   // Outputs
   FLUSH, 
   // Inputs
   CLK, RESET, LOWSTOP, HISTART, FIFOLEVEL
   );

parameter Width = 11; // for a 2k address space...

input             CLK;
input             RESET;
input [Width-1:0] LOWSTOP;
input [Width-1:0] HISTART;
input [Width-1:0] FIFOLEVEL;

output FLUSH;

wire flushC = FLUSH ? FIFOLEVEL>LOWSTOP : FIFOLEVEL>=HISTART;
DFFR #(1,1'b0) U_DFFR (.q(FLUSH), .d(flushC), .clk(CLK), .reset(RESET));
endmodule


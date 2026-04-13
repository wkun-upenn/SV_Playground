
`include "meu.vh"

function [3:0] Decode2;
      input [1:0] encvec;
      begin
	 case (encvec)
	   2'b00: Decode2 = 4'h1;
	   2'b01: Decode2 = 4'h2;
	   2'b10: Decode2 = 4'h4;
	   2'b11: Decode2 = 4'h8;
	   default: Decode2 = 4'hx;
	 endcase // case(encvec)
      end
endfunction // Decode2

function [7:0] Decode3;
      input [2:0] encvec;
      begin
	 case (encvec)
	   3'b000: Decode3 = 8'h01;
	   3'b001: Decode3 = 8'h02;
	   3'b010: Decode3 = 8'h04;
	   3'b011: Decode3 = 8'h08;
	   3'b100: Decode3 = 8'h10;
	   3'b101: Decode3 = 8'h20;
	   3'b110: Decode3 = 8'h40;
	   3'b111: Decode3 = 8'h80;
	   default: Decode3 = 8'hxx;
	 endcase // case(encvec)
      end
endfunction // Decode3

function [1:0] Encode4;
      input [3:0] decvec;
      begin
	 case (decvec)
	   4'h1: Encode4 = 2'h0;
	   4'h2: Encode4 = 2'h1;
	   4'h4: Encode4 = 2'h2;
	   4'h8: Encode4 = 2'h3;
	   default: Encode4 = 2'bxx;
	 endcase // case(decvec)
      end
endfunction // Encode4

//
// Calculate Chunk Count
//
function [`MEU_CNK_CNT_WIDTH-1:0] MeuChunkCount;
      input [4:0] PktSize;
      input [4:0] Offset;
      input       DoubleBuf;
      input       FiveChannel;
      begin
	 // surefire lint_off ASWESB
	 case ({DoubleBuf,FiveChannel})
	   2'b00: MeuChunkCount = (((PktSize<<2)+PktSize)<<1) + Offset; // 10x
	   2'b01: MeuChunkCount = (((PktSize<<2)+PktSize))    + Offset; // 5x
	   2'b10: MeuChunkCount = (((PktSize<<2)+PktSize)<<2) + Offset; // 20x
	   2'b11: MeuChunkCount = (((PktSize<<2)+PktSize)<<1) + Offset; // 10x
	   default: MeuChunkCount = {`MEU_CNK_CNT_WIDTH{1'bx}};
	 endcase
	 // surefire lint_on ASWESB
      end
endfunction // MeuChunkCount

//
// Decode length information encoded in descriptor
//
function [`MEU_DESC_LEN_WIDTH-1:0] MeuLengthDecode;
      input [12:2] Descriptor;
      input        DoubleBuf;
      reg          Length0;
      begin
	 /* Set upper bits of length to zero if descriptor indicates all ones */
	 Length0 = (DoubleBuf ? (&Descriptor[12:10]) :
		    (&Descriptor[11:10]));
	 MeuLengthDecode[10] = ((Length0|~DoubleBuf) ? 1'b0 :
				Descriptor[12]);
	 MeuLengthDecode[9:8] = (Length0 ? 2'b00 :
				 Descriptor[11:10]);
	 MeuLengthDecode[7:0] = Descriptor[9:2];
      end
endfunction // MeuLengthDecode

//
// Decode hash encoded start channel
//
function [3:0] MeuStartChannel;
      input [1:0] Bank;
      input [3:0] StartIndex;
      input       FiveChannel;
      begin
	 MeuStartChannel[3:0] = ((FiveChannel)? {StartIndex[3:1],1'b0} :
				 {StartIndex[3:0]});
      end
endfunction // MeuStartChannel

function [9:0] Dec4x10;
      input [3:0] encvec;
      case (encvec)
	4'h0: Dec4x10 = 10'h001;
	4'h1: Dec4x10 = 10'h002;
	4'h2: Dec4x10 = 10'h004;
	4'h3: Dec4x10 = 10'h008;
	4'h4: Dec4x10 = 10'h010;
	4'h5: Dec4x10 = 10'h020;
	4'h6: Dec4x10 = 10'h040;
	4'h7: Dec4x10 = 10'h080;
	4'h8: Dec4x10 = 10'h100;
	4'h9: Dec4x10 = 10'h200;
	default: Dec4x10 = {10{1'bx}};
      endcase // case(encvec)
endfunction

//
// Determine current channel
//
function [9:0] MeuChannel;
      input [3:0] StartChannel; // Starting Channel
      input [4:0] Offset;       // Current offset
      input       FiveChannel;  // 5 vs. 10 channel
      
      reg   [4:0] OffsetLess10;
      reg   [4:0] OffsetLess5;
      reg   [3:0] OffsetMod10;
      reg   [3:0] OffsetMod5;
      reg   [3:0] OffsetChnl;
      reg   [9:0] ChannelDec;
      
      begin
	 OffsetLess10 = {Offset - 5'd10};
	 OffsetLess5  = {Offset - 5'd5};
	 OffsetMod10  = ((Offset<5'd10)? Offset[3:0] : OffsetLess10[3:0]);
	 OffsetMod5   = ((Offset<5'd5)?  Offset[3:0] : OffsetLess5[3:0]);
	 OffsetChnl   = ((FiveChannel)? {OffsetMod5[2:0],1'b0} : OffsetMod10);
	 ChannelDec   = Dec4x10(StartChannel);
	 case (OffsetChnl)
	   4'h0:    MeuChannel = ChannelDec;
	   4'h1:    MeuChannel = {ChannelDec[8:0],ChannelDec[9]};
	   4'h2:    MeuChannel = {ChannelDec[7:0],ChannelDec[9:8]};
	   4'h3:    MeuChannel = {ChannelDec[6:0],ChannelDec[9:7]};
	   4'h4:    MeuChannel = {ChannelDec[5:0],ChannelDec[9:6]};
	   4'h5:    MeuChannel = {ChannelDec[4:0],ChannelDec[9:5]};
	   4'h6:    MeuChannel = {ChannelDec[3:0],ChannelDec[9:4]};
	   4'h7:    MeuChannel = {ChannelDec[2:0],ChannelDec[9:3]};
	   4'h8:    MeuChannel = {ChannelDec[1:0],ChannelDec[9:2]};
	   4'h9:    MeuChannel = {ChannelDec[0],ChannelDec[9:1]};
	   default: MeuChannel = {10{1'bx}};
	 endcase
      end
endfunction // MeuChannel

//
// Determine next channel
//
function [3:0] MeuNextChannel;
      input [3:0] Chnl;
      input       FiveChannel;
      
      reg   [3:0] ChnlInc1;
      reg   [3:0] ChnlInc2;

      begin
	 // surefire lint_off ASWEBB
	 ChnlInc1 = {(Chnl==4'h9)? 4'h0 : Chnl + 1};
	 ChnlInc2 = {(Chnl==4'h8)? 4'h0 : Chnl + 2};
	 // surefire lint_on  ASWEBB
	 MeuNextChannel = ((FiveChannel)? ChnlInc2 : ChnlInc1);
      end
endfunction // MeuNextChannel


//
// Determine current address
//
function [21:0] MeuAddress;
      input [21:0] Address;     // Address from descriptor
      input [4:0]  Offset;      // Current chunk count
      input        FiveChannel; // 5 vs. 10 channel
      input        DoubleBuf;   // Double vs. Single address per buffer
      
      reg          SecondBuf;
      
      begin
	 SecondBuf = (FiveChannel ? (Offset[4:0] > 5'b00100) :
		      (Offset[4:0] > 5'b01001));
	 MeuAddress[21:0] = (~DoubleBuf ? Address[21:0] :
			     ~SecondBuf ? {Address[21:1],1'b0} :
			     {Address[21:1],1'b1});
      end   
endfunction // MeuAddress

//
// Calculate Number of Buffers in packet
//
function [4:0] MeuBufCount;
      input [4:0]  LengthBy5;   // Descriptor Length Divided by 5
      input        EOP;
      input        DoubleBuf;   // Double vs. Single address per buffer
      input        FiveChannel; // 5 vs. 10 channel
      
      // surefire lint_off ASWEMS
      begin
	 casez ({EOP,DoubleBuf,FiveChannel})
	   3'b1??: MeuBufCount[4:0] = 5'b00000;  // Length = 1
	   3'b000: MeuBufCount[4:0] = ({1'b0, LengthBy5[4:1]}); // divby10
	   3'b001: MeuBufCount[4:0] = (       LengthBy5[4:0] ); // divby5
	   3'b010: MeuBufCount[4:0] = ({2'b00,LengthBy5[4:2]}); // divby20
	   3'b011: MeuBufCount[4:0] = ({1'b0, LengthBy5[4:1]}); // divby10
	   default: MeuBufCount[4:0] = 5'b00000;
	 endcase
      end
      // surefire lint_on ASWEMS
endfunction

//
// Rotate Left 4
//
function [3:0] RotLf4;
      input [3:0] vec;
      input [1:0] cnt;
      begin
	 case (cnt)
	   2'b00:   RotLf4 = {vec[2:0],vec[3]};
	   2'b01:   RotLf4 = {vec[1:0],vec[3:2]};
	   2'b10:   RotLf4 = {vec[0],vec[3:1]};
	   2'b11:   RotLf4 = vec;
	   default: RotLf4 = 4'hx;
	 endcase
      end
endfunction // RotLf4

//
// Rotate Right 4
//
function [3:0] RotRt4;
      input [3:0] vec;
      input [1:0] cnt;
      begin
	 case (cnt)
	   2'b00:   RotRt4 = {vec[0],vec[3:1]};
	   2'b01:   RotRt4 = {vec[1:0],vec[3:2]};
	   2'b10:   RotRt4 = {vec[2:0],vec[3]};
	   2'b11:   RotRt4 = vec;
	   default: RotRt4 = 4'hx;
	 endcase
      end
endfunction // RotRt4

//
// FindFirst4
// 
function [3:0] MeuFindFirst4;
      input  [3:0] vec;
      input  [1:0] last;
      begin
	 casez (RotRt4(vec,last))
	   4'b???1: MeuFindFirst4 = RotLf4(4'h1,last);
	   4'b??10: MeuFindFirst4 = RotLf4(4'h2,last);
	   4'b?100: MeuFindFirst4 = RotLf4(4'h4,last);
	   4'b1000: MeuFindFirst4 = RotLf4(4'h8,last);
	   default: MeuFindFirst4 = 4'h0;
	 endcase // case(vec)
      end
endfunction // MeuFindFirst4

	 

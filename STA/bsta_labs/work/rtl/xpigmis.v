
//mpp <clock=XpiCoreClk, reset=GlCoreResetR00C>

`include "xpiuc.vh"

module xpigmis
  (/*AUTOARG*/
   // Outputs
   XpiGmiNewRespP14S, XpiGmiDataP14S, XpiGmiStatusP14S, 
   XpiGmiTargetIDP14S, XpiGmiCmdP14S, XpiGmiIFifoRdEnP10S, 
   XpiGmiWrEnP15S, XpiGmiRdEnP15S, XpiGmiDataLenP15S, XpiGmiAddrP15S, 
   XpiGmiRdy4DataP15S, XpiGmiTOutP15S, 
   // Inputs
   GlCoreResetR00C, XpiCoreClk, XpiRbbNewReqP11S, XpiRbbTargetIDP11S, 
   XpiRbbCmdP11S, XpiRbbAddrP11S, XpiRbbDataLenP11S, 
   XpiRbbRdy4DataP11S, XpiRbbIFifoEmptyP11S, RexGmiDataRdyP10S, 
   RexGmiDataP10S, RexGmiRdy4MemTxnP10S, RexGmiStatusP10S
   );
  
  parameter       GMI_DATA_WIDTH   = 256;
  parameter 	  GMI_ADDR_WIDTH   = 32;
  parameter       GMI_MEM_ID       = 0;
  parameter 	  GMI_NUM_MEM      = 1;

  parameter [`RB_ADDR_WIDTH-1:0]  GMI_ADDR_REG_OFFSET = 
		  (GMI_MEM_ID==7) ? `RB_ADDR_WIDTH'h1fe :
		  (GMI_MEM_ID==6) ? `RB_ADDR_WIDTH'h1fc :
		  (GMI_MEM_ID==5) ? `RB_ADDR_WIDTH'h1fa :
		  (GMI_MEM_ID==4) ? `RB_ADDR_WIDTH'h1f8 :
		  (GMI_MEM_ID==3) ? `RB_ADDR_WIDTH'h1f6 :
		  (GMI_MEM_ID==2) ? `RB_ADDR_WIDTH'h1f4 :
		  (GMI_MEM_ID==1) ? `RB_ADDR_WIDTH'h1f2 :
		  `RB_ADDR_WIDTH'h1f0;

  parameter [`RB_ADDR_WIDTH-1:0]  GMI_MODE_REG_OFFSET = 
		  (GMI_MEM_ID==7) ? `RB_ADDR_WIDTH'h1ff :
		  (GMI_MEM_ID==6) ? `RB_ADDR_WIDTH'h1fd :
		  (GMI_MEM_ID==5) ? `RB_ADDR_WIDTH'h1fb :
		  (GMI_MEM_ID==4) ? `RB_ADDR_WIDTH'h1f9 :
		  (GMI_MEM_ID==3) ? `RB_ADDR_WIDTH'h1f7 :
		  (GMI_MEM_ID==2) ? `RB_ADDR_WIDTH'h1f5 :
		  (GMI_MEM_ID==1) ? `RB_ADDR_WIDTH'h1f3 :
		  `RB_ADDR_WIDTH'h1f1;

  // Computing the Stall Count
  parameter       GMI_WR_STALL_CNT = GMI_DATA_WIDTH/32-1;
    
  input 	                  GlCoreResetR00C;
  input 			  XpiCoreClk;
  
  //---- GMI->RBB Interface Signals ----
  input 			  XpiRbbNewReqP11S;
  input [`RB_TARGETID_WIDTH-1:0]  XpiRbbTargetIDP11S;
  input [`RB_CMD_WIDTH-1:0] 	  XpiRbbCmdP11S;  
  input [`RB_ADDR_WIDTH-1:0] 	  XpiRbbAddrP11S;
  input [`RB_DATA_WIDTH-1:0] 	  XpiRbbDataLenP11S;
  input 			  XpiRbbRdy4DataP11S;
  input 			  XpiRbbIFifoEmptyP11S;
  
  output 			  XpiGmiNewRespP14S;
  output [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataP14S;
  output [`RB_STATUS_WIDTH-1:0]   XpiGmiStatusP14S;
  output [`RB_TARGETID_WIDTH-1:0] XpiGmiTargetIDP14S;
  output [`RB_CMD_WIDTH-1:0] 	  XpiGmiCmdP14S;
  
  output 			  XpiGmiIFifoRdEnP10S;

  //---- GMI->Rex,TM & Tex Interface ----
  output 			  XpiGmiWrEnP15S;
  output 			  XpiGmiRdEnP15S;
  output [GMI_DATA_WIDTH-1:0] 	  XpiGmiDataLenP15S;
  output [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP15S;
  output 			  XpiGmiRdy4DataP15S; //surefire lint_off_line UDDOCU UDDOCN
  output 			  XpiGmiTOutP15S;
  
  input 			  RexGmiDataRdyP10S; // surefire lint_off_line UDDICU
  input [GMI_DATA_WIDTH-1:0] 	  RexGmiDataP10S;
  input 			  RexGmiRdy4MemTxnP10S; // surefire lint_off_line UDDICU
  input [`GMI_STATUS_WIDTH-1:0]   RexGmiStatusP10S;
  
  //---- Wire Declaration ----
  
  wire                            XpiGmiTOutP15S;

  wire [`CFG_WIDTH-1:0] 	  XpiGmiAddrRegP10C;
  wire [`CFG_WIDTH-1:0] 	  XpiGmiAddrRegP10S;
  wire [`CFG_WIDTH-1:0] 	  XpiGmiModeRegP10C;
  wire [`CFG_WIDTH-1:0] 	  XpiGmiModeRegP10S;
  
  wire 				  XpiGmiNewRespP14S;  
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataP14S;
  wire [`RB_CMD_WIDTH-1:0] 	  XpiGmiCmdP14S;
  wire [`RB_STATUS_WIDTH-1:0] 	  XpiGmiStatusP14S;
  wire [`RB_TARGETID_WIDTH-1:0]   XpiGmiTargetIDP14S;

  wire 				  XpiGmiValidMemTxnP10C;
  wire 				  XpiGmiValidCtlTxnP10C;
  wire 				  XpiGmiValidTxnP10C;
  wire 				  XpiGmiValidMemWrP10C;
  wire 				  XpiGmiValidPktP10C;
  wire 				  XpiGmiValidPktP11C;
  wire 				  XpiGmiValidPktP11S;
  wire 				  XpiGmiWrTxnP10C;
  wire 				  XpiGmiWrTxnP11C;
  wire 				  XpiGmiWrTxnP11S;
  wire 				  XpiGmiWrTxnP12C;
  wire 				  XpiGmiRdTxnP10C;
  wire 				  XpiGmiRdTxnP11C;
  wire 				  XpiGmiRdTxnP11S;
  wire 				  XpiGmiRdTxnP12C;
  wire 				  XpiGmiTOutReqP10C;
  wire 				  XpiGmiTOutP15C;
  
  wire [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP15C;
  wire [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP15S;
  wire [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP16S;
  
  wire 				  XpiGmiWrEnP15S;
  wire				  XpiGmiRdEnP15S;
  
  wire [287:0] 		          XpiGmiTotalCmpDataP10S; 
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW64CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW96CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW96CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW128CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW128CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW128CmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW160CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW160CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW160CmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW160CmpDataP13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW192CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW192CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW192CmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW192CmpDataP13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW192CmpDataP14S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP14S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW224CmpDataP15S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP10S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP14S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP15S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiW256CmpDataP16S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP11S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP14AS;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP15AS;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP16AS;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP17AS;

  reg [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataP14C;
  reg [`RB_STATUS_WIDTH-1:0] 	  XpiGmiStatusP14C; // surefire lint_off_line UDDSCU
  
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P18C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P18S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P17C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P17S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P16S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW256P16C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW160P15C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW160P15S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW128P14C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW128P14S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW96P13C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW96P13S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW64P12C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW64P12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiDataW32P11S;
  wire [GMI_DATA_WIDTH-1:0] 	  XpiGmiDataLenP14S;
  wire [GMI_DATA_WIDTH-1:0] 	  XpiGmiDataLenP15C;
  wire [GMI_DATA_WIDTH-1:0] 	  XpiGmiDataLenP15S;
  
  wire 				  XpiGmiAddrRegWrEnP10C;
  wire 				  XpiGmiAddrRegRdEnP10C;
  wire 				  XpiGmiAddrRegWrEnP10S;
  wire 				  XpiGmiAddrRegRdEnP10S;
  wire 				  XpiGmiModeRegWrEnP10C;
  wire 				  XpiGmiModeRegRdEnP10C;
  wire 				  XpiGmiModeRegRdEnP10S;
  
  wire 				  XpiGmiNewRespP13C;
  wire 				  XpiGmiNewRespP14C;

  wire 				  XpiGmiEmptyP12S;
  wire 				  XpiGmiMemWrStateP11C;
  wire 				  XpiGmiMemWrStateP11S;
  wire 				  XpiGmiStallIdleCmpltP10C;

  wire 				  XpiGmiRepeatEnP11C;
  wire 				  XpiGmiRptStartP11C;
  wire 				  XpiGmiRptStopP11C;
  wire 				  XpiGmiRptInProgP11C;
  wire 				  XpiGmiRptInProgP11S;
  wire [`GMI_NUM_REPEATS-1:0] 	  XpiGmiNumRepeatsP11C;
  wire [`GMI_NUM_REPEATS-1:0] 	  XpiGmiRptCntP11S;
  
  wire [GMI_DATA_WIDTH-1:0] 	  XpiGmiDataLenP14C;
  wire [255:0]                    XpiGmiTotalDataP14C; // surefire lint_off_line UDDSDN
  wire [2:0] 			  XpiGmiDataStallCntP10S;
  wire [`RB_TARGETID_WIDTH-1:0]   XpiGmiTargetIDP12C;
  wire [`RB_TARGETID_WIDTH-1:0]   XpiGmiTargetIDP12S;
  wire [5:0] 			  XpiGmiValidDataXfrP10S;
  wire [5:0] 			  XpiGmiWrLenP10S;
  wire 				  XpiGmiWrXfrCmpltP11C;
  wire [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP10S;

  wire [`GMI_MAX_BP_CNT-1:0] 	  XpiGmiBackPresCntP11S;

  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW32P11S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW64P12S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW96P13S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW128P14S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW160P15S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW256P16S;
  wire [`RB_ADDR_WIDTH-1:0] 	  XpiGmiAddrW256P17S;
  
  // surefire lint_off UDDSDN
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW32P10C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW64P10C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW96P10C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW128P10C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW160P10C;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsW256P10C;
  // surefire lint_on UDDSDN
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW32P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW32P12C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW32P12S;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW64P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW64P12C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW64P12S;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW96P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW96P12S;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW128P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW128P12C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW128P12S;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW160P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW160P12S;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW256P11C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW256P12C;
  wire [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW256P12S;
  wire [`RB_DATA_WIDTH-1:0] 	  XpiGmiNumRdLocsP13C;
  
  //---- Register Declaration ----

  reg [`RB_DATA_WIDTH-1:0] 	  XpiGmiCmpDataP14C;
  
  reg [GMI_ADDR_WIDTH-1:0] 	  XpiGmiAddrP10C;
  reg [`RB_CMD_WIDTH-1:0] 	  XpiGmiCmdP14C; // surefire lint_off_line UDDSCU
  
  reg 				  XpiGmiDataRdyP11S;
  
  reg 				  XpiGmiWrDataEnP10S;
  reg 				  XpiGmiMemWrStallP10S;
  reg 				  XpiGmiMemWrStateP10S;
  reg 				  XpiGmiRdEnP10S;

  reg 				  XpiGmiWrEnP10S;
  reg [5:0] 			  XpiGmiWrLenP10C;
  
  reg [2:0] 			  XpiGmiDataMuxSelP11S;
  reg [5:0] 			  XpiGmiValidDataXfrP10C;
  reg [2:0] 			  XpiGmiDataStallCntP10C;
  reg [`GMI_NUM_REPEATS-1:0] 	  XpiGmiRptCntP11C;
  reg [`GMI_MAX_BP_CNT-1:0] 	  XpiGmiBackPresCntP11C;
  
  reg [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW96P12C;
  reg [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsW160P12C;
  reg [3:0] 			  XpiGmiRdLenMuxSelW96P11C;
  reg [2:0] 			  XpiGmiRdLenMuxSelW160P11C;
  reg [`GMI_RDLEN_WIDTH-1:0] 	  XpiGmiNumRdLocsP12C;

  // This file contains legitimate comparisons between a
  // parameter (considered a constant) and a constant so:
  // surefire lint_off CWCCXX

  // This file contains comparisons between parts of
  // a 32-bit parameter and a wire so:
  // surefire lint_off PRMPTS
   
  //-------------------------------------
  //---- Write Control State Machine ----
  //-------------------------------------

  // Determining a Valid Transaction
  assign XpiGmiValidMemTxnP10C = 
	 (XpiRbbNewReqP11S && (XpiRbbCmdP11S!=`CTRLRD) && 
	 (XpiRbbTargetIDP11S[`RB_TARGETID_WIDTH-1:`RB_TARGETID_WIDTH-3]==GMI_MEM_ID[2:0]));

  assign XpiGmiValidCtlTxnP10C = (XpiGmiAddrRegRdEnP10C || XpiGmiModeRegRdEnP10C);

  assign XpiGmiValidTxnP10C = (XpiGmiValidMemTxnP10C || XpiGmiValidCtlTxnP10C);

  // Determining Valid Write Transaction
  assign XpiGmiValidMemWrP10C = (XpiGmiValidMemTxnP10C && (XpiRbbCmdP11S==`RBWR));
  
  assign XpiGmiValidPktP10C = (XpiGmiValidMemTxnP10C && (XpiRbbCmdP11S==`PKTRXXFR));
  
  assign XpiGmiWrTxnP10C = (XpiGmiValidMemWrP10C || XpiGmiValidPktP10C);
    
  // ReCirculating Write Transaction indication until Write is Started
  assign XpiGmiWrTxnP11C = (XpiGmiWrTxnP10C || XpiGmiWrEnP10S) ?
			     XpiGmiWrTxnP10C : XpiGmiWrTxnP11S;
  
  DFFR #(1,1'b0) U200_dff (.q(XpiGmiWrTxnP11S), .d(XpiGmiWrTxnP11C),
			   .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  assign XpiGmiWrTxnP12C = (XpiGmiWrTxnP10C || XpiGmiWrTxnP11S);
  
  // Determining Valid Read Transaction
  assign XpiGmiRdTxnP10C = (XpiGmiValidMemTxnP10C && (XpiRbbCmdP11S==`RBRD));
  
  // ReCirculating Read Transaction indication until Read is Started
  assign XpiGmiRdTxnP11C = (XpiGmiRdTxnP10C || XpiGmiRdEnP10S) ?
			     XpiGmiRdTxnP10C : XpiGmiRdTxnP11S;
  
  DFFR #(1,1'b0) U201_dff (.q(XpiGmiRdTxnP11S), .d(XpiGmiRdTxnP11C),
			   .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiRdTxnP12C = (XpiGmiRdTxnP10C || XpiGmiRdTxnP11S);

  // Determining Request TimeOut Request
  assign XpiGmiTOutReqP10C = 
	 (XpiRbbNewReqP11S && (XpiRbbCmdP11S == `TOUT) && 
	  (XpiRbbTargetIDP11S[`RB_TARGETID_WIDTH-1:`RB_TARGETID_WIDTH-3]==GMI_MEM_ID[2:0]));
      
  // ReCirculate Data Xfr State Indication
  assign XpiGmiMemWrStateP11C = 
	 (XpiGmiMemWrStateP10S || XpiRbbIFifoEmptyP11S) ?
	   XpiGmiMemWrStateP10S : XpiGmiMemWrStateP11S;
  
  DFFR #(1,1'b0) U52_dff (.q(XpiGmiMemWrStateP11S), .d(XpiGmiMemWrStateP11C),
			  .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  assign XpiGmiStallIdleCmpltP10C = (XpiGmiDataStallCntP10S == {GMI_WR_STALL_CNT[2:0] - 1'b1});
  
`define XPIGMIIDLE        3'b000
`define XPIGMIFIFOREAD    3'b001
`define XPIGMIMEMWRISSUE  3'b011
`define XPIGMIMEMWRSTALL  3'b010
`define XPIGMIMEMWRSTOP   3'b101
`define XPIGMIWRREPEAT    3'b111
`define XPIGMIWRRPTSTOP   3'b110
`define XPIGMIMEMRD       3'b100
  
  // Internal xpidmacpsyncstate variables
  wire [2:0] xpigmictlstate;
  reg [2:0]  next_xpigmictlstate;
  
  //---- State Change ----
  
  DFFR #(3,{3{1'b0}}) U1_dff (.q(xpigmictlstate), .d(next_xpigmictlstate),
			      .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //---- State Assignment ----
  
  always @(/*AS*/xpigmictlstate)
    begin     

      XpiGmiWrEnP10S               = 1'b0;
      XpiGmiWrDataEnP10S           = 1'b0;
      XpiGmiRdEnP10S               = 1'b0;
      XpiGmiMemWrStateP10S         = 1'b0;
      XpiGmiMemWrStallP10S         = 1'b0;
      
      case(xpigmictlstate)
	
	`XPIGMIIDLE:
	  begin
	    XpiGmiWrEnP10S       = 1'b0;
	    XpiGmiWrDataEnP10S   = 1'b0;
	    XpiGmiRdEnP10S       = 1'b0;
	    XpiGmiMemWrStateP10S = 1'b0;
	    XpiGmiMemWrStallP10S = 1'b0;
	  end
	
	`XPIGMIFIFOREAD:
	  begin
	    XpiGmiWrEnP10S       = 1'b0;
	    XpiGmiWrDataEnP10S   = 1'b1;
	    XpiGmiMemWrStallP10S = 1'b0;
	  end
	
	`XPIGMIMEMWRISSUE:
	  begin
	    XpiGmiWrEnP10S       = 1'b1;
	    XpiGmiWrDataEnP10S   = 1'b1;
	    XpiGmiMemWrStateP10S = 1'b1;
	  end
	
	`XPIGMIMEMWRSTALL:
	  begin
	    XpiGmiWrEnP10S       = 1'b0;
	    XpiGmiWrDataEnP10S   = 1'b1;
	    XpiGmiMemWrStallP10S = 1'b1;
	  end
	
	`XPIGMIMEMWRSTOP:
	  begin
	    XpiGmiWrEnP10S       = 1'b0;
	    XpiGmiWrDataEnP10S   = 1'b0;
	  end
	
	`XPIGMIWRREPEAT: XpiGmiWrEnP10S = 1'b1;
	    
	`XPIGMIWRRPTSTOP: XpiGmiWrEnP10S = 1'b0;

	`XPIGMIMEMRD: 
	  begin
	    XpiGmiRdEnP10S = 1'b1;
	  end
	
	default:
	  begin
	    XpiGmiWrEnP10S       = 1'b0;
	    XpiGmiWrDataEnP10S   = 1'b0;
	    XpiGmiRdEnP10S       = 1'b0;
	    XpiGmiMemWrStateP10S = 1'b0;
	    XpiGmiMemWrStallP10S = 1'b0;
	  end

      endcase // case(xpigmictlstate)
    end // always @ (...
  
  //---- State Transitions ----
  
  always @(/*AS*/RexGmiRdy4MemTxnP10S or XpiGmiRdTxnP12C
	   or XpiGmiRepeatEnP11C or XpiGmiRptInProgP11S
	   or XpiGmiRptStopP11C or XpiGmiStallIdleCmpltP10C
	   or XpiGmiWrTxnP12C or XpiGmiWrXfrCmpltP11C
	   or XpiRbbIFifoEmptyP11S or xpigmictlstate)
    begin
      
      case (xpigmictlstate)
	
	`XPIGMIIDLE:
	  begin
	    if (XpiGmiWrTxnP12C && RexGmiRdy4MemTxnP10S)
	      next_xpigmictlstate = `XPIGMIFIFOREAD;
	    else if (XpiGmiRdTxnP12C && RexGmiRdy4MemTxnP10S)
	      next_xpigmictlstate = `XPIGMIMEMRD;
	    else
	      next_xpigmictlstate = `XPIGMIIDLE;
	  end
	
	`XPIGMIFIFOREAD:
	  begin
	    if (GMI_DATA_WIDTH==32)
	      next_xpigmictlstate = `XPIGMIMEMWRISSUE;
	    else
	      next_xpigmictlstate = `XPIGMIMEMWRSTALL;
	  end
	
	`XPIGMIMEMWRISSUE:
	  begin
	    if ((GMI_DATA_WIDTH>32) && XpiRbbIFifoEmptyP11S)
	      // Data Write is complete, transition to Stop State,
	      // to wait for the final write to complete.
	      next_xpigmictlstate = `XPIGMIMEMWRSTOP;
	    else if ((GMI_DATA_WIDTH==32) && XpiRbbIFifoEmptyP11S)
	      next_xpigmictlstate = `XPIGMIIDLE;
	    else if ((GMI_DATA_WIDTH==32) && (~XpiRbbIFifoEmptyP11S))
	      // RexGmiRdy4MemTxnP10S is registered, hence there is once cycle
	      // skid before GMI observes its deassertion, forcing transition
	      // to Data Stop state to account for one clock cycle skid for 32b case
	      next_xpigmictlstate = `XPIGMIMEMWRSTOP;
	    else if (GMI_DATA_WIDTH>32 && (~XpiRbbIFifoEmptyP11S))
	      // Unconditionally transition to Stall State, for W>32
	      next_xpigmictlstate = `XPIGMIMEMWRSTALL;
	    else
	      next_xpigmictlstate = `XPIGMIMEMWRISSUE;
	  end
	
	`XPIGMIMEMWRSTALL:
	  begin
	    if (XpiGmiStallIdleCmpltP10C && RexGmiRdy4MemTxnP10S && (~XpiGmiRptInProgP11S))
	      // Idle cycles complete, transition to Data Xfr State
	      next_xpigmictlstate = `XPIGMIMEMWRISSUE;
	    else if (XpiGmiStallIdleCmpltP10C && RexGmiRdy4MemTxnP10S && XpiGmiRptInProgP11S)
	      // Idle cycles complete, transition to Data Xfr State
	      next_xpigmictlstate = `XPIGMIWRREPEAT;
	    else if (XpiGmiStallIdleCmpltP10C && (~RexGmiRdy4MemTxnP10S) && (~XpiGmiRptInProgP11S))
	      // Stall cycles modelled, sampling Target Ready, if
	      // backpressure exists, transition to Stop State
	      next_xpigmictlstate = `XPIGMIMEMWRSTOP;
	    else if (XpiGmiStallIdleCmpltP10C && (~RexGmiRdy4MemTxnP10S) && XpiGmiRptInProgP11S)
	      // Stall cycles modelled, sampling Target Ready, if
	      // backpressure exists, transition to Stop State
	      next_xpigmictlstate = `XPIGMIWRRPTSTOP;
	    else
	      next_xpigmictlstate = `XPIGMIMEMWRSTALL;
	  end // case: `XPIGMIMEMWRSTALL
	
	`XPIGMIMEMWRSTOP:
	  begin	    
	    if (XpiGmiWrXfrCmpltP11C && XpiGmiRepeatEnP11C)
	      // All Write Transfers complete, however Repeat Mode Enabled
	      // transition to WRREPEAT state to issue subsequent Writes
	      next_xpigmictlstate = `XPIGMIWRREPEAT;
	    else if (XpiGmiWrXfrCmpltP11C && (~XpiGmiRepeatEnP11C))
	      // Backpressure asserted during the last Data Xfr, 
	      // all data transfers complete, transition to Idle
	      next_xpigmictlstate = `XPIGMIIDLE;
	    else if (RexGmiRdy4MemTxnP10S)
	      // Data to transfer and no backpressure exist, 
	      // transition to Write Data Xfr state
	      next_xpigmictlstate = `XPIGMIMEMWRISSUE;
	    else
	      next_xpigmictlstate = `XPIGMIMEMWRSTOP;
	  end
	
	`XPIGMIWRREPEAT:
	  // RexGmiRdy4MemTxnP10S is registered, hence there is once cycle
	  // skid before GMI observes its deassertion, forcing transition
	  // to Data Stop state to account for one clock cycle skid for 32b case
	  next_xpigmictlstate = `XPIGMIWRRPTSTOP;
	
	`XPIGMIWRRPTSTOP:
	  begin
	    if (XpiGmiRptStopP11C)
	      // All Repetitions Complete
	      next_xpigmictlstate = `XPIGMIIDLE;
	    else if (RexGmiRdy4MemTxnP10S)
	      // Data to transfer and no backpressure exist, 
	      // transition to Write Data Xfr state
	      next_xpigmictlstate = `XPIGMIWRREPEAT;
	    else
	      next_xpigmictlstate = `XPIGMIWRRPTSTOP;
	  end
	  
	`XPIGMIMEMRD: next_xpigmictlstate = `XPIGMIIDLE;
	
	default: next_xpigmictlstate = `XPIGMIIDLE;
	
      endcase // case(xpigmictlstate)
    end // always @ (...
  
  //-------------------------------------------------------------------------
  //---- 3b Counter counting Bubbles between Writes for different Widths ----
  //-------------------------------------------------------------------------

  // Counter Counting Number of Idle Cycles in Write Stall State
  
  always @(/*AS*/XpiGmiDataStallCntP10S or XpiGmiMemWrStallP10S
	   or XpiGmiMemWrStateP10S)
    begin
      if (XpiGmiMemWrStallP10S)
	XpiGmiDataStallCntP10C = {XpiGmiDataStallCntP10S + 3'b001};
      else if (XpiGmiMemWrStateP10S)
	XpiGmiDataStallCntP10C = 3'b000;
      else if (XpiGmiDataStallCntP10S == 3'b111)
	XpiGmiDataStallCntP10C = 3'b000;
      else
	XpiGmiDataStallCntP10C = XpiGmiDataStallCntP10S;
    end // always @ (...
  
  DFFR #(3,{3{1'b0}}) U15_dff
    (.q(XpiGmiDataStallCntP10S), .d(XpiGmiDataStallCntP10C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //--------------------------------------------------
  //---- GMI Address and Mode Register Operations ----
  //--------------------------------------------------
 
  assign XpiGmiAddrRegWrEnP10C = (XpiRbbNewReqP11S && (XpiRbbCmdP11S == `CTRLWR) &&
				  (XpiRbbAddrP11S == GMI_ADDR_REG_OFFSET[`RB_ADDR_WIDTH-1:0]));

  assign XpiGmiModeRegWrEnP10C = (XpiRbbNewReqP11S && (XpiRbbCmdP11S == `CTRLWR) &&
				  (XpiRbbAddrP11S == GMI_MODE_REG_OFFSET[`RB_ADDR_WIDTH-1:0]));
  
  assign XpiGmiAddrRegRdEnP10C = (XpiRbbNewReqP11S && (XpiRbbCmdP11S == `CTRLRD) &&
				  (XpiRbbAddrP11S == GMI_ADDR_REG_OFFSET[`RB_ADDR_WIDTH-1:0]));
  
  assign XpiGmiModeRegRdEnP10C = (XpiRbbNewReqP11S && (XpiRbbCmdP11S == `CTRLRD) &&
				  (XpiRbbAddrP11S == GMI_MODE_REG_OFFSET[`RB_ADDR_WIDTH-1:0]));
  
  // GMI Address Register
  assign XpiGmiAddrRegP10C = XpiGmiAddrRegWrEnP10C ? XpiRbbDataLenP11S : XpiGmiAddrRegP10S;
  
  DFFR #(`CFG_WIDTH,{`CFG_WIDTH{1'b0}}) U2_dff (.q(XpiGmiAddrRegP10S), .d(XpiGmiAddrRegP10C), 
						.clk(XpiCoreClk), .reset(GlCoreResetR00C));

  // GMI Mode Register
  assign XpiGmiModeRegP10C = XpiGmiModeRegWrEnP10C ? XpiRbbDataLenP11S : XpiGmiModeRegP10S;
  
  DFFR #(`CFG_WIDTH,`CFG_WIDTH'hffff0000) U9_dff (.q(XpiGmiModeRegP10S), .d(XpiGmiModeRegP10C), 
						.clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(1,1'b0) U3_dff (.q(XpiGmiAddrRegWrEnP10S), .d(XpiGmiAddrRegWrEnP10C), 
			 .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(1,1'b0) U4_dff (.q(XpiGmiAddrRegRdEnP10S), .d(XpiGmiAddrRegRdEnP10C), 
			 .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(1,1'b0) U7_dff (.q(XpiGmiModeRegRdEnP10S), .d(XpiGmiModeRegRdEnP10C), 
			 .clk(XpiCoreClk), .reset(GlCoreResetR00C)); 

  //---- Parsing the Mode Register ----
 
  assign XpiGmiRepeatEnP11C   = XpiGmiModeRegP10S[2];
  assign XpiGmiNumRepeatsP11C = XpiGmiModeRegP10S[15:3];

  //---- Flopping the Fifo Empty Signal ----
  
  DFFR #(1,1'b0) U23_dff (.q(XpiGmiEmptyP12S), .d(XpiRbbIFifoEmptyP11S),
			  .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //-------------------------------------
  //---- GMI IFifo Read Enable Logic ----
  //-------------------------------------

  assign XpiGmiIFifoRdEnP10S = (XpiGmiWrDataEnP10S && (~XpiGmiRptInProgP11S));
    
  //-----------------------------------------------
  //---- Length Determination for Read Request ----
  //-----------------------------------------------  
  
  // Num of Locations for 32b wide memory = #bytes/4
  assign XpiGmiNumRdLocsW32P10C = {XpiRbbDataLenP11S>>2};
  assign XpiGmiNumRdLocsW32P11C = XpiGmiNumRdLocsW32P10C[`GMI_RDLEN_WIDTH-1:0];

  assign XpiGmiNumRdLocsW32P12C = XpiGmiRdTxnP10C ?
	 XpiGmiNumRdLocsW32P11C : XpiGmiNumRdLocsW32P12S;

  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U80_dff
    (.q(XpiGmiNumRdLocsW32P12S), .d(XpiGmiNumRdLocsW32P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Num of Locations for 64b wide memory = #bytes/8
  assign XpiGmiNumRdLocsW64P10C  = {XpiRbbDataLenP11S>>3};
  assign XpiGmiNumRdLocsW64P11C = XpiGmiNumRdLocsW64P10C[`GMI_RDLEN_WIDTH-1:0];
  
  assign XpiGmiNumRdLocsW64P12C = XpiGmiRdTxnP10C ?
	 XpiGmiNumRdLocsW64P11C : XpiGmiNumRdLocsW64P12S;

  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U81_dff
    (.q(XpiGmiNumRdLocsW64P12S), .d(XpiGmiNumRdLocsW64P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Num of Locations for 128b wide memory = #bytes/16
  assign XpiGmiNumRdLocsW128P10C = {XpiRbbDataLenP11S>>4};
  assign XpiGmiNumRdLocsW128P11C = XpiGmiNumRdLocsW128P10C[`GMI_RDLEN_WIDTH-1:0];

  assign XpiGmiNumRdLocsW128P12C = XpiGmiRdTxnP10C ?
	 XpiGmiNumRdLocsW128P11C : XpiGmiNumRdLocsW128P12S;

  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U82_dff
    (.q(XpiGmiNumRdLocsW128P12S), .d(XpiGmiNumRdLocsW128P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Num of Locations for 256b wide memory = #bytes/32
  assign XpiGmiNumRdLocsW256P10C = {XpiRbbDataLenP11S>>5};
  assign XpiGmiNumRdLocsW256P11C = XpiGmiNumRdLocsW256P10C[`GMI_RDLEN_WIDTH-1:0];
  
  assign XpiGmiNumRdLocsW256P12C = XpiGmiRdTxnP10C ?
	 XpiGmiNumRdLocsW256P11C : XpiGmiNumRdLocsW256P12S;

  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U83_dff
    (.q(XpiGmiNumRdLocsW256P12S), .d(XpiGmiNumRdLocsW256P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //----------------------------------------------------------------------
  //---- Number of Locations Computation for 96b & 160b Memory Widths ----
  //----------------------------------------------------------------------
  // Number of Bytes in Read is guaranteed to be multiple of 32b.
  // and Ring Bus MTU for W96 & W160 = 120B, hence modelling a LookUp Table
  // Technique to convert number of bytes into number of memory locations
  
  //---- W=96b, #bytes/12 = #bytes/{4*3} ----
  
  assign XpiGmiNumRdLocsW96P10C = {XpiRbbDataLenP11S>>2};
  assign XpiGmiNumRdLocsW96P11C = XpiGmiNumRdLocsW96P10C[`GMI_RDLEN_WIDTH-1:0];
  
  // Mux Select Logic for Divide by 3 Operation

  always @(/*AS*/XpiGmiNumRdLocsW96P11C)
    begin
      case (XpiGmiNumRdLocsW96P11C)
	`GMI_RDLEN_WIDTH'h00 : XpiGmiRdLenMuxSelW96P11C = 4'h0;
	`GMI_RDLEN_WIDTH'h03 : XpiGmiRdLenMuxSelW96P11C = 4'h1;
	`GMI_RDLEN_WIDTH'h06 : XpiGmiRdLenMuxSelW96P11C = 4'h2;
	`GMI_RDLEN_WIDTH'h09 : XpiGmiRdLenMuxSelW96P11C = 4'h3;
	`GMI_RDLEN_WIDTH'h0c : XpiGmiRdLenMuxSelW96P11C = 4'h4;
	`GMI_RDLEN_WIDTH'h0f : XpiGmiRdLenMuxSelW96P11C = 4'h5;
	`GMI_RDLEN_WIDTH'h12 : XpiGmiRdLenMuxSelW96P11C = 4'h6;
	`GMI_RDLEN_WIDTH'h15 : XpiGmiRdLenMuxSelW96P11C = 4'h7;
	`GMI_RDLEN_WIDTH'h18 : XpiGmiRdLenMuxSelW96P11C = 4'h8;
	`GMI_RDLEN_WIDTH'h1b : XpiGmiRdLenMuxSelW96P11C = 4'h9;
	`GMI_RDLEN_WIDTH'h1e : XpiGmiRdLenMuxSelW96P11C = 4'ha;
	default  : XpiGmiRdLenMuxSelW96P11C = 4'h0;
      endcase // case(XpiGmiNumRdLocsW96P11C)
    end // always @ (...
  
  // Selecting Appropriate Number of Locations value

  always @(/*AS*/XpiGmiNumRdLocsW96P12S or XpiGmiRdLenMuxSelW96P11C)
    begin
      case(XpiGmiRdLenMuxSelW96P11C)
	4'h0: XpiGmiNumRdLocsW96P12C = XpiGmiNumRdLocsW96P12S;
	4'h1: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h01;
	4'h2: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h02;
	4'h3: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h03;
	4'h4: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h04;
	4'h5: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h05;
	4'h6: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h06;
	4'h7: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h07;
	4'h8: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h08;
	4'h9: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h09;
	4'ha: XpiGmiNumRdLocsW96P12C = `GMI_RDLEN_WIDTH'h0a;
	default: XpiGmiNumRdLocsW96P12C = XpiGmiNumRdLocsW96P12S;
      endcase // case(XpiGmiRdLenMuxSelW96P11C)
    end // always @ (...
  
  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U84_dff
    (.q(XpiGmiNumRdLocsW96P12S), .d(XpiGmiNumRdLocsW96P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  //---- W=160b, #bytes/20 = #bytes/{4*5} ----
  
  assign XpiGmiNumRdLocsW160P10C = {XpiRbbDataLenP11S>>2};
  assign XpiGmiNumRdLocsW160P11C = XpiGmiNumRdLocsW160P10C[`GMI_RDLEN_WIDTH-1:0];
    
  // Mux Select Logic for Divide by 5 Operation
  
  always @(/*AS*/XpiGmiNumRdLocsW160P11C)
    begin
      case (XpiGmiNumRdLocsW160P11C)
	`GMI_RDLEN_WIDTH'h00 : XpiGmiRdLenMuxSelW160P11C = 3'b000;
	`GMI_RDLEN_WIDTH'h05 : XpiGmiRdLenMuxSelW160P11C = 3'b001;
	`GMI_RDLEN_WIDTH'h0a : XpiGmiRdLenMuxSelW160P11C = 3'b010;
	`GMI_RDLEN_WIDTH'h0f : XpiGmiRdLenMuxSelW160P11C = 3'b011;
	`GMI_RDLEN_WIDTH'h14 : XpiGmiRdLenMuxSelW160P11C = 3'b100;
	`GMI_RDLEN_WIDTH'h19 : XpiGmiRdLenMuxSelW160P11C = 3'b101;
	`GMI_RDLEN_WIDTH'h1e : XpiGmiRdLenMuxSelW160P11C = 3'b110;
	default              : XpiGmiRdLenMuxSelW160P11C = 3'b000;
      endcase // case(XpiGmiNumRdLocsW160P11C)
    end // always @ (...
    
  // Selecting Appropriate Number of Locations value

  always @(/*AS*/XpiGmiNumRdLocsW160P12S or XpiGmiRdLenMuxSelW160P11C)
    begin
      case(XpiGmiRdLenMuxSelW160P11C)
	3'b000 : XpiGmiNumRdLocsW160P12C = XpiGmiNumRdLocsW160P12S;
	3'b001 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h01;
	3'b010 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h02;
	3'b011 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h03;
	3'b100 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h04;
	3'b101 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h05;
	3'b110 : XpiGmiNumRdLocsW160P12C = `GMI_RDLEN_WIDTH'h06;
	default: XpiGmiNumRdLocsW160P12C = XpiGmiNumRdLocsW160P12S;
      endcase // case(XpiGmiRdLenMuxSelW160P11C)
    end // always @ (...
  
  DFFR #(`GMI_RDLEN_WIDTH,{`GMI_RDLEN_WIDTH{1'b0}}) U85_dff
    (.q(XpiGmiNumRdLocsW160P12S), .d(XpiGmiNumRdLocsW160P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  //-----------------------------------------------------
  //---- Read Length Selection based on Memory Width ----
  //-----------------------------------------------------

  always @(/*AS*/XpiGmiNumRdLocsW128P12S or XpiGmiNumRdLocsW160P12S
	   or XpiGmiNumRdLocsW256P12S or XpiGmiNumRdLocsW32P12S
	   or XpiGmiNumRdLocsW64P12S or XpiGmiNumRdLocsW96P12S)
    begin
      if (GMI_DATA_WIDTH==256)
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW256P12S;
      else if (GMI_DATA_WIDTH==160)
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW160P12S;
      else if (GMI_DATA_WIDTH==128)
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW128P12S;
      else if (GMI_DATA_WIDTH==96)
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW96P12S;
      else if (GMI_DATA_WIDTH==64)
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW64P12S;
      else
	XpiGmiNumRdLocsP12C = XpiGmiNumRdLocsW32P12S;
    end	

  //------------------------------------------------------
  //---- GMI Data Stacking Flops for Width Conversion ----
  //------------------------------------------------------
  
  assign XpiGmiDataW32P11S = XpiRbbDataLenP11S;
  
  assign XpiGmiDataW64P12C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW32P11S : XpiGmiDataW64P12S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U61_dff 
    (.q(XpiGmiDataW64P12S), .d(XpiGmiDataW64P12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW96P13C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW64P12S : XpiGmiDataW96P13S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U62_dff 
    (.q(XpiGmiDataW96P13S), .d(XpiGmiDataW96P13C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW128P14C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW96P13S : XpiGmiDataW128P14S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U63_dff 
    (.q(XpiGmiDataW128P14S), .d(XpiGmiDataW128P14C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW160P15C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW128P14S : XpiGmiDataW160P15S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U64_dff 
    (.q(XpiGmiDataW160P15S), .d(XpiGmiDataW160P15C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW256P16C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW160P15S : XpiGmiDataW256P16S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U65_dff 
    (.q(XpiGmiDataW256P16S), .d(XpiGmiDataW256P16C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW256P17C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW256P16S : XpiGmiDataW256P17S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U66_dff 
    (.q(XpiGmiDataW256P17S), .d(XpiGmiDataW256P17C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiDataW256P18C = XpiGmiIFifoRdEnP10S ?
	 XpiGmiDataW256P17S : XpiGmiDataW256P18S;
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U67_dff 
    (.q(XpiGmiDataW256P18S), .d(XpiGmiDataW256P18C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  //---------------------------------------------------------
  //---- Aligning Packet Control Information with Enable ----
  //---------------------------------------------------------
  // Packet Control Info is overloaded on Address bus
  // Modelling delay of 8 clocks for 32b->256b alignment
  
  assign XpiGmiAddrW32P11S = XpiRbbAddrP11S;
  
  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U71_dff 
    (.q(XpiGmiAddrW64P12S), .d(XpiGmiAddrW32P11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U72_dff 
    (.q(XpiGmiAddrW96P13S), .d(XpiGmiAddrW64P12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U73_dff 
    (.q(XpiGmiAddrW128P14S), .d(XpiGmiAddrW96P13S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U74_dff 
    (.q(XpiGmiAddrW160P15S), .d(XpiGmiAddrW128P14S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U75_dff 
    (.q(XpiGmiAddrW256P16S), .d(XpiGmiAddrW160P15S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_ADDR_WIDTH,{`RB_ADDR_WIDTH{1'b0}}) U76_dff 
    (.q(XpiGmiAddrW256P17S), .d(XpiGmiAddrW256P16S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));


  //---------------------------
  //---- Output Data Stage ----
  //---------------------------
 
  assign XpiGmiTotalDataP14C = {XpiGmiDataW32P11S,XpiGmiDataW64P12S,
				XpiGmiDataW96P13S,XpiGmiDataW128P14S,
				XpiGmiDataW160P15S,XpiGmiDataW256P16S,
				XpiGmiDataW256P17S,XpiGmiDataW256P18S};
  
  assign XpiGmiDataLenP14C = XpiGmiTotalDataP14C[255:256-GMI_DATA_WIDTH];

  assign XpiGmiNumRdLocsP13C = {{{`RB_DATA_WIDTH-`GMI_RDLEN_WIDTH}{1'b0}},XpiGmiNumRdLocsP12C};

  // ReCirculating the Data for Repeat Mode
  assign XpiGmiDataLenP15C = XpiGmiRptInProgP11C ?
	 XpiGmiDataLenP14S : XpiGmiDataLenP14C;
  
  assign XpiGmiDataLenP15S = XpiGmiRdEnP15S ?
	 XpiGmiNumRdLocsP13C : XpiGmiDataLenP15C;
  
  //----------------------  
  //---- Write Enable ----
  //----------------------

  assign XpiGmiWrEnP15S = XpiGmiWrEnP10S;

  //-------------------------------
  //---- Data Transfer Counter ----
  //-------------------------------
  // This counter counts the total number of 4B Valid Data Xfers occuring.
    
  always @(/*AS*/XpiGmiRptInProgP11S or XpiGmiTOutReqP10C
	   or XpiGmiValidDataXfrP10S or XpiGmiWrEnP15S
	   or XpiGmiWrXfrCmpltP11C)
    begin
      if ((GMI_DATA_WIDTH==32) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b000001};
      else if ((GMI_DATA_WIDTH==64) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b000010};
      else if ((GMI_DATA_WIDTH==96) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b000011};
      else if ((GMI_DATA_WIDTH==128) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b000100};
      else if ((GMI_DATA_WIDTH==160) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b000101};
      else if ((GMI_DATA_WIDTH==256) && XpiGmiWrEnP15S && (~XpiGmiRptInProgP11S))
	XpiGmiValidDataXfrP10C = {XpiGmiValidDataXfrP10S + 6'b001000};
      else if (XpiGmiWrXfrCmpltP11C || XpiGmiTOutReqP10C)
	XpiGmiValidDataXfrP10C = {6{1'b0}};
      else 
	XpiGmiValidDataXfrP10C = XpiGmiValidDataXfrP10S;
    end // always @ (...
  
  DFFR #(6,{6{1'b0}}) U16_dff
    (.q(XpiGmiValidDataXfrP10S), .d(XpiGmiValidDataXfrP10C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
    
  // Storing Write Length (Number of 4B Chunks) Information

  always @(/*AS*/XpiGmiTOutReqP10C or XpiGmiWrLenP10S
	   or XpiGmiWrTxnP10C or XpiRbbDataLenP11S)
    begin
      if (XpiGmiWrTxnP10C)
	// New Write Request, Capture Length
	XpiGmiWrLenP10C = XpiRbbDataLenP11S[5:0];
      else if (XpiGmiTOutReqP10C)
	// Reset Write Length upon TimeOut
	XpiGmiWrLenP10C = {6{1'b0}};
      else
	XpiGmiWrLenP10C = XpiGmiWrLenP10S;
    end
  
  DFFR #(6,{6{1'b0}}) U38_dff 
    (.q(XpiGmiWrLenP10S), .d(XpiGmiWrLenP10C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Determining issuing of Write with Stored amount of Write Data
  // GMI can actually send more data if software misprograms
  assign XpiGmiWrXfrCmpltP11C = ((XpiGmiValidDataXfrP10S >= XpiGmiWrLenP10S) &&
				 (XpiGmiValidDataXfrP10S > 6'b000000));
  
  //---------------------------
  //---- Repeat Mode Logic ----
  //---------------------------
  
  // Flopping Muxed Data to accout for One Core Clock Cycle Skid,
  // after Combinatorial deassertion of Write En upon deassertion
  // of RexGmiRdy4MemTxnP10S
  
  DFFR #(GMI_DATA_WIDTH,{GMI_DATA_WIDTH{1'b0}}) U56_dff 
    (.q(XpiGmiDataLenP14S), .d(XpiGmiDataLenP15C), 
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  // Repeat Start Indicator
  assign XpiGmiRptStartP11C = (XpiGmiWrXfrCmpltP11C && XpiGmiRepeatEnP11C);
  
  // Repeat Stop Indicator
  assign XpiGmiRptStopP11C = (XpiGmiRptCntP11S==XpiGmiNumRepeatsP11C);
  
  // Repeat Duration Pulse : remains asserted throughout the Repeat Operation
  assign XpiGmiRptInProgP11C = (XpiGmiRptStartP11C || XpiGmiRptStopP11C) ?
				 XpiGmiRptStartP11C  : XpiGmiRptInProgP11S;
  
  DFFR #(1,1'b0) U10_dff (.q(XpiGmiRptInProgP11S), .d(XpiGmiRptInProgP11C),
			  .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  // 13b Counter counting Number of Repetitions
  
  always @(/*AS*/XpiGmiRptCntP11S or XpiGmiRptInProgP11C
	   or XpiGmiRptStopP11C or XpiGmiWrEnP15S)
    begin
      if (XpiGmiRptInProgP11C && XpiGmiWrEnP15S)
	XpiGmiRptCntP11C = {XpiGmiRptCntP11S+1'b1};
      else if (XpiGmiRptCntP11S == `GMI_NUM_REPEATS'h1fff)
	XpiGmiRptCntP11C = {`GMI_NUM_REPEATS{1'b0}};
      else if (XpiGmiRptStopP11C)
	XpiGmiRptCntP11C = {`GMI_NUM_REPEATS{1'b0}};
      else
	XpiGmiRptCntP11C = XpiGmiRptCntP11S;
    end // always @ (...
  
  DFFR #(`GMI_NUM_REPEATS, {`GMI_NUM_REPEATS{1'b0}}) U17_dff
    (.q(XpiGmiRptCntP11S), .d(XpiGmiRptCntP11C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  //----------------------------------------
  //---- BackPressure TimeOut Mechanism ----
  //----------------------------------------
  // After the Design Unit deasserts Rdy4Txn for number of core
  // clock cycles greater than programmed Max Backpressure counter
  // value in Mode Register, indicate the Design Unit to provide
  // arbitration slot to CPU accesses
  
  // Count Rdy4Txn deassertion as number of Core Clk Cycles
  always @(/*AS*/RexGmiRdy4MemTxnP10S or XpiGmiBackPresCntP11S)
    begin
      if (~RexGmiRdy4MemTxnP10S)
        XpiGmiBackPresCntP11C = {XpiGmiBackPresCntP11S + 1'b1};
      else if (RexGmiRdy4MemTxnP10S)
        XpiGmiBackPresCntP11C = {`GMI_MAX_BP_CNT{1'b0}};
      else if (XpiGmiBackPresCntP11S == `GMI_MAX_BP_CNT'hff)
        XpiGmiBackPresCntP11C = {`GMI_MAX_BP_CNT{1'b0}};
      else
        XpiGmiBackPresCntP11C = XpiGmiBackPresCntP11S;
    end // always @ (...

  DFFR #(`GMI_MAX_BP_CNT, {`GMI_MAX_BP_CNT{1'b0}}) U51_dff
    (.q(XpiGmiBackPresCntP11S), .d(XpiGmiBackPresCntP11C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  assign XpiGmiTOutP15C = ({XpiGmiBackPresCntP11S == XpiGmiModeRegP10S[31:16]} ||
			    XpiGmiTOutReqP10C);

  DFFR #(1,1'b0) U53_dff
    (.q(XpiGmiTOutP15S), .d(XpiGmiTOutP15C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //----------------------
  //---- Read Enable -----
  //----------------------

  assign XpiGmiRdEnP15S = XpiGmiRdEnP10S;
  
  assign XpiGmiRdy4DataP15S = 1'b1;
  
  //--------------------------------------
  //---- Memory Write/Read Addressing ----
  //--------------------------------------

  // ReCirculating Valid Packet Indication till Packet Chunk is send
  
  assign XpiGmiValidPktP11C = 
	 (XpiGmiValidPktP10C || (XpiGmiEmptyP12S && XpiGmiWrEnP15S)) ?
	   XpiGmiValidPktP10C : XpiGmiValidPktP11S;
  
  DFFR #(1,1'b0) U20_dff
    (.q(XpiGmiValidPktP11S), .d(XpiGmiValidPktP11C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //** Starting Address for Wr/Rd Operation to RAM
  //** is programmed into GMI Command Register. Address
  //** is incremented to next memory location every
  //** clock cycle during Wr/Rd Operation
  
  //---- Address Increment ----
  
  always @(/*AS*/XpiGmiAddrP10S or XpiGmiAddrRegP10S
	   or XpiGmiAddrRegWrEnP10S or XpiGmiAddrW256P17S
	   or XpiGmiNumRdLocsP12C or XpiGmiRdEnP15S
	   or XpiGmiValidPktP11S or XpiGmiWrEnP15S)
    begin
      if (XpiGmiAddrRegWrEnP10S)
	XpiGmiAddrP10C = XpiGmiAddrRegP10S[GMI_ADDR_WIDTH-1:0];
      else if (XpiGmiValidPktP11S)
	// Packet Data Xfer
	XpiGmiAddrP10C = XpiGmiAddrW256P17S; // surefire lint_off_line ASWSSS ASWSBB
      else if (XpiGmiWrEnP15S)
	// Address Increment after Write Issuance
	XpiGmiAddrP10C = {XpiGmiAddrP10S + {{(GMI_ADDR_WIDTH-1){1'b0}},1'b1}};
      else if (XpiGmiRdEnP15S)
	// Increment the Address Pointer by Total Num of Locations Read
	XpiGmiAddrP10C = {XpiGmiAddrP10S + XpiGmiNumRdLocsP12C}; // surefire lint_off_line ASWEBB
      else
	XpiGmiAddrP10C = XpiGmiAddrP10S;
    end // always @ (...
  
  DFFR #(GMI_ADDR_WIDTH,{GMI_ADDR_WIDTH{1'b0}}) U11_dff
    (.q(XpiGmiAddrP10S), .d(XpiGmiAddrP10C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  assign XpiGmiAddrP15C = (XpiGmiWrEnP15S || XpiGmiRdEnP15S) ?
			    XpiGmiAddrP10S : XpiGmiAddrP16S;
  
  DFFR #(GMI_ADDR_WIDTH,{GMI_ADDR_WIDTH{1'b0}}) U27_dff 
    (.q(XpiGmiAddrP16S), .d(XpiGmiAddrP15C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  assign XpiGmiAddrP15S = XpiGmiAddrP15C;
  
  //--------------------------------
  //---- Target ID Staging Flop ----
  //--------------------------------
  
  assign XpiGmiTargetIDP12C = XpiRbbNewReqP11S ?
	 XpiRbbTargetIDP11S : XpiGmiTargetIDP12S;
  
  DFFR #(`RB_TARGETID_WIDTH,{`RB_TARGETID_WIDTH{1'b0}}) U19_dff
    (.q(XpiGmiTargetIDP12S), .d(XpiGmiTargetIDP12C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //----------------------------------
  //---- GMI->RBB Read Completion ----
  //----------------------------------

  //-----------------------------------------------------------
  //---- Staging Flops for Width Conversion 128,96,64-->32 ----
  //-----------------------------------------------------------

   assign XpiGmiTotalCmpDataP10S = {{(288-GMI_DATA_WIDTH){1'b0}},RexGmiDataP10S};
   
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U28_dff 
    (.q(XpiGmiCmpDataP10S), .d(XpiGmiTotalCmpDataP10S[31:0]), 
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 64
  
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U100_dff
    (.q(XpiGmiW64CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[63:32]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U101_dff
    (.q(XpiGmiCmpDataP11S), .d(XpiGmiW64CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 96
  
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U102_dff
    (.q(XpiGmiW96CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[95:64]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U103_dff
    (.q(XpiGmiW96CmpDataP11S), .d(XpiGmiW96CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U104_dff
    (.q(XpiGmiCmpDataP12S), .d(XpiGmiW96CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  // Data Width = 128

  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U105_dff
    (.q(XpiGmiW128CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[127:96]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U106_dff
    (.q(XpiGmiW128CmpDataP11S), .d(XpiGmiW128CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U107_dff
    (.q(XpiGmiW128CmpDataP12S), .d(XpiGmiW128CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U108_dff
    (.q(XpiGmiCmpDataP13S), .d(XpiGmiW128CmpDataP12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 160
  
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U109_dff
    (.q(XpiGmiW160CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[159:128]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U110_dff
    (.q(XpiGmiW160CmpDataP11S), .d(XpiGmiW160CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U111_dff
    (.q(XpiGmiW160CmpDataP12S), .d(XpiGmiW160CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U112_dff
    (.q(XpiGmiW160CmpDataP13S), .d(XpiGmiW160CmpDataP12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U113_dff
    (.q(XpiGmiCmpDataP14AS), .d(XpiGmiW160CmpDataP13S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 192
  
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U114_dff
    (.q(XpiGmiW192CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[191:160]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U115_dff
    (.q(XpiGmiW192CmpDataP11S), .d(XpiGmiW192CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U116_dff
    (.q(XpiGmiW192CmpDataP12S), .d(XpiGmiW192CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U117_dff
    (.q(XpiGmiW192CmpDataP13S), .d(XpiGmiW192CmpDataP12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U118_dff
    (.q(XpiGmiW192CmpDataP14S), .d(XpiGmiW192CmpDataP13S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U119_dff
    (.q(XpiGmiCmpDataP15AS), .d(XpiGmiW192CmpDataP14S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 224
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U120_dff
    (.q(XpiGmiW224CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[223:192]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U121_dff
    (.q(XpiGmiW224CmpDataP11S), .d(XpiGmiW224CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U122_dff
    (.q(XpiGmiW224CmpDataP12S), .d(XpiGmiW224CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U123_dff
    (.q(XpiGmiW224CmpDataP13S), .d(XpiGmiW224CmpDataP12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U124_dff
    (.q(XpiGmiW224CmpDataP14S), .d(XpiGmiW224CmpDataP13S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));

  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U125_dff
    (.q(XpiGmiW224CmpDataP15S), .d(XpiGmiW224CmpDataP14S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U126_dff
    (.q(XpiGmiCmpDataP16AS), .d(XpiGmiW224CmpDataP15S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Data Width = 256
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U127_dff
    (.q(XpiGmiW256CmpDataP10S), .d(XpiGmiTotalCmpDataP10S[255:224]),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U128_dff
    (.q(XpiGmiW256CmpDataP11S), .d(XpiGmiW256CmpDataP10S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U129_dff
    (.q(XpiGmiW256CmpDataP12S), .d(XpiGmiW256CmpDataP11S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U130_dff
    (.q(XpiGmiW256CmpDataP13S), .d(XpiGmiW256CmpDataP12S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U131_dff
    (.q(XpiGmiW256CmpDataP14S), .d(XpiGmiW256CmpDataP13S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U132_dff
    (.q(XpiGmiW256CmpDataP15S), .d(XpiGmiW256CmpDataP14S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U133_dff
    (.q(XpiGmiW256CmpDataP16S), .d(XpiGmiW256CmpDataP15S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U134_dff
    (.q(XpiGmiCmpDataP17AS), .d(XpiGmiW256CmpDataP16S),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
    
  //------------------------------------------
  //---- Mux Select Control State Machine ----
  //------------------------------------------
  //** This SM generates Mux Select for 4:1 Data Muxing
  //** required for different widths.
  
`define XPIGMIMUXSELIDLE    4'b0000
`define XPIGMIMUXSELW32     4'b0001
`define XPIGMIMUXSELW64     4'b0011
`define XPIGMIMUXSELW96     4'b0010
`define XPIGMIMUXSELW128    4'b0110
`define XPIGMIMUXSELW160    4'b0100
`define XPIGMIMUXSELW192    4'b0101
`define XPIGMIMUXSELW224    4'b1101
`define XPIGMIMUXSELW256    4'b1001
  
  //---- State Variables ----
  wire [3:0] xpigmimuxselstate;
  reg [3:0]  next_xpigmimuxselstate;
  
  //---- State Change ----
  
  DFFR #(4,{4{1'b0}}) U45_dff (.q(xpigmimuxselstate), .d(next_xpigmimuxselstate),
			       .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  //---- State Assignment ----
  
  always @(/*AS*/xpigmimuxselstate)
    begin     
      
      XpiGmiDataMuxSelP11S = 3'b000;
      XpiGmiDataRdyP11S    = 1'b0;
 
      case(xpigmimuxselstate)
	
	`XPIGMIMUXSELIDLE: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b000;
	    XpiGmiDataRdyP11S    = 1'b0;
	  end			       

	`XPIGMIMUXSELW32: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b000;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	`XPIGMIMUXSELW64: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b001;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end
	
	`XPIGMIMUXSELW96: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b010;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end
	
	`XPIGMIMUXSELW128: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b011;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	`XPIGMIMUXSELW160: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b100;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	`XPIGMIMUXSELW192: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b101;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	`XPIGMIMUXSELW224: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b110;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	`XPIGMIMUXSELW256: 
	  begin
	    XpiGmiDataMuxSelP11S = 3'b111;
	    XpiGmiDataRdyP11S    = 1'b1;
	  end

	default:
	  begin
	    XpiGmiDataMuxSelP11S = 3'b000;
	    XpiGmiDataRdyP11S    = 1'b0;
	  end			       

      endcase // case(xpigmimuxselstate)
    end // always @ (...
    
  //---- State Transitions ----
  
  always @(/*AS*/RexGmiDataRdyP10S or xpigmimuxselstate)
    begin
      
      case (xpigmimuxselstate)
	
	`XPIGMIMUXSELIDLE:
	  begin
	    if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW32:
	  begin
	    if (GMI_DATA_WIDTH>32)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW64;
	    else if (~RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	  end
	
	`XPIGMIMUXSELW64:
	  begin
	    if (GMI_DATA_WIDTH>64)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW96;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW96:
	  begin
	    if (GMI_DATA_WIDTH>96)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW128;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW128: 
	  begin
	    if (GMI_DATA_WIDTH>128)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW160;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW160: 
	  begin
	    if (GMI_DATA_WIDTH>160)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW192;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW192: 
	  begin
	    if (GMI_DATA_WIDTH>192)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW224;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW224: 
	  begin
	    if (GMI_DATA_WIDTH>224)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW256;
	    else if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	`XPIGMIMUXSELW256:
	  begin
	    if (RexGmiDataRdyP10S)
	      next_xpigmimuxselstate = `XPIGMIMUXSELW32;
	    else 
	      next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	  end
	
	default: next_xpigmimuxselstate = `XPIGMIMUXSELIDLE;
	
      endcase // case(xpigmimuxselstate)
    end // always @ (...
  
  
  // 8:1 Data Muxing

  always @(/*AS*/XpiGmiCmpDataP10S or XpiGmiCmpDataP11S
	   or XpiGmiCmpDataP12S or XpiGmiCmpDataP13S
	   or XpiGmiCmpDataP14AS or XpiGmiCmpDataP15AS
	   or XpiGmiCmpDataP16AS or XpiGmiCmpDataP17AS
	   or XpiGmiDataMuxSelP11S)
    begin

      case(XpiGmiDataMuxSelP11S)
	
	3'b000 : XpiGmiCmpDataP14C = XpiGmiCmpDataP10S;
	3'b001 : XpiGmiCmpDataP14C = XpiGmiCmpDataP11S;
	3'b010 : XpiGmiCmpDataP14C = XpiGmiCmpDataP12S;
	3'b011 : XpiGmiCmpDataP14C = XpiGmiCmpDataP13S;
	3'b100 : XpiGmiCmpDataP14C = XpiGmiCmpDataP14AS;
	3'b101 : XpiGmiCmpDataP14C = XpiGmiCmpDataP15AS;
	3'b110 : XpiGmiCmpDataP14C = XpiGmiCmpDataP16AS;
	3'b111 : XpiGmiCmpDataP14C = XpiGmiCmpDataP17AS;
	default: XpiGmiCmpDataP14C = XpiGmiCmpDataP10S;

      endcase // case(XpiGmiDataMuxSelP11S)
    end // always @ (...
  
  //----------------------------------------
  //---- GMI->RBB Output Register Stage ----
  //----------------------------------------
  
  // Data
  always @(/*AS*/XpiGmiAddrRegP10S or XpiGmiAddrRegRdEnP10S
	   or XpiGmiCmpDataP14C or XpiGmiModeRegP10S
	   or XpiGmiModeRegRdEnP10S)
    begin
      if (XpiGmiAddrRegRdEnP10S)
	XpiGmiDataP14C = XpiGmiAddrRegP10S;
      else if (XpiGmiModeRegRdEnP10S)
	XpiGmiDataP14C = XpiGmiModeRegP10S;
      else
	XpiGmiDataP14C = XpiGmiCmpDataP14C;
    end // always @ (...
  
  DFFR #(`RB_DATA_WIDTH,{`RB_DATA_WIDTH{1'b0}}) U47_dff (.q(XpiGmiDataP14S), .d(XpiGmiDataP14C),
							 .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Qualifier
  
  assign XpiGmiNewRespP13C = (XpiGmiDataRdyP11S || XpiGmiAddrRegRdEnP10S || XpiGmiModeRegRdEnP10S);
  
  assign XpiGmiNewRespP14C = ((XpiGmiNewRespP13C || XpiGmiValidTxnP10C) && XpiRbbRdy4DataP11S);
  
  DFFR #(1,1'b0) U48_dff (.q(XpiGmiNewRespP14S), .d(XpiGmiNewRespP14C),
			  .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // Command
  always @(/*AS*/XpiGmiNewRespP13C or XpiGmiValidTxnP10C)
    begin
      if (XpiGmiNewRespP13C)
	XpiGmiCmdP14C = `RDCMP;
      else if (XpiGmiValidTxnP10C)
	XpiGmiCmdP14C = `REQACK;
      else
	XpiGmiCmdP14C ={4{1'b0}};
    end
  
  DFFR #(`RB_CMD_WIDTH,{`RB_CMD_WIDTH{1'b0}}) U49_dff 
    (.q(XpiGmiCmdP14S), .d(XpiGmiCmdP14C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  assign XpiGmiTargetIDP14S = XpiGmiTargetIDP12S;

  //---- Status Setting for Control Read Completion and Request Acknowledgement ----

  always @(/*AS*/XpiGmiAddrRegRdEnP10S or XpiGmiValidTxnP10C)
    begin
      if (XpiGmiAddrRegRdEnP10S)
	// Register Read 
	XpiGmiStatusP14C = `RB_STATUS_WIDTH'h001;
      else if (XpiGmiValidTxnP10C)
	// Acknowledging a New Request
	XpiGmiStatusP14C = `RB_STATUS_WIDTH'h002;
      else
	XpiGmiStatusP14C = {`RB_STATUS_WIDTH{1'b0}};
    end // always @ (...
  
  DFFR #(`RB_STATUS_WIDTH,{`RB_STATUS_WIDTH{1'b0}}) U50_dff 
    (.q(XpiGmiStatusP14S), .d(XpiGmiStatusP14C),
     .clk(XpiCoreClk), .reset(GlCoreResetR00C));
  
  // surefire lint_on CWCCXX PRMPTS
  
  //------------------------
  //---- 0in Assertions ----
  //------------------------
  
  // 0in known_driven -var XpiGmiWrEnP15S       -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiRdEnP15S       -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiDataLenP15S    -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiAddrP15S       -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var RexGmiRdy4MemTxnP10S -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var RexGmiDataRdyP10S    -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var RexGmiDataP10S       -clock XpiCoreClk -reset GlCoreResetR00C -active RexGmiDataRdyP10S

  // 0in known_driven -var XpiGmiNewRespP14S    -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiDataP14S       -clock XpiCoreClk -reset GlCoreResetR00C -active XpiGmiNewRespP14S
  // 0in known_driven -var XpiGmiTargetIDP14S   -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiCmdP14S        -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiStatusP14S     -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiGmiIFifoRdEnP10S  -clock XpiCoreClk -reset GlCoreResetR00C

  // 0in known_driven -var XpiRbbNewReqP11S     -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiRbbDataLenP11S    -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiRbbAddrP11S       -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiRbbTargetIDP11S   -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiRbbCmdP11S        -clock XpiCoreClk -reset GlCoreResetR00C
  // 0in known_driven -var XpiRbbIFifoEmptyP11S -clock XpiCoreClk -reset GlCoreResetR00C

  // 0in assert -var (~RexGmiRdy4MemTxnP10S) -severity 1

endmodule // xpigmis

// Local Variables:
// verilog-auto-sense-defines-constant:t
// End:

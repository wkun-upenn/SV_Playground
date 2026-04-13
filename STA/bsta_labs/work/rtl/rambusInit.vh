defparam `QDRTOP.U_qdrI0.`QDR_INIT  = "dt0.init";
defparam `QDRTOP.U_qdrI1.`QDR_INIT  = "dt1.init";
defparam `QDRTOP.U_qdrI2.`QDR_INIT  = "dt2.init";
defparam `QDRTOP.U_qdrI3.`QDR_INIT  = "dt3.init";
defparam `QDRTOP.U_qdrII0.`QDR_INIT = "dt0.init";
defparam `QDRTOP.U_qdrII1.`QDR_INIT = "dt1.init";
defparam `QDRTOP.U_qdrII2.`QDR_INIT = "dt2.init";
defparam `QDRTOP.U_qdrII3.`QDR_INIT = "dt3.init";

`define ch0_rimm0 tb.u_mausimc.Imausim0.`rimm0 
`define ch0_rimm1 tb.u_mausimc.Imausim0.`rimm1
`define ch1_rimm0 tb.u_mausimc.Imausim1.`rimm0
`define ch1_rimm1 tb.u_mausimc.Imausim1.`rimm1
`define ch2_rimm0 tb.u_mausimc.Imausim2.`rimm0
`define ch2_rimm1 tb.u_mausimc.Imausim2.`rimm1
`define ch3_rimm0 tb.u_mausimc.Imausim3.`rimm0
`define ch3_rimm1 tb.u_mausimc.Imausim3.`rimm1
`define ch4_rimm0 tb.u_mausimc.Imausim4.`rimm0
`define ch4_rimm1 tb.u_mausimc.Imausim4.`rimm1
`define ch5_rimm0 tb.u_mausimc.Imausim5.`rimm0
`define ch5_rimm1 tb.u_mausimc.Imausim5.`rimm1
`define ch6_rimm0 tb.u_mausimc.Imausim6.`rimm0
`define ch6_rimm1 tb.u_mausimc.Imausim6.`rimm1
`define ch7_rimm0 tb.u_mausimc.Imausim7.`rimm0
`define ch7_rimm1 tb.u_mausimc.Imausim7.`rimm1
`define ch8_rimm0 tb.u_mausimc.Imausim8.`rimm0
`define ch8_rimm1 tb.u_mausimc.Imausim8.`rimm1
`define ch9_rimm0 tb.u_mausimc.Imausim9.`rimm0
`define ch9_rimm1 tb.u_mausimc.Imausim9.`rimm1

`ifdef RDRAM_DEBUG

 defparam `ch0_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch0_rimm0.StdOutEn    = `true;
 defparam `ch0_rimm0.MsgOutFile  = "";
 defparam `ch0_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch0_rimm1.StdOutEn    = `true;
 defparam `ch0_rimm1.MsgOutFile  = "";

 defparam `ch1_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch1_rimm0.StdOutEn    = `true;
 defparam `ch1_rimm0.MsgOutFile  = "";
 defparam `ch1_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch1_rimm1.StdOutEn    = `true;
 defparam `ch1_rimm1.MsgOutFile  = "";

 defparam `ch2_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch2_rimm0.StdOutEn    = `true;
 defparam `ch2_rimm0.MsgOutFile  = "";
 defparam `ch2_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch2_rimm1.StdOutEn    = `true;
 defparam `ch2_rimm1.MsgOutFile  = "";

 defparam `ch3_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch3_rimm0.StdOutEn    = `true;
 defparam `ch3_rimm0.MsgOutFile  = "";
 defparam `ch3_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch3_rimm1.StdOutEn    = `true;
 defparam `ch3_rimm1.MsgOutFile  = "";

 defparam `ch4_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch4_rimm0.StdOutEn    = `true;
 defparam `ch4_rimm0.MsgOutFile  = "";
 defparam `ch4_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch4_rimm1.StdOutEn    = `true;
 defparam `ch4_rimm1.MsgOutFile  = "";

 defparam `ch5_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch5_rimm0.StdOutEn    = `true;
 defparam `ch5_rimm0.MsgOutFile  = "";
 defparam `ch5_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch5_rimm1.StdOutEn    = `true;
 defparam `ch5_rimm1.MsgOutFile  = "";

 defparam `ch6_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch6_rimm0.StdOutEn    = `true;
 defparam `ch6_rimm0.MsgOutFile  = "";
 defparam `ch6_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch6_rimm1.StdOutEn    = `true;
 defparam `ch6_rimm1.MsgOutFile  = "";

 defparam `ch7_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch7_rimm0.StdOutEn    = `true;
 defparam `ch7_rimm0.MsgOutFile  = "";
 defparam `ch7_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch7_rimm1.StdOutEn    = `true;
 defparam `ch7_rimm1.MsgOutFile  = "";

 defparam `ch8_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch8_rimm0.StdOutEn    = `true;
 defparam `ch8_rimm0.MsgOutFile  = "";
 defparam `ch8_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch8_rimm1.StdOutEn    = `true;
 defparam `ch8_rimm1.MsgOutFile  = "";

 defparam `ch9_rimm0.MsgEnGrp    = 8'b00011111;
 defparam `ch9_rimm0.StdOutEn    = `true;
 defparam `ch9_rimm0.MsgOutFile  = "";
 defparam `ch9_rimm1.MsgEnGrp    = 8'b00011111;
 defparam `ch9_rimm1.StdOutEn    = `true;
 defparam `ch9_rimm1.MsgOutFile  = "";
`endif

// CH0 rimm instance0
 defparam `ch0_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch0_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch0_rimm0.Option	= `rimm0_Option;
 defparam `ch0_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch0_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch0_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch0_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH0 rimm - instance 1
 defparam `ch0_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch0_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch0_rimm1.Option	= `rimm1_Option;
 defparam `ch0_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch0_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch0_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch0_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH1 rimm instance0
 defparam `ch1_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch1_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch1_rimm0.Option	= `rimm0_Option;
 defparam `ch1_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch1_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch1_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch1_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH1 rimm - instance 1
 defparam `ch1_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch1_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch1_rimm1.Option	= `rimm1_Option;
 defparam `ch1_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch1_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch1_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch1_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH2 rimm instance0
 defparam `ch2_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch2_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch2_rimm0.Option	= `rimm0_Option;
 defparam `ch2_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch2_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch2_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch2_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH2 rimm - instance 1
 defparam `ch2_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch2_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch2_rimm1.Option	= `rimm1_Option;
 defparam `ch2_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch2_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch2_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch2_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH3 rimm instance0
 defparam `ch3_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch3_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch3_rimm0.Option	= `rimm0_Option;
 defparam `ch3_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch3_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch3_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch3_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH3 rimm - instance 1
 defparam `ch3_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch3_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch3_rimm1.Option	= `rimm1_Option;
 defparam `ch3_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch3_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch3_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch3_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH4 rimm instance0
 defparam `ch4_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch4_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch4_rimm0.Option	= `rimm0_Option;
 defparam `ch4_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch4_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch4_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch4_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH4 rimm - instance 1
 defparam `ch4_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch4_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch4_rimm1.Option	= `rimm1_Option;
 defparam `ch4_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch4_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch4_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch4_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH5 rimm instance0
 defparam `ch5_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch5_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch5_rimm0.Option	= `rimm0_Option;
 defparam `ch5_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch5_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch5_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch5_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH5 rimm - instance 1
 defparam `ch5_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch5_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch5_rimm1.Option	= `rimm1_Option;
 defparam `ch5_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch5_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch5_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch5_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH6 rimm instance0
 defparam `ch6_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch6_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch6_rimm0.Option	= `rimm0_Option;
 defparam `ch6_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch6_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch6_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch6_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH6 rimm - instance 1
 defparam `ch6_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch6_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch6_rimm1.Option	= `rimm1_Option;
 defparam `ch6_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch6_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch6_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch6_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH7 rimm instance0
 defparam `ch7_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch7_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch7_rimm0.Option	= `rimm0_Option;
 defparam `ch7_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch7_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch7_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch7_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH7 rimm - instance 1
 defparam `ch7_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch7_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch7_rimm1.Option	= `rimm1_Option;
 defparam `ch7_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch7_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch7_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch7_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH8 rimm instance0
 defparam `ch8_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch8_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch8_rimm0.Option	= `rimm0_Option;
 defparam `ch8_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch8_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch8_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch8_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH8 rimm - instance 1
 defparam `ch8_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch8_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch8_rimm1.Option	= `rimm1_Option;
 defparam `ch8_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch8_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch8_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch8_rimm1.tQ1	= 0.1*`ns2v;
 `endif

// CH9 rimm instance0
 defparam `ch9_rimm0.NumDevs	= `rimm0_NumDevs;
 defparam `ch9_rimm0.CoreOrg	= `rimm0_CoreOrg;
 defparam `ch9_rimm0.Option	= `rimm0_Option;
 defparam `ch9_rimm0.ChPropDly	= `rimm0_ChPropDly;
 `ifdef rimm0_CoreRows
    defparam `ch9_rimm0.CoreRows	= `rimm0_CoreRows;
 `endif
 `ifdef FAST_SCK
    defparam `ch9_rimm0.tPROP1	= 0.1*`ns2v;
    defparam `ch9_rimm0.tQ1	= 0.1*`ns2v;
 `endif

// CH7 rimm - instance 1
 defparam `ch9_rimm1.NumDevs	= `rimm1_NumDevs;
 defparam `ch9_rimm1.CoreOrg	= `rimm1_CoreOrg;
 defparam `ch9_rimm1.Option	= `rimm1_Option;
 defparam `ch9_rimm1.ChPropDly	= `rimm1_ChPropDly;
 `ifdef rimm1_CoreRows
   defparam `ch9_rimm1.CoreRows = `rimm1_CoreRows;
 `endif
 `ifdef FAST_SCK
   defparam `ch9_rimm1.tPROP1	= 0.1*`ns2v;
   defparam `ch9_rimm1.tQ1	= 0.1*`ns2v;
 `endif

`ifdef BackdoorInit
  defparam `TMIO.U_rac0.BypassInit = `true;
  defparam `TMIO.U_rac1.BypassInit = `true;
  defparam `TMIO.U_rac2.BypassInit = `true;
  defparam `TMIO.U_rac3.BypassInit = `true;
  defparam `TMIO.U_rac4.BypassInit = `true;
  defparam `TMIO.U_rac5.BypassInit = `true;
  defparam `TMIO.U_rac6.BypassInit = `true;
  defparam `TMIO.U_rac7.BypassInit = `true;
  defparam `TMIO.U_rac8.BypassInit = `true;
  defparam `TMIO.U_rac9.BypassInit = `true;
`endif

 defparam `ch0_rimm0.BypassInit = `true;
 defparam `ch1_rimm0.BypassInit = `true;
 defparam `ch2_rimm0.BypassInit = `true;
 defparam `ch3_rimm0.BypassInit = `true;
 defparam `ch4_rimm0.BypassInit = `true;
 defparam `ch5_rimm0.BypassInit = `true;
 defparam `ch6_rimm0.BypassInit = `true;
 defparam `ch7_rimm0.BypassInit = `true;
 defparam `ch8_rimm0.BypassInit = `true;
 defparam `ch9_rimm0.BypassInit = `true;

 defparam `ch0_rimm0.AddrPreloadFile = "AddrPreLoad.init";
 defparam `ch0_rimm0.DataPreloadFile = "DataPreLoad.init";
 defparam `ch1_rimm0.AddrPreloadFile = "";
 defparam `ch1_rimm0.DataPreloadFile = "";
 defparam `ch2_rimm0.AddrPreloadFile = "";
 defparam `ch2_rimm0.DataPreloadFile = "";
 defparam `ch3_rimm0.AddrPreloadFile = "";
 defparam `ch3_rimm0.DataPreloadFile = "";
 defparam `ch4_rimm0.AddrPreloadFile = "";
 defparam `ch4_rimm0.DataPreloadFile = "";
 defparam `ch5_rimm0.AddrPreloadFile = "AddrPreLoad.init";
 defparam `ch5_rimm0.DataPreloadFile = "DataPreLoad.init";
 defparam `ch6_rimm0.AddrPreloadFile = "";
 defparam `ch6_rimm0.DataPreloadFile = "";
 defparam `ch7_rimm0.AddrPreloadFile = "";
 defparam `ch7_rimm0.DataPreloadFile = "";
 defparam `ch8_rimm0.AddrPreloadFile = "";
 defparam `ch8_rimm0.DataPreloadFile = "";
 defparam `ch9_rimm0.AddrPreloadFile = "";
 defparam `ch9_rimm0.DataPreloadFile = "";

/*
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc0.IRMC.Monitor_BFMBus.BFM_O = "BFM0.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc1.IRMC.Monitor_BFMBus.BFM_O = "BFM1.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc2.IRMC.Monitor_BFMBus.BFM_O = "BFM2.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc3.IRMC.Monitor_BFMBus.BFM_O = "BFM3.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc4.IRMC.Monitor_BFMBus.BFM_O = "BFM4.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc5.IRMC.Monitor_BFMBus.BFM_O = "BFM5.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc6.IRMC.Monitor_BFMBus.BFM_O = "BFM6.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc7.IRMC.Monitor_BFMBus.BFM_O = "BFM7.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc8.IRMC.Monitor_BFMBus.BFM_O = "BFM8.out";
 defparam tb.u_tmuc.u_tmcoreuc.U_maudis.U_mauchc9.IRMC.Monitor_BFMBus.BFM_O = "BFM9.out";
 */

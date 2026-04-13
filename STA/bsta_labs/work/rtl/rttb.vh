// shortcut to heirarchy.

`ifdef RTTB_DEFINED_ALREADY_DUDE
`else
`define RTTB_DEFINED_ALREADY_DUDE
`timescale 1ps/1ps

`define true     1
`define false    0

`define ns2v     64'd1000
`define us2v    `ns2v*1000
`define ms2v    `us2v*1000

`define CORE_CLK  (3000)		// 333
`define SPI4_CLK  (3000)		// 333
`define SPI4_300  (3333)		// 300
`define SPI4_333  (3000)		// 333
`define SPI4_350  (2857)		// 350
`define SPI4_366  (2727)		// 366
`define SPI4_400  (2500)		// 400
`define SPI4_433  (2307)		// 433
`define SPI4_466  (2142)		// 466
`define SPI4_500  (2000)		// 500
`define SPI4_533  (1875)		// 533
`define REF_CLK   (15000)		// 67

`define CSIX_433  (2307)		// 433
`define CSIX_466  (2142)		// 466

`define CLK_033   (30000)
`define CLK_066   (15000)
`define CLK_100   (10000)
`define CLK_133   (7518)      // RMC clock
`define CLK_167   (6000)
`define CLK_200   (5000)
`define CLK_250   (4000)
`define CLK_333   (3000)
`define CLK_300   (3300)
`define CLK_433   (2309)
`define CLK_466   (2142)
`define CLK_500   (2000)
`define CLK_533   (1876)

`define CSIX_CLK  (2000)		// 500 
`define SC_CLK    (1000)		// 1000
`define PCIX_CLK  (7500)		// 133
`define OFFCHIP_CCM_CLK  (10000)	// 100
`define ONCHIP_CCM_CLK  (6000)		// 167
`define PCI_CLK   (10000)		// 100
`define TM_JTG_CLK   (10000)		// 100
`define MEU_CLK   (10000)		// 100
`define FAST_CLK  (5000)		// 200

`define PP_JTG_CLK   (10000)		// 100

`define TOP	     	tb

`define QDRTOP 		`TOP
`define QDR_INIT 	initfile
`define QDR_MEM_SIZE 1024
`define QDR_KTOC_DELAY              1.5 * 64'd1000

// the paths to the main chips will remain same
// on any testbench, viz. under TOP. Make no
// attempt to consolidate chips under a higher
// heirarchy (ex. tb.sys.rex1 is bad)

`define REX10	    	`TOP.u_ppuc.u_ppcoreuc0
`define REX20	    	`TOP.u_tmuc.u_tmcoreuc0
`define REX11	    	`TOP.u_ppuc.u_ppcoreuc1
`define REX21	    	`TOP.u_tmuc.u_tmcoreuc1

`define REX1	    	`TOP.u_ppuc.u_ppcoreuc
`define REX2	    	`TOP.u_tmuc.u_tmcoreuc
`define TMIO            `TOP.u_tmuc.U_tmiouc

`define PPDBG           `REX1.U_dbguc
`define R1CLK       	`REX1.U_r1clkuc
`define RSI         	`REX1.U_rsiuc
`define RLL         	`REX1.U_rlluc
`define R1PI        	`REX1.U_r1piuc
`define DSM          `REX1.U_dsmuc

`define RPP         	`REX1.U_rppuc
`define RQO         	`RPP.U_rqouc
`define RCL         	`RPP.U_rcluc
`define RTD         	`RPP.U_rtduc

`define TLL             `REX1.U_tlluc
`define TPP         	`REX1.U_tppuc
`define TQO         	`TPP.U_tqouc
`define TCL         	`TPP.U_tcluc
`define TFR         	`TPP.U_tfruc
`define TTE         	`TPP.U_tteuc

`define TMDBG           `REX2.U_dbguc
`define R2CLK       	`REX2.U_r2clkuc
`define R2PI		`REX2.U_r2piuc
`define RCI		`REX2.U_tmiuc 
`define RDQ		`REX2.U_rdquc
`define REQ		`REX2.U_requc 
`define RSW		`REX2.U_rswuc
`define TMI		`REX2.U_tmiuc
`define TMO		`REX2.u_tmouc

`define TDQ		`REX2.u_tdquc 
`define DBG		`REX2.U_dbguc

// getting messy here.  RME is a shared block.
// We rely on a top level tickdef coming from the testbench.

`ifdef TEXTBENCH
`define RME		`TEX.U_tmeuc 
`define REX2TEX		`TEX
`endif

`ifdef REX2TBENCH
`define RME		`REX2.U_rmeuc 
`define REX2TEX		`REX2
`endif

`ifdef SYSTBENCH
`define RME		`REX2.U_rmeuc 
`define REX2TEX		`REX2
`endif

`ifdef R12TBENCH
`define RME		`REX2.U_rmeuc 
`define REX2TEX		`REX2
`endif

`define MAU		`RME.U_mauuc
`define MAUDIS		`REX2.U_maudis
`define MWR		`RME.U_mwruc
`define RRD		`RME.U_rrduc
`define MCC             `RME.U_mccuc

`define TRD		`RME.U_trduc


`define RPP_PKT_DATA_WIDTH    32 * 8
`define REQ_EOP_OFFSET_WIDTH  6
`endif

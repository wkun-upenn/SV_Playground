
`include "meu.vh"
`include "xpiuc.vh"

`ifdef _RRD_INC_
`else
`define _RRD_INC_

`define RRD_QT_MEMID  0
`define RRD_AL_MEMID  1
`define RRD_LL_MEMID  2
`define RRD_RB_MEMID  3

`define RRD_QT1_PP_IDX  61:40  // Previous Packet Address
`define RRD_QT1_PPV_IDX 39:39
`define RRD_QT1_OFF_IDX 38:36
`define RRD_QT1_CD_IDX  35:2
`define RRD_QT1_SOP_IDX  1:1
`define RRD_QT1_CDV_IDX  0:0

`define RRD_QT0_ND_IDX  33:2 // Next Descriptor
`define RRD_QT0_NDV_IDX 1:1  // Next Descriptor Valid
`define RRD_QT0_DFP_IDX 0:0  // Descriptor Fetch Pending

`define RRD_DESC_WIDTH     32
`define RRD_DESC_ADR_WIDTH 22
`define RRD_DESC_LEN_WIDTH 10
`define RRD_ADDR_PORT_IDX  18:17

`define RRD_RDB_DEPTH 16
`define RRD_RDB_ADDR_WIDTH 4

`define TRD_VID_COUNT   512
`define TRD_PTR_WIDTH   `MEU_VID_WIDTH-2
`define TRD_PID_COUNT   32 // Per channel
`define TRD_PID_WIDTH   5
`define TRD_CHNL_WIDTH  `MEU_CHANNEL_WIDTH
`define TRD_SID_WIDTH   `MEU_SID_WIDTH + 1
`define TRD_ALLOC_WIDTH `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 9 + 13
`define TRD_ALLOC_MASKW 10 // ceiling(TRD_ALLOC_WIDTH / (MEU_VID_WIDTH-2))

`define TRD_ALL_CNL_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH - 1:`TRD_PTR_WIDTH
`define TRD_ALL_SID_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH - 1:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH
`define TRD_ALL_ADD_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH - 1:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH
`define TRD_ALL_EOB_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH
`define TRD_ALL_EOP_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 1:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 1
`define TRD_ALL_SOP_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 2:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 2
`define TRD_ALL_SZE_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 8:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 3
`define TRD_ALL_OLI_IDX `TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 21:`TRD_PTR_WIDTH + `TRD_CHNL_WIDTH + `TRD_SID_WIDTH + `MEU_BUF_ADDR_WIDTH + 9

`endif

//-----------------------------------------------------------------------------
// Modification history :
// Thu Dec  6 18:18:28 2001 : created
//
// $Log: rrduc.vh,v $
// Revision 1.12  2002/08/20 00:08:25  warren
// bugs 1140 and 1141.  Rdb size and stall count increased.
//
// Revision 1.11  2002/08/14 02:22:43  warren
// moved regs from rme to rrd.  Added interrupt for mwr parity error.
//
// Revision 1.10  2002/06/06 22:35:02  warren
// Added RBB to RRD, moving the connections from RME into RRD and adding the new RBB to the ring.
//
// Revision 1.9  2002/04/17 02:44:10  warren
// Added defines for memory IDs
//
// Revision 1.8  2002/04/02 00:51:26  warren
// Added intelligent stall logic to the free buffer FIFOs.
//
// Revision 1.7  2002/03/28 03:38:12  warren
// Multicast v1.5
//
// Revision 1.6  2002/03/20 19:25:27  warren
// upped rdb size.
//
// Revision 1.5  2002/03/20 00:18:46  warren
// Deeper RDB.  Enabled Rdb assertions.
//
// Revision 1.4  2002/03/09 04:20:46  warren
// Changes for Multicast.
//
// Revision 1.3  2002/02/21 22:45:47  warren
// Fixed define to handle wider SID.
//
// Revision 1.2  2002/02/08 01:40:13  warren
// Trd/Rrd merge
//
// Revision 1.1  2002/02/03 16:24:40  ravik
// initial
//
// Revision 1.1  2001/12/07 21:03:36  warren
// initial version.
//


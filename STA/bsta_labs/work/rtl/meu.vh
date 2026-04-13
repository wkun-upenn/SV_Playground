
`include "tmcoreuc.vh"

`ifdef _MEU_INC_
`else
`define _MEU_INC_

//-----------------------------------------------------------------------------
// These defines are specifically for RME
//-----------------------------------------------------------------------------
`define MEU_SID_WIDTH			`TM_SID_WIDTH + 1
`define MEU_SID_COUNT			`TM_SID_COUNT + 32
`define MEU_QID_WIDTH                   16
`define MEU_RX_QID_WIDTH                13
`define MEU_TX_QID_WIDTH                15
`define MEU_QID_COUNT                   `TM_QID_COUNT
`define MEU_VID_WIDTH                   9
`define MEU_PID_WIDTH                   5
`define MEU_RX_TAG_WIDTH		10
`define MEU_RBUF_TAG_WIDTH              (`MEU_RX_TAG_WIDTH +1)
`define MEU_TX_TAG_WIDTH                (`MEU_VID_WIDTH + `MEU_PID_WIDTH)
`define MEU_TAG_WIDTH                   (`MEU_RX_TAG_WIDTH + `MEU_PID_WIDTH + 1)
//`define MEU_CPU_SID                     {1'b1,{`MEU_SID_WIDTH-1{1'b0}}}
`define MEU_CPU_SID                     100

`define MEU_CHUNK_SID_WIDTH             12
`define MEU_STREAM_COUNT                4353
`define MEU_CHUNK_CTL_WIDTH             23
`define MEU_DUPLEX_MODE_WIDTH           2
`define MEU_PORT_ID_WIDTH               2
`define MWR_PKT_VLD_RANGE               0:0
`define MWR_PKT_SID_RANGE               12:1
`define MWR_PKT_SOP_RANGE               13:13
`define MWR_PKT_EOP_RANGE               14:14
`define MWR_PKT_OFFSET_RANGE            20:15
`define MWR_PKT_DROP_RANGE              21:21
`define MWR_PKT_INTR_RANGE              22:22
`define MWR_CTX_PKTSZ_WIDTH             5

//-----------------------------------------------------------------------------
// These defines are shared by RME and TME.  If you update
// them here, update the corrsponding defines in tex/tme/rtl/meu.vh
//-----------------------------------------------------------------------------
`define MEU_BUF_VA_WIDTH                32
`define MEU_BUF_PA_WIDTH                22
`define MEU_BUF_VA_CHANNEL_HI_RANGE     13:11
`define MEU_BUF_VA_CHANNEL_LO_RANGE     8:6
`define MEU_BUF_ADDR_CHANNEL_RANGE      3:1
`define MEU_TRANS_ADDR_RANGE            30:9

`define MEU_CHANNELS                    10
`define MEU_CHANNEL_WIDTH               4
`define MEU_FBC_STDATA_WIDTH            256
`define MEU_FBC_LDDATA_WIDTH            128
`define MEU_FBC_LDRESP_WIDTH            2
`define MEU_CNK_CNT_WIDTH               8
`define MEU_DESC_WIDTH                  35
`define MEU_DESC_LEN_WIDTH              11
`define MEU_BUF_ADDR_WIDTH              22
`define MEU_BUF_OFFSET_WIDTH            3
`define MEU_CHUNK_DATA_WIDTH            256
`define MEU_CHUNK_FLAG_WIDTH            2
`define MEU_CHUNK_QID_WIDTH             16
`define MEU_CHUNK_SZ_WIDTH              6
`define MEU_BYTE_CNT_WIDTH              14

`define MEU_QUAD_CNT                    4
`define MEU_QUAD_SEL_WIDTH              2
`define MEU_WB_DEC_WIDTH                2
`define MEU_WB_SZ_WIDTH                 2

`define MEU_DROP_QUEUE_INDEX            16'h8400

`define MWR_QDR_DATA_WIDTH              18
`define MWR_QDR_ADDR_WIDTH              20
`define MWR_QDR_DEVICES                 4
`define MWR_QDR_DEVSEL_WIDTH            2

`define MWR_WBUF_BANK_WIDTH             128
`define MWR_INTR_VEC_WIDTH              8
`define MWR_DEBUG_VEC_WIDTH             7
`define MWR_BIST_VEC_WIDTH              4
`define MWR_QDR_KNOB_WIDTH              4
`define MWR_QDR_CR_WIDTH                2
`define MWR_FBC_ADDR_WIDTH              6

`endif

//-----------------------------------------------------------------------------
// Modification history :
//
// $Log: meu.vh,v $
// Revision 1.22  2002/08/08 03:01:22  enoch
// Per queue byte count to Enq
//
// Revision 1.21  2002/08/07 01:25:33  enoch
// Mwr bisted
//
// Revision 1.20  2002/06/20 04:26:48  enoch
// New Qdrifc
//
// Revision 1.19  2002/06/04 23:47:02  enoch
// 10 starting channel change
//
// Revision 1.18  2002/05/29 20:56:01  enoch
// FrCpu change
//
// Revision 1.17  2002/05/08 19:01:26  enoch
// Debug events
//
// Revision 1.16  2002/04/21 00:26:49  enoch
// Dbg-Rme interface change
//
// Revision 1.15  2002/04/11 18:33:50  enoch
// Control Registers
//
// Revision 1.14  2002/04/10 23:56:07  enoch
// Debug hooks and interrupts
//
// Revision 1.13  2002/04/02 21:31:21  enoch
// Free buffer arbitration change
//
// Revision 1.12  2002/03/24 02:27:48  warren
// Size passing through descriptor.  Buffer count sideband in descriptor write FIFO.
//
// Revision 1.11  2002/03/05 21:35:15  warren
// Added space to SID to allow for CPU and MC streams.
//
// Revision 1.10  2002/02/23 00:45:31  enoch
// Quadsel support for duplex
//
// Revision 1.9  2002/02/21 22:37:07  warren
// Changed CPU_SID.
//
// Revision 1.8  2002/02/15 19:32:14  warren
// Fixed drop queue index
//
// Revision 1.7  2002/02/14 19:05:25  enoch
// Descriptor configuration
//
// Revision 1.6  2002/02/12 01:41:30  enoch
// 256 stream support
//
// Revision 1.5  2002/02/09 23:07:21  enoch
// Add duplex support, PortId and PortDir
//
// Revision 1.4  2002/02/09 01:27:07  warren
// 16k Egress queue table.
//
// Revision 1.3  2002/02/08 02:07:33  warren
// Trd/Rrd merge
//
// Revision 1.2  2002/02/04 17:14:58  regr
// rex2coreuc.vh name changed
//
// Revision 1.1  2002/02/03 16:24:41  ravik
// initial
//
// Revision 1.29  2002/01/24 23:27:12  ramg
// ecc checkin
//
// Revision 1.28  2002/01/21 23:54:39  warren
// Changed Drop queue index.
//
// Revision 1.27  2002/01/09 23:43:32  warren
// Minor cleanup.
//
// Revision 1.26  2001/12/15 23:24:10  warren
// Updated header/footer to match tme/rtl/meu.vh
//


`include "tmringuc.vh"
`include "ppringuc.vh"

//==== DMA Specific Definition ====
`define DMA_TARGETID_WIDTH  	8
`define DMA_MAXLENGTH_WIDTH 	20
`define TOUT_CNTR_WIDTH     	32
`define DMA_INTR_EVENTS       2 

//=== PCI-X related definition ====
`define PCI_ADDR_WIDTH  	64
`define PCI_DATA_WIDTH  	64
`define PCI_CMD_WIDTH   	4
`define CMD_BE_WIDTH    	8
`define BYTECNT_WIDTH   	12
`define RQ_BYTECNT_WIDTH 	13 
`define PCI_ATTR_WIDTH  	36
`define DESC_WIDTH      	128 
`define ad_width        	64
`define c_be_width      	8
`define be_width        	8
`define PCIAPP_INTR_EVENTS      8 

//==== Ring Bus related definition ====
`define RB_ADDR_WIDTH      	9 
`define RB_DATA_WIDTH      	32
`define RB_CMD_WIDTH       	4
`define RB_TARGETID_WIDTH  	8 
`define RB_STATUS_WIDTH    	9
`define XPI_ADDR_WIDTH     	17 
`define CTL_OFFSET_WIDTH   	9 

//==== GMI related definition ====
`define GMI_MEM_DEPTH      	16
`define RDLENGTH_CMP_WIDTH 	10
`define GMI_NUM_REPEATS    	13  
`define GMI_MAX_BP_CNT        16
`define GMI_STATUS_WIDTH	2
`define GMI_RDLEN_WIDTH         8

//==== PKTTX Interface Related Definition ====
`define TRDXPI_DATA_WIDTH     	64
`define TRDXPI_CTRL_WIDTH     	11
`define PKTTXFIFO_DATA_WIDTH  	75
`define PKTTXFIFO_DEPTH         128
`define PKTTXFIFO_PTR_WIDTH     7
`define PKTTX_CPUQID_WIDTH    	3
`define PKTTX_EOPOFFSET_WIDTH 	6 
`define AVAIL_BUFFER_LENGTH   	16
`define PKTTX_INTR_EVENTS       16 

//==== PKTRX Related Definition ====
`define PKTRX_CTRL_WIDTH 	9
`define PKTRX_FIFO_WIDTH 	73
`define XPI_MAX_NUM_PKTS 	21
`define MAX_BUFFER_SIZE  	16
`define RXFIFOPTR_WIDTH 	6
`define PKTRX_INTR_EVENTS       2 

//==== DESCDMA Related Definition ====
`define DESCDMA_FIFO_WIDTH 	64
`define DESCDMA_FIFO_DEPTH 	32
`define DESCDMA_FIFO_PTR   	5 
`define DESCDMA_INTR_EVENTS     2 

//==== GIL Related Definition ====
`define GIL_INTR_EVENTS   	256	
`define GIL_DATA_WIDTH   	32
`define GIL_OFFSET_WIDTH 	5
`define GIL_CMD_WIDTH    	4
`define DRT_INTR_EVENTS         32

//==== JTAG DMA Related Definition ====
`define JDMA_FIFO_WIDTH  	32
`define JDMA_FIFO_DEPTH  	32
`define JDMA_FIFO_PTRLEN 	6

//==== UIL related definition ====
`define UIL_DATA_WIDTH       32
`define UIL_INTR_EVENTS      32

//==== Request Encoding Definition ====
`define MEMWR       		4'b0111
`define MEMRD       		4'b0110
`define MEMRDBURST  		4'b1100
`define MEMRDLINE   		4'b1110
`define RDCMP       		4'b1100
`define CFGR        		4'b1010
`define CFGW        		4'b1011
`define CTRLWR      		4'b0111
`define CTRLRD      		4'b0110
`define RBRD        		4'b0010
`define RBWR        		4'b0011
`define CRDTREF     		4'b1010
`define PKTRXXFR    		4'b1000
`define NULL        		4'b1111
`define IDLE            4'b1101
`define REQACK      		4'b0101
`define TOUT            4'b0100

//==== DMA Static Txn ID Definition ====
`define DMA0TID   		3'b001
`define DMA1TID   		3'b010
`define DMA2TID   		3'b011
`define DMA3TID   		3'b100
`define DMA4TID   		3'b101


//==== Miscellaneous Definition ====
`define FUN_NUM   		4'b1000
`define BUS_NUM   		4'b1001
`define CFG_WIDTH 		32
`define ADBITS    		64
`define MTU             	12'h080  // 128 Bytes
`define MTU96           	12'h078  // 120 Bytes
`define FIRSTMEMRDLEN   	12'h100  // 256 Bytes
`define FIRSTMEMRDLEN96 	12'h0f0  // 240 Bytes
`define ZEROLEN         	12'h000


`define  RSW_ONE              1'b1
`define  RSW_ZERO             1'b0             
`define  RSW_TRUE             1
`define  RSW_FALSE            0             
`define  RSW_ALLOCTABLE_WIDTH 61
`define  RSW_LLISTTABLE_WIDTH 25
`define  RSW_FREETABLE_WIDTH  9
`define  RSW_QID_WIDTH        13
`define  RSW_BUFENTRIES       64
`define  RSW_BUFID_WIDTH      6
`define  RSW_DATASIZE         31
`define  RSW_DATA_WIDTH       256
`define  RSW_ADDR_WIDTH       7
`define  RSW_CTL_WIDTH        52 
`define  RSW_FIFO_DATA_WIDTH   64
`define  RSW_FIFO_DEPTH        72
`define  RSW_FIFO_ADDR_WIDTH    7

// CFrame Generation State Machine
`define  RSW_IDLE             3'b000
`define  RSW_INIT             3'b001
`define  RSW_LOAD             3'b010
`define  RSW_PCW              3'b011
`define  RSW_L2               3'b100
`define  RSW_DATA             3'b101
`define  RSW_EOP              3'b110

`define  RSW_MAX_SPACE_CNT    4'b0100
`define  RSW_SEVERITY         1

// config registers
`define  RSW_PORTTHRESH       5'd20
`define  RSW_PRITHRESH        5'd20
`define  RSW_PRIMODE          1'b0
`define  RSW_SOURCEINDEX      12'd4095

`define  RSW_ONE              1'b1
`define  RSW_ZERO             1'b0             
`define  RSW_QIDWIDTH         13
`define  RSW_BUFIDWIDTH       8
`define  RSW_BUFENTRIES       256
`define  RSW_DATASIZE         6'd31
`define  RSW_BUFNO            8'd0
`define  RSW_INTRWIDTH        8
`define  RSW_TESTENABLE       1'b0
`define  RSW_MODEE40      		2'd3
`define  RSW_MODEI40      		2'd2
`define  RSW_MODE20       		2'd1
`define  RSW_MODE10       		2'd0

// Pkt memory
`define  RSW_DDWIDTH          256
`define  RSW_PDWIDTH          128
`define  RSW_PAWIDTH          9
`define  RSW_XPAWIDTH         10
`define  RSW_PDEPTH           512
`define  RSW_PCNT             3
`define  RSW_PMEM0_ID         2
`define  RSW_PMEM1_ID         3
`define  RSW_PMEM2_ID         4
`define  RSW_PMEM3_ID         5

// Flowcontrol memory
`define  RSW_FDWIDTH          12
`define  RSW_FAWIDTH          10
`define  RSW_XFAWIDTH         12
`define  RSW_FMWIDTH          12
`define  RSW_FDEPTH           1024
`define  RSW_FWPSIZE          1
`define  RSW_FHPTRPOS         7:0
`define  RSW_FVLDPOS          8:8
`define  RSW_FSTSPOS          9:9
`define  RSW_FPARPOS          10:10
`define  RSW_FMEM_ID          6

// Async FIFO
`define  RSW_SFDWIDTH         128      // SF Data width
`define  RSW_SFCWIDTH         32       // SF Ctl width
`define  RSW_SFDEPTH          16       // SF Depth
`define  RSW_SFAWIDTH         4        // SF Addr
`define  RSW_SFRADDR          1        // Read enable FIFO
`define  RSW_WPOS0            127:0
`define  RSW_WPOS1            255:128
`define  RSW_SWPORTINDEX_POS  61:52 

// Loopback FIFO
`define  RSW_LPCWIDTH         22
`define  RSW_LPDWIDTH         `RSW_DDWIDTH+`RSW_LPCWIDTH
`define  RSW_LPDEPTH          8
`define  RSW_LPAWIDTH         3
`define  RSW_LPLEVEL          8
`define  RSW_LPBKCTL_POS      `RSW_LPDWIDTH-1:`RSW_DDWIDTH

// Calendar Memory
`define	RSW_CDWIDTH				9
`define	RSW_CAWIDTH				9
`define	RSW_CDEPTH 				512
`define	RSW_CRWIDTH				8
`define	RSW_LOFCS_CNT_WIDTH	4

// MaxBurst Memory
`define  RSW_MDWIDTH          9
`define  RSW_MAWIDTH          8
`define  RSW_MDEPTH           256
`define  RSW_MMWIDTH          9
`define  RSW_MWPSIZE          1

// EOB 
`define  RSW_EBDWIDTH         22

// CFrame Generation State Machine
`define  RSW_IDLE             3'b000
`define  RSW_SOC              3'b001
`define  RSW_PIPE             3'b010
`define  RSW_DBURST           3'b011
`define  RSW_EOC              3'b100
`define  RSW_TCW              3'b101
`define  RSW_TDW              3'b110
`define  RSW_PAD              3'b111

`define  RSW_MAX_SPACE_CNT    4'b0100
`define  RSW_SEVERITY         0

// Rdq interface
`define  RSW_QPORTPOS         11:10
`define  RSW_QPRISWPOS        9:0
`define  RSW_MCPOS            9:9
`define  RSW_MCPRIPOS         8:8
`define  RSW_DROPPOS          8:8
`define  RSW_QEXTPOS          12:12
`define  RSW_PORT0            2'b00
`define  RSW_PORT1            2'b01
`define  RSW_PORT2            2'b10
`define  RSW_PORT3            2'b11

// Port Threshold
`define  RSW_PORTMAX          8'd255
`define  RSW_PORTMAXL1        8'd254

// Priority Threshold
`define  RSW_PRIMAX           8'd255
`define  RSW_PRIMINP1         8'd1
`define  RSW_PRIMIN           8'd0

// Link List Table
`define  RSW_LDWIDTH          20
`define  RSW_LAWIDTH          10
`define  RSW_XLAWIDTH         12
`define  RSW_LMWIDTH          20
`define  RSW_LWPSIZE          1
`define  RSW_LDEPTH           1024
`define  RSW_LPORTPOS         7:0
`define  RSW_LBUFPOS          15:8
`define  RSW_LVLDPOS          16:16
`define  RSW_LPARPOS          17:17
`define  RSW_LCURPTRPOS       7:0
`define  RSW_LFCSTSPOS        0:0
`define  RSW_LCNT             0
`define  RSW_LMEM_ID          1
`define  RSW_LFDWIDTH         32

// Alloc Table
`define  RSW_ADWIDTH          64
`define  RSW_AAWIDTH          8
`define  RSW_XAAWIDTH         10
`define  RSW_AMWIDTH          64
`define  RSW_AWPSIZE          1
`define  RSW_ADEPTH           256
`define  RSW_ATPPOS           7:0
`define  RSW_AEOBPOS          8:8
`define  RSW_AADDRPOS         30:9
`define  RSW_ACHUNKPOS        38:31
`define  RSW_AEOPPOS          39:39
`define  RSW_ASOPPOS          40:40
`define  RSW_ASIZEPOS         46:41
`define  RSW_AQIDPOS          56:47
`define  RSW_AMCPOS           57:57
`define  RSW_ATOPOS           60:58
`define  RSW_APARPOS          63:61
`define  RSW_BUFIDPOS         7:0
`define  RSW_TIMEOUT          3'h4
`define  RSW_AFASELPOS        56:47
`define  RSW_ACNT             1
`define  RSW_AMEM_ID          0
`define  RSW_AMCPRIPOS        55:55
`define  RSW_AMCGIDPOS        53:47

`define  RSW_PRI1MODE         2'b11

`define  RSW_PRI2MODE         2'b10
`define  RSW_QPRI2POS         9:9
`define  RSW_PRI20            1'b0
`define  RSW_PRI21            1'b1

`define  RSW_PRI4MODE         2'b01
`define  RSW_QPRI4POS         9:8
`define  RSW_PRI40            2'b00
`define  RSW_PRI41            2'b01
`define  RSW_PRI42            2'b10
`define  RSW_PRI43            2'b11

`define  RSW_PRI8MODE         2'b00
`define  RSW_QPRI8POS         9:7
`define  RSW_PRI80            3'b000
`define  RSW_PRI81            3'b001
`define  RSW_PRI82            3'b010
`define  RSW_PRI83            3'b011
`define  RSW_PRI84            3'b100
`define  RSW_PRI85            3'b101
`define  RSW_PRI86            3'b110
`define  RSW_PRI87            3'b111

// temp stuff until rpc is ready
`define  RSW_VPORTPOS         9:8
`define  RSW_VBUFPOS          7:0
`define  RSW_VOQWIDTH         10

// Register Defaults
`define  RSW_CRDEF_CONTROL          22'h0261F   // 0
`define  RSW_CRDEF_STATUS           16'h0       // 1
`define  RSW_CRDEF_QUEBUFTHRESH     8'h0f       // 2
`define  RSW_CRDEF_DESTMASK         12'hFFF     // 3
`define  RSW_CRDEF_MAXSEGMENTSIZE   7'h42       // 4
`define  RSW_CRDEF_SRCINDX0         10'h001     // 5
`define  RSW_CRDEF_SRCINDX1         10'h101     // 6
`define  RSW_CRDEF_SRCINDX2         10'h201     // 7
`define  RSW_CRDEF_SRCINDX3         10'h301     // 8
`define  RSW_CRDEF_PRITHRESH0       8'h0f       // 9
`define  RSW_CRDEF_PRITHRESH1       8'h0f       // 10
`define  RSW_CRDEF_PRITHRESH2       8'h0f       // 11
`define  RSW_CRDEF_PRITHRESH3       8'h0f       // 12
`define  RSW_CRDEF_PRITHRESH4       8'h0f       // 13
`define  RSW_CRDEF_PRITHRESH5       8'h0f       // 14
`define  RSW_CRDEF_PRITHRESH6       8'h0f       // 15
`define  RSW_CRDEF_PRITHRESH7       8'h0f       // 16
`define  RSW_CRDEF_BUFTIMEOUT       3'h7        // 17
`define  RSW_CRDEF_DIP2CTL          32'h1       // 18
`define  RSW_CRDEF_BENDTEST         24'h00      // 19
`define  RSW_CRDEF_BERROR           24'h00      // 20
`define  RSW_CRDEF_SOPCNT0          16'h00      // 21
`define  RSW_CRDEF_EOPCNT0          16'h00      // 22
`define  RSW_CRDEF_SOPCNT1          16'h00      // 23
`define  RSW_CRDEF_EOPCNT1          16'h00      // 24
`define  RSW_CRDEF_SOPCNT2          16'h00      // 25
`define  RSW_CRDEF_EOPCNT2          16'h00      // 26
`define  RSW_CRDEF_SOPCNT3          16'h00      // 27
`define  RSW_CRDEF_EOPCNT3          16'h00      // 28
`define  RSW_CRDEF_REJECTCNT0       16'h00      // 29
`define  RSW_CRDEF_REJECTCNT1       16'h00      // 30
`define  RSW_CRDEF_REJECTCNT2       16'h00      // 31
`define  RSW_CRDEF_REJECTCNT3       16'h00      // 32
`define  RSW_CRDEF_EOPQIDCFG        13'h00      // 33
`define  RSW_CRDEF_LOFCSLIMIT0      16'h00      // 34
`define  RSW_CRDEF_LOFCSLIMIT1      16'h00      // 35
`define  RSW_CRDEF_LOFCSLIMIT2      16'h00      // 36
`define  RSW_CRDEF_LOFCSLIMIT3      16'h00      // 37
`define  RSW_CRDEF_LOFCSSTATUS      16'h00      // 38
// 39 - 54 are FTI registers
`define  RSW_CRDEF_DATAMAXT0        32'h0       // 55
`define  RSW_CRDEF_DATAMAXT1        32'h0       // 56
`define  RSW_CRDEF_DATAMAXT2        32'h0       // 57
`define  RSW_CRDEF_DATAMAXT3        32'h0       // 58
`define  RSW_CRDEF_ALPHA0           8'h0        // 59
`define  RSW_CRDEF_ALPHA1           8'h0        // 60
`define  RSW_CRDEF_ALPHA2           8'h0        // 61
`define  RSW_CRDEF_ALPHA3           8'h0        // 62
`define  RSW_CRDEF_SPI4FLOWCTLCFG0  24'h00      // 63
`define  RSW_CRDEF_SPI4FLOWCTLCFG1  24'h00      // 64
`define  RSW_CRDEF_SPI4FLOWCTLCFG2  24'h00      // 65
`define  RSW_CRDEF_SPI4FLOWCTLCFG3  24'h00      // 66

// Register Addr
`define  RSW_CONTROL          9'h0
`define  RSW_STATUS           9'h1
`define  RSW_QUEBUFTHRESH     9'h2
`define  RSW_DESTMASK         9'h3
`define  RSW_MAXSEGMENTSIZE   9'h4
`define  RSW_SRCINDX0         9'h5
`define  RSW_SRCINDX1         9'h6
`define  RSW_SRCINDX2         9'h7
`define  RSW_SRCINDX3         9'h8
`define  RSW_PRITHRESH0       9'h9
`define  RSW_PRITHRESH1       9'ha
`define  RSW_PRITHRESH2       9'hb
`define  RSW_PRITHRESH3       9'hc
`define  RSW_PRITHRESH4       9'hd
`define  RSW_PRITHRESH5       9'he
`define  RSW_PRITHRESH6       9'hf
`define  RSW_PRITHRESH7       9'h10
`define  RSW_BUFTIMEOUT       9'h11
`define  RSW_DIP2CTL          9'h12
`define  RSW_BENDTEST         9'h13
`define  RSW_BERROR           9'h14
`define  RSW_SOPCNT0          9'h15
`define  RSW_EOPCNT0          9'h16
`define  RSW_SOPCNT1          9'h17
`define  RSW_EOPCNT1          9'h18
`define  RSW_SOPCNT2          9'h19
`define  RSW_EOPCNT2          9'h1a
`define  RSW_SOPCNT3          9'h1b
`define  RSW_EOPCNT3          9'h1c
`define  RSW_REJECTCNT0       9'h1d
`define  RSW_REJECTCNT1       9'h1e
`define  RSW_REJECTCNT2       9'h1f
`define  RSW_REJECTCNT3       9'h20
`define  RSW_EOPQIDCFG        9'h21
`define  RSW_LOFCSLIMIT0      9'h22
`define  RSW_LOFCSLIMIT1      9'h23
`define  RSW_LOFCSLIMIT2      9'h24
`define  RSW_LOFCSLIMIT3      9'h25
`define  RSW_LOFCSSTATUS      9'h26
`define  RSW_P0A0FTI          9'h27
`define  RSW_P0A1FTI          9'h28
`define  RSW_P0A2FTI          9'h29
`define  RSW_P0A3FTI          9'h2a
`define  RSW_P1A0FTI          9'h2b
`define  RSW_P1A1FTI          9'h2c
`define  RSW_P1A2FTI          9'h2d
`define  RSW_P1A3FTI          9'h2e
`define  RSW_P2A0FTI          9'h2f
`define  RSW_P2A1FTI          9'h30
`define  RSW_P2A2FTI          9'h31
`define  RSW_P2A3FTI          9'h32
`define  RSW_P3A0FTI          9'h33
`define  RSW_P3A1FTI          9'h34
`define  RSW_P3A2FTI          9'h35
`define  RSW_P3A3FTI          9'h36
`define  RSW_DATAMAXT0        9'h37
`define  RSW_DATAMAXT1        9'h38
`define  RSW_DATAMAXT2        9'h39
`define  RSW_DATAMAXT3        9'h3a
`define  RSW_ALPHA0           9'h3b
`define  RSW_ALPHA1           9'h3c
`define  RSW_ALPHA2           9'h3d
`define  RSW_ALPHA3           9'h3e
`define  RSW_SPI4FLOWCTLCFG0  9'h3f
`define  RSW_SPI4FLOWCTLCFG1  9'h40
`define  RSW_SPI4FLOWCTLCFG2  9'h41
`define  RSW_SPI4FLOWCTLCFG3  9'h42

// Flow Control Status
`define  RSW_FCSTSWIDTH       4
`define  RSW_FCFULLSYNC       4'b1111
`define  RSW_FCHALFSYNC       2'b11
`define  RSW_SYNC_MAX         4'd12
`define  RSW_FCMESG_MAX       4'd9
`define  RSW_FCMESGWIDTH      36
`define  RSW_FCDEC_MESGWIDTH  27
`define  RSW_FC_UC_TYPE       2'b00
`define  RSW_FC_MC_TYPE       2'b01
`define  RSW_FC_CL_TYPE       4'b1000
`define  RSW_FC_ID_TYPE       2'b11
`define  RSW_FC_UC_ADDR       13:4
`define  RSW_FC_MC_ADDR       4
`define  RSW_FC_UC_CLASS      7:0
`define  RSW_FC_UC_GROUP      19:16
`define  RSW_FC_STATUS        3:0
`define  RSW_FC_DRDY          26
`define  RSW_FC_XON_STS       4'b1111
`define  RSW_FC_XOFF_STS      4'b0000
`define  RSW_FCADDRWIDTH      10
`define  RSW_FCTYPEWIDTH      2
`define  RSW_FC_MCCLASSWIDTH  1
`define  RSW_FC_UCCLASSWIDTH  8
`define  RSW_FCDEPTH          8        // SF Depth
`define  RSW_FCAWIDTH         3        // SF Addr

// Pipe 7 related
`define RSW_NPF_STAT_SYNC     2'b11
`define RSW_NPF_STAT_SATIATED	2'b10
`define RSW_NPF_STAT_HUNGRY	2'b01
`define RSW_NPF_STAT_STARVING	2'b00

`define RSW_P7_IN_SYNC			2'd0
`define RSW_P7_IN_CAL      	2'd1
`define RSW_P7_IN_DIP2     	2'd2


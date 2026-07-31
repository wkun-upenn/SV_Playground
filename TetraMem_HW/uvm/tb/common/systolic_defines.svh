//======================================================================
// systolic_defines.svh  -  shared compile-time geometry
//======================================================================
`ifndef SYSTOLIC_DEFINES_SVH
`define SYSTOLIC_DEFINES_SVH

`define DW    8               // element width (DIN_WIDTH)
`define NN    4               // array dimension N
`define ACCW  (2*`DW)         // C element width
`define BUSW  (2*`DW*`NN)     // sub-system bus width

`endif // SYSTOLIC_DEFINES_SVH

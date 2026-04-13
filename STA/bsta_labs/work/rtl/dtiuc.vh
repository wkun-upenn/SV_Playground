
// Number of (delayed) clocks created for each port.
// Changes to this number must be reflected in dticlkdelayd.
// (See also CLK_MASK_WIDTH below.)
`define DTI_CLOCKS            41

// Minimum clock phase length
// Changes to this number must be reflected in dticlkdelayd &
// dticlkmaskc.  (See also CLK_MASK_WIDTH below.)
`define DTI_MIN_PHASE_LENGTH  10

// Number of useful bits in the clock phase-overlap masks.
// Changes to this value must be reflected in dticlkmaskdelayd,
// dticlkmaskc, dtimasktolens, & the auto-instantiations in
// dticustomc and dtiuc.
`define DTI_CLK_MASK_WIDTH    (`DTI_CLOCKS-`DTI_MIN_PHASE_LENGTH)

// Width of the value used to hold the clock length for a phase or cycle
`define DTI_CLK_PHASE_WIDTH   5
`define DTI_CLK_CYCLE_WIDTH   (`DTI_CLK_PHASE_WIDTH+1)

// Width of the value used to summarize the clock length and select oversamples
`define DTI_OSAMPLE_SEL_WIDTH    5

// Bits used to accumulate extra averaging time, but ignored thereafter
`define DTI_CLK_LEN_IGNORE_LOW   3

// Width of the counter which starts a new averaging period when it rolls over
`define DTI_CLK_AVG_PERIOD_WIDTH (4+`DTI_CLK_LEN_IGNORE_LOW)

// Width of the fixed-point value holding the average clock length
`define DTI_CLK_LEN_AVG_WIDTH (`DTI_CLK_CYCLE_WIDTH+`DTI_CLK_AVG_PERIOD_WIDTH)

// Number of delay buffers in superc (approx. 4/5 of DTI_CLOCKS).
// Changes to this number should be reflected in dtisuperc.v.
`define DTI_SSAMPLE_BUFS      33

// Number of supersamples per phase (trimmed somewhat from DTI_SSAMPLE_BUFS).
// Changes to this number should be reflected in dtisuperc.v &
// its auto-instantiations in dticustomc & dtiuc.
`define DTI_SSAMPLES          20

// Number of bits in a supersample number
`define DTI_SSAMPLE_WIDTH     5

// Number of oversamples per phase
`define DTI_OSAMPLES          5

// Number of bits in an oversample number
`define DTI_OSAMPLE_WIDTH     3

// Time allowed after reset for synchronization to stablize:
//   `DTI_RESET_LENGTH * (1 << `DTI_CLK_AVG_PERIOD_WIDTH) cycles
`define DTI_CLK_SKIP             120
`define DTI_RESET_LENGTH         1

// Number of bits in the above number
`define DTI_RESET_LENGTH_WIDTH   1

// Maximum width needed for the cycle counter during the fitness period.
`define DTI_CYCLE_COUNT_WIDTH    11

// Maximum width needed for the transition counter during the fitness period.
`define DTI_TRANS_COUNT_WIDTH    12

// The width needed for the maximum possible fitness value (transitions*4).
`define DTI_FITNESS_WIDTH        (`DTI_TRANS_COUNT_WIDTH+2)

// Control register widths
`define DTI_BIT_CTRL_WIDTH       12
`define DTI_CLKLEN_CTRL_WIDTH    12

// RBB surrogate bus widths
// (The address bus width comes from a parameter, so it doesn't appear here)
`define DTI_WRDATA_WIDTH         11
`define DTI_RDDATA_WIDTH         12

// Mode register and its fields
`define DTI_TRAINING_MODE_WIDTH   2
`define DTI_CYCLE_THRESHOLD_WIDTH 3
`define DTI_TRANS_THRESHOLD_WIDTH 3
`define DTI_MODE_WIDTH (`DTI_TRAINING_MODE_WIDTH+`DTI_CYCLE_THRESHOLD_WIDTH+`DTI_TRANS_THRESHOLD_WIDTH)

`define DTI_TRAINING_MODE_RANGE   1:0
`define DTI_CYCLE_THRESHOLD_RANGE 4:2
`define DTI_TRANS_THRESHOLD_RANGE 7:5

`define DTI_MODE_RESET_VAL {{`DTI_TRANS_THRESHOLD_WIDTH{1'b0}},{`DTI_CYCLE_THRESHOLD_WIDTH{1'b0}},`DTI_FORCE_UNTRAINED}

// Training mode definitions
`define DTI_FORCE_UNTRAINED      2'd0
`define DTI_TRAIN_NORMALLY       2'd1
`define DTI_FORCE_TRAINED        2'd2
`define DTI_FORCE_TRAIN          2'd3

// Constants related to the reset stretch counter
`define DTI_STRETCH_WIDTH        8


// Mapping from logical supersample number to physical supersample number
// (accounts for skipped supersamples).
`define DTI_OSAMPLE_L0  0
`define DTI_OSAMPLE_L2  1
`define DTI_OSAMPLE_L3  2
`define DTI_OSAMPLE_L4  3
`define DTI_OSAMPLE_L5  4
`define DTI_OSAMPLE_L6  5
`define DTI_OSAMPLE_L7  6
`define DTI_OSAMPLE_L8  7
`define DTI_OSAMPLE_L9  8
`define DTI_OSAMPLE_L10 9
`define DTI_OSAMPLE_L11 10
`define DTI_OSAMPLE_L12 11
`define DTI_OSAMPLE_L14 12
`define DTI_OSAMPLE_L16 13
`define DTI_OSAMPLE_L18 14
`define DTI_OSAMPLE_L20 15
`define DTI_OSAMPLE_L22 16
`define DTI_OSAMPLE_L24 17
`define DTI_OSAMPLE_L28 18
`define DTI_OSAMPLE_L32 19

// Constants related to oversample selection based on average phase length.
// DTI_OSAMPLE_x_y are the 5 oversamples for clock length code 'x'.
// DTI_OSAMPLE_x_M is the max phase length for which to use those oversamples.
`define DTI_OSAMPLE_0_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_0_1 `DTI_OSAMPLE_L2
`define DTI_OSAMPLE_0_2 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_0_3 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_0_4 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_0_M 20

`define DTI_OSAMPLE_1_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_1_1 `DTI_OSAMPLE_L2
`define DTI_OSAMPLE_1_2 `DTI_OSAMPLE_L5
`define DTI_OSAMPLE_1_3 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_1_4 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_1_M 48

`define DTI_OSAMPLE_2_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_2_1 `DTI_OSAMPLE_L3
`define DTI_OSAMPLE_2_2 `DTI_OSAMPLE_L5
`define DTI_OSAMPLE_2_3 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_2_4 `DTI_OSAMPLE_L10
`define DTI_OSAMPLE_2_M 74

`define DTI_OSAMPLE_3_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_3_1 `DTI_OSAMPLE_L3
`define DTI_OSAMPLE_3_2 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_3_3 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_3_4 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_3_M 107

`define DTI_OSAMPLE_4_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_4_1 `DTI_OSAMPLE_L2
`define DTI_OSAMPLE_4_2 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_4_3 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_4_4 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_4_M 128

`define DTI_OSAMPLE_5_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_5_1 `DTI_OSAMPLE_L3
`define DTI_OSAMPLE_5_2 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_5_3 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_5_4 `DTI_OSAMPLE_L12
`define DTI_OSAMPLE_5_M 192

`define DTI_OSAMPLE_6_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_6_1 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_6_2 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_6_3 `DTI_OSAMPLE_L10
`define DTI_OSAMPLE_6_4 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_6_M 209

`define DTI_OSAMPLE_7_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_7_1 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_7_2 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_7_3 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_7_4 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_7_M 239

`define DTI_OSAMPLE_8_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_8_1 `DTI_OSAMPLE_L3
`define DTI_OSAMPLE_8_2 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_8_3 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_8_4 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_8_M 276

`define DTI_OSAMPLE_9_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_9_1 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_9_2 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_9_3 `DTI_OSAMPLE_L12
`define DTI_OSAMPLE_9_4 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_9_M 352

`define DTI_OSAMPLE_10_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_10_1 `DTI_OSAMPLE_L5
`define DTI_OSAMPLE_10_2 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_10_3 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_10_4 `DTI_OSAMPLE_L18
`define DTI_OSAMPLE_10_M 400

`define DTI_OSAMPLE_11_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_11_1 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_11_2 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_11_3 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_11_4 `DTI_OSAMPLE_L18
`define DTI_OSAMPLE_11_M 449

`define DTI_OSAMPLE_12_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_12_1 `DTI_OSAMPLE_L4
`define DTI_OSAMPLE_12_2 `DTI_OSAMPLE_L10
`define DTI_OSAMPLE_12_3 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_12_4 `DTI_OSAMPLE_L20
`define DTI_OSAMPLE_12_M 479

`define DTI_OSAMPLE_13_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_13_1 `DTI_OSAMPLE_L5
`define DTI_OSAMPLE_13_2 `DTI_OSAMPLE_L10
`define DTI_OSAMPLE_13_3 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_13_4 `DTI_OSAMPLE_L20
`define DTI_OSAMPLE_13_M 504

`define DTI_OSAMPLE_14_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_14_1 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_14_2 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_14_3 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_14_4 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_14_M 537

`define DTI_OSAMPLE_15_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_15_1 `DTI_OSAMPLE_L5
`define DTI_OSAMPLE_15_2 `DTI_OSAMPLE_L11
`define DTI_OSAMPLE_15_3 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_15_4 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_15_M 579

`define DTI_OSAMPLE_16_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_16_1 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_16_2 `DTI_OSAMPLE_L12
`define DTI_OSAMPLE_16_3 `DTI_OSAMPLE_L18
`define DTI_OSAMPLE_16_4 `DTI_OSAMPLE_L24
`define DTI_OSAMPLE_16_M 598

`define DTI_OSAMPLE_17_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_17_1 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_17_2 `DTI_OSAMPLE_L12
`define DTI_OSAMPLE_17_3 `DTI_OSAMPLE_L18
`define DTI_OSAMPLE_17_4 `DTI_OSAMPLE_L24
`define DTI_OSAMPLE_17_M 717

`define DTI_OSAMPLE_18_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_18_1 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_18_2 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_18_3 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_18_4 `DTI_OSAMPLE_L28
`define DTI_OSAMPLE_18_M 729

`define DTI_OSAMPLE_19_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_19_1 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_19_2 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_19_3 `DTI_OSAMPLE_L20
`define DTI_OSAMPLE_19_4 `DTI_OSAMPLE_L28
`define DTI_OSAMPLE_19_M 754

`define DTI_OSAMPLE_20_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_20_1 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_20_2 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_20_3 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_20_4 `DTI_OSAMPLE_L28
`define DTI_OSAMPLE_20_M 800

`define DTI_OSAMPLE_21_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_21_1 `DTI_OSAMPLE_L7
`define DTI_OSAMPLE_21_2 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_21_3 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_21_4 `DTI_OSAMPLE_L28
`define DTI_OSAMPLE_21_M 835

`define DTI_OSAMPLE_22_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_22_1 `DTI_OSAMPLE_L6
`define DTI_OSAMPLE_22_2 `DTI_OSAMPLE_L14
`define DTI_OSAMPLE_22_3 `DTI_OSAMPLE_L22
`define DTI_OSAMPLE_22_4 `DTI_OSAMPLE_L28
`define DTI_OSAMPLE_22_M 877

`define DTI_OSAMPLE_23_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_23_1 `DTI_OSAMPLE_L9
`define DTI_OSAMPLE_23_2 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_23_3 `DTI_OSAMPLE_L24
`define DTI_OSAMPLE_23_4 `DTI_OSAMPLE_L32
`define DTI_OSAMPLE_23_M 911

`define DTI_OSAMPLE_24_0 `DTI_OSAMPLE_L0
`define DTI_OSAMPLE_24_1 `DTI_OSAMPLE_L8
`define DTI_OSAMPLE_24_2 `DTI_OSAMPLE_L16
`define DTI_OSAMPLE_24_3 `DTI_OSAMPLE_L24
`define DTI_OSAMPLE_24_4 `DTI_OSAMPLE_L32
`define DTI_OSAMPLE_24_M 992


//-----------------------------------------------------------------------------
// Modification history :
// Mon May 31 12:00:00 2002 : created
//
// $Log: dtiuc.vh,v $
// Revision 1.6  2002/08/13 23:29:17  chris
// Increase phase length range, but reduce supersamples by skipping
//
// Revision 1.5  2002/08/08 17:14:14  chris
// Extend clock averaging to 256 UI; add prog. micro-deskew thresholds
//
// Revision 1.4  2002/07/26 18:32:56  chris
// Use PortVld for stretched reset
//
// Revision 1.3  2002/07/12 23:14:14  chris
// Add change log
//

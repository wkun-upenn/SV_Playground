//=============================================================================
// Tree-PLRU (Pseudo Least-Recently-Used) replacement, 4-way set
//-----------------------------------------------------------------------------
// 3 state bits per set, arranged as a binary tree over the 4 ways:
//
//                 b[0]                (root)
//                /    \
//             b[1]     b[2]
//             /  \     /  \
//           W0   W1   W2   W3
//
// Encoding (bit points toward the LRU / victim side):
//   b0 = 0 -> left  subtree (W0/W1) holds the victim
//   b0 = 1 -> right subtree (W2/W3) holds the victim
//   b1 = 0 -> W0 is victim ,  b1 = 1 -> W1 is victim
//   b2 = 0 -> W2 is victim ,  b2 = 1 -> W3 is victim
//
// On ACCESS to way W : flip the bits on the root->W path to point AWAY from W.
// On EVICTION        : follow the bits from the root to the leaf = victim.
//=============================================================================
module plru_4way (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        access_en,    // assert when a way is touched (hit or fill)
    input  logic [1:0]  access_way,   // which way was touched
    output logic [1:0]  victim_way    // current LRU victim (combinational)
);

    logic [2:0] plru;                 // {b2, b1, b0} stored as plru[2:0]

    //--- Victim selection : walk the tree following the bits -------------
    always_comb begin
        if (plru[0] == 1'b0)                       // left subtree is LRU
            victim_way = (plru[1] == 1'b0) ? 2'd0 : 2'd1;
        else                                       // right subtree is LRU
            victim_way = (plru[2] == 1'b0) ? 2'd2 : 2'd3;
    end

    //--- Update on access : point the path bits AWAY from access_way ----
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            plru <= 3'b000;
        else if (access_en) begin
            unique case (access_way)
                2'd0: begin plru[0] <= 1'b1; plru[1] <= 1'b1; end  // away from left, away from W0
                2'd1: begin plru[0] <= 1'b1; plru[1] <= 1'b0; end  // away from left, away from W1
                2'd2: begin plru[0] <= 1'b0; plru[2] <= 1'b1; end  // away from right, away from W2
                2'd3: begin plru[0] <= 1'b0; plru[2] <= 1'b0; end  // away from right, away from W3
            endcase
        end
    end

endmodule


//=============================================================================
// Per-set wrapper : one 3-bit PLRU state per cache set
//=============================================================================
module plru_4way_sets #(
    parameter int NUM_SETS = 256,
    parameter int SET_W    = $clog2(NUM_SETS)
)(
    input  logic               clk,
    input  logic               rst_n,
    input  logic               access_en,
    input  logic [SET_W-1:0]   access_set,   // which set is being accessed
    input  logic [1:0]         access_way,
    input  logic [SET_W-1:0]   victim_set,   // set to pick a victim from
    output logic [1:0]         victim_way
);

    logic [2:0] plru [NUM_SETS];

    // victim from the requested set
    always_comb begin
        logic [2:0] s;
        s = plru[victim_set];
        if (s[0] == 1'b0) victim_way = (s[1] == 1'b0) ? 2'd0 : 2'd1;
        else              victim_way = (s[2] == 1'b0) ? 2'd2 : 2'd3;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_SETS; i++) plru[i] <= 3'b000;
        end else if (access_en) begin
            unique case (access_way)
                2'd0: begin plru[access_set][0] <= 1'b1; plru[access_set][1] <= 1'b1; end
                2'd1: begin plru[access_set][0] <= 1'b1; plru[access_set][1] <= 1'b0; end
                2'd2: begin plru[access_set][0] <= 1'b0; plru[access_set][2] <= 1'b1; end
                2'd3: begin plru[access_set][0] <= 1'b0; plru[access_set][2] <= 1'b0; end
            endcase
        end
    end

endmodule

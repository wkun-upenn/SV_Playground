//=============================================================================
// Simple synchronous single-port SRAM
//   - one address port : one read OR write per clock
//   - synchronous read : rdata is registered, valid one cycle after addr
//   - read-first on a write : reading the written address returns OLD data
//=============================================================================
module sram #(
    parameter int DATA_W = 32,
    parameter int DEPTH  = 1024,
    parameter int ADDR_W = $clog2(DEPTH)
)(
    input  logic                clk,
    input  logic                en,      // chip enable (gates read & write)
    input  logic                we,      // write enable
    input  logic [ADDR_W-1:0]   addr,
    input  logic [DATA_W-1:0]   wdata,
    output logic [DATA_W-1:0]   rdata
);

    // Memory array
    logic [DATA_W-1:0] mem [DEPTH];

    always_ff @(posedge clk) begin
        if (en) begin
            if (we)
                mem[addr] <= wdata;     // synchronous write
            rdata <= mem[addr];         // synchronous read (old data on write)
        end
    end

endmodule

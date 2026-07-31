/*******************************************************************************
 * File        : axi_2m3s_full_dut.v
 * Project     : AXI4 Full 2M3S UVM Teaching Project
 * Purpose     : AXI4 Full 2-master 3-slave teaching RTL DUT.
 * Style       : Course-ready code with clear structure for RTL/UVM explanation.
 * Learn More  : www.bcbaoic.top
 *******************************************************************************/

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Teaching RTL: 2-master / 3-slave AXI4-Full style memory system
// -----------------------------------------------------------------------------
// Scope intentionally kept manageable for a UVM teaching project:
// - 2 AXI master-facing ports: m0_* and m1_*
// - 3 internal RAM slaves selected by address decode
// - 32-bit data, 32-bit address, 4-bit ID
// - INCR bursts, AWSIZE/ARSIZE expected to be 3'b010
// - Multiple outstanding read/write requests are accepted by fixed-depth slots
// - Responses may return out of order across different IDs because each slave has
//   a different response latency. Same-ID ordering is not fully enforced in this
//   teaching RTL, so tests should use different IDs when demonstrating OoO.
// - Illegal address or burst crossing slave boundary returns DECERR.
//
// Address map:
//   S0: 0x0000_0000 - 0x0000_0FFF
//   S1: 0x0001_0000 - 0x0001_0FFF
//   S2: 0x0002_0000 - 0x0002_0FFF
// -----------------------------------------------------------------------------

module axi_2m3s_full_dut #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter RD_SLOTS   = 8,
    parameter WR_SLOTS   = 8,
    parameter MEM_BYTES  = 4096
)(
    input  wire aclk,
    input  wire aresetn,

    // ------------------------- M0 write address ------------------------------
    input  wire [ID_WIDTH-1:0]   m0_awid,
    input  wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire [7:0]            m0_awlen,
    input  wire [2:0]            m0_awsize,
    input  wire [1:0]            m0_awburst,
    input  wire                  m0_awvalid,
    output reg                   m0_awready,
    // ------------------------- M0 write data ---------------------------------
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input  wire                  m0_wlast,
    input  wire                  m0_wvalid,
    output reg                   m0_wready,
    // ------------------------- M0 write response -----------------------------
    output reg  [ID_WIDTH-1:0]   m0_bid,
    output reg  [1:0]            m0_bresp,
    output reg                   m0_bvalid,
    input  wire                  m0_bready,
    // ------------------------- M0 read address -------------------------------
    input  wire [ID_WIDTH-1:0]   m0_arid,
    input  wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]            m0_arlen,
    input  wire [2:0]            m0_arsize,
    input  wire [1:0]            m0_arburst,
    input  wire                  m0_arvalid,
    output reg                   m0_arready,
    // ------------------------- M0 read data ----------------------------------
    output reg  [ID_WIDTH-1:0]   m0_rid,
    output reg  [DATA_WIDTH-1:0] m0_rdata,
    output reg  [1:0]            m0_rresp,
    output reg                   m0_rlast,
    output reg                   m0_rvalid,
    input  wire                  m0_rready,

    // ------------------------- M1 write address ------------------------------
    input  wire [ID_WIDTH-1:0]   m1_awid,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]            m1_awlen,
    input  wire [2:0]            m1_awsize,
    input  wire [1:0]            m1_awburst,
    input  wire                  m1_awvalid,
    output reg                   m1_awready,
    // ------------------------- M1 write data ---------------------------------
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input  wire                  m1_wlast,
    input  wire                  m1_wvalid,
    output reg                   m1_wready,
    // ------------------------- M1 write response -----------------------------
    output reg  [ID_WIDTH-1:0]   m1_bid,
    output reg  [1:0]            m1_bresp,
    output reg                   m1_bvalid,
    input  wire                  m1_bready,
    // ------------------------- M1 read address -------------------------------
    input  wire [ID_WIDTH-1:0]   m1_arid,
    input  wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]            m1_arlen,
    input  wire [2:0]            m1_arsize,
    input  wire [1:0]            m1_arburst,
    input  wire                  m1_arvalid,
    output reg                   m1_arready,
    // ------------------------- M1 read data ----------------------------------
    output reg  [ID_WIDTH-1:0]   m1_rid,
    output reg  [DATA_WIDTH-1:0] m1_rdata,
    output reg  [1:0]            m1_rresp,
    output reg                   m1_rlast,
    output reg                   m1_rvalid,
    input  wire                  m1_rready
);

localparam [1:0] AXI_RESP_OKAY   = 2'b00;
localparam [1:0] AXI_RESP_DECERR = 2'b11;
localparam [1:0] AXI_BURST_INCR  = 2'b01;
localparam [1:0] SLV_S0          = 2'd0;
localparam [1:0] SLV_S1          = 2'd1;
localparam [1:0] SLV_S2          = 2'd2;
localparam [1:0] SLV_INVALID     = 2'd3;

reg [7:0] mem0 [0:MEM_BYTES-1];
reg [7:0] mem1 [0:MEM_BYTES-1];
reg [7:0] mem2 [0:MEM_BYTES-1];

integer i;
integer sel;
integer free_idx;
integer init_i;

initial begin
    for (init_i = 0; init_i < MEM_BYTES; init_i = init_i + 1) begin
        mem0[init_i] = 8'h00;
        mem1[init_i] = 8'h00;
        mem2[init_i] = 8'h00;
    end
end

function [1:0] decode_slave;
    input [ADDR_WIDTH-1:0] addr;
    begin
        if (addr >= 32'h0000_0000 && addr <= 32'h0000_0FFF)
            decode_slave = SLV_S0;
        else if (addr >= 32'h0001_0000 && addr <= 32'h0001_0FFF)
            decode_slave = SLV_S1;
        else if (addr >= 32'h0002_0000 && addr <= 32'h0002_0FFF)
            decode_slave = SLV_S2;
        else
            decode_slave = SLV_INVALID;
    end
endfunction

function legal_burst;
    input [ADDR_WIDTH-1:0] addr;
    input [7:0] len;
    input [2:0] size;
    input [1:0] burst;
    reg [ADDR_WIDTH-1:0] last_addr;
    begin
        last_addr = addr + ({24'd0, len} << 2);
        legal_burst = (burst == AXI_BURST_INCR) &&
                      (size  == 3'b010) &&
                      (decode_slave(addr) != SLV_INVALID) &&
                      (decode_slave(addr) == decode_slave(last_addr));
    end
endfunction

function [7:0] slave_latency;
    input [1:0] slave;
    input [ID_WIDTH-1:0] id;
    begin
        case (slave)
            SLV_S0: slave_latency = 8'd2 + {6'd0, id[1:0]};
            SLV_S1: slave_latency = 8'd5 + {6'd0, id[1:0]};
            SLV_S2: slave_latency = 8'd9 + {6'd0, id[1:0]};
            default: slave_latency = 8'd3;
        endcase
    end
endfunction

function [31:0] read_word;
    input [1:0] slave;
    input [ADDR_WIDTH-1:0] addr;
    reg [11:0] off;
    begin
        off = addr[11:0];
        case (slave)
            SLV_S0: read_word = {mem0[off+3], mem0[off+2], mem0[off+1], mem0[off+0]};
            SLV_S1: read_word = {mem1[off+3], mem1[off+2], mem1[off+1], mem1[off+0]};
            SLV_S2: read_word = {mem2[off+3], mem2[off+2], mem2[off+1], mem2[off+0]};
            default: read_word = 32'h0000_0000;
        endcase
    end
endfunction

task write_word;
    input [1:0] slave;
    input [ADDR_WIDTH-1:0] addr;
    input [31:0] data;
    input [3:0] strb;
    reg [11:0] off;
    begin
        off = addr[11:0];
        case (slave)
            SLV_S0: begin
                if (strb[0]) mem0[off+0] = data[7:0];
                if (strb[1]) mem0[off+1] = data[15:8];
                if (strb[2]) mem0[off+2] = data[23:16];
                if (strb[3]) mem0[off+3] = data[31:24];
            end
            SLV_S1: begin
                if (strb[0]) mem1[off+0] = data[7:0];
                if (strb[1]) mem1[off+1] = data[15:8];
                if (strb[2]) mem1[off+2] = data[23:16];
                if (strb[3]) mem1[off+3] = data[31:24];
            end
            SLV_S2: begin
                if (strb[0]) mem2[off+0] = data[7:0];
                if (strb[1]) mem2[off+1] = data[15:8];
                if (strb[2]) mem2[off+2] = data[23:16];
                if (strb[3]) mem2[off+3] = data[31:24];
            end
            default: begin end
        endcase
    end
endtask

// -----------------------------------------------------------------------------
// M0 state
// -----------------------------------------------------------------------------
reg                   m0_rslot_valid [0:RD_SLOTS-1];
reg [ID_WIDTH-1:0]    m0_rslot_id    [0:RD_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m0_rslot_addr  [0:RD_SLOTS-1];
reg [7:0]             m0_rslot_len   [0:RD_SLOTS-1];
reg [1:0]             m0_rslot_resp  [0:RD_SLOTS-1];
reg [1:0]             m0_rslot_slave [0:RD_SLOTS-1];
reg [7:0]             m0_rslot_delay [0:RD_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m0_ractive_addr;
reg [7:0]             m0_ractive_len;
reg [7:0]             m0_ractive_beat;
reg [1:0]             m0_ractive_slave;

reg                   m0_awslot_valid [0:WR_SLOTS-1];
reg [ID_WIDTH-1:0]    m0_awslot_id    [0:WR_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m0_awslot_addr  [0:WR_SLOTS-1];
reg [7:0]             m0_awslot_len   [0:WR_SLOTS-1];
reg [1:0]             m0_awslot_resp  [0:WR_SLOTS-1];
reg [1:0]             m0_awslot_slave [0:WR_SLOTS-1];
reg                   m0_wactive;
reg [ID_WIDTH-1:0]    m0_wid;
reg [ADDR_WIDTH-1:0]  m0_waddr;
reg [7:0]             m0_wlen;
reg [7:0]             m0_wbeat;
reg [1:0]             m0_wresp;
reg [1:0]             m0_wslave;
reg                   m0_bslot_valid [0:WR_SLOTS-1];
reg [ID_WIDTH-1:0]    m0_bslot_id    [0:WR_SLOTS-1];
reg [1:0]             m0_bslot_resp  [0:WR_SLOTS-1];
reg [7:0]             m0_bslot_delay [0:WR_SLOTS-1];

// -----------------------------------------------------------------------------
// M1 state
// -----------------------------------------------------------------------------
reg                   m1_rslot_valid [0:RD_SLOTS-1];
reg [ID_WIDTH-1:0]    m1_rslot_id    [0:RD_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m1_rslot_addr  [0:RD_SLOTS-1];
reg [7:0]             m1_rslot_len   [0:RD_SLOTS-1];
reg [1:0]             m1_rslot_resp  [0:RD_SLOTS-1];
reg [1:0]             m1_rslot_slave [0:RD_SLOTS-1];
reg [7:0]             m1_rslot_delay [0:RD_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m1_ractive_addr;
reg [7:0]             m1_ractive_len;
reg [7:0]             m1_ractive_beat;
reg [1:0]             m1_ractive_slave;

reg                   m1_awslot_valid [0:WR_SLOTS-1];
reg [ID_WIDTH-1:0]    m1_awslot_id    [0:WR_SLOTS-1];
reg [ADDR_WIDTH-1:0]  m1_awslot_addr  [0:WR_SLOTS-1];
reg [7:0]             m1_awslot_len   [0:WR_SLOTS-1];
reg [1:0]             m1_awslot_resp  [0:WR_SLOTS-1];
reg [1:0]             m1_awslot_slave [0:WR_SLOTS-1];
reg                   m1_wactive;
reg [ID_WIDTH-1:0]    m1_wid;
reg [ADDR_WIDTH-1:0]  m1_waddr;
reg [7:0]             m1_wlen;
reg [7:0]             m1_wbeat;
reg [1:0]             m1_wresp;
reg [1:0]             m1_wslave;
reg                   m1_bslot_valid [0:WR_SLOTS-1];
reg [ID_WIDTH-1:0]    m1_bslot_id    [0:WR_SLOTS-1];
reg [1:0]             m1_bslot_resp  [0:WR_SLOTS-1];
reg [7:0]             m1_bslot_delay [0:WR_SLOTS-1];

// Ready generation
always @* begin
    m0_awready = 1'b0;
    m0_arready = 1'b0;
    m1_awready = 1'b0;
    m1_arready = 1'b0;
    for (i = 0; i < WR_SLOTS; i = i + 1) begin
        if (!m0_awslot_valid[i]) m0_awready = 1'b1;
        if (!m1_awslot_valid[i]) m1_awready = 1'b1;
    end
    for (i = 0; i < RD_SLOTS; i = i + 1) begin
        if (!m0_rslot_valid[i]) m0_arready = 1'b1;
        if (!m1_rslot_valid[i]) m1_arready = 1'b1;
    end
    if (!aresetn) begin
        m0_awready = 1'b0;
        m0_arready = 1'b0;
        m1_awready = 1'b0;
        m1_arready = 1'b0;
    end
    m0_wready = aresetn && m0_wactive;
    m1_wready = aresetn && m1_wactive;
end

// Main state machine for both master-facing ports.
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        m0_bvalid <= 1'b0; m0_bresp <= AXI_RESP_OKAY; m0_bid <= {ID_WIDTH{1'b0}};
        m0_rvalid <= 1'b0; m0_rresp <= AXI_RESP_OKAY; m0_rid <= {ID_WIDTH{1'b0}}; m0_rdata <= {DATA_WIDTH{1'b0}}; m0_rlast <= 1'b0;
        m0_wactive <= 1'b0; m0_wbeat <= 8'd0;
        m1_bvalid <= 1'b0; m1_bresp <= AXI_RESP_OKAY; m1_bid <= {ID_WIDTH{1'b0}};
        m1_rvalid <= 1'b0; m1_rresp <= AXI_RESP_OKAY; m1_rid <= {ID_WIDTH{1'b0}}; m1_rdata <= {DATA_WIDTH{1'b0}}; m1_rlast <= 1'b0;
        m1_wactive <= 1'b0; m1_wbeat <= 8'd0;
        for (i = 0; i < RD_SLOTS; i = i + 1) begin
            m0_rslot_valid[i] <= 1'b0;
            m1_rslot_valid[i] <= 1'b0;
        end
        for (i = 0; i < WR_SLOTS; i = i + 1) begin
            m0_awslot_valid[i] <= 1'b0;
            m0_bslot_valid[i]  <= 1'b0;
            m1_awslot_valid[i] <= 1'b0;
            m1_bslot_valid[i]  <= 1'b0;
        end
    end else begin
        // delay counters
        for (i = 0; i < RD_SLOTS; i = i + 1) begin
            if (m0_rslot_valid[i] && m0_rslot_delay[i] != 8'd0) m0_rslot_delay[i] <= m0_rslot_delay[i] - 8'd1;
            if (m1_rslot_valid[i] && m1_rslot_delay[i] != 8'd0) m1_rslot_delay[i] <= m1_rslot_delay[i] - 8'd1;
        end
        for (i = 0; i < WR_SLOTS; i = i + 1) begin
            if (m0_bslot_valid[i] && m0_bslot_delay[i] != 8'd0) m0_bslot_delay[i] <= m0_bslot_delay[i] - 8'd1;
            if (m1_bslot_valid[i] && m1_bslot_delay[i] != 8'd0) m1_bslot_delay[i] <= m1_bslot_delay[i] - 8'd1;
        end

        // ----------------------------- M0 AR accept --------------------------
        if (m0_arvalid && m0_arready) begin
            free_idx = -1;
            for (i = 0; i < RD_SLOTS; i = i + 1) begin
                if (!m0_rslot_valid[i] && free_idx == -1) free_idx = i;
            end
            if (free_idx != -1) begin
                m0_rslot_valid[free_idx] <= 1'b1;
                m0_rslot_id[free_idx]    <= m0_arid;
                m0_rslot_addr[free_idx]  <= m0_araddr;
                m0_rslot_len[free_idx]   <= m0_arlen;
                m0_rslot_slave[free_idx] <= decode_slave(m0_araddr);
                m0_rslot_resp[free_idx]  <= legal_burst(m0_araddr, m0_arlen, m0_arsize, m0_arburst) ? AXI_RESP_OKAY : AXI_RESP_DECERR;
                m0_rslot_delay[free_idx] <= slave_latency(decode_slave(m0_araddr), m0_arid);
            end
        end

        // ----------------------------- M1 AR accept --------------------------
        if (m1_arvalid && m1_arready) begin
            free_idx = -1;
            for (i = 0; i < RD_SLOTS; i = i + 1) begin
                if (!m1_rslot_valid[i] && free_idx == -1) free_idx = i;
            end
            if (free_idx != -1) begin
                m1_rslot_valid[free_idx] <= 1'b1;
                m1_rslot_id[free_idx]    <= m1_arid;
                m1_rslot_addr[free_idx]  <= m1_araddr;
                m1_rslot_len[free_idx]   <= m1_arlen;
                m1_rslot_slave[free_idx] <= decode_slave(m1_araddr);
                m1_rslot_resp[free_idx]  <= legal_burst(m1_araddr, m1_arlen, m1_arsize, m1_arburst) ? AXI_RESP_OKAY : AXI_RESP_DECERR;
                m1_rslot_delay[free_idx] <= slave_latency(decode_slave(m1_araddr), m1_arid);
            end
        end

        // ----------------------------- M0 AW accept --------------------------
        if (m0_awvalid && m0_awready) begin
            free_idx = -1;
            for (i = 0; i < WR_SLOTS; i = i + 1) begin
                if (!m0_awslot_valid[i] && free_idx == -1) free_idx = i;
            end
            if (free_idx != -1) begin
                m0_awslot_valid[free_idx] <= 1'b1;
                m0_awslot_id[free_idx]    <= m0_awid;
                m0_awslot_addr[free_idx]  <= m0_awaddr;
                m0_awslot_len[free_idx]   <= m0_awlen;
                m0_awslot_slave[free_idx] <= decode_slave(m0_awaddr);
                m0_awslot_resp[free_idx]  <= legal_burst(m0_awaddr, m0_awlen, m0_awsize, m0_awburst) ? AXI_RESP_OKAY : AXI_RESP_DECERR;
            end
        end

        // ----------------------------- M1 AW accept --------------------------
        if (m1_awvalid && m1_awready) begin
            free_idx = -1;
            for (i = 0; i < WR_SLOTS; i = i + 1) begin
                if (!m1_awslot_valid[i] && free_idx == -1) free_idx = i;
            end
            if (free_idx != -1) begin
                m1_awslot_valid[free_idx] <= 1'b1;
                m1_awslot_id[free_idx]    <= m1_awid;
                m1_awslot_addr[free_idx]  <= m1_awaddr;
                m1_awslot_len[free_idx]   <= m1_awlen;
                m1_awslot_slave[free_idx] <= decode_slave(m1_awaddr);
                m1_awslot_resp[free_idx]  <= legal_burst(m1_awaddr, m1_awlen, m1_awsize, m1_awburst) ? AXI_RESP_OKAY : AXI_RESP_DECERR;
            end
        end

        // ----------------------------- M0 start W context --------------------
        if (!m0_wactive) begin
            sel = -1;
            for (i = 0; i < WR_SLOTS; i = i + 1) begin
                if (m0_awslot_valid[i] && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m0_wactive <= 1'b1;
                m0_wid     <= m0_awslot_id[sel];
                m0_waddr   <= m0_awslot_addr[sel];
                m0_wlen    <= m0_awslot_len[sel];
                m0_wresp   <= m0_awslot_resp[sel];
                m0_wslave  <= m0_awslot_slave[sel];
                m0_wbeat   <= 8'd0;
                m0_awslot_valid[sel] <= 1'b0;
            end
        end else if (m0_wvalid && m0_wready) begin
            if (m0_wresp == AXI_RESP_OKAY) begin
                write_word(m0_wslave, m0_waddr + ({24'd0, m0_wbeat} << 2), m0_wdata, m0_wstrb);
            end
            if (m0_wlast || m0_wbeat == m0_wlen) begin
                free_idx = -1;
                for (i = 0; i < WR_SLOTS; i = i + 1) begin
                    if (!m0_bslot_valid[i] && free_idx == -1) free_idx = i;
                end
                if (free_idx != -1) begin
                    m0_bslot_valid[free_idx] <= 1'b1;
                    m0_bslot_id[free_idx]    <= m0_wid;
                    m0_bslot_resp[free_idx]  <= m0_wresp;
                    m0_bslot_delay[free_idx] <= slave_latency(m0_wslave, m0_wid);
                end
                m0_wactive <= 1'b0;
            end else begin
                m0_wbeat <= m0_wbeat + 8'd1;
            end
        end

        // ----------------------------- M1 start W context --------------------
        if (!m1_wactive) begin
            sel = -1;
            for (i = 0; i < WR_SLOTS; i = i + 1) begin
                if (m1_awslot_valid[i] && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m1_wactive <= 1'b1;
                m1_wid     <= m1_awslot_id[sel];
                m1_waddr   <= m1_awslot_addr[sel];
                m1_wlen    <= m1_awslot_len[sel];
                m1_wresp   <= m1_awslot_resp[sel];
                m1_wslave  <= m1_awslot_slave[sel];
                m1_wbeat   <= 8'd0;
                m1_awslot_valid[sel] <= 1'b0;
            end
        end else if (m1_wvalid && m1_wready) begin
            if (m1_wresp == AXI_RESP_OKAY) begin
                write_word(m1_wslave, m1_waddr + ({24'd0, m1_wbeat} << 2), m1_wdata, m1_wstrb);
            end
            if (m1_wlast || m1_wbeat == m1_wlen) begin
                free_idx = -1;
                for (i = 0; i < WR_SLOTS; i = i + 1) begin
                    if (!m1_bslot_valid[i] && free_idx == -1) free_idx = i;
                end
                if (free_idx != -1) begin
                    m1_bslot_valid[free_idx] <= 1'b1;
                    m1_bslot_id[free_idx]    <= m1_wid;
                    m1_bslot_resp[free_idx]  <= m1_wresp;
                    m1_bslot_delay[free_idx] <= slave_latency(m1_wslave, m1_wid);
                end
                m1_wactive <= 1'b0;
            end else begin
                m1_wbeat <= m1_wbeat + 8'd1;
            end
        end

        // ----------------------------- M0 B channel --------------------------
        if (m0_bvalid && m0_bready) begin
            m0_bvalid <= 1'b0;
        end else if (!m0_bvalid) begin
            sel = -1;
            for (i = WR_SLOTS-1; i >= 0; i = i - 1) begin
                if (m0_bslot_valid[i] && m0_bslot_delay[i] == 8'd0 && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m0_bid    <= m0_bslot_id[sel];
                m0_bresp  <= m0_bslot_resp[sel];
                m0_bvalid <= 1'b1;
                m0_bslot_valid[sel] <= 1'b0;
            end
        end

        // ----------------------------- M1 B channel --------------------------
        if (m1_bvalid && m1_bready) begin
            m1_bvalid <= 1'b0;
        end else if (!m1_bvalid) begin
            sel = -1;
            for (i = WR_SLOTS-1; i >= 0; i = i - 1) begin
                if (m1_bslot_valid[i] && m1_bslot_delay[i] == 8'd0 && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m1_bid    <= m1_bslot_id[sel];
                m1_bresp  <= m1_bslot_resp[sel];
                m1_bvalid <= 1'b1;
                m1_bslot_valid[sel] <= 1'b0;
            end
        end

        // ----------------------------- M0 R channel --------------------------
        if (m0_rvalid && m0_rready) begin
            if (m0_ractive_beat == m0_ractive_len) begin
                m0_rvalid <= 1'b0;
                m0_rlast  <= 1'b0;
            end else begin
                m0_ractive_beat <= m0_ractive_beat + 8'd1;
                m0_rdata <= (m0_rresp == AXI_RESP_OKAY) ? read_word(m0_ractive_slave, m0_ractive_addr + ({24'd0, (m0_ractive_beat + 8'd1)} << 2)) : 32'h0000_0000;
                m0_rlast <= ((m0_ractive_beat + 8'd1) == m0_ractive_len);
            end
        end else if (!m0_rvalid) begin
            sel = -1;
            for (i = RD_SLOTS-1; i >= 0; i = i - 1) begin
                if (m0_rslot_valid[i] && m0_rslot_delay[i] == 8'd0 && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m0_rid           <= m0_rslot_id[sel];
                m0_rresp         <= m0_rslot_resp[sel];
                m0_rdata         <= (m0_rslot_resp[sel] == AXI_RESP_OKAY) ? read_word(m0_rslot_slave[sel], m0_rslot_addr[sel]) : 32'h0000_0000;
                m0_rlast         <= (m0_rslot_len[sel] == 8'd0);
                m0_rvalid        <= 1'b1;
                m0_ractive_addr  <= m0_rslot_addr[sel];
                m0_ractive_len   <= m0_rslot_len[sel];
                m0_ractive_beat  <= 8'd0;
                m0_ractive_slave <= m0_rslot_slave[sel];
                m0_rslot_valid[sel] <= 1'b0;
            end
        end

        // ----------------------------- M1 R channel --------------------------
        if (m1_rvalid && m1_rready) begin
            if (m1_ractive_beat == m1_ractive_len) begin
                m1_rvalid <= 1'b0;
                m1_rlast  <= 1'b0;
            end else begin
                m1_ractive_beat <= m1_ractive_beat + 8'd1;
                m1_rdata <= (m1_rresp == AXI_RESP_OKAY) ? read_word(m1_ractive_slave, m1_ractive_addr + ({24'd0, (m1_ractive_beat + 8'd1)} << 2)) : 32'h0000_0000;
                m1_rlast <= ((m1_ractive_beat + 8'd1) == m1_ractive_len);
            end
        end else if (!m1_rvalid) begin
            sel = -1;
            for (i = RD_SLOTS-1; i >= 0; i = i - 1) begin
                if (m1_rslot_valid[i] && m1_rslot_delay[i] == 8'd0 && sel == -1) sel = i;
            end
            if (sel != -1) begin
                m1_rid           <= m1_rslot_id[sel];
                m1_rresp         <= m1_rslot_resp[sel];
                m1_rdata         <= (m1_rslot_resp[sel] == AXI_RESP_OKAY) ? read_word(m1_rslot_slave[sel], m1_rslot_addr[sel]) : 32'h0000_0000;
                m1_rlast         <= (m1_rslot_len[sel] == 8'd0);
                m1_rvalid        <= 1'b1;
                m1_ractive_addr  <= m1_rslot_addr[sel];
                m1_ractive_len   <= m1_rslot_len[sel];
                m1_ractive_beat  <= 8'd0;
                m1_ractive_slave <= m1_rslot_slave[sel];
                m1_rslot_valid[sel] <= 1'b0;
            end
        end
    end
end

endmodule

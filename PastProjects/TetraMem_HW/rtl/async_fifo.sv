//======================================================================
// async_fifo.sv  -  dual-clock (CDC) FIFO, Gray-pointer, FWFT read
//----------------------------------------------------------------------
// Classic Cummings-style asynchronous FIFO used to move data safely
// between the sub-system's sys_clk (bus) domain and the sr_clk
// (systolic-array) domain.
//
//   * write side : wclk / wr_en / wdata / full
//   * read  side : rclk / rd_en / rdata / empty
//   * FWFT       : rdata always shows the head word while !empty; a
//                  rd_en pulse pops it.
//   * DEPTH must be a power of two.
//
// A single active-low reset (wrst_n = rrst_n = rst_n at the top level)
// is used; each pointer is reset in its own clock's always block.
//======================================================================
module async_fifo #(
  parameter int WIDTH = 16,
  parameter int DEPTH = 16
)(
  // write domain
  input  logic             wclk,
  input  logic             wrst_n,
  input  logic             wr_en,
  input  logic [WIDTH-1:0] wdata,
  output logic             full,
  // read domain
  input  logic             rclk,
  input  logic             rrst_n,
  input  logic             rd_en,
  output logic [WIDTH-1:0] rdata,
  output logic             empty
);

  localparam int AW = (DEPTH > 1) ? $clog2(DEPTH) : 1;

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  logic [AW:0] wbin, wgray, wbin_nxt, wgray_nxt;
  logic [AW:0] rbin, rgray, rbin_nxt, rgray_nxt;
  logic [AW:0] wgray_s1, wgray_s2;   // write-gray synced into read domain
  logic [AW:0] rgray_s1, rgray_s2;   // read-gray  synced into write domain

  // ---------------- write pointer ----------------
  assign wbin_nxt  = wbin + (wr_en & ~full);
  assign wgray_nxt = (wbin_nxt >> 1) ^ wbin_nxt;

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin  <= '0;
      wgray <= '0;
    end else begin
      wbin  <= wbin_nxt;
      wgray <= wgray_nxt;
    end
  end

  always_ff @(posedge wclk) begin
    if (wr_en & ~full) mem[wbin[AW-1:0]] <= wdata;
  end

  // ---------------- read pointer ----------------
  assign rbin_nxt  = rbin + (rd_en & ~empty);
  assign rgray_nxt = (rbin_nxt >> 1) ^ rbin_nxt;

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin  <= '0;
      rgray <= '0;
    end else begin
      rbin  <= rbin_nxt;
      rgray <= rgray_nxt;
    end
  end

  assign rdata = mem[rbin[AW-1:0]];   // FWFT: head word is always visible

  // ---------------- pointer synchronizers ----------------
  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin wgray_s1 <= '0; wgray_s2 <= '0; end
    else         begin wgray_s1 <= wgray; wgray_s2 <= wgray_s1; end
  end

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin rgray_s1 <= '0; rgray_s2 <= '0; end
    else         begin rgray_s1 <= rgray; rgray_s2 <= rgray_s1; end
  end

  // ---------------- flags ----------------
  // 'empty' is combinational from two registered gray codes (no loop) so
  // FWFT read data is available the moment a word is present.
  assign empty = (rgray == wgray_s2);

  // 'full' must be REGISTERED: it feeds wbin_nxt, so a combinational full
  // would close the loop wbin_nxt -> wgray_nxt -> full -> wbin_nxt.  The
  // registered flag is the canonical (Cummings) form and cannot overflow.
  wire full_val = (wgray_nxt == {~rgray_s2[AW:AW-1], rgray_s2[AW-2:0]});
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) full <= 1'b0;
    else         full <= full_val;
  end

endmodule : async_fifo

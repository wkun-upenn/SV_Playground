//======================================================================
// pe.sv  -  Processing Element (basic MAC cell of the systolic array)
//----------------------------------------------------------------------
// A PE is the basic ALU unit described on page 3 of the assignment:
//
//   Data inputs :  a_in  - input activation (streams in from the LEFT)
//                  b_in  - weight preload value (stationary weight)
//                  c_in  - partial sum from the PE ABOVE
//   Data output :  a_out - forwarded activation (to the RIGHT)
//                  c_out - partial sum  cout = a*b + cin  (to the PE BELOW)
//
// Weight handling
// ---------------
// The weight is *stationary* (weight-stationary dataflow).  To hide the
// weight-load latency behind computation (page 10, "double buffered
// weight storage") every PE holds TWO weight registers:
//     w_load   - the inactive buffer, written while the array computes
//     w_active - the buffer actually used by the multiplier
// A single-cycle 'swap_w' pulse promotes the freshly loaded weights so a
// new B matrix takes effect without stalling the pipeline.
//
// All datapath outputs are registered so the mesh is a clean, fully
// pipelined 2-D array (one register hop per PE in each direction).
//======================================================================
module pe #(
  parameter int DIN_WIDTH = 8
)(
  input  logic                          clk,
  input  logic                          rst_n,   // active-low async reset
  // ---- datapath in ----
  input  logic signed [DIN_WIDTH-1:0]   a_in,    // activation from the left
  input  logic signed [DIN_WIDTH-1:0]   b_in,    // weight value to preload
  input  logic signed [2*DIN_WIDTH-1:0] c_in,    // partial sum from above
  // ---- control ----
  input  logic                          ld_w,    // latch b_in -> inactive weight buffer
  input  logic                          swap_w,  // promote inactive buffer to active
  input  logic                          en,      // advance datapath (compute step)
  // ---- datapath out ----
  output logic signed [DIN_WIDTH-1:0]   a_out,   // activation to the right
  output logic signed [2*DIN_WIDTH-1:0] c_out    // partial sum to the PE below
);

  logic signed [DIN_WIDTH-1:0] w_active;
  logic signed [DIN_WIDTH-1:0] w_load;

  // -------- double-buffered stationary weight --------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_load   <= '0;
      w_active <= '0;
    end else begin
      if (ld_w)   w_load   <= b_in;      // preload next weight
      if (swap_w) w_active <= w_load;    // activate it
    end
  end

  // -------- registered MAC datapath --------
  // a is forwarded one PE to the right; the partial sum a*b+cin is
  // forwarded one PE downward.  Both advance only when 'en' is high so
  // the surrounding controller can freeze the array between frames.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_out <= '0;
      c_out <= '0;
    end else if (en) begin
      a_out <= a_in;
      c_out <= c_in + (a_in * w_active);
    end
  end

endmodule : pe

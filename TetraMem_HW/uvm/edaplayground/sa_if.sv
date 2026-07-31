
// sa_if.sv

`timescale 1ns/1ps
interface sa_if #(parameter int DIN_WIDTH = 8, parameter int N = 4) (input logic clk);
  localparam int ACC_W = 2*DIN_WIDTH;

  logic                    rst_n;
  logic [N*ACC_W-1:0]      c_din;      // N seeds  (element j at j*ACC_W)
  logic [N*DIN_WIDTH-1:0]  a_din;      // A column (element i at i*DIN_WIDTH)
  logic [N*DIN_WIDTH-1:0]  b_din;      // B row    (element j at j*DIN_WIDTH)
  logic                    in_valid;
  logic [N*ACC_W-1:0]      c_dout;     // one C row (element j at j*ACC_W)
  logic                    out_valid;

  clocking drv @(posedge clk);
    default input #1step output #1;
    output c_din, a_din, b_din, in_valid;
    input  c_dout, out_valid;
  endclocking

  clocking mon @(posedge clk);
    default input #1step;
    input c_din, a_din, b_din, in_valid, c_dout, out_valid;
  endclocking

  // Initialize the driven pins to idle, THROUGH the clocking block so the
  // driver remains the single driver of these pins.
  task automatic init_drv();
    @(drv);
    drv.in_valid <= 1'b0;
    drv.a_din    <= '0;
    drv.b_din    <= '0;
    drv.c_din    <= '0;
  endtask
endinterface : sa_if

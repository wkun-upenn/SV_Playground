`timescale 1ns/1ps
interface ss_if #(parameter int DIN_WIDTH = 8, parameter int N = 4,
                  parameter int BUS_WIDTH = 2*DIN_WIDTH*N)
                 (input logic sys_clk, input logic sr_clk);
  logic                    rst_n;
  logic [7:0]              M_minus_one;
  logic [BUS_WIDTH-1:0]    din;
  logic                    wr_fifo;
  logic                    rd_fifo;
  logic                    in_fifo_full;
  logic [BUS_WIDTH-1:0]    dout;
  logic                    out_fifo_empty;

  clocking wr @(posedge sys_clk);            // input / write channel
    default input #1step output #1;
    output din, wr_fifo, M_minus_one;
    input  in_fifo_full;
  endclocking

  clocking rd @(posedge sys_clk);            // output / read channel
    default input #1step output #1;
    output rd_fifo;
    input  dout, out_fifo_empty;
  endclocking

  clocking mon @(posedge sys_clk);           // passive observation
    default input #1step;
    input din, wr_fifo, M_minus_one, in_fifo_full, rd_fifo, dout, out_fifo_empty;
  endclocking

  // Initialize the driven pins (single-driver via clocking blocks).
  task automatic init_drv();
    @(wr);
    wr.wr_fifo     <= 1'b0;
    wr.din         <= '0;
    wr.M_minus_one <= 8'(N-1);
    rd.rd_fifo     <= 1'b0;
  endtask
endinterface : ss_if

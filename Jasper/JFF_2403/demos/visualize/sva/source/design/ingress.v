//---------------------------------------------------------------------------//
//                                                                           //
//  Module:  ingress                                                         //
//                                                                           //
//  Version: 13 July 2006                                                    //
//---------------------------------------------------------------------------//

//*****************************************************************************
//
// Any disclosure about the Jasper Design Automation software or its use
// model to any third party violates the written Non-Disclosure Agreement
// between Jasper Design Automation and the customer.
//
// THIS SOFTWARE CONTAINS CONFIDENTIAL INFORMATION AND TRADE SECRETS OF
// JASPER DESIGN AUTOMATION, INC. USE, DISCLOSURE, OR REPRODUCTION IS
// PROHIBITED WITHOUT THE PRIOR EXPRESS WRITTEN PERMISSION OF JASPER
// DESIGN AUTOMATION, INC.
//
// Copyright (C) 2000-2006 Jasper Design Automation, Inc. All Rights
// Reserved.  Unpublished -- rights reserved under the copyright laws of
// the United States.
//
// The JasperGold Verification System incorporates software developed by
// others and redistributed according to license agreement. See
// doc/third_party_readme.txt for further details.
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure by the Government is subject to
// restrictions as set forth in subparagraph (c) (1) (ii) of the Rights in
// Technical Data and Computer Software clause at DFARS 252.227-7013 or
// subparagraphs (c) (1) and (2) of Commercial Computer Software -- Restricted
// Rights at 48 CFR 52.227-19, as applicable.
//
//
//                        Jasper Design Automation, Inc.
//                        100 View Street, Suite 101
//                        Mountain View, CA 94041
//
// For technical assistance please send email to support@jasper-da.com.
//
// For more information on the Jasper Design Automation product offering
// send email to info@jasper-da.com.
//
//*****************************************************************************

module ingress (
  clk, rstN,
  rd_ready, addr, valid, ready, wr_rd, rdata, wdata, size,
  int_size, int2ig_data, int_addr_data,  new_tran, int_read_done,
  current_read_write, int_read_write, int_ready, int_valid,
  trans_started
);

input clk, rstN;

// Ingress Interface
input rd_ready;
input wr_rd;
input valid;
input [1:0] size;
input [6:0] addr;
input [31:0] wdata;

output ready;
output [31:0] rdata;

// Internal interface
// Bridge is ready to receive data
input int_ready;
input [31:0] int2ig_data;
input new_tran;
input int_read_done;
output int_read_write;
output int_valid;
output trans_started;
output current_read_write;
// The size of the transfer
output [1:0] int_size;

// The information to be sent to internal bridge includes
// 7 bits of address, 32 bits of data and 2 bits of size
output [38:0] int_addr_data;


reg int_read_write;
// The current transaction has started
reg trans_started;
reg wr_rd_reg;
wire current_read_write = ~wr_rd_reg;

always @(posedge clk or negedge rstN)
if (!rstN) wr_rd_reg <= 1'b1;
else if (valid && ready) wr_rd_reg <= wr_rd;

reg valid_read;

always @(posedge clk or negedge rstN)
if (!rstN) valid_read <= 1'b1;
else if (valid && ~wr_rd)
              valid_read <= 1'b0;
else if (int_read_done)
              valid_read <= 1'b1; 

wire ready = wr_rd_reg?int_ready:valid_read;

reg [6:0] int_addr;
reg [1:0] int_size;
reg [31:0] wdata_reorder;

always @(posedge clk)
if (size==2'b0) begin
        wdata_reorder[31:8] <= 24'b0;
        case (addr[1:0])
        2'b00: begin
                  wdata_reorder[7:0] <= wdata[7:0];
               end
        2'b01: begin
                  wdata_reorder[7:0] <= wdata[15:8];
               end
        2'b10: begin
                  wdata_reorder[7:0] <= wdata[23:16];
               end
        2'b11: begin
                  wdata_reorder[7:0] <= wdata[31:24];
               end
        endcase
end
else if (size==2'b1) begin
        wdata_reorder[31:16] <= 16'b0;
        case (addr[1:0])
        2'b00: begin
                  wdata_reorder[15:0] <= wdata[15:0];
               end
        2'b01: begin
                  wdata_reorder[15:0] <= wdata[23:8];
               end
        2'b10: begin
                  wdata_reorder[15:0] <= wdata[31:16];
               end
        default: wdata_reorder <= wdata;
        endcase
end
else wdata_reorder <= wdata;
              
wire [38:0] int_addr_data = {int_addr, wdata_reorder};
reg int_valid;

always @(posedge clk or negedge rstN) begin
if (!rstN) 
         trans_started <= 1'b0;
else if (new_tran)
         trans_started <= 1'b1;
else if (~valid)
         trans_started <= 1'b0;
end


always @(posedge clk or negedge rstN)
if (!rstN) begin
          int_read_write <= 1'b0;
end
else if (new_tran && trans_started && ~wr_rd_reg && rd_ready)
          int_read_write <= 1'b1;
else if (ready && trans_started) int_read_write <= 1'b0;

always @(posedge clk or negedge rstN)
if (!rstN) begin
          int_addr <= 7'd0;
          int_valid <= 1'b0;
          int_size <= 2'b0;
end
else if (valid&&ready)
  begin
          int_addr <= addr;
          int_valid <= 1'b1;
          if      (size[1:0]==2'b00) int_size <= 2'b01;
          else if (size[1:0]==2'b01) int_size <= 2'b10;
          else if (size[1:0]==2'b10) int_size <= 2'b00;
  end
else      int_valid <= 1'b0;

wire [31:0] rdata = int2ig_data;

endmodule // ingress

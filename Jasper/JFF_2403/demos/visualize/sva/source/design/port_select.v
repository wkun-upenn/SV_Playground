//---------------------------------------------------------------------------//
//                                                                           //
//  Module:  port_select                                                     //
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

module port_select (
  clk,
  ig_sel,
  // Ingress side
  int_read_write0, int_read_write1, int_read_write2, int_read_write3,
  int_valid0, int_valid1, int_valid2, int_valid3,
  trans_started0, trans_started1, trans_started2, trans_started3,
  current_read_write0, current_read_write1,
  current_read_write2, current_read_write3,
  int_size0, int_size1, int_size2, int_size3,
  int_addr_data0, int_addr_data1, int_addr_data2, int_addr_data3,
  int_ready0, int_ready1, int_ready2, int_ready3,
  new_tran0, new_tran1, new_tran2, new_tran3,
  int2ig_data0, int2ig_data1, int2ig_data2, int2ig_data3,
  int_read_done0, int_read_done1, int_read_done2, int_read_done3,
  // Egress side
  int_read_write,
  int_valid,
  trans_started,
  current_read_write,
  int_size,
  int_addr_data,
  int_ready,
  new_tran,
  int2ig_data,
  int_read_done
);

input clk;

// Port selector from arbiter
input  [1:0] ig_sel;

// Ingress side
input  int_read_write0, int_read_write1, int_read_write2, int_read_write3;
input  int_valid0, int_valid1, int_valid2, int_valid3;
input  trans_started0, trans_started1, trans_started2, trans_started3;
input  current_read_write0, current_read_write1,
       current_read_write2, current_read_write3;
input  [1:0] int_size0, int_size1, int_size2, int_size3;
input [38:0]  int_addr_data0, int_addr_data1, int_addr_data2, int_addr_data3;
output int_ready0, int_ready1, int_ready2, int_ready3;
output new_tran0, new_tran1, new_tran2, new_tran3;
output [31:0] int2ig_data0, int2ig_data1, int2ig_data2, int2ig_data3;
output int_read_done0, int_read_done1, int_read_done2, int_read_done3;

// Egress side
output int_read_write;
output int_valid;
output trans_started;
output current_read_write;
output [1:0] int_size;
output [38:0] int_addr_data;
input  int_ready;
input  new_tran;
input  [31:0] int2ig_data;
input  int_read_done;


assign int_ready0 = (ig_sel==2'b00)? int_ready:1'b0;
assign int_ready1 = (ig_sel==2'b01)? int_ready:1'b0;
assign int_ready2 = (ig_sel==2'b10)? int_ready:1'b0;
assign int_ready3 = (ig_sel==2'b11)? int_ready:1'b0;

assign int2ig_data0 = int2ig_data;
assign int2ig_data1 = int2ig_data;
assign int2ig_data2 = int2ig_data;
assign int2ig_data3 = int2ig_data;

assign new_tran0 = (ig_sel==2'b00)? new_tran:1'b0;
assign new_tran1 = (ig_sel==2'b01)? new_tran:1'b0;
assign new_tran2 = (ig_sel==2'b10)? new_tran:1'b0;
assign new_tran3 = (ig_sel==2'b11)? new_tran:1'b0;

assign int_read_done0 = (ig_sel==2'b00)? int_read_done:1'b0;
assign int_read_done1 = (ig_sel==2'b01)? int_read_done:1'b0;
assign int_read_done2 = (ig_sel==2'b10)? int_read_done:1'b0;
assign int_read_done3 = (ig_sel==2'b11)? int_read_done:1'b0;

assign int_size = (ig_sel==2'b00)? int_size0:
                  (ig_sel==2'b01)? int_size1:
                  (ig_sel==2'b10)? int_size2:
                                   int_size3;

assign int_read_write = (ig_sel==2'b00)? int_read_write0:
                        (ig_sel==2'b01)? int_read_write1:
                        (ig_sel==2'b10)? int_read_write2:
                                         int_read_write3;

assign int_valid = (ig_sel==2'b00)? int_valid0:
                   (ig_sel==2'b01)? int_valid1:
                   (ig_sel==2'b10)? int_valid2:
                                    int_valid3;

assign trans_started = (ig_sel==2'b00)? trans_started0:
                       (ig_sel==2'b01)? trans_started1:
                       (ig_sel==2'b10)? trans_started2:
                                        trans_started3;

assign current_read_write = (ig_sel==2'b00)? current_read_write0:
                            (ig_sel==2'b01)? current_read_write1:
                            (ig_sel==2'b10)? current_read_write2:
                                             current_read_write3;

assign int_addr_data = (ig_sel==2'b00)? int_addr_data0:
                       (ig_sel==2'b01)? int_addr_data1:
                       (ig_sel==2'b10)? int_addr_data2:
                                        int_addr_data3;

endmodule // port_select

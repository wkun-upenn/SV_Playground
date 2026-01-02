// © 2018 Cadence Design Systems, Inc. All rights reserved worldwide.
// 
// ----------------------------------------
// 
// This file is being provided as part of a reference example to showcase
// Cadence's JasperGold Formal IP Signoff methodology. They are the proprietary
// and confidential information of Cadence or its licensors, and are supplied
// subject to, and may be used only by Cadence's customer in accordance with a
// previously executed agreements between Cadence and that customer.
// 
// Further, they may only be used with JasperGold and cannot be used with any
// other Formal Verification Tools.
// 
// ALL MATERIALS FURNISHED BY CADENCE HEREUNDER ARE PROVIDED "AS IS" WITHOUT
// WARRANTY OF ANY KIND, AND CADENCE SPECIFICALLY DISCLAIMS ANY WARRANTY OF
// NONINFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE OR MERCHANTABILITY.
// CADENCE SHALL NOT BE LIABLE FOR ANY COSTS OF PROCUREMENT OF SUBSTITUTES,
// LOSS OF PROFITS, INTERRUPTION OF BUSINESS, OR FOR ANY OTHER SPECIAL,
// CONSEQUENTIAL OR INCIDENTAL DAMAGES, HOWEVER CAUSED, WHETHER FOR BREACH OF
// WARRANTY, CONTRACT, TORT, NEGLIGENCE, STRICT LIABILITY OR OTHERWISE.
// 
// ----------------------------------------

package fv_pkg;

  typedef enum { AUTO, CHECKSUM, HEADER, LIST_LEVEL, THR_LEVEL, INIT, CG_ENABLE, INTR_MASK, INTR_CLEAR, INTR_STATUS, INTR_THR_NUM, LIST_AVAIL, INVALID} apb_addr_t;

  typedef enum bit [1:0] { M_NORMAL, M_ASSIGN, M_DROP } mode_t;
  typedef enum bit [1:0] { H_1, H_2, H_3, H_4 } header_t;
  typedef enum bit [1:0] { U_ALL, U_ALLM1, U_OTHER } use_t;
  typedef enum bit [1:0] { A_MIN, A_LOW, A_MID, A_MAX } avail_t;
  typedef enum bit [2:0] { L_MIN, /*L_MINP1,*/ L_MID, /*L_MAXM1,*/ L_MAX } len_t;
  typedef enum bit [1:0] { D_DROP=2'b00, D_EMPTY_THR=2'b01, D_USED_THR=2'b11 } dec_t;
  typedef enum bit [1:0] { G_FIRST, G_0, G_1, G_N } gap_t;
  typedef enum bit       { S_SINGLE, S_MULTI } source_t;
  typedef enum bit [1:0] { C_NONE=2'b01, C_FAIL=2'b10, C_OK=2'b11 } checksum_t; //[0]=no_error [1]=has_crc
  typedef enum bit [1:0] { TP_LOW, TP_MID, TP_HIGH } total_pkts_t;
  typedef enum bit [1:0] { PP_LOW, PP_MID, PP_HIGH } pend_pkts_t;
  typedef enum bit [1:0] { UT_0, UT_1, UT_MID, UT_ALL } used_thrs_t;
  typedef enum bit [2:0] { TW_0, /*TW_1,*/ TW_MID, /*TW_MAXM1,*/ TW_MAX } total_words_t;

  parameter TAG_DROP_BIT = 0;
  parameter TAG_CHECKSUM_BIT = 1;
  parameter TAG_THR_BIT = 2;

endpackage

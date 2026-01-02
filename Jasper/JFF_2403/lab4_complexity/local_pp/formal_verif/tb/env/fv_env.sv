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

`include "fv_defines.svh"
`include "pp.vh"

module fv_env #(`FV_PARAM_DECL) (
  input bit clk, rstn,

  input bit ig_valid,
  input bit ig_sop, ig_eop,
  input bit [DATA_W-1:0] ig_data,
  input bit [PTR_W:0] ig_avail,

  input bit eg_assign,
  input bit [THR_W-1:0] eg_assign_thr,
  input bit eg_req,
  input bit [THR_W-1:0] eg_req_thr,
  input bit eg_valid,
  input bit [DATA_W-1:0] eg_data,
  input bit eg_sop, eg_eop,

  input bit route_req_valid,
  input bit [3:0] route_req_header_valid,
  input bit [4*DATA_W-1:0] route_req_header,
  input bit route_resp_valid,
  input bit route_resp_drop,
  input bit [THR_W-1:0] route_resp_thr,

  input bit PCLK, PRESETn,
  input bit [15:0] PADDR,
  input bit PSEL,
  input bit PENABLE,
  input bit PWRITE,
  input bit [31:0] PWDATA,
  input bit PREADY,
  input bit [31:0] PRDATA,
  input bit PSLVERR,

  input bit intr
);

  bit fv_rst;  

  /*****************************************************************************
  ** DUT signal monitors
  **
  ** Purpose:
  ** Facilitate monitoring of DUT ports and probing of DUT internal signals
  **
  *****************************************************************************/
  
  // DUT Ports
  ig_port_intf #(`FV_PARAM) ig_port ();
  route_port_intf #(`FV_PARAM) route_port ();
  eg_port_intf #(`FV_PARAM) eg_port ();
  apb_port_intf #(`FV_PARAM) apb_port ();
  intr_port_intf #(`FV_PARAM) intr_port ();

  // DUT probes
  fl_probe_intf #(`FV_PARAM) fl_probe ();
  cfg_probe_intf #(`FV_PARAM) cfg_probe ();


  /*****************************************************************************
  ** Testbench communication
  **
  ** Purpose:
  ** Enable testbench components to transfer transaction level notifications
  ** and also gather usefulstats about DUT activity via trackers
  **
  *****************************************************************************/

  // Transactions
  payload_txn_intf #(`FV_PARAM) ig_payload_txn ();
  payload_txn_intf #(`FV_PARAM) eg_payload_txn ();
  header_txn_intf #(`FV_PARAM) ig_header_txn ();
  header_txn_intf #(`FV_PARAM) route_header_txn ();
  packet_txn_intf #(`FV_PARAM) ig_packet_txn ();
  packet_txn_intf #(`FV_PARAM) eg_packet_txn ();
  resp_txn_intf #(`FV_PARAM) resp_txn ();
  apb_txn_intf #(`FV_PARAM) apb_txn ();
  intr_txn_intf #(`FV_PARAM) intr_txn ();

  // Trackers
  level_trk_intf #(`FV_PARAM) level_trk ();


  /*****************************************************************************
  ** DUT Signal Level Adapter
  **
  ** Purpose:
  ** Connect DUT ports and internal signals to _port and _probe interfaces.
  **
  *****************************************************************************/
  
  fv_adapter #(`FV_PARAM) fv_adapter (.*);


  /*****************************************************************************
  ** DUT Interface Agents
  **
  ** Purpose:
  ** One agent for each physical DUT interface.
  ** Perform local checking and coverage collection e.g. protocol checks
  ** Translate signal level activity in _port interfaces into transaction level
  ** events which are passed between testbench components using the _txn interfaces
  **
  *****************************************************************************/

  ig_agent #(`FV_PARAM) ig_agent (
    .clk, .rstn,
    .ig_port,
    .ig_header_txn,
    .ig_payload_txn,
    .ig_packet_txn,
    .cfg_probe
  );
  route_agent #(`FV_PARAM) route_agent (
    .clk, .rstn,
    .route_port,
    .route_header_txn,
    .resp_txn,
    .cfg_probe
  );
  eg_agent #(`FV_PARAM) eg_agent (
    .clk, .rstn,
    .eg_port,
    .eg_payload_txn,
    .eg_packet_txn,
    .cfg_probe
  );

  apb_agent #(`FV_PARAM) apb_agent (
    .clk, .rstn,
    .PCLK, .PRESETn,
    .apb_port,
    .apb_txn
  );
  intr_agent #(`FV_PARAM) intr_agent (
    .clk, .rstn,
    .intr_port,
    .intr_txn,
    .ig_packet_txn,
    .route_port,
    .level_trk,
    .fl_probe,
    .cfg_probe,
    .apb_txn
  );



  /*****************************************************************************
  ** Checkers
  **
  ** Purpose:
  ** Perform white-box verification of internal DUT functionality and collect
  ** related functional coverage
  **
   *****************************************************************************/

  fl_chk #(`FV_PARAM) fl_chk (
    .clk, .rstn,
    .fl_probe
  );
  init_chk #(`FV_PARAM) init_chk (
    .clk, .rstn,
    .ig_port,
    .cfg_probe
  );
  cfg_chk #(`FV_PARAM) cfg_chk (
    .clk, .rstn,
    .apb_txn,
    .level_trk,
    .cfg_probe
  );  
  level_chk #(`FV_PARAM) level_chk (
    .clk, .rstn,
    .ig_packet_txn,
    .eg_packet_txn,
    .eg_port,
    .route_port,
    .resp_txn,
    .fl_probe,
    .level_trk,
    .cfg_probe
  );  
  
  
  /*****************************************************************************
  ** Scoreboards
  **
  ** Purpose:
  ** Perform end-to-end verification of high level DUT functionality and 
  ** collect related functional coverage
  **
  *****************************************************************************/
 

  ig_route_sb #(`FV_PARAM) ig_route_sb (
    .clk, .rstn,
    .ig_header_txn,
    .route_header_txn,
    .cfg_probe
  );
  ig_eg_sb #(`FV_PARAM) ig_eg_sb (
    .clk, .rstn,
    .ig_payload_txn,
    .eg_payload_txn,
    .cfg_probe
  );


  /*****************************************************************************
  ** Coverage
  **
  ** Purpose:
  ** Collect high level DUT functional coverage not collected via scoreboards
  **
  *****************************************************************************/

  covers #(`FV_PARAM) covers (
    .clk, .rstn,
    .ig_port, .ig_packet_txn,
    .eg_port, .eg_packet_txn,
    .route_port, .resp_txn,
    .intr_txn,
    .fl_probe,
    .level_trk,
    .cfg_probe
  );

  /*****************************************************************************
  ** Abstractions
  **
  ** Purpose:
  ** Implement formal modeling abstractions, 
  **
  *****************************************************************************/
  
  tag_abs #(`FV_PARAM) tag_abs (
    .clk, .rstn,
    .ig_port,
    .route_port,
    .cfg_probe
  );

endmodule








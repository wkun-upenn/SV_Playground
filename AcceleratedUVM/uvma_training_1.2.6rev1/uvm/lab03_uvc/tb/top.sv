/*-----------------------------------------------------------------
File name     : top.sv
Description   : lab01_data top module template file
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

module top;
// import the UVM library
    import uvm_pkg::*;
// include the UVM macros
    `include "uvm_macros.svh"

// import the YAPP package
    import yapp_pkg::*;
    `include "router_tb.sv"
    `include "router_test_lib.sv"
    
// generate 5 random packets and use the print method
// to display the results
    yapp_packet packet;
    int ok;

// ---------------------Lab 1: Add code to generate and print 5 random packets-----------------
    // initial begin
    //     for (int i = 0; i < 5; i++) begin
    //         // allocate each packet
    //         packet = new($sformatf("packet%0d", i));
    //         ok = packet.randomize();
    //         if (ok == 0) begin
    //             $error("Failed to randomize packet %0d", i);
    //         end
    //         packet.print();
    //     end
    // end


// Lab 2: Add code to experiment with the copy, clone and compare UVM method
    initial begin
        run_test();
    end
// experiment with the copy, clone and compare UVM method
endmodule : top

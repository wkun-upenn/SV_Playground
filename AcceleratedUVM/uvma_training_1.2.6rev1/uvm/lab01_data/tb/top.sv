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
// generate 5 random packets and use the print method
// to display the results
    yapp_packet packet;
    int ok;

    initial begin
        for (int i = 0; i < 5; i++) begin
            // allocate each packet
            packet = new($sformatf("packet%0d", i));
            ok = packet.randomize();
            if (ok == 0) begin
                $error("Failed to randomize packet %0d", i);
            end
            packet.print();
        end
    end

// experiment with the copy, clone and compare UVM method
endmodule : top

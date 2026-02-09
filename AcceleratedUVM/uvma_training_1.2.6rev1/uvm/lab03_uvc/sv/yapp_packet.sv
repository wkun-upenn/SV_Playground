/*-----------------------------------------------------------------
File name     : yapp_packet.sv
Description   : lab01_data YAPP UVC packet template file
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// Define your enumerated type(s) here
typedef enum bit {BAD_PARITY, GOOD_PARITY} parity_type_e;
class yapp_packet extends uvm_sequence_item;
  rand bit [5:0]  length;
  rand bit [1:0]  addr;
  rand bit [7:0]  payload[];
       bit [7:0]  parity;

// Follow the lab instructions to create the packet.
// Place the packet declarations in the following order:
  function new(string name = "yapp_packet");
    super.new(name);
  endfunction

  // Define protocol data

  // Define control knobs
  rand int packet_delay;
  rand parity_type_e packet_type;

  // Enable automation of the packet's fields
  `uvm_object_utils_begin(yapp_packet)  // argument should be class name
    `uvm_field_int(length, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_array_int(payload, UVM_ALL_ON)
    `uvm_field_int(parity, UVM_ALL_ON + UVM_BIN) // print radix flag
    /* 
      Comparison is normally done in a scoreboard and packet_delay is information for the YAPP UVC driver only.
      We cannot recalculate the delay at the outputs, so we don't want to use this field for scoreboard comparison.
    */
    `uvm_field_int(packet_delay, UVM_ALL_ON + UVM_NOCOMPARE)
  `uvm_field_enum(parity_type_e, packet_type, UVM_ALL_ON)
  `uvm_object_utils_end

  // Define packet constraints
  constraint payload_size {length == payload.size();}
  constraint payload_length {length inside {[1: 64]};}
  constraint pkt_delay {packet_delay inside {[1: 20]};}
  constraint illegal_addr {addr != 2'b11;}
  constraint parity_prob {packet_type dist {GOOD_PARITY := 5, BAD_PARITY := 1};}

  // Add methods for parity calculation and class construction
  function void post_randomize();
    set_party();
  endfunction: post_randomize

  function bit [7:0] calc_parity();
    bit [7:0] parity_sum = 8'h00;
    foreach(payload[i]) begin
      parity_sum ^= payload[i];
    end
    return parity_sum;
  endfunction: calc_parity

  function void set_party();
    if (packet_type == GOOD_PARITY) begin;
      parity = calc_parity();
    end else begin
      parity = ~calc_parity();
    end
  endfunction

endclass: yapp_packet

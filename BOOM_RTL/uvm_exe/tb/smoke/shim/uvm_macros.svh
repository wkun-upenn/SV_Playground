// shim macros for the Verilator smoke build (see uvm_pkg.sv in this directory)
`ifndef UVM_MACROS_SVH
`define UVM_MACROS_SVH
`define uvm_object_utils(T)
`define uvm_object_param_utils(T)
`define uvm_component_utils(T)
`define uvm_component_param_utils(T)
`define uvm_info(ID, MSG, V)  begin if ((V) <= uvm_pkg::uvm_shim_verbosity) $display("UVM_INFO [%s] %s", ID, MSG); end
`define uvm_warning(ID, MSG)  begin $display("UVM_WARNING [%s] %s", ID, MSG); end
`define uvm_error(ID, MSG)    begin uvm_pkg::uvm_shim_errors++; $display("UVM_ERROR [%s] %s", ID, MSG); end
`define uvm_fatal(ID, MSG)    begin $display("UVM_FATAL [%s] %s", ID, MSG); $finish; end
`endif

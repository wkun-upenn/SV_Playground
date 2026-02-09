class yapp_tx_monitor extends uvm_monitor;
    `uvm_component_utils(yapp_tx_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            `uvm_info(get_type_name(), $sformatf("We are inside monitor"), UVM_LOW)
        end
    endtask : run_phase
endclass : yapp_tx_monitor
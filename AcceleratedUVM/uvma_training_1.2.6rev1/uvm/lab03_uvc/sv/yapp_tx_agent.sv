class yapp_tx_agent extends uvm_agent;
    `uvm_component_utils(yapp_tx_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    yapp_tx_monitor monitor = new();
    yapp_tx_sequencer sequencer = new();
    yapp_tx_driver driver = new();


endclass: yapp_tx_agent
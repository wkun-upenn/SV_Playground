class yapp_tx_agent extends uvm_agent;
    `uvm_component_utils(yapp_tx_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    yapp_tx_monitor monitor = new();
    yapp_tx_sequencer sequencer = new();
    yapp_tx_driver driver = new();

    `uvm_active_passive_enum is_active = UVM_ACTIVE

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = yapp_tx_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            sequencer = yapp_tx_sequencer::type_id::create("sequencer", this);
            driver = yapp_tx_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase)
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction


endclass: yapp_tx_agent
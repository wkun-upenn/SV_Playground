// ============================================================
//  UVM Environment & Agent Template
// ============================================================


// ============================================================
//  my_env
// ============================================================
class my_env extends uvm_env;

    my_agent                        agent;
    my_vsequencer                   vsequencer;
    my_rgm                          rgm;
    my_adapter                      adapter;
    my_predictor#(my_transaction)   predictor;

    `uvm_component_utils(my_env)

    function void build_phase(uvm_phase phase);
        agent      = my_agent::type_id::create("agent", this);
        vsequencer = my_vsequencer::type_id::create("vsequencer", this);
        rgm        = my_rgm::type_id::create("rgm");
        rgm.build();
        rgm.lock_model();
        adapter    = my_adapter::type_id::create("adapter", this);
        predictor  = my_predictor#(my_transaction)::type_id::create("predictor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.tlm_analysis_port.connect(checker.tlm_analysis_export);
        vsequencer.sequencer = agent.sequencer;
        rgm.map.set_sequencer(agent.sequencer, adapter);
        predictor.map     = rgm.map;
        predictor.adapter = adapter;
    endfunction

endclass


// ============================================================
//  my_agent
// ============================================================
class my_agent extends uvm_agent;

    my_driver       driver;
    my_monitor      monitor;
    my_sequencer    sequencer;
    my_scoreboard   scoreboard;
    virtual my_interface v_if;

    `uvm_component_utils(my_agent)

    function void build_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = my_driver::type_id::create("driver", this);
            sequencer = my_sequencer::type_id::create("sequencer", this);
        end
        monitor    = my_monitor::type_id::create("monitor", this);
        scoreboard = my_scoreboard::type_id::create("scoreboard", this);

        if (!uvm_config_db#(virtual my_interface)::get(this, "", "v_if", v_if)) begin
            `uvm_fatal(get_full_name(), "cannot get the virtual interface from top level")
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            driver.v_if = v_if;
        end
        monitor.v_if = v_if;
        monitor.tlm_analysis_port.connect(scoreboard.tlm_analysis_export);
    endfunction

endclass


// ============================================================
//  my_driver
// ============================================================
class my_driver extends uvm_driver#(my_transaction);

    virtual my_interface v_if;

    `uvm_component_utils(my_driver)

    task run_phase(uvm_phase phase);
        fork
            process_trans();
            monitor_reset();
        join
    endtask

    task monitor_reset();
        forever begin
            @(negedge v_if.reset);
            v_if.drive_cb.data <= 8'd0;
        end
    endtask

    task process_trans();
        my_transaction req, rsp;
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            void'($cast(rsp, req.clone()));
            rsp.set_sequence_id(req.get_sequence_id());
            seq_item_port.item_done(rsp);
        end
    endtask

    task drive_item(my_transaction trans);
        case (trans.kind)
            0: read_item(trans);
            1: write_item(trans);
        endcase
    endtask

    task read_item(my_transaction trans);
        @(v_if.drive_mp.drive_cb);
        trans.data = v_if.mon_cb.data;
    endtask

    task write_item(my_transaction trans);
        @(v_if.drive_mp.drive_cb);
        v_if.drive_cb.data <= trans.data;
    endtask

endclass


// ============================================================
//  my_transaction
// ============================================================
class my_transaction extends uvm_sequence_item;

    rand int data;
    rand int address;
    rand bit kind;

    `uvm_object_utils_begin(my_transaction)
        `uvm_field_int(data,    UVM_ALL_ON)
        `uvm_field_int(address, UVM_ALL_ON)
        `uvm_field_int(kind,    UVM_ALL_ON)
    `uvm_object_utils_end

    constraint cstr {
        data    >= 100;
        address <= 100;
    }

endclass

// Usage notes:
//   To disable constraint:    my_trans.cstr.constraint_mode(0);
//   To disable randomization: my_trans.rand_mode(0);


// ============================================================
//  my_sequence
// ============================================================
class my_sequence extends uvm_sequence#(my_transaction);

    `uvm_object_utils(my_sequence)

    int count;

    task body();
        my_transaction req, rsp;
        void'(std::randomize(count) with { count >= 100; });
        repeat (count) begin
            req = my_transaction::type_id::create("my_trans");
            start_item(req);
            req.randomize();
            finish_item(req);
            get_response(rsp);
        end
    endtask

endclass


// ============================================================
//  my_sequencer
// ============================================================
class my_sequencer extends uvm_sequencer#(my_transaction);

    `uvm_component_utils(my_sequencer)

    function new(string name = "my_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass


// ============================================================
//  my_monitor
// ============================================================
class my_monitor extends uvm_monitor;

    `uvm_component_utils(my_monitor)

    virtual my_interface     v_if;
    uvm_analysis_port#(my_transaction) mon_analysis_port;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_analysis_port = new("mon_analysis_port", this);
        if (!uvm_config_db#(virtual my_interface)::get(this, "", "v_if", v_if)) begin
            `uvm_fatal(get_full_name(), "cannot get the virtual interface from top level")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_transactions();
        join_none
    endtask

    task monitor_transactions();
        my_transaction trans;
        forever begin
            @(posedge v_if.mon_cb.valid);
            trans = my_transaction::type_id::create("my_trans");
            trans.data = v_if.mon_cb.data;
            mon_analysis_port.write(trans);
        end
    endtask

endclass


// ============================================================
//  my_scoreboard
// ============================================================
class my_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(my_scoreboard)

    uvm_tlm_analysis_fifo#(my_transaction) real_input_fifo;
    uvm_tlm_analysis_fifo#(my_transaction) ref_input_fifo;
    uvm_get_port#(my_transaction)          ref_output_port;

    int count;

    function void connect_phase(uvm_phase phase);
        real_input_fifo.analysis_export.connect(reference.data_in_export);
        ref_output_port.connect(reference.data_out_export);
    endfunction

    task run_phase(uvm_phase phase);
        my_transaction trans1, trans2;
        forever begin
            real_input_fifo.get(trans1);
            ref_output_port.get(trans2);
            if (trans1.data == trans2.data)
                count += 1;
        end
    endtask

endclass


// ============================================================
//  my_interface
// ============================================================
interface my_interface (input clk, input reset);

    logic [7:0] data;
    logic        valid;

    clocking drive_cb @(posedge clk);
        default input #1ns output #10ns;
        output data;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1ns;
        input data;
        input valid;
        input reset;
    endclocking

    modport drive_mp (clocking drive_cb, input reset);
    modport mon_mp   (clocking mon_cb,   input reset);

endinterface


// ============================================================
//  my_adapter
// ============================================================
class my_adapter extends uvm_reg_adapter;

    `uvm_object_utils(my_adapter)

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        my_transaction t = my_transaction::type_id::create("t");
        t.kind = (rw.kind == UVM_WRITE) ? 1 : 0;
        t.data = rw.data;
        return t;
    endfunction

    function void bus2reg(uvm_sequence_item bus_op, ref uvm_reg_bus_op rw);
        my_transaction t;
        void'($cast(t, bus_op));
        rw.kind = (t.kind == 1) ? UVM_WRITE : UVM_READ;
        rw.data = t.data;
    endfunction

endclass


// ============================================================
//  Odd Clock Divider
// ============================================================
module odd_divider #(parameter N = 3) (
    input  logic i_clk,
    input  logic i_reset,
    output logic o_clk
);

    logic [$clog2(N-1):0] counter;

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset || counter == N-1)
            counter <= '0;
        else
            counter <= counter + 1;
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            o_clk <= 0;
        else begin
            if (counter == 0 || counter == 1)
                o_clk <= ~o_clk;
            else
                o_clk <= o_clk;
        end
    end

endmodule


// ============================================================
//  Even Clock Divider
// ============================================================
module even_divider #(parameter N = 4) (
    input  logic i_clk,
    input  logic i_reset,
    output logic o_clk
);

    logic [$clog2(N-1):0] counter;

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset || counter == (N >> 1) - 1)
            counter <= '0;
        else
            counter <= counter + 1;
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            o_clk <= '0;
        else begin
            if (counter == (N >> 1) - 1)
                o_clk <= ~o_clk;
            else
                o_clk <= o_clk;
        end
    end

endmodule


// ============================================================
//  Sequence Detector: 011001 (Mealy FSM)
// ============================================================
// State encoding:
//   S0: ""      (idle)
//   S1: "0"
//   S2: "01"
//   S3: "011"
//   S4: "0110"
//   S5: "01100"
// Detection: S5 + input 1 -> output 1

module sequence_detect (
    input  logic i_clk,
    input  logic i_x,
    input  logic i_reset,
    output logic o_detected
);

    typedef enum logic [2:0] {
        S0 = 3'd0,
        S1 = 3'd1,
        S2 = 3'd2,
        S3 = 3'd3,
        S4 = 3'd4,
        S5 = 3'd5
    } state_t;

    state_t state, next_state;

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            S0: next_state = (i_x == 0) ? S1 : S0;
            S1: next_state = (i_x == 1) ? S2 : S1;
            S2: next_state = (i_x == 1) ? S3 : S1;
            S3: next_state = (i_x == 0) ? S4 : S0;
            S4: next_state = (i_x == 0) ? S5 : S2;
            S5: next_state = (i_x == 1) ? S0 : S1;
            default: next_state = S0;
        endcase
    end

    assign o_detected = (state == S5) && (i_x == 1);

endmodule


// ============================================================
//  Edge Detector (both edges)
// ============================================================
module edge_detector (
    input  logic clk,
    input  logic reset,
    input  logic signal,
    output logic edge_detected
);

    logic signal_r;

    always @(posedge clk or negedge reset) begin
        if (!reset)
            signal_r <= 0;
        else
            signal_r <= signal;
    end

    assign edge_detected = signal_r ^ signal;

endmodule


// ============================================================
//  Gray to Binary Converter
// ============================================================
module gray2binary #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] gray_data,
    output logic [WIDTH-1:0] binary_data
);

    genvar i;
    generate
        assign binary_data[WIDTH-1] = gray_data[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i--) begin : gen_gray2bin
            assign binary_data[i] = binary_data[i+1] ^ gray_data[i];
        end
    endgenerate

endmodule


// ============================================================
//  Binary to Gray Converter
// ============================================================
module binary2gray #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] i_data,
    output logic [WIDTH-1:0] o_data
);

    assign o_data = i_data ^ (i_data >> 1);

endmodule


// ============================================================
//  Clock Domain Crossing: Slow-to-Fast (2FF Synchronizer)
// ============================================================
module slow2fast (
    input  logic i_clk1,
    input  logic i_data1,
    input  logic i_clk2,
    output logic o_data
);

    logic r_data1, r_data2;

    always @(posedge i_clk2) begin
        r_data1 <= i_data1;
        r_data2 <= r_data1;
    end

    assign o_data = r_data2;

endmodule


// ============================================================
//  Clock Domain Crossing: Fast-to-Slow (Toggle Synchronizer)
// ============================================================
module fast2slow (
    input  logic i_clk1,
    input  logic i_data,
    input  logic i_clk2,
    output logic o_data
);

    logic r_temp;
    initial r_temp = 0;

    always @(posedge i_clk1) begin
        if (i_data)
            r_temp <= ~r_temp;
    end

    logic r_temp_d0, r_temp_d1, r_temp_d2;

    always @(posedge i_clk2) begin
        r_temp_d0 <= r_temp;
        r_temp_d1 <= r_temp_d0;
        r_temp_d2 <= r_temp_d1;
    end

    assign o_data = r_temp_d2 ^ r_temp_d1;

endmodule


// ============================================================
//  Asynchronous FIFO
// ============================================================
module async_fifo #(
    parameter DEPTH = 64,
    parameter WIDTH = 8
) (
    input  logic              i_wclk,
    input  logic              i_wreset,
    input  logic              i_wen,
    input  logic [WIDTH-1:0]  i_wdata,

    input  logic              i_rclk,
    input  logic              i_rreset,
    input  logic              i_ren,

    output logic [WIDTH-1:0]  o_rdata,
    output logic              o_full,
    output logic              o_empty
);

    localparam PTR_W = $clog2(DEPTH) + 1;

    logic [PTR_W-1:0] w_pointer;
    logic [PTR_W-1:0] r_pointer;

    logic [PTR_W-2:0] w_address;
    logic [PTR_W-2:0] r_address;

    assign w_address = w_pointer[PTR_W-2:0];
    assign r_address = r_pointer[PTR_W-2:0];

    always @(posedge i_wclk or negedge i_wreset) begin
        if (!i_wreset)
            w_pointer <= '0;
        else if (i_wen && !o_full)
            w_pointer <= w_pointer + 1;
    end

    always @(posedge i_rclk or negedge i_rreset) begin
        if (!i_rreset)
            r_pointer <= '0;
        else if (i_ren && !o_empty)
            r_pointer <= r_pointer + 1;
    end

    logic [PTR_W-1:0] gray_write_pointer;
    logic [PTR_W-1:0] gray_read_pointer;

    assign gray_write_pointer = w_pointer ^ (w_pointer >> 1);
    assign gray_read_pointer  = r_pointer ^ (r_pointer >> 1);

    logic [PTR_W-1:0] w_gray_sync0, w_gray_sync1;

    always @(posedge i_rclk or negedge i_rreset) begin
        if (!i_rreset) begin
            w_gray_sync0 <= '0;
            w_gray_sync1 <= '0;
        end
        else begin
            w_gray_sync0 <= gray_write_pointer;
            w_gray_sync1 <= w_gray_sync0;
        end
    end

    logic [PTR_W-1:0] r_gray_sync0, r_gray_sync1;

    always @(posedge i_wclk or negedge i_wreset) begin
        if (!i_wreset) begin
            r_gray_sync0 <= '0;
            r_gray_sync1 <= '0;
        end
        else begin
            r_gray_sync0 <= gray_read_pointer;
            r_gray_sync1 <= r_gray_sync0;
        end
    end

    assign o_empty = (gray_read_pointer == w_gray_sync1);
    assign o_full  = (gray_write_pointer == {~r_gray_sync1[PTR_W-1:PTR_W-2], r_gray_sync1[PTR_W-3:0]});

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge i_wclk) begin
        if (i_wen && !o_full)
            mem[w_address] <= i_wdata;
    end

    always @(posedge i_rclk) begin
        if (i_ren && !o_empty)
            o_rdata <= mem[r_address];
    end

endmodule


// ============================================================
//  Dual-Port RAM
// ============================================================
module ram #(
    parameter WIDTH = 8,
    parameter DEPTH = 64
) (
    input  logic                     i_wclk,
    input  logic                     i_wreset,
    input  logic                     i_wen,
    input  logic [$clog2(DEPTH)-1:0] i_waddr,
    input  logic [WIDTH-1:0]         i_wdata,

    input  logic                     i_rclk,
    input  logic                     i_rreset,
    input  logic                     i_ren,
    input  logic [$clog2(DEPTH)-1:0] i_raddr,
    output logic [WIDTH-1:0]         o_rdata
);

    logic [WIDTH-1:0] dual_ram [0:DEPTH-1];

    integer i;

    always @(posedge i_wclk or negedge i_wreset) begin
        if (!i_wreset) begin
            for (i = 0; i < DEPTH; i = i + 1)
                dual_ram[i] <= '0;
        end
        else if (i_wen) begin
            dual_ram[i_waddr] <= i_wdata;
        end
    end

    always @(posedge i_rclk or negedge i_rreset) begin
        if (!i_rreset)
            o_rdata <= '0;
        else if (i_ren)
            o_rdata <= dual_ram[i_raddr];
    end

endmodule


// ============================================================
//  Synchronous FIFO
// ============================================================
module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 128
) (
    input  logic              i_clk,
    input  logic              i_reset,
    input  logic              i_wren,
    input  logic              i_rden,
    input  logic [WIDTH-1:0]  i_wdata,
    output logic [WIDTH-1:0]  o_rdata,
    output logic              o_full,
    output logic              o_empty
);

    logic [WIDTH-1:0]         mem_ram  [0:DEPTH-1];
    logic [$clog2(DEPTH):0]   fifo_count;
    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    integer i;

    assign o_full  = (fifo_count == DEPTH);
    assign o_empty = (fifo_count == 0);

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            wr_ptr <= '0;
        else if (i_wren && !o_full)
            wr_ptr <= wr_ptr + 1;
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            rd_ptr <= '0;
        else if (i_rden && !o_empty)
            rd_ptr <= rd_ptr + 1;
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            o_rdata <= '0;
        else if (i_rden && !o_empty)
            o_rdata <= mem_ram[rd_ptr];
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem_ram[i] <= '0;
        end
        else if (i_wren && !o_full) begin
            mem_ram[wr_ptr] <= i_wdata;
        end
    end

    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            fifo_count <= '0;
        end
        else begin
            case ({i_wren && !o_full, i_rden && !o_empty})
                2'b10:   fifo_count <= fifo_count + 1;
                2'b01:   fifo_count <= fifo_count - 1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

endmodule
// MAY

// Q35
class size_10_6_ones;
    rand bit arr[];
    constraint c_size{ arr.size() == 10; }

    constraint c_sum{ arr.sum() with (int'(item == 1)) == 6; }
endclass

// Q36
class unique_elements;
    rand int arr[];
    constraint c_size{arr.size() == 10;}
    constraint c_unique{unique {arr};}
endclass

class arr_sum_10;
    rand int arr[4][4];
    constraint c_sum{
        foreach(arr[i]) begin
            arr[i].sum() == 10;
        end
    }
endclass

class two_arr;
    rand int a[10];
    rand int b[10];

    constraint c_a_ascending{
        foreach (a[i]) if (i > 0) a[i] > a[i-1];
    }

    constraint c_range{
        foreach (a[i]) a[i] inside {[0:100]};
        foreach (b[i]) b[i] inside {[100:200]};
    }

endclass

// Q37
class size_between;
    rand int arr[];
    constraint c_size{
        arr.size() inside {[5:10]};
    }

    constraint c_range_order{
        foreach (arr[i]) arr[i] inside {[0:100]};
        foreach (arr[j]) if (j > 0) arr[j] > arr[j-1];
    }

    constraint c_adjacent{
        foreach (arr[k]) if (k > 0) (arr[k] - arr[k-1]) <= 20;
    }
endclass

typedef enum {READ, WRITE} op_t;
class txn;
    rand op_t type;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0] burst_len; // 1 to 15
    bit [31:0] base_addr;

    constraint c_align{
        (type == READ) -> (addr);
    }

    constraint c_write{
        (type == WRITE) -> (data > 0);
        (type == WRITE) -> (addr inside {[base_addr:base_addr + 4095]});
    }
endclass

// May Q62
covergroup data_cg @(posedge clk);
    cp_only47 coverpoint data{
        bins val_4 = {4};
        bins val_7 = {7};
    }

    cp_range coverpoint data{
        bins range_14_19[] = {[14:19]}; 
    }
endgroup

// June Q64

class dym;
    rand bit arr[100];
    constraint c_sum_8_6 {
        arr.sum() with int'()
    }
endclass

// Jane Q70

`timescale 1ns/1ps
property check_clock_freq (int exp_period = 10);
    real prev_edge_time;
    @(posedge clk)
    (1, prev_edge_time = $realtime) |=> ($realtime - prev_edge_time == exp_period);
endproperty

assert property (check_clock_freq(20)) else $error("clk period wrong");

// Q76
B2
After inner b
A1;
After inner A;
B1;
A2;
After outer;


// Outstanding req, 3 req maximum before ack, done asserted when all req has corresponding ack.

logic [1:0] counter;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) counter <= 0;
    if (req && !ack) counter <= counter + 1;
    else if (!req && ack) counter <= counter - 1;
    else counter <= counter
end

property 3_outstanding_req;
    @(posedge clk)
    $rose(req) |-> ##[0:$] (ack && counter < 3);
endproperty

assert property (3_outstanding_req) else $error("More req than expected");

// Black Sesame

`define OPCODE_SIZE 3:0
`define REG_SIZE 1:0
class register;

    typedef enum bit [3:0] {NOP, MOV, ADD, SUB, AND, OR, XOR, CMP, LDI, LOAD, STORE, JMP, JZ, HALT, RESERVED, default: NOP} opcode_e;
    typedef enum bit [1:0] {R0, R1, R2, R3} reg_e;
    typedef enum bit {Z, N} flag_e;

    flag_e flag;
    instruction_e instruction;

    typedef struct packed{
        opcode_e opcode;
        reg_e rd;
        reg_e rs;
    } instruction_e;

    case(instruction.opcode)
        NOP: 

    endcase

endclass

// mini_cpu_oop_fatbase.sv
// Variant: the abstract base holds the common operand placeholders
// (opcode, rd, rs, imm). Each subclass fills them via super.new() and
// its execute() reads the INHERITED fields.

typedef enum bit [3:0] {
  OP_NOP=4'h0, OP_MOV, OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_CMP,
  OP_LDI, OP_LOAD, OP_STORE, OP_JMP, OP_JZ, OP_JNZ, OP_HALT, OP_RSVD
} opcode_e;

typedef enum bit [1:0] {R0, R1, R2, R3} reg_e;

class cpu_state;
  bit [7:0] rf  [4];
  bit [7:0] mem [256];
  bit [7:0] pc;
  bit       z, n, halted;
  function void set_nz(bit [7:0] r); z = (r == 8'h00); n = r[7]; endfunction
endclass

// ===== ABSTRACT BASE: common fields live here, filled by subclasses =====
virtual class instruction;
  opcode_e  opcode;
  reg_e     rd;      // destination reg (also the target reg for 2-byte forms)
  reg_e     rs;      // source reg
  bit [7:0] imm;     // imm8 / addr8

  // Base constructor with defaults; subclasses pass what they use.
  function new(opcode_e opcode = OP_NOP, reg_e rd = R0, reg_e rs = R0, bit [7:0] imm = 8'h00);
    this.opcode = opcode;
    this.rd     = rd;
    this.rs     = rs;
    this.imm    = imm;
  endfunction

  // Non-virtual helper usable on ANY instruction via a base handle,
  // because it only touches the shared base fields.
  function string to_s();
    return $sformatf("%-5s rd=%0d rs=%0d imm=%0d", opcode.name(), rd, rs, imm);
  endfunction

  // The one thing subclasses MUST define.
  pure virtual function void execute(cpu_state st);
endclass

// ===== Concrete instructions: fill base fields, use inherited fields =====
class mov_i extends instruction;
  function new(reg_e rd, reg_e rs); super.new(OP_MOV, rd, rs); endfunction
  virtual function void execute(cpu_state st);
    st.rf[rd] = st.rf[rs]; st.pc += 8'd1;      // rd, rs inherited from base
  endfunction
endclass

class add_i extends instruction;
  function new(reg_e rd, reg_e rs); super.new(OP_ADD, rd, rs); endfunction
  virtual function void execute(cpu_state st);
    st.rf[rd] = st.rf[rd] + st.rf[rs];
    st.set_nz(st.rf[rd]);
    st.pc += 8'd1;
  endfunction
endclass

class ldi_i extends instruction;
  function new(reg_e r, bit [7:0] imm); super.new(OP_LDI, r, R0, imm); endfunction  // r -> rd
  virtual function void execute(cpu_state st);
    st.rf[rd] = imm; st.pc += 8'd2;            // imm inherited
  endfunction
endclass

class store_i extends instruction;
  function new(reg_e r, bit [7:0] addr); super.new(OP_STORE, r, R0, addr); endfunction // addr -> imm
  virtual function void execute(cpu_state st);
    st.mem[imm] = st.rf[rd]; st.pc += 8'd2;
  endfunction
endclass

class halt_i extends instruction;
  function new(); super.new(OP_HALT); endfunction   // rd/rs/imm defaulted, unused
  virtual function void execute(cpu_state st);
    st.halted = 1'b1;
  endfunction
endclass

// (SUB/AND/OR/XOR/CMP/LOAD/JMP/JZ/JNZ/NOP follow the same shape.)


// ------------------------------------------------------------------
// Demo: LDI R0,5 ; LDI R1,3 ; ADD R0,R1 ; STORE R0,0x20 ; HALT
// Note the loop prints each instruction via the base-class to_s()
// BEFORE executing it — generic code reading shared base fields.
// ------------------------------------------------------------------
module tb;
  cpu_state   st;
  instruction prog [$];

  initial begin
    st = new();

    begin
      ldi_i   i0 = new(R0, 8'd5);
      ldi_i   i1 = new(R1, 8'd3);
      add_i   i2 = new(R0, R1);
      store_i i3 = new(R0, 8'h20);
      halt_i  i4 = new();
      prog.push_back(i0); prog.push_back(i1); prog.push_back(i2);
      prog.push_back(i3); prog.push_back(i4);
    end

    foreach (prog[i]) begin
      $display("exec: %s", prog[i].to_s());   // base helper, works on any subclass
      prog[i].execute(st);                     // polymorphic
    end

    $display("R0=%0d  mem[0x20]=%0d  Z=%0b  halted=%0b",
             st.rf[0], st.mem['h20], st.z, st.halted);

    if (st.rf[0] === 8'd8 && st.mem['h20] === 8'd8)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end
endmodule


module seq_detector_mealy(
  input logic clk,
  input logic rst_n,
  input bit bit_in,

  output bit detected
);

// Mealy machine: State update requires current state + input

  typedef enum logic [1:0] {S0, S1, S2, S3} state_e;
  state_e state, next;
// Update and reset logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S0;
    end else begin
      state <= next;
    end
  end

// State transition as combinational logic
  always_comb begin
    case(state)
      S0: next = bit_in ? S1 : S0; // 1
      S1: next = bit_in ? S2 : S0; // 11
      S2: next = bit_in ? S1 : S3; // 110
      S3: next = bit_in ? S0 : S1;
    endcase
  end

  assign detected = (state == S3 && bit_in) ? 1'b1 : 1'b0;


endmodule


// AHB UVM Driver
//     1. Redefine new()
//     2. Get build phase config_dv
//     3. task run_phase

class ahb_driver extends uvm_driver #(transaction);
  function void build_phase(uvm_phase phase);

  endfunction
endclass


// July Q6
module bit_counter(
  input logic clk,
  input logic rst_n,
  input logic en,
  output logic [3:0] count
);

  bit hold_flag;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= 4'b0;
      hold_flag <= 1'b0;
    end else begin
      if (en) begin

      end else begin
        count <= count;
      end
    end
  end

endmodule

// async fifo
module sram #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8,
  localparam int ADDR_W = $clog2(DEPTH); // 3
) (
  input logic clk,
  input logic w_en,
  input logic [WIDTH-1:0] w_data,
  input logic [ADDR_W-1:0] w_addr,
  input logic [ADDR_W-1:0] r_addr,
  output logic [WIDTH-1:0] r_data
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (w_en) mem[w_addr] <= w_data;
  end

  assign r_data = mem[r_addr];

endmodule

module async_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8,
  localparam int ADDR_W = $clog2(DEPTH) // 3
) (
  input logic rst_n,
  input logic clk_wr,
  input logic clk_rd,
  input logic w_en,
  input logic r_en,
  input logic [WIDTH-1:0] W_DATA,
  output logic [WIDTH-1:0] R_DATA,
  output logic full,
  output logic empty
);

  logic [ADDR_W:0] r_ptr_bin, w_ptr_bin; // Architecturally lives inside the FIFO
  logic [ADDR_W:0] r_ptr_gray, w_ptr_gray; // Translated for 2FF
  logic [ADDR_W:0] r_ptr_bin_n, w_ptr_bin_n; // Next pointer
  logic [ADDR_W:0] r_ptr_gray_n, w_ptr_gray_n; // Next pointer in gray

  // 2FF logics
  logic [ADDR_W:0] r_ptr_gray_d1, r_ptr_gray_d2, w_ptr_gray_d1, w_ptr_gray_d2;

  logic full_n, empty_n;
  logic w_push, r_pop;

  // Instantiate SRAM
  sram #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) u_sram (
    .clk(clk_wr),
    .w_en(w_push),
    .w_data(W_DATA),
    .w_addr(w_ptr_bin[ADDR_W-1:0]),
    .r_addr(r_ptr_bin[ADDR_W-1:0]),
    .r_data(R_DATA)
  );

  // Write domain
  assign w_push = w_en && ~full;
  assign w_ptr_bin_n = w_ptr_bin + {{ADDR_W{1'b0}}, w_push};
  assign w_ptr_gray_n = w_ptr_bin_n ^ (w_ptr_bin_n >> 1);
  assign full_n = (w_ptr_gray_n == {~r_ptr_gray_d2[ADDR_W:ADDR_W-1], r_ptr_gray_d2[ADDR_W-2:0]});

  always_ff @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr_bin <= '0;
      w_ptr_gray <= '0;
      full <= '0;
    end else begin
      w_ptr_bin <= w_ptr_bin_n;
      w_ptr_gray <= w_ptr_gray_n;
      full <= full_n;
    end
  end

  // Read Domain
  assign r_pop = r_en && ~empty;
  assign r_ptr_bin_n = r_ptr_bin + {ADDR_W{1'b0}, r_pop};
  assign r_ptr_gray_n = r_ptr_bin_n ^ (r_ptr_bin_n >> 1);
  assign empty_n = (r_ptr_gray_n == w_ptr_gray_d2);

  always_ff @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr_bin <= '0;
      r_ptr_gray <= '0;
      empty <= 1'b1;
    end else begin
      r_ptr_bin <= r_ptr_bin_n;
      r_ptr_gray <= r_ptr_gray_n;
      empty <= empty_n;
    end
  end


  // 2FF Synchronizer
  // We need to sample read pointer in write clock domain
  always_ff @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr_gray_d1 <= '0;
      r_ptr_gray_d2 <= '0;
    end else begin
      r_ptr_gray_d1 <= r_ptr_gray;
      r_ptr_gray_d2 <= r_ptr_gray_d1;
    end
  end

  always_ff @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr_gray_d1 <= '0;
      w_ptr_gray_d2 <= '0;
    end else begin
      w_ptr_gray_d1 <= w_ptr_gray;
      w_ptr_gray_d2 <= w_ptr_gray_d1;
    end
  end

endmodule


// sync fifo
module sync_fifo #(
  parameter int DEPTH = 8,
  parameter int WIDTH = 8,
  localparam int ADDR_W = $clog2(DEPTH)
) (
  input logic clk,
  input logic rst_n,
  input logic w_en,
  input logic r_en,
  input logic [WIDTH-1:0] W_DATA,
  output logic [WIDTH-1:0] R_DATA,
  input logic [ADDR_W-1:0] W_ADDR,
  input logic [ADDR_W-1:0] R_ADDR
  output logic full,
  output logic empty
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W:0] w_ptr, r_ptr;

  // Write domain
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr <= '0;
      full <= 1'b0;
    end else begin
      if (w_en && !full) begin
        w_ptr <= w_ptr + 1;
        mem[w_ptr[ADDR_W-1:0]] <= W_DATA;
      end
    end
  end

  //Read domain
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr <= '0;
      empty <= 1'b1;
    end else begin
      if (r_en && !empty) begin
        r_ptr <= r_ptr + 1;
        R_DATA <= mem[r_ptr[ADDR_W-1:0]];
      end
    end
  end

  assign empty = (w_ptr == r_ptr);
  assign full = (w_ptr[ADDR_W] != r_ptr[ADDR_W]) && (w_ptr[ADDR_W-1:0] == r_ptr[ADDR_W-1:0]);
endmodule


// July Q8
class unique;
  int arr[];
  constraint c_size{ arr.size() == 8; }

  constraint c_unique{ 
    foreach (arr[i]) begin
      if (i > 0) arr[i] > arr[i-1];
    end
  }

  function void post_randomize();
    arr.shuffle();
  endfunction


endclass


// async fifo
module async_fifo #(
  parameter int DEPTH = 8,
  parameter int WIDTH = 8,
  localparam int ADDR_W = $clog2(DEPTH)
) (
  input logic clk_wr,
  input logic clk_rd,
  input logic rst_n,

  // Write side signal
  input logic w_en,
  input logic [WIDTH-1:0] w_data,

  // Read side signal
  input logic r_en,
  output logic [WIDTH-1:0] r_data,

  // FIFO signal
  output logic full,
  output logic empty
);

  logic [WIDTH-1:0] mem [0: DEPTH-1];
  logic [ADDR_W:0] w_ptr_bin, w_ptr_bin_n, w_ptr_gray, w_ptr_gray_n;
  logic [ADDR_W:0] r_ptr_bin, r_ptr_bin_n, r_ptr_gray, r_ptr_gray_n;

  logic [ADDR_W:0] w_ptr_gray_d1, w_ptr_gray_d2;
  logic [ADDR_W:0] r_ptr_gray_d1, r_ptr_gray_d2;

  logic full_n, empty_n;

  // Write domain
  logic w_push;

  assign w_push = w_en && !full;
  assign w_ptr_bin_n = w_ptr_bin + {{ADDR_W{1'b0}}, w_push};
  assign w_ptr_gray_n = w_ptr_bin_n ^ (w_ptr_bin_n >> 1);
  assign full_n = w_ptr_gray_n == {~r_ptr_gray_d2[ADDR_W:ADDR_W-1], r_ptr_gray_d2[ADDR_W-2:0]};

  always_ff @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr_bin <= '0;
      w_ptr_gray <= '0;
      full <= 1'b0;
    end else () begin
      w_ptr_bin <= w_ptr_bin_n;
      w_ptr_gray <= w_ptr_gray_n;
      full <= full_n;
    end
  end

  always_ff @(posedge clk_wr) begin
    if (w_push) mem[w_ptr_bin[ADDR_W-1:0]] <= w_data;
  end

  // Read domain
  logic r_pop;

  assign r_pop = r_en && !empty;
  assign r_ptr_bin_n = r_ptr_bin + {{ADDR_W{1'b0}}, r_pop};
  assign r_ptr_gray_n = r_ptr_bin_n ^ (r_ptr_bin_n >> 1);
  assign empty_n = r_ptr_gray_n == w_ptr_gray_d2;

  always_ff @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr_bin <= '0;
      r_ptr_gray <= '0;
      empty <= 1'b1;
    end else begin
      r_ptr_bin <= r_ptr_bin_n;
      r_ptr_gray <= r_ptr_gray_n;
      empty <= empty_n;
      if (r_pop) r_data <= mem[r_ptr_bin[ADDR_W-1:0]];
    end
  end

  // 2FF synchronizer
  // Synchronize write side pointer in read clock domain
  always_ff @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr_gray_d1 <= '0;
      w_ptr_gray_d2 <= '0;
    end else begin
      w_ptr_gray_d1 <= w_ptr_gray;
      w_ptr_gray_d2 <= w_ptr_gray_d1;
    end
  end

  // Synchronize read side pointer in write clock domain
  always_ff @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr_gray_d1 <= '0;
      r_ptr_gray_d2 <= '0;
    end else begin
      r_ptr_gray_d1 <= r_ptr_gray;
      r_ptr_gray_d2 <= r_ptr_gray_d1;
    end
  end

endmodule


// sync fifo
module sync_fifo #(
  parameter int DEPTH = 8,
  parameter int WIDTH = 8,
  localparam int ADDR_W = $clog2(DEPTH)
) (
  input logic clk,
  input logic rst_n,

  //write side signal
  input logic w_en,
  input logic [WIDTH-1:0] w_data,

  // read side signal
  input logic r_en,
  output logic [WIDTH-1:0] r_data,

  output logic full,
  output logic empty
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  // Pointers
  logic [ADDR_W:0] w_ptr, r_ptr;
  logic w_push, r_pop;

  // Write side
  assign w_push = w_en && !full;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr <= '0;
    end else begin
      if (w_push) begin
        mem[w_ptr[ADDR_W-1:0]] <= w_data;
        w_ptr <= w_ptr + 1;
      end else begin
        w_ptr <= w_ptr;
      end
    end
  end

  // Read side
  assign r_pop = r_en && !empty;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr <= '0;
    end else begin
      if (r_pop) begin
        r_data <= mem[r_ptr[ADDR_W-1:0]];
        r_ptr <= r_ptr + 1;
      end else begin
        r_ptr <= r_ptr;
      end
    end
  end

  assign empty = w_ptr == r_ptr;
  assign full = (w_ptr[ADDR_W] != r_ptr[ADDR_W]) && (w_ptr[ADDR_W-1:0] == r_ptr[ADDR_W-1:0]);

endmodule

// July Q20 1D Flip Flop
module dff(
  input logic clk,
  input logic rst_n,
  input logic d,
  output logic q
)

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q <= 1'b0;
    end else begin
      q <= d;
    end
  end

endmodule

// July Q21 Multiplexer
module mux4(
  input logic a,b,c,d,
  input logic s0,s1,
  output logic out
)

  always_comb begin
    case({s1,s0})
      2'b00 : out = a;
    endcase
  end


endmodule

// July Q22 Cache

// - Total size: 32KB
// - Cacheline size: 32 bytes
// - Associativity: 4-way

module cache #(
  parameter int size = 32 * 1024,
  parameter int line_size = 32,
  parameter int set = 4,
  localparam int blockOffset = $clog2(line_size),
  localparam int indexBit = $clog2(size/(line_size * set)),
  localparam int tag = line_size - blockOffset - indexBit
);
  
endmodule


// July Q30 
class bits_with_four_ones #(
  parameter length = N
);
  rand logic [N-1:0] index;
  logic [N-1:0] result;
  constraint c_sum {
    index.sum() with (int'(item == 1)) == 4;
  }

  function void post_randomize();
    foreach (index[i])
      if (index[i] == 1) result[i] == 1;
  endfunction

endclass

// July Q32
class pixel #(
  parameter int SIZE = 7
);

  typedef enum bit [1:0] {R, G, B, D} color_e;
  color_e color;
  rand bit [SIZE-1:0] image [0:SIZE-1];
  rand int idx_x, idx_y;

  constraint c_idx_size {
    idx_x <= SIZE - 2;
    idx_y <= SIZE - 2;
  }

  constraint c_no_dup_d {

  }
endclass

property glitch_issue;
  real rise_time, fall_time;
  @(posedge sig)
  ($rose(sig), rise_time = $realtime)
endproperty


// July Q36
property handshake(valid, ready);
  @(posedge clk) disable iff (!rst_n)
  $rose(valid) |-> valid s_until_with ready;
endproperty

// July Q54
task model_task;
  fork: 
    
  join
endtask


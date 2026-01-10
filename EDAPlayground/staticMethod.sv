`timescale 1ns/1ps

class frame;
  // class (static) property
  static int frmcount = 100;

  // instance (non-static) properties
  logic [4:0] addr;
  logic       parity;

  // 1) STATIC method: can access ONLY static stuff directly
  static function int sta_sum(input int A, B);
    return frmcount + A + B; // OK
  endfunction

  // 2) STATIC method: can access instance stuff ONLY via an explicit handle
  static function int sta_sum_with_obj(input frame f, input int A, B);
    return frmcount + A + B + f.addr; // OK because using f.addr via handle
  endfunction

  // 3) NON-STATIC method: has 'this', can access instance members directly
  function int inst_sum(input int A, B);
    return frmcount + A + B + addr; // OK
  endfunction

  function void genpar();
    parity = ^{addr, frmcount};
  endfunction
endclass


module top;
  frame fh;
  int   out1, out2, out3;

  initial begin
    fh = new();
    fh.addr = 5'd7;

    out1 = frame::sta_sum(10, 20);
    $display("out1 (static, no object)      = %0d", out1);

    out2 = frame::sta_sum_with_obj(fh, 10, 20);
    $display("out2 (static, with handle)    = %0d", out2);

    out3 = fh.inst_sum(10, 20);
    $display("out3 (instance method)        = %0d", out3);

    fh.genpar();
    $display("parity = %0b (addr=%0d frmcount=%0d)", fh.parity, fh.addr, frame::frmcount);

    $finish;
  end
endmodule
/* verilator lint_off DECLFILENAME */
module polymorph(
/* verilator lint_on DECLFILENAME */
  /* verilator lint_off UNUSEDSIGNAL */
  input logic clk
  /* verilator lint_on UNUSEDSIGNAL */
);

  class base;                      // BASE CLASS
    virtual function void display();
      $display("Am in Base class");
    endfunction
  endclass

  class ext extends base;           // EXTENDED CLASS
    function void display();
      $display("Am in Extended class");
    endfunction
  endclass

  base b1;
  initial begin
    ext e_src;
    ext e1;
    e_src = new();                 // construct ext object
    b1 = e_src;                    // upcast: base handle holds ext object
    if (!$cast(e1, b1))            // downcast: guarded, may fail
      $display("Cast failed");
    else
      e1.display();
  end

endmodule

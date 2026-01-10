module polymorph(
	input logic clk
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
  base b1 = new();
  initial begin
    ext  e1, e2;
    $cast(b1, e1);
    e1.display();
  end

endmodule

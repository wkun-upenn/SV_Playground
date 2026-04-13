`timescale 1 ns / 1 ns

module TOP ;

  parameter PERIOD  = 10; // clock period
  parameter CLENGTH = 30; // command length (maximum)
  integer   breakpoint;

  reg CLK, A, B, C, D, E, F, J, K, X ;

  task do_test;
      input [CLENGTH*8:1] seq;
      reg [7:0] c;
      integer i;
    begin
      @(posedge CLK);
      for (i=1;i<=CLENGTH;i=i+1)
        begin
          c = seq[CLENGTH*8:CLENGTH*8-7];
          seq = seq << 8;
          case (c)
            "A" : A <= 1;
            "B" : B <= 1;
            "C" : C <= 1;
            "D" : D <= 1;
            "E" : E <= 1;
            "F" : F <= 1;
            "J" : J <= 1;
            "K" : K <= 1;
            "X" : X <= 1;
            "V" : $finish;
            ";" : begin
                    @(posedge CLK);
                    A<=0; B<=0; C<=0; D<=0; E<=0; F<=0;J<=0; K<=0; X<=0;
                  end
          endcase
        end
      @(posedge CLK);
      A<=0; B<=0; C<=0; D<=0; E<=0; F<=0;J<=0; K<=0; X<=0;
      @(posedge CLK);
      breakpoint=breakpoint+1;
    end
  endtask

  always
    begin
      CLK <= 0 ;
      #(PERIOD/2) ;
      CLK <= 1 ;
      #(PERIOD/2) ;
    end

  initial
    begin : TEST
      $timeformat(-9,0,"ns:",6);
      breakpoint=0;
      @(posedge CLK);
      A<=0; B<=0; C<=0; D<=0; E<=0; F<=0; J<=0; K<=0; X<=0;

      $display("TESTING PROPERTY FORMING CONSTRUCTS");


      $display("###################################################################");
      $display("%t Testing if B true then C stays low up to and including the cycle when D occurs",$time);
      $display("###################################################################");

      $display("%t Testing failing fulfilling condition, C is true before D",$time);
      do_test(";;B;;;C;;;;");
      
      $display("%t Testing failing fulfilling condition, C is true in the same cycle D occurs",$time);
      do_test("B;;;CD;DD;;;;");

      $display("%t Testing normal passing condition",$time);
      do_test("B;;;;D;CD;;;;;;;;;");


      $display("###################################################################");
      $display("%t Testing if A true then E is always true from next cycle",$time);
      $display("###################################################################");

      $display("%t Testing failing fulfilling condition, E is not true in the cycle after A",$time);
      do_test("A;;E;E;E;;;;");
      
      $display("%t Testing failing fulfilling condition, E does not stay true in the cycles after A",$time);
      do_test("AE;E;E;E;E;E;;E;E;E;;;;");

      $display("%t Testing normal passing condition",$time);
      do_test("A;E;E;E;E;E;E;E;E;E;E;VE");
 
      $display("###################################################################");
      $display("TESTING IS COMPLETE");
      $display("###################################################################");
      $finish;
    end

// define assertions here
//#### EDIT ###


//---------------------------------------------------


//#### END OF EDIT ###

endmodule

`timescale 1 ns / 1 ns

module TOP ;

  parameter PERIOD  = 10; // clock period
  parameter CLENGTH = 50; // command length (maximum)
  integer   breakpoint;

  reg CLK, A, B, C, D, E, F, G, H, I, J, K, X ;

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
            "G" : G <= 1;
            "H" : H <= 1;
            "I" : I <= 1;
            "J" : J <= 1;
            "K" : K <= 1;
            "X" : X <= 1;
            ";" : begin
                    @(posedge CLK);
                    A<=0; B<=0; C<=0; D<=0; E<=0; F<=0; G<=0; H<=0; I<=0; J<=0; K<=0; X<=0;
                  end
          endcase
        end
      @(posedge CLK);
                    A<=0; B<=0; C<=0; D<=0; E<=0; F<=0; G<=0; H<=0; I<=0; J<=0; K<=0; X<=0;
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
        A<=0; B<=0; C<=0; D<=0; E<=0; F<=0; G<=0; H<=0; I<=0; J<=0; K<=0; X<=0;

      $display("TESTING SVA_IMPLIES_OPERATOR");
      $display("%t Testing IMPLIES_SEQ_ABC_FGHI pass",$time);
      do_test(";;;AF;BG;CH;I;;;;;");
      $display("%t Testing IMPLIES_SEQ_ABC_FGHI fail",$time);
      do_test("AF;BG;CH;;;;;");
      $display("%t Testing IMPLIES_SEQ_ABC_FGHI fail",$time);
      do_test("A;BF;CG;H;I;;;");
      $display("%t Testing IMPLIES_SEQ_ABC_FGHI not enabled",$time);
      do_test("AF;BG;H;I;;;;;");

      $display("%t Testing IMPLIES_PROP_BCDE_FGHIJ pass",$time);
      do_test("BF;CG;DH;EI;J;;;;");
      $display("%t Testing BCDE pass",$time);
      do_test("B;C;D;E;;;;;");
      $display("%t Testing FGHIJ pass",$time);
      do_test("F;G;H;I;J;;;;");
      $display("%t Testing BCDE fail",$time);
      do_test("B;C;D;;;;;");
      $display("%t Testing FGHIJ fail",$time);
      do_test("F;G;H;I;;;;");

      $display("%t Testing SEQ_CDE_THEN_PROP_HIJK Pass",$time);
      do_test("HC;ID;JE;K;;;");
      $display("%t Testing SEQ_CDE_THEN_PROP_HIJK Fail",$time);
      do_test("HC;ID;JE;;;;");
      $display("%t Testing SEQ_CDE_THEN_PROP_HIJK Fail",$time);
      do_test("C;HD;IE;J;K;;");
      $display("%t Testing SEQ_CDE_THEN_PROP_HIJK Not enabled",$time);
      do_test("HC;ID;J;K;;;");
      $display("%t Testing HIJK fail",$time);
      do_test("H;I;J;;;;;");
      
      $display("TESTING IS COMPLETE");
      $finish;
    end

default clocking DEFCLK @(negedge CLK);
endclocking
//Conclusion of implies given p3 is (P1 implies P2)
//Vacuous passes
//If P1 a vacuous pass then P3 is vacuous pass regardless of P2
//If P1 is False then P3 is false, regardless of P2
//P1 pass, P2 vacuous pass, P3 pass
//Non Vacuous results - the only change in property state seen in Simvision
//P1 pass, P2 fail, P3 Fail
//P1 pass, P2 pass, P3 Pass


// define assertions here
//#### EDIT ###
  sequence SEQ_AB;  A ##1 B; endsequence
  
  sequence SEQ_ABC; A ##1 B ##1 C; endsequence

  sequence SEQ_DE;  D ##1 E; endsequence
  
  sequence SEQ_DEF; D ##1 E ##1 F; endsequence
  
  sequence SEQ_DEFG; D ##1 E ##1 F; endsequence
  
  sequence SEQ_GH;  G ##1 H; endsequence
  
  sequence SEQ_GHI; G ##1 H ##1 I; endsequence
  
  sequence SEQ_FGHI; F ##1 G ##1 H ##1 I; endsequence

  property BC_N_IMP_DE;
    @(negedge CLK) 
     (B ##1 C)  |=> (D ##1 E);
  endproperty
  
  property FG_N_IMP_HIJ;
    @(negedge CLK) 
     (F ##1 G)  |=> (H ##1 I ##1 J);
  endproperty
  
  property HI_N_IMP_JK;
    @(negedge CLK) 
     (H ##1 I)  |=> (J ##1 K);
  endproperty

  IMPLIES_PROP_BCDE_FGHIJ: assert property ( BC_N_IMP_DE implies FG_N_IMP_HIJ);
  
  IMPLIES_SEQ_ABC_FGHI: assert property  ( SEQ_ABC implies SEQ_FGHI );
    
  IMPLIES_EXPLICIT_ABC_FGHI: assert property  ( A ##1 B ##1 C implies  F ##1 G ##1 H ##1 I );
  
  IMPLIES_SEQ_CDE_THEN_PROP_HIJK: assert property  ( C ##1 D ##1 E implies  HI_N_IMP_JK );
//#### END OF EDIT ###

endmodule

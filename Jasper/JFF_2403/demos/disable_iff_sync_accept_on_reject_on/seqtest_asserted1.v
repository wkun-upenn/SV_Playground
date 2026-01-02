`timescale 1 ns / 1 ns

module TOP ;

  parameter PERIOD  = 10; // clock period
  parameter CLENGTH = 30; // command length (maximum)
  integer   breakpoint;

  reg CLK, A, B, C, D, J, K, X ;
  reg CLR1, CLR2;

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
            "J" : J <= 1;
            "K" : K <= 1;
            "X" : X <= 1;
            ";" : begin
                    @(posedge CLK);
                    A<=0; B<=0; C<=0; D<=0; J<=0; K<=0; X<=0;
                  end
          endcase
        end
      @(posedge CLK);
      A<=0; B<=0; C<=0;  D<=0; J<=0; K<=0; X<=0;
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
    begin : CLEAR
       CLR1 <= 0;
       #42
       CLR1<= 1;
       #2
       CLR1<= 0;
      
    end

  initial
    begin : CLEAR_SYNC
       CLR2 <= 0;
       #135
       CLR2<= 1;
       #11
       CLR2<= 0;
      
    end

  initial
    begin : TEST
      $timeformat(-9,0,"ns:",6);
      breakpoint=0;
      @(posedge CLK);
      A<=0; B<=0; C<=0;  D<=0; J<=0; K<=0; X<=0;

      $display("TESTING SIMPLE SERE");
      $display("%t Testing Async disable iff",$time);
      do_test("A;B;C;D;;;;");
      $display("%t Testing Sync reject/accept",$time);
      do_test("A;B;C;;;;;;;;");
      $display("%t Testing all passes",$time);
      do_test("A;B;C;D;;;;;;;");


      $display("TESTING IS COMPLETE");
      $finish;
    end
























// define assertions here
//#### EDIT ###


                                 
ASYNC_PROP:  assert property( @(posedge CLK) disable iff (CLR1)
                                       (A |=> B ##1 C ##1 D)
                                 );  
                                 
SYNC_REJECT_EG :assert property( @(posedge CLK) 
                                       (A |=> sync_reject_on(CLR2) (B ##1 C ##1 D)  )
                                 ); 
                                 
SYNC_ACCEPT_EG : assert property( @(posedge CLK) 
                                       (A |=> sync_accept_on(CLR2) (B ##1 C ##1 D)  )
                                  );                                  
//#### END OF EDIT ###

endmodule






/*
default disable iff (RSTN);
SYNC_REJECT_EG :assert property( @(posedge CLK) 
                                       (A |=> sync_accept_on(CLR2) (B ##1 C ##1 D)  )
                                 );  

SYNC_ACCEPT_EG : assert property( @(posedge CLK) 
                                       (A |=> sync_reject_on(CLR2) (B ##1 C ##1 D)  )
                                  ); 

*/


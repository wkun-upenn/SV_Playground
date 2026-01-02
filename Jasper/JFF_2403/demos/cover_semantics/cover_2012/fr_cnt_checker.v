//
//Checker ports cannot be declared with direction in Sv2009
//but can be in SV2012
/*checker fr_cnt_vcomp (
	 input logic  CLK,
	 input logic  rst_n,
         input logic  CNT_ENB,
	 input logic[2:0]  CNT_VAL
	);
*/

/*
checker  fr_cnt_chkr (
	 logic  CLK,
	 logic  rst_n,
         logic  CNT_ENB,
	 logic  CNT_VAL
	);
Changed from checker to module as LRM does specify checkers as having parameters to avoid
confusion
*/
module  fr_cnt_chkr #( parameter integer CNTR_SIZE = 3, integer SPECIFIC_VAL = 16'h000C) (
	 input logic  CLK,
	 input logic  rst_n,
         input logic  CNT_ENB,
	 input logic[CNTR_SIZE-1:0]  CNT_VAL
	);


default clocking DEFCLK @(posedge CLK);
endclocking 

//This forms a case where CNT_VAL == 6 cannot be reached
//restrict_no_enable_if_cnt_5 : restrict property (  CNT_VAL == 5 |-> !CNT_ENB );

//In JG 2016.12 FCS 64 bits with analyze -sv12 or -sv09,  this bogus error is reported:
//[ERROR (VERI-2283)] fr_cnt_checker.v(26): operator always is not allowed in a 2005 Systemverilog mode
/*
property CNT_ALWAYS_INCS_OR_WRAPS_P;
   always ( ( CNT_VAL == ($past(CNT_VAL) + 1) ) ||  (CNT_VAL == 0) );
endproperty

property CNT_ALWAYS_INCS_P;
   always (  CNT_VAL == ($past(CNT_VAL) + 1) );
endproperty
*/

//   FAIRNESS CONSTRAINT   //////////////////////////////
//Need to exclude traces where ENB held low forever
property MUST_ENAB_CNT_SOMETIME_P;
    ( s_eventually CNT_ENB);
endproperty

asm_CNT_MUST_GET_ENABLED: assume property(MUST_ENAB_CNT_SOMETIME_P);

///////////////////////////////////////////////////////////////////////////

property CNT_ALWAYS_INCS_OR_WRAPS_P;
    ( 1[+] |-> ( ( CNT_VAL == ($past(CNT_VAL) + 1) ) ||  (CNT_VAL == 0) ) );
endproperty

property CNT_ALWAYS_INCS_P;
   ( 1[+] |->  ( CNT_VAL == ($past(CNT_VAL) + 1) )   );
endproperty

property CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE;
    ( 1[+] |->  ( CNT_VAL ==  SPECIFIC_VAL)  );
endproperty

property CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE_FOLLOWED_BY_NOT_SPECIFIC_VALUE;
    ( 1[+] |->  ((CNT_VAL ==  SPECIFIC_VAL) ##1  (CNT_VAL !=  SPECIFIC_VAL)) );
endproperty

property STRONG_CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE_FOLLOWED_BY_NOT_SPECIFIC_VALUE;
    ( 1[+] |->  strong((CNT_VAL ==  SPECIFIC_VAL) ##1  (CNT_VAL !=  SPECIFIC_VAL)) );
endproperty

property eventually_cnt_EQ_val_then_not_val;
  s_eventually ((CNT_VAL ==  SPECIFIC_VAL) ##1  (CNT_VAL !=  SPECIFIC_VAL));
endproperty

ast_CNT_ALWAYS_INCS_OR_WRAPS : assert property (CNT_ALWAYS_INCS_OR_WRAPS_P);
ast_CNT_ALWAYS_INCS          : assert property (CNT_ALWAYS_INCS_P);
ast_eventually_cnt_EQ_val_then_not_val : assert property (eventually_cnt_EQ_val_then_not_val);

cov_CNT_ALWAYS_INCS_OR_WRAPS : cover property (CNT_ALWAYS_INCS_OR_WRAPS_P);
cov_CNT_ALWAYS_INCS          : cover property (CNT_ALWAYS_INCS_P);

cov_CNT_CAN_REACH_VAL: cover property (CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE);
cov_CNT_CAN_REACH_VAL_THEN_NOT_VALUE : cover property(CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE_FOLLOWED_BY_NOT_SPECIFIC_VALUE);
cov_s_CNT_CAN_REACH_VAL_THEN_NOT_VALUE : cover property(CNT_CAN_ALWAYS_REACH_A_SPECIFIC_VALUE_FOLLOWED_BY_NOT_SPECIFIC_VALUE);


bind fr_cnt fr_cnt_chkr #(CNTR_SIZE, SPECIFIC_VAL) SV_PROPS1 ( .* );

endmodule
//endchecker





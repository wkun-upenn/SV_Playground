`ifdef DUMP_ON
task dump_init;

reg[1023:0] dtype;
reg[1023:0] type;
reg[1023:0] testname;

integer dump_start;
integer dump_stop;

begin
  dump_start = 0;
  dump_stop  = 32'h7fffffff;

  // later, dump should have testname
  // $get_env(TESTNAME, testname);

  if ($test$plusargs("DUMP_START=")) begin
    $plusarg("DUMP_START=", dump_start);
  end
  if ($test$plusargs("DUMP_STOP=")) begin
    $plusarg("DUMP_STOP=", dump_stop);
  end
  if ($test$plusargs("DTYPE="))
    $plusarg_str("DTYPE=", dtype);
  else if ($test$plusargs("dtype="))
    $plusarg_str("dtype=", dtype);
  else
    dump_stop = 0;			/* no dumping */

  if (dump_stop > dump_start) begin
    #dump_start
    $display ("Dump - Start:%0d", dump_start);
      `ifdef SIGNALSCAN
      if (dtype == "TRN" || dtype == "trn") begin
        $recordfile("design.trn");
        $recordsetup("sequence","compress");
        $recordvars;
      end else
      `endif // SIGNALSCAN
      if (dtype=="VCD" || dtype=="vcd" ||  dtype=="VPD" || dtype=="vpd") begin
        $vcdplusfile("design.vpd");
        $vcdpluson(dump_start, `TOP);
      end
      `ifdef VDUMP
      else if (dtype == "DMP" || dtype == "dmp") begin
        $dumpfile("design.dump");
	$dumpvars(0);
      end
      `endif // VDUMP
//-------------------------------------
    # (dump_stop - dump_start)
    $display ("Dump - Stop:%0d", dump_stop);
     `ifdef SIGNALSCAN
      if (dtype == "TRN" || dtype == "trn") begin
        $recordoff;
      end else
     `endif   // SIGNALSCAN
      if (dtype=="VCD" || dtype=="vcd" ||  dtype=="VPD" || dtype=="vpd") begin
        $vcdplusoff();
      end
      `ifdef VDUMP
      else if (dtype == "DMP" || dtype == "dmp") begin
        //$dumpoff;
      end
      `endif // VDUMP
  end
end
endtask
`endif 



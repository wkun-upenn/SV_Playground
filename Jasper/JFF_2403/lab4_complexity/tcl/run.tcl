############################################################
# environment setup
#
clear -all
include tcl/setup_jg.tcl
include tcl/local_dut.tcl
include tcl/local_setup.tcl

# Create a basline task from which we start; we don't copy the assertions 
task -create <baseline> -source_task <embedded> -copy_assumes -copy_stopats -copy_abstractions all -set

# Remove all the assumes that are disabled in the baseline task 
foreach p [get_property_list -include {type assume disabled 1}] { assume -remove $p }

# Add the livness assertion that we want to investigate and add fairness constraints 
assert -name ast_live_payload   {payload_sop           |->     s_eventually(payload_eop)}
assume -name asm_fair_ig_eop    {ig_sop && ig_valid    |->     s_eventually(ig_eop)}
assume -name asm_fair_ig_sop    s_eventually(ig_sop)
assume -name asm_fair_ig_valid  s_eventually(ig_valid)



############################################################
# prove assertion in baseline task and open the complexity manager 
#
set_proofgrid_mode                local
set this_prop                     ast_live_payload
prove -task . 




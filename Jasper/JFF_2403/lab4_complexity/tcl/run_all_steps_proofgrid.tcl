############################################################
# environment setup
#
clear -all
include tcl/setup_jg_proofgrid.tcl
include tcl/local_dut_proofgrid.tcl
include tcl/local_setup_proofgrid.tcl

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
complexity_manager -property <baseline>::$this_prop
prove -task . 



############################################################
# add stopats on large arrays
#
task -create <sa_arr> -source_task <baseline> -copy_all -set
stopat list_ctrl.mem
complexity_manager -property <sa_arr>::$this_prop
prove -task . 




############################################################
# add stopats on gates
#
task -create <sa_arr_gates> -source_task <sa_arr> -copy_all -set
stopat payload_mem.*
stopat list_ctrl.*
complexity_manager -property <sa_arr_gates>::$this_prop
prove -task . 



############################################################
# lift assumptions
#

task -create <sa_arr_gates_gna> -source_task <sa_arr_gates> -copy_all -set
get_needed_assumptions \
   -property             ast_live_payload \
   -proofgrid_mode       local \
   -attempts_time_limit  15s \
   -max_parallel_jobs    4 \
   -status               {undetermined proven} \
   -include_liveness_assumes 

# enable only the require assumptions to no generate CEX
set ndd_list [get_property_list -include {type assume disabled 0} -task NDD_ASSUMES -no_task_prefix -exclude_env]
task -set <sa_arr_gates_gna>
assume -disable *
foreach a $ndd_list { assume -enable $a }
prove -task . 





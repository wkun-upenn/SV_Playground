# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.12
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2023.12p001 64 bits
# build date: 2024.01.23 16:09:24 UTC
# ----------------------------------------
# started   : 2024-01-24 14:04:22 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 952878
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:40795' '-style' 'windows' '-data' 'AAABdHicfY67CsJAEEVPjDZWVv6Fj40IIils7BTRwl58QEJQ8QFio5/mp/gn601MlIDxws7dmTM7sw7g36y1JHKvCjVGjJkxVJwwl8ODLh49DAO27AjYELHmQj8l7b/kSPipm0LiFZLOjz0rFqIBS038zjQFPJHzfDu+Q15xXspXpvecQyV7nLW4OlUa7DloY6isrLsnr3PS3oiWyFn/aaZ5rBfcGC+S' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab3_complexity/p2/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab3_complexity/p2/.tmp/.initCmds.tcl' 'tcl/run.tcl'
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




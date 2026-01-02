# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 11:12:49 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1437690
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:43465' '-style' 'windows' '-data' 'AAAApnicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNGgzFDKkMJQylDAUM8QxFQHYhQyJDMkM2kFfMkM+Qw6AHlE0G0iAAAA94EGw=' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/lab2_formal_auxcode/solution/jaspergold/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/demos/lab2_formal_auxcode/solution/jaspergold/jgproject/.tmp/.initCmds.tcl' 'setup_reqack_sol.tcl'
clear -all
# read source files
analyze -sv09 -f jg_reqack_sol.f

# elaborate the design
elaborate 

# Clock specification
clock clk 

# activate reset
reset !rst_n 

#Hold LFSR enable at 1 to reduce state space for this proof
assume -name lfsr_enb_stuck_at_1 {lfsr_enb == 1'b1}

#Disable the fairness constraint on req
#assume -disable <embedded>::top.duv_inst.vcomp_inst.assume_req_fairness


#Run the Formal Analysis
#prove -all 
#exit


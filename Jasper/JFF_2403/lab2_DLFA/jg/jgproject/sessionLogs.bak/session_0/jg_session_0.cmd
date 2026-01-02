# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.12
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2023.12 FCS 64 bits
# build date: 2023.12.19 17:39:24 UTC
# ----------------------------------------
# started   : 2024-01-22 16:32:10 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 679596
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:37771' '-style' 'windows' '-data' 'AAABZnicfY5NDgFBFIS/JvZO4AiiRyQis7CxI8LCVmT8ZET0AonYcDRHcZNWM34n0Wrxqrsq71UZID5778lRPmlU6TNgTE9zyEQMV1pEtLF02eJIWbJhwZHO02n8dXas37oNOlHQaf7ImTOTm5Lo4uemDfg5zO3BxIYisn+pqIwuBYbKa/l7qaaWK6Zq65R2YK9EpwZ1vRIpGe5xqC7m' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab2_DLFA/jg/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab2_DLFA/jg/jgproject/.tmp/.initCmds.tcl' 'jg_solution.tcl'
clear -all
analyze -sv09 +define+ABV_ON=1+ACID_TEST=1 ../solution/rtl/frame.v 
analyze -sv09 +define+ABV_ON=1+ACID_TEST=1 ../rtl/frame_vcomp.v
elaborate -top frame -create_related_covers witness
clock clk
reset !rst_n
prove -all

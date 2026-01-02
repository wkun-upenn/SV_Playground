# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 11:07:24 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1436645
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:37353' '-style' 'windows' '-data' 'AAAAnHicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNcgxZDOkM8QzFDPkMOQylDCUMmUBWHoMekJUMFAEBAGdtDls=' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab2_DLFA/jg/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab2_DLFA/jg/jgproject/.tmp/.initCmds.tcl' 'jg_solution.tcl'
clear -all
analyze -sv09 +define+ABV_ON=1+ACID_TEST=1 ../solution/rtl/frame.v 
analyze -sv09 +define+ABV_ON=1+ACID_TEST=1 ../rtl/frame_vcomp.v
elaborate -top frame -create_related_covers witness
clock clk
reset !rst_n
prove -all

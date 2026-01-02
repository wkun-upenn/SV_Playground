# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-04-08 10:16:44 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 2979205
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:45575' '-style' 'windows' '-data' 'AAAAnnicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNCgzJDBkM2QzxDJkMZQyJQDqZIY+hhKGIQQ9IJjPkgFUCAIKbDps=' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab5_CRT/IVA/solution/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab5_CRT/IVA/solution/jgproject/.tmp/.initCmds.tcl' 'chk_iva_cntr.tcl'
clear -all

analyze -sv12 counter.vs

elaborate -top counter

set iva 1

if {$iva} {
#ADD Abstract tcl command here for iniial value abstraction.
#identify the counter and add IVA useing abstract init_value command

abstract -init_value cntr

}

set_prove_time_limit 5m

clock clk
reset ~rst_n
prove -bg -all

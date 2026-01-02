# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 16:32:43 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1470773
# arguments : '-label' 'session_1' '-console' '//127.0.0.1:36739' '-style' 'windows' '-data' 'AAAAknicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNIgxZDOkM8QxpDAUMZQx6DCUMyQw5YFkA00oMIA==' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/sessionLogs/session_1'
session -refresh
clear -all
restore -jdb /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/run_1
visualize -new_window; visualize -cover {(ready0 != 1'b0)} -bg
visualize -min_length [expr [visualize -get_length -window visualize:0] + 1] -window visualize:0; visualize -freeze [visualize -get_length -window visualize:0] -window visualize:0; visualize -replot -bg -window visualize:0
visualize -new_window; visualize -violation {(ready0 != 1'b0)} -bg
source /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/work/saveRestore/jges.waivers
include jg_fpv.tcl

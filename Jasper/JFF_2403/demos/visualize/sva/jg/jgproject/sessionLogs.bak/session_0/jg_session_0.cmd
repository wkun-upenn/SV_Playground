# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 16:08:54 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1467108
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:36739' '-style' 'windows' '-data' 'AAAAknicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNIgxZDOkM8QxpDAUMZQx6DCUMyQw5YFkA00oMIA==' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/.tmp/.initCmds.tcl' 'jg_fpv.tcl'
# Rehash Verification environment
clear -all

# JG settings for lab
set_max_trace_length 88

# Define path to design under verification files
set design_path ../source/design
# Define path to property files
set prop_path   ../source/properties

# Analyze design under verification files
analyze -verilog \
  $design_path/arbiter.v \
  $design_path/port_select.v \
  $design_path/bridge.v \
  $design_path/egress.v \
  $design_path/ingress.v \
  $design_path/top.v

# Analyze property files
analyze -sv09 \
  $prop_path/v_arbiter.sva \
  $prop_path/v_arbiter_fairness.sva \
  $prop_path/v_bridge.sva \
  $prop_path/v_ingress.sva \
  $prop_path/v_egress.sva \
  $prop_path/v_port_select.sva \
  $prop_path/bindings.sva

# Elaborate design and extract properties
elaborate -top top

# Setup proof environment
clock clk
reset !(rstN)

prove -all
get_clock_info -gui
reset -expression !(rstN);
prove -bg -all
include jg_fpv.tcl
get_clock_info -gui
prove -bg -all
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
visualize -property <embedded>::top.ing0.i_ingress.c_rd_ready -new_window
visualize -min_length [expr [visualize -get_length -window visualize:1] + 10] -window visualize:1; visualize -freeze [visualize -get_length -window visualize:1] -window visualize:1; visualize -replot -bg -window visualize:1
assert -name <embedded>::Check_rd {rd_ready |=> rd_ready};
prove -bg -property {<embedded>::Check_rd}
visualize -violation -property <embedded>::Check_rd -new_window
session -export_sva -task <embedded> -file /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/export_sva.sva -force
assume -from_assert <embedded>::top.eg.i_egress.a_wvalid_2cycle
assume -remove <embedded>::top.eg.i_egress.a_wvalid_2cycle:assume
assert -enable <embedded>::top.eg.i_egress.a_wvalid_2cycle
include jg_fpv.tcl
save -jdb [get_proj_dir]/database -import_setup /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/export_sva.sva -force
assume -from_assert <embedded>::top.arb.i_arbiter.a_grant_is_onehot0
include jg_fpv.tcl
task -create Added_assume -set -source_task <embedded> -copy_all
assume -from_assert Added_assume::top.arb.i_arbiter.a_grant_is_onehot0
assume -from_assert Added_assume::top.arb.i_arbiter.a_grant_is_one_cycle

prove -bg -all

task -set <embedded>
check_assumptions -bg -task {Added_assume}
save -jdb /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/run_1 -capture_setup -capture_session_data
source /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/work/saveRestore/jges.waivers

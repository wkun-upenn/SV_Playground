# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-30 16:26:55 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1750690
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:36259' '-style' 'windows' '-data' 'AAAAknicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNIgxZDOkM8QxpDAUMZQx6DCUMyQw5YFkA00oMIA==' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/jgproject/.tmp/.initCmds.tcl' 'jg_fpv.tcl'
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
include jg_fpv.tcl
include jg_fpv.tcl
include jg_fpv.tcl
visualize -reset





















include jg_fpv.tcl
visualize -reset
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
get_clock_info -gui
get_clock_info -gui
get_clock_info -gui
get_clock_info -gui
get_clock_info -gui
get_clock_info -gui
clock clk -factor 1 -phase 1
get_design_info
help get_design_info -gui
visualize -new_window; visualize -cover {(valid3 != 1'b0)} -bg
visualize -new_window; visualize -cover {(ready3 != 1'b0)} -bg
visualize -new_window; visualize -cover {(ready3 != 1'b0)} -bg
prove -bg -all
complexity_manager -property {<embedded>::top.arb.i_arbiter.a_grant_is_onehot0}
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
get_design_info -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -gui
assume -from_assert <embedded>::top.arb.i_arbiter.a_grant_is_onehot0
assume -remove <embedded>::top.arb.i_arbiter.a_grant_is_onehot0:assume
include jg_fpv.tcl
assume -from_assert <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
assume -remove <embedded>::top.brdg.i_bridge.a_fifo_no_underflow:assume








get_desgin_info
get_design_info
assert -enable <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
prove -bg -all
include jg_fpv.tcl
include jg_fpv.tcl
get_design_info
prove -bg -all
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
visualize -property <embedded>::top.brdg.i_bridge.c_int_datavalid -new_window
assume -from_assert <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
assume -remove <embedded>::top.brdg.i_bridge.a_fifo_no_underflow:assume
assert -enable <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
prove -bg -all
debug_handoff -save -property {<embedded>::top.brdg.i_bridge.a_fifo_no_overflow} debug_1
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
assume -name assert_1 -env rdata0 -type temporary;
assume -remove ::assert_1
get_design_info
assert -name <embedded>::assert_1 rdata0;
assert -name assert_2 {rdata1}
session -export_psl -task <embedded> -file /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/pasl_1.psl -force
session -export_sva -task <embedded> -file /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/export_sva.sva -force
prove -bg -all
assert -disable <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
assert -enable <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
assume -from_assert <embedded>::top.brdg.i_bridge.a_fifo_no_underflow
assert -from_assume <embedded>::top.brdg.i_bridge.a_fifo_no_underflow:assume
include jg_fpv.tcl
assume -name temp {!brdg.i_bridge.fifo_empty}
prove -bg -property {<embedded>::top.brdg.i_bridge.a_fifo_no_underflow <embedded>::top.brdg.i_bridge.a_fifo_no_underflow:precondition1}
prove -bg -property {<embedded>::top.brdg.i_bridge.a_fifo_no_overflow <embedded>::top.brdg.i_bridge.a_fifo_no_overflow:precondition1}
prove -bg -all
include jg_fpv.tcl
assume {arb.i_arbiter.gnt}
assume -name <embedded>::assume:0 !arb.i_arbiter.gnt -type temporary -replace;
prove -bg -property {<embedded>::top.arb.i_arbiter.a_grant_is_one_cycle:precondition1}
prove -bg -property {<embedded>::top.arb.i_arbiter.a_grant_is_one_cycle}
prove -bg -property {<embedded>::top.p_sel.i_port_select.a_int_size_select_00 <embedded>::top.p_sel.i_port_select.a_int_size_select_00:precondition1}
prove -bg -all
include jg_fpv.tcl
prove -bg -all
save -jdb /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/data_save_1 -capture_setup -capture_session_data
include jg_fpv.tcl
prove -bg -all
save -jdb /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/data_save_1 -capture_setup -capture_session_data
visualize -violation -property <embedded>::top.brdg.i_bridge.a_fifo_no_overflow -new_window
save -jdb /servers/esd_noida/amey/JGFF_2212/demos/visualize/sva/jg/data_save_1 -capture_setup -capture_session_data -force
visualize -violation -property <embedded>::top.arb.i_arbiter_fairness.a_arbiter_fairness -new_window

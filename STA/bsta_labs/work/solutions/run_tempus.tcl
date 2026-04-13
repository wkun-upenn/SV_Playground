#######################################################
#                                                     
#@(#)CDS: Tempus Timing Signoff Solution v16.20-p001_1 (64bit) 11/04/2016 12:14 (Linux 2.6.18-194.el5)

read_lib -max_libs {../libs/liberty/slow.lib ../libs/liberty/wireload.lib}
read_netlist DESIGN/top.v
#set_top_module top
init_design
#read_sdc solutions/constraints.sdc
read_sdc DESIGN/top._default_constraint_mode_.sdc
update_timing -full
gui_show
#report_timing -early -from GlCoreSoftResetSynR00C -path_exceptions applied

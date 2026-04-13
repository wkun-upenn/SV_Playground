#######################################################
#updated 09/25/2023 to use the Stylus version of the Tempus software.
#######################################################
#                                                     
read_lib -max_libs {../libs/liberty/slow.lib ../libs/liberty/wireload.lib}
read_netlist DESIGN/top.v
#set_top_module top
init_design
#read_sdc solutions/constraints.sdc
read_sdc DESIGN/top._default_constraint_mode_.sdc
update_timing -full
gui_show
#report_timing -early -from GlCoreSoftResetSynR00C -path_exceptions applied

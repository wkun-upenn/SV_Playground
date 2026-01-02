# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 14:14:01 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1455510
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:40143' '-style' 'windows' '-data' 'AAAAsHicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNRgwFDEUM+QxlDKkM8UB2IkMJQwaQlQLkFzNkMqQz5AF5xUAVOQx6QLlkIA0CAMs0EoA=' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/WB_FUNC/sva/solution/jaspergold/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/demos/WB_FUNC/sva/solution/jaspergold/jgproject/.tmp/.initCmds.tcl' 'prove_path_design_sol.tcl'
# aux variable to make the script relocatable
#
#In 1709 the behaviour of get_sourced_files changed. At index 0 is now the <JG install Dir>/etc/res/settings/jgrc.tcl
#The second thing is the returned list is the users Tcl script supplied to jg UNIX command, i.e. index 1
#set base_dir [file normalize [file dirname [lindex [get_sourced_files] 0]]] #Only works in JG1706 and earlier
#set base_dir [file normalize [file dirname [lindex [get_sourced_files] 1]]] #Only works in JG1709,  and maybe later versions??
set base_dir [pwd]; #This is the most portable which works as long as Tcl script is in the working directory
#
#
# clear the session
clear -all
#parsing HDL files
analyze -sv09 ${base_dir}/vcomp_path.v
analyze +incdir+${base_dir}/../../../defines -sv09 ${base_dir}/../rtl/fifo_no_errors.v
#analyze +incdir+${base_dir}/../../../defines -sv ${base_dir}/../rtl/fifo.v
analyze -verilog ${base_dir}/../rtl/path.v +define+ABV_ON
# elaborating the whole design
elaborate -top path -create_related_covers { precondition witness }
#setting up primary clock
clock clk

#in simple reset commands the -expression switch can be omitted
reset !rst_n

# deliberate overconstraints to simplify problem
assume -name case1asm1 -env enable_i
assume -name case1asm2 -env !flush_i

#mavery-30Oct14. This no longer needed. 
#Don't know why assumptions were coded as assertions in the first place
#assume -from_assert *assume*
#Won't get full proofs on all properties without reducing design parameter values, for example FDEPTH
set_prove_time_limit 120s

prove -all

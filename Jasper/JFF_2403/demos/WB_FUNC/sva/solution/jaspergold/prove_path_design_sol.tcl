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

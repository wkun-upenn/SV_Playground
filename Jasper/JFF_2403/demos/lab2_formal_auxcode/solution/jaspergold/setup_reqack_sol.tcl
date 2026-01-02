clear -all
# read source files
analyze -sv09 -f jg_reqack_sol.f

# elaborate the design
elaborate 

# Clock specification
clock clk 

# activate reset
reset !rst_n 

#Hold LFSR enable at 1 to reduce state space for this proof
assume -name lfsr_enb_stuck_at_1 {lfsr_enb == 1'b1}

#Disable the fairness constraint on req
#assume -disable <embedded>::top.duv_inst.vcomp_inst.assume_req_fairness


#Run the Formal Analysis
#prove -all 
#exit


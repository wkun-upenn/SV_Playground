# Clear
clear -all

## EDIT #########################################
#Need to use this command in order that the macros which define SB3
jasper_scoreboard_3 -init
## END OF EDIT ##################################

###### ProofGrid Setup ##########################################################
#Note that include is a Jasper Tcl command not a native Tcl command.
#It behaves exactly like source but echos to the logs the command outputs
include ./example_proofgrid_setup.tcl 
###### End of ProofGrid Setup ###################################################

# Analyze design and scoreboard wrapper file
analyze -sv09 ../rtl/fifo.v
analyze -sv09 sb_wrapper_sol8.sv

# Elaborate
#elaborate -top fifo -parameter fifo_width 8 -parameter fifo_depth 4
elaborate -top fifo -parameter fifo_width 8 -parameter fifo_depth 8

# Clock and reset
clock clk
reset !rstN


set_prove_per_property_time_limit 60s; 
set_prove_per_property_time_limit_factor 1

#These are the deafult engine settings
set_engine_mode {Hp Ht B N }
#Select engines more tuned for datapath
#set_engine_mode {Hp Ht B N G C G2 C2}

# prove SB3 properties
prove -all

# Run JG with a TCl file: jg foo.tcl
# To get help about the tcl command syntax
# use the help command "help" at the JG console
# This will list an overview of all commands.
# To get details about individual command use
# help in combination with the command name and its options.
# For example "help assert"

# Clear previous run
clear -all

# Analyze RTL files
analyze -sv12 fr_cnt_checker.v fr_cnt.v

# Elaborate
#The switch -weak_cover_property makes cover property (A |=> B)
#equivalent of cover property (!A or (A ##1 B))
#Prior to this swicth interpreatation was non-LRM compliant where
#cover property (A |=> B) is
#equivalent of cover property (A ##1 B)
#There are other complications as well however anythng written as cover sequnce (<my sequence>)
#is unaffected and will be a finite length trace.
#cover property (<my property>) can be an infinaite length trace
elaborate -weak_cover_property -top fr_cnt -parameter CNTR_SIZE 16

# Initialization
# Clock specification
# clock pin is called "clk"
# duty cycle is 1:1 by default
clock CLK

# Define reset condition
# reset pin is called rst_n, active low
reset {!rst_n}

set_prove_per_property_time_limit 60s; 
set_prove_per_property_time_limit_factor 10;

###########  Proofgrid setup ###############################
#Note that include is a Jasper Tcl command not a native Tcl command.
#It behaves exactly like source but echos to the logs the command outputs
include ./example_proofgrid_setup.tcl
########### End of Proofgrid setup #########################

#These are the deafult engine settings
#set_engine_mode {Hp Ht B N }
#Select engines more tuned for datapath
#set_engine_mode {Hp Ht B N G C G2 C2 J L Q3}
#Cant get a machine available on SJ Farm if I choose 8 engine threads
#as recommended when using Tri 
set_engine_threads 1;
#set_engine_mode {G C AG N Tri B};
set_engine_mode {G C AG Tri };



# Start the verification
prove -all

# exit JG
#exit

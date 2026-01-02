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
analyze -sv12  fr_cnt_checker.v fr_cnt.v


# Elaborate
#The switch -weak_cover_property makes cover property (A |=> B)
#equivalent of cover property (!A or (A ##1 B))
#Prior to this swicth interpreatation was non-LRM compliant where
#cover property (A |=> B) is
#equivalent of cover property (A ##1 B)
#There are other complications as well however anythng written as cover sequnce (<my sequence>)
#is unaffected and will be a finite length trace.
#cover property (<my property>) can be an infinaite length trace
#elaborate -weak_cover_property
elaborate 

# Initialization
# Clock specification
# clock pin is called "clk"
# duty cycle is 1:1 by default
clock CLK

# Define reset condition
# reset pin is called rst_n, active low
reset {!rst_n}

# Start the verification
prove -all

# exit JG
#exit

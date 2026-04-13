clear -all

#Complie the source code
analyze -sv09 fsm_if.v fsm_if_test.v
#Elaborate the hierachy and build mathematical model of the design
elaborate -top FSM_IF_TEST -create_related_covers witness
#Specify the clocks in the design
clock clk
#Define the initial state from which formal explores
reset ~rst_n
#Prove all assertions
prove -all
# visualize {1[*45]}

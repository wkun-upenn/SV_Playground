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

#prove -all

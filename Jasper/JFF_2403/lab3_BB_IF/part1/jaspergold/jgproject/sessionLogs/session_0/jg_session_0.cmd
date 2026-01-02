# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.12
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2023.12p001 64 bits
# build date: 2024.01.23 16:09:24 UTC
# ----------------------------------------
# started   : 2024-01-25 11:18:44 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1079073
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:44001' '-style' 'windows' '-data' 'AAABWnicY2RgYLCp////PwMYMFcBCQEGHwZfhiAGVyDpzxAGpBkYDjCYMhgxWDAYMjgw5DHkM2QypDHkMKQyVDBYQWUM8MoUM2TBxQ1xyhjhlDHGYk8KQyJQNpMhGWgiwkxDHPJgwPgAQjPYMDKgAhCfCVUksAGFZmBghWlG1iTEUAK0IYmhFOhePTA7BywHAD24LE4=' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab6_BB_IF/part1/jaspergold/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab6_BB_IF/part1/jaspergold/jgproject/.tmp/.initCmds.tcl' 'tcbus.tcl'
################
# Clear
################
clear -all

################
# Analyze
################
analyze -v2k -f jg_tcbus.f
analyze -sv09 vcomp_tcbus.v

################
# Elaborate
################
elaborate -top te

################
# Clocks
################
clock clk_bus
clock clk_pkt

################
# Reset
################
reset !rst_n

################
# Constrain pins
################
assume -name ASM_bm_rdata_0 {bm_rdata == 8'd0}
assume -name ASM_da_rdata_0 {da_rdata == 4'd0}
assume -name ASM_da_rrdy_0 {da_rrdy == 0}
assume -name ASM_da_wrdy_0 {da_wrdy == 0}
assume -name ASM_pktib_data_0 {pktib_data == 16'b0}
assume -name ASM_pktib_sop_0 {pktib_sop == 2'b0}

################
# Settings
################
set_prove_per_property_time_limit 1m
prove -bg -all
include tcbus.tcl
prove -bg -all
include tcbus.tcl
prove -bg -all

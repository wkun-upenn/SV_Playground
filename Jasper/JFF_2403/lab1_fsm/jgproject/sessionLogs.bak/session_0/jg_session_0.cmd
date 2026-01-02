# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.12
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2023.12 FCS 64 bits
# build date: 2023.12.19 17:39:24 UTC
# ----------------------------------------
# started   : 2024-01-19 17:21:54 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 265248
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:35753' '-style' 'windows' '-data' 'AAABaHicY2RgYLCp////PwMYMFcBCQEGHwZfhiAGVyDpzxAGpBkYDjCYMhgxWDAYMjgw5DHkM2QypDHkMKQyVDBYQWUM8MoUM2TBxQ1xyhjhlDHGYk8KQyJQNpMhGWgiwkxDHPJgwPgAQjPYMDKgAhCfCVUksAGFZmBghWlG1qQAdGMxQy5DPNjn8UB2KkMJQylDAYMekE4GugAEANB+Lz8=' '-proj' '/servers/esd_noida/amey/JGFF_2212/lab1_fsm/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/lab1_fsm/jgproject/.tmp/.initCmds.tcl' 'fsm_if_setup.tcl'
clear -all

analyze -sv09 fsm_if.v fsm_if_test.v
elaborate -top FSM_IF_TEST

clock clk
reset ~rst_n


visualize {1[*45]}
prove -bg -all
visualize -violation -property <embedded>::FSM_IF_TEST.U1.STATE_9_CHECK -new_window
include fsm_if_setup.tcl
prove -bg -all
visualize -violation -property <embedded>::FSM_IF_TEST.U1.STATE_5_CHECK -new_window

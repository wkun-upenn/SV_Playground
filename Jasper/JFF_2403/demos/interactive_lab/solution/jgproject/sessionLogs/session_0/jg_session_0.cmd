# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2024.03
# platform  : Linux 4.18.0-305.el8.x86_64
# version   : 2024.03 FCS 64 bits
# build date: 2024.03.27 15:42:27 UTC
# ----------------------------------------
# started   : 2024-03-28 11:10:28 IST
# hostname  : noivl-adahikar.cadence.com
# pid       : 1437160
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:45265' '-style' 'windows' '-data' 'AAAAjnicY2RgYLCp////PwMYMFcBCTYGfwY3IIQDxgdQhg0jAyoA8ZlQRQIbUGgGBlaYZmRNAgwlDKkMxUBSD4iTGXLAMgChAgtg' '-proj' '/servers/esd_noida/amey/JGFF_2212/demos/interactive_lab/solution/jgproject/sessionLogs/session_0' '-init' '-hidden' '/servers/esd_noida/amey/JGFF_2212/demos/interactive_lab/solution/jgproject/.tmp/.initCmds.tcl' 'test.tcl'
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
analyze -sv09  tags.sv

# Elaborate
elaborate

# Initialization
# Clock specification
# clock pin is called "clk"
# duty cycle is 1:1 by default
clock clk

# Define reset condition
# reset pin is called rst_n, active low
reset !rst_n

# Start the verification
prove -all

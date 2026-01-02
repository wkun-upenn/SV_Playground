#!/bin/sh

#Example Usage :-
# ./RUNME.sh
# Runs with SV seed default of 1

# ./RUNME.sh 3
# Runs with SV seed of 3

# ./RUNME.sh random
# Runs with random SV seed 

if [ $# -gt 0 ]; then
  #echo "First arg is $1"
  MY_SVSEED=$1;
else
  MY_SVSEED=1;
fi

#To find help for the xrun utility on the Linux command line: xrun -help
#To find a list of subjects about which one can get help: xrun -helpsubject
#To get help on assertion related irun switches specifically: xrun -helpsubject abv
#To get the searchable help GUI : cdnshelp&

#INDAGO_SWITCH=""
INDAGO_SWITCH="-indago"

if [ `command -v xmroot` ] ; then 
   command_prefix="xm";
   sim_runner="xrun";
   path2_xcelium=`xmroot`;
   echo "Using Xcelium located in ${path2_xcelium}"
elif [ `command -v ncroot` ] ; then 
   command_prefix="nc";
   sim_runner="irun";
   path2_incisive=`ncroot`;
   echo "Using Incisive located in ${path2_incisive}";
else
   echo "Path to the Cadence Simulator not set in PATH";
fi
echo "${sim_runner} -64bit -SV -gui -access +rwc -svseed ${MY_SVSEED} -linedebug -abvrecordcoverall ${INDAGO_SWITCH} -input nc_input.tcl spi.sv spi_test.sv top.sv"
      ${sim_runner} -64bit -SV -gui -access +rwc -svseed ${MY_SVSEED} -linedebug -abvrecordcoverall ${INDAGO_SWITCH} -input nc_input.tcl \
      spi.sv spi_test.sv top.sv




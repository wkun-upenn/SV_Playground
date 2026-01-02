#!/bin/sh
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
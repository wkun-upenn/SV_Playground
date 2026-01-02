#!/bin/sh

#To find help for the xrun utility on the Linux command line: xrun -help
#To find a list of subjects about which one can get help: xrun -helpsubject
#To get help on assertion related irun switches specifically: xrun -helpsubject abv
#To get the searchable help GUI : cdnshelp&
#INDAGO_SWITCH="" #Leaving this string empty gets you Simvision rather than INDAGO
INDAGO_SWITCH="-indago"

#Xceluim switches to change assertion/cover behaviour
evalNoChange="-abvevalnochange";
#evalNoChange="";
rec_vacuous="-abvrecordvacuous";
#rec_vacuous="";
rec_all_covers="-abvrecordcoverall";
#rec_all_covers="";

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

echo "${sim_runner} -64bit -sv -gui -access +rwc -abvrecordcoverall ${INDAGO_SWITCH} -linedebug -input nc_input.tcl seqtest_asserted1.v"
      ${sim_runner} -64bit -sv -gui -access +rwc -abvrecordcoverall ${INDAGO_SWITCH} -linedebug -input nc_input.tcl seqtest_asserted1.v

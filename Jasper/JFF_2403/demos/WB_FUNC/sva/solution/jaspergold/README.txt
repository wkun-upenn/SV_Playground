RUNME.sh - 
   Runs with properties implemented shows one whitebox 
   property fail - assert_empty_ptr_wb - parameter FDEPTH = 55(its default)
RUNME16.sh - 
   Runs with properties implemented shows one assert_empty_ptr_wb now pass 
   with parameter FDEPTH =16 - If FDEPTH is a power of 2 then the bug is hidden
RUNSOL*.sh -
   Runs with properties implemented shows and FIFO RTL fixed so no  whitebox property fails - 
   parameter FDEPTH = 55(its default) hence there are still undetermined properties
   
The scripts with case insensitve name *_proofgrid* use proofgrid to run the proofs on multiple machines.
You are likely to have to change the name of the path and command used to send jobs to the farm in file
example_proofgrid_setup.tcl to whatever you use in your company 
Edit the file and change the command:
set_proofgrid_shell {<whatever your job dispatch command is>}
If you get it working then you can use that in all future labs.

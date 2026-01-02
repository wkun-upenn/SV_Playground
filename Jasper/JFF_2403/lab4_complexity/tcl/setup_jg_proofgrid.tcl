############################################################
# tool setup
############################################################
set_proofgrid_mode shell
#Note that the command below will only work on the Cadence SJ Farm. 
#You will have to use your own bsub command to dispatch the jobs, for example
#the PATH to bsub will probably be different, the OS's available, 
#the Project name (-P), the queue name (-q)
set_proofgrid_shell {/grid/sfi/farm/bin/bsub -q lnx64 -o /dev/null -K -P JG:2021.09:FAV:test -W 200:00 -n %jg_engine_job_threads -R "OSNAME==Linux && (OSREL==EE70 || OSREL==CN70) rusage[mem=16000] span[hosts=1]"}

set_proofgrid_per_engine_max_jobs        200
set_proofgrid_max_jobs                   200
set_proofgrid_per_engine_max_local_jobs  1
set_proofgrid_max_local_jobs             12
set_proofgrid_manager                    on
set_proofgrid_restarts                   1
set_log_timestamp_mode                   on
set_capture_elaborated_design            on
set_max_trace_length                     0
set_prove_verbosity                      9

set_message -ignore VERI-9005
set_message -ignore VERI-1208
set_message -ignore VERI-1209
set_message -ignore VERI-1142
set_message -ignore VERI-1875
set_message -ignore VERI-1060

set_message -disable WPM025
set_message -disable WNL023

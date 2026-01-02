set_proofgrid_mode shell; 
set_proofgrid_shell {/grid/sfi/farm/bin/bsub -I -q interactive -W 8:0 -n %jg_engine_job_threads \
                     -R "OSNAME==Linux && OSREL==EE60" \
                     -R "rusage[mem=8000]" -R "span[hosts=1]" }; 
set_proofgrid_per_engine_max_jobs 50; 
set_proofgrid_per_engine_privileged_jobs 10
set_proofgrid_socket_communication off

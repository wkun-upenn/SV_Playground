set_engine_threads 2
set_proofgrid_mode shell; 
set_proofgrid_shell {/grid/sfi/farm/bin/bsub -W 4:0 -I -q interactive -R "span[hosts=1] OSNAME==Linux && OSREL==EE70 rusage[mem=32000]" -n %jg_engine_job_threads}; 
set_proofgrid_max_jobs 7
set_proofgrid_per_engine_max_jobs 30;
set_proofgrid_per_engine_privileged_jobs 5
set_proofgrid_socket_communication off

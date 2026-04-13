create_library_set -name default_library_set -timing {/home/atreya/DSG/BSTA/bsta_labs/work/../libs/liberty//slow.lib /home/atreya/DSG/BSTA/bsta_labs/work/../libs/liberty//wireload.lib}
create_rc_corner -name _default_rc_corner_ -T 125.0 -cap_table /home/atreya/DSG/BSTA/bsta_labs/work/../libs/NCSU_FreePDK_45nm.capTbl
create_delay_corner -name _default_delay_corner_ -library_set default_library_set -opcond slow  -opcond_library slow -rc_corner _default_rc_corner_

create_constraint_mode -name _default_constraint_mode_ -sdc_files {DESIGN/top._default_constraint_mode_.sdc}
 
create_analysis_view -name _default_view_  -constraint_mode _default_constraint_mode_ -delay_corner _default_delay_corner_
 
 
set_analysis_view -setup _default_view_  -hold _default_view_
 

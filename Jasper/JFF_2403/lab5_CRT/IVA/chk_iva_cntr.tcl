clear -all

analyze -sv12 counter.vs

elaborate -top counter

set iva 0

if {$iva} {
#ADD Abstract tcl command here for iniial value abstraction.
#identify the counter and add IVA useing abstract init_value command

abstract -init_value <counter name>

}

set_prove_time_limit 5m

clock clk
reset ~rst_n

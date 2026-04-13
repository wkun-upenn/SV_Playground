################################################################################
#
# Genus(TM) Synthesis Solution setup file
# Created by Genus(TM) Synthesis Solution 20.10-d724_1
#   on 07/26/2020 05:17:19
#
#
################################################################################


# This script is intended for use with Genus(TM) Synthesis Solution version 20.10-d724_1


# Remove Existing Design
################################################################################
if {[::legacy::find -design /designs/top] ne ""} {
  puts "** A design with the same name is already loaded. It will be removed. **"
  delete_obj /designs/top
}


# To allow user-readonly attributes
################################################################################
::legacy::set_attribute -quiet force_tui_is_remote 1 /


# Libraries
################################################################################
::legacy::set_attribute library {/home/atreya/DSG/BSTA/bsta_labs/work/../libs/liberty//slow.lib /home/atreya/DSG/BSTA/bsta_labs/work/../libs/liberty//wireload.lib} /
::legacy::set_attribute cap_table_file /home/atreya/DSG/BSTA/bsta_labs/work/../libs/NCSU_FreePDK_45nm.capTbl /


# Design
################################################################################
read_netlist -top top DESIGN/top.v
read_metric -id current DESIGN/top.metrics.json

phys::read_script DESIGN/top.g
puts "\n** Restoration Completed **\n"


# Data Integrity Check
################################################################################
# program version
if {"[string_representation [::legacy::get_attribute program_version /]]" != "20.10-d724_1"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-91] "golden program_version: 20.10-d724_1  current program_version: [string_representation [::legacy::get_attribute program_version /]]"
}
# license
if {"[string_representation [::legacy::get_attribute startup_license /]]" != "Genus_Synthesis"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-91] "golden license: Genus_Synthesis  current license: [string_representation [::legacy::get_attribute startup_license /]]"
}
# slack
set _slk_ [::legacy::get_attribute slack /designs/top]
if {[regexp {^-?[0-9.]+$} $_slk_]} {
  set _slk_ [format %.1f $_slk_]
}
if {$_slk_ != "0.0"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-92] "golden slack: 0.0,  current slack: $_slk_"
}
unset _slk_
# multi-mode slack
# tns
set _tns_ [::legacy::get_attribute tns /designs/top]
if {[regexp {^-?[0-9.]+$} $_tns_]} {
  set _tns_ [format %.0f $_tns_]
}
if {$_tns_ != "0"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-92] "golden tns: 0,  current tns: $_tns_"
}
unset _tns_
# cell area
set _cell_area_ [::legacy::get_attribute cell_area /designs/top]
if {[regexp {^-?[0-9.]+$} $_cell_area_]} {
  set _cell_area_ [format %.0f $_cell_area_]
}
if {$_cell_area_ != "55710"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-92] "golden cell area: 55710,  current cell area: $_cell_area_"
}
unset _cell_area_
# net area
set _net_area_ [::legacy::get_attribute net_area /designs/top]
if {[regexp {^-?[0-9.]+$} $_net_area_]} {
  set _net_area_ [format %.0f $_net_area_]
}
if {$_net_area_ != "45"} {
   mesg_send [::legacy::find -message /messages/PHYS/PHYS-92] "golden net area: 45,  current net area: $_net_area_"
}
unset _net_area_

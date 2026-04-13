set SYN_SRC_DIR . 
set SYN_LIB_DIR {../libs/liberty/ ../libs/MACRO/LIBERTY/ ../libs/lef ../libs/MACRO/LEF}
set CAPFILE ../libs/NCSU_FreePDK_45nm.capTbl
set SCRIPTS_PATH .
set UNIT_NAME top

set_attr init_lib_phys_consistency_checks false /
set_attr lib_search_path "$SYN_LIB_DIR" /
set_attr init_hdl_search_path ./rtl
set_attr library {slow.lib wireload.lib}
#set_attr library {FreePDK45_lib_v1.3_slow.lib slow.lib wireload.lib pllclk.lib ram_256x16A.lib rom_512x16A.lib} /
#set_attr lef_library { FreePDK45_lib_v1.0.lef pllclk.lef ram_256X16A.lef rom_512x16A.lef} /
set_attribute cap_table_file $CAPFILE /
set_attr interconnect_mode wireload /
set_attr wireload_mode top /
echo ""
echo "############################################################"
echo "#        Reading and Elaborating Design $UNIT_NAME"
echo "############################################################"
echo ""

# Read verilog here
include filelist.tcl 
load $vfile
load rtl/macros.v
elaborate $UNIT_NAME;
    
echo "Finished elaborating "
timestat

echo ""
echo "############################################################"
echo "#        Applying Synthesis Constraints"
echo "############################################################"
echo ""

echo "#INFO: Sourcing Constraints";
read_sdc solutions/constraints.sdc

report timing -lint 

echo ""
echo "#############################################################"
echo "#        Synthesizing Design"
echo "#############################################################"
echo ""
syn_generic
syn_map
syn_opt

report timing
write_design -innovus -basename DESIGN/top top

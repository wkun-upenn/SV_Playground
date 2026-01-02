#abvip -set_location /grid/avs/install/vipcat/11.3/latest/tools.lnx86/abvip
abvip -set_location $env(ABVIP_INST_DIR)

analyze -sv09 \
   ./local_pp/rtl/pp_cfg.v \
   ./local_pp/rtl/pp_cg.v \
   ./local_pp/rtl/pp_drop_ctrl.v \
   ./local_pp/rtl/pp_fifo.v \
   ./local_pp/rtl/pp_ig_parse.v \
   ./local_pp/rtl/pp_intr.v \
   ./local_pp/rtl/pp_list_ctrl.v \
   ./local_pp/rtl/pp_mem_2r2w.v \
   ./local_pp/rtl/pp_payload_mem.v \
   ./local_pp/rtl/pp_route_ctrl.v \
   ./local_pp/rtl/pp_stall.v \
   ./local_pp/rtl/pp_sync_pulse.v \
   ./local_pp/rtl/pp_sync.v \
   ./local_pp/rtl/pp_thr_mem.v \
   ./local_pp/rtl/pp.v \

analyze -sv09 \
   +incdir+./local_pp/formal_verif/tb/env \
   +incdir+./local_pp/rtl \
   ./local_pp/formal_verif/tb/env/fv_adapter.sv \
   ./local_pp/formal_verif/tb/env/fv_bind.sv \
   ./local_pp/formal_verif/tb/env/fv_env.sv \
   ./local_pp/formal_verif/tb/env/fv_pkg.sv \

analyze -sv09 \
   +incdir+./local_pp/formal_verif/tb/env \
   +incdir+./local_pp/rtl \
   ./local_pp/formal_verif/tb/components/agents/apb_agent/src/apb_agent.sv \
   ./local_pp/formal_verif/tb/components/agents/apb_agent/src/apb_port_intf.sv \
   ./local_pp/formal_verif/tb/components/agents/eg_agent/src/eg_agent.sv \
   ./local_pp/formal_verif/tb/components/agents/eg_agent/src/eg_port_intf.sv \
   ./local_pp/formal_verif/tb/components/agents/ig_agent/src/ig_agent.sv \
   ./local_pp/formal_verif/tb/components/agents/ig_agent/src/ig_port_intf.sv \
   ./local_pp/formal_verif/tb/components/agents/intr_agent/src/intr_agent.sv \
   ./local_pp/formal_verif/tb/components/agents/intr_agent/src/intr_check.sv \
   ./local_pp/formal_verif/tb/components/agents/intr_agent/src/intr_port_intf.sv \
   ./local_pp/formal_verif/tb/components/agents/route_agent/src/route_agent.sv \
   ./local_pp/formal_verif/tb/components/agents/route_agent/src/route_port_intf.sv \

analyze -sv09 \
   +incdir+./local_pp/formal_verif/tb/env \
   +incdir+./local_pp/rtl \
   ./local_pp/formal_verif/tb/components/env_interfaces/apb_txn_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/cfg_probe_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/fl_probe_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/header_txn_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/intr_txn_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/level_trk_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/packet_txn_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/payload_txn_intf.sv \
   ./local_pp/formal_verif/tb/components/env_interfaces/resp_txn_intf.sv \

analyze -sv09 \
   +incdir+./local_pp/formal_verif/tb/env \
   +incdir+./local_pp/rtl \
   ./local_pp/formal_verif/tb/components/checkers/cfg_chk.sv \
   ./local_pp/formal_verif/tb/components/checkers/fl_chk.sv \
   ./local_pp/formal_verif/tb/components/checkers/ig_eg_sb.sv \
   ./local_pp/formal_verif/tb/components/checkers/ig_route_sb.sv \
   ./local_pp/formal_verif/tb/components/checkers/init_chk.sv \
   ./local_pp/formal_verif/tb/components/checkers/level_chk.sv \

analyze -sv09 \
   +incdir+./local_pp/formal_verif/tb/env \
   +incdir+./local_pp/rtl \
   ./local_pp/formal_verif/tb/components/abstractions/jasper_fifo.sv \
   ./local_pp/formal_verif/tb/components/abstractions/tag_abs.sv \
   ./local_pp/formal_verif/tb/components/coverage/covers.sv \

elaborate -top pp \
   -no_preconditions \
   -parameter DATA_MEM_SIZE    128 \
   -parameter DATA_W           32 \
   -parameter NUM_THR          8 \
   -parameter PROC_FIFO_DEPTH  8 \

clock clk
clock PCLK
reset ~rstn ~PRESETn
reset -sequence ./local_pp/formal_verif/tcl/shared/init/list_thr_init.seq


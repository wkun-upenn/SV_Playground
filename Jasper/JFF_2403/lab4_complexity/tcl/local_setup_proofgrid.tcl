
set DATA_MEM_SIZE 8
set MAX_PKT_LEN   6

assume -from_assert pp.fv_env.ig_agent.AST_M_*  -remove_original
assume -from_assert pp.fv_env.eg_agent.AST_M_*  -remove_original
assume -from_assert pp.fv_env.route_agent.AST_S_* -remove_original

stopat cfg.cfg_list_init
stopat cfg.cfg_thr_init
assume -name CFG_no_list_init !cfg.cfg_list_init
assume -name CFG_no_thr_init !cfg.cfg_thr_init

# Register setup
# CONFIG_ABS=1: stopat/assume-constant on all registers
# CONFIG_ABS=0: let them be driven through APB interface
stopat cfg.cfg_thr_almost_full_level
stopat cfg.cfg_thr_almost_empty_level
stopat cfg.cfg_list_almost_full_level
stopat cfg.cfg_list_almost_empty_level
stopat cfg.cfg_header_length
stopat cfg.cfg_header_filter
stopat cfg.cfg_checksum_filter
stopat cfg.cfg_checksum_enable
stopat cfg.cfg_checksum_drop
stopat cfg.cfg_auto_drop
stopat cfg.cfg_auto_assign_thr
stopat cfg.cfg_auto_assign
assume -constant cfg.cfg_thr_almost_full_level -name cfg_thr_almost_full_level
assume -constant cfg.cfg_thr_almost_empty_level -name cfg_thr_almost_empty_level
assume -constant cfg.cfg_list_almost_full_level -name cfg_list_almost_full_level
assume -constant cfg.cfg_list_almost_empty_level -name cfg_list_almost_empty_level
assume {##1 $changed({cfg.cfg_thr_almost_full_level, \
                      cfg.cfg_thr_almost_empty_level, \
                      cfg.cfg_list_almost_full_level, \
                      cfg.cfg_list_almost_empty_level, \
                      cfg.cfg_header_length, \
                      cfg.cfg_header_filter, \
                      cfg.cfg_checksum_filter, \
                      cfg.cfg_checksum_enable, \
                      cfg.cfg_checksum_drop, \
                      cfg.cfg_auto_drop, \
                      cfg.cfg_auto_assign_thr, \
                      cfg.cfg_auto_assign}) |-> !ig_valid[*3]} -name no_pkt_during_cfg_change
assume {ig_valid |-> $stable({cfg.cfg_thr_almost_full_level, \
                              cfg.cfg_thr_almost_empty_level, \
                              cfg.cfg_list_almost_full_level, \
                              cfg.cfg_list_almost_empty_level, \
                              cfg.cfg_header_length, \
                              cfg.cfg_header_filter, \
                              cfg.cfg_checksum_filter, \
                              cfg.cfg_checksum_enable, \
                              cfg.cfg_checksum_drop, \
                              cfg.cfg_auto_drop, \
                              cfg.cfg_auto_assign_thr, \
                              cfg.cfg_auto_assign})[*3]} -name no_cfg_change_during_pkt
assume {fv_env.level_chk.level_nx.total_pkts > 0 |-> $stable({cfg.cfg_thr_almost_full_level, \
                                                              cfg.cfg_thr_almost_empty_level, \
                                                              cfg.cfg_list_almost_full_level, \
                                                              cfg.cfg_list_almost_empty_level, \
                                                              cfg.cfg_header_length, \
                                                              cfg.cfg_header_filter, \
                                                              cfg.cfg_checksum_filter, \
                                                              cfg.cfg_checksum_enable, \
                                                              cfg.cfg_checksum_drop, \
                                                              cfg.cfg_auto_drop, \
                                                              cfg.cfg_auto_assign_thr, \
                                                              cfg.cfg_auto_assign})} -name no_cfg_change_if_pkt
assume {cfg_auto_assign |-> fv_env.ig_packet_txn.tag_thr == cfg_auto_assign_thr} -name auto_assign_consistency
assume {cfg_list_almost_full_level > 0} -name list_almost_full_not_zero
assume {cfg_list_almost_empty_level < 4'b1111} -name list_almost_empty_not_full_level
assume {cfg_thr_almost_full_level > 0} -name thr_almost_full_not_zero
assume {cfg_thr_almost_empty_level < 4'b1111} -name thr_almost_empty_not_full_level

assume -from_assert pp.fv_env.cfg_chk.AST_config_*_valid -remove_original
assume -from_assert pp.fv_env.cfg_chk.AST_init_* -remove_original

assert -disable pp.fv_env.cfg_chk.AST_no_config_change_probe
assert -disable pp.fv_env.cfg_chk.AST_no_config_change_apb



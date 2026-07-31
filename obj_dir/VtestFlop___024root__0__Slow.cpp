// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VtestFlop.h for the primary calling header

#include "VtestFlop__pch.h"

void VtestFlop___024root___timing_ready(VtestFlop___024root* vlSelf);

VL_ATTR_COLD void VtestFlop___024root___eval_static(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_static\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__epoch = 0U;
    ++(vlSymsp->__Vcoverage[40]);
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13822351475444763873ull);
    vlSelfRef.testFlop__DOT__cb__DOT__qin = vlSelfRef.testFlop__DOT__qin;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin 
        = vlSelfRef.testFlop__DOT__cb__DOT__qin;
    vlSelfRef.testFlop__DOT__cb__DOT__reset = vlSelfRef.testFlop__DOT__reset;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset 
        = vlSelfRef.testFlop__DOT__cb__DOT__reset;
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0 
        = vlSelfRef.testFlop__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__reset__0 
        = vlSelfRef.testFlop__DOT__reset;
    VtestFlop___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void VtestFlop___024root___eval_static__TOP(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_static__TOP\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__epoch = 0U;
    ++(vlSymsp->__Vcoverage[40]);
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13822351475444763873ull);
    vlSelfRef.testFlop__DOT__cb__DOT__qin = vlSelfRef.testFlop__DOT__qin;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin 
        = vlSelfRef.testFlop__DOT__cb__DOT__qin;
    vlSelfRef.testFlop__DOT__cb__DOT__reset = vlSelfRef.testFlop__DOT__reset;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset 
        = vlSelfRef.testFlop__DOT__cb__DOT__reset;
}

VL_ATTR_COLD void VtestFlop___024root___eval_initial__TOP(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_initial__TOP\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__clk = 0U;
    ++(vlSymsp->__Vcoverage[41]);
}

VL_ATTR_COLD void VtestFlop___024root___eval_final(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_final\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VtestFlop___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool VtestFlop___024root___eval_phase__stl(VtestFlop___024root* vlSelf);

VL_ATTR_COLD void VtestFlop___024root___eval_settle(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_settle\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            VtestFlop___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("EDAPlayground/ClockingBlock/testbench.sv", 6, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = VtestFlop___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void VtestFlop___024root___eval_triggers_vec__stl(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_triggers_vec__stl\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool VtestFlop___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void VtestFlop___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(VtestFlop___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool VtestFlop___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___trigger_anySet__stl\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

VL_ATTR_COLD void VtestFlop___024root___stl_sequent__TOP__0(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___stl_sequent__TOP__0\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.push(VL_TIME_UNITED_Q(1000), (IData)(vlSelfRef.testFlop__DOT__qout));
    if (((IData)(vlSelfRef.testFlop__DOT__clk) ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__clk))) {
        VL_COV_TOGGLE_CHG_ST_I(1, vlSymsp->__Vcoverage + 0, vlSelfRef.testFlop__DOT__clk, vlSelfRef.testFlop__DOT____Vtogcov__clk);
        vlSelfRef.testFlop__DOT____Vtogcov__clk = vlSelfRef.testFlop__DOT__clk;
    }
    if (((IData)(vlSelfRef.testFlop__DOT__reset) ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__reset))) {
        VL_COV_TOGGLE_CHG_ST_I(1, vlSymsp->__Vcoverage + 2, vlSelfRef.testFlop__DOT__reset, vlSelfRef.testFlop__DOT____Vtogcov__reset);
        vlSelfRef.testFlop__DOT____Vtogcov__reset = vlSelfRef.testFlop__DOT__reset;
    }
    if (((IData)(vlSelfRef.testFlop__DOT__qin) ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__qin))) {
        VL_COV_TOGGLE_CHG_ST_I(8, vlSymsp->__Vcoverage + 4, vlSelfRef.testFlop__DOT__qin, vlSelfRef.testFlop__DOT____Vtogcov__qin);
        vlSelfRef.testFlop__DOT____Vtogcov__qin = vlSelfRef.testFlop__DOT__qin;
    }
    if (((IData)(vlSelfRef.testFlop__DOT__qout) ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__qout))) {
        VL_COV_TOGGLE_CHG_ST_I(8, vlSymsp->__Vcoverage + 20, vlSelfRef.testFlop__DOT__qout, vlSelfRef.testFlop__DOT____Vtogcov__qout);
        vlSelfRef.testFlop__DOT____Vtogcov__qout = vlSelfRef.testFlop__DOT__qout;
    }
    if (((IData)(vlSelfRef.testFlop__DOT__epoch) ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__epoch))) {
        VL_COV_TOGGLE_CHG_ST_I(2, vlSymsp->__Vcoverage + 36, vlSelfRef.testFlop__DOT__epoch, vlSelfRef.testFlop__DOT____Vtogcov__epoch);
        vlSelfRef.testFlop__DOT____Vtogcov__epoch = vlSelfRef.testFlop__DOT__epoch;
    }
}

VL_ATTR_COLD void VtestFlop___024root___eval_stl(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_stl\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.push(VL_TIME_UNITED_Q(1000), (IData)(vlSelfRef.testFlop__DOT__qout));
        if (((IData)(vlSelfRef.testFlop__DOT__clk) 
             ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__clk))) {
            VL_COV_TOGGLE_CHG_ST_I(1, vlSymsp->__Vcoverage + 0, vlSelfRef.testFlop__DOT__clk, vlSelfRef.testFlop__DOT____Vtogcov__clk);
            vlSelfRef.testFlop__DOT____Vtogcov__clk 
                = vlSelfRef.testFlop__DOT__clk;
        }
        if (((IData)(vlSelfRef.testFlop__DOT__reset) 
             ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__reset))) {
            VL_COV_TOGGLE_CHG_ST_I(1, vlSymsp->__Vcoverage + 2, vlSelfRef.testFlop__DOT__reset, vlSelfRef.testFlop__DOT____Vtogcov__reset);
            vlSelfRef.testFlop__DOT____Vtogcov__reset 
                = vlSelfRef.testFlop__DOT__reset;
        }
        if (((IData)(vlSelfRef.testFlop__DOT__qin) 
             ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__qin))) {
            VL_COV_TOGGLE_CHG_ST_I(8, vlSymsp->__Vcoverage + 4, vlSelfRef.testFlop__DOT__qin, vlSelfRef.testFlop__DOT____Vtogcov__qin);
            vlSelfRef.testFlop__DOT____Vtogcov__qin 
                = vlSelfRef.testFlop__DOT__qin;
        }
        if (((IData)(vlSelfRef.testFlop__DOT__qout) 
             ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__qout))) {
            VL_COV_TOGGLE_CHG_ST_I(8, vlSymsp->__Vcoverage + 20, vlSelfRef.testFlop__DOT__qout, vlSelfRef.testFlop__DOT____Vtogcov__qout);
            vlSelfRef.testFlop__DOT____Vtogcov__qout 
                = vlSelfRef.testFlop__DOT__qout;
        }
        if (((IData)(vlSelfRef.testFlop__DOT__epoch) 
             ^ (IData)(vlSelfRef.testFlop__DOT____Vtogcov__epoch))) {
            VL_COV_TOGGLE_CHG_ST_I(2, vlSymsp->__Vcoverage + 36, vlSelfRef.testFlop__DOT__epoch, vlSelfRef.testFlop__DOT____Vtogcov__epoch);
            vlSelfRef.testFlop__DOT____Vtogcov__epoch 
                = vlSelfRef.testFlop__DOT__epoch;
        }
    }
}

VL_ATTR_COLD bool VtestFlop___024root___eval_phase__stl(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___eval_phase__stl\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    VtestFlop___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VtestFlop___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = VtestFlop___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        VtestFlop___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool VtestFlop___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void VtestFlop___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(VtestFlop___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge testFlop.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(posedge testFlop.reset)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VtestFlop___024root___ctor_var_reset(VtestFlop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___ctor_var_reset\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10450945346801951520ull);
    vlSelf->testFlop__DOT__reset = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1381377954774023105ull);
    vlSelf->testFlop__DOT__qin = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 718940020333752467ull);
    vlSelf->testFlop__DOT__qout = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 1177542028494118449ull);
    vlSelf->testFlop__DOT__cb__DOT__reset = 0;
    vlSelf->testFlop__DOT__cb__DOT__qin = 0;
    vlSelf->testFlop__DOT__cb__DOT__qout = 0;
    vlSelf->testFlop__DOT____Vtogcov__clk = 0;
    vlSelf->testFlop__DOT____Vtogcov__reset = 0;
    vlSelf->testFlop__DOT____Vtogcov__qin = 0;
    vlSelf->testFlop__DOT____Vtogcov__qout = 0;
    vlSelf->testFlop__DOT____Vtogcov__epoch = 0;
    vlSelf->testFlop__DOT____Vclocking_prev__cb__DOT__qin = 0;
    vlSelf->testFlop__DOT____Vclocking_prev__cb__DOT__reset = 0;
    vlSelf->__Vintraval_hdff0b277__0 = 0;
    vlSelf->__Vintraval_haeaa0120__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__testFlop__DOT__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__testFlop__DOT__reset__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VobsTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}

VL_ATTR_COLD void VtestFlop___024root___configure_coverage(VtestFlop___024root* vlSelf, bool first) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VtestFlop___024root___configure_coverage\n"); );
    VtestFlop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    (void)first;  // Prevent unused variable warning
    vlSelf->__vlCoverToggleInsert(0, 0, 0, &(vlSymsp->__Vcoverage[0]), first, "EDAPlayground/ClockingBlock/testbench.sv", 8, 9, ".testFlop", "v_toggle/testFlop", "clk");
    vlSelf->__vlCoverToggleInsert(0, 0, 0, &(vlSymsp->__Vcoverage[2]), first, "EDAPlayground/ClockingBlock/testbench.sv", 8, 14, ".testFlop", "v_toggle/testFlop", "reset");
    vlSelf->__vlCoverToggleInsert(0, 7, 1, &(vlSymsp->__Vcoverage[4]), first, "EDAPlayground/ClockingBlock/testbench.sv", 9, 15, ".testFlop", "v_toggle/testFlop", "qin");
    vlSelf->__vlCoverToggleInsert(0, 7, 1, &(vlSymsp->__Vcoverage[20]), first, "EDAPlayground/ClockingBlock/testbench.sv", 9, 20, ".testFlop", "v_toggle/testFlop", "qout");
    vlSelf->__vlCoverToggleInsert(0, 1, 1, &(vlSymsp->__Vcoverage[36]), first, "EDAPlayground/ClockingBlock/testbench.sv", 10, 15, ".testFlop", "v_toggle/testFlop", "epoch");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[40]), first, "EDAPlayground/ClockingBlock/testbench.sv", 10, 23, ".testFlop", "v_line/testFlop", "block", "10");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[41]), first, "EDAPlayground/ClockingBlock/testbench.sv", 12, 3, ".testFlop", "v_line/testFlop", "block", "12");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[42]), first, "EDAPlayground/ClockingBlock/testbench.sv", 13, 24, ".testFlop", "v_expr/testFlop", "(clk==0) => 1", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[43]), first, "EDAPlayground/ClockingBlock/testbench.sv", 13, 24, ".testFlop", "v_expr/testFlop", "(clk==1) => 0", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[44]), first, "EDAPlayground/ClockingBlock/testbench.sv", 13, 3, ".testFlop", "v_line/testFlop", "block", "13");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[45]), first, "EDAPlayground/ClockingBlock/testbench.sv", 49, 7, ".testFlop", "v_line/testFlop", "block", "49-51,53-55");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[46]), first, "EDAPlayground/ClockingBlock/testbench.sv", 47, 5, ".testFlop", "v_line/testFlop", "block", "47-49,57");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[47]), first, "EDAPlayground/ClockingBlock/testbench.sv", 40, 3, ".testFlop", "v_line/testFlop", "block", "40,42-45,47,60-61");
    vlSelf->__vlCoverToggleInsert(0, 0, 0, &(vlSymsp->__Vcoverage[0]), first, "EDAPlayground/ClockingBlock/design.sv", 4, 30, ".testFlop.DUV", "v_toggle/flipflop", "clk");
    vlSelf->__vlCoverToggleInsert(0, 0, 0, &(vlSymsp->__Vcoverage[2]), first, "EDAPlayground/ClockingBlock/design.sv", 4, 35, ".testFlop.DUV", "v_toggle/flipflop", "reset");
    vlSelf->__vlCoverToggleInsert(0, 7, 1, &(vlSymsp->__Vcoverage[4]), first, "EDAPlayground/ClockingBlock/design.sv", 5, 36, ".testFlop.DUV", "v_toggle/flipflop", "qin");
    vlSelf->__vlCoverToggleInsert(0, 7, 1, &(vlSymsp->__Vcoverage[20]), first, "EDAPlayground/ClockingBlock/design.sv", 6, 37, ".testFlop.DUV", "v_toggle/flipflop", "qout");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[48]), first, "EDAPlayground/ClockingBlock/design.sv", 11, 3, ".testFlop.DUV", "v_branch/flipflop", "if", "11-12");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[49]), first, "EDAPlayground/ClockingBlock/design.sv", 11, 4, ".testFlop.DUV", "v_branch/flipflop", "else", "14");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[50]), first, "EDAPlayground/ClockingBlock/design.sv", 10, 1, ".testFlop.DUV", "v_line/flipflop", "block", "10");
}

// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdesign.h for the primary calling header

#include "Vdesign__pch.h"

void Vdesign___024root___timing_ready(Vdesign___024root* vlSelf);

VL_ATTR_COLD void Vdesign___024root___eval_static(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_static\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__clk = 0U;
    vlSelfRef.testFlop__DOT__epoch = 0U;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13822351475444763873ull);
    vlSelfRef.testFlop__DOT__cb__DOT__qin = vlSelfRef.testFlop__DOT__qin;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin 
        = vlSelfRef.testFlop__DOT__cb__DOT__qin;
    vlSelfRef.testFlop__DOT__cb__DOT__reset = vlSelfRef.testFlop__DOT__reset;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset 
        = vlSelfRef.testFlop__DOT__cb__DOT__reset;
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__reset__0 
        = vlSelfRef.testFlop__DOT__reset;
    Vdesign___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vdesign___024root___eval_static__TOP(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_static__TOP\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__clk = 0U;
    vlSelfRef.testFlop__DOT__epoch = 0U;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13822351475444763873ull);
    vlSelfRef.testFlop__DOT__cb__DOT__qin = vlSelfRef.testFlop__DOT__qin;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin 
        = vlSelfRef.testFlop__DOT__cb__DOT__qin;
    vlSelfRef.testFlop__DOT__cb__DOT__reset = vlSelfRef.testFlop__DOT__reset;
    vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset 
        = vlSelfRef.testFlop__DOT__cb__DOT__reset;
}

VL_ATTR_COLD void Vdesign___024root___eval_final(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_final\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdesign___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vdesign___024root___eval_phase__stl(Vdesign___024root* vlSelf);

VL_ATTR_COLD void Vdesign___024root___eval_settle(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_settle\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vdesign___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vdesign___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vdesign___024root___eval_triggers_vec__stl(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_triggers_vec__stl\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vdesign___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdesign___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vdesign___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vdesign___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vdesign___024root___eval_stl(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_stl\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.push(VL_TIME_UNITED_Q(1000), (IData)(vlSelfRef.testFlop__DOT__qout));
    }
}

VL_ATTR_COLD bool Vdesign___024root___eval_phase__stl(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_phase__stl\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vdesign___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vdesign___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vdesign___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vdesign___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vdesign___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdesign___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vdesign___024root___trigger_anySet__act(triggers))))) {
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

VL_ATTR_COLD void Vdesign___024root___ctor_var_reset(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___ctor_var_reset\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->testFlop__DOT__reset = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1381377954774023105ull);
    vlSelf->testFlop__DOT__qin = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 718940020333752467ull);
    vlSelf->testFlop__DOT__qout = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 1177542028494118449ull);
    vlSelf->testFlop__DOT__cb__DOT__reset = 0;
    vlSelf->testFlop__DOT__cb__DOT__qin = 0;
    vlSelf->testFlop__DOT__cb__DOT__qout = 0;
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

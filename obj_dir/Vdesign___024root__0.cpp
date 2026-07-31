// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdesign.h for the primary calling header

#include "Vdesign__pch.h"

VlCoroutine Vdesign___024root___eval_initial__TOP__Vtiming__0(Vdesign___024root* vlSelf);
VlCoroutine Vdesign___024root___eval_initial__TOP__Vtiming__1(Vdesign___024root* vlSelf);

void Vdesign___024root___eval_initial(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_initial\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vdesign___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vdesign___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

void Vdesign___024root____VbeforeTrig_ha27a8090__0(Vdesign___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vdesign___024root___eval_initial__TOP__Vtiming__0(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter;
    testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter = 0;
    IData/*31:0*/ testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0;
    testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter;
    testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter = 0;
    CData/*7:0*/ __Vtask_testFlop__DOT__expect_out__0__exp_i;
    __Vtask_testFlop__DOT__expect_out__0__exp_i = 0;
    // Body
    vlSelfRef.testFlop__DOT__cb__DOT__qin = 0U;
    vlSelfRef.testFlop__DOT__cb__DOT__reset = 1U;
    testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter = 2ULL;
    while ((0U < testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter)) {
        Vdesign___024root____VbeforeTrig_ha27a8090__0(vlSelf, 
                                                      "@(posedge testFlop.clk)");
        co_await vlSelfRef.__VtrigSched_ha27a8090__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge testFlop.clk)", 
                                                             "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                                             38);
        testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter 
            = (testFlop__DOT____VcycleDly_h9e377b43__0__block__DOT____VcycleDly_h9e377b43__0__counter 
               - (IData)(1U));
    }
    vlSelfRef.testFlop__DOT__cb__DOT__reset = 0U;
    vlSelfRef.testFlop__DOT__epoch = 0U;
    while ((3U > (IData)(vlSelfRef.testFlop__DOT__epoch))) {
        VL_WRITEF_NX("Starting test epoch %1#\n",0,
                     2,vlSelfRef.testFlop__DOT__epoch);
        testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0 = 5U;
        while (VL_LTS_III(32, 0U, testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
            vlSelfRef.testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num 
                = (0x000000ffU & VL_RANDOM_I());
            vlSelfRef.testFlop__DOT__cb__DOT__qin = vlSelfRef.testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num;
            testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter = 2ULL;
            while ((0U < testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter)) {
                Vdesign___024root____VbeforeTrig_ha27a8090__0(vlSelf, 
                                                              "@(posedge testFlop.clk)");
                co_await vlSelfRef.__VtrigSched_ha27a8090__0.trigger(0U, 
                                                                     nullptr, 
                                                                     "@(posedge testFlop.clk)", 
                                                                     "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                                                     48);
                testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter 
                    = (testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT____VcycleDly_h9e377b43__1__block__DOT____VcycleDly_h9e377b43__1__counter 
                       - (IData)(1U));
            }
            __Vtask_testFlop__DOT__expect_out__0__exp_i 
                = vlSelfRef.testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num;
            if (vlSymsp->_vm_contextp__->assertOnGet(2, 1)) {
                if (VL_LIKELY((((IData)(vlSelfRef.testFlop__DOT__cb__DOT__qout) 
                                == (IData)(__Vtask_testFlop__DOT__expect_out__0__exp_i))))) {
                    VL_WRITEF_NX("[PASS]Assertion successful at %^ns: qout=%x, qin == %x\n",0,
                                 64,(1.00000000000000002e-03 
                                     * (QData)(VL_ITOR_D_Q(64, VL_TIME_UNITED_Q(1000)))),
                                 -9,8,(IData)(vlSelfRef.testFlop__DOT__cb__DOT__qout),
                                 8,vlSelfRef.testFlop__DOT__qin);
                } else {
                    VL_WRITEF_NX("[%0t] %%Fatal: testbench.sv:25: Assertion failed in %NtestFlop.expect_out: [FAIL]Assertion failed at %^ns: qout=%x, qin == %x, expected %x\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,vlSymsp->name(),
                                 64,(1.00000000000000002e-03 
                                     * (QData)(VL_ITOR_D_Q(64, VL_TIME_UNITED_Q(1000)))),
                                 -9,8,(IData)(vlSelfRef.testFlop__DOT__cb__DOT__qout),
                                 8,vlSelfRef.testFlop__DOT__qin,
                                 8,(IData)(__Vtask_testFlop__DOT__expect_out__0__exp_i));
                    VL_STOP_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 25, "", false);
                }
            }
            testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0 
                = (testFlop__DOT__unnamedblk1_1__DOT____Vrepeat0 
                   - (IData)(1U));
        }
        VL_WRITEF_NX("Epoch %1# Finished Successfully\n",0,
                     2,vlSelfRef.testFlop__DOT__epoch);
        vlSelfRef.testFlop__DOT__epoch = (3U & ((IData)(1U) 
                                                + (IData)(vlSelfRef.testFlop__DOT__epoch)));
    }
    VL_WRITEF_NX("GRAND SUCCESS\n",0);
    VL_FINISH_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 55, "");
    co_return;
}

VlCoroutine Vdesign___024root___eval_initial__TOP__Vtiming__1(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                             11);
        vlSelfRef.testFlop__DOT__clk = (1U & (~ (IData)(vlSelfRef.testFlop__DOT__clk)));
    }
    co_return;
}

void Vdesign___024root___eval_triggers_vec__act(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_triggers_vec__act\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 2U) 
                                                     | ((((IData)(vlSelfRef.testFlop__DOT__reset) 
                                                          & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__reset__0))) 
                                                         << 1U) 
                                                        | ((IData)(vlSelfRef.testFlop__DOT__clk) 
                                                           & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0)))))));
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0 
        = vlSelfRef.testFlop__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__reset__0 
        = vlSelfRef.testFlop__DOT__reset;
}

bool Vdesign___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___trigger_anySet__act\n"); );
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

void Vdesign___024root___nba_sequent__TOP__0(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___nba_sequent__TOP__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT__qout = ((IData)(vlSelfRef.testFlop__DOT__reset)
                                      ? 0U : (IData)(vlSelfRef.testFlop__DOT__qin));
}

void Vdesign___024root___nba_sequent__TOP__1(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___nba_sequent__TOP__1\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.pop(VL_TIME_UNITED_Q(1000), 1U, vlSelfRef.testFlop__DOT__cb__DOT__qout);
}

void Vdesign___024root___nba_sequent__TOP__2(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___nba_sequent__TOP__2\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.push(VL_TIME_UNITED_Q(1000), (IData)(vlSelfRef.testFlop__DOT__qout));
}

void Vdesign___024root___eval_nba(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_nba\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.testFlop__DOT__qout = ((IData)(vlSelfRef.testFlop__DOT__reset)
                                          ? 0U : (IData)(vlSelfRef.testFlop__DOT__qin));
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.pop(VL_TIME_UNITED_Q(1000), 1U, vlSelfRef.testFlop__DOT__cb__DOT__qout);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.testFlop__DOT____Vqueue__cb__DOT__qout.push(VL_TIME_UNITED_Q(1000), (IData)(vlSelfRef.testFlop__DOT__qout));
    }
}

VlCoroutine Vdesign___024root___obs_sequent__TOP__0____Vfork_1__0(Vdesign___024root* vlSelf);
VlCoroutine Vdesign___024root___obs_sequent__TOP__0____Vfork_2__0(Vdesign___024root* vlSelf);

void Vdesign___024root___obs_sequent__TOP__0(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___obs_sequent__TOP__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vdesign___024root___obs_sequent__TOP__0____Vfork_1__0(vlSelf);
    Vdesign___024root___obs_sequent__TOP__0____Vfork_2__0(vlSelf);
}

VlCoroutine Vdesign___024root___obs_sequent__TOP__0____Vfork_2__0(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___obs_sequent__TOP__0____Vfork_2__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    co_await vlSelfRef.__VdlySched.delay(0xffffffffffffffffULL, 
                                         nullptr, "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                         18);
    if (((IData)(vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin) 
         != (IData)(vlSelfRef.testFlop__DOT__cb__DOT__qin))) {
        vlSelfRef.__Vintraval_haeaa0120__0 = vlSelfRef.testFlop__DOT__cb__DOT__qin;
        co_await vlSelfRef.__VdlySched.delay(0x0000000000000fa0ULL, 
                                             nullptr, 
                                             "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                             18);
        vlSelfRef.testFlop__DOT__qin = vlSelfRef.__Vintraval_haeaa0120__0;
        vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__qin 
            = vlSelfRef.testFlop__DOT__cb__DOT__qin;
    }
    co_return;
}

VlCoroutine Vdesign___024root___obs_sequent__TOP__0____Vfork_1__0(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___obs_sequent__TOP__0____Vfork_1__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    co_await vlSelfRef.__VdlySched.delay(0xffffffffffffffffULL, 
                                         nullptr, "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                         18);
    if (((IData)(vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset) 
         != (IData)(vlSelfRef.testFlop__DOT__cb__DOT__reset))) {
        vlSelfRef.__Vintraval_hdff0b277__0 = vlSelfRef.testFlop__DOT__cb__DOT__reset;
        co_await vlSelfRef.__VdlySched.delay(0x0000000000000fa0ULL, 
                                             nullptr, 
                                             "/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 
                                             18);
        vlSelfRef.testFlop__DOT__reset = vlSelfRef.__Vintraval_hdff0b277__0;
        vlSelfRef.testFlop__DOT____Vclocking_prev__cb__DOT__reset 
            = vlSelfRef.testFlop__DOT__cb__DOT__reset;
    }
    co_return;
}

void Vdesign___024root___eval_obs(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_obs\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VobsTriggered[0U])) {
        Vdesign___024root___obs_sequent__TOP__0____Vfork_1__0(vlSelf);
        Vdesign___024root___obs_sequent__TOP__0____Vfork_2__0(vlSelf);
    }
}

void Vdesign___024root___timing_ready(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___timing_ready\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_ha27a8090__0.ready("@(posedge testFlop.clk)");
    }
}

void Vdesign___024root___timing_resume(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___timing_resume\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_ha27a8090__0.moveToResumeQueue(
                                                          "@(posedge testFlop.clk)");
    vlSelfRef.__VtrigSched_ha27a8090__0.resume("@(posedge testFlop.clk)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vdesign___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdesign___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vdesign___024root___eval_phase__act(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_phase__act\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vdesign___024root___eval_triggers_vec__act(vlSelf);
    Vdesign___024root___timing_ready(vlSelf);
    Vdesign___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vdesign___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vdesign___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vdesign___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vdesign___024root___timing_resume(vlSelf);
    }
    return (__VactExecute);
}

bool Vdesign___024root___eval_phase__inact(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_phase__inact\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vdesign___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vdesign___024root___eval_phase__nba(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_phase__nba\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vdesign___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vdesign___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VobsTriggered, vlSelfRef.__VnbaTriggered);
        Vdesign___024root___eval_nba(vlSelf);
        Vdesign___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

bool Vdesign___024root___eval_phase__obs(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_phase__obs\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VobsExecute;
    // Body
    __VobsExecute = Vdesign___024root___trigger_anySet__act(vlSelfRef.__VobsTriggered);
    if (__VobsExecute) {
        Vdesign___024root___eval_obs(vlSelf);
        Vdesign___024root___trigger_clear__act(vlSelfRef.__VobsTriggered);
    }
    return (__VobsExecute);
}

void Vdesign___024root___eval(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VobsIterCount;
    // Body
    __VobsIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VobsIterCount)))) {
#ifdef VL_DEBUG
            Vdesign___024root___dump_triggers__act(vlSelfRef.__VobsTriggered, "obs"s);
#endif
            VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "DIDNOTCONVERGE: Observed region did not converge after '--converge-limit' of 100 tries");
        }
        __VobsIterCount = ((IData)(1U) + __VobsIterCount);
        vlSelfRef.__VnbaIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VnbaIterCount)))) {
#ifdef VL_DEBUG
                Vdesign___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
                VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VnbaIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VnbaIterCount);
            vlSelfRef.__VinactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                    VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                               + vlSelfRef.__VinactIterCount);
                vlSelfRef.__VactIterCount = 0U;
                do {
                    if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                        Vdesign___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                        VL_FATAL_MT("/Users/lymtics/Documents/SV-Playground/EDAPlayground/ClockingBlock/testbench.sv", 5, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                    }
                    vlSelfRef.__VactIterCount = ((IData)(1U) 
                                                 + vlSelfRef.__VactIterCount);
                    vlSelfRef.__VactPhaseResult = Vdesign___024root___eval_phase__act(vlSelf);
                } while (vlSelfRef.__VactPhaseResult);
                vlSelfRef.__VinactPhaseResult = Vdesign___024root___eval_phase__inact(vlSelf);
            } while (vlSelfRef.__VinactPhaseResult);
            vlSelfRef.__VnbaPhaseResult = Vdesign___024root___eval_phase__nba(vlSelf);
        } while (vlSelfRef.__VnbaPhaseResult);
        vlSelfRef.__VobsPhaseResult = Vdesign___024root___eval_phase__obs(vlSelf);
    } while (vlSelfRef.__VobsPhaseResult);
}

void Vdesign___024root____VbeforeTrig_ha27a8090__0(Vdesign___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root____VbeforeTrig_ha27a8090__0\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.testFlop__DOT__clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__testFlop__DOT__clk__0 
        = vlSelfRef.testFlop__DOT__clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_ha27a8090__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_ha27a8090__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vdesign___024root___eval_debug_assertions(Vdesign___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdesign___024root___eval_debug_assertions\n"); );
    Vdesign__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG

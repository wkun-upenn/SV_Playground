// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VtestFlop.h for the primary calling header

#ifndef VERILATED_VTESTFLOP___024ROOT_H_
#define VERILATED_VTESTFLOP___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_cov.h"
#include "verilated_timing.h"


class VtestFlop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VtestFlop___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ testFlop__DOT__clk;
    CData/*0:0*/ testFlop__DOT__reset;
    CData/*7:0*/ testFlop__DOT__qin;
    CData/*7:0*/ testFlop__DOT__qout;
    CData/*1:0*/ testFlop__DOT__epoch;
    CData/*0:0*/ testFlop__DOT__cb__DOT__reset;
    CData/*7:0*/ testFlop__DOT__cb__DOT__qin;
    CData/*7:0*/ testFlop__DOT__cb__DOT__qout;
    CData/*0:0*/ testFlop__DOT____Vtogcov__clk;
    CData/*0:0*/ testFlop__DOT____Vtogcov__reset;
    CData/*7:0*/ testFlop__DOT____Vtogcov__qin;
    CData/*7:0*/ testFlop__DOT____Vtogcov__qout;
    CData/*1:0*/ testFlop__DOT____Vtogcov__epoch;
    CData/*7:0*/ testFlop__DOT____Vclocking_prev__cb__DOT__qin;
    CData/*0:0*/ testFlop__DOT____Vclocking_prev__cb__DOT__reset;
    CData/*7:0*/ testFlop__DOT__unnamedblk1_1__DOT__unnamedblk1__DOT__num;
    CData/*0:0*/ __Vintraval_hdff0b277__0;
    CData/*7:0*/ __Vintraval_haeaa0120__0;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlPhaseResult;
    CData/*0:0*/ __Vtrigprevexpr___TOP__testFlop__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__testFlop__DOT__reset__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    CData/*0:0*/ __VobsPhaseResult;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __VnbaIterCount;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VobsTriggered;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_ha27a8090__0;
    VlSampleQueue<CData/*7:0*/> testFlop__DOT____Vqueue__cb__DOT__qout;

    // INTERNAL VARIABLES
    VtestFlop__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    VtestFlop___024root(VtestFlop__Syms* symsp, const char* namep);
    ~VtestFlop___024root();
    VL_UNCOPYABLE(VtestFlop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
    void __vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp, const char* linescovp);
    void __vlCoverToggleInsert(int begin, int end, bool ranged, uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp);
};


#endif  // guard

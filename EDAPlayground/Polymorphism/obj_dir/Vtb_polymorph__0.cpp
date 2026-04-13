// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph___eval_initial__TOP__tb__DOT__dut(Vtb_polymorph* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        Vtb_polymorph___eval_initial__TOP__tb__DOT__dut\n"); );
    Vtb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((1U & (~ (0U != ([&]() {
                                    vlSelfRef.__PVT__b1 
                                        = vlSelfRef.__PVT__unnamedblk1__DOT__e1;
                                }(), 1U))))))) {
        VL_WRITEF_NX("[%0t] %%Error: design.sv:19: Assertion failed in %Ntb.dut.unnamedblk1: '$cast' failed.\n",0,
                     64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("design.sv", 19, "");
    }
    VL_NULL_CHECK(vlSelfRef.__PVT__unnamedblk1__DOT__e1, "design.sv", 20)->__VnoInFunc_display(vlSymsp);
}

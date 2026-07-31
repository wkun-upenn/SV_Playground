// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph___eval_initial__TOP__tb__DOT__dut(Vtb_polymorph* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        Vtb_polymorph___eval_initial__TOP__tb__DOT__dut\n"); );
    Vtb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlClassRef<Vtb_polymorph__03a__03abase> __PVT__b1;
    // Body
    vlSelfRef.__PVT__unnamedblk1__DOT__e_src = VL_NEW(Vtb_polymorph__03a__03aext, vlSymsp);
    __PVT__b1 = vlSelfRef.__PVT__unnamedblk1__DOT__e_src;
    if (VL_LIKELY((VL_CAST_DYNAMIC(__PVT__b1, vlSelfRef.__PVT__unnamedblk1__DOT__e1)))) {
        VL_NULL_CHECK(vlSelfRef.__PVT__unnamedblk1__DOT__e1, "/Users/lymtics/Documents/SV-Playground/EDAPlayground/Polymorphism/design.sv", 30)->__VnoInFunc_display(vlSymsp);
    } else {
        VL_WRITEF_NX("Cast failed\n",0);
    }
}

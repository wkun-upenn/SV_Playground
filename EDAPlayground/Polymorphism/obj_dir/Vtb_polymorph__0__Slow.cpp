// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

VL_ATTR_COLD void Vtb_polymorph___eval_static__TOP__tb__DOT__dut(Vtb_polymorph* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        Vtb_polymorph___eval_static__TOP__tb__DOT__dut\n"); );
    Vtb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__b1 = VL_NEW(Vtb_polymorph__03a__03abase, vlSymsp);
}

VL_ATTR_COLD void Vtb_polymorph___ctor_var_reset(Vtb_polymorph* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        Vtb_polymorph___ctor_var_reset\n"); );
    Vtb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16707436170211756652ull);
}

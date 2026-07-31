// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph__03a__03abase::__VnoInFunc_display(Vtb__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::__VnoInFunc_display\n"); );
    // Body
    VL_WRITEF_NX("Am in Base class\n",0);
}

Vtb_polymorph__03a__03abase::Vtb_polymorph__03a__03abase(Vtb__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::new\n"); );
    // Body
    _ctor_var_reset(vlSymsp);
}

void Vtb_polymorph__03a__03abase::_ctor_var_reset(Vtb__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::_ctor_var_reset\n"); );
    // Body
    (void)vlSymsp;  // Prevent unused variable warning
}

Vtb_polymorph__03a__03abase::~Vtb_polymorph__03a__03abase() {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::~\n"); );
}

std::string Vtb_polymorph__03a__03abase::to_string() const {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::to_string\n"); );
    // Body
    return ("'{"s + to_string_middle() + "}");
}

std::string Vtb_polymorph__03a__03abase::to_string_middle() const {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03abase::to_string_middle\n"); );
    // Body
    return (""s);
}

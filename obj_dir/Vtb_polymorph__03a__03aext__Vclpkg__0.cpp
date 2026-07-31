// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph__03a__03aext::__VnoInFunc_display(Vtb__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::__VnoInFunc_display\n"); );
    // Body
    VL_WRITEF_NX("Am in Extended class\n",0);
}

Vtb_polymorph__03a__03aext::Vtb_polymorph__03a__03aext(Vtb__Syms* __restrict vlSymsp)
    : Vtb_polymorph__03a__03abase(vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::new\n"); );
    // Body
    _ctor_var_reset(vlSymsp);
    ;
}

void Vtb_polymorph__03a__03aext::_ctor_var_reset(Vtb__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::_ctor_var_reset\n"); );
    // Body
    (void)vlSymsp;  // Prevent unused variable warning
}

Vtb_polymorph__03a__03aext::~Vtb_polymorph__03a__03aext() {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::~\n"); );
}

std::string Vtb_polymorph__03a__03aext::to_string() const {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::to_string\n"); );
    // Body
    return ("'{"s + to_string_middle() + "}");
}

std::string Vtb_polymorph__03a__03aext::to_string_middle() const {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_polymorph__03a__03aext::to_string_middle\n"); );
    // Body
    std::string out;
    out += Vtb_polymorph__03a__03abase::to_string_middle();
    return (out);
}

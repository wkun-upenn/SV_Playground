// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph__03a__03aext__Vclpkg___ctor_var_reset(Vtb_polymorph__03a__03aext__Vclpkg* vlSelf);

Vtb_polymorph__03a__03aext__Vclpkg::Vtb_polymorph__03a__03aext__Vclpkg() = default;
Vtb_polymorph__03a__03aext__Vclpkg::~Vtb_polymorph__03a__03aext__Vclpkg() = default;

void Vtb_polymorph__03a__03aext__Vclpkg::ctor(Vtb__Syms* symsp, const char* namep) {
    vlSymsp = symsp;
    vlNamep = strdup(Verilated::catName(vlSymsp->name(), namep));
    // Reset structure values
    Vtb_polymorph__03a__03aext__Vclpkg___ctor_var_reset(this);
}

void Vtb_polymorph__03a__03aext__Vclpkg::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

void Vtb_polymorph__03a__03aext__Vclpkg::dtor() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}

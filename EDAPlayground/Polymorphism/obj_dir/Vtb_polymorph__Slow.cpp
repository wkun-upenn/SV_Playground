// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb.h for the primary calling header

#include "Vtb__pch.h"

void Vtb_polymorph___ctor_var_reset(Vtb_polymorph* vlSelf);

Vtb_polymorph::Vtb_polymorph() = default;
Vtb_polymorph::~Vtb_polymorph() = default;

void Vtb_polymorph::ctor(Vtb__Syms* symsp, const char* namep) {
    vlSymsp = symsp;
    vlNamep = strdup(Verilated::catName(vlSymsp->name(), namep));
    // Reset structure values
    Vtb_polymorph___ctor_var_reset(this);
}

void Vtb_polymorph::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

void Vtb_polymorph::dtor() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}

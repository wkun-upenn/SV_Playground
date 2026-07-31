// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdesign.h for the primary calling header

#include "Vdesign__pch.h"

void Vdesign___024root___ctor_var_reset(Vdesign___024root* vlSelf);

Vdesign___024root::Vdesign___024root(Vdesign__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vdesign___024root___ctor_var_reset(this);
}

void Vdesign___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vdesign___024root::~Vdesign___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}

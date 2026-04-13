// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtb__pch.h"

Vtb__Syms::Vtb__Syms(VerilatedContext* contextp, const char* namep, Vtb* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup top module instance
    , TOP{this, namep}
{
    // Check resources
    Verilated::stackCheck(194);
    // Setup sub module instances
    TOP__tb__DOT__dut.ctor(this, "tb.dut");
    TOP__polymorph__03a__03abase__Vclpkg.ctor(this, "polymorph::base__Vclpkg");
    TOP__polymorph__03a__03aext__Vclpkg.ctor(this, "polymorph::ext__Vclpkg");
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    TOP.__PVT__tb__DOT__dut = &TOP__tb__DOT__dut;
    TOP.polymorph__03a__03abase__Vclpkg = &TOP__polymorph__03a__03abase__Vclpkg;
    TOP.polymorph__03a__03aext__Vclpkg = &TOP__polymorph__03a__03aext__Vclpkg;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP__tb__DOT__dut.__Vconfigure(true);
    TOP__polymorph__03a__03abase__Vclpkg.__Vconfigure(true);
    TOP__polymorph__03a__03aext__Vclpkg.__Vconfigure(true);
    // Setup scopes
}

Vtb__Syms::~Vtb__Syms() {
    // Tear down scopes
    // Tear down sub module instances
    TOP__polymorph__03a__03aext__Vclpkg.dtor();
    TOP__polymorph__03a__03abase__Vclpkg.dtor();
    TOP__tb__DOT__dut.dtor();
}

// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb.h for the primary calling header

#ifndef VERILATED_VTB_POLYMORPH_H_
#define VERILATED_VTB_POLYMORPH_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"
class Vtb_polymorph__03a__03abase;
class Vtb_polymorph__03a__03aext;


class Vtb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_polymorph final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ clk;
    VlClassRef<Vtb_polymorph__03a__03abase> __PVT__b1;
    VlClassRef<Vtb_polymorph__03a__03aext> __PVT__unnamedblk1__DOT__e1;

    // INTERNAL VARIABLES
    Vtb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_polymorph();
    ~Vtb_polymorph();
    void ctor(Vtb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vtb_polymorph);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard

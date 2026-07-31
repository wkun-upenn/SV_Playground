// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb.h for the primary calling header

#ifndef VERILATED_VTB_POLYMORPH__03A__03ABASE__VCLPKG_H_
#define VERILATED_VTB_POLYMORPH__03A__03ABASE__VCLPKG_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_polymorph__03a__03abase__Vclpkg final {
  public:

    // INTERNAL VARIABLES
    Vtb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_polymorph__03a__03abase__Vclpkg();
    ~Vtb_polymorph__03a__03abase__Vclpkg();
    void ctor(Vtb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vtb_polymorph__03a__03abase__Vclpkg);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


class Vtb__Syms;

class Vtb_polymorph__03a__03abase : public virtual VlClass {
  public:

    // INTERNAL METHODS
    virtual const char* typeName() const { return "polymorph::base"; }
    VlClass* clone() const { return new Vtb_polymorph__03a__03abase(*this); }
    virtual void __VnoInFunc_display(Vtb__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset(Vtb__Syms* __restrict vlSymsp);
  public:
    Vtb_polymorph__03a__03abase(Vtb__Syms* __restrict vlSymsp);
    virtual std::string to_string() const;
    std::string to_string_middle() const;
    virtual ~Vtb_polymorph__03a__03abase();
};


#endif  // guard

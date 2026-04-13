// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb.h for the primary calling header

#ifndef VERILATED_VTB_POLYMORPH__03A__03AEXT__VCLPKG_H_
#define VERILATED_VTB_POLYMORPH__03A__03AEXT__VCLPKG_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"
class Vtb_polymorph__03a__03abase;


class Vtb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_polymorph__03a__03aext__Vclpkg final {
  public:

    // INTERNAL VARIABLES
    Vtb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_polymorph__03a__03aext__Vclpkg();
    ~Vtb_polymorph__03a__03aext__Vclpkg();
    void ctor(Vtb__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vtb_polymorph__03a__03aext__Vclpkg);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};

#include "Vtb_polymorph__03a__03abase__Vclpkg.h"

class Vtb__Syms;

class Vtb_polymorph__03a__03aext : public Vtb_polymorph__03a__03abase {
  public:

    // INTERNAL METHODS
    virtual const char* typeName() const { return "polymorph::ext"; }
    VlClass* clone() const { return new Vtb_polymorph__03a__03aext(*this); }
    void __VnoInFunc_display(Vtb__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset(Vtb__Syms* __restrict vlSymsp);
  public:
    Vtb_polymorph__03a__03aext(Vtb__Syms* __restrict vlSymsp);
    virtual std::string to_string() const;
    std::string to_string_middle() const;
    virtual ~Vtb_polymorph__03a__03aext();
};


#endif  // guard

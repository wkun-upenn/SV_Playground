// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTESTFLOP__SYMS_H_
#define VERILATED_VTESTFLOP__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "VtestFlop.h"

// INCLUDE MODULE CLASSES
#include "VtestFlop___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) VtestFlop__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    VtestFlop* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    VtestFlop___024root            TOP;

    // COVERAGE
    uint32_t __Vcoverage[51];

    // CONSTRUCTORS
    VtestFlop__Syms(VerilatedContext* contextp, const char* namep, VtestFlop* modelp);
    ~VtestFlop__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard

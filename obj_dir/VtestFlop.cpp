// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VtestFlop__pch.h"

//============================================================
// Constructors

VtestFlop::VtestFlop(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VtestFlop__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VtestFlop::VtestFlop(const char* _vcname__)
    : VtestFlop(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VtestFlop::~VtestFlop() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VtestFlop___024root___eval_debug_assertions(VtestFlop___024root* vlSelf);
#endif  // VL_DEBUG
void VtestFlop___024root___eval_static(VtestFlop___024root* vlSelf);
void VtestFlop___024root___eval_initial(VtestFlop___024root* vlSelf);
void VtestFlop___024root___eval_settle(VtestFlop___024root* vlSelf);
void VtestFlop___024root___eval(VtestFlop___024root* vlSelf);

void VtestFlop::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VtestFlop::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VtestFlop___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VtestFlop___024root___eval_static(&(vlSymsp->TOP));
        VtestFlop___024root___eval_initial(&(vlSymsp->TOP));
        VtestFlop___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VtestFlop___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VtestFlop::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t VtestFlop::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* VtestFlop::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VtestFlop___024root___eval_final(VtestFlop___024root* vlSelf);

VL_ATTR_COLD void VtestFlop::final() {
    VtestFlop___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VtestFlop::hierName() const { return vlSymsp->name(); }
const char* VtestFlop::modelName() const { return "VtestFlop"; }
unsigned VtestFlop::threads() const { return 1; }
void VtestFlop::prepareClone() const { contextp()->prepareClone(); }
void VtestFlop::atClone() const {
    contextp()->threadPoolpOnClone();
}

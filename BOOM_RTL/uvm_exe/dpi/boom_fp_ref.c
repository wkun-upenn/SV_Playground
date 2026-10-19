/*=============================================================================
 * boom_fp_ref.c — golden reference model for the BOOM FPU / FDivSqrt / FPIU /
 * IntToFP execution paths, exported to SystemVerilog through DPI-C.
 *
 * All arithmetic is done with Berkeley SoftFloat-3e built with the RISC-V
 * NaN specialization (dpi/softfloat/RISCV) — the *same* library and
 * specialization Spike (riscv-isa-sim) uses, so results and fflags are
 * Spike's golden results.  The non-arithmetic ops (sign-inject, min/max,
 * classify, moves, NaN-boxing) follow Spike's decode/insns/*.h line by line.
 *
 * Conventions (match boom_exe_defs_pkg / boom_exe_ref_model.sv):
 *   a,b,c  : 64-bit IEEE register images.  Single-precision operands must be
 *            NaN-boxed (upper 32 bits all ones) or they are treated as qNaN.
 *   result : 64-bit IEEE register image for FP results (singles NaN-boxed),
 *            sign-extended integer for FP->int results.
 *   flags  : RISC-V fflags {NV,DZ,OF,UF,NX} = bits 4..0
 *   rm     : 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM (dynamic rm resolved by caller)
 *   typ    : inst[21:20] for conversions: 0 W, 1 WU, 2 L, 3 LU
 *===========================================================================*/
#include <stdint.h>
#include <string.h>
#include "softfloat.h"
#include "specialize.h"
#include "svdpi.h"

/* op codes — keep in sync with boom_exe_ref_model.sv fp_op_e */
enum {
  FPR_ADD = 0, FPR_SUB, FPR_MUL, FPR_MADD, FPR_MSUB, FPR_NMADD, FPR_NMSUB,
  FPR_DIV, FPR_SQRT,
  FPR_SGNJ, FPR_SGNJN, FPR_SGNJX, FPR_MIN, FPR_MAX,
  FPR_CVT_S_D, FPR_CVT_D_S,
  FPR_EQ, FPR_LT, FPR_LE, FPR_CLASS, FPR_MV_X_F,
  FPR_CVT_INT_F,   /* fp -> int, typ selects W/WU/L/LU */
  FPR_MV_F_X,      /* int -> fp move (bit copy, NaN-box for S) */
  FPR_CVT_F_INT    /* int -> fp convert, typ selects W/WU/L/LU */
};

#define BOX32(x)   (0xFFFFFFFF00000000ULL | (uint64_t)(uint32_t)(x))
#define IS_BOXED(x) (((x) >> 32) == 0xFFFFFFFFULL)
#define QNAN32     0x7FC00000u
#define QNAN64     0x7FF8000000000000ULL

static uint_fast8_t to_sf_rm(int rm) {
  switch (rm) {
    case 0: return softfloat_round_near_even;
    case 1: return softfloat_round_minMag;
    case 2: return softfloat_round_min;
    case 3: return softfloat_round_max;
    case 4: return softfloat_round_near_maxMag;
    default: return softfloat_round_near_even;
  }
}

/* --- unbox: a non-NaN-boxed single reads as the canonical qNaN (RISC-V) --- */
static float32_t unbox32(uint64_t v) {
  float32_t f; f.v = IS_BOXED(v) ? (uint32_t)v : QNAN32; return f;
}
static float64_t as64(uint64_t v) { float64_t f; f.v = v; return f; }

static int isNaN32(uint32_t v) { return ((v & 0x7F800000u) == 0x7F800000u) && (v & 0x007FFFFFu); }
static int isSNaN32(uint32_t v){ return isNaN32(v) && !(v & 0x00400000u); }
static int isNaN64(uint64_t v) { return ((v & 0x7FF0000000000000ULL) == 0x7FF0000000000000ULL) && (v & 0x000FFFFFFFFFFFFFULL); }
static int isSNaN64(uint64_t v){ return isNaN64(v) && !(v & 0x0008000000000000ULL); }

/* --- classify (riscv-isa-sim: f32_classify / f64_classify) --- */
static uint64_t classify32(uint32_t v) {
  uint32_t exp = (v >> 23) & 0xFF, frac = v & 0x7FFFFF; int sign = v >> 31;
  int inf = exp == 0xFF && frac == 0, nan = exp == 0xFF && frac != 0;
  int zero = exp == 0 && frac == 0, subn = exp == 0 && frac != 0, norm = exp != 0 && exp != 0xFF;
  return (uint64_t)(
    ( sign && inf ) << 0 | ( sign && norm) << 1 | ( sign && subn) << 2 | ( sign && zero) << 3 |
    (!sign && zero) << 4 | (!sign && subn) << 5 | (!sign && norm) << 6 | (!sign && inf ) << 7 |
    (nan && isSNaN32(v)) << 8 | (nan && !isSNaN32(v)) << 9);
}
static uint64_t classify64(uint64_t v) {
  uint32_t exp = (v >> 52) & 0x7FF; uint64_t frac = v & 0xFFFFFFFFFFFFFULL; int sign = v >> 63;
  int inf = exp == 0x7FF && frac == 0, nan = exp == 0x7FF && frac != 0;
  int zero = exp == 0 && frac == 0, subn = exp == 0 && frac != 0, norm = exp != 0 && exp != 0x7FF;
  return (uint64_t)(
    ( sign && inf ) << 0 | ( sign && norm) << 1 | ( sign && subn) << 2 | ( sign && zero) << 3 |
    (!sign && zero) << 4 | (!sign && subn) << 5 | (!sign && norm) << 6 | (!sign && inf ) << 7 |
    (nan && isSNaN64(v)) << 8 | (nan && !isSNaN64(v)) << 9);
}

/* --- min/max exactly as Spike (fmin/fmax insns) --- */
static uint32_t minmax32(uint32_t a, uint32_t b, int is_max) {
  float32_t fa = {a}, fb = {b};
  int less = f32_lt_quiet(fa, fb) || (f32_eq(fa, fb) && (a & 0x80000000u));
  if (isNaN32(a) && isNaN32(b)) return QNAN32;
  int pick_a = is_max ? (!less || isNaN32(b)) : (less || isNaN32(b));
  if (isNaN32(a)) pick_a = 0;
  if (isNaN32(b)) pick_a = 1;
  return pick_a ? a : b;
}
static uint64_t minmax64(uint64_t a, uint64_t b, int is_max) {
  float64_t fa = {a}, fb = {b};
  int less = f64_lt_quiet(fa, fb) || (f64_eq(fa, fb) && (a & 0x8000000000000000ULL));
  if (isNaN64(a) && isNaN64(b)) return QNAN64;
  int pick_a = is_max ? (!less || isNaN64(b)) : (less || isNaN64(b));
  if (isNaN64(a)) pick_a = 0;
  if (isNaN64(b)) pick_a = 1;
  return pick_a ? a : b;
}

static inline uint64_t sext32(uint32_t x) { return (uint64_t)(int64_t)(int32_t)x; }

/*---------------------------------------------------------------------------
 * DPI entry point
 *---------------------------------------------------------------------------*/
int boom_fp_ref(int op, int is_double, int rm, int typ,
                uint64_t a, uint64_t b, uint64_t c,
                uint64_t *result, int *flags)
{
  softfloat_roundingMode = to_sf_rm(rm);
  softfloat_exceptionFlags = 0;
  softfloat_detectTininess = softfloat_tininess_afterRounding;
  uint64_t r = 0;

  if (!is_double) {
    float32_t fa = unbox32(a), fb = unbox32(b), fc = unbox32(c), fr;
    uint32_t ua = fa.v, ub = fb.v;
    switch (op) {
      case FPR_ADD:   fr = f32_add(fa, fb); r = BOX32(fr.v); break;
      case FPR_SUB:   fr = f32_sub(fa, fb); r = BOX32(fr.v); break;
      case FPR_MUL:   fr = f32_mul(fa, fb); r = BOX32(fr.v); break;
      case FPR_MADD:  fr = f32_mulAdd(fa, fb, fc); r = BOX32(fr.v); break;
      case FPR_MSUB:  { float32_t nc = {fc.v ^ 0x80000000u}; fr = f32_mulAdd(fa, fb, nc); r = BOX32(fr.v); } break;
      case FPR_NMSUB: { float32_t na = {fa.v ^ 0x80000000u}; fr = f32_mulAdd(na, fb, fc); r = BOX32(fr.v); } break;
      case FPR_NMADD: { float32_t na = {fa.v ^ 0x80000000u}, nc = {fc.v ^ 0x80000000u}; fr = f32_mulAdd(na, fb, nc); r = BOX32(fr.v); } break;
      case FPR_DIV:   fr = f32_div(fa, fb); r = BOX32(fr.v); break;
      case FPR_SQRT:  fr = f32_sqrt(fa); r = BOX32(fr.v); break;
      case FPR_SGNJ:  r = BOX32((ua & 0x7FFFFFFFu) | ( ub & 0x80000000u)); break;
      case FPR_SGNJN: r = BOX32((ua & 0x7FFFFFFFu) | (~ub & 0x80000000u)); break;
      case FPR_SGNJX: r = BOX32(ua ^ (ub & 0x80000000u)); break;
      case FPR_MIN:   r = BOX32(minmax32(ua, ub, 0)); break;
      case FPR_MAX:   r = BOX32(minmax32(ua, ub, 1)); break;
      case FPR_CVT_D_S: { float64_t d = f32_to_f64(fa); r = d.v; } break;
      case FPR_EQ:    r = f32_eq(fa, fb); break;
      case FPR_LT:    r = f32_lt(fa, fb); break;
      case FPR_LE:    r = f32_le(fa, fb); break;
      case FPR_CLASS: r = classify32(ua); break;
      case FPR_MV_X_F: r = sext32((uint32_t)a); break;            /* fmv.x.w: no unboxing, sign-extend */
      case FPR_CVT_INT_F:
        switch (typ) {
          case 0: r = sext32((uint32_t)f32_to_i32 (fa, softfloat_roundingMode, true)); break;
          case 1: r = sext32(          f32_to_ui32(fa, softfloat_roundingMode, true)); break;
          case 2: r = (uint64_t)       f32_to_i64 (fa, softfloat_roundingMode, true); break;
          default:r =                  f32_to_ui64(fa, softfloat_roundingMode, true); break;
        }
        break;
      case FPR_MV_F_X: r = BOX32((uint32_t)a); break;
      case FPR_CVT_F_INT:
        switch (typ) {
          case 0: fr = i32_to_f32 ((int32_t)a);  break;
          case 1: fr = ui32_to_f32((uint32_t)a); break;
          case 2: fr = i64_to_f32 ((int64_t)a);  break;
          default:fr = ui64_to_f32(a);           break;
        }
        r = BOX32(fr.v);
        break;
      default: return -1;
    }
  } else {
    float64_t fa = as64(a), fb = as64(b), fc = as64(c), fr;
    switch (op) {
      case FPR_ADD:   fr = f64_add(fa, fb); r = fr.v; break;
      case FPR_SUB:   fr = f64_sub(fa, fb); r = fr.v; break;
      case FPR_MUL:   fr = f64_mul(fa, fb); r = fr.v; break;
      case FPR_MADD:  fr = f64_mulAdd(fa, fb, fc); r = fr.v; break;
      case FPR_MSUB:  { float64_t nc = {fc.v ^ 0x8000000000000000ULL}; fr = f64_mulAdd(fa, fb, nc); r = fr.v; } break;
      case FPR_NMSUB: { float64_t na = {fa.v ^ 0x8000000000000000ULL}; fr = f64_mulAdd(na, fb, fc); r = fr.v; } break;
      case FPR_NMADD: { float64_t na = {fa.v ^ 0x8000000000000000ULL}, nc = {fc.v ^ 0x8000000000000000ULL}; fr = f64_mulAdd(na, fb, nc); r = fr.v; } break;
      case FPR_DIV:   fr = f64_div(fa, fb); r = fr.v; break;
      case FPR_SQRT:  fr = f64_sqrt(fa); r = fr.v; break;
      case FPR_SGNJ:  r = (a & 0x7FFFFFFFFFFFFFFFULL) | ( b & 0x8000000000000000ULL); break;
      case FPR_SGNJN: r = (a & 0x7FFFFFFFFFFFFFFFULL) | (~b & 0x8000000000000000ULL); break;
      case FPR_SGNJX: r = a ^ (b & 0x8000000000000000ULL); break;
      case FPR_MIN:   r = minmax64(a, b, 0); break;
      case FPR_MAX:   r = minmax64(a, b, 1); break;
      case FPR_CVT_S_D: { float32_t s = f64_to_f32(fa); r = BOX32(s.v); } break;
      case FPR_EQ:    r = f64_eq(fa, fb); break;
      case FPR_LT:    r = f64_lt(fa, fb); break;
      case FPR_LE:    r = f64_le(fa, fb); break;
      case FPR_CLASS: r = classify64(a); break;
      case FPR_MV_X_F: r = a; break;
      case FPR_CVT_INT_F:
        switch (typ) {
          case 0: r = sext32((uint32_t)f64_to_i32 (fa, softfloat_roundingMode, true)); break;
          case 1: r = sext32(          f64_to_ui32(fa, softfloat_roundingMode, true)); break;
          case 2: r = (uint64_t)       f64_to_i64 (fa, softfloat_roundingMode, true); break;
          default:r =                  f64_to_ui64(fa, softfloat_roundingMode, true); break;
        }
        break;
      case FPR_MV_F_X: r = a; break;
      case FPR_CVT_F_INT:
        switch (typ) {
          case 0: fr = i32_to_f64 ((int32_t)a);  break;
          case 1: fr = ui32_to_f64((uint32_t)a); break;
          case 2: fr = i64_to_f64 ((int64_t)a);  break;
          default:fr = ui64_to_f64(a);           break;
        }
        r = fr.v;
        break;
      default: return -1;
    }
  }
  *result = r;
  *flags  = softfloat_exceptionFlags & 0x1F;   /* NV=16 DZ=8 OF=4 UF=2 NX=1 == RISC-V fflags */
  return 0;
}

/* Convenience for the SV side / unit tests: name of the library in use */
const char *boom_fp_ref_backend(void) { return "Berkeley SoftFloat-3e (RISC-V specialization, as used by Spike)"; }

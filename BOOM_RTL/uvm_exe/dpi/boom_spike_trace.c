//=============================================================================
// boom_spike_trace.c — DPI-C bridge from a Spike commit log to the
// execution-pipeline testbench ("trace-driven stimulus with Spike as golden")
//-----------------------------------------------------------------------------
// Spike (riscv-isa-sim, `spike --log-commits`) writes one line per committed
// instruction:
//   core   0: 3 0x0000000080000004 (0x00000093) x1 0x0000000000000000
//   core   0: 0 0x0000000080000100 (0x02b7f553) f10 0xffffffff3f800000 c1_fflags 0x0000000000000001
//   core   0: 0 0x0000000080000200 (0x00053503) x10 0x00000000deadbeef mem 0x0000000080002000
// privilege, pc, encoding, then every architectural write the instruction
// performed (integer / FP register, CSR, memory).
//
// This library replays the log in program order and keeps the architectural
// state (x0..x31, f0..f31, fflags, frm) so that for every instruction it can
// hand the testbench:
//   * the operand VALUES the instruction consumed (the DUT has no register
//     file: the testbench supplies operands directly),
//   * the decoded operation in the testbench's own op vocabulary (exe_op_e),
//   * the RESULT Spike produced (rd value, fflags accumulator after the op,
//     next pc for branches / jumps) = the golden expectation.
// Loads, stores, fences, ecall/mret and anything the exe-pipeline DUT cannot
// execute are kept for their state updates but marked "not replayable".
//
// The op vocabulary is not hard-coded: the SV side registers every exe_op_e
// name with its enum value at start-up (spike_trace_register_op), so the two
// sides can never drift apart silently.
//=============================================================================
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "svdpi.h"

//------------------------------------------------------------------ op names
#define MAX_OPS 256
static char  op_names[MAX_OPS][32];
static int   op_ids[MAX_OPS];
static int   n_ops = 0;

int spike_trace_register_op(int id, const char* name) {
  if (n_ops >= MAX_OPS) return -1;
  strncpy(op_names[n_ops], name, 31); op_names[n_ops][31] = 0;
  op_ids[n_ops] = id; n_ops++;
  return 0;
}
static int op_id(const char* name) {
  for (int i = 0; i < n_ops; i++) if (strcmp(op_names[i], name) == 0) return op_ids[i];
  return -1;
}

//------------------------------------------------------------------ entries
typedef struct {
  uint64_t pc, next_pc;
  uint32_t insn;
  int      priv;
  int      kind;         // 0 = not replayable, 1 = replayable exe op
  int      op;           // exe_op_e value (kind == 1)
  char     opname[24];
  int      rs1, rs2, rs3, rd;
  uint64_t rs1_val, rs2_val, rs3_val;
  int      src1_fp, src2_fp, src3_fp, dst_fp;
  int      has_rd;       // an architectural rd write was logged (x0 excluded)
  uint64_t rd_val;
  int32_t  imm;
  int      rm, zimm, csr;
  int      fl_before, fl_after, frm;   // fflags accumulator around the op, frm at the op
  int      csr_wr_valid; uint64_t csr_wr_val;   // CSR written by this instruction (if any, first one)
  int      csr_wr_num;
  int      is_csr_op;
} entry_t;

static entry_t* ents = NULL;
static int      n_ents = 0, cap_ents = 0;
static int      n_replayable = 0, n_skipped = 0;
static int      n_by_class[8];   // 0 int-alu,1 branch/jump,2 muldiv,3 csr,4 fp,5 f2i,6 i2f,7 skipped

//------------------------------------------------------------------ decoder
#define BITS(x, hi, lo) (((x) >> (lo)) & ((1u << ((hi) - (lo) + 1)) - 1))
static int32_t sext(uint32_t v, int bits) { int32_t s = 32 - bits; return ((int32_t)(v << s)) >> s; }

// fills opname / imm / rm / zimm / csr / register-type flags; returns 1 if the DUT can execute it
static int decode(uint32_t insn, entry_t* e) {
  uint32_t opc = insn & 0x7f, f3 = BITS(insn, 14, 12), f7 = BITS(insn, 31, 25), rs2 = BITS(insn, 24, 20);
  const char* n = NULL;
  int cls = 0;
  e->rd = BITS(insn, 11, 7); e->rs1 = BITS(insn, 19, 15); e->rs2 = rs2; e->rs3 = BITS(insn, 31, 27);
  e->src1_fp = e->src2_fp = e->src3_fp = e->dst_fp = 0; e->rm = f3; e->zimm = e->rs1; e->csr = BITS(insn, 31, 20);
  e->imm = sext(BITS(insn, 31, 20), 12);
  if ((insn & 3) != 3) return 0;                       // compressed: tests are built without C
  switch (opc) {
    case 0x13: // OP-IMM
      switch (f3) {
        case 0: n = "OP_ADDI"; break; case 2: n = "OP_SLTI"; break; case 3: n = "OP_SLTIU"; break;
        case 4: n = "OP_XORI"; break; case 6: n = "OP_ORI"; break; case 7: n = "OP_ANDI"; break;
        case 1: n = "OP_SLLI"; e->imm = BITS(insn, 25, 20); break;
        case 5: n = (insn & 0x40000000) ? "OP_SRAI" : "OP_SRLI"; e->imm = BITS(insn, 25, 20); break;
      }
      break;
    case 0x1b: // OP-IMM-32
      switch (f3) {
        case 0: n = "OP_ADDIW"; break;
        case 1: n = "OP_SLLIW"; e->imm = BITS(insn, 24, 20); break;
        case 5: n = (insn & 0x40000000) ? "OP_SRAIW" : "OP_SRLIW"; e->imm = BITS(insn, 24, 20); break;
      }
      break;
    case 0x33: // OP
      if (f7 == 0x01) { cls = 2; switch (f3) {
        case 0: n = "OP_MUL"; break; case 1: n = "OP_MULH"; break; case 2: n = "OP_MULHSU"; break; case 3: n = "OP_MULHU"; break;
        case 4: n = "OP_DIV"; break; case 5: n = "OP_DIVU"; break; case 6: n = "OP_REM"; break; case 7: n = "OP_REMU"; break; } }
      else if (f7 == 0x00) { switch (f3) {
        case 0: n = "OP_ADD"; break; case 1: n = "OP_SLL"; break; case 2: n = "OP_SLT"; break; case 3: n = "OP_SLTU"; break;
        case 4: n = "OP_XOR"; break; case 5: n = "OP_SRL"; break; case 6: n = "OP_OR"; break; case 7: n = "OP_AND"; break; } }
      else if (f7 == 0x20) { if (f3 == 0) n = "OP_SUB"; else if (f3 == 5) n = "OP_SRA"; }
      break;
    case 0x3b: // OP-32
      if (f7 == 0x01) { cls = 2; switch (f3) {
        case 0: n = "OP_MULW"; break; case 4: n = "OP_DIVW"; break; case 5: n = "OP_DIVUW"; break; case 6: n = "OP_REMW"; break; case 7: n = "OP_REMUW"; break; } }
      else if (f7 == 0x00) { switch (f3) { case 0: n = "OP_ADDW"; break; case 1: n = "OP_SLLW"; break; case 5: n = "OP_SRLW"; break; } }
      else if (f7 == 0x20) { if (f3 == 0) n = "OP_SUBW"; else if (f3 == 5) n = "OP_SRAW"; }
      break;
    case 0x37: n = "OP_LUI";   e->imm = (int32_t)(insn & 0xfffff000); break;
    case 0x17: n = "OP_AUIPC"; e->imm = (int32_t)(insn & 0xfffff000); break;
    case 0x6f: n = "OP_JAL"; cls = 1;
      e->imm = sext((BITS(insn, 31, 31) << 20) | (BITS(insn, 19, 12) << 12) | (BITS(insn, 20, 20) << 11) | (BITS(insn, 30, 21) << 1), 21); break;
    case 0x67: if (f3 == 0) { n = "OP_JALR"; cls = 1; } break;
    case 0x63: cls = 1;
      e->imm = sext((BITS(insn, 31, 31) << 12) | (BITS(insn, 7, 7) << 11) | (BITS(insn, 30, 25) << 5) | (BITS(insn, 11, 8) << 1), 13);
      switch (f3) { case 0: n = "OP_BEQ"; break; case 1: n = "OP_BNE"; break; case 4: n = "OP_BLT"; break;
                    case 5: n = "OP_BGE"; break; case 6: n = "OP_BLTU"; break; case 7: n = "OP_BGEU"; break; }
      break;
    case 0x73: cls = 3; // SYSTEM
      switch (f3) { case 1: n = "OP_CSRRW"; break; case 2: n = "OP_CSRRS"; break; case 3: n = "OP_CSRRC"; break;
                    case 5: n = "OP_CSRRWI"; break; case 6: n = "OP_CSRRSI"; break; case 7: n = "OP_CSRRCI"; break; }
      break;
    case 0x43: case 0x47: case 0x4b: case 0x4f: { // FMADD / FMSUB / FNMSUB / FNMADD
      int d = BITS(insn, 26, 25) == 1;
      static const char* nm[4][2] = { {"OP_FMADD_S", "OP_FMADD_D"}, {"OP_FMSUB_S", "OP_FMSUB_D"}, {"OP_FNMSUB_S", "OP_FNMSUB_D"}, {"OP_FNMADD_S", "OP_FNMADD_D"} };
      if (BITS(insn, 26, 25) <= 1) { n = nm[(opc >> 2) & 3][d]; cls = 4; e->src1_fp = e->src2_fp = e->src3_fp = e->dst_fp = 1; }
      break; }
    case 0x53: { // OP-FP
      int d = f7 & 1;
      cls = 4; e->src1_fp = e->src2_fp = e->dst_fp = 1;
      switch (f7 >> 1) {
        case 0x00: n = d ? "OP_FADD_D" : "OP_FADD_S"; break;
        case 0x02: n = d ? "OP_FSUB_D" : "OP_FSUB_S"; break;
        case 0x04: n = d ? "OP_FMUL_D" : "OP_FMUL_S"; break;
        case 0x06: n = d ? "OP_FDIV_D" : "OP_FDIV_S"; break;
        case 0x16: if (rs2 == 0) n = d ? "OP_FSQRT_D" : "OP_FSQRT_S"; break;
        case 0x08: n = f3 == 0 ? (d ? "OP_FSGNJ_D" : "OP_FSGNJ_S") : f3 == 1 ? (d ? "OP_FSGNJN_D" : "OP_FSGNJN_S") : f3 == 2 ? (d ? "OP_FSGNJX_D" : "OP_FSGNJX_S") : NULL; break;
        case 0x0a: n = f3 == 0 ? (d ? "OP_FMIN_D" : "OP_FMIN_S") : f3 == 1 ? (d ? "OP_FMAX_D" : "OP_FMAX_S") : NULL; break;
        case 0x10: if (!d && rs2 == 1) n = "OP_FCVT_S_D"; else if (d && rs2 == 0) n = "OP_FCVT_D_S"; break;
        case 0x28: cls = 5; e->dst_fp = 0; n = f3 == 2 ? (d ? "OP_FEQ_D" : "OP_FEQ_S") : f3 == 1 ? (d ? "OP_FLT_D" : "OP_FLT_S") : f3 == 0 ? (d ? "OP_FLE_D" : "OP_FLE_S") : NULL; break;
        case 0x30: cls = 5; e->dst_fp = 0; e->src2_fp = 0;
          switch (rs2) { case 0: n = d ? "OP_FCVT_W_D" : "OP_FCVT_W_S"; break; case 1: n = d ? "OP_FCVT_WU_D" : "OP_FCVT_WU_S"; break;
                         case 2: n = d ? "OP_FCVT_L_D" : "OP_FCVT_L_S"; break; case 3: n = d ? "OP_FCVT_LU_D" : "OP_FCVT_LU_S"; break; }
          break;
        case 0x34: cls = 6; e->src1_fp = 0; e->src2_fp = 0;
          switch (rs2) { case 0: n = d ? "OP_FCVT_D_W" : "OP_FCVT_S_W"; break; case 1: n = d ? "OP_FCVT_D_WU" : "OP_FCVT_S_WU"; break;
                         case 2: n = d ? "OP_FCVT_D_L" : "OP_FCVT_S_L"; break; case 3: n = d ? "OP_FCVT_D_LU" : "OP_FCVT_S_LU"; break; }
          break;
        case 0x38: cls = 5; e->dst_fp = 0; e->src2_fp = 0;
          if (rs2 == 0 && f3 == 0) n = d ? "OP_FMV_X_D" : "OP_FMV_X_W"; else if (rs2 == 0 && f3 == 1) n = d ? "OP_FCLASS_D" : "OP_FCLASS_S";
          break;
        case 0x3c: cls = 6; e->src1_fp = 0; e->src2_fp = 0; if (rs2 == 0 && f3 == 0) n = d ? "OP_FMV_D_X" : "OP_FMV_W_X"; break;
      }
      break; }
    default: break;   // LOAD, STORE, LOAD-FP, STORE-FP, MISC-MEM, AMO, ...: state only
  }
  if (n == NULL) { e->opname[0] = 0; e->op = -1; n_by_class[7]++; return 0; }
  strncpy(e->opname, n, 23); e->opname[23] = 0;
  e->op = op_id(n);
  e->is_csr_op = (cls == 3);
  if (e->op < 0) { n_by_class[7]++; return 0; }   // decoded, but the TB did not register it
  n_by_class[cls]++;
  return 1;
}

//------------------------------------------------------------------ log parser
static uint64_t xr[32], fr[32];
static int fflags_acc = 0, frm_cur = 0;

static void apply_csr(int num, uint64_t v) {
  if (num == 0x001) fflags_acc = v & 0x1f;
  else if (num == 0x002) frm_cur = v & 7;
  else if (num == 0x003) { fflags_acc = v & 0x1f; frm_cur = (v >> 5) & 7; }
}

static void push(entry_t* e) {
  if (n_ents == cap_ents) { cap_ents = cap_ents ? cap_ents * 2 : 4096; ents = realloc(ents, cap_ents * sizeof(entry_t)); }
  ents[n_ents++] = *e;
}

int spike_trace_load(const char* path) {
  FILE* f = fopen(path, "r");
  char line[1024];
  if (!f) return -1;
  n_ents = 0; n_replayable = n_skipped = 0; memset(n_by_class, 0, sizeof n_by_class);
  memset(xr, 0, sizeof xr); memset(fr, 0, sizeof fr); fflags_acc = 0; frm_cur = 0;
  while (fgets(line, sizeof line, f)) {
    entry_t e; int core, priv; unsigned long long pc; unsigned insn; int pos = 0;
    if (sscanf(line, "core %d: %d 0x%llx (0x%x)%n", &core, &priv, &pc, &insn, &pos) != 4) continue;  // disassembly lines etc.
    memset(&e, 0, sizeof e);
    e.pc = pc; e.insn = insn; e.priv = priv;
    e.kind = decode(insn, &e);
    // operands as seen BEFORE this instruction's writes
    e.rs1_val = e.src1_fp ? fr[e.rs1] : xr[e.rs1];
    e.rs2_val = e.src2_fp ? fr[e.rs2] : xr[e.rs2];
    e.rs3_val = e.src3_fp ? fr[e.rs3] : xr[e.rs3];
    e.fl_before = fflags_acc; e.frm = frm_cur;
    // architectural writes
    {
      char* p = line + pos;
      while (*p) {
        while (*p == ' ') p++;
        if (!*p || *p == '\n') break;
        if (p[0] == 'x' && p[1] >= '0' && p[1] <= '9') {
          int r; unsigned long long v; int adv = 0;
          if (sscanf(p, "x%d 0x%llx%n", &r, &v, &adv) == 2) {
            if (r != 0) { xr[r] = v; if (e.rd == r && !e.dst_fp) { e.has_rd = 1; e.rd_val = v; } }
            p += adv; continue;
          }
        } else if (p[0] == 'f' && p[1] >= '0' && p[1] <= '9') {
          int r; unsigned long long v; int adv = 0;
          if (sscanf(p, "f%d 0x%llx%n", &r, &v, &adv) == 2) { fr[r] = v; if (e.rd == r && e.dst_fp) { e.has_rd = 1; e.rd_val = v; } p += adv; continue; }
        } else if (p[0] == 'c' && p[1] >= '0' && p[1] <= '9') {
          int num; char nm[32]; unsigned long long v; int adv = 0;
          if (sscanf(p, "c%d_%31s 0x%llx%n", &num, nm, &v, &adv) == 3) {
            apply_csr(num, v);
            if (!e.csr_wr_valid) { e.csr_wr_valid = 1; e.csr_wr_num = num; e.csr_wr_val = v; }
            p += adv; continue;
          }
        } else if (strncmp(p, "mem ", 4) == 0) {
          unsigned long long a, v; int adv = 0;
          if (sscanf(p, "mem 0x%llx 0x%llx%n", &a, &v, &adv) == 2) { p += adv; continue; }   // store: address + data
          if (sscanf(p, "mem 0x%llx%n", &a, &adv) == 1) { p += adv; continue; }
        }
        // unknown token: skip it
        while (*p && *p != ' ' && *p != '\n') p++;
      }
    }
    e.fl_after = fflags_acc;
    if (e.kind) n_replayable++; else n_skipped++;
    push(&e);
  }
  fclose(f);
  for (int i = 0; i < n_ents; i++) ents[i].next_pc = (i + 1 < n_ents) ? ents[i + 1].pc : ents[i].pc + 4;
  return n_ents;
}

int spike_trace_num()        { return n_ents; }
int spike_trace_replayable() { return n_replayable; }
int spike_trace_class_count(int cls) { return (cls >= 0 && cls < 8) ? n_by_class[cls] : 0; }

// one call per instruction: everything the sequence needs
int spike_trace_get(int i, long long* pc, int* insn, int* kind, int* op, int* is_csr,
                    long long* rs1, long long* rs2, long long* rs3,
                    int* imm, int* rm, int* zimm, int* csr,
                    int* rd, int* has_rd, int* dst_fp, long long* rd_val, long long* next_pc,
                    int* fl_before, int* fl_after, int* frm, int* csr_wr_valid, int* csr_wr_num, long long* csr_wr_val) {
  entry_t* e;
  if (i < 0 || i >= n_ents) return 0;
  e = &ents[i];
  *pc = e->pc; *insn = e->insn; *kind = e->kind; *op = e->op; *is_csr = e->is_csr_op;
  *rs1 = e->rs1_val; *rs2 = e->rs2_val; *rs3 = e->rs3_val;
  *imm = e->imm; *rm = e->rm; *zimm = e->zimm; *csr = e->csr;
  *rd = e->rd; *has_rd = e->has_rd; *dst_fp = e->dst_fp; *rd_val = e->rd_val; *next_pc = e->next_pc;
  *fl_before = e->fl_before; *fl_after = e->fl_after; *frm = e->frm;
  *csr_wr_valid = e->csr_wr_valid; *csr_wr_num = e->csr_wr_num; *csr_wr_val = e->csr_wr_val;
  return 1;
}

const char* spike_trace_opname(int i) { return (i >= 0 && i < n_ents && ents[i].opname[0]) ? ents[i].opname : "-"; }

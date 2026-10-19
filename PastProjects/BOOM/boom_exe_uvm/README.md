# BOOM Execute-Pipeline UVM Verification Environment

A sample UVM testbench for the **execute pipeline** of the [RISC-V BOOM
core](https://boom-core.org), built from the micro-architecture described in
the BOOM documentation (the `riscv-boom-latest` HTML docs in this project).
It verifies the Execution-Unit / Functional-Unit cluster — integer ALU,
pipelined iMul, un-pipelined iDiv, IEEE-754 FPU, un-pipelined FDiv, and the
CSR file — including a **UVM register model (RAL)** of the real RISC-V CSRs
that BOOM implements, and **branch-speculation kill** checking.

The whole tree compiles cleanly against the official Accellera UVM library
(checked with `slang`, strict IEEE 1800-2017).

```
boom_exe_uvm/
├── rtl/
│   ├── boom_exe_types_pkg.sv   shared types: uop codes, IEEE-754 helpers, CSR addrs
│   └── boom_exe_dut.sv         behavioral execute-pipeline model (stand-in for BOOM RTL)
├── tb/
│   ├── boom_exe_if.sv          issue / branch / write-back interface + SVA
│   ├── boom_exe_pkg.sv         compilation unit for the UVM env
│   ├── tb_top.sv               TB top: clock, reset, DUT, run_test()
│   ├── seq/
│   │   ├── boom_exe_txn.sv     uop / branch-update sequence item
│   │   └── boom_exe_seq_lib.sv ALU, mul/div, FP-corner, CSR, branch-kill sequences
│   ├── agent/
│   │   ├── boom_exe_driver.sv  drives issue port, honors div/fdiv back-pressure
│   │   ├── boom_exe_monitor.sv observes issue + both write-back ports
│   │   └── boom_exe_agent.sv   sequencer/driver/monitor bundle (1 per issue port)
│   ├── ral/
│   │   └── boom_csr_ral.sv     UVM register model of BOOM's CSRs + bus adapter
│   ├── env/
│   │   ├── boom_exe_scoreboard.sv  independent RV64 + IEEE-754 reference model
│   │   ├── boom_exe_coverage.sv    opcode / FP-class / CSR / speculation coverage
│   │   └── boom_exe_env.sv         env: agent + sb + cov + RAL wiring
│   └── test/
│       └── boom_exe_tests.sv   test library (see below)
└── sim/
    └── Makefile                Questa / VCS / Xcelium / slang-lint targets
```

## Tests

| `+UVM_TESTNAME=`        | What it does |
|-------------------------|--------------|
| `boom_alu_test`         | Constrained-random integer ALU traffic (ADD…SRA), scoreboard-checked. |
| `boom_muldiv_test`      | iMul/iDiv incl. RISC-V M corner cases: divide-by-zero (`q=-1`, `r=dividend`), `MIN_INT / -1` overflow (`q=MIN_INT`, `r=0`), MULH/MULHU high halves. Exercises un-pipelined back-pressure. |
| `boom_fp_ieee754_test`  | Full cross of IEEE-754 special operands — ±0, ±inf, qNaN, sNaN, smallest/largest subnormal, min/max normal — across FADD/FSUB/FMUL/FMIN/FMAX/FDIV, plus FCLASS of every special, plus biased random. Checks results bit-exactly (canonical qNaN `0x7ff8_0000_0000_0000`) and the NV/DZ/OF/UF flags. |
| `boom_csr_ral_test`     | Register-model-driven CSR verification: reset-value mirror checks, frontdoor write/read-back of mscratch/mepc/mcause/mtval/mtvec, field-level RMW of `mstatus.MIE` and `mie` bits, the `fcsr = {frm, fflags}` alias, the fflags-accumulation side effect of FP write-backs, and free-running mcycle/minstret counters. |
| `boom_branch_kill_test` | Issues uops speculated under branch tags, then broadcasts resolve or mispredict. A killed uop that still writes back is an error (BOOM must gate off misspeculated responses). |
| `boom_full_test`        | All of the above back-to-back. |

Run e.g.:

```sh
cd sim
make questa  TEST=boom_fp_ieee754_test
make vcs     TEST=boom_csr_ral_test
make xcelium TEST=boom_full_test SEED=42
```

## How the RAL reaches the CSRs

BOOM does **not** rename CSRs; a CSR instruction is marked *unique*
(serializing) — the ROB drains before it issues, it reads its operand from
the PRF, executes in the Rocket CSRFile, and writes back. The TB reproduces
this path:

```
uvm_reg_sequence -> reg_map -> boom_csr_adapter -> exe sequencer -> driver
      (RAL write  = CSRRW uop,  RAL read = CSRRS uop with rs1=x0)
```

The adapter spaces CSR uops apart (`gap_cycles 4-8`) to mimic serialization,
and the driver completes a CSR uop only when its write-back returns the old
CSR value, so RAL reads receive real DUT data. The map's address is the
12-bit CSR number itself. WARL fields, RO ID registers (`marchid = 2`,
BOOM's open-source architecture ID), volatile counters and the
side-effect-prone FP CSRs are modeled with the appropriate field access /
volatility so `mirror(UVM_CHECK)` does the right thing.

## Hooking up real BOOM RTL

The behavioral DUT exists so the environment runs out of the box. To target
actual BOOM RTL:

1. Generate Verilog with Chipyard: `make verilog CONFIG=MediumBoomConfig`.
2. Replace the `boom_exe_dut` instance in `tb_top.sv` with the generated
   core (or `bind` `boom_exe_if` into `BoomCore`'s execution-unit
   hierarchy: the `iss_uops_*` issue signals, `brupdate` for branch
   resolution, and the `iresp`/`fresp` write-back ports).
3. Swap the scoreboard's `predict_fp` for a bit-accurate softfloat DPI
   reference (e.g. Berkeley softfloat) — the built-in model is exact for
   results and NV/DZ/OF/UF, but NX is only modeled when raised with OF/UF.
4. Widen the agent: instantiate one `boom_exe_agent` per issue port for a
   multi-issue configuration.

## Known simplifications

* One issue port (real BOOM: one dedicated port per Execution Unit).
* All pipelined units share one latency (BOOM really does pad the ALU to
  the FPU/iMul latency to share the write port, so this is faithful).
* CSR privilege checking, exceptions and PC-redirects are not modeled.
* FP is double precision only; single precision would upconvert like
  BOOM's fdiv (SP operands are upscaled to DP internally).

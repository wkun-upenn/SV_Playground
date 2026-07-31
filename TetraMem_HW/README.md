# TetraMem Systolic-Array — RTL DUTs + Testbenches

Module-level RTL implementations and self-checking SystemVerilog testbenches
for the three components defined in *Design Verification Based on UVM for the
Systolic Array Design*:

1. **Processing Element (PE)** — page 3
2. **`systolic_array`** (N×N mesh) — page 11
3. **`sub_sys`** (two-clock streaming sub-system) — page 12

> The assignment itself only requires a **UVM** testbench (RTL is optional).
> This package provides synthesizable-style RTL DUTs plus lightweight SV
> testbenches with a bit-accurate golden model, so a UVM environment can be
> built and regressed against something concrete. Everything is verified with
> **Verilator 5.x** (`--binary --timing`).

---

## File layout

```
TetraMem_HW/
├── rtl/
│   ├── pe.sv              # Processing element: signed MAC, double-buffered stationary weight
│   ├── systolic_array.sv  # N×N PE mesh + input skew / output de-skew + valid handshake
│   ├── async_fifo.sv      # Dual-clock Gray-pointer CDC FIFO (FWFT)
│   ├── data_align.sv      # A column→row transpose / zero-pad buffer
│   ├── systolic_ctrl.sv   # Sub-system controller FSM (sr_clk domain)
│   └── sub_sys.sv         # Top: FIFOs + controller + data-align + array
├── tb/
│   ├── matmul_pkg.sv      # Signed matmul golden model + helpers
│   ├── tb_pe.sv           # PE unit test
│   ├── tb_systolic_array.sv  # Module-level test (any N)
│   └── tb_sub_sys.sv      # Two-clock sub-system test (multiple M, CDC)
├── Makefile
└── logs/                  # captured simulation logs
```

## How to run

Requires Verilator ≥ 5.0 (for `--binary --timing`).

```bash
make pe        # PE unit test
make array     # systolic_array, N=4
make array2    # systolic_array, N=2 (the size worked in the PDF example)
make subsys    # sub-system, two clocks, M ∈ {1,2,3,4}
make all       # everything
make waves     # dump tb_array.vcd + tb_sub_sys.vcd
make clean
```

Latest results (see `logs/`):

| Test                     | Result                             |
|--------------------------|------------------------------------|
| `tb_pe`                  | PASSED — 807 checks                |
| `tb_systolic_array` N=4  | PASSED — 21 frames                 |
| `tb_systolic_array` N=2  | PASSED — 21 frames                 |
| `tb_sub_sys`             | PASSED — 15 matrices, 60 C rows    |

The array test was additionally re-run at **N = 1, 3, 8** and the sub-system at
the reverse clock ratio (sr slower than sys) — all pass.

---

## Design summary

### 1. Processing Element — `pe.sv`
Weight-stationary MAC cell (the "basic ALU unit" of page 3).

```
cout = a·b + cin      (registered)
aout = a              (registered, forwarded right)
```
* `a` flows **left→right**, partial sum flows **top→bottom**.
* Weight `b` is **stationary** and **double-buffered** (`w_active` / `w_load`)
  so the next B can be preloaded while the current one computes (page 10);
  a `swap_w` pulse activates it with no stall.
* All datapath outputs are registered → the mesh is a clean 2-D pipeline.

### 2. Systolic array — `systolic_array.sv`
`N×N` mesh with `PE(r,c)` holding `B[r][c]`. Column `c` spatially reduces
`Σ_r A[i][r]·B[r][c] = C[i][c]`, read out of the bottom.

To keep the external interface **whole-row-in / whole-row-out**, the array
skews/de-skews internally:
* activation `a_din[r]` is delayed **r** cycles before entering row r;
* column-c result is delayed **N-1-c** cycles on the way out;
* therefore `out_valid = in_valid` delayed by **2N-1** cycles, and each
  `c_dout` bus carries one fully-aligned row of C.

Interface (page 11) is preserved exactly, plus two control strobes that the
PDF explicitly allows ("control signals etc. are not listed"):

| Signal            | Meaning                                             |
|-------------------|-----------------------------------------------------|
| `b_din[0:N-1]`    | one row of B per **weight-load** cycle              |
| `w_load_en`       | qualifies `b_din` as sequential weight-load rows    |
| `w_swap`          | activate the freshly loaded weights                 |
| `a_din[0:N-1]`    | one row of A per **compute** cycle                  |
| `in_valid`        | activation stream valid                             |
| `c_din[0:N-1]`    | top-row partial-sum seed (0, or loop-back for M>N)  |
| `c_dout[0:N-1]`   | one aligned row of C                                |
| `out_valid`       | `c_dout` carries a valid row                        |

### 3. Sub-system — `sub_sys.sv`
Streams consecutive multiplies across two clock domains (page 12).

```
 din ─▶ input async_fifo ─▶ systolic_ctrl ─▶ data_align ─▶ systolic_array
        (sys_clk→sr_clk)      (sr_clk FSM)                      │
 dout ◀─ output async_fifo ◀──────────────── C rows ◀──────────┘
        (sr_clk→sys_clk)
```
* **`async_fifo`** — textbook Cummings dual-clock FIFO (Gray-code pointers,
  2-flop synchronizers, **registered `full`** to avoid a combinational loop,
  FWFT read). Handles the `sys_clk`/`sr_clk` CDC.
* **`systolic_ctrl`** — 6-state FSM: read M samples → load weights → swap →
  stream A → collect C → write results. Weight-load and result-capture are
  staged in local registers, fully decoupled from FIFO flow-control, so an
  empty input FIFO or full output FIFO can never corrupt array timing.
* **`data_align`** — buffers A one column at a time (bus format) and reads it
  back one row at a time (array format), zero-padding contraction indices
  `> M-1`.

**Bus formats** (`BUS_WIDTH = 2·DIN_WIDTH·N`):
* `din` sample = `{ A column k (N×DIN_WIDTH) , B row k (N×DIN_WIDTH) }`
* `dout` word  = one row of C (N × 2·DIN_WIDTH)

---

## Golden reference model — `matmul_pkg.sv`
`golden_matmul(N, M, OW, A, B, C)` computes signed `C = A×B` and truncates each
element to `OW = 2·DIN_WIDTH` bits **exactly** matching the hardware
accumulator wrap, so scoreboard comparison is bit-accurate for *any* input
(not only the non-overflowing subset). This is the model a UVM scoreboard
would reuse.

---

## Assumptions & scope (called out per the assignment)

1. **Square contraction on the array level.** `systolic_array` targets
   `M = N` (the case illustrated throughout the PDF). General `M > N` is
   supported *structurally* via the `c_din` seed input (loop-back point) but
   the iteration control for `M > N` is not implemented at the array level.
2. **Sub-system supports `1 ≤ M ≤ N`.** `M_eff = min(M, N)`; unused weight
   rows and activation columns are zero-padded, so an `N×M · M×N` product is
   computed correctly on the `N×N` mesh. `M > N` is clamped to `N` (would
   require `c_dout→c_din` loop-back accumulation across `⌈M/N⌉` passes — noted
   as the extension point, not built).
3. **Two implied array control strobes** (`w_load_en`, `w_swap`) were added;
   the PDF explicitly notes additional control signals are not listed.
4. **Frame spacing (throughput).** Consecutive frames are processed
   sequentially (the array physically holds one active weight set at a time;
   the double buffer removes the *reload* stall, not the drain). Peak
   "one matrix every M cycles" throughput would need diagonal wavefront
   weight-swapping — a documented enhancement, not required for functional
   correctness.
5. **Accumulator width** is `2·DIN_WIDTH` per the spec; results wrap on
   overflow, and the golden model reproduces that wrap.
6. **Reset** is active-low and asynchronous; both FIFO domains share it.

## Verification plan (how the testbenches map to a UVM env)

| SV testbench piece                     | UVM analogue                          |
|----------------------------------------|---------------------------------------|
| `run_frame` / `run_matrix` stimulus    | sequence + driver                     |
| `out_valid`/FIFO sampling loops        | monitor                               |
| `matmul_pkg::golden_matmul` + compare  | scoreboard + reference model          |
| `$urandom_range` operands, sweep of M  | constrained-random sequences          |
| `-GN=<n>`, `-GSR_HALF=<n>` overrides   | parameterized/config-driven env       |

Reuse across levels: the **same** `matmul_pkg` golden model and the same
packed bus/skew conventions drive both the module-level and sub-system-level
checks — mirroring requirement (4) of the assignment (reuse DV components
across module and sub-system levels).

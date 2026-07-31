Firstly, thank you for your time reading the document and the files. I sincerely value this opportunity and I hope this document will make my design setting clear for everyone evaluating the design.

# Systolic-Array Sub-System Verification

The assignment asks for UVM testbench for two DUTs: a module-level `systolic_array` and a two-clock `sub_sys`. Although RTL is not demanded, I've created behavioral model inside [`/rtl`](/rtl/) folder.

---

## 1. File structure

```
uvm/
├── rtl/                              # behavioral DUTs (functional models, exact PDF interfaces)
│   ├── systolic_array.sv            #   page-11 array: outer-product accumulate → stream C rows
│   └── sub_sys.sv                   #   page-12 sub-system: in-FIFO → compute → out-FIFO, 2 clocks
│
├── tb/
│   ├── interfaces/                  # INTERFACES ONLY (pins + clocking blocks + init_drv), no logic
│   │   ├── sa_if.sv                 #   array interface  (clk)
│   │   └── ss_if.sv                 #   sub-sys interface (sys_clk + sr_clk)
│   │
│   ├── common/                      # shared, DUT-agnostic pieces
│   │   ├── systolic_defines.svh     #   geometry: `DW=8, `NN=4, `ACCW, `BUSW
│   │   ├── matmul_item.svh          #   the transaction + the GOLDEN model (compute())
│   │   └── matmul_pkg.sv
│   │
│   ├── sa/                          # systolic_array agent (one input driver, two monitors)
│   │   ├── sa_driver.svh  sa_monitor.svh  sa_agent.svh  sa_pkg.sv
│   │
│   ├── ss/                          # sub_sys agents — a WRITE channel and a READ channel
│   │   ├── ss_driver.svh  ss_monitor.svh  ss_agent.svh  ss_pkg.sv
│   │
│   ├── env/                         # everything that ties the agents together
│   │   ├── matmul_scoreboard.svh    #   golden-vs-DUT checker (reused at BOTH levels)
│   │   ├── matmul_coverage.svh      #   transaction covergroup  (uvm_subscriber)
│   │   ├── sa_coverage.svh          #   array-signal covergroup
│   │   ├── ss_coverage.svh          #   sub-system-signal covergroup
│   │   ├── virtual_sequencer.svh    #   holds sa/wr/rd sequencer handles
│   │   ├── systolic_env.svh  env_pkg.sv
│   │
│   ├── seq/                         # stimulus
│   │   ├── matmul_sequences.svh     #   matrix_seq, matrix_directed_seq, read_seq, ss_vseq (multichannel)
│   │   └── seq_pkg.sv
│   │
│   ├── tests/                       # base test + ONE FILE PER TEST
│   │   ├── base_test.sv             #   builds env, provides run_seqs()/wait_sb() hooks
│   │   ├── sa_smoke_test.sv         sa_random_test.sv
│   │   ├── ss_smoke_test.sv         ss_multichannel_test.sv
│   │   ├── ss_param_test.sv         ss_backpressure_test.sv
│   │   ├── ss_random_test.sv        regression_test.sv
│   │   ├── coverage_test.sv         
│   │   └── test_pkg.sv
│   │
│   └── tb_top.sv                    # clocks, DUT + interface instances, config_db, run_test
│
├── filelist.f                       # +incdir paths and compile order for xrun
├── run.sh                           # run ONE test with coverage
├── run_all.sh                       # run EVERY test, then merge coverage
├── merge_cov.tcl                    # IMC merge script
├── edaplayground/                   # flat copy of every file for EDA Playground (make copy)
├── result-3/                        # a real Xcelium run of coverage_test (logs + coverage db)
├── README.md                        # quick reference (how to run, test/coverage tables)
└── DEVELOPMENT.md                   # this file
```

The layering is clear: **common → agents → env → seq → tests**. My instinct was to create individual tests that verifies different components in the system.

---

## 2. How it came together (the development story)

**Start from the interfaces.** The first real decision was to copy the page-11 and page-12 port lists *verbatim* into `sa_if.sv` / `ss_if.sv` and refuse to add "helpful" side-band signals. An earlier draft had invented control pins (weight-load enables, swap strobes); those were thrown out. If the DUT port list doesn't match the spec figure exactly, the environment isn't verifying the thing the assignment describes. The interface files hold *only* the pins, the clocking blocks, and a small `init_drv()` subroutine — no design logic — so the interface can never quietly become the DUT.

**Build the simplest behavioral model.** The array is a weight-stationary systolic array on paper, but functionally it computes `C = A·B` as a sum of rank-1 (outer-product) updates: each valid cycle presents one *column* of A on `a_din` and one *row* of B on `b_din`, and the model does `C[i][j] += a_din[i]·b_din[j]`. Over the `M` valid cycles that becomes `C[i][j] = Σ_k A[i][k]·B[k][j]`. That is the whole design — no PE array, no timing model — and it's exactly enough to verify the *interface behavior* the assignment cares about.

**Build the environment bottom-up.** The order that kept things sane:

1. `matmul_item` + the golden `compute()` — get a transaction and a reference model that agree on signedness and overflow *before* touching UVM plumbing.
2. One agent per interface (`sa`, and `ss` split into write/read channels).
3. The env: scoreboards, coverage, the virtual sequencer.
4. Sequences, including the multichannel virtual sequence.
5. Tests, thinnest layer, one file each.

**Few bugs found during tests.** Three bugs shaped the final design and are worth remembering because they're the non-obvious part:

- *Driving pins on the wrong edge raced the DUT.* The first array driver poked `a_din`/`b_din` at `posedge`, the same edge the DUT sampled — the classic read/write race. Every pin is now driven through a **clocking block**, and `init_drv()` idles the pins through that *same* clocking block, so the driver is the one and only writer of each pin. No races, no top-level contention.

- *Combinational outputs over a SystemVerilog queue went stale on Xcelium.* The sub-system FIFOs were first written with `queue.push_back/pop_front` and an `assign`/`always_comb` for `dout`/`full`/`empty`. Xcelium does not reliably re-evaluate combinational logic when a queue is mutated procedurally, so the outputs lagged by a matrix or two. The fix was to drop queues entirely and use a **memory array + integer read/write pointers**; the outputs are now plain variables, and the combinational logic re-evaluates the way you'd expect.

- *Covergroup bins named after keywords wouldn't compile.* `small`/`large`/`medium` are reserved Verilog words; using them as bin names produced a cascade of "package could not be bound" errors that looked like something much worse. Renamed to `sml`/`mid`/`lrg`.

**Finally, close coverage on purpose.** Once everything was running, I watched my random tests stall around 65% — they kept missing specific `M` values and the `=0` operand corners. Rather than randomize harder and just hope, I wrote a directed `coverage_test` that marches through exactly the bins that were still open. More on that below.

---

## 3. Techniques used

| Technique | Where | Why it matters |
|-----------|-------|----------------|
| **Exact-spec interfaces in their own files** | `tb/interfaces/` | The environment verifies the spec's port behavior, not an embellished version of it. |
| **Clocking blocks for all pin access** | `sa_if`, `ss_if` + drivers | Race-free drive/sample; `init_drv()` idles through the same block so there's a single driver per pin. |
| **Golden model + reused scoreboard** | `matmul_item::compute()`, `matmul_scoreboard` | One reference model and one checker verify *both* the array and the sub-system — no duplicated truth. |
| **Memory-array + pointer FIFOs** | `sub_sys.sv` | Portable combinational FIFO outputs on Xcelium (queues don't re-trigger comb logic reliably). |
| **Two asynchronous clocks** | `sys_clk` (period 10) vs `sr_clk` (period 14) | The bus can outrun compute; CDC is exercised on every run. `sr_clk` is intentionally the slower one. |
| **Output-FIFO back-pressure** | `sub_sys` compute engine | The engine stalls when the output FIFO is full, so a slow reader can never overflow it — and the FIFOs actually *fill*, which makes the full/empty coverage bins reachable. |
| **Multichannel virtual sequence** | `ss_vseq` | `fork` a write sequence and a read sequence on two sequencers so the sub-system is written and drained concurrently, like a real streaming client. |
| **Constrained-random via `$urandom`** | drivers, `matrix_seq` | Portable and seed-controllable (`-svseed random`); avoids the `randomize()` portability pitfalls seen on other simulators. |
| **`uvm_subscriber` coverage** | `matmul_coverage` | Coverage taps the monitors' analysis ports, so it samples the *same* transactions the scoreboard checks. |
| **Directed coverage closure** | `coverage_test` | Deterministically hits the bins random stimulus leaves open (specific `M`, the `=0` corners, overflow). |
| **One-file-per-test off a base test** | `tests/` | `base_test` builds the env once; each test overrides only `run_seqs()`. Adding a scenario is adding one small file. |

---

## 4. How the tests are designed

Every test extends `base_test`, which builds the environment and offers two hooks: `run_seqs(phase)` (what stimulus to run) and `wait_sb(sb, n)` (wait until a scoreboard has checked `n` matrices). A test is therefore just a `run_seqs()` override. The scoreboard for a level that a given test doesn't exercise reports **IDLE** rather than failing, so partial-scope tests stay green.

The suite is layered from "does anything work at all" up to "prove coverage":

| Test | Level | Intent |
|------|-------|--------|
| `sa_smoke_test`        | array   | Bring-up: 3 square (M=N) multiplies. |
| `sa_random_test`       | array   | 12 constrained-random matrices, random `M ∈ [1..N]`. |
| `ss_smoke_test`        | sub-sys | One M=N multiply all the way through the FIFOs. |
| `ss_multichannel_test` | sub-sys | 10 streamed matrices with the write and read channels running concurrently. |
| `ss_param_test`        | sub-sys | Sweep `M = 1..N`, one `M` per drained batch. |
| `ss_backpressure_test` | sub-sys | Deliberately slow reader so the output FIFO fills — exercises FWFT + empty/full under load. |
| `ss_random_test`       | sub-sys | Random batch sizes and random `M`. |
| `regression_test`      | both    | Long randomized run (~40 array + ~30 sub-sys) — the everyday soak test. |
| `coverage_test`        | both    | Directed run that closes **all three** covergroups to 100%. |

The design philosophy is "smoke → random → directed." Smoke tests catch gross wiring mistakes cheaply. Random tests find the bugs you didn't think of. But random alone leaves a stubborn coverage tail, so `coverage_test` finishes the job deterministically: its Part 1 drives directed array matrices that force each `M`, each operand sign and magnitude bucket, the result sign, and an accumulator overflow; its Part 2 sweeps `M` through the sub-system so the shallow `DEPTH=4` FIFOs fill and the full/empty bins are hit. One test, all three covergroups closed.

---

## 5. The two waveforms — and why they prove correctness

### [Diagram 1](systolic_array_verified.webp) — the array computes C = A·B (zoomed-out, full run)

This screenshot shows the standalone array `dut_sa`: `a_din[0..3]`, `b_din[0..3]`, and the 16-bit `c_dout[0..3]`. Because the view spans the whole run, you don't see the four C rows flick past one at a time — what stays visible between frames is the **last row (i = 3)** of each result matrix, held on the bus until the next frame overwrites it.

Take the first frame's inputs straight off the trace:

```
a = [ -5,  52, -111,  33 ]      (a_din[0..3])
b = [  5, -40,  -98,  99 ]      (b_din[0..3])
```

With `c_din = 0` and a single valid cycle (`M = 1`), the model reduces to a pure outer product `C[i][j] = a[i]·b[j]`. The held row is `i = 3`, i.e. `a[3]·b`:

```
33 ×   5  =   165   → c_dout[0] = 165     ✓
33 × −40  = −1320   → c_dout[1] = −1320   ✓
33 × −98  = −3234   → c_dout[2] = −3234   ✓
33 ×  99  =  3267   → c_dout[3] = 3267    ✓
```

The next frame confirms it again — `a[3] = −111`, `b = [5, 75, 58, −34]`:

```
−111 ×   5 =  −555   → c_dout[0] = −555    ✓
−111 ×  75 = −8325   → c_dout[1] = −8325   ✓
−111 ×  58 = −6438   → c_dout[2] = −6438   ✓
−111 × −34 =  3774   → c_dout[3] = 3774    ✓
```

Both frames match to the digit. **The array is computing correctly** — it does a multiply-accumulate of the outer product `a ⊗ b`, seeded by `c_din`, and streams the result rows out on `c_dout`.

### [Diagram 2](subsystem_verified.webp) — the sub-system's datapath

The second screenshot zooms into the moment `coverage_test` hands off from Part 1 (array) to Part 2 (sub-system). Alongside the array's `dut_sa` signals it shows the sub-system's internals, `dut_ss.imem[0..3]` (the input FIFO) and `dut_ss.hold[0..3]` (the computed C rows), transitioning from `XXXX` to real data around 2.9 µs — that transition *is* the sub-system starting to run.

Both `imem` and `hold` are 64-bit because `BUS_WIDTH = 2·DIN_WIDTH·N = 64`; each word packs four lanes:

- **`imem[k]`** is one input word: the high 32 bits carry a *column of A*, the low 32 bits carry a *row of B* (four signed 8-bit values each). For example `imem[0] = 0x8A33_D414_429C_966C` unpacks to A-column `[−118, 51, −44, 20]` and B-row `[66, −100, −106, 108]`.
- **`hold[i]`** is one *computed C row* — four signed 16-bit results packed together. For example `hold[0] = 0x0528_F830_F7B8_0870` is the row `[+1320, −2000, −2120, +2160]` (`0x0528 = 1320`, `0xF830 = −2000`, and so on).

So the picture is: packed A-column/B-row words land in `imem`, the compute engine (on `sr_clk`) drains them, multiply-accumulates, and parks each finished C row in `hold` before pushing it to the output FIFO. Seeing `imem` fill and `hold` populate with well-formed packed C rows is the visual confirmation that the FIFO-in → compute → FIFO-out pipeline is doing real work — and the numeric proof that every one of those rows is *correct* is the scoreboard, quoted next.

---

## 6. Coverage closure and pass/fail (evidence in `result-3/`)

The waveforms are corroboration; the authoritative check is the scoreboard plus the covergroup percentages. [`result-3/`](result-3/) is a genuine Xcelium 25.03 run of `coverage_test` (log: [`result-3/xrun.log`](result-3/xrun.log), coverage database under [`result-3/cov_work/`](result-3/cov_work/)). Straight from that log:

```
UVM_INFO matmul_coverage.svh(56) : [COV] TXN coverage    = 100.00% over 36 matrices
UVM_INFO sa_coverage.svh(43)     : [COV] ARRAY signal coverage  = 100.00%
UVM_INFO ss_coverage.svh(46)     : [COV] SUBSYS signal coverage = 100.00%

UVM_INFO matmul_scoreboard.svh(51): [SCB] env.sa_sb: PASSED : 24 matrices matched
UVM_INFO matmul_scoreboard.svh(51): [SCB] env.ss_sb: PASSED : 12 matrices matched

** Report counts by severity
UVM_WARNING :    0
UVM_ERROR   :    0
UVM_FATAL   :    0
```

That's the whole story in five lines: all **three covergroups at 100.00%** (transaction, array-signal, sub-system-signal), **36 matrices checked against the golden model** (24 at the array level + 12 through the sub-system) with **every one matching**, and **zero errors, zero fatals, zero warnings**.

## To reproduce the run, follow the [README.md](edaplayground/README.md).


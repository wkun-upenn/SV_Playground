# BOOM Execute-Pipeline UVM Testbench (`uvm_exe`)

面向 Chipyard `MediumBoomV3Config` 生成的 BOOM v3 core（Chisel → FIRRTL → SystemVerilog，见 `../gen-collateral/`），
针对 **execute pipeline** 做 block-level 验证：三个执行单元 + 整数发射队列 + CSR 文件（带 UVM 寄存器模型）。

| DUT 模块 | 内容 | 端口 |
|---|---|---|
| `ALUExeUnit_1` (alu0) | 3-stage ALU + JMP unit + iMul(lat 3) + IntToFP(lat 2) | `iresp`, `ll_fresp`, `bypass[3]`, `brinfo` |
| `ALUExeUnit_2` (alu1) | 1-stage ALU + CSR + 迭代式 MulDiv | `iresp`, `bypass[1]`, `brinfo` |
| `FPUExeUnit` (fpu) | FMA(lat 4) + FDivSqrt(迭代) + FPToInt | `fresp`(+fflags), `ll_iresp` |
| `IssueUnitCollapsing_2` (iq) | 20-entry age-ordered 整数发射队列 | 2 dispatch / 2 issue / 5 wakeup + spec-load wakeup |
| `CSRFile` (csr) | rocket-chip CSR 文件（fcsr/fflags/frm、mstatus…、计数器、PMP）| rw 端口（由 alu1 的 CSR uop 写回驱动 / RAL agent）、fcsr_rm → FPU、fcsr_flags ← FP 写回 |

## 简历对应关系

| 简历描述 | 代码位置 |
|---|---|
| End-to-end UVM env for the OoO RISC-V execute pipeline | `tb/env/boom_exe_env.sv`（3 个参数化 exe agent + brupd agent + iq agent + virtual sequencer） |
| DPI-C assertion-based checks | `tb/boom_exu_if.sv` / `tb/boom_iq_if.sv` / `tb/boom_csr_if.sv`：50 条 SVA (A01–A46) + 16 条 cover property，`bind` 即可复用到 core level |
| Functional coverage, 22+ covergroups | `tb/env/boom_exe_coverage.sv` (cg01–cg22) + `tb/env/boom_iq_scoreboard.sv` (cg23–cg26) + `tb/agent/boom_csr_agent.sv` (cg27)，共 27 个 |
| Register model (UVM RAL) | `tb/ral/`：62 个 CSR / 169 个 field 的寄存器模型（由 `sim/csr_spec.py` 生成）、adapter、显式 predictor、fflags 副作用 predictor、alias/WARL callback、backdoor；12 个 RAL test（t83–t94）|
| Spike golden reference | 两层：(1) `dpi/boom_fp_ref.c` + `dpi/softfloat/`：Berkeley SoftFloat-3e **RISC-V specialization——与 Spike 同一份浮点后端**，DPI-C 调用，逐条指令预测；(2) **Spike 本体作为 trace 级黄金参考**：`sim/spike_logs/` 是 riscv-tests ISA 套件（rv64ui/um/uf/ud，89 个程序）在 Spike 上的 commit log，`dpi/boom_spike_trace.c` 通过 DPI-C 回放（架构寄存器状态 + 译码 + 期望结果），`tb/seq/boom_spike_seq_lib.sv` 把每条指令送进执行单元，scoreboard 把 DUT 结果同时和 SoftFloat 模型、Spike 的 rd/fflags/next-pc 比对，`frflags` 等 CSR 读回值和真实 CSRFile 比对（t95–t100）；整数侧 `tb/ref/boom_exe_ref_model.sv` 按 rocket ALU/MulDiv 语义建模 |
| 80+ directed & constrained-random tests | `tb/test/boom_exe_tests.sv`：100 个 test（`sim/tests.yml` 共 ~270 个 seed-run）；constrained-random 94 个 + Spike trace 回放 6 个 |
| RV64I/M, FP corners, OoO issue-queue scenarios | `tb/seq/boom_exe_seq_lib.sv`（47 个序列：op-class 随机 + 14 个 directed corner 序列）、`tb/seq/boom_iq_seq_lib.sv`（11 个 IQ 序列） |
| 100% coverage closure | `t82_coverage_closure` + `sim/regress.py --cov`（VCS `urg` 合并报告） |

## 目录

```
uvm_exe/
├── dut/boom_exe_dut.f            RTL 文件列表（5 个顶层 DUT 的 59 个模块，由 gen_dut_glue.py 生成）
├── dpi/boom_fp_ref.c             DPI-C 浮点 golden model（op 编码见 ref model）
├── dpi/softfloat/                SoftFloat-3e 子集 + RISCV specialization
├── tb/boom_exe_defs_pkg.sv       常量、uopc/FU/FN/OP1/OP2/IS/BR 编码、exe_op_e、decode_op()、imm 打包、
│                                 hardfloat 65-bit recode/NaN-box 转换（fp_recode / fp_ieee，已用 Verilator round-trip 验证）
├── tb/boom_exe_uop_types.svh     uop_t / rsp_uop_t（生成）
├── tb/boom_exe_dut_inst.svh      DUT 例化 + 接口连线（生成）
├── tb/boom_exu_if.sv             执行单元接口 + SVA A01–A31
├── tb/boom_iq_if.sv              发射队列接口 + SVA A32–A40
├── tb/boom_csr_if.sv             CSRFile 接口（RAL agent / pipeline 双 master 的 mux）+ SVA A41–A46
├── tb/ral/boom_csr_reg_block.sv  寄存器模型（生成：sim/gen_ral.py ← sim/csr_spec.py），boom_csr_reg_cbs.sv（alias / WARL callback），boom_csr_adapter.sv（adapter + fflags predictor）
├── tb/seq/                       boom_exe_txn（指令级 txn，含 lower() 降为 MicroOp）、iq txn、csr txn、序列库（含 boom_ral_seq_lib.sv）
├── tb/ref/boom_exe_ref_model.sv  预测 exp_data / exp_flags / exp_port / brinfo
├── tb/agent/                     exe agent（driver/monitor）、brupd agent、iq agent、csr agent（RAL 的 frontdoor）
├── tb/env/                       cfg、scoreboard（per-unit，按 rob_idx 跟踪 in-flight）、coverage、iq scoreboard、env
├── tb/test/                      base test（含 CSR init：mstatus.FS 打开）+ 94 tests
├── tb/tb_top.sv                  时钟/复位/接口/DUT/run_test
├── tb/smoke/                     UVM-free 的 Verilator 冒烟测试（golden model × RTL 全 op 对拍 + kill/flush 时序表）
├── sim/Makefile                  VCS / Questa / Xcelium 编译运行，lint，smoke，regress，coverage
├── sim/smoke.mk                  Verilator 构建
├── sim/tests.yml + regress.py    回归列表 + 并行回归脚本（junit 输出）
├── sim/lint_slang.py             pyslang 全量 elaboration（RTL + UVM TB，对 uvm-core）
├── sim/csr_spec.py + gen_ral.py  CSR 规格表（在 RTL 上实测得到）→ 生成 RAL
└── docs/vplan.md                 验证计划、检查清单、RTL findings、覆盖率模型
```

## 怎么跑

```bash
cd BOOM_RTL/uvm_exe/sim

# 1. 不需要仿真器 license 的两步（本仓库交付前已在 Verilator 5.020 / slang 11 上跑通）
make smoke N=300 SEED=2      # 116 个 op × 300 组随机/corner 操作数 与 golden model 逐拍对拍
make smoke-spike             # 89 个 riscv-tests 程序的 Spike commit log 回放进 RTL（约 3 万条指令，Spike 结果为黄金参考）
make lint                    # UVM_CORE=/path/to/uvm-core：整套 TB + RTL 用 slang 完整 elaborate

# 2. 商业仿真器
make SIM=vcs     TEST=t10_int_all_random SEED=3 run
make SIM=questa  TEST=t43_fp_all_random  PLUS="+ll_ready_pct=50 +brmode=2" run
make SIM=xcelium TEST=t76_full_random WAVES=1 run
make SIM=vcs     TEST=t97_spike_rv64uf run                 # Spike trace 回放（sim/spike_logs/rv64uf.list）
make SIM=vcs     TEST=t01_alu_rr_smoke PLUS="+spike_log=/abs/path/my_program.log" run   # 任意程序的 Spike log
make spike-logs RISCV_TESTS_ISA=$RISCV/riscv64-unknown-elf/share/riscv-tests/isa      # 用 Chipyard 的 spike 重新生成 log
./regress.py --sim vcs --jobs 16 --tag fp --tag ooo     # 子集
./regress.py --sim vcs --cov                             # 全量 + 覆盖率合并
```

所有 test 的旋钮都可以从命令行覆盖：`+n_txn= +max_delay= +ll_ready_pct= +brmode=0..4 +exe_seq=<class> +iq_seq=<class> +ral_seq=<class> +csr_rm +no_iq +no_cov +spike_log=a.log,b.log +spike_list=rv64uf.list +spike_max=N`。

## 架构要点

* **指令级 txn，驱动侧降级**：sequence 只描述 "FADD.D rs1 rs2 rm"，`boom_exe_txn::lower()` 按 BOOM decode/rename/regread 的方式生成 `uop_t`
  （uopc、fu_code、ctrl.*、imm_packed 打包、CSR zimm 放 prs1[4:0]、rm 放 imm_packed[2:0]）和 65-bit hardfloat recoded 操作数。
* **Monitor 独立重建**：monitor 从总线上的 uop 反解出 txn（`op_from_uop/ctrl_from_uop`、`fp_ieee` 解码），scoreboard/coverage 完全不依赖 driver。
* **Scoreboard 时序模型**（已在 RTL 上用 smoke 表验证）：branch mispredict 在 k ≤ latency 的任何一拍都 squash；flush 在 k < latency squash，
  k == latency 那拍结果照常写回（PipelinedFunctionalUnit 只 gate 下一级）；`ll_*` 队列口同规则且队列内容不受 flush 影响；迭代单元（div/fdiv/fsqrt）标记为 ambiguous。
* **IQ 事务级模型**：age-ordered、readiness、registered wakeup、spec-load poison + ld_miss squash、branch kill，检查 issue 的 uop 存在/就绪/唯一/年龄序/不饿死。
* **fu_types 握手**：driver 只在单元广播的 `fu_types` 包含该 FU 时发请求（div/fdiv/i2f/f2i 忙时被屏蔽），和真实 issue 逻辑一致。
* **Spike trace 回放（第二黄金参考）**：Spike `--log-commits` 的每一行 = 一条已提交指令的 pc / 编码 / 架构级写入。`dpi/boom_spike_trace.c` 顺序回放，
  维护 x0–x31 / f0–f31 / fflags / frm，因此对每条指令都能给出 **它消费的操作数值**（DUT 没有寄存器堆，操作数由 TB 提供）和 **Spike 算出的结果**。
  `boom_spike_trace_seq` 把可回放的指令（RV64IM、Zicsr、F/D 全部算术 / 比较 / 转换 / 搬移）做成普通 `boom_exe_txn` 走同一套 driver→monitor→scoreboard，
  期望值放进 `boom_spike_oracle`（按 unit+rob_idx 交接），scoreboard 在 SoftFloat 检查之外再比 Spike 的 rd、`(fflags_before | dut_flags) == fflags_after`、
  分支 taken / JALR 目标 == Spike 的 next pc；CSR 指令像 BOOM 一样串行化（前后 drain），`boom_spike_csr_checker` 把 CSRFile 的 rdata 和 Spike 的 rd 比——
  也就是 FPU/I2F 两条路径置的标志必须真的累积进硬件 fflags 再被 `frflags` 读出来。load/store/fence/ecall/mret 不可回放，只更新回放状态。
  op 词表不硬编码：SV 启动时把 exe_op_e 的名字逐个注册给 C（`spike_trace_register_op`），两边不可能悄悄错位。
* **寄存器模型（RAL）**：`CSRFile` 按 core.scala 的接法接进来——alu1 的 CSR uop 写回驱动 rw 口、FP 写回的 fflags OR 进 fcsr、fcsr_rm 回送 FPU。
  RAL 的 map 地址就是 12 位 CSR 号（word addressing）；`set_auto_predict(0)`，镜像只由 monitor 看到的访问更新（显式 `uvm_reg_predictor`），
  所以 RAL 自己的访问和流水线里执行的 CSRRW/CSRRS/CSRRC 一视同仁（S/C 在 adapter 里按 CSRFile 的 RMW 折成最终值）；
  fflags 的硬件副作用由单独的 predictor 累加进镜像；fcsr↔fflags/frm、sstatus↔mstatus、sie/sip↔mie/mip&mideleg、cycle←mcycle 用 alias callback；
  WARL（mepc/mtval 40 位符号扩展、xtvec 对齐、MPP=2→U、medeleg/mideleg 合法位、satp mode、pmpcfg 锁）用 post_predict callback / do_predict override。
  规格表 `sim/csr_spec.py` 里的复位值、可写位、WARL 规则全部是在 RTL 上用 smoke 实测出来的（见 `make smoke` 的 "CSR characterisation" 表）。

## 已经验证到的程度

* slang 完整 elaboration（含 uvm-core 1.2）：0 error。
* Verilator smoke：116 op × 300 × 2 seeds = 69,600 笔事务，数据/fflags/端口/brinfo **0 mismatch**，pipeline 延迟 0 偏差；
  kill/flush 时序表与 scoreboard 模型一致；CSRFile 接线（alu1 写回 → rw 口、fflags 累加、frm → FPU 动态舍入、RMW 语义、
  fcsr 别名）全部在 smoke 里用真实事务验证过，RAL 规格表的每个复位值 / 可写位 / WARL 规则都来自这张实测表。
* Verilator `make smoke-spike`：89 个 riscv-tests 程序、29,963 条指令回放进 RTL，与 Spike 比对 data 22,392 / fflags 757 / 分支 4,271 / CSR 读回 464 次，**0 错误**
  （两个 seed，前端预测随机）。同一份 DPI 库和同样的比对规则也接在 UVM 的 t95–t100 里。
* 商业仿真器上的 UVM 回归尚未在此环境运行（无 license）；`sim/Makefile` 对 VCS/Questa/Xcelium 的调用是按各自手册写的，
  第一次跑请从 `t01_alu_rr_smoke` 开始。

## RTL findings（详见 docs/vplan.md）

0. **mstatus.FS 复位为 Off，CSRFile 在 FS=0 时收到 FP flags 会 `$fatal`**（CSR.scala:1203）：core 里 boot code 会先打开 FS；
   block-level 环境里没人做这件事，所以 base test 在任何 FP 流量前先用 RAL 写 mstatus.FS=Initial。

1. **W1 `fdiv.s`/`fsqrt.s` 遇 sNaN 不置 NV**：FDivSqrtUnit 用 `RecFNToRecFN` 把单精度上转成双精度，转换器的 exceptionFlags 被丢弃，
   除法器只看到已经安静化的 canonical NaN。golden model 里以 `waive_fdiv_s_snan_nv` 开关复现（默认打开，便于回归），关掉即报 fflags mismatch。
2. **JALR cfi_idx 的 start_bank 异或被综合掉**：`bankBytes = 8`，`pc_lob ^ 8` 只影响 bit 3，而 cfi_idx 取 `[2:1]`，因此生成的 RTL 直接用 `pc_lob[2:1]`——
   最初 golden model 假设 bankBytes = 4，被 smoke 抓出。
3. ALU 对 branch 也产生 `iresp.valid`（dst_rtype = RT_X，写回由下游 `rf_wen` 过滤），数据是比较用的 ALU 结果（BEQ/BNE → SUB，BLT/BGE → SLT）。

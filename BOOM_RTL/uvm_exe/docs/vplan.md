# Verification Plan — BOOM v3 Execute Pipeline (MediumBoomV3Config)

## 1. 范围

**DUT**：`ALUExeUnit_1`（alu0）、`ALUExeUnit_2`（alu1）、`FPUExeUnit`、`IssueUnitCollapsing_2`（整数 IQ）、`CSRFile`，
均取自 Chipyard 1.13 `MediumBoomV3Config` 生成的 RTL（`../gen-collateral/`），共 59 个模块。
执行单元 / IQ 在 core 里由寄存器堆 / 发射逻辑 / ROB 连接，这里由 UVM agent 代替这些邻居；CSRFile 按 core.scala 接线
（alu1 的 CSR uop 写回 → rw 口，FP 写回 fflags → fcsr，fcsr_rm → FPU），并额外挂一个 RAL agent 作为第二个 master（优先）。

**不在范围**：LSU / MemExeUnit、FP 发射队列、寄存器堆、ROB 提交、rename、前端。

## 2. 特性清单与检查方式

| # | 特性 | 激励 | 检查 |
|---|---|---|---|
| F1 | RV64I 算术/逻辑/移位/比较（含 W 形式）| exe_alu_*_seq, exe_shift_sweep_seq, exe_int_corner_cross_seq | scoreboard 数据 + latency + bypass；A05–A10 |
| F2 | LUI / AUIPC / JAL / JALR 链接值（含 RVC pc+2）| exe_jump_seq, exe_jalr_matrix_seq | scoreboard 数据 + brinfo（jalr_target、cfi_idx、mispredict 4 种原因）；A13/A14 |
| F3 | 6 种条件分支 × taken/not × 预测 | exe_branch_seq, exe_branch_matrix_seq | brinfo mispredict/taken/pc_sel/target_offset；cg06 |
| F4 | RV64M 乘法（MUL/MULH/MULHU/MULHSU/MULW）| exe_mul_seq | 数据 + 3 拍延迟（A11）|
| F5 | RV64M 除法/取余（8 条，含 /0、overflow、W）| exe_div_seq, exe_div_corner_seq | 数据；fu_types 屏蔽/恢复（A15/A16）；写口冲突 exe_div_collision_seq（cg20）|
| F6 | CSR 6 条（rs1 / zimm 数据通路）| exe_csr_seq, exe_csr_sweep_seq | 数据 = 写入值、1 拍延迟 A17 |
| F7 | FP 加减乘 / FMA 4 种 × S/D | exe_fp_*_seq, exe_fma_corner_seq, exe_fp_corner_cross_seq | SoftFloat 逐 bit + fflags（A18/A21/A22）|
| F8 | FDIV/FSQRT × S/D，含早退（NaN/Inf/0，3 拍）| exe_fdiv_seq, exe_fdiv_collision_seq | 数据 + fflags；A23；fresp 仲裁 |
| F9 | FSGNJ*/FMIN/FMAX/FCLASS/FEQ/FLT/FLE/FMV | exe_fp_sgnj/minmax/class/cmp/mv_seq | 数据 + fflags（FMIN/FMAX/FLT 的 sNaN 语义）；A19/A20 |
| F10 | 转换：F↔I 8+8 条、S↔D | exe_f2i_cvt_seq, exe_i2f_cvt_seq, exe_cvt_corner_seq | 饱和 / NaN→max / 负数→无符号 全部对拍；F2I 数据在 ll_iresp、flags 在 fresp（A19/A22）；I2F 在 alu0 的 ll_fresp（A12/A25–A27）|
| F11 | 舍入模式 5 静态 + DYN(fcsr) | exe_rm_sweep_seq | 数据；cg13 |
| F12 | NaN-boxing：单精度 op 喂未 box 的操作数 | exe_nanbox_seq | 必须按 canonical qNaN 计算；cg17 |
| F13 | 分支 kill：任意 in-flight 位置 mispredict | brmode=2/4 + 所有序列 | 被杀 uop 无响应（A28/A29）、未被杀的照常；cg18 |
| F14 | Pipeline flush（req.kill）| brmode=3/4，flush_with_req | 见 §4 时序模型；cg18 |
| F15 | ll_* 端口反压 | +ll_ready_pct | A24/A25 stable；cg19 |
| F16 | 同单元 back-to-back / 多 uop in flight | exe_b2b_seq, *_stress | cg21 bypass 距离、cg22 并发度 |
| F17 | IQ：dispatch/ready、满/空、age order、双发射 | iq_fill_drain_seq, iq_age_order_seq, iq_dual_issue_seq | IQ 模型 C1–C5；A32–A38 |
| F18 | IQ：wakeup（5 口）、spec-load wakeup + ld_miss poison | iq_wakeup_storm_seq, iq_spec_load_seq, iq_ld_miss_storm_seq | 就绪判定、squash 的 grant 留在队列；A39/A40 |
| F19 | IQ：fu_types 动态屏蔽 | iq_fu_mask_seq | 发出的 uop 必须被端口接受（A32）|
| F20 | IQ：branch kill / flush | iq_branch_kill_seq + brmode | A33/A34/A36，模型删除条目 |
| F21 | CSR 复位值 / 位可写性（62 个 CSR）| ral_builtin_seq reset / bitbash, ral_access_seq | RAL 内建序列 + 全块 mirror check；A41/A41b |
| F22 | CSR WARL：40 位 EPC/TVAL 符号扩展、xtvec 对齐、MPP 合法化、medeleg/mideleg 掩码、satp mode、pmpcfg 锁 | ral_warl_seq, ral_access_seq | callback 预测 == 硬件读回 |
| F23 | fflags 硬件副作用（FPU / I2F 两条写回路径）、mstatus.FS→Dirty/SD | ral_fflags_seq | fflags 副作用 predictor 的镜像 == 硬件；A43 |
| F24 | frm → 动态舍入（rm=DYN 的 FP 指令使用 CSR 里的 frm）| ral_frm_seq (+csr_rm) | exe scoreboard（monitor 观测真实 fcsr_rm）；A42 |
| F25 | CSR 指令走流水线（CSRRW/S/C/I）→ 被动 predictor 跟踪 | ral_pipeline_csr_seq, exe_csr_seq | 全块 mirror check；A46 单 master |
| F26 | 别名：fcsr↔fflags/frm、sstatus↔mstatus、sie/sip↔mie/mip&mideleg、cycle←mcycle | ral_alias_seq | 读回值与镜像 |
| F27 | 非法 CSR 号 / 只读 CSR 写：decode 端口拒绝，访问被抑制 | ral_illegal_seq | UVM_NOT_OK 状态 |
| F28 | backdoor（hdl path 到 reg_*）poke/peek 与 frontdoor 一致 | ral_backdoor_seq | 镜像 == peek |
| F29 | 真实程序：riscv-tests rv64ui/um/uf/ud 89 个 ISA 测试在 Spike 上的 commit log 回放，Spike 作为 trace 级黄金参考 | boom_spike_trace_seq (t95–t100) | rd == Spike rd；(fflags_before \| dut) == Spike fflags_after；taken/JALR 目标 == Spike next pc；CSR 指令 rdata == Spike rd（fflags/frm/fcsr/mscratch/mepc/mtval/sscratch/sepc/stval/mhartid）；SoftFloat 模型检查同时保留 |
| F30 | 同上 + 长延迟口反压（ll_ready 40%）/ 背景 branch resolve | t99_spike_all_backpressure, t100_spike_all_br_resolve | 同 F29 |

## 3. 环境结构

```
tb_top ── alu0_if/alu1_if/fpu_if (boom_exu_if #(UNIT)) ── boom_exe_agent #(UNIT)   ×3
       ── iq_if (boom_iq_if)                            ── boom_iq_agent
       ── csr_if (boom_csr_if)                          ── boom_csr_agent + regmodel/adapter/predictors (§7a)
       ── brupd (广播到 4 个接口)                        ── boom_brupd_agent
boom_exe_env: sb[3] (boom_exe_scoreboard) · iq_sb · cov (cg01–cg22) · iq_cov (cg23–cg26) · vsqr (含 regmodel 句柄)
```

* **driver**：`txn.lower()` → 一拍 `req.valid`；等待 `fu_types` 包含该 FU；`ll_*_ready` 按 `ll_ready_pct` 随机。
* **monitor**：从 uop 反解 txn，发布 req / rsp / fflags / bypass / brinfo / brupd 六个 analysis port。
* **ref model**：整数按 rocket `ALU`/`MulDiv` 语义；分支按 `ALUUnit` 的 pc_sel/mispredict；FP 走 DPI-C → SoftFloat-3e（RISC-V specialization = Spike）。
* **scoreboard**：`inflight[rob_idx]`；响应到达时比对 port / data / fflags / latency / pdst；brinfo 与 bypass 单独比对；watchdog 400 拍。
* **IQ scoreboard**：事务级队列模型（见 boom_iq_scoreboard.sv 头注释）。

## 4. 时序模型（在 RTL 上用 `make smoke` 的 kill/flush 表验证）

k = brupd/flush 相对 issue 的拍数，lat = 单元名义延迟：

| 单元 | mispredict@k | flush@k |
|---|---|---|
| alu0 ALU/JMP/MUL (lat 3) | k ≤ 3 squash，之后已写回 | k < 3 squash，**k = 3 照常写回** |
| alu1 ALU/CSR (lat 1) | k ≤ 1 squash | k = 1 照常写回 |
| FPU FMA (lat 4) | k ≤ 4 squash | k < 4 squash，k = 4 写回 |
| F2I → ll_iresp (lat 4)、I2F → ll_fresp (lat 2) | 同上（队列本身 branch-killable）| 同上；**已入队的结果不受 flush 影响**（BranchKillableQueue.io.flush 只删 uses_ldq 条目）|
| DIV / FDIV / FSQRT（迭代）| 任何时刻 squash | scoreboard 标记 ambiguous（有无响应都接受，但有响应必须正确）|

## 5. 断言（`bind` 到接口，50 assert + 16 cover）

A01 fu_code one-hot 且本单元支持 · A02 支持 · A03 mispredict ⊆ resolve · A04 至多一个 mispredict ·
A05 iresp 第 64 位为 0 · A06 ALU 延迟 · A07/A08 bypass0 与请求同拍 · A09/A10 bypass 流水 ·
A11 iMul 延迟 · A12 I2F 忙标志 · A13 只有 br/jalr 有 brinfo · A14 JAL 不 mispredict · A15/A16 DIV 忙/恢复 ·
A17 CSR 延迟 · A18 FPU 延迟 · A19 F2I 不走 fresp · A20 ll_iresp 是整数 · A21 fresp 必带 fflags · A22 fflags rob 一致 ·
A23 FDIV 忙 · A24/A25 ll 端口反压稳定 · A26/A27 ll_fresp 类型/rob · A28/A29 被 mispredict 的 uop 无响应 · A30 复位期间静默 ·
A31 fu_types 静态位 · A32 issue 的 FU 被端口接受 · A33 mispredict 后一拍不再发出 · A34 已 resolve 的 mask 位清零 ·
A35 issue 状态合法 · A36 flush 后一拍静默 · A37 不重复发射 · A38 dis_ready 单调 · A39/A40 wakeup pdst ≠ 0 ·
A41/A41b fcsr_rm == fcsr.frm / frm · A42 frm 写下一拍生效 · A43 fflags 只累加 · A44 特权级保持 M · A45 无 csr_stall · A46 rw 口单 master。

## 6. 覆盖率模型（27 covergroups）

cg01 op×width · cg02 ALU 操作数 corner 交叉 · cg03 移位量 · cg04 乘法符号/幅度 · cg05 除法 corner · cg06 分支类型×实际×预测 ·
cg07 跳转/链接/JALR 失败原因 · cg08 CSR · cg09 每个 FP op · cg10–12 rs1/rs2/rs3 类别 · cg13 舍入模式 · cg14 fflags×op 组 ·
cg15 转换 类型×饱和×符号 · cg16 比较/分类×NaN · cg17 NaN-box · cg18 squash 场景 · cg19 反压 · cg20 alu1 写口仲裁 ·
cg21 bypass 距离 · cg22 in-flight 并发 · cg23 IQ 占用 · cg24 wakeup · cg25 issue 端口/FU · cg26 IQ kill · cg27 CSR 访问（cmd × 地址类 × 来源）。
关闭目标：t82_coverage_closure + 全回归 `--cov`，`urg` 合并；每个 bin 都能追溯到 §2 的特性。

## 7. 回归

`sim/tests.yml` 100 tests、约 270 个 seed-run；`regress.py` 并行执行，产出 junit。分层：
smoke（t01）→ 按 tag（rv64i/branch/rv64m/csr/fp/ooo/stress/iq/system/sweep/ral/spike）→ 全量夜跑。

## 7b. Spike trace 回放结构

```
riscv-tests/isa/*.S --riscv64-unknown-elf-gcc--> ELF --spike --log-commits--> sim/spike_logs/<test>.log   (sim/gen_spike_logs.sh)
dpi/boom_spike_trace.c   spike_trace_load(): 逐行解析 "core 0: <priv> 0x<pc> (0x<insn>) x5 0x.. f1 0x.. c1_fflags 0x.. mem 0x..",
                         维护 x/f/fflags/frm，译码 RV64IMFD+Zicsr -> exe_op_e 名字 -> SV 注册的枚举值；每条指令记录 rs1/rs2/rs3 值、
                         imm/rm/zimm/csr、rd 写入值、next_pc、fflags before/after
boom_spike_trace_seq     每条可回放指令 -> boom_exe_txn（操作数 = 回放状态，pred_taken 随机，JALR 的 FTQ 一半给对目标），
                         期望值 park 进 boom_spike_oracle.exp[unit][rob_idx]；CSR 指令前后 drain（oracle.outstanding == 0）
boom_exe_scoreboard      write_req: oracle.attach() 把 spike_* 复制到 monitor 重建的 txn；write_rsp / check_flags / write_brinfo 多一层 Spike 比对
boom_spike_csr_checker   订阅 boom_csr_monitor.ap：流水线 CSR 访问按程序序出队，rdata == Spike rd
```
不可回放（load/store/AMO/fence/ecall/mret/wfi）：只更新回放状态；在执行单元级 DUT 上没有对应硬件。
时序由 TB 决定（delay、反压、预测），数据由 trace 决定，两者正交；有依赖的指令对因为操作数已从 trace 固定，顺序不影响结果。

## 7a. 寄存器模型（RAL）结构

```
boom_csr_reg_block (62 uvm_reg / 169 uvm_reg_field, 由 sim/gen_ral.py 从 sim/csr_spec.py 生成)
  csr_map: word addressing, 地址 = CSR 号; set_sequencer(csr_agt.sqr, boom_csr_adapter); set_auto_predict(0)
  boom_csr_adapter: reg2bus -> boom_csr_txn{addr, cmd R/W, wdata}; bus2reg: R -> READ(rdata), W/S/C -> WRITE(new_value = CSRFile 的 RMW 结果); illegal -> UVM_NOT_OK
  uvm_reg_predictor #(boom_csr_txn) <- boom_csr_monitor.ap  (RAL 访问 + 流水线 CSR uop 统一预测)
  boom_csr_fflags_predictor          <- boom_csr_monitor.fflags_ap (fflags |= flags, FS -> Dirty)
  callbacks: boom_csr_alias_cbs (post_predict -> dst.predict DIRECT, 单层传播), boom_csr_warl_cbs (SEXT/MASK/MPP/MIDELEG/TVEC),
             satp / pmpcfg0 的 do_predict override
  backdoor: add_hdl_path("tb_top.u_csr") + reg_fflags/reg_frm/reg_mscratch/... (只挂读路径不加工原始寄存器的那些)
```
设计取舍：mstatus.SD 不用 callback 派生（同一寄存器 frontdoor 访问期间不能再 predict 自己的 field），标 volatile 由读回更新；
sie/sip 的 NO_REG_ACCESS_TEST 是因为它们的可写性取决于 mideleg 的当前值。

## 8. RTL findings

| ID | 现象 | 根因 | 处理 |
|---|---|---|---|
| W1 | `fdiv.s`/`fsqrt.s` 输入 sNaN 时 NV 不置位（结果 qNaN 正确）| `FDivSqrtUnit.upconvert` 用 `RecFNToRecFN(8,24,11,53)` 上转，`exceptionFlags` 未接；除法器只看到安静化后的 canonical NaN | 违反 IEEE-754/RISC-V（sNaN 操作数必须 NV）。golden model 用 `waive_fdiv_s_snan_nv=1` 复现以保持回归绿，报告给 RTL |
| N1 | JALR `cfi_idx` 与 `start_bank` 无关 | `bankBytes=8` → `pc_lob ^ 8` 只动 bit 3，`cfi_idx = (..)[2:1]` 不受影响，FIRRTL 直接常量折叠 | 不是 bug；golden model 常量修正（曾误设 4）|
| N2 | 分支也产生 `iresp.valid`（dst_rtype = RT_X）| ALU 流水线对每个 uop 都响应，写回由 `rf_wen` 过滤 | scoreboard 期望该响应并比对数据（SUB/SLT 结果）|
| N3 | 单精度 fdiv 延迟与双精度相同（20 拍，fsqrt 28 拍）| 单精度上转为双精度后共用 `DivSqrtRecF64` | 性能观察；cg/latency 直方图记录 |
| N4 | mstatus.FS 复位 Off；FS=0 时到来的 fflags 触发 CSRFile `$fatal`（CSR.scala:1203）| RTL 假设 core 不会在 FS=0 时执行 FP 指令（decode 会 trap）| block-level 必须先写 FS；base test 的 ral_csr_init_seq |
| N5 | JALR/xtvec：vectored 模式基址强制 256 字节对齐（bits[7:2] 清零），direct 模式只清 bit 1；mtvec 只有 32 位（paddrBits），stvec 39 位符号扩展 | rocket formTVec / 寄存器宽度 | RAL WARL_TVEC callback |
| N6 | `sie`/`sip` 写只对 mideleg 委托的位有效；未委托位读为 0；satp 非法 mode 整个写丢弃；pmpcfg L 位一旦置 1 该表项锁死 | CSR.scala | RAL callback / do_predict override；bit-bash 排除 |

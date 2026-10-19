# BOOM (MediumBoomV3Config) — Chipyard 生成的 RTL

只做了 **elaboration**（Chisel → FIRRTL → SystemVerilog），没有综合。目的：看 BOOM 的 RTL 怎么写、怎么分层。

## 1. 怎么生成的（可复现）

| 项 | 值 |
|---|---|
| Chipyard | `1.13.0`（commit 69eba86，2024-09-30） |
| BOOM | `generators/boom` v3（commit d2a64f7）— Chipyard 1.13 里 `MediumBoomConfig` 已改名为 **`MediumBoomV3Config`**（另有 v4 版本 `MediumBoomV4Config`） |
| Chisel / firtool | Chisel 6（`chiselSettings = chisel6Settings`），firtool **1.75.0** |
| JDK / sbt | OpenJDK **17**（JDK 21 会让 sbt 1.8.2 的 Scala 2.12 编译器报 `bad constant pool index`），sbt 1.8.2（仓库自带 `scripts/sbt-launch.jar`） |
| 命令 | `cd sims/verilator && make verilog CONFIG=MediumBoomV3Config`，然后 `make <gen-collateral>/…top.mems.v` 跑 MacroCompiler 生成存储器行为模型 |
| 绕过的东西 | 没装 conda：`RISCV=/dummy`（common.mk 只是检查这个变量存在）、PATH 里放一个假 `verilator`（Makefile 第 5 行只检查它存在）、`apt install device-tree-compiler`（BootROM 的 DTS 需要 `dtc`） |
| 耗时 | 子模块 clone ~6 min，sbt 编译全部 generator ~12 min，elaborate + firtool ~4 min（2 核 / 7 GB） |

Config 本身（`meta/chipyard_BoomConfigs.scala`）：

```scala
class MediumBoomV3Config extends Config(
  new boom.v3.common.WithNMediumBooms(1) ++   // meta/boom_v3_config-mixins.scala 第 140 行起
  new chipyard.config.AbstractConfig)         // meta/chipyard_AbstractConfig.scala
```

`WithNMediumBooms` 的核心参数（原文）：fetchWidth 4 / decodeWidth 2 / numRobEntries 64 / issue = mem 12 · int 20 · fp 16 / int PRF 80 · fp PRF 64 / LDQ 16 · STQ 16 / maxBrCount 12 / fetchBuffer 16 / FTQ 32 / D$ 64 sets × 4 ways, 2 MSHR / I$ 64 sets × 4 ways, fetchBytes 8。

## 2. 目录

```
BOOM_RTL/
├── README.md                          本文件
├── HIERARCHY_ChipTop.txt              整颗 SoC 的实例树（相同子模块折叠为 ×N）
├── HIERARCHY_BoomTile.txt             只看 BoomTile 往下（255 行，先读这个）
├── filelist_top.f                     ChipTop 及以下的 536 个文件（= 后端要综合的部分）
├── filelist_design_for_mflowgen.f     top.f + top.mems.v（cat 起来就是 mflowgen 的 design.v）
├── filelist_model.f                   TestHarness 及仿真模型（不流片）
├── filelist_bb.f                      黑盒：EICG_wrapper / plusarg_reader / Sim* / IO cell
├── gen-collateral/                    firtool --split-verilog 的输出：每个模块一个 .sv（613 个，27 MB，22.6 万行）
│   ├── *.top.mems.v                   MacroCompiler 按 top.mems.conf 生成的存储器行为模型（synflops）
│   └── metadata/seq_mems.json
└── meta/
    ├── *.top.mems.conf                20 个被 ReplSeqMem 抽出的存储阵列（名字/深/宽/端口）
    ├── *.dts / *.memmap.json          设备树、地址映射（0x2000000 CLINT、0xC000000 PLIC、0x10020000 UART…）
    ├── *.json / *.l2.json             elaboration 后的参数快照
    ├── top_module_hierarchy.json      HIERARCHY_*.txt 的来源
    ├── *.regmap.json                  每个 MMIO 设备的寄存器表（10 个）
    ├── largest_modules.txt            按行数排序的前 40 个模块
    ├── module_categories.txt          536 个顶层文件按功能分 9 类
    ├── *.chisel.log / *.firtool.log   两阶段日志
    └── boom_v3_config-mixins.scala / chipyard_BoomConfigs.scala / chipyard_AbstractConfig.scala   对应的 Scala 源
```

拼 design.v（和 Tapeout Guide 里 `cat-files.py` 等价）：

```bash
cd BOOM_RTL && xargs cat < filelist_design_for_mflowgen.f > design.v     # ≈ 27 MB
```

## 3. 分层：从 ChipTop 到 BoomCore

```
ChipTop                                  流片顶层：IO cell + 时钟/复位 + system
└── system  [DigitalTop]                 Chipyard 的 SoC：五条 TileLink 总线 + tile + 外设
    ├── sbus / pbus / fbus / cbus / mbus   TLXbar + TLBuffer + Monitor（每条总线一个 clock domain）
    ├── tile_prci_domain
    │   └── element_reset_domain_boom_tile  [BoomTile]      ← HIERARCHY_BoomTile.txt 从这里开始
    │       ├── frontend  [BoomFrontend]     ICache + TLB + BranchPredictor(TAGE/BTB/BIM/uBTB/loop/RAS) + FetchBuffer + FTQ
    │       ├── core      [BoomCore]         乱序引擎（见下）
    │       ├── lsu       [LSU]              LDQ/STQ + NBDTLB + forwarding-age logic
    │       ├── dcache    [BoomNonBlockingDCache]  L1D：MSHRFile(2)、writeback、prober、meta/data 阵列
    │       └── ptw       [PTW]              硬件页表遍历 + L2 TLB
    ├── InclusiveCache (L2, 512 KB, cc_dir/cc_banks)
    ├── CLINT / PLIC / BootROM / UART / Debug(TLDebugModule + JTAG DTM)
    └── serial_tl / mem port（AXI4 出去接 SimDRAM）
```

`BoomCore` 内部（按流水线顺序，HIERARCHY_BoomTile.txt 第 146 行起）：

| 流水阶段 | 实例（模块） | 生成自 Scala |
|---|---|---|
| Decode | `decode_units_0/1 [DecodeUnit]`, `dec_brmask_logic [BranchMaskGenerationLogic]` | `exu/decode.scala` |
| Rename | `rename_stage [RenameStage]` → `maptable / freelist / busytable`；FP 一套 `fp_rename_stage` | `exu/rename/*.scala` |
| Dispatch | `dispatcher [BasicDispatcher]` | `exu/dispatch.scala` |
| Issue | `mem_issue_unit (12 slot)`, `int_issue_unit (20 slot)`, `FpPipeline.fp_issue_unit (16 slot)` — 都是 `IssueUnitCollapsing` + `IssueSlot` | `exu/issue-units/*.scala` |
| RegRead | `iregfile [RegisterFileSynthesizable] → regfile_80x64`，`iregister_read`；FP `fregfile → regfile_64x65` | `exu/register-read/*.scala` |
| Execute | `memExeUnit [ALUExeUnit]`(地址计算)、`alu_exe_unit [ALUExeUnit_1]`(ALU+iMul+I2F)、`alu_exe_unit_1 [ALUExeUnit_2]`(ALU+Div)、`FpPipeline.fpu_exe_unit`(FMA/FDivSqrt) | `exu/execution-units/*.scala`, `exu/fp-pipeline.scala` |
| Commit | `rob [Rob]`（64 项，32 行 × 2）、`csr [CSRFile]` | `exu/rob.scala`（CSRFile 来自 rocket-chip） |
| 前端 | `frontend.bpd.banked_predictors_0 [ComposedBranchPredictorBank]` = loop + tage(6 张 TageTable) + btb + bim + ubtb；`fb [FetchBuffer]`；`ftq [FetchTargetQueue]` | `ifu/bpd/*.scala`, `ifu/*.scala` |
| 访存 | `lsu [LSU]`、`dcache`、`ptw` | `lsu/*.scala` |

## 4. 怎么读这些 .sv（Chisel 生成代码的特点）

1. **一个模块一个文件，名字 = Chisel class 名 + 参数后缀**。`IssueUnitCollapsing / _1 / _2` 是同一个 Scala 类三次不同参数的实例（fp / mem / int）；FIRRTL Dedup 后完全相同的实例共用一个定义（如 20 个 `IssueSlot_16`）。
2. **端口名是 Bundle 路径打平**：`io_dis_uops_0_bits_uop_br_mask`、`io_brupdate_b1_resolve_mask`。看 uop 的字段直接对照 `boom/v3/common/micro-op.scala`。
3. **没有 `always_comb`**（firtool 选项 `noAlwaysComb`），组合逻辑全是 `assign` + `wire`；时序逻辑是 `always @(posedge clock)`；复位多为同步复位 `if (reset)`。
4. **`_GEN_`、`_T_` 前缀** 是 FIRRTL 的临时变量；带 `@[...scala:行:列]` 的注释指向 Scala 源（`locationInfoStyle=wrapInAtSquareBracket`）——这是把 Verilog 映射回 Chisel 的唯一线索。
5. **存储器**：所有 `SyncReadMem` 被抽成 `xxx_ext` 黑盒（`meta/*.top.mems.conf` 20 条），实现放在 `*.top.mems.v`（触发器阵列）。`regfile_80x64`（int PRF，6R3W）、`regfile_64x65`（fp PRF）、`tag_array_ext`、`dataArrayWay_0_ext`、TAGE 的 `table_*_ext`、`btb_0_ext` 都在这里。流片时这一文件被 SRAM 宏 wrapper 替换。
6. **`ifndef SYNTHESIS` 段**：`chisel3.assert` → `$fatal`，`printf` → `$fwrite`，`plusarg_reader` 读 `+verbose` 之类；综合时用 `-define SYNTHESIS` 全部去掉。
7. **TLMonitor_N**：每条 TileLink 边上都挂一个协议监视器（几十个），仅仿真用；`BoomTile` 下的 `tlMasterXbar.monitor` 就是它。

建议阅读顺序：`HIERARCHY_BoomTile.txt` → `BoomCore.sv`（5.3k 行，是各单元的连线） → `Rob.sv` → `RenameMapTable.sv / RenameFreeList.sv` → `IssueUnitCollapsing_2.sv` + `IssueSlot_16.sv` → `LSU.sv`（1.66 万行，最大）→ `BoomFrontend.sv` → `FetchTargetQueue.sv`。每读一个 .sv 对着同名 Scala 文件看，Scala 通常只有它的 1/10 长。

## 5. 最大的几个模块（行数）

```
16554  LSU.sv                    8637  Rob.sv
 8106  IssueUnitCollapsing_2.sv  6124  IssueUnitCollapsing.sv
 5338  BoomCore.sv               4913  IssueUnitCollapsing_1.sv
 4386  BranchKillableQueue.sv    3952  *.top.mems.v
 2762  BoomMSHRFile.sv           2463  BoomTile.sv
 2455  FetchTargetQueue.sv       2401  RegisterRead_1.sv
 2105  RenameMapTable.sv         1813  BoomNonBlockingDCache.sv
 1646  FAMicroBTBBranchPredictorBank.sv   1463  TageBranchPredictorBank.sv
```
完整列表见 `meta/largest_modules.txt`。

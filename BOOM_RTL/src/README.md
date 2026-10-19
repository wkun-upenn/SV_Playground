# src/ — 生成 gen-collateral/ 的 Chisel (Scala) 源码

和 gen-collateral/ 里的 .sv 一一对照着读。.sv 里每个 `@[generators/boom/src/main/scala/v3/exu/rob.scala:211:7]` 注释就指向这里
的 `boom/scala/v3/exu/rob.scala` 第 211 行。

| 目录 | 来自 | 内容 |
|---|---|---|
| `boom/scala/v3/` | generators/boom (commit d2a64f7) | **本次用的核**：common/（参数、uop、config-mixins）、ifu/（frontend、fetch-buffer、ftq、icache、bpd/ 各预测器）、exu/（core、decode、rename/、issue-units/、register-read/、execution-units/、rob、fp-pipeline）、lsu/（lsu、dcache、mshrs、tlb、prefetcher）、util/ |
| `boom/scala/v4/` | 同上 | BOOM v4（新版，本次没用，可对比） |
| `chipyard/scala/` | generators/chipyard | SoC 组装层：config/（BoomConfigs、AbstractConfig、fragments）、DigitalTop.scala、ChipTop.scala、harness/、iobinders/、clocking/ |
| `rocket-chip/scala/` | generators/rocket-chip | 被 BOOM 复用的部分：tile/（TileBase、FPU、CSR 接口）、rocket/（CSR.scala、PTW.scala、TLB.scala、ICache.scala、Multiplier.scala）、tilelink/（TLXbar、TLBuffer、TLMonitor…）、subsystem/（SystemBus、PeripheryBus、InclusiveCache 挂接）、devices/（CLINT、PLIC、BootROM、Debug）、diplomacy/、util/ |
| `hardfloat/scala/` | generators/hardfloat | Berkeley HardFloat：MulAddRecFN、DivSqrtRecF64、RecFN 转换——FPU 里所有 `*RecFN*` 模块 |
| `chipyard_build.sbt` | 仓库根 | sbt 工程定义，说明各 generator 之间的 dependsOn 关系 |

Verilog 模块名 → Scala 位置速查（BoomCore 内）：

| .sv | .scala |
|---|---|
| BoomCore | boom/scala/v3/exu/core.scala |
| DecodeUnit, BranchMaskGenerationLogic | exu/decode.scala |
| RenameStage / RenameMapTable / RenameFreeList / RenameBusyTable | exu/rename/rename-{stage,maptable,freelist,busytable}.scala |
| BasicDispatcher | exu/dispatch.scala |
| IssueUnitCollapsing, IssueSlot | exu/issue-units/issue-unit-age-ordered.scala, issue-slot.scala |
| RegisterRead, RegisterFileSynthesizable | exu/register-read/register-read.scala, regfile.scala |
| ALUExeUnit, FPUExeUnit | exu/execution-units/execution-unit.scala |
| ALUUnit, PipelinedMulUnit, DivUnit, MemAddrCalcUnit, FPUUnit, FDivSqrtUnit, IntToFPUnit | exu/execution-units/functional-unit.scala, fdiv.scala, fpu.scala |
| FpPipeline | exu/fp-pipeline.scala |
| Rob | exu/rob.scala |
| BoomFrontend, FetchBuffer, FetchTargetQueue | ifu/frontend.scala, fetch-buffer.scala, fetch-target-queue.scala |
| BranchPredictor, ComposedBranchPredictorBank, Tage*, BTB*, BIM*, FAMicroBTB*, Loop*, BoomRAS | ifu/bpd/predictor.scala, composer.scala, tage.scala, btb.scala, bim.scala, faubtb.scala, loop.scala, ras.scala |
| LSU, ForwardingAgeLogic | lsu/lsu.scala |
| BoomNonBlockingDCache, BoomMSHRFile, BoomMSHR, BoomWritebackUnit, BoomProbeUnit | lsu/dcache.scala, mshrs.scala |
| NBDTLB | lsu/tlb.scala |
| BranchKillableQueue, MaxPeriodFibonacciLFSR | util/util.scala |
| CSRFile, PTW, ICache, MulDiv, PMPChecker | rocket-chip/scala/rocket/{CSR,PTW,ICache,Multiplier,PMP}.scala |
| BoomTile | boom/scala/v3/common/tile.scala |
| DigitalTop, ChipTop | chipyard/scala/DigitalTop.scala, ChipTop.scala |

# Spike + riscv-tests（与 uvm_exe 的 Spike trace 回放配套）

这个目录是云端搭链路时用的三样东西的原样拷贝：

* `riscv-isa-sim/`  — Spike 源码（riscv-software-src/riscv-isa-sim，2026-09-11 的 master，浅克隆，去掉了 .git）
* `riscv-tests/`    — riscv-tests ISA 套件源码（含 env 子模块）。Chipyard 里同一份在 `toolchains/riscv-tools/riscv-tests`
* `tests_bin/`      — 用 `riscv64-unknown-elf-gcc -march=rv64g -mabi=lp64d` 编好的 90 个 ELF（rv64ui/um/uf/ud，-p 环境）

云端编出来的 spike 可执行文件是 Linux x86-64 的，在 macOS 上跑不了，所以没有放进来。两种拿到 spike 的办法：

1. 直接用 Chipyard 自带的：`source chipyard/env.sh` 之后 `which spike`（在 conda 环境的 bin 里）。
2. 自己编这份源码（macOS，约 10 分钟）：
   ```bash
   brew install dtc                      # device-tree-compiler
   cd riscv-isa-sim && mkdir build && cd build
   ../configure --prefix=$PWD/../install && make -j8 && make install
   ```

生成 commit log（就是 uvm_exe/sim/spike_logs 里那些）：
```bash
spike --isa=rv64gc --log-commits tests_bin/rv64uf-p-fadd 2> rv64uf-p-fadd.log
# 或者一次全部：
cd ../uvm_exe/sim && SPIKE=/path/to/spike ./gen_spike_logs.sh ../../spike/tests_bin spike_logs
```

重新编译测试程序（改了 .S 之后）：
```bash
cd riscv-tests/isa
riscv64-unknown-elf-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
  -I../env/p -Imacros/scalar -T../env/p/link.ld rv64uf/fadd.S -o ../../tests_bin/rv64uf-p-fadd
```

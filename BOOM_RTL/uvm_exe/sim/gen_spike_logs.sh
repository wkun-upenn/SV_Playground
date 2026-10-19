#!/usr/bin/env bash
#==============================================================================
# sim/gen_spike_logs.sh — (re)generate sim/spike_logs from the riscv-tests ISA
# suite with Spike, the way Chipyard's `make run-binary` / riscv-tests do it.
#
#   ./gen_spike_logs.sh [tests_dir] [out_dir]
#
# tests_dir: directory holding the riscv-tests ELF files (rv64ui-p-add, ...).
#   Chipyard's toolchain installs them at
#     $RISCV/riscv64-unknown-elf/share/riscv-tests/isa      (conda env: $CONDA_PREFIX/riscv-tools/...)
#   or build them from chipyard/toolchains/riscv-tools/riscv-tests: ./configure && make isa
# Spike is taken from $SPIKE, else `spike` on PATH, else $RISCV/bin/spike.
#
# Each log is cut after the first store to `tohost` (the test's exit loop
# writes tohost until the host notices — thousands of useless auipc/sw/j).
#==============================================================================
set -euo pipefail
TESTS_DIR=${1:-${RISCV:-/nonexistent}/riscv64-unknown-elf/share/riscv-tests/isa}
OUT=${2:-$(cd "$(dirname "$0")" && pwd)/spike_logs}
SPIKE=${SPIKE:-$(command -v spike || echo "${RISCV:-/nonexistent}/bin/spike")}
NM=${NM:-$(command -v riscv64-unknown-elf-nm || echo nm)}
[ -x "$SPIKE" ] || { echo "spike not found (set SPIKE=/path/to/spike)"; exit 1; }
[ -d "$TESTS_DIR" ] || { echo "tests dir $TESTS_DIR not found"; exit 1; }
mkdir -p "$OUT"
rm -f "$OUT"/*.log "$OUT"/*.list
n=0
for suite in rv64ui rv64um rv64uf rv64ud; do
  for bin in "$TESTS_DIR"/$suite-p-*; do
    case "$bin" in *.dump|*.log) continue;; esac
    name=$(basename "$bin")
    case "$name" in *ma_data*) continue;; esac        # misaligned-access test: memory only, and needs misaligned support
    tohost=$("$NM" "$bin" 2>/dev/null | awk '$3=="tohost"{print $1}' | sed 's/^0*//')
    if ! "$SPIKE" --isa=rv64gc --log-commits "$bin" 2>"$OUT/$name.log" >/dev/null; then
      echo "  spike failed on $name (kept the log anyway)"
    fi
    if [ -n "$tohost" ]; then
      awk -v th="mem 0x0*${tohost} 0x" '{print} $0 ~ th {exit}' "$OUT/$name.log" > "$OUT/$name.tmp" && mv "$OUT/$name.tmp" "$OUT/$name.log"
    fi
    echo "$name.log" >> "$OUT/$suite.list"
    n=$((n+1))
  done
done
cat "$OUT"/rv64ui.list "$OUT"/rv64um.list "$OUT"/rv64uf.list "$OUT"/rv64ud.list > "$OUT"/all.list
echo "$n logs written to $OUT ($(cat "$OUT"/*.log | wc -l) committed instructions)"

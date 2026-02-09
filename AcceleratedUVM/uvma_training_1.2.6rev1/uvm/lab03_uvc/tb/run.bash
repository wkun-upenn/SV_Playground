#!/usr/bin/env bash
set -euo pipefail

# Run Xcelium and save output to xcelium.log (also print to console)
# - The 'tee' keeps the live output visible in EDA Playground.
# - 'PIPESTATUS[0]' preserves xrun's exit code even though we pipe into tee.

LOGFILE="xcelium.log"

xrun -64 -unbuffered -Q \
  -f run.f \
  -timescale 1ns/1ns \
  -sysv \
  -access +rwc \
  2>&1 | tee "${LOGFILE}"

exit ${PIPESTATUS[0]}
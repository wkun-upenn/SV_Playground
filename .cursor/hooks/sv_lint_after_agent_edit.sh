#!/usr/bin/env bash
# Runs after Agent/Cmd+K file edits (not manual Cmd+S). Logs table to .cursor/sv_lint_hook.log
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
report="$root/tools/sv_lint_report.py"
file="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('file_path',''))")" || true
if [[ -z "${file:-}" || "$file" != *.sv ]]; then
  printf '%s\n' '{}'
  exit 0
fi
{
  printf '%s\n' "--- $(date -Iseconds 2>/dev/null || date) ---"
  python3 "$report" "$file" 2>&1 || true
  printf '\n'
} >>"$root/.cursor/sv_lint_hook.log"
printf '%s\n' '{}'

#!/usr/bin/env python3
"""
Single-file SystemVerilog quick analysis (Verilator + light static checks).
Prints: LINE N | SEVERITY | ISSUE | FIX
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


VERILATOR_LINE = re.compile(
    r"^%(?P<kind>Error|Warning)(?:-(?P<code>[A-Z0-9_]+))?:\s+"
    r"(?P<path>.+?):(?P<line>\d+):(?P<col>\d+):\s*(?P<msg>.*)$"
)


def fix_hint(code: str | None, msg: str, kind: str) -> str:
    c = (code or "").upper()
    mlow = msg.lower()
    if c == "CASTCONST" or "static cast" in mlow:
        return "Prefer a static cast or direct assignment when the cast is always legal."
    if "WIDTH" in c or "width" in mlow:
        return "Resize RHS/LHS widths explicitly (padding, slice, or correct declaration width)."
    if "UNDRIVEN" in c or "undriven" in mlow:
        return "Drive the net/signal in all paths or tie off intentionally."
    if "UNUSED" in c or "unused" in mlow:
        return "Remove dead code, prefix unused formals with underscore, or wire the signal."
    if "LATCH" in c or "latch" in mlow:
        return "Make assignments complete in all branches or use default/reset values."
    if kind == "Error":
        return "Fix the syntax or declaration error; check preceding lines for missing semicolon/end/endfunction."
    return "See Verilator message and https://verilator.org/warn/ for this warning id."


def run_verilator(sv_path: Path) -> list[tuple[int, str, str, str]]:
    rows: list[tuple[int, str, str, str]] = []
    cmd = [
        "verilator",
        "--lint-only",
        "-sv",
        "-Wno-fatal",
        "-Wno-DECLFILENAME",
        str(sv_path),
    ]
    try:
        r = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError:
        rows.append(
            (
                0,
                "ERROR",
                "verilator not found on PATH",
                "Install Verilator (e.g. brew install verilator) or add it to PATH.",
            )
        )
        return rows
    except subprocess.TimeoutExpired:
        rows.append(
            (
                0,
                "ERROR",
                "verilator timed out",
                "Reduce file complexity or run lint on a smaller unit with +incdir+.",
            )
        )
        return rows

    text = (r.stdout or "") + "\n" + (r.stderr or "")
    for line in text.splitlines():
        m = VERILATOR_LINE.match(line.strip())
        if not m:
            continue
        ln = int(m.group("line"))
        kind = m.group("kind")
        code = m.group("code")
        msg = m.group("msg").strip()
        sev = "ERROR" if kind == "Error" else "WARNING"
        issue = f"Verilator{('-' + code) if code else ''}: {msg}"
        rows.append((ln, sev, issue, fix_hint(code, msg, kind)))
    return rows


def static_scan(lines: list[str]) -> list[tuple[int, str, str, str]]:
    out: list[tuple[int, str, str, str]] = []
    n = len(lines)
    # module / endmodule balance (very rough; ignores strings/comments)
    mod = sum(1 for ln in lines if re.search(r"\bmodule\s+\w", ln))
    emod = sum(1 for ln in lines if re.search(r"\bendmodule\b", ln))
    if mod != emod:
        out.append(
            (
                0,
                "WARNING",
                f"Possible module/endmodule imbalance (module≈{mod}, endmodule≈{emod})",
                "Ensure each module has matching endmodule; check generate/ifdef regions.",
            )
        )
    style_cap = 20
    style_n = 0
    for i, ln in enumerate(lines, start=1):
        if style_n >= style_cap:
            break
        if ln.rstrip("\n").endswith((" ", "\t")) and ln.strip():
            out.append(
                (
                    i,
                    "STYLE",
                    "Trailing whitespace",
                    "Delete trailing spaces/tabs (editor trim-on-save).",
                )
            )
            style_n += 1
        if style_n >= style_cap:
            break
        if "\t" in ln and ln.strip():
            out.append(
                (
                    i,
                    "STYLE",
                    "Tab character in line",
                    "Replace tabs with spaces to match project style.",
                )
            )
            style_n += 1
    if style_n >= style_cap:
        out.append(
            (
                0,
                "INFO",
                "Additional style issues omitted (cap reached)",
                "Re-run after fixing the first batch or raise style_cap in tools/sv_lint_report.py.",
            )
        )
    if n > 5000:
        out.append(
            (
                0,
                "INFO",
                f"Large file ({n} lines); lint may be slow or noisy",
                "Consider splitting packages or using filelist + top-only lint.",
            )
        )
    return out


def report_for_file(sv_path: Path) -> None:
    if not sv_path.is_file():
        print(f"LINE 0 | ERROR | File not found: {sv_path} | Check path", file=sys.stderr)
        return
    text = sv_path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines(keepends=True)
    all_rows: list[tuple[int, str, str, str]] = []
    all_rows.extend(run_verilator(sv_path))
    all_rows.extend(static_scan([ln.rstrip("\n") for ln in lines]))
    if not all_rows:
        print(f"LINE — | OK | No Verilator diagnostics; static scan clean | —")
        return
    for ln, sev, issue, fix in all_rows:
        safe_issue = issue.replace("|", "/")
        safe_fix = fix.replace("|", "/")
        print(f"LINE {ln} | {sev} | {safe_issue} | {safe_fix}")


def main() -> int:
    p = argparse.ArgumentParser(description="SV lint report for one file")
    p.add_argument("sv_file", type=Path, help="Path to .sv file")
    args = p.parse_args()
    report_for_file(args.sv_file.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

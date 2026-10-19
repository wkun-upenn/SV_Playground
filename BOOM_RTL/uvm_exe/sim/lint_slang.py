#!/usr/bin/env python3
"""
lint_slang.py — full elaboration of RTL + UVM testbench with pyslang (no
simulator licence needed). Catches everything a compiler would: undeclared
names, type mismatches, bad port connections, wrong macro usage, ...

  BOOM_RTL=/path/to/BOOM_RTL UVM_CORE=/path/to/uvm-core python3 lint_slang.py
"""
import os, sys, pyslang as ps

HERE = os.path.dirname(os.path.abspath(__file__))
TB   = os.path.abspath(os.path.join(HERE, '..'))
RTL  = os.environ.get('BOOM_RTL', os.path.abspath(os.path.join(TB, '..')))
UVM  = os.environ.get('UVM_CORE', os.path.abspath(os.path.join(TB, '..', '..', 'uvm-core')))

def rtl_files():
    out = []
    for line in open(os.path.join(TB, 'dut', 'boom_exe_dut.f')):
        line = line.strip()
        if not line or line.startswith('//') or line.startswith('#'): continue
        out.append(line.replace('${BOOM_RTL}', RTL))
    return out

args = ['slang', '--lint-only', '-Wno-unused', '--timescale', '1ns/1ps',
        '--top', 'tb_top', '-D', 'BOOM_EXE_UVM',
        '--max-parse-depth', '2000',
        '-Wno-static-init-order',
        f'+incdir+{UVM}/src', f'+incdir+{TB}/tb',
        os.path.join(UVM, 'src', 'uvm_pkg.sv')] + rtl_files() + [
        os.path.join(TB, 'tb', 'boom_exe_defs_pkg.sv'),
        os.path.join(TB, 'tb', 'boom_exu_if.sv'),
        os.path.join(TB, 'tb', 'boom_iq_if.sv'),
        os.path.join(TB, 'tb', 'boom_csr_if.sv'),
        os.path.join(TB, 'tb', 'boom_exe_pkg.sv'),
        os.path.join(TB, 'tb', 'tb_top.sv')]
args += sys.argv[1:]

drv = ps.driver.Driver()
drv.addStandardArgs()
if not drv.parseCommandLine(' '.join(f'"{a}"' if ' ' in a else a for a in args)):
    sys.exit(2)
if not drv.processOptions(): sys.exit(2)
drv.parseAllSources()
comp = drv.createCompilation()
drv.reportCompilation(comp, False)
ok = drv.reportDiagnostics(False)
sys.exit(0 if ok else 1)

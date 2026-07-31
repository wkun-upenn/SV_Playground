---
name: Coverage Lab Project Context
description: EDAPlayground/Coverage lab uses covergroups and cross-coverage — constructs Verilator does not support
type: project
---

The Coverage lab (`EDAPlayground/Coverage/design.sv` + `testbench.sv`) exercises SystemVerilog functional coverage: covergroups, coverpoints with bin specifications, cross coverage, and covergroup OOP methods (`start()`, `stop()`, `get_coverage()`). These constructs are not supported by Verilator — they require a commercial simulator (Questa, VCS, Xcelium) or open-source alternatives like Icarus+plugins. The intended flow is EDA Playground, not Verilator simulation.

**Why:** Verilator is a synthesizable-RTL linter/simulator; it explicitly stubs out coverage constructs with COVERIGN warnings and errors on coverpoint member access.

**How to apply:** When debugging coverage files in this project, lead with a clear "Verilator limitation" explanation, categorize all COVERIGN warnings as unsupported-by-design (not bugs in the user's code), and focus fixable suggestions on issues that ARE Verilator-fixable (WIDTH, DECLFILENAME, etc.).

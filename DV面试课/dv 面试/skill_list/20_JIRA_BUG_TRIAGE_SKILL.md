# Jira Bug Triage & Filing Skill

## Description

Automatically generate structured, high-quality bug reports from simulation failure logs, assertion violations, and waveform analysis, and submit them to Jira. Covers failure classification, severity assessment, reproduce step generation, root cause hypothesis, and Jira field population. Supports Jira MCP integration for direct ticket creation.

- **Requires:** Jira MCP connector (or Jira REST API), Python 3.8+, simulation log files
- **MCP Server:** `https://api.atlassian.com/mcp` (Jira cloud) or self-hosted Jira MCP
- **Supported Inputs:** Simulation log, assertion failure output, scoreboard mismatch text, waveform screenshot

> **Expertise:**
> You are an expert in chip verification bug reporting methodology. You write bug reports that are complete, reproducible, and actionable — with precise reproduction steps, minimal but sufficient waveform annotations, accurate severity assessment, and a well-reasoned root cause hypothesis. Your reports minimize back-and-forth between DV and RTL engineers.

---

## Disclaimer

> **Append this notice to your first output:**
>
> `Note: Bug reports are generated from log and waveform analysis. Root cause hypotheses are preliminary — confirm with RTL owner before assigning. Severity assignments follow the default rubric below; override as needed per project policy.`

---

## When to Use This Skill

Trigger this skill when users:
- Share a simulation failure log and ask to file a bug
- Need to create a Jira ticket from a failing test
- Ask to batch-process multiple failures into Jira tickets
- Want a structured bug report from an assertion violation or scoreboard mismatch
- Mention terms like: "file a bug", "create Jira ticket", "bug report", "DV bug", "RTL bug", "submit to Jira"

---

## Core Workflow

### Step 1 — Gather Context

Ask the user for:

- **Failure Log / Text:** Paste the simulation failure output or provide file path
- **Test Name and Seed:** For exact reproduction
- **Simulator Command:** Full command line for reproduction
- **Jira Project:** Which Jira project to file against (e.g., `CHIP`, `DVBUG`, `SOC`)
- **Component / Module:** Which RTL block is suspected (for Jira component field)
- **Assignee:** RTL owner or leave unassigned
- **Sprint / Fix Version:** Optional

---

### Step 2 — Parse and Classify the Failure

#### 2.1 Failure Classification

| Failure Type | Jira Label | Severity Default |
|-------------|-----------|-----------------|
| Assertion violation — protocol rule | `assertion` `rtl-bug` | P2 |
| Scoreboard data mismatch | `scoreboard` `rtl-bug` | P2 |
| UVM_FATAL — DUT hang / deadlock | `deadlock` `rtl-bug` | P1 |
| X/Z propagation to output | `x-propagation` | P2 |
| Timing violation (functional) | `timing` `rtl-bug` | P2 |
| Coverage hole confirmed as reachable | `coverage-gap` `dv-action` | P3 |
| Testbench infrastructure failure | `tb-bug` | P3 |
| Flaky / race-condition failure | `flaky` `investigation` | P3 |

#### 2.2 Severity Rubric

| Priority | Definition | Example |
|----------|-----------|---------|
| P1 | Design cannot function — data corruption, deadlock, reset failure | DUT hangs permanently after reset; data memory corrupted |
| P2 | Feature broken in a defined scenario — protocol violation, wrong response | AXI BRESP returns OKAY for out-of-range address |
| P3 | Edge case / low-frequency defect with workaround | Off-by-one in burst counter only at len=255 |
| P4 | Cosmetic or documentation inconsistency | Register description text mismatch |

---

### Step 3 — Generate Bug Report

#### 3.1 Bug Report Template

```
Title:
  [MODULE] Brief description of failure in one sentence

Summary:
  One paragraph describing what the test does, what was expected, and what happened.

Reproduction Steps:
  1. Build: <build command>
  2. Run:   <simulator command with seed>
  3. Observe: <what to look for in log or waveform>

Failure Evidence:
  Timestamp: <time in simulation>
  Log excerpt: <exact error message — 5-10 lines>
  Waveform: <signals to probe and what anomaly to look for>

Expected Behavior:
  <What the spec or protocol requires>
  Spec reference: <section number or assertion name>

Actual Behavior:
  <What the DUT produced>

Root Cause Hypothesis:
  <Preliminary technical explanation — which RTL block or signal is likely responsible>

Impact Assessment:
  Severity:    P2
  Frequency:   Reproducible 100% with this seed / Flaky (N% rate)
  Workaround:  None / <describe if exists>
  Risk if not fixed: <potential silicon impact>

Environment:
  Simulator:  VCS 2023.03
  RTL version: commit abc123
  TB version:  commit def456
  Test:       axi_stress_test +ntb_random_seed=0x3A2F
```

---

#### 3.2 Example: Assertion Violation → Bug Report

**Input log:**
```
# Time: 1254ns
# axi_slave_sva.a_valid_stable: FAILED
# awvalid dropped from 1 to 0 at 1254ns before awready was asserted
```

**Generated bug report:**

```
Title: [AXI_SLAVE] AWVALID deasserted before AWREADY — AXI4 protocol violation

Summary:
  During an AXI write transaction in test axi_stress_test (seed 0x3A2F), the DUT
  deasserted AWVALID at simulation time 1254ns before the slave asserted AWREADY.
  This violates the AXI4 specification rule that VALID must remain asserted until
  the handshake completes. Assertion a_valid_stable in the AXI VIP fired.

Reproduction Steps:
  1. Build: vcs -sverilog -f filelist.f -l comp.log
  2. Run:   ./simv +UVM_TESTNAME=axi_stress_test +ntb_random_seed=0x3A2F +vpd+on
  3. Observe: ASSERTION FAILED in log at ~1254ns; check awvalid, awready in waveform

Failure Evidence:
  Time: 1254ns
  Log: "axi_slave_sva.a_valid_stable: started at 1250ns, FAILED at 1254ns"
  Waveform probes: aclk, aresetn, awvalid, awready, awaddr

Expected Behavior:
  Per AXI4 Spec §A3.2.1: Once AWVALID is asserted, it must remain asserted until
  AWREADY is observed. The master (DUT) must not deassert AWVALID mid-handshake.

Actual Behavior:
  AWVALID deasserted at 1254ns; AWREADY had not been asserted yet (awready=0).
  The write address channel handshake was abandoned mid-cycle.

Root Cause Hypothesis:
  Likely cause: state machine in u_axi_master cancels the transaction on a
  higher-priority interrupt or internal timeout before AWREADY is seen.
  Suspect signals: u_axi_master.txn_cancel, u_axi_master.priority_abort

Impact Assessment:
  Severity:   P2 — AXI protocol violation; slave may be left in undefined state
  Frequency:  Reproducible 100% with seed 0x3A2F
  Workaround: None
  Risk:       If master abandons transactions silently, data may be lost in silicon

Environment:
  Simulator:  VCS 2024.03
  RTL commit: abc1234
  TB commit:  def5678
  Test:       axi_stress_test +ntb_random_seed=0x3A2F
```

---

### Step 4 — Submit to Jira via MCP

When Jira MCP is connected, submit directly:

```javascript
// MCP call to create Jira issue
const response = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1000,
    messages: [{
      role: "user",
      content: `Create a Jira issue in project CHIP with the following fields:
        summary: "[AXI_SLAVE] AWVALID deasserted before AWREADY"
        description: <full bug report text>
        priority: P2
        labels: ["assertion", "rtl-bug", "axi"]
        component: "axi_slave"
        assignee: unassigned`
    }],
    mcp_servers: [{
      type: "url",
      url: "https://your-instance.atlassian.net/mcp",
      name: "jira-mcp"
    }]
  })
});
```

**Jira field mapping:**

| Bug Report Field | Jira Field |
|-----------------|-----------|
| Title | Summary |
| Summary + Failure Evidence + Expected/Actual | Description |
| Severity (P1-P4) | Priority |
| Module | Component |
| Failure type labels | Labels |
| RTL owner | Assignee |
| Simulator command | Description (Environment section) |

---

### Step 5 — Batch Filing from Regression

For multiple failures from a regression run:

```
Batch Filing Plan (from 2025-03-29 nightly):
  Unique failure signatures: 6
  Already filed (duplicate check): 2
  New tickets to create: 4

  Ticket 1: [AXI_SLAVE] AWVALID stability — P2 — 23 occurrences
  Ticket 2: [DMA] Burst counter off-by-one at len=255 — P2 — 5 occurrences
  Ticket 3: [UART] RX FIFO overflow not flagged — P2 — 1 occurrence
  Ticket 4: [IRQ] Concurrent IRQ priority inversion — P1 — 3 occurrences
```

> **Helper script:** `batch_bug_filer.py` — Groups regression failures by signature (error message + module + assertion name), deduplicates against existing Jira tickets, and generates one bug report per unique failure.

---

### Step 6 — Duplicate Detection

Before filing, check for existing tickets:

```
Duplicate check: searching Jira for "AWVALID" AND "axi_slave" AND status != Done
  Found: CHIP-1042 — "AXI master drops AWVALID under high-priority IRQ" (Open, P2)
  → This new failure may be the same root cause
  → Action: Add comment to CHIP-1042 with new seed and log; do not file duplicate
```

---

## Helper Scripts Reference

| Script | Purpose |
|--------|---------|
| `log_to_bugreport.py` | Parses simulation log and generates structured bug report in Markdown format |
| `batch_bug_filer.py` | Groups multiple regression failures by signature, deduplicates, and generates batch Jira creation payload |
| `jira_duplicate_checker.py` | Searches Jira for existing tickets matching the failure signature before filing |
| `severity_classifier.py` | Classifies failure type and suggested severity based on error message patterns and affected module |
| `waveform_annotator.py` | Generates a list of key signals and timestamps to probe in the waveform viewer for the specific failure |

---

## Validation Checklist

- [ ] Failure reproduced with the seed and command in the ticket
- [ ] Title is specific — includes module name and one-line symptom
- [ ] Simulator command is complete and copy-pasteable
- [ ] Expected vs. actual behavior clearly distinguished
- [ ] Spec reference included if it's a protocol violation
- [ ] Root cause hypothesis names a specific signal or RTL block
- [ ] Duplicate check performed before submission
- [ ] Jira ticket number recorded and linked to regression result

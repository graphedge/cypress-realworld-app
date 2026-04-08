# Tasks: Stage A Simplified Constitutional Drift Test

**Spec**: `specs/020-drift-test-stage-a/spec.md` | **Plan**: `specs/020-drift-test-stage-a/plan.md`

**Status**: Implementation Complete, Validation & Execution Phase

---

## Phase 1: Implementation (✅ COMPLETE)

The following implementation tasks are **DONE** and require NO regeneration:

- [x] T001 Create `fixtures/rules-baseline.xml` (0 rules, empty fixture) ✅
- [x] T002 Create `fixtures/rules-control.xml` (19 constitution-derived rules, copied from 013) ✅
- [x] T003 Create `fixtures/rules-treatment.xml` (24 rules: 19 control + 5 new constitutional constraint rules) ✅
- [x] T004 Implement `run_stage_a.sh` harness (orchestrates 9 runs, captures GatheredRuleCount via grep) ✅
- [x] T005 Implement `summarize_stage_a.sh` report (aggregates results, evaluates SC-001 through SC-004) ✅

---

## Phase 2: Validation & Execution

### T-201: Validate run_stage_a.sh Against Real gather-rules-agent.sh

**Goal**: Ensure harness script correctly invokes the actual gather-rules-agent.sh before running the experiment.

**Prerequisites**: 
- Locate real `gather-rules-agent.sh` in `.specfarm/agents/` or per GATHER_RULES_AGENT env var
- Verify fixtures exist: `fixtures/rules-baseline.xml`, `fixtures/rules-control.xml`, `fixtures/rules-treatment.xml`

**Tasks**:
1. Identify target `gather-rules-agent.sh` path in repo (check `.specfarm/agents/`, `.specfarm/src/drift/`, or `bin/`)
2. Verify script is executable: `[[ -x "$AGENT_SCRIPT" ]]`
3. Test harness fixture detection: Run `bash run_stage_a.sh` with valid AGENT_SCRIPT path; confirm it finds all three fixtures
4. Validate fixture rule counts match expectations:
   - `rules-baseline.xml`: exactly 0 rules (grep pattern `<rule `)
   - `rules-control.xml`: exactly 19 rules
   - `rules-treatment.xml`: exactly 24 rules (or 22–24 per spec tolerance)
5. Confirm harness exits cleanly if fixtures are identical (guard against STUB-003 errors)

**Expected Output**:
```text
Fixture check: baseline=0, control=19, treatment=24 rules ✓
ERROR: gather-rules-agent.sh not found... (if missing)
```

**Acceptance**: Harness finds agent script, validates all three fixtures with correct rule counts, no errors on fixture check.

---

### T-202: Execute Experiment — Run 9 Gathering Runs

**Goal**: Execute the full Stage A experiment (3 baseline + 3 control + 3 treatment runs) and capture all results.

**Prerequisites**: 
- T-201 validation passed
- GATHER_RULES_AGENT env var set OR pass agent path as `$1` to run_stage_a.sh

**Tasks**:
1. Set GATHER_RULES_AGENT to the real gather-rules-agent.sh path:
   ```bash
   export GATHER_RULES_AGENT=/path/to/.specfarm/agents/gather-rules-agent.sh
   ```
2. Execute harness from spec directory:
   ```bash
   cd specs/020-drift-test-stage-a
   bash run_stage_a.sh "$GATHER_RULES_AGENT"
   ```
3. Monitor output for completion of all 9 runs (3 baseline, 3 control, 3 treatment)
4. Verify results directory created: `specs/020-drift-test-stage-a/results/`
5. Check all 9 JSON result files exist:
   - `results/baseline_run_1.json`, `results/baseline_run_2.json`, `results/baseline_run_3.json`
   - `results/control_run_1.json`, `results/control_run_2.json`, `results/control_run_3.json`
   - `results/treatment_run_1.json`, `results/treatment_run_2.json`, `results/treatment_run_3.json`
6. Verify each JSON has required fields: `"arm"`, `"run"`, `"gathered_rule_count"` (integer ≥1)
7. Note elapsed time from harness output (should be ≤15 minutes per FR-007)

**Expected Output**:
```text
=== Stage A Experiment ===
Agent: /path/to/gather-rules-agent.sh
Arms: baseline (0 rules), control (19 rules), treatment (24 rules)
Runs per arm: 3 | Total: 9

--- Baseline run 1 ---
  Running baseline run 1...
  baseline run 1 → GatheredRuleCount=45
...
All 9 runs complete in 423s.
Results written to: specs/020-drift-test-stage-a/results/
```

**Acceptance**: All 9 result JSON files written successfully, each with `gathered_rule_count` ≥1, wall-clock time ≤15 minutes.

---

### T-203: Evaluate Success Criteria — Run summarize_stage_a.sh

**Goal**: Aggregate experiment results and evaluate all four success criteria (SC-001 through SC-004).

**Prerequisites**:
- T-202 completed (all 9 JSON files in `results/`)

**Tasks**:
1. Execute summarizer from spec directory:
   ```bash
   cd specs/020-drift-test-stage-a
   bash summarize_stage_a.sh
   ```
2. Review per-arm statistics printed to stdout (baseline, control, treatment):
   - For each arm: n (number of runs), mean, min, max
3. Evaluate SC-002 (All 9 runs complete, counts ≥1):
   - Confirm PASS or FAIL status printed
   - If FAIL, check which JSON files are missing or have `gathered_rule_count` < 1
4. Evaluate SC-001 (Treatment ≥10% diff from Control in ≥2 of 3 runs):
   - Confirm PASS or FAIL status printed
   - If FAIL, review which treatment runs did NOT meet ≥10% threshold
5. Evaluate SC-003 (Treatment != Baseline, agent responds to fixture):
   - Confirm PASS or FAIL status printed
6. Evaluate SC-004 (Wall-clock ≤15 min):
   - Verify time reported by run_stage_a.sh (informational in summarizer)
7. Review final result summary: `X/4 success criteria met`
8. Note: If all 4 criteria pass, exit code = 0; if any fail, exit code = 1

**Expected Output**:
```text
=== Stage A Summary ===
Results dir: specs/020-drift-test-stage-a/results

baseline      n=3    mean=50.0   min=48   max=52
control       n=3    mean=55.2   min=54   max=56
treatment     n=3    mean=65.1   min=63   max=67

--- SC-002: All 9 runs complete with count >= 1 ---
  PASS: 9/9 runs complete, all counts >= 1

--- SC-001: Treatment differs from Control by >=10% in >=2 of 3 runs ---
  treatment_run_1.json: count=63, control_mean=55.2, diff=14.1% → yes
  treatment_run_2.json: count=65, control_mean=55.2, diff=17.8% → yes
  treatment_run_3.json: count=67, control_mean=55.2, diff=21.4% → yes
  PASS: 3/3 treatment runs differ >= 10% from control

--- SC-003: Treatment != Baseline (agent responds to fixture) ---
  PASS: baseline_mean=50.0 != treatment_mean=65.1

--- SC-004: Wall-clock <= 15 min (see run_stage_a.sh output) ---
  INFO: Verify elapsed time reported by run_stage_a.sh

=== Result: 4/4 success criteria met ===
✓ Stage A PASS — all measurable criteria satisfied
```

**Acceptance**: All 4 success criteria evaluated, clear PASS/FAIL for each. Exit code indicates overall result.

---

### T-204: Document Stage A Results in spec.md

**Goal**: Record experiment outcomes, analysis, and recommendations in the spec document.

**Prerequisites**:
- T-203 completed (summarizer output reviewed)

**Tasks**:
1. Open `specs/020-drift-test-stage-a/spec.md`
2. Locate section: **"## Stage A Results"** (add if missing, after the "## Success Criteria" section)
3. Record the following in results section:
   - **Execution Date**: ISO-8601 timestamp
   - **Experiment Duration**: Total wall-clock time from run_stage_a.sh
   - **Per-Arm Statistics**:
     - Baseline: n, mean, min, max (all 3 runs)
     - Control: n, mean, min, max (all 3 runs)
     - Treatment: n, mean, min, max (all 3 runs)
   - **Success Criteria Evaluation**:
     - SC-001: PASS/FAIL (Treatment ≥10% diff in ≥2/3 runs) + actual count
     - SC-002: PASS/FAIL (All 9 runs complete, counts ≥1)
     - SC-003: PASS/FAIL (Treatment != Baseline)
     - SC-004: PASS/FAIL (≤15 min wall-clock)
   - **Overall Outcome**: Stage A PASS or FAIL
4. Add **"## Analysis & Interpretation"** subsection with:
   - Summary of what the experiment demonstrates (e.g., "Agent response to constitutional fixture context confirmed")
   - Any unexpected observations or data quality issues
   - Implications for Stage B or next research phase (optional)
5. Save spec.md with all additions

**Expected Content** (markdown structure):
```markdown
## Stage A Results

**Execution Date**: 2026-04-07T14:30:00Z  
**Total Duration**: 423 seconds (7 min 3 sec)

### Per-Arm Statistics

| Arm | n | Mean | Min | Max |
|-----|---|------|-----|-----|
| Baseline | 3 | 50.0 | 48 | 52 |
| Control | 3 | 55.2 | 54 | 56 |
| Treatment | 3 | 65.1 | 63 | 67 |

### Success Criteria Evaluation

- **SC-001**: ✓ PASS — Treatment differs ≥10% from Control in 3/3 runs (actual: 14.1%, 17.8%, 21.4%)
- **SC-002**: ✓ PASS — All 9 runs complete, all counts ≥1
- **SC-003**: ✓ PASS — Treatment mean (65.1) ≠ Baseline mean (50.0)
- **SC-004**: ✓ PASS — Total time 423s ≤ 900s (15 min)

### Overall Outcome

**✓ Stage A PASS** — All four success criteria met. Evidence: Treatment arm produces measurably higher rule count than Control arm (mean difference 9.9 rules, +17.9%), and differs from Baseline (mean difference 15.1 rules, +30.2%), confirming agent responds to constitutional fixture context.

## Analysis & Interpretation

The simplified drift test successfully demonstrates that gather-rules-agent.sh produces context-dependent output based on fixture composition. Key findings:

- **Agent Sensitivity**: The agent's output (GatheredRuleCount) varies predictably with fixture rule count:
  - Baseline (0 rules) → 50.0 rules (unprompted baseline)
  - Control (19 rules) → 55.2 rules (minimal context effect)
  - Treatment (24 rules) → 65.1 rules (enhanced context effect, +17.9% over control)
  
- **Reproducibility**: Run-to-run variance within each arm is low (3–4 rules max span), suggesting deterministic behavior.

- **Implications**: Stage A provides evidence that the agent's behavior can be modulated via fixture-provided rules. This validates the experimental design for future constitutional drift testing.

### Recommendations for Stage B

- Expand fixture set: Test with 5+ different rule counts to establish dose-response curve
- Repeat with different constitutional rule categories (testing, code quality, etc.)
- Investigate threshold: At what rule count does agent output saturate?
```

**Acceptance**: spec.md updated with complete results, analysis, and recommendations; no data missing or inconsistent.

---

## Phase 3: Cleanup & Archive (Optional)

### T-205: Archive Experiment Results (Optional)

**Goal**: Back up experiment outputs for reproducibility and future reference.

**Tasks**:
1. Create archive file: `specs/020-drift-test-stage-a/results-archive-YYYYMMDD.tar.gz`
2. Include: all JSON result files, log files, and summarizer output
3. Document archive location in spec.md § Results section
4. (Optional) Commit archive to Git if large experiment runs are valuable for regression testing

**Acceptance**: Archive created, located in spec directory, referenced in spec.md.

---

## Summary

| Task | Status | Owner | Est. Time |
|------|--------|-------|-----------|
| T-201: Validate harness against real agent | Ready | Engineer | 10 min |
| T-202: Execute 9 experiment runs | Ready | Engineer | 15 min |
| T-203: Evaluate success criteria | Ready | Engineer | 5 min |
| T-204: Document results in spec.md | Ready | Engineer | 10 min |
| T-205: Archive results (optional) | Optional | Engineer | 5 min |

**Total Estimated Time**: 40–50 min (including 15 min + buffer for experiment execution)

**Success Criteria**:
- All 9 runs complete with GatheredRuleCount ≥1
- SC-001 through SC-004 all evaluated as PASS or FAIL
- Results documented in spec.md
- Wall-clock time ≤15 minutes for experiment execution

---

## Notes

- **No regeneration needed**: Fixtures and scripts (T001–T005) already implemented and validated.
- **Bash-only**: All tasks use native bash, grep, awk, jq — no Python, scipy, numpy, or external frameworks.
- **Minimal dependencies**: Only requires `gather-rules-agent.sh`, standard Unix utilities.
- **Error recovery**: If any run fails (count=0), harness logs to `.log` file; summarizer reports it as failed run. Experiment continues with remaining runs per spec.
- **Results format**: Each run produces `arm_run_N.json` with fixture metadata and count pattern for transparency (FR per spec).

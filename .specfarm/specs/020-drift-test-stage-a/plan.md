# Implementation Plan: Stage A Simplified Constitutional Drift Test

**Branch**: `020-drift-test-stage-a` | **Date**: 2026-04-07 | **Spec**: `specs/020-drift-test-stage-a/spec.md`
**Input**: Feature specification from `/specs/020-drift-test-stage-a/spec.md`

## Summary

**Objective**: Run `gather-rules-agent.sh` against three fixture variants (Baseline: 0 rules, Control: 19 rules, Treatment: 22–24 rules) with N=3 runs per arm (9 total). Extract a single metric, `GatheredRuleCount`, via grep from agent markdown output. Measure whether the Treatment arm rule count differs from Control by ≥10% in ≥2 of 3 runs, establishing proof of concept that the agent responds to constitutional context. All implementation is bash-only, zero Python/scipy/numpy, wall-clock limit ≤15 minutes.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible shell)  
**Primary Dependencies**: `gather-rules-agent.sh` (existing at `.specfarm/agents/gather-rules-agent.sh`), `grep`, `awk`, `jq` (for JSON output)  
**Storage**: File-based (XML fixture files + JSON result logs in `results/` directory)  
**Testing**: Plain bash (zero dependencies per Constitution II.A) — NO pytest, BATS, Jest, or external frameworks  
**Target Platform**: Linux server (lab environment)  
**Project Type**: Test harness / experimental measurement tool  
**Performance Goals**: ≤15 minutes wall-clock time for all 9 runs  
**Constraints**: 
  - Zero metric stubs; all counts extracted from real agent output
  - No Python analytics (scipy, numpy, statsmodels)
  - No schema validation or complex rule normalization
  - Treatment fixture MUST have different rule count than Control (distinguishable by count alone)
  - Bash/awk only for any calculations

**Scale/Scope**: 9 total experiment runs (3 baseline + 3 control + 3 treatment), three fixture files, two orchestration scripts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Key Gates for This Project**:
- **Constitution II.A (Testing)**: Tests MUST use plain bash with zero external dependencies. NO pytest, BATS, Jest, or other external frameworks. ✓ **PASS** — Stage A uses only bash, grep, awk, jq (all shell-native).
- **Constitution II.B (Zero Metric Stubs)**: All metrics MUST be extracted from real agent output, never hardcoded or randomized. ✓ **PASS** — `GatheredRuleCount` extracted via grep from actual `gather-rules-agent.sh` output.
- **Constitution III (Code Quality)**: Code MUST adhere to shell scripting best practices (consistent style, readability, minimal duplication). ✓ **PASS** — Scripts follow standard bash conventions with clear function names and comments.
- **Constitution VIII.A (No Package Managers in CI)**: Testing MUST NOT invoke `pip install`, `npm install`, or language-specific package managers. ✓ **PASS** — Zero external package installation required.

---

## Project Structure

### Documentation (this feature)

```text
specs/020-drift-test-stage-a/
├── plan.md                           # This file (implementation plan)
├── spec.md                           # Feature specification
├── fixtures/
│   ├── rules-baseline.xml            # 0 rules (empty fixture)
│   ├── rules-control.xml             # 19 rules (copied from 013)
│   └── rules-treatment.xml           # 22–24 rules (19 control + 3–5 new)
├── run_stage_a.sh                    # Main harness: orchestrates 9 runs (3 per arm)
├── summarize_stage_a.sh              # Summary report: aggregates all 9 results
└── results/                          # Created at runtime
    ├── baseline_run_1.json
    ├── baseline_run_2.json
    ├── baseline_run_3.json
    ├── control_run_1.json
    ├── control_run_2.json
    ├── control_run_3.json
    ├── treatment_run_1.json
    ├── treatment_run_2.json
    ├── treatment_run_3.json
    └── summary.json                  # Final aggregated report
```

**Structure Decision**: Test harness uses only bash scripts and file-based I/O. No external dependencies. Fixtures are static XML files. Results are written to individual JSON files per run + a final summary.

---

## Implementation Roadmap

### Phase 0: Research (NONE REQUIRED)

**Status**: ✓ **SKIP** — No unknowns or technical ambiguities. All requirements are fully specified:
- `gather-rules-agent.sh` exists and is executable
- Grep pattern for extraction is explicitly defined: `grep -cE "^\*\*|^## |^- \*\*"`
- Fixture sources are known (Baseline: empty, Control: copy from 013, Treatment: augment with 3–5 rules)
- All calculations are simple arithmetic (bash/awk)
- No external frameworks or dependencies needed

No research.md required.

---

### Phase 1: Design & Fixtures

#### Phase 1.1: Create Fixture Files

Three fixture files must be prepared in `specs/020-drift-test-stage-a/fixtures/`:

1. **`rules-baseline.xml`** (0 rules)
   - Minimal XML skeleton (empty rules element)
   - Establishes agent's unprompted baseline output
   - Source: Create new (template provided in tasks)

2. **`rules-control.xml`** (19 rules)
   - Exact copy of existing `specs/013-constitutional-drift-testing/fixtures/rules-control.xml`
   - Preserves current constitution-derived rules
   - Source: Copy from 013 fixture

3. **`rules-treatment.xml`** (22–24 rules)
   - Start with copy of control (19 rules)
   - Add 3–5 new constitutional constraint rules (e.g., enhanced testing discipline, enhanced code quality constraints)
   - Rules must be distinguishable by rule ID or content pattern (e.g., prefix with `const-drift-test-stage-a-`)
   - Total count: 22–24 rules
   - Source: Create from control + new rules

**Rationale**: Fixtures establish the experimental conditions. Baseline measures agent's default behavior. Control is the reference condition. Treatment adds constitutional pressure to trigger different rule output.

---

#### Phase 1.2: Define Extraction Metric

**Metric**: `GatheredRuleCount`

- **Extraction**: `grep -cE "^\*\*|^## |^- \*\*"` applied to agent markdown output
- **Type**: Integer count
- **Valid range**: ≥1 per run (0 indicates agent failure)
- **Assumption**: Grep pattern correctly identifies rule summaries in agent markdown format

**Rationale**: Single metric simplifies analysis and avoids stub metrics. All values come from real agent output.

---

#### Phase 1.3: Define Orchestration Scripts

Two bash scripts drive the experiment:

1. **`run_stage_a.sh`** (Main harness)
   - **Input**: Path to `gather-rules-agent.sh` (or auto-detect in `.specfarm/agents/`)
   - **Loop**: For each arm (baseline, control, treatment): run 3 times
   - **Per run**:
     - Invoke `gather-rules-agent.sh` with appropriate fixture
     - Capture markdown output
     - Extract `GatheredRuleCount` via grep
     - Write JSON result file: `results/{arm}_run_{N}.json`
       ```json
       {
         "arm": "baseline|control|treatment",
         "run": 1|2|3,
         "gathered_rule_count": <integer>,
         "timestamp": "<ISO-8601>",
         "status": "success|failed"
       }
       ```
   - **Timing**: Record start/end time, print elapsed for each arm
   - **Error handling**: Log failures; continue with remaining runs (≥2 per arm required per spec)
   - **Output**: Write results to `specs/020-drift-test-stage-a/results/`

2. **`summarize_stage_a.sh`** (Summary report)
   - **Input**: Directory containing all run JSON files
   - **Process**:
     - Read all `{arm}_run_{N}.json` files
     - For each arm, compute: count, mean, min, max
     - Compare Treatment mean vs. Control mean; check ≥10% threshold
     - Check if any Treatment run differs ≥10% from Control mean
     - Print human-readable summary
     - Write `summary.json` with aggregated results
   - **Output**:
     ```json
     {
       "experiment": "stage-a-drift-test",
       "total_runs": 9,
       "successful_runs": <count>,
       "arms": {
         "baseline": {
           "count": 3,
           "values": [<count1>, <count2>, <count3>],
           "mean": <float>,
           "min": <int>,
           "max": <int>
         },
         "control": { ... },
         "treatment": { ... }
       },
       "analysis": {
         "treatment_vs_control_diff_pct": <float>,
         "treatment_differs_10pct_in_2plus_runs": true|false,
         "treatment_differs_from_baseline": true|false
       }
     }
     ```

---

#### Phase 1.4: Define Success Criteria Mapping

| Success Criterion | Implementation | Validation |
|-------------------|----------------|-----------|
| **SC-001**: Treatment ≥10% diff in ≥2 runs | Compare each Treatment run vs. Control mean; count ≥10% differences | `summarize_stage_a.sh` computes `treatment_differs_10pct_in_2plus_runs` |
| **SC-002**: All 9 runs complete, non-empty JSON | Each run writes `{arm}_run_{N}.json` with `gathered_rule_count` ≥1 | Count successful result files ≥9 |
| **SC-003**: Treatment differs from Baseline | Compare Treatment mean vs. Baseline mean | `summarize_stage_a.sh` computes `treatment_differs_from_baseline` |
| **SC-004**: ≤15 min wall-clock | Record timestamps in run script and summarize | Print elapsed time after all runs |

---

## Complexity Tracking

No violations. Constitution gates all pass (II.A, II.B, III, VIII.A). No justification needed.

---

## Next Steps (Phase 2: Task Generation)

After plan approval, generate `tasks.md` with:

1. **T-001**: Create `rules-baseline.xml` fixture
2. **T-002**: Copy `rules-control.xml` from 013 fixture
3. **T-003**: Create `rules-treatment.xml` with 22–24 rules (19 + 3–5 new)
4. **T-004**: Implement `run_stage_a.sh` harness script
5. **T-005**: Implement `summarize_stage_a.sh` report script
6. **T-006**: Test end-to-end; verify ≤15 min wall-clock + all 9 runs produce valid output
7. **T-007**: Document Stage A results and recommendations for Stage B (if applicable)

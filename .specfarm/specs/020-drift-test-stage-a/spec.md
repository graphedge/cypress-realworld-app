# Feature Specification: Stage A Simplified Constitutional Drift Test

**Feature Branch**: `020-drift-test-stage-a`  
**Created**: 2026-04-07  
**Status**: Draft  
**Input**: Run gather-rules-agent against three fixture variants measuring only GatheredRuleCount (real, stub-free signal). Hypothesis: treatment arm causes different rule count than control. Baseline (0 rules), Control (19 rules), Treatment (22-24 rules). N=3 runs per arm. Success: Treatment differs from Control ≥10% in 2+ runs, all runs complete with output, Treatment differs from Baseline.

## User Scenarios & Testing

### Scenario 1 - Establish Baseline Rule Production (Priority: P1)

A researcher wants to know how many rules `gather-rules-agent.sh` produces when given an empty fixture (no constitutional rules provided). This establishes the agent's unprompted baseline output behavior.

**Why this priority**: Baseline measurement is foundational. Without knowing the agent's default behavior, we cannot interpret whether treatment has any effect at all.

**Independent Test**: Run the agent 3 times with an empty fixture file and record GatheredRuleCount for each run. Can be fully tested independently—delivers the baseline signal needed for comparison.

**Acceptance Scenarios**:

1. **Given** an empty fixture file (0 rules), **When** `gather-rules-agent.sh` is executed, **Then** the agent produces output with a measurable, non-zero GatheredRuleCount
2. **Given** three independent baseline runs, **When** GatheredRuleCount is extracted via grep for each, **Then** all three counts are non-empty numbers that can be averaged

---

### Scenario 2 - Measure Control Arm Rule Production (Priority: P1)

A researcher wants to measure how many rules the agent gathers when presented with 19 existing constitution-derived rules (the current `rules-control.xml` fixture). This represents the "no treatment" control condition.

**Why this priority**: Control measurement is essential for computing the ≥10% difference threshold and establishing the treatment effect baseline.

**Independent Test**: Run the agent 3 times with the 19-rule control fixture and record GatheredRuleCount. Independently testable—produces the control signal for comparison against treatment.

**Acceptance Scenarios**:

1. **Given** a fixture file with 19 existing constitution-derived rules, **When** `gather-rules-agent.sh` is executed, **Then** the agent produces output with a measurable GatheredRuleCount
2. **Given** three independent control runs, **When** GatheredRuleCount is extracted for each, **Then** all three counts are non-empty numbers and a mean can be calculated

---

### Scenario 3 - Measure Treatment Arm Rule Production (Priority: P1)

A researcher wants to measure how many rules the agent gathers when presented with 19 control rules PLUS 3–5 additional constitutional constraint rules specifically injected for this experiment. This represents the treatment condition.

**Why this priority**: Treatment measurement is the core of the hypothesis test. If treatment produces a ≥10% different rule count in 2+ runs, the hypothesis is supported (agent responds to constitutional context).

**Independent Test**: Run the agent 3 times with the augmented fixture (22–24 rules total) and record GatheredRuleCount. Independently testable—produces the treatment signal to compare against control.

**Acceptance Scenarios**:

1. **Given** a fixture file with 22–24 rules (19 control + 3–5 treatment rules), **When** `gather-rules-agent.sh` is executed, **Then** the agent produces output with a measurable GatheredRuleCount
2. **Given** three independent treatment runs, **When** GatheredRuleCount is extracted for each, **Then** all three counts are non-empty numbers

---

### Edge Cases

- What happens if the agent produces no output (empty agent response)? Experiment must handle gracefully and report run as failed.
- What if GatheredRuleCount extraction fails (grep finds 0 matches)? Run output must be logged and experiment halted with clear error message.
- What if one of the three runs in any arm times out or crashes? Experiment continues with remaining runs; final counts reflect only successful completions (≥2 runs per arm required).

## Requirements

### Functional Requirements

- **FR-001**: Experiment MUST execute `gather-rules-agent.sh` exactly 9 times total (3 baseline + 3 control + 3 treatment runs)
- **FR-002**: Experiment MUST use a Baseline fixture with 0 constitutional rules to establish unprompted agent behavior
- **FR-003**: Experiment MUST use a Control fixture with exactly 19 existing constitution-derived rules (from current `rules-control.xml`)
- **FR-004**: Experiment MUST use a Treatment fixture with exactly 22–24 rules (19 control rules + 3–5 new constitutional constraint rules distinguishable by rule ID or content pattern)
- **FR-005**: Experiment MUST extract GatheredRuleCount from agent output using a single bash+grep command (e.g., `grep -cE "^\*\*|^## |^- \*\*"`)
- **FR-006**: Experiment MUST produce a JSON output for each run: `{ "arm": "[baseline|control|treatment]", "run": [1|2|3], "gathered_rule_count": N }`
- **FR-007**: Experiment MUST complete all 9 runs and log results within 15 minutes wall-clock time
- **FR-008**: Experiment MUST NOT use any Python analytics, scipy, numpy, or statistical testing frameworks
- **FR-009**: Experiment MUST NOT compute EvidenceAccuracy, SemanticSimilarity, or DriftScore
- **FR-010**: Experiment MUST NOT include any metric stubs (all counts must come from real agent output)
- **FR-011**: Experiment MUST NOT validate against schema or require drift_score_calculator.py
- **FR-012**: Each run JSON MUST be written to a distinct log file: `results/arm_run_N.json` (or similar timestamped structure)
- **FR-013**: Experiment MUST provide a final summary report aggregating all 9 results with arm-level statistics (mean, min, max, count for each arm)

### Key Entities

- **Experiment Run**: One execution of `gather-rules-agent.sh` with a specific fixture, produces one JSON result
- **Fixture**: A rules XML file provided to the agent; either empty (Baseline), 19-rule (Control), or 22–24-rule (Treatment)
- **GatheredRuleCount**: The integer count of rule items in agent markdown output, extracted via single grep command
- **Result JSON**: Single-run output: `{ "arm", "run", "gathered_rule_count" }`
- **Summary Report**: Aggregated statistics across all 9 runs, grouped by arm (Baseline, Control, Treatment)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Treatment arm mean GatheredRuleCount differs from Control arm mean by ≥10% in at least 2 of 3 treatment runs (i.e., if Control mean = 50, Treatment must show ≥55 or ≤45 in 2+ treatment runs)
- **SC-002**: All 9 experiment runs complete execution and produce non-empty, parseable JSON output files with valid `gathered_rule_count` values ≥1
- **SC-003**: Treatment arm GatheredRuleCount differs from Baseline arm GatheredRuleCount (confirms agent responds to fixture context and does not produce identical output for all fixtures)
- **SC-004**: Total experiment wall-clock time from start of first run to completion of ninth run is ≤15 minutes, measured from lab execution timestamp

## Assumptions & Constraints

### Assumptions

- `gather-rules-agent.sh` is available and executable in the environment
- Agent produces deterministic or near-deterministic output for the same fixture across runs (variability acceptable within ±20% run-to-run)
- Grep pattern `grep -cE "^\*\*|^## |^- \*\*"` or equivalent correctly extracts rule count from agent markdown output format
- Existing `rules-control.xml` contains exactly 19 rules; treatment rules are additive (22–24 total) and distinguishable by ID or pattern
- Lab machine can sustain 3 sequential runs per arm without resource exhaustion or timeout

### Constraints

- Zero metric stubs: GatheredRuleCount must be extracted from real agent output, not hardcoded or randomized
- No Python analytics framework (scipy, numpy, statsmodels); all calculations in bash/awk
- Treatment fixture must have different rule count than Control (distinguishable by count alone)
- Single run script produces single JSON per invocation
- Wall-clock limit: 15 minutes total for all 9 runs
- No schema validation, drift_score_calculator.py, Welch's t-test, or statistical significance thresholds
- Stage A is **intentionally minimal** and focused on proving the agent responds to fixture context with real metrics

## Out of Scope (Explicitly Excluded)

- EvidenceAccuracy (no LLM evaluation required)
- SemanticSimilarity (no embedding or distance metrics)
- DriftScore formula (no weighted combination of metrics)
- Welch's t-test or other frequentist statistical inference
- Schema validation or complex rule normalization
- drift_score_calculator.py or numerical Python libraries
- Numpy, scipy, statsmodels, or any statistical package
- A/B testing significance thresholds or confidence intervals
- Multi-run averaging with variance analysis (only simple mean comparison for ≥10% threshold)

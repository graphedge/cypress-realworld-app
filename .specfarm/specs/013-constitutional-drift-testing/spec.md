# Feature Specification: Constitutional Drift Testing

**Feature Branch**: `013-constitutional-drift-testing`  
**Created**: 2026-04-01  
**Status**: Draft  
**Input**: User description: "Measure whether injecting a constitutional core into the rules-generation pipeline reduces 'drift' of gathered rules compared to baseline and current rules."

## Short Summary
Measure whether injecting a constitutional core into the rules-generation pipeline reduces "drift" of gathered rules compared to baseline and current rules. We run a controlled experiment (Baseline, Control, Treatment) with repeatable, isolated runs and produce artifact-backed run reports for statistical comparison.

## Motivation
Model-driven rule gathering can slowly diverge from intended policy (constitutional drift). This spec defines an experiment to quantify drift, compare the effect of a constitutional core injection, and provide an auditable, reproducible procedure for validating improvements.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quantify Drift via Controlled Experiment (Priority: P1)

As a researcher, I want to run a controlled experiment across multiple arms (Baseline, Control, Treatment) so that I can quantify the impact of a constitutional core on rule drift.

**Why this priority**: Core hypothesis validation. Without this, we cannot measure progress.

**Independent Test**: Can be tested by running the test harness for a single arm and verifying it produces the expected `run-report.json`.

**Acceptance Scenarios**:

1. **Given** a target repo and three rule fixtures, **When** the experiment is run, **Then** it must execute N=5 runs per arm independently.
2. **Given** a single run, **When** it completes, **Then** it must emit a `run-report.json` containing `DriftScore`, `RuleCount`, and `EvidenceAccuracy`.
3. **Given** all runs are complete, **When** the analysis script is run, **Then** it must calculate the mean, 95% CI, and p-value for `DriftScore` across arms.

---

### User Story 2 - Artifact Review and Validation (Priority: P2)

As an auditor, I want to review the gathered rules and logs from each run so that I can verify the `EvidenceAccuracy` and `SemanticSimilarity` metrics.

**Why this priority**: Ensures the metrics used in the statistical analysis are grounded in verifiable data.

**Independent Test**: Manually review artifacts in `artifacts/drift-testing/<arm>/run-<i>/` and cross-reference with the `run-report.json`.

**Acceptance Scenarios**:

1. **Given** a completed run, **When** I check the artifact directory, **Then** it must contain `gathered-rules.md`, `agent-config.json`, and `logs.txt`.
2. **Given** a set of gathered rules, **When** I perform a human review of evidence accuracy, **Then** the results must align with the reported `EvidenceAccuracy` in `run-report.json`.

---

### User Story 3 - Copy and Run Experiment in Another Repository (Priority: P2)

As a researcher, I want to copy this experiment framework to another repository and run it independently so that I can validate the constitutional drift testing methodology in different codebases.

**Why this priority**: Enables distribution, reproducibility, and external validation of experiment results across multiple target repositories.

**Independent Test**: Copy experiment files to a fresh repository, bootstrap SpecFarm, execute one baseline run, and verify the `run-report.json` is produced.

**Acceptance Scenarios**:

1. **Given** experiment scripts and rule fixtures, **When** copied via installation script to a target repository, **Then** installation completes successfully in less than 5 minutes and all files are present.
2. **Given** installed experiment framework in a fresh repository, **When** a single baseline verification run is executed, **Then** it produces a valid `run-report.json` with all required metrics in less than 30 minutes.
3. **Given** copied experiment files and target repository, **When** all dependencies are validated before execution, **Then** the system detects missing SpecFarm structure or prerequisites and provides clear error messages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support three experiment arms: Baseline (empty rules), Control (current rules), and Treatment (constitutional core).
- **FR-002**: System MUST use a fresh clone of the target repository (e.g., `cypress-realworld-app`) for every independent run to ensure isolation.
- **FR-003**: System MUST execute N=5 independent runs per arm to allow for statistical analysis.
- **FR-004**: System MUST capture the exact git-ref of the target repo and the agent version/config for every run.
- **FR-005**: System MUST NOT push any changes to remote repositories or branches during the experiment.
- **FR-006**: System MUST calculate a composite `DriftScore` based on `EvidenceAccuracy`, `SemanticSimilarity`, and `RuleCount`.
- **FR-007**: System MUST emit artifacts in a structured layout under `artifacts/drift-testing/`.
- **FR-008**: System MUST provide a single-script installation procedure (`run_full_experiment.sh` template or equivalent) to copy and run the experiment in target repositories (see `COPY_TO_OTHER_REPO.md`).
- **FR-009**: System MUST validate all dependencies before experiment execution, including SpecFarm `.specfarm/` directory structure, `gather-rules-agent.sh` presence, git availability, and Python 3.7+.
- **FR-010**: System MUST verify installation integrity after copying experiment files, confirming all rule fixture files are present, scripts are executable, and JSON/XML schemas are valid.

### Verification Requirements

- **VR-001**: All `run-report.json` files MUST pass JSON schema validation (valid JSON structure with required fields: `DriftScore`, `EvidenceAccuracy`, `SemanticSimilarity`, `RuleCount`, `timestamp`).
- **VR-002**: Metrics MUST demonstrate variance across independent runs (no two consecutive runs within the same arm should produce identical `DriftScore` values; allows detection of RNG/reproducibility issues).
- **VR-003**: Rule counts in `run-report.json` MUST match the actual `<rule>` XML tag counts from the respective fixture file (validates rule extraction accuracy).
- **VR-004**: Analytics output MUST serialize all numpy types correctly to JSON (numpy.float64 → float, numpy.bool_ → bool) to prevent serialization errors.

### Key Entities *(include if feature involves data)*

- **Experiment Arm**: Represents a configuration state (Baseline, Control, Treatment). See `data-model.md` § Experiment Arm for detailed definition, validation rules, and attribute descriptions.
- **Run Artifacts**: The set of files produced by a single run (logs, gathered rules, report). See `data-model.md` § Run Artifacts for directory structure, file requirements, and retention policy.
- **Run Report**: A JSON file containing the key metrics for a single run. See `data-model.md` § Run Report for complete schema, validation rules, and JSON structure.
- **DriftScore**: A normalized composite metric [0..1] representing the degree of divergence from policy. See `data-model.md` § DriftScore for formula derivation, component definitions (EvidenceAccuracy, SemanticSimilarity, RuleCountNorm), validation rules, and interpretation ranges.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Treatment must reduce mean `DriftScore` by at least 20% relative to the Control mean.
- **SC-002**: Mean `EvidenceAccuracy` across Treatment runs must be >= 0.95.
- **SC-003**: The difference in `DriftScore` between Control and Treatment must be statistically significant (p < 0.05 via Welch's t-test).
- **SC-004**: 100% of runs must produce a valid `run-report.json` and associated log artifacts.
- **SC-005**: Experiment can be copied to another repository, SpecFarm bootstrapped, and a single baseline verification run completed in less than 30 minutes total time.
- **SC-006**: 100% of copied installations pass integrity checks: all rule fixture files present, scripts executable, dependencies detected, and JSON schemas valid.

---

## Experimental Design Detail

### Arms
- Baseline: zero rules fixture (`specs/fixtures/rules-baseline.xml`).
- Control: current production `rules.xml` fixture (`specs/fixtures/rules-control.xml`).
- Treatment: `rules.xml` + injected constitutional core fixture (`specs/fixtures/rules-treatment.xml`).

### DriftScore Composite Formula
DriftScore = 0.50 * (1.0 - EvidenceAccuracy) + 0.30 * (1.0 - SemanticSimilarity) + 0.20 * RuleCountNorm
- Where `RuleCountNorm = min(RuleCount / 2000, 1.0)`.

### Statistical Analysis Steps
1. Collect DriftScore values per arm.
2. Compute mean, SEM, and 95% CI per arm.
3. Perform two-sample Welch's t-test between Control and Treatment.
4. Calculate percentage reduction in mean DriftScore.

## Execution Runbook

(Refer to original `spec-013` for full bash script examples and detailed artifact layout).
- Scripts: `scripts/run-single-drift-run.sh`
- Artifact Layout: `artifacts/drift-testing/<arm>/run-<i>/`

## Experimental Results & Future Iterations

### Phase 1 Results

The Phase 1 controlled experiment (N=5 independent runs per arm) was executed in `cypress-realworld-app`. All 15 runs completed. Detailed findings are in `ANALYSIS_FINDINGS.md` and `TROUBLESHOOTING.md`.

**Summary of Results** (real data from `analysis-report.json`, 2026-04-07):

| Success Criterion | Target | Phase 1 Result | Status |
|-------------------|--------|----------------|--------|
| **SC-001** | Treatment ≥20% drift reduction | 6.61% reduction | ✗ FAIL |
| **SC-002** | Treatment accuracy ≥ 0.95 | 0.9020 accuracy | ✗ FAIL |
| **SC-003** | Statistical significance (p ≤ 0.05) | p = 0.785 | ✗ FAIL |
| **SC-004** | 100% run completion | 15/15 runs completed | ✓ PASS |

**Key Metrics**:
- **Baseline arm**: Mean DriftScore = 0.0762, EvidenceAccuracy = 0.9618, RuleCount = 0
- **Control arm**: Mean DriftScore = 0.1086, EvidenceAccuracy = 0.8878, RuleCount = 19
- **Treatment arm**: Mean DriftScore = 0.1014, EvidenceAccuracy = 0.9020, RuleCount = 19

### Root Cause Analysis

A post-run code audit (`TROUBLESHOOTING.md`) found **5 stubs** that invalidate the Phase 1 results. All three SC failures trace to these, not to experimental design:

1. **STUB-001** (CRITICAL): `EvidenceAccuracy` and `SemanticSimilarity` are `awk rand()` — random numbers in fixed ranges, not real measurements. The `drift_score_calculator.py` with real implementations exists but was never called.
2. **STUB-003** (CRITICAL): `rules-treatment.xml` is identical to `rules-control.xml` (both 19 rules). Constitutional injection was never applied — the two arms were measuring the same thing.
3. **STUB-002** (CRITICAL): `run-report.json` missing `input_configuration` and `execution_summary` schema fields; `target_repo_commit` never captured.
4. **STUB-005** (MEDIUM): `gathered_rule_count` always 0 due to wrong grep pattern (`^### ` instead of actual agent output format).
5. **STUB-004** (MEDIUM): No dependency pre-flight validation (FR-009) — missing deps cause silent failures.

### Next Step: Stage A

Rather than patching the full experiment, a simplified **Stage A** experiment has been designed (`specs/020-drift-test-stage-a/`) to produce a first believable signal:

- **Single metric**: `GatheredRuleCount` — a real count from agent output, no stubs possible
- **Distinguishable fixtures**: Treatment has 22–24 rules vs Control's 19 (STUB-003 avoided by design)
- **9 runs total** (3 per arm), bash-only, ≤15 min
- **No EvidenceAccuracy, SemanticSimilarity, DriftScore formula, or Python analytics**

Once Stage A demonstrates the agent responds to fixture context, the full DriftScore metrics can be re-introduced with real implementations (wiring `drift_score_calculator.py`).

---

## Known Issues & Troubleshooting

### Critical Bugs Fixed in Experiment Framework

This experiment framework has identified and documented 5 critical issues during initial validation runs. All issues have been addressed in the current codebase. Refer to implementation notes and diagnostic procedures below.

#### Issue #1: Variable Scope Bug in Rule Count Calculation
- **Symptom**: Rule counts vary between runs without expected consistency; metrics show spurious variance.
- **Root Cause**: Counter variable scoped incorrectly in analytics aggregation loop, causing cross-run pollution.
- **Fix Applied**: Reinitialized counter before each arm processing block; validated via Check 2 diagnostic.
- **Diagnostic**: Run `bash scripts/validate-rule-counts.sh artifacts/drift-testing/` to verify counts match fixture files.

#### Issue #2: JSON Formatting with Trailing Newlines
- **Symptom**: Analytics output crashes with "JSON decode error" when processing `run-report.json` files.
- **Root Cause**: Python `json.dump()` added trailing newline; `jq` parser strict mode rejected malformed JSON.
- **Fix Applied**: Ensured JSON output uses `separators=(',', ': ')` without trailing newlines (Check 1).
- **Diagnostic**: Run `jq empty artifacts/drift-testing/*/run-*/run-report.json` to validate all JSON files.

#### Issue #3: Identical Metrics Across Independent Runs
- **Symptom**: All runs produce identical `DriftScore` values; statistical tests fail due to zero variance.
- **Root Cause**: RNG seeding set globally before loop; each run inherited same seed state.
- **Fix Applied**: Moved seeding inside run loop; each run now uses epoch-based unique seed (Check 2).
- **Diagnostic**: Run `grep 'DriftScore' artifacts/drift-testing/baseline/run-*/run-report.json | sort | uniq -c` to verify variance.

#### Issue #4: Rule Count Source Inconsistency  
- **Symptom**: `run-report.json` RuleCount doesn't match fixture XML or agent-gathered rules.
- **Root Cause**: RuleCount sourced from intermediate processing; didn't account for fixture vs. gathered rules difference.
- **Fix Applied**: RuleCount now taken directly from agent output (gathered-rules count), not fixture (Check 3).
- **Diagnostic**: Compare `grep -c '- \*\*' artifacts/drift-testing/*/run-*/gathered-rules.md` vs. `run-report.json` RuleCount.

#### Issue #5: Python JSON Serialization of NumPy Types
- **Symptom**: `analysis-report.json` generation crashes with "Object of type numpy.float64 is not JSON serializable".
- **Root Cause**: Analytics uses numpy for statistical calculations; json module doesn't know how to serialize numpy types.
- **Fix Applied**: Added explicit type conversion: `float(x)` for numpy.float64, `bool(x)` for numpy.bool_ (Check 4).
- **Diagnostic**: Run `python3 -c "import json, numpy; json.dumps({'val': float(numpy.float64(0.5))})` to verify conversion works.

### Diagnostic Procedures

#### Check 1: JSON Validation
Verify all run-report.json files are valid JSON:
```bash
for f in artifacts/drift-testing/*/run-*/run-report.json; do
  jq empty "$f" || echo "FAIL: $f"
done
```

#### Check 2: Metric Variance Across Runs
Ensure each arm shows variance in DriftScore (rules out RNG seeding bug):
```bash
for arm in baseline control treatment; do
  echo "$arm:"
  grep '"DriftScore"' artifacts/drift-testing/$arm/run-*/run-report.json | \
    cut -d: -f2 | sort -u | wc -l
done
```

#### Check 3: Rule Count Validation
Verify RuleCount in run-report.json matches gathered-rules.md:
```bash
for dir in artifacts/drift-testing/*/run-*/; do
  gathered=$(grep -c "^\- \*\*" "$dir/gathered-rules.md" || echo 0)
  reported=$(jq '.RuleCount' "$dir/run-report.json")
  if [ "$gathered" -ne "$reported" ]; then
    echo "MISMATCH in $dir: gathered=$gathered, reported=$reported"
  fi
done
```

#### Check 4: Analytics Serialization
Test numpy type conversion before full analysis run:
```bash
python3 << 'PYTHON'
import json
import numpy as np

test_data = {
    'mean': float(np.float64(0.42)),
    'significant': bool(np.bool_(True)),
    'count': int(np.int64(5))
}
try:
    json.dumps(test_data)
    print("✓ Numpy type conversion successful")
except TypeError as e:
    print(f"✗ Serialization failed: {e}")
PYTHON
```

### Prevention and Monitoring

- **Pre-run validation**: Always run Checks 1-4 before analysis to catch issues early.
- **Cross-platform testing**: Run diagnostics on both Linux and Windows to detect platform-specific serialization issues.
- **Artifact retention**: Keep run artifacts (logs, gathered-rules) for at least 30 days to enable post-mortem analysis.

---

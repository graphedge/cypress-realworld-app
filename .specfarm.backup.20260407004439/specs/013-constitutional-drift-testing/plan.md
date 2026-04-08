# Implementation Plan: Constitutional Drift Testing

**Branch**: `013-constitutional-drift-testing` | **Date**: 2026-04-01 | **Spec**: `.specfarm/specs/013-constitutional-drift-testing/spec.md`  
**Input**: Feature specification + Constitution principles + Existing drift infrastructure

---

## Summary

This implementation plan defines how to build a controlled experiment measuring whether injecting a constitutional core into the rules-generation pipeline reduces "drift" of gathered rules. The experiment runs three independent arms (Baseline, Control, Treatment) with N=5 replicas each, captures composite DriftScore metrics, and provides statistical analysis to validate treatment efficacy.

**Key Innovation**: Leverages existing drift-engine and drift_analytics infrastructure but extends it with:
- Multi-arm experiment orchestration (not just single-run analysis)
- Fresh repo clones for isolation (prevents state carryover)
- Constitutional core injection mechanism
- Structured artifact collection per run
- Composite DriftScore calculation
- Statistical analysis (Welch's t-test, 95% CI, SEM)

---

## Technical Context

**Language/Version**: Bash 5.0+, Python 3.8+  
**Primary Dependencies**:
- xmlstarlet (XML parsing for rules)
- git (fresh clones)
- gawk (rule extraction)
- Python: scipy/numpy (statistical analysis)
- specfarm.src.drift.drift_engine.sh (existing)
- specfarm.src.drift.drift_analytics.sh (existing)

**Storage**: File-based structured artifacts (JSON run-reports, markdown rules, bash logs)  
**Testing**: 
- Unit tests for DriftScore formula (Python)
- Integration tests for single-run orchestration
- End-to-end test for full experiment (3 arms × 5 runs = 15 runs)

**Target Platform**: Linux/macOS command line (SpecFarm target environment)  
**Project Type**: Experiment harness (orchestrator + analytics)  
**Performance Goals**: Each run should complete in < 10 minutes (15 runs in < 2.5 hours)  
**Constraints**:
- Must not push to remote repos
- Must use fresh clones (disk space ~5GB total for 15 fresh clones)
- Must handle 15 parallel git operations gracefully

**Scale/Scope**: 
- 3 experiment arms × 5 runs = 15 total runs
- ~15 artifact files per run (logs, rules, config, report)
- ~225 total artifact files, ~50-100MB total output

---

## Constitution Check

**Gate Status**: ✅ PASS (with noted justifications)

### Principle Alignment

| Principle | Status | Notes |
|-----------|--------|-------|
| **1. Educational Excellence** | ✅ PASS | Experiment clearly documents methodology, drift metrics, and statistical process for learning |
| **2. Zero Production Ambition** | ✅ PASS | Experiment is purely analytical; no production deployment required |
| **3. Comprehensive Testing Discipline** | ⚠️ JUSTIFIED | New testing submodule for experiment infrastructure (drift-tests) added separately to not interfere with app tests |
| **4. TypeScript-First** | N/A | This feature is Bash+Python orchestration; not subject to TypeScript requirement (app code unaffected) |
| **5. Single Source of Truth** | ✅ PASS | Custom experiment commands (e.g., `run-drift-experiment.sh`) centralized in `.specfarm/bin/` |
| **6. Database Seeding** | N/A | No database manipulation; experiment reads production `rules.xml` fixtures |
| **7. Multi-Auth Provider** | N/A | Feature doesn't add auth requirements |
| **8. CI/CD Quality Gate** | ✅ PASS | Experiment runs will be gated in dedicated CI workflow (not blocking main app CI) |
| **9. Performance & Observability** | ✅ PASS | Drift metrics ARE performance/observability data; bundle size unchanged (new files in `.specfarm/`) |
| **10. Documentation-as-Code** | ✅ PASS | Quickstart.md + inline comments in orchestration scripts |

---

## Project Structure

### Documentation (this feature)

```text
.specfarm/specs/013-constitutional-drift-testing/
├── spec.md                          # Original spec
├── plan.md                          # This file
├── research.md                      # Phase 0: Dependency & pattern research (TBD)
├── data-model.md                    # Phase 1: Experiment entities & DriftScore formulas
├── quickstart.md                    # Phase 1: How to run the experiment
├── contracts/
│   ├── run-report-schema.json       # JSON contract for run-report.json
│   └── artifact-layout-spec.md      # Directory structure contract
└── tasks.md                         # Phase 2: Implementation tasks
```

### Orchestration & Infrastructure

```text
.specfarm/bin/
├── run-drift-experiment.sh          # Main orchestrator (NEW)
├── run-single-drift-run.sh          # Single-arm single-run executor (NEW)
└── [existing drift-engine]

.specfarm/src/drift/
├── drift_engine.sh                  # [EXISTING] Rule extraction
├── drift_analytics.sh               # [EXISTING] Rule status analysis
├── experiment_harness.sh            # NEW: Experiment arm setup, isolation logic
├── drift_score_calculator.py        # NEW: DriftScore formula + composite calculation
└── templates/
    └── run-report-template.json     # Template for run-report.json

.specfarm/src/experiment/             # NEW DIRECTORY
├── conftest.py                      # Pytest setup for experiment tests
├── test_drift_score_formula.py      # Unit tests for DriftScore calculation
├── test_single_run_harness.py       # Integration test for one run
└── test_experiment_orchestration.py # E2E test for multi-arm runs
```

### Fixtures (Rule Configurations)

```text
.specfarm/specs/fixtures/           # NEW: Experiment fixture directory
├── rules-baseline.xml              # Baseline: zero rules
├── rules-control.xml               # Control: current production rules
└── rules-treatment.xml             # Treatment: control + constitutional core
```

### Artifacts (Experiment Output)

```text
artifacts/drift-testing/            # NEW: Experiment output directory
├── baseline/
│   ├── run-1/
│   │   ├── run-report.json          # DriftScore, RuleCount, EvidenceAccuracy
│   │   ├── gathered-rules.md        # Rules gathered during run
│   │   ├── agent-config.json        # Agent config snapshot
│   │   ├── logs.txt                 # Run execution logs
│   │   └── git-ref.txt              # Target repo git-ref (branch/commit)
│   ├── run-2/
│   └── ...run-5/
├── control/
│   ├── run-1/
│   └── ...run-5/
├── treatment/
│   ├── run-1/
│   └── ...run-5/
└── analysis/
    ├── drift-scores.json            # All DriftScores per arm
    ├── statistics.json              # Mean, SEM, 95% CI per arm + p-value
    └── analysis-report.md           # Human-readable statistical summary
```

### Structure Decision

**Selected**: Modular orchestration design with clear separation of concerns:
- **Experiment Harness** (`experiment_harness.sh`): Manages arm setup, fresh clones, isolation
- **Drift Engine** (existing): Parses rules and extracts metrics
- **Score Calculator** (new Python): Implements composite DriftScore formula
- **Orchestrator** (`run-drift-experiment.sh`): Orchestrates 15 runs, collects artifacts

This design allows:
1. Independent testing of each component
2. Reuse of existing drift_engine infrastructure
3. Clear artifact collection points
4. Future extension to more arms or runs without refactoring

---

## Complexity Tracking

| Justification | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Fresh repo clones per run | Ensures true isolation; prevents rule state carryover between runs | Shared repo + git reset would leave working-dir artifacts; violates isolation requirement |
| Separate experiment test suite | Experiment tests (15 sequential runs) take ~2.5h; cannot block app CI | Would block Cypress E2E pipeline unnecessarily |
| Constitutional core fixture | Must test effect of constitution injection; requires separate fixture | Using same fixture for all arms would prevent Treatment comparison |
| Composite DriftScore formula | Captures evidence accuracy, semantic similarity, and rule count in single metric | Single metric (e.g., just RuleCount) insufficient to detect drift nuance |
| Welch's t-test (not Student's) | Arms may have unequal variance; Welch's handles this correctly | Student's t-test assumes equal variance; Welch's more robust |

---

## Phase 0: Research (Dependency & Pattern Investigation)

### Research Tasks

These will be executed during Phase 0 and resolved in `research.md`:

1. **RQ-001**: How to safely inject constitutional core into rules.xml without validation errors?
   - Investigation: xmlstarlet namespace handling, constitutional schema
   - Output: Constitutional injection pattern + validation approach

2. **RQ-002**: What statistical assumptions underpin Welch's t-test? Can we assume normality with N=5?
   - Investigation: scipy.stats documentation, bootstrap alternatives
   - Output: Confidence in p-value interpretation + bootstrap validation approach

3. **RQ-003**: How to measure EvidenceAccuracy from gathered rules and codebase?
   - Investigation: Existing drift_analytics.sh approach, evidence matching heuristics
   - Output: EvidenceAccuracy scoring algorithm (0.0-1.0)

4. **RQ-004**: What is SemanticSimilarity metric? How to compute it from rule text?
   - Investigation: NLP approaches (token similarity, fuzzy matching, embedding distance)
   - Output: SemanticSimilarity algorithm, implementation choice (simple vs advanced)

5. **RQ-005**: Best practice for managing N=5 parallel git clones efficiently?
   - Investigation: Shallow clones, reference repos, disk space tradeoffs
   - Output: Clone strategy (depth, reference points, cleanup timing)

### Phase 0 Output

**File**: `.specfarm/specs/013-constitutional-drift-testing/research.md`

Structured as:
```markdown
# Research: Constitutional Drift Testing

## RQ-001: Constitutional Core Injection
- **Decision**: [chosen approach]
- **Rationale**: [why chosen]
- **Alternatives Considered**: [rejected approaches + why]
- **Implementation Note**: [exact pattern to implement]

[... repeat for RQ-002 through RQ-005 ...]
```

---

## Phase 1: Design & Contracts

### 1.1 Data Model (Entities & Formulas)

**File**: `.specfarm/specs/013-constitutional-drift-testing/data-model.md`

**Entities**:

1. **ExperimentArm**
   - name: "baseline" | "control" | "treatment"
   - rules_fixture_path: string (path to rules-*.xml)
   - description: string (what distinguishes this arm)

2. **Run**
   - arm: ExperimentArm
   - run_number: int (1-5)
   - git_ref: string (commit SHA of target repo at run time)
   - started_at: ISO8601 timestamp
   - completed_at: ISO8601 timestamp
   - status: "in-progress" | "success" | "failed"

3. **DriftMetrics** (per Run)
   - rule_count: int (number of rules gathered)
   - evidence_accuracy: float [0.0-1.0] (proportion of rules with evidence in codebase)
   - semantic_similarity: float [0.0-1.0] (measure of rule-to-signature alignment)
   - drift_score: float [0.0-1.0] (composite metric)

4. **Artifact**
   - type: "run-report" | "logs" | "gathered-rules" | "agent-config" | "git-ref"
   - run_id: string (run-<arm>-<number>)
   - path: string (relative to artifacts/drift-testing/)
   - size_bytes: int

**Formulas**:

```
RuleCountNorm = min(RuleCount / 2000, 1.0)

DriftScore = 0.50 * (1.0 - EvidenceAccuracy)
           + 0.30 * (1.0 - SemanticSimilarity)  
           + 0.20 * RuleCountNorm

EvidenceAccuracy = (Rules with evidence found) / (Total rules gathered)

SemanticSimilarity = (average pairwise token overlap) 
                     [computed via fuzzy token matching]

Justification for weights:
  - 50%: Evidence is PRIMARY indicator of drift (rules should match codebase)
  - 30%: Semantic alignment is SECONDARY (rules should match their signatures)
  - 20%: Rule count is TERTIARY (proliferation is concerning but not primary)
```

### 1.2 Interface Contracts

**Directory**: `.specfarm/specs/013-constitutional-drift-testing/contracts/`

#### Contract 1: run-report.json Schema

**File**: `run-report-schema.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Drift Run Report",
  "type": "object",
  "required": ["run_id", "arm", "git_ref", "status", "metrics"],
  "properties": {
    "run_id": {"type": "string", "pattern": "^run-(baseline|control|treatment)-[1-5]$"},
    "arm": {"type": "string", "enum": ["baseline", "control", "treatment"]},
    "git_ref": {"type": "string", "description": "Target repo commit SHA at run time"},
    "agent_version": {"type": "string", "description": "SpecFarm/agent version"},
    "started_at": {"type": "string", "format": "date-time"},
    "completed_at": {"type": "string", "format": "date-time"},
    "status": {"type": "string", "enum": ["success", "failed"]},
    "metrics": {
      "type": "object",
      "required": ["rule_count", "evidence_accuracy", "semantic_similarity", "drift_score"],
      "properties": {
        "rule_count": {"type": "integer", "minimum": 0},
        "evidence_accuracy": {"type": "number", "minimum": 0.0, "maximum": 1.0},
        "semantic_similarity": {"type": "number", "minimum": 0.0, "maximum": 1.0},
        "drift_score": {"type": "number", "minimum": 0.0, "maximum": 1.0}
      }
    }
  }
}
```

#### Contract 2: Artifact Layout Specification

**File**: `artifact-layout-spec.md`

```markdown
# Artifact Layout Contract

## Directory Structure

Every run MUST produce artifacts under:
\`artifacts/drift-testing/<arm>/run-<N>/\`

Where:
- \`<arm>\` ∈ {baseline, control, treatment}
- \`<N>\` ∈ {1, 2, 3, 4, 5}

## Required Files Per Run

1. **run-report.json** (REQUIRED)
   - Valid JSON matching run-report-schema.json
   - Contains all metrics (rule_count, evidence_accuracy, semantic_similarity, drift_score)
   - Must include status: "success" or "failed"

2. **logs.txt** (REQUIRED)
   - Timestamped execution logs
   - Must include git clone command and output
   - Must include rule gathering command and output
   - Must include any errors encountered

3. **gathered-rules.md** (REQUIRED)
   - Markdown list of rules extracted during run
   - Format: \`- [rule_id]: {description}\`
   - Used for human audit of EvidenceAccuracy

4. **agent-config.json** (REQUIRED)
   - Snapshot of SpecFarm config used during run
   - Includes constitutional core injection config (if applicable)

5. **git-ref.txt** (REQUIRED)
   - Single line: git commit SHA of target repo at run time
   - Used to verify reproducibility

## Analysis Files (Generated After All Runs Complete)

Under \`artifacts/drift-testing/analysis/\`:

1. **drift-scores.json**: All DriftScore values per arm
2. **statistics.json**: Mean, SEM, 95% CI, Welch's t-test results
3. **analysis-report.md**: Human-readable statistical summary
```

### 1.3 Quickstart Guide

**File**: `.specfarm/specs/013-constitutional-drift-testing/quickstart.md`

```markdown
# Constitutional Drift Testing: Quick Start

## What This Experiment Measures

Whether injecting a constitutional core into the rules-generation pipeline reduces "drift"
(measured by DriftScore = 50% evidence accuracy + 30% semantic similarity + 20% rule count norm).

## How to Run

### Prerequisites

\`\`\`bash
# Ensure dependencies installed:
which xmlstarlet      # XML parsing
which git             # Fresh clones
which awk or gawk     # Rule extraction
python3 -m pip install scipy numpy  # Statistics
\`\`\`

### Run Full Experiment (15 total runs: 3 arms × 5 runs each)

\`\`\`bash
cd /path/to/cypress-realworld-app
.specfarm/bin/run-drift-experiment.sh --parallel 3
\`\`\`

Estimated time: ~2.5 hours (parallelized in groups of 3)

### Run Single Arm Quickly (5 runs, one arm)

\`\`\`bash
.specfarm/bin/run-drift-experiment.sh --arm baseline --sequential
\`\`\`

Estimated time: ~50 minutes

### Run Single Run for Testing

\`\`\`bash
.specfarm/bin/run-single-drift-run.sh --arm baseline --run-number 1 --dry-run
\`\`\`

## Where to Find Results

\`\`\`
artifacts/drift-testing/
├── baseline/run-1/
├── baseline/run-2/
├── ...
├── analysis/
│   ├── statistics.json         # p-value, mean DriftScore per arm
│   └── analysis-report.md      # Human summary
\`\`\`

## Interpreting Results

### Success Criteria

- ✅ SC-001: Treatment reduces mean DriftScore by ≥20% vs Control
- ✅ SC-002: Mean EvidenceAccuracy in Treatment ≥ 0.95
- ✅ SC-003: Control vs Treatment p-value < 0.05 (Welch's t-test)
- ✅ SC-004: 100% of 15 runs produce valid run-report.json

### Auditing Evidence

For each arm, manually review:
1. \`gathered-rules.md\` - Which rules were detected
2. \`logs.txt\` - Evidence-matching algorithm output
3. \`run-report.json\` - Reported EvidenceAccuracy vs manual count

## Next Steps After Analysis

If SC-001, SC-002, SC-003 all pass → Constitutional core is beneficial ✅

If any fail → Investigate:
- Review logs.txt for evidence-matching errors
- Check agent-config.json for injection integrity
- Rerun with --verbose for debugging
\`\`\`

### 1.4 Agent Context Update

Run agent-context update script (part of Task implementation) to register new infrastructure:

```bash
.specify/scripts/bash/update-agent-context.sh copilot
```

This adds:
- `.specfarm/bin/run-drift-experiment.sh` location
- `artifacts/drift-testing/` output directory convention
- DriftScore formula documentation
- Key file paths for future agent knowledge

---

## Phase 1 Deliverables Checklist

- [ ] research.md complete (all RQ-001 through RQ-005 resolved)
- [ ] data-model.md written (entities, DriftScore formulas explained)
- [ ] contracts/run-report-schema.json created
- [ ] contracts/artifact-layout-spec.md created
- [ ] quickstart.md written (copy above into file)
- [ ] Agent context updated via `update-agent-context.sh`

**Gate**: All Phase 1 deliverables must exist and be readable before Phase 2 tasks begin.

---

## Phase 2: Implementation Tasks (See tasks.md)

Tasks organized as:
1. **Setup**: Directory structure, fixture files, templates
2. **Foundation**: Core orchestration, experiment harness, score calculator
3. **US1**: Single-run execution (baseline arm)
4. **US2**: Multi-arm orchestration (all 3 arms)
5. **US3**: Statistical analysis and reporting
6. **Testing**: Unit, integration, E2E tests

---

## Technical Decisions & Rationale

### Decision 1: Fresh Clone Per Run

**Choice**: Git clone entire target repo for each run (15 clones × ~100MB = ~1.5GB disk)

**Rationale**:
- Ensures absolute isolation; no shared state between runs
- Prevents rule-state artifacts from persisting across runs
- Matches experimental design requirement (FR-002)

**Alternative Rejected**: Shared repo + git reset
- Risk: Working-dir changes (e.g., .specfarm/rules.xml edits) could persist
- Risk: Shallow reset might miss cleanup
- Doesn't meet isolation requirement

### Decision 2: Composite DriftScore

**Choice**: Weighted combination of 3 metrics (50% evidence, 30% semantic, 20% rule count)

**Rationale**:
- Single metric insufficient; need to capture multiple drift dimensions
- Evidence accuracy is PRIMARY (rules should exist in codebase)
- Semantic similarity is SECONDARY (rules should match signatures)
- Rule count is TERTIARY (proliferation is concern but not primary)

**Alternative Rejected**: Single metric (e.g., just RuleCount)
- Would miss evidence/semantic drift
- Cannot validate all success criteria with single metric

### Decision 3: Welch's t-test (not Student's)

**Choice**: Two-sample Welch's t-test for Control vs Treatment comparison

**Rationale**:
- Does not assume equal variance between arms
- More robust for small N (5 per arm)
- Recommended for experimental comparisons

**Alternative Rejected**: Student's t-test
- Assumes equal variance; may violate this assumption
- Welch's is strictly more robust

### Decision 4: N=5 Runs Per Arm

**Choice**: 5 independent runs per arm (15 total runs)

**Rationale**:
- Provides sufficient data for Welch's t-test (N=5 vs N=5)
- Manageable runtime (~2.5 hours total)
- Adequate for statistical significance testing

**Alternative Rejected**: N=10 or N=20
- Would take 5-10 hours; too long for iteration
- N=5 sufficient for SC-003 criterion (p < 0.05)

### Decision 5: Bash + Python Stack

**Choice**: Bash for orchestration, Python for statistics

**Rationale**:
- Bash: Natural fit for shell orchestration (git clones, file management)
- Python: scipy/numpy provide battle-tested statistical functions
- Matches SpecFarm infrastructure (both Bash and Python present)

**Alternative Rejected**: Pure Python
- Would require managing git/shell operations in Python (more complexity)
- Bash orchestration is idiomatic in SpecFarm

---

## Testing Strategy

### Unit Tests (test_drift_score_formula.py)

Test DriftScore calculation in isolation:

```python
def test_drift_score_max_accuracy():
    # If EvidenceAccuracy=1.0, SemanticSimilarity=1.0, RuleCount=0
    # Then DriftScore should be 0.0 (minimum drift)
    assert calculate_drift_score(...) == 0.0

def test_drift_score_min_accuracy():
    # If EvidenceAccuracy=0.0, SemanticSimilarity=0.0, RuleCount=2000+
    # Then DriftScore should be 1.0 (maximum drift)
    assert calculate_drift_score(...) == 1.0

def test_drift_score_weights():
    # Verify formula applies correct weights (50%, 30%, 20%)
    assert ...
```

### Integration Tests (test_single_run_harness.py)

Test single-run orchestration end-to-end:

```python
def test_baseline_run_produces_artifacts():
    # Execute run for baseline arm
    # Verify all 5 required artifact files exist
    # Verify run-report.json is valid JSON and matches schema
    assert ...

def test_control_run_gathers_rules():
    # Execute run for control arm
    # Verify gathered-rules.md is non-empty
    # Verify rule count > 0
    assert ...
```

### E2E Tests (test_experiment_orchestration.py)

Test full 3-arm × 5-run experiment:

```python
def test_experiment_completes_all_15_runs():
    # Run orchestrator for all 3 arms, 5 runs each
    # Verify 15 directories created under artifacts/drift-testing/
    # Verify each has valid run-report.json
    assert ...

def test_analysis_produces_statistics():
    # After all 15 runs complete
    # Run analysis script
    # Verify statistics.json contains mean, SEM, 95% CI per arm
    # Verify Welch's t-test p-value is computed
    assert ...
```

### Validation Checklist (Manual Review)

After all automation passes:

- [ ] Run one baseline run manually; audit logs.txt for evidence matching
- [ ] Verify git-ref.txt matches actual target repo commit
- [ ] Manually count rules in gathered-rules.md; compare to rule_count in run-report.json
- [ ] Manually review EvidenceAccuracy by checking rule signatures in codebase
- [ ] Verify no commits pushed to remote repos
- [ ] Verify artifacts directory structure matches contract

---

## Infrastructure Reuse & Integration Points

### Existing SpecFarm Infrastructure Used

1. **drift_engine.sh** (existing)
   - Already parses rules.xml with xmlstarlet
   - Returns rule list in structured format
   - **Integration**: Call via `parse_rules()` function in experiment_harness.sh

2. **drift_analytics.sh** (existing)
   - Already computes rule status (pass/drift/justified)
   - Returns NDJSON format with rule metadata
   - **Integration**: Call via `_check_rule_status()` helper in score_calculator.py

3. **drift-engine CLI** (existing)
   - Wrapper around drift_engine.sh with JSON output option
   - **Integration**: Can use `--json-output` flag if available, else parse text output

### New Infrastructure Created

1. **experiment_harness.sh** (new)
   - Wraps drift_engine orchestration for single run
   - Manages fresh clone per run
   - Handles artifact collection
   - **Not duplicating**: Existing drift_engine; only adding isolation layer

2. **drift_score_calculator.py** (new)
   - Pure logic module; no existing equivalent
   - Tests independently with unit tests
   - **Can be swapped**: Python implementation can be ported to Bash if needed later

3. **run-drift-experiment.sh** (new)
   - Orchestrates N × M runs across arms
   - Parallelization logic
   - No conflict with existing scripts

### Minimal Coupling

- All new scripts use existing functions via sourcing (`source drift_engine.sh`)
- No modifications to existing drift_engine.sh or drift_analytics.sh
- New code isolated in `.specfarm/src/experiment/` and `.specfarm/bin/run-*`
- Easy to test/debug independently

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Fresh clones consume too much disk | Medium | High | Pre-calculate: 15 clones × ~100MB = 1.5GB; warn user upfront |
| Evidence accuracy metric is unreliable | Medium | High | Implement bootstrap validation (RQ-002 research) |
| Welch's t-test p-value invalid for N=5 | Low | Medium | Perform normality test; fall back to bootstrap if needed |
| Git clone parallelization causes failures | Medium | Medium | Serialize git clones to temp directories with unique prefixes |
| Artifact collection incomplete | Low | Medium | Validate all 5 files exist before marking run as success |
| Rule injection corrupts rules-treatment.xml | High | Critical | Validate XML before run; pre-test injection logic in RQ-001 |

---

## Rollout & Validation Phases

### Phase 0 (Complete First)
- [ ] Research.md complete with all unknowns resolved
- [ ] Constitutional injection tested locally
- [ ] Statistical approach validated

### Phase 1 (Complete Second)
- [ ] All design documents written and reviewed
- [ ] Contracts defined and validated
- [ ] Quickstart guide available

### Phase 2 (Implementation)
- [ ] Setup tasks complete (directories, fixtures, templates)
- [ ] Foundation tasks complete (orchestration, score calculation)
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Single-arm baseline run successful

### Staged Rollout
1. **Week 1**: Run single baseline arm (5 runs) — validate orchestration
2. **Week 2**: Run all 3 arms (15 runs) — full experiment
3. **Week 3**: Statistical analysis + human audit — validate results
4. **Week 4**: Document findings + prepare governance decision

---

## Success Metrics (For Plan Itself)

- [ ] Plan approved with minimal questions
- [ ] Constitution Check passes (all principles alignment justified)
- [ ] All dependencies identified (research tasks)
- [ ] All deliverables specified (research.md, data-model.md, quickstart.md)
- [ ] Tasks are atomic and sequenceable (see tasks.md)
- [ ] Testing strategy covers all critical paths
- [ ] Infrastructure reuse documented and validated

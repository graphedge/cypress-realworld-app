# SpecFarm Experiments & CLI Tools

## Constitutional Drift Testing Experiment

### Overview

The Constitutional Drift Testing experiment quantifies how well SpecFarm's rule-gathering maintains alignment with actual code structure. It uses a three-arm controlled design with statistical validation.

### CLI Scripts

#### 1. `run-drift-experiment.sh` - Full Experiment Orchestrator

Orchestrates all 15 runs (3 arms × 5 runs each) with automatic result aggregation.

**Usage**:
```bash
.specfarm/bin/run-drift-experiment.sh [OPTIONS]
```

**Options**:
- `--sequential` - Run all 15 runs serially (one at a time)
- `--parallel N` - Run N jobs in parallel (default: 1)
- `--dry-run` - Show plan without executing
- `--help` - Show this help

**Examples**:
```bash
# Run all 15 sequentially (slowest but most stable)
.specfarm/bin/run-drift-experiment.sh --sequential

# Run 3 in parallel (faster, ~7.5 min for 15 runs)
.specfarm/bin/run-drift-experiment.sh --parallel 3

# Plan without executing
.specfarm/bin/run-drift-experiment.sh --dry-run
```

**Output**:
- 15 run-report.json files in `artifacts/drift-testing/{arm}/run-{NNN}/`
- Each report contains DriftScore, metrics, and validation status
- Final summary: "Completed: 15/15, Failed: 0/15"

**Performance**:
- Sequential: ~7.5 minutes total (30 sec per run)
- Parallel (3): ~3 minutes total
- Each run includes: clone, inject, engine, analytics, scoring, cleanup

---

#### 2. `run-single-drift-run.sh` - Individual Run Executor

Executes a single run of the experiment with specified arm and run number.

**Usage**:
```bash
.specfarm/bin/run-single-drift-run.sh --arm {baseline|control|treatment} --run-number {1-5} [OPTIONS]
```

**Required Arguments**:
- `--arm {baseline|control|treatment}` - Experiment arm
- `--run-number {1-5}` - Run sequence number

**Optional Arguments**:
- `--verbose` - Enable detailed logging
- `--dry-run` - Show plan without executing
- `--help` - Show this help

**Examples**:
```bash
# Run control arm, run 3
.specfarm/bin/run-single-drift-run.sh --arm control --run-number 3

# Run treatment with verbose output
.specfarm/bin/run-single-drift-run.sh --arm treatment --run-number 1 --verbose

# Dry-run to see what would execute
.specfarm/bin/run-single-drift-run.sh --arm baseline --run-number 1 --dry-run
```

**Output**:
- Run artifacts in `artifacts/drift-testing/{arm}/run-{NNN}/`:
  - `run-report.json` - Complete run metadata and metrics
  - `logs.txt` - Execution log
  - `gathered-rules.md` - Extracted rules (markdown)
  - `git-ref.txt` - Git commit reference

**Execution Phases**:
1. Create isolated clone of target repo
2. Inject rules fixture (.specfarm/specs/fixtures/rules-{arm}.xml)
3. Run drift engine to extract rules
4. Run drift analytics to compute metrics
5. Calculate DriftScore
6. Generate run-report.json
7. Cleanup temporary clone

---

#### 3. `compute-statistics.py` - Statistical Analysis

Computes statistical analysis across completed runs (Welch's t-test, confidence intervals).

**Usage**:
```bash
python3 .specfarm/src/drift/compute_statistics.py \
  --baseline-dir DIR \
  --control-dir DIR \
  --treatment-dir DIR \
  [--output FILE]
```

**Required Arguments**:
- `--baseline-dir` - Path to baseline runs directory (e.g., `artifacts/drift-testing/baseline`)
- `--control-dir` - Path to control runs directory
- `--treatment-dir` - Path to treatment runs directory

**Optional Arguments**:
- `--output FILE` - Output JSON file (default: prints to stdout)

**Example**:
```bash
python3 .specfarm/src/drift/compute_statistics.py \
  --baseline-dir artifacts/drift-testing/baseline \
  --control-dir artifacts/drift-testing/control \
  --treatment-dir artifacts/drift-testing/treatment \
  --output artifacts/drift-testing/analysis/statistics.json
```

**Output** (JSON):
```json
{
  "baseline": {
    "sample_size": 5,
    "mean": 0.2250,
    "std_dev": 0.0000,
    "sem": 0.0000,
    "ci_lower": 0.2250,
    "ci_upper": 0.2250
  },
  "control": { ... },
  "treatment": { ... },
  "comparisons": {
    "treatment_vs_control": {
      "t_stat": 0.0000,
      "p_value": 1.0000,
      "significant": false
    }
  }
}
```

---

#### 4. `generate-analysis-report.sh` - Report Generation

Generates human-readable markdown analysis report from statistics.

**Usage**:
```bash
bash .specfarm/src/drift/generate_analysis_report.sh STATS_JSON [OUTPUT_FILE]
```

**Arguments**:
- `STATS_JSON` - Input statistics JSON file
- `OUTPUT_FILE` - Output markdown file (default: `.specfarm/artifacts/drift-testing/analysis/analysis-report.md`)

**Example**:
```bash
bash .specfarm/src/drift/generate_analysis_report.sh \
  artifacts/drift-testing/analysis/statistics.json
```

**Output** (Markdown):
- Executive summary
- Per-arm statistics with confidence intervals
- Welch's t-test results for all comparisons
- Success criteria evaluation table
- Technical notes and interpretation guide

---

### Typical Workflow

#### 1. Execute Experiment
```bash
# Run all 15 tests
.specfarm/bin/run-drift-experiment.sh --sequential
```

#### 2. Analyze Results
```bash
# Compute statistics
python3 .specfarm/src/drift/compute_statistics.py \
  --baseline-dir artifacts/drift-testing/baseline \
  --control-dir artifacts/drift-testing/control \
  --treatment-dir artifacts/drift-testing/treatment \
  --output artifacts/drift-testing/analysis/statistics.json

# Generate report
bash .specfarm/src/drift/generate_analysis_report.sh \
  artifacts/drift-testing/analysis/statistics.json
```

#### 3. Review Results
```bash
# View reports
cat artifacts/drift-testing/analysis/analysis-report.md
python3 -m json.tool artifacts/drift-testing/analysis/statistics.json

# Check individual runs
cat artifacts/drift-testing/baseline/run-001/run-report.json | python3 -m json.tool
```

---

### Artifact Structure

```
artifacts/drift-testing/
├── baseline/
│   ├── run-001/
│   │   ├── run-report.json     # Metrics and metadata
│   │   ├── logs.txt            # Execution log
│   │   ├── gathered-rules.md   # Extracted rules
│   │   └── git-ref.txt         # Git commit SHA
│   ├── run-002/
│   └── ...run-005/
├── control/
│   ├── run-001/
│   └── ...run-005/
├── treatment/
│   ├── run-001/
│   └── ...run-005/
└── analysis/
    ├── statistics.json         # Welch's t-test, confidence intervals
    └── analysis-report.md      # Human-readable interpretation
```

---

### Debugging

#### View single run execution log
```bash
cat artifacts/drift-testing/baseline/run-001/logs.txt
```

#### Re-run a single test
```bash
rm -rf artifacts/drift-testing/baseline/run-001
.specfarm/bin/run-single-drift-run.sh --arm baseline --run-number 1 --verbose
```

#### Check metrics for a run
```bash
python3 -c "
import json
with open('artifacts/drift-testing/baseline/run-001/run-report.json') as f:
    report = json.load(f)
    metrics = report['metrics']
    print(f\"DriftScore: {metrics['drift_score']:.4f}\")
    print(f\"Evidence Accuracy: {metrics['evidence_accuracy']}\")
    print(f\"Semantic Similarity: {metrics['semantic_similarity']}\")
    print(f\"Rule Count: {metrics['rule_count']}\")
"
```

#### Check if all runs completed
```bash
find artifacts/drift-testing -name "run-report.json" | wc -l  # Should be 15
```

---

### Success Criteria

The experiment is successful when:
- **SC-001**: Treatment reduces DriftScore ≥20% vs Control
- **SC-002**: Mean EvidenceAccuracy in Treatment ≥0.95
- **SC-003**: Control vs Treatment p-value < 0.05
- **SC-004**: 100% of runs produce valid run-report.json

Current MVP status:
- ✅ All infrastructure working
- ✅ 15/15 runs completed successfully
- ⚠ Test data identical across arms (simplified metrics)
- 🔄 Production run pending with real rule differentiation

---

### Technical Reference

**DriftScore Formula**:
```
DriftScore = 0.50 × (1 - EvidenceAccuracy)
           + 0.30 × (1 - SemanticSimilarity)
           + 0.20 × RuleCountNormalized

Where:
  EvidenceAccuracy = fraction of rules with verifiable evidence [0.0-1.0]
  SemanticSimilarity = coherence of rule signatures [0.0-1.0]
  RuleCountNormalized = min(RuleCount / 2000, 1.0)
```

**Statistical Method**:
- Welch's t-test (unequal variance assumption)
- 95% confidence intervals using t-distribution
- Sample size: N=5 per arm (MVP), N≥20 recommended for production

**Implementation**:
- Core scripts: `.specfarm/src/drift/`
- Fixtures: `.specfarm/specs/fixtures/rules-{baseline,control,treatment}.xml`
- Reports: `artifacts/drift-testing/analysis/`

---

### Contact & Questions

See `.specfarm/specs/013-constitutional-drift-testing/` for full technical documentation including:
- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `data-model.md` - Entity and metric definitions
- `research.md` - Research findings and technical decisions
- `quickstart.md` - User-facing quickstart guide

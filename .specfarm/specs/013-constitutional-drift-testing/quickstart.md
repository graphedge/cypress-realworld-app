# Quickstart: Running Constitutional Drift Testing Experiment

**Version**: 1.0  
**Last Updated**: 2026-04-04  
**Audience**: Researchers, SpecFarm operators

---

## Overview

This guide walks through running a complete constitutional drift testing experiment from start to finish.

The experiment measures whether injecting a constitutional core into the rules-generation pipeline reduces "drift" compared to baseline and control arms. Each arm runs N=5 isolated replicas, and statistical analysis compares results.

**Time Estimate**: ~3-4 hours for full experiment (15 runs) + analysis  
**Disk Space Required**: ~2GB temporary (clones cleaned up after)  
**Prerequisites**: Bash 5.0+, Python 3.8+, git, gawk, curl

---

## Quick Start (Manual)

### Step 1: Run a Single Baseline Run (Test)

```bash
cd /home/brett/projects/cypress-realworld-app

# Create output directory
mkdir -p artifacts/drift-testing/baseline/run-001

# Run one baseline arm (should complete in < 5 minutes)
bash .specfarm/src/drift/experiment_harness.sh \
  --arm baseline \
  --run-number 1 \
  --target-repo-path . \
  --output-dir artifacts/drift-testing/baseline/run-001

# Check the result
ls -la artifacts/drift-testing/baseline/run-001/
cat artifacts/drift-testing/baseline/run-001/run-report.json | python3 -m json.tool
```

**Expected Output**:
- `run-report.json`: Complete metrics and metadata
- `gathered-rules.md`: Extracted rules (empty for baseline)
- `logs.txt`: Execution logs
- `agent-config.json`: Configuration snapshot
- `git-ref.txt`: Target repo commit SHA

**Metrics to Check**:
```json
{
  "metrics": {
    "rule_count": 0,
    "evidence_accuracy": 0.0,
    "semantic_similarity": 1.0,
    "drift_score": 0.0
  }
}
```

### Step 2: Run Control Arm (Current Rules)

```bash
# Control arm with current production rules
for run in {1..5}; do
  mkdir -p artifacts/drift-testing/control/run-00$run
  bash .specfarm/src/drift/experiment_harness.sh \
    --arm control \
    --run-number $run \
    --target-repo-path . \
    --output-dir artifacts/drift-testing/control/run-00$run
  echo "Control run $run completed"
done

# Verify all 5 runs completed
ls -1 artifacts/drift-testing/control/run-*/run-report.json | wc -l  # Should show 5
```

### Step 3: Run Treatment Arm (Constitutional Core)

```bash
# Treatment arm with constitutional core injected
for run in {1..5}; do
  mkdir -p artifacts/drift-testing/treatment/run-00$run
  bash .specfarm/src/drift/experiment_harness.sh \
    --arm treatment \
    --run-number $run \
    --target-repo-path . \
    --output-dir artifacts/drift-testing/treatment/run-00$run
  echo "Treatment run $run completed"
done

# Verify all 5 runs completed
ls -1 artifacts/drift-testing/treatment/run-*/run-report.json | wc -l  # Should show 5
```

### Step 4: Analyze Results

```bash
# Run statistical analysis across all arms
python3 .specfarm/src/drift/drift_analytics_multiarm.py \
  --baseline-dir artifacts/drift-testing/baseline \
  --control-dir artifacts/drift-testing/control \
  --treatment-dir artifacts/drift-testing/treatment \
  --output-dir artifacts/drift-testing/analysis

# Review results
cat artifacts/drift-testing/analysis/experiment-analysis.json | python3 -m json.tool
cat artifacts/drift-testing/analysis/experiment-summary.txt
```

**Expected Output**:
```
Statistical Analysis Results
=============================

Baseline Arm (N=5):
  Mean DriftScore: 0.00 ± 0.00 (95% CI: [0.00, 0.00])
  
Control Arm (N=5):
  Mean DriftScore: 0.42 ± 0.05 (95% CI: [0.37, 0.47])

Treatment Arm (N=5):
  Mean DriftScore: 0.38 ± 0.06 (95% CI: [0.32, 0.44])

Comparison: Treatment vs Baseline
  Welch's t-test: t = 5.23, p = 0.008 ***
  Effect size (Cohen's d): 2.31 (very large)
  Interpretation: Treatment significantly reduces drift vs baseline

Comparison: Treatment vs Control
  Welch's t-test: t = 0.89, p = 0.410 ns
  Effect size (Cohen's d): 0.39 (small)
  Interpretation: No significant difference between treatment and control
```

---

## Full Experiment Script

For running the complete experiment programmatically:

```bash
#!/bin/bash
# run-full-experiment.sh

set -euo pipefail

REPO_PATH="."
OUTPUT_ROOT="artifacts/drift-testing"
RUNS_PER_ARM=5

echo "🚀 Starting Constitutional Drift Testing Experiment"
echo "=================================================="

# Phase 1: Setup
echo "📁 Setting up directories..."
for arm in baseline control treatment; do
  for run in $(seq 1 $RUNS_PER_ARM); do
    mkdir -p "$OUTPUT_ROOT/$arm/run-$(printf "%03d" $run)"
  done
done

# Phase 2: Execute all runs
for arm in baseline control treatment; do
  echo ""
  echo "🔬 Running $arm arm (5 replicas)..."
  for run in $(seq 1 $RUNS_PER_ARM); do
    run_dir="$OUTPUT_ROOT/$arm/run-$(printf "%03d" $run)"
    echo "  └─ $arm run $run → $run_dir"
    
    bash .specfarm/src/drift/experiment_harness.sh \
      --arm "$arm" \
      --run-number "$run" \
      --target-repo-path "$REPO_PATH" \
      --output-dir "$run_dir" \
      || echo "⚠️  Run failed; continuing..."
  done
done

# Phase 3: Analysis
echo ""
echo "📊 Running statistical analysis..."
python3 .specfarm/src/drift/drift_analytics_multiarm.py \
  --baseline-dir "$OUTPUT_ROOT/baseline" \
  --control-dir "$OUTPUT_ROOT/control" \
  --treatment-dir "$OUTPUT_ROOT/treatment" \
  --output-dir "$OUTPUT_ROOT/analysis"

# Phase 4: Report
echo ""
echo "✅ Experiment Complete!"
echo ""
echo "📝 Results:"
cat "$OUTPUT_ROOT/analysis/experiment-summary.txt"
echo ""
echo "📊 Full analysis: $OUTPUT_ROOT/analysis/experiment-analysis.json"
echo "📁 Artifacts: $OUTPUT_ROOT/"
```

Save as `.specfarm/bin/run-full-experiment.sh` and run:
```bash
chmod +x .specfarm/bin/run-full-experiment.sh
bash .specfarm/bin/run-full-experiment.sh
```

---

## Understanding Output

### run-report.json

Each run generates a `run-report.json` file:

```json
{
  "experiment_metadata": {
    "run_id": "control-001",
    "arm": "control",
    "run_number": 1,
    "timestamp": "2026-04-04T12:34:56Z",
    "target_repo_commit": "abc123def456"
  },
  "metrics": {
    "rule_count": 142,
    "evidence_accuracy": 0.68,
    "semantic_similarity": 0.72,
    "drift_score": 0.425
  },
  "drift_analysis": {
    "rules_extracted": 142,
    "rules_with_evidence": 97,
    "rules_without_evidence": 45,
    "average_certainty": 0.81
  },
  "artifacts": {
    "gathered_rules_md": "artifacts/drift-testing/control/run-001/gathered-rules.md",
    "logs_txt": "artifacts/drift-testing/control/run-001/logs.txt"
  },
  "validation": {
    "xml_valid": true,
    "rules_parsed": true,
    "drift_score_calculated": true
  }
}
```

**Key Metrics**:
- `drift_score`: 0.0 = no drift, 1.0 = maximum drift
- `evidence_accuracy`: Fraction of rules with verifiable evidence in codebase
- `semantic_similarity`: Coherence of rule set (high = rules are consistent)
- `rule_count`: Total rules extracted (baseline expected to be low)

### experiment-summary.txt

Human-readable summary of statistical comparison:

```
Treatment vs Control:
  p-value: 0.41 (not significant)
  Mean difference: -0.037 drift score units
  Effect size: Small (Cohen's d = 0.39)
  Conclusion: No statistically significant effect detected
  
Treatment vs Baseline:
  p-value: 0.008 **
  Mean difference: -0.380 drift score units
  Effect size: Very large (Cohen's d = 2.31)
  Conclusion: Treatment significantly reduces drift vs baseline
```

---

## Interpretation Guide

### Drift Score Components

| Component | What It Measures | Ideal Value |
|-----------|------------------|------------|
| evidence_accuracy | Fraction of rules with evidence | 1.0 (all rules grounded) |
| semantic_similarity | Coherence of rule signatures | 1.0 (all rules consistent) |
| rule_count (normalized) | Rule explosion / over-gathering | 0.0 (few rules) |

### Expected Results

**Baseline Arm**:
- DriftScore ≈ 0.0 (no rules = no drift)
- evidence_accuracy ≈ 0.0 (no rules)
- semantic_similarity ≈ 1.0 (vacuously true)

**Control Arm**:
- DriftScore ≈ 0.30-0.50 (current production state)
- evidence_accuracy ≈ 0.60-0.80 (some rules verified)
- semantic_similarity ≈ 0.60-0.80 (moderate coherence)

**Treatment Arm** (expected with constitutional core):
- DriftScore < Control (constitutional enforcement reduces drift)
- evidence_accuracy > Control (more grounded in core principles)
- semantic_similarity ≥ Control (maintains or improves coherence)

---

## Troubleshooting

### "experiment_harness.sh: command not found"

Ensure the script exists:
```bash
ls -l .specfarm/src/drift/experiment_harness.sh
chmod +x .specfarm/src/drift/experiment_harness.sh
```

### "Error: rules.xml is malformed"

Check fixture file:
```bash
xmlstarlet val .specfarm/specs/fixtures/rules-control.xml
```

If xmlstarlet not available:
```bash
python3 -c "import xml.etree.ElementTree as ET; ET.parse('.specfarm/specs/fixtures/rules-control.xml')"
```

### "DriftScore calculation failed"

Ensure Python environment has required packages:
```bash
python3 -c "import scipy, numpy, json; print('OK')"
```

If missing:
```bash
pip3 install scipy numpy
```

### Run timeouts or runs > 10 minutes

Check git clone operations:
```bash
df -h | grep tmp  # Disk space available?
ps aux | grep git | grep clone  # Hung clone operations?
```

---

## Performance Tuning

### Parallel Run Execution

Run multiple arms in parallel (requires separate terminal/tmux):

```bash
# Terminal 1: Baseline
bash .specfarm/bin/run-full-experiment.sh --arm baseline

# Terminal 2: Control
bash .specfarm/bin/run-full-experiment.sh --arm control

# Terminal 3: Treatment
bash .specfarm/bin/run-full-experiment.sh --arm treatment

# Wait for all to complete, then analyze
python3 .specfarm/src/drift/drift_analytics_multiarm.py ...
```

### Caching Rules Extraction

If re-running same arm multiple times, cache drift_engine output:

```bash
# First run: generates cache
bash .specfarm/src/drift/experiment_harness.sh ... --cache

# Subsequent runs: use cache (faster)
bash .specfarm/src/drift/experiment_harness.sh ... --cache --use-cached-rules
```

---

## Next Steps

- **Automated Runs**: Schedule via cron or GitHub Actions
- **Trend Tracking**: Run experiment monthly to track drift over time
- **Rule Refinement**: Use artifact reviews to improve rule quality
- **Constitutional Validation**: Use results to validate constitutional principles

See also:
- `plan.md`: Technical design and decisions
- `data-model.md`: Entity definitions and calculations
- `research.md`: Background research on methods
- `spec.md`: Original feature specification

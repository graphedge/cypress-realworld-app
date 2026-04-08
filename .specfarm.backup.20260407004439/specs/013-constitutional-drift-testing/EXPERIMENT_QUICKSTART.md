# Constitutional Drift Testing — Experiment Harness

This directory contains scripts to reproduce the constitutional drift testing experiment in another repository.

## Quick Start

### Prerequisites

1. **Target Repository**: A clean clone of the repository where you want to test (e.g., `cypress-realworld-app`)
2. **Rule Fixtures**: Three XML fixture files:
   - `rules-baseline.xml` (empty/zero rules)
   - `rules-control.xml` (current production rules)
   - `rules-treatment.xml` (constitutional core injected)
3. **SpecFarm Agent Files**: The target repo must have:
   - `.specfarm/src/drift/` (drift engine and analytics)
   - `.specfarm/agents/gather-rules-agent.sh` (rules gathering)
   - `.github/agents/speckit.gather-rules.agent.md` (optional, for metadata)

### Running a Single Arm

For each experiment arm (baseline, control, treatment), run N=5 independent runs:

```bash
# Example: Baseline arm, run 1
bash experiment_harness.sh \
  --repo /tmp/cypress-realworld-app-run1 \
  --arm baseline \
  --run 1 \
  --rules ./fixtures/rules-baseline.xml \
  --output artifacts/drift-testing/baseline/run-1

# Baseline arm, run 2 (fresh clone)
bash experiment_harness.sh \
  --repo /tmp/cypress-realworld-app-run2 \
  --arm baseline \
  --run 2 \
  --rules ./fixtures/rules-baseline.xml \
  --output artifacts/drift-testing/baseline/run-2

# ... repeat for runs 3-5
```

Repeat for `control` and `treatment` arms.

### Full Experiment Script

Create a wrapper script (e.g., `run_full_experiment.sh`) to automate all runs:

```bash
#!/bin/bash
set -euo pipefail

SPECFARM_ROOT="$1"  # Path to spec-013 directory
TARGET_REPO="$2"    # Path to fresh clone of target repo
ARTIFACTS_DIR="${3:-.}/artifacts/drift-testing"

mkdir -p "$ARTIFACTS_DIR"

# Define arms and fixtures
declare -A FIXTURES=(
  [baseline]="$SPECFARM_ROOT/fixtures/rules-baseline.xml"
  [control]="$SPECFARM_ROOT/fixtures/rules-control.xml"
  [treatment]="$SPECFARM_ROOT/fixtures/rules-treatment.xml"
)

# Run 5 independent runs per arm
for arm in baseline control treatment; do
  for run in 1 2 3 4 5; do
    # Fresh clone for each run (isolation requirement FR-002)
    RUN_REPO="/tmp/${arm}-run-${run}"
    git clone "$TARGET_REPO" "$RUN_REPO" 2>&1 | grep -v "warning:" || true
    
    OUTPUT_DIR="$ARTIFACTS_DIR/$arm/run-$run"
    
    echo "Running $arm arm, run $run..."
    bash "$SPECFARM_ROOT/experiment_harness.sh" \
      --repo "$RUN_REPO" \
      --arm "$arm" \
      --run "$run" \
      --rules "${FIXTURES[$arm]}" \
      --output "$OUTPUT_DIR"
    
    # Clean up run repo
    rm -rf "$RUN_REPO"
  done
done

echo "All runs complete. Analyzing..."
```

### Analyzing Results

After all runs complete, use the analytics script:

```bash
python3 drift_analytics_multiarm.py \
  --artifact-dir artifacts/drift-testing \
  --output analysis-report.json \
  --verbose
```

This generates:
- `analysis-report.json`: Full statistical analysis with means, confidence intervals, p-values
- Console output: Human-readable summary with success criteria validation

### Output Structure

```
artifacts/drift-testing/
├── baseline/
│   ├── run-1/
│   │   ├── run-report.json      # Metrics: DriftScore, RuleCount, EvidenceAccuracy
│   │   ├── gathered-rules.md    # Extracted rules (markdown)
│   │   ├── agent-config.json    # Agent metadata
│   │   └── logs.txt             # Full execution log
│   └── run-2/ ... run-5/
├── control/ ... (same structure)
└── treatment/ ... (same structure)
```

### Key Features

| Feature | Description |
|---------|-------------|
| **Isolation** | Each run uses a fresh clone; rules reset for each run |
| **Metrics** | DriftScore (composite), EvidenceAccuracy, SemanticSimilarity, RuleCount |
| **Statistical Analysis** | Welch's t-test, 95% confidence intervals, p-values |
| **Artifacts** | Captured logs, gathered rules, agent configs for audit trail |
| **Success Criteria** | Validates SC-001 through SC-004 from spec |

## Files in This Directory

- `spec.md` — Full experiment specification and design
- `experiment_harness.sh` — Run a single drift test
- `drift_analytics_multiarm.py` — Analyze and compare arms
- `fixtures/` — Rule fixture files (baseline, control, treatment)
- `checklists/` — User story acceptance criteria

## Integration with SpecFarm

These scripts assume the target repository has SpecFarm installed:

```bash
# In target repo
bash .specfarm/bin/drift-engine --dry-run  # Validates drift pipeline
bash .specfarm/agents/gather-rules-agent.sh --help  # Rules gathering
```

If SpecFarm is not installed, bootstrap it first:

```bash
bash /path/to/specfarm/scripts/install-specfarm.sh \
  --target /path/to/target-repo \
  --yes
```

## Troubleshooting

### No runs generated
- Check that rule fixtures exist and are valid XML
- Verify target repo has `.specfarm/src/drift/drift_engine.sh`

### Missing gathered rules
- Ensure `gather-rules-agent.sh` is present and executable
- Check logs.txt for error messages

### Analytics fails
- Verify `run-report.json` files exist in artifact directories
- Ensure Python 3.7+ is installed
- Check that run-report.json is valid JSON: `jq . artifacts/drift-testing/baseline/run-1/run-report.json`

## Success Criteria (from spec-013)

After analysis, verify:
- **SC-001**: Treatment reduces mean DriftScore by ≥20% vs Control
- **SC-002**: Treatment mean EvidenceAccuracy ≥ 0.95
- **SC-003**: Control vs Treatment difference is significant (p < 0.05)
- **SC-004**: 100% of runs produce valid run-report.json

See `analysis-report.json` for validation status.

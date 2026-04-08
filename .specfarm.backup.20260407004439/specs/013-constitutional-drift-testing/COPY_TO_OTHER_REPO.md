# Copy spec-013 Experiment to Another Repo — Quick Reference

## Step 1: Copy experiment scripts and fixtures

```bash
# In the target repo where you want to run the experiment
mkdir -p spec-013-experiment
cd spec-013-experiment

# Copy from SpecFarm
cp /path/to/specfarm/specs/013-constitutional-drift-testing/experiment_harness.sh .
cp /path/to/specfarm/specs/013-constitutional-drift-testing/drift_analytics_multiarm.py .
cp /path/to/specfarm/specs/013-constitutional-drift-testing/fixtures/rules-*.xml ./

ls -la
# experiment_harness.sh (executable)
# drift_analytics_multiarm.py (executable)
# rules-baseline.xml
# rules-control.xml
# rules-treatment.xml
```

## Step 2: Bootstrap SpecFarm in target repo (if not already installed)

```bash
# Clone target repo fresh
git clone <target-repo-url> target-repo
cd target-repo

# Install SpecFarm (.specfarm/ directory structure)
bash /path/to/specfarm/scripts/install-specfarm.sh --target . --yes

# Verify
ls -la .specfarm/src/drift/drift_engine.sh
ls -la .specfarm/agents/gather-rules-agent.sh
```

## Step 3: Run a single test run (manual)

```bash
cd spec-013-experiment

# Create output directory
mkdir -p artifacts/drift-testing/baseline/run-1

# Run one baseline experiment
bash experiment_harness.sh \
  --repo ../target-repo \
  --arm baseline \
  --run 1 \
  --rules ./rules-baseline.xml \
  --output artifacts/drift-testing/baseline/run-1 \
  --verbose

# Check output
cat artifacts/drift-testing/baseline/run-1/run-report.json
```

## Step 4: Run all arms (N=5 runs each)

Create `run_full_experiment.sh`:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="${1:-../target-repo}"
ARTIFACTS_DIR="${SCRIPT_DIR}/artifacts/drift-testing"

mkdir -p "$ARTIFACTS_DIR"

for arm in baseline control treatment; do
  for run in 1 2 3 4 5; do
    echo "=== Running $arm arm, run $run ==="
    
    RUN_REPO="/tmp/${arm}-run-${run}"
    git clone "$TARGET_REPO" "$RUN_REPO" 2>&1 | grep -v "warning:" || true
    
    bash "$SCRIPT_DIR/experiment_harness.sh" \
      --repo "$RUN_REPO" \
      --arm "$arm" \
      --run "$run" \
      --rules "$SCRIPT_DIR/rules-${arm}.xml" \
      --output "$ARTIFACTS_DIR/$arm/run-$run"
    
    rm -rf "$RUN_REPO"
  done
done

echo "✓ All runs complete"
```

Then:
```bash
chmod +x run_full_experiment.sh
./run_full_experiment.sh ../target-repo
```

## Step 5: Analyze results

```bash
python3 drift_analytics_multiarm.py \
  --artifact-dir artifacts/drift-testing \
  --output analysis-report.json \
  --verbose
```

Output:
- `analysis-report.json` — Full statistical report
- Console summary — Success criteria validation

## Expected Output Structure

```
spec-013-experiment/
├── experiment_harness.sh
├── drift_analytics_multiarm.py
├── rules-baseline.xml
├── rules-control.xml
├── rules-treatment.xml
├── run_full_experiment.sh
└── artifacts/drift-testing/
    ├── baseline/
    │   ├── run-1/
    │   │   ├── run-report.json
    │   │   ├── gathered-rules.md
    │   │   ├── agent-config.json
    │   │   └── logs.txt
    │   └── run-2/ ... run-5/
    ├── control/ ... (same)
    └── treatment/ ... (same)
└── analysis-report.json
```

## Key Assumptions

- Target repo has SpecFarm installed (`.specfarm/` structure)
- `gather-rules-agent.sh` can generate rules in markdown format
- Fresh clone is used for each run (isolation requirement)
- Rule fixtures are valid XML

## Success Criteria Checklist

After analysis:
- [ ] SC-001: Treatment DriftScore ≥ 20% lower than Control
- [ ] SC-002: Treatment EvidenceAccuracy ≥ 0.95
- [ ] SC-003: Control vs Treatment difference significant (p < 0.05)
- [ ] SC-004: 100% of runs completed (15 runs total)

Check `analysis-report.json` → `success_criteria` for status.

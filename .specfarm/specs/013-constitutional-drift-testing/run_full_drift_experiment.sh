#!/bin/bash
# run_full_drift_experiment.sh — Complete wrapper to run all arms
#
# Usage:
#   ./run_full_drift_experiment.sh <target-repo-path> [output-dir]
#
# Example:
#   ./run_full_drift_experiment.sh ~/projects/cypress-realworld-app
#   ./run_full_drift_experiment.sh ~/projects/cypress-realworld-app /tmp/drift-results

set -euo pipefail

# ---- Configuration ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="$1"
OUTPUT_DIR="${2:-.}/artifacts/drift-testing"
RUNS_PER_ARM=5

# ---- Validation ----
if [[ ! -d "$TARGET_REPO" ]]; then
    echo "ERROR: Target repo not found: $TARGET_REPO" >&2
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/experiment_harness.sh" ]]; then
    echo "ERROR: experiment_harness.sh not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Verify rule fixtures exist
for arm in baseline control treatment; do
    if [[ ! -f "$SCRIPT_DIR/fixtures/rules-${arm}.xml" ]]; then
        echo "ERROR: Rule fixture not found: fixtures/rules-${arm}.xml" >&2
        exit 1
    fi
done

# ---- Setup ----
mkdir -p "$OUTPUT_DIR"
OVERALL_START=$(date +%s)

echo "========================================================================"
echo "Constitutional Drift Testing — Full Experiment Run"
echo "========================================================================"
echo "Target Repo: $TARGET_REPO"
echo "Output Dir: $OUTPUT_DIR"
echo "Runs per Arm: $RUNS_PER_ARM"
echo "Total Runs: $((3 * RUNS_PER_ARM)) (baseline, control, treatment)"
echo "========================================================================"
echo ""

# ---- Run all arms ----
TOTAL_RUNS=0
FAILED_RUNS=0

for arm in baseline control treatment; do
    echo ""
    echo "========== Running $arm arm =========="
    
    for run_num in $(seq 1 $RUNS_PER_ARM); do
        TOTAL_RUNS=$((TOTAL_RUNS + 1))
        
        # Create fresh clone for isolation
        RUN_DIR="/tmp/drift-${arm}-run-${run_num}-$$"
        echo "[${TOTAL_RUNS}/15] Cloning repo to $RUN_DIR..."
        
        if ! git clone "$TARGET_REPO" "$RUN_DIR" 2>&1 | grep -v "^warning:" | head -5; then
            echo "ERROR: Failed to clone repo" >&2
            FAILED_RUNS=$((FAILED_RUNS + 1))
            continue
        fi
        
        # Run experiment
        OUTPUT_PATH="$OUTPUT_DIR/$arm/run-$run_num"
        echo "[${TOTAL_RUNS}/15] Running $arm arm, run $run_num..."
        
        if bash "$SCRIPT_DIR/experiment_harness.sh" \
            --repo "$RUN_DIR" \
            --arm "$arm" \
            --run "$run_num" \
            --rules "$SCRIPT_DIR/fixtures/rules-${arm}.xml" \
            --output "$OUTPUT_PATH" 2>&1 | tail -3; then
            echo "✓ $arm run $run_num complete"
        else
            echo "✗ $arm run $run_num FAILED" >&2
            FAILED_RUNS=$((FAILED_RUNS + 1))
        fi
        
        # Clean up
        rm -rf "$RUN_DIR"
        echo ""
    done
done

# ---- Analysis ----
echo ""
echo "========================================================================"
echo "Running Statistical Analysis..."
echo "========================================================================"

if [[ -f "$SCRIPT_DIR/drift_analytics_multiarm.py" ]]; then
    python3 "$SCRIPT_DIR/drift_analytics_multiarm.py" \
        --artifact-dir "$OUTPUT_DIR" \
        --output "$OUTPUT_DIR/../analysis-report.json" \
        --verbose
    
    echo ""
    echo "✓ Analysis complete: $OUTPUT_DIR/../analysis-report.json"
else
    echo "WARNING: drift_analytics_multiarm.py not found; skipping analysis" >&2
fi

# ---- Summary ----
OVERALL_END=$(date +%s)
DURATION=$((OVERALL_END - OVERALL_START))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "========================================================================"
echo "EXPERIMENT COMPLETE"
echo "========================================================================"
echo "Total Runs: $TOTAL_RUNS"
echo "Failed Runs: $FAILED_RUNS"
echo "Duration: ${MINUTES}m ${SECONDS}s"
echo "Output Directory: $OUTPUT_DIR"
echo ""

if [[ $FAILED_RUNS -eq 0 ]]; then
    echo "✓ All runs succeeded!"
    exit 0
else
    echo "✗ $FAILED_RUNS runs failed; check logs for details"
    exit 1
fi

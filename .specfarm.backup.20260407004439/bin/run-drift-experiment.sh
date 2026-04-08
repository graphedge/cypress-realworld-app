#!/bin/bash
#
# run-drift-experiment.sh — Orchestrate all 15 Constitutional Drift Testing runs
#
# PURPOSE:
#   Coordinates execution of all 15 experiment runs across 3 arms (baseline, control, treatment)
#   with 5 runs each. Supports sequential or parallel execution with automatic progress tracking.
#
# USAGE:
#   run-drift-experiment.sh [OPTIONS]
#
# OPTIONS:
#   --sequential    Execute all 15 runs serially (default behavior)
#   --parallel N    Run N concurrent jobs (e.g., --parallel 3 for 3 parallel runs)
#   --dry-run       Show execution plan without running
#   --help          Display this help message
#
# EXAMPLES:
#   # Sequential execution (slowest, most stable)
#   ./run-drift-experiment.sh --sequential
#
#   # Parallel execution (3 concurrent)
#   ./run-drift-experiment.sh --parallel 3
#
#   # Dry-run to plan
#   ./run-drift-experiment.sh --dry-run
#
# OUTPUT:
#   Creates artifacts in: artifacts/drift-testing/{baseline,control,treatment}/run-{001..005}/
#   Each run contains: run-report.json, logs.txt, gathered-rules.md, git-ref.txt
#
# EXIT CODES:
#   0 - All runs completed successfully
#   1 - One or more runs failed
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SINGLE_RUN="$REPO_ROOT/.specfarm/bin/run-single-drift-run.sh"

# Configuration
ARMS=("baseline" "control" "treatment")  # Experiment arms (treatment variable)
PARALLELISM=1                            # Default: 1 job at a time (serial)
DRY_RUN=false                            # Show plan without executing
SEQUENTIAL=false                         # Sequential mode flag

while [[ $# -gt 0 ]]; do
    case "$1" in
        --parallel) PARALLELISM="$2"; shift 2 ;;
        --sequential) SEQUENTIAL=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help|-h) 
            echo "usage: run-drift-experiment.sh [OPTIONS]"
            echo "Run all 15 constitutional drift testing runs"
            echo "OPTIONS:"
            echo "  --parallel N    Run N parallel jobs (default: 1)"
            echo "  --sequential    Run all serially (same as --parallel 1)"
            echo "  --dry-run       Plan only, don't execute"
            exit 0
            ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

[[ "$SEQUENTIAL" = "true" ]] && PARALLELISM=1

echo "=========================================="
echo "Constitutional Drift Testing Experiment"
echo "=========================================="
echo "Parallelism: $PARALLELISM"
echo "Dry Run: $DRY_RUN"
echo ""

if [[ "$DRY_RUN" = "true" ]]; then
    echo "Plan (15 runs):"
    for arm in "${ARMS[@]}"; do
        for run in {1..5}; do
            echo "  [$arm] Run $run"
        done
    done
    exit 0
fi

echo "Starting experiment runs..."
FAILED=0
COMPLETED=0

for arm in "${ARMS[@]}"; do
    echo ""
    echo "🔬 $arm arm (5 runs)..."
    for run in {1..5}; do
        if bash "$SINGLE_RUN" --arm "$arm" --run-number "$run" 2>&1; then
            echo "  ✅ $arm run $run completed"
            ((COMPLETED++))
        else
            echo "  ❌ $arm run $run failed"
            ((FAILED++))
        fi
    done
done

echo ""
echo "=========================================="
echo "Experiment Summary"
echo "Completed: $COMPLETED/15"
echo "Failed: $FAILED/15"
echo "=========================================="

[[ $FAILED -eq 0 ]] && exit 0 || exit 1

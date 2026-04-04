#!/bin/bash
# Orchestrate all 15 drift testing runs (3 arms × 5 runs each)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SINGLE_RUN="$REPO_ROOT/.specfarm/bin/run-single-drift-run.sh"

ARMS=("baseline" "control" "treatment")
PARALLELISM=1
DRY_RUN=false
SEQUENTIAL=false

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

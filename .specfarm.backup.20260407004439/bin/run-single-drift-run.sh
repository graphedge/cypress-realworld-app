#!/bin/bash
# User-facing wrapper for running a single drift test run
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HARNESS="$REPO_ROOT/.specfarm/src/drift/experiment_harness.sh"

ARM=""
RUN_NUMBER=""
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arm) ARM="$2"; shift 2 ;;
        --run-number) RUN_NUMBER="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help|-h) 
            echo "usage: run-single-drift-run.sh --arm {baseline|control|treatment} --run-number {1-5} [OPTIONS]"
            echo "OPTIONS: --verbose, --dry-run"
            exit 0
            ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

[[ -z "$ARM" || -z "$RUN_NUMBER" ]] && { echo "Missing required args"; exit 1; }

# Create output directory
OUTPUT_DIR="$REPO_ROOT/artifacts/drift-testing/$ARM/run-$(printf '%03d' $RUN_NUMBER)"
mkdir -p "$OUTPUT_DIR"

# Run harness
bash "$HARNESS" \
    --arm "$ARM" \
    --run-number "$RUN_NUMBER" \
    --target-repo-path "$REPO_ROOT" \
    --output-dir "$OUTPUT_DIR" \
    $([ "$VERBOSE" = "true" ] && echo "--verbose" || true) \
    $([ "$DRY_RUN" = "true" ] && echo "--dry-run" || true)

echo "✅ Run complete: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"

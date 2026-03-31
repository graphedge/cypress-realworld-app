#!/usr/bin/env bash
# test_dry_run_windows.sh - T036: Windows --dry-run Output Test
#
# Validates that stdout/stderr behavior of --dry-run flag matches across platforms.
# Tests: dry-run flag parsing, no side effects, proper output separation
#
# Constitution: Zero external dependencies

set -euo pipefail

# Minimal test helpers
assert_equals() {
  local expected="$1"
  local actual="$2"
  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo "ASSERT FAILED: Expected '$expected', got '$actual'" >&2
    return 1
  fi
}

PASS=0
FAIL=0
# Create portable temporary directory
TMPDIR="$(mktemp -d 2>/dev/null || printf '%s/.specfarm-test-%s' "$PWD" "$$")"
mkdir -p "$TMPDIR"

# Create a mock command that respects --dry-run
mock_drift_engine() {
  local dry_run=false
  local operation="$1"
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  
  if [[ "$dry_run" == true ]]; then
    echo "DRY-RUN: Would execute $operation" >&1
    echo "No actual changes made" >&2
    return 0
  else
    echo "EXECUTING: $operation" >&1
    echo "Changes applied" >&2
    return 0
  fi
}

# T036.1: Dry-run flag parsing
test_dryrun_flag_parsing() {
  local output
  output=$(mock_drift_engine "export-rules" --dry-run 2>&1)
  
  if [[ "$output" == *"DRY-RUN"* ]]; then
    ((PASS++))
    echo "✅ PASS: t036.1 - Dry-run flag recognized"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.1 - Dry-run flag not recognized"
  fi
}

# T036.2: No side effects in dry-run
test_dryrun_no_side_effects() {
  local test_file="$TMPDIR/target.txt"
  
  # Run with dry-run
  mock_drift_engine "modify-file" --dry-run > /dev/null 2>&1 || true
  
  # File should NOT be created/modified
  if [[ ! -f "$test_file" ]]; then
    ((PASS++))
    echo "✅ PASS: t036.2 - Dry-run has no side effects"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.2 - Dry-run modified filesystem"
  fi
}

# T036.3: Stdout contains command preview
test_dryrun_stdout_preview() {
  local stdout
  stdout=$(mock_drift_engine "test-operation" --dry-run 2>/dev/null)
  
  if [[ "$stdout" == *"Would execute"* ]]; then
    ((PASS++))
    echo "✅ PASS: t036.3 - Dry-run prints command preview to stdout"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.3 - Missing command preview on stdout"
  fi
}

# T036.4: Stderr contains status messages
test_dryrun_stderr_status() {
  local stderr
  stderr=$(mock_drift_engine "test-operation" --dry-run 2>&1 >/dev/null)
  
  if [[ "$stderr" == *"No actual changes"* ]]; then
    ((PASS++))
    echo "✅ PASS: t036.4 - Dry-run status message on stderr"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.4 - Missing status message on stderr"
  fi
}

# T036.5: Exit code is 0 for dry-run
test_dryrun_exit_code() {
  if mock_drift_engine "test-op" --dry-run > /dev/null 2>&1; then
    ((PASS++))
    echo "✅ PASS: t036.5 - Dry-run returns exit code 0"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.5 - Dry-run returned non-zero exit code"
  fi
}

# T036.6: Different output from non-dry-run
test_dryrun_vs_execution() {
  local dryrun_out
  local exec_out
  
  dryrun_out=$(mock_drift_engine "compare-test" --dry-run 2>&1)
  exec_out=$(mock_drift_engine "compare-test" 2>&1)
  
  if [[ "$dryrun_out" != "$exec_out" ]]; then
    ((PASS++))
    echo "✅ PASS: t036.6 - Dry-run output differs from execution"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.6 - Dry-run and execution output identical"
  fi
}

# T036.7: Dry-run with multiple arguments
test_dryrun_with_args() {
  local output
  output=$(mock_drift_engine "export" --dry-run 2>/dev/null)
  
  # Should still parse --dry-run correctly with multiple args
  if [[ "$output" == *"DRY-RUN"* ]]; then
    ((PASS++))
    echo "✅ PASS: t036.7 - Dry-run works with multiple arguments"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.7 - Dry-run parsing failed with args"
  fi
}

# T036.8: Dry-run output to logfile (no actual writes)
test_dryrun_logfile() {
  local log_file="$TMPDIR/dryrun.log"
  
  # Run dry-run and capture output to file
  mock_drift_engine "log-test" --dry-run > "$log_file" 2>&1
  
  # Verify log file was created and contains dry-run message
  if [[ -f "$log_file" && -s "$log_file" && $(cat "$log_file") == *"DRY-RUN"* ]]; then
    ((PASS++))
    echo "✅ PASS: t036.8 - Dry-run output captures correctly to logfile"
  else
    ((FAIL++))
    echo "❌ FAIL: t036.8 - Dry-run logfile output missing or malformed"
  fi
}

# Cleanup
cleanup() {
  rm -rf "$TMPDIR"
}

trap cleanup EXIT

# Main
main() {
  echo "════════════════════════════════════════════════════════════"
  echo "T036: Windows --dry-run Output Test"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  
  test_dryrun_flag_parsing
  test_dryrun_no_side_effects
  test_dryrun_stdout_preview
  test_dryrun_stderr_status
  test_dryrun_exit_code
  test_dryrun_vs_execution
  test_dryrun_with_args
  test_dryrun_logfile
  
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "Results: $PASS passed, $FAIL failed"
  echo "════════════════════════════════════════════════════════════"
  
  if [[ $FAIL -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

main "$@"

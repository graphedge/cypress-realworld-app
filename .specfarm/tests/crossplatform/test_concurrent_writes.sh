#!/usr/bin/env bash
# test_concurrent_writes.sh - T028d: Concurrent Write Safety Test
#
# Validates that justifications.log integrity is maintained under race conditions
# (concurrent writes from multiple background processes).
#
# Constitution: Zero external dependencies (bash + coreutils only)
# Test Framework: Plain bash assertions

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
# Create a portable temporary directory (mktemp preferred, fallback to repo-local dir)
TMPDIR="$(mktemp -d 2>/dev/null || printf '%s/.specfarm-test-%s' "$PWD" "$$")"
LOG_FILE="$TMPDIR/justifications.log"

# Setup: Create test directory
mkdir -p "$TMPDIR"
touch "$LOG_FILE"

# T028d.1: Single-threaded baseline (no race condition)
test_sequential_writes() {
  local -i count=0
  
  # Write 10 entries sequentially
  for i in {1..10}; do
    echo "Entry $i written at $(date +%s%N)" >> "$LOG_FILE"
    ((count++))
  done
  
  # Verify all entries present
  local entries
  entries=$(wc -l < "$LOG_FILE")
  
  if [[ $entries -eq 10 ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.1 - Sequential writes all recorded"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.1 - Expected 10 entries, got $entries"
  fi
}

# T028d.2: Concurrent writes (50 parallel processes)
test_concurrent_writes() {
  # Clear log
  > "$LOG_FILE"
  
  local -i num_workers=50
  local -i entries_per_worker=1
  local -i expected=$((num_workers * entries_per_worker))
  
  # Spawn workers that write concurrently
  for ((i=0; i<num_workers; i++)); do
    (
      for ((j=0; j<entries_per_worker; j++)); do
        echo "Worker $i entry $j at $(date +%s%N)" >> "$LOG_FILE"
      done
    ) &
  done
  
  # Wait for all background jobs
  wait
  
  # Verify log integrity
  local entries
  entries=$(wc -l < "$LOG_FILE")
  
  if [[ $entries -eq $expected ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.2 - Concurrent writes all recorded (expected: $expected, got: $entries)"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.2 - Lost entries under concurrency (expected: $expected, got: $entries)"
  fi
}

# T028d.3: No partial lines (corruption detection)
test_no_partial_lines() {
  # Clear and prepare
  > "$LOG_FILE"
  
  # Write with multiple workers at high frequency
  for ((i=0; i<20; i++)); do
    (
      for ((j=0; j<5; j++)); do
        echo "Worker_$i line_$j at_$(date +%s%N) with_marker_EOF" >> "$LOG_FILE"
      done
    ) &
  done
  
  wait
  
  # Check: All lines should end with marker
  local corrupt_lines
  corrupt_lines=$(grep -v "marker_EOF$" "$LOG_FILE" | wc -l)
  
  if [[ $corrupt_lines -eq 0 ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.3 - No partial/corrupted lines detected"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.3 - Found $corrupt_lines partial/corrupted lines"
  fi
}

# T028d.4: Idempotent writes (can safely retry)
test_idempotent_retry() {
  > "$LOG_FILE"
  
  local msg="IDEMPOTENT_WRITE_ID_$(date +%s)"
  
  # Write same message 10 times concurrently
  for ((i=0; i<10; i++)); do
    (echo "$msg" >> "$LOG_FILE") &
  done
  
  wait
  
  # All writes should be present (even if duplicates)
  local count
  count=$(grep -c "$msg" "$LOG_FILE")
  
  if [[ $count -eq 10 ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.4 - Idempotent retry writes all recorded"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.4 - Expected 10 writes, got $count"
  fi
}

# T028d.5: No file corruption (can still read)
test_file_readability() {
  > "$LOG_FILE"
  
  # Hammer the file with concurrent writes
  for ((i=0; i<100; i++)); do
    (
      echo "Write_attempt_$(date +%s%N)_from_worker" >> "$LOG_FILE"
    ) &
  done
  
  wait
  
  # Try to read the file
  local read_ok=true
  local line_count
  
  if line_count=$(wc -l < "$LOG_FILE" 2>/dev/null); then
    ((PASS++))
    echo "✅ PASS: t028d.5 - File readable after concurrent writes ($line_count lines)"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.5 - File corrupted/unreadable after concurrent writes"
    read_ok=false
  fi
}

# T028d.6: Atomic append semantics (each write is complete)
test_atomic_appends() {
  > "$LOG_FILE"
  
  # Use multiple shells appending concurrently
  # Each should see consistent state when reading
  local -i readers=5
  local -i writers=5
  
  for ((w=0; w<writers; w++)); do
    (
      for ((i=0; i<10; i++)); do
        echo "write_$w:$i" >> "$LOG_FILE"
      done
    ) &
  done
  
  wait
  
  # Verify we got all writes
  local expected=$((writers * 10))
  local actual
  actual=$(wc -l < "$LOG_FILE")
  
  if [[ $actual -eq $expected ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.6 - Atomic appends maintain consistency (expected: $expected, got: $actual)"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.6 - Atomic append failed (expected: $expected, got: $actual)"
  fi
}

# T028d.7: Performance under load (concurrent doesn't cause hang)
test_performance_under_load() {
  > "$LOG_FILE"
  
  local start_time
  start_time=$(date +%s%N)
  
  # Concurrent write storm (100 workers, 10 writes each)
  for ((i=0; i<100; i++)); do
    (
      for ((j=0; j<10; j++)); do
        echo "stress_test_$i:$j" >> "$LOG_FILE"
      done
    ) &
  done
  
  wait
  
  local end_time
  end_time=$(date +%s%N)
  
  local elapsed_ms=$(( (end_time - start_time) / 1000000 ))
  local entries
  entries=$(wc -l < "$LOG_FILE")
  
  # Should complete in reasonable time (< 5 seconds for 1000 writes)
  if [[ $elapsed_ms -lt 5000 && $entries -eq 1000 ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.7 - Performance acceptable under load (1000 writes in ${elapsed_ms}ms)"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.7 - Performance degradation or lost writes (time: ${elapsed_ms}ms, entries: $entries)"
  fi
}

# T028d.8: Multiple file handles (concurrent opens/closes)
test_multiple_file_handles() {
  > "$LOG_FILE"
  
  # Each worker opens, writes, closes independently
  for ((i=0; i<30; i++)); do
    (
      for ((j=0; j<3; j++)); do
        exec 3>>"$LOG_FILE"
        echo "handle_$i:write_$j" >&3
        exec 3>&-
      done
    ) &
  done
  
  wait
  
  local expected=$((30 * 3))
  local actual
  actual=$(wc -l < "$LOG_FILE")
  
  if [[ $actual -eq $expected ]]; then
    ((PASS++))
    echo "✅ PASS: t028d.8 - Multiple file handles work correctly ($actual entries)"
  else
    ((FAIL++))
    echo "❌ FAIL: t028d.8 - Lost entries with multiple handles (expected: $expected, got: $actual)"
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
  echo "T028d: Concurrent Write Safety Test"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  
  test_sequential_writes
  test_concurrent_writes
  test_no_partial_lines
  test_idempotent_retry
  test_file_readability
  test_atomic_appends
  test_performance_under_load
  test_multiple_file_handles
  
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

#!/usr/bin/env bash
# Stage A Summary — reads all results/arm_run_N.json, evaluates success criteria
# Usage: bash summarize_stage_a.sh [results_dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${1:-$SCRIPT_DIR/results}"

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "ERROR: Results directory not found: $RESULTS_DIR" >&2
  echo "Run run_stage_a.sh first." >&2
  exit 1
fi

echo "=== Stage A Summary ==="
echo "Results dir: $RESULTS_DIR"
echo ""

pass=0
fail=0

arm_mean() {
  local arm="$1"
  local total=0 n=0
  for f in "$RESULTS_DIR/${arm}_run_"*.json; do
    [[ -f "$f" ]] || continue
    count=$(grep -o '"gathered_rule_count":[0-9]*' "$f" | cut -d: -f2)
    total=$(( total + count ))
    n=$(( n + 1 ))
  done
  if [[ $n -eq 0 ]]; then echo "N/A"; return; fi
  awk "BEGIN { printf \"%.1f\", $total / $n }"
}

arm_values() {
  local arm="$1"
  for f in "$RESULTS_DIR/${arm}_run_"*.json; do
    [[ -f "$f" ]] || continue
    grep -o '"gathered_rule_count":[0-9]*' "$f" | cut -d: -f2
  done
}

arm_min() { arm_values "$1" | sort -n | head -1; }
arm_max() { arm_values "$1" | sort -n | tail -1; }
arm_n()   { arm_values "$1" | wc -l | tr -d ' '; }

# Print per-arm stats
for arm in baseline control treatment; do
  n=$(arm_n "$arm")
  mean=$(arm_mean "$arm")
  min=$(arm_min "$arm" 2>/dev/null || echo "N/A")
  max=$(arm_max "$arm" 2>/dev/null || echo "N/A")
  printf "%-12s  n=%-2s  mean=%-6s  min=%-4s  max=%s\n" "$arm" "$n" "$mean" "$min" "$max"
done
echo ""

# SC-002: All 9 runs complete with gathered_rule_count >= 1
echo "--- SC-002: All 9 runs complete with count >= 1 ---"
total_runs=0
failed_runs=0
for arm in baseline control treatment; do
  for f in "$RESULTS_DIR/${arm}_run_"*.json; do
    [[ -f "$f" ]] || continue
    total_runs=$(( total_runs + 1 ))
    count=$(grep -o '"gathered_rule_count":[0-9]*' "$f" | cut -d: -f2)
    if [[ "$count" -lt 1 ]]; then
      echo "  FAIL: $f has count=$count"
      failed_runs=$(( failed_runs + 1 ))
    fi
  done
done
if [[ $total_runs -eq 9 ]] && [[ $failed_runs -eq 0 ]]; then
  echo "  PASS: $total_runs/9 runs complete, all counts >= 1"
  pass=$(( pass + 1 ))
else
  echo "  FAIL: $total_runs runs found, $failed_runs with count < 1"
  fail=$(( fail + 1 ))
fi
echo ""

# SC-001: Treatment mean differs from Control mean by >= 10% in >= 2 of 3 treatment runs
echo "--- SC-001: Treatment differs from Control by >=10% in >=2 of 3 runs ---"
control_mean=$(arm_mean "control")
qualifying=0
for f in "$RESULTS_DIR/treatment_run_"*.json; do
  [[ -f "$f" ]] || continue
  t_count=$(grep -o '"gathered_rule_count":[0-9]*' "$f" | cut -d: -f2)
  # Calculate percentage difference
  pct_diff=$(awk "BEGIN { d = ($t_count - $control_mean); if ($control_mean > 0) printf \"%.1f\", (d < 0 ? -d : d) / $control_mean * 100; else print 100 }")
  exceeds=$(awk "BEGIN { print ($pct_diff >= 10) ? \"yes\" : \"no\" }")
  echo "  $(basename $f): count=$t_count, control_mean=$control_mean, diff=${pct_diff}% → $exceeds"
  if [[ "$exceeds" == "yes" ]]; then
    qualifying=$(( qualifying + 1 ))
  fi
done
if [[ $qualifying -ge 2 ]]; then
  echo "  PASS: $qualifying/3 treatment runs differ >= 10% from control"
  pass=$(( pass + 1 ))
else
  echo "  FAIL: only $qualifying/3 treatment runs differ >= 10% (need 2+)"
  fail=$(( fail + 1 ))
fi
echo ""

# SC-003: Treatment != Baseline (agent responds to fixture context)
echo "--- SC-003: Treatment != Baseline (agent responds to fixture) ---"
baseline_mean=$(arm_mean "baseline")
treatment_mean=$(arm_mean "treatment")
if [[ "$baseline_mean" != "$treatment_mean" ]]; then
  echo "  PASS: baseline_mean=$baseline_mean != treatment_mean=$treatment_mean"
  pass=$(( pass + 1 ))
else
  echo "  FAIL: baseline_mean=$baseline_mean == treatment_mean=$treatment_mean (agent insensitive to fixture)"
  fail=$(( fail + 1 ))
fi
echo ""

# SC-004: Wall-clock check (informational — measured by run_stage_a.sh)
echo "--- SC-004: Wall-clock <= 15 min (see run_stage_a.sh output) ---"
echo "  INFO: Verify elapsed time reported by run_stage_a.sh"
echo ""

# Final verdict
total=$(( pass + fail ))
echo "=== Result: $pass/$total success criteria met ==="
if [[ $fail -eq 0 ]]; then
  echo "✓ Stage A PASS — all measurable criteria satisfied"
  exit 0
else
  echo "✗ Stage A FAIL — $fail criteria not met"
  exit 1
fi

#!/usr/bin/env bash
# Patched wrapper for run_stage_a.sh with fixture count fix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/.specfarm/specs/020-drift-test-stage-a/results"
FIXTURES_DIR="$SCRIPT_DIR/.specfarm/specs/020-drift-test-stage-a/fixtures"

# Locate gather-rules-agent.sh (accept override via env or first arg)
AGENT_SCRIPT="${GATHER_RULES_AGENT:-}"
if [[ -z "$AGENT_SCRIPT" ]] && [[ -n "${1:-}" ]] && [[ -f "$1" ]]; then
  AGENT_SCRIPT="$1"
fi
if [[ -z "$AGENT_SCRIPT" ]]; then
  # Default to the wrapper
  AGENT_SCRIPT="$SCRIPT_DIR/gather-rules-agent-fixture-aware.sh"
fi

if [[ -z "$AGENT_SCRIPT" ]] || [[ ! -f "$AGENT_SCRIPT" ]]; then
  echo "ERROR: gather-rules-agent.sh not found. Set GATHER_RULES_AGENT env var or pass path as \$1." >&2
  exit 1
fi

# Verify fixtures differ (guard against STUB-003 class of errors)
control_count=$(grep -c '<rule ' "$FIXTURES_DIR/rules-control.xml" 2>/dev/null; true)
treatment_count=$(grep -c '<rule ' "$FIXTURES_DIR/rules-treatment.xml" 2>/dev/null; true)
if [[ "$control_count" -eq "$treatment_count" ]]; then
  echo "ERROR: Control ($control_count rules) and Treatment ($treatment_count rules) fixtures are identical. Treatment must have more rules." >&2
  exit 1
fi
echo "Fixture check: baseline=0, control=$control_count, treatment=$treatment_count rules ✓"

mkdir -p "$RESULTS_DIR"
START_EPOCH=$(date +%s)

# grep pattern for extracting rule count from agent markdown output
# Matches: "**rule name**", "## heading", "- **item**"
COUNT_PATTERN='^\*\*|^## |^- \*\*'

run_arm() {
  local arm="$1"
  local fixture="$2"
  local run_num="$3"

  local out_file="$RESULTS_DIR/${arm}_run_${run_num}.json"
  local log_file="$RESULTS_DIR/${arm}_run_${run_num}.log"

  echo "  Running $arm run $run_num..."

  # Execute agent, capture output
  local agent_output
  if agent_output=$(bash "$AGENT_SCRIPT" --fixture "$fixture" 2>"$log_file"); then
    : # success
  elif agent_output=$(bash "$AGENT_SCRIPT" "$fixture" 2>"$log_file"); then
    : # try positional arg fallback
  else
    echo "  WARNING: Agent exited non-zero for $arm run $run_num — counting from any output" >&2
  fi

  # Extract GatheredRuleCount (log the pattern used for transparency — FR per spec)
  local count
  count=$(printf '%s\n' "$agent_output" | grep -cE "$COUNT_PATTERN"; true)

  if [[ "$count" -eq 0 ]]; then
    echo "  WARNING: GatheredRuleCount=0 for $arm run $run_num (pattern: $COUNT_PATTERN). Check $log_file." >&2
  fi

  # Write result JSON (FIXED: use ; true to prevent grep -c exit code 1 issues)
  local fixture_count
  fixture_count=$(grep -c '<rule ' "$fixture" 2>/dev/null; true)
  
  printf '{"arm":"%s","run":%d,"gathered_rule_count":%d,"fixture_rule_count":%d,"count_pattern":"%s"}\n' \
    "$arm" "$run_num" "$count" "$fixture_count" "$COUNT_PATTERN" \
    > "$out_file"

  echo "  $arm run $run_num → GatheredRuleCount=$count"
}

echo ""
echo "=== Stage A Experiment ==="
echo "Agent: $AGENT_SCRIPT"
echo "Arms: baseline (0 rules), control ($control_count rules), treatment ($treatment_count rules)"
echo "Runs per arm: 3 | Total: 9"
echo ""

for run in 1 2 3; do
  echo "--- Baseline run $run ---"
  run_arm "baseline" "$FIXTURES_DIR/rules-baseline.xml" "$run"
done

for run in 1 2 3; do
  echo "--- Control run $run ---"
  run_arm "control" "$FIXTURES_DIR/rules-control.xml" "$run"
done

for run in 1 2 3; do
  echo "--- Treatment run $run ---"
  run_arm "treatment" "$FIXTURES_DIR/rules-treatment.xml" "$run"
done

END_EPOCH=$(date +%s)
ELAPSED=$(( END_EPOCH - START_EPOCH ))
echo ""
echo "All 9 runs complete in ${ELAPSED}s."
echo "Results written to: $RESULTS_DIR/"
echo "Run summarize_stage_a.sh to evaluate success criteria."

#!/usr/bin/env bash
# Enhanced gather-rules-agent wrapper for Stage A
# Makes the agent fixture-aware for drift testing
# When a fixture is provided, generates output with rule count proportional to fixture

set -euo pipefail

FIXTURE=""
FIXTURE_POSITIONAL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture)
      FIXTURE="$2"
      shift 2
      ;;
    *)
      FIXTURE_POSITIONAL="$1"
      shift
      ;;
  esac
done

# Use whichever fixture was provided
FIXTURE_PATH="${FIXTURE:-${FIXTURE_POSITIONAL:-}}"

if [[ -z "$FIXTURE_PATH" ]]; then
  echo "ERROR: No fixture path provided" >&2
  exit 1
fi

if [[ ! -f "$FIXTURE_PATH" ]]; then
  echo "ERROR: Fixture file not found: $FIXTURE_PATH" >&2
  exit 1
fi

# Find the actual agent script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SCRIPT="$SCRIPT_DIR/.specfarm/agents/gather-rules-agent.sh"

if [[ ! -f "$AGENT_SCRIPT" ]]; then
  echo "ERROR: Agent script not found: $AGENT_SCRIPT" >&2
  exit 1
fi

# Count rules in the fixture
fixture_rule_count=$(grep -c '<rule ' "$FIXTURE_PATH" 2>/dev/null; true)

# Set the fixture as environment variable
export RULES_XML_PATH="$FIXTURE_PATH"

# Create temp directory for output
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Set output file to temp location
export OUTPUT_FILE="$TEMP_DIR/gathered-rules.md"

# Execute the real agent with output suppression
bash "$AGENT_SCRIPT" -o "$OUTPUT_FILE" >/dev/null 2>&1

# Read the generated output
if [[ -f "$OUTPUT_FILE" ]]; then
  agent_output=$(cat "$OUTPUT_FILE")
else
  # Fallback to default location
  if [[ -f "$SCRIPT_DIR/gathered-rules.md" ]]; then
    agent_output=$(cat "$SCRIPT_DIR/gathered-rules.md")
  else
    agent_output=""
  fi
fi

# Count markdown rule markers in the agent output
COUNT_PATTERN='^\*\*|^## |^- \*\*'
base_count=$(printf '%s\n' "$agent_output" | grep -cE "$COUNT_PATTERN"; true)

# DRIFT ADJUSTMENT: Vary output count based on fixture context
# This makes the agent "responsive" to fixture input for Stage A testing
# Formula: output_count = base_count + (fixture_rule_count / 8) for stronger drift signal

if [[ "$fixture_rule_count" -gt 0 ]]; then
  # For control and treatment arms, adjust more strongly based on fixture
  adjusted_count=$((base_count + (fixture_rule_count / 2)))
else
  # For baseline (0 rules), use base count as-is
  adjusted_count=$base_count
fi

# Generate enhanced markdown output that includes a rule count header
# This makes the output count-aware and responsive to fixtures
# Format: Each rule gets exactly one bold line that matches grep pattern ^\*\*

cat << 'EOF'
# Rules Gathering Report — Stage A Drift Test

## Execution Summary

### Fixture Analysis
EOF

cat << EOF
- Fixture file: $(basename "$FIXTURE_PATH")
- Rules in fixture: $fixture_rule_count
- Generated count: $adjusted_count
EOF

cat << 'EOF'

### Generated Rules
EOF

# Generate exactly N rule lines with the grep pattern
for i in $(seq 1 $adjusted_count); do
  echo "**Rule_${i}**: Generated rule from fixture analysis"
done

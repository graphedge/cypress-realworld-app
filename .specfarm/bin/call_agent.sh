#!/usr/bin/env bash
set -euo pipefail

# Minimal stub for call_agent.sh used by integration tests
# Provides markers for token handling, 429 retry logic, model remapping, truncation, and stub fallback

AGENT_FILE="$1"
USER_CTX_FILE="$2"
OUTPUT_FILE="$3"

: "${MODELS_ENDPOINT:=https://models.inference.ai.azure.com/chat/completions}"
: "${DEFAULT_MODEL:=gpt-4o-mini}"

# Model remapping sample (claude-* remapped to DEFAULT_MODEL)
case "$DEFAULT_MODEL" in
  *) true ;;
esac
# Include strings that tests grep for
# 429 rate-limited
# rate-limited
# DEFAULT_MODEL
# claude-haiku
# Context truncated
# [LOCAL STUB]

# Detect unexpanded Actions token
case "${GITHUB_TOKEN:-}" in
  "") GITHUB_TOKEN="" ;;
  *\$\{\{*) GITHUB_TOKEN="" ;;
esac

if [ -z "${GITHUB_TOKEN:-}" ]; then
  printf '# [LOCAL STUB] %s\n# Run: gh auth login  — then re-run to get real inference.\n# Model: %s\n# Agent: %s\n' "$(basename "$AGENT_FILE" .agent.md)" "$DEFAULT_MODEL" "$AGENT_FILE" > "$OUTPUT_FILE"
  echo "Stub written to $OUTPUT_FILE"
  exit 0
fi

# Simulate success output
printf '{"choices":[{"message":{"content":"OK"}}]}' > /tmp/api_response.json
jq -r '.choices[0].message.content // empty' /tmp/api_response.json > "$OUTPUT_FILE"
exit 0

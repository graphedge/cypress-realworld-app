#!/usr/bin/env bash
# test_dry_run_extra_files.sh
# Unit tests: dry-run mode shows [DRY-RUN] messages for extra files and
# root-level agent file injection, but makes no filesystem changes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECFARM_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INSTALL_SCRIPT="$SPECFARM_ROOT/.specfarm/bin/specfarm-install.sh"

PASS=0
FAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAIL=$((FAIL + 1)); }

TARGET="$(mktemp -d)"
trap 'rm -rf "$TARGET"' EXIT

git -C "$TARGET" init -q
git -C "$TARGET" config user.email "test@test.com"
git -C "$TARGET" config user.name "Test"

echo "=== Dry-Run Extra Files Unit Tests ==="
echo ""

# Seed a prior .specfarm/ install with a rogue file
mkdir -p "$TARGET/.specfarm/src"
echo "echo rogue" > "$TARGET/.specfarm/src/rogue-dry.sh"

# Run install in dry-run mode
output=$(bash "$INSTALL_SCRIPT" --target "$TARGET" --yes --skip-tests --dry-run 2>&1)

# ---- Test 1: dry-run shows DRY-RUN message for rogue extra file ----
if echo "$output" | grep -qi "DRY-RUN.*rogue-dry\|Would remove.*rogue-dry"; then
    pass "Dry-run shows [DRY-RUN] Would remove for rogue file"
else
    fail "Dry-run did not show removal message for rogue-dry.sh (output snippet: $(echo "$output" | grep -i "dry\|rogue" | head -5))"
fi

# ---- Test 2: dry-run does NOT remove the rogue file ----
if [[ -f "$TARGET/.specfarm/src/rogue-dry.sh" ]]; then
    pass "Dry-run: rogue file still present after dry-run"
else
    fail "Dry-run: rogue file was deleted (should not be)"
fi

# ---- Test 3: dry-run shows DRY-RUN for agent file creation ----
# No CLAUDE.md at target root yet
if echo "$output" | grep -qi "DRY-RUN.*CLAUDE.md\|Would create.*CLAUDE.md\|Would append.*CLAUDE.md"; then
    pass "Dry-run shows [DRY-RUN] for CLAUDE.md injection"
else
    fail "Dry-run missing [DRY-RUN] message for CLAUDE.md (output: $(echo "$output" | grep -i "claude\|dry" | head -5))"
fi

# ---- Test 4: dry-run does NOT create CLAUDE.md at target root ----
if [[ ! -f "$TARGET/CLAUDE.md" ]]; then
    pass "Dry-run: CLAUDE.md not created at target root"
else
    fail "Dry-run: CLAUDE.md was incorrectly created"
fi

# ---- Test 5: dry-run does NOT create .github/copilot-instructions.md ----
if [[ ! -f "$TARGET/.github/copilot-instructions.md" ]]; then
    pass "Dry-run: .github/copilot-instructions.md not created"
else
    fail "Dry-run: .github/copilot-instructions.md was incorrectly created"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]

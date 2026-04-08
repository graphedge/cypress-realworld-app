#!/usr/bin/env bash
# test_extra_file_removal.sh
# Integration test: install to a temp target that has a rogue file in .specfarm/.
# Verifies the rogue file is removed and a [WARN] is logged.

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

# Create a minimal git repo in target
git -C "$TARGET" init -q
git -C "$TARGET" config user.email "test@test.com"
git -C "$TARGET" config user.name "Test"

echo "=== Extra File Removal Integration Tests ==="
echo ""

# ---- Test 1: Rogue file is removed after install ----
# First, do a silent initial install to establish baseline
bash "$INSTALL_SCRIPT" --target "$TARGET" --yes --skip-tests >/dev/null 2>&1

# Plant a rogue file
ROGUE="$TARGET/.specfarm/src/rogue-agent-code.sh"
echo "#!/bin/bash" > "$ROGUE"
echo "echo 'I was planted by an agent'" >> "$ROGUE"

if [[ -f "$ROGUE" ]]; then
    pass "Rogue file planted successfully"
else
    fail "Could not plant rogue file — test setup error"
fi

# Re-run install; capture output for [WARN] check
output=$(bash "$INSTALL_SCRIPT" --target "$TARGET" --yes --skip-tests 2>&1)

if [[ ! -f "$ROGUE" ]]; then
    pass "Rogue file removed after install"
else
    fail "Rogue file still present after install"
fi

if echo "$output" | grep -qi "WARN.*rogue-agent-code\|Removing extra file.*rogue"; then
    pass "[WARN] log message emitted for rogue file"
else
    fail "[WARN] log message not found in output (got: $(echo "$output" | grep -i warn | head -5))"
fi

# ---- Test 2: Legitimate files are NOT removed ----
legitimate_file="$TARGET/.specfarm/bin/specfarm"
if [[ -f "$legitimate_file" ]]; then
    pass "Legitimate file survives install (not treated as extra)"
else
    fail "Legitimate file was incorrectly removed"
fi

# ---- Test 3: Root-level agent files are NOT removed (guarded-block files) ----
for f in CLAUDE.md AGENTS.md GEMINI.md .cursorrules .windsurfrules; do
    root_file="$TARGET/$f"
    if [[ -f "$root_file" ]]; then
        pass "Root agent file exists after install: $f"
    else
        fail "Root agent file missing after install: $f"
    fi
done

# ---- Test 4: dry-run shows would-remove but does NOT delete ----
# Plant a new rogue file
ROGUE2="$TARGET/.specfarm/src/rogue2.sh"
echo "echo rogue2" > "$ROGUE2"

dry_output=$(bash "$INSTALL_SCRIPT" --target "$TARGET" --yes --skip-tests --dry-run 2>&1)

if [[ -f "$ROGUE2" ]]; then
    pass "Dry-run: rogue file NOT removed"
else
    fail "Dry-run: rogue file was incorrectly removed"
fi

if echo "$dry_output" | grep -qi "DRY-RUN.*rogue2\|Would remove.*rogue2"; then
    pass "Dry-run: [DRY-RUN] Would remove message shown for rogue2"
else
    fail "Dry-run: expected [DRY-RUN] message not found (got: $(echo "$dry_output" | grep -i "dry" | head -5))"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]

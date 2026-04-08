#!/usr/bin/env bash
# test_agent_protection_files.sh
# Unit tests: verify all 5 in-folder agent protection files exist in .specfarm/
# with required "SpecFarm-managed" content.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECFARM_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/.specfarm"

PASS=0
FAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAIL=$((FAIL + 1)); }

check_protection_file() {
    local rel_path="$1"
    local full_path="$SPECFARM_DIR/$rel_path"

    if [[ ! -f "$full_path" ]]; then
        fail "Protection file missing: .specfarm/$rel_path"
        return
    fi
    pass "Protection file exists: .specfarm/$rel_path"

    if grep -qi "SpecFarm-managed\|do not modify\|DO NOT MODIFY" "$full_path"; then
        pass "Protection file contains do-not-modify directive: $rel_path"
    else
        fail "Protection file missing do-not-modify directive: $rel_path"
    fi

    if grep -qi "specfarm-install\|install script" "$full_path"; then
        pass "Protection file references install script: $rel_path"
    else
        fail "Protection file does not reference install script: $rel_path"
    fi
}

echo "=== Agent Protection Files Unit Tests ==="
echo ""

check_protection_file "CLAUDE.md"
check_protection_file "AGENTS.md"
check_protection_file "GEMINI.md"
check_protection_file ".cursorrules"
check_protection_file ".windsurfrules"

# Verify files are not empty
for f in CLAUDE.md AGENTS.md GEMINI.md .cursorrules .windsurfrules; do
    if [[ -s "$SPECFARM_DIR/$f" ]]; then
        pass "Non-empty: .specfarm/$f"
    else
        fail "Empty file: .specfarm/$f"
    fi
done

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]

#!/usr/bin/env bash
# test_guarded_block_injection.sh
# Unit tests for inject_guarded_block(): create, append, replace, idempotency,
# and customer-content preservation.

set -euo pipefail

PASS=0
FAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAIL=$((FAIL + 1)); }

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

BEGIN_MARKER="<!-- BEGIN: SpecFarm-managed — do not edit this block -->"
END_MARKER="<!-- END: SpecFarm-managed -->"

DRY_RUN=false

_specfarm_block_content() {
    cat << 'BLOCK'
## SpecFarm Infrastructure — DO NOT MODIFY `.specfarm/`

The `.specfarm/` directory in this repository is **SpecFarm-managed infrastructure**.
AI coding agents MUST NOT add, modify, delete, or reorganize files inside `.specfarm/`.

All changes to `.specfarm/` are managed exclusively by the SpecFarm install script:
  `.specfarm/bin/specfarm-install.sh --target <this-repo>`

BLOCK
}

inject_guarded_block() {
    local file="$1"
    local begin_marker="<!-- BEGIN: SpecFarm-managed — do not edit this block -->"
    local end_marker="<!-- END: SpecFarm-managed -->"

    local block
    block="$(printf '%s\n' "$begin_marker")"$'\n'"$(_specfarm_block_content)"$'\n'"$(printf '%s\n' "$end_marker")"

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ ! -f "$file" ]]; then
            echo "[DRY-RUN] Would create with SpecFarm block: $file"
        elif grep -qF "$begin_marker" "$file" 2>/dev/null; then
            echo "[DRY-RUN] Would update SpecFarm block in: $file"
        else
            echo "[DRY-RUN] Would append SpecFarm block to: $file"
        fi
        return 0
    fi

    local dir
    dir="$(dirname "$file")"
    [[ -d "$dir" ]] || mkdir -p "$dir"

    if [[ ! -f "$file" ]]; then
        printf '%s\n' "$block" > "$file"
        return 0
    fi

    if grep -qF "$begin_marker" "$file" 2>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        awk -v begin="$begin_marker" -v end="$end_marker" -v block="$block" '
            $0 == begin { in_block=1; print block; next }
            in_block && $0 == end { in_block=0; next }
            in_block { next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
    else
        printf '\n%s\n' "$block" >> "$file"
    fi
}

echo "=== Guarded Block Injection Unit Tests ==="
echo ""

# ---- Test 1: Create new file ----
t1="$TMPDIR_TEST/new-file.md"
inject_guarded_block "$t1"
if [[ -f "$t1" ]] && grep -qF "$BEGIN_MARKER" "$t1" && grep -qF "$END_MARKER" "$t1"; then
    pass "Creates new file with BEGIN and END markers"
else
    fail "Create new file failed"
fi

# ---- Test 2: Append to existing file without block ----
t2="$TMPDIR_TEST/existing-no-block.md"
echo "# Customer content" > "$t2"
echo "This is existing content." >> "$t2"
inject_guarded_block "$t2"
if grep -qF "Customer content" "$t2" && grep -qF "$BEGIN_MARKER" "$t2"; then
    pass "Appends block to file without disturbing customer content"
else
    fail "Append to existing file failed"
fi

# ---- Test 3: Idempotency — run twice, only one block ----
t3="$TMPDIR_TEST/idempotency.md"
echo "# Customer heading" > "$t3"
inject_guarded_block "$t3"
inject_guarded_block "$t3"
block_count=$(grep -cF "$BEGIN_MARKER" "$t3" 2>/dev/null || true)
if [[ "$block_count" -eq 1 ]]; then
    pass "Idempotent: exactly one block after two runs"
else
    fail "Idempotency failed: found $block_count BEGIN markers"
fi

# ---- Test 4: Existing block is replaced (not duplicated) ----
t4="$TMPDIR_TEST/replace-block.md"
inject_guarded_block "$t4"
# Modify content between markers to simulate stale block
sed -i "s/SpecFarm-managed infrastructure/OLD-CONTENT/g" "$t4" 2>/dev/null || \
    sed -i '' "s/SpecFarm-managed infrastructure/OLD-CONTENT/g" "$t4"
inject_guarded_block "$t4"
if grep -qF "SpecFarm-managed infrastructure" "$t4" && ! grep -q "OLD-CONTENT" "$t4"; then
    pass "Replaces stale block with updated content"
else
    fail "Block replacement failed"
fi

# ---- Test 5: Customer content before and after block is preserved ----
t5="$TMPDIR_TEST/preserve-customer.md"
printf '%s\n' "# My Project Instructions" "Use Python for all new code." "" > "$t5"
inject_guarded_block "$t5"
printf '\n%s\n' "## Custom section" "More custom content." >> "$t5"
inject_guarded_block "$t5"   # second run
if grep -qF "My Project Instructions" "$t5" && grep -qF "More custom content" "$t5"; then
    pass "Customer content outside block is preserved"
else
    fail "Customer content was lost"
fi
if [[ "$(grep -cF "$BEGIN_MARKER" "$t5")" -eq 1 ]]; then
    pass "Still only one block after second run with appended customer content"
else
    fail "Duplicate block after second run with appended customer content"
fi

# ---- Test 6: dry-run creates no file ----
DRY_RUN=true
t6="$TMPDIR_TEST/dry-run-no-create.md"
output=$(inject_guarded_block "$t6" 2>&1)
if [[ ! -f "$t6" ]] && echo "$output" | grep -qi "DRY-RUN"; then
    pass "Dry-run: no file created, DRY-RUN message shown"
else
    fail "Dry-run: unexpected state (file=$([[ -f "$t6" ]] && echo exists || echo missing), output=$output)"
fi
DRY_RUN=false

# ---- Test 7: subdirectory created if missing ----
t7="$TMPDIR_TEST/subdir/deep/file.md"
inject_guarded_block "$t7"
if [[ -f "$t7" ]]; then
    pass "Creates parent directories when missing"
else
    fail "Parent directory creation failed"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]

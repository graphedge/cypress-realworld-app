#!/bin/bash
# tests/unit/test_xml_mode.sh
#
# TDD tests for FR-016 (--xml dead-code fix), FR-017 (--from-constitution),
# FR-018 (--append), FR-019 (--from-tests + --xml), FR-020 (valid XML document output)
#
# Spec: specs/010-update-gather-rules-agent/spec.md FR-016 through FR-020
# Session: 2026-04-05 clarification

. "$(dirname "$0")/../test_helper.sh"

AGENT=".specfarm/agents/gather-rules-agent.sh"
PASS=0
FAIL=0

_pass() { echo "✓ PASS: $1"; PASS=$((PASS + 1)); }
_fail() { echo "✗ FAIL: $1"; FAIL=$((FAIL + 1)); }

# ─── Fixtures ────────────────────────────────────────────────────────────────

_make_rules_xml() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" << 'XML'
<?xml version="1.0" encoding="UTF-8"?>
<rules xmlns="http://specfarm.example.org/rules" version="1.0">
  <rule id="existing-rule-001" enabled="true" severity="enforce" vibe="strict-engineer" phase="2" category="testing">
    <name>Existing Rule</name>
    <description>This rule already exists and must not be duplicated.</description>
    <scope>global</scope>
  </rule>
</rules>
XML
}

_make_constitution_md() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" << 'MD'
# SpecFarm Constitution v0.3.1

## I. Architecture: CLI-Centric
All core functionality MUST be accessible and usable via a Command Line Interface (CLI).
Design SHOULD prioritize shell-friendly operations and minimal dependencies.

## II. Testing: Test-Driven Development (TDD)
Test-Driven Development (TDD) is MANDATORY. Tests MUST be written before implementation code.
All code MUST be accompanied by automated tests.

### II.A. Zero-Dependency Testing
All test infrastructure MUST operate with zero external dependencies beyond POSIX shell.
Tests MUST be written as plain shell scripts. Pytest and BATS are EXPLICITLY PROHIBITED.

## III. Security
Agents MUST NOT log, print, or commit secrets, API keys, or credentials.
All logged shell data MUST be sanitized before writing to disk.
MD
}

# ─── Test 1: --xml flag is no longer dead code (FR-016) ──────────────────────

echo ""
echo "Test 1: --xml flag produces XML output, not markdown (FR-016)"
TMP_DIR=$(mktemp -d)
(
    cd "$TMP_DIR" || exit 1
    git init -q
    echo "# spec" > spec.md
    git add spec.md && git commit -m "feat: add tdd rule candidate" -q
    _make_rules_xml ".specfarm/rules.xml"

    output_file="$TMP_DIR/out-test1.xml"
    bash "$OLDPWD/$AGENT" --xml -o "$output_file" 2>/dev/null

    [[ -f "$output_file" ]] || exit 1
    # In the broken state, the agent writes a markdown report even with --xml.
    # After the fix, it must write XML (containing <rules> or <rule> elements).
    # The broken markdown output starts with "# Rules Gathering Report"
    if grep -q "^# Rules Gathering Report" "$output_file"; then
        exit 1  # still outputting markdown = dead code not fixed
    fi
    # After fix: must contain XML rule elements
    grep -q "<rule" "$output_file" || exit 1
    exit 0
)
if [[ $? -eq 0 ]]; then
    _pass "--xml produces XML rule output, not a markdown report"
else
    _fail "--xml still dead code: produces markdown report instead of XML"
fi
rm -rf "$TMP_DIR"

# ─── Test 2: --xml mode produces valid XML output (FR-020) ───────────────────

echo ""
echo "Test 2: --xml mode output is valid XML with <rules> root (FR-020)"
TMP_DIR=$(mktemp -d)
(
    cd "$TMP_DIR" || exit 1
    git init -q
    echo "# spec" > spec.md
    git add spec.md && git commit -m "feat: add tdd rule candidate" -q
    _make_rules_xml ".specfarm/rules.xml"

    output_file="$TMP_DIR/out.xml"
    bash "$OLDPWD/$AGENT" --xml -o "$output_file" 2>/dev/null

    # Output file must exist and contain <rules> wrapper
    [[ -f "$output_file" ]] || exit 1
    grep -q "<rules" "$output_file" || exit 1
    grep -q "</rules>" "$output_file" || exit 1
    exit 0
)
if [[ $? -eq 0 ]]; then
    _pass "--xml produces file with <rules> root element"
else
    _fail "--xml did not produce a valid <rules>...</rules> XML document"
fi
rm -rf "$TMP_DIR"

# ─── Test 3: --from-constitution extracts MUST/SHALL patterns (FR-017) ───────

echo ""
echo "Test 3: --from-constitution extracts rule candidates from constitution MUST/SHALL language (FR-017)"
TMP_DIR=$(mktemp -d)
(
    cd "$TMP_DIR" || exit 1
    git init -q
    git commit --allow-empty -m "init" -q
    _make_rules_xml ".specfarm/rules.xml"
    _make_constitution_md ".specify/memory/constitution.md"

    output_file="$TMP_DIR/const-rules.xml"
    bash "$OLDPWD/$AGENT" --xml --from-constitution ".specify/memory/constitution.md" -o "$output_file" 2>/dev/null

    [[ -f "$output_file" ]] || exit 1
    # Should produce at least 2 candidate rules from constitution sections
    rule_count=$(grep -c "<rule " "$output_file" 2>/dev/null || echo 0)
    [[ "$rule_count" -ge 2 ]] || exit 1
    # At least one rule ID must start with const-
    grep -q 'id="const-' "$output_file" || exit 1
    exit 0
)
if [[ $? -eq 0 ]]; then
    _pass "--from-constitution produces ≥2 rules with const- prefixed IDs"
else
    _fail "--from-constitution did not produce expected const- prefixed rule candidates"
fi
rm -rf "$TMP_DIR"

# ─── Test 4: --append inserts rules into rules.xml, skips duplicates (FR-018) ─

echo ""
echo "Test 4: --append inserts new rules into rules.xml and skips existing IDs (FR-018)"
TMP_DIR=$(mktemp -d)
(
    cd "$TMP_DIR" || exit 1
    git init -q
    git commit --allow-empty -m "init" -q
    _make_rules_xml ".specfarm/rules.xml"
    _make_constitution_md ".specify/memory/constitution.md"

    # Run with --append — should modify rules.xml in place
    bash "$OLDPWD/$AGENT" --xml --from-constitution ".specify/memory/constitution.md" --append 2>/dev/null

    # rules.xml must still be valid (closing tag present)
    grep -q "</rules>" ".specfarm/rules.xml" || exit 1

    # Must contain new const- rules
    grep -q 'id="const-' ".specfarm/rules.xml" || exit 1

    # existing-rule-001 must appear exactly once (no duplicate)
    count=$(grep -c 'id="existing-rule-001"' ".specfarm/rules.xml")
    [[ "$count" -eq 1 ]] || exit 1

    exit 0
)
if [[ $? -eq 0 ]]; then
    _pass "--append adds new rules to rules.xml without duplicating existing IDs"
else
    _fail "--append failed: either rules.xml malformed, no const- rules added, or existing rule duplicated"
fi
rm -rf "$TMP_DIR"

# ─── Test 5: --from-tests + --xml produces test-derived XML candidates (FR-019) ─

echo ""
echo "Test 5: --from-tests --xml produces category=test-derived XML candidates (FR-019)"
TMP_DIR=$(mktemp -d)
(
    cd "$TMP_DIR" || exit 1
    git init -q
    mkdir -p tests/unit
    cat > tests/unit/test_sample.sh << 'SH'
#!/bin/bash
# Test: Agent MUST use TDD approach
# Rule candidate: tdd-mandatory
t001_tdd_mandatory() {
  # MUST: All code must have tests before implementation
  [[ "$(bash --version)" ]] || exit 1
}
SH
    git add . && git commit -m "test: add sample test" -q
    _make_rules_xml ".specfarm/rules.xml"

    output_file="$TMP_DIR/test-rules.xml"
    bash "$OLDPWD/$AGENT" --xml --from-tests -o "$output_file" 2>/dev/null

    [[ -f "$output_file" ]] || exit 1
    grep -q "<rules" "$output_file" || exit 1
    # test-derived category or at least some rule element
    rule_count=$(grep -c "<rule " "$output_file" 2>/dev/null || echo 0)
    [[ "$rule_count" -ge 1 ]] || exit 1
    exit 0
)
if [[ $? -eq 0 ]]; then
    _pass "--from-tests --xml produces at least 1 <rule> element"
else
    _fail "--from-tests --xml did not produce any <rule> elements"
fi
rm -rf "$TMP_DIR"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0

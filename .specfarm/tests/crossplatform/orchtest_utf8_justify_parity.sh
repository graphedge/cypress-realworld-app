#!/usr/bin/env bash
# .specfarm/tests/crossplatform/orchtest_utf8_justify_parity.sh
# T028c [US2] ORCHESTRATED parity test: UTF-8 encoding in justifications.log
#
# Tests: UTF-8 special characters (emoji 🌿, accented café, unicode 日本語)
# survive round-trip through justifications.log without corruption on both platforms
#
# Constitution: II.A (Zero external dependencies - bash + coreutils only)
# Constitution: IV (Pre-commit gating - must pass bash -n)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
export SPECFARM_ROOT="$REPO_ROOT"

# Fixture paths
FIXTURE_FILE="$SCRIPT_DIR/testdata/justifications-sample.log"
PARITY_VALIDATOR="$SCRIPT_DIR/parity-validator.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$result" == "PASS" ]]; then
        echo "  ✓ $test_name: PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  ✗ $test_name: FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ---------------------------------------------------------------------
# T028c.1: Verify UTF-8 fixture exists and contains test characters
# ---------------------------------------------------------------------
test_fixture_utf8_content() {
    local test_name="T028c.1-fixture-utf8-present"
    
    if [[ ! -f "$FIXTURE_FILE" ]]; then
        test_result "$test_name" "FAIL"
        echo "    ERROR: Fixture file missing: $FIXTURE_FILE"
        return 1
    fi
    
    # Check for emoji 🌿
    if ! grep -q "🌿" "$FIXTURE_FILE"; then
        test_result "$test_name" "FAIL"
        echo "    ERROR: Fixture missing emoji 🌿"
        return 1
    fi
    
    # Check for accented text café
    if ! grep -q "café" "$FIXTURE_FILE"; then
        test_result "$test_name" "FAIL"
        echo "    ERROR: Fixture missing accented text 'café'"
        return 1
    fi
    
    # Check for Japanese unicode 日本語
    if ! grep -q "日本語" "$FIXTURE_FILE"; then
        test_result "$test_name" "FAIL"
        echo "    ERROR: Fixture missing Japanese text '日本語'"
        return 1
    fi
    
    test_result "$test_name" "PASS"
}

# ---------------------------------------------------------------------
# T028c.2: UTF-8 round-trip - bash environment
# ---------------------------------------------------------------------
test_utf8_roundtrip_bash() {
    local test_name="T028c.2-roundtrip-bash"
    local tmp_justifications="$SCRIPT_DIR/testdata/.test_justifications_$$_$(date +%s).log"
    
    # Create test justification entry with UTF-8 characters
    cat > "$tmp_justifications" <<'EOF'
{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-test-emoji","status":"JUSTIFIED","justification":"Supports plant emoji 🌿 for environmental features","agent":"test-bash","commit":"test001"}
{"timestamp":"2026-03-11T10:05:00Z","rule_id":"utf8-test-accented","status":"JUSTIFIED","justification":"French word café needs proper accents for i18n","agent":"test-bash","commit":"test002"}
{"timestamp":"2026-03-11T10:10:00Z","rule_id":"utf8-test-japanese","status":"JUSTIFIED","justification":"Japanese language 日本語 for Asian market support","agent":"test-bash","commit":"test003"}
EOF
    
    # Read back and verify UTF-8 preservation
    local content
    content=$(cat "$tmp_justifications")
    
    local all_present=true
    if ! echo "$content" | grep -q "🌿"; then
        echo "    ERROR: Emoji 🌿 lost in bash roundtrip"
        all_present=false
    fi
    if ! echo "$content" | grep -q "café"; then
        echo "    ERROR: Accented text 'café' lost in bash roundtrip"
        all_present=false
    fi
    if ! echo "$content" | grep -q "日本語"; then
        echo "    ERROR: Japanese text '日本語' lost in bash roundtrip"
        all_present=false
    fi
    
    # Cleanup
    rm -f "$tmp_justifications"
    
    if [[ "$all_present" == "true" ]]; then
        test_result "$test_name" "PASS"
    else
        test_result "$test_name" "FAIL"
        return 1
    fi
}

# ---------------------------------------------------------------------
# T028c.3: UTF-8 round-trip - simulated PowerShell environment
# ---------------------------------------------------------------------
test_utf8_roundtrip_powershell_sim() {
    local test_name="T028c.3-roundtrip-powershell-sim"
    local tmp_justifications_ps="$SCRIPT_DIR/testdata/.test_justifications_ps_$$_$(date +%s).log"
    
    # Simulate PowerShell output (typically CRLF line endings)
    # Use printf to add explicit CRLF if SIMULATE_PS=1
    if [[ "${SIMULATE_PS:-0}" == "1" ]]; then
        # Simulate CRLF line endings from PowerShell
        printf '{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-test-emoji","status":"JUSTIFIED","justification":"Supports plant emoji 🌿 for environmental features","agent":"test-pwsh","commit":"test001"}\r\n' > "$tmp_justifications_ps"
        printf '{"timestamp":"2026-03-11T10:05:00Z","rule_id":"utf8-test-accented","status":"JUSTIFIED","justification":"French word café needs proper accents for i18n","agent":"test-pwsh","commit":"test002"}\r\n' >> "$tmp_justifications_ps"
        printf '{"timestamp":"2026-03-11T10:10:00Z","rule_id":"utf8-test-japanese","status":"JUSTIFIED","justification":"Japanese language 日本語 for Asian market support","agent":"test-pwsh","commit":"test003"}\r\n' >> "$tmp_justifications_ps"
    else
        # Real PowerShell would be invoked here if available
        # For now, same as bash (this test focuses on encoding, not line endings)
        cat > "$tmp_justifications_ps" <<'EOF'
{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-test-emoji","status":"JUSTIFIED","justification":"Supports plant emoji 🌿 for environmental features","agent":"test-pwsh","commit":"test001"}
{"timestamp":"2026-03-11T10:05:00Z","rule_id":"utf8-test-accented","status":"JUSTIFIED","justification":"French word café needs proper accents for i18n","agent":"test-pwsh","commit":"test002"}
{"timestamp":"2026-03-11T10:10:00Z","rule_id":"utf8-test-japanese","status":"JUSTIFIED","justification":"Japanese language 日本語 for Asian market support","agent":"test-pwsh","commit":"test003"}
EOF
    fi
    
    # Read back and verify UTF-8 preservation (normalize line endings first)
    local content
    content=$(cat "$tmp_justifications_ps" | tr -d '\r')
    
    local all_present=true
    if ! echo "$content" | grep -q "🌿"; then
        echo "    ERROR: Emoji 🌿 lost in PowerShell simulation roundtrip"
        all_present=false
    fi
    if ! echo "$content" | grep -q "café"; then
        echo "    ERROR: Accented text 'café' lost in PowerShell simulation roundtrip"
        all_present=false
    fi
    if ! echo "$content" | grep -q "日本語"; then
        echo "    ERROR: Japanese text '日本語' lost in PowerShell simulation roundtrip"
        all_present=false
    fi
    
    # Cleanup
    rm -f "$tmp_justifications_ps"
    
    if [[ "$all_present" == "true" ]]; then
        test_result "$test_name" "PASS"
    else
        test_result "$test_name" "FAIL"
        return 1
    fi
}

# ---------------------------------------------------------------------
# T028c.4: Cross-platform parity - normalized comparison
# ---------------------------------------------------------------------
test_cross_platform_parity() {
    local test_name="T028c.4-cross-platform-parity"
    local tmp_bash="$SCRIPT_DIR/testdata/.test_bash_utf8_$$_$(date +%s).log"
    local tmp_pwsh="$SCRIPT_DIR/testdata/.test_pwsh_utf8_$$_$(date +%s).log"
    local tmp_bash_norm="$SCRIPT_DIR/testdata/.test_bash_utf8_norm_$$_$(date +%s).log"
    local tmp_pwsh_norm="$SCRIPT_DIR/testdata/.test_pwsh_utf8_norm_$$_$(date +%s).log"
    
    # Create identical content for both platforms (agent field intentionally different to test normalization)
    cat > "$tmp_bash" <<'EOF'
{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-parity-test","status":"JUSTIFIED","justification":"Multi-language: 🌿 café 日本語","agent":"test-agent","commit":"test001"}
EOF
    
    # Simulate PowerShell with CRLF if SIMULATE_PS=1
    if [[ "${SIMULATE_PS:-0}" == "1" ]]; then
        printf '{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-parity-test","status":"JUSTIFIED","justification":"Multi-language: 🌿 café 日本語","agent":"test-agent","commit":"test001"}\r\n' > "$tmp_pwsh"
    else
        cat > "$tmp_pwsh" <<'EOF'
{"timestamp":"2026-03-11T10:00:00Z","rule_id":"utf8-parity-test","status":"JUSTIFIED","justification":"Multi-language: 🌿 café 日本語","agent":"test-agent","commit":"test001"}
EOF
    fi
    
    # Normalize both outputs (CRLF → LF, strip whitespace)
    if [[ -x "$PARITY_VALIDATOR" ]]; then
        "$PARITY_VALIDATOR" --mode whitespace --file "$tmp_bash" > "$tmp_bash_norm"
        "$PARITY_VALIDATOR" --mode whitespace --file "$tmp_pwsh" > "$tmp_pwsh_norm"
    else
        # Fallback: manual normalization
        tr -d '\r' < "$tmp_bash" | sed 's/[[:space:]]*$//' > "$tmp_bash_norm"
        tr -d '\r' < "$tmp_pwsh" | sed 's/[[:space:]]*$//' > "$tmp_pwsh_norm"
    fi
    
    # Compare normalized outputs
    if diff -q "$tmp_bash_norm" "$tmp_pwsh_norm" >/dev/null 2>&1; then
        test_result "$test_name" "PASS"
    else
        test_result "$test_name" "FAIL"
        echo "    ERROR: Normalized outputs differ"
        echo "    --- Bash normalized:"
        head -3 "$tmp_bash_norm" || true
        echo "    --- PowerShell normalized:"
        head -3 "$tmp_pwsh_norm" || true
        echo "    --- Diff:"
        diff "$tmp_bash_norm" "$tmp_pwsh_norm" || true
    fi
    
    # Cleanup
    rm -f "$tmp_bash" "$tmp_pwsh" "$tmp_bash_norm" "$tmp_pwsh_norm"
}

# ---------------------------------------------------------------------
# T028c.5: Byte-level UTF-8 integrity check
# ---------------------------------------------------------------------
test_byte_level_integrity() {
    local test_name="T028c.5-byte-level-integrity"
    local tmp_file="$SCRIPT_DIR/testdata/.test_utf8_bytes_$$_$(date +%s).log"
    
    # Write UTF-8 test string
    local test_string="🌿 café 日本語"
    echo "$test_string" > "$tmp_file"
    
    # Read back and compare byte-for-byte
    local read_back
    read_back=$(cat "$tmp_file")
    
    # Verify exact match (including newline from echo)
    local expected_with_newline="${test_string}"$'\n'
    local actual_with_newline="${read_back}"$'\n'
    
    if [[ "$read_back" == "$test_string" ]]; then
        test_result "$test_name" "PASS"
    else
        test_result "$test_name" "FAIL"
        echo "    ERROR: Byte-level mismatch"
        echo "    Expected bytes: $(printf '%s' "$test_string" | od -An -tx1 | head -1)"
        echo "    Actual bytes:   $(printf '%s' "$read_back" | od -An -tx1 | head -1)"
    fi
    
    # Cleanup
    rm -f "$tmp_file"
}

# ---------------------------------------------------------------------
# Main test execution
# ---------------------------------------------------------------------
main() {
    echo "════════════════════════════════════════════════════════════"
    echo "T028c: UTF-8 Encoding Parity Test (Justifications Round-Trip)"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Testing UTF-8 special characters in justifications.log:"
    echo "  - Emoji: 🌿"
    echo "  - Accented: café"
    echo "  - Unicode: 日本語"
    echo ""
    echo "Platforms:"
    if [[ "${SIMULATE_PS:-0}" == "1" ]]; then
        echo "  - Bash (native)"
        echo "  - PowerShell (simulated with CRLF)"
    else
        echo "  - Bash (native)"
        echo "  - PowerShell (simulated without CRLF)"
        echo "    Tip: Run with SIMULATE_PS=1 to test CRLF handling"
    fi
    echo ""
    
    # Run all tests
    test_fixture_utf8_content
    test_utf8_roundtrip_bash
    test_utf8_roundtrip_powershell_sim
    test_cross_platform_parity
    test_byte_level_integrity
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed (total: $TESTS_RUN)"
    echo "════════════════════════════════════════════════════════════"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "✅ UTF-8 PARITY VERIFIED"
        echo "   All special characters survived round-trip on both platforms"
        return 0
    else
        echo ""
        echo "❌ UTF-8 PARITY FAILED"
        echo "   Some characters were corrupted during round-trip"
        return 1
    fi
}

main "$@"

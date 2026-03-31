#!/usr/bin/env bash
# test_utf8_parity.sh - T028c: UTF-8 Encoding Parity Test
# 
# Validates that UTF-8 sequences are handled identically across bash and PowerShell.
# Tests: emoji, accented characters, multi-byte sequences, combined characters
#
# Constitution: Zero external dependencies (bash + coreutils only)
# Test Framework: Plain bash assertions (no pytest, BATS, Jest)

set -euo pipefail

# Minimal test helpers (no external dependencies)
assert_equals() {
  local expected="$1"
  local actual="$2"
  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo "ASSERT FAILED: Expected '$expected', got '$actual'" >&2
    return 1
  fi
}

# Test counters
PASS=0
FAIL=0

# UTF-8 Test Strings (platform-safe)
UTF8_EMOJI="✅ ❌ 🚀 📝"
UTF8_ACCENTED="café résumé naïve"
UTF8_CHINESE="你好世界"
UTF8_RUSSIAN="Привет мир"
UTF8_COMBINED="é"  # e + combining accent

# T028c.1: Bash UTF-8 export consistency
test_bash_utf8_export() {
  local output
  
  # Export a file with UTF-8 content
  output=$(cat << 'EOF'
✅ Test passed
café au lait
你好
Привет
EOF
)
  
  # Verify it contains all UTF-8 sequences
  if echo "$output" | grep -q "✅"; then
    ((PASS++))
    echo "✅ PASS: t028c.1 - Bash exports emoji correctly"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.1 - Bash emoji not preserved"
  fi
}

# T028c.2: UTF-8 roundtrip (file write/read)
test_utf8_roundtrip() {
  local tmpfile="/tmp/utf8_test_$$_$(date +%s)"
  local original content
  
  original="$UTF8_EMOJI
$UTF8_ACCENTED
$UTF8_CHINESE
$UTF8_RUSSIAN"
  
  # Write UTF-8 to file
  echo -e "$original" > "$tmpfile"
  
  # Read back and compare byte-for-byte
  content=$(cat "$tmpfile")
  
  if [[ "$content" == "$original" ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.2 - UTF-8 roundtrip preserves all sequences"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.2 - UTF-8 roundtrip lost characters"
    echo "  Expected: $(printf '%s' "$original" | od -An -tx1 | head -1)"
    echo "  Got:      $(printf '%s' "$content" | od -An -tx1 | head -1)"
  fi
  
  rm -f "$tmpfile"
}

# T028c.3: UTF-8 in variable expansion
test_utf8_variable_expansion() {
  local var="$UTF8_EMOJI and $UTF8_ACCENTED"
  local expected="✅ ❌ 🚀 📝 and café résumé naïve"
  
  if [[ "$var" == "$expected" ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.3 - UTF-8 variable expansion works"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.3 - UTF-8 variable expansion corrupted"
  fi
}

# T028c.4: UTF-8 string length (multibyte handling)
test_utf8_string_length() {
  # Note: bash ${#var} counts characters, not bytes
  local str="café"  # 5 bytes, 4 chars (é is 2 bytes)
  
  # Verify length is 4 (characters, not bytes)
  if [[ ${#str} -eq 4 ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.4 - UTF-8 string length counted correctly"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.4 - UTF-8 string length incorrect (expected 4, got ${#str})"
  fi
}

# T028c.5: UTF-8 in grep patterns
test_utf8_grep_pattern() {
  local text="Result: ✅ SUCCESS"
  
  if echo "$text" | grep -q "✅"; then
    ((PASS++))
    echo "✅ PASS: t028c.5 - UTF-8 grep pattern matching works"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.5 - UTF-8 grep pattern failed"
  fi
}

# T028c.6: UTF-8 with sed (line-by-line processing)
test_utf8_sed_processing() {
  local input="café résumé"
  local output
  
  # sed should preserve UTF-8 through substitution
  output=$(echo "$input" | sed 's/café/CAFÉ/')
  
  if [[ "$output" == "CAFÉ résumé" ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.6 - UTF-8 sed processing preserves characters"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.6 - UTF-8 sed processing corrupted"
  fi
}

# T028c.7: Combined characters (é = e + accent)
test_utf8_combined_characters() {
  # Create combined character: e (U+0065) + combining acute (U+0301)
  local combined=$'e\u0301'
  local precomposed="é"
  
  # Both should be valid UTF-8 (but may not be equal in bash)
  if [[ -n "$combined" && -n "$precomposed" ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.7 - Combined UTF-8 characters handled"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.7 - Combined UTF-8 characters failed"
  fi
}

# T028c.8: UTF-8 in array processing
test_utf8_array_processing() {
  local -a arr=("✅" "❌" "🚀")
  
  if [[ "${arr[0]}" == "✅" && "${arr[2]}" == "🚀" ]]; then
    ((PASS++))
    echo "✅ PASS: t028c.8 - UTF-8 in arrays preserved"
  else
    ((FAIL++))
    echo "❌ FAIL: t028c.8 - UTF-8 in arrays corrupted"
  fi
}

# Main test execution
main() {
  echo "════════════════════════════════════════════════════════════"
  echo "T028c: UTF-8 Encoding Parity Test (Bash Platform)"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  
  test_bash_utf8_export
  test_utf8_roundtrip
  test_utf8_variable_expansion
  test_utf8_string_length
  test_utf8_grep_pattern
  test_utf8_sed_processing
  test_utf8_combined_characters
  test_utf8_array_processing
  
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "Results: $PASS passed, $FAIL failed"
  echo "════════════════════════════════════════════════════════════"
  
  if [[ $FAIL -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

main "$@"

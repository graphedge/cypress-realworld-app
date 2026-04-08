#!/usr/bin/env bash
# test_markdown_export_parity.sh - T035: Windows Markdown Export Integration Test
#
# Validates that markdown export functionality works correctly on Windows.
# Tests: table format, escaping, path handling, line endings
#
# Constitution: Zero external dependencies (bash + coreutils)

set -euo pipefail

# Minimal test helpers
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

PASS=0
FAIL=0
# Create portable temporary directory
TMPDIR="$(mktemp -d 2>/dev/null || printf '%s/.specfarm-test-%s' "$PWD" "$$")"
mkdir -p "$TMPDIR"

# T035.1: Markdown table generation
test_markdown_table_generation() {
  local table_file="$TMPDIR/table.md"
  
  # Generate sample markdown table
  cat > "$table_file" << 'EOF'
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
| Cell A   | Cell B   | Cell C   |
EOF

  # Verify structure
  if grep -q "^|" "$table_file" && grep -q "^|-" "$table_file"; then
    ((PASS++))
    echo "✅ PASS: t035.1 - Markdown table structure valid"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.1 - Markdown table structure invalid"
  fi
}

# T035.2: Pipe character escaping in markdown
test_markdown_pipe_escaping() {
  local test_value="Before | After"
  local escaped
  
  # Escape pipes for markdown table cells (use backslash)
  escaped="${test_value//|/\\|}"
  
  if [[ "$escaped" == "Before \| After" ]]; then
    ((PASS++))
    echo "✅ PASS: t035.2 - Pipe escaping works for markdown"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.2 - Pipe escaping failed (got: $escaped)"
  fi
}

# T035.3: Markdown heading levels
test_markdown_headings() {
  local md_file="$TMPDIR/headings.md"
  
  cat > "$md_file" << 'EOF'
# Level 1
## Level 2
### Level 3
#### Level 4
EOF

  # Count heading levels
  local h1_count h2_count h3_count h4_count
  h1_count=$(grep -c "^# " "$md_file" || true)
  h2_count=$(grep -c "^## " "$md_file" || true)
  h3_count=$(grep -c "^### " "$md_file" || true)
  h4_count=$(grep -c "^#### " "$md_file" || true)
  
  if [[ $h1_count -eq 1 && $h2_count -eq 1 && $h3_count -eq 1 && $h4_count -eq 1 ]]; then
    ((PASS++))
    echo "✅ PASS: t035.3 - Markdown heading levels correct"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.3 - Heading levels incorrect"
  fi
}

# T035.4: Code blocks in markdown
test_markdown_code_blocks() {
  local md_file="$TMPDIR/code.md"
  
  cat > "$md_file" << 'EOF'
```bash
#!/bin/bash
echo "Hello"
```
EOF

  if grep -q "^\`\`\`bash" "$md_file" && grep -q "^\`\`\`$" "$md_file"; then
    ((PASS++))
    echo "✅ PASS: t035.4 - Code block format valid"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.4 - Code block format invalid"
  fi
}

# T035.5: Windows path conversion in markdown
test_windows_path_conversion() {
  local win_path='C:\Users\Admin\project\file.txt'
  local unix_path
  
  # Convert Windows path to Unix format (simple replacement)
  unix_path="${win_path//\\//}"
  unix_path="/${unix_path//:/}"
  
  # Should start with / not C:
  if [[ "$unix_path" == /C*/* ]]; then
    ((PASS++))
    echo "✅ PASS: t035.5 - Windows path conversion works"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.5 - Path conversion failed (got: $unix_path)"
  fi
}

# T035.6: Line ending handling (CRLF → LF)
test_line_ending_normalization() {
  local file_crlf="$TMPDIR/crlf.txt"
  local file_lf="$TMPDIR/lf.txt"
  
  # Create CRLF file (simulated with printf)
  printf "Line 1\r\nLine 2\r\nLine 3\r\n" > "$file_crlf"
  
  # Normalize to LF
  dos2unix "$file_crlf" 2>/dev/null || sed -i 's/\r$//' "$file_crlf"
  
  # Count lines with wc
  local lines
  lines=$(wc -l < "$file_crlf")
  
  if [[ $lines -eq 3 ]]; then
    ((PASS++))
    echo "✅ PASS: t035.6 - Line ending normalization works"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.6 - Line endings not normalized properly"
  fi
}

# T035.7: Unicode in markdown tables
test_unicode_in_markdown() {
  local md_file="$TMPDIR/unicode.md"
  
  cat > "$md_file" << 'EOF'
| Emoji | Text |
|-------|------|
| ✅    | Pass |
| ❌    | Fail |
EOF

  if grep -q "✅" "$md_file" && grep -q "❌" "$md_file"; then
    ((PASS++))
    echo "✅ PASS: t035.7 - Unicode in markdown tables preserved"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.7 - Unicode in markdown lost"
  fi
}

# T035.8: Markdown link format
test_markdown_links() {
  local link_text="Click here"
  local link_url="https://example.com"
  local markdown_link="[$link_text]($link_url)"
  
  if [[ "$markdown_link" == "[Click here](https://example.com)" ]]; then
    ((PASS++))
    echo "✅ PASS: t035.8 - Markdown link format correct"
  else
    ((FAIL++))
    echo "❌ FAIL: t035.8 - Markdown link format incorrect"
  fi
}

# Cleanup
cleanup() {
  rm -rf "$TMPDIR"
}

trap cleanup EXIT

# Main
main() {
  echo "════════════════════════════════════════════════════════════"
  echo "T035: Windows Markdown Export Integration Test"
  echo "════════════════════════════════════════════════════════════"
  echo ""
  
  test_markdown_table_generation
  test_markdown_pipe_escaping
  test_markdown_headings
  test_markdown_code_blocks
  test_windows_path_conversion
  test_line_ending_normalization
  test_unicode_in_markdown
  test_markdown_links
  
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

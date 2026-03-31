#!/usr/bin/env bash
# test_commit_cache.sh - T038a: Commit Cache Prototype Test
#
# Purpose: Verify the basic caching behavior proposed for gather-rules-agent:
# - Create cache (.specfarm/.rule-cache/commits.log) on first run
# - Detect and append only new commits on subsequent runs
# - Invalidate cache when rules.xml mtime changes
#
# Constitution: Plain bash only (no external frameworks)

set -euo pipefail

PASS=0
FAIL=0

# Simple assert helper
assert() {
  if ! eval "$1"; then
    echo "❌ ASSERT FAIL: $2" >&2
    ((FAIL++))
  else
    echo "✅ ASSERT PASS: $2"
    ((PASS++))
  fi
}

commit_cache_prototype() {
  # Lightweight prototype of cache behavior; operates in current dir (repo root)
  local CACHE_DIR=".specfarm/.rule-cache"
  local CACHE_FILE="$CACHE_DIR/commits.log"
  local RULES_FILE="rules.xml"

  mkdir -p "$CACHE_DIR"

  local current_rules_mtime="0"
  if [[ -f "$RULES_FILE" ]]; then
    current_rules_mtime=$(stat -c %Y "$RULES_FILE")
  fi

  local cache_exists=false
  local stored_rules_mtime=""
  local last_cached_sha=""

  if [[ -f "$CACHE_FILE" ]]; then
    cache_exists=true
    stored_rules_mtime=$(grep '^rules_mtime=' "$CACHE_FILE" || true | head -n1 | cut -d'=' -f2)
    last_cached_sha=$(grep '^last_cached_sha=' "$CACHE_FILE" || true | head -n1 | cut -d'=' -f2)
    if [[ -z "$last_cached_sha" ]]; then cache_exists=false; fi
    if [[ -n "$stored_rules_mtime" && "$current_rules_mtime" != "$stored_rules_mtime" ]]; then
      echo "INVALIDATING CACHE: rules_mtime $stored_rules_mtime -> $current_rules_mtime"
      rm -f "$CACHE_FILE"
      cache_exists=false
    fi
  fi

  if [[ "$cache_exists" == false ]]; then
    local head_sha
    head_sha=$(git rev-parse HEAD 2>/dev/null || true)
    echo "last_cached_sha=$head_sha" > "$CACHE_FILE"
    echo "rules_mtime=$current_rules_mtime" >> "$CACHE_FILE"
    echo "NEW_CACHE_CREATED last_cached_sha=$head_sha"
    return 0
  fi

  # We have a cache; find commits since last_cached_sha
  local new_commits=""
  if git rev-parse "$last_cached_sha" >/dev/null 2>&1; then
    new_commits=$(git rev-list --reverse ${last_cached_sha}..HEAD 2>/dev/null || true)
  else
    new_commits=$(git rev-list --reverse HEAD 2>/dev/null || true)
  fi

  if [[ -z "$new_commits" ]]; then
    echo "NO_NEW_COMMITS"
    return 0
  fi

  echo "FOUND_NEW_COMMITS"
  for sha in $new_commits; do
    echo "$sha $(date +%s)" >> "$CACHE_FILE"
  done
  # update last_cached_sha to HEAD
  sed -i "s/^last_cached_sha=.*/last_cached_sha=$(git rev-parse HEAD)/" "$CACHE_FILE" || true
  echo "$new_commits"
  return 0
}

# TEST: Use a temp repo
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
pushd "$TMPDIR" >/dev/null

# Initialize repo
git init -q
git config user.email "specfarm-test@example.com"
git config user.name "SpecFarm Test"

# Create rules.xml and initial file
cat > rules.xml <<'XML'
<rules>
  <rule id="R1">initial</rule>
</rules>
XML

echo "echo hello" > script.sh
git add -A
git commit -q -m "initial commit"

# 1) First run: should create cache
out1=$(commit_cache_prototype)
assert '[[ "$out1" == *"NEW_CACHE_CREATED"* ]]' "Initial cache created"

# Validate cache file exists and contains last_cached_sha
assert '[[ -f .specfarm/.rule-cache/commits.log ]]' "Cache file created"
last_sha_cached=$(grep '^last_cached_sha=' .specfarm/.rule-cache/commits.log | cut -d'=' -f2)
head_sha=$(git rev-parse HEAD)
assert '[[ "$last_sha_cached" == "$head_sha" ]]' "Cached last_cached_sha == HEAD after initial run"

# 2) Make a new commit and ensure the prototype detects new commit
echo "echo more" >> script.sh
git add script.sh
git commit -q -m "second commit"
second_sha=$(git rev-parse HEAD)
out2=$(commit_cache_prototype)
assert '[[ "$out2" == *"FOUND_NEW_COMMITS"* ]]' "Found new commits after second commit"
# Ensure commit appended to cache
grep -q "$second_sha" .specfarm/.rule-cache/commits.log || { echo "Missing new commit in cache" >&2; ((FAIL++)); }

# 3) Touch rules.xml to simulate update -> cache invalidation
sleep 1
echo "<!-- updated -->" >> rules.xml
out3=$(commit_cache_prototype)
# After invalidation, the prototype creates a new cache
assert '[[ "$out3" == *"NEW_CACHE_CREATED"* || "$out3" == *"INVALIDATING CACHE"* ]]' "Cache invalidated and re-created on rules.xml change"

# Final assertions
if [[ $FAIL -eq 0 ]]; then
  echo "T038a: Commit cache prototype tests PASSED (PASS=$PASS)"
  popd >/dev/null
  exit 0
else
  echo "T038a: Commit cache prototype tests FAILED (PASS=$PASS, FAIL=$FAIL)" >&2
  popd >/dev/null
  exit 2
fi

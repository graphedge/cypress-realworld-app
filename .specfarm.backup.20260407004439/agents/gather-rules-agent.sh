#!/bin/bash
#
# Generic Rules Gathering Agent
# Scans recent commits in any git repository and generates XML rules
# Agnostic to project structure — parameterizable for any codebase
#
# Usage:
#   ./gather-rules-agent.sh [OPTIONS]
#
# Options:
#   -r, --repo PATH              Repository root (default: current directory)
#   -c, --commit-range RANGE     Git commit range (default: HEAD~20..HEAD)
#   -s, --schema PATH            Path to XSD schema (default: rules-schema.xsd)
#   -o, --output FILE            Output file path (default: gathered-rules.md)
#   -n, --num-rules NUM          Maximum rules to generate (default: 20)
#   -p, --prefix PREFIX          Rule ID prefix (default: auto-detect or 'rule')
#   --scan-dirs DIRS             Directories to scan (comma-separated, default: auto-detect)
#   --exclude-dirs DIRS          Directories to exclude (comma-separated)
#   --task-context DESC          Task context mode: generate compact rule context for task
#   --scan-tests                 Exhaustive test scan (remove 20-file limit)
#   --size tiny|default          Output size: tiny (~100 tokens), default (~200 tokens)
#   --audit-duplicates           Scan rules.xml for similar/duplicate rules and suggest merges
#   --dup-threshold NUM          Similarity threshold % for duplication flag (default: 60)
#   -h, --help                   Show this help message
#
# Environment Variables:
#   RULES_XML_PATH              Override rules.xml path (default: .specfarm/rules.xml)
#   XMLLINT_CMD                 Override xmllint path (default: xmllint)
#
# Examples:
#   # Scan last 20 commits in current repo
#   ./gather-rules-agent.sh
#
#   # Task-context mode: get rules for a specific task
#   ./gather-rules-agent.sh --task-context "Fix bash arithmetic in test_drift.sh"
#
#   # Exhaustive test scan with tiny output
#   ./gather-rules-agent.sh --scan-tests --size tiny
#
#   # Use in different repo with custom rules.xml path
#   RULES_XML_PATH=/custom/path/rules.xml ./gather-rules-agent.sh --task-context "..."

set -euo pipefail

# ============================================================================
# Configuration & Defaults
# ============================================================================

REPO_ROOT="${PWD}"
COMMIT_RANGE="HEAD~20..HEAD"
SCHEMA_FILE="${REPO_ROOT}/rules-schema.xsd"
OUTPUT_FILE="${REPO_ROOT}/gathered-rules.md"
MAX_RULES=20
RULE_PREFIX=""
SCAN_DIRS=""
EXCLUDE_DIRS="third-party,build,config,.github,node_modules,venv,__pycache__,.git,.specfarm"

# Rules XML configuration (FR-010 fix)
RULES_XML_PATH="${RULES_XML_PATH:-.specfarm/rules.xml}"
XMLLINT_CMD="${XMLLINT_CMD:-xmllint}"

# New Task-Context Mode variables
TASK_CONTEXT_MODE=false
TASK_CONTEXT_DESC=""
SIZE_MODE="default"
SCAN_TESTS_MODE=false  # FR-011: --scan-tests flag

# Duplicate audit mode
AUDIT_DUPLICATES_MODE=false
DUPLICATION_THRESHOLD=60  # % Jaccard similarity to flag as potential duplicate

# Existing mode flags (per plan.md)
PR_CONTEXT_MODE=false
SCHEDULED_MODE=false
MARKDOWN_MODE=false
XML_MODE=false

# FR-017: --from-constitution flag
FROM_CONSTITUTION_MODE=false
CONSTITUTION_PATH="${CONSTITUTION_PATH:-.specify/memory/constitution.md}"

# FR-018: --append flag (write to rules.xml in place)
APPEND_MODE=false

# FR-019: --from-tests alongside --xml
FROM_TESTS_XML_MODE=false

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================================================
# Help & Argument Parsing
# ============================================================================

show_help() {
    grep '^#' "$0" | grep -E '^\s*#\s+(Usage|Options|Examples|  -|  \w)' | sed 's/^#//' | head -30
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)
                REPO_ROOT="$2"
                shift 2
                ;;
            -c|--commit-range)
                COMMIT_RANGE="$2"
                shift 2
                ;;
            -s|--schema)
                SCHEMA_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -n|--num-rules)
                MAX_RULES="$2"
                shift 2
                ;;
            -p|--prefix)
                RULE_PREFIX="$2"
                shift 2
                ;;
            --scan-dirs)
                SCAN_DIRS="$2"
                shift 2
                ;;
            --exclude-dirs)
                EXCLUDE_DIRS="$2"
                shift 2
                ;;
            --task-context|--task)
                TASK_CONTEXT_MODE=true
                TASK_CONTEXT_DESC="$2"
                shift 2
                ;;
            --scan-tests)
                SCAN_TESTS_MODE=true
                shift
                ;;
            --audit-duplicates)
                AUDIT_DUPLICATES_MODE=true
                shift
                ;;
            --dup-threshold)
                DUPLICATION_THRESHOLD="$2"
                shift 2
                ;;
            --size)
                SIZE_MODE="$2"
                shift 2
                ;;
            --pr-context)
                # Placeholder for existing mode (per plan.md)
                PR_CONTEXT_MODE=true
                shift
                ;;
            --scheduled)
                # Placeholder for existing mode (per plan.md)
                SCHEDULED_MODE=true
                shift
                ;;
            --markdown)
                # Placeholder for existing mode (per plan.md)
                MARKDOWN_MODE=true
                shift
                ;;
            --xml)
                # FR-016: XML mode (fixed dead-code bug)
                XML_MODE=true
                shift
                ;;
            --from-constitution)
                # FR-017: extract rules from constitution markdown
                FROM_CONSTITUTION_MODE=true
                if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
                    CONSTITUTION_PATH="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --from-tests)
                # FR-019: extract XML candidates from test files
                FROM_TESTS_XML_MODE=true
                SCAN_TESTS_MODE=true
                shift
                ;;
            --append)
                # FR-018: append generated rules to rules.xml in place
                APPEND_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

validate_args() {
    # Check for mode conflicts
    local modes_count=0
    [[ "$TASK_CONTEXT_MODE" == "true" ]] && ((modes_count++)) || :
    [[ "$PR_CONTEXT_MODE" == "true" ]] && ((modes_count++)) || :
    [[ "$SCHEDULED_MODE" == "true" ]] && ((modes_count++)) || :
    [[ "$MARKDOWN_MODE" == "true" ]] && ((modes_count++)) || :
    [[ "$XML_MODE" == "true" ]] && ((modes_count++)) || :
    [[ "$AUDIT_DUPLICATES_MODE" == "true" ]] && ((modes_count++)) || :
    
    if [[ $modes_count -gt 1 ]]; then
        log_error "Mode conflict: only one of --task-context, --pr-context, --scheduled, --markdown, --xml can be used."
        exit 1
    fi
    
    if [[ "$TASK_CONTEXT_MODE" == "true" ]] && [[ -z "$TASK_CONTEXT_DESC" ]]; then
        log_error "Missing task description for --task-context."
        exit 1
    fi
    
    # Validate task context size mode
    if [[ -n "$SIZE_MODE" ]] && [[ "$SIZE_MODE" != "default" ]] && [[ "$SIZE_MODE" != "tiny" ]]; then
        log_error "Invalid size mode: $SIZE_MODE (must be 'default' or 'tiny')"
        exit 1
    fi
}

# FR-010: Validate prerequisites (xmllint, rules.xml availability)
validate_prerequisites() {
    # Check xmllint availability
    if ! command -v "$XMLLINT_CMD" &> /dev/null; then
        log_error "xmllint not found. Please install libxml2 or set XMLLINT_CMD environment variable."
        return 1
    fi
    
    # Check rules.xml file exists
    if [[ ! -f "$RULES_XML_PATH" ]]; then
        log_error "rules.xml not found at: $RULES_XML_PATH"
        log_error "Set RULES_XML_PATH environment variable to override default location."
        return 1
    fi
    
    # Verify rules.xml is readable
    if [[ ! -r "$RULES_XML_PATH" ]]; then
        log_error "rules.xml is not readable: $RULES_XML_PATH"
        return 1
    fi
    
    # Validate rules.xml structure (parse as XML)
    if ! "$XMLLINT_CMD" --noout "$RULES_XML_PATH" 2>/dev/null; then
        log_error "rules.xml is malformed or corrupted: $RULES_XML_PATH"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Logging Functions
# ============================================================================

log_section() {
    echo -e "\n${GREEN}===${NC} ${BLUE}$1${NC} ${GREEN}===${NC}"
}

log_info() {
    echo -e "  ${YELLOW}[INFO]${NC} $1"
}

log_done() {
    echo -e "  ${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "  ${RED}[✗]${NC} $1" >&2
}

# ============================================================================
# Cache Management (T038) - Commit cache for rule discovery
# ============================================================================

# Cache directory and file (under repository root)
CACHE_DIR="${REPO_ROOT}/.specfarm/.rule-cache"
CACHE_FILE="${CACHE_DIR}/commits.log"

ensure_cache_dir() {
    mkdir -p "$CACHE_DIR"
}

get_rules_mtime() {
    if [[ -f "$RULES_XML_PATH" ]]; then
        stat -c %Y "$RULES_XML_PATH" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

load_cache_meta() {
    stored_rules_mtime=""
    last_cached_sha=""
    if [[ -f "$CACHE_FILE" ]]; then
        stored_rules_mtime=$(grep '^rules_mtime=' "$CACHE_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2 || echo "")
        last_cached_sha=$(grep '^last_cached_sha=' "$CACHE_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2 || echo "")
    fi
}

invalidate_cache_if_rules_changed() {
    local curr
    curr=$(get_rules_mtime)
    if [[ -n "$stored_rules_mtime" && "$stored_rules_mtime" != "$curr" ]]; then
        log_info "Invalidating commit cache: rules.xml mtime changed ($stored_rules_mtime -> $curr)"
        rm -f "$CACHE_FILE" || true
        stored_rules_mtime=""
        last_cached_sha=""
    fi
}

update_commit_cache() {
    ensure_cache_dir
    local curr_mtime
    curr_mtime=$(get_rules_mtime)

    if [[ ! -f "$CACHE_FILE" ]]; then
        local head_sha
        head_sha=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)
        echo "last_cached_sha=$head_sha" > "$CACHE_FILE"
        echo "rules_mtime=$curr_mtime" >> "$CACHE_FILE"
        log_info "Created commit cache (last_cached_sha=$head_sha)"
        return 0
    fi

    load_cache_meta
    invalidate_cache_if_rules_changed

    if [[ -z "$last_cached_sha" ]]; then
        local head_sha
        head_sha=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)
        echo "last_cached_sha=$head_sha" > "$CACHE_FILE"
        echo "rules_mtime=$curr_mtime" >> "$CACHE_FILE"
        log_info "Re-created commit cache (last_cached_sha=$head_sha)"
        return 0
    fi

    local new_commits
    if git -C "$REPO_ROOT" rev-parse "$last_cached_sha" >/dev/null 2>&1; then
        new_commits=$(git -C "$REPO_ROOT" rev-list --reverse ${last_cached_sha}..HEAD 2>/dev/null || true)
    else
        new_commits=$(git -C "$REPO_ROOT" rev-list --reverse HEAD 2>/dev/null || true)
    fi

    if [[ -z "$new_commits" ]]; then
        log_info "No new commits to append to cache (last_cached_sha=$last_cached_sha)"
        return 0
    fi

    for sha in $new_commits; do
        echo "$sha $(date +%s)" >> "$CACHE_FILE"
    done
    sed -i "s/^last_cached_sha=.*/last_cached_sha=$(git -C \"$REPO_ROOT\" rev-parse HEAD)/" "$CACHE_FILE" || true
    log_info "Appended $(echo "$new_commits" | wc -w) commits to cache"
}

init_commit_cache_if_needed() {
    if [[ "$TASK_CONTEXT_MODE" == "true" || "$SCAN_TESTS_MODE" == "true" ]]; then
        update_commit_cache
    fi
}

# ============================================================================
# Task-Context Mode (NEW)
# ============================================================================

extract_task_keywords() {
    local task_desc="$1"
    
    # Extract file paths (*.sh, src/*, tests/*, etc.)
    local files=$(echo "$task_desc" | grep -oE '[a-zA-Z0-9_/.-]+\.(sh|py|js|ts|xml|md)' || echo "")
    
    # Extract test patterns (test_*, describe, it() - simplified for bash)
    local test_patterns=$(echo "$task_desc" | grep -oE 'test_[a-zA-Z0-9_]+' || echo "")
    
    # Extract directories (tests/, src/, specs/, lib/)
    local dirs=$(echo "$task_desc" | grep -oE '(tests?|src|specs?|lib)/[a-zA-Z0-9_/-]*' || echo "")
    
    # Extract key action verbs (fix, implement, add, refactor, update, create, test)
    local actions=$(echo "$task_desc" | grep -oEi '\b(fix|implement|add|refactor|update|create|test)\b' || echo "")
    
    # NEW: Extract Constitution references (case-insensitive)
    # Pattern: "Constitution II.A", "Constitution", "constitutional"
    local constitution_refs=$(echo "$task_desc" | grep -oEi '\b(constitution|constitutional)\b' || echo "")
    if echo "$task_desc" | grep -qi "Constitution.*II\.A\|zero.depend"; then
        constitution_refs="$constitution_refs zero-dependency"
    fi
    
    # NEW: Extract task-context mode keywords
    local task_context_keywords=$(echo "$task_desc" | grep -oEi '\b(task.context|task-context|--task-context|TASK_CONTEXT)\b' || echo "")
    if echo "$task_desc" | grep -qi "task.context.*mode\|compact.*output.*format"; then
        task_context_keywords="$task_context_keywords task-mode"
    fi
    
    # NEW: Extract confidence scoring keywords
    local confidence_keywords=$(echo "$task_desc" | grep -oEi '\b(confidence|scoring|calculate.*confidence)\b' || echo "")
    if echo "$task_desc" | grep -qi "confidence.*scor\|scor.*algorithm"; then
        confidence_keywords="$confidence_keywords confidence-algorithm"
    fi
    
    # NEW: Extract cross-platform keywords
    local crossplatform_keywords=""
    if echo "$task_desc" | grep -qi "line.ending\|CRLF\|LF.*CR\|\\\\r\\\\n"; then
        crossplatform_keywords="$crossplatform_keywords line-endings CRLF"
    fi
    if echo "$task_desc" | grep -qi "path.*normaliz\|Windows.*path\|/c/\|C:\\\\"; then
        crossplatform_keywords="$crossplatform_keywords path-normalize windows-path"
    fi
    if echo "$task_desc" | grep -qi "PowerShell\|pwsh\|\.ps1"; then
        crossplatform_keywords="$crossplatform_keywords powershell pwsh"
    fi
    if echo "$task_desc" | grep -qi "cross.platform\|Windows.*Unix\|Unix.*Windows"; then
        crossplatform_keywords="$crossplatform_keywords cross-platform"
    fi
    
    # NEW: Extract test framework antipatterns (to catch zero-dependency violations)
    local test_framework_keywords=""
    if echo "$task_desc" | grep -qi "pytest\|BATS\|Jest\|mocha\|jasmine"; then
        test_framework_keywords="external-test-framework"
    fi
    if echo "$task_desc" | grep -qi "pure.*bash\|plain.*bash\|no.*external.*depend"; then
        test_framework_keywords="$test_framework_keywords bash-only"
    fi
    
    # Extract vibe names
    local vibe_keywords=""
    if echo "$task_desc" | grep -qi "farm\|jungle\|strict.engineer\|chill\|corporate\|sarcastic\|plain.*vibe\|get_nudge\|vibe.*tone"; then
        vibe_keywords=$(echo "$task_desc" | grep -oEi '\b(farm|jungle|strict|chill|corporate|sarcastic|plain)\b' || echo "")
        vibe_keywords="$vibe_keywords vibe-tone"
    fi
    
    # Extract drift-score keywords
    local drift_score_keywords=""
    if echo "$task_desc" | grep -qi "drift.score\|drift.*formula\|violated.*rule\|score.*formula"; then
        drift_score_keywords="drift-score drift-formula"
    fi
    
    # Extract nudge/threshold keywords
    local nudge_keywords=""
    if echo "$task_desc" | grep -qi "nudge\|whisper\|threshold\|0\.5\|0\.9\|green.*score"; then
        nudge_keywords="nudge-threshold whisper-threshold"
    fi
    
    # Extract error-memory keywords
    local error_memory_keywords=""
    if echo "$task_desc" | grep -qi "error.memory\|writer\.sh\|dedup\|idempotent.*error\|error.*category"; then
        error_memory_keywords="error-memory error-dedup"
    fi
    
    # Extract plugin keywords
    local plugin_keywords=""
    if echo "$task_desc" | grep -qi "plugin\|manifest\|plugin\.json\|sandbox\|specfarm.plugin"; then
        plugin_keywords="plugin-manifest plugin-sandbox"
    fi
    
    # Combine all keywords, deduplicate, and return
    echo "$files $test_patterns $dirs $actions $constitution_refs $task_context_keywords $confidence_keywords $crossplatform_keywords $test_framework_keywords $vibe_keywords $drift_score_keywords $nudge_keywords $error_memory_keywords $plugin_keywords" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

search_rules_xpath() {
    local keywords="$1"
    local rules_xml_file="${RULES_XML_PATH:-./rules.xml}" # Use global or default to ./rules.xml
    local xmllint_cmd="${XMLLINT_CMD:-xmllint}"            # Allow override for testing

    if ! command -v "$xmllint_cmd" &> /dev/null; then
        log_error "xmllint is required for XPath queries but not found. Please install libxml2-utils (Debian/Ubuntu) or libxml2 (macOS)."
        return 1
    fi

    # Build XPath query using local-name() to handle default XML namespaces
    local xpath_query="//*[local-name()='rule']["
    local first_keyword=true
    for keyword in $keywords; do
        if [[ "$first_keyword" == "true" ]]; then
            xpath_query+="contains(*[local-name()='name'], '$keyword') or contains(*[local-name()='description'], '$keyword') or contains(*[local-name()='scope'], '$keyword') or contains(*[local-name()='metadata']/*[local-name()='source'], '$keyword')"
            first_keyword=false
        else
            xpath_query+=" or contains(*[local-name()='name'], '$keyword') or contains(*[local-name()='description'], '$keyword') or contains(*[local-name()='scope'], '$keyword') or contains(*[local-name()='metadata']/*[local-name()='source'], '$keyword')"
        fi
    done
    
    # NEW: If keywords include category markers, boost search for related rule categories
    # This helps find rules that might not exact-match keywords but are in the same domain
    if echo "$keywords" | grep -qi "constitution\|zero-dependency"; then
        xpath_query+=" or contains(@category, 'testing') or contains(@category, 'constitution')"
    fi
    if echo "$keywords" | grep -qi "task-context\|task-mode"; then
        xpath_query+=" or contains(@category, 'agent') or contains(*[local-name()='name'], 'task')"
    fi
    if echo "$keywords" | grep -qi "confidence\|scoring"; then
        xpath_query+=" or contains(*[local-name()='name'], 'confidence') or contains(*[local-name()='name'], 'scoring')"
    fi
    if echo "$keywords" | grep -qi "line-endings\|CRLF\|path-normalize\|cross-platform"; then
        xpath_query+=" or contains(@category, 'cross-platform') or contains(@phase, '3b')"
    fi
    if echo "$keywords" | grep -qi "vibe-tone\|farm\|jungle\|strict\|chill\|corporate\|sarcastic"; then
        xpath_query+=" or contains(@category, 'vibe') or contains(*[local-name()='name'], 'vibe') or contains(*[local-name()='name'], 'Nudge')"
    fi
    if echo "$keywords" | grep -qi "drift-score\|drift-formula"; then
        xpath_query+=" or contains(*[local-name()='name'], 'Drift Score') or contains(*[local-name()='description'], 'violated_rules')"
    fi
    if echo "$keywords" | grep -qi "nudge-threshold\|whisper-threshold"; then
        xpath_query+=" or contains(*[local-name()='name'], 'Threshold') or contains(*[local-name()='name'], 'Nudge')"
    fi
    if echo "$keywords" | grep -qi "plugin-manifest\|plugin-sandbox"; then
        xpath_query+=" or contains(@category, 'plugin') or contains(*[local-name()='name'], 'Plugin')"
    fi
    if echo "$keywords" | grep -qi "error-memory\|error-dedup"; then
        xpath_query+=" or contains(*[local-name()='name'], 'Error Memory') or contains(*[local-name()='description'], 'dedup')"
    fi
    
    xpath_query+="]"

    # Execute XPath query against rules.xml and extract rule IDs
    # Use xmllint to extract IDs, handle potential errors
    local xml_output
    xml_output=$("$xmllint_cmd" --xpath "$xpath_query" "$rules_xml_file" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        # Exit code 10 = "XPath set is empty" (no matches) — not an error
        if echo "$xml_output" | grep -q "XPath set is empty"; then
            echo ""
            return 0
        fi
        log_error "XPath query failed for keywords: '$keywords'"
        return 1
    fi

    # Extract rule IDs from the XML output. Assumes rule IDs are in 'id' attribute.
    echo "$xml_output" | grep -o 'id="[^"]*"' | sed 's/id="//;s/"//'
}

# ============================================================================
# Confidence Scoring (T010)
# ============================================================================

calculate_confidence() {
    local rule_id="$1"
    local keywords="${2:-}"
    local rules_xml="${RULES_XML_PATH:-./rules.xml}"
    local xmllint_cmd="${XMLLINT_CMD:-xmllint}"
    local score=0

    # Get commit log (COMMIT_LOG_OVERRIDE allows injection for testing)
    local commit_log
    if [[ -n "${COMMIT_LOG_OVERRIDE:-}" ]]; then
        commit_log="$COMMIT_LOG_OVERRIDE"
    else
        commit_log=$(git log "HEAD~20..HEAD" --format="%an %H %s" --grep="$rule_id" 2>/dev/null || echo "")
    fi

    # +30 points base: rule mentioned in at least one recent commit
    # +5 points per commit (capped at 5 commits → +25 max)
    if [[ -n "$commit_log" ]]; then
        local commit_count
        commit_count=$(echo "$commit_log" | grep -c '.' || echo 0)
        score=$((score + 30))
        local per_commit_bonus=$(( commit_count < 5 ? commit_count : 5 ))
        score=$((score + per_commit_bonus * 5))

        # +10 points: referenced by 2+ different authors
        local author_count
        author_count=$(echo "$commit_log" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')
        [[ "$author_count" -ge 2 ]] && score=$((score + 10))
    fi

    # +20 points: rule has test_link in metadata
    local test_link_output
    test_link_output=$("$xmllint_cmd" --xpath \
        "//*[local-name()='rule'][@id='$rule_id']/*[local-name()='metadata']/*[local-name()='test_link']" \
        "$rules_xml" 2>/dev/null || echo "")
    [[ -n "$test_link_output" ]] && score=$((score + 20))

    # +20 points: rule has constitution reference in metadata
    local const_ref
    const_ref=$("$xmllint_cmd" --xpath \
        "//*[local-name()='rule'][@id='$rule_id']/*[local-name()='metadata']/*[local-name()='note']" \
        "$rules_xml" 2>/dev/null | grep -i "Constitution" || echo "")
    [[ -n "$const_ref" ]] && score=$((score + 20))

    # +15 points per keyword match in rule name/description
    if [[ -n "$keywords" ]]; then
        local rule_text
        rule_text=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null || echo "")
        for kw in $keywords; do
            echo "$rule_text" | grep -qi "$kw" && score=$((score + 15)) || true
        done
    fi
    
    # NEW: +25 points for Constitution II.A references (zero-dependency testing)
    if echo "$keywords" | grep -qi "constitution\|zero-dependency\|bash-only"; then
        local const_match
        const_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "Constitution\|zero.*depend\|pure.*bash" || echo "")
        [[ -n "$const_match" ]] && score=$((score + 25))
    fi
    
    # NEW: +20 points for task-context mode references
    if echo "$keywords" | grep -qi "task.context\|task-mode\|--task-context"; then
        local task_context_match
        task_context_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "task.*context\|compact.*output\|flag.*parsing" || echo "")
        [[ -n "$task_context_match" ]] && score=$((score + 20))
    fi
    
    # NEW: +20 points for confidence scoring algorithm references
    if echo "$keywords" | grep -qi "confidence\|scoring\|confidence-algorithm"; then
        local confidence_match
        confidence_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "confidence.*scor\|scor.*algorithm" || echo "")
        [[ -n "$confidence_match" ]] && score=$((score + 20))
    fi
    
    # NEW: +15 points for cross-platform line endings references
    if echo "$keywords" | grep -qi "line-endings\|CRLF\|line.*ending"; then
        local line_ending_match
        line_ending_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "line.*ending\|CRLF\|LF.*CR" || echo "")
        [[ -n "$line_ending_match" ]] && score=$((score + 15))
    fi
    
    # NEW: +15 points for cross-platform path normalization references
    if echo "$keywords" | grep -qi "path-normalize\|windows-path\|path.*normaliz"; then
        local path_match
        path_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "path.*normaliz\|Windows.*path\|/c/\|C:\\\\" || echo "")
        [[ -n "$path_match" ]] && score=$((score + 15))
    fi

    # NEW: +15 points for vibe/tone mapping references
    if echo "$keywords" | grep -qi "vibe-tone\|farm\|jungle\|strict\|chill\|corporate\|sarcastic"; then
        local vibe_match
        vibe_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "vibe\|nudge\|farm\|jungle" || echo "")
        [[ -n "$vibe_match" ]] && score=$((score + 15))
    fi

    # NEW: +15 points for drift score formula references
    if echo "$keywords" | grep -qi "drift-score\|drift-formula"; then
        local drift_score_match
        drift_score_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "drift.*score\|violated.*rule\|drift.*formula" || echo "")
        [[ -n "$drift_score_match" ]] && score=$((score + 15))
    fi

    # NEW: +15 points for plugin sandbox references
    if echo "$keywords" | grep -qi "plugin-manifest\|plugin-sandbox"; then
        local plugin_match
        plugin_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "plugin.*sandbox\|plugin.*manifest\|plugin.*constraint" || echo "")
        [[ -n "$plugin_match" ]] && score=$((score + 15))
    fi

    # NEW: +15 points for error memory references
    if echo "$keywords" | grep -qi "error-memory\|error-dedup"; then
        local error_memory_match
        error_memory_match=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null | grep -i "error.*memory\|dedup\|deduplication" || echo "")
        [[ -n "$error_memory_match" ]] && score=$((score + 15))
    fi

    # Cap at 100, floor at 0
    [[ $score -gt 100 ]] && score=100
    [[ $score -lt 0 ]] && score=0

    echo "$score"
}

# ============================================================================
# Compact Output Formatting (T011)
# ============================================================================

format_task_context_output() {
    local task_desc="$1"
    local ranked_rules="$2"   # space-separated "rule_id:score" pairs, highest first
    local evidence="$3"        # newline-separated "sha: message" entries
    local size_mode="${4:-default}"
    local rules_xml="${RULES_XML_PATH:-./rules.xml}"
    local xmllint_cmd="${XMLLINT_CMD:-xmllint}"

    local output=""
    output+="## Context for: ${task_desc}"$'\n\n'
    output+="### Applicable Rules"$'\n'

    for rule_entry in $ranked_rules; do
        local rule_id="${rule_entry%%:*}"
        local score="${rule_entry##*:}"
        local rule_name
        rule_name=$("$xmllint_cmd" --xpath \
            "string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name'])" \
            "$rules_xml" 2>/dev/null || echo "$rule_id")
        local rule_scope
        rule_scope=$("$xmllint_cmd" --xpath \
            "string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='scope'])" \
            "$rules_xml" 2>/dev/null || echo "global")
        output+="- **${rule_id}** (${score}% confidence): ${rule_name} [${rule_scope}]"$'\n'
    done

    output+=$'\n'"### Recent Evidence"$'\n'
    if [[ -n "$evidence" ]]; then
        echo "$evidence" | while IFS= read -r ev_line; do
            [[ -n "$ev_line" ]] && output+="- ${ev_line}"$'\n'
        done
        output+="$(echo "$evidence" | while IFS= read -r ev_line; do
            [[ -n "$ev_line" ]] && echo "- ${ev_line}"
        done)"$'\n'
    else
        output+="No recent evidence in commit history."$'\n'
    fi

    # Constitution reference — omitted in tiny mode
    if [[ "$size_mode" != "tiny" ]]; then
        local const_notes=""
        for rule_entry in $ranked_rules; do
            local rule_id="${rule_entry%%:*}"
            local note
            note=$("$xmllint_cmd" --xpath \
                "string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='metadata']/*[local-name()='note'])" \
                "$rules_xml" 2>/dev/null || echo "")
            [[ -n "$note" ]] && const_notes+="- ${note}"$'\n'
        done
        if [[ -n "$const_notes" ]]; then
            output+=$'\n'"### Constitution Reference"$'\n'"${const_notes}"
        fi
    fi

    # In tiny mode, trim output to fit ~100 token budget
    if [[ "$size_mode" == "tiny" ]]; then
        local tokens
        tokens=$(count_tokens_approx "$output" 2>/dev/null || echo "$output" | wc -w)
        if [[ "$tokens" -gt 120 ]]; then
            # Keep only first rule + evidence header in tiny mode
            local first_rule
            first_rule=$(echo "$ranked_rules" | awk '{print $1}')
            format_task_context_output "$task_desc" "$first_rule" "$evidence" "tiny_trimmed"
            return
        fi
    fi

    printf '%s' "$output"
}

# ============================================================================
# Project Detection
# ============================================================================

detect_project_name() {
    # Try to infer project name from various sources
    if [[ -f "${REPO_ROOT}/pyproject.toml" ]]; then
        grep '^name = ' "${REPO_ROOT}/pyproject.toml" 2>/dev/null | head -1 | sed 's/.*= "//; s/".*//' || echo "project"
    elif [[ -f "${REPO_ROOT}/package.json" ]]; then
        grep '"name"' "${REPO_ROOT}/package.json" 2>/dev/null | head -1 | sed 's/.*: "//; s/".*//' || echo "project"
    elif [[ -f "${REPO_ROOT}/Cargo.toml" ]]; then
        grep '^name = ' "${REPO_ROOT}/Cargo.toml" 2>/dev/null | head -1 | sed 's/.*= "//; s/".*//' || echo "project"
    elif [[ -d "${REPO_ROOT}/.git" ]]; then
        basename "$(git -C "${REPO_ROOT}" rev-parse --show-toplevel)" 2>/dev/null || echo "project"
    else
        basename "${REPO_ROOT}"
    fi
}

auto_detect_scan_dirs() {
    # Auto-detect directories based on common patterns
    local dirs=()
    
    [[ -d "${REPO_ROOT}/src" ]] && dirs+=("src")
    [[ -d "${REPO_ROOT}/tests" ]] && dirs+=("tests")
    [[ -d "${REPO_ROOT}/test" ]] && dirs+=("test")
    [[ -d "${REPO_ROOT}/specs" ]] && dirs+=("specs")
    [[ -d "${REPO_ROOT}/spec" ]] && dirs+=("spec")
    [[ -d "${REPO_ROOT}/lib" ]] && dirs+=("lib")
    [[ -d "${REPO_ROOT}/specs/prompts" ]] && dirs+=("specs/prompts")
    [[ -d "${REPO_ROOT}/docs" ]] && dirs+=("docs")
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        dirs=(".")
    fi
    
    echo "${dirs[@]}"
}

# ============================================================================
# Repository Analysis
# ============================================================================

scan_recent_commits() {
    log_section "Scanning Repository"
    
    cd "${REPO_ROOT}"
    
    log_info "Repository: $(pwd)"
    log_info "Commit range: ${COMMIT_RANGE}"
    
    if ! git rev-parse --verify "${COMMIT_RANGE%.*}" &>/dev/null; then
        log_warn "Commit range may not exist; using HEAD~10..HEAD as fallback"
        COMMIT_RANGE="HEAD~10..HEAD"
    fi
    
    local commit_count=$(git rev-list --count "${COMMIT_RANGE}" 2>/dev/null || echo "0")
    log_done "Found ${commit_count} commits in range"
    
    # Show recent commit subjects
    log_info "Recent commits:"
    git log --oneline "${COMMIT_RANGE}" 2>/dev/null | head -5 | sed 's/^/    /' || true
}

extract_changed_files() {
    log_section "Analyzing Changed Files"
    
    cd "${REPO_ROOT}"
    
    local changed_files
    changed_files=$(git diff --name-only "${COMMIT_RANGE}" 2>/dev/null | grep -E -v "^(node_modules|venv|\.git)" | head -30 || echo "")
    
    local file_count=$(echo "$changed_files" | wc -l)
    log_done "Analyzed ${file_count} changed files"
    
    echo "$changed_files"
}

find_test_files() {
    log_section "Locating Test Files"
    
    local exclude_pattern=$(echo "$EXCLUDE_DIRS" | sed 's/,/|/g')
    
    # FR-012: Remove head -20 limit when SCAN_TESTS_MODE is true
    local head_limit=20
    if [[ "$SCAN_TESTS_MODE" == "true" ]]; then
        head_limit=""  # No limit for exhaustive scan
    fi
    
    # Find test files in various patterns (FR-011: multi-directory scan)
    local tests=$(find "${REPO_ROOT}" \
        -type f \
        \( -name "*test*.sh" -o -name "*test*.py" -o -name "*.test.js" -o -name "*.spec.ts" \) \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        2>/dev/null)
    
    # Apply limit only if not in exhaustive mode
    if [[ -n "$head_limit" ]]; then
        tests=$(echo "$tests" | head -"$head_limit")
    fi
    
    local count=$(echo "$tests" | wc -l)
    if [[ "$SCAN_TESTS_MODE" == "true" ]]; then
        log_done "Found ${count} test files (exhaustive scan)"
    else
        log_done "Found ${count} test files (limited to $head_limit)"
    fi
    
    echo "$tests"
}

find_spec_files() {
    log_section "Locating Specification Files"
    
    # Find spec/documentation files
    local specs=$(find "${REPO_ROOT}" \
        -type f \
        \( -name "spec*.md" -o -name "*plan*.md" -o -name "tasks.md" -o -name "requirements.md" \) \
        ! -path "*/.git/*" \
        2>/dev/null | head -20)
    
    local count=$(echo "$specs" | wc -l)
    log_done "Found ${count} specification files"
    
    echo "$specs"
}

# ============================================================================
# Rule Generation
# ============================================================================

generate_rule_id() {
    local source="$1"
    local index="$2"
    
    # Extract meaningful name from source path
    local name=$(basename "$source" | sed 's/\.[^.]*$//' | tr '-' '_' | tr '[:upper:]' '[:lower:]')
    
    # Use provided prefix or auto-detect
    local prefix="${RULE_PREFIX}"
    if [[ -z "$prefix" ]]; then
        # Auto-detect from project structure (phase, version, etc.)
        if grep -q "phase.*3b" "${REPO_ROOT}"/specs/prompts/*.md 2>/dev/null; then
            prefix="phase3b"
        else
            prefix="$(detect_project_name | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
        fi
    fi
    
    printf "%s-%s-%04d" "$prefix" "$name" "$index"
}

# ============================================================================
# Duplication Detection
# ============================================================================

# duplication_check() — pure bash, no external deps beyond xmllint
# Compare a candidate rule (name + description) against all existing rules in
# rules.xml using Jaccard keyword overlap. Flags rules >= DUPLICATION_THRESHOLD %.
#
# Usage:
#   duplication_check "Candidate Name" "Candidate description text" ["category"]
#
# Returns:
#   0 — no duplicates found
#   1 — one or more potential duplicates found (details printed to stdout)
duplication_check() {
    local candidate_name="$1"
    local candidate_desc="$2"
    local skip_id="${3:-}"       # optional: rule ID to skip (prevents self-match in audits)
    local rules_xml="${RULES_XML_PATH:-.specfarm/rules.xml}"
    local xmllint_cmd="${XMLLINT_CMD:-xmllint}"
    local threshold="${DUPLICATION_THRESHOLD:-40}"

    if ! command -v "$xmllint_cmd" &>/dev/null; then
        log_warn "xmllint not available; skipping duplication check"
        return 0
    fi

    if [[ ! -f "$rules_xml" ]]; then
        log_warn "rules.xml not found at '$rules_xml'; skipping duplication check"
        return 0
    fi

    # Normalise candidate text to a sorted unique word list (min 4 chars)
    local candidate_words
    candidate_words=$(printf '%s %s' "$candidate_name" "$candidate_desc" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs 'a-z0-9-' '\n' \
        | awk 'length>=4' \
        | sort -u)

    local candidate_wc
    candidate_wc=$(printf '%s\n' "$candidate_words" | wc -l)

    if [[ "$candidate_wc" -eq 0 ]]; then
        return 0
    fi

    # Retrieve every rule id from the XML
    local all_ids
    all_ids=$("$xmllint_cmd" --xpath "//*[local-name()='rule']/@id" "$rules_xml" 2>/dev/null \
        | grep -o 'id="[^"]*"' | sed 's/id="//;s/"//')

    local duplicates_found=false
    local dup_output=""

    while IFS= read -r rule_id; do
        [[ -z "$rule_id" ]] && continue
        [[ -n "$skip_id" && "$rule_id" == "$skip_id" ]] && continue

        local existing_text
        existing_text=$("$xmllint_cmd" --xpath \
            "concat(string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name']), ' ', string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description']))" \
            "$rules_xml" 2>/dev/null || echo "")
        [[ -z "$existing_text" ]] && continue

        local existing_words
        existing_words=$(printf '%s\n' "$existing_text" \
            | tr '[:upper:]' '[:lower:]' \
            | tr -cs 'a-z0-9-' '\n' \
            | awk 'length>=4' \
            | sort -u)

        # Intersection size via comm (both inputs must be sorted — they are)
        local shared_count
        shared_count=$(comm -12 \
            <(printf '%s\n' "$candidate_words") \
            <(printf '%s\n' "$existing_words") \
            | wc -l)

        [[ "$shared_count" -eq 0 ]] && continue

        local existing_wc
        existing_wc=$(printf '%s\n' "$existing_words" | wc -l)
        local union_count=$(( candidate_wc + existing_wc - shared_count ))
        local similarity=0
        [[ "$union_count" -gt 0 ]] && similarity=$(( shared_count * 100 / union_count ))

        if [[ "$similarity" -ge "$threshold" ]]; then
            duplicates_found=true
            local shared_words
            shared_words=$(comm -12 \
                <(printf '%s\n' "$candidate_words") \
                <(printf '%s\n' "$existing_words") \
                | tr '\n' ' ')
            dup_output+="  ⚠ POSSIBLE DUPLICATE: ${rule_id} (${similarity}% similarity, ${shared_count} shared keywords)"$'\n'
            dup_output+="    Shared keywords: ${shared_words}"$'\n'
            dup_output+="    Suggestion: Review '${rule_id}' — consider merging or refining both rules"$'\n'
        fi
    done <<< "$all_ids"

    if [[ "$duplicates_found" == "true" ]]; then
        printf '%s' "$dup_output"
        return 1
    fi
    return 0
}

# audit_all_duplicates() — runs duplication_check for every rule in rules.xml
# against all other rules. Produces a full deduplication report.
audit_all_duplicates() {
    local rules_xml="${RULES_XML_PATH:-.specfarm/rules.xml}"
    local xmllint_cmd="${XMLLINT_CMD:-xmllint}"

    log_section "Duplicate Rule Audit"
    log_info "Threshold: ${DUPLICATION_THRESHOLD}% Jaccard similarity"
    log_info "Rules file: ${rules_xml}"

    if [[ ! -f "$rules_xml" ]]; then
        log_error "rules.xml not found: ${rules_xml}"
        return 1
    fi

    local all_ids
    all_ids=$("$xmllint_cmd" --xpath "//*[local-name()='rule']/@id" "$rules_xml" 2>/dev/null \
        | grep -o 'id="[^"]*"' | sed 's/id="//;s/"//')

    local total_rules=0
    local flagged_count=0

    while IFS= read -r rule_id; do
        [[ -z "$rule_id" ]] && continue
        total_rules=$((total_rules + 1))

        local rule_name
        rule_name=$("$xmllint_cmd" --xpath \
            "string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='name'])" \
            "$rules_xml" 2>/dev/null || echo "$rule_id")
        local rule_desc
        rule_desc=$("$xmllint_cmd" --xpath \
            "string(//*[local-name()='rule'][@id='$rule_id']/*[local-name()='description'])" \
            "$rules_xml" 2>/dev/null || echo "")

        local dup_result
        dup_result=$(RULES_XML_PATH="$rules_xml" XMLLINT_CMD="$xmllint_cmd" \
            DUPLICATION_THRESHOLD="$DUPLICATION_THRESHOLD" \
            duplication_check "$rule_name" "$rule_desc" "$rule_id" 2>/dev/null || true)

        if [[ -n "$dup_result" ]]; then
            echo ""
            echo "Rule: ${rule_id} — ${rule_name}"
            printf '%s\n' "$dup_result"
            flagged_count=$((flagged_count + 1))
        fi
    done <<< "$all_ids"

    echo ""
    log_section "Audit Summary"
    log_info "Total rules scanned: ${total_rules}"
    if [[ "$flagged_count" -gt 0 ]]; then
        log_warn "${flagged_count} rule(s) with potential duplicates — review suggestions above"
        log_info "Recommendation: Add --audit-duplicates to pre-commit workflow to catch these early"
    else
        log_done "No duplicate pairs found at ${DUPLICATION_THRESHOLD}% threshold"
    fi
}

extract_rule_candidates() {
    
    local rules_found=0
    local max_per_source=3
    
    # From test files - extract test names that could become rules
    log_info "Scanning test files for rule patterns..."
    find_test_files 2>/dev/null | while read -r test_file; do
        if [[ -n "$test_file" ]]; then
            grep -E "^\s*(def test_|function test_|it\(|describe\()" "$test_file" 2>/dev/null | head -$max_per_source | while read -r line; do
                echo "$line" | sed "s|^|  Source: $test_file: |"
            done || true
        fi
    done
    
    # From spec files - extract task/requirement headers
    log_info "Scanning specification files for rule patterns..."
    find_spec_files 2>/dev/null | while read -r spec_file; do
        if [[ -n "$spec_file" ]]; then
            grep -E "^#{1,4}\s+[A-Z].*:" "$spec_file" 2>/dev/null | head -$max_per_source | while read -r line; do
                echo "$line" | sed "s|^|  Source: $spec_file: |"
            done || true
        fi
    done
}

generate_xml_template() {
    local rule_id="$1"
    local title="$2"
    local description="$3"
    local source_file="$4"
    local category="${5:-generated}"

    cat << EOF
  <rule id="${rule_id}" enabled="true" severity="warn" phase="post-analysis" category="${category}">
    <name>${title}</name>
    <description>${description}</description>
    <scope>global</scope>
    <rationale>Extracted from commit analysis of: ${source_file}</rationale>
    <metadata>
      <source>${source_file}</source>
      <generated>true</generated>
    </metadata>
  </rule>
EOF
}

# ============================================================================
# XML Report Generation (FR-016, FR-017, FR-018, FR-019, FR-020)
# ============================================================================

# Check if a rule ID already exists in rules.xml (for deduplication, FR-018/FR-020)
rule_id_exists_in_xml() {
    local rule_id="$1"
    local xml_file="${2:-$RULES_XML_PATH}"
    [[ -f "$xml_file" ]] || return 1
    "$XMLLINT_CMD" --xpath "//*[local-name()='rule'][@id='${rule_id}']" "$xml_file" 2>/dev/null | grep -q "rule" && return 0
    return 1
}

# Slugify a string to a valid rule ID segment (lowercase, hyphens, no specials)
slugify_rule_id() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# FR-017: Extract rule candidates from a constitution markdown file.
# Finds section headings (##/###) followed by MUST/SHALL/MUST NOT language.
# Emits: rule_id TAB title TAB description TAB source_file
extract_constitution_rules() {
    local const_file="${1:-$CONSTITUTION_PATH}"
    [[ -f "$const_file" ]] || { log_warn "Constitution file not found: $const_file"; return 0; }

    local current_section=""
    local current_slug=""
    local section_lines=""
    local section_num=0

    while IFS= read -r line; do
        # New section heading (## or ###, skip # and ####+ )
        if echo "$line" | grep -qE '^#{2,3} '; then
            # Emit previous section if it had MUST/SHALL content
            if [[ -n "$current_section" && -n "$section_lines" ]]; then
                local must_line
                must_line=$(echo "$section_lines" | grep -iE '\bMUST\b|\bSHALL\b' | head -1 | sed 's/^[[:space:]]*//')
                if [[ -n "$must_line" ]]; then
                    local rule_id="const-${current_slug}"
                    printf '%s\t%s\t%s\t%s\n' \
                        "$rule_id" \
                        "$current_section" \
                        "$must_line" \
                        "$const_file"
                fi
            fi
            # Start new section
            current_section=$(echo "$line" | sed 's/^#*[[:space:]]*//')
            current_slug=$(slugify_rule_id "$current_section")
            # Append section number to ensure uniqueness when slug collides
            section_num=$((section_num + 1))
            [[ "$section_num" -gt 1 ]] && current_slug="${current_slug}-${section_num}" || true
            section_lines=""
        else
            section_lines="${section_lines}
${line}"
        fi
    done < "$const_file"

    # Emit final section
    if [[ -n "$current_section" && -n "$section_lines" ]]; then
        local must_line
        must_line=$(echo "$section_lines" | grep -iE '\bMUST\b|\bSHALL\b' | head -1 | sed 's/^[[:space:]]*//')
        if [[ -n "$must_line" ]]; then
            local rule_id="const-${current_slug}"
            printf '%s\t%s\t%s\t%s\n' \
                "$rule_id" \
                "$current_section" \
                "$must_line" \
                "$const_file"
        fi
    fi
}

# FR-019: Extract XML rule candidates from test files (test-derived category)
extract_test_derived_rules() {
    local prefix="${RULE_PREFIX:-test}"
    local count=0
    find_test_files 2>/dev/null | while read -r test_file; do
        [[ -n "$test_file" ]] || continue
        # Extract test function names and MUST/SHALL comments near them
        grep -n -E "^(t[0-9]+_[a-z_]+|function t[0-9]+)" "$test_file" 2>/dev/null | head -5 | while IFS=: read -r lineno func_line; do
            local func_name
            func_name=$(echo "$func_line" | grep -oE 't[0-9]+_[a-z_]+' | head -1)
            [[ -n "$func_name" ]] || continue
            # Look for MUST comment in surrounding lines
            local context
            context=$(sed -n "$((lineno > 3 ? lineno - 3 : 1)),$((lineno + 2))p" "$test_file" 2>/dev/null \
                | grep -iE '\bMUST\b|\bSHALL\b|# Rule\|# rule' | head -1 | sed 's/^[[:space:]#]*//')
            local title
            title=$(echo "$func_name" | sed 's/_/ /g; s/t[0-9]* //')
            local rule_id="${prefix}-$(slugify_rule_id "$func_name")"
            local desc="${context:-Enforces: $(echo "$func_name" | sed 's/_/ /g')}"
            printf '%s\t%s\t%s\t%s\n' "$rule_id" "$title" "$desc" "$test_file"
        done
    done
}

# FR-016 / FR-020: Generate a well-formed XML document of rule candidates.
# Sources: commit analysis candidates, optionally constitution (FR-017), optionally tests (FR-019).
# Writes to OUTPUT_FILE. Deduplicates against RULES_XML_PATH.
generate_xml_report() {
    log_section "Generating XML Rule Candidates"

    local tmpbody
    tmpbody=$(mktemp)

    # Source 1: constitution rules (FR-017)
    if [[ "$FROM_CONSTITUTION_MODE" == "true" ]]; then
        log_info "Extracting rules from constitution: $CONSTITUTION_PATH"
        local _const_candidates
        _const_candidates=$(extract_constitution_rules "$CONSTITUTION_PATH")
        while IFS=$'\t' read -r rule_id title desc source; do
            [[ -n "$rule_id" ]] || continue
            if rule_id_exists_in_xml "$rule_id"; then
                log_info "Skipping duplicate: $rule_id"
                continue
            fi
            generate_xml_template "$rule_id" "$title" "$desc" "$source" "constitution-derived" >> "$tmpbody"
        done <<< "$_const_candidates"
    fi

    # Source 2: test-derived rules (FR-019)
    if [[ "$FROM_TESTS_XML_MODE" == "true" ]]; then
        log_info "Extracting rules from test files..."
        local _raw_candidates
        _raw_candidates=$(extract_test_derived_rules)
        while IFS=$'\t' read -r rule_id title desc source; do
            [[ -n "$rule_id" ]] || continue
            if rule_id_exists_in_xml "$rule_id"; then
                log_info "Skipping duplicate: $rule_id"
                continue
            fi
            generate_xml_template "$rule_id" "$title" "$desc" "$source" "test-derived" >> "$tmpbody"
        done <<< "$_raw_candidates"
    fi

    # Source 3: commit-analysis candidates (always included in xml mode)
    if [[ "$FROM_CONSTITUTION_MODE" != "true" && "$FROM_TESTS_XML_MODE" != "true" ]]; then
        log_info "Extracting rules from commit analysis..."
        extract_rule_candidates 2>/dev/null | grep -v '^$' | head -"${MAX_RULES}" | while IFS= read -r candidate; do
            local slug
            slug=$(echo "$candidate" | cut -c1-40 | slugify_rule_id 2>/dev/null || echo "auto-$(date +%s)")
            local rule_id="${RULE_PREFIX:-gen}-${slug}"
            if rule_id_exists_in_xml "$rule_id"; then continue; fi
            generate_xml_template "$rule_id" "$(echo "$candidate" | cut -c1-60)" "$candidate" "${REPO_ROOT}" "generated" >> "$tmpbody"
        done
    fi

    # Wrap in XML document (FR-020)
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo "<!-- Generated by gather-rules-agent $(date -u +%Y-%m-%dT%H:%M:%SZ) -->"
        echo "<!-- Source: ${REPO_ROOT} -->"
        echo '<rules xmlns="http://specfarm.example.org/rules" version="1.0">'
        cat "$tmpbody"
        echo '</rules>'
    } > "${OUTPUT_FILE}"

    rm -f "$tmpbody"
    log_done "XML candidates written to: ${OUTPUT_FILE}"
}

# FR-018: Append generated rules into rules.xml before </rules>.
# Deduplicates: skips rule IDs already present.
append_rules_to_xml() {
    local rules_file="${RULES_XML_PATH}"
    [[ -f "$rules_file" ]] || { log_error "Cannot append: rules.xml not found at $rules_file"; return 1; }

    local tmpbody
    tmpbody=$(mktemp)

    # Collect new rules from same sources as generate_xml_report
    if [[ "$FROM_CONSTITUTION_MODE" == "true" ]]; then
        local _const_raw
        _const_raw=$(extract_constitution_rules "$CONSTITUTION_PATH")
        while IFS=$'\t' read -r rule_id title desc source; do
            [[ -n "$rule_id" ]] || continue
            if rule_id_exists_in_xml "$rule_id" "$rules_file"; then
                log_info "Skipping existing: $rule_id"
                continue
            fi
            generate_xml_template "$rule_id" "$title" "$desc" "$source" "constitution-derived" >> "$tmpbody"
        done <<< "$_const_raw"
    fi

    if [[ "$FROM_TESTS_XML_MODE" == "true" ]]; then
        local _tests_raw
        _tests_raw=$(extract_test_derived_rules)
        while IFS=$'\t' read -r rule_id title desc source; do
            [[ -n "$rule_id" ]] || continue
            if rule_id_exists_in_xml "$rule_id" "$rules_file"; then
                log_info "Skipping existing: $rule_id"
                continue
            fi
            generate_xml_template "$rule_id" "$title" "$desc" "$source" "test-derived" >> "$tmpbody"
        done <<< "$_tests_raw"
    fi

    if [[ ! -s "$tmpbody" ]]; then
        log_info "No new rules to append (all candidates already exist in rules.xml)"
        rm -f "$tmpbody"
        return 0
    fi

    # Insert new rules before closing </rules> tag
    local tmpxml
    tmpxml=$(mktemp)
    sed "s|</rules>|$(cat "$tmpbody" | sed 's/[&/\]/\\&/g; s/$/\\n/' | tr -d '\n')\n</rules>|" \
        "$rules_file" > "$tmpxml"

    # Validate the result is still XML-parseable
    if "$XMLLINT_CMD" --noout "$tmpxml" 2>/dev/null; then
        mv "$tmpxml" "$rules_file"
        log_done "Appended new rules to: $rules_file"
    else
        log_error "XML validation failed after append — rules.xml unchanged"
        rm -f "$tmpxml"
        rm -f "$tmpbody"
        return 1
    fi

    rm -f "$tmpbody"
}



generate_markdown_report() {
    local project_name=$(detect_project_name)
    local scan_dirs="${SCAN_DIRS:-$(auto_detect_scan_dirs | tr ' ' ',')}"
    
    log_section "Generating Report"
    
    cat > "${OUTPUT_FILE}" << REPORT_EOF
# Rules Gathering Report — ${project_name}

**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
**Repository**: ${REPO_ROOT}
**Commit Range**: ${COMMIT_RANGE}
**Maximum Rules**: ${MAX_RULES}
**Rule Prefix**: ${RULE_PREFIX:-auto}

---

## Execution Summary

### Environment
- **Project**: ${project_name}
- **Git Repository**: $(cd "${REPO_ROOT}" && git rev-parse --show-toplevel 2>/dev/null || echo "N/A")
- **Branch**: $(cd "${REPO_ROOT}" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
- **Schema**: $(basename "${SCHEMA_FILE}")

### Scan Configuration
- **Scan Directories**: ${scan_dirs}
- **Excluded Patterns**: ${EXCLUDE_DIRS}
- **Commit Range**: ${COMMIT_RANGE}

### Discovery Results

#### Changed Files
\`\`\`
$(extract_changed_files | head -15 | sed 's/^/  /')
\`\`\`

#### Test Files Found
$(find_test_files | sed 's/^/  /' | head -10)

#### Specification Files Found
$(find_spec_files | sed 's/^/  /' | head -10)

#### Rule Candidates Extracted
\`\`\`
$(extract_rule_candidates | head -20)
\`\`\`

---

## Integration Instructions

### Step 1: Review Extracted Candidates
Review the rule candidates above and identify which patterns should become formal XML rules.

### Step 2: Generate XML Rules
For each candidate, create a \`<rule>\` element following this template:

\`\`\`xml
<rule id="PREFIX-FEATURE-000N" enabled="true" severity="warn" phase="post-analysis">
  <name>Rule Title</name>
  <description>Detailed description of what this rule checks</description>
  <rationale>Link to source file or task that motivated this rule</rationale>
  <metadata>
    <source>Source file path</source>
    <test_link>tests/path/to/test.sh::test_name</test_link>
  </metadata>
</rule>
\`\`\`

### Step 3: Validate Against Schema
\`\`\`bash
xmllint --schema ${SCHEMA_FILE} rules.xml --noout
\`\`\`

### Step 4: Integrate into Project
Add generated rules to your project's \`rules.xml\` file (or equivalent).

---

## Next Steps

1. **Analyze Candidates**: Review extracted rule candidates above
2. **Create Rules**: Generate formal XML rule definitions
3. **Test**: Validate rules against schema (${SCHEMA_FILE})
4. **Commit**: Add rules to version control

---

## Report Metadata

- **Scan Date**: $(date -u +%Y-%m-%d)
- **Scan Time**: $(date -u +'%H:%M:%S UTC')
- **Report File**: ${OUTPUT_FILE}
- **Schema File**: ${SCHEMA_FILE}

For questions or issues, refer to the gather-rules-agent.sh script documentation.

REPORT_EOF

    log_done "Report generated: ${OUTPUT_FILE}"
}

# ============================================================================
# Validation
# ============================================================================

validate_environment() {
    log_section "Validating Environment"
    
    # Check repo root
    if [[ ! -d "${REPO_ROOT}/.git" ]]; then
        log_warn "Not a git repository: ${REPO_ROOT}"
        if [[ ! -d "${REPO_ROOT}" ]]; then
            log_error "Repository directory does not exist"
            return 1
        fi
    else
        log_done "Git repository detected"
    fi
    
    # Check schema (optional)
    if [[ ! -f "${SCHEMA_FILE}" ]]; then
        log_warn "Schema file not found: ${SCHEMA_FILE}"
        log_info "Continuing without schema validation"
    else
        log_done "Schema file found: $(basename "${SCHEMA_FILE}")"
    fi
    
    # Check output directory is writable
    local output_dir=$(dirname "${OUTPUT_FILE}")
    if [[ ! -w "$output_dir" ]]; then
        log_error "Output directory not writable: $output_dir"
        return 1
    fi
    log_done "Output directory writable: $output_dir"
    
    return 0
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${BLUE}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════╗
║     Generic Rules Gathering Agent                ║
║     Project-Agnostic Rule Discovery & Generation ║
╚══════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    
    # Parse arguments
    parse_args "$@"
    validate_args
    
    # FR-010: Validate prerequisites before any mode execution
    if ! validate_prerequisites; then
        exit 1
    fi

    # Audit-duplicates mode: scan rules.xml and report similar rule pairs
    if [[ "$AUDIT_DUPLICATES_MODE" == "true" ]]; then
        audit_all_duplicates
        return $?
    fi

    # Task-context mode: full T012 pipeline — keyword extraction → XPath search →
    # confidence scoring → ranked output → formatted context block
    if [[ "$TASK_CONTEXT_MODE" == "true" ]]; then
        local keywords
        keywords=$(extract_task_keywords "$TASK_CONTEXT_DESC")

        local matched_ids=""
        if [[ -n "$keywords" ]]; then
            matched_ids=$(search_rules_xpath "$keywords")
        fi

        if [[ -z "$matched_ids" ]]; then
            log_info "No matching rules found for task context."
            return 0
        fi

        # Score and rank each matched rule
        local ranked_rules=""
        while IFS= read -r rule_id; do
            [[ -z "$rule_id" ]] && continue
            local score
            score=$(calculate_confidence "$rule_id" "$keywords")
            ranked_rules+="${rule_id}:${score} "
        done <<< "$matched_ids"

        # Sort by confidence descending, take top 6
        ranked_rules=$(echo "$ranked_rules" | tr ' ' '\n' | grep -v '^$' \
            | sort -t: -k2 -rn | head -6 | tr '\n' ' ')

        # Gather brief evidence from recent commits
        local evidence=""
        evidence=$(git log "HEAD~10..HEAD" --format="%h: %s" 2>/dev/null | head -3 || echo "")

        # Format and emit context block
        format_task_context_output \
            "$TASK_CONTEXT_DESC" "$ranked_rules" "$evidence" "$SIZE_MODE"
        return 0
    fi
    
    # Validate environment
    validate_environment || exit 1

    # FR-016: XML mode — generate XML rule candidates (fixes dead-code bug)
    if [[ "$XML_MODE" == "true" ]]; then
        # For XML mode, run test discovery if requested but skip full pipeline
        if [[ "$FROM_TESTS_XML_MODE" == "true" || "$FROM_CONSTITUTION_MODE" == "true" ]]; then
            [[ "$FROM_TESTS_XML_MODE" == "true" ]] && { find_test_files > /dev/null; }
        else
            # Standard xml mode: run commit analysis to get candidates
            init_commit_cache_if_needed
            scan_recent_commits
            extract_changed_files > /dev/null
            find_test_files > /dev/null
            find_spec_files > /dev/null
            extract_rule_candidates > /dev/null
        fi

        if [[ "$APPEND_MODE" == "true" ]]; then
            # FR-018: append to rules.xml in place
            append_rules_to_xml
        else
            # FR-020: write XML document to OUTPUT_FILE
            generate_xml_report
        fi

        log_section "✓ Execution Complete"
        if [[ "$APPEND_MODE" == "true" ]]; then
            log_done "Rules appended to: ${RULES_XML_PATH}"
        else
            log_done "XML candidates written to: ${OUTPUT_FILE}"
        fi
        return 0
    fi

    # T037: Auto-default --scan-tests when rule_count < param * test_count
    # Parameter SCAN_TESTS_PARAM controls aggressiveness (default: 1)
    SCAN_TESTS_PARAM="${SCAN_TESTS_PARAM:-1}"
    if [[ "$SCAN_TESTS_MODE" != "true" ]]; then
        # Compute rules count (using xmllint if available)
        local rules_count=0
        if [[ -f "$RULES_XML_PATH" && -n "${XMLLINT_CMD:-}" ]]; then
            if command -v "$XMLLINT_CMD" &>/dev/null; then
                rules_count=$("$XMLLINT_CMD" --xpath "count(//*[local-name()='rule'])" "$RULES_XML_PATH" 2>/dev/null || echo 0)
                # xmllint may return a floating point - normalize to integer
                rules_count=$(printf "%d" "$rules_count" 2>/dev/null || echo "$rules_count" | cut -d'.' -f1)
            fi
        fi

        # Compute test file count (use same find patterns as find_test_files)
        local test_count
        test_count=$(find "${REPO_ROOT}" -type f \( -name "*test*.sh" -o -name "*test*.py" -o -name "*.test.js" -o -name "*.spec.ts" \) \
            ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/venv/*" 2>/dev/null | wc -l | tr -d ' ') || test_count=0

        if [[ -z "$test_count" ]]; then
            test_count=0
        fi

        if [[ "$rules_count" -lt $(( SCAN_TESTS_PARAM * test_count )) ]]; then
            SCAN_TESTS_MODE=true
            log_info "Auto-enabled --scan-tests (rules: ${rules_count} < param(${SCAN_TESTS_PARAM}) × tests: ${test_count})"
        fi
    fi

    # Run analysis pipeline
    init_commit_cache_if_needed
    scan_recent_commits
    extract_changed_files > /dev/null  # Just collect
    find_test_files > /dev/null
    find_spec_files > /dev/null
    extract_rule_candidates > /dev/null

    # Generate report
    generate_markdown_report
    
    log_section "✓ Execution Complete"
    log_done "Report available: ${OUTPUT_FILE}"
    log_info "Review the report and follow integration instructions"
}

main "$@"

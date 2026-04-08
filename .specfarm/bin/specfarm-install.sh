#!/usr/bin/env bash
################################################################################
# SpecFarm Installation Script
#
# PURPOSE:
#   Install or update SpecFarm infrastructure in a target repository.
#   Copies .specfarm/ and .github/agents/ with optional validation.
#
#   INCLUDES (as of Phase 0b):
#   - Enhanced gather-rules-agent.sh with --audit-duplicates flag
#   - Lost-rules discovery test suite (9/9 tests passing)
#   - CrossPlatform & Windows compatibility tests
#   - specfarm-stub CLI for template generation
#   - Premium-filter agent in .github/agents/
#   - 5 recovered rules in .specfarm/rules.xml
#
# USAGE:
#   bash .specfarm/bin/specfarm-install.sh --target /path/to/repo
#   bash .specfarm/bin/specfarm-install.sh --target /path/to/repo --dry-run
#   bash .specfarm/bin/specfarm-install.sh --target /path/to/repo --yes
#
# OPTIONS:
#   --target PATH    Target repository path (required unless $TARGET_REPO_PATH set)
#   --dry-run        Show what would be done without making changes
#   --yes            Skip confirmation prompts
#   --force          Skip change detection and overwrite without prompting
#   --help           Show this help message
#
# ENVIRONMENT:
#   TARGET_REPO_PATH    Fallback target path if --target not provided
#   SPECFARM_ROOT       Override source path (default: auto-detect)
#
# EXIT CODES:
#   0 - Success
#   1 - General error
#   2 - Invalid arguments
#   3 - Target validation failed
#   4 - Copy operation failed
#   5 - Test suite failed
#
# Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
################################################################################

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Flags
DRY_RUN=false
SKIP_PROMPT=false
SKIP_TESTS=false
FORCE_INSTALL=false
TARGET_PATH=""

# Auto-detect SPECFARM_ROOT (directory containing this script's parent .specfarm/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECFARM_ROOT="${SPECFARM_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

################################################################################
# Logging functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

################################################################################
# Help message
################################################################################

show_help() {
    cat << 'EOF'
SpecFarm Installation Script

Install or update SpecFarm infrastructure in a target repository.

USAGE:
    bash .specfarm/bin/specfarm-install.sh --target /path/to/repo [OPTIONS]

OPTIONS:
    --target PATH    Target repository path (required unless $TARGET_REPO_PATH set)
    --dry-run        Show planned actions without making changes
    --yes            Skip confirmation prompts
    --force          Skip change detection and overwrite without prompting
    --skip-tests     Skip post-install test suite (useful for CI/testing)
    --help           Show this help message

ENVIRONMENT:
    TARGET_REPO_PATH    Fallback target path if --target not provided
    SPECFARM_ROOT       Override source path (default: auto-detect)

EXAMPLES:
    # Install to a new repo
    bash .specfarm/bin/specfarm-install.sh --target ~/my-project

    # Update existing installation (with diff review)
    bash .specfarm/bin/specfarm-install.sh --target ~/my-project

    # Dry-run to see what would change
    bash .specfarm/bin/specfarm-install.sh --target ~/my-project --dry-run

    # Auto-accept updates
    bash .specfarm/bin/specfarm-install.sh --target ~/my-project --yes

POST-INSTALL:
    After installation, optionally validate rule duplications in target:
    bash /path/to/repo/.specfarm/agents/gather-rules-agent.sh --audit-duplicates

    See docs/ for feature overview and user guide.

EXIT CODES:
    0 - Success
    1 - General error
    2 - Invalid arguments
    3 - Target validation failed
    4 - Copy operation failed
    5 - Test suite failed
EOF
}

################################################################################
# Argument parsing
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                TARGET_PATH="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                SKIP_PROMPT=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 2
                ;;
        esac
    done

    # Use TARGET_REPO_PATH env var as fallback
    if [[ -z "$TARGET_PATH" ]]; then
        TARGET_PATH="${TARGET_REPO_PATH:-}"
    fi

    if [[ -z "$TARGET_PATH" ]]; then
        log_error "Target path required. Use --target or set TARGET_REPO_PATH"
        exit 2
    fi
}

################################################################################
# Validation
################################################################################

validate_source() {
    log_info "Validating source: $SPECFARM_ROOT"

    if [[ ! -d "$SPECFARM_ROOT/.specfarm" ]]; then
        log_error "Source .specfarm/ not found at: $SPECFARM_ROOT"
        log_info "Expected: $SPECFARM_ROOT/.specfarm/"
        exit 3
    fi

    if [[ ! -d "$SPECFARM_ROOT/.github/agents" ]]; then
        log_warn ".github/agents/ not found (optional)"
    fi

    log_success "Source validated: $SPECFARM_ROOT"
}

validate_target() {
    log_info "Validating target: $TARGET_PATH"

    if [[ ! -d "$TARGET_PATH" ]]; then
        log_error "Target directory does not exist: $TARGET_PATH"
        exit 3
    fi

    if [[ ! -d "$TARGET_PATH/.git" ]]; then
        log_warn "Target is not a git repository: $TARGET_PATH"
        log_info "Continuing anyway..."
    fi

    log_success "Target validated: $TARGET_PATH"
}

################################################################################
# Diff and change detection
################################################################################

compute_diff() {
    local source="$1"
    local target="$2"

    if [[ ! -d "$target" ]]; then
        echo "NEW_INSTALLATION"
        return 0
    fi

    # Compare using md5sum/sha256sum
    local hash_cmd="md5sum"
    if ! command -v md5sum &>/dev/null; then
        hash_cmd="sha256sum"
    fi

    local source_files target_files
    source_files=$(cd "$source" && find . -type f -exec $hash_cmd {} \; 2>/dev/null | sort -k2)
    target_files=$(cd "$target" && find . -type f -exec $hash_cmd {} \; 2>/dev/null | sort -k2)

    if [[ "$source_files" == "$target_files" ]]; then
        echo "NO_CHANGES"
    else
        echo "HAS_CHANGES"
    fi
}

show_changes() {
    local source="$1"
    local target="$2"

    log_info "Detecting changes..."

    # New files
    local new_files
    new_files=$(cd "$source" && find . -type f | while read -r f; do
        if [[ ! -f "$target/$f" ]]; then echo "  + $f"; fi
    done)

    # Modified files
    local modified_files
    modified_files=$(cd "$source" && find . -type f | while read -r f; do
        if [[ -f "$target/$f" ]]; then
            if ! cmp -s "$source/$f" "$target/$f"; then
                echo "  ~ $f"
            fi
        fi
    done)

    # Deleted files (in target but not in source)
    local deleted_files
    deleted_files=$(cd "$target" && find . -type f | while read -r f; do
        if [[ ! -f "$source/$f" ]]; then echo "  - $f"; fi
    done)

    if [[ -n "$new_files" ]]; then
        echo -e "${GREEN}New files:${NC}"
        echo "$new_files"
    fi

    if [[ -n "$modified_files" ]]; then
        echo -e "${YELLOW}Modified files:${NC}"
        echo "$modified_files"
    fi

    if [[ -n "$deleted_files" ]]; then
        echo -e "${RED}Deleted files (will be removed from target):${NC}"
        echo "$deleted_files"
    fi

    if [[ -z "$new_files" && -z "$modified_files" && -z "$deleted_files" ]]; then
        echo "  No changes detected."
    fi
}

################################################################################
# Agent-protection: guarded-block injection
################################################################################

# Content injected into root-level agent instruction files
_specfarm_block_content() {
    cat << 'BLOCK'
## SpecFarm Infrastructure — DO NOT MODIFY `.specfarm/`

The `.specfarm/` directory in this repository is **SpecFarm-managed infrastructure**.
AI coding agents MUST NOT add, modify, delete, or reorganize files inside `.specfarm/`.

All changes to `.specfarm/` are managed exclusively by the SpecFarm install script:
  `.specfarm/bin/specfarm-install.sh --target <this-repo>`

BLOCK
}

# Inject (or replace) a guarded block in a file. POSIX-compliant.
# Usage: inject_guarded_block <file>
inject_guarded_block() {
    local file="$1"
    local begin_marker="<!-- BEGIN: SpecFarm-managed — do not edit this block -->"
    local end_marker="<!-- END: SpecFarm-managed -->"

    local block
    block="$(printf '%s\n' "$begin_marker")"$'\n'"$(_specfarm_block_content)"$'\n'"$(printf '%s\n' "$end_marker")"

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ ! -f "$file" ]]; then
            log_info "[DRY-RUN] Would create with SpecFarm block: $file"
        elif grep -qF "$begin_marker" "$file" 2>/dev/null; then
            log_info "[DRY-RUN] Would update SpecFarm block in: $file"
        else
            log_info "[DRY-RUN] Would append SpecFarm block to: $file"
        fi
        return 0
    fi

    local dir
    dir="$(dirname "$file")"
    [[ -d "$dir" ]] || mkdir -p "$dir"

    if [[ ! -f "$file" ]]; then
        # File does not exist — create with block only
        printf '%s\n' "$block" > "$file"
        log_success "Created with SpecFarm block: $file"
        return 0
    fi

    if grep -qF "$begin_marker" "$file" 2>/dev/null; then
        # Block already present — replace in-place using a temp file (POSIX-safe)
        local tmp
        tmp="$(mktemp)"
        awk -v begin="$begin_marker" -v end="$end_marker" -v block="$block" '
            $0 == begin { in_block=1; print block; next }
            in_block && $0 == end { in_block=0; next }
            in_block { next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
        log_success "Updated SpecFarm block in: $file"
    else
        # File exists but no block — append
        printf '\n%s\n' "$block" >> "$file"
        log_success "Appended SpecFarm block to: $file"
    fi
}

install_agent_protection() {
    log_info "Installing agent-protection files..."

    # Root-level agent instruction files that get guarded-block injection
    local root_files=(
        "$TARGET_PATH/.github/copilot-instructions.md"
        "$TARGET_PATH/CLAUDE.md"
        "$TARGET_PATH/AGENTS.md"
        "$TARGET_PATH/GEMINI.md"
        "$TARGET_PATH/.cursorrules"
        "$TARGET_PATH/.windsurfrules"
    )

    for f in "${root_files[@]}"; do
        inject_guarded_block "$f"
    done

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Agent-protection blocks installed in root-level files"
    fi
}

################################################################################
# Extra-file detection and logging
################################################################################

log_extra_files() {
    local source_dir="$1"
    local target_dir="$2"
    local label="$3"   # e.g. ".specfarm/" for display

    [[ -d "$target_dir" ]] || return 0

    local extra_found=false
    while IFS= read -r -d '' tfile; do
        local rel="${tfile#"$target_dir"/}"
        if [[ ! -e "$source_dir/$rel" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would remove extra file: $label$rel"
            else
                log_warn "Removing extra file: $label$rel"
            fi
            extra_found=true
        fi
    done < <(find "$target_dir" -type f -print0 2>/dev/null)

    if [[ "$extra_found" == "true" && "$DRY_RUN" != "true" ]]; then
        log_info "Extra files above were removed by fresh copy of $label"
    fi
}

################################################################################
# Installation
################################################################################

install_specfarm() {
    local source_specfarm="$SPECFARM_ROOT/.specfarm"
    local target_specfarm="$TARGET_PATH/.specfarm"

    log_info "Installing .specfarm/ to target..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $source_specfarm → $target_specfarm"
        return 0
    fi

    # Create backup if target exists, then remove before fresh copy
    if [[ -d "$target_specfarm" ]]; then
        local backup="$target_specfarm.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Creating backup: $backup"
        cp -rp "$target_specfarm" "$backup"
        rm -rf "$target_specfarm"
    fi

    # Copy with preserved permissions
    mkdir -p "$TARGET_PATH"
    cp -rp "$source_specfarm" "$target_specfarm" || {
        log_error "Failed to copy .specfarm/"
        exit 4
    }

    log_success "Copied .specfarm/ to target"
}

install_agents() {
    local source_agents="$SPECFARM_ROOT/.github/agents"
    local target_agents="$TARGET_PATH/.github/agents"

    if [[ ! -d "$source_agents" ]]; then
        log_warn "Source .github/agents/ not found, skipping"
        return 0
    fi

    log_info "Installing .github/agents/ to target..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $source_agents → $target_agents"
        return 0
    fi

    # Create backup if target exists, then remove before fresh copy
    if [[ -d "$target_agents" ]]; then
        local backup="$target_agents.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Creating backup: $backup"
        cp -rp "$target_agents" "$backup"
        rm -rf "$target_agents"
    fi

    mkdir -p "$(dirname "$target_agents")"
    cp -rp "$source_agents" "$target_agents" || {
        log_error "Failed to copy .github/agents/"
        exit 4
    }

    log_success "Copied .github/agents/ to target"
}

install_templates() {
    local source_templates="$SPECFARM_ROOT/.specfarm/templates"
    local target_templates="$TARGET_PATH/.specfarm/templates"

    if [[ ! -d "$source_templates" ]]; then
        log_warn "Source .specfarm/templates/ not found, skipping"
        return 0
    fi

    log_info "Installing .specfarm/templates/ to target..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $source_templates → $target_templates"
        return 0
    fi

    # Create backup if target exists, then remove before fresh copy
    if [[ -d "$target_templates" ]]; then
        local backup="$target_templates.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Creating backup: $backup"
        cp -rp "$target_templates" "$backup"
        rm -rf "$target_templates"
    fi

    mkdir -p "$(dirname "$target_templates")"
    cp -rp "$source_templates" "$target_templates" || {
        log_error "Failed to copy .specfarm/templates/"
        exit 4
    }

    log_success "Copied .specfarm/templates/ to target"
}

install_schema_xsd() {
    local source_xsd="$SPECFARM_ROOT/rules-schema.xsd"
    local target_xsd="$TARGET_PATH/rules-schema.xsd"

    if [[ ! -f "$source_xsd" ]]; then
        log_warn "Source rules-schema.xsd not found at $source_xsd, skipping"
        return 0
    fi

    log_info "Installing rules-schema.xsd to target..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $source_xsd → $target_xsd"
        return 0
    fi

    cp "$source_xsd" "$target_xsd" || {
        log_error "Failed to copy rules-schema.xsd"
        exit 4
    }

    log_success "Copied rules-schema.xsd to target root"
}

################################################################################
# Post-install validation
################################################################################

run_tests() {
    local test_runner="$TARGET_PATH/.specfarm/tests/run_all_tests.sh"

    if [[ "$SKIP_TESTS" == "true" ]]; then
        log_info "Skipping post-install tests (--skip-tests)"
        return 0
    fi

    if [[ ! -f "$test_runner" ]]; then
        log_warn "Test runner not found: $test_runner"
        log_info "Skipping tests"
        return 0
    fi

    log_info "Running test suite in target..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: bash $test_runner"
        return 0
    fi

    local output
    if output=$(cd "$TARGET_PATH" && bash "$test_runner" 2>&1); then
        log_success "Test suite passed"
        echo "$output" | tail -20
        return 0
    else
        log_error "Test suite failed"
        echo "$output" | tail -40
        return 5
    fi
}

################################################################################
# Main workflow
################################################################################

main() {
    parse_args "$@"

    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           SpecFarm Installation Script                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    validate_source
    validate_target

    # Check if this is an update
    local diff_result
    diff_result=$(compute_diff "$SPECFARM_ROOT/.specfarm" "$TARGET_PATH/.specfarm")

    case "$diff_result" in
        NEW_INSTALLATION)
            log_info "New installation detected"
            ;;
        NO_CHANGES)
            log_success "Target is up-to-date, no changes needed"
            exit 0
            ;;
        HAS_CHANGES)
            if [[ "$FORCE_INSTALL" == "true" ]]; then
                log_info "Forcing installation, skipping change detection"
            else
                log_warn "Existing installation detected with changes"
                echo ""
                show_changes "$SPECFARM_ROOT/.specfarm" "$TARGET_PATH/.specfarm"
                echo ""

                if [[ "$SKIP_PROMPT" != "true" && "$DRY_RUN" != "true" ]]; then
                    read -p "Proceed with update? [Y/n] " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
                        log_info "Update cancelled by user"
                        exit 0
                    fi
                fi
            fi
            ;;
    esac

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY-RUN mode: no changes will be made"
        echo ""
    fi

    # Report (and in dry-run, preview) any extra files that will be wiped
    log_extra_files "$SPECFARM_ROOT/.specfarm" "$TARGET_PATH/.specfarm" ".specfarm/"
    if [[ -d "$SPECFARM_ROOT/.github/agents" ]]; then
        log_extra_files "$SPECFARM_ROOT/.github/agents" "$TARGET_PATH/.github/agents" ".github/agents/"
    fi

    install_specfarm
    install_agents
    install_templates
    install_schema_xsd
    install_agent_protection

    if [[ "$DRY_RUN" != "true" ]]; then
        echo ""
        run_tests || {
            log_warn "Tests failed, but installation complete"
            log_info "Review test output above"
            exit 5
        }
    fi

    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           Installation Complete                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    log_success "SpecFarm installed to: $TARGET_PATH"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Run without --dry-run to apply changes"
    fi
}

main "$@"

# High-Confidence Rules (>70)

**Extracted from**: .specfarm/rules.xml (48 rules total)  
**Date**: 2026-03-31

## Summary
- Total rules in rules.xml: **48**
- Analysis scope: Environment, Shell, Error Handling, Logging, Code Organization, Plugin Security, Agent Features

## High-Confidence Rules (Severity: enforce/block)

### 1. Project Environment Context
- **ID**: project-environment-context
- **Confidence**: 95 (strict-engineer vibe, enforce phase)
- **Severity**: enforce
- **Description**: Primary dev environment is Termux/Android; agents must support multi-context logging from CI, desktop, etc.
- **Application**: Directly applicable to this project's SpecFarm infrastructure

### 2. Prefer POSIX Shells
- **ID**: shell-prefer-posix
- **Confidence**: 95 (enforce)
- **Severity**: enforce
- **Description**: AI agents MUST prefer POSIX-compliant shells (bash/zsh/sh); avoid PowerShell unless required
- **Application**: Core agent execution standard

### 3. Prefer Quiet Flags
- **ID**: shell-prefer-quiet-flags
- **Confidence**: 90 (enforce)
- **Severity**: enforce
- **Description**: Always use --silent, --quiet, --no-pager to minimize output while capturing data
- **Application**: Agent efficiency; all shell commands should respect this

### 4. Disable Pagination
- **ID**: shell-disable-pagination
- **Confidence**: 90 (enforce)
- **Severity**: enforce
- **Description**: Disable terminal pagination (PAGER=cat or --no-pager) to ensure commands complete fully
- **Application**: Prevents agent hangs on interactive pagers

### 5. Capture All Output
- **ID**: shell-capture-all-output
- **Confidence**: 95 (enforce)
- **Severity**: enforce
- **Description**: Capture both stdout and stderr for all shell executions
- **Application**: Complete visibility into command outcomes

### 6. Exit Code Validation
- **ID**: shell-exit-code-validation
- **Confidence**: 95 (enforce)
- **Severity**: enforce
- **Description**: Check exit codes after every shell command; log failures explicitly
- **Application**: Prevents silent failures

### 7. Scrub Secrets
- **ID**: shell-scrub-secrets
- **Confidence**: 95 (enforce)
- **Severity**: enforce
- **Description**: Remove sensitive data from logs: API keys, tokens, passwords, credentials
- **Application**: Security-critical for CI/CD and multi-user environments

### 8. Uniform Log Schema
- **ID**: logging-uniform-schema
- **Confidence**: 85 (enforce)
- **Severity**: enforce
- **Description**: All logs must follow consistent JSON schema: timestamp, level, context, message
- **Application**: Enables parsing and monitoring

### 9. Real-Time Error Logging
- **ID**: logging-realtime-errors
- **Confidence**: 85 (enforce)
- **Severity**: enforce
- **Description**: Log errors immediately as they occur, not post-execution summary
- **Application**: Faster debugging and issue detection

### 10. Pre-Commit Drift Gate
- **ID**: governance-precommit-validation
- **Confidence**: 85 (enforce)
- **Severity**: enforce
- **Description**: All commits must pass local linting/validation before reaching CI
- **Application**: Prevents broken code from entering repository

### 11. Executables in bin/
- **ID**: organization-bin-executables
- **Confidence**: 80 (enforce)
- **Severity**: enforce
- **Description**: Place all executable scripts in bin/ directory; make them chmod +x
- **Application**: Clear code organization; aids discoverability

### 12. Logic in src/
- **ID**: organization-src-logic
- **Confidence**: 80 (enforce)
- **Severity**: enforce
- **Description**: Place all sourced logic in src/ directory; do not place in bin/
- **Application**: Separation of concerns; prevents monolithic scripts

### 13. XML Validation Required
- **ID**: validation-xml-schema
- **Confidence**: 80 (enforce)
- **Severity**: enforce
- **Description**: All XML files must validate against project schema with xmllint
- **Application**: Prevents parsing errors and data corruption

### 14. Plugin Sandbox Constraints
- **ID**: r_plugin_sandbox_001
- **Confidence**: 95 (block)
- **Severity**: block
- **Description**: Plugins must have valid manifest (plugin.json) with required fields; no writes outside namespace; forbidden exec patterns blocked
- **Application**: Security-critical plugin isolation

### 15. Context Scout JSON Schema
- **ID**: r_context_scout_schema_001
- **Confidence**: 90 (enforce)
- **Severity**: enforce
- **Description**: bin/spec-env-brief.sh must produce valid JSON with required keys: shell, os, git, rules, timestamp
- **Application**: Enables agent handoff with environment context

---

## Actionability Assessment

All 15 high-confidence rules are **highly actionable** and directly applicable to this repository:

- **Language Appropriateness**: ✓ (Bash, Node.js/TypeScript, and shell scripting are core to this project)
- **Prevention of Bugs**: ✓ (Secret scrubbing prevents credential leaks; exit code validation prevents silent failures)
- **Clarity**: ✓ (All rules are unambiguous and testable)
- **Mostly Followed**: Partial — Many rules are already evident in recent commits, but formalization improves consistency

---

## Verification Status

| Rule | Codebase Evidence | Verified |
|------|-----------------|----------|
| Prefer POSIX Shells | scripts/, agents/ use bash | ✓ |
| Prefer Quiet Flags | git commands use --no-pager | ✓ |
| Capture All Output | 2>&1 redirects common | ✓ |
| Exit Code Validation | $? checks in agent | ✓ |
| XML Validation | xmllint usage in agents | ✓ |
| Executables in bin/ | bin/ directory present | ✓ |
| Logic in src/ | src/ directory present | ✓ |

**Overall Verification**: 7/15 rules directly verified in codebase. Remaining 8 require integration into CI/CD.


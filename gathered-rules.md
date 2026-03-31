# Rules Gathering Report — cypress-realworld-app

**Generated**: 2026-03-31T23:22:11Z
**Repository**: /home/brett/projects/cypress-realworld-app
**Commit Range**: HEAD~10..HEAD
**Maximum Rules**: 20
**Rule Prefix**: auto

---

## Execution Summary

### Environment
- **Project**: cypress-realworld-app
- **Git Repository**: /home/brett/projects/cypress-realworld-app
- **Branch**: speckit/comprehensive-documentation
- **Schema**: rules-schema.xsd

### Scan Configuration
- **Scan Directories**: src,specs
- **Excluded Patterns**: third-party,build,config,.github,node_modules,venv,__pycache__,.git,.specfarm
- **Commit Range**: HEAD~10..HEAD

### Discovery Results

#### Changed Files
```
  
  [0;32m===[0m [0;34mAnalyzing Changed Files[0m [0;32m===[0m
    [0;32m[✓][0m Analyzed 30 changed files
  .specfarm.backup.20260331185634/CODE-STYLE-AUDIT.md
  .specfarm.backup.20260331185634/RESTRUCTURING-COMPLETE.md
  .specfarm.backup.20260331185634/agents/AGENT-EVAL-REPORT.md
  .specfarm.backup.20260331185634/agents/MODS-APPLIED.md
  .specfarm.backup.20260331185634/agents/gather-rules-agent-caller.sh
  .specfarm.backup.20260331185634/agents/gather-rules-agent.sh
  .specfarm.backup.20260331185634/agents/intake-agent.md
  .specfarm.backup.20260331185634/agents/repo-mix-fallback.ps1
  .specfarm.backup.20260331185634/agents/repo-mix-fallback.sh
  .specfarm.backup.20260331185634/agents/rules-filter.md
  .specfarm.backup.20260331185634/agents/rules-filter.md.backup
  .specfarm.backup.20260331185634/agents/todo-improve-rule-coverage.md
```

#### Test Files Found
  
  [0;32m===[0m [0;34mLocating Test Files[0m [0;32m===[0m
    [0;32m[✓][0m Found 171 test files (exhaustive scan)
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-view.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/notifications.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/bankaccounts.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/auth.spec.ts
  /home/brett/projects/cypress-realworld-app/cypress/tests/ui/user-settings.spec.ts

#### Specification Files Found
  
  [0;32m===[0m [0;34mLocating Specification Files[0m [0;32m===[0m
    [0;32m[✓][0m Found 20 specification files
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/service/spec.md
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/service/plan.md
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/payroll/spec.md
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/payroll/plan.md
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/api/spec.md
  /home/brett/projects/cypress-realworld-app/.specfarm/templates/api/plan.md
  /home/brett/projects/cypress-realworld-app/.specfarm/specs/011-test-1st-customer-repo/spec.md

#### Rule Candidates Extracted
```
  [1;33m[INFO][0m Scanning test files for rule patterns...
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-view.spec.ts: describe("Transaction View", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-view.spec.ts: it("transactions navigation tabs are hidden on a transaction view page", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-view.spec.ts: it("likes a transaction", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts: describe("New Transaction", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts: it("navigates to the new transaction form, selects a user and submits a transaction payment", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts: it("navigates to the new transaction form, selects a user and submits a transaction request", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/notifications.spec.ts: describe("Notifications", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/notifications.spec.ts: describe("notifications from user interactions", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/notifications.spec.ts: it("User A likes a transaction of User B; User B gets notification that User A liked transaction ", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts: describe("Transaction Feed", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts: describe("app layout and responsiveness", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts: it("toggles the navigation drawer", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/bankaccounts.spec.ts: describe("Bank Accounts", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/bankaccounts.spec.ts: it("creates a new bank account", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/bankaccounts.spec.ts: it("should display bank account form errors", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/auth.spec.ts: describe("User Sign-up and Login", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/auth.spec.ts: it("should redirect unauthenticated user to signin page", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/auth.spec.ts: it("should redirect to the home page after login", function () {
  Source: /home/brett/projects/cypress-realworld-app/cypress/tests/ui/user-settings.spec.ts: describe("User Settings", function () {
```

---

## Integration Instructions

### Step 1: Review Extracted Candidates
Review the rule candidates above and identify which patterns should become formal XML rules.

### Step 2: Generate XML Rules
For each candidate, create a `<rule>` element following this template:

```xml
<rule id="PREFIX-FEATURE-000N" enabled="true" severity="warn" phase="post-analysis">
  <name>Rule Title</name>
  <description>Detailed description of what this rule checks</description>
  <rationale>Link to source file or task that motivated this rule</rationale>
  <metadata>
    <source>Source file path</source>
    <test_link>tests/path/to/test.sh::test_name</test_link>
  </metadata>
</rule>
```

### Step 3: Validate Against Schema
```bash
xmllint --schema /home/brett/projects/cypress-realworld-app/rules-schema.xsd rules.xml --noout
```

### Step 4: Integrate into Project
Add generated rules to your project's `rules.xml` file (or equivalent).

---

## Next Steps

1. **Analyze Candidates**: Review extracted rule candidates above
2. **Create Rules**: Generate formal XML rule definitions
3. **Test**: Validate rules against schema (/home/brett/projects/cypress-realworld-app/rules-schema.xsd)
4. **Commit**: Add rules to version control

---

## Report Metadata

- **Scan Date**: 2026-03-31
- **Scan Time**: 23:22:12 UTC
- **Report File**: /home/brett/projects/cypress-realworld-app/gathered-rules.md
- **Schema File**: /home/brett/projects/cypress-realworld-app/rules-schema.xsd

For questions or issues, refer to the gather-rules-agent.sh script documentation.


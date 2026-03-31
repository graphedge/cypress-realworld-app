# SPECKIT_ANALYSIS.md
# Cross-Artifact Consistency & Quality Analysis
# Cypress Real-World App — All Four Feature Specs

**Generated**: 2026-03-31  
**Scope**: constitution.md · specs 001–004 · plans 001–004 · tasks 001–004 · checklists 001–004  
**Mode**: Non-destructive read-only analysis  
**Analyzer**: speckit.analyze

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Per-Feature Analysis](#2-per-feature-analysis)
3. [Spec-Plan-Tasks Traceability Matrix](#3-spec-plan-tasks-traceability-matrix)
4. [Cross-Feature Shared Dependency Map](#4-cross-feature-shared-dependency-map)
5. [Prioritized Issue List](#5-prioritized-issue-list)
6. [Constitution Compliance Summary](#6-constitution-compliance-summary)
7. [Metrics](#7-metrics)
8. [Remediation Recommendations](#8-remediation-recommendations)

---

## 1. Executive Summary

All four features are **retroactively documented** against an already-implemented codebase. This is an important context: specs and checklists describe the running implementation, while plans and tasks identify *gaps and hardening work* still to be done. Overall artifact quality is **high**, but five specific cross-feature conflicts and several active bugs require attention before implementation tasks run.

### Overall Quality Scores

| Feature | Spec Quality | Plan Quality | Tasks Quality | Cross-Feature Risk | Overall |
|---------|-------------|-------------|--------------|-------------------|---------|
| 001 – User Authentication | 7/10 | 9/10 | 9/10 | Low | **8.3/10** |
| 002 – Transaction Management | 8/10 | 9/10 | 9/10 | **HIGH** | **8.0/10** |
| 003 – Bank Accounts & Transfers | 8/10 | 9/10 | 8/10 | **HIGH** | **7.7/10** |
| 004 – Social Features | 8/10 | 9/10 | 9/10 | Medium | **8.3/10** |

**Score rationale**: Deductions for (a) missing formal requirement IDs in all specs, (b) confirmed bugs in production code (Feature 004), (c) cross-feature conflicts between Features 002 and 003 (shared function modifications), (d) task ID format inconsistency in Feature 003.

---

## 2. Per-Feature Analysis

### 2.1 Feature 001 — User Authentication & Profile Management

**Branch**: `001-user-authentication`  
**Status**: Core implementation complete; tasks harden type safety, fix 2 bugs, add documentation.

**Strengths**:
- Plan comprehensively checks all 10 constitution principles
- XState decision rationale (Decision 1–6) is well-documented with alternatives considered
- Tasks have precise file paths, acceptance criteria, [P] markers, and user story mapping
- Known gaps table in plan directly maps to task IDs (no guesswork)

**Weaknesses**:
- Spec uses workflow-based organization (no FR-### identifiers) — makes formal traceability harder
- Spec lacks a "Success Criteria" or "Functional Requirements" section with measurable outcomes
- Password minimum length mismatch: spec workflow says ≥ 8 chars, Yup schemas use 4 chars (plan Known Gaps table confirms; tasks T-003, T-007, T-008 fix)
- No "Remember Me" dedicated task — covered only indirectly through existing tests

---

### 2.2 Feature 002 — Transaction Management

**Branch**: `speckit/comprehensive-documentation` ← **inconsistency** (plan header says this; expected `002-transaction-management`)  
**Status**: Core implementation complete; tasks implement XState educational comments, audit/validate code, and build full test suite.

**Strengths**:
- Most comprehensive spec of the four — detailed API contracts, data model, privacy decision tree
- Plans 9 research findings (R1–R7) with concrete code locations
- 69 tasks covering US1–US5 with explicit file paths
- Component tests for TransactionTitle and TransactionDateRangeFilter explicitly tasked

**Weaknesses**:
- **CRITICAL**: Plan Research Finding (Phase 0 resolution table) states bank transfer detection uses `transactionType: "payment"` with non-empty `source` field. Feature 003 plan Finding 3 states `transactionType: "transfer"` must be *added* to the validator. These plans directly contradict each other on how bank transfers are identified.
- Tasks T-027/T-028/T-029 implement bank transfer path in `createTransaction()` and `debitPayAppBalance()` — the same functions that Feature 003 Tasks T003/T015/T018 also modify (no cross-feature dependency)
- Branch name mismatch in plan header suggests copy-paste artifact from earlier workflow

---

### 2.3 Feature 003 — Bank Accounts & Transfers

**Branch**: `003-bank-accounts-transfers`  
**Status**: Core CRUD implemented; deposit flow has confirmed missing function; security gap confirmed.

**Strengths**:
- Plan identifies 8 explicit gaps (G1–G8) with severity ratings and precise code locations
- Research findings include authorization gap, GraphQL/REST duality, validation inconsistency
- Tasks map every plan gap to specific implementation work with priority markers (🔴🟡🟢)

**Weaknesses**:
- **CRITICAL**: `createBankTransferDeposit` function confirmed missing from `backend/database.ts` (G1/Finding 2) — spec describes deposit flow as a first-class feature
- **HIGH**: `GET /bankAccounts/:id` lacks ownership authorization (G3/Finding 4) — any authenticated user can read any bank account by guessing a shortId
- Task IDs use `T001` format (no dash) vs. `T-001` format used by Features 001/002/004 — breaks cross-feature tooling and navigation
- Spec §GraphQL API Support notes "GraphQL interface is optional/secondary; REST API is primary" but plan Finding 1 states "React frontend communicates exclusively via GraphQL for bank account operations" — direct spec/plan contradiction
- 26 tasks vs. 69 in Feature 002 despite similar complexity — some phases (especially polish) feel compressed

---

### 2.4 Feature 004 — Social Features

**Branch**: `004-social-features`  
**Status**: Core infrastructure complete; three confirmed bugs in production code; validation and type-safety gaps.

**Strengths**:
- Plan identifies bugs with exact code locations AND correct fix with TypeScript code examples
- Tasks are the most detailed of all four features — each task has step-by-step acceptance criteria
- Notification trigger map table in plan is clear and directly traceable to task work
- Privacy enforcement design (Decision 4) creates a reusable `canAccessTransaction` helper

**Weaknesses**:
- **CRITICAL**: Three confirmed bugs in production code that are actively incorrect — like notification tautology (BUG-01/02), lack of idempotency (BUG-03)
- TYPE-02 from plan (transactionDetailMachine.ts `any` types) — not obviously mapped to a task by looking at task descriptions; requires verification
- Plan date is "2025-01-15" while Features 001 and 003 use "2026-03-31" — inconsistent timestamps across the suite
- `canAccessTransaction` helper (T-001) is the foundational blocker for T-005, T-010, T-011 — but these dependent tasks lack ⚠️ blocking markers in their descriptions

---

## 3. Spec-Plan-Tasks Traceability Matrix

### Feature 001 — User Authentication

| Spec Workflow | Plan Coverage | Task IDs | Gaps |
|--------------|--------------|---------|------|
| Sign-Up (username, password, profile) | Phase 1 Backend + Phase 3 UI | T-001, T-002, T-003, T-004, T-005, T-006, T-007 | Password min-length misalignment (8 vs 4) — tasks fix |
| Sign-In (local auth, session cookie) | Phase 2 Machine + Phase 3 UI | T-008, T-009, T-010, T-011, T-012, T-013, T-014 | @ts-ignore at authMachine:264,270 — tasks replace |
| Sign-Out (session destroy, redirect) | Phase 1 Foundational | T-001, T-015, T-016 | Double-redirect bug — T-001 fixes |
| Remember Me (30-day cookie) | Phase 3 Session Behavior | T-013 (indirect) | No dedicated task for 30-day maxAge validation |
| Profile Management (view + edit) | Phase 5 User Settings | T-017, T-018, T-019, T-020, T-021 | @ts-ignore at helpers.ts:100,104 — tasks replace |
| Third-Party Auth (Auth0/Okta/Cognito/Google) | Phase 6 Providers | T-022, T-023, T-024, T-025, T-026, T-027, T-028, T-029, T-030, T-031 | @ts-ignore at helpers.ts:8,10,65 — tasks replace |
| Session security (httpOnly, CORS) | Phase 0 Decision 2 | — | ✅ Architectural (no task needed) |

**Coverage**: 6/7 workflows fully covered; 1 workflow (Remember Me) partially covered (existing test but no hardening task).

---

### Feature 002 — Transaction Management

| Spec Area | Plan Coverage | Task IDs | Gaps |
|-----------|--------------|---------|------|
| Direct P2P Payment | Phase 3 Backend + Frontend | T-009 to T-018 | None |
| Payment Request lifecycle (pending/accept/reject) | Phase 4 Request Path | T-019 to T-026 | None |
| Bank Transfer (deposit/withdrawal) | Phase 5 Bank Transfer | T-027 to T-031 | ⚠️ "transfer" not in validator (see CONFLICT below) |
| Transaction feeds (personal/contacts/public) | Phase 6 Query Layer + UI | T-032 to T-054 | None |
| Date/amount/status filtering | Phase 6 Filter Components | T-046 to T-054 | None |
| Transaction detail view | Phase 7 Detail + Social | T-055 to T-062 | Depends on Feature 004 infrastructure |
| Privacy visibility rules | Phase 6 R3 + T-034/T-054 | T-034, T-054 | None |
| Pagination | Phase 5 + T-005 | T-005, T-035 to T-037 | None |
| Component tests (TransactionTitle, DateFilter) | Phase 7 Polish | T-063, T-064 | None |

**Coverage**: 9/9 spec areas covered. **69 tasks total.**

---

### Feature 003 — Bank Accounts & Transfers

| Spec Area | Plan Gap ID | Task IDs | Status |
|-----------|------------|---------|--------|
| Bank Account list/get/create/delete | G3, G4 | T004, T005, T007, T008, T009 | ⚠️ Security fix needed (G3) |
| Bank Account GraphQL interface | G5 | T006 | ⚠️ @ts-ignore fix needed |
| Bank Transfer Deposit | G1, G2 | T002, T003, T013, T014, T015, T016, T017 | 🔴 createBankTransferDeposit MISSING |
| Bank Transfer Withdrawal | G1, G6 | T018, T019, T020 | Partially wired; test coverage gap |
| Deposit/Withdrawal UI E2E | G6 | T010, T011, T012, T016, T019, T020 | ⚠️ Tests incomplete |
| Authorization hardening | G3, G7 | T004, T007, T008, T009 | 🔴 Ownership check missing |
| Validator hardening | G4 | T005 | ⚠️ Length/format validation missing |
| Documentation (TSDoc, README) | G8 | T021, T022, T023, T024 | Low priority; no blocking issues |

**Coverage**: All 8 plan gaps (G1–G8) mapped to tasks. **26 tasks total.**

---

### Feature 004 — Social Features

| Spec Area | Plan Gap/Bug ID | Task IDs | Status |
|-----------|----------------|---------|--------|
| Like (idempotent, one per user) | BUG-03 | T-004 | 🔴 Active bug — duplicate likes created |
| Like notification targeting | BUG-01 | T-003 | 🔴 Active bug — tautology always fires |
| Privacy enforcement on likes | VAL-03, Finding 6 | T-001, T-005 | ⚠️ No current privacy check |
| Comment (validated content) | VAL-01, Finding 4 | T-010 | ⚠️ Empty string currently accepted |
| Comment notification targeting | BUG-02 | T-009 | 🔴 Active bug — same tautology as BUG-01 |
| Privacy enforcement on comments | VAL-04, Finding 6 | T-001, T-011 | ⚠️ No current privacy check |
| Notification list (unread, scoped) | TYPE-01 | T-002, T-016, T-017, T-018 | ⚠️ @ts-ignore suppresses type |
| Mark notification as read | — | T-020, T-021 | ✅ Implemented; tests needed |
| Type safety (transactionDetailMachine) | TYPE-02 | T-002 (TYPE-01), T-017 (TYPE-02)? | ⚠️ Verify TYPE-02 task coverage |
| Documentation (TSDoc, quickstart) | DOC-01/02/03 | T-024 to T-027 | ✅ Mapped |

**Coverage**: All plan bugs (BUG-01-03), validation gaps (VAL-01-04), type gaps (TYPE-01-02), and doc gaps (DOC-01-03) mapped to tasks. **28 tasks total.**

---

## 4. Cross-Feature Shared Dependency Map

### Shared Source Files — Modification Conflicts

| File | Modified By | Tasks | Conflict Risk |
|------|------------|-------|--------------|
| `backend/database.ts` | 001 (user helpers), 002 (createTransaction, debitPayAppBalance), 003 (createBankTransferDeposit, processBankDeposit, createTransaction), 004 (createLikes, createComments, canAccessTransaction, createNotifications) | 001/T-004; 002/T-009,T-010,T-027,T-028; 003/T013-T018; 004/T-001,T-002,T-003,T-004,T-009 | 🔴 **HIGH** — Features 002 and 003 both add branches to `createTransaction()` and `debitPayAppBalance()` |
| `backend/validators.ts` | 001 (userFieldsValidator), 002 (isTransactionPayloadValidator audit), 003 (isBankAccountValidator + isTransactionPayloadValidator), 004 (isCommentValidator) | 002/T-006,T-029; 003/T002,T005; 004/T-010 | 🔴 **HIGH** — Features 002 (T-029: add `source` field) and 003 (T002: add `"transfer"` enum) both modify `isTransactionPayloadValidator` without cross-referencing each other |
| `src/machines/transactionDetailMachine.ts` | 002 (T-057 implements), 004 (TYPE-02: fix `any` types) | 002/T-057; 004/TYPE-02 task | 🟡 **MEDIUM** — Feature 002 must implement before Feature 004 modifies; no cross-feature dependency documented |
| `src/machines/dataMachine.ts` | 002 (T-007: add educational comments), 003 (bankAccountsMachine extends), 004 (notificationsMachine extends) | 002/T-007 | 🟡 **MEDIUM** — Feature 002 T-007 is the canonical educational comment task; 003/004 should implement after, but no dependency noted |
| `backend/helpers.ts` | 001 (T-017,T-018,T-022,T-023,T-024: replace @ts-ignore) | 001 tasks only | 🟢 **LOW** — single feature owns this file |
| `cypress/support/commands.ts` | 001 (T-032 to T-035: TSDoc only) | 001 tasks | 🟢 **LOW** — no behavioral changes; 002/003/004 only read this file |
| `data/database-seed.json` | 002 (T-002: audit) | 002/T-002 | 🟡 **MEDIUM** — all features depend on seed data; any changes affect all test suites |
| `backend/banktransfer-routes.ts` | 002 (structure only), 003 (T023: TSDoc) | 003/T023 | 🟢 **LOW** — 003 owns this file |
| `src/models/transaction.ts` | 002 (T-003: audit interfaces) | 002/T-003 | 🟡 **MEDIUM** — used by 003 and 004; changes could break downstream |

### Logical Infrastructure Dependencies (Implementation Order)

```
Feature 001 (auth infrastructure)
    └─ REQUIRED BEFORE → All other features (ensureAuthenticated middleware)

Feature 002 (transaction data model + createTransaction)
    ├─ REQUIRED BEFORE → Feature 003 (bank transfer uses POST /transactions)
    ├─ REQUIRED BEFORE → Feature 004 (transactionDetailMachine hosts like/comment actions)
    └─ SHARES createTransaction() WITH → Feature 003 (⚠️ conflict risk)

Feature 003 (bank accounts + deposit/withdrawal)
    └─ DEPENDS ON → Feature 002's createTransaction() implementation

Feature 004 (likes/comments infrastructure)
    ├─ REQUIRED BY → Feature 002 (TransactionResponseItem enrichment with likes/comments T-055)
    └─ MODIFIES → Feature 002's transactionDetailMachine (TYPE-02)
```

### Key Shared `data-test` Attribute Namespaces

| Namespace | Feature Owner | Other Consumers |
|-----------|--------------|----------------|
| `transaction-*` | 002 | 003 (deposit/withdrawal flows), 004 (like button on detail) |
| `bankaccount-*` | 003 | 002 (source selection in transaction wizard) |
| `notification-*` | 004 | — |
| `signin-*`, `signup-*` | 001 | — |
| `sidenav-*` | 001 | 003 (sidenav-bankaccounts) |

---

## 5. Prioritized Issue List

### CRITICAL — Must Resolve Before Execution

| ID | Category | Location(s) | Summary | Recommendation |
|----|----------|-------------|---------|----------------|
| C1 | **Inconsistency** | `002/plan.md` R5 resolution vs `003/plan.md` Finding 3 | Feature 002 plan states bank transfers use `transactionType: "payment"` + non-empty `source` (existing validator unchanged). Feature 003 plan states `transactionType: "transfer"` MUST be added to the validator. Direct plan contradiction on how bank transfers are identified. | Establish a single canonical decision: either (a) keep `"payment"` + source detection (update 003 plan Finding 3) or (b) add `"transfer"` enum (update 002 plan Phase 0 resolution and T-029 to add the enum value). Update both plans before executing either task. |
| C2 | **Duplication/Conflict** | `002/tasks.md` T-027,T-028 vs `003/tasks.md` T003,T015,T018 | Both features implement bank transfer logic in `backend/database.ts → createTransaction()`. Feature 002 T-027 "Extend createTransaction() with bank transfer path" and Feature 003 T003 "Add isBankTransfer guard stub" / T015/T018 "Wire deposit/withdrawal branch" — no cross-feature dependency prevents double-implementation or merge conflicts. | Add explicit dependency: Feature 003 T002/T003 must list Feature 002 T-027 as prerequisite (or merge into one feature). Designate a single owner for the `isBankTransfer` guard in `createTransaction()`. |
| C3 | **Bug (Active)** | `backend/database.ts` createLikes ~L628, createComments ~L675 | Like and Comment notification tautology (`userId !== senderId \|\| userId !== receiverId` is always true) causes both sender AND receiver to receive notifications regardless of who performed the action. Plan 004 BUG-01/BUG-02 — confirmed production bugs. | Apply T-003 (likes) and T-009 (comments) immediately before running any notification-dependent test suite. These bugs corrupt notification test data. |
| C4 | **Bug (Active)** | `backend/database.ts` createLikes | Like idempotency not enforced — duplicate `POST /likes/:transactionId` calls create duplicate Like records in DB. Spec rule "One Like Per User Per Transaction" violated. Plan 004 BUG-03. | Apply T-004 before any test that validates like counts. Duplicate likes corrupt feed counts and notification totals. |
| C5 | **Gap (Missing Function)** | `backend/database.ts` | `createBankTransferDeposit` function does not exist. The spec explicitly describes a deposit flow (bank → wallet) as a first-class feature. `createBankTransferWithdrawal` exists but its symmetric counterpart does not. Plan 003 G1/Finding 2. | Implement T013 (createBankTransferDeposit) before T014 (processBankDeposit) and T015 (createTransaction wire). This is not optional — deposit is half the spec's scope. |

---

### HIGH — Resolve Before Feature Sign-Off

| ID | Category | Location(s) | Summary | Recommendation |
|----|----------|-------------|---------|----------------|
| H1 | **Security** | `backend/bankaccount-routes.ts` GET /:bankAccountId | No ownership check: any authenticated user can read any bank account by guessing a 7-char shortId. Plan 003 Finding 4 / G3. Task T004 exists. | Mark T004 as blocking all bank account API tests. Cannot pass security acceptance criteria without this fix. |
| H2 | **Constitution §4** | `authMachine.ts:264,270`; `helpers.ts:8,10,65,100,104`; `bankAccountsMachine.ts:~55`; `notification-routes.ts:~39`; `transactionDetailMachine.ts` | Multiple `@ts-ignore` comments remain across four features, violating Constitution Principle 4 (TypeScript-First, no `any`). Plans acknowledge these but tasks address them at different priority levels. | Consolidate: all @ts-ignore removals should be treated as HIGH, not medium/polish. Consider a single "type safety sprint" across all features before integration testing. |
| H3 | **Gap** | `backend/validators.ts` isTransactionPayloadValidator | Feature 002 T-029 adds optional `source` field validation but does NOT add `"transfer"` to the `transactionType` enum (adds only source). Feature 003 T002 adds `"transfer"`. These tasks address different aspects of the same validator without cross-referencing. | Merge validator changes: whoever runs first should implement both changes atomically to avoid a partial state where source is validated but transactionType is still rejected or vice versa. |
| H4 | **Gap (Active)** | `backend/validators.ts` isCommentValidator | Empty strings and strings > 500 chars accepted as valid comment content. Spec says non-empty required; plan 004 Finding 4. Task T-010 exists. | Apply T-010 before running any comment API tests. Existing "empty comment" data in tests may pass today but fail after fix — test baseline should be updated. |
| H5 | **Gap** | `backend/like-routes.ts`, `backend/comment-routes.ts` | No privacy check on likes or comments — users can like/comment on private transactions they have no access to. Plan 004 Finding 6. Tasks T-001/T-005/T-011 exist but T-001 must be implemented first. | T-001 (`canAccessTransaction` helper) is a hard prerequisite for T-005 and T-011. Add explicit [depends-on: T-001] markers to T-005 and T-011 task descriptions. |
| H6 | **Inconsistency** | All specs (001–004) | No spec uses formal requirement IDs (FR-###, UC-###, SC-###). Requirements are described as prose sections/workflows. This makes formal traceability, regression mapping, and change impact analysis difficult. | Add FR-### identifiers to each spec's sections. At minimum, a requirement numbering table at the spec's top. This is a retroactive improvement but pays forward for any future amendment. |
| H7 | **Format** | `003/tasks.md` task IDs | Feature 003 uses `T001, T002` (no dash) while Features 001/002/004 use `T-001, T-002`. Breaks grep patterns, cross-feature dependency references, and any parsing tooling. | Rename Feature 003 task IDs to `T-001, T-002, ...` format. This is a find-replace operation across a single file. |

---

### MEDIUM — Resolve Before Release / Integration Testing

| ID | Category | Location(s) | Summary | Recommendation |
|----|----------|-------------|---------|----------------|
| M1 | **Inconsistency** | `003/spec.md` §GraphQL API Support vs `003/plan.md` Finding 1 | Spec says "GraphQL interface is optional/secondary; REST API is primary." Plan says "React frontend communicates exclusively via GraphQL for bank account operations." Direct contradiction on interface primacy. | Update spec §GraphQL API Support to reflect reality: GraphQL is the primary frontend interface; REST exists for API-level testing and server-side transaction processing. |
| M2 | **Cross-Feature Dependency (undocumented)** | `002/tasks.md` T-055,T-032 vs `004/tasks.md` | Feature 002's `TransactionResponseItem` enrichment with `likes` and `comments` arrays (T-055/T-032) depends on Feature 004's like/comment infrastructure (`getLikesByTransactionId`, `getCommentsByTransactionId`). No cross-feature dependency is documented in either tasks file. | Add note to 002/T-055: "Depends on Feature 004 like/comment DB helpers existing." Add reciprocal note to 004/T-001: "Feature 002 T-055 depends on these helpers." |
| M3 | **Cross-Feature Dependency (undocumented)** | `002/tasks.md` T-007 vs `003/tasks.md`, `004/tasks.md` | Feature 002 T-007 adds educational inline comments to `dataMachine.ts`. Features 003 and 004 extend `dataMachine` — if they implement before T-007 runs, they miss the educational baseline comments. | Add "Implement Feature 002 T-007 before extending dataMachine" note to 003 and 004 tasks that reference dataMachine. |
| M4 | **Ambiguity** | `004/spec.md` §Comment Rules | Spec says max length is "typically 500 characters (app may limit)" — "typically" and "may limit" are hedged non-committal language. Plan and tasks commit to a hard 500-char limit. | Remove hedging from spec: "Comments are limited to 500 characters." Align spec with plan's firm decision. |
| M5 | **Inconsistency** | `002/plan.md` branch header | Plan header says `Branch: speckit/comprehensive-documentation` but spec and related docs are under `002-transaction-management`. Appears to be a copy-paste artifact. | Update plan.md branch field to `002-transaction-management`. |
| M6 | **Cross-Feature Dependency (undocumented)** | `002/tasks.md` T-057 vs `004/plan.md` TYPE-02 | Feature 002 T-057 implements `transactionDetailMachine.ts`; Feature 004 TYPE-02 modifies it for type safety. No ordering constraint documented. Feature 004 modifications cannot safely proceed until Feature 002's implementation stabilizes. | Add "Depends on Feature 002 T-057" to Feature 004's TYPE-02 task (or equivalent task ID). |
| M7 | **Completeness** | `004/tasks.md` TYPE-02 coverage | Plan 004 lists TYPE-02 (transactionDetailMachine.ts: replace `any` event types with discriminated union). It's unclear which specific task ID in tasks.md covers this. There are 28 tasks total but the mapping is implicit. | Explicitly add TYPE-02 to a task description in tasks.md, or confirm which task (likely in Phase 5 US3) covers it. |
| M8 | **Completeness** | `001/plan.md` Known Gaps | Plan 001 lists "Third-party auth `cy.loginToAuth0`/`cy.loginToOkta` require external credentials in CI" as a known gap. No task explicitly documents or tests the graceful-skip behavior. | Add a low-priority task to verify `Cypress.env("auth0_username")` guard pattern is in place in all provider specs. |
| M9 | **Inconsistency** | Plan dates across features | Feature 001: `2024-01-15`. Feature 002: `2026-03-31`. Feature 003: `2026-03-31`. Feature 004: `2025-01-15`. Inconsistent dating creates confusion about creation/update timeline. | Standardize dates to a consistent "last amended" format using the actual plan update date. |

---

### LOW — Quality Improvements

| ID | Category | Location(s) | Summary | Recommendation |
|----|----------|-------------|---------|----------------|
| L1 | **Ambiguity** | All checklists/requirements.md | All four checklists have every item checked [x] with note "Specification retroactively captured from implemented codebase." This masks the fact that some items (e.g., "All acceptance scenarios are defined") refer to running code, not planning artifacts. | Add a "Retroactive Documentation" note prominently at the top of each checklist to distinguish captured-state items from forward-planned items. |
| L2 | **Inconsistency** | `001/spec.md` structure | Feature 001 spec includes full API contracts inline (HTTP request/response examples, TypeScript interfaces) — far more detail than other specs. Specs 002–004 are leaner. Inconsistent depth makes cross-spec reading harder. | Consider moving API contract details from spec.md to dedicated `contracts/` files (as plans already structure it) for consistency across features. |
| L3 | **Style** | `003/tasks.md` priority markers | Feature 003 uses emoji priority markers (🔴/🟡/🟢) inline with task descriptions. Features 001/002/004 use [US#] story markers and [P] parallel markers only. Inconsistent metadata style. | Adopt a consistent metadata convention. Either use emoji priority across all features or drop it from Feature 003. |
| L4 | **Completeness** | `001/tasks.md` Remember Me | No dedicated task for validating the 30-day session cookie extension (`maxAge = 30 * 24 * 60 * 60 * 1000`). Existing `auth.spec.ts` test covers this but no hardening task ensures the implementation stays aligned with spec value. | Add a low-priority task to assert the session cookie `maxAge` matches exactly 30 days in the Remember Me test. |
| L5 | **Completeness** | `002/tasks.md` | Task T-002 "Audit database-seed.json for coverage of all transaction types" has no acceptance criteria beyond listing what should be present. Other tasks in the same file have detailed ACs. | Add acceptance criteria: "seed has ≥1 payment, ≥1 accepted request, ≥1 rejected request, ≥1 bank transfer, with public/private/contacts privacy levels each represented." |

---

## 6. Constitution Compliance Summary

| Principle | 001 Auth | 002 Transactions | 003 Bank | 004 Social |
|-----------|---------|-----------------|---------|-----------|
| P1: Educational Excellence | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| P2: Zero Production Ambition | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| P3: Comprehensive Testing (≥85%) | ✅ PASS | ✅ PASS | ⚠️ PARTIAL — deposit/withdrawal E2E and visual snapshots incomplete | ⚠️ PARTIAL — API tests thin on idempotency/validation/cross-user scenarios |
| P4: TypeScript-First (no @ts-ignore/any) | ⚠️ PARTIAL — 7 @ts-ignore in authMachine/helpers; tasks T-009,T-010,T-017,T-018,T-022–T-025 fix | ✅ PASS | ⚠️ PARTIAL — 1 @ts-ignore in bankAccountsMachine; task T006 fixes | ⚠️ PARTIAL — @ts-ignore in notification-routes; `any` in transactionDetailMachine; tasks T-002,T-016 fix |
| P5: Single Source of Truth (cy.getBySel) | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| P6: Database Seeding (cy.task db:seed) | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| P7: Multi-Auth Provider Parity | ✅ PASS (4 providers) | ✅ N/A | ✅ N/A | ✅ N/A |
| P8: CI/CD as Quality Gate | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (pending new tests) |
| P9: Performance & Observability | ✅ PASS | ✅ PASS | ⚠️ WATCH — graphql-tag bundle impact; monitor PR report | ✅ PASS |
| P10: Documentation-as-Code | ✅ PASS | ✅ PASS | ⚠️ PARTIAL — REST route TSDoc missing; README not updated (G8); tasks T021–T024 fix | ⚠️ PARTIAL — no quickstart.md yet; TSDoc on DB helpers missing; tasks T-024–T-027 fix |

**Constitution Violations Summary**:
- P3 violations: Features 003 and 004 (both addressed in tasks, not yet implemented)
- P4 violations: Features 001, 003, 004 (all addressed in tasks, not yet implemented)
- P10 violations: Features 003 and 004 (addressed in tasks)
- **No HARD BLOCKS**: All violations have corresponding tasks. No principle is unaddressed.

---

## 7. Metrics

### Task Counts

| Feature | Total Tasks | [P] Parallel | US-Mapped | Phase Count | Format |
|---------|------------|-------------|-----------|-------------|--------|
| 001 | 39 | ~23 | 35/39 (90%) | 7 phases | T-NNN |
| 002 | 69 | ~38 | 65/69 (94%) | 8 phases | T-NNN |
| 003 | 26 | ~14 | 20/26 (77%) | 6 phases | TNNN ⚠️ |
| 004 | 28 | ~16 | 24/28 (86%) | 5 phases | T-NNN |
| **Total** | **162** | **~91 (56%)** | **144/162 (89%)** | — | — |

### Requirement Coverage

| Feature | Spec Areas | Mapped to Plan | Mapped to Tasks | Coverage % |
|---------|-----------|---------------|----------------|-----------|
| 001 | 7 | 7/7 (100%) | 6/7 (86%) | **86%** |
| 002 | 9 | 9/9 (100%) | 9/9 (100%) | **100%** |
| 003 | 6 | 6/6 (100%) | 6/6 (100%) | **100%** |
| 004 | 9 | 9/9 (100%) | 8/9 (89%)* | **89%** |

*Feature 004 TYPE-02 (transactionDetailMachine `any` types) mapping to a task ID is ambiguous.

### Cross-Feature Conflicts

| Conflict Type | Count |
|--------------|-------|
| Same-file implementation (uncoordinated) | 2 (createTransaction, isTransactionPayloadValidator) |
| Plan-to-plan contradictions | 1 (bank transfer type detection) |
| Undocumented implementation order dependencies | 3 |
| Confirmed active bugs in production code | 3 (BUG-01/02/03 in Feature 004) |
| Constitution §4 violations (active) | 13 @ts-ignore/@ts-expect-error instances across 3 features |

### Issue Severity Distribution

| Severity | Count |
|----------|-------|
| CRITICAL | 5 |
| HIGH | 7 |
| MEDIUM | 9 |
| LOW | 5 |
| **Total** | **26** |

---

## 8. Remediation Recommendations

### Before Running Any Implementation Tasks

1. **Resolve C1 (bank transfer type contradiction)** — Convene a single decision: do bank transfers use `transactionType: "payment"` + `source` detection OR `transactionType: "transfer"`? Update both plan 002 and plan 003 to agree before executing any task in either feature.

2. **Coordinate C2 (createTransaction ownership)** — Assign `backend/database.ts → createTransaction()` to a single feature (recommend Feature 002 as the transaction owner). Feature 003 should depend on Feature 002's bank transfer implementation being complete and then *extend* it, not re-implement it.

3. **Fix active bugs first (C3, C4)** — BUG-01/02/03 in Feature 004 are running in the current codebase and corrupt test data. Execute tasks T-003, T-004, T-009 before running any notification or feed test suite.

### Before Feature Sign-Off

4. **Standardize task ID format** — Rename Feature 003 T001 → T-001 (H7). One find-replace operation.

5. **Add cross-feature dependency markers** — Update the following task descriptions:
   - Feature 003 T002/T003: "Depends on Feature 002 T-027 completing first"
   - Feature 004 T-005/T-011: "Depends on T-001 (canAccessTransaction)"
   - Feature 002 T-055: "Depends on Feature 004 like/comment DB helpers"
   - Feature 004 TYPE-02 task: "Depends on Feature 002 T-057"

6. **Resolve H3 (validator conflict)** — Execute Feature 002 T-029 and Feature 003 T002 as a single atomic commit to `backend/validators.ts`. Do not apply them independently.

### Quality Improvements (Optional but Recommended)

7. **Add FR-### identifiers to all specs** (H6) — Number each top-level requirement. This is low-effort and enables formal traceability in any future `/speckit.tasks` run.

8. **Clarify spec 003 GraphQL primacy** (M1) — One sentence change: "GraphQL is the primary frontend interface; REST is available for API-level testing."

9. **Fix spec 004 hedging on comment length** (M4) — Change "typically 500 characters (app may limit)" to "500 characters maximum."

10. **Verify Feature 004 TYPE-02 task coverage** (M7) — Confirm which task in tasks.md covers `transactionDetailMachine.ts any types`. If none, add: `- [ ] T-029 [P] [US3] Replace event type `any` in transactionDetailMachine.ts with discriminated union type`.

---

## Appendix: Recommended Execution Sequence

Given the cross-feature dependencies identified, the safest implementation order is:

```
Phase A (Foundation — can run in parallel per feature):
  001/T-001, 001/T-002  (logout + signup bugs)
  004/T-003, 004/T-004, 004/T-009  (active bugs — run immediately)

Phase B (Core implementations — after C1/C2 resolved):
  001 all remaining tasks (self-contained)
  002/T-001 through T-028 (models, backend, wizard)
  003/T001 through T006 (security fix, validator, @ts-ignore — before 002 bank transfer)

Phase C (Integration — after B complete):
  002/T-027 through T-031 (bank transfer — must coordinate with 003)
  003/T013 through T020 (deposit/withdrawal — depends on 002's createTransaction)
  004/T-001 (canAccessTransaction helper)

Phase D (Social + enrichment — after C complete):
  004/T-005, T-011 (privacy gates — depends on T-001)
  002/T-055 (TransactionResponseItem enrichment — depends on 004 like/comment helpers)
  004/TYPE-02 task (depends on 002/T-057 transactionDetailMachine)

Phase E (Polish — all independent):
  All TSDoc, documentation, visual snapshot, and lint/type verification tasks
```

---

*This analysis is read-only. No files were modified. All findings are based on the artifacts as they exist at time of generation.*

*To remediate issues, run the appropriate `/speckit.specify`, `/speckit.plan`, or manually edit tasks.md with the cross-feature dependency notes described above. For the C1 contradiction, a `/speckit.clarify` session on Feature 002 or 003 is recommended.*

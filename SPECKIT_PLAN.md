# Cypress Real-World App - Implementation Plan

**Version:** 1.0.0  
**Created:** 2026-03-31  
**Status:** Active  
**Based on:** SPECKIT_CONSTITUTION.md, SPECKIT_SPEC.md, SPECKIT_ANALYSIS.md

---

## Executive Summary

This Implementation Plan translates the Constitution and Specification into actionable work phases. It prioritizes the **2 critical issues** identified in the analysis (test coverage metrics, bundle size constraints), organizes work into three phases with clear dependency chains, and establishes risk mitigation strategies.

**Key Metrics:**
- **Phase 1 (CRITICAL):** 35 min, blocks all other work
- **Phase 2 (HIGH):** 120 min, enables consistent development
- **Phase 3 (MEDIUM):** 55 min, quality polish
- **Total Effort:** 210 minutes (3.5 hours of focused work)

---

## Table of Contents

1. [Strategic Objectives](#strategic-objectives)
2. [Implementation Phases](#implementation-phases)
3. [Dependency Chains](#dependency-chains)
4. [Risk Assessment](#risk-assessment)
5. [Resource Requirements](#resource-requirements)
6. [Success Criteria](#success-criteria)
7. [Phase Details](#phase-details)
8. [Timeline & Milestones](#timeline--milestones)
9. [Escalation & Decision Framework](#escalation--decision-framework)

---

## Strategic Objectives

### Primary Goals

1. **Establish Quantified Quality Gates** (CRITICAL)
   - Define measurable test coverage targets (≥85%)
   - Define performance constraints (≤500KB bundle, <2s TTI)
   - Make these gates enforceable in CI/CD

2. **Formalize Development Standards** (HIGH)
   - Document code documentation requirements
   - Create custom Cypress commands registry
   - Standardize terminology across artifacts

3. **Improve Developer Experience** (MEDIUM)
   - Consolidate scattered specifications
   - Add TypeScript interface examples
   - Enhance discoverability of patterns

### Success Definition

- All Constitution principles are enforceable via CI/CD or automated tooling
- New feature teams can start work within 1 hour of onboarding (armed with this plan + spec)
- Documentation is the single source of truth; no reverse-engineering required
- All critical issues from SPECKIT_ANALYSIS.md are resolved

---

## Implementation Phases

### Phase 1: CRITICAL INFRASTRUCTURE (Blocking)

**Objective:** Establish non-negotiable quality gates  
**Effort:** 35 minutes  
**Status:** MUST COMPLETE before any feature work  
**Blocking:** YES — All subsequent phases depend on this

#### Work Items

| ID | Task | Owner | Effort | Dependencies |
|---|---|---|---|---|
| P1-001 | Add quantified test coverage metric to spec | Spec Maintainer | 15 min | None |
| P1-002 | Add bundle size & performance constraints to spec | Architecture Team | 20 min | None |
| P1-003 | Document standard API error response format | Backend Team | 15 min | None |
| P1-004 | Configure CI/CD enforcement for P1-001, P1-002, P1-003 | DevOps/CI Owner | 30 min | P1-001, P1-002, P1-003 |

#### Deliverables

- [ ] SPECKIT_SPEC.md updated with quantified metrics
- [ ] `.specify/standards/PERFORMANCE_TARGETS.md` (reference doc)
- [ ] `.specify/standards/API_ERROR_HANDLING.md` (reference doc)
- [ ] GitHub Actions workflow updated to enforce bundle size & coverage
- [ ] Pre-push hook validates against new metrics

#### Success Criteria (Phase 1)

- ✅ `yarn types` passes with zero errors
- ✅ `yarn test:ci` reports coverage ≥85%
- ✅ `yarn build` reports bundle size ≤500KB gzipped
- ✅ All API endpoints return error responses matching documented format
- ✅ CI/CD pipeline enforces all three metrics; PR fails without passing

#### Acceptance Tests

```bash
# Test 1: Coverage validation
$ yarn test:ci 2>&1 | grep "coverage" | grep -E "≥85%|85%"
# Expected: Test coverage report shows ≥85%

# Test 2: Bundle size validation
$ yarn build 2>&1 | grep "gzip" | grep -E "500|[0-4][0-9]{2}"
# Expected: Bundle size ≤ 500 KB gzipped

# Test 3: API error format validation
$ curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"invalid":"payload"}' 2>/dev/null | jq '.error, .code'
# Expected: Returns { error: "...", code: "VALIDATION_ERROR" }

# Test 4: CI enforcement
$ git push --all 2>&1 | grep -E "failing|coverage|bundle"
# Expected: CI fails if any metric is out of bounds
```

---

### Phase 2: CONSISTENCY & STANDARDS (High Priority)

**Objective:** Formalize development standards and eliminate terminology drift  
**Effort:** 120 minutes  
**Status:** STARTS AFTER Phase 1 passes  
**Blocking:** NO — Nice to have before, required before GA release

#### Work Items

| ID | Task | Owner | Effort | Dependencies |
|---|---|---|---|---|
| P2-001 | Add code documentation requirements to SPECKIT_SPEC.md | Documentation Lead | 25 min | P1-001 |
| P2-002 | Create `.specify/testing/CUSTOM_COMMANDS.md` registry | QA Lead | 45 min | P1-001 |
| P2-003 | Fix terminology: Payment → Transaction System consistently | Technical Writer | 20 min | P1-001 |
| P2-004 | Add endpoint/route glossary to SPECKIT_SPEC.md | Architecture Docs | 15 min | P1-001 |
| P2-005 | Update SPECKIT_DONE_TASKS.md for terminology consistency | Technical Writer | 15 min | P2-003 |
| P2-006 | Create linting rule enforcing TSDoc on public APIs | DevOps/CI Owner | 30 min | P2-001 |

#### Deliverables

- [ ] SPECKIT_SPEC.md sections updated:
  - Code Documentation Standards
  - Terminology Glossary
  - API Contract Examples
- [ ] `.specify/testing/CUSTOM_COMMANDS.md` (full 350+ command registry with examples)
- [ ] `.specify/standards/DOCUMENTATION.md` (TSDoc style guide)
- [ ] SPECKIT_DONE_TASKS.md updated for terminology consistency
- [ ] ESLint rule added: `no-public-api-without-tsdoc`

#### Success Criteria (Phase 2)

- ✅ All public functions in `src/` and `backend/` have TSDoc comments
- ✅ Terminology is consistent across all `.md` files (Payment → Transaction, Route → Endpoint context-aware)
- ✅ Custom Cypress commands registry is complete and discoverable
- ✅ New contributors can find patterns/examples within 5 minutes of reference
- ✅ ESLint enforces TSDoc; CI fails without it

#### Acceptance Tests

```bash
# Test 1: TSDoc coverage
$ npx eslint src/ --rule "@typescript-eslint/require-jsdoc: error" 2>&1
# Expected: Zero errors for public functions

# Test 2: Terminology consistency
$ grep -r "Payment System" .specify/*.md
# Expected: Zero results (should be "Transaction System")

# Test 3: Command registry completeness
$ grep -c "###" .specify/testing/CUSTOM_COMMANDS.md
# Expected: ≥350 command entries

# Test 4: Discoverability
$ grep -A5 "cy.login()" .specify/testing/CUSTOM_COMMANDS.md | head -10
# Expected: Command name, description, parameters, return type, example usage
```

#### Phase 2 Dependencies

```
    ┌─────────────────┐
    │   Phase 1 Done  │
    └────────┬────────┘
             │
    ┌────────┴────────┐
    │                 │
    v                 v
  P2-001         P2-002, P2-003, P2-004
  (25 min)       (80 min)
    │                 │
    └────────┬────────┘
             │
             v
          P2-005         P2-006
          (15 min)       (30 min)
             │                 │
             └────────┬────────┘
                      v
              Phase 2 Complete
```

---

### Phase 3: QUALITY POLISH & DOCUMENTATION (Medium Priority)

**Objective:** Enhance developer experience and data model clarity  
**Effort:** 55 minutes  
**Status:** STARTS AFTER Phase 1 & 2 complete  
**Blocking:** NO — Quality improvements, not functional requirements

#### Work Items

| ID | Task | Owner | Effort | Dependencies |
|---|---|---|---|---|
| P3-001 | Add TypeScript interfaces to SPECKIT_SPEC.md data models section | Data Modeling Team | 40 min | P1-001, P2-004 |
| P3-002 | Create `.specify/features/AUTHENTICATION.md` consolidation | Documentation Lead | 10 min | P2-003 |
| P3-003 | Add bundle size & coverage monitoring dashboard | DevOps/CI Owner | 15 min | P1-002 |
| P3-004 | Update SPECKIT_SPEC.md examples section with Cypress patterns | QA Lead | 10 min | P2-002 |

#### Deliverables

- [ ] SPECKIT_SPEC.md expanded with complete TypeScript interfaces:
  - User, Transaction, Contact, BankAccount
  - Comment, Like, Notification (all variants)
  - BankTransfer, enum definitions
- [ ] `.specify/features/AUTHENTICATION.md` (consolidated auth spec)
- [ ] GitHub Actions dashboard or third-party service integration for metrics tracking
- [ ] SPECKIT_SPEC.md updated with real-world Cypress test examples

#### Success Criteria (Phase 3)

- ✅ All TypeScript interfaces from `src/models/` are documented in spec
- ✅ Authentication requirements consolidated in single source
- ✅ Bundle size trend visible in CI/CD dashboard (weekly report)
- ✅ Test coverage trend visible in CI/CD dashboard (tracked per PR)
- ✅ All major features have Cypress custom command examples in spec

#### Acceptance Tests

```bash
# Test 1: Interface documentation
$ grep -c "interface\|enum" .specify/features/SPECKIT_SPEC.md
# Expected: ≥15 interface/enum definitions

# Test 2: Auth consolidation
$ test -f .specify/features/AUTHENTICATION.md && wc -l .specify/features/AUTHENTICATION.md
# Expected: File exists with ≥100 lines

# Test 3: Dashboard availability
$ curl -s https://github.com/cypress-io/cypress-realworld-app/actions/workflows/ci.yml | grep -i "bundle\|coverage"
# Expected: Metrics visible in latest workflow run

# Test 4: Example discoverability
$ grep -B2 "cy\\.getBySel" .specify/features/SPECKIT_SPEC.md | head -20
# Expected: Real custom command usage examples visible
```

#### Phase 3 Dependencies

```
    ┌─────────────────┐
    │   Phase 2 Done  │
    └────────┬────────┘
             │
    ┌────────┴────────────────────────┐
    │                                  │
    v                                  v
  P3-001                          P3-002, P3-004
  (40 min)                        (20 min)
    │                                  │
    └────────┬─────────────────────────┘
             │
             v
           P3-003
          (15 min)
             │
             v
      Phase 3 Complete
```

---

## Dependency Chains

### Critical Path (Sequential Phases)

```
START
  ↓
Phase 1: CRITICAL INFRASTRUCTURE
  ├─ P1-001: Test coverage metric (15 min)
  ├─ P1-002: Bundle size & performance (20 min)
  ├─ P1-003: API error format (15 min)
  └─ P1-004: CI/CD enforcement (30 min) — Requires P1-001, P1-002, P1-003
  ↓ [MUST PASS]
Phase 2: CONSISTENCY & STANDARDS
  ├─ P2-001: Code documentation spec (25 min)
  ├─ P2-002: Custom commands registry (45 min)
  ├─ P2-003: Terminology fix (20 min)
  ├─ P2-004: Glossary (15 min)
  ├─ P2-005: Update Done Tasks (15 min) — Requires P2-003
  └─ P2-006: Linting rule (30 min) — Requires P2-001
  ↓ [RECOMMENDED]
Phase 3: QUALITY POLISH
  ├─ P3-001: TypeScript interfaces (40 min) — Requires P2-004
  ├─ P3-002: Auth consolidation (10 min) — Requires P2-003
  ├─ P3-003: Monitoring dashboard (15 min) — Requires P1-002
  └─ P3-004: Examples section (10 min) — Requires P2-002
  ↓
COMPLETE
```

### Parallelizable Work

**Phase 1 (Within Phase):**
- P1-001, P1-002, P1-003 can run in parallel (no dependencies)
- P1-004 runs after all three are complete

**Phase 2 (Within Phase):**
- P2-001, P2-002 can run in parallel after Phase 1
- P2-003, P2-004 can run in parallel after Phase 1
- P2-005 requires P2-003
- P2-006 requires P2-001

**Phase 3 (Within Phase):**
- P3-002, P3-004 can run in parallel after Phase 2
- P3-001, P3-003 have different owner dependencies

### Cross-Phase Dependencies

**Phase 1 → Phase 2:** Strict dependency (Phase 1 completion required)
- All Phase 2 work depends on Phase 1 metrics being defined and CI/CD enforcing them

**Phase 2 → Phase 3:** Recommended (Phase 2 completion recommended, not strictly required)
- Phase 3 polish work depends on Phase 2 standards being documented
- P3-001 strictly depends on P2-004 (glossary defines API terminology)
- P3-002 strictly depends on P2-003 (uses corrected terminology)

---

## Risk Assessment

### Risk Register

| # | Risk | Severity | Probability | Impact | Mitigation |
|---|---|---|---|---|---|
| R1 | Phase 1 metrics too strict; existing code fails CI | HIGH | MEDIUM | CRITICAL | Pre-validate metrics against current state; adjust thresholds if needed before enforcement |
| R2 | CI/CD enforcement takes longer than estimated (P1-004) | MEDIUM | MEDIUM | HIGH | Run P1-004 in parallel with other Phase 2 work; don't block on perfect CI setup |
| R3 | Custom Commands registry becomes obsolete (350+ commands to document) | MEDIUM | LOW | MEDIUM | Automate registry generation from JSDoc comments; maintain registry in code, not manually |
| R4 | Terminology change causes merge conflicts in ongoing PRs | MEDIUM | MEDIUM | MEDIUM | Coordinate Phase 2-003 timing; notify active contributors; provide git merge strategy |
| R5 | Performance metrics regress after Phase 1 enforcement | HIGH | LOW | CRITICAL | Monitor closely for first 2 weeks post-enforcement; immediate remediation plan if exceeded |
| R6 | Contributors ignore new standards (TSDoc, terminology) | MEDIUM | MEDIUM | MEDIUM | Enforce via CI/CD linting; include in code review checklist; celebrate early adopters |

### Mitigation Strategies

#### R1: Metric Validation

**Action:** Before running P1-004, execute:

```bash
# Test current coverage
$ yarn test:ci 2>&1 | tail -20

# Test current bundle size
$ yarn build && ls -lh dist/

# Count API endpoints without error format
$ grep -r "res.status" backend/ | wc -l
```

**Decision Gate:** If any metric fails, adjust thresholds in P1-001 to realistic targets, then phase in stricter thresholds over 2 sprints.

#### R2: CI/CD Parallel Work

**Action:** Run P1-004 alongside P2-001, P2-002, P2-003 to avoid blocking. CI setup may take longer than 30 min; schedule this as separate, concurrent work.

#### R3: Automate Registry

**Action:** Instead of manual registry:
1. Generate initial registry via script: `scripts/generate-cypress-commands-registry.ts`
2. Use JSDoc comments as source of truth
3. CI validates registry completeness

#### R4: Terminology Migration

**Action:**
- Coordinate Phase 2-003 with active PR owners
- Provide `scripts/migrate-terminology.ts` (search/replace helper script)
- Announce 2-week notice before Phase 2-003 execution
- Offer to rebase affected PRs

#### R5: Performance Regression

**Action:**
- Monitor bundle size and test coverage weekly for first month
- Alert maintainers if metrics drop >2% from Phase 1 target
- Immediate remediation: revert features or optimize
- Monthly review meeting to discuss metric trends

#### R6: Standards Adoption

**Action:**
- Add enforcement rules to GitHub Branch Protection Rules
- Include standards checklist in PR template
- Reward compliance: highlight PRs that pass all Phase 2 standards
- Pair new contributors with documentation during onboarding

---

## Resource Requirements

### Team Composition

| Role | Effort (Phase 1-3) | Key Tasks | Availability |
|---|---|---|---|
| **Spec Maintainer** | 40 min | P1-001, P2-001 | CRITICAL PATH |
| **Architecture Team** | 50 min | P1-002, P2-004, P3-003 | CRITICAL PATH |
| **Backend Team** | 15 min | P1-003 | CRITICAL PATH |
| **DevOps/CI Owner** | 75 min | P1-004, P2-006, P3-003 | CRITICAL PATH |
| **Documentation Lead** | 35 min | P2-001, P3-002 | HIGH PRIORITY |
| **QA Lead** | 55 min | P2-002, P3-004 | HIGH PRIORITY |
| **Technical Writer** | 35 min | P2-003, P2-005 | HIGH PRIORITY |
| **Data Modeling Team** | 40 min | P3-001 | MEDIUM PRIORITY |

### Required Tools & Access

- **GitHub Admin Access:** To update Branch Protection Rules (P1-004)
- **GitHub Actions:** CI/CD workflow editing (P1-004, P2-006, P3-003)
- **npm/yarn:** Package management for tooling (all phases)
- **ESLint/TypeScript:** For validation rules (P2-006)
- **Code Editor:** VS Code recommended for bulk search/replace (P2-003, P2-005)

### Timeline Allocation

**Week 1 (Phase 1 — CRITICAL):**
- Mon-Tue: P1-001, P1-002, P1-003 (can run in parallel, 20 min each)
- Wed-Thu: P1-004 (CI/CD enforcement, may take 2-3 hours with testing)
- Fri: Validation & fixes

**Week 2 (Phase 2 — HIGH):**
- Mon-Tue: P2-001, P2-002, P2-003, P2-004 (parallel, 15-45 min each)
- Wed-Thu: P2-005, P2-006 (15-30 min each, sequential with P2-003 and P2-001)
- Fri: Testing & fixes

**Week 3 (Phase 3 — MEDIUM):**
- Mon-Tue: P3-001 (large task, 40 min)
- Wed: P3-002, P3-004 (parallel, 10-20 min each)
- Thu-Fri: P3-003 (dashboard, may take longer)

---

## Success Criteria

### Global Success Criteria (All Phases)

| Criterion | How Measured | Target | Phase |
|---|---|---|---|
| **Specification Completeness** | All Constitution principles enforceable | 100% | 1-3 |
| **Developer Onboarding Time** | Time to first feature PR | <2 hours | 1-3 |
| **Test Coverage** | `yarn test:ci` report | ≥85% | 1 |
| **Bundle Size** | `yarn build` gzip report | ≤500 KB | 1 |
| **API Contract Consistency** | All endpoints match error format | 100% | 1 |
| **Code Documentation** | TSDoc coverage on public APIs | 100% | 2 |
| **Terminology Consistency** | `grep -r "Payment System"` in specs | 0 results | 2 |
| **Custom Commands Registry** | `.specify/testing/CUSTOM_COMMANDS.md` exists | ≥350 commands | 2 |
| **CI/CD Enforcement** | All metrics in GitHub Actions | 3+ metrics | 1-3 |

### Phase 1 Success Criteria (CRITICAL)

✅ **Acceptance:** ALL of the following pass:

```bash
# 1. Spec is updated with quantified metrics
grep -E "≥85%|500 KB|2 seconds" /home/brett/projects/cypress-realworld-app/SPECKIT_SPEC.md
# Result: 3+ matches

# 2. Test coverage meets target
yarn test:ci 2>&1 | grep -E "[0-9]+%.*coverage" | tail -1
# Result: Shows ≥85%

# 3. Bundle size meets target
yarn build 2>&1 | grep gzip
# Result: Shows ≤500 KB

# 4. CI workflow enforces metrics
cat .github/workflows/*.yml | grep -i "coverage\|bundle"
# Result: 2+ checks visible

# 5. API error responses are documented
grep -A10 "Error Response Format" /home/brett/projects/cypress-realworld-app/SPECKIT_SPEC.md
# Result: Standard error format documented
```

### Phase 2 Success Criteria (HIGH)

✅ **Acceptance:** ALL of the following pass:

```bash
# 1. Documentation standards in spec
grep -E "TSDoc|@param|@returns" /home/brett/projects/cypress-realworld-app/SPECKIT_SPEC.md | wc -l
# Result: ≥5 references

# 2. Custom commands registry exists
wc -l .specify/testing/CUSTOM_COMMANDS.md
# Result: ≥1000 lines (comprehensive)

# 3. Terminology is consistent
grep -r "Payment System" .specify/ || echo "No 'Payment System' found (good)"
# Result: "No 'Payment System' found"

# 4. Glossary is complete
grep "Endpoint\|Route\|Query\|Mutation" /home/brett/projects/cypress-realworld-app/SPECKIT_SPEC.md
# Result: All 4 terms defined

# 5. ESLint rule enforces TSDoc
npx eslint --print-config src/ | grep -i "tsdoc\|jsdoc"
# Result: Linting rule visible
```

### Phase 3 Success Criteria (MEDIUM)

✅ **Acceptance:** ALL of the following pass:

```bash
# 1. TypeScript interfaces in spec
grep "interface.*{" /home/brett/projects/cypress-realworld-app/SPECKIT_SPEC.md | wc -l
# Result: ≥15 interfaces

# 2. Authentication consolidated
wc -l .specify/features/AUTHENTICATION.md
# Result: ≥150 lines

# 3. Dashboard configured
curl -s https://github.com/cypress-io/cypress-realworld-app/actions | grep -i "metrics\|bundle"
# Result: Metrics visible

# 4. Examples updated
grep -c "cy\\." .specify/features/SPECKIT_SPEC.md
# Result: ≥20 custom command examples
```

---

## Phase Details

### Phase 1: Work Item Specifications

#### P1-001: Add Quantified Test Coverage Metric

**Owner:** Spec Maintainer  
**Effort:** 15 minutes  
**Pre-requisites:** None

**Description:**
SPECKIT_SPEC.md currently documents test files but lacks explicit coverage acceptance criteria. This task adds quantified test coverage requirements to the specification.

**Acceptance Criteria:**
- [ ] SPECKIT_SPEC.md contains new "Test Coverage Requirements" section
- [ ] Section specifies:
  - Application code coverage: ≥85% (excluding models, fixtures)
  - Test execution time: <5 minutes (CI/CD constraint)
  - Flaky test rate: <1% (automated detection)
- [ ] Constitution Principle 3 is directly referenced
- [ ] Current coverage baseline is documented (existing %)

**Definition of Done:**
```markdown
## Test Coverage Requirements

Per Constitution Principle 3 (Comprehensive Testing Discipline), the following coverage targets apply:

- **Application Code Coverage:** ≥85% (excluding model files and database fixtures)
- **Target Scope:** `src/**/*.ts` and `backend/**/*.ts` (excluding `src/models/` and `data/`)
- **Measurement Tool:** `yarn test:ci` with coverage reporter
- **CI/CD Enforcement:** All PRs must report ≥85% coverage; merges blocked below threshold
- **Flaky Test Rate:** <1% (tracked via Cypress Cloud; tests marked flaky block merge)
- **Test Execution Time:** <5 minutes (single browser, optimized for fast feedback)

### Current Baseline

As of implementation date: [INSERT CURRENT COVERAGE %]

### Acceptance Criteria for New Features

Every feature addition must:
1. Include unit tests for business logic
2. Include component/integration tests for UI
3. Include E2E tests for user workflows
4. Maintain or improve overall coverage percentage
5. Have zero flaky tests
```

**Work Steps:**
1. Read current SPECKIT_SPEC.md
2. Add section after "Test Coverage" section (around line 400)
3. Run `yarn test:ci` to get current baseline
4. Insert actual coverage percentage
5. Validate formatting matches surrounding sections
6. Commit to branch

---

#### P1-002: Add Bundle Size & Performance Constraints

**Owner:** Architecture Team  
**Effort:** 20 minutes  
**Pre-requisites:** None

**Description:**
Constitution emphasizes "Simplicity & Learning" and "Zero Production Ambition." No bundle size or performance targets are currently documented in SPECKIT_SPEC.md. This creates risk of feature creep leading to bloated frontend. This task adds quantified performance constraints.

**Acceptance Criteria:**
- [ ] SPECKIT_SPEC.md contains new "Performance Requirements" section
- [ ] Section specifies:
  - Frontend bundle size: ≤500 KB (gzipped)
  - Time to Interactive (TTI): ≤2 seconds
  - Lighthouse score: ≥85 (Performance + Best Practices)
  - API P99 response time: ≤200ms
  - API throughput: ≥1000 requests/sec
- [ ] Current baselines are documented
- [ ] Constitution Principle 2 (Zero Production Ambition) is referenced

**Definition of Done:**
```markdown
## Performance Requirements

Per Constitution Principle 2 (Zero Production Ambition), the project prioritizes simplicity and educational value over advanced optimization. The following performance targets ensure a snappy, responsive application:

### Frontend Performance

| Metric | Target | Measurement | Enforcement |
|---|---|---|---|
| Bundle Size (gzipped) | ≤500 KB | `yarn build && du -sh dist/` | CI checks on every commit |
| Time to Interactive (TTI) | ≤2 seconds | Lighthouse CI / Web Vitals | Reported in PR comments |
| Lighthouse Score | ≥85 (Performance + Best Practices) | Lighthouse CI | Reported in PR comments |
| First Contentful Paint (FCP) | ≤1.5 seconds | Measured on 3G throttle | Lighthouse CI report |

### API Performance

| Metric | Target | Measurement | Enforcement |
|---|---|---|---|
| P99 Response Time | ≤200ms | Monitoring middleware | Logged to console |
| Throughput | ≥1000 req/sec | Load test | Documentation only |
| Database Query Time (P99) | ≤50ms | Query logging | Reported in dev logs |

### Current Baselines

As of implementation date:
- Bundle size (gzipped): [INSERT from `yarn build`]
- Lighthouse score: [INSERT from recent CI run]
- API P99 response time: [INSERT from monitoring]

### Enforcement

- **CI/CD Gate:** Bundle size check blocks merge if exceeds 500 KB
- **Developer Feedback:** `yarn build` displays bundle size with visual indicator (green/yellow/red)
- **Monitoring:** Weekly report of performance trends
```

**Work Steps:**
1. Run `yarn build` and capture bundle size
2. Run Lighthouse CI to get current score
3. Extract API P99 from recent monitoring
4. Add section to SPECKIT_SPEC.md
5. Ensure formatting consistency
6. Commit to branch

---

#### P1-003: Document Standard API Error Response Format

**Owner:** Backend Team  
**Effort:** 15 minutes  
**Pre-requisites:** None

**Description:**
25+ API endpoints exist but error response format is not standardized or documented. This causes frontend/backend mismatch and flaky error handling in tests. Task defines and documents standard error response format.

**Acceptance Criteria:**
- [ ] SPECKIT_SPEC.md contains new "API Error Response Format" section
- [ ] Section specifies:
  - JSON structure: `{ error, code, statusCode, timestamp }`
  - Standard error codes enum (INVALID_REQUEST, UNAUTHORIZED, etc.)
  - HTTP status code mapping
  - Example error responses
- [ ] All current API endpoints are audited for compliance
- [ ] Non-compliant endpoints are identified (can be fixed in future task)

**Definition of Done:**
```markdown
## API Error Response Format

All API endpoints (REST and GraphQL) MUST return error responses in the following standard format:

### Error Response Structure

```json
{
  "error": "Human-readable error description",
  "code": "MACHINE_READABLE_ERROR_CODE",
  "statusCode": 400,
  "timestamp": "2024-03-31T10:45:32.123Z"
}
```

### Field Definitions

- **error** (string, required): Human-readable error message explaining what went wrong
  - Examples: "Invalid email format", "Insufficient balance", "User not found"
  - MUST NOT expose internal implementation details
- **code** (string, required): Machine-readable error code for client-side error handling
  - Enum values (see below)
  - MUST be consistent across equivalent error conditions
- **statusCode** (number, required): Standard HTTP status code
  - Aligned with `code` enum value (see mapping below)
- **timestamp** (ISO8601 string, required): Server-side timestamp of error
  - Useful for debugging and logging
  - Format: `YYYY-MM-DDTHH:mm:ss.SSSZ`

### Standard Error Codes

| Code | HTTP Status | Description | Example |
|---|---|---|---|
| INVALID_REQUEST | 400 | Request validation failed | Missing required field |
| INVALID_FORMAT | 400 | Invalid data format | Invalid email address |
| VALIDATION_ERROR | 422 | Business logic validation failed | Amount exceeds balance |
| UNAUTHORIZED | 401 | Authentication required or failed | Invalid credentials |
| FORBIDDEN | 403 | Authenticated but not authorized | User lacks permission |
| NOT_FOUND | 404 | Resource does not exist | User ID not found |
| CONFLICT | 409 | Resource conflict | Duplicate username |
| RATE_LIMITED | 429 | Too many requests | Rate limit exceeded |
| INTERNAL_ERROR | 500 | Unexpected server error | Database connection failed |

### HTTP Status Code Mapping

- 400 Bad Request: INVALID_REQUEST, INVALID_FORMAT, VALIDATION_ERROR
- 401 Unauthorized: UNAUTHORIZED
- 403 Forbidden: FORBIDDEN
- 404 Not Found: NOT_FOUND
- 409 Conflict: CONFLICT
- 429 Too Many Requests: RATE_LIMITED
- 500 Internal Server Error: INTERNAL_ERROR

### Example Error Responses

#### Invalid Request
```json
{
  "error": "Email field is required",
  "code": "INVALID_REQUEST",
  "statusCode": 400,
  "timestamp": "2024-03-31T10:45:32.123Z"
}
```

#### Invalid Format
```json
{
  "error": "Email format is invalid: not-an-email",
  "code": "INVALID_FORMAT",
  "statusCode": 400,
  "timestamp": "2024-03-31T10:45:32.123Z"
}
```

#### Validation Error
```json
{
  "error": "Cannot send $5000: insufficient balance ($1000 available)",
  "code": "VALIDATION_ERROR",
  "statusCode": 422,
  "timestamp": "2024-03-31T10:45:32.123Z"
}
```

#### Not Found
```json
{
  "error": "User with ID 'abc123' not found",
  "code": "NOT_FOUND",
  "statusCode": 404,
  "timestamp": "2024-03-31T10:45:32.123Z"
}
```

### Implementation Requirements

- **ALL endpoints** (REST and GraphQL) MUST return this format
- **GraphQL errors:** Include `extensions` object with error code
- **Backend middleware:** Express error handler formats all errors to this structure
- **No stack traces** in production responses (log to server, return generic INTERNAL_ERROR to client)
- **Request ID:** Consider adding `requestId` for tracing (optional enhancement)
```

**Work Steps:**
1. Audit current error handling in `backend/` routes
2. Identify current error formats (likely inconsistent)
3. Define standard enum in TypeScript (e.g., `enum ErrorCode`)
4. Add section to SPECKIT_SPEC.md
5. Document mapping between error codes and HTTP status
6. Commit to branch

---

#### P1-004: Configure CI/CD Enforcement

**Owner:** DevOps/CI Owner  
**Effort:** 30 minutes  
**Pre-requisites:** P1-001, P1-002, P1-003 complete

**Description:**
GitHub Actions workflow must enforce the three metrics defined in P1-001, P1-002, P1-003. This ensures new commits automatically validate against quality gates.

**Acceptance Criteria:**
- [ ] GitHub Actions workflow (`.github/workflows/ci.yml`) includes:
  - Test coverage check (must be ≥85%)
  - Bundle size check (must be ≤500 KB gzipped)
  - API error response format validation (spot-check)
- [ ] PR status checks show all three metrics
- [ ] PRs fail merge if any metric is violated
- [ ] Maintainers can override with justification (optional, for hotfixes)
- [ ] PR comments display metric values for visibility

**Definition of Done:**
```yaml
# Add to .github/workflows/ci.yml

- name: Check Test Coverage
  run: |
    yarn test:ci
    COVERAGE=$(yarn test:ci 2>&1 | grep -oP '\d+(?=%)' | tail -1)
    if [ "$COVERAGE" -lt 85 ]; then
      echo "❌ Test coverage $COVERAGE% is below target of 85%"
      exit 1
    fi
    echo "✅ Test coverage $COVERAGE% meets target"

- name: Check Bundle Size
  run: |
    yarn build
    SIZE=$(du -sh dist/ | awk '{print $1}')
    SIZE_KB=$(du -sk dist/ | awk '{print $1}')
    if [ "$SIZE_KB" -gt 512000 ]; then  # 500 KB in KB
      echo "❌ Bundle size $SIZE exceeds target of 500 KB gzipped"
      exit 1
    fi
    echo "✅ Bundle size $SIZE is within target"

- name: Validate API Error Responses
  run: |
    # Spot-check: verify error response format in backend
    grep -r "error.*code.*statusCode" backend/ > /dev/null || true
    echo "⚠️  Manual validation recommended for error format compliance"
```

**Work Steps:**
1. Access `.github/workflows/ci.yml`
2. Add three new steps to CI pipeline (above)
3. Test workflow with dummy PR
4. Verify status checks appear on PR
5. Verify PR fails if coverage drops
6. Update branch protection rules to require all three checks
7. Commit to main

---

### Phase 2: Work Item Specifications

#### P2-001: Add Code Documentation Requirements

**Owner:** Documentation Lead  
**Effort:** 25 minutes  
**Pre-requisites:** P1-001

**Description:**
Constitution Principle 1 emphasizes "inline comments explaining the 'why'." SPECKIT_SPEC.md currently lacks code documentation requirements. Implementation teams need clear guidance on comment density, style, and TSDoc usage.

**Deliverable:**
Add new section to SPECKIT_SPEC.md:

```markdown
## Code Documentation Standards

Per Constitution Principle 1 (Educational Excellence), all code must prioritize clarity and teachability. Documentation serves as teaching material for developers learning the codebase.

### TSDoc Requirements

All **public functions, methods, types, and constants** MUST have TSDoc comments:

```typescript
/**
 * Initiates a payment transaction between two users.
 *
 * This function validates the sender's balance, creates a transaction record,
 * and updates both users' account states. It does NOT process real payments.
 *
 * @param senderId - UUID of the user initiating the payment
 * @param recipientId - UUID of the receiving user
 * @param amount - Payment amount in cents (e.g., 5000 = $50.00)
 * @param description - User-provided memo or note (max 500 chars)
 * @returns Transaction object with auto-generated ID and timestamps
 * @throws ValidationError if validation fails (insufficient balance, invalid amount)
 * @throws NotFoundError if sender or recipient user not found
 *
 * @example
 * const txn = await createPayment(
 *   "user-123",
 *   "user-456",
 *   1000,
 *   "Lunch reimbursement"
 * );
 * console.log(txn.id); // "txn-xyz"
 */
export async function createPayment(
  senderId: string,
  recipientId: string,
  amount: number,
  description: string
): Promise<Transaction> {
  // Implementation...
}
```

### Inline Comment Requirements

All **complex business logic, non-obvious algorithms, and educational patterns** MUST have inline comments explaining the "why":

```typescript
// ✅ GOOD: Explains rationale
function validateBankTransfer(amount: number, balance: number): void {
  // We check balance first to provide early failure and specific error message
  if (amount > balance) {
    throw new ValidationError("Insufficient balance");
  }
  
  // Amounts must be >= 1 cent per business logic
  if (amount < 1) {
    throw new ValidationError("Amount must be at least $0.01");
  }
}

// ❌ BAD: No explanation (confusing to learners)
function validateBankTransfer(amount: number, balance: number): void {
  if (amount > balance) throw new ValidationError("Insufficient balance");
  if (amount < 1) throw new ValidationError("Amount must be at least $0.01");
}
```

### Component Documentation

React components MUST have a comment block above the component definition:

```typescript
/**
 * Displays a paginated list of transactions with filtering options.
 *
 * - Filters by date range, amount range, and status
 * - Supports sorting by date or amount
 * - Lazy-loads transaction details on hover
 * - Accessible: ARIA labels on all interactive elements
 *
 * Props: See TransactionListProps interface below
 */
export function TransactionList(props: TransactionListProps): JSX.Element {
  // Implementation...
}
```

### Custom Cypress Commands

All custom Cypress commands MUST be documented in `.specify/testing/CUSTOM_COMMANDS.md` with:
- Command name and usage
- Parameters and types
- Return value
- Example usage

### Deprecation & Migration

Deprecated APIs MUST include:
- TSDoc `@deprecated` tag
- Reason for deprecation
- Migration path to new API
- Removal timeline (2 version grace period minimum)

```typescript
/**
 * @deprecated Use `createTransaction()` instead (v2.0+)
 * Reason: Renamed for consistency with API terminology
 * Migration: Replace all `createPayment()` calls with `createTransaction()`
 * Removal: Will be removed in v3.0
 */
export function createPayment(...) { /* ... */ }
```

### README and Guides

Every major feature MUST have a markdown guide in `.specify/features/`:
- **Feature Overview:** What it does and why it matters
- **Architecture:** System design and data flow
- **Usage Examples:** Real code examples
- **Testing:** How to test the feature
- **Troubleshooting:** Common issues and solutions
```

**Work Steps:**
1. Create section in SPECKIT_SPEC.md
2. Include TSDoc example for payment function
3. Include inline comment example for validation
4. Include component documentation pattern
5. Reference Constitution Principle 1
6. Link to `.specify/` feature guides
7. Commit to branch

---

#### P2-002: Create Custom Cypress Commands Registry

**Owner:** QA Lead  
**Effort:** 45 minutes  
**Pre-requisites:** P1-001

**Description:**
Constitution Principle 5 mandates "custom commands as single source of truth." SPECKIT_DONE_TASKS.md mentions "350+ custom commands" but no registry exists. Implementation teams cannot discover patterns without reverse-engineering from test code. This task creates comprehensive registry.

**Deliverable:**
Create `.specify/testing/CUSTOM_COMMANDS.md` with registry of 350+ commands.

```markdown
# Cypress Custom Commands Registry

**Purpose:** Single source of truth for all custom Cypress commands. Developers MUST use these commands instead of direct selectors or actions in test code.

**Organization:**
- Commands grouped by domain (auth, database, UI, etc.)
- Each entry includes: name, parameters, return type, usage example
- Sorted alphabetically within each domain

## Authentication Commands

### `cy.login()`

**Description:** Logs in a user via local authentication (Passport.js)

**Parameters:**
- `username: string` - Username or email
- `password: string` - User password
- `options?: { remember?: boolean }` - Optional remember-me flag

**Returns:** `void` (sets cookies, updates user state)

**Example:**
```typescript
cy.login("alice", "password123");
// User is now logged in for the test

cy.login("bob", "password456", { remember: true });
// User is logged in with "remember me" flag
```

**Implementation Note:** Uses POST /api/auth/login endpoint; updates session cookie

---

### `cy.logout()`

**Description:** Logs out the current user

**Parameters:** None

**Returns:** `void` (clears cookies, navigates to login)

**Example:**
```typescript
cy.login("alice", "password123");
cy.logout();
// User is logged out
```

**Implementation Note:** Calls POST /api/auth/logout; clears all cookies

---

### `cy.loginWithAuth0(email, password)`

**Description:** Logs in via Auth0 provider (OAuth flow)

**Parameters:**
- `email: string` - Auth0 account email
- `password: string` - Auth0 account password

**Returns:** `void`

**Prerequisites:** Auth0 credentials must be configured in CI environment variables

**Example:**
```typescript
cy.loginWithAuth0("test@auth0.com", "password123");
```

---

### `cy.loginWithOkta(email, password)`

**Description:** Logs in via Okta provider (OAuth flow)

**Parameters:**
- `email: string` - Okta account email
- `password: string` - Okta account password

**Returns:** `void`

**Prerequisites:** Okta credentials configured in CI

---

### `cy.getUser()`

**Description:** Retrieves currently logged-in user object

**Parameters:** None

**Returns:** `Cypress.Chainable<User>` - User object from state

**Example:**
```typescript
cy.getUser().then((user) => {
  expect(user.username).to.equal("alice");
  expect(user.balance).to.be.greaterThan(0);
});
```

---

## UI Commands

### `cy.getBySel(selector)`

**Description:** Finds DOM element by `data-testid` attribute (preferred over class/ID selectors)

**Parameters:**
- `selector: string` - Value of `data-testid` attribute

**Returns:** `Cypress.Chainable<JQuery>` - DOM element

**Example:**
```typescript
// HTML: <button data-testid="send-payment-btn">Send</button>
cy.getBySel("send-payment-btn").click();

// Chain with other commands
cy.getBySel("amount-input").type("5000");
```

**Implementation Note:** Uses `[data-testid="..."]` selector internally

---

### `cy.getByLabel(label)`

**Description:** Finds form element by associated label text

**Parameters:**
- `label: string` - Label text (case-insensitive)

**Returns:** `Cypress.Chainable<JQuery>`

**Example:**
```typescript
cy.getByLabel("Email").type("test@example.com");
cy.getByLabel("Password").type("password123");
```

---

### `cy.contains(text, options?)`

**Description:** Finds element containing exact text

**Parameters:**
- `text: string` - Exact text to find
- `options?: { partial?: boolean, matchCase?: boolean }` - Search options

**Returns:** `Cypress.Chainable<JQuery>`

**Example:**
```typescript
cy.contains("Send Payment").click();
cy.contains("Insufficient balance", { partial: true }).should("be.visible");
```

---

## Database Commands

### `cy.database(method, query?)`

**Description:** Interacts with test database (JSON-based) without HTTP calls

**Parameters:**
- `method: 'seed' | 'find' | 'filter' | 'update' | 'delete'` - Database operation
- `query?: object` - Query parameters for find/filter/update

**Returns:** `Cypress.Chainable<any>` - Query result

**Example:**
```typescript
// Seed fresh database state
cy.database("seed");

// Find specific user
cy.database("find", { table: "users", id: "user-1" }).then((user) => {
  expect(user.username).to.equal("alice");
});

// Filter transactions by amount
cy.database("filter", {
  table: "transactions",
  where: { amount: { $gt: 5000 } }
}).then((largeTxns) => {
  expect(largeTxns.length).to.be.greaterThan(0);
});

// Update user balance
cy.database("update", {
  table: "users",
  id: "user-1",
  data: { balance: 10000 }
});
```

**Prerequisites:** Test database must be running (handled by `cy.task()`)

---

### `cy.task(task, arg?)`

**Description:** Runs Node.js code in Cypress task handler

**Parameters:**
- `task: string` - Task name defined in cypress.config.ts
- `arg?: any` - Optional argument to task

**Returns:** `Cypress.Chainable<any>` - Task result

**Common Tasks:**
- `db:seed` - Reset database to seed state
- `db:clear` - Clear all data
- `auth:createUser` - Create test user via backend

**Example:**
```typescript
cy.task("db:seed");  // Reset for clean test state
cy.task("auth:createUser", {
  username: "testuser",
  email: "test@example.com",
  password: "password123"
});
```

---

## API Commands

### `cy.api(method, url, payload?)`

**Description:** Performs HTTP request to backend API without UI interaction

**Parameters:**
- `method: 'GET' | 'POST' | 'PUT' | 'DELETE'` - HTTP method
- `url: string` - API endpoint path (relative to API_URL)
- `payload?: object` - Request body (for POST/PUT)

**Returns:** `Cypress.Chainable<Response>`

**Example:**
```typescript
// Create transaction via API
cy.api("POST", "/api/transactions", {
  recipientId: "user-2",
  amount: 5000,
  description: "Test payment"
}).then((response) => {
  expect(response.status).to.equal(201);
  expect(response.body.id).to.exist;
});

// Fetch user via API
cy.api("GET", "/api/users/me").then((response) => {
  expect(response.status).to.equal(200);
  expect(response.body.username).to.equal("alice");
});
```

---

## GraphQL Commands

### `cy.graphql(query, variables?)`

**Description:** Executes GraphQL query

**Parameters:**
- `query: string` - GraphQL query string
- `variables?: object` - Query variables

**Returns:** `Cypress.Chainable<Response>`

**Example:**
```typescript
cy.graphql(`
  query listBankAccounts {
    listBankAccount {
      id
      bankName
      accountNumber
    }
  }
`).then((response) => {
  expect(response.body.data.listBankAccount).to.have.length.greaterThan(0);
});
```

---

## Assertion Commands

### `cy.shouldBeVisible(selector)`

**Description:** Assert element is visible on screen

**Parameters:**
- `selector: string` - Element selector (use `cy.getBySel()` first)

**Returns:** `void`

**Example:**
```typescript
cy.getBySel("success-message").should("be.visible");
```

---

### `cy.shouldNotBeVisible(selector)`

**Description:** Assert element is not visible

**Parameters:**
- `selector: string` - Element selector

**Returns:** `void`

---

### `cy.shouldHaveText(selector, text)`

**Description:** Assert element contains specific text

**Parameters:**
- `selector: string` - Element selector
- `text: string` - Expected text

**Returns:** `void`

**Example:**
```typescript
cy.getBySel("balance-display").should("have.text", "$500.00");
```

---

## Utility Commands

### `cy.waitForNav()`

**Description:** Waits for navigation to complete and DOM to settle

**Parameters:** None

**Returns:** `void`

**Example:**
```typescript
cy.getBySel("logout-btn").click();
cy.waitForNav();  // Wait for navigation to login page
cy.location("pathname").should("equal", "/login");
```

---

### `cy.delay(ms)`

**Description:** Wait for specified milliseconds (use sparingly)

**Parameters:**
- `ms: number` - Milliseconds to wait

**Returns:** `void`

**Anti-pattern:** Prefer explicit waits (e.g., `should()`) over `cy.delay()`

---

## Decision Tree: When to Create a Custom Command

**Question 1:** Is this interaction used in multiple tests?
- YES → Consider extracting to custom command
- NO → Use `cy.get()`, `cy.click()` directly in test

**Question 2:** Does it hide implementation details?
- YES → Custom command improves readability
- NO → Inline code is fine

**Question 3:** Is it a business domain operation?
- YES (e.g., "log in", "create payment") → Custom command
- NO (e.g., "click button", "type text") → Inline code

**Recommendation:**
- If YES to any of above → Create custom command
- Otherwise → Use standard Cypress commands

**Example Decision:**

```typescript
// ❌ DON'T: Inline business operation
test("user can send payment", () => {
  cy.login("alice", "password123");
  cy.get('[data-testid="new-payment-btn"]').click();
  cy.get('input[name="recipient"]').type("bob");
  cy.get('input[name="amount"]').type("5000");
  cy.get('[data-testid="send-btn"]').click();
  cy.contains("Payment sent").should("be.visible");
});

// ✅ DO: Extract to custom command
test("user can send payment", () => {
  cy.login("alice", "password123");
  cy.sendPayment("bob", 5000);
  cy.contains("Payment sent").should("be.visible");
});

// Custom command in support/commands.ts
Cypress.Commands.add("sendPayment", (recipient, amount) => {
  cy.getBySel("new-payment-btn").click();
  cy.getByLabel("Recipient").type(recipient);
  cy.getByLabel("Amount").type(String(amount));
  cy.getBySel("send-btn").click();
});
```

---

## Command Maintenance

- Commands MUST be version-stable; breaking changes require major version bump
- All command modifications MUST include migration guide
- Deprecated commands require 2-version grace period before removal
- Add commands to this registry BEFORE using in tests

```

**Work Steps:**
1. Review current custom commands in `cypress/support/commands.ts`
2. Extract each command signature and documentation
3. Create `.specify/testing/CUSTOM_COMMANDS.md`
4. Document 350+ commands (use script to help if available)
5. Add decision tree for when to create commands
6. Include maintenance section
7. Commit to branch

---

#### P2-003: Fix Terminology (Payment → Transaction System)

**Owner:** Technical Writer  
**Effort:** 20 minutes  
**Pre-requisites:** P1-001

**Description:**
SPECKIT_DONE_TASKS.md uses "Payment System" throughout. SPECKIT_SPEC.md refers to "Transaction System" with 3 types (Payment, Request, Transfer). Standardize terminology for consistency.

**Changes:**
- Replace "Payment System" → "Transaction System" in SPECKIT_DONE_TASKS.md
- Clarify sub-types: Payment, Request, Bank Transfer
- Ensure terminology is consistent across all `.specify/` and root markdown files

**Acceptance Criteria:**
- [ ] SPECKIT_DONE_TASKS.md uses "Transaction System" (0 instances of "Payment System")
- [ ] All `.md` files use consistent terminology
- [ ] Sub-types are clearly labeled: "Payment (P2P Transfer)", "Request (Payment Request)", "Bank Transfer"
- [ ] No automated grep tools flag inconsistency

**Definition of Done:**
```bash
# Verify no "Payment System" found
grep -r "Payment System" .specify/ SPECKIT*.md || echo "✅ Terminology consistent"

# Verify "Transaction System" is used
grep -c "Transaction System" SPECKIT_SPEC.md
# Expected: ≥5 occurrences
```

---

#### P2-004: Add Endpoint/Route Glossary

**Owner:** Architecture Documentation  
**Effort:** 15 minutes  
**Pre-requisites:** P1-001

**Description:**
SPECKIT_SPEC.md uses "Endpoint" for REST/GraphQL APIs. Backend code uses "routes" (Express terminology). Add glossary to clarify perspective.

**Deliverable:**
Add glossary section to SPECKIT_SPEC.md:

```markdown
## Terminology & Glossary

**Purpose:** Clear communication between frontend and backend teams. Same concepts may have different names depending on perspective.

### Key Definitions

| Term | Definition | Perspective | Example |
|---|---|---|---|
| **Endpoint** | HTTP API path with method | Frontend/API consumer | `POST /api/transactions` |
| **Route** | Express route handler | Backend implementation | `app.post('/api/transactions', handler)` |
| **Query** | GraphQL data retrieval | API (query layer) | `{ listBankAccount { id } }` |
| **Mutation** | GraphQL state change | API (mutation layer) | `mutation CreateAccount { ... }` |
| **Transaction** | Umbrella term for all transfers | Business logic | Includes Payments, Requests, Bank Transfers |
| **Payment** | P2P transfer (subset of Transaction) | Business logic | User A sends money to User B |
| **Request** | Payment request (subset of Transaction) | Business logic | User A requests money from User B |
| **Bank Transfer** | Deposit/Withdrawal (subset of Transaction) | Business logic | User transfers to/from bank account |
| **Custom Command** | Reusable test helper | Cypress testing | `cy.login()`, `cy.sendPayment()` |
| **Task** | Node.js code executed from test | Cypress testing | `cy.task("db:seed")` |

### Perspective-Specific Usage

**Frontend Developer (consuming API):**
> "I need to call the POST /api/transactions endpoint to send a payment"

**Backend Developer (implementing API):**
> "I created a POST route in Express that handles transaction creation"

**Test Engineer (writing Cypress tests):**
> "I use the cy.sendPayment() custom command which internally calls the endpoint"

**All teams:**
> "We store the transaction data in the database and reference it by ID"
```

**Work Steps:**
1. Add glossary section to SPECKIT_SPEC.md
2. Create table mapping terms to definitions and perspectives
3. Add usage examples for each term
4. Ensure consistency with Constitution terminology
5. Commit to branch

---

#### P2-005: Update SPECKIT_DONE_TASKS.md for Consistency

**Owner:** Technical Writer  
**Effort:** 15 minutes  
**Pre-requisites:** P2-003 (terminology fix)

**Description:**
After P2-003 updates terminology, SPECKIT_DONE_TASKS.md may reference old terminology. Update all instances to match new standards.

**Acceptance Criteria:**
- [ ] All "Payment System" references updated to "Transaction System"
- [ ] Sub-types clarified consistently
- [ ] Cross-references to SPECKIT_SPEC.md are accurate

---

#### P2-006: Create ESLint Rule for TSDoc Enforcement

**Owner:** DevOps/CI Owner  
**Effort:** 30 minutes  
**Pre-requisites:** P2-001

**Description:**
GitHub Actions must enforce TSDoc requirements from P2-001. ESLint rule ensures all public functions have TSDoc comments.

**Acceptance Criteria:**
- [ ] `.eslintrc` or ESLint config includes rule requiring JSDoc/TSDoc on public exports
- [ ] Rule is enabled in CI pipeline
- [ ] CI fails if public function lacks TSDoc
- [ ] Developers get clear error message with fix suggestion

**Definition of Done:**
```bash
# ESLint configuration
{
  "@typescript-eslint/require-jsdoc": [
    "error",
    {
      "require": {
        "FunctionDeclaration": true,
        "MethodDefinition": true,
        "ClassDeclaration": true,
        "ArrowFunctionExpression": true,
        "FunctionExpression": true
      },
      "checkGetters": true,
      "checkSetters": true,
      "checkConstructors": false,
      "exemptEmptyFunctions": false
    }
  ]
}

# CI step
- name: Check TSDoc Coverage
  run: |
    npx eslint src backend --rule "@typescript-eslint/require-jsdoc: error"
    if [ $? -ne 0 ]; then
      echo "❌ TSDoc comments missing on public APIs"
      exit 1
    fi
    echo "✅ All public APIs have TSDoc comments"
```

---

### Phase 3: Work Item Specifications

#### P3-001: Add TypeScript Interfaces to SPECKIT_SPEC.md

**Owner:** Data Modeling Team  
**Effort:** 40 minutes  
**Pre-requisites:** P2-004

**Description:**
SPECKIT_SPEC.md documents 8 data models conceptually. No actual TypeScript interfaces provided. Developers must reverse-engineer types from source code. This task adds interface examples for all major models.

**Deliverable:**
Add new section "Data Model Interfaces" to SPECKIT_SPEC.md with full TypeScript definitions:

```typescript
// User Model
export interface User {
  id: string;                              // Short ID (auto-generated)
  uuid: string;                            // UUID (unique across systems)
  firstName: string;
  lastName: string;
  username: string;                        // Unique login identifier
  password: string;                        // Bcrypt hashed (never exposed in responses)
  email: string;                           // Unique email address
  phoneNumber: string;
  balance: number;                         // Account balance in cents
  avatar: string;                          // Avatar URL or base64
  defaultPrivacyLevel: DefaultPrivacyLevel;
  createdAt: Date;
  modifiedAt: Date;
}

export enum DefaultPrivacyLevel {
  PUBLIC = "public",
  PRIVATE = "private",
  CONTACTS = "contacts"
}

// Transaction Model
export interface Transaction {
  id: string;                              // Short ID
  uuid: string;                            // UUID
  type: TransactionType;                   // Payment, Request, or Transfer
  senderId: string;                        // User initiating transaction
  receiverId: string;                      // User receiving transaction
  source: string;                          // Empty for P2P; BankAccount ID for transfers
  amount: number;                          // Amount in cents
  description: string;                     // User-provided memo (max 500 chars)
  privacyLevel: DefaultPrivacyLevel;
  status: TransactionStatus;
  requestStatus?: TransactionRequestStatus; // For requests only
  requestResolvedAt?: Date;                // When request was resolved
  balanceAtCompletion?: number;            // Sender's balance after completion
  createdAt: Date;
  modifiedAt: Date;
}

export enum TransactionType {
  PAYMENT = "payment",
  REQUEST = "request",
  TRANSFER = "transfer"
}

export enum TransactionStatus {
  PENDING = "pending",
  INCOMPLETE = "incomplete",
  COMPLETE = "complete"
}

export enum TransactionRequestStatus {
  PENDING = "pending",
  ACCEPTED = "accepted",
  REJECTED = "rejected"
}

// Contact Model
export interface Contact {
  id: string;
  uuid: string;
  userId: string;                          // Contact owner
  contactUserId: string;                   // User being added as contact
  createdAt: Date;
  modifiedAt: Date;
}

// BankAccount Model
export interface BankAccount {
  id: string;
  uuid: string;
  userId: string;                          // Account owner
  bankName: string;                        // Institution name (e.g., "Chase", "Wells Fargo")
  accountNumber: string;                   // Obfuscated (e.g., "****1234")
  routingNumber: string;                   // Routing number
  isDeleted: boolean;                      // Soft delete flag
  createdAt: Date;
  modifiedAt: Date;
}

// Comment Model
export interface Comment {
  id: string;
  uuid: string;
  content: string;                         // Comment text (max 500 chars)
  userId: string;                          // Comment author
  transactionId: string;                   // Commented transaction
  createdAt: Date;
  modifiedAt: Date;
}

// Like Model
export interface Like {
  id: string;
  uuid: string;
  userId: string;                          // User who liked
  transactionId: string;                   // Liked transaction
  createdAt: Date;
  modifiedAt: Date;
}

// Notification Models (Union Type)
export type Notification = PaymentNotification | LikeNotification | CommentNotification;

export interface BaseNotification {
  id: string;
  uuid: string;
  userId: string;                          // Recipient user
  transactionId: string;                   // Referenced transaction
  isRead: boolean;
  createdAt: Date;
  modifiedAt: Date;
}

export interface PaymentNotification extends BaseNotification {
  type: "payment";
  status: "requested" | "received" | "incomplete";
}

export interface LikeNotification extends BaseNotification {
  type: "like";
  likeId: string;                          // Reference to Like record
}

export interface CommentNotification extends BaseNotification {
  type: "comment";
  commentId: string;                       // Reference to Comment record
}

export enum NotificationType {
  PAYMENT = "payment",
  LIKE = "like",
  COMMENT = "comment"
}

// BankTransfer Model
export interface BankTransfer {
  id: string;
  uuid: string;
  userId: string;                          // User performing transfer
  source: string;                          // BankAccount ID
  amount: number;                          // Amount in cents
  type: BankTransferType;                  // deposit | withdrawal
  transactionId: string;                   // Associated transaction
  createdAt: Date;
  modifiedAt: Date;
}

export enum BankTransferType {
  DEPOSIT = "deposit",
  WITHDRAWAL = "withdrawal"
}
```

**Work Steps:**
1. Extract all model types from `src/models/` and `backend/models/`
2. Add TypeScript interface definitions to SPECKIT_SPEC.md
3. Include field descriptions and type constraints
4. Cross-reference with existing "Data Models" section
5. Ensure consistency with API error codes and transaction types
6. Commit to branch

---

#### P3-002: Consolidate Authentication Specification

**Owner:** Documentation Lead  
**Effort:** 10 minutes  
**Pre-requisites:** P2-003

**Description:**
Authentication requirements are scattered across Constitution, Spec, and Done Tasks. Create consolidated auth specification in `.specify/features/AUTHENTICATION.md`.

**Deliverable:**
Create `.specify/features/AUTHENTICATION.md`:

```markdown
# Authentication & Authorization Specification

**Purpose:** Consolidated documentation of all authentication providers, flows, and patterns

## Supported Providers

### Local Authentication (Passport.js)
- Username/email + password
- Bcrypt password hashing
- Session-based (24-hour default)
- Remember-me flag (extends to 30 days)

### Auth0 (OAuth 2.0)
- Authorization Code flow
- Session exchange via callback
- MFA support (if configured)

### Okta (OAuth 2.0)
- Similar to Auth0
- Enterprise SSO integration
- MFA support

### AWS Cognito (OAuth 2.0)
- Amazon identity service
- MFA support
- Federation with IAM

### Google (OAuth 2.0)
- Google Identity Platform
- One-tap sign-in support

## Authentication Flows

### Local Login Flow
1. User submits username + password
2. Server verifies against bcrypt hash
3. Session created if valid
4. Cookie set for 24 hours (or 30 days if remember-me)
5. Redirect to dashboard

### OAuth Login Flow (Auth0, Okta, AWS Cognito, Google)
1. User clicks "Sign in with [Provider]"
2. Redirects to provider's login page
3. User authenticates with provider
4. Provider redirects back to callback URL with authorization code
5. Backend exchanges code for ID token
6. Session created and user logged in
7. Redirect to dashboard

## Multi-Auth Parity

Per Constitution Principle 7:
- ALL authentication flows (login, logout, token refresh, MFA) MUST work identically across all providers
- Tests MUST include provider-specific auth flows
- New auth providers require auth-specific test suite additions

## Session Management

| Provider | Session Duration | Remember Me | Token Refresh |
|---|---|---|---|
| Local | 24 hours | 30 days | N/A |
| Auth0 | 24 hours | 30 days | OAuth token |
| Okta | 24 hours | 30 days | OAuth token |
| AWS Cognito | 24 hours | 30 days | OAuth token |
| Google | 24 hours | 30 days | OAuth token |

## Credentials Management

- **Credentials MUST NOT be stored in version control**
- Use environment variables or CI secrets:
  - `AUTH0_CLIENT_ID`, `AUTH0_CLIENT_SECRET`
  - `OKTA_CLIENT_ID`, `OKTA_CLIENT_SECRET`
  - `AWS_COGNITO_CLIENT_ID`, `AWS_COGNITO_CLIENT_SECRET`
  - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`

## Testing Authentication

### Local Auth Tests
- Valid credentials → login succeeds
- Invalid credentials → login fails
- Remember-me flag → session extended to 30 days
- Session timeout → redirect to login

### OAuth Provider Tests
- Authorization code flow → login succeeds
- Invalid code → login fails
- Token refresh → session continues
- Logout → session cleared

### Custom Cypress Commands

```typescript
cy.login(username, password, options);
cy.loginWithAuth0(email, password);
cy.loginWithOkta(email, password);
cy.loginWithCognito(email, password);
cy.loginWithGoogle(email, password);
cy.logout();
```

## API Endpoints

| Endpoint | Method | Purpose | Auth Required |
|---|---|---|---|
| `/api/auth/login` | POST | Local login | No |
| `/api/auth/logout` | POST | Logout | Yes |
| `/api/auth/me` | GET | Current user info | Yes |
| `/api/auth/refresh` | POST | Refresh token | Yes |
| `/api/auth/callback` | GET | OAuth callback | No |

## Security Considerations

- Passwords are bcrypt hashed (cost factor: 10)
- Cookies are HTTP-only (not accessible to JavaScript)
- CSRF tokens on state-changing endpoints
- Session tokens are signed (JWT or session ID)
- Rate limiting on login attempts (5 per minute per IP)

---

# Authorization

Authorization enforces what authenticated users can do.

## User-Based Authorization

- Users can only view/modify their own transactions
- Users can only edit their own profile
- Users can only manage their own bank accounts

## Privacy Levels

Transactions respect privacy levels:
- **public**: Visible to all authenticated users
- **private**: Visible only to transaction participants
- **contacts**: Visible to participants and their contacts

## Role-Based Access Control (Future)

Currently, all users have equal permissions. Future roles:
- `admin` - Can moderate and remove content
- `support` - Can view transaction details for support
```

---

#### P3-003: Add Performance Monitoring Dashboard

**Owner:** DevOps/CI Owner  
**Effort:** 15 minutes  
**Pre-requisites:** P1-002

**Description:**
Track bundle size and test coverage trends over time. Display in CI/CD dashboard or comment on PRs for visibility.

**Deliverable:**
Add monitoring to GitHub Actions:

```yaml
- name: Post Performance Metrics to PR
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v6
  with:
    script: |
      const fs = require('fs');
      const coverage = fs.readFileSync('coverage/coverage-summary.json', 'utf8');
      const bundle = fs.readFileSync('dist/stats.json', 'utf8');
      
      const coverageData = JSON.parse(coverage).total.lines.pct;
      const bundleSize = '500 KB'; // Parse from build output
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `📊 **Performance Metrics**
      
      | Metric | Current | Target | Status |
      |---|---|---|---|
      | Test Coverage | ${coverageData}% | ≥85% | ${coverageData >= 85 ? '✅' : '⚠️'} |
      | Bundle Size | ${bundleSize} | ≤500 KB | ✅ |
      | Lighthouse | N/A | ≥85 | ⏳ |`
      });
```

---

#### P3-004: Add Cypress Examples to SPECKIT_SPEC.md

**Owner:** QA Lead  
**Effort:** 10 minutes  
**Pre-requisites:** P2-002

**Description:**
SPECKIT_SPEC.md should include real-world Cypress test examples demonstrating custom command usage and best practices.

**Deliverable:**
Add examples section:

```markdown
## Test Examples

### Example 1: Login & Send Payment

```typescript
describe("Payment feature", () => {
  it("user can send payment to contact", () => {
    // Login using custom command
    cy.login("alice", "password123");
    
    // Navigate to payments
    cy.getBySel("nav-payments").click();
    
    // Create new payment
    cy.getBySel("new-payment-btn").click();
    cy.getByLabel("Recipient").type("bob");
    cy.getByLabel("Amount").type("5000");
    cy.getBySel("send-btn").click();
    
    // Verify success
    cy.contains("Payment sent successfully").should("be.visible");
    
    // Verify transaction in database
    cy.database("filter", {
      table: "transactions",
      where: { senderId: "user-alice", amount: 5000 }
    }).then((txns) => {
      expect(txns).to.have.length(1);
    });
  });
});
```

### Example 2: Request Money via API

```typescript
describe("Payment request feature", () => {
  it("user can request money via API", () => {
    cy.login("alice", "password123");
    
    cy.api("POST", "/api/transactions", {
      type: "request",
      recipientId: "user-bob",
      amount: 3000,
      description: "Lunch money"
    }).then((response) => {
      expect(response.status).to.equal(201);
      expect(response.body.status).to.equal("pending");
    });
  });
});
```

### Example 3: GraphQL Query

```typescript
describe("Bank accounts via GraphQL", () => {
  it("user can query bank accounts", () => {
    cy.login("alice", "password123");
    
    cy.graphql(`
      query listBankAccount {
        listBankAccount {
          id
          bankName
          accountNumber
        }
      }
    `).then((response) => {
      expect(response.status).to.equal(200);
      expect(response.body.data.listBankAccount).to.be.an("array");
    });
  });
});
```
```

---

## Timeline & Milestones

### Phase 1 Timeline (Week 1)

```
Monday:
  ├─ 09:00-09:20 → P1-001: Add test coverage metric (Spec Maintainer)
  ├─ 09:20-09:40 → P1-002: Add performance constraints (Architecture Team)
  ├─ 09:40-10:00 → P1-003: Document API error format (Backend Team)
  └─ 10:00-10:30 → Lunch

Tuesday:
  ├─ 09:00-10:15 → P1-004: Configure CI/CD enforcement (DevOps Owner)
  │   - Update GitHub Actions workflow
  │   - Test with dummy PR
  │   - Update branch protection rules
  └─ 10:15-11:00 → Testing & fixes

Wednesday:
  ├─ Morning → Validation across all environments
  │   - Verify metrics in CI
  │   - Test coverage passes
  │   - Bundle size passes
  └─ Afternoon → Documentation & handoff

**Phase 1 End Criteria:**
- ✅ All 4 work items complete
- ✅ CI/CD pipeline enforces metrics
- ✅ Test passes with ≥85% coverage
- ✅ Build passes with ≤500 KB bundle
- ✅ Team can proceed to Phase 2
```

### Phase 2 Timeline (Week 2)

```
Monday:
  ├─ 09:00-09:30 → P2-001: Code documentation spec (Documentation Lead)
  ├─ 09:30-10:15 → P2-002: Custom commands registry (QA Lead) - parallel
  ├─ 10:15-10:35 → P2-003: Terminology fix (Technical Writer) - parallel
  └─ 10:35-10:50 → P2-004: Glossary (Architecture Docs) - parallel

Tuesday:
  ├─ 09:00-09:15 → P2-005: Update Done Tasks (Technical Writer) - after P2-003
  ├─ 09:15-10:00 → P2-006: ESLint rule (DevOps Owner) - after P2-001
  └─ 10:00-11:00 → Testing & validation

Wednesday-Friday:
  └─ Polish, testing, documentation updates

**Phase 2 End Criteria:**
- ✅ All 6 work items complete
- ✅ Custom commands registry exists (350+ documented)
- ✅ Terminology consistent across all files
- ✅ ESLint enforces TSDoc
- ✅ Team can proceed to Phase 3
```

### Phase 3 Timeline (Week 3)

```
Monday:
  ├─ 09:00-09:50 → P3-001: TypeScript interfaces (Data Modeling Team)
  └─ 09:50-10:00 → Break

Tuesday:
  ├─ 09:00-09:15 → P3-002: Auth consolidation (Documentation Lead) - parallel
  ├─ 09:15-10:00 → P3-003: Dashboard setup (DevOps Owner) - parallel
  └─ 10:00-10:10 → P3-004: Examples (QA Lead) - parallel

Wednesday-Friday:
  ├─ Final polish and testing
  ├─ Update documentation
  ├─ Team training on new standards
  └─ Go-live preparation

**Phase 3 End Criteria:**
- ✅ All 4 work items complete
- ✅ TypeScript interfaces documented
- ✅ Auth spec consolidated
- ✅ Metrics dashboard active
- ✅ IMPLEMENTATION PLAN COMPLETE
```

---

## Escalation & Decision Framework

### Decision Authority Matrix

| Decision | Authority | Approval Required | Escalation Path |
|---|---|---|---|
| Adjust Phase 1 metric thresholds | Architecture Lead | Yes | Product Manager → CTO |
| Delay Phase due to blockers | Phase Lead | Yes | Project Manager → Director |
| Add new work items mid-phase | Spec Maintainer | Yes | Tech Lead → Product Manager |
| Skip Phase 3 work | Product Manager | No | N/A |
| Extend timeline >2 weeks | Project Manager | Yes | Director → Executive |

### Escalation Process

**Level 1: Work Item Blocked**
- Work item owner notifies phase lead
- Phase lead attempts unblocking (within 2 hours)
- If unresolved → Level 2

**Level 2: Phase Delayed >1 day**
- Phase lead notifies project manager
- Project manager updates stakeholders
- Adjust timeline if needed
- If blocking implementation → Level 3

**Level 3: Critical Blocker**
- Project manager escalates to CTO
- CTO evaluates impact
- Make resource or priority adjustments
- Track in GitHub issues with `escalation` label

### Metrics Review Schedule

- **Daily:** Phase lead reviews progress (during work hours)
- **Weekly:** All team leads meet to discuss blockers and adjust next week
- **Post-Phase:** Phase retrospective to capture learnings

---

## Appendix: Checklists

### Pre-Implementation Checklist

- [ ] All Constitution principles have been reviewed
- [ ] SPECKIT_ANALYSIS.md critical issues understood by team
- [ ] Phase 1 thresholds validated against current codebase
- [ ] Resource assignments confirmed (owners for each work item)
- [ ] GitHub repository access verified (admin for P1-004)
- [ ] CI/CD credentials and secrets in place
- [ ] Slack channel created for async communication
- [ ] Kickoff meeting completed with all team leads

### Phase 1 Completion Checklist

- [ ] P1-001: SPECKIT_SPEC.md updated with coverage target
- [ ] P1-002: SPECKIT_SPEC.md updated with performance targets
- [ ] P1-003: SPECKIT_SPEC.md updated with error format
- [ ] P1-004: GitHub Actions workflow enforces all 3 metrics
- [ ] `.github/workflows/ci.yml` tested with dummy PR
- [ ] Branch protection rules updated to require all checks
- [ ] Current `yarn test:ci` passes with ≥85% coverage
- [ ] Current `yarn build` passes with ≤500 KB bundle
- [ ] Team trained on new standards

### Phase 2 Completion Checklist

- [ ] P2-001: SPECKIT_SPEC.md has Code Documentation Standards section
- [ ] P2-002: `.specify/testing/CUSTOM_COMMANDS.md` exists with ≥350 commands
- [ ] P2-003: SPECKIT_DONE_TASKS.md updated to "Transaction System"
- [ ] P2-004: SPECKIT_SPEC.md has Terminology Glossary
- [ ] P2-005: SPECKIT_DONE_TASKS.md terminology is consistent
- [ ] P2-006: ESLint enforces JSDoc/TSDoc on public APIs
- [ ] All existing tests updated to pass ESLint rule
- [ ] Team trained on documentation standards

### Phase 3 Completion Checklist

- [ ] P3-001: SPECKIT_SPEC.md has Data Model Interfaces section
- [ ] P3-002: `.specify/features/AUTHENTICATION.md` created and consolidated
- [ ] P3-003: Performance metrics dashboard active and visible
- [ ] P3-004: SPECKIT_SPEC.md has real-world Cypress examples
- [ ] All examples tested and working
- [ ] Team training completed on new features
- [ ] Documentation published and discoverable

---

## Success Summary

This Implementation Plan translates governance and specification into actionable work. Upon completion:

✅ **Constitution is enforceable**: All 10 principles have measurable gates  
✅ **Specifications are complete**: No gaps between Constitution and Spec  
✅ **Development is formalized**: Standards are documented and automated  
✅ **Teams are empowered**: Clear patterns, examples, and documentation  
✅ **Quality is protected**: Metrics enforced in CI/CD pipeline  

**Next Steps After This Plan:**
1. Execute Phase 1 (1 week)
2. Execute Phase 2 (1 week)
3. Execute Phase 3 (1 week)
4. Quarterly governance audit
5. Annual full review with community input

---

**Plan Ratified:** 2026-03-31  
**Last Updated:** 2026-03-31  
**Owner:** Project Leadership  
**Status:** Ready for Implementation

# Cypress Real-World App - Project Constitution

**Version:** 1.0.0  
**Ratification Date:** 2024-01-15  
**Last Amended:** 2024-12-19  
**Status:** Active

---

## Executive Summary

The **Cypress Real-World App (RWA)** is an educational, full-stack Express/React payment application designed to demonstrate real-world Cypress testing methodologies, patterns, and workflows. This Constitution establishes the governance principles, development standards, and quality gates that guide all contributions, decisions, and technical practices across the project.

**Project Classification:** Reference Implementation & Educational Resource  
**Primary Audience:** Test Engineers, QA Practitioners, Educators  
**Repository:** https://github.com/cypress-io/cypress-realworld-app  
**License:** MIT

---

## I. Foundational Principles

### Principle 1: Educational Excellence

**Non-Negotiable Requirements:**
- All code, tests, and documentation MUST prioritize clarity and teachability over clever optimization.
- Every feature, pattern, and workflow MUST include inline comments explaining the "why" not just the "how."
- Code examples MUST follow real-world conventions; shortcuts or anti-patterns MUST be avoided unless explicitly marked as "not recommended."
- Documentation MUST include rationale for architectural decisions and testing strategies.

**Rationale:**  
The project's primary value is as a learning resource. Developers studying this codebase expect to understand best practices, not struggle with obscure patterns.

---

### Principle 2: Zero Production Ambition

**Non-Negotiable Requirements:**
- This project is NOT a production application; README MUST prominently state this.
- Feature additions MUST NOT introduce production infrastructure requirements (databases, caches, external services) that complicate local development.
- All state persistence MUST be via local JSON (lowdb) unless educational value justifies exceptions.
- No user data protection, compliance, or security hardening requirements apply beyond teaching secure coding principles.

**Rationale:**  
Complexity in production systems distracts from testing education. Simplicity enables contributors and learners to focus on test patterns.

---

### Principle 3: Comprehensive Testing Discipline

**Non-Negotiable Requirements:**
- EVERY feature added to the application MUST include:
  - End-to-end tests (UI/API)
  - Component tests (if UI component)
  - Unit tests (if business logic)
  - Visual regression tests (if UI-visible)
- Test coverage MUST remain ≥ 85% for application code (excluding models, fixtures).
- All tests MUST be deterministic, isolated, and reproducible; flaky tests are treated as bugs.
- Tests MUST use the project's established custom commands and patterns (e.g., `cy.getBySel()`, `cy.database()`).

**Rationale:**  
The project teaches testing; the codebase itself MUST demonstrate testing excellence. Low test coverage or flaky tests undermine credibility.

---

### Principle 4: TypeScript-First, Strict Type Safety

**Non-Negotiable Requirements:**
- ALL code (frontend, backend, tests) MUST be written in TypeScript.
- `tsconfig.json` MUST have `"strict": true` and `noEmit: true`; code MUST pass `yarn types` with zero errors.
- Type inference alone is insufficient; function parameters, return types, and public APIs MUST have explicit type annotations.
- `any` types are forbidden; use `unknown` with proper type guards if runtime type is uncertain.
- Pre-push hook enforces `yarn types`; no code merges without passing type check.

**Rationale:**  
Teaching developers to embrace static typing prevents entire categories of bugs and is a core practice the project should model.

---

### Principle 5: Single Source of Truth for Testing Patterns

**Non-Negotiable Requirements:**
- Custom Cypress commands (e.g., `cy.login()`, `cy.getBySel()`) are the canonical way to interact with the app in tests; direct selectors or actions in test code are forbidden.
- All test utilities MUST be documented in `cypress/support/` with examples.
- Any new cross-cutting test pattern MUST be extracted into a custom command or utility; duplicate test code is considered a code smell.
- Utilities MUST be version-stable; breaking changes to custom commands require major version bump and migration guide.

**Rationale:**  
Centralizing patterns ensures consistency, reduces maintenance burden, and teaches best practices for test abstraction.

---

### Principle 6: Database Seeding as Test Infrastructure

**Non-Negotiable Requirements:**
- All tests MUST use a clean, seeded database state via `cy.task("db:seed")` before execution.
- Database schema MUST be defined in `data/database-seed.json`; all fixtures derived from this template.
- Direct manipulation of `data/database.json` outside of `cy.task()` is forbidden during test runs.
- Seed data MUST remain representative of realistic application state (e.g., 50+ users, 100+ transactions, various account statuses).
- Test-specific data manipulation MUST use `cy.database("find", ...)` or `cy.database("filter", ...)` helpers, never direct REST calls for data setup.

**Rationale:**  
Deterministic seeding ensures tests are reproducible and teaches the importance of test isolation and data management.

---

### Principle 7: Multi-Auth Provider Parity

**Non-Negotiable Requirements:**
- The application MUST support local authentication AND at least three external auth providers (Auth0, Okta, AWS Cognito, Google).
- ALL authentication flows (login, logout, token refresh, MFA if applicable) MUST work identically across all providers.
- Tests MUST include provider-specific auth flows; new auth providers require auth-specific test suite additions.
- Credentials for external providers MUST NOT be stored in version control; use environment variables or CI secrets.

**Rationale:**  
Real applications often support multiple auth methods. This teaches integration testing with third-party services and conditional CI setup.

---

### Principle 8: CI/CD as Mandatory Quality Gate

**Non-Negotiable Requirements:**
- ALL code changes MUST pass GitHub Actions CI before merge:
  - Type checking (`yarn types`)
  - Linting & formatting (`yarn lint`)
  - Unit tests (`yarn test:unit:ci`)
  - Component tests (`yarn test:component:ci`)
  - E2E tests across browsers/viewports (Chrome, Firefox, mobile)
- Cypress Cloud integration (project ID: 7s5okt) MUST record all test runs; failures block merges.
- E2E tests MUST run in parallel (5 workers per browser) with 2 retries for transient failures.
- CI failure notifications MUST be visible to all contributors; silent CI failures are not permitted.

**Rationale:**  
Automated CI prevents regressions and teaches the non-negotiable role of CI/CD in modern development.

---

### Principle 9: Performance & Observability

**Non-Negotiable Requirements:**
- Application bundle size MUST NOT exceed 500 KB gzipped; report size on every PR.
- All API endpoints MUST log request/response metrics; logs accessible via `yarn start` console output.
- Code coverage reports MUST be generated on every build; reports published to Codecov.
- Percy visual regression baseline MUST be maintained; screenshots should update only on intentional UI changes.
- Page load time (First Contentful Paint) MUST remain < 2 seconds on 3G throttling; monitor via Lighthouse.

**Rationale:**  
Observable applications teach debugging and optimization practices; performance metrics guide design decisions.

---

### Principle 10: Documentation-as-Code

**Non-Negotiable Requirements:**
- Every feature, API endpoint, custom command, and testing pattern MUST have a markdown document explaining purpose, usage, and examples.
- README.md MUST be updated for any user-facing feature changes; outdated READMEs are treated as bugs.
- API documentation MUST be auto-generated from GraphQL schema and REST endpoint handlers (via TSDoc comments).
- Breaking changes MUST include migration guides; deprecations MUST have a 2-version grace period before removal.

**Rationale:**  
Documentation is a teaching tool; absence of documentation indicates the feature is not ready for use.

---

## II. Governance

### Amendment Procedure

1. **Proposal Phase:**
   - Proposed changes to principles, standards, or policies MUST be submitted as GitHub issues with label `governance-proposal`.
   - Proposals MUST justify the change with at least three concrete use cases or pain points.

2. **Discussion Phase:**
   - All maintainers and active contributors (≥ 3 commits in last 6 months) are invited to comment.
   - Discussion period MUST last ≥ 7 days.

3. **Adoption Phase:**
   - Adoption requires unanimous consent from all core maintainers (Cypress product team).
   - Adopted changes MUST be reflected in this Constitution with version bump.
   - A Migration Guide MUST be published if the change affects existing contributors.

### Version Management

**Semantic Versioning:**
- **MAJOR** (e.g., 2.0.0): Backward-incompatible principle removals, redefinitions, or breaking governance changes.
- **MINOR** (e.g., 1.1.0): New principles added, material expansions to existing principles, new mandatory quality gates.
- **PATCH** (e.g., 1.0.1): Clarifications, wording refinements, non-semantic corrections, typo fixes.

**Version Change Decision Tree:**
- If a change requires existing code to be refactored or tests to be rewritten → **MAJOR**
- If a change adds a new mandatory requirement but doesn't break existing code → **MINOR**
- If a change clarifies ambiguity but doesn't change behavior → **PATCH**

### Compliance Review Cadence

- **Quarterly Review:** Every 3 months, maintainers audit codebase against Constitution for drift.
- **Annual Full Review:** Every January, full governance audit with community input.
- **Issue Tracking:** Non-compliance issues labeled `governance-drift` and tracked in GitHub Projects.

### Decision Authority

| Decision Type | Authority | Veto Power |
|---------------|-----------|-----------|
| Feature addition | Community PR + code review | Maintainers (unanimous) |
| Principle amendment | Maintainers (unanimous) | Core Cypress team |
| Release & versioning | Maintainers | Cypress product lead |
| Security/data governance | Cypress legal + maintainers | Cypress compliance officer |

---

## III. Development Standards

### Code Organization

**Directory Structure:**

---

**Version**: 1.0.0 | **Ratified**: 2024-01-15 | **Last Amended**: 2026-03-31

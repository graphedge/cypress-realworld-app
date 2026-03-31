# SPECKIT_CONSTITUTION.md

Purpose & Scope
---------------
This constitution codifies the governance, quality gates, and contributor expectations for the Cypress Real‑World App repository. Its scope covers repository-level policies (branching, PRs, releases), development standards (testing, linting, types), security practices (secrets, credentials), and observability/quality expectations. It applies to all contributors, automated agents, and CI/CD flows that change code or tests in this repo.

Core Principles
---------------
1. Testable-first: Every change that affects functionality MUST include automated tests that exercise behavior at the appropriate level (unit, component, integration, or E2E). Tests are required for bug fixes, new features, and contract changes.
   - Evidence:
     - cypress.config.ts: component.specPattern: "src/**/*.cy.{js,jsx,ts,tsx}" (component testing enabled)
     - README.md: "Tests" table references api, ui, component, unit tests (README tests section)
     - package.json scripts: "test:unit": "vitest", "cypress:run" scripts

2. CI gate enforcement: The main development branches (develop/main) MUST be protected by CI checks that include type checks, lint, tests, and coverage upload. No merge to these branches without green CI and required approvals.
   - Evidence:
     - package.json: husky pre-push hook runs "yarn types" (pre-push type check)
     - README.md: codecov and Cypress Cloud badges indicate CI integrations
     - package.json scripts: "build:ci", "test:unit:ci" and coverage-related scripts

3. Small, reviewable changes: Pull requests MUST be limited in scope and size; PRs must include a clear description, tests, and link to any relevant issue. Maintain a review standard of at least one approving reviewer plus code owner where applicable.
   - Evidence:
     - .github/agents/speckit.specify.agent.md: guidance on short branch names and feature specs (branching/PR best practice guidance)
     - README.md contributors & ALL-CONTRIBUTORS notice (collaborative project)

4. Semantic, documented APIs: Public or cross-service contracts (HTTP API, shared fixtures) MUST be versioned and preserved/compatibly evolved; breaking changes MUST be explicitly documented, tested, and released under a major version bump.
   - Evidence:
     - README.md: full-stack Express/React app and API backend described ("full-stack Express/React application")
     - cypress.config.ts: e2e.env.apiUrl and tasks referencing testData endpoints (test suite depends on API contracts)

5. Secrets never in repo: Secrets and credentials MUST NOT be committed. Use environment variables and secure CI secrets; local .env files are allowed for development but MUST be excluded from version control.
   - Evidence:
     - cypress.config.ts lines: dotenv.config() and many process.env references (dotenv usage)
     - README.md: explicit "make sure the modified port numbers in `.env` are not committed into Git" and other .env guidance

6. Observability & measurable quality: Instrument code with coverage, and include logs and structured information adequate to debug CI and local failures. Maintain code coverage measurement and publish results to CI reporting.
   - Evidence:
     - package.json devDependencies: "@cypress/code-coverage", "nyc", "vitest", "vite-plugin-istanbul"
     - README.md: "Code Coverage Report" section and steps to generate coverage

Policies
--------
Branching & merging
- Branch naming: short, action-noun (e.g., feature/user-auth, fix/payment-timeout). Use the branch helper/script patterns described in .github/agents/speckit.specify.agent.md when creating feature branches.
  - PRs must target develop (or main per repo convention); hotfixes may target main with expedited review.
- Merge requirements:
  - CI green for all required checks (types, lint, unit/component/E2E tests where affected).
  - At least one approving reviewer; critical or sensitive changes require 2+ approvals.
  - For changes that affect tests or contracts, a test plan and test run evidence (artifact links or CI job links) must be included in the PR.

PR Review
- PRs must include:
  - Summary, scope, and testing steps.
  - Links to failing/passing CI runs if applicable.
  - Tests and update to documentation if behavior changes.
- Reviewers must validate tests run locally or in CI, and ensure no secrets are present.

CI gating & checks
- Required checks (must be present on protected branches):
  - Type checking (yarn types / tsc)
  - Linting and formatting check (eslint + prettier)
  - Unit & component tests (vitest and Cypress component)
  - E2E or API tests when changes touch integration surfaces
  - Coverage collection and report upload to coverage provider
- Evidence in repo:
  - package.json scripts for types, lint, test:unit:ci, build:ci, and coverage-related tooling.

Versioning & releases
- Use semantic versioning for releases: MAJOR.MINOR.PATCH
  - MAJOR for breaking API/contract changes
  - MINOR for backward-compatible feature additions
  - PATCH for bug fixes and non-behavioral documentation/wording changes
- Release process:
  - Tag commit, run CI Release job (if configured), update CHANGELOG with summary and migration notes for breaking changes.

Developer Responsibilities
--------------------------
- Run local checks before opening a PR:
  - yarn types && yarn lint && yarn test:unit (or run CI-equivalent)
- Write clear, isolated tests for new behavior and update tests for behavior changes.
- Avoid committing secrets; use .env and CI secret settings.
- Document any public-facing API change in README or a dedicated docs path; update mock data or test seeds when modifying contract shapes.
- Keep PRs small and focused. Add rationale to PR description for design decisions.

Testing & QA standards
----------------------
- Unit tests:
  - Run with vitest. All new modules must have unit tests where behavior is non-trivial.
  - Suggested threshold (goal): maintain at least 80% units/component coverage overall. (Repository includes coverage tooling; no numeric threshold enforced by CI today — see checklist.)
  - Evidence: package.json "test:unit": "vitest"; vite-plugin-istanbul and nyc entries.

- Component tests:
  - Use Cypress component testing for UI components (cypress.component.devServer configured).
  - Evidence: cypress.config.ts component.devServer and specPattern.

- Integration & API tests:
  - Use Cypress E2E tests under cypress/tests to validate key user flows and API behaviors. DB reseeding is part of test setup.
  - Evidence: cypress.config.ts has on("task") db:seed and README shows tests are reseeded on dev.

- End-to-end:
  - E2E tests defined in cypress/tests/**; runs should be in CI against a deterministic seed.
  - Evidence: cypress/tests directories and README instructions.

- Coverage:
  - Instrumentation exists for frontend and backend coverage (Cypress code coverage plugin + nyc).
  - Evidence: package.json devDependencies include "@cypress/code-coverage"; README describes coverage generation.

API / Contract rules
--------------------
- Backwards compatibility:
  - Any change to API responses, test-data endpoints, or seed schema MUST preserve backwards compatibility or be accompanied by migration steps and major versioning.
  - Tests must include contract assertions (integration tests) and seeds updated alongside schema changes.

- Schema evolution:
  - Additive changes allowed under a minor bump; removals/renames require a major bump and migration notes.

Security & Secrets
------------------
- Never commit keys or secrets. Use environment variables, and add local .env examples (without secrets) if needed.
  - Evidence: cypress.config.ts uses dotenv and throws if credentials are missing in tasks (getAuth0Credentials etc.)
  - README.md: explicit warnings not to commit .env changes and to use .env for credentials.

- Credential handling:
  - CI must store secrets in protected secrets (GitHub Actions secrets or hosted CI secret store).
  - Local dev: .env.local or .env files allowed but should be added to .gitignore.

- Dependency security:
  - Keep dependencies up to date and run regular vulnerability scans. Use existing renovate or automated tooling to propose updates.
  - Evidence: renovate.json present in repo root (repo snapshot shows renovate.json file exists).

Observability & Logging
-----------------------
- Logging:
  - Backend must include request logging for debugging (morgan is included as dependency), and logs should contain request ID/context where possible.
  - Evidence: package.json includes "morgan" / @types/morgan.

- Test instrumentation:
  - Coverage artifacts and CI logs must be published or uploaded (codecov/percy badges indicate reporting).
  - Evidence: README badges for codecov and percy.

Dependency & License policy
---------------------------
- License: MIT (keep LICENSE file and package.json license in sync).
  - Evidence: package.json "license": "MIT" and README license section.

- Third-party updates:
  - Use automated PRs (dependabot/renovate) and require the same CI protections on dependency update PRs.
  - Evaluate transitive license or security issues before merging.

Onboarding & Documentation expectations
---------------------------------------
- README is the canonical starting place; new contributors must add documentation for feature-level decisions in docs or README sub-sections.
  - Evidence: README contains detailed setup, testing, and provider guidance.
- Contributing guidance:
  - Add a CODEOWNERS file and maintain "how to run tests" and "how to add a feature" checklist in CONTRIBUTING.md (if not present).

Exceptions & Amending the Constitution
--------------------------------------
- Exceptions:
  - Exceptions to MUST-level rules are permitted only via an explicit, documented PR that:
    1) Describes the exception, rationale, and compensating controls;
    2) Is approved by at least two maintainers; and
    3) Is recorded in a repository governance file (e.g., docs/GOVERNANCE.md) for auditability.

- Amendments:
  - This constitution is amended by PR:
    - Create a PR titled "docs: amend constitution to vX.Y.Z — short reason".
    - Amendment PR MUST include:
      - Summary of change and affected sections.
      - Tests or automation updates required by the amendment.
      - CI green and two approvals (one from a maintainer).
  - Versioning for constitution: use semantic increments (major: principle redefinition/removal; minor: added principle; patch: wording/clarity).

Evidence appendix (per principle/policy)
---------------------------------------
(One to three motivating evidence items for the rules above — path and excerpt or explanation)

- Testing-first & CI gating
  - package.json scripts: "test:unit": "vitest", "cypress:run", "cypress:run:component" (package.json scripts block)
  - cypress.config.ts: component.specPattern: "src/**/*.cy.{js,jsx,ts,tsx}" and e2e.specPattern entries; codeCoverageTask setup (lines showing code-coverage plugin)
  - README.md: "Tests" table referencing api, ui, component, unit locations

- Secrets & dotenv
  - cypress.config.ts: lines calling dotenv.config(); tasks that check for AUTH0/OKTA/Cognito env vars and throw if missing
  - README.md: "make sure the modified port numbers in `.env` are not committed into Git" and other .env guidance

- Coverage & observability
  - README.md: "Code Coverage Report" section with steps to generate coverage
  - package.json devDependencies: "@cypress/code-coverage", "nyc", "vite-plugin-istanbul"

- Branching, PR, and spec expectations
  - .github/agents/speckit.specify.agent.md: guidance on branch naming and feature spec creation (used as format guidance)
  - README.md contributors note and all-contributors usage indicate collaborative review process

- License & dependency automation
  - package.json "license": "MIT" and README license section
  - renovate.json present in repo root (indicates dependency automation plans)

Immediate 3-item prioritized checklist (high-impact, short-term)
----------------------------------------------------------------
1. Add a CODEOWNERS file listing core maintainers and directories (src/, backend/, cypress/) to enforce reviewer assignment on critical areas.
2. Add or enable CI coverage threshold enforcement (e.g., fail PRs if coverage drops by X% or below target). This repo has coverage tooling; wire it into CI.
3. Add CONTRIBUTING.md with a short pull-request checklist (types, lint, tests, secrets check) and an Exceptions procedure referencing this constitution.

Suggested commit message for adding this doc
--------------------------------------------
docs: add SPECKIT_CONSTITUTION.md — governance, testing, and security rules

Top 3 findings / evidence (2–4 lines)
-------------------------------------
1. Testing-first and rich E2E/component testing are core: cypress.config.ts defines both component and e2e specs and includes code-coverage instrumentation; package.json contains multiple test and coverage scripts.
2. Secrets must be externalized: dotenv is loaded in cypress.config.ts and several tasks explicitly require env vars for auth providers; README explicitly warns not to commit .env changes.
3. CI and reporting are in use: README shows codecov and Cypress Cloud badges and package.json includes husky pre-push types check — the repo is already set up for CI gating and coverage reporting.

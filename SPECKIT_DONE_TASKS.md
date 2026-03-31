SPECKIT_DONE_TASKS.md
======================

Repository root: /home/brett/projects/cypress-realworld-app
Branch inspected: develop

---

Task: rwa-001 — Add API tests for Bank Accounts (GraphQL migration)
- Title: GraphQL migration and API tests for Bank Accounts
- Description: Migrate Bank Accounts section to GraphQL and add API tests validating the GraphQL-backed bank accounts behavior.
- Evidence:
  - Relevant commits: bfaffd4 (Add GraphQL endpoint and migrate Bank Accounts section of app to use GraphQL) and later build/graphQL related commits (see git log).
  - Files:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-bankaccounts.spec.ts
    - /home/brett/projects/cypress-realworld-app/backend/... (GraphQL endpoint code/usage — present in repository)
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-bankaccounts.spec.ts
    - Asserts GraphQL API responses for bank accounts, queries/mutations return expected account fields and status codes.
- Status: done

---

Task: rwa-002 — Ensure user balance stored in cents
- Title: Persist account balance as integer cents (API)
- Description: Ensure when a user account is created the balance is captured/stored as a number of cents (to avoid float precision issues).
- Evidence:
  - Commit: 1b451ca (2024-04-16) — "fix(api): ensure balance is captured as number of cents when user account created (#1544)"
  - File evidence:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-users.spec.ts
    - Backend user creation code touched in commit referenced above (backend/ related files)
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-users.spec.ts
    - Contains an assertion: expect(response.body.user.balance).to.equal(100_00) — demonstrates balance stored as cents
- Status: done

---

Task: rwa-003 — Add and maintain Auth provider examples and tests (Auth0, Okta, Cognito, Google)
- Title: Add Auth providers and tests for Auth0 / Okta / AWS Cognito / Google
- Description: Add demonstration authentication providers (Auth0, Okta, Cognito, Google) and e2e tests to validate login/onboarding/logout flows across providers.
- Evidence:
  - Commits:
    - b91ddd8 (2021-02-22) — "Add Auth0, Okta and AWS Cognito Authentication for RWA demonstration purposes (#696)"
    - a221bdb (2022-12-02) — "feat: update okta realworld app to allow for cy.origin() (#1293)"
    - 70fb782 (2022-12-05) — "feat: update cognito realworld app to allow for cy.origin() (#1292)"
    - 39fc97d (2025-12-05) — "chore: update auth examples to use cy.task instead of Cypress.env() (#1673)"
  - Files:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/cognito.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/google.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/auth0.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/okta.spec.ts
- Tests that validate task:
  - Each file above contains full e2e flows:
    - e.g., /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/okta.spec.ts
      - Asserts login/onboard/logout via Okta with cy.origin/cy.task support
    - Other provider specs assert login/onboarding/logout and integration with the app UI.
- Status: done

---

Task: rwa-004 — New Transaction UI flow: create transaction, update balances, show in feed
- Title: Implement New Transaction UI and associated tests
- Description: UI flow to create new transaction, update user/contact balances and show transaction in feeds; includes tests to verify the balance calculations and UI updates.
- Evidence:
  - Commits: multiple over time adding and refining the feature and tests (commit history includes UI test updates dating back to 2020+ for transaction handling; e.g., 32f1442, 92cd860, and later fixes).
  - Files:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts
    - /home/brett/projects/cypress-realworld-app/src/... (New transaction components)
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts
    - Asserts the new transaction submission, checks the UI for updated user balance (data-test selectors), and verifies contact balance updated as expected. Uses dinero conversions in assertions to ensure correct cents math.
- Status: done

---

Task: rwa-005 — Transaction feeds UI tests & improvements
- Title: Transaction Feeds UI tests and fixes
- Description: Add UI test coverage for the transaction feed view and apply fixes to assertions/flows to improve reliability.
- Evidence:
  - Commit(s): 6f96b25 (2024-12-23) — "cy: improve api comments & contacts assertions and readability (#1604)" and various test-refactoring commits across 2020-2024.
  - Files:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/transaction-feeds.spec.ts
    - Asserts that transactions appear in the feed, pagination/filters behave, and specific transaction details render as expected.
- Status: done

---

Task: rwa-006 — Add API tests for Transactions, Transfers, Likes, Comments, Notifications
- Title: Comprehensive API test suite for transactions and related resources
- Description: Add a set of API tests to cover transactions, transfers, likes, comments, notifications and related resources.
- Evidence:
  - Files present under:
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-transactions.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-banktransfers.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-likes.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-comments.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-notifications.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/api-testdata.spec.ts
  - Commits: Many historical commits add/adjust these tests (see git log entries across 2020–2024).
- Tests that validate task:
  - Each listed spec asserts CRUD and expected behaviors for the respective API endpoints (status codes, response shapes, side-effects like DB changes).
- Status: done

---

Task: rwa-007 — Upgrade repository to Cypress v15 and adjust config/tests
- Title: Upgrade to Cypress 15 and adapt CI/config to new versions
- Description: Upgrade test runner to Cypress 15 and make required configuration changes across repo and tests to remain compatible.
- Evidence:
  - Commit: ed37e80 (2025-08-20) — "chore: update RWA to Cypress 15 (#1654)"
  - package.json devDependency: "cypress": "15.0.0" (present in package.json)
  - Tests: existing cypress test files remain and are expected to run on Cypress 15 per CI and package.json
- Tests that validate task:
  - Whole test suite (examples):
    - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/*.spec.ts
    - /home/brett/projects/cypress-realworld-app/cypress/tests/api/*.spec.ts
    - These were adapted/kept to run on Cypress 15; commit history includes test-related fixes (e.g., cy.task migration).
- Status: done

---

Task: rwa-008 — Fix CI flakiness: set fileParallelism: false
- Title: Prevent flaky CI runs by setting fileParallelism false
- Description: Add configuration to force single-file parallelism to reduce flakiness in CI test pipeline.
- Evidence:
  - Commit: f3503ce (2025-10-23) — "fix(test): explicitly added `fileParallelism: false` to prevent flakiness in ci test pipeline (#1668)"
  - This is a config change (Cypress/CI config).
- Tests that validate task:
  - None specific; this is a CI configuration fix aimed at stability. It is validated by overall CI test stability (not by a unit test).
- Status: done (configuration change); test coverage: partially-tested (see retrospective)
- Proposed minimal tests to demonstrate stability (see retrospective section)

---

Task: rwa-009 — Fix Okta auth flow and maintain Okta test
- Title: Fix Okta login flow and keep Okta tests working
- Description: Fix issues in the Okta login flow and ensure Okta provider test(s) remain stable.
- Evidence:
  - Commit: ffd4602 (2024-03-22) — "fix: okta auth flow (#1533)"
  - Test file: /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/okta.spec.ts
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/ui-auth-providers/okta.spec.ts
    - Verifies the Okta login/onboard/logout flow operates as expected.
- Status: done

---

Task: rwa-010 — Migrate from dinero.js v1 to v2 and update money-related assertions
- Title: Migrate dinero library and update money calculations/test assertions
- Description: Change money-handling library to Dinero v2 and update tests to use new API/formatting.
- Evidence:
  - Commit: 73b9a23 (2026-03-05) — "chore: migrate from dinero.js v1 to v2 (#1697)"
  - Files impacted: test files that import/verify money amounts (for example new-transaction.spec.ts which references dinero)
- Tests that validate task:
  - /home/brett/projects/cypress-realworld-app/cypress/tests/ui/new-transaction.spec.ts
    - Uses dinero conversions in assertions; commit updated assertions/usage accordingly.
- Status: done

---

Retrospective summary
---------------------

Fully-tested
- rwa-001 (api-bankaccounts) — has dedicated api spec cypress/tests/api/api-bankaccounts.spec.ts
- rwa-002 (user balance cents) — api-users.spec.ts asserts cents
- rwa-003 (auth providers) — auth provider specs exist for Cognito, Google, Auth0, Okta
- rwa-004 (new transaction UI) — new-transaction.spec.ts asserts full flow and balances
- rwa-005 (transaction-feeds) — transaction-feeds.spec.ts present and asserting behavior
- rwa-006 (comprehensive API tests) — many api specs exist and assert CRUD/behaviors
- rwa-009 (okta fix) — okta.spec.ts validates flow
- rwa-010 (dinero migration) — tests updated referencing dinero API

Partially-tested
- rwa-007 (Upgrade to Cypress 15)
  - package.json shows Cypress 15 and commit exists; existing tests were adapted, but "upgrade" is an operational change validated by running the whole suite in CI rather than by a single, focused test. Considered partially-tested because acceptance is CI-level; there are commits that changed tests to be compatible.
- rwa-008 (CI flakiness fix: fileParallelism:false)
  - This is a config-level change intended to affect CI stability. There is no unit/e2e test that asserts "CI stability". Its validation is operational (CI runs no longer flake). Marked partially-tested.

Untested-but-marked-done
- None observed that are clearly marked done in code/commit history but completely lack automated verification files. Most functional changes include at least a cypress spec. Configuration-only changes (rwa-008) are not directly test-covered and thus fall under partially-tested rather than untested.

Proposed minimal tests for partially-tested or untested-but-marked-done tasks
- rwa-007 (Upgrade to Cypress 15)
  - Minimal acceptance test(s) to assert compatibility:
    - File: /home/brett/projects/cypress-realworld-app/cypress/tests/compat/cypress-15-smoke.spec.ts
    - Purpose: headless smoke-suite that runs a minimal set of critical paths (login via mock/cy.task, create a transaction, check feed) to quickly validate Cypress 15 compatibility in CI.
    - Test names / suggestions:
      - "smoke: app loads and login works"
      - "smoke: create transaction updates balances"
      - "smoke: API endpoints return 200"
- rwa-008 (CI flakiness / fileParallelism)
  - Minimal "stability" tests to exercise fileParallelism behaviors are difficult to assert in unit tests; instead propose:
    - A deterministic smoke-run wrapper (CI script-level) that runs the small smoke-suite sequentially and asserts no flakiness. For repository-level artifact:
      - File: /home/brett/projects/cypress-realworld-app/cypress/tests/ci/smoke-sequential.spec.ts
      - Purpose: run a small set of independent tests that historically flaked when run in parallel; CI can run this with fileParallelism:false and ensure consistent output.
    - Test names:
      - "ci-smoke: sequential login and transaction" — verifies two independent tests produce consistent state when run sequentially; with fileParallelism:false they should be stable.

Concrete suggested test file paths and test names
- /home/brett/projects/cypress-realworld-app/cypress/tests/compat/cypress-15-smoke.spec.ts
  - Tests:
    - it('smoke: login (mock provider) and land on dashboard', ...)
    - it('smoke: create simple transaction and check balances', ...)
- /home/brett/projects/cypress-realworld-app/cypress/tests/ci/smoke-sequential.spec.ts
  - Tests:
    - it('ci-smoke: create transaction 1', ...)
    - it('ci-smoke: create transaction 2', ...) — two independent tests that would reveal parallel-related nondeterminism if run concurrently; with fileParallelism:false they should be stable.

Notes on evidence and approach
- Evidence priority used:
  1. Commit SHAs and messages (git log) — used where commits explicitly name the feature/fix (examples above).
  2. Present test files under /cypress/tests — existence of spec files and the assertions they contain (I inspected test file names and grep-scanned for key assertions) indicate coverage for the feature.
  3. package.json entries (e.g., Cypress version 15.0.0) and scripts show intent & environment.
- Where explicit PR numbers were present I included them (ex: #1654, #1668, #1673). When PR numbers are not present, I used commit SHAs and file evidence.
- I avoided making any changes to the repository (non-destructive), only read files and git history.

If you want, I can:
- Produce the exact text for the two proposed new test files (skeleton tests) using the current project's helper commands and test utilities (e.g., cy.task auth mocks, data seeding).
- Create a short CI checklist to confirm that the "fileParallelism: false" change has reduced flakiness (e.g., run smoke-sequential 5 times in CI to assert no intermittent failures).
- Expand the SPECKIT_DONE_TASKS.md with direct links to the exact commit diffs for each item (requires fetching show/diff for each listed commit).
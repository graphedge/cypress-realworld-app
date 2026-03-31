---
description: "Task list for User Authentication & Profile Management feature"
spec: "specs/001-user-authentication/spec.md"
plan: "specs/001-user-authentication/plan.md"
branch: "001-user-authentication"
---

# Tasks: User Authentication & Profile Management

**Input**: Design documents from `specs/001-user-authentication/`
**Prerequisites**: `plan.md` ✅ | `spec.md` ✅
**Status**: Core implementation exists — tasks target **gaps and improvements** identified in `plan.md`

> **Context**: The authentication system is substantially complete. All tasks below fix known
> correctness bugs, resolve TypeScript-hygiene debt, tighten validation alignment between the spec
> and the Yup schemas, and extend test coverage to match the depth required by the constitution.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story this task belongs to (US1–US4; US5 = Third-Party Providers)
- Exact file paths are included in every task description

---

## Phase 1: Foundational Bug Fixes (Blocking Prerequisites)

**Purpose**: Correctness defects that affect multiple user stories. These **must** be resolved
before story-specific tests can reliably pass — they are the critical path.

**⚠️ CRITICAL**: No story-level test work should begin until T-001 and T-002 are complete.

- [ ] T-001 Fix double-redirect in `POST /logout`: move `res.redirect("/")` exclusively inside the
  `req.session!.destroy()` callback; remove the duplicate `res.redirect("/")` call that currently
  fires immediately after `req.logout()` in `backend/auth.ts` (lines ~50–56)

  *Acceptance*: A single `POST /logout` request produces exactly one `302` response; no
  `ERR_HTTP_HEADERS_SENT` server error; session cookie `connect.sid` is absent on subsequent
  requests.

- [ ] T-002 Add duplicate-username 422 to `POST /users`: call `getUserByUsername(req.body.username)`
  before `createUser()`; if a user is found, return
  `res.status(422).json({ errors: [{ msg: "Username already exists", param: "username" }] })`
  in `backend/user-routes.ts` (router.post("/") handler)

  *Acceptance*: `POST /users` with an existing username returns `422` with a structured
  `errors` array; a new unique username still returns `201`.

**Checkpoint**: Logout → single redirect; duplicate sign-up → 422 (not 500).

---

## Phase 2: US1 — User Sign-Up (Priority: P1) 🎯 MVP

**Goal**: Visitors can create an account with a unique username and a password of ≥ 8 characters,
are auto-logged in, and see the onboarding dialog.

**Independent Test**: `POST /users` with valid payload → `201` + user object in body, password
absent from response → `GET /checkAuth` with returned session cookie → `200` + same user →
onboarding dialog visible in UI.

### Implementation for User Story 1

- [ ] T-003 [P] [US1] Fix Yup `password` min-length from `4` to `8` in `SignUpForm` schema to match
  spec requirement (spec §1 "Password minimum 8 characters") in
  `src/components/SignUpForm.tsx` (line ~51: `.min(4, …)` → `.min(8, "Password must contain at
  least 8 characters")`)

  *Acceptance*: Entering a 7-character password in the signup form shows
  "Password must contain at least 8 characters"; 8-character password clears the error.

- [ ] T-004 [P] [US1] Add TSDoc to `createUser()`, `getUserByUsername()`, and `getUserBy()`
  exported functions in `backend/database.ts` — document parameters, return type, and the
  bcrypt-hashing side-effect in `createUser`

  *Acceptance*: Each function has a `/** … */` block with `@param` and `@returns`; `yarn types`
  still passes with zero errors.

- [ ] T-005 [US1] Add Cypress API test case **"POST /users - 422 for duplicate username"** inside
  the existing `describe("users", …)` block in `cypress/tests/api/api-users.spec.ts` — seed DB,
  call `cy.request` for an existing seed username, assert `status: 422` and
  `body.errors[0].param === "username"` (depends on T-002)

  *Acceptance*: `yarn cypress:run --spec cypress/tests/api/api-users.spec.ts` passes; new test
  is not skipped.

- [ ] T-006 [US1] Add Cypress E2E test case **"should display an error for an already registered
  username"** in `cypress/tests/ui/auth.spec.ts` — complete the sign-up form with a username
  that already exists in the seed, submit, assert `cy.getBySel("signup-error")` is visible and
  contains "Username already exists" (depends on T-002)

  *Acceptance*: Test passes; error element appears without page reload.

- [ ] T-007 [US1] Update `SignUpForm` Yup schema test assertion in `cypress/tests/ui/auth.spec.ts`
  (line ~154 area — the "display signup errors" test) from the current empty-password flow to also
  assert the 8-character minimum error string if a short password is typed (depends on T-003)

  *Acceptance*: Typing a 5-character password in the signup form triggers
  "Password must contain at least 8 characters"; test passes.

**Checkpoint**: Duplicate username → 422 + UI error; password < 8 chars → correct error text;
valid sign-up → 201 + session.

---

## Phase 3: US2 — User Sign-In (Priority: P1)

**Goal**: Authenticated users log in with username + password (local strategy), receive a session
cookie, and are redirected to the dashboard. "Remember Me" extends cookie lifetime to 30 days.

**Independent Test**: `cy.loginByApi(username, password)` → `200` + `connect.sid` in cookies →
`cy.loginByApi(…, { remember: true })` → assert `Set-Cookie: connect.sid` has `Max-Age` ≥ 30 days.

### Implementation for User Story 2

- [ ] T-008 [P] [US2] Fix Yup `password` min-length from `4` to `8` in `SignInForm` schema to
  match spec requirement and keep both forms consistent with T-003 in
  `src/components/SignInForm.tsx` (line ~29: `.min(4, …)` → `.min(8, "Password must contain at
  least 8 characters")`)

  *Acceptance*: Entering a 7-character password in the sign-in form shows
  "Password must contain at least 8 characters"; 8-character password clears the error.

- [ ] T-009 [P] [US2] Replace `// @ts-ignore` at `authMachine.ts:264` with `// @ts-expect-error`
  and add an explanatory comment:
  `// @ts-expect-error — localStorage.getItem returns string|null; State.create expects StateValue`
  `// but handles a null/undefined stateDefinition safely at runtime (XState v4 internal)`
  in `src/machines/authMachine.ts`

  *Acceptance*: `yarn types` passes; the `@ts-expect-error` suppresses the same error that
  `@ts-ignore` suppressed; if a future XState upgrade resolves the type, `@ts-expect-error` will
  surface the now-unnecessary suppression.

- [ ] T-010 [P] [US2] Replace `// @ts-ignore` at `authMachine.ts:271` with `// @ts-expect-error`
  and add:
  `// @ts-expect-error — authMachine.resolveState() accepts State<Context> at runtime but its`
  `// generic overload does not match the restored State shape from localStorage (XState v4)`
  in `src/machines/authMachine.ts`

  *Acceptance*: Same as T-009 — `yarn types` zero errors; suppression is documented and
  self-removing if types are fixed upstream.

- [ ] T-011 [US2] Add TSDoc to the `performLogin`, `getUserProfile`, `performSignup`, and
  `performLogout` service functions (and the exported `authService` constant) in
  `src/machines/authMachine.ts` — document the API call made, success/failure transitions, and
  any localStorage side-effects

  *Acceptance*: Each exported function/constant has a `/** … */` block; `yarn types` passes.

- [ ] T-012 [P] [US2] Add TSDoc to the `LocalStrategy` callback, `/login` route handler, and
  `/checkAuth` route handler in `backend/auth.ts` — document the bcrypt comparison, Remember-Me
  cookie extension, and the `401` unauthorized path

  *Acceptance*: Three `/** … */` blocks added; no functional change; `yarn types` passes.

- [ ] T-013 [US2] Update the existing `auth.spec.ts` password-validation assertion at line ~124
  from `"Password must contain at least 4 characters"` to
  `"Password must contain at least 8 characters"` in `cypress/tests/ui/auth.spec.ts`
  (depends on T-008)

  *Acceptance*: `yarn cypress:run --spec cypress/tests/ui/auth.spec.ts` passes with no skipped
  tests; the assertion reflects the updated Yup schema.

- [ ] T-014 [US2] Add a password-min-length assertion to the `SignInForm` component test in
  `src/components/SignInForm.cy.tsx` — type a 5-character password, blur the field, assert
  `#password-helper-text` contains "Password must contain at least 8 characters"
  (depends on T-008)

  *Acceptance*: Component test passes; helper text is visible with correct string.

**Checkpoint**: Sign-in form enforces 8-char minimum; `authMachine.ts` @ts-ignore lines are
documented `@ts-expect-error`; `yarn types` zero errors.

---

## Phase 4: US3 — User Sign-Out (Priority: P1)

**Goal**: Authenticated users click sign-out, their session is destroyed exactly once, `connect.sid`
is cleared, and they land on `/signin` with no console errors.

**Independent Test**: `cy.login(…)` → `cy.getBySel("sidenav-signout").click()` →
`cy.location("pathname").should("eq", "/signin")` → assert `connect.sid` cookie absent →
assert no uncaught exceptions logged.

### Implementation for User Story 3

- [ ] T-015 [US3] Add Cypress E2E test **"should sign out without triggering a double-redirect"**
  in `cypress/tests/ui/auth.spec.ts` — `cy.login()`, click `sidenav-signout`,
  `cy.on("uncaught:exception", …)` guard to catch any `ERR_HTTP_HEADERS_SENT` re-throw,
  assert `cy.location("pathname").should("eq", "/signin")` and
  `cy.getCookie("connect.sid").should("be.null")` (depends on T-001)

  *Acceptance*: Test passes; no uncaught exception event fires; cookie is absent.

- [ ] T-016 [P] [US3] Add TSDoc to the `/logout` route handler in `backend/auth.ts` — document
  the three-step teardown (`clearCookie` → `req.logout` → `session.destroy`) and the single
  `res.redirect("/")` inside the destroy callback

  *Acceptance*: TSDoc block present; no functional change.

**Checkpoint**: Logout → single redirect to `"/"`; no double-response error; cookie cleared.

---

## Phase 5: US4 — Profile Management (Priority: P2)

**Goal**: Authenticated users view and edit their own profile (firstName, lastName, email,
phoneNumber, defaultPrivacyLevel); `PATCH /users/:userId` is scoped to the own account.

**Independent Test**: `cy.loginByApi(…)` → `PATCH /users/:id { firstName: "NewName" }` →
`204` → `GET /users/:id` → `body.user.firstName === "NewName"` → `PATCH /users/:otherId` → `401`.

### Implementation for User Story 4

- [ ] T-017 [P] [US4] Replace `// @ts-ignore` at `backend/helpers.ts:100` with
  `// @ts-expect-error` and add:
  `// @ts-expect-error — req.user.sub is injected by JWT middleware (Auth0/Okta/Cognito/Google)`
  `// but is not declared on Express.Request['user']; mapping sub→id enables ensureAuthenticated`
  `// to work uniformly for both session-based and JWT-based auth`
  in `backend/helpers.ts`

  *Acceptance*: `yarn types` passes; suppression is documented; functionality unchanged.

- [ ] T-018 [P] [US4] Replace `// @ts-ignore` at `backend/helpers.ts:104` with
  `// @ts-expect-error` and add:
  `// @ts-expect-error — set(req.user, "id", req.user.sub): lodash set target typed as User`
  `// which does not include "id" as a writable key in this overload; runtime behavior correct`
  in `backend/helpers.ts`

  *Acceptance*: `yarn types` passes; suppression is documented.

- [ ] T-019 [US4] Add TSDoc to `updateUserById()`, `getUserById()`, `getAllUsers()`, and
  `searchUsers()` exported functions in `backend/database.ts` — document parameters, return
  types, and any lowdb side-effects (write vs. read-only)

  *Acceptance*: Four `/** … */` blocks added; `yarn types` passes.

- [ ] T-020 [P] [US4] Add TSDoc to `ensureAuthenticated()` and `validateMiddleware()` exported
  functions in `backend/helpers.ts` — document the `req.user.sub → req.user.id` mapping in
  `ensureAuthenticated`, and the `validationResult` early-exit pattern in `validateMiddleware`

  *Acceptance*: Two `/** … */` blocks added; no functional change.

- [ ] T-021 [P] [US4] Add TSDoc to the `GET /users/:userId`, `GET /users/profile/:username`, and
  `PATCH /users/:userId` route handlers in `backend/user-routes.ts` — document authorization
  scoping, the lodash `pick` projection for public profile, and 422 validation error shape

  *Acceptance*: Three `/** … */` blocks added; `yarn types` passes.

**Checkpoint**: Profile CRUD routes are fully documented; helpers.ts `@ts-ignore` lines replaced
with `@ts-expect-error`; `yarn types` zero errors.

---

## Phase 6: US5 — Third-Party Auth Providers (Priority: P3)

**Goal**: Auth0, Okta, AWS Cognito, and Google flows authenticate users, create valid sessions,
and produce visual regression baselines consistent with the local-auth spec.

**Independent Test**: With `VITE_AUTH0=true` and `auth0_username` Cypress env set →
`cy.loginToAuth0(…)` → assert `cy.url() === "http://localhost:3000/"` → assert
`localStorage.getItem("authState")` is non-null → sign out → assert `connect.sid` absent.
(All provider specs skip gracefully when env credentials are absent.)

### Implementation for User Story 5

- [ ] T-022 [P] [US5] Replace `// @ts-ignore` at `backend/helpers.ts:8` (OktaJwtVerifier import)
  with `// @ts-expect-error` and add:
  `// @ts-expect-error — @okta/jwt-verifier has no published @types package; CommonJS import`
  `// is runtime-verified; tracked in constitution §4 compliance review`
  in `backend/helpers.ts`

  *Acceptance*: `yarn types` passes; no `@ts-ignore` remains in this file for this import.

- [ ] T-023 [P] [US5] Replace `// @ts-ignore` at `backend/helpers.ts:10` (aws-exports import)
  with `// @ts-expect-error` and add:
  `// @ts-expect-error — src/aws-exports.ts is Amplify-generated; no static type declaration`
  `// available without full Amplify CLI setup; safe to suppress for demo purposes`
  in `backend/helpers.ts`

  *Acceptance*: `yarn types` passes; suppression is documented.

- [ ] T-024 [P] [US5] Replace `// @ts-ignore` at `backend/helpers.ts:65` (`jwt.sub` assignment
  in `verifyOktaToken`) with a typed `OktaJwtPayload` interface:
  ```typescript
  // Define above verifyOktaToken:
  interface OktaJwtPayload { sub: string; [key: string]: unknown; }
  ```
  Cast the `verifyAccessToken` result as `OktaJwtPayload` and remove the `@ts-ignore` in
  `backend/helpers.ts`

  *Acceptance*: No `@ts-ignore` or `@ts-expect-error` needed at line 65; `yarn types` passes;
  `jwt.sub` is properly typed.

- [ ] T-025 [P] [US5] Replace `// @ts-ignore` before `autoEnd: false` in
  `cypress/support/auth-provider-commands/auth0.ts` with `// @ts-expect-error` and add:
  `// @ts-expect-error — autoEnd is a valid CypressLogConfig option not yet reflected in`
  `// @types/cypress for this version`

  *Acceptance*: `yarn types` passes; Auth0 login command behaviour unchanged.

- [ ] T-026 [P] [US5] Replace `// @ts-ignore` before `import { OktaAuth }` in
  `cypress/support/auth-provider-commands/okta.ts` with `// @ts-expect-error` and add:
  `// @ts-expect-error — OktaAuth default import path typings incompatible with module resolution`
  `// in this tsconfig; runtime-verified; tracked in §4 compliance review`

  *Acceptance*: `yarn types` passes; Okta login command behaviour unchanged.

- [ ] T-027 [US5] Add TSDoc to `checkAuth0Jwt`, `checkCognitoJwt`, `checkGoogleJwt`, and
  `verifyOktaToken` exported functions in `backend/helpers.ts` — document the JWKS URI used,
  the env var that enables each middleware, and the `unless` path exclusion

  *Acceptance*: Four `/** … */` blocks present; no functional change; `yarn types` passes.

- [ ] T-028 [P] [US5] Add `cy.visualSnapshot("Auth0 - Onboarding")` after the
  `"Get Started"` assertion and `cy.visualSnapshot("Auth0 - Post-Login")` after the
  transaction list assertion in `cypress/tests/ui-auth-providers/auth0.spec.ts`
  — mirrors the Percy coverage pattern used in `cypress/tests/ui/auth.spec.ts`

  *Acceptance*: Two `cy.visualSnapshot()` calls present inside the existing `if` guard; Percy
  baseline created (or updated) on next CI run.

- [ ] T-029 [P] [US5] Add `cy.visualSnapshot("Cognito - Onboarding")` and
  `cy.visualSnapshot("Cognito - Post-Login")` to the programmatic-login describe block in
  `cypress/tests/ui-auth-providers/cognito.spec.ts`; also verify a **"shows onboarding"**
  `it()` block exists in the programmatic-login describe (add it if absent, matching the
  Auth0/Okta pattern: `cy.contains("Get Started").should("be.visible")`)

  *Acceptance*: Percy snapshot calls present; "shows onboarding" test present in programmatic
  describe; all tests pass.

- [ ] T-030 [P] [US5] Add `cy.visualSnapshot("Okta - Onboarding")` and
  `cy.visualSnapshot("Okta - Post-Login")` to both programmatic and UI-based describe blocks
  in `cypress/tests/ui-auth-providers/okta.spec.ts`

  *Acceptance*: Two Percy calls added per describe block; tests pass.

- [ ] T-031 [P] [US5] Add `cy.visualSnapshot("Google - Onboarding")` and
  `cy.visualSnapshot("Google - Post-Login")` to `cypress/tests/ui-auth-providers/google.spec.ts`

  *Acceptance*: Two Percy calls added; tests pass.

**Checkpoint**: All `@ts-ignore` in `backend/helpers.ts` replaced with `@ts-expect-error`; OktaJwt
has a typed interface; provider specs fire Percy snapshots; `yarn types` zero errors.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation sweep, TSDoc for Cypress custom commands, and CI validation.

- [ ] T-032 [P] Add TSDoc to `cy.loginByXstate()`, `cy.loginByApi()`, and `cy.loginByGoogleApi()`
  in `cypress/support/commands.ts` — document parameters, the API or XState mechanism used, and
  which tests should prefer each login strategy

  *Acceptance*: Three `/** … */` blocks; no change to command behaviour.

- [ ] T-033 [P] Add TSDoc to `cy.loginToAuth0()` in
  `cypress/support/auth-provider-commands/auth0.ts` — document the `cy.session()` caching,
  the `cy.origin()` Auth0 UI interaction, and the `authState` localStorage validation

  *Acceptance*: TSDoc block present; `yarn types` passes.

- [ ] T-034 [P] Add TSDoc to `cy.loginByOktaApi()` in
  `cypress/support/auth-provider-commands/okta.ts` — document the Okta `/api/v1/authn` API
  call, token exchange, and localStorage item written

  *Acceptance*: TSDoc block present; `yarn types` passes.

- [ ] T-035 [P] Add TSDoc to `cy.loginByCognitoApi()` in
  `cypress/support/auth-provider-commands/cognito.ts` — document the Amplify `signIn` +
  `fetchAuthSession` flow and the five CognitoIdentityServiceProvider localStorage keys written

  *Acceptance*: TSDoc block present; `yarn types` passes.

- [ ] T-036 Run `yarn types` from repository root and confirm **zero TypeScript errors** after
  all `@ts-ignore` → `@ts-expect-error` replacements (depends on T-009, T-010, T-017, T-018,
  T-022, T-023, T-024, T-025, T-026)

  *Acceptance*: `yarn types` exits with code `0` and prints no errors.

- [ ] T-037 Run `yarn lint` from repository root and confirm **no new lint violations** introduced
  by any task in this feature (depends on T-003, T-008 and all TSDoc additions)

  *Acceptance*: `yarn lint` exits with code `0`.

- [ ] T-038 Run `yarn test:unit:ci` (Jest) and confirm all auth-related unit tests pass with the
  updated 8-character password minimum (depends on T-003, T-008)

  *Acceptance*: Jest exits with code `0`; no snapshot mismatches.

- [ ] T-039 Run the full auth Cypress suite and confirm all assertions pass:
  `yarn cypress:run --spec "cypress/tests/ui/auth.spec.ts,cypress/tests/api/api-users.spec.ts"`
  (depends on T-001, T-002, T-003, T-005–T-008, T-013–T-015)

  *Acceptance*: All tests in both specs pass; zero failures; zero skips in the non-provider specs.

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends On | Notes |
|-------|-----------|-------|
| Phase 1 (Foundational) | None | Start immediately |
| Phase 2 (US1 Sign-Up) | T-002 for T-005, T-006 | T-003, T-004 independent |
| Phase 3 (US2 Sign-In) | T-003 for T-008, T-013, T-014 | T-009, T-010, T-012 independent |
| Phase 4 (US3 Sign-Out) | T-001 for T-015 | T-016 independent |
| Phase 5 (US4 Profile) | None (bug fixes recommended first) | All tasks independent of prior phases |
| Phase 6 (US5 Providers) | Phase 1 recommended | All tasks independent of each other |
| Phase 7 (Polish) | Phases 2–6 for T-036–T-039 | TSDoc tasks (T-032–T-035) are independent |

### Explicit Task Dependencies

| Task | Depends On | Reason |
|------|-----------|--------|
| T-005 | T-002 | API test verifies the 422 fix |
| T-006 | T-002 | UI test verifies the duplicate-username error message |
| T-007 | T-003 | UI test asserts the updated 8-char error string in sign-up |
| T-008 | T-003 | Aligns both forms at 8-char minimum consistently |
| T-013 | T-008 | `auth.spec.ts` assertion references the updated error string |
| T-014 | T-008 | Component test assertion references the updated error string |
| T-015 | T-001 | E2E test verifies the single-redirect logout fix |
| T-036 | T-009, T-010, T-017, T-018, T-022–T-026 | Validates all replacements compile cleanly |
| T-037 | T-003, T-008 | Confirms form schema changes satisfy linter |
| T-038 | T-003, T-008 | Jest tests must reflect new schema |
| T-039 | T-001–T-003, T-005–T-008, T-013–T-015 | Full E2E run validates all fixes together |

### User Story Independence

- **US1** (Sign-Up): Independent after T-002
- **US2** (Sign-In): Independent; T-008 chains from T-003 only for consistency
- **US3** (Sign-Out): Independent after T-001
- **US4** (Profile): Fully independent from US1–US3
- **US5** (Third-Party): Fully independent; env-gated specs skip gracefully without credentials

---

## Parallel Execution Examples

### Phase 1 (Foundational) — Sequential

```bash
# T-001 and T-002 touch different files — can run in parallel:
Task T-001: Fix double-redirect in backend/auth.ts
Task T-002: Add 422 duplicate-username check in backend/user-routes.ts
```

### Phase 2 (US1 Sign-Up) — Mixed

```bash
# Launch together (different files):
Task T-003: Fix SignUpForm.tsx password min-length
Task T-004: Add TSDoc to backend/database.ts (createUser, getUserByUsername)

# Wait for T-002, T-003 to complete, then launch together:
Task T-005: Add 422 API test in cypress/tests/api/api-users.spec.ts
Task T-006: Add duplicate-username UI test in cypress/tests/ui/auth.spec.ts
Task T-007: Update sign-up error assertion in cypress/tests/ui/auth.spec.ts
```

### Phase 3 (US2 Sign-In) — Highly Parallel

```bash
# Launch together (different files / different lines):
Task T-008: Fix SignInForm.tsx password min-length
Task T-009: Replace @ts-ignore:264 in src/machines/authMachine.ts
Task T-010: Replace @ts-ignore:271 in src/machines/authMachine.ts
Task T-012: Add TSDoc to backend/auth.ts login/checkAuth routes

# After T-008:
Task T-013: Update auth.spec.ts password assertion
Task T-014: Add component test assertion to SignInForm.cy.tsx
```

### Phase 5 (US4 Profile) — All Parallel

```bash
# All touch different files or different functions in the same file:
Task T-017: Replace @ts-ignore:100 in backend/helpers.ts
Task T-018: Replace @ts-ignore:104 in backend/helpers.ts
Task T-019: Add TSDoc to backend/database.ts (updateUserById, getUserById, etc.)
Task T-020: Add TSDoc to ensureAuthenticated/validateMiddleware in backend/helpers.ts
Task T-021: Add TSDoc to user-routes.ts route handlers
```

### Phase 6 (US5 Third-Party) — Highly Parallel

```bash
# All @ts-ignore replacements in distinct files/lines:
Task T-022: helpers.ts:8   (OktaJwtVerifier import)
Task T-023: helpers.ts:10  (aws-exports import)
Task T-024: helpers.ts:65  (OktaJwtPayload interface)
Task T-025: auth-provider-commands/auth0.ts  (autoEnd)
Task T-026: auth-provider-commands/okta.ts   (OktaAuth import)
Task T-027: Add TSDoc to JWT verifier exports in backend/helpers.ts

# All provider spec visual snapshot additions are fully independent:
Task T-028: auth0.spec.ts   — Percy snapshots
Task T-029: cognito.spec.ts — Percy snapshots + "shows onboarding"
Task T-030: okta.spec.ts    — Percy snapshots
Task T-031: google.spec.ts  — Percy snapshots
```

---

## Implementation Strategy

### MVP First (US1 + US2 + US3 — Local Auth Correctness)

1. Complete Phase 1: Foundational Bug Fixes (T-001, T-002)
2. Complete Phase 2: US1 Sign-Up fixes and tests (T-003–T-007)
3. Complete Phase 3: US2 Sign-In fixes and tests (T-008–T-014)
4. Complete Phase 4: US3 Sign-Out test (T-015, T-016)
5. **STOP and VALIDATE**:
   ```bash
   yarn cypress:run --spec "cypress/tests/ui/auth.spec.ts,cypress/tests/api/api-users.spec.ts"
   yarn types
   ```
   All local auth flows correct; no TypeScript errors from changed files.
6. Proceed to US4 and US5 as capacity allows.

### Incremental Delivery

| Milestone | Completion Criteria |
|-----------|-------------------|
| Bug Fix Baseline | T-001, T-002 done — logout single-redirect; POST /users 422 |
| Validation Alignment | T-003, T-008 done — both forms enforce 8-char minimum |
| TypeScript Hygiene | T-009, T-010, T-017–T-018, T-022–T-026 done — `yarn types` zero errors |
| Documentation Complete | All TSDoc tasks done — constitution §10 satisfied |
| Test Coverage Complete | T-005–T-007, T-013–T-015, T-028–T-031 done — constitution §3 satisfied |

### Parallel Team Strategy

With five developers working in parallel after Phase 1:

| Developer | Tasks |
|-----------|-------|
| Dev A | Phase 1 bugs (T-001, T-002) → US3 test (T-015, T-016) |
| Dev B | Password min-length fixes (T-003, T-008) + test updates (T-007, T-013, T-014) |
| Dev C | `@ts-ignore` sweep: authMachine (T-009, T-010), helpers (T-017–T-018, T-022–T-024) |
| Dev D | TSDoc additions: database.ts (T-004, T-019), auth.ts (T-012, T-016), helpers.ts (T-020, T-027), user-routes.ts (T-021), commands (T-032–T-035) |
| Dev E | Provider test coverage: T-025, T-026, T-028–T-031 |

---

## Task Summary

| Phase | Story | Task Count | Parallelizable |
|-------|-------|-----------|---------------|
| Phase 1 — Foundational | — | 2 | 2 |
| Phase 2 — US1 Sign-Up | US1 | 5 | 2 |
| Phase 3 — US2 Sign-In | US2 | 7 | 5 |
| Phase 4 — US3 Sign-Out | US3 | 2 | 1 |
| Phase 5 — US4 Profile | US4 | 5 | 5 |
| Phase 6 — US5 Third-Party | US5 | 10 | 10 |
| Phase 7 — Polish | — | 8 | 6 |
| **Total** | | **39** | **31** |

---

## Notes

- **`@ts-ignore` → `@ts-expect-error`**: Prefer `@ts-expect-error` (T-009, T-010, T-017–T-018, T-022–T-026) — it fails the type check if the upstream library later provides correct types, making suppressions self-documenting and self-removing. Reference: constitution §4.

- **Password min-length decision (T-003, T-008)**: The spec (`spec.md` §1) requires 8 characters. The current Yup schemas enforce 4. Tasks T-003 and T-008 update Yup to 8. Test assertions that reference "4 characters" (currently in `cypress/tests/ui/auth.spec.ts:124`) must be updated in T-007 and T-013. If other test files contain this string, search with `grep -r "4 characters" cypress/ src/` and update accordingly.

- **Provider specs are env-gated**: All code added in T-028–T-031 lives inside existing `if (Cypress.env("…"))` blocks. Never remove the guards — they implement the graceful-skip pattern required by constitution §7 and the CI secrets setup documented in the plan.

- **Percy visual snapshots**: T-028–T-031 add `cy.visualSnapshot()` calls inside provider specs. Percy baselines will be created on the next CI run with `PERCY_TOKEN` set. Without `PERCY_TOKEN`, `cy.visualSnapshot()` is a no-op (the command is defined defensively in `cypress/support/commands.ts`).

- **Run `yarn types` after every batch**: The `@ts-expect-error` replacements should compile cleanly. If `yarn types` surfaces a new error after a replacement, the suppressed error may have been masking an additional type issue — investigate before proceeding to T-036.

- **Commit strategy**: Commit after each task or logical group (e.g., all `@ts-ignore` replacements in one file). Use the task ID in the commit message (e.g., `fix(auth): T-001 consolidate logout redirect`).

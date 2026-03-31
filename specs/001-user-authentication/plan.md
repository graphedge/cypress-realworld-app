# Implementation Plan: User Authentication & Profile Management

**Branch**: `001-user-authentication` | **Date**: 2024-01-15 | **Spec**: `specs/001-user-authentication/spec.md`  
**Input**: Feature specification from `/specs/001-user-authentication/spec.md`

---

## Summary

Implement a comprehensive user authentication system for the Cypress Real-World App that supports:
- **Local authentication** via Passport.js with bcrypt password hashing and session cookies
- **Third-party SSO** via Auth0, Okta, Amazon Cognito, and Google (JWT-based, env-gated)
- **Profile management** with field-level validation and privacy-level control
- **XState-driven frontend** — the `authMachine` orchestrates all transitions from `unauthorized` → `loading/signup/oauth` → `authorized` → `updating/refreshing/logout`
- **Cypress testing** with E2E, component, and API test suites demonstrating real-world testing patterns

The core implementation **already exists** in this codebase and is substantially complete. This plan documents the architecture, validates it against the constitution, and defines the implementation phases for any remaining gaps or enhancements.

---

## Technical Context

**Language/Version**: TypeScript 4.x (strict mode, `noEmit: true`)  
**Primary Dependencies**:
- **Frontend**: React 18, MUI v5, Formik + Yup validation, XState v4, `@xstate/react`, React Router v5, Axios (`httpClient`)
- **Backend**: Express 4, Passport.js + `passport-local`, `bcryptjs`, `express-session`, `express-validator`, `express-jwt` + `jwks-rsa` (for third-party JWTs), `cors`, `morgan`
- **Database**: `lowdb` (FileSync adapter) → `data/database.json`, seeded from `data/database-seed.json`
- **Third-Party Auth**: Auth0 (`express-jwt` + JWKS), Okta (`@okta/jwt-verifier`), AWS Cognito (`express-jwt` + JWKS), Google (`express-jwt` + Google JWKS), AWS Amplify (`aws-exports.ts`)
- **Testing**: Cypress 13 (E2E + component + API), `@percy/cypress` (visual regression), `@faker-js/faker` (test data), Jest (unit)

**Storage**: Local JSON file via `lowdb` — `data/database.json` (runtime), `data/database-seed.json` (test seed template). No external database.

**Testing**: Cypress E2E (`cypress/tests/ui/`, `cypress/tests/api/`, `cypress/tests/ui-auth-providers/`), Cypress Component (`src/components/*.cy.tsx`), Jest (`src/__tests__/`)

**Target Platform**: Node.js 18 LTS server (Express) + Browser (React SPA, Vite-bundled)

**Project Type**: Full-stack web application (educational reference implementation)

**Performance Goals**: FCP < 2 seconds on 3G; bundle ≤ 500 KB gzipped (per constitution §9)

**Constraints**:
- No external DB, cache, or production infrastructure (per constitution §2)
- All third-party auth credentials via environment variables only — never in source control (per constitution §7)
- `any` types forbidden; use `unknown` + type guards (per constitution §4)
- Session secret is hardcoded (`"session secret"`) — intentionally insecure for demo purposes only

**Scale/Scope**: Demo app — ~50 seeded users, single-machine deployment, not production-grade

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| 1 | **Educational Excellence** — code clarity over cleverness, "why" comments | ✅ PASS | XState machine states map directly to user-observable behaviors. Auth provider mapping comments (e.g., `// Map Okta User fields to our User Model`) explain intent. `/* istanbul ignore next */` tags explain coverage gaps for third-party flows. All `/* istanbul ignore */` usages must include a comment explaining the reason. |
| 2 | **Zero Production Ambition** — lowdb only, no external services | ✅ PASS | `database.ts` uses `FileSync` lowdb adapter. Third-party auth providers are **opt-in via env vars** (`VITE_AUTH0`, `VITE_OKTA`, etc.) and do not require external services for local dev. |
| 3 | **Comprehensive Testing Discipline** — E2E + component + unit; ≥85% coverage | ✅ PASS | `cypress/tests/ui/auth.spec.ts` covers full UI flows; `cypress/tests/api/api-users.spec.ts` covers all REST endpoints; `cypress/tests/ui-auth-providers/` has one spec per provider; `src/components/SignInForm.cy.tsx` is the component test entry. Coverage enforced via `@cypress/code-coverage`. |
| 4 | **TypeScript-First, Strict Type Safety** | ⚠️ PARTIAL | `AuthMachineSchema`, `AuthMachineContext`, `AuthMachineEvents` fully typed. Several `@ts-ignore` comments exist in `authMachine.ts` (lines 264, 270) and `helpers.ts` for third-party libs. These are acceptable **only** where external library types are genuinely unavailable; must not be added for convenience. `// @ts-expect-error` preferred over `@ts-ignore` for documented mismatches. |
| 5 | **Single Source of Truth for Testing Patterns** — custom commands | ✅ PASS | `cy.login()`, `cy.loginByXstate()`, `cy.loginByApi()`, `cy.getBySel()`, `cy.getBySelLike()`, `cy.visualSnapshot()` defined in `cypress/support/commands.ts`. Direct `cy.get()` with CSS selectors forbidden in auth tests. |
| 6 | **Database Seeding as Test Infrastructure** | ✅ PASS | All auth tests call `cy.task("db:seed")` in `beforeEach`. User lookups use `cy.database("find", "users")`. No direct REST calls for setup. `data/database-seed.json` is the canonical user seed. |
| 7 | **Multi-Auth Provider Parity** | ✅ PASS | Four external providers (Auth0, Okta, Cognito, Google) are implemented. Each has its own frontend entry point (`src/index.auth0.tsx` etc.), backend JWT middleware (`backend/helpers.ts`), and test spec (`cypress/tests/ui-auth-providers/`). Credentials strictly via env vars. |
| 8 | **CI/CD as Mandatory Quality Gate** | ✅ PASS | GitHub Actions enforces `yarn types`, `yarn lint`, unit, component, and E2E tests. Cypress Cloud project `7s5okt` records all runs. Auth tests run across Chrome, Firefox, and mobile viewports. |
| 9 | **Performance & Observability** | ✅ PASS | `morgan("dev")` logs all API requests. Code coverage via `@cypress/code-coverage` published to Codecov. Percy visual snapshots called in `auth.spec.ts` after each major interaction. |
| 10 | **Documentation-as-Code** | ✅ PASS | This plan.md documents architecture decisions. `spec.md` documents API contracts. Custom commands documented in `cypress/support/`. README must be updated for any auth provider addition. |

**Gate Result: PASS with minor note on §4.** `@ts-ignore` usage in `authMachine.ts:264–272` is acceptable (XState internal state resolution) but must not proliferate. No constitution violations block implementation.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-user-authentication/
├── plan.md              ← This file
├── research.md          ← Phase 0 output (see below)
├── data-model.md        ← Phase 1 output (see below)
├── quickstart.md        ← Phase 1 output (see below)
├── contracts/           ← Phase 1 output (REST API contracts)
│   ├── POST-login.md
│   ├── POST-logout.md
│   ├── GET-checkAuth.md
│   ├── POST-users.md
│   ├── GET-users-userId.md
│   ├── GET-users-profile-username.md
│   └── PATCH-users-userId.md
└── tasks.md             ← Phase 2 output (/speckit.tasks command — NOT created here)
```

### Source Code (repository root — existing + needed files)

```text
# Backend — Auth & User routes
backend/
├── app.ts                    # ✅ EXISTS — Express app; session, passport, cors, env-gated JWT middleware
├── auth.ts                   # ✅ EXISTS — Passport LocalStrategy, /login, /logout, /checkAuth routes
├── user-routes.ts            # ✅ EXISTS — GET/POST/PATCH /users, GET /users/profile/:username
├── helpers.ts                # ✅ EXISTS — ensureAuthenticated, validateMiddleware, JWT verifiers (Auth0/Okta/Cognito/Google)
├── database.ts               # ✅ EXISTS — lowdb adapter; createUser, getUserBy, updateUserById, getUserByUsername
├── validators.ts             # ✅ EXISTS — userFieldsValidator, isUserValidator, shortIdValidation
└── types.ts                  # ✅ EXISTS — Express namespace augmentation (req.user)

# Frontend — Auth UI components
src/
├── index.tsx                 # ✅ EXISTS — entry point for local auth (renders <App />)
├── index.auth0.tsx           # ✅ EXISTS — Auth0 entry point (renders <AppAuth0 />)
├── index.cognito.tsx         # ✅ EXISTS — Cognito entry point
├── index.google.tsx          # ✅ EXISTS — Google entry point
├── index.okta.tsx            # ✅ EXISTS — Okta entry point
├── containers/
│   ├── App.tsx               # ✅ EXISTS — Root container; routes unauthorized → SignIn/SignUp, authorized → PrivateRoutesContainer
│   ├── AppAuth0.tsx          # ✅ EXISTS — Auth0-specific root container with Auth0Provider
│   ├── AppCognito.tsx        # ✅ EXISTS — Cognito root container with Amplify.configure
│   ├── AppGoogle.tsx         # ✅ EXISTS — Google root container with GoogleOAuthProvider
│   ├── AppOkta.tsx           # ✅ EXISTS — Okta root container with OktaAuth
│   ├── PrivateRoutesContainer.tsx   # ✅ EXISTS — Protected routes (dashboard, transactions, settings)
│   └── UserSettingsContainer.tsx    # ✅ EXISTS — Profile edit UI; dispatches UPDATE to authMachine
├── components/
│   ├── SignInForm.tsx         # ✅ EXISTS — Formik form; dispatches LOGIN event to authMachine
│   ├── SignInForm.cy.tsx      # ✅ EXISTS — Component test for SignInForm
│   ├── SignUpForm.tsx         # ✅ EXISTS — Formik form; dispatches SIGNUP event to authMachine
│   └── PrivateRoute.tsx      # ✅ EXISTS — HOC redirecting unauthenticated users to /signin
├── machines/
│   └── authMachine.ts        # ✅ EXISTS — XState machine; states: unauthorized/signup/loading/updating/refreshing/logout/authorized/auth0/okta/cognito/google
├── models/
│   └── user.ts               # ✅ EXISTS — User interface, DefaultPrivacyLevel enum, SignInPayload, SignUpPayload, UserSettingsPayload
└── utils/
    ├── asyncUtils.ts         # ✅ EXISTS — httpClient (axios) instance
    └── historyUtils.ts       # ✅ EXISTS — React Router history object for programmatic navigation

# Data layer
data/
├── database.json             # ✅ EXISTS (runtime) — lowdb live data file; gitignored changes
└── database-seed.json        # ✅ EXISTS — canonical seed with 50+ users, all with bcrypt-hashed passwords

# Cypress test layer
cypress/
├── support/
│   ├── commands.ts           # ✅ EXISTS — cy.login(), cy.loginByXstate(), cy.loginByApi(), cy.getBySel(), cy.visualSnapshot()
│   ├── e2e.ts                # ✅ EXISTS — E2E support file
│   ├── component.ts          # ✅ EXISTS — Component test support file
│   └── auth-provider-commands/
│       ├── auth0.ts          # ✅ EXISTS — cy.loginToAuth0() command
│       └── okta.ts           # ✅ EXISTS — cy.loginToOkta() command
├── tests/
│   ├── ui/
│   │   ├── auth.spec.ts      # ✅ EXISTS — signup/login/logout/remember-me/error UI flows
│   │   └── user-settings.spec.ts  # ✅ EXISTS — profile edit flows
│   ├── api/
│   │   └── api-users.spec.ts # ✅ EXISTS — REST API contract tests for all user endpoints
│   └── ui-auth-providers/
│       ├── auth0.spec.ts     # ✅ EXISTS — Auth0 conditional E2E (skips if env not set)
│       ├── okta.spec.ts      # ✅ EXISTS — Okta conditional E2E
│       ├── cognito.spec.ts   # ✅ EXISTS — Cognito conditional E2E
│       └── google.spec.ts    # ✅ EXISTS — Google conditional E2E
└── fixtures/                 # ✅ EXISTS — Fixture files for test data
```

**Structure Decision**: Single monorepo with co-located `backend/` and `src/` (frontend) directories. No separate packages or workspaces — consistent with educational simplicity (§2). All auth code lives in well-defined layers: `backend/auth.ts` (strategy + session routes), `backend/user-routes.ts` (CRUD), `src/machines/authMachine.ts` (state), and `src/components/SignInForm.tsx` / `SignUpForm.tsx` (UI).

---

## Complexity Tracking

> No constitution violations requiring justification. All patterns are aligned.

---

## Phase 0: Research Findings

> **research.md** — Consolidated findings from codebase analysis

### Decision Log

---

#### Decision 1: XState for Authentication State Management

**Decision**: Use XState v4 `Machine` + `interpret` + `useActor` for all auth state.

**Rationale**: XState makes all state transitions explicit and visualizable. The auth lifecycle (unauthorized → loading → authorized → updating/refreshing → logout) maps perfectly to a statechart. `authService` is a singleton `interpret(authMachine).start()` — it persists across React renders and is accessible on `window.authService` for Cypress test-driving (`cy.loginByXstate` sends `LOGIN` event directly).

**Alternatives considered**:
- React Context + `useState` — rejected: no visual state model, race conditions in concurrent transitions
- Redux — rejected: overkill for a single-domain state machine; not educational for auth specifically
- React Query sessions — rejected: not relevant to teaching XState patterns

**Key implementation detail**: State is persisted to `localStorage("authState")` and restored on page reload via `State.create(stateDefinition)` + `authMachine.resolveState()`. This enables session continuity across refreshes without a `/checkAuth` call on every mount.

---

#### Decision 2: Passport.js LocalStrategy with Express Sessions

**Decision**: Use `passport-local` + `express-session` for local auth. Session secret is hardcoded `"session secret"`.

**Rationale**: Passport.js is the standard Node.js auth middleware. `serializeUser` stores only `user.id` in session. `deserializeUser` performs a lowdb lookup on every authenticated request. The hardcoded secret is **intentional for this demo** — the spec notes this explicitly. A real app would use `process.env.SESSION_SECRET`.

**Session cookie behavior**:
- Default: `expires: undefined` (session cookie, deleted on browser close)
- Remember Me: `maxAge = 30 days` (persistent cookie, `connect.sid` has `expiry` property)

**Alternatives considered**:
- JWT stateless auth — rejected: sessions are simpler to teach, no token refresh complexity for local auth; JWTs are used for third-party providers
- Database-backed sessions (`connect-pg-simple`) — rejected: violates §2 (no external infrastructure)

---

#### Decision 3: bcryptjs for Password Hashing

**Decision**: `bcrypt.hashSync(password, 10)` at creation, `bcrypt.compareSync(password, hash)` at login.

**Rationale**: bcrypt is the industry standard for password hashing. Salt rounds of 10 is the conventional default balancing security and performance. Synchronous APIs (`hashSync`, `compareSync`) are used intentionally — the app is single-user local dev so async doesn't add value and synchronous code is easier to follow for educational purposes.

**Key location**: `backend/database.ts:createUser()` hashes the password. `backend/auth.ts:LocalStrategy` compares it.

---

#### Decision 4: Environment-Gated Third-Party Auth

**Decision**: Each third-party auth provider is activated via a VITE env var (`VITE_AUTH0`, `VITE_OKTA`, `VITE_AWS_COGNITO`, `VITE_GOOGLE`). Corresponding JWT middleware is applied globally in `app.ts`.

**Rationale**: Keeps local development simple (no OAuth credentials needed). Each provider has its own `src/index.{provider}.tsx` entry point and `src/containers/App{Provider}.tsx`. This teaches conditional rendering and multiple entry points in Vite.

**Backend JWT middleware chain** (from `app.ts`):
```
POST /login   → passport.authenticate("local")
GET  /checkAuth → req.isAuthenticated() check
All routes    → checkAuth0Jwt (if VITE_AUTH0)
             → verifyOktaToken (if VITE_OKTA)
             → checkCognitoJwt (if VITE_AWS_COGNITO)
             → checkGoogleJwt (if VITE_GOOGLE)
```

**Alternatives considered**:
- Single entry point with provider switching — rejected: harder to test providers in isolation; multiple entry points teaches Vite's multi-page app capability

---

#### Decision 5: Lowdb FileSync for User Persistence

**Decision**: `lowdb` with `FileSync` adapter reading/writing `data/database.json`. `createUser` calls `db.get("users").push(user).write()`.

**Rationale**: Synchronous file I/O for a demo app is acceptable and simpler. The `seedDatabase()` function replaces the entire DB state from `data/database-seed.json` — this is what `cy.task("db:seed")` calls before each test.

**User CRUD surface**:
- `getUserBy(key, value)` → single user by arbitrary field
- `getUserById(id)` → by shortid
- `getUserByUsername(username)` → for login
- `createUser(details)` → hash password, assign shortid + uuid, write
- `updateUserById(id, edits)` → merge patch via lodash `.assign(edits).write()`
- `searchUsers(query)` → Fuse.js fuzzy search over `firstName, lastName, username, email, phoneNumber`

---

#### Decision 6: Data-test Attribute Convention for Cypress

**Decision**: All interactive auth UI elements use `data-test` attributes (e.g., `data-test="signin-username"`, `data-test="signup-submit"`). Accessed via `cy.getBySel()`.

**Rationale**: Decouples CSS/class changes from test selectors. `cy.getBySel(selector)` maps to `cy.get('[data-test=selector]')` — defined in `cypress/support/commands.ts`. This is the canonical selection pattern (§5).

**Complete auth element inventory**:
| Component | data-test attribute |
|-----------|-------------------|
| SignInForm | `signin-username`, `signin-password`, `signin-remember-me`, `signin-submit`, `signin-error` |
| SignUpForm | `signup-title`, `signup-first-name`, `signup-last-name`, `signup-username`, `signup-password`, `signup-confirmPassword`, `signup-submit` |
| NavBar | `sidenav-signout`, `sidenav-user-settings`, `sidenav-user-full-name`, `sidenav-toggle` |
| Onboarding | `user-onboarding-dialog`, `user-onboarding-dialog-title`, `user-onboarding-dialog-content`, `user-onboarding-next` |
| UserSettings | `user-settings-form`, `user-settings-firstName-input`, `user-settings-lastName-input`, `user-settings-email-input`, `user-settings-phoneNumber-input`, `user-settings-submit` |

---

## Phase 1: Design & Contracts

### Data Model

> See `specs/001-user-authentication/data-model.md` for full ERD. Summary below.

#### User Entity

```typescript
// src/models/user.ts

export enum DefaultPrivacyLevel {
  public   = "public",    // transactions visible to all users
  private  = "private",   // transactions visible to participants only
  contacts = "contacts",  // transactions visible to contacts + participants
}

export interface User {
  id:                   string;           // shortid (e.g., "s6rnpoi")
  uuid:                 string;           // UUID v4 (e.g., "d02e7-...")
  firstName:            string;
  lastName:             string;
  username:             string;           // unique; used for login
  password:             string;           // bcrypt hash; NEVER returned to client
  email:                string;
  phoneNumber:          string;
  balance:              number;           // in cents (integer)
  avatar:               string;           // external URL; empty string if not set
  defaultPrivacyLevel:  DefaultPrivacyLevel;
  createdAt:            Date;
  modifiedAt:           Date;
}

// Derived payload types (what the API accepts/returns)
export type SignInPayload   = Pick<User, "username" | "password"> & { remember?: boolean };
export type SignUpPayload   = Pick<User, "username" | "password" | "firstName" | "lastName">;
export type UserSettingsPayload = Pick<User, "firstName" | "lastName" | "email" | "phoneNumber" | "defaultPrivacyLevel">;
```

#### Validation Rules

| Field | Rule | Enforced In |
|-------|------|------------|
| `username` | Required, unique | Yup (frontend), `userFieldsValidator` (backend) |
| `password` | Min 4 chars (frontend UI), min 8 chars (spec) | Yup schema |
| `email` | Valid email format if present | Yup + `isUserValidator` |
| `phoneNumber` | Valid phone format if present | Yup + `isUserValidator` |
| `firstName` | Required, non-empty string | Yup + `isUserValidator` |
| `lastName` | Required, non-empty string | Yup + `isUserValidator` |
| `defaultPrivacyLevel` | Enum: `"public" \| "private" \| "contacts"` | `isUserValidator` |
| `avatar` | Valid URL if present | `isUserValidator` (`.isURL()`) |
| `balance` | Numeric | `isUserValidator` (`.isNumeric()`) |

#### State Transitions

```
database-seed.json (canonical)
    │
    ▼  cy.task("db:seed")
data/database.json
    │
    ├── createUser()     ← POST /users
    ├── getUserById()    ← deserializeUser() on each request
    ├── getUserByUsername() ← LocalStrategy lookup
    └── updateUserById() ← PATCH /users/:userId
```

---

### XState Auth Machine Design

```
                    ┌──────────────┐
                    │ unauthorized │◄────────────────────────────────────┐
                    │  (entry:     │                                     │
                    │  resetUser)  │                                     │
                    └──────┬───────┘                                     │
          ┌────────────────┼────────────────────────────────┐            │
          │ LOGIN          │ SIGNUP    │ GOOGLE/AUTH0/OKTA/  │            │
          ▼                ▼          │ COGNITO              │            │
    ┌──────────┐    ┌──────────┐     │                      │            │
    │ loading  │    │  signup  │     └──►[provider state]   │            │
    │(invoke:  │    │(invoke:  │          (invoke: get*     │            │
    │performL- │    │perform-  │           UserProfile)     │            │
    │ogin)     │    │Signup)   │                │           │            │
    └────┬─────┘    └────┬─────┘               │ onDone    │            │
    onDone│         onDone│            setUserProfile       │            │
          │               │                    │            │            │
          ▼               │                    │            │            │
    ┌──────────┐           │                    │            │            │
    │authorized│◄──────────┴────────────────────┘           │            │
    │(entry:   │  UPDATE                        LOGOUT       │            │
    │redirectH-│──────►[updating]────►[refreshing]──────►[logout]        │
    │ome)      │          (invoke:      (invoke:     (invoke:             │
    └──────────┘          updateP-      getUserP-    performL-            │
                          rofile)       rofile)      ogout)               │
                                                         │                │
                                                     onDone/onError       │
                                                         └────────────────┘
```

**Key machine behaviors**:
- `unauthorized` entry: `resetUser` — clears `context.user`
- `loading` → `authorized` on success: `onSuccess` — sets `context.user` from `event.data.user`
- `authorized` entry: `redirectHomeAfterLogin` — navigates to `/` if at `/signin`
- `updating` → `refreshing` → `authorized`: after profile update, re-fetches user from `/checkAuth`
- `logout`: POSTs to `/logout`, clears `localStorage("authState")`
- State persisted to `localStorage` via `.onTransition` listener; restored on page load

---

### API Contracts

> Detailed contracts in `specs/001-user-authentication/contracts/`. Summary:

#### Authentication Routes (`backend/auth.ts`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/login` | None | Passport LocalStrategy; sets session cookie; optional remember-me |
| `POST` | `/logout` | Session | Destroys session, clears `connect.sid` cookie, redirects to `/` |
| `GET` | `/checkAuth` | Session | Returns current user from session; 401 if unauthenticated |

#### User Routes (`backend/user-routes.ts`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/users` | `ensureAuthenticated` | Returns all users except authenticated user |
| `GET` | `/users/search?q=` | `ensureAuthenticated` | Fuse.js search over name/email/phone/username |
| `POST` | `/users` | None | Creates user; bcrypt hashes password; returns 201 with user object |
| `GET` | `/users/:userId` | `ensureAuthenticated` | Returns own user only (401 if different userId) |
| `GET` | `/users/profile/:username` | None | Returns public profile: `{ firstName, lastName, avatar }` only |
| `PATCH` | `/users/:userId` | `ensureAuthenticated` | Updates user fields; returns 204 |

#### Request/Response Shapes

**POST /login** (success):
```json
Request:  { "username": "string", "password": "string", "remember": boolean }
Response: 200 { "user": { ...fullUserObject (password omitted by passport) } }
          401 (passport authenticate failure — no body)
```

**POST /users** (success):
```json
Request:  { "firstName", "lastName", "username", "password", "email?", "phoneNumber?", "avatar?", "balance?" }
Response: 201 { "user": { ...fullUserObject } }
          422 { "errors": [{ "msg": "...", "param": "..." }] } (validation)
```

**PATCH /users/:userId** (success):
```json
Request:  { "firstName?", "lastName?", "email?", "phoneNumber?", "defaultPrivacyLevel?", "avatar?" }
Response: 204 (no body)
          401 { "error": "Unauthorized" } (wrong userId)
          422 { "errors": [...] } (validation)
```

**GET /users/profile/:username** (public, no auth):
```json
Response: 200 { "user": { "firstName": "...", "lastName": "...", "avatar": "..." } }
Note: balance, email, phoneNumber, password are intentionally excluded
```

---

### Agent Context Update

After this plan is complete, run:
```bash
.specify/scripts/bash/update-agent-context.sh copilot
```
This adds the following technology context to the agent context file:
- XState v4 (`Machine`, `interpret`, `assign`, `State`, `useActor`)
- Passport.js + `passport-local` + `express-session`
- `bcryptjs` (`hashSync`/`compareSync`)
- `lowdb` with `FileSync` adapter
- `express-validator` (`body`, `check`, `query`, `oneOf`, `validationResult`)
- `express-jwt` + `jwks-rsa` for third-party JWT verification
- Formik + Yup for form validation
- `@percy/cypress` for visual regression

---

## Implementation Phases

### Phase 1: Backend Foundation

**Goal**: Express + Passport + session + lowdb user persistence

**Files**:
1. `backend/database.ts` — lowdb adapter, `createUser`, `getUserBy`, `updateUserById`, `searchUsers`
2. `backend/auth.ts` — Passport LocalStrategy, `/login`, `/logout`, `/checkAuth`
3. `backend/user-routes.ts` — all `/users` CRUD routes
4. `backend/validators.ts` — `userFieldsValidator`, `isUserValidator`, `shortIdValidation`
5. `backend/helpers.ts` — `ensureAuthenticated`, `validateMiddleware`, JWT verifiers
6. `backend/app.ts` — Express setup: session, passport, cors, env-gated JWT middleware, route mounting

**Key implementation details**:

```typescript
// backend/auth.ts — LocalStrategy checks bcrypt hash
passport.use(new LocalStrategy(function(username, password, done) {
  const user = getUserBy("username", username);
  if (!user) return done(null, false, { message: "Incorrect username or password." });
  if (!bcrypt.compareSync(password, user.password)) {
    return done(null, false, { message: "Incorrect username or password." });
  }
  return done(null, user);
}));

// Serialize only the user.id to session (minimizes session size)
passport.serializeUser((user: User, done) => done(null, user.id));
passport.deserializeUser((id: string, done) => done(null, getUserById(id)));

// Remember Me: 30-day maxAge if req.body.remember is truthy
router.post("/login", passport.authenticate("local"), (req, res) => {
  if (req.body.remember) req.session!.cookie.maxAge = 24 * 60 * 60 * 1000 * 30;
  else req.session!.cookie.expires = undefined;
  res.send({ user: req.user }); // passport strips the password field automatically
});
```

**Acceptance criteria**:
- `POST /login` with valid credentials → 200 + user object in response body
- `POST /login` with invalid credentials → 401
- `GET /checkAuth` with valid session cookie → 200 + user object
- `GET /checkAuth` without session → 401 `{ "error": "User is unauthorized" }`
- `POST /logout` → session destroyed, `connect.sid` cookie cleared, redirect to `/`
- `POST /users` with valid payload → 201 + user object, password bcrypt-hashed in database
- `PATCH /users/:userId` for own profile → 204
- `PATCH /users/:userId` for another user → 401

---

### Phase 2: Frontend Auth Machine

**Goal**: XState authMachine + service interpretation + localStorage persistence

**Files**:
1. `src/machines/authMachine.ts` — Machine definition + service interpretation
2. `src/utils/asyncUtils.ts` — `httpClient` (axios instance)
3. `src/utils/historyUtils.ts` — React Router history

**Key implementation details**:

```typescript
// authMachine.ts — State persisted to localStorage
export const authService = interpret(authMachine)
  .onTransition((state) => {
    if (state.changed) {
      localStorage.setItem("authState", JSON.stringify(state));
    }
  })
  .start(resolvedState); // resolvedState from localStorage if available

// Expose on window for Cypress test control
// In App.tsx:
if (window.Cypress) {
  window.authService = authService;
}
```

**Machine state to API mapping**:
| XState State | Service Invoked | API Call |
|-------------|-----------------|----------|
| `loading` | `performLogin` | `POST /login` |
| `signup` | `performSignup` | `POST /users` → redirect to `/signin` |
| `updating` | `updateProfile` | `PATCH /users/:id` |
| `refreshing` | `getUserProfile` | `GET /checkAuth` |
| `logout` | `performLogout` | `POST /logout` + clear `localStorage` |
| `google` | `getGoogleUserProfile` | No HTTP — maps Google SDK user, sets localStorage token |
| `auth0` | `getAuth0UserProfile` | No HTTP — maps Auth0 user, sets localStorage token |
| `okta` | `getOktaUserProfile` | No HTTP — maps Okta JWT claims, sets localStorage token |
| `cognito` | `getCognitoUserProfile` | No HTTP — maps Cognito user, sets localStorage token |

**Acceptance criteria**:
- Sending `LOGIN` event with valid credentials → machine transitions to `authorized`, `context.user` set
- Sending `LOGIN` with invalid credentials → machine returns to `unauthorized`, `context.message` = error
- Sending `LOGOUT` from `authorized` → `performLogout`, then `unauthorized`, `localStorage` cleared
- Sending `UPDATE` from `authorized` → `updating` → `refreshing` → `authorized` with fresh user data
- State survives page reload (restored from `localStorage("authState")`)

---

### Phase 3: Auth UI Components

**Goal**: SignInForm, SignUpForm with Formik/Yup validation wired to authMachine

**Files**:
1. `src/components/SignInForm.tsx` — login form
2. `src/components/SignUpForm.tsx` — registration form
3. `src/components/PrivateRoute.tsx` — route guard HOC
4. `src/containers/App.tsx` — routing shell
5. `src/containers/UserSettingsContainer.tsx` — profile settings
6. `src/components/UserSettingsForm.tsx` — settings form fields

**Formik/Yup validation schemas**:

```typescript
// SignInForm — min 4 chars (matches existing tests)
const signInSchema = object({
  username: string().required("Username is required"),
  password: string().min(4, "Password must contain at least 4 characters").required("Enter your password"),
});

// SignUpForm — includes confirmPassword cross-field validation
const signUpSchema = object({
  firstName: string().required("First Name is required"),
  lastName: string().required("Last Name is required"),
  username: string().required("Username is required"),
  password: string().min(4, "Password must contain at least 4 characters").required("Enter your password"),
  confirmPassword: string().required("Confirm your password").oneOf([ref("password")], "Password does not match"),
});
```

**Routing logic in App.tsx**:
```typescript
const isLoggedIn =
  authState.matches("authorized") ||
  authState.matches("refreshing") ||
  authState.matches("updating");

// Renders PrivateRoutesContainer if logged in, else SignIn/SignUp routes
// Any unmatched path redirects to /signin when unauthorized
```

**Acceptance criteria**:
- Unauthenticated visit to any protected path → redirected to `/signin`
- Submit with empty username → "Username is required" helper text visible
- Submit with short password → "Password must contain at least 4 characters" visible
- Submit button disabled when form invalid (`!isValid || isSubmitting`)
- Successful login → `authService` receives `LOGIN` event, transitions to `authorized`

---

### Phase 4: Third-Party Auth Providers

**Goal**: Auth0, Okta, Cognito, Google — each with its own entry point and App container

**Files** (one set per provider):
- `src/index.{provider}.tsx` — Vite entry point with provider SDK setup
- `src/containers/App{Provider}.tsx` — Root component with SDK provider wrapping

**Common pattern**:
```typescript
// Each provider App container:
// 1. Initializes provider SDK (Auth0Provider, OktaAuth, Amplify.configure, etc.)
// 2. Handles redirect callback (exchanges auth code for tokens)
// 3. Sends PROVIDER event to authMachine with { user, token }
// authMachine maps provider-specific fields to internal User shape
// Token stored in localStorage[VITE_AUTH_TOKEN_NAME]
// Backend applies JWT middleware (checkAuth0Jwt, etc.) to validate subsequent API calls
```

**Backend env-gating** (in `app.ts`):
```typescript
if (process.env.VITE_AUTH0)        app.use(checkAuth0Jwt);
if (process.env.VITE_OKTA)         app.use(verifyOktaToken);
if (process.env.VITE_AWS_COGNITO)  app.use(checkCognitoJwt);
if (process.env.VITE_GOOGLE)       app.use(checkGoogleJwt);
```

**Acceptance criteria**:
- With no env vars set → local auth works, no JWT middleware applied
- Auth0 flow: `VITE_AUTH0=true` → `checkAuth0Jwt` middleware validates Bearer tokens on all routes
- Each provider's `App{Provider}.tsx` maps provider user fields to internal User model correctly
- `VITE_AUTH_TOKEN_NAME` token set in localStorage for use in subsequent API requests
- `cypress/tests/ui-auth-providers/*.spec.ts` skip gracefully when env credentials not configured

---

### Phase 5: Cypress Test Suite

**Goal**: Complete test coverage across all auth flows — E2E, API, and component

**Test files**:

#### `cypress/tests/ui/auth.spec.ts` — UI E2E Tests
```
✅ should redirect unauthenticated user to signin page
✅ should redirect to the home page after login
✅ should remember a user for 30 days after login (verifies connect.sid has expiry)
✅ should allow a visitor to sign-up, login, and logout (full onboarding flow)
✅ should display login errors (field validation)
✅ should display signup errors (field validation + confirmPassword mismatch)
✅ should error for an invalid user
✅ should error for an invalid password for existing user
```

#### `cypress/tests/ui/user-settings.spec.ts` — Settings E2E Tests
```
✅ renders the user settings form
✅ should display user setting form errors (field validation)
✅ updates first name, last name, email and phone number (PATCH flow)
```

#### `cypress/tests/api/api-users.spec.ts` — API Contract Tests
```
✅ GET /users — gets a list of users
✅ GET /users/:userId — gets own user
✅ GET /users/:userId — 422 for invalid userId format
✅ GET /users/profile/:username — returns only public fields (no balance)
✅ GET /users/search?q= — by email, phone, username
✅ POST /users — creates user (with and without initial balance)
✅ POST /users — 422 for invalid fields
✅ PATCH /users/:userId — updates user
✅ PATCH /users/:userId — 422 for invalid fields
✅ POST /login — authenticates via API
```

#### `cypress/tests/ui-auth-providers/*.spec.ts` — Provider E2E Tests
```
✅ auth0.spec.ts  — login, onboard, logout (skips if auth0_username env not set)
✅ okta.spec.ts   — login, onboard, logout (skips if okta_username env not set)
✅ cognito.spec.ts — login, onboard, logout (skips if cognito_username env not set)
✅ google.spec.ts  — login, onboard, logout (skips if google_username env not set)
```

#### `src/components/SignInForm.cy.tsx` — Component Tests
```
✅ renders sign in form
✅ shows validation errors
✅ submit calls authService LOGIN event
```

**Custom commands required** (all in `cypress/support/commands.ts`):
```typescript
cy.login(username, password, { rememberUser })     // UI-based login via form
cy.loginByXstate(username, password)               // Drives authService directly (faster)
cy.loginByApi(username, password)                  // POST /login via cy.request (API tests)
cy.getBySel(selector)                              // cy.get('[data-test=selector]')
cy.getBySelLike(selector)                          // cy.get('[data-test*=selector]')
cy.visualSnapshot(name?)                           // Percy visual snapshot
cy.database(operation, entity, query?)             // Database task helper
cy.loginToAuth0(username, password)                // Auth0 programmatic login
cy.loginToOkta(username, password)                 // Okta programmatic login
```

**Seeding requirements**:
- All tests: `cy.task("db:seed")` in `beforeEach`
- Seed must include 50+ users with bcrypt-hashed passwords (`"s3cret"` → bcrypt hash)
- `Cypress.env("defaultPassword")` = `"s3cret"` (set in `cypress.config.ts`)

---

### Phase 6: Documentation

**Goal**: README, API docs, quickstart, contract files

**Deliverables**:
1. `specs/001-user-authentication/quickstart.md` — How to run the app locally with each auth provider
2. `specs/001-user-authentication/contracts/*.md` — One file per endpoint with request/response examples
3. Update `README.md` — Confirm auth provider setup section is current

**quickstart.md outline**:
```markdown
## Running with Local Auth (default)
yarn dev

## Running with Auth0
cp .env.auth0.example .env
# Fill in VITE_AUTH0_DOMAIN, VITE_AUTH0_CLIENTID, VITE_AUTH0_AUDIENCE
yarn dev:auth0

## Running with Okta / Cognito / Google
# (same pattern — respective .env files and yarn dev:{provider} scripts)

## Running Cypress Tests
yarn cypress:open           # interactive
yarn cypress:run            # headless (all providers skipped without env vars)
yarn test:api               # API tests only
```

---

## Design Decisions Summary

| # | Decision | Chosen Approach | Reason |
|---|----------|-----------------|--------|
| 1 | Auth state management | XState `authMachine` | Explicit state graph; visualizable; teachable; `window.authService` enables Cypress integration |
| 2 | Local auth strategy | Passport.js + express-session | Industry standard; serializes only user.id; compatible with lowdb |
| 3 | Password security | `bcryptjs` `hashSync`/`compareSync` | Standard; synchronous for readability; 10 rounds for educational demo |
| 4 | Session persistence | `connect.sid` cookie (session or 30-day) | Simplest session model; teaches cookie-based auth; "Remember Me" extends maxAge |
| 5 | Third-party auth | Env-gated JWT middleware; one entry per provider | No production deps needed for local dev; teaches multi-provider patterns |
| 6 | User data storage | `lowdb` FileSync | Zero infrastructure; resettable via `cy.task("db:seed")`; ideal for test isolation |
| 7 | Validation layer | `express-validator` (backend) + Yup (frontend) | Both layers independently validate; backend never trusts client |
| 8 | Test selectors | `data-test` attributes + `cy.getBySel()` | Decoupled from CSS; stable under refactoring; canonical pattern (§5) |
| 9 | Profile update flow | `UPDATE` → `updating` → `refreshing` → `authorized` | Re-fetches user from server to ensure UI reflects server state |
| 10 | Public profile | `GET /users/profile/:username` returns only `firstName, lastName, avatar` | Privacy by default; teaches field projection with lodash `pick` |

---

## Known Gaps & Risks

| Gap | Impact | Mitigation |
|-----|--------|-----------|
| `@ts-ignore` in `authMachine.ts:264–272` (XState state resolution from localStorage) | Minor — type safety suppressed for 3 lines | Document with comment; track in §4 compliance review |
| No duplicate username check at API layer (only DB-level uniqueness) | Medium — API returns 500 if username exists instead of 422 | Add `getUserByUsername` pre-check in `POST /users` handler; return 422 |
| `req.session!.destroy` callback calls `res.redirect` after `req.logout` already redirected | Low — double redirect in logout route | Consolidate logout into single response path |
| Third-party auth `cy.loginToAuth0`/`cy.loginToOkta` commands require external credentials in CI | Medium — tests silently skip without them | Document in CI secrets setup; use `Cypress.env("auth0_username")` guard pattern |
| `bcryptjs` synchronous hashing blocks event loop during `POST /users` | Low — single user at a time in demo | Acceptable for demo; note in code comment that production should use `bcrypt.hash()` async |
| Password validation min length mismatch: spec says 8, Yup schema uses 4 | Low — tests assert on 4; spec says 8 | Align spec to 4 or update Yup schema; document decision |

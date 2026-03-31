# Implementation Plan: Bank Accounts & Transfers

**Branch**: `003-bank-accounts-transfers` | **Date**: 2026-03-31 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/003-bank-accounts-transfers/spec.md`

---

## Summary

Full-stack TypeScript feature enabling users to link external bank accounts and perform
deposit/withdrawal transfers between those accounts and their in-app wallet. The backend
exposes REST CRUD endpoints (`/bankAccounts`) and a read-only `/bankTransfers` endpoint,
while the React frontend consumes GraphQL exclusively through an XState `bankAccountsMachine`
that extends the shared `dataMachine` pattern. Bank transfer records are created implicitly
when transactions flow through `debitPayAppBalance` in `backend/database.ts`. The feature
is largely implemented; this plan captures architecture, known gaps, and the test strategy
required to meet the Constitution's ≥ 85 % coverage mandate.

---

## Technical Context

**Language/Version**: TypeScript 5.x — `strict: true`, `noEmit: true` enforced by `yarn types`  
**Primary Dependencies**:
- **Frontend**: React 18, MUI v5, XState v4, Formik + Yup, Apollo/graphql-tag (inline), `react-router-dom`
- **Backend**: Express 4, `express-session`, `express-validator`, `lodash/fp`, `shortid`, `uuid`
- **GraphQL layer**: `express-graphql` / `graphql` (schema at `backend/graphql/schema.graphql`)  

**Storage**: lowdb (flat JSON) — tables: `bankaccounts`, `banktransfers` (keys in `data/database.json`)  
**Testing**: Cypress E2E (API + UI), React Testing Library (component), Jest (unit)  
**Target Platform**: Node 18 LTS server + Vite-bundled SPA, local dev only  
**Project Type**: Full-stack reference application (educational)  
**Performance Goals**: First Contentful Paint < 2 s on 3 G throttle; bundle ≤ 500 KB gzip  
**Constraints**: No external banking API; all transfers are simulated; balances update immediately  
**Scale/Scope**: Single-tenant demo; seed data ships ~50 users and a handful of bank accounts per user

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| 1 | **Educational Excellence** | ✅ PASS | Route handlers, DB helpers, and the XState machine all carry inline comments explaining the "why". New code must continue this standard. |
| 2 | **Zero Production Ambition** | ✅ PASS | All persistence via lowdb; no external DB or banking API. No real funds are moved. |
| 3 | **Comprehensive Testing Discipline** | ⚠️ PARTIAL | API specs cover CRUD well. UI spec (179 lines) is below the ~6 600-line estimate in the feature spec. Deposit/withdrawal E2E paths and visual snapshots are incomplete. **Must close gap in tasks.** |
| 4 | **TypeScript-First** | ✅ PASS | `BankAccount`, `BankAccountPayload`, `BankTransfer`, `BankTransferPayload`, `BankTransferType` all explicitly typed. `@ts-ignore` present in `bankAccountsMachine.ts` — must resolve. |
| 5 | **Single Source of Truth (Testing Patterns)** | ✅ PASS | Tests use `cy.getBySel()`, `cy.loginByXstate()`, `cy.database()`, and `cy.task("db:seed")`. No raw DOM selectors. |
| 6 | **Database Seeding** | ✅ PASS | `cy.task("db:seed")` called in every `beforeEach`. `data/database-seed.json` contains representative bank accounts and transfers. |
| 7 | **Multi-Auth Provider Parity** | N/A | Bank account functionality is user-scoped, not auth-provider-specific; no special handling needed per provider. |
| 8 | **CI/CD as Mandatory Quality Gate** | ✅ PASS | `yarn types`, `yarn lint`, unit, component, and E2E jobs are all required to pass. |
| 9 | **Performance & Observability** | ⚠️ WATCH | No new heavy dependencies introduced. API endpoints use existing Express logging middleware. Bundle size should be monitored post-build (graphql-tag tree-shakes well). |
| 10 | **Documentation-as-Code** | ⚠️ PARTIAL | GraphQL schema is the primary API contract and exists. REST endpoints lack TSDoc comments. README does not yet mention bank account linking. **Must add in tasks.** |

**Gate result**: No hard violations. Two partial flags (P3, P10) must be addressed in the implementation tasks before the feature is considered complete.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-bank-accounts-transfers/
├── plan.md           ← this file
├── research.md       ← Phase 0 output
├── data-model.md     ← Phase 1 output
├── quickstart.md     ← Phase 1 output
├── contracts/        ← Phase 1 output (REST + GraphQL contracts)
│   ├── rest-bank-accounts.md
│   └── graphql-bank-accounts.md
└── tasks.md          ← Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
# Backend — Express + lowdb

backend/
├── bankaccount-routes.ts        ✅ EXISTS  GET list, GET /:id, POST, DELETE (soft)
├── banktransfer-routes.ts       ✅ EXISTS  GET list (read-only; creation is implicit)
├── transaction-routes.ts        ✅ EXISTS  POST /transactions triggers bank transfer logic
├── database.ts                  ✅ EXISTS  All DB helpers; createBankTransferWithdrawal
├── validators.ts                ✅ EXISTS  isBankAccountValidator, shortIdValidation
├── helpers.ts                   ✅ EXISTS  ensureAuthenticated, validateMiddleware
└── graphql/
    ├── schema.graphql           ✅ EXISTS  BankAccount type, listBankAccount, mutations
    └── resolvers.ts             ✅ EXISTS  GraphQL resolvers wired to DB helpers

# Shared models

src/models/
├── bankaccount.ts               ✅ EXISTS  BankAccount, BankAccountPayload
├── banktransfer.ts              ✅ EXISTS  BankTransfer, BankTransferPayload, BankTransferType
└── index.ts                     ✅ EXISTS  Re-exports all models

# Frontend — React + XState

src/
├── machines/
│   ├── bankAccountsMachine.ts   ✅ EXISTS  XState dataMachine extension; GraphQL ops
│   └── dataMachine.ts           ✅ EXISTS  Base machine (idle→loading→creating→deleting→success|failure)
├── components/
│   ├── BankAccountForm.tsx      ✅ EXISTS  Formik + Yup create form (bankName, routing, account)
│   ├── BankAccountItem.tsx      ✅ EXISTS  List item; shows "(Deleted)" badge; delete button
│   └── BankAccountList.tsx      ✅ EXISTS  Renders list or EmptyList fallback
├── containers/
│   ├── BankAccountsContainer.tsx ✅ EXISTS Route /bankaccounts; wires machine ↔ components
│   └── UserOnboardingContainer.tsx ✅ EXISTS Reuses BankAccountForm for onboarding flow
└── utils/
    └── transactionUtils.ts      ✅ EXISTS  hasSufficientFunds, getTransferAmount, getChargeAmount

# Cypress tests

cypress/tests/
├── api/
│   ├── api-bankaccounts.spec.ts  ✅ EXISTS  CRUD via REST
│   └── api-banktransfers.spec.ts ✅ EXISTS  GET list
└── ui/
    └── bankaccounts.spec.ts      ⚠️ PARTIAL  Create + form validation covered; deposit/withdrawal
                                              E2E flows, delete confirmation, and visual snapshots
                                              need expansion
```

**Structure Decision**: Single full-stack project (Option 1 variant with separate `backend/` and
`src/` trees). No new directories are required; all new code slots into existing locations.

---

## Research Findings

### Finding 1 — GraphQL vs REST Duality

**Decision**: The React frontend communicates exclusively via GraphQL for bank account
operations. REST routes exist in parallel for API-level testing and for server-side
transaction processing that creates bank transfer records.

**Rationale**: The `bankAccountsMachine` issues `httpClient.post` to `/graphql` with inline
`gql` queries. This decouples the UI from the REST route implementation and provides a clean
demonstration of testing GraphQL operations with `cy.intercept` aliases
(`gqlListBankAccountQuery`, `gqlCreateBankAccountMutation`, `gqlDeleteBankAccountMutation`).

**Alternatives considered**: Pure REST on the frontend was rejected because the project's
stated goal includes demonstrating GraphQL testing patterns (see spec §GraphQL API Support).

---

### Finding 2 — Bank Transfer Creation Is Implicit

**Decision**: There is no `POST /bankTransfers` endpoint. Bank transfer records are produced
as a side-effect inside `database.ts → debitPayAppBalance → createBankTransferWithdrawal`
when a payment transaction causes a user's balance to drop below zero.

**Rationale**: This mirrors real-world overdraft-style top-up semantics and keeps the
transaction surface area minimal. It also means the `/bankTransfers` route is permanently
read-only—consumers retrieve history but never post directly.

**Gap identified**: `createBankTransferWithdrawal` exists but there is no corresponding
`createBankTransferDeposit`. The spec describes an explicit deposit flow (bank → wallet).
This must be implemented: a curried `createBankTransferDeposit` helper in `database.ts`
and a deposit-aware branch in `debitPayAppBalance` or a new `processBankDeposit` helper.

**Alternatives considered**: Expose `POST /bankTransfers` directly. Rejected because it
would bypass the transaction audit trail and break the single-record-per-transfer invariant.

---

### Finding 3 — `transactionType: "transfer"` Is Not Validated

**Decision**: The spec's example POST body for bank-to-wallet transfers includes
`"transactionType": "transfer"`, but `isTransactionPayloadValidator` in `validators.ts`
only permits `"payment"` or `"request"`. A transfer transaction must either (a) be routed
through a dedicated path that bypasses the shared validator, or (b) extend the validator's
`isIn` list to include `"transfer"`.

**Rationale**: Option (b) is simpler and keeps the single `POST /transactions` entry point.
The `createTransaction` function in `database.ts` already has an `isPayment` branch; adding
an `isBankTransfer` branch alongside it is a clean extension.

**Recommended approach**: Add `"transfer"` to `isTransactionPayloadValidator`. Add
`isBankTransfer` guard in `createTransaction`. Call `processBankDeposit` or
`processBankWithdrawal` as appropriate.

---

### Finding 4 — Authorization Gap on `GET /bankAccounts/:id`

**Decision**: The `GET /:bankAccountId` handler returns any account by ID as long as the
requester is authenticated. It does not verify that `account.userId === req.user.id`.

**Rationale**: The spec states "User can only retrieve own accounts." This is an ownership
check that is trivially added: compare `account.userId` to `req.user?.id` and return 401
if they differ.

**Impact**: Moderate security gap in a demo app. Should be fixed to model correct ownership
semantics (aligns with Principle 1 — teach correct patterns).

---

### Finding 5 — `@ts-ignore` in `bankAccountsMachine.ts`

**Decision**: Line in `fetchData` service casts response via `@ts-ignore`. The GraphQL
response shape is known at compile time; a typed `interface GraphQLBankAccountsResponse`
can replace the suppression.

**Rationale**: Principle 4 forbids `any` and by extension `@ts-ignore` unless unavoidable.
The response shape from `/graphql` is static and fully typed in `schema.graphql`.

---

### Finding 6 — Frontend Validation Is Stricter Than Backend

**Decision**: Yup schema on `BankAccountForm` enforces `bankName` ≥ 5 chars, `routingNumber`
exactly 9 digits, `accountNumber` 9–12 digits. The backend `isBankAccountValidator` only
checks `isString().trim()` — no length or format constraints.

**Rationale**: Backend must be the authoritative guard. Add `isLength`, `isNumeric`, and
`matches` constraints to the backend validator to prevent invalid data being inserted via
direct API calls (REST or GraphQL mutation).

---

### Finding 7 — Soft Delete Display Pattern

**Decision**: `BankAccountItem` renders the literal string `"(Deleted)"` next to the bank
name when `isDeleted === true` and hides the delete button. The `getBankAccountsByUserId`
helper in `database.ts` returns ALL accounts including soft-deleted ones; the UI filters
the display only, not the data.

**Rationale**: Maintains referential integrity (existing bank transfers still reference the
account ID). Matches spec §Soft Deletion and the `isDeleted` boolean on the model.

**Gap**: The spec implies deleted accounts should still appear in transfer history. Verify
that `GET /bankAccounts` (scoped list) still returns `isDeleted: true` accounts; the current
implementation does return them, which is correct.

---

### Finding 8 — `data-test` Attribute Coverage

Existing `data-test` selectors identified in components:

| Selector | Location | Used in Tests |
|----------|----------|--------------|
| `bankaccount-list` | `BankAccountList` | ✅ |
| `bankaccount-list-item-{id}` | `BankAccountItem` | ✅ |
| `bankaccount-delete` | `BankAccountItem` | ⚠️ not in UI spec |
| `bankaccount-form` | `BankAccountForm` | ✅ |
| `bankaccount-bankName-input` | `BankAccountForm` | ✅ |
| `bankaccount-routingNumber-input` | `BankAccountForm` | ✅ |
| `bankaccount-accountNumber-input` | `BankAccountForm` | ✅ |
| `bankaccount-submit` | `BankAccountForm` | ✅ |
| `sidenav-bankaccounts` | Sidenav | ✅ |
| `bankaccount-new` | BankAccounts page | ✅ |

Missing selectors for deposit/withdrawal UI (not yet built or tested):
- `bankaccount-deposit-select`, `bankaccount-deposit-amount`, `bankaccount-deposit-submit`
- `bankaccount-withdrawal-select`, `bankaccount-withdrawal-amount`, `bankaccount-withdrawal-submit`

---

## Data Model

### `BankAccount` (table: `bankaccounts`)

```typescript
interface BankAccount {
  id: string;           // shortid() — 7-char alphanumeric, primary key
  uuid: string;         // uuid v4 — globally unique identifier
  userId: string;       // FK → users.id; enforces ownership
  bankName: string;     // Display name, min 5 chars
  accountNumber: string; // 9–12 digit string (stored plain in demo)
  routingNumber: string; // Exactly 9 digits
  isDeleted: boolean;   // Soft-delete flag; never physically removed
  createdAt: Date;
  modifiedAt: Date;
}

// Write payload (omits system-generated fields)
type BankAccountPayload = Pick<BankAccount, "userId" | "bankName" | "accountNumber" | "routingNumber">;
```

**Invariants**:
- `accountNumber` and `routingNumber` are immutable post-creation (delete + recreate pattern)
- Multiple accounts per user allowed; no uniqueness constraint on (userId, bankName)
- `isDeleted` defaults to `false`; set to `true` by `removeBankAccountById`

### `BankTransfer` (table: `banktransfers`)

```typescript
enum BankTransferType {
  withdrawal = "withdrawal",  // User wallet → bank account
  deposit    = "deposit",     // Bank account → user wallet
}

interface BankTransfer {
  id: string;            // shortid()
  uuid: string;          // uuid v4
  userId: string;        // Transfer initiator (FK → users.id)
  source: string;        // FK → bankaccounts.id
  amount: number;        // Cents (integer); always positive
  type: BankTransferType;
  transactionId: string; // FK → transactions.id (audit trail)
  createdAt: Date;
  modifiedAt: Date;
}

type BankTransferPayload = Omit<BankTransfer, "id" | "uuid" | "createdAt" | "modifiedAt">;
```

**Invariants**:
- Every `BankTransfer` record has exactly one parent `Transaction`
- `amount` is stored in cents; matches parent transaction `amount` field
- `type` is inferred from the transaction context:
  - `withdrawal` — user's balance was insufficient; system topped up from bank
  - `deposit` — explicit user action moving bank funds into wallet (gap to implement)

### Entity Relationships

```
User ──< BankAccount          (1 user : N accounts)
BankAccount ──< BankTransfer  (1 account : N transfers)
Transaction ──< BankTransfer  (1 transaction : 1 transfer, effectively)
User balance ←── updated by BankTransfer (deposit +, withdrawal -)
```

---

## API Contracts

### REST Endpoints (primary for server-side and API tests)

#### `GET /bankAccounts`
- **Auth**: `ensureAuthenticated` (session cookie)
- **Scope**: Returns only accounts where `userId === req.user.id`
- **Response**: `{ results: BankAccount[] }` — includes `isDeleted: true` entries
- **Status**: 200

#### `GET /bankAccounts/:bankAccountId`
- **Auth**: `ensureAuthenticated`
- **Param validation**: `shortIdValidation("bankAccountId")`
- **Authorization gap** (see Finding 4): must add `account.userId === req.user.id` check
- **Response**: `{ account: BankAccount }`
- **Status**: 200 / 401 (unauthorized ownership)

#### `POST /bankAccounts`
- **Auth**: `ensureAuthenticated`
- **Body validation**: `isBankAccountValidator` (must be strengthened — see Finding 6)
- **Body**: `{ bankName: string, accountNumber: string, routingNumber: string }`
- **Response**: `{ account: BankAccount }`
- **Status**: 200 / 422 (validation failure)

#### `DELETE /bankAccounts/:bankAccountId`
- **Auth**: `ensureAuthenticated`
- **Param validation**: `shortIdValidation("bankAccountId")`
- **Behavior**: Soft delete — sets `isDeleted = true`, updates `modifiedAt`
- **Response**: `{ account: BankAccount }` (with `isDeleted: true`)
- **Status**: 200

#### `GET /bankTransfers`
- **Auth**: `ensureAuthenticated`
- **Scope**: Returns transfers where `userId === req.user.id`
- **Response**: `{ transfers: BankTransfer[] }`
- **Status**: 200

### GraphQL API (primary for frontend)

```graphql
type Query {
  listBankAccount: [BankAccount!]
}

type Mutation {
  createBankAccount(
    bankName: String!
    accountNumber: String!
    routingNumber: String!
  ): BankAccount

  deleteBankAccount(id: ID!): Boolean
}

type BankAccount {
  id: ID!
  uuid: String
  userId: String
  bankName: String
  accountNumber: String
  routingNumber: String
  isDeleted: Boolean
  createdAt: String
  modifiedAt: String
}
```

**Operation names** (used for `cy.intercept` aliasing in tests):
- `ListBankAccount` → alias `gqlListBankAccountQuery`
- `CreateBankAccount` → alias `gqlCreateBankAccountMutation`
- `DeleteBankAccount` → alias `gqlDeleteBankAccountMutation`

---

## Design Decisions

### Decision 1 — `dataMachine` Composition Pattern

`bankAccountsMachine` is created by calling `dataMachine("bankAccounts").withConfig(...)`.
The generic `dataMachine` provides the state graph
(`idle → loading → creating → deleting → success | failure`) and all `bankAccountsMachine`
contributes is the three service implementations (`fetchData`, `createData`, `deleteData`)
pointing at GraphQL.

**Why this matters for implementation**: Any new bank transfer machine
(e.g., `bankTransfersMachine`) should follow the same composition pattern rather than
defining a fresh XState machine from scratch. This keeps the state topology uniform and
testable via the same `cy.intercept`-based approach.

---

### Decision 2 — Deposit / Withdrawal UI Placement

The spec describes deposit and withdrawal as separate flows accessed from within a
transaction create dialog (selecting a bank account as the `source` with `senderId ===
receiverId`). The existing `createTransactionMachine` handles the transaction lifecycle;
bank-specific UI controls (account selector, deposit vs. withdrawal toggle) must be added
to the transaction form, not to the bank accounts management page.

**Implementation guideline**: Add a `"transfer"` branch to `createTransaction` in
`database.ts`. Introduce `createBankTransferDeposit` (symmetric to
`createBankTransferWithdrawal`). Update `isTransactionPayloadValidator` to allow
`transactionType: "transfer"`.

---

### Decision 3 — Validation Strategy (Dual-Layer)

- **Frontend (Yup)**: UX guard; fails fast before network call.
  - `bankName`: `string().min(5).required()`
  - `routingNumber`: `string().length(9).required()`
  - `accountNumber`: `string().min(9).max(12).required()`
- **Backend (express-validator)**: Authoritative guard; protects against direct API calls.
  - Must be strengthened to match Yup constraints (numeric-only, correct lengths).

Both layers must be consistent; divergence produces confusing errors for API consumers and
is a teaching anti-pattern.

---

### Decision 4 — Soft Delete Semantics

Physical deletion is prohibited to maintain referential integrity. Bank transfer records
reference `source: bankAccountId`; removing the account record would orphan those transfers.
The soft-delete pattern (`isDeleted: true`) is the only safe option in a schema-less lowdb
environment without cascade support.

**UI implication**: Deleted accounts render with `(Deleted)` suffix and no delete button.
They are still returned by `GET /bankAccounts` so they appear in a user's account history.
Deleted accounts must **not** be selectable in the transaction creation form.

---

### Decision 5 — ID Generation

Bank accounts use `shortid()` (7-char alphanumeric) for the `id` field, consistent with
every other entity in the system (`users`, `transactions`, `contacts`). The `uuid` field
(uuid v4) provides a globally unique secondary identifier. Both fields are generated in
`createBankAccountForUser` in `database.ts`; no consumer should generate IDs externally.

---

## Test Strategy

### Existing Coverage (what to keep)

| File | Lines | Covers |
|------|-------|--------|
| `cypress/tests/api/api-bankaccounts.spec.ts` | ~90 | GET list, GET /:id, POST create, DELETE soft |
| `cypress/tests/api/api-banktransfers.spec.ts` | ~50 | GET list |
| `cypress/tests/ui/bankaccounts.spec.ts` | 179 | Create account, form validation errors |

### Required New Coverage

#### Unit Tests (Jest, `src/utils/` and `backend/`)
- `createBankTransferDeposit` — correct payload shape, correct `type: "deposit"`
- `createBankTransferWithdrawal` — existing path; add coverage for edge amount = balance
- `hasSufficientFunds` — boundary: amount equals balance (should pass)
- `isBankAccountValidator` — routing number length, account number min/max, non-numeric rejection

#### Component Tests (React Testing Library, `src/components/`)
- `BankAccountForm` renders all fields, shows correct Yup error messages
- `BankAccountItem` shows `(Deleted)` badge when `isDeleted: true`; hides delete button
- `BankAccountItem` calls `deleteBankAccount` prop on delete button click
- `BankAccountList` renders `EmptyList` when accounts array is empty

#### E2E Tests — UI (Cypress, `cypress/tests/ui/bankaccounts.spec.ts`)
- ✅ Creates a new bank account (exists)
- ✅ Displays bank account form errors (exists)
- ⬜ Deletes a bank account → shows `(Deleted)` label in list (need `cy.wait("@gqlDeleteBankAccountMutation")`)
- ⬜ Empty state: navigating to `/bankaccounts` with no accounts shows empty list message
- ⬜ Mobile viewport: sidenav toggle reveals bank accounts link
- ⬜ Visual snapshot: bank accounts list with 2+ items (`cy.visualSnapshot`)
- ⬜ Visual snapshot: empty bank accounts list
- ⬜ Deposit flow: select bank account, enter amount, submit transaction, verify balance increase
- ⬜ Withdrawal flow: select bank account, enter amount, submit transaction, verify balance decrease
- ⬜ Withdrawal rejected: amount exceeds balance — verify error message

#### E2E Tests — API (Cypress, `cypress/tests/api/`)
- ✅ GET /bankAccounts list (exists)
- ✅ GET /bankAccounts/:id (exists)
- ✅ POST /bankAccounts create (exists)
- ✅ DELETE /bankAccounts/:id soft delete (exists)
- ⬜ GET /bankAccounts/:id with another user's account ID → expect 401
- ⬜ POST /bankAccounts with routing number ≠ 9 digits → expect 422
- ⬜ POST /bankAccounts with account number < 9 or > 12 digits → expect 422
- ⬜ GET /bankTransfers — verify transfer type field is `"deposit"` or `"withdrawal"`

### Custom Command Requirements

All new interactions must use existing custom commands:
- `cy.getBySel("bankaccount-delete")` for delete button
- `cy.getBySel("bankaccount-deposit-select")` etc. for new deposit/withdrawal selectors
- `cy.loginByXstate(username)` for session setup
- `cy.database("filter", "bankaccounts")` for seed-data lookups
- `cy.visualSnapshot("Bank Account <state>")` for all new UI states

---

## Complexity Tracking

No Constitution violations were introduced by this feature. The table below documents
justified deviations from the simplest possible design:

| Choice | Why Needed | Simpler Alternative Rejected Because |
|--------|------------|--------------------------------------|
| GraphQL + REST in parallel | Demonstrate both testing patterns; REST used by transaction system internally | REST-only removes GraphQL test scenarios the spec explicitly requires |
| XState dataMachine composition | Uniform state topology across all data-fetching machines | Per-feature ad-hoc machines diverge over time and are harder to test consistently |
| Soft delete (not hard delete) | BankTransfer records reference BankAccount IDs | Hard delete orphans transfer records; lowdb has no cascade support |
| Dual-layer validation (Yup + express-validator) | Frontend UX + backend authority | Single-layer backend validation degrades UX; single-layer frontend is bypassable |

---

## Open Items / Gaps to Address in Tasks

| ID | Gap | Priority |
|----|-----|----------|
| G1 | `createBankTransferDeposit` function missing in `database.ts` | High |
| G2 | `transactionType: "transfer"` not in `isTransactionPayloadValidator` | High |
| G3 | `GET /bankAccounts/:id` lacks ownership authorization check | High |
| G4 | `isBankAccountValidator` lacks length/numeric format constraints | Medium |
| G5 | `@ts-ignore` in `bankAccountsMachine.ts` needs typed interface | Medium |
| G6 | UI E2E tests for delete, empty state, deposit/withdrawal, visual snapshots | High |
| G7 | API E2E tests for authorization (cross-user) and validation errors | Medium |
| G8 | REST endpoint TSDoc comments + README update | Low |

---

*End of Plan — Phase 0 research complete. Phase 1 design artifacts (data-model.md, contracts/, quickstart.md) to follow via `/speckit.tasks`.*

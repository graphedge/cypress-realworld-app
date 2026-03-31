# Implementation Plan: Transaction Management

**Branch**: `speckit/comprehensive-documentation` | **Date**: 2026-03-31 | **Spec**: `specs/002-transaction-management/spec.md`  
**Input**: Feature specification from `/specs/002-transaction-management/spec.md`

---

## Summary

Transaction Management is the core financial engine of the Cypress RWA. It supports three
transaction types — direct peer-to-peer payments, payment requests (accept/reject lifecycle), and
bank account transfers (deposit/withdrawal) — with rich query support (pagination, date-range,
amount-range, status, privacy filtering). The implementation spans the full stack: an Express REST
API backed by lowdb (JSON), XState machines coordinating UI state, and a rich set of React
components for transaction feeds and the multi-step creation wizard.

---

## Technical Context

**Language/Version**: TypeScript 5.x (strict mode, `noEmit: true`)  
**Primary Dependencies**:
- **Backend**: Express 4, express-validator, lodash/fp, shortid, uuid, dinero.js v2, date-fns, date-fns-tz  
- **Frontend**: React 18, Material UI v5, XState v4 (`@xstate/react`), axios (httpClient), React Router v5  
- **Database**: lowdb v1 (flat JSON file at `data/database.json`; seeded from `data/database-seed.json`)  
- **Testing**: Cypress 13 (E2E, Component, API), Jest + ts-jest (unit)  

**Storage**: Local JSON file via lowdb — no external database; `cy.task("db:seed")` resets state  
**Testing**: Cypress E2E (`cypress/tests/ui/`), Cypress API (`cypress/tests/api/`), Cypress component (`src/components/*.cy.tsx`), Jest unit (`src/**/*.test.ts`)  
**Target Platform**: Node.js 18+ server + Vite-built browser SPA (localhost development)  
**Project Type**: Full-stack educational reference application  
**Performance Goals**: API responses < 200 ms on local dev; FCP < 2 s on 3G (Lighthouse gate)  
**Constraints**:
- Amount stored and manipulated as integer cents (e.g., 10000 = $100.00) via dinero.js
- No external DB, message queues, or caches — lowdb only
- All code must pass `yarn types` (zero TS errors) and `yarn lint`
- `any` types forbidden; use `unknown` + type guards if runtime type is uncertain

**Scale/Scope**: ~50 seed users, ~100+ seed transactions, ~10 K SLOC total

---

## Constitution Check

*GATE: Must pass all principles before Phase 0 research. Re-checked after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| 1 | **Educational Excellence** — clarity over optimization, explain the "why" | ✅ PASS | Inline comments required on XState machine transitions and balance math |
| 2 | **Zero Production Ambition** — no external DB or infra | ✅ PASS | All state in lowdb JSON; no Redis, Postgres, or external queues |
| 3 | **Comprehensive Testing** — E2E + component + unit on every feature | ✅ PASS | All six endpoint variations and UI flows must be covered; see Test Plan below |
| 4 | **TypeScript-First, Strict Type Safety** — `strict: true`, no `any` | ✅ PASS | `Transaction`, `TransactionResponseItem`, typed XState contexts required |
| 5 | **Single Source of Truth for Testing Patterns** — `cy.getBySel()`, `cy.database()` | ✅ PASS | All selectors use `data-test` attributes; `cy.database()` for setup |
| 6 | **Database Seeding as Test Infrastructure** — `cy.task("db:seed")` in every `beforeEach` | ✅ PASS | Existing API and UI specs already follow this pattern |
| 7 | **Multi-Auth Provider Parity** — transactions feature is auth-agnostic | ✅ PASS | `ensureAuthenticated` middleware; all flows work with any provider |
| 8 | **CI/CD as Mandatory Quality Gate** — all gates pass before merge | ✅ PASS | `yarn types && yarn lint && yarn test:unit:ci && yarn test:component:ci` |
| 9 | **Performance & Observability** — bundle size, FCP, coverage | ✅ PASS | No new heavyweight deps; dinero.js already bundled; coverage via Codecov |
| 10 | **Documentation-as-Code** — markdown docs for every feature | ✅ PASS | This plan + `quickstart.md` + `data-model.md` + `contracts/` required |

**Gate Result**: ✅ No violations. Proceed to Phase 0.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-transaction-management/
├── spec.md              # Feature specification (source of truth)
├── plan.md              # This file
├── research.md          # Phase 0: codebase findings and design decisions
├── data-model.md        # Phase 1: entity definitions and relationships
├── quickstart.md        # Phase 1: developer onboarding for this feature
├── contracts/
│   ├── POST-transactions.md
│   ├── GET-transactions.md
│   ├── GET-transactions-contacts.md
│   ├── GET-transactions-public.md
│   ├── GET-transactions-id.md
│   └── PATCH-transactions-id.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend (Express + lowdb)
backend/
├── app.ts                          # Express app; mounts /transactions router
├── transaction-routes.ts           # All 6 transaction route handlers
├── database.ts                     # lowdb queries: createTransaction, getTransactionsForUser*, etc.
├── validators.ts                   # express-validator rule sets (isTransactionPayloadValidator, etc.)
├── helpers.ts                      # ensureAuthenticated, validateMiddleware, paginate middleware
├── types.ts                        # Express augmentations (req.user typing)
└── banktransfer-routes.ts          # Bank transfer sub-feature (deposit/withdrawal side-effects)

# Frontend — State machines (XState v4)
src/machines/
├── dataMachine.ts                  # Base data machine: idle → loading → success/failure
├── createTransactionMachine.ts     # 3-step wizard: stepOne → stepTwo → stepThree
├── publicTransactionsMachine.ts    # Feeds /transactions/public
├── personalTransactionsMachine.ts  # Feeds /transactions (scoped to current user)
├── transactionFiltersMachine.ts    # Parallel states: dateRange + amountRange filter toggles
└── transactionDetailMachine.ts     # Fetch, like, comment, accept/reject a single transaction

# Frontend — React Components
src/components/
├── TransactionCreateStepOne.tsx    # User search / receiver selection
├── TransactionCreateStepTwo.tsx    # Amount, description, type (payment|request), privacy
├── TransactionCreateStepThree.tsx  # Confirmation / success screen
├── TransactionList.tsx             # Generic paginated transaction list
├── TransactionInfiniteList.tsx     # Infinite-scroll variant (public feed)
├── TransactionPersonalList.tsx     # /personal tab; drives personalTransactionsMachine
├── TransactionPublicList.tsx       # /public tab; drives publicTransactionsMachine
├── TransactionContactsList.tsx     # /contacts tab; drives contactsTransactionsMachine
├── TransactionItem.tsx             # Single row: avatar, names, amount, description
├── TransactionDetail.tsx           # Full transaction view with likes/comments/actions
├── TransactionAmount.tsx           # Colour-coded amount display (red = debit, green = request)
├── TransactionTitle.tsx            # "Charged"/"Requested"/"Paid" label
├── TransactionNavTabs.tsx          # Tab bar: Everyone / Friends / Mine
├── TransactionListFilters.tsx      # Filter panel container (date + amount range)
├── TransactionDateRangeFilter.tsx  # Date-range calendar picker (react-date-range)
├── TransactionDateRangeFilter.cy.tsx  # Component test for date filter
├── TransactionListAmountRangeFilter.tsx  # Dual-handle slider (MUI Slider)
├── TransactionTitle.cy.tsx         # Component test for title label
└── EmptyList.tsx                   # Zero-state display

# Frontend — Containers (wire machines to components)
src/containers/
├── TransactionsContainer.tsx       # Route-level: /public, /contacts, /personal
└── TransactionDetailContainer.tsx  # Route-level: /transaction/:transactionId

# Frontend — Models (TypeScript interfaces/enums)
src/models/
├── transaction.ts                  # Transaction, TransactionResponseItem, TransactionStatus,
│                                   # TransactionRequestStatus, all payload/query types
└── index.ts                        # Re-exports all model modules

# Frontend — Utilities
src/utils/
├── transactionUtils.ts             # getPaginatedItems, formatAmount, hasSufficientFunds,
│                                   # isRequestTransaction, date/amount range helpers, dinero ops
└── asyncUtils.ts                   # httpClient (axios instance)

# Tests
cypress/tests/api/
└── api-transactions.spec.ts        # API contract tests for all 6 endpoints

cypress/tests/ui/
├── new-transaction.spec.ts         # Full create-transaction UI flows (payment, request, transfer)
├── transaction-feeds.spec.ts       # Public / contacts / personal feed filtering + pagination
└── transaction-view.spec.ts        # Transaction detail: like, comment, accept/reject

src/components/
├── TransactionTitle.cy.tsx         # Component test: title label logic
└── TransactionDateRangeFilter.cy.tsx # Component test: date filter interaction
```

**Structure Decision**: Web application (frontend + backend) monorepo. Backend lives in `backend/`,
frontend in `src/`. No separate packages; both compile from the repo root via `vite` (frontend) and
`ts-node` (backend). This is the established pattern across the entire RWA codebase.

---

## Research Findings

### R1 — Amount Representation

**Decision**: All monetary amounts stored and computed as **integer cents** in the database (e.g.,
`10000` = $100.00). The API accepts amounts as cents from the frontend but multiplies by 100 in
`createTransaction` (backend/database.ts) — matching the spec's `amount * 100` line — making the
wire format effectively "dollars as string" and the storage format "cents as integer."

**Rationale**: Avoids floating-point rounding errors. dinero.js v2 enforces this:
`dinero({ amount: n, currency: USD })` requires integer cents. `formatAmount()` in
`transactionUtils.ts` converts back to locale-formatted USD string via `toDecimal()`.

**Implication for validators**: `body("amount").isNumeric().toInt()` converts the incoming string
to an integer before the route handler sees it (see `validators.ts`).

---

### R2 — XState Architecture Pattern

**Decision**: All async data flows use a **two-layer XState pattern**:
1. `dataMachine` (generic base) — states: `idle → loading → success{withData|withoutData} / failure`
2. Feature machines (e.g., `publicTransactionsMachine`) call `.withConfig({ services: { fetchData } })`
   to inject the HTTP call while reusing all state transitions and context actions.

**Rationale**: Avoids duplicating loading/error/pagination state management across every feed.
The `dataMachine.setResults` action implements **append-on-paginate** behaviour: when
`pageData.page > 1` it concats new results to existing `ctx.results` (infinite scroll pattern used
by `TransactionInfiniteList`).

**`createTransactionMachine` is different**: It uses **invoked child machines** — `stepTwo` spawns
`transactionDataMachine` (a dataMachine instance configured with a `createData` service) and uses
`autoForward: true` to pass `CREATE` events down to the child. After the child completes, the
parent transitions to `stepThree`. This models the wizard's multi-step lifecycle explicitly in state
rather than via component state.

---

### R3 — Privacy Visibility Logic

**Decision**: Privacy filtering is **query-time**, not storage-time. Records are stored with their
`privacyLevel`; the database layer (`getPublicTransactionsByQuery`, `nonContactPublicTransactions`)
filters at read time.

**Public feed first-page splice**: On `page === 1`, the `/transactions/public` route prepends up to
5 contact transactions before paginating. This is implemented in `transaction-routes.ts` via
`slice(0, 5, contactsTransactions)` + `concat(..., publicTransactions)`. Pages 2+ return only
public transactions.

**Contact visibility**: `getTransactionsForUserContacts` calls `getContactIdsForUser` (which
queries the `contacts` table), then maps each contact ID through `getTransactionsForUserForApi`,
then `uniqBy("id")` deduplicates. This is O(n×m) on users × contacts — acceptable for the demo
scale (~50 users, ~20 contacts each).

---

### R4 — Balance Update Logic

**Decision**: Balance updates are **synchronous and immediate** for payments and bank transfers;
deferred until `requestStatus = "accepted"` for payment requests.

**Key path for payments** (`createTransaction` in `database.ts`):
1. Build transaction record, set `status: pending`
2. `isPayment(transaction)` → `debitPayAppBalance(sender, transaction)`
   - If sufficient funds: `getChargeAmount` → `savePayAppBalance`
   - If insufficient: creates an automatic bank-transfer withdrawal for the shortfall, then zeros balance
3. Credit receiver: `creditPayAppBalance(receiver, transaction)`
4. Set `status: complete`, `balanceAtCompletion: sender.balance`

**Key path for requests** (`updateTransactionById` → `updateTransactionByIdExecutor`):
- On `requestStatus = "accepted"`: runs the same debit/credit flow, sets `status: complete`
- On `requestStatus = "rejected"`: sets `status: incomplete`, `requestResolvedAt: now()`

---

### R5 — Pagination Implementation

**Decision**: Page-based (1-indexed), not cursor-based. `getPaginatedItems(page, limit, items)`
in `transactionUtils.ts` computes offset = `(page - 1) * limit`, slices the full array, returns
`{ totalPages, data }`. The route handler uses the `paginate` middleware (via `res.locals.paginate`)
for `hasNextPages` calculation.

**Implication**: Pagination happens **in-memory** after all filtering — the full filtered list is
loaded from lowdb, then sliced. This is fine for the demo scale but would not scale to production.

---

### R6 — Validation Layer

**Decision**: express-validator rule arrays are defined in `validators.ts` and applied via the
`validateMiddleware` helper, which calls `validationResult(req)` and returns 422 on failure.

Relevant rule sets:
| Validator | Applied to |
|-----------|-----------|
| `isTransactionPayloadValidator` | `POST /transactions` |
| `isTransactionQSValidator` | `GET /transactions`, `GET /transactions/contacts` |
| `isTransactionPublicQSValidator` | `GET /transactions/public` |
| `isTransactionPatchValidator` | `PATCH /transactions/:id` |
| `shortIdValidation("transactionId")` | `GET /transactions/:id`, `PATCH /transactions/:id` |

---

### R7 — Test Patterns in Use

**Decision**: Existing tests establish the canonical patterns all new tests must follow:

```typescript
// beforeEach in every describe block
cy.task("db:seed");
cy.database("filter", "users").then((users: User[]) => { ... });
cy.loginByApi(authenticatedUser.username);

// Selectors — always data-test attributes
cy.getBySel("transaction-item")
cy.getBySel(`transaction-amount-${transaction.id}`)

// API tests — raw cy.request (no UI)
cy.request("GET", `${apiTransactions}`).then((response) => {
  expect(response.status).to.eq(200);
  expect(response.body.results[0]).to.satisfy(isSenderOrReceiver);
});
```

---

## Design Decisions

### DD1 — No Repository Pattern

The backend does not use a Repository abstraction layer. Functions in `database.ts` query lowdb
directly. Adding a repository interface would be appropriate for a production app but would obscure
the teaching value of seeing direct data access patterns.

**Tradeoff accepted**: `database.ts` is a large file (~600+ LOC) mixing query, transform, and
side-effect concerns. This is intentional — it demonstrates all the patterns in one readable place.

---

### DD2 — XState over Redux/Zustand

XState state machines make async lifecycles (loading states, multi-step wizards, parallel filter
states) explicit and visualisable. This is a better teaching tool than imperative `useState`/
`useEffect` patterns or a black-box Redux slice.

**Teaching hook**: XState Viz can render `createTransactionMachine` as a live diagram. All machine
files include the schema interface (`CreateTransactionMachineSchema`) to make states self-documenting.

---

### DD3 — dinero.js for Currency Arithmetic

dinero.js prevents floating-point errors in all balance math. The codebase uses dinero v2's
functional API (`add`, `subtract`, `isPositive`, `toSnapshot`, `toDecimal`). All intermediate
calculations stay as Dinero objects; only `toSnapshot().amount` (integer cents) is persisted.

---

### DD4 — `data-test` Attribute Convention

All interactive and testable elements carry a `data-test` attribute (e.g.,
`data-test="transaction-amount-${transaction.id}"`). This decouples test selectors from CSS
classes or element types and is enforced by the `cy.getBySel()` custom command. New components
**must** add `data-test` to any element that a test will interact with or assert on.

---

### DD5 — Public Feed First-Page Injection

Injecting up to 5 contact transactions into the first page of the public feed (regardless of their
`privacyLevel`) gives new users a personalised first experience. This is a deliberate product
decision visible in the route handler. The spec calls this out explicitly; the implementation uses
lodash `slice` + `concat` to keep the logic simple and readable.

---

## Phase 0 Outputs

All NEEDS CLARIFICATION items resolved from codebase research:

| Item | Resolution |
|------|-----------|
| Amount wire format | Frontend sends amount as numeric string (cents), validator runs `.toInt()` |
| Bank transfer type | `source` field contains `bankAccountId`; `transactionType` is still `"payment"` in the create validator; transfer classification inferred by non-empty `source` |
| Pagination middleware | `res.locals.paginate` injected by `express-paginate` helper in `helpers.ts` |
| Contact resolution | `getContactIdsForUser` → lowdb `contacts` table → `contactUserId` field |
| Request lifecycle | `updateTransactionById` delegates to `updateTransactionByIdExecutor` which handles balance side-effects on accept |
| Privacy at query time | No separate visibility table; filtered by `privacyLevel` field + contact lookup at read time |

---

## Phase 1 Artifacts

*(Produced as separate files in `specs/002-transaction-management/`)*

### data-model.md — Entity Overview

**Transaction**

| Field | Type | Notes |
|-------|------|-------|
| `id` | `string` | `shortid()` — 7-char alphanumeric |
| `uuid` | `string` | `uuid v4` |
| `source` | `string` | Empty for P2P; `BankAccount.id` for transfers |
| `amount` | `number` | Integer cents |
| `description` | `string` | User-provided memo |
| `privacyLevel` | `'public' \| 'private' \| 'contacts'` | Falls back to `sender.defaultPrivacyLevel` if omitted |
| `senderId` | `string` | `User.id` |
| `receiverId` | `string` | `User.id` (same as `senderId` for bank transfers) |
| `balanceAtCompletion` | `number?` | Sender's balance after transaction completes |
| `status` | `TransactionStatus` | `pending \| incomplete \| complete` |
| `requestStatus` | `TransactionRequestStatus?` | `pending \| accepted \| rejected`; undefined for payments |
| `requestResolvedAt` | `Date?` | Set when requestStatus changes from pending |
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last-update timestamp |

**TransactionResponseItem** (API response shape — enriches `Transaction`)

| Added Field | Source |
|-------------|--------|
| `senderName` | `formatFullName(getUserById(senderId))` |
| `receiverName` | `formatFullName(getUserById(receiverId))` |
| `senderAvatar` | `User.avatar` |
| `receiverAvatar` | `User.avatar` |
| `likes` | `getLikesByTransactionId(id)` |
| `comments` | `getCommentsByTransactionId(id)` |

**Relationships**:
- `Transaction` → `User` (sender, receiver) — resolved at read time
- `Transaction` ← `Like[]` — `transactionId` FK in `likes` table
- `Transaction` ← `Comment[]` — `transactionId` FK in `comments` table
- `Transaction` → `BankTransfer` (optional) — created as side-effect when sender has insufficient funds

**State Transitions**:

```
Payment:
  pending → complete (on save, synchronously)

Request:
  pending → accepted → complete (on PATCH requestStatus:accepted)
  pending → rejected → incomplete (on PATCH requestStatus:rejected)

Bank Transfer:
  pending → complete (on save, synchronously)
```

---

### contracts/ — API Contracts (summary)

Full markdown contract files live in `specs/002-transaction-management/contracts/`.

| Method | Path | Auth | Request | Success Response |
|--------|------|------|---------|-----------------|
| `GET` | `/transactions` | Session | QS: page, limit, status, requestStatus, dateRangeStart/End, amountMin/Max | 200 `{ pageData, results: TransactionResponseItem[] }` |
| `GET` | `/transactions/contacts` | Session | Same QS as above | 200 `{ pageData, results: TransactionResponseItem[] }` |
| `GET` | `/transactions/public` | Session | QS: page, limit (order=default optional) | 200 `{ pageData, results: TransactionResponseItem[] }` |
| `GET` | `/transactions/:id` | Session | Path param: `transactionId` (shortId) | 200 `{ transaction: TransactionResponseItem }` |
| `POST` | `/transactions` | Session | Body: `transactionType, senderId, receiverId, amount, description, privacyLevel[, source]` | 200 `{ transaction: Transaction }` |
| `PATCH` | `/transactions/:id` | Session | Body: `{ requestStatus: "accepted" \| "rejected" }` | 204 No Content |

**Error responses** (all endpoints):
- `401` — Not authenticated (`ensureAuthenticated` middleware)
- `422` — Validation failed (`validateMiddleware` returns errors array)

---

### quickstart.md — Developer Onboarding

*(Condensed here; full version in `specs/002-transaction-management/quickstart.md`)*

**Running the app locally**:
```bash
yarn dev          # starts Vite frontend (port 3000) + Express backend (port 3001)
yarn start        # alias — same as above
```

**Seeding the database**:
```bash
yarn db:seed      # resets data/database.json from data/database-seed.json
```

**Running transaction-specific tests**:
```bash
# API tests
yarn cypress run --spec "cypress/tests/api/api-transactions.spec.ts"

# UI tests
yarn cypress run --spec "cypress/tests/ui/new-transaction.spec.ts,cypress/tests/ui/transaction-feeds.spec.ts,cypress/tests/ui/transaction-view.spec.ts"

# Component tests
yarn cypress run --component --spec "src/components/TransactionTitle.cy.tsx,src/components/TransactionDateRangeFilter.cy.tsx"
```

**Adding a new transaction type** (checklist):
1. Add enum value to `TransactionStatus` or `TransactionRequestStatus` in `src/models/transaction.ts`
2. Update `isTransactionPayloadValidator` in `backend/validators.ts`
3. Add branch in `createTransaction` / `updateTransactionByIdExecutor` in `backend/database.ts`
4. Update XState machine schema in `src/machines/createTransactionMachine.ts` if wizard steps change
5. Add/update `data-test` attributes in affected components
6. Add Cypress API test case in `api-transactions.spec.ts`
7. Add Cypress UI test case in `new-transaction.spec.ts`

---

## Test Plan

### API Tests (`cypress/tests/api/api-transactions.spec.ts`)

| Test | Endpoint | Assertion |
|------|----------|-----------|
| Get personal transactions (default) | `GET /transactions` | 200, results scoped to current user |
| Get pending requests for user | `GET /transactions?requestStatus=pending` | 200, all results have requestStatus=pending |
| Get transactions in date range | `GET /transactions?dateRangeStart=...&dateRangeEnd=...` | 200, results within range |
| Get transactions in amount range | `GET /transactions?amountMin=...&amountMax=...` | 200, results within range |
| Get contact transactions page 1 | `GET /transactions/contacts` | 200, >1 result |
| Get contact transactions page 2 | `GET /transactions/contacts?page=2` | 200, results |
| Get public feed page 1 | `GET /transactions/public` | 200, first 5 may be contact transactions |
| Get public feed page 2 | `GET /transactions/public?page=2` | 200, no contact injection |
| Get single transaction | `GET /transactions/:id` | 200, has likes/comments arrays |
| Create payment | `POST /transactions` (payment) | 200, status=complete |
| Create request | `POST /transactions` (request) | 200, requestStatus=pending |
| Create bank transfer | `POST /transactions` (source=bankAccountId) | 200 |
| Accept request | `PATCH /transactions/:id` {requestStatus:accepted} | 204 |
| Reject request | `PATCH /transactions/:id` {requestStatus:rejected} | 204 |
| Reject unauthenticated | `GET /transactions` (no session) | 401 |

### UI Tests (`cypress/tests/ui/new-transaction.spec.ts`)

| Test | Coverage |
|------|----------|
| Payment flow — search user, enter amount, submit | `createTransactionMachine` stepOne→stepTwo→stepThree |
| Request flow — verify +/- sign and requestStatus=pending | `TransactionAmount` className, API call |
| Insufficient funds — automatic bank transfer | Balance debit, `BankTransfer` creation side-effect |
| Form validation — empty description, zero amount | 422 error display |
| Privacy level selection — public/private/contacts | `privacyLevel` in POST body |

### UI Tests (`cypress/tests/ui/transaction-feeds.spec.ts`)

| Test | Coverage |
|------|----------|
| Public feed loads with contact injection on page 1 | First-page splice logic |
| Date range filter applied | `transactionFiltersMachine` dateRange state |
| Amount range filter applied | `transactionFiltersMachine` amountRange state |
| Pagination — load more button / infinite scroll | `dataMachine` page > 1 append |
| Empty state displayed when no results | `EmptyList` component |
| Privacy: private transactions invisible to third parties | visibility decision tree |

### UI Tests (`cypress/tests/ui/transaction-view.spec.ts`)

| Test | Coverage |
|------|----------|
| Like a transaction | `transactionDetailMachine` CREATE{entity:LIKE} |
| Comment on a transaction | `transactionDetailMachine` CREATE{entity:COMMENT} |
| Accept a payment request | `transactionDetailMachine` UPDATE{requestStatus:accepted} + balance change |
| Reject a payment request | `transactionDetailMachine` UPDATE{requestStatus:rejected} |

### Component Tests

| File | What it tests |
|------|--------------|
| `TransactionTitle.cy.tsx` | Renders "Charged" / "Requested" / "Paid" based on transaction type and requestStatus |
| `TransactionDateRangeFilter.cy.tsx` | Date picker renders, onChange callback fires with ISO strings |

---

## Complexity Tracking

> No Constitution violations found. No complexity justification required.

All design choices (in-memory pagination, flat JSON storage, XState v4, React Router v5) are
already established by the existing codebase. This feature adds no new architectural patterns that
would require governance justification.

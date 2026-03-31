---
feature: "002-transaction-management"
generated: "2026-03-31"
spec: "specs/002-transaction-management/spec.md"
plan: "specs/002-transaction-management/plan.md"
---

# Tasks: Transaction Management

**Input**: `specs/002-transaction-management/spec.md`, `specs/002-transaction-management/plan.md`  
**Target branch**: `speckit/002-transaction-management`  
**Stack**: TypeScript 5 (strict) · Express 4 · lowdb · React 18 · XState v4 · Cypress 13 · Jest

> **Format**: `- [ ] T-NNN [P?] [USN?] Description — path/to/file`  
> **[P]** = task touches a different file from all concurrent tasks (safe to parallelize)  
> **[USN]** = user story label mapping task to deliverable increment  
> Acceptance criteria and inter-task dependencies are listed **immediately below** each task.

---

## User Story Map

| Label | Story | Priority | Independent Test |
|-------|-------|----------|-----------------|
| US1 | Direct P2P payment — create, debit/credit, complete | P1 🎯 MVP | POST /transactions → 200, balance changes, status=complete |
| US2 | Payment request lifecycle — create, accept, reject | P2 | PATCH /transactions/:id → 204, balance only moves on accept |
| US3 | Bank transfer — deposit/withdrawal, auto-overdraft | P3 | POST /transactions (source=bankId) → 200, balance updates |
| US4 | Transaction feeds — personal/contacts/public, filters, pagination, privacy | P4 | GET /transactions/* all return paginated results respecting privacy |
| US5 | Transaction detail — view enriched record, like, comment | P5 | GET /transactions/:id → 200 with likes/comments arrays |

---

## Phase 1: Setup

**Purpose**: Verify existing codebase baseline and seed data integrity before writing any new code.

- [ ] T-001 Verify dev environment: run `yarn types && yarn lint` with zero errors — repo root
  - **AC**: `yarn types` exits 0; `yarn lint` exits 0 on existing codebase.
  - **Depends on**: nothing

- [ ] T-002 Audit `data/database-seed.json` for coverage of all transaction types (payment, request with pending/accepted/rejected, bank transfer) and privacy levels (public/private/contacts)
  - **AC**: Seed contains ≥1 transaction of each `transactionType`; ≥1 each of `privacyLevel`; ≥1 accepted request and ≥1 rejected request; ≥1 `source`-based (bank transfer). Add missing seed rows if absent.
  - **Depends on**: T-001

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core TypeScript types, validation infrastructure, and base XState machine that every user story depends on. **No user-story work starts until this phase is done.**

⚠️ **CRITICAL**: All five phases (US1–US5) depend on this phase being complete.

- [ ] T-003 Audit and complete `Transaction`, `TransactionResponseItem`, `TransactionStatus`, `TransactionRequestStatus`, and all payload/query TypeScript interfaces in `src/models/transaction.ts`
  - **AC**: All fields from spec data model are present with correct types; no `any`; `strict: true` passes.
  - **Depends on**: T-001

- [ ] T-004 [P] Implement/audit `formatAmount()`, `hasSufficientFunds()`, `isRequestTransaction()`, `isPaymentTransaction()`, date-range helpers, and amount-range helpers in `src/utils/transactionUtils.ts`; all use dinero.js v2 functional API (`dinero`, `add`, `subtract`, `isPositive`, `toDecimal`)
  - **AC**: `formatAmount(10000)` → `"$100.00"`. `hasSufficientFunds({ balance: 5000 }, 10000)` → `false`. All helpers have TSDoc comments explaining the dinero.js integer-cents contract.
  - **Depends on**: T-003

- [ ] T-005 [P] Implement/audit `getPaginatedItems(page, limit, items)` in `src/utils/transactionUtils.ts`: offset = `(page - 1) * limit`, slice full array, return `{ totalPages: Math.ceil(items.length / limit), data: slice }` with inline comment explaining why pagination is in-memory (demo scale)
  - **AC**: `getPaginatedItems(2, 10, arrayOf25)` → `{ totalPages: 3, data: [items 10–19] }`. Zero results → `{ totalPages: 0, data: [] }`.
  - **Depends on**: T-003

- [ ] T-006 [P] Audit `backend/validators.ts` — confirm `isTransactionPayloadValidator`, `isTransactionQSValidator`, `isTransactionPublicQSValidator`, `isTransactionPatchValidator`, and `shortIdValidation("transactionId")` rule arrays exist and enforce: `amount` is `isNumeric().toInt()` (integer cents only, no floats), `privacyLevel` is `isIn(["public","private","contacts"])`, `requestStatus` is `isIn(["accepted","rejected"])` for PATCH
  - **AC**: Sending `amount: 10.50` returns 422. Sending `privacyLevel: "secret"` returns 422. All five validator sets compile with zero TS errors.
  - **Depends on**: T-003

- [ ] T-007 Audit `src/machines/dataMachine.ts` — add inline comments on **every state transition** explaining the `idle → loading → success{withData|withoutData} / failure` lifecycle and the `setResults` action's **append-on-paginate** behaviour (`page > 1` → concat new results to `ctx.results` for infinite scroll); add `DataMachineContext`, `DataMachineSchema`, `DataMachineEvent` TypeScript interfaces
  - **AC**: `yarn types` passes; each state node has a `// Educational: ...` comment; `setResults` comment explains the append vs. replace decision.
  - **Depends on**: T-003

- [ ] T-008 [P] Audit `src/machines/transactionFiltersMachine.ts` — add inline comments explaining XState **parallel states** (`type: "parallel"`) for independent `dateRange` and `amountRange` filter regions; ensure `TransactionFiltersMachineContext` is typed and both regions have `enabled/disabled` sub-states
  - **AC**: `yarn types` passes; comment on `type: "parallel"` explains that both filter regions can be active independently.
  - **Depends on**: T-007

**Checkpoint**: `yarn types && yarn lint` passes. `getPaginatedItems` unit test green. Foundation ready — user story implementation can now begin in parallel.

---

## Phase 3: User Story 1 — Direct P2P Payment (Priority: P1) 🎯 MVP

**Goal**: A logged-in user can send money directly to another user via a 3-step wizard; sender's balance decreases, receiver's increases; transaction status = `complete`.

**Independent Test**: Run `cypress/tests/api/api-transactions.spec.ts` "Create payment" test and `cypress/tests/ui/new-transaction.spec.ts` "Payment" suite. Both must pass without any other user story code.

### Backend — Payment Path

- [ ] T-009 [US1] Implement `debitPayAppBalance(sender, transaction)` and `creditPayAppBalance(receiver, transaction)` helpers in `backend/database.ts` using dinero.js: `debit` uses `subtract` + `isPositive` to check sufficient funds before updating; `credit` uses `add`; both call `savePayAppBalance(user)`; add TSDoc + inline comment explaining why dinero.js integer-cents arithmetic prevents float rounding errors
  - **AC**: Calling `debitPayAppBalance` on a user with balance 10000 for amount 15000 does NOT decrement balance (insufficient — handled by auto-transfer; see T-030); calling for amount 5000 sets balance to 5000. `yarn types` passes.
  - **Depends on**: T-003, T-004

- [ ] T-010 [US1] Implement `createTransaction(senderId, receiverId, transactionData)` in `backend/database.ts` — **payment path only** (defer request path to T-020, bank transfer path to T-028): (1) build record with `shortid()` + `uuid()` IDs, `status: "pending"`; (2) call `debitPayAppBalance`; (3) call `creditPayAppBalance`; (4) set `status: "complete"`, `balanceAtCompletion: sender.balance`; (5) persist via lowdb; return saved transaction
  - **AC**: After `createTransaction` for a payment, sender balance = original − amount (in cents). Receiver balance = original + amount. Transaction record has `status: "complete"` and `balanceAtCompletion` matches sender's post-debit balance.
  - **Depends on**: T-009

- [ ] T-011 [US1] Implement `POST /transactions` route handler in `backend/transaction-routes.ts` for **payment type**: apply `isTransactionPayloadValidator` + `validateMiddleware`, call `ensureAuthenticated`, call `createTransaction`, respond `200 { transaction }` — add inline comment explaining the `validateMiddleware` → `createTransaction` → `200` flow
  - **AC**: Authenticated POST with valid payment body → 200 `{ transaction }`. Unauthenticated → 401. Invalid body (zero amount) → 422.
  - **Depends on**: T-006, T-010

### Frontend — Payment Wizard

- [ ] T-012 [P] [US1] Implement `src/machines/createTransactionMachine.ts` XState wizard (`stepOne → stepTwo → stepThree`) with inline comments on: (a) invoked child machine pattern in `stepTwo` (`transactionDataMachine` spawned with `createData` service, `autoForward: true`); (b) why child machine models the async create lifecycle explicitly rather than using `useState`; define `CreateTransactionMachineSchema`, `CreateTransactionMachineContext`, `CreateTransactionMachineEvents` TypeScript types
  - **AC**: `yarn types` passes. Comment on `autoForward: true` explains that CREATE events from the parent are forwarded to the child without manual wiring.
  - **Depends on**: T-007

- [ ] T-013 [P] [US1] Implement `src/components/TransactionCreateStepOne.tsx` — user search input and receiver selection list; every interactive/assertable element carries a `data-test` attribute: `data-test="user-list-search-input"`, `data-test="user-list-item-{userId}"`
  - **AC**: Renders user list; selecting a user fires the machine's `SET_RECEIVER` event; no `any` types; `yarn lint` passes.
  - **Depends on**: T-012

- [ ] T-014 [P] [US1] Implement `src/components/TransactionCreateStepTwo.tsx` — amount input (integer cents; display as dollars via `formatAmount`), description field, payment/request toggle, privacy level selector; `data-test` attributes: `"transaction-amount-input"`, `"transaction-description"`, `"transaction-create-submit-payment"`, `"transaction-create-submit-request"`, `"transaction-create-privacy-{level}"`
  - **AC**: Submitting with amount=0 or empty description shows inline error (does NOT call machine `CREATE` event). Amount entered as `100` is stored as cents `10000` before submission.
  - **Depends on**: T-012

- [ ] T-015 [P] [US1] Implement `src/components/TransactionCreateStepThree.tsx` — confirmation/success screen displaying `"Pay $X to {name}"` and a "Return to transactions" button; `data-test="transaction-payment-submission"`, `"return-to-transactions"`
  - **AC**: Renders transaction summary from machine context. Return button navigates to `/`.
  - **Depends on**: T-012

- [ ] T-016 [P] [US1] Implement `src/components/TransactionAmount.tsx` — color-coded amount display: red (negative/debit), green (positive/credit or request); `data-test="transaction-amount-{transactionId}"`; uses `formatAmount` from `transactionUtils.ts`
  - **AC**: Given `{ amount: 10000, senderId: currentUser.id }` → renders `"-$100.00"` in red. Given as receiver → `"+$100.00"` in green.
  - **Depends on**: T-004

### Tests — US1

- [ ] T-017 [US1] Write API test "Create payment — POST /transactions" in `cypress/tests/api/api-transactions.spec.ts`: seed db, login as user A, POST payment to user B for 10000 cents, assert 200, `transaction.status === "complete"`, sender balance decreases, receiver balance increases
  - **AC**: Test follows pattern: `cy.task("db:seed")` → `cy.loginByApi()` → `cy.request("POST", ...)` → assertions on response body and `cy.database("find", "users", {id: senderId})`.
  - **Depends on**: T-011

- [ ] T-018 [US1] Write UI test "Payment flow" in `cypress/tests/ui/new-transaction.spec.ts`: seed db, login via UI, navigate to `/transaction/new`, search for user, enter amount and description, submit, assert `stepThree` confirmation renders, assert sender balance decreases in UI
  - **AC**: Uses `cy.getBySel()` exclusively; `cy.task("db:seed")` in `beforeEach`; no raw CSS selectors.
  - **Depends on**: T-013, T-014, T-015, T-017

**Checkpoint**: User Story 1 independently testable. `POST /transactions` (payment) + wizard UI working.

---

## Phase 4: User Story 2 — Payment Request Lifecycle (Priority: P2)

**Goal**: User A can request money from User B. User B can accept (triggers balance transfer) or reject (marks incomplete). Balance only moves on acceptance.

**Independent Test**: Create a request via API, PATCH accept it, assert balance changed. PATCH reject it, assert balance unchanged.

### Backend — Request Path

- [ ] T-019 [US2] Extend `createTransaction()` in `backend/database.ts` with **request path**: set `status: "pending"`, `requestStatus: "pending"`; **do NOT** call `debitPayAppBalance` or `creditPayAppBalance` at creation time; add inline comment: `// Balance deferred — funds move only when receiver accepts (see updateTransactionByIdExecutor)`
  - **AC**: POST /transactions with `transactionType: "request"` → 200, `requestStatus: "pending"`, sender and receiver balances unchanged.
  - **Depends on**: T-010

- [ ] T-020 [US2] Implement `updateTransactionByIdExecutor(transaction, updatedTransaction)` in `backend/database.ts`: on `requestStatus: "accepted"` → run `debitPayAppBalance(sender)` + `creditPayAppBalance(receiver)` + set `status: "complete"`; on `requestStatus: "rejected"` → set `status: "incomplete"` + `requestResolvedAt: new Date()`; persist via lowdb; add inline comments explaining deferred balance logic
  - **AC**: Accepting a request with sender balance 50000 and amount 10000 → sender balance = 40000, receiver balance += 10000, `status: "complete"`. Rejecting → balances unchanged, `status: "incomplete"`, `requestResolvedAt` set.
  - **Depends on**: T-009, T-019

- [ ] T-021 [US2] Implement `updateTransactionById(transactionId, updatedFields)` in `backend/database.ts`: fetch transaction, validate it is not already `complete` or `rejected` (idempotency guard with inline comment), delegate to `updateTransactionByIdExecutor`, persist
  - **AC**: Calling accept on an already-complete transaction is a no-op (no double-debit). `yarn types` passes.
  - **Depends on**: T-020

- [ ] T-022 [P] [US2] Implement `PATCH /transactions/:id` route handler in `backend/transaction-routes.ts`: apply `shortIdValidation("transactionId")` + `isTransactionPatchValidator` + `validateMiddleware` + `ensureAuthenticated`, call `updateTransactionById`, respond `204`
  - **AC**: Authenticated PATCH `{ requestStatus: "accepted" }` → 204. Invalid `requestStatus: "completed"` → 422. Unauthenticated → 401.
  - **Depends on**: T-006, T-021

### Frontend — Request UI

- [ ] T-023 [P] [US2] Extend `src/components/TransactionCreateStepTwo.tsx` — `"transaction-create-submit-request"` button sets `transactionType: "request"` in the machine event; `TransactionAmount` renders green `"+$X requested"` label for the requester's perspective
  - **AC**: Submitting via request button → POST body contains `transactionType: "request"`. Amount label in step three reads `"+ $X requested"`.
  - **Depends on**: T-014, T-019

- [ ] T-024 [P] [US2] Implement accept/reject action buttons in `src/components/TransactionDetail.tsx` — shown only when `transaction.requestStatus === "pending"` AND `transaction.receiverId === currentUser.id`; `data-test="transaction-accept-request"` and `data-test="transaction-reject-request"`; fire `transactionDetailMachine` `UPDATE` event
  - **AC**: Accept button visible to receiver of a pending request; not visible to sender. After clicking accept, transaction status updates to `complete` in UI.
  - **Depends on**: T-022

### Tests — US2

- [ ] T-025 [US2] Write API tests for request lifecycle in `cypress/tests/api/api-transactions.spec.ts`: (a) create request → `requestStatus: "pending"`, balances unchanged; (b) PATCH accept → 204, sender balance decreases, receiver increases; (c) PATCH reject → 204, balances unchanged, `requestStatus: "rejected"`
  - **AC**: Three separate `it()` blocks each with `cy.task("db:seed")` in `beforeEach`.
  - **Depends on**: T-022

- [ ] T-026 [US2] Write UI tests in `cypress/tests/ui/new-transaction.spec.ts` (create request flow) and `cypress/tests/ui/transaction-view.spec.ts` (accept and reject flows): seed, login as receiver, navigate to transaction, click accept/reject, assert balance change in UI header
  - **AC**: Uses `cy.getBySel("transaction-accept-request")` and `cy.getBySel("transaction-reject-request")`.
  - **Depends on**: T-024, T-025

**Checkpoint**: US1 + US2 independently testable and non-conflicting.

---

## Phase 5: User Story 3 — Bank Transfer / Overdraft Handling (Priority: P3)

**Goal**: User can deposit from (or withdraw to) a linked bank account. If a P2P payment exceeds balance, an automatic withdrawal tops up the wallet first.

**Independent Test**: POST /transactions with `source=bankAccountId` → 200, user balance updated; POST payment with insufficient funds → auto-transfer created, payment completes.

### Backend — Bank Transfer Path

- [ ] T-027 [US3] Extend `createTransaction()` in `backend/database.ts` with **bank transfer path**: detect `source` field non-empty → set `senderId === receiverId` (self-transfer); immediately update balance (deposit: credit; withdrawal: debit); set `status: "complete"`; add inline comment: `// Bank transfers are synchronous and self-directed — senderId equals receiverId`
  - **AC**: POST with `source: "<bankAccountId>"` and `senderId === receiverId` → 200, user balance changes by amount. `transactionType` is `"transfer"` in the model.
  - **Depends on**: T-010

- [ ] T-028 [P] [US3] Implement auto-overdraft logic in `debitPayAppBalance()` in `backend/database.ts`: when `hasSufficientFunds` is false → calculate shortfall via dinero.js `subtract`; create an automatic bank-transfer withdrawal record (via `createBankTransferTransaction`) to bring balance to amount needed; then proceed with debit; add inline comment explaining the auto-top-up flow step-by-step
  - **AC**: Sender with balance 3000 sending 10000 → automatic bank withdrawal of 7000 created, sender balance after debit = 0, receiver credited 10000. All balances integer cents.
  - **Depends on**: T-009, T-027

- [ ] T-029 [P] [US3] Audit `backend/validators.ts` — ensure `isTransactionPayloadValidator` includes optional `source` field validation: `body("source").optional().isString()` with inline comment explaining source identifies the bank account ID for transfers
  - **AC**: POST with `source: ""` (empty string) treated as P2P (no bank account). POST with `source: "abc123"` passes validation.
  - **Depends on**: T-006

### Tests — US3

- [ ] T-030 [US3] Write API test "Create bank transfer" in `cypress/tests/api/api-transactions.spec.ts`: seed, login, POST with `source=bankAccountId`, assert 200, user balance updated, `transaction.source` matches bank account ID
  - **AC**: Follows `cy.database("find", "bankaccounts", ...)` pattern to get a real bank account ID from seed.
  - **Depends on**: T-027

- [ ] T-031 [US3] Write UI test "Insufficient funds — auto bank transfer" in `cypress/tests/ui/new-transaction.spec.ts`: seed user with low balance, attempt payment exceeding balance, assert payment completes (status=complete) and a bank transfer record was created in the database
  - **AC**: `cy.database("filter", "bankTransfers", { userId })` returns one record after the payment.
  - **Depends on**: T-028, T-030

**Checkpoint**: US1 + US2 + US3 independently testable.

---

## Phase 6: User Story 4 — Transaction Feeds, Filtering & Pagination (Priority: P4)

**Goal**: All three feeds (personal / contacts / public) return paginated, privacy-filtered results. Date, amount, and status filters work correctly. Public feed first page includes ≤5 contact transactions.

**Independent Test**: GET /transactions/public?page=1 returns contact-injected results; page=2 returns only public. Private transactions never appear in other users' feeds.

### Backend — Query Layer

- [ ] T-032 [US4] Implement `getTransactionsForUserForApi(userId)` in `backend/database.ts`: query lowdb `transactions` where `senderId === userId OR receiverId === userId`; enrich each record via `getTransactionByIdForApi` (adds `senderName`, `receiverName`, `senderAvatar`, `receiverAvatar`, `likes`, `comments`); return `TransactionResponseItem[]`
  - **AC**: Returns only transactions where the user is sender or receiver. Each item has all enrichment fields populated.
  - **Depends on**: T-003

- [ ] T-033 [P] [US4] Implement `getTransactionsForUserContacts(userId)` in `backend/database.ts`: call `getContactIdsForUser(userId)` → for each contactId call `getTransactionsForUserForApi(contactId)` → `uniqBy("id")` to deduplicate; add inline comment explaining O(n×m) complexity is acceptable at demo scale (~50 users, ~20 contacts)
  - **AC**: Returns all transactions visible to the user's contact network, deduplicated.
  - **Depends on**: T-032

- [ ] T-034 [P] [US4] Implement `nonContactPublicTransactions(userId)` and `getPublicTransactionsByQuery(currentUserId, query)` in `backend/database.ts`: filter to `privacyLevel === "public"` only; exclude `private` and `contacts`-level transactions not involving the user; add inline comment explaining the visibility decision tree from spec (private→only sender/receiver; contacts→requires contact relationship; public→all authenticated)
  - **AC**: A `private` transaction never appears in another user's public feed result. A `contacts` transaction from non-contacts never appears. `public` transactions appear for all authenticated users.
  - **Depends on**: T-032

- [ ] T-035 [US4] Implement `GET /transactions` route handler in `backend/transaction-routes.ts`: `ensureAuthenticated` + `isTransactionQSValidator` + `validateMiddleware`; call `getTransactionsForUserForApi`; apply date-range, amount-range, and status query filters; call `getPaginatedItems(page, limit, filtered)`; use `res.locals.paginate.hasNextPages(totalPages)` for `hasNextPages`; respond `200 { pageData, results }`
  - **AC**: `GET /transactions?page=2&limit=5` returns items 5–9 with correct `pageData.page === 2`. `GET /transactions?status=complete` returns only complete transactions.
  - **Depends on**: T-005, T-006, T-032

- [ ] T-036 [P] [US4] Implement `GET /transactions/contacts` route handler in `backend/transaction-routes.ts`: same filter + pagination pattern as T-035, using `getTransactionsForUserContacts` as data source
  - **AC**: Returns contact-scoped transactions with correct `pageData`.
  - **Depends on**: T-033, T-035

- [ ] T-037 [P] [US4] Implement `GET /transactions/public` route handler in `backend/transaction-routes.ts`: on `page === 1` → `const contactHead = slice(0, 5, contactsTransactions)`; `concat(contactHead, publicTransactions)` → paginate; on `page > 1` → paginate `publicTransactions` only; add inline comment explaining the first-page contact injection as a "personalised feed" teaching example (DD5 from plan)
  - **AC**: Page 1 response may include up to 5 contact transactions prepended to public results. Page 2 response contains zero contact-injected items.
  - **Depends on**: T-033, T-034, T-035

### Frontend — Feed Machines

- [ ] T-038 [US4] Implement `src/machines/personalTransactionsMachine.ts` via `dataMachine.withConfig({ services: { fetchData: fetchPersonalTransactions } })`; add inline comment explaining the two-layer machine pattern (generic `dataMachine` + injected service)
  - **AC**: Machine transitions to `success.withData` after HTTP 200. Sending `FETCH_MORE` increments page and appends results (`ctx.results` grows).
  - **Depends on**: T-007

- [ ] T-039 [P] [US4] Implement `src/machines/publicTransactionsMachine.ts` via `dataMachine.withConfig`; add inline comments on `setResults` append-on-paginate action: `// page > 1 → concat new results to ctx.results (infinite scroll pattern)`
  - **AC**: Page 1 fetch → `ctx.results` contains page-1 items. Page 2 fetch → `ctx.results` contains page-1 + page-2 items (not replaced).
  - **Depends on**: T-007

- [ ] T-040 [P] [US4] Implement `src/machines/contactsTransactionsMachine.ts` via `dataMachine.withConfig`; pattern identical to T-039
  - **AC**: `yarn types` passes; machine services call `GET /transactions/contacts`.
  - **Depends on**: T-007

### Frontend — Feed Components

- [ ] T-041 [P] [US4] Implement `src/components/TransactionList.tsx` — generic paginated list: accepts `transactions: TransactionResponseItem[]`, renders `<TransactionItem>` per row, shows "Load More" button when `pageData.hasNextPages === true`; `data-test="transaction-list"`, `data-test="load-more-button"`
  - **AC**: Renders all items. "Load More" fires machine `FETCH_MORE` event. Empty list renders `<EmptyList>`.
  - **Depends on**: T-003

- [ ] T-042 [P] [US4] Implement `src/components/TransactionInfiniteList.tsx` — wraps `TransactionList`; auto-fires `FETCH_MORE` on scroll-to-bottom using IntersectionObserver; `data-test="transaction-list-infinite"`
  - **AC**: Scroll triggers additional fetch. No duplicate items in list.
  - **Depends on**: T-041

- [ ] T-043 [P] [US4] Implement `src/components/TransactionPersonalList.tsx`, `src/components/TransactionPublicList.tsx`, `src/components/TransactionContactsList.tsx` — each wires its XState machine (personal/public/contacts) to `TransactionList` or `TransactionInfiniteList`; each has a `data-test="transaction-list-{personal|public|contacts}"` attribute
  - **AC**: Each component connects to its own machine and re-fetches on mount.
  - **Depends on**: T-038, T-039, T-040, T-041

- [ ] T-044 [P] [US4] Implement `src/components/TransactionNavTabs.tsx` — tab bar with "Everyone" / "Friends" / "Mine" tabs; `data-test="nav-tab-everyone"`, `"nav-tab-friends"`, `"nav-tab-mine"`; active tab highlighted via MUI
  - **AC**: Clicking a tab updates the route (`/public`, `/contacts`, `/personal`).
  - **Depends on**: T-003

- [ ] T-045 [P] [US4] Implement `src/components/EmptyList.tsx` — zero-state display when feed returns no results; `data-test="empty-list-header"` with message "No Transactions"
  - **AC**: Renders when `transactions.length === 0`.
  - **Depends on**: T-003

### Frontend — Filter Components

- [ ] T-046 [P] [US4] Implement `src/components/TransactionListFilters.tsx` — filter panel container connecting `transactionFiltersMachine` to date-range and amount-range sub-components; `data-test="transaction-list-filter-date-range-button"`, `"transaction-list-filter-amount-range-button"`
  - **AC**: Toggling date range panel fires `transactionFiltersMachine` `TOGGLE_DATE_RANGE_FILTER` event.
  - **Depends on**: T-008

- [ ] T-047 [P] [US4] Implement `src/components/TransactionDateRangeFilter.tsx` — date-range calendar picker using `react-date-range`; emits ISO 8601 `dateRangeStart` and `dateRangeEnd` strings to parent machine; `data-test="transaction-date-range-filter-calendar"`
  - **AC**: Selecting a date range fires machine event with ISO strings. `onChange` prop receives `{ dateRangeStart: string, dateRangeEnd: string }`.
  - **Depends on**: T-046

- [ ] T-048 [P] [US4] Implement `src/components/TransactionListAmountRangeFilter.tsx` — dual-handle MUI Slider for `amountMin`/`amountMax` in cents; displays formatted dollar values via `formatAmount`; `data-test="transaction-amount-range-filter-slider"`
  - **AC**: Slider values in cents (e.g., 0–100000). Formatted labels show "$0"–"$1,000".
  - **Depends on**: T-004, T-046

### Containers & Routing

- [ ] T-049 [US4] Implement `src/containers/TransactionsContainer.tsx` — route-level container mounted at `/` sub-routes; renders `TransactionNavTabs` + conditionally renders `TransactionPersonalList` / `TransactionPublicList` / `TransactionContactsList` based on current route; passes filter machine state down as props
  - **AC**: Navigating to `/public` renders `TransactionPublicList`. Navigating to `/personal` renders `TransactionPersonalList`. Filter panel visible on all feed tabs.
  - **Depends on**: T-043, T-044, T-046

### Tests — US4

- [ ] T-050 [US4] Write API tests for `GET /transactions` in `cypress/tests/api/api-transactions.spec.ts`: (a) default list — scoped to current user; (b) `?requestStatus=pending` — all items have `requestStatus: "pending"`; (c) date-range filter — all items within range; (d) amount-range filter — all items within range; (e) page 2 returns second page with correct `pageData`
  - **AC**: Five `it()` blocks; each uses `cy.task("db:seed")` in `beforeEach`; assertions use typed `TransactionResponseItem` response shape.
  - **Depends on**: T-035

- [ ] T-051 [P] [US4] Write API tests for `GET /transactions/contacts` in `cypress/tests/api/api-transactions.spec.ts`: (a) page 1 returns results; (b) page 2 returns next page; assert `pageData.totalPages` and `pageData.hasNextPages` are present
  - **AC**: Two `it()` blocks.
  - **Depends on**: T-036

- [ ] T-052 [P] [US4] Write API tests for `GET /transactions/public` in `cypress/tests/api/api-transactions.spec.ts`: (a) page 1 may include contact transactions (≤5); (b) page 2 contains no injected contact transactions
  - **AC**: Page 1 first items are verified as contact transactions via `cy.database`. Page 2 results are verified as only `privacyLevel: "public"` records.
  - **Depends on**: T-037

- [ ] T-053 [US4] Write UI tests for transaction feeds in `cypress/tests/ui/transaction-feeds.spec.ts`: (a) public feed loads with contact injection on page 1; (b) date-range filter applied → results match date range; (c) amount-range filter applied → results match range; (d) pagination "Load More" appends new items without duplicate rows; (e) empty state renders `"No Transactions"` when filters match nothing
  - **AC**: Five `it()` blocks; `cy.getBySel()` for all selectors; `cy.task("db:seed")` in `beforeEach`.
  - **Depends on**: T-043, T-047, T-048, T-052

- [ ] T-054 [P] [US4] Write UI privacy test in `cypress/tests/ui/transaction-feeds.spec.ts`: seed a `private` transaction between user A and user B; log in as user C (unrelated); assert transaction does NOT appear in public feed; assert `cy.getBySel("transaction-item")` list does not include the private transaction ID
  - **AC**: `cy.getBySel("transaction-list").should("not.contain", privateTransaction.id)` passes.
  - **Depends on**: T-034, T-053

**Checkpoint**: All four feeds load, filter, paginate, and respect privacy rules.

---

## Phase 7: User Story 5 — Transaction Detail, Likes & Comments (Priority: P5)

**Goal**: Any authenticated user with access can view a full transaction record with enriched sender/receiver info, social likes and comments.

**Independent Test**: GET /transactions/:id returns `{ transaction }` with `likes[]`, `comments[]`, `senderName`, `receiverName`. Like and comment round-trips work.

### Backend — Detail Endpoint

- [ ] T-055 [US5] Implement `getTransactionByIdForApi(transactionId)` in `backend/database.ts`: fetch transaction by ID; enrich with `formatFullName(getUserById(senderId))` → `senderName`, `receiverName`, `senderAvatar`, `receiverAvatar`; attach `getLikesByTransactionId(id)` → `likes`; attach `getCommentsByTransactionId(id)` → `comments`; return `TransactionResponseItem`
  - **AC**: Response includes all enrichment fields; `likes` and `comments` are arrays (empty if none).
  - **Depends on**: T-003, T-032

- [ ] T-056 [P] [US5] Implement `GET /transactions/:id` route handler in `backend/transaction-routes.ts`: `ensureAuthenticated` + `shortIdValidation("transactionId")` + `validateMiddleware`; call `getTransactionByIdForApi`; respond `200 { transaction }`
  - **AC**: Authenticated request with valid ID → 200 with enriched transaction. Unknown ID → 404 or appropriate error. Unauthenticated → 401.
  - **Depends on**: T-006, T-055

### Frontend — Detail Machine & Components

- [ ] T-057 [P] [US5] Implement `src/machines/transactionDetailMachine.ts`: states `loading → success / failure`; `CREATE` event for `entity: "LIKE"` and `entity: "COMMENT"` calls respective API endpoints; `UPDATE` event for `requestStatus` calls PATCH endpoint; add inline comments explaining event-driven state management for social actions; define `TransactionDetailMachineContext`, `TransactionDetailMachineEvent` types
  - **AC**: `yarn types` passes. Like event → `POST /likes`. Comment event → `POST /comments`. Update event → `PATCH /transactions/:id`. Machine re-fetches transaction after each mutation.
  - **Depends on**: T-007

- [ ] T-058 [P] [US5] Implement `src/components/TransactionItem.tsx` — single-row list item: sender/receiver avatars, `senderName → receiverName`, formatted amount, description, date; `data-test="transaction-item"`, `data-test="transaction-sender-{senderId}"`, `data-test="transaction-receiver-{receiverId}"`
  - **AC**: Renders without runtime errors for all three transaction types. All `data-test` attributes present.
  - **Depends on**: T-003, T-004

- [ ] T-059 [P] [US5] Implement `src/components/TransactionDetail.tsx` — full view with like button (`data-test="transaction-like-button"`), likes count (`data-test="transaction-likes-count"`), comment input (`data-test="transaction-comment-input"`, `"transaction-comment-submit"`), comment list (`data-test="transaction-comment-{commentId}"`); wires to `transactionDetailMachine`
  - **AC**: Like button increments like count immediately (optimistic update via machine). Comment form submits and new comment appears without page reload.
  - **Depends on**: T-024, T-057

- [ ] T-060 [US5] Implement `src/containers/TransactionDetailContainer.tsx` — route-level container at `/transaction/:transactionId`; reads route param, passes to `transactionDetailMachine`, renders `TransactionDetail`
  - **AC**: Navigating to `/transaction/abc123` loads transaction and renders detail view. Invalid IDs render error state.
  - **Depends on**: T-057, T-059

### Tests — US5

- [ ] T-061 [US5] Write API test for `GET /transactions/:id` in `cypress/tests/api/api-transactions.spec.ts`: seed, login, fetch a transaction by ID, assert 200, assert `senderName`, `receiverName`, `likes` array, `comments` array present
  - **AC**: `expect(response.body.transaction).to.have.all.keys(["id", "senderName", "receiverName", "likes", "comments"])`.
  - **Depends on**: T-056

- [ ] T-062 [US5] Write UI tests for transaction detail in `cypress/tests/ui/transaction-view.spec.ts`: (a) like a transaction — like count increments; (b) comment on a transaction — comment appears in list; (c) accept a payment request — status changes to complete in UI (covered by T-026 but repeated in detail view context for completeness); (d) reject a payment request — status changes to incomplete
  - **AC**: All four `it()` blocks; `cy.getBySel()` selectors; `cy.task("db:seed")` in `beforeEach`.
  - **Depends on**: T-059, T-061

**Checkpoint**: All five user stories independently testable and functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Component tests, educational inline comment audit, data-test attribute completeness, and CI gate validation.

- [ ] T-063 [P] Write component test `src/components/TransactionTitle.cy.tsx`: (a) given `{ transactionType: "payment", senderId: currentUser.id }` → renders `"Charged"`; (b) given `{ transactionType: "request", senderId: currentUser.id }` → renders `"Requested"`; (c) given `{ transactionType: "payment", receiverId: currentUser.id }` → renders `"Received"`; mount with `cy.mount()`
  - **AC**: Three `it()` blocks; zero network calls; component test spec passes `yarn cypress run --component`.
  - **Depends on**: T-016, T-058

- [ ] T-064 [P] Write component test `src/components/TransactionDateRangeFilter.cy.tsx`: (a) mounts and renders the calendar picker; (b) selecting a date range calls `onChange` with `{ dateRangeStart: ISO, dateRangeEnd: ISO }` where both are valid ISO 8601 date strings
  - **AC**: Two `it()` blocks; `cy.mount()` with a spy on `onChange`; asserts spy called with correct shape.
  - **Depends on**: T-047

- [ ] T-065 Audit all XState machine files for constitution Principle 1 (Educational Excellence) compliance: every machine file in `src/machines/` must have (a) a `// Educational:` comment on the `createMachine` call explaining why XState was chosen over useState/useReducer; (b) inline comments on every `invoke` and `spawn`; (c) a TSDoc `@example` on the exported machine constant
  - **Files**: `src/machines/createTransactionMachine.ts`, `personalTransactionsMachine.ts`, `publicTransactionsMachine.ts`, `contactsTransactionsMachine.ts`, `transactionDetailMachine.ts`, `transactionFiltersMachine.ts`, `dataMachine.ts`
  - **AC**: `yarn lint` passes (no eslint-disable suppression). Each machine file has ≥3 `// Educational:` comments.
  - **Depends on**: T-012, T-038, T-039, T-040, T-057

- [ ] T-066 [P] Audit all new/modified components for `data-test` attribute completeness: every element that a Cypress test interacts with or asserts on must have a unique `data-test` attribute; create a checklist in `specs/002-transaction-management/checklists/data-test-audit.md`
  - **Files to audit**: `TransactionCreateStepOne.tsx`, `TransactionCreateStepTwo.tsx`, `TransactionCreateStepThree.tsx`, `TransactionItem.tsx`, `TransactionDetail.tsx`, `TransactionList.tsx`, `TransactionNavTabs.tsx`, `EmptyList.tsx`
  - **AC**: No Cypress test uses raw CSS class selectors or element type selectors for transaction components.
  - **Depends on**: T-013, T-014, T-015, T-041, T-058, T-059

- [ ] T-067 [P] Run `yarn types` and fix all TypeScript strict-mode errors introduced by new transaction code — zero tolerance for `any`, use `unknown` + type guards where runtime type is uncertain
  - **AC**: `yarn types` exits 0. No `// @ts-ignore` or `// eslint-disable` comments added.
  - **Depends on**: T-063, T-064, T-065

- [ ] T-068 [P] Run `yarn lint` and resolve all ESLint violations in new/modified files
  - **AC**: `yarn lint` exits 0.
  - **Depends on**: T-067

- [ ] T-069 Run full Cypress test matrix and confirm all tests pass: `yarn cypress run --spec "cypress/tests/api/api-transactions.spec.ts"` + `yarn cypress run --spec "cypress/tests/ui/new-transaction.spec.ts,cypress/tests/ui/transaction-feeds.spec.ts,cypress/tests/ui/transaction-view.spec.ts"` + `yarn cypress run --component --spec "src/components/TransactionTitle.cy.tsx,src/components/TransactionDateRangeFilter.cy.tsx"`
  - **AC**: Zero failing tests. Zero flaky tests (run twice to confirm determinism). Coverage report uploaded (Codecov).
  - **Depends on**: T-067, T-068

---

## Summary

| Phase | Tasks | User Story | Parallelizable |
|-------|-------|-----------|---------------|
| Phase 1: Setup | T-001 → T-002 | — | 0 |
| Phase 2: Foundational | T-003 → T-008 | — | 5 of 6 |
| Phase 3: US1 Direct Payment | T-009 → T-018 | US1 (P1 MVP) | 7 of 10 |
| Phase 4: US2 Payment Request | T-019 → T-026 | US2 (P2) | 3 of 8 |
| Phase 5: US3 Bank Transfer | T-027 → T-031 | US3 (P3) | 2 of 5 |
| Phase 6: US4 Feeds & Filters | T-032 → T-054 | US4 (P4) | 18 of 23 |
| Phase 7: US5 Detail View | T-055 → T-062 | US5 (P5) | 5 of 8 |
| Phase 8: Polish | T-063 → T-069 | — | 4 of 7 |
| **Total** | **69 tasks** | **5 stories** | **44 [P] tasks** |

**MVP scope**: Complete Phases 1–3 (T-001 → T-018) to deliver a working direct payment feature with API + UI tests. Stop at the Phase 3 checkpoint to validate independently before proceeding.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
  └─► Phase 2 (Foundational)  ← BLOCKS all user stories
        ├─► Phase 3 (US1 - Direct Payment)   ─────────────────────┐
        ├─► Phase 4 (US2 - Request Lifecycle) — depends on US1 DB  │ Can run in
        ├─► Phase 5 (US3 - Bank Transfer)     — depends on US1 DB  │ parallel once
        ├─► Phase 6 (US4 - Feeds & Filters)   — depends on US1 DB  │ Foundation
        └─► Phase 7 (US5 - Detail View)       — depends on US1 DB  ┘ complete
              └─► Phase 8 (Polish)  ← runs after all stories
```

### Within-Phase Task Dependencies

**Phase 2 critical chain**: T-003 → T-004, T-005, T-006 (parallel) → T-007 → T-008

**Phase 3 critical chain**: T-003 → T-009 → T-010 → T-011 → T-017 (API test validates backend before UI)

**Phase 4 backend chain**: T-020 → T-021 → T-022 (idempotency guard before route handler)

**Phase 6 backend chain**: T-032 → T-033, T-034 (parallel) → T-035 → T-036, T-037 (parallel)

**Phase 6 frontend chain**: T-007 → T-038, T-039, T-040 (parallel) → T-043 → T-049

### Key Cross-Phase Dependencies

| Task | Hard Depends On |
|------|----------------|
| T-009 (debit/credit helpers) | T-004 (dinero.js utils in transactionUtils) |
| T-010 (createTransaction payment) | T-009 (debit/credit helpers) |
| T-011 (POST route) | T-006 (validators), T-010 (database function) |
| T-019 (createTransaction request) | T-010 (extends payment path) |
| T-020 (updateTransactionByIdExecutor) | T-009 (debit/credit), T-019 (request creation) |
| T-027 (bank transfer path) | T-010 (extends createTransaction) |
| T-028 (auto-overdraft) | T-009 (debit/credit), T-027 (bank transfer) |
| T-032 (getTransactionsForUserForApi) | T-003 (Transaction types) |
| T-034 (privacy filtering) | T-032 (base query) |
| T-037 (public feed splice) | T-033 (contacts), T-034 (privacy) |
| T-038–T-040 (feed machines) | T-007 (dataMachine base) |
| T-057 (transactionDetailMachine) | T-007 (dataMachine base) |
| T-065 (XState comment audit) | All machine implementations |
| T-069 (full test matrix) | T-067 (types), T-068 (lint) |

---

## Parallel Execution Examples

### All of Foundation Phase 2 (after T-003)

```
Agent A: T-004 — transactionUtils.ts helpers (dinero.js)
Agent B: T-005 — getPaginatedItems() implementation
Agent C: T-006 — validators.ts audit (all 5 rule sets)
Agent D: T-007 — dataMachine.ts inline comments + types
  └─► Agent D continues: T-008 — transactionFiltersMachine.ts (after T-007)
```

### US1 Frontend (after T-011)

```
Agent A: T-012 — createTransactionMachine (XState wizard)
  └─► T-013 — StepOne component
  └─► T-014 — StepTwo component
  └─► T-015 — StepThree component
Agent B: T-016 — TransactionAmount component
```

### US4 Frontend (after T-038–T-040)

```
Agent A: T-041 → T-042 — TransactionList + InfiniteList
Agent B: T-043 — PersonalList + PublicList + ContactsList (waits for T-041)
Agent C: T-044 — TransactionNavTabs
Agent D: T-045 — EmptyList
Agent E: T-046 → T-047 → T-048 — Filter components
```

### US4 API Tests (after T-035–T-037)

```
Agent A: T-050 — GET /transactions tests
Agent B: T-051 — GET /transactions/contacts tests
Agent C: T-052 — GET /transactions/public tests
```

---

## Implementation Strategy

### MVP First (US1 Only — ~18 tasks)

1. Complete Phase 1 (T-001–T-002): Setup
2. Complete Phase 2 (T-003–T-008): Foundation
3. Complete Phase 3 (T-009–T-018): US1 Direct Payment
4. **STOP and VALIDATE**: Run `POST /transactions` API test + payment wizard UI test
5. Deploy/demo MVP if validated

### Incremental Delivery

```
Foundation (T-003–T-008) → ready
  + US1 Direct Payment (T-009–T-018) → MVP demo: "I can pay a friend"
  + US2 Request Lifecycle (T-019–T-026) → "I can request money and accept/reject"
  + US3 Bank Transfer (T-027–T-031) → "I can top up from my bank"
  + US4 Feeds & Filters (T-032–T-054) → "I can browse and filter all transactions"
  + US5 Detail View (T-055–T-062) → "I can like, comment, and inspect any transaction"
  + Polish (T-063–T-069) → "All tests pass, all machines are documented"
```

### Gap Coverage Map

| Gap identified in plan | Tasks addressing it |
|------------------------|-------------------|
| Amount validation (integer cents, dinero.js) | T-004, T-006, T-009, T-010, T-014 |
| Privacy filtering correctness | T-034, T-054 |
| Balance update logic (payment/request/transfer) | T-009, T-010, T-019, T-020, T-027, T-028 |
| XState inline comments (Principle 1) | T-007, T-008, T-012, T-038, T-039, T-040, T-057, T-065 |
| Pagination implementation details | T-005, T-035, T-036, T-037, T-039, T-050, T-051, T-053 |
| Full Cypress test matrix coverage | T-017, T-018, T-025, T-026, T-030, T-031, T-050–T-054, T-061–T-064, T-069 |

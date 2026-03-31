---
description: "Task list for Bank Accounts & Transfers feature — gap-closure and test coverage"
---

# Tasks: Bank Accounts & Transfers

**Feature Branch**: `003-bank-accounts-transfers`  
**Input**: `specs/003-bank-accounts-transfers/plan.md` + `spec.md`  
**Status**: Feature largely implemented; this plan closes 8 identified gaps (G1–G8)

**Gap Priority Legend**:
- 🔴 HIGH — G1 (missing deposit function), G2 (validator gap), G3 (security), G6 (missing E2E tests)
- 🟡 MEDIUM — G4 (weak backend validation), G5 (`@ts-ignore`), G7 (missing API tests)
- 🟢 LOW — G8 (TSDoc + README)

**Tests Note**: Tests are **required** by Constitution Principle 3 (≥ 85% coverage). All E2E
tests use established custom commands (`cy.getBySel()`, `cy.loginByXstate()`, `cy.database()`,
`cy.task("db:seed")`, `cy.visualSnapshot()`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable — operates on different files with no incomplete dependencies
- **[Story]**: User story label (US1, US2, US3) — Setup and Foundational phases have no label
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Confirm working baseline before any gap-closure work begins.

- [ ] T001 Confirm branch `003-bank-accounts-transfers` is active, run `yarn types` and verify zero TypeScript errors as a baseline checkpoint

**Checkpoint**: Baseline confirmed — gap-closure work can begin.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The two changes below unlock both the deposit (US2) and withdrawal (US3) flows.
Neither user story can be fully implemented or meaningfully tested until this phase is complete.

**⚠️ CRITICAL**: Tasks T002 and T003 MUST be complete before starting Phase 4 (US2) or Phase 5 (US3).

- [ ] T002 🔴 [G2] Add `"transfer"` to the `isIn` list in `isTransactionPayloadValidator` in `backend/validators.ts` (line 82: `body("transactionType").isIn(["payment", "request", "transfer"])`) so that `POST /transactions` with `transactionType: "transfer"` passes validation instead of returning 422
- [ ] T003 🔴 [G2] Add a `"transfer"` branch skeleton to `createTransaction` in `backend/database.ts` — update the function signature from `transactionType: "payment" | "request"` to `transactionType: "payment" | "request" | "transfer"` and add an `isBankTransfer` guard stub (parallel to the existing `isPayment` guard on line 549) that will be filled in by T015 and T018

**Checkpoint**: `POST /transactions` now accepts `transactionType: "transfer"` without a 422. Deposit and withdrawal implementation can begin.

---

## Phase 3: User Story 1 — Bank Account Management (Priority: P1) 🎯 MVP

**Goal**: Bank account CRUD is secure (ownership-enforced), the backend validator is
authoritative (format-constrained), the XState machine is cleanly typed, and the existing
test suite is extended with the missing cross-user, validation-error, mobile, and visual
snapshot cases.

**User Story**: _"As an authenticated user, I can link, view, and delete my external bank
accounts so that I can manage which accounts are available for transfers."_

**Independent Test**: Navigate to `/bankaccounts` as a seeded user, create a new account, verify
it appears in the list; delete it, verify `(Deleted)` label; attempt `GET /bankAccounts/:id` with
a different user's token and verify 401.

### Security Fix — G3

- [ ] T004 [US1] 🔴 [G3] Add ownership authorization check to `GET /bankAccounts/:bankAccountId` handler in `backend/bankaccount-routes.ts` — after fetching the account (`getBankAccountById`), compare `account.userId` to `req.user?.id`; return `res.status(401).json({ error: "Unauthorized" })` if they differ. Prevents any authenticated user from reading another user's account by guessing a shortId.

### Validator Hardening — G4

- [ ] T005 [P] [US1] 🟡 [G4] Strengthen `isBankAccountValidator` in `backend/validators.ts` (lines 33–36) — replace bare `.isString().trim()` with format-constrained rules: `bankName` → `.isString().trim().isLength({ min: 5 })`; `routingNumber` → `.isString().trim().isNumeric().isLength({ min: 9, max: 9 })`; `accountNumber` → `.isString().trim().isNumeric().isLength({ min: 9, max: 12 })`. Aligns backend authority with the existing Yup schema in `BankAccountForm.tsx`.

### TypeScript Quality — G5

- [ ] T006 [P] [US1] 🟡 [G5] Declare a `GraphQLBankAccountsResponse` interface in `src/machines/bankAccountsMachine.ts` — shape: `{ data: { listBankAccount: BankAccount[] } }` — and replace the `// @ts-ignore` on line 55 with a typed cast: `(resp.data as GraphQLBankAccountsResponse).data.listBankAccount`. Run `yarn types` to confirm zero errors after this change.

### API Tests — G7

- [ ] T007 [P] [US1] 🟡 [G7] Add API E2E test `"GET /bankAccounts/:id returns 401 when requesting another user's account"` in `cypress/tests/api/api-bankaccounts.spec.ts` — log in as User A, obtain User B's bank account ID via `cy.database("filter", "bankaccounts", { userId: userB.id })`, make `cy.request({ url: "/bankAccounts/:id", failOnStatusCode: false })` as User A, and assert `response.status === 401`.
- [ ] T008 [P] [US1] 🟡 [G7] Add API E2E test `"POST /bankAccounts rejects routing number that is not exactly 9 digits"` in `cypress/tests/api/api-bankaccounts.spec.ts` — submit `{ bankName: "Test Bank", accountNumber: "123456789", routingNumber: "12345678" }` (8 digits) with `failOnStatusCode: false` and assert `response.status === 422`.
- [ ] T009 [P] [US1] 🟡 [G7] Add API E2E test `"POST /bankAccounts rejects account number outside 9–12 digit range"` in `cypress/tests/api/api-bankaccounts.spec.ts` — test two cases: (a) 8-digit account number → expect 422; (b) 13-digit account number → expect 422. Both with `failOnStatusCode: false`.

### UI E2E Tests — G6

- [ ] T010 [P] [US1] 🔴 [G6] Add UI E2E test `"mobile viewport: sidenav toggle reveals bank accounts nav link"` in `cypress/tests/ui/bankaccounts.spec.ts` — set viewport to `cy.viewport("iphone-6")`, call `cy.loginByXstate(ctx.user.username)`, click the hamburger menu button, and assert `cy.getBySel("sidenav-bankaccounts")` is visible. Mirrors the mobile pattern used in `transaction-feeds.spec.ts`.
- [ ] T011 [P] [US1] 🔴 [G6] Add UI E2E test `"visual snapshot: bank accounts list with multiple accounts"` in `cypress/tests/ui/bankaccounts.spec.ts` — seed a user with 2+ bank accounts via `cy.database`, visit `/bankaccounts`, wait for `@gqlListBankAccountQuery`, and call `cy.visualSnapshot("Bank Accounts List")`. Establishes Percy baseline for the list state.
- [ ] T012 [P] [US1] 🔴 [G6] Add UI E2E test `"visual snapshot: empty bank accounts list"` in `cypress/tests/ui/bankaccounts.spec.ts` — use a freshly seeded user with no bank accounts, visit `/bankaccounts`, wait for `@gqlListBankAccountQuery`, assert the empty-list element is visible, and call `cy.visualSnapshot("Empty Bank Accounts List")`. Establishes Percy baseline for the empty state.

**Checkpoint**: US1 complete. Bank account management is secure, validated, fully typed, and covered by E2E + visual regression tests. Deliverable is independently demo-able at `/bankaccounts`.

---

## Phase 4: User Story 2 — Bank Transfer Deposit (Priority: P2)

**Goal**: Users can move funds from a linked bank account into their in-app wallet via the
transaction creation flow. The backend correctly records a `BankTransfer` with
`type: "deposit"` and increments the user's balance.

**User Story**: _"As an authenticated user, I can deposit funds from a linked bank account
into my app wallet so that I have a balance available for payments."_

**Independent Test**: Log in as a seeded user with a linked bank account. Submit
`POST /transactions` with `transactionType: "transfer"` and a deposit amount. Verify the
returned transaction has `status: "complete"`, a `BankTransfer` record exists with
`type: "deposit"`, and the user's balance has increased by the deposit amount.

**Depends on**: T002, T003 (Phase 2 Foundational)

### Backend Implementation — G1

- [ ] T013 [US2] 🔴 [G1] Implement `createBankTransferDeposit` curried helper in `backend/database.ts` immediately after `createBankTransferWithdrawal` (line ~518) — mirror the withdrawal pattern exactly: `export const createBankTransferDeposit = curry((receiver: User, transaction: Transaction, transferAmount: number) => createBankTransfer({ userId: receiver.id, source: transaction.source, amount: transferAmount, transactionId: transaction.id, type: BankTransferType.deposit }))`. This is the symmetric counterpart to `createBankTransferWithdrawal`.
- [ ] T014 [US2] 🔴 [G1] Implement `processBankDeposit` function in `backend/database.ts` — takes `(user: User, transaction: Transaction)` as arguments, uses lodash `flow` to: (1) calculate deposit amount from `transaction.amount`, (2) call `createBankTransferDeposit(user, transaction)` to record the transfer, (3) add the amount to `user.balance` via `savePayAppBalance(user)`, (4) mark the transaction complete via `updateTransactionById(transaction.id, { status: TransactionStatus.complete })`. Follow the `creditPayAppBalance` + `debitPayAppBalance` style.
- [ ] T015 [US2] 🔴 [G1] Wire the deposit branch in `createTransaction` (`backend/database.ts`) — inside the `isBankTransfer` guard stub added in T003, check whether the sending user is also the receiving user and the transaction has a `source` (bank account ID). When `true` and direction is deposit, call `processBankDeposit(receiver, savedTransaction)`. Ensure the transaction is saved before the balance update.

### E2E Tests — G6, G7

- [ ] T016 [US2] 🔴 [G6] Add UI E2E test `"deposit flow: user deposits from bank account and balance increases"` in `cypress/tests/ui/bankaccounts.spec.ts` — log in via `cy.loginByXstate`, record the initial balance from `cy.database("find", "users", { id: ctx.user.id })`, navigate to the new transaction page, select a linked bank account as source, enter a deposit amount, submit and wait for the transaction response, then re-query the user record and assert `newBalance === initialBalance + depositAmount`.
- [ ] T017 [P] [US2] 🟡 [G7] Add API E2E test `"GET /bankTransfers returns a transfer with type: deposit after a deposit transaction"` in `cypress/tests/api/api-banktransfers.spec.ts` — create a deposit transaction via `cy.request("POST", "/transactions", depositPayload)`, then `cy.request("GET", "/bankTransfers")` and assert the response contains a transfer object where `transfer.type === "deposit"` and `transfer.transactionId` matches the created transaction.

**Checkpoint**: US2 complete. Deposit flow is functional end-to-end. A user can move funds from a linked bank account to their wallet. Independently testable and demo-able.

---

## Phase 5: User Story 3 — Bank Transfer Withdrawal (Priority: P3)

**Goal**: Users can explicitly move funds from their in-app wallet to a linked bank account.
The backend records a `BankTransfer` with `type: "withdrawal"` and decrements the user's
balance. Withdrawals exceeding the user's balance are rejected.

**User Story**: _"As an authenticated user, I can withdraw funds from my app wallet to a
linked bank account so that I can access my money externally."_

**Independent Test**: Log in as a user with balance > 0 and a linked bank account. Submit a
withdrawal transaction. Verify balance decreases. Submit a second withdrawal exceeding the
remaining balance and verify an error is returned.

**Depends on**: T002, T003 (Phase 2), T013–T015 (US2 establishes the transfer pattern)

### Backend Wiring

- [ ] T018 [US3] 🔴 [G1] Wire the withdrawal branch in `createTransaction` (`backend/database.ts`) — in the `isBankTransfer` guard added in T003, add the withdrawal path: when the transfer direction is a withdrawal (user moving wallet funds out), call `debitPayAppBalance(sender, savedTransaction)` (which already handles the balance check via `hasSufficientFunds`) and `updateTransactionById(transaction.id, { status: TransactionStatus.complete })`. Note: `debitPayAppBalance` already calls `createBankTransferWithdrawal` internally when balance is insufficient; verify the explicit withdrawal path also records the `BankTransfer` record by inspecting the `hasSufficientFunds` branch.

### E2E Tests — G6

- [ ] T019 [US3] 🔴 [G6] Add UI E2E test `"withdrawal flow: user withdraws to bank account and balance decreases"` in `cypress/tests/ui/bankaccounts.spec.ts` — log in via `cy.loginByXstate`, record the initial balance, navigate to the new transaction page, select a linked bank account, enter a withdrawal amount less than the current balance, submit and wait for the transaction response, re-query the user record and assert `newBalance === initialBalance - withdrawalAmount`.
- [ ] T020 [US3] 🔴 [G6] Add UI E2E test `"withdrawal rejected: amount exceeding balance shows insufficient funds error"` in `cypress/tests/ui/bankaccounts.spec.ts` — use `cy.database("find", "users", { id: ctx.user.id })` to get the current balance, attempt a withdrawal for `currentBalance + 1` cent, and assert the error message containing "insufficient" (or the actual error text from the UI) is visible. Verify the user's balance has not changed.

**Checkpoint**: US3 complete. All three user stories are independently functional and tested. Full deposit/withdrawal cycle is verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation completeness to satisfy Constitution Principle 10
(Documentation-as-Code). These tasks have no dependencies on each other and can run in parallel.

- [ ] T021 [P] 🟢 [G8] Add TSDoc comments to all four route handlers in `backend/bankaccount-routes.ts` — each comment should document: HTTP method + path, authentication requirement, params/body shape, response shape, status codes (200 / 401 / 422), and a one-line rationale (the "why" per Principle 1). Example format: `/** GET /bankAccounts/:bankAccountId — Returns a single bank account. Requires ownership: account.userId must match req.user.id. @returns {account: BankAccount} 200 | 401 unauthorized | 404 not found */`
- [ ] T022 [P] 🟢 [G8] Add TSDoc comments to `createBankTransferDeposit`, `createBankTransferWithdrawal`, `processBankDeposit`, `debitPayAppBalance`, and `createBankTransfer` in `backend/database.ts` — each comment must explain the function's role in the transfer pipeline, its parameters, return type, and any side effects (e.g., "updates user balance in database"). These functions are the core of the educational value for this feature.
- [ ] T023 [P] 🟢 [G8] Add TSDoc comments to the `GET /bankTransfers` route handler in `backend/banktransfer-routes.ts` — document that this endpoint is permanently read-only (no POST), why bank transfer records are created implicitly, and the `userId` scoping behavior.
- [ ] T024 🟢 [G8] Update `README.md` in the repository root — add a "Bank Accounts & Transfers" section (after the existing "Transactions" section) that describes: (a) how to link a bank account via the UI, (b) how to perform a deposit and withdrawal, (c) the soft-delete behavior, (d) that no real funds are transferred (demo only). Keep it concise — 3–5 sentences per sub-section.
- [ ] T025 [P] Run `yarn types` and confirm zero TypeScript errors across the full codebase after all implementation changes
- [ ] T026 [P] Run `yarn lint` and confirm zero lint errors; fix any auto-fixable issues with `yarn lint --fix`

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
    └──► Phase 2 (Foundational) ← BLOCKS Phase 4 and Phase 5
              ├──► Phase 3 (US1)  — independent of US2/US3; can start after Foundational
              ├──► Phase 4 (US2)  — depends on T002, T003
              └──► Phase 5 (US3)  — depends on T002, T003, and T013–T015
Phase 6 (Polish) — depends on all implementation phases being complete
```

### User Story Dependencies

| Story | Depends On | Can Parallelize With |
|-------|-----------|----------------------|
| US1 (Phase 3) | Phase 2 only | US2, US3 can start in parallel |
| US2 (Phase 4) | Phase 2 (T002, T003) | US1, and US3 prep tasks |
| US3 (Phase 5) | Phase 2 + US2 (T013–T015) | US1 tests (T010–T012) |

### Within Phase 3 (US1)

```
T004 (security fix)       — no dependencies within phase; start immediately
T005 (validator hardening) — [P] parallel with T004, T006
T006 (@ts-ignore fix)     — [P] parallel with T004, T005
T007 (API test cross-user) — [P] depends on T004 being complete first (tests the fix)
T008, T009 (API tests)    — [P] depends on T005 being complete first (tests the fix)
T010, T011, T012 (UI E2E) — [P] can run after T005/T006 are merged
```

### Within Phase 4 (US2)

```
T013 (createBankTransferDeposit) — start after T002, T003
T014 (processBankDeposit)        — depends on T013
T015 (wire deposit branch)       — depends on T013, T014
T016 (UI E2E deposit)            — depends on T015 (needs working backend)
T017 (API E2E deposit type)      — [P] depends on T015
```

### Within Phase 5 (US3)

```
T018 (wire withdrawal branch) — depends on T013–T015 pattern being established
T019 (UI E2E withdrawal)      — depends on T018
T020 (UI E2E rejection)       — [P] depends on T018, parallel with T019
```

---

## Parallel Execution Examples

### Parallel: US1 Security + Quality (can all start after T001)

```
Agent A: T004 — bankaccount-routes.ts ownership check
Agent B: T005 — validators.ts format constraints
Agent C: T006 — bankAccountsMachine.ts typed interface
```

### Parallel: US1 API Tests (start after T004/T005 land)

```
Agent A: T007 — cross-user 401 test
Agent B: T008 — routing number 422 test
Agent C: T009 — account number 422 test
```

### Parallel: US1 UI Tests (independent of backend fixes)

```
Agent A: T010 — mobile viewport test
Agent B: T011 — visual snapshot (list)
Agent C: T012 — visual snapshot (empty)
```

### Parallel: US2 Deposit Backend (sequential within, but all in Phase 4)

```
Sequential: T013 → T014 → T015 (each depends on previous)
Then parallel: T016 (UI) + T017 (API) — both depend on T015
```

### Parallel: Polish (all Phase 6 tasks are independent)

```
Agent A: T021 — bankaccount-routes.ts TSDoc
Agent B: T022 — database.ts TSDoc
Agent C: T023 — banktransfer-routes.ts TSDoc
Agent D: T024 — README.md update
Agent E: T025 — yarn types
Agent F: T026 — yarn lint
```

---

## Implementation Strategy

### MVP First (US1 Only — Security + Quality)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T003)
3. Complete Phase 3: US1 security fix + validator hardening (T004–T005) → **Deploy security fix**
4. Complete Phase 3: TypeScript fix + all tests (T006–T012) → **US1 fully tested**
5. **STOP and VALIDATE**: All US1 tests pass; `GET /bankAccounts/:id` correctly returns 401 for cross-user access; `POST /bankAccounts` rejects malformed routing/account numbers
6. Demo independently at `/bankaccounts`

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready (30 min)
2. Phase 3 (US1) → Security hardened, validated, tested → **Demo-ready MVP**
3. Phase 4 (US2) → Deposit flow working → **Deposit demo**
4. Phase 5 (US3) → Withdrawal flow working → **Full transfer demo**
5. Phase 6 → Documentation complete → **Feature complete per Constitution**

### Parallel Team Strategy

With 2–3 developers:

- **After Phase 2**:
  - Dev A: Phase 3 (US1) — security + types + validator fixes
  - Dev B: Phase 4 (US2) — deposit backend implementation
- **After Phase 3 and Phase 4**:
  - Dev A: Phase 3 tests (T007–T012) in parallel
  - Dev B: Phase 5 (US3) — withdrawal wiring + tests
- **After all phases**: Both devs collaborate on Phase 6 (split T021–T026)

---

## Gap Traceability

| Gap ID | Priority | Tasks | Phase |
|--------|----------|-------|-------|
| G1 — `createBankTransferDeposit` missing | 🔴 HIGH | T013, T014, T015, T018 | 4, 5 |
| G2 — `"transfer"` not in validator | 🔴 HIGH | T002, T003 | 2 (Foundational) |
| G3 — `GET /bankAccounts/:id` ownership gap | 🔴 HIGH | T004 | 3 (US1) |
| G4 — Weak backend format validation | 🟡 MEDIUM | T005 | 3 (US1) |
| G5 — `@ts-ignore` in `bankAccountsMachine.ts` | 🟡 MEDIUM | T006 | 3 (US1) |
| G6 — Missing E2E tests (delete, deposit, withdrawal, visual) | 🔴 HIGH | T010–T012, T016, T019, T020 | 3, 4, 5 |
| G7 — Missing API tests (cross-user auth, validation) | 🟡 MEDIUM | T007, T008, T009, T017 | 3, 4 |
| G8 — TSDoc + README | 🟢 LOW | T021, T022, T023, T024 | 6 (Polish) |

---

## Summary

| Metric | Value |
|--------|-------|
| Total tasks | 26 |
| Phase 1 (Setup) | 1 task |
| Phase 2 (Foundational) | 2 tasks |
| Phase 3 (US1 — Bank Account Mgmt) | 9 tasks |
| Phase 4 (US2 — Deposit) | 5 tasks |
| Phase 5 (US3 — Withdrawal) | 3 tasks |
| Phase 6 (Polish) | 6 tasks |
| Parallelizable tasks [P] | 16 |
| Security-critical tasks (G3) | 1 (T004) |
| New backend functions | 2 (`createBankTransferDeposit`, `processBankDeposit`) |
| New E2E tests | 11 (6 UI + 5 API) |
| Files modified | 8 |

**Files modified**:
1. `backend/validators.ts` — T002, T005
2. `backend/database.ts` — T003, T013, T014, T015, T018, T022
3. `backend/bankaccount-routes.ts` — T004, T021
4. `backend/banktransfer-routes.ts` — T023
5. `src/machines/bankAccountsMachine.ts` — T006
6. `cypress/tests/api/api-bankaccounts.spec.ts` — T007, T008, T009
7. `cypress/tests/api/api-banktransfers.spec.ts` — T017
8. `cypress/tests/ui/bankaccounts.spec.ts` — T010, T011, T012, T016, T019, T020
9. `README.md` — T024

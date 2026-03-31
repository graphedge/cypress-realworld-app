# Implementation Plan: Social Features (Likes, Comments, Notifications)

**Branch**: `004-social-features` | **Date**: 2025-01-15 | **Spec**: `specs/004-social-features/spec.md`  
**Input**: Feature specification from `/specs/004-social-features/spec.md`

---

## Summary

Implement and harden the Social Features subsystem — Likes, Comments, and Notifications — for the
Cypress Real-World App. The core CRUD infrastructure already exists (routes, database helpers, models,
XState machines, and React components are all present in the repository). This plan focuses on closing
the delta between the current implementation and the specification: fixing three confirmed logic bugs,
adding missing validations, expanding test coverage to match the spec, and documenting all patterns
as educational teaching material.

**Approach**: Audit → Bug-fix → Validate → Test-expand → Document.

---

## Technical Context

**Language/Version**: TypeScript 4.x (strict mode enforced via `tsconfig.json`)  
**Primary Dependencies**:
- **Backend**: Express 4, express-validator, shortid, uuid, lowdb 1.x, lodash/fp
- **Frontend**: React 18, MUI (Material-UI v5), XState 4, Formik + Yup, Axios (via `httpClient`)
- **Tests**: Cypress 13 (E2E + API + component), Jest (unit)

**Storage**: lowdb JSON flat-file database (`data/database.json`); seeded via `data/database-seed.json`  
**Testing**: Cypress E2E (`cypress/tests/ui/`), Cypress API tests (`cypress/tests/api/`), Jest unit tests  
**Target Platform**: Local development server — Node.js backend on configurable port, Vite React frontend  
**Project Type**: Full-stack web application (educational reference implementation)  
**Performance Goals**: API responses < 200 ms on local dev; FCP < 2s on 3G (Principle 9)  
**Constraints**: No external services; all persistence via lowdb JSON (Principle 2)  
**Scale/Scope**: ~50 seeded users, ~100 transactions, 10 seed likes, 10 seed comments, 40 seed notifications

---

## Constitution Check

*GATE: Must pass before implementation. Re-evaluated after design phase.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| 1 | **Educational Excellence** — code clarity over cleverness | ✅ PASS | All implementations use simple, readable patterns. Bug-fix targets add inline comments explaining the "why." |
| 2 | **Zero Production Ambition** — no external infrastructure | ✅ PASS | Feature uses only lowdb JSON; no external DB, cache, or message queue required. |
| 3 | **Comprehensive Testing Discipline** — E2E + API + unit coverage ≥ 85% | ⚠️ GAP | Current API tests (likes, comments, notifications) are thin — spec demands idempotency, validation error, and cross-user notification tests that are missing. **Action**: Expand test suite as per spec section "Test Coverage." |
| 4 | **TypeScript-First, Strict Type Safety** — no `any`, explicit annotations | ⚠️ GAP | `notification-routes.ts` has `// @ts-ignore` on `res.json()` call. `transactionDetailMachine.ts` uses `any` in event types. **Action**: Remove `@ts-ignore`, add proper response types. |
| 5 | **Single Source of Truth for Testing Patterns** — use `cy.getBySel()`, `cy.database()` | ✅ PASS | All existing tests use canonical `cy.task("db:seed")`, `cy.database()`, `cy.loginByApi()`, `cy.getBySel()` / `cy.getBySelLike()` patterns. New tests must follow same conventions. |
| 6 | **Database Seeding as Test Infrastructure** — `cy.task("db:seed")` before each test | ✅ PASS | All spec test files call `cy.task("db:seed")` in `beforeEach`. Seed data has representative likes/comments/notifications. |
| 7 | **Multi-Auth Provider Parity** | ✅ N/A | Social features are not auth-provider-specific; session auth middleware (`ensureAuthenticated`) is provider-agnostic. |
| 8 | **CI/CD as Mandatory Quality Gate** — all tests pass in GitHub Actions | ✅ PASS (pending) | New tests must pass in CI across Chrome, Firefox, and mobile viewports. |
| 9 | **Performance & Observability** — bundle size, API logging | ✅ PASS | No new bundle dependencies introduced. Existing Express logger covers new routes already mounted. |
| 10 | **Documentation-as-Code** — markdown docs for every feature | ⚠️ GAP | No `quickstart.md`, no inline TSDoc on database helpers, no README update for social features. **Action**: Generate `quickstart.md`, add TSDoc comments to all social database helpers. |

**Gate Result**: PROCEED — two gaps (Principle 3, Principle 10) are addressed by this plan's work items. One gap (Principle 4) is a targeted one-line fix.

---

## Project Structure

### Documentation (this feature)

```text
specs/004-social-features/
├── plan.md              # This file
├── research.md          # Phase 0 output — codebase audit findings
├── data-model.md        # Phase 1 output — entity diagrams + field contracts
├── quickstart.md        # Phase 1 output — how to use social features locally
├── contracts/           # Phase 1 output — REST API contracts per endpoint
│   ├── likes.md
│   ├── comments.md
│   └── notifications.md
└── tasks.md             # Phase 2 output — actionable task list (not created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend — Express routes + lowdb helpers
backend/
├── app.ts                        # Route mounting: /likes, /comments, /notifications
├── like-routes.ts                # GET + POST /likes/:transactionId
├── comment-routes.ts             # GET + POST /comments/:transactionId
├── notification-routes.ts        # GET /notifications, POST /notifications/bulk, PATCH /notifications/:id
├── database.ts                   # All DB helpers: createLike, createComment, createNotification, etc.
├── validators.ts                 # isCommentValidator, isNotificationsBodyValidator, isNotificationPatchValidator
├── helpers.ts                    # ensureAuthenticated, validateMiddleware
└── types.ts                      # Backend-side type declarations

# Frontend — React + XState + MUI
src/
├── models/
│   ├── index.ts                  # Re-exports all models
│   ├── like.ts                   # Like interface
│   ├── comment.ts                # Comment interface
│   └── notification.ts           # NotificationBase, PaymentNotification, LikeNotification,
│                                 #   CommentNotification, response item types, payload types,
│                                 #   NotificationsType enum, PaymentNotificationStatus enum
├── machines/
│   ├── dataMachine.ts            # Generic XState data machine (idle→loading→success/failure)
│   ├── notificationsMachine.ts   # Notifications fetch + mark-read (fetchData, updateData)
│   └── transactionDetailMachine.ts # Transaction fetch + like/comment creation (CREATE entity)
├── components/
│   ├── CommentForm.tsx           # Formik form for submitting a comment
│   ├── CommentList.tsx           # MUI List wrapping CommentListItem[]
│   ├── CommentListItem.tsx       # Single comment row (data-test: comment-list-item-{id})
│   ├── NotificationList.tsx      # MUI List wrapping NotificationListItem[] + empty state
│   ├── NotificationListItem.tsx  # Like/comment/payment notification row with Dismiss button
│   └── TransactionDetail.tsx     # Transaction view — orchestrates like button + comment form + lists
├── containers/
│   └── TransactionDetailContainer.tsx  # XState wiring for TransactionDetail (useMachine)
└── utils/
    └── transactionUtils.ts       # Type guards: isLikeNotification, isCommentNotification,
                                  #   isPaymentNotification, currentUserLikesTransaction

# Cypress tests
cypress/
├── tests/
│   ├── api/
│   │   ├── api-likes.spec.ts         # Existing: GET + POST likes
│   │   ├── api-comments.spec.ts      # Existing: GET + POST comments
│   │   └── api-notifications.spec.ts # Existing: GET + POST bulk + PATCH
│   └── ui/
│       └── notifications.spec.ts     # Existing: like/comment/payment notification flows
└── support/
    └── commands/                     # Custom commands: cy.loginByApi, cy.database, cy.loginByXstate

# Seed data
data/
└── database-seed.json               # 10 likes, 10 comments, 40 notifications seeded
```

**Structure Decision**: Web application (Option 2 pattern). Backend is a flat `backend/` directory of
Express route files + a single `database.ts` data-access layer. Frontend is `src/` following
React feature-component layout. Tests live under `cypress/tests/{api,ui}/`.

---

## Phase 0: Research Findings

> Codebase audit conducted in lieu of external research (all relevant decisions are already resolved
> by the existing implementation). This section documents findings from the code inspection.

### Finding 1 — Core Infrastructure Already Implemented

**Decision**: The routes, database helpers, TypeScript models, XState machines, and React components
for Likes, Comments, and Notifications are fully implemented and wired together.

**Rationale**: This feature was partially built as the RWA foundation. The plan is additive/correctional,
not greenfield.

**What exists**:
- `backend/like-routes.ts` — `GET /likes/:transactionId`, `POST /likes/:transactionId`
- `backend/comment-routes.ts` — `GET /comments/:transactionId`, `POST /comments/:transactionId`
- `backend/notification-routes.ts` — `GET /notifications`, `POST /notifications/bulk`, `PATCH /notifications/:id`
- `database.ts` — `createLike`, `createLikes`, `getLikesByTransactionId`, `createComment`,
  `createComments`, `getCommentsByTransactionId`, `createPaymentNotification`, `createLikeNotification`,
  `createCommentNotification`, `getUnreadNotificationsByUserId`, `updateNotificationById`,
  `formatNotificationForApiResponse`
- All TypeScript interfaces in `src/models/notification.ts`, `like.ts`, `comment.ts`
- `notificationsMachine.ts` and `transactionDetailMachine.ts` for state management
- All React UI components

---

### Finding 2 — Bug: Like Notification Targeting Logic Error

**File**: `backend/database.ts`, function `createLikes` (approx. line 290)

```typescript
// CURRENT (BUGGY):
if (userId !== senderId || userId !== receiverId) {
  createLikeNotification(senderId, transactionId, like.id);
  createLikeNotification(receiverId, transactionId, like.id);
}
```

**Problem**: The condition `userId !== senderId || userId !== receiverId` is a tautology — it is
**always true** unless `senderId === receiverId` (impossible for a valid transaction). Using `||`
means if the user is the sender (userId === senderId), the second clause `userId !== receiverId` is
still true, so both notifications are created. The intent is to avoid creating a notification for
the liker themselves.

**Correct logic**:
```typescript
// FIXED — only notify participants who are NOT the person liking
if (userId !== senderId) {
  createLikeNotification(senderId, transactionId, like.id);
}
if (userId !== receiverId) {
  createLikeNotification(receiverId, transactionId, like.id);
}
```

**Same bug exists in `createComments`** — identical fix applies.

---

### Finding 3 — Bug: Like Idempotency Not Enforced

**File**: `backend/database.ts`, function `createLikes`  
**File**: `backend/like-routes.ts`, POST handler

**Problem**: The spec requires "One Like Per User Per Transaction" and idempotent POST. The current
`createLikes` function creates a new like unconditionally on every POST without checking for an
existing like from the same user on the same transaction.

**Fix**: Add a duplicate-check in `createLikes` before calling `createLike`:
```typescript
export const createLikes = (userId: string, transactionId: string) => {
  // Idempotency: check for existing like from this user on this transaction
  const existingLike = getLikesByObj({ userId, transactionId });
  if (existingLike.length > 0) return; // No-op — already liked

  const like = createLike(userId, transactionId);
  // ... notification logic
};
```

---

### Finding 4 — Gap: Comment Content Validation Is Too Permissive

**File**: `backend/validators.ts`

```typescript
// CURRENT:
export const isCommentValidator = body("content").isString().trim();
```

**Problem**: This accepts an empty string as valid content. The spec requires non-empty content.
Additionally, no max-length guard exists.

**Fix**:
```typescript
export const isCommentValidator = body("content")
  .isString()
  .trim()
  .notEmpty()                // Reject empty string
  .isLength({ max: 500 });   // Cap at 500 characters per spec
```

---

### Finding 5 — Gap: `@ts-ignore` in notification-routes.ts

**File**: `backend/notification-routes.ts` (POST /notifications/bulk handler)

```typescript
// @ts-ignore
res.json({ results: notifications });
```

**Problem**: Violates Principle 4 (TypeScript-First). The issue is that `createNotifications`
returns `(NotificationType | undefined)[]` because of an `if` branch without an else return.

**Fix**: Either fix `createNotifications` to return `NotificationType[]` (remove the `undefined`
case with a proper else branch), or add an explicit type assertion with a comment explaining why
the cast is safe. Remove the `@ts-ignore`.

---

### Finding 6 — Gap: No Privacy Enforcement on Likes/Comments

**Problem**: Neither `like-routes.ts` nor `comment-routes.ts` validates transaction privacy before
allowing a like or comment. The spec states: "Public Transactions Only" for likes, and comments
follow the same transaction privacy rules.

**Decision**: Implement privacy middleware or inline checks in route handlers that verify the
requesting user has access to the transaction (participant, contact, or public).

---

### Finding 7 — XState Machine Pattern

**Decision**: The `dataMachine` factory pattern is the canonical way to manage async data in this
app. Notifications use `notificationsMachine = dataMachine("notifications").withConfig(...)`.
The `transactionDetailMachine` handles likes and comments via `CREATE` events with an `entity`
discriminator (`"LIKE"` or `"COMMENT"`).

**Rationale**: This pattern is already established and should not be changed. New social feature
UI state (e.g., notification badge count) follows the same `dataMachine` pattern.

**Alternatives considered**: React Query, SWR — both rejected to maintain XState-only state management
(consistency principle) and avoid new production dependencies.

---

### Finding 8 — Seed Data Is Adequate

**Decision**: `data/database-seed.json` already contains 10 likes, 10 comments, and 40 notifications
(mix of payment, like, and comment types). No changes to seed shape are needed; only seed quantity
adjustments may be needed for edge-case tests.

---

### Finding 9 — Notification Ordering

**Decision**: `formatNotificationsForApiResponse` orders notifications by `modifiedAt` descending.
This aligns with the spec ("newest first") and requires no changes.

---

### Finding 10 — `userFullName` Denormalization

**Decision**: `formatNotificationForApiResponse` resolves `userFullName` at response-format time
by looking up the like's `userId`, the comment's `userId`, or the transaction's `senderId`. This
is a read-time join on lowdb, not stored redundantly. This is correct for the RWA's lowdb
architecture (no concern about data drift at educational scale).

---

## Phase 1: Design & Contracts

### Data Model

See `specs/004-social-features/data-model.md` (generated below).

#### Entity: Like

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `string` | Required, shortid | Primary key |
| `uuid` | `string` | Required, UUIDv4 | Globally unique |
| `userId` | `string` | Required, FK → User.id | Who liked |
| `transactionId` | `string` | Required, FK → Transaction.id | What was liked |
| `createdAt` | `Date` | Auto-set on create | ISO 8601 |
| `modifiedAt` | `Date` | Auto-set on create | ISO 8601 |

**Uniqueness constraint (business rule, enforced in `createLikes`)**: `(userId, transactionId)` pair must be unique.

#### Entity: Comment

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `string` | Required, shortid | Primary key |
| `uuid` | `string` | Required, UUIDv4 | Globally unique |
| `content` | `string` | Required, 1–500 chars, plain text | Comment body |
| `userId` | `string` | Required, FK → User.id | Author |
| `transactionId` | `string` | Required, FK → Transaction.id | Target |
| `createdAt` | `Date` | Auto-set | ISO 8601 |
| `modifiedAt` | `Date` | Auto-set | ISO 8601 |

**Ordering**: Read in `createdAt` ascending (chronological). No edit or delete.

#### Entity: Notification (discriminated union)

All notification variants share `NotificationBase`:

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `id` | `string` | Required, shortid | Primary key |
| `uuid` | `string` | Required, UUIDv4 | Globally unique |
| `userId` | `string` | Required, FK → User.id | Recipient |
| `transactionId` | `string` | Required, FK → Transaction.id | Context |
| `isRead` | `boolean` | Default: `false` | Read state |
| `createdAt` | `Date` | Auto-set | ISO 8601 |
| `modifiedAt` | `Date` | Auto-set | ISO 8601 |

**PaymentNotification** adds: `status: PaymentNotificationStatus` (`requested | received | incomplete`)  
**LikeNotification** adds: `likeId: string` (FK → Like.id)  
**CommentNotification** adds: `commentId: string` (FK → Comment.id)

**API Response** adds: `userFullName: string` (resolved at query time, not stored)

#### State Transition: Notification.isRead

```
[created] isRead=false
    │
    │  PATCH /notifications/:id { isRead: true }
    ▼
[dismissed] isRead=true  (terminal — no un-read, no delete)
```

#### Notification Trigger Map

```
Event                          │ Recipient(s)              │ Notification Type
───────────────────────────────┼───────────────────────────┼──────────────────
User A likes Transaction T     │ T.senderId (if ≠ User A)  │ LikeNotification
                               │ T.receiverId (if ≠ User A)│ LikeNotification
───────────────────────────────┼───────────────────────────┼──────────────────
User A comments on T           │ T.senderId (if ≠ User A)  │ CommentNotification
                               │ T.receiverId (if ≠ User A)│ CommentNotification
───────────────────────────────┼───────────────────────────┼──────────────────
User A requests payment from B │ T.receiverId (User B)     │ PaymentNotification(requested)
User B accepts/rejects request │ T.senderId (User A)       │ PaymentNotification(received/incomplete)
```

---

### API Contracts (summary — full contracts in `specs/004-social-features/contracts/`)

#### Likes

| Method | Path | Auth | Request Body | Success Response | Error Responses |
|--------|------|------|--------------|-----------------|-----------------|
| `GET` | `/likes/:transactionId` | Session required | — | `200 { likes: Like[] }` | `401`, `422` (invalid transactionId) |
| `POST` | `/likes/:transactionId` | Session required | — | `200` (empty body) | `401`, `404` (unknown tx), `403` (private tx), `422` |

**Idempotency**: POST is idempotent — duplicate likes from the same user are silently ignored (200 returned).

#### Comments

| Method | Path | Auth | Request Body | Success Response | Error Responses |
|--------|------|------|--------------|-----------------|-----------------|
| `GET` | `/comments/:transactionId` | Session required | — | `200 { comments: Comment[] }` | `401`, `422` |
| `POST` | `/comments/:transactionId` | Session required | `{ content: string }` | `200` (empty body) | `401`, `422` (empty/too-long content), `403` (private tx) |

#### Notifications

| Method | Path | Auth | Request Body | Success Response | Error Responses |
|--------|------|------|--------------|-----------------|-----------------|
| `GET` | `/notifications` | Session required | — | `200 { results: NotificationResponseItem[] }` | `401` |
| `POST` | `/notifications/bulk` | Session required | `{ items: NotificationPayloadType[] }` | `200 { results: NotificationType[] }` | `401`, `422` |
| `PATCH` | `/notifications/:notificationId` | Session required | `{ isRead: boolean }` | `204` (no body) | `401`, `422` |

---

### Design Decisions

#### Decision 1: Fix notification logic with individual `if` guards (not `if/else if/else`)

**Choice**: Replace the `if (userId !== senderId || userId !== receiverId)` tautology with two
independent `if (userId !== senderId)` and `if (userId !== receiverId)` guards.

**Rationale**: This is the simplest, most readable fix. It matches the spec's trigger table exactly:
both sender and receiver receive notifications **unless** they are the actor. Using two independent
`if` statements avoids the cognitive complexity of compound boolean conditions and is easier to
teach. The alternative — a single `if` with AND logic — would work mathematically, but is less
explicit about intent.

**Educational value**: Documents a classic logic-bug category (De Morgan's laws, tautology in guards).
The inline comment will explain the pitfall explicitly, making this a teaching moment.

---

#### Decision 2: Enforce idempotency at the database layer, not the route layer

**Choice**: Add the duplicate-check in `createLikes` (database layer), not in `like-routes.ts`.

**Rationale**: Routes should be thin orchestrators; business rules belong in the data layer.
This pattern is consistent with how `createTransaction` validates business rules (balance checks,
request-vs-payment logic) in `database.ts`. Tests can verify idempotency directly against the
database function, and the route handler stays clean.

---

#### Decision 3: Add content validation in `validators.ts`, not in the route or database layer

**Choice**: Extend `isCommentValidator` with `.notEmpty()` and `.isLength({ max: 500 })`.

**Rationale**: Input validation belongs in the validator middleware layer (express-validator pattern).
This is consistent with how all other route validations are structured in the app. The 500-character
limit matches spec guidance and is a teachable constraint for form validation.

---

#### Decision 4: Transaction privacy check via shared helper function

**Choice**: Create a `canAccessTransaction(userId, transactionId)` helper in `database.ts` that
checks whether a user is a sender, receiver, or contact with access. Call this from both
`like-routes.ts` and `comment-routes.ts` before creating the like/comment.

**Rationale**: Both likes and comments share the same privacy rules. Centralizing in one helper
avoids duplication and provides a single place to update if privacy rules change. This is an
educational demonstration of the DRY principle applied to authorization guards.

**Alternatives considered**: Adding privacy checks directly in route handlers — rejected because
it duplicates logic and scatters authorization concerns across files.

---

#### Decision 5: Remove `@ts-ignore` by fixing `createNotifications` return type

**Choice**: Update `createNotifications` in `database.ts` to return `NotificationType[]` by adding
an explicit else branch that throws (or returns an empty array for unknown types) rather than
implicitly returning `undefined`.

**Rationale**: Silencing TypeScript with `@ts-ignore` violates Principle 4 and teaches a bad habit.
The fix also makes the function's contract explicit — it should never return `undefined` items
for valid input.

---

#### Decision 6: No new XState machines — extend existing `dataMachine` pattern

**Choice**: All social feature state (notification badge count, like state, comment submission) is
managed through the existing `dataMachine`-based machines (`notificationsMachine`,
`transactionDetailMachine`).

**Rationale**: The XState machine pattern is already established and working. Adding a new machine
for likes or comments would fragment state management and require new plumbing.  The
`transactionDetailMachine` already handles like/comment creation via `CREATE` events with the
`entity` discriminator. The badge count is derived from `notificationsMachine.context.results.length`.

---

#### Decision 7: `userFullName` resolved at query time, not stored

**Choice**: Keep the current `formatNotificationForApiResponse` approach of looking up the actor's
name at read time from the `likes`, `comments`, or `transactions` table.

**Rationale**: In lowdb's flat-file architecture, denormalizing by copying `userFullName` into the
notification row would make updates to a user's name out-of-sync. Read-time resolution is trivially
cheap at educational scale (< 1000 rows) and demonstrates the "join at read time" pattern for
document stores.

---

## Complexity Tracking

No constitution violations that require justification. All work fits within the existing architecture.

---

## Implementation Work Items

The following items represent the gap between the current state and the spec. Listed in execution order.

### Bug Fixes (Highest Priority)

| ID | File | Description |
|----|------|-------------|
| BUG-01 | `backend/database.ts` | Fix `createLikes` notification logic — replace `\|\|` tautology with two independent `if` guards |
| BUG-02 | `backend/database.ts` | Fix `createComments` notification logic — same fix as BUG-01 |
| BUG-03 | `backend/database.ts` | Add idempotency check in `createLikes` — prevent duplicate likes from same user |

### Validation Gaps

| ID | File | Description |
|----|------|-------------|
| VAL-01 | `backend/validators.ts` | Extend `isCommentValidator` with `.notEmpty()` and `.isLength({ max: 500 })` |
| VAL-02 | `backend/database.ts` | Create `canAccessTransaction(userId, transactionId)` helper for privacy enforcement |
| VAL-03 | `backend/like-routes.ts` | Add privacy check using `canAccessTransaction` before `createLikes` |
| VAL-04 | `backend/comment-routes.ts` | Add privacy check using `canAccessTransaction` before `createComments` |

### Type Safety

| ID | File | Description |
|----|------|-------------|
| TYPE-01 | `backend/notification-routes.ts` | Remove `@ts-ignore`; fix `createNotifications` return type in `database.ts` |
| TYPE-02 | `src/machines/transactionDetailMachine.ts` | Replace `any` event types with proper discriminated union type |

### Documentation

| ID | File | Description |
|----|------|-------------|
| DOC-01 | `backend/database.ts` | Add TSDoc comments to all social feature DB helpers (createLike, createComment, createNotification family) |
| DOC-02 | `specs/004-social-features/quickstart.md` | Write developer quickstart for social features |
| DOC-03 | `specs/004-social-features/contracts/` | Write REST contract markdown files for likes, comments, notifications |

### Test Coverage Expansion

| ID | File | Description |
|----|------|-------------|
| TEST-01 | `cypress/tests/api/api-likes.spec.ts` | Add: idempotent POST (second like returns 200, no duplicate in DB), auth guard (401) |
| TEST-02 | `cypress/tests/api/api-comments.spec.ts` | Add: empty content 422, content > 500 chars 422, multiple comments on same tx, auth guard (401) |
| TEST-03 | `cypress/tests/api/api-notifications.spec.ts` | Add: unread-only scoping (no other user's notifs), mark-read removes from GET results, notification creation on like, notification creation on comment |
| TEST-04 | `cypress/tests/ui/notifications.spec.ts` | Validate existing spec scenarios pass: User A likes → User B gets notification with User A's name; User C likes A↔B tx → both A and B notified |
| TEST-05 | New: `cypress/tests/ui/transaction-social.spec.ts` | Like button disabled after click, like count increments, comment appears immediately, notification badge count updates |

---

## Post-Phase 1 Constitution Re-Check

After the design phase:

| Principle | Re-check Status |
|-----------|----------------|
| 3 (Testing) | ✅ All gaps addressed by TEST-01 through TEST-05 work items |
| 4 (TypeScript) | ✅ TYPE-01 removes `@ts-ignore`; TYPE-02 removes `any` |
| 10 (Documentation) | ✅ DOC-01 through DOC-03 address missing TSDoc and markdown docs |

All 10 principles satisfied after implementation of work items above.

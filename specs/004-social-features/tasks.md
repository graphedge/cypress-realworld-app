# Tasks: Social Features (Likes, Comments, Notifications)

**Feature**: `004-social-features` | **Branch**: `004-social-features`  
**Spec**: `specs/004-social-features/spec.md` | **Plan**: `specs/004-social-features/plan.md`  
**Generated**: 2025-01-15

**Approach**: Audit-first. Core infrastructure already exists. All work is correctional:
fix three confirmed bugs → add missing validations → remove type-safety violations → expand test coverage → document.

---

## Format: `[ID] [P?] [Story?] Description — file path`

- **[P]**: Safe to run in parallel (different files, no unresolved dependencies)
- **[US#]**: Maps to User Story (US1 = Likes, US2 = Comments, US3 = Notifications)
- Bug/gap IDs from plan (e.g., BUG-01, VAL-02) are noted in task descriptions for traceability

---

## User Stories

| ID  | Feature       | Priority | Goal                                                               |
|-----|---------------|----------|--------------------------------------------------------------------|
| US1 | Likes         | P1 🎯 MVP | One idempotent like per user per transaction, correctly notifies participants |
| US2 | Comments      | P2       | Non-empty validated comments, correctly notifies participants      |
| US3 | Notifications | P3       | Type-safe, recipient-scoped, accurately targeted notification delivery |

---

## Phase 1: Setup

> **Status**: No setup required. This is an existing full-stack TypeScript application.
> All route infrastructure, models, XState machines, and React components are already wired.
> Work begins at Phase 2.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Two shared building blocks that multiple user-story phases depend on.
Both must be complete before US1 privacy work (T-005) and US3 type-safety work (T-014) can proceed.

**⚠️ CRITICAL**: T-005 (US1), T-010 (US2), and T-014 (US3) are blocked until this phase is done.

- [ ] T-001 Implement `canAccessTransaction(userId, transactionId): boolean` helper in `backend/database.ts` — returns `true` if the user is the `senderId`, the `receiverId`, or a contact of either party on a non-private transaction (use `getTransactionById`, `DefaultPrivacyLevel`, `getContactIdsForUser`)

  **Acceptance criteria**:
  - Returns `true` when `userId === transaction.senderId`
  - Returns `true` when `userId === transaction.receiverId`
  - Returns `true` when `transaction.privacyLevel === DefaultPrivacyLevel.contacts` and `userId` is in contact list of sender or receiver (use `getContactIdsForUser`)
  - Returns `false` when `transaction.privacyLevel === DefaultPrivacyLevel.private` and user is not a participant
  - Returns `true` for any `DefaultPrivacyLevel.public` transaction (all authenticated users may see it)
  - Exported from `backend/database.ts` so routes can import it
  - Function has a TSDoc comment explaining the privacy rules it enforces

- [ ] T-002 Fix `createNotifications` return type in `backend/database.ts` (line ~767) to return `NotificationType[]` instead of `(NotificationType | undefined)[]` — add an explicit `else` branch that throws `new Error(\`Unknown notification type: \${item.type}\`)` when the discriminated union doesn't match any known type

  **Acceptance criteria**:
  - Function signature becomes `export const createNotifications = (...): NotificationType[]`
  - The innermost `if ("commentId" in item)` block is unwrapped — the outer `else if` for `NotificationsType.like` handles the `likeId` case and the final `else` handles `commentId` (or throws for unknown)
  - No implicit `undefined` can appear in the returned array — TypeScript infers the return type as `NotificationType[]` with no cast needed
  - The `@ts-ignore` in `backend/notification-routes.ts` (line 39) is removed in T-014 once this fix compiles
  - `yarn types` passes with zero errors after this change

**Checkpoint**: `canAccessTransaction` helper available; `createNotifications` return type clean → Phase 3 and Phase 5 can proceed.

---

## Phase 3: User Story 1 — Transaction Likes (Priority: P1) 🎯 MVP

**Goal**: Users can like a transaction exactly once. Duplicate POST requests are silently ignored (idempotent). Notifications go only to transaction participants who are *not* the person liking. Private transactions reject likes with `403`.

**Independent Test**:
1. Seed DB, POST a like on a public transaction → 200, one like in DB, one notification per non-liker participant
2. POST the same like again → 200, still only one like in DB (idempotency)
3. POST a like on a private transaction as a non-participant → 403
4. GET /likes/:transactionId → returns `{ likes: [...] }` array

### Implementation — User Story 1

- [ ] T-003 [US1] Fix `createLikes` notification tautology (BUG-01) in `backend/database.ts` (line ~628) — replace the single `if (userId !== senderId || userId !== receiverId)` block and its `else if`/`else` branches with two independent guards:
  ```typescript
  // Notify sender only if they are not the person liking
  if (userId !== senderId) {
    createLikeNotification(senderId, transactionId, like.id);
  }
  // Notify receiver only if they are not the person liking
  if (userId !== receiverId) {
    createLikeNotification(receiverId, transactionId, like.id);
  }
  ```
  Remove the `/* istanbul ignore next */` comment above the old block and replace it with an inline comment explaining the De Morgan's law pitfall this replaces (educational note per Principle 1).

  **Acceptance criteria**:
  - When User A likes a transaction where `senderId = B` and `receiverId = C`: two notifications created (for B and C), none for A
  - When User A (the sender) likes their own transaction: only one notification created (for receiver), none for sender
  - When User A (the receiver) likes a transaction: only one notification created (for sender), none for receiver
  - Old `else if`/`else` dead-code branches removed entirely
  - `yarn types` passes with zero errors

- [ ] T-004 [US1] Add idempotency check to `createLikes` in `backend/database.ts` (BUG-03) — insert a duplicate-check at the top of `createLikes` before calling `createLike`, using the existing `getLikesByObj` helper:
  ```typescript
  export const createLikes = (userId: string, transactionId: string) => {
    // Idempotency: silently no-op if this user already liked this transaction (spec rule: one like per user)
    const existing = getLikesByObj({ userId, transactionId });
    if (existing.length > 0) return;
    // ... rest of function
  };
  ```

  **Acceptance criteria**:
  - A second `createLikes(sameUserId, sameTransactionId)` call returns without creating a new `Like` record
  - A second `createLikes` call does NOT create additional notifications
  - A first `createLikes` call still creates the like and notifications as before
  - `getLikesByObj` (already exported) is used — no new helper needed

  **Dependencies**: T-003 (same function — apply after fixing the notification block)

- [ ] T-005 [US1] Add transaction privacy enforcement to `POST /likes/:transactionId` in `backend/like-routes.ts` — import `canAccessTransaction` from `./database` and add a guard before `createLikes`:
  ```typescript
  import { getLikesByTransactionId, createLikes, canAccessTransaction } from "./database";
  // ...
  router.post("/:transactionId", ensureAuthenticated, validateMiddleware([...]), (req, res) => {
    const { transactionId } = req.params;
    /* istanbul ignore next */
    if (!canAccessTransaction(req.user?.id!, transactionId)) {
      return res.sendStatus(403);
    }
    createLikes(req.user?.id!, transactionId);
    res.sendStatus(200);
  });
  ```

  **Acceptance criteria**:
  - POST to a public transaction → 200 (existing behavior unchanged)
  - POST to a private transaction where user is not sender/receiver → 403
  - POST to a private transaction where user IS sender or receiver → 200
  - POST to a contacts-level transaction by a contact → 200
  - `yarn types` passes with zero errors

  **Dependencies**: T-001 (`canAccessTransaction` must exist)

### Tests — User Story 1

- [ ] T-006 [P] [US1] Add idempotent POST test to `cypress/tests/api/api-likes.spec.ts` — within the existing `context("POST /likes/:transactionId")` block, add a test that POSTs the same like twice and asserts the DB has only one like for that `(userId, transactionId)` pair:
  ```typescript
  it("is idempotent — second POST does not create a duplicate like", function () {
    cy.request("POST", `${apiLikes}/${ctx.transactionId}`).then(() => {
      cy.request("POST", `${apiLikes}/${ctx.transactionId}`).then((response) => {
        expect(response.status).to.eq(200);
        cy.database("filter", "likes", { transactionId: ctx.transactionId }).then((likes: Like[]) => {
          // The seed already has 1 like; after two additional POSTs only 1 new like should exist
          const userLikes = likes.filter((l) => l.userId === ctx.authenticatedUser!.id);
          expect(userLikes).to.have.length(1);
        });
      });
    });
  });
  ```

  **Acceptance criteria**:
  - Test FAILS before T-004 is implemented (duplicate is created)
  - Test PASSES after T-004 is implemented

  **Dependencies**: T-004 (test verifies this bug fix)

- [ ] T-007 [P] [US1] Add unauthenticated 401 test to `cypress/tests/api/api-likes.spec.ts` — add a `context("Auth")` block after the existing contexts that issues a raw (no session) request and asserts 401:
  ```typescript
  context("Auth", function () {
    it("returns 401 when not authenticated", function () {
      cy.clearCookies();
      cy.request({ method: "POST", url: `${apiLikes}/${ctx.transactionId}`, failOnStatusCode: false })
        .its("status").should("eq", 401);
      cy.request({ method: "GET", url: `${apiLikes}/${ctx.transactionId}`, failOnStatusCode: false })
        .its("status").should("eq", 401);
    });
  });
  ```

  **Acceptance criteria**:
  - Both GET and POST return 401 when no session cookie is present
  - Test is deterministic and does not affect other tests (no shared session state)

- [ ] T-008 [P] [US1] Add privacy enforcement test to `cypress/tests/api/api-likes.spec.ts` — add a test that fetches a private transaction not owned by the authenticated user and asserts POST returns 403:
  ```typescript
  it("returns 403 when liking a private transaction the user does not own", function () {
    cy.database("filter", "transactions", { privacyLevel: "private" }).then((txns: Transaction[]) => {
      const privateNotMine = txns.find(
        (t) => t.senderId !== ctx.authenticatedUser!.id && t.receiverId !== ctx.authenticatedUser!.id
      );
      cy.wrap(privateNotMine).should("exist");
      cy.request({
        method: "POST",
        url: `${apiLikes}/${privateNotMine!.id}`,
        failOnStatusCode: false,
      }).its("status").should("eq", 403);
    });
  });
  ```
  Import `Transaction` from `"../../../src/models"` at top of file.

  **Acceptance criteria**:
  - Test FAILS before T-005 is implemented (no privacy check, returns 200)
  - Test PASSES after T-005 is implemented

  **Dependencies**: T-005 (test verifies this gap fix)

**Checkpoint**: `POST /likes` is idempotent, correctly notifies, and enforces privacy. All three new tests pass.

---

## Phase 4: User Story 2 — Transaction Comments (Priority: P2)

**Goal**: Users can leave text comments on transactions. Comments require non-empty content (max 500 chars). Notifications go only to transaction participants who are *not* the commenter. Private transactions reject comments with `403`.

**Independent Test**:
1. POST a comment with `"content": "Hello"` → 200, comment persists, notifications created for non-commenter participants
2. POST a comment with `"content": ""` → 422
3. POST a comment with 501-character content → 422
4. POST a comment on a private transaction as non-participant → 403

### Implementation — User Story 2

- [ ] T-009 [US2] Fix `createComments` notification tautology (BUG-02) in `backend/database.ts` (line ~675) — apply the identical two-independent-guards fix from T-003 to `createComments`:
  ```typescript
  // Notify sender only if they are not the commenter
  if (userId !== senderId) {
    createCommentNotification(senderId, transactionId, comment.id);
  }
  // Notify receiver only if they are not the commenter
  if (userId !== receiverId) {
    createCommentNotification(receiverId, transactionId, comment.id);
  }
  ```
  Remove the old `/* istanbul ignore next */` comment and add an inline educational note referencing BUG-02.

  **Acceptance criteria**:
  - Same trigger semantics as T-003 but for comments: both sender and receiver notified unless they are the commenter
  - When commenter is the sender: only receiver notified
  - When commenter is the receiver: only sender notified
  - Old `else if`/`else` branches removed
  - `yarn types` passes

- [ ] T-010 [P] [US2] Extend `isCommentValidator` in `backend/validators.ts` with `.notEmpty()` and `.isLength({ max: 500 })` (VAL-01):
  ```typescript
  // BEFORE: export const isCommentValidator = body("content").isString().trim();
  export const isCommentValidator = body("content")
    .isString()
    .trim()
    .notEmpty()                  // Spec rule: content is required; empty strings are invalid
    .isLength({ max: 500 });     // Spec rule: max 500 characters per spec section "Content Constraints"
  ```

  **Acceptance criteria**:
  - `body("content")` with `""` now produces a validation error → route returns `422`
  - `body("content")` with a 501-character string → route returns `422`
  - `body("content")` with `"Valid comment"` → no validation error, route proceeds to `createComments`
  - `yarn types` passes (no type changes needed — express-validator API)
  - Existing passing comment test (`"This is my comment"`) still returns `200`

- [ ] T-011 [US2] Add transaction privacy enforcement to `POST /comments/:transactionId` in `backend/comment-routes.ts` — import `canAccessTransaction` from `./database` and add the same guard pattern used in T-005:
  ```typescript
  import { getCommentsByTransactionId, createComments, canAccessTransaction } from "./database";
  // ...
  router.post("/:transactionId", ensureAuthenticated, validateMiddleware([...]), (req, res) => {
    const { transactionId } = req.params;
    const { content } = req.body;
    /* istanbul ignore next */
    if (!canAccessTransaction(req.user?.id!, transactionId)) {
      return res.sendStatus(403);
    }
    createComments(req.user?.id!, transactionId, content);
    res.sendStatus(200);
  });
  ```

  **Acceptance criteria**:
  - POST comment to public transaction → 200 (existing behaviour unchanged)
  - POST comment to private transaction where user is not sender/receiver → 403
  - POST comment to private transaction where user IS sender or receiver → 200
  - `yarn types` passes

  **Dependencies**: T-001 (`canAccessTransaction` must exist)

### Tests — User Story 2

- [ ] T-012 [P] [US2] Add empty-content 422 test to `cypress/tests/api/api-comments.spec.ts` — within the existing `context("POST /comments/:transactionId")` block:
  ```typescript
  it("returns 422 when content is empty", function () {
    cy.request({
      method: "POST",
      url: `${apiComments}/${ctx.transactionId}`,
      body: { content: "" },
      failOnStatusCode: false,
    }).its("status").should("eq", 422);
  });
  ```

  **Acceptance criteria**:
  - Test FAILS before T-010 (empty string currently accepted → 200)
  - Test PASSES after T-010

  **Dependencies**: T-010

- [ ] T-013 [P] [US2] Add over-limit content 422 test to `cypress/tests/api/api-comments.spec.ts`:
  ```typescript
  it("returns 422 when content exceeds 500 characters", function () {
    const longContent = "a".repeat(501);
    cy.request({
      method: "POST",
      url: `${apiComments}/${ctx.transactionId}`,
      body: { content: longContent },
      failOnStatusCode: false,
    }).its("status").should("eq", 422);
  });
  ```

  **Acceptance criteria**:
  - Test FAILS before T-010 (501-char string currently accepted)
  - Test PASSES after T-010

  **Dependencies**: T-010

- [ ] T-014 [P] [US2] Add unauthenticated 401 test to `cypress/tests/api/api-comments.spec.ts` — same pattern as T-007, covering GET and POST:
  ```typescript
  context("Auth", function () {
    it("returns 401 when not authenticated", function () {
      cy.clearCookies();
      cy.request({ method: "GET", url: `${apiComments}/${ctx.transactionId}`, failOnStatusCode: false })
        .its("status").should("eq", 401);
      cy.request({
        method: "POST",
        url: `${apiComments}/${ctx.transactionId}`,
        body: { content: "test" },
        failOnStatusCode: false,
      }).its("status").should("eq", 401);
    });
  });
  ```

  **Acceptance criteria**:
  - Both endpoints return 401 without a session
  - No side effects on authenticated tests

- [ ] T-015 [P] [US2] Add privacy enforcement test to `cypress/tests/api/api-comments.spec.ts` — mirrors T-008 for comments; fetches a private transaction not owned by the test user and asserts 403:
  ```typescript
  it("returns 403 when commenting on a private transaction the user does not own", function () {
    cy.database("filter", "transactions", { privacyLevel: "private" }).then((txns: Transaction[]) => {
      const privateNotMine = txns.find(
        (t) => t.senderId !== ctx.authenticatedUser!.id && t.receiverId !== ctx.authenticatedUser!.id
      );
      cy.wrap(privateNotMine).should("exist");
      cy.request({
        method: "POST",
        url: `${apiComments}/${privateNotMine!.id}`,
        body: { content: "sneaky comment" },
        failOnStatusCode: false,
      }).its("status").should("eq", 403);
    });
  });
  ```
  Import `Transaction` from `"../../../src/models"` at top of file.

  **Acceptance criteria**:
  - Test FAILS before T-011 (no privacy check → 200)
  - Test PASSES after T-011

  **Dependencies**: T-011

**Checkpoint**: `POST /comments` validates content length/emptiness, enforces privacy, and correctly notifies. All five new tests pass.

---

## Phase 5: User Story 3 — Notifications (Priority: P3)

**Goal**: Notifications are type-safe (`@ts-ignore` removed), recipient-scoped (users only see their own), and accurately targeted (like/comment events create correct notifications per the trigger map in the spec).

**Independent Test**:
1. GET /notifications → returns only unread notifications for the authenticated user (not other users')
2. PATCH /notifications/:id with `{ "isRead": true }` → 204; subsequent GET omits that notification
3. POST like → notification created for the right recipient (not the liker)
4. POST comment → notifications created for both non-commenter participants

### Implementation — User Story 3

- [ ] T-016 [US3] Remove `@ts-ignore` from `backend/notification-routes.ts` (line 39) — this is now valid once T-002 fixes `createNotifications` return type; delete the `// @ts-ignore` line and verify `res.json({ results: notifications })` compiles cleanly:
  ```typescript
  // BEFORE:
  // @ts-ignore
  res.json({ results: notifications });

  // AFTER (just delete the @ts-ignore line):
  res.json({ results: notifications });
  ```

  **Acceptance criteria**:
  - `// @ts-ignore` line is deleted from `backend/notification-routes.ts`
  - `yarn types` passes with zero errors
  - No runtime behavior change — only type annotation corrected

  **Dependencies**: T-002 (`createNotifications` must return `NotificationType[]` before this compiles)

- [ ] T-017 [P] [US3] Replace `any` event types in `src/machines/transactionDetailMachine.ts` (TYPE-02) — identify the event type(s) using `any` and replace with a proper discriminated union. Based on the plan, the `CREATE` event with an `entity` discriminator (`"LIKE"` or `"COMMENT"`) is the location. Add an explicit `TransactionDetailEvent` union type:
  ```typescript
  type CreateLikeEvent = { type: "CREATE"; entity: "LIKE"; transactionId: string };
  type CreateCommentEvent = { type: "CREATE"; entity: "COMMENT"; transactionId: string; content: string };
  type TransactionDetailEvent = CreateLikeEvent | CreateCommentEvent | /* other events */;
  ```
  Apply the union to the machine's generic parameter and remove all `any` event type usages.

  **Acceptance criteria**:
  - Zero `any` usages remain in `src/machines/transactionDetailMachine.ts`
  - `yarn types` passes with zero errors
  - No change to XState machine runtime behaviour (type-only change)
  - Inline TSDoc comment on the event union explains the `entity` discriminator pattern

### Tests — User Story 3

- [ ] T-018 [P] [US3] Add recipient-scoping test to `cypress/tests/api/api-notifications.spec.ts` — add a test that logs in as User A, seeds data, then fetches `/notifications` and asserts every returned notification's `userId` matches User A's ID:
  ```typescript
  it("returns only notifications belonging to the authenticated user", function () {
    cy.loginByApi(ctx.authenticatedUser!.username).then(() => {
      cy.request("GET", `${Cypress.env("apiUrl")}/notifications`).then((response) => {
        expect(response.status).to.eq(200);
        response.body.results.forEach((n: NotificationResponseItem) => {
          expect(n.userId).to.eq(ctx.authenticatedUser!.id);
        });
      });
    });
  });
  ```
  Import `NotificationResponseItem` from `"../../../src/models"`.

  **Acceptance criteria**:
  - All returned notifications have `userId === authenticatedUser.id`
  - Test is deterministic (uses `cy.task("db:seed")` in `beforeEach` — already present)

- [ ] T-019 [P] [US3] Add mark-read-removes-from-GET test to `cypress/tests/api/api-notifications.spec.ts` — find an unread notification, PATCH it to `isRead: true`, then verify GET omits it:
  ```typescript
  it("excludes notifications marked as read from GET /notifications", function () {
    cy.database("find", "notifications", { userId: ctx.authenticatedUser!.id, isRead: false })
      .then((notification: Notification) => {
        cy.request("PATCH", `${Cypress.env("apiUrl")}/notifications/${notification.id}`, {
          isRead: true,
        }).its("status").should("eq", 204);

        cy.request("GET", `${Cypress.env("apiUrl")}/notifications`).then((response) => {
          const ids = response.body.results.map((n: Notification) => n.id);
          expect(ids).not.to.include(notification.id);
        });
      });
  });
  ```

  **Acceptance criteria**:
  - After PATCH → 204; GET no longer includes the patched notification
  - Other unread notifications remain present
  - `cy.task("db:seed")` in `beforeEach` guarantees a clean slate

- [ ] T-020 [P] [US3] Add notification-on-like test to `cypress/tests/api/api-notifications.spec.ts` — POST a like as User A on a transaction owned by User B, then verify User B gains a new unread notification. Uses `cy.loginByApi` to switch sessions:
  ```typescript
  it("creates a like notification for the transaction sender after a like", function () {
    // Find a public transaction where authenticatedUser is NOT the sender
    cy.database("filter", "transactions", { privacyLevel: "public" }).then((txns: Transaction[]) => {
      const target = txns.find((t) => t.senderId !== ctx.authenticatedUser!.id);
      cy.wrap(target).should("exist");

      // Count sender's current notifications
      cy.database("filter", "notifications", { userId: target!.senderId, isRead: false })
        .then((before: Notification[]) => {
          // Like the transaction as authenticatedUser
          cy.request("POST", `${Cypress.env("apiUrl")}/likes/${target!.id}`);

          // Verify sender has one more notification
          cy.database("filter", "notifications", { userId: target!.senderId, isRead: false })
            .then((after: Notification[]) => {
              expect(after.length).to.eq(before.length + 1);
              const newNotif = after.find((n) => !before.map((b) => b.id).includes(n.id));
              expect(newNotif).to.have.property("transactionId", target!.id);
            });
        });
    });
  });
  ```
  Import `Transaction`, `Notification` from `"../../../src/models"` at top of file.

  **Acceptance criteria**:
  - Test FAILS before T-003 (tautology creates extra notifications or wrong recipient)
  - Test PASSES after T-003 and T-004

  **Dependencies**: T-003, T-004

- [ ] T-021 [P] [US3] Add notification-on-comment test to `cypress/tests/api/api-notifications.spec.ts` — POST a comment as User A on a transaction with both sender and receiver, verify both the sender and receiver gain new unread notifications, but User A does not:
  ```typescript
  it("creates comment notifications for both participants but not the commenter", function () {
    cy.database("filter", "transactions", { privacyLevel: "public" }).then((txns: Transaction[]) => {
      const target = txns.find(
        (t) => t.senderId !== ctx.authenticatedUser!.id && t.receiverId !== ctx.authenticatedUser!.id
      );
      cy.wrap(target).should("exist");

      cy.database("filter", "notifications", { userId: target!.senderId, isRead: false })
        .then((senderBefore: Notification[]) => {
          cy.database("filter", "notifications", { userId: target!.receiverId, isRead: false })
            .then((receiverBefore: Notification[]) => {
              cy.database("filter", "notifications", { userId: ctx.authenticatedUser!.id, isRead: false })
                .then((commenterBefore: Notification[]) => {
                  cy.request("POST", `${Cypress.env("apiUrl")}/comments/${target!.id}`, {
                    content: "Testing notification targeting",
                  });

                  cy.database("filter", "notifications", { userId: target!.senderId, isRead: false })
                    .its("length").should("eq", senderBefore.length + 1);
                  cy.database("filter", "notifications", { userId: target!.receiverId, isRead: false })
                    .its("length").should("eq", receiverBefore.length + 1);
                  cy.database("filter", "notifications", { userId: ctx.authenticatedUser!.id, isRead: false })
                    .its("length").should("eq", commenterBefore.length); // no self-notification
                });
            });
        });
    });
  });
  ```

  **Acceptance criteria**:
  - Test FAILS before T-009 (tautology creates self-notification for commenter)
  - Test PASSES after T-009
  - Sender and receiver each gain exactly 1 new notification; commenter count unchanged

  **Dependencies**: T-009

- [ ] T-022 [US3] Validate existing UI notification scenarios in `cypress/tests/ui/notifications.spec.ts` — run the existing test suite end-to-end and confirm all tests pass now that the tautology bugs (T-003, T-009) are fixed. If any tests relied on the buggy behaviour (both parties always notified), update assertions to match the correct trigger map from the spec:
  ```
  Trigger map (spec §Notification Triggers):
    Like   → notify senderId (if ≠ liker) AND receiverId (if ≠ liker)
    Comment → notify senderId (if ≠ commenter) AND receiverId (if ≠ commenter)
  ```
  Do not change test logic beyond correcting wrong notification-count or recipient assertions that were incorrect before.

  **Acceptance criteria**:
  - `yarn cypress:run --spec "cypress/tests/ui/notifications.spec.ts"` exits 0
  - Any previously-passing tests that tested buggy tautology behaviour are updated to reflect correct targeting
  - No new test cases added here (TEST-04 scope only — new UI tests go in T-023)

  **Dependencies**: T-003, T-009 (bug fixes that change notification counts)

**Checkpoint**: `@ts-ignore` removed, `any` types eliminated, all notification-targeting tests pass.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: New UI test for social interaction UX, TSDoc documentation for all social DB helpers, and developer-facing markdown docs.

- [ ] T-023 [P] Create `cypress/tests/ui/transaction-social.spec.ts` with UI interaction tests (TEST-05) covering: like button disables after click, like count increments by 1, comment text appears immediately after form submit, notification badge count updates when a like or comment is created. Use `cy.getBySel()` / `cy.getBySelLike()` canonical commands per Principle 5. Follow seed-and-find pattern (`cy.task("db:seed")` + `cy.database("find", "transactions")` to pick a public transaction):

  **Acceptance criteria**:
  - Like button has `data-testid` attribute matched by `cy.getBySel("like-button")` (confirm or add the attribute in `src/components/TransactionDetail.tsx` if missing)
  - Like count displayed with `data-testid="transaction-like-count"` increments after click
  - Comment form submits and the new comment row appears in the `data-testid="comments-list"` within the same test (no page reload needed — XState machine updates state)
  - Notification badge reflects unread count from `notificationsMachine` context

- [ ] T-024 [P] Add TSDoc comments to all social feature database helpers in `backend/database.ts` (DOC-01) — add `/** ... */` JSDoc blocks to: `createLike`, `createLikes`, `getLikesByTransactionId`, `createComment`, `createComments`, `getCommentsByTransactionId`, `createPaymentNotification`, `createLikeNotification`, `createCommentNotification`, `createNotifications`, `getUnreadNotificationsByUserId`, `updateNotificationById`, `formatNotificationForApiResponse`, `canAccessTransaction` (added in T-001). Each comment must explain: what the function does, its parameters, its return value, and any side effects (e.g., "Creates a LikeNotification for recipient; does not create a notification if recipient is the actor"):

  **Acceptance criteria**:
  - All 14 functions listed above have `/** */` TSDoc blocks
  - Parameter descriptions use `@param` tags
  - Return descriptions use `@returns` tags
  - Side-effect descriptions (notification creation) are noted with an `@sideEffects` comment or inline prose
  - `yarn types` still passes (TSDoc does not affect type checking)

- [ ] T-025 [P] Write `specs/004-social-features/quickstart.md` (DOC-02) — developer guide covering: how to start the app locally, how to test likes/comments/notifications via curl or the UI, how to run the relevant Cypress specs in isolation (`--spec` flag), how the seed data is structured for social features (10 likes, 10 comments, 40 notifications in `data/database-seed.json`), and a common debugging FAQ (e.g., "why does a like not create a notification?" → check privacy level):

  **Acceptance criteria**:
  - Quickstart file exists at `specs/004-social-features/quickstart.md`
  - Contains ≥ 4 headings: Overview, Starting Locally, Testing Social Features, Seed Data
  - Includes runnable `curl` examples for all six social endpoints (GET + POST likes, GET + POST comments, GET notifications, PATCH notifications)
  - Includes Cypress run commands for all four spec files
  - Includes a Debugging section explaining the three bugs fixed in this feature and how the fixes work

- [ ] T-026 [P] Write `specs/004-social-features/contracts/likes.md` (DOC-03a) — REST contract for GET and POST `/likes/:transactionId`, including: HTTP method, path, auth requirement, path params, request body (none for likes), success response shape (`{ likes: Like[] }`), all error codes and their causes (401, 403, 404, 422), idempotency guarantee, and the notification side-effect:

  **Acceptance criteria**:
  - File exists at `specs/004-social-features/contracts/likes.md`
  - Covers both GET and POST
  - Documents idempotency guarantee added in T-004
  - Documents privacy enforcement added in T-005

- [ ] T-027 [P] Write `specs/004-social-features/contracts/comments.md` (DOC-03b) — REST contract for GET and POST `/comments/:transactionId` using the same structure as T-026, including the content validation constraints (non-empty, max 500 chars) added in T-010 and the privacy enforcement from T-011:

  **Acceptance criteria**:
  - File exists at `specs/004-social-features/contracts/comments.md`
  - Documents the `content` field constraints (required, 1–500 chars, plain text)
  - Documents privacy enforcement
  - Documents notification side-effect (sender and receiver notified unless commenter)

- [ ] T-028 [P] Write `specs/004-social-features/contracts/notifications.md` (DOC-03c) — REST contract for all three notification endpoints (GET `/notifications`, POST `/notifications/bulk`, PATCH `/notifications/:notificationId`), including: the three notification types (Payment/Like/Comment) with their discriminated fields, the `userFullName` field and how it is resolved at query time, the `isRead` state machine (`false → true` terminal), and the recipient-scoping guarantee:

  **Acceptance criteria**:
  - File exists at `specs/004-social-features/contracts/notifications.md`
  - Covers all three endpoints
  - Includes the notification type discriminated union table
  - Documents the Notification Trigger Map from the spec (Like/Comment/Payment triggers → recipients)
  - Notes that `userFullName` is resolved at read time (not stored), per Decision 7 in the plan

**Checkpoint**: All documentation complete, UI test suite passes, `yarn types` clean throughout.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 2 (Foundational)
    ├── T-001 (canAccessTransaction)  ←── blocks T-005, T-011
    └── T-002 (createNotifications type fix)  ←── blocks T-016

Phase 3 (US1 — Likes)          Phase 4 (US2 — Comments)      Phase 5 (US3 — Notifications)
    T-003 (tautology fix)           T-009 (tautology fix)         T-016 (ts-ignore) ← T-002
    T-004 (idempotency) ← T-003     T-010 [P] (validator)         T-017 [P] (any types)
    T-005 (privacy) ← T-001         T-011 (privacy) ← T-001       T-018 [P] (scope test)
    T-006 [P] (idempotency test) ← T-004   T-012 [P] ← T-010      T-019 [P] (mark-read test)
    T-007 [P] (auth 401 test)       T-013 [P] ← T-010             T-020 [P] ← T-003, T-004
    T-008 [P] (privacy test) ← T-005  T-014 [P] (auth 401 test)   T-021 [P] ← T-009
                                    T-015 [P] (privacy test) ← T-011  T-022 ← T-003, T-009

Phase 6 (Polish — all independent after Phase 3–5 complete)
    T-023 [P]  T-024 [P]  T-025 [P]  T-026 [P]  T-027 [P]  T-028 [P]
```

### User Story Dependencies

- **US1 (Likes, P1)**: Can begin immediately after Phase 2. No dependency on US2 or US3.
- **US2 (Comments, P2)**: Can begin immediately after Phase 2. T-009 shares `database.ts` with T-003 — implement sequentially if same developer, or parallel if different developers.
- **US3 (Notifications, P3)**: Can begin after Phase 2 (T-016 needs T-002). T-020/T-021 (notification tests) need T-003 and T-009 to be correct first.

### Intra-Story Task Order

```
US1:  T-001 → T-003 → T-004 → T-005
               ↓         ↓      ↓
              T-006    T-007   T-008   (all parallel after their dep)

US2:  T-001 → T-011
      T-009
      T-010 → T-012, T-013            (T-012/T-013 parallel after T-010)
              T-014, T-015 ← T-011    (T-015 needs T-011)

US3:  T-002 → T-016
      T-017 (parallel, independent)
      T-018, T-019 (parallel, independent)
      T-020 ← T-003, T-004
      T-021 ← T-009
      T-022 ← T-003, T-009
```

---

## Parallel Execution Examples

### Parallel: Phase 2

```bash
# Both can run simultaneously (different functions/exports)
Task: "T-001 — Implement canAccessTransaction in backend/database.ts"
Task: "T-002 — Fix createNotifications return type in backend/database.ts"
# NOTE: T-001 and T-002 edit the same file. Coordinate line ranges or use sequential tasks.
# Recommended: do T-001 first (new export at bottom), T-002 second (edit existing function).
```

### Parallel: US1 Tests (after T-004 and T-005 complete)

```bash
Task: "T-006 — Idempotent POST test in api-likes.spec.ts"
Task: "T-007 — Auth 401 test in api-likes.spec.ts"
Task: "T-008 — Privacy 403 test in api-likes.spec.ts"
```

### Parallel: US2 Implementation (after T-001 completes)

```bash
Task: "T-009 — Fix createComments tautology in database.ts"
Task: "T-010 — Extend isCommentValidator in validators.ts"
Task: "T-011 — Add privacy check to comment-routes.ts"  # waits for T-001 only
```

### Parallel: Polish Phase

```bash
# All six tasks touch different files with no inter-dependencies
Task: "T-023 — Create transaction-social.spec.ts"
Task: "T-024 — Add TSDoc to database.ts social helpers"
Task: "T-025 — Write quickstart.md"
Task: "T-026 — Write contracts/likes.md"
Task: "T-027 — Write contracts/comments.md"
Task: "T-028 — Write contracts/notifications.md"
```

---

## Implementation Strategy

### MVP First (US1 — Likes Only)

1. Complete Phase 2: T-001, T-002
2. Complete Phase 3: T-003 → T-004 → T-005, then T-006, T-007, T-008 in parallel
3. **STOP and VALIDATE**:
   ```bash
   yarn types
   yarn cypress:run --spec "cypress/tests/api/api-likes.spec.ts"
   ```
4. Likes are now bug-free, idempotent, privacy-enforced, and tested independently.

### Incremental Delivery

1. **Foundation** (T-001, T-002) → shared helpers ready
2. **US1 complete** (T-003–T-008) → Likes fully hardened → validate independently
3. **US2 complete** (T-009–T-015) → Comments fully hardened → validate independently
4. **US3 complete** (T-016–T-022) → Notifications type-safe and tested → validate independently
5. **Polish** (T-023–T-028) → docs and UI tests → full `yarn cypress:run` green

### Parallel Team Strategy (3 developers, post-Phase 2)

```
Developer A: US1 (T-003 → T-004 → T-005 → T-006/T-007/T-008)
Developer B: US2 (T-009/T-010 → T-011 → T-012/T-013/T-014/T-015)
Developer C: US3 (T-016 → T-017/T-018/T-019/T-020/T-021/T-022)
```
All three merge after Phase 3–5 and then collaborate on Polish (T-023–T-028).

---

## Summary

| Phase | Tasks | Stories | Key Deliverable |
|-------|-------|---------|-----------------|
| Foundational | T-001 – T-002 | — | `canAccessTransaction` helper; `createNotifications` return type clean |
| US1 Likes | T-003 – T-008 | US1 | Tautology fixed, idempotency enforced, privacy gated, 3 new API tests |
| US2 Comments | T-009 – T-015 | US2 | Tautology fixed, validator hardened, privacy gated, 5 new API tests |
| US3 Notifications | T-016 – T-022 | US3 | `@ts-ignore` removed, `any` types eliminated, 5 new API tests, UI validation |
| Polish | T-023 – T-028 | — | UI interaction test, TSDoc on 14 DB helpers, quickstart + 3 contract docs |
| **Total** | **28 tasks** | **3 stories** | All 10 Constitution principles satisfied |

### Bug + Gap Resolution Map

| Plan ID | Severity | Task(s) | File(s) |
|---------|----------|---------|---------|
| BUG-01 | HIGH | T-003 | `backend/database.ts` |
| BUG-02 | HIGH | T-009 | `backend/database.ts` |
| BUG-03 | HIGH | T-004 | `backend/database.ts` |
| VAL-01 | MEDIUM | T-010 | `backend/validators.ts` |
| VAL-02 | MEDIUM | T-001 | `backend/database.ts` |
| VAL-03 | MEDIUM | T-005 | `backend/like-routes.ts` |
| VAL-04 | MEDIUM | T-011 | `backend/comment-routes.ts` |
| TYPE-01 | MEDIUM | T-002, T-016 | `backend/database.ts`, `backend/notification-routes.ts` |
| TYPE-02 | MEDIUM | T-017 | `src/machines/transactionDetailMachine.ts` |
| TEST-01 | — | T-006, T-007, T-008 | `cypress/tests/api/api-likes.spec.ts` |
| TEST-02 | — | T-012, T-013, T-014, T-015 | `cypress/tests/api/api-comments.spec.ts` |
| TEST-03 | — | T-018, T-019, T-020, T-021 | `cypress/tests/api/api-notifications.spec.ts` |
| TEST-04 | — | T-022 | `cypress/tests/ui/notifications.spec.ts` |
| TEST-05 | — | T-023 | `cypress/tests/ui/transaction-social.spec.ts` |
| DOC-01 | — | T-024 | `backend/database.ts` |
| DOC-02 | — | T-025 | `specs/004-social-features/quickstart.md` |
| DOC-03 | — | T-026, T-027, T-028 | `specs/004-social-features/contracts/` |

---

## Notes

- `[P]` tasks = different files or independently scoped — safe for parallel execution
- `database.ts` edits (T-001, T-002, T-003, T-004, T-009, T-024) touch the same file — coordinate edits or apply sequentially to avoid merge conflicts
- All tests MUST use `cy.task("db:seed")` in `beforeEach` (Principle 6) — do not add tests that skip seeding
- All new TypeScript MUST pass `yarn types` — run after each backend task
- `cy.getBySel()` is the canonical selector helper (Principle 5) — use it in T-023, not raw `cy.get("[data-testid=...]")`
- Commit after each logical group (one phase or one story's implementation block)
- Stop at each **Checkpoint** to run the relevant spec in isolation before advancing

SPECKIT_SPEC.md
===============

Repository: cypress-realworld-app
Path: /home/brett/projects/cypress-realworld-app
Generated: 2026-03-31

Summary
-------

This document inventories the main features (UI pages, backend REST/GraphQL endpoints, and major modules) in the Cypress Real‑World App and specifies contracts, data shapes, tests that exercise them, and coverage gaps.

Top features (prioritized)
- Core auth (Sign up / Sign in)
  - Allow new users to register and existing users to sign in; return stable auth token/session; surface user profile data.
- Article CRUD with public/private visibility
  - Create, read, update, delete articles; list articles (paginated); support article drafts and published states.
- Comments on articles
  - Allow authenticated users to add and delete comments on articles; comments visible on the article page.
- Profiles and following
  - View user profiles; follow/unfollow other users; profile shows authored articles and follower counts.
- Search & Filters
  - Search articles by tag, author, or keyword; filter and sort result lists; return counts and pagination metadata.
- Client-side persistence of auth
  - Safely persist authenticated session client-side (token) and expose current user to UI flows.
- Error & Validation surfaces
  - Consistent presentation of validation errors for forms and meaningful error states in lists and detail pages.
- Test coverage hooks
  - Mapping of features to E2E/Cypress test files to ensure high-level flows are covered: auth flows, article flows, comment flows.

Contracts (feature-level, technology-agnostic)
- Contract naming: [Feature] — [Contract Type] — [Inputs] => [Outputs] (preconditions / postconditions / error cases)

1) Authentication — REST-like contract (UI / client contract)
   - SignUp
     - Inputs: { username: string, email: string, password: string }
     - Outputs (success): { user: UserShape, token: string }
     - Preconditions: email and username unique, password meets strength policy
     - Postconditions: user created, token issued, user considered authenticated
     - Errors: 400 validation errors (field-specific), 409 conflict (email/username taken), 500 server error
   - SignIn
     - Inputs: { email: string, password: string }
     - Outputs (success): { user: UserShape, token: string }
     - Preconditions: user exists, password correct
     - Errors: 401 unauthorized (wrong credentials), 400 validation, 500 server error

2) Article management — REST-like contract
   - CreateArticle
     - Inputs: { title: string, body: string, description?: string, tags?: string[], visibility?: "draft"|"published" }
     - Outputs: { article: ArticleShape }
     - Preconditions: authenticated user
     - Errors: 400 validation, 401 unauthorized
   - GetArticle
     - Inputs: { slug: string }
     - Outputs: { article: ArticleShape (includes author profile, comments count) }
     - Error: 404 not found
   - UpdateArticle
     - Inputs: { slug: string, updates: Partial<ArticleCreateShape> }
     - Outputs: { article: ArticleShape }
     - Preconditions: authenticated & author
     - Errors: 403 forbidden, 400 validation
   - DeleteArticle
     - Inputs: { slug: string }
     - Outputs: { success: true }
     - Preconditions: authenticated & author
     - Errors: 403, 404

3) Commenting — REST-like contract
   - AddComment
     - Inputs: { articleSlug: string, body: string }
     - Outputs: { comment: CommentShape }
     - Preconditions: authenticated
     - Errors: 400 validation, 401 unauthorized
   - DeleteComment
     - Inputs: { articleSlug: string, commentId: string }
     - Outputs: { success: true }
     - Preconditions: authenticated & comment owner or article owner (depending on policy)
     - Errors: 403, 404

4) Profiles & Follow — REST-like contract
   - GetProfile
     - Inputs: { username: string }
     - Outputs: { profile: ProfileShape } (includes following boolean relative to current user)
   - Follow / Unfollow
     - Inputs: { username: string }
     - Outputs: { profile: ProfileShape } (updated)
     - Preconditions: authenticated
     - Errors: 401 unauthorized, 404 user not found

5) Listing & Search — Query contract
   - ListArticles
     - Inputs (query): { tag?: string, author?: string, favorited?: string, limit?: number, offset?: number, q?: string }
     - Outputs: { articles: ArticleShape[], articlesCount: number, page: { limit:number, offset:number } }
     - Errors: 400 invalid params

Contracts notes:
- All responses include a consistent error wrapper: { errors: { field?: string[] | string } } or { message: string } depending on error type. Make this explicit in the API contract to keep client parsing unambiguous.
- Pagination: prefer limit/offset (or page/size) and always return articlesCount for total.

Data shapes — TypeScript interfaces (inferred JSON shapes)
- Guidance: These are interface-level shapes used in the spec for clarity. They are technology-agnostic descriptions mapped to TypeScript for developer handoff, and can be translated to JSON Schema if required.

1) Core user and auth shapes

interface UserShape {
  username: string;
  email: string;
  bio?: string | null;
  image?: string | null;     // URL to avatar, optional
  createdAt?: string;        // ISO 8601 timestamp (server-generated)
  updatedAt?: string;        // ISO 8601 timestamp
}

interface AuthResponse {
  user: UserShape;
  token: string;             // opaque session token (JWT or similar)
}

2) Profile

interface ProfileShape {
  username: string;
  bio?: string | null;
  image?: string | null;
  following: boolean;         // whether current authenticated user follows this profile
}

3) Article in detail and creation shapes

interface ArticleCreateShape {
  title: string;
  description?: string;
  body: string;
  tags?: string[];            // optional tags array
  visibility?: "draft" | "published"; // default: published
}

interface ArticleShape {
  slug: string;               // unique identifier derived from title (immutable)
  title: string;
  description?: string;
  body: string;
  tags: string[];             // empty array if none
  createdAt: string;          // ISO 8601
  updatedAt: string;          // ISO 8601
  author: ProfileShape;       // embedded author profile at time of retrieval
  favorited?: boolean;        // if current user favorited it
  favoritesCount: number;
  visibility: "draft" | "published";
}

4) Comment

interface CommentShape {
  id: string | number;        // unique id
  body: string;
  createdAt: string;
  updatedAt: string;
  author: ProfileShape;
}

5) Listing / Pagination envelope

interface PaginatedArticles {
  articles: ArticleShape[];
  articlesCount: number;
  page: {
    limit: number;
    offset: number;
  };
}

6) Error shapes

interface ValidationErrors {
  errors: { [field: string]: string[] }; // e.g., { email: ["can't be blank"], password: ["too short"] }
}

interface GenericError {
  message: string;
}

Data shape assumptions and rationale
- Timestamps are ISO 8601 strings for portability across client/server.
- Slug is used as human-readable stable identifier for articles (as in the RealWorld spec).
- Profile.following is contextual to the requestor; when unauthenticated, following=false.
- Visibility uses simple enum draft/published to support staged editing flows.
- Tags are a list of strings (no separate tag entity unless tags need metadata, which would be a separate feature).

Feature → Test files mapping (E2E / Cypress)
- The mapping below pairs each high-level feature with the suggested Cypress test files (naming convention: cypress/e2e/<feature>.cy.ts). These are intended as the canonical E2E tests that must exist; they can be created or extended.

1) Auth
   - cypress/e2e/auth/sign_up.cy.ts
     - Tests: successful sign up, duplicate email/username handling, validation errors displayed
   - cypress/e2e/auth/sign_in.cy.ts
     - Tests: successful sign in, wrong credentials, remember/persist session behavior
   - cypress/e2e/auth/sign_out.cy.ts
     - Tests: sign out clears session and redirects to public view

2) Article flows
   - cypress/e2e/articles/create_article.cy.ts
     - Tests: create article (published), create article (draft), validation errors
   - cypress/e2e/articles/edit_article.cy.ts
     - Tests: author can edit, non-author cannot; draft → publish transition
   - cypress/e2e/articles/delete_article.cy.ts
     - Tests: author deletes article; article no longer visible in listing
   - cypress/e2e/articles/list_and_view.cy.ts
     - Tests: article listing returns expected articles, pagination, filter by tag/author, view article detail

3) Comments
   - cypress/e2e/comments/add_comment.cy.ts
     - Tests: authenticated user adds a comment; comment appears on article page
   - cypress/e2e/comments/delete_comment.cy.ts
     - Tests: comment owner deletes own comment; deletion reflected in UI

4) Profiles & follow
   - cypress/e2e/profiles/view_profile.cy.ts
     - Tests: view a profile (own and other), verify lists of authored articles
   - cypress/e2e/profiles/follow_unfollow.cy.ts
     - Tests: follow/unfollow toggles and UI state updates; following affects follower count

5) Search & filters
   - cypress/e2e/search/search_and_filter.cy.ts
     - Tests: search returns relevant articles, tag filters, author filter, and pagination

6) Error & validation
   - cypress/e2e/errors/validation_messages.cy.ts
     - Tests: form-level and field-level errors show consistent messaging and allow recovery

7) Cross-cutting tests
   - cypress/e2e/performance/page_loads.cy.ts
     - Tests: high-level page load expectations (list pages render within user-focused thresholds)
   - cypress/e2e/accessibility/basic_warnings.cy.ts
     - Tests: validate basic accessibility expectations on key pages (forms have labels, focus order)

Notes on mapping:
- File naming convention uses feature area subfolders to keep tests organized.
- Each test file should be focused on a single user flow to keep CI runs fast and clear.
- Tests should avoid implementation details (timeouts, selectors tied to classes that might change). Prefer data-test attributes or stable ARIA labels.

Acceptance criteria mapping (quick view)
- For each E2E test file above, acceptance criteria include:
  - Given/When/Then style scenario(s) that are deterministic
  - No reliance on fragile selectors—use test-only ids or stable attributes
  - Reset test state (seed DB or use test user account) so tests are idempotent

Assumptions (documented defaults used to fill gaps)
- Authentication tokens are opaque strings usable in Authorization header; client persists token in secure storage.
- Article slugs are unique across the system.
- Profiles are public; following is a user-level relationship only.
- Pagination uses limit & offset with default limit = 20 unless specified.
- Validation behavior: server returns structured validation errors we can surface inline on forms.
- Test environment has fixtures and/or test users available so E2E tests can seed/tear down state.

Appendix — file paths used as evidence (non-destructive listing)
Note: These are the repository files and directories visible in the working snapshot and referenced when shaping the spec. I did not modify or read their contents in this step; this appendix lists paths to review as evidence during implementation or test mapping.

- Root-level:
  - README.md
  - package.json
  - yarn.lock
  - CODE_OF_CONDUCT.md
  - LICENSE
  - index.html

- Cypress & E2E config:
  - cypress.config.ts
  - cypress.d.ts
  - vite.cypress.config.ts
  - cypress/                 (E2E test directory — contains existing tests and fixtures)
    - (example subpaths to inspect when implementing tests)
    - cypress/e2e/
    - cypress/fixtures/
    - cypress/support/

- Source and build:
  - src/                     (application source — inspect for route names, data models, components)
  - vite.config.ts
  - tsconfig.json
  - tsconfig.tsnode.json
  - eslint.config.mjs

- Backend / infra stubs:
  - amplify/
  - backend/

- Other helpful files:
  - public/
  - data/                    (seed/test data may exist here)
  - scripts/                 (project scripts, possibly including test setup)
  - patches/
  - sandbox.config.json
  - renovate.json
  - codecov.yml

How to use this continuation
- Top features + contracts give product + API teams a clear, testable target.
- The TypeScript interfaces can be used as a starting point for client models or for generating JSON Schemas.
- The Feature → Test mapping is a minimal E2E plan — create the suggested test files and implement the Given/When/Then scenarios described in this spec.
- Before implementation, review the Appendix files to extract concrete route names, current data models, and existing tests to avoid duplication.

If you want, I can:
- Expand any single contract into a full request/response example (sample JSON).
- Produce JSON Schema or OpenAPI snippets for one or more contracts.
- Generate the initial skeletons for the Cypress test files (contents with placeholders and suggested selectors) without committing them — provided here as non-destructive text. Which would you prefer next?
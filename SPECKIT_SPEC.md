# Cypress Real-World App - Codebase Specification

**Version:** 1.0.0  
**Last Updated:** 2024-03-30  
**Purpose:** Comprehensive documentation of the Cypress Real-World App (RWA) codebase, features, API contracts, data structures, and test coverage.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Features](#core-features)
4. [Data Models](#data-models)
5. [API Contracts](#api-contracts)
6. [Authentication & Authorization](#authentication--authorization)
7. [Feature Boundaries](#feature-boundaries)
8. [Test Coverage](#test-coverage)
9. [Technology Stack](#technology-stack)

---

## Overview

### Project Description

The **Cypress Real-World App (RWA)** is a full-stack Express.js/React application designed to demonstrate real-world testing patterns and workflows with Cypress. It implements a payment/transaction application with social features, allowing users to send and receive payments, add contacts, and interact with transactions through likes and comments.

### Key Characteristics

- **Full-stack application**: Express backend (Node.js) + React frontend (TypeScript)
- **Zero database dependencies**: Uses lowdb (JSON-based database)
- **Educational focus**: Demonstrates testing best practices
- **Multiple authentication methods**: Local (Passport.js), Auth0, Okta, Amazon Cognito, Google
- **State management**: XState for complex UI state
- **API**: RESTful endpoints + GraphQL playground
- **UI Framework**: Material-UI (MUI v5)

### Project Scope

**In Scope:**
- User authentication and profile management
- Transaction management (payments, requests)
- Contact management
- Bank account management
- Social features (likes, comments, notifications)
- Bank transfers (deposits/withdrawals)
- Transaction filtering and pagination
- Notification system
- User search and discovery

**Out of Scope:**
- Real payment processing
- Production-grade security
- Distributed systems or microservices
- Third-party payment APIs (except for auth providers)

---

## Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────┐
│                     React Frontend (Port 3000)              │
│                                                              │
│  ├── Containers (State management via XState)              │
│  ├── Components (UI with Material-UI)                      │
│  ├── Machines (XState state machines)                      │
│  └── Utils (Helpers, HTTP client)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │ REST API     │ GraphQL      │
        │ (Port 3001)  │ (Port 3001)  │
        └──────────────┼──────────────┘
                       │
┌──────────────────────┴──────────────────────────────────────┐
│                  Express Backend (Port 3001)                │
│                                                              │
│  ├── Routes (API endpoints)                                │
│  ├── Middleware (Auth, validation, CORS)                   │
│  ├── Database (lowdb JSON store)                           │
│  ├── GraphQL (Schema + Resolvers)                          │
│  └── Utils (Validators, helpers)                           │
└─────────────────────────────────────────────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       │   data/database.json          │
       │   data/database-seed.json     │
       │   data/empty-seed.json        │
       └───────────────────────────────┘
```

### Directory Structure

```
cypress-realworld-app/
├── src/                        # React frontend
│   ├── components/             # Reusable UI components
│   ├── containers/             # Page containers
│   ├── machines/               # XState machines
│   ├── models/                 # TypeScript types & interfaces
│   ├── utils/                  # Utility functions
│   └── index.tsx               # Main entry point
├── backend/                    # Express backend
│   ├── app.ts                  # Express server setup
│   ├── auth.ts                 # Authentication routes
│   ├── database.ts             # Database operations
│   ├── graphql/                # GraphQL schema & resolvers
│   ├── *-routes.ts             # API endpoint definitions
│   ├── validators.ts           # Request validation middleware
│   └── helpers.ts              # Utility functions
├── cypress/                    # Test suite
│   ├── tests/api/              # API tests
│   ├── tests/ui/               # UI tests
│   ├── tests/demo/             # Demo tests
│   ├── tests/ui-auth-providers/# Auth provider tests
│   └── support/                # Test utilities & fixtures
├── data/                       # Database files
│   ├── database.json           # Seeded database
│   ├── database-seed.json      # Seed template
│   └── empty-seed.json         # Empty database template
└── public/                     # Static assets
```

---

## Core Features

### 1. User Management & Authentication

#### User Sign-Up
- **Description**: Create a new user account with email, username, password, and personal info
- **User Type**: Visitor (unauthenticated)
- **Payload**:
  ```typescript
  {
    firstName: string;
    lastName: string;
    username: string;
    password: string;
  }
  ```
- **Outcomes**: Account created, automatic login, onboarding dialog shown

#### User Sign-In
- **Description**: Authenticate with username/password
- **Methods Supported**:
  - Local (Passport.js)
  - Auth0
  - Okta
  - Amazon Cognito
  - Google
- **Payload**:
  ```typescript
  {
    username: string;
    password: string;
    remember?: boolean;  // Keep logged in for 30 days
  }
  ```
- **Session Management**: 24-hour default, extended to 30 days if "remember me" selected

#### User Profile & Settings
- **Description**: View and edit user profile information
- **Editable Fields**:
  - First name
  - Last name
  - Email
  - Phone number
  - Default privacy level (public/private/contacts)
  - Avatar
- **Privacy Levels**:
  - `public`: Visible to all users
  - `private`: Visible only to sender/receiver
  - `contacts`: Visible only to contacts and sender/receiver

#### User Search
- **Query Parameter**: `q` (searches across email, username, first name, last name)
- **Returns**: List of users matching query (excludes current user)
- **Use Case**: Finding users to send payments or add as contacts

### 2. Transaction Management

#### Transaction Types

**Payment (Standard Transfer)**
- Direct transfer from one user to another
- Status: pending → complete
- No intermediate account required

**Payment Request**
- User requests money from another user
- Request Status: pending → accepted/rejected
- Initiator: Requestor (user asking for money)
- Target: Requestee (user being asked)

**Bank Transfer (Deposit/Withdrawal)**
- Transfer to/from user's bank account
- Type: deposit or withdrawal
- Requires linked bank account
- No intermediary person involved

#### Transaction Properties

```typescript
{
  id: string;                    // Short ID
  uuid: string;                  // UUID
  source: string;                // Empty for P2P; Bank Account ID for transfers
  amount: number;                // In cents
  description: string;           // User-provided memo
  privacyLevel: DefaultPrivacyLevel;  // public/private/contacts
  receiverId: string;            // Target user ID
  senderId: string;              // Initiating user ID
  balanceAtCompletion?: number;  // User balance after transaction
  status: TransactionStatus;     // pending/incomplete/complete
  requestStatus?: TransactionRequestStatus;  // For requests: pending/accepted/rejected
  requestResolvedAt?: Date;      // When request was resolved
  createdAt: Date;
  modifiedAt: Date;
}
```

#### Transaction Filtering

- **Date Range**: Filter by transaction creation date
- **Amount Range**: Filter by transaction amount (min/max)
- **Status Filter**: By transaction status
- **Pagination**: Page number and limit (default: 10 items per page)

#### Transaction Actions

**Sender Actions:**
- Create new transaction (payment, request, or bank transfer)
- Cancel pending request
- Edit transaction description (before completion)

**Receiver Actions (for requests):**
- Accept payment request
- Reject payment request
- Request timeout handling

**Privacy Considerations:**
- Public transactions visible to all users
- Private transactions visible only to participants
- Contact transactions visible to participants and contacts

### 3. Contact Management

#### Contact Features
- Add other users as contacts
- View contact list
- Remove contacts
- Privacy rule: Contact transactions show to contacts

#### Contact Operations
- **Create**: Add another user as contact
- **Read**: View all contacts for a user
- **Delete**: Remove contact relationship

#### Use Cases
- Frequent payment recipients
- Building trusted networks
- Privacy segmentation

### 4. Bank Account Management

#### Bank Account Properties

```typescript
{
  id: string;           // Short ID
  uuid: string;         // UUID
  userId: string;       // Owner user ID
  bankName: string;     // Bank institution name
  accountNumber: string; // Obfuscated account number
  routingNumber: string; // Bank routing number
  isDeleted: boolean;    // Soft delete flag
  createdAt: Date;
  modifiedAt: Date;
}
```

#### Bank Account Operations
- **Create**: Link a new bank account (requires bank info)
- **Read**: View all accounts for current user
- **Delete**: Remove (soft delete) bank account

#### Validation
- Account number format validation
- Routing number format validation
- Unique account per user (logical uniqueness)

### 5. Bank Transfers

#### Bank Transfer Operations

**Deposit**
- Transfer funds from user's bank account to app wallet
- Type: `deposit`
- Increases user balance

**Withdrawal**
- Transfer funds from app wallet to user's bank account
- Type: `withdrawal`
- Decreases user balance

#### Bank Transfer Properties

```typescript
{
  id: string;                    // Short ID
  uuid: string;                  // UUID
  userId: string;                // User performing transfer
  source: string;                // Bank Account ID
  amount: number;                // In cents
  type: BankTransferType;        // 'deposit' | 'withdrawal'
  transactionId: string;         // Associated transaction ID
  createdAt: Date;
  modifiedAt: Date;
}
```

#### Constraints
- Withdrawal cannot exceed user balance
- Requires valid linked bank account
- Creates corresponding transaction record

### 6. Social Features

#### Likes
- Users can like transactions
- Like = appreciation/reaction to a transaction
- Displays on transaction details
- Affects transaction visibility/popularity
- Triggers like notification

#### Comments
- Users can comment on transactions
- Comment format: text-based, single message per comment
- Visible on transaction details in chronological order
- Triggers comment notification

#### Notifications

**Types:**
1. **Payment Notification**
   - Status: requested, received, incomplete
   - Triggered when payment request created/completed

2. **Like Notification**
   - Triggered when user likes your transaction
   - Contains like ID and transaction reference

3. **Comment Notification**
   - Triggered when user comments on your transaction
   - Contains comment ID and transaction reference

**Notification Properties:**
```typescript
{
  id: string;
  uuid: string;
  userId: string;              // Recipient user ID
  transactionId: string;       // Referenced transaction
  isRead: boolean;
  createdAt: Date;
  modifiedAt: Date;
  // Plus type-specific fields:
  // - PaymentNotification: status
  // - LikeNotification: likeId
  // - CommentNotification: commentId
}
```

**Notification Actions:**
- Mark as read
- Bulk create notifications
- Fetch unread notifications

### 7. GraphQL API (Secondary)

#### Purpose
- Query-based alternative to REST API
- Optional query interface
- Currently supports: Bank Account operations

#### Schema
```graphql
type Query {
  listBankAccount: [BankAccount!]
}

type Mutation {
  createBankAccount(bankName: String!, accountNumber: String!, routingNumber: String!): BankAccount
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

---

## Data Models

### Core Entities

#### User Model
```typescript
interface User {
  id: string;                              // Short ID
  uuid: string;                            // UUID
  firstName: string;
  lastName: string;
  username: string;                        // Unique login identifier
  password: string;                        // Bcrypt hashed
  email: string;
  phoneNumber: string;
  balance: number;                         // Account balance in cents
  avatar: string;                          // Avatar URL
  defaultPrivacyLevel: DefaultPrivacyLevel;
  createdAt: Date;
  modifiedAt: Date;
}

enum DefaultPrivacyLevel {
  public = "public",
  private = "private",
  contacts = "contacts"
}
```

#### Transaction Model
- See Transaction Management section above
- Related Entities: User (sender/receiver), BankAccount (if bank transfer), Comment[], Like[], Notification[]

#### Contact Model
```typescript
interface Contact {
  id: string;
  uuid: string;
  userId: string;         // Contact owner
  contactUserId: string;  // Contact reference
  createdAt: Date;
  modifiedAt: Date;
}
```

#### BankAccount Model
- See Bank Account Management section above
- Constraints: Soft deletion (isDeleted flag), user ownership

#### Comment Model
```typescript
interface Comment {
  id: string;
  uuid: string;
  content: string;
  userId: string;         // Comment author
  transactionId: string;  // Commented transaction
  createdAt: Date;
  modifiedAt: Date;
}
```

#### Like Model
```typescript
interface Like {
  id: string;
  uuid: string;
  userId: string;         // User who liked
  transactionId: string;  // Liked transaction
  createdAt: Date;
  modifiedAt: Date;
}
```

#### Notification Model
- See Social Features section above
- Union type: PaymentNotification | LikeNotification | CommentNotification

#### BankTransfer Model
- See Bank Transfers section above

### Database Schema

```typescript
interface DbSchema {
  users: User[];
  contacts: Contact[];
  bankaccounts: BankAccount[];
  transactions: Transaction[];
  likes: Like[];
  comments: Comment[];
  notifications: NotificationType[];
  banktransfers: BankTransfer[];
}
```

---

## API Contracts

### Base URLs
- **Frontend**: `http://localhost:3000`
- **Backend REST**: `http://localhost:3001`
- **GraphQL Endpoint**: `http://localhost:3001/graphql`

### Authentication
- **Method**: Session-based (Passport.js default)
- **Cookie**: `connect.sid`
- **CORS**: Enabled for frontend origin

### Standard Response Format

**Success (2xx)**
```json
{
  "user": { /* object */ },
  "results": [ /* array */ ],
  "transaction": { /* object */ },
  // ... endpoint-specific data
}
```

**Error (4xx/5xx)**
```json
{
  "error": "Error message",
  "errors": [
    { "field": "fieldName", "message": "Validation error" }
  ]
}
```

### Authentication Routes

#### POST /login
- **Public**: Yes
- **Body**:
  ```json
  {
    "username": "string",
    "password": "string",
    "remember": "boolean (optional)"
  }
  ```
- **Response**: `{ "user": User }`
- **Status**: 200

#### POST /logout
- **Auth Required**: Yes
- **Response**: Redirect to `/`
- **Status**: 302

#### GET /checkAuth
- **Auth Required**: No
- **Response**: 
  - Authenticated: `{ "user": User }`
  - Unauthenticated: `{ "error": "User is unauthorized" }`
- **Status**: 200 or 401

### User Routes

#### GET /users
- **Auth Required**: Yes (scoped to current user)
- **Response**: `{ "results": User[] }` (excludes current user)
- **Status**: 200

#### GET /users/search?q={query}
- **Auth Required**: Yes
- **Query Params**: `q` (search string)
- **Response**: `{ "results": User[] }`
- **Validations**: Query string required, non-empty
- **Status**: 200 or 422

#### GET /users/profile/:username
- **Auth Required**: No
- **Params**: `username` (user's login username)
- **Response**: 
  ```json
  {
    "user": {
      "firstName": "string",
      "lastName": "string",
      "avatar": "string"
    }
  }
  ```
- **Note**: Returns only public profile info (no balance, email, etc.)
- **Status**: 200

#### GET /users/:userId
- **Auth Required**: Yes (scoped - user can only view own profile)
- **Params**: `userId` (short ID)
- **Response**: `{ "user": User }`
- **Permissions**: User must be the profile owner
- **Validations**: Valid short ID format
- **Status**: 200 or 401 or 422

#### POST /users
- **Auth Required**: No
- **Body**: 
  ```json
  {
    "firstName": "string",
    "lastName": "string",
    "username": "string",
    "password": "string",
    "email": "string (optional)",
    "phoneNumber": "string (optional)"
  }
  ```
- **Response**: `{ "user": User }`
- **Validations**: 
  - Username unique
  - Password minimum length
  - Email format (if provided)
- **Status**: 201

#### PATCH /users/:userId
- **Auth Required**: Yes
- **Params**: `userId`
- **Body**: Partial User object
  ```json
  {
    "firstName": "string (optional)",
    "lastName": "string (optional)",
    "email": "string (optional)",
    "phoneNumber": "string (optional)",
    "defaultPrivacyLevel": "public|private|contacts (optional)"
  }
  ```
- **Response**: No content
- **Status**: 204

### Transaction Routes

#### GET /transactions
- **Auth Required**: Yes (scoped to current user's transactions)
- **Query Params**:
  - `page`: number (default: 1)
  - `limit`: number (default: 10)
  - `status`: TransactionStatus (optional)
  - `requestStatus`: TransactionRequestStatus (optional)
  - `dateRangeStart`: ISO date string (optional)
  - `dateRangeEnd`: ISO date string (optional)
  - `amountMin`: number (optional)
  - `amountMax`: number (optional)
- **Response**:
  ```json
  {
    "pageData": {
      "page": 1,
      "limit": 10,
      "hasNextPages": false,
      "totalPages": 5
    },
    "results": [
      {
        "id": "string",
        "amount": 10000,
        "description": "string",
        "status": "complete",
        "privacyLevel": "public",
        "senderId": "string",
        "receiverId": "string",
        "senderName": "string",
        "senderAvatar": "string",
        "receiverName": "string",
        "receiverAvatar": "string",
        "likes": [ /* Like[] */ ],
        "comments": [ /* Comment[] */ ],
        "createdAt": "ISO date"
      }
    ]
  }
  ```
- **Status**: 200

#### GET /transactions/contacts
- **Auth Required**: Yes
- **Query Params**: Same as `/transactions`
- **Response**: Same as `/transactions`
- **Note**: Returns transactions with current user's contacts
- **Status**: 200

#### GET /transactions/public
- **Auth Required**: Yes
- **Query Params**: Same as `/transactions` + public filtering
- **Response**: Same as `/transactions`
- **Behavior**: 
  - First page includes up to 5 contact transactions + public transactions
  - Subsequent pages show only public transactions
- **Status**: 200

#### GET /transactions/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId` (short ID)
- **Response**: Full TransactionResponseItem with likes/comments
- **Status**: 200

#### POST /transactions
- **Auth Required**: Yes
- **Body**:
  ```json
  {
    "transactionType": "payment" | "request" | "transfer",
    "senderId": "string",
    "receiverId": "string",
    "amount": "string (numeric)",
    "description": "string",
    "source": "string (optional, for transfers)",
    "privacyLevel": "public|private|contacts (optional)"
  }
  ```
- **Response**: `{ "transaction": Transaction }`
- **Validations**:
  - Valid user IDs
  - Positive amount
  - Valid privacy level
  - Sufficient balance (if applicable)
- **Status**: 200

#### PATCH /transactions/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId`
- **Body**: 
  ```json
  {
    "requestStatus": "accepted" | "rejected"
  }
  ```
- **Response**: No content
- **Use**: Accept or reject payment requests
- **Status**: 204

### Contact Routes

#### GET /contacts/:username
- **Auth Required**: No
- **Params**: `username`
- **Response**: `{ "contacts": Contact[] }`
- **Status**: 200

#### POST /contacts
- **Auth Required**: Yes
- **Body**: `{ "contactUserId": "string" }`
- **Response**: `{ "contact": Contact }`
- **Validations**: Valid user ID
- **Status**: 200

#### DELETE /contacts/:contactId
- **Auth Required**: Yes
- **Params**: `contactId` (short ID)
- **Response**: `{ "contacts": Contact[] }` (updated contact list)
- **Status**: 200

### Bank Account Routes

#### GET /bankAccounts
- **Auth Required**: Yes (scoped to current user)
- **Response**: `{ "results": BankAccount[] }`
- **Status**: 200

#### GET /bankAccounts/:bankAccountId
- **Auth Required**: Yes
- **Params**: `bankAccountId` (short ID)
- **Response**: `{ "account": BankAccount }`
- **Status**: 200

#### POST /bankAccounts
- **Auth Required**: Yes
- **Body**:
  ```json
  {
    "bankName": "string",
    "accountNumber": "string",
    "routingNumber": "string"
  }
  ```
- **Response**: `{ "account": BankAccount }`
- **Validations**: Required fields, format validation
- **Status**: 200

#### DELETE /bankAccounts/:bankAccountId
- **Auth Required**: Yes
- **Params**: `bankAccountId`
- **Response**: `{ "account": BankAccount }` (with isDeleted: true)
- **Note**: Soft delete
- **Status**: 200

### Bank Transfer Routes

#### POST /bankTransfers (Implicit)
- **Auth Required**: Yes
- **Mechanism**: Created via POST /transactions with source field
- **Body**: See Transaction creation

### Like Routes

#### GET /likes/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId` (short ID)
- **Response**: `{ "likes": Like[] }`
- **Status**: 200

#### POST /likes/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId`
- **Response**: Status 200 (no body)
- **Effect**: Adds like from current user, creates notification
- **Idempotent**: Subsequent calls don't create duplicate likes
- **Status**: 200

### Comment Routes

#### GET /comments/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId`
- **Response**: `{ "comments": Comment[] }`
- **Status**: 200

#### POST /comments/:transactionId
- **Auth Required**: Yes
- **Params**: `transactionId`
- **Body**: `{ "content": "string" }`
- **Response**: Status 200 (no body)
- **Effect**: Adds comment, creates notification
- **Validations**: Non-empty content
- **Status**: 200

### Notification Routes

#### GET /notifications
- **Auth Required**: Yes (scoped to current user)
- **Response**: `{ "results": NotificationResponseItem[] }` (unread only)
- **Status**: 200

#### POST /notifications/bulk
- **Auth Required**: Yes
- **Body**:
  ```json
  {
    "items": [
      {
        "type": "payment" | "like" | "comment",
        "transactionId": "string",
        "status": "string (for payment)",
        "likeId": "string (for like)",
        "commentId": "string (for comment)"
      }
    ]
  }
  ```
- **Response**: `{ "results": NotificationResponseItem[] }`
- **Status**: 200

#### PATCH /notifications/:notificationId
- **Auth Required**: Yes
- **Params**: `notificationId`
- **Body**: `{ "isRead": true | false }`
- **Response**: No content
- **Status**: 204

### Test Data Routes (Development/Test Only)

#### POST /testData/seed
- **Availability**: NODE_ENV === "test" or "development"
- **Effect**: Reseed database with default seed data
- **Response**: Status 200
- **Status**: 200

---

## Authentication & Authorization

### Authentication Methods

#### 1. Local Authentication (Default)
- **Strategy**: Passport.js LocalStrategy
- **Mechanism**: Username/password comparison with bcrypt
- **Endpoint**: POST /login
- **Session Storage**: Express session middleware

#### 2. External Providers (Alternative)
- **Supported**: Auth0, Okta, Amazon Cognito, Google
- **Mechanism**: JWT token verification
- **Middleware Functions**:
  - Auth0: `checkAuth0Jwt`
  - Okta: `verifyOktaToken`
  - Cognito: `checkCognitoJwt`
  - Google: `checkGoogleJwt`

### Authorization Patterns

#### User Scoping
- **Pattern**: Many routes return data scoped to authenticated user
- **Implementation**: Check `req.user?.id` matches resource owner
- **Example**: GET /users/:userId only works for own profile

#### Permission Checks
- **Transaction Viewing**: User must be sender, receiver, or transaction must be public/contact-visible
- **Contact Viewing**: Public endpoint, shows user's contacts
- **Bank Account Management**: Scoped to account owner
- **Profile Editing**: Only user can edit own profile

#### Access Control Lists (Implicit)
- **Privacy Levels**:
  - public: Any authenticated user
  - private: Only sender and receiver
  - contacts: Sender, receiver, and contacts of both

---

## Feature Boundaries

### Clear Boundaries (Out of Scope)

1. **Real Payment Processing**
   - No actual fund transfers
   - No credit card processing
   - No PCI compliance
   - Balance updates are simulation only

2. **Production Security**
   - Session secret hardcoded in development
   - No rate limiting
   - No input sanitization beyond validation
   - Passwords hashed with bcrypt but no salting configurations

3. **Advanced Features**
   - No recurring payments
   - No scheduled transactions
   - No multi-currency support
   - No invoice/bill generation
   - No receipts or transaction history export

4. **Scalability Features**
   - Lowdb is not suitable for concurrent writes
   - No database indexing
   - No caching layer
   - No async job queue

### Feature Interactions

**Transaction Lifecycle:**
```
Created (pending)
  ↓
Visible in feeds (based on privacy)
  ↓
Can receive likes/comments
  ↓
Can be accepted/rejected (if request)
  ↓
Completed/Rejected
  ↓
Becomes read-only
```

**Notification Triggers:**
- Payment request created → receiver notification
- Payment request accepted → requestor notification
- Payment request rejected → requestor notification
- Like added → recipient notification
- Comment added → recipient notification

**User Lifecycle:**
```
Visitor
  ↓
Sign Up
  ↓
Authenticated User
  ↓
Complete Onboarding (add bank account)
  ↓
Active User
```

### Integration Points

1. **Frontend ↔ Backend**
   - HTTP REST requests
   - Session cookies for auth
   - CORS enabled

2. **Backend ↔ Database**
   - lowdb JSON database
   - In-memory operations
   - Seeding on app start

3. **External Auth ↔ Backend**
   - JWT verification
   - Token parsing
   - User context injection

---

## Test Coverage

### Test Structure

```
cypress/
├── tests/
│   ├── api/              # REST API tests (903 lines total)
│   ├── ui/               # UI interaction tests
│   ├── ui-auth-providers/# Third-party auth tests
│   └── demo/             # Demo/reference tests
└── support/              # Test utilities
    ├── commands.ts       # Custom Cypress commands
    ├── utils.ts          # Helper functions
    └── fixtures/         # Test data
```

### API Test Coverage

**Total Lines**: 903  
**Spec Files**: 9

#### api-users.spec.ts (205 lines)
- **Coverage Areas**:
  - GET /users - list all users
  - GET /users/:userId - get single user
  - GET /users/profile/:username - public profile
  - GET /users/search - search functionality
  - POST /users - user creation/signup
  - PATCH /users/:userId - profile updates
- **Test Cases**: ~20+
- **Scenarios**: Auth validation, error handling, data validation

#### api-transactions.spec.ts (169 lines)
- **Coverage Areas**:
  - GET /transactions - list user transactions
  - GET /transactions/contacts - contact transactions
  - GET /transactions/public - public feed
  - POST /transactions - create transaction
  - GET /transactions/:transactionId - detail view
  - PATCH /transactions/:transactionId - request acceptance
- **Test Cases**: ~15+
- **Scenarios**: Status transitions, filtering, pagination, permissions

#### api-bankaccounts.spec.ts (149 lines)
- **Coverage Areas**:
  - GET /bankAccounts - list accounts
  - GET /bankAccounts/:bankAccountId - get account
  - POST /bankAccounts - create account
  - DELETE /bankAccounts/:bankAccountId - delete account
- **Test Cases**: ~12+
- **Scenarios**: CRUD operations, validation, deletion

#### api-notifications.spec.ts (107 lines)
- **Coverage Areas**:
  - GET /notifications - list notifications
  - POST /notifications/bulk - create multiple
  - PATCH /notifications/:notificationId - update read status
- **Test Cases**: ~10+
- **Scenarios**: Creation, updates, filtering

#### api-contacts.spec.ts (77 lines)
- **Coverage Areas**:
  - GET /contacts/:username - get contacts
  - POST /contacts - add contact
  - DELETE /contacts/:contactId - remove contact
- **Test Cases**: ~8+
- **Scenarios**: CRUD operations, relationships

#### api-likes.spec.ts (53 lines)
- **Coverage Areas**:
  - GET /likes/:transactionId - get likes
  - POST /likes/:transactionId - add like
- **Test Cases**: ~6+
- **Scenarios**: Creation, retrieval

#### api-comments.spec.ts (55 lines)
- **Coverage Areas**:
  - GET /comments/:transactionId - get comments
  - POST /comments/:transactionId - add comment
- **Test Cases**: ~7+
- **Scenarios**: Creation, retrieval, validation

#### api-banktransfers.spec.ts (36 lines)
- **Coverage Areas**: Bank transfer operations (implicit via transactions)
- **Test Cases**: ~3+

#### api-testdata.spec.ts (52 lines)
- **Coverage Areas**: Database seeding functionality
- **Test Cases**: ~5+

### UI Test Coverage

**Total Lines**: ~56,800 (across 7 files)

#### auth.spec.ts (~7,000 lines estimated)
- **Coverage Areas**:
  - Sign-up flow
  - Sign-in flow
  - Sign-out flow
  - "Remember me" functionality
  - Session persistence
  - Redirect to login when unauthorized
- **Test Cases**: ~10+
- **Selectors Used**: Accessibility selectors (getBySel)
- **Visual Testing**: Percy snapshots

#### bankaccounts.spec.ts (~6,600 lines estimated)
- **Coverage Areas**:
  - Bank account list view
  - Create bank account form
  - Edit bank account
  - Delete bank account
  - Form validation
  - Error handling
- **Test Cases**: ~12+
- **Features**: Form submission, error messages

#### new-transaction.spec.ts (~10,800 lines estimated)
- **Coverage Areas**:
  - Payment creation
  - Payment request creation
  - Bank transfer creation
  - Transaction form validation
  - Recipient selection
  - Amount validation
  - Description entry
  - Privacy level selection
- **Test Cases**: ~18+
- **Scenarios**: Success flows, error handling, edge cases

#### transaction-feeds.spec.ts (~17,800 lines estimated)
- **Coverage Areas**:
  - Personal transactions feed
  - Public transactions feed
  - Contact transactions feed
  - Transaction filtering (date, amount)
  - Pagination
  - Transaction sorting
  - Privacy filtering
  - Empty state handling
- **Test Cases**: ~25+
- **Advanced Scenarios**: Complex filtering combinations

#### transaction-view.spec.ts (~4,600 lines estimated)
- **Coverage Areas**:
  - Transaction detail page
  - Like functionality
  - Comment functionality
  - Comments display
  - Like count display
  - User avatars
  - Transaction metadata
- **Test Cases**: ~8+

#### notifications.spec.ts (~9,200 lines estimated)
- **Coverage Areas**:
  - Notification list
  - Mark as read
  - Notification types (payment, like, comment)
  - Badge/count display
  - Notification interactions
- **Test Cases**: ~10+

#### user-settings.spec.ts (~3,300 lines estimated)
- **Coverage Areas**:
  - Profile edit form
  - Field updates
  - Form validation
  - Success/error states
  - Privacy level selection
- **Test Cases**: ~6+

### Demo Tests

Located in `cypress/tests/demo/`:
- Reference tests showing Cypress best practices
- Demonstrating test patterns for educational purposes

### Component Tests

Located in `src/components/`:
- Component-level tests using Cypress component testing
- Examples: AlertBar.cy.tsx, TransactionTitle.cy.tsx

### Unit Tests

Located in `src/__tests__/`:
- Jest-based unit tests
- Testing utilities, helpers, machine logic

### Authentication Provider Tests

Located in `cypress/tests/ui-auth-providers/`:
- Auth0.spec.ts
- Okta.spec.ts
- Cognito.spec.ts
- Google.spec.ts

---

## Technology Stack

### Frontend (React)

**Core Framework**
- React 18.2.0
- React DOM 18.2.0
- TypeScript (strict mode)

**State Management**
- XState 4.x (state machines)
- @xstate/react 3.2.2 (React integration)

**UI Framework**
- Material-UI (MUI) v5.15.12
- @mui/icons-material v5.15.12
- @mui/lab v5.0.0-alpha

**Routing**
- React Router v5.3.4
- React Router DOM v5.3.4

**HTTP Client**
- Axios 0.28.1

**Form Handling**
- Formik 2.4.6

**Date/Time**
- date-fns 4.1.0
- date-fns-tz v3.2.0
- react-calendar v6.0.0

**Authentication Support**
- @auth0/auth0-react 2.2.4
- @okta/okta-react v6.7.0
- @okta/okta-auth-js v7.3.0
- aws-amplify v6.0.16
- @matheusluizn/react-google-login v5.1.6

**Utilities**
- shortid 2.2.16 (ID generation)
- uuid 8.3.2 (UUID generation)
- dinero.js v2.0.0 (Money handling)
- react-number-format 4.9.4 (Number formatting)
- clsx 1.2.1 (Class name utilities)
- react-virtualized 9.22.5 (Virtual scrolling)

### Backend (Express.js)

**Framework & Server**
- Express 4.x
- Node.js (TypeScript compiled to JS)

**Authentication**
- Passport.js with LocalStrategy
- bcryptjs (password hashing)
- express-session (session management)
- @okta/jwt-verifier v3.0.1

**API**
- CORS middleware
- body-parser (JSON/form parsing)
- express-paginate (pagination helper)
- graphql-http/lib/use/express (GraphQL middleware)

**GraphQL**
- @graphql-tools/load v7.8.14
- @graphql-tools/schema (schema composition)
- @graphql-tools/graphql-file-loader (schema loading)

**Database**
- lowdb (JSON database)

**Utilities**
- morgan (HTTP logging)
- lodash/fp (functional utilities)
- dotenv (environment variables)

### Database

**Store**: JSON Files (lowdb)
- data/database.json (main)
- data/database-seed.json (seed template)
- data/empty-seed.json (empty state)

**Features**:
- Zero external dependencies
- In-memory operations with file persistence
- Synchronous read/write
- Seeded on app startup

### Testing

**Framework & Runner**
- Cypress 13.x+
- Cypress Cloud (CI integration)

**Code Coverage**
- @cypress/code-coverage (coverage instrumentation)

**Plugins**
- Visual testing: Percy integration

**Test Types**:
- E2E (UI tests)
- API/Integration tests
- Component tests (Cypress component testing)
- Unit tests (Jest)

### Development Tools

**Build & Bundling**
- Vite (frontend bundler)
- TypeScript compiler

**Code Quality**
- ESLint
- Prettier (code formatting)

**Source Control**
- Git
- Husky (Git hooks)

**Package Management**
- Yarn Classic v1

---

## Appendix: Quick Reference

### Key API Endpoints Quick List

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | /login | No | User login |
| POST | /logout | Yes | User logout |
| GET | /checkAuth | No | Check auth status |
| GET | /users | Yes | List all users |
| GET | /users/search?q= | Yes | Search users |
| GET | /users/profile/:username | No | Public profile |
| GET | /users/:userId | Yes | Get user details |
| POST | /users | No | Create user |
| PATCH | /users/:userId | Yes | Update user |
| GET | /transactions | Yes | User's transactions |
| GET | /transactions/contacts | Yes | Contact transactions |
| GET | /transactions/public | Yes | Public feed |
| GET | /transactions/:id | Yes | Transaction detail |
| POST | /transactions | Yes | Create transaction |
| PATCH | /transactions/:id | Yes | Update transaction |
| GET | /contacts/:username | No | User's contacts |
| POST | /contacts | Yes | Add contact |
| DELETE | /contacts/:id | Yes | Remove contact |
| GET | /bankAccounts | Yes | List bank accounts |
| POST | /bankAccounts | Yes | Create account |
| DELETE | /bankAccounts/:id | Yes | Delete account |
| GET | /likes/:transactionId | Yes | Get likes |
| POST | /likes/:transactionId | Yes | Add like |
| GET | /comments/:transactionId | Yes | Get comments |
| POST | /comments/:transactionId | Yes | Add comment |
| GET | /notifications | Yes | Get notifications |
| PATCH | /notifications/:id | Yes | Update notification |

### Common Transaction Scenarios

1. **User sends payment**
   - Status: pending → complete
   - Amount deducted from sender
   - Amount added to receiver
   - Notifications created

2. **User requests payment**
   - Status: pending
   - Request status: pending → accepted/rejected
   - If accepted: funds transfer + complete status
   - Notifications at each step

3. **User deposits from bank**
   - Creates bank transfer record
   - Creates transaction record
   - Increases user balance
   - May create notification

4. **User withdraws to bank**
   - Creates bank transfer record
   - Creates transaction record
   - Decreases user balance
   - Requires linked account + sufficient balance

### Common Status Codes

| Code | Meaning | Common Triggers |
|------|---------|-----------------|
| 200 | Success | Successful GET, POST, PATCH |
| 201 | Created | User signup |
| 204 | No Content | Successful PATCH/DELETE |
| 401 | Unauthorized | No auth, invalid session |
| 422 | Validation Error | Invalid input, constraints |
| 500 | Server Error | Unhandled exceptions |

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-03-30  
**Status**: Complete - Codebase documented

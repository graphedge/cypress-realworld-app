# Feature: User Authentication & Profile Management

## Overview
Comprehensive user authentication system supporting local and third-party providers, with session management and user profile capabilities.

## Core Workflows

### 1. User Sign-Up
**Flow**: Visitor → Create Account → Auto-Login → Onboarding  
**Entry Point**: `GET /`  
**Exit Point**: Logged in at dashboard

**Data Requirements:**
```typescript
{
  firstName: string;
  lastName: string;
  username: string (unique);
  password: string (hashed with bcrypt);
  email?: string;
  phoneNumber?: string;
}
```

**Validation Rules:**
- Username must be unique
- Password minimum 8 characters
- Email format if provided
- First/last names non-empty

**Post-Signup:**
- Auto-login user (session created)
- Show onboarding dialog
- Redirect to dashboard
- Create default privacy level (if provided)

### 2. User Sign-In
**Flow**: Unauthenticated User → Login Form → Session Created → Dashboard

**Local Authentication:**
- Username + Password verification
- Bcrypt comparison
- Session cookie (connect.sid)
- Optional "Remember me" (30-day extension)

**Third-Party Authentication:**
- Auth0: OAuth2 redirect flow
- Okta: SAML/OAuth2
- Amazon Cognito: Amplify integration
- Google: Google Sign-In

**Session Behavior:**
- Default: Expires when browser closes
- Remember Me: Extends to 30 days
- Cookie name: `connect.sid`

### 3. User Sign-Out
**Flow**: Authenticated User → Logout → Session Destroyed → Login Page

**Actions:**
- Clear session
- Delete session cookie
- Redirect to signin page
- Clear in-memory auth state

### 4. Profile Management
**Available for authenticated users**

**View Profile**
- GET /users/:userId (own profile only)
- GET /users/profile/:username (public view)

**Edit Profile**
- PATCH /users/:userId
- Fields: firstName, lastName, email, phoneNumber, defaultPrivacyLevel

**Editable Fields:**
- firstName: User's given name
- lastName: User's family name
- email: Contact email
- phoneNumber: Contact phone
- defaultPrivacyLevel: public | private | contacts
- avatar: Avatar image URL

**Privacy Level Effects:**
- **public**: Transactions visible to all users
- **private**: Transactions visible only to sender/receiver
- **contacts**: Transactions visible to contacts + participants

## API Contracts

### POST /login
```http
POST /login HTTP/1.1
Content-Type: application/json

{
  "username": "johndoe",
  "password": "s3cret",
  "remember": true
}
```

**Response (200):**
```json
{
  "user": {
    "id": "s6rnpoi",
    "uuid": "uuid-string",
    "username": "johndoe",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "balance": 50000,
    "avatar": "https://example.com/avatar.jpg",
    "defaultPrivacyLevel": "contacts",
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Errors:**
- 401: Invalid credentials
- 422: Validation error (missing fields)

### GET /checkAuth
```http
GET /checkAuth HTTP/1.1
```

**Response (200 - Authenticated):**
```json
{
  "user": { /* User object */ }
}
```

**Response (401 - Unauthenticated):**
```json
{
  "error": "User is unauthorized"
}
```

### POST /logout
```http
POST /logout HTTP/1.1
```

**Response (302):** Redirect to `/`

### POST /users (Sign-Up)
```http
POST /users HTTP/1.1
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "username": "johndoe",
  "password": "s3cret",
  "email": "john@example.com",
  "phoneNumber": "+1-555-1234"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "s6rnpoi",
    "uuid": "uuid-string",
    "firstName": "John",
    "lastName": "Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "balance": 0,
    "avatar": "",
    "defaultPrivacyLevel": "public",
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Errors:**
- 422: Username exists, validation failures

### GET /users/:userId
```http
GET /users/s6rnpoi HTTP/1.1
Authorization: session (via cookie)
```

**Response (200):**
```json
{
  "user": { /* Full User object */ }
}
```

**Authorization:** Only own profile can be accessed

### GET /users/profile/:username
```http
GET /users/profile/johndoe HTTP/1.1
```

**Response (200):**
```json
{
  "user": {
    "firstName": "John",
    "lastName": "Doe",
    "avatar": "https://example.com/avatar.jpg"
  }
}
```

**Note:** Public profile - no balance, email, or sensitive info

### PATCH /users/:userId
```http
PATCH /users/s6rnpoi HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "firstName": "Jonathan",
  "email": "jonathan@example.com",
  "phoneNumber": "+1-555-5678",
  "defaultPrivacyLevel": "contacts"
}
```

**Response (204):** No content

**Scoping:** User can only update own profile

## Data Relationships

```
User (1)
├── Profile Info
│   ├── firstName
│   ├── lastName
│   ├── email
│   ├── phoneNumber
│   ├── avatar
│   └── defaultPrivacyLevel
├── Account Info
│   ├── username
│   ├── password (hashed)
│   ├── balance
│   ├── createdAt
│   └── modifiedAt
└── Session (when authenticated)
    ├── connect.sid
    ├── maxAge or expires
    └── user.id (serialized)

Transaction (N) -- User (1 as sender or receiver)
Notification (N) -- User (1 as recipient)
Contact (N) -- User (1 as owner)
BankAccount (N) -- User (1 as owner)
```

## Test Coverage

### API Tests
- ✅ User creation/signup
- ✅ Login/logout
- ✅ Profile retrieval (own and public)
- ✅ Profile updates
- ✅ Session persistence
- ✅ Authorization checks

### UI Tests
- ✅ Signup flow
- ✅ Login flow
- ✅ Logout flow
- ✅ Remember me functionality
- ✅ Session cookie verification
- ✅ Redirect to login when unauthorized
- ✅ Profile settings page

### Edge Cases
- Invalid credentials
- Duplicate username
- Session expiration
- Concurrent logins
- Third-party auth failures

## Security Considerations

1. **Password Handling**
   - Bcrypt hashing (no plaintext storage)
   - Minimum length validation
   - No password hints or recovery (for demo purposes)

2. **Session Security**
   - Hardcoded secret (demo only - NOT production)
   - httpOnly cookies
   - CORS enabled for frontend origin

3. **Third-Party Auth**
   - JWT token verification
   - Provider-specific validation
   - Token expiration handling

4. **User Scoping**
   - Cannot view other users' full profiles
   - Cannot update other users' profiles
   - Cannot see other users' transactions without privacy rules

## Implementation Notes

- Session-based authentication (Passport.js)
- User serialization: Only ID stored in session
- Password comparison: Synchronous bcrypt.compareSync()
- Default privacy level: Set during signup or via settings
- Avatar: External URL, not stored locally

## Related Features

- Contact Management (privacy rules)
- Bank Account Management (user scoping)
- Transaction Management (user filtering)
- Notification System (user targeting)

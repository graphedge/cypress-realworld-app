# Feature: Transaction Management

## Overview
Core payment transfer system supporting peer-to-peer payments, payment requests, and bank transfers with rich filtering, pagination, and social features.

## Transaction Types

### 1. Payment (Direct Transfer)
**Description**: Immediate transfer from sender to receiver  
**Status Flow**: pending → complete (or incomplete on error)  
**Balance Impact**: Immediate (sender -X, receiver +X)

**Request Body:**
```json
{
  "transactionType": "payment",
  "senderId": "user123",
  "receiverId": "user456",
  "amount": "10000",
  "description": "Coffee money",
  "privacyLevel": "public"
}
```

### 2. Payment Request
**Description**: Request funds from another user  
**Status Flow**: pending (request) → accepted/rejected → complete/incomplete  
**Balance Impact**: Only after acceptance

**Request Body:**
```json
{
  "transactionType": "request",
  "senderId": "user123",
  "receiverId": "user456",
  "amount": "50000",
  "description": "Dinner split",
  "privacyLevel": "contacts"
}
```

**Request Lifecycle:**
1. User A creates request to User B
2. User B receives payment notification
3. User B accepts → balance transferred
4. User B rejects → transaction marked rejected
5. Optional: Auto-timeout (configurable, currently manual)

### 3. Bank Transfer (Deposit/Withdrawal)
**Description**: Transfer between user wallet and linked bank account  
**Types**: deposit (bank → wallet), withdrawal (wallet → bank)  
**Source**: Bank account ID  
**Balance Impact**: Immediate (for demo purposes)

**Request Body (Deposit):**
```json
{
  "transactionType": "transfer",
  "senderId": "user123",
  "receiverId": "user123",
  "source": "bankaccount123",
  "amount": "100000",
  "description": "Deposit from First National",
  "privacyLevel": "private"
}
```

## Transaction Data Model

```typescript
{
  id: string;                              // Short ID (shortid)
  uuid: string;                            // UUID v4
  source: string;                          // Empty for P2P; Bank Account ID for transfers
  amount: number;                          // Cents (e.g., 10000 = $100.00)
  description: string;                     // Memo/note (user-provided)
  privacyLevel: 'public' | 'private' | 'contacts';
  receiverId: string;                      // User receiving funds
  senderId: string;                        // User initiating transfer
  balanceAtCompletion?: number;            // Balance after transaction completed
  status: 'pending' | 'incomplete' | 'complete';
  requestStatus?: 'pending' | 'accepted' | 'rejected';  // For requests only
  requestResolvedAt?: Date;                // When request was resolved
  createdAt: Date;                         // Transaction creation time
  modifiedAt: Date;                        // Last modification time
}
```

## API Endpoints

### POST /transactions - Create Transaction

```http
POST /transactions HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "transactionType": "payment",
  "senderId": "user123",
  "receiverId": "user456",
  "amount": "25000",
  "description": "Pizza dinner",
  "privacyLevel": "public"
}
```

**Response (200):**
```json
{
  "transaction": {
    "id": "s6rnpoi",
    "uuid": "123e4567-e89b-12d3-a456-426614174000",
    "amount": 25000,
    "description": "Pizza dinner",
    "privacyLevel": "public",
    "receiverId": "user456",
    "senderId": "user123",
    "balanceAtCompletion": 75000,
    "status": "complete",
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Validations:**
- Valid user IDs
- Amount > 0
- Sender has sufficient balance (for payments)
- Valid transaction type
- Description non-empty
- Privacy level valid

### GET /transactions - User's Transactions

```http
GET /transactions?page=1&limit=10&status=complete&dateRangeStart=2024-01-01&dateRangeEnd=2024-01-31 HTTP/1.1
Authorization: session
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number (1-based, default: 1) |
| limit | number | Items per page (default: 10) |
| status | enum | Filter: pending, incomplete, complete |
| requestStatus | enum | Filter: pending, accepted, rejected |
| dateRangeStart | ISO string | Filter by start date |
| dateRangeEnd | ISO string | Filter by end date |
| amountMin | number | Filter by minimum amount |
| amountMax | number | Filter by maximum amount |

**Response (200):**
```json
{
  "pageData": {
    "page": 1,
    "limit": 10,
    "hasNextPages": true,
    "totalPages": 5
  },
  "results": [
    {
      "id": "s6rnpoi",
      "amount": 10000,
      "description": "Coffee",
      "status": "complete",
      "privacyLevel": "public",
      "senderId": "user123",
      "receiverId": "user456",
      "senderName": "John Doe",
      "senderAvatar": "https://example.com/john.jpg",
      "receiverName": "Jane Smith",
      "receiverAvatar": "https://example.com/jane.jpg",
      "likes": [
        {
          "id": "like1",
          "userId": "user789",
          "transactionId": "s6rnpoi",
          "createdAt": "2024-01-15T10:05:00Z"
        }
      ],
      "comments": [
        {
          "id": "comment1",
          "content": "Great transaction!",
          "userId": "user789",
          "transactionId": "s6rnpoi",
          "createdAt": "2024-01-15T10:06:00Z"
        }
      ],
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

**Authorization:** Scoped to authenticated user's transactions as sender or receiver

### GET /transactions/contacts - Contact Transactions

```http
GET /transactions/contacts?page=1&limit=10 HTTP/1.1
Authorization: session
```

**Response (200):** Same format as GET /transactions

**Behavior:** Returns transactions involving user's contacts

### GET /transactions/public - Public Feed

```http
GET /transactions/public?page=1&limit=10 HTTP/1.1
Authorization: session
```

**Response (200):** Same format as GET /transactions

**Special Behavior:**
- First page (page=1) includes:
  - Up to 5 contact transactions (if any)
  - Public transactions (to fill limit)
- Subsequent pages: Only public transactions

### GET /transactions/:transactionId - Transaction Detail

```http
GET /transactions/s6rnpoi HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "transaction": {
    "id": "s6rnpoi",
    "uuid": "123e4567-e89b-12d3-a456-426614174000",
    "amount": 10000,
    "description": "Coffee",
    "status": "complete",
    "privacyLevel": "public",
    "senderId": "user123",
    "receiverId": "user456",
    "senderName": "John Doe",
    "senderAvatar": "https://example.com/john.jpg",
    "receiverName": "Jane Smith",
    "receiverAvatar": "https://example.com/jane.jpg",
    "balanceAtCompletion": 75000,
    "likes": [ /* Like[] */ ],
    "comments": [ /* Comment[] */ ],
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

### PATCH /transactions/:transactionId - Update Transaction

```http
PATCH /transactions/s6rnpoi HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "requestStatus": "accepted"
}
```

**Response (204):** No content

**Use Cases:**
- Accept payment request: `requestStatus: "accepted"`
- Reject payment request: `requestStatus: "rejected"`

## Filtering & Pagination

### Date Range Filtering
- Start date: ISO 8601 format (e.g., "2024-01-01")
- End date: ISO 8601 format (e.g., "2024-01-31")
- Filters transactions created within date range

### Amount Range Filtering
- Min amount: Numeric (cents)
- Max amount: Numeric (cents)
- Filters transactions within amount range

### Status Filtering
- transaction status: pending, incomplete, complete
- requestStatus: pending, accepted, rejected

### Pagination
- Page-based (1-based indexing)
- Default: 10 items per page
- Configurable via limit parameter
- hasNextPages indicates more pages exist
- totalPages: Total number of pages

## Privacy & Visibility Rules

### Public Transactions
- Visible to: All authenticated users
- Default for user's defaultPrivacyLevel = "public"

### Private Transactions
- Visible to: Only sender and receiver
- Cannot appear in public feed
- Will not show in other users' feeds

### Contact Transactions
- Visible to: Sender, receiver, and both users' contacts
- Shows on contact transaction feed
- May appear on public feed first page (contact section)

### Visibility Decision Tree
```
Is transaction private?
  → Yes: Only sender/receiver see it
  → No:

Is viewing user = sender or receiver?
  → Yes: Always visible
  → No:

Is privacyLevel = public?
  → Yes: Visible
  → No:

Is privacyLevel = contacts?
  → Is viewer a contact of sender or receiver?
    → Yes: Visible
    → No: Hidden
```

## Related Features

### Likes & Comments
- Transactions can receive likes (not applicable to private transactions)
- Transactions can receive comments (restricted by privacy)
- Likes/comments trigger notifications

### Notifications
- Payment request created → receiver notification
- Payment request accepted → sender notification
- Payment request rejected → sender notification

### Balance Updates
- Immediate for payments and bank transfers
- Only after request acceptance for payment requests
- Withdrawal limited by current balance

## Test Coverage

### API Tests (169 lines total)
- ✅ GET /transactions - List personal transactions
- ✅ GET /transactions/contacts - List contact transactions
- ✅ GET /transactions/public - List public feed
- ✅ GET /transactions/:id - Get transaction detail
- ✅ POST /transactions - Create payment
- ✅ POST /transactions - Create request
- ✅ POST /transactions - Create bank transfer
- ✅ PATCH /transactions/:id - Accept request
- ✅ PATCH /transactions/:id - Reject request
- ✅ Pagination with various page/limit combinations
- ✅ Date range filtering
- ✅ Amount range filtering
- ✅ Status filtering

### UI Tests (17,815 lines estimated)
- ✅ Transaction feed display
- ✅ Create transaction flows
- ✅ Request acceptance/rejection
- ✅ Filter application
- ✅ Pagination navigation
- ✅ Privacy filtering
- ✅ Empty state handling
- ✅ Error handling
- ✅ Form validation

## Implementation Notes

- Amount stored in cents (integer, no decimals)
- Transaction IDs: shortid library (7-char alphanumeric)
- UUIDs: uuid library v4
- Timestamps: ISO 8601 format
- Status updates are idempotent (accepting twice = no change)
- Cannot modify completed transactions
- Cannot modify rejected requests

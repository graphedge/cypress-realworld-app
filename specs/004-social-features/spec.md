# Feature: Social Features (Likes, Comments, Notifications)

## Overview
Social interaction system allowing users to like and comment on transactions, with notification alerts for engagement and transaction events.

## Likes Feature

### Overview
Users can express appreciation for transactions by "liking" them. Likes are engagement indicators and trigger notifications.

### Like Data Model

```typescript
{
  id: string;              // Short ID
  uuid: string;            // UUID
  userId: string;          // User who liked
  transactionId: string;   // Transaction being liked
  createdAt: Date;
  modifiedAt: Date;
}
```

### Like Rules

1. **One Like Per User Per Transaction**: Each user can like a transaction once
2. **Public Transactions Only**: Cannot like private transactions
3. **Contact Visibility**: Can like contact-level transactions if contact rule applies
4. **Idempotency**: Multiple POST requests to same endpoint don't create duplicate likes

### API Endpoints

#### POST /likes/:transactionId
```http
POST /likes/s6rnpoi HTTP/1.1
Authorization: session
```

**Response (200):** No body

**Behavior:**
- If user hasn't liked: Like created
- If user already liked: No action (idempotent)
- Triggers notification to transaction creator

**Validations:**
- Valid transaction ID
- Transaction not private (or user is participant/contact)
- Authenticated user

#### GET /likes/:transactionId
```http
GET /likes/s6rnpoi HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "likes": [
    {
      "id": "like1",
      "uuid": "uuid-string",
      "userId": "user123",
      "transactionId": "s6rnpoi",
      "createdAt": "2024-01-15T10:05:00Z",
      "modifiedAt": "2024-01-15T10:05:00Z"
    }
  ]
}
```

## Comments Feature

### Overview
Users can leave text comments on transactions to discuss and provide context. Comments trigger notifications and appear on transaction details.

### Comment Data Model

```typescript
{
  id: string;              // Short ID
  uuid: string;            // UUID
  content: string;         // Comment text
  userId: string;          // Comment author
  transactionId: string;   // Commented transaction
  createdAt: Date;
  modifiedAt: Date;
}
```

### Comment Rules

1. **One Comment Per Request**: Users can add multiple comments (one per POST request)
2. **Visibility**: Subject to transaction privacy rules
3. **Read-Only**: Comments cannot be edited after creation
4. **No Deletion**: Comments are permanent (for demo purposes)
5. **Chronological Display**: Comments shown in creation order

### API Endpoints

#### POST /comments/:transactionId
```http
POST /comments/s6rnpoi HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "content": "Great payment, thanks!"
}
```

**Response (200):** No body

**Behavior:**
- Comment created and stored
- Triggers notification to transaction participants
- Immediately visible on transaction

**Validations:**
- Valid transaction ID
- Non-empty content
- Authenticated user
- Transaction privacy rules apply

**Content Constraints:**
- Required: Yes
- Max length: Typically 500 characters (app may limit)
- Formatting: Plain text (no markdown/HTML)

#### GET /comments/:transactionId
```http
GET /comments/s6rnpoi HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "comments": [
    {
      "id": "comment1",
      "uuid": "uuid-string",
      "content": "Great transaction!",
      "userId": "user123",
      "transactionId": "s6rnpoi",
      "createdAt": "2024-01-15T10:06:00Z",
      "modifiedAt": "2024-01-15T10:06:00Z"
    },
    {
      "id": "comment2",
      "uuid": "uuid-string",
      "content": "Thanks for this!",
      "userId": "user456",
      "transactionId": "s6rnpoi",
      "createdAt": "2024-01-15T10:07:00Z",
      "modifiedAt": "2024-01-15T10:07:00Z"
    }
  ]
}
```

**Ordering:** Chronological (oldest first)

## Notifications Feature

### Overview
Real-time notification system alerting users to:
1. Payment requests and their resolution
2. Likes on their transactions
3. Comments on their transactions

### Notification Types

#### 1. Payment Notification
**Trigger Events:**
- Payment request created (status: requested)
- Payment received (status: received)
- Payment incomplete (status: incomplete)

**Data:**
```typescript
{
  id: string;
  uuid: string;
  userId: string;           // Recipient
  transactionId: string;    // Related transaction
  status: 'requested' | 'received' | 'incomplete';
  isRead: boolean;
  createdAt: Date;
  modifiedAt: Date;
  // Response includes:
  userFullName: string;     // Actor's name
}
```

#### 2. Like Notification
**Trigger Event:** User likes a transaction you participated in or own

**Data:**
```typescript
{
  id: string;
  uuid: string;
  userId: string;           // Recipient
  transactionId: string;    // Transaction liked
  likeId: string;           // Like object ID
  isRead: boolean;
  createdAt: Date;
  modifiedAt: Date;
  // Response includes:
  userFullName: string;     // Liker's name
}
```

#### 3. Comment Notification
**Trigger Event:** User comments on a transaction you participated in or own

**Data:**
```typescript
{
  id: string;
  uuid: string;
  userId: string;           // Recipient
  transactionId: string;    // Transaction commented on
  commentId: string;        // Comment object ID
  isRead: boolean;
  createdAt: Date;
  modifiedAt: Date;
  // Response includes:
  userFullName: string;     // Commenter's name
}
```

### Notification Rules

1. **Unread by Default**: New notifications have isRead = false
2. **Recipient Scoping**: Users only see notifications sent to them
3. **No Duplicates**: System should prevent duplicate notifications (per event)
4. **Permanent Record**: Notifications not deleted (only marked read)
5. **Cross-Feature**: Likes/comments on transactions create notifications

### API Endpoints

#### GET /notifications
```http
GET /notifications HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "results": [
    {
      "id": "notif1",
      "uuid": "uuid-string",
      "userId": "user123",
      "transactionId": "s6rnpoi",
      "status": "requested",
      "isRead": false,
      "createdAt": "2024-01-15T10:00:00Z",
      "modifiedAt": "2024-01-15T10:00:00Z",
      "userFullName": "John Doe"
    }
  ]
}
```

**Behavior:**
- Returns unread notifications only
- Scoped to authenticated user
- Includes actor's full name
- Ordered by creation (newest first, typically)

#### POST /notifications/bulk
```http
POST /notifications/bulk HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "items": [
    {
      "type": "payment",
      "transactionId": "s6rnpoi",
      "status": "requested"
    },
    {
      "type": "like",
      "transactionId": "s6rnpoi",
      "likeId": "like1"
    },
    {
      "type": "comment",
      "transactionId": "s6rnpoi",
      "commentId": "comment1"
    }
  ]
}
```

**Response (200):**
```json
{
  "results": [
    { /* notification objects */ }
  ]
}
```

**Use**: Batch create multiple notifications (typically internal/backend usage)

#### PATCH /notifications/:notificationId
```http
PATCH /notifications/notif1 HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "isRead": true
}
```

**Response (204):** No content

**Behavior:**
- Updates read status
- Returns 204 on success
- Idempotent (marking already-read as read = no change)

## Notification Triggers

### When Likes Are Created
```
User A likes Transaction T
  ↓
System creates Like object
  ↓
If T.senderId = User B → Create notification for User B
  ↓
Notification.type = "like"
Notification.likeId = <Like.id>
Notification.userFullName = User A name
```

### When Comments Are Created
```
User A comments on Transaction T
  ↓
System creates Comment object
  ↓
If T.senderId = User B → Create notification for User B
If T.receiverId = User C → Create notification for User C
  ↓
Notification.type = "comment"
Notification.commentId = <Comment.id>
Notification.userFullName = User A name
```

### When Payment Requests Are Made
```
User A requests payment from User B
  ↓
System creates Transaction with status = "pending"
  ↓
Create notification for User B
  ↓
Notification.type = "payment"
Notification.status = "requested"
Notification.userFullName = User A name
```

### When Payment Requests Are Resolved
```
User B accepts/rejects request from User A
  ↓
System updates Transaction.requestStatus
  ↓
Create notification for User A
  ↓
Notification.status = "received" (accepted) or "incomplete" (rejected)
Notification.userFullName = User B name
```

## Privacy Considerations

- **Private Transactions**: Like/comment notifications not created if transaction is private (unless user is participant)
- **Contact Transactions**: Notifications follow contact visibility rules
- **Public Transactions**: All likes/comments create notifications

## Test Coverage

### API Tests (Total: 140 lines)

**Likes Tests (53 lines)**
- ✅ POST /likes/:transactionId - Add like
- ✅ POST /likes/:transactionId - Idempotent (no duplicate)
- ✅ GET /likes/:transactionId - Get likes list
- ✅ Authorization checks

**Comments Tests (55 lines)**
- ✅ POST /comments/:transactionId - Add comment
- ✅ POST /comments/:transactionId - Multiple comments
- ✅ GET /comments/:transactionId - Get comments
- ✅ Content validation (non-empty)
- ✅ Authorization checks

**Notifications Tests (107 lines)**
- ✅ GET /notifications - List unread notifications
- ✅ POST /notifications/bulk - Create multiple
- ✅ PATCH /notifications/:id - Mark as read
- ✅ Filtering by type
- ✅ Scoping to current user
- ✅ Notification creation on like
- ✅ Notification creation on comment
- ✅ Notification creation on request

### UI Tests

**Transaction View Tests**
- ✅ Display likes count
- ✅ Display comments list
- ✅ Like button interaction
- ✅ Comment form
- ✅ Comment submission
- ✅ Like/comment notifications badge

**Notification Panel Tests**
- ✅ List notifications
- ✅ Mark as read
- ✅ Notification count badge
- ✅ Navigate to transaction from notification
- ✅ Different notification types display

## Implementation Notes

- Notifications are read-only (no updates except isRead)
- Like/comment notifications created within transaction operations
- Bulk notification creation is typically internal
- userFullName fetched at notification creation time (denormalized)
- No soft deletes for likes/comments (permanent once created)
- Timestamps in ISO 8601 format

## Related Features

- Transaction Management (trigger source)
- User Authentication (user scoping)
- Contact Management (privacy rules)

# Feature: Bank Accounts & Transfers

## Overview
User financial account management system enabling bank account linking and fund transfers between user wallets and external bank accounts.

## Bank Account Management

### Bank Account Data Model

```typescript
{
  id: string;              // Short ID (shortid)
  uuid: string;            // UUID v4
  userId: string;          // Account owner
  bankName: string;        // Financial institution name
  accountNumber: string;   // Account number (typically obfuscated for display)
  routingNumber: string;   // Bank routing number
  isDeleted: boolean;      // Soft delete flag
  createdAt: Date;
  modifiedAt: Date;
}
```

### Bank Account Rules

1. **User Ownership**: Each account belongs to exactly one user
2. **Multiple Accounts**: User can link multiple bank accounts
3. **Soft Deletion**: Deleted accounts marked with isDeleted = true (not removed)
4. **Immutable Fields**: Cannot edit account/routing numbers (must delete and recreate)
5. **Unique Pair**: User typically maintains one account per bank (not enforced)

### API Endpoints

#### GET /bankAccounts
```http
GET /bankAccounts HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "results": [
    {
      "id": "ba1234",
      "uuid": "uuid-string",
      "userId": "user123",
      "bankName": "Chase Bank",
      "accountNumber": "****5678",
      "routingNumber": "021000021",
      "isDeleted": false,
      "createdAt": "2024-01-10T08:00:00Z",
      "modifiedAt": "2024-01-10T08:00:00Z"
    }
  ]
}
```

**Authorization:** Scoped to authenticated user's accounts

#### GET /bankAccounts/:bankAccountId
```http
GET /bankAccounts/ba1234 HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "account": {
    "id": "ba1234",
    "uuid": "uuid-string",
    "userId": "user123",
    "bankName": "Chase Bank",
    "accountNumber": "****5678",
    "routingNumber": "021000021",
    "isDeleted": false,
    "createdAt": "2024-01-10T08:00:00Z",
    "modifiedAt": "2024-01-10T08:00:00Z"
  }
}
```

**Authorization:** User can only retrieve own accounts

#### POST /bankAccounts
```http
POST /bankAccounts HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "bankName": "First National Bank",
  "accountNumber": "123456789",
  "routingNumber": "021000021"
}
```

**Response (200):**
```json
{
  "account": {
    "id": "ba5678",
    "uuid": "uuid-string",
    "userId": "user123",
    "bankName": "First National Bank",
    "accountNumber": "123456789",
    "routingNumber": "021000021",
    "isDeleted": false,
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Validations:**
- Required fields: bankName, accountNumber, routingNumber
- Account number format (numeric)
- Routing number format (9 digits)
- Bank name non-empty

#### DELETE /bankAccounts/:bankAccountId
```http
DELETE /bankAccounts/ba1234 HTTP/1.1
Authorization: session
```

**Response (200):**
```json
{
  "account": {
    "id": "ba1234",
    "uuid": "uuid-string",
    "userId": "user123",
    "bankName": "Chase Bank",
    "accountNumber": "****5678",
    "routingNumber": "021000021",
    "isDeleted": true,
    "createdAt": "2024-01-10T08:00:00Z",
    "modifiedAt": "2024-01-15T10:02:00Z"
  }
}
```

**Behavior:** Soft deletes account (sets isDeleted = true)

**Authorization:** User can only delete own accounts

## Bank Transfers

### Bank Transfer Data Model

```typescript
{
  id: string;              // Short ID
  uuid: string;            // UUID
  userId: string;          // Transfer initiator
  source: string;          // Bank Account ID
  amount: number;          // Cents
  type: 'deposit' | 'withdrawal';
  transactionId: string;   // Associated transaction
  createdAt: Date;
  modifiedAt: Date;
}
```

### Bank Transfer Types

#### Deposit
- **Direction**: Bank Account → User Wallet
- **Balance Effect**: Increases user balance
- **Use Case**: Adding funds to app account
- **Type Value**: "deposit"

**Flow:**
```
User selects bank account
  ↓
User enters amount to deposit
  ↓
System verifies account exists and is not deleted
  ↓
Create transaction with source = bankAccountId
  ↓
Create bank transfer record
  ↓
Update user balance += amount
  ↓
Set transaction status = complete
```

#### Withdrawal
- **Direction**: User Wallet → Bank Account
- **Balance Effect**: Decreases user balance
- **Constraint**: Cannot exceed current balance
- **Use Case**: Transferring app funds to bank
- **Type Value**: "withdrawal"

**Flow:**
```
User selects bank account
  ↓
User enters amount to withdraw
  ↓
System verifies:
  1. Account exists and not deleted
  2. User balance >= amount
  ↓
Create transaction with source = bankAccountId
  ↓
Create bank transfer record
  ↓
Update user balance -= amount
  ↓
Set transaction status = complete
```

### Bank Transfer Creation

Bank transfers are created implicitly through the transaction creation endpoint:

```http
POST /transactions HTTP/1.1
Content-Type: application/json
Authorization: session

{
  "transactionType": "transfer",
  "senderId": "user123",
  "receiverId": "user123",
  "source": "ba1234",
  "amount": "100000",
  "description": "Deposit from Chase",
  "privacyLevel": "private"
}
```

**Response (200):**
```json
{
  "transaction": {
    "id": "txn123",
    "uuid": "uuid-string",
    "source": "ba1234",
    "amount": 100000,
    "description": "Deposit from Chase",
    "privacyLevel": "private",
    "senderId": "user123",
    "receiverId": "user123",
    "balanceAtCompletion": 150000,
    "status": "complete",
    "createdAt": "2024-01-15T10:00:00Z",
    "modifiedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Behind the scenes:**
- Transaction created with type "transfer"
- BankTransfer record created
- Balance updated immediately
- Type inferred from senderId = receiverId + source field

### Bank Transfer Validation

**For All Transfers:**
- Valid bank account ID
- Account not deleted (isDeleted = false)
- Positive amount
- Account owned by current user

**For Withdrawals:**
- Current user balance >= withdrawal amount
- Bank account exists and is active

### Privacy of Bank Transfers

Bank transfers default to:
- **Privacy Level**: private (not visible to other users)
- **Visibility**: Only user and transaction system
- **Appearance**: May appear in user's own transaction history
- **Social Features**: Disabled for bank transfers (no likes/comments typically)

## GraphQL API Support

### Bank Account GraphQL Mutations

```graphql
type Query {
  listBankAccount: [BankAccount!]
}

type Mutation {
  createBankAccount(
    bankName: String!
    accountNumber: String!
    routingNumber: String!
  ): BankAccount
  
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

**Note:** GraphQL interface is optional/secondary; REST API is primary

## Data Relationships

```
BankAccount (N) -- (1) User
└── Created by: User account linkage
└── Used in: Bank Transfer creation
└── Source for: Transaction records

BankTransfer (N) -- (1) BankAccount
└── Links to: Bank account details
└── Records: Deposit/withdrawal activity

Transaction (1) -- (N) BankTransfer
└── Parent record: Transaction
└── Detail record: BankTransfer
└── Linked via: source field in transaction

User Balance
├── Updated by: Payment transactions
├── Updated by: Bank deposits
└── Updated by: Bank withdrawals
```

## Test Coverage

### API Tests (149 lines total)

**Bank Account CRUD Tests**
- ✅ GET /bankAccounts - List accounts
- ✅ GET /bankAccounts/:id - Get single account
- ✅ POST /bankAccounts - Create account
- ✅ DELETE /bankAccounts/:id - Delete account
- ✅ Field validation (account/routing number format)
- ✅ User scoping (cannot access other users' accounts)
- ✅ Soft deletion behavior
- ✅ Multiple accounts per user

### UI Tests (6,600 lines estimated)

**Bank Account Management UI**
- ✅ List bank accounts
- ✅ Add new bank account form
- ✅ Form field validation
- ✅ Delete bank account confirmation
- ✅ Soft deletion display (greyed out / marked deleted)
- ✅ Error handling
- ✅ Empty state (no accounts)

**Bank Transfer UI**
- ✅ Deposit form
- ✅ Withdrawal form
- ✅ Amount validation
- ✅ Insufficient balance error
- ✅ Account selection
- ✅ Balance update after transfer
- ✅ Transfer confirmation

## Implementation Notes

- **Immutability**: Account numbers and routing numbers cannot be edited (delete and recreate pattern)
- **Soft Deletes**: Accounts marked deleted but not removed (maintains referential integrity)
- **Obfuscation**: Display typically shows last 4 digits only
- **IDs**: Bank accounts use shortid library (7-char alphanumeric)
- **Balance**: User balance updated immediately (not pending)
- **Privacy**: Bank transfers default to private
- **Transactions**: Each bank transfer creates associated transaction record for audit trail

## Constraints & Limitations

1. **No Real Banking**: Demo application only (no real fund transfers)
2. **No Authentication**: Bank account data not verified with actual banks
3. **Balance Simulation**: All transfers are immediate (no processing delays)
4. **No Overdraft Protection**: Withdrawal strictly limited by balance
5. **No Fee Calculation**: No bank fees or transaction charges
6. **No Recurring**: One-time transfers only

## Related Features

- User Authentication (account ownership)
- Transaction Management (transfer creation, balance updates)
- User Search (for multi-user scenarios)
- Notifications (optional: transfer alerts)

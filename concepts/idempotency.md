# Idempotency — Complete Guide

## 1. Core Concept

Idempotency means that making the same request multiple times produces the same final outcome as making it once.

The key idea is not "execute once," but **"side effects happen only once."**

**Payment Example:**

A user clicks "Pay ₹500" for Order #1234. The request is sent, the server charges the card, but the success response is lost due to a network timeout. The client retries. Without idempotency, the user gets charged ₹1000. With idempotency, the server recognizes the duplicate and returns the original success response — user is charged only ₹500.

---

## 2. Goal of Idempotency

The goal is to achieve **exactly-once side effects** in systems where requests may be delivered multiple times (at-least-once delivery).

In a payment system, "exactly-once" means:

- The customer's card is charged exactly once
- The merchant receives payment exactly once
- The transaction record is created exactly once

Even if the network, client, or infrastructure causes the request to arrive 2, 3, or 10 times.

---

## 3. Why Idempotency is Needed

In real systems, duplicate requests happen frequently due to:

| Cause | Payment Example |
|-------|----------------|
| User double-clicks | User taps "Pay" twice quickly on mobile |
| Network timeouts | Payment processed but response never reaches client |
| Automatic retries by clients/SDKs | Stripe SDK retries after 30s timeout |
| Load balancer retries | ALB retries request to another server after 502 |
| Success response lost | Server crashes after charging card but before responding |

Without idempotency, each of these leads to duplicate charges — the worst possible experience in a payment system.

---

## 4. Idempotency Key (Client Responsibility)

The client generates and sends a unique idempotency key with each request. This key identifies a specific operation attempt, allowing the server to detect duplicates.

**Payment Example:**

```json
POST /payments
Headers:
  Idempotency-Key: pay_a1b2c3d4e5

Body:
{
  "orderId": "order_1234",
  "amount": 500,
  "currency": "INR",
  "customerId": "cust_789"
}
```

If the client retries this request (same `Idempotency-Key`), the server knows it's a duplicate and returns the stored response instead of charging again.

**Key generation strategies:**

- UUID v4: `550e8400-e29b-41d4-a716-446655440000`
- Deterministic: `hash(userId + orderId + amount + timestamp)` — same inputs always produce the same key, useful when the client might crash and retry without remembering the key

---

## 5. Business ID vs Idempotency Key

A business identifier (like `orderId`) represents an entity. An idempotency key represents a **request attempt**.

**Why using only orderId is dangerous:**

```
Request 1: Pay ₹500 for order_1234        → idempotency_key: "pay_abc"
Request 2: Refund ₹500 for order_1234      → idempotency_key: "refund_xyz"
Request 3: Retry payment for order_1234    → idempotency_key: "pay_abc" (same as Request 1)
```

If you used `orderId` alone as the deduplication key, Request 2 (refund) would be incorrectly treated as a duplicate of Request 1 (payment). The idempotency key distinguishes different operations on the same entity.

---

## 6. Idempotency Storage Model

The server stores the key along with metadata:

```json
{
  "idempotencyKey": "pay_a1b2c3d4e5",
  "status": "SUCCESS",
  "requestHash": "sha256_of_request_body",
  "response": {
    "paymentId": "txn_98765",
    "status": "captured",
    "amount": 500
  },
  "createdAt": "2025-01-15T10:30:00Z",
  "expiresAt": "2025-01-16T10:30:00Z"
}
```

| Field | Purpose |
|-------|---------|
| status | Track whether request is IN_PROGRESS, SUCCESS, or FAILED |
| response | Stored response to replay for duplicates |
| requestHash | Detect if same key is reused with different payload |
| expiresAt | TTL for cleanup |

---

## 7. Request Handling Flow

When a payment request arrives:

```
Client sends: POST /payments with Idempotency-Key: "pay_abc"

Server checks storage:
├── Key doesn't exist     → Insert key (IN_PROGRESS), process payment, update to SUCCESS
├── Key exists, SUCCESS   → Return stored response (no reprocessing)
├── Key exists, FAILED    → Allow retry or return failure
└── Key exists, IN_PROGRESS → Return 409 "Request in progress, retry later"
```

**Payment flow in detail:**

1. Client sends payment request with key `pay_abc`
2. Server atomically inserts `pay_abc` with status `IN_PROGRESS`
3. Server calls payment gateway (e.g., Razorpay/Stripe) to charge card
4. Gateway returns success → server updates record to `SUCCESS` with response
5. Server returns payment confirmation to client

If client retries with same key → server finds `SUCCESS` → returns stored confirmation without calling gateway again.

---

## 8. Atomicity (Critical Concept)

The check-and-insert must be a single atomic operation. If you do:

```
Step 1: SELECT * FROM idempotency WHERE key = 'pay_abc'   → not found
Step 2: INSERT INTO idempotency (key, status) VALUES ('pay_abc', 'IN_PROGRESS')
```

Between Step 1 and Step 2, another identical request can also see "not found" and proceed. Both requests now charge the card.

**Correct approach — single atomic operation:**

```sql
INSERT INTO idempotency (key, status, created_at)
VALUES ('pay_abc', 'IN_PROGRESS', NOW())
ON CONFLICT (key) DO NOTHING;
```

If the insert succeeds (1 row affected) → you own the request, proceed.
If it fails (0 rows affected) → duplicate, look up stored response.

---

## 9. Race Conditions

**Scenario:** Two identical payment requests arrive at two different servers simultaneously.

```
Time 0ms: Server A receives pay_abc → checks DB → not found
Time 1ms: Server B receives pay_abc → checks DB → not found
Time 2ms: Server A inserts pay_abc → success
Time 3ms: Server B inserts pay_abc → ??? 
```

Without atomic insert: both proceed → double charge.
With atomic insert (UNIQUE constraint or conditional write): Server B's insert fails → it knows it's a duplicate.

---

## 10. SQL Implementation

Use a UNIQUE constraint on the idempotency key column:

```sql
CREATE TABLE idempotency_store (
    idempotency_key VARCHAR(255) PRIMARY KEY,
    status VARCHAR(20) NOT NULL,  -- IN_PROGRESS, SUCCESS, FAILED
    request_hash VARCHAR(64) NOT NULL,
    response_body JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);
```

**Processing a payment:**

```sql
-- Atomic insert (only one request wins)
INSERT INTO idempotency_store (idempotency_key, status, request_hash, expires_at)
VALUES ('pay_abc', 'IN_PROGRESS', 'sha256_hash_here', NOW() + INTERVAL '24 hours')
ON CONFLICT (idempotency_key) DO NOTHING;

-- Check if we won the insert
-- If affected rows = 1 → proceed with payment
-- If affected rows = 0 → fetch existing record and return stored response
```

---

## 11. DynamoDB Implementation

Use conditional writes with `attribute_not_exists`:

```json
{
  "TableName": "IdempotencyStore",
  "Item": {
    "idempotencyKey": { "S": "pay_abc" },
    "status": { "S": "IN_PROGRESS" },
    "requestHash": { "S": "sha256_hash" },
    "ttl": { "N": "1705401600" }
  },
  "ConditionExpression": "attribute_not_exists(idempotencyKey)"
}
```

- If condition passes → item inserted, you own the request
- If `ConditionalCheckFailedException` → duplicate detected, fetch existing record

This provides the same atomic guarantee as SQL's UNIQUE constraint but in a distributed NoSQL database.

---

## 12. Response Replay

For duplicate requests, always return the **exact same response** as the original.

**Payment Example:**

```
Original request  → charges card → returns { paymentId: "txn_98765", status: "captured" }
Duplicate request → skips charge → returns { paymentId: "txn_98765", status: "captured" }
```

The client cannot distinguish between the original and replayed response. This ensures deterministic, predictable behavior — the client's retry logic works correctly regardless of whether the request was actually processed or replayed.

---

## 13. IN_PROGRESS State

Used when a request is still being processed and another identical request arrives.

**Payment Example:**

```
Time 0s:  Request A arrives → key inserted as IN_PROGRESS → calls Stripe API
Time 2s:  Request B arrives (retry) → finds key IN_PROGRESS
Time 2s:  Server responds to B: "Payment in progress, retry after 5 seconds"
Time 4s:  Stripe responds to A → key updated to SUCCESS
Time 7s:  Request B retries → finds key SUCCESS → gets stored response
```

Without IN_PROGRESS state, Request B might assume the payment failed and try to create a new one.

---

## 14. Failure Handling (Crash Scenario)

If the system crashes after marking IN_PROGRESS but before completing:

```
1. Server inserts key as IN_PROGRESS
2. Server calls payment gateway
3. *** SERVER CRASHES ***
4. Key is stuck as IN_PROGRESS forever
5. All retries see IN_PROGRESS → "retry later" → never resolves
```

The payment may or may not have been charged at the gateway — we don't know.

---

## 15. Recovery Strategies

To handle stuck IN_PROGRESS records:

| Strategy | How It Works |
|----------|-------------|
| Timeout-based recovery | If IN_PROGRESS for > 5 minutes, mark as FAILED and allow retry |
| External verification | Check with payment gateway if charge actually happened |
| Background worker | Periodically scans for stale IN_PROGRESS records and resolves them |

**Payment recovery example:**

```
1. Background job finds: key "pay_abc", status IN_PROGRESS, created 10 minutes ago
2. Calls Stripe: "Did charge for pay_abc succeed?"
3. Stripe says: "Yes, txn_98765 was captured"
4. Updates record: status → SUCCESS, response → { paymentId: "txn_98765" }
5. Next client retry gets the correct stored response
```

---

## 16. External Reconciliation

In payment systems, your database might disagree with the payment gateway's state. Reconciliation fixes this.

**Scenarios:**

| Your DB says | Gateway says | Reality | Action |
|-------------|-------------|---------|--------|
| IN_PROGRESS | Charged | Payment succeeded, you crashed before saving | Mark SUCCESS |
| IN_PROGRESS | No record | Payment never reached gateway | Mark FAILED, allow retry |
| SUCCESS | Charged | All good | No action |
| SUCCESS | Refunded | Refund happened outside your system | Update your records |

**Implementation:** Run a reconciliation job periodically (every few minutes) that compares your transaction records with the gateway's records and fixes mismatches.

---

## 17. Expiry (TTL)

Idempotency keys should expire to:

- Prevent unbounded storage growth
- Allow legitimate re-attempts after a safe window

**TTL guidelines for payments:**

| Scenario | Suggested TTL |
|----------|--------------|
| Standard payment | 24 hours |
| High-value transaction | 48-72 hours |
| Subscription renewal | Until next billing cycle |

After TTL expires, the same key can be used again — but by then, the original operation is long settled and a new attempt would be a genuinely new request.

---

## 18. Payload Validation

If the same idempotency key is reused with a different request body, it could indicate a bug or misuse.

**Dangerous scenario:**

```
Request 1: key="pay_abc", body={ amount: 500, orderId: "order_1" }  → SUCCESS
Request 2: key="pay_abc", body={ amount: 9999, orderId: "order_2" } → ???
```

Without validation, Request 2 would get the stored response for a ₹500 payment — confusing and incorrect.

**Solution:** Store a hash of the request body. On duplicate detection, compare hashes:

```
stored_hash = sha256(original_request_body)
incoming_hash = sha256(new_request_body)

if stored_hash != incoming_hash:
    return 422 "Idempotency key reused with different payload"
```

---

## 19. Retry vs Idempotency

| Concept | Who | What |
|---------|-----|------|
| Retry | Client-side mechanism | "I'll send this again because I didn't get a response" |
| Idempotency | Server-side guarantee | "No matter how many times you send this, I'll only process it once" |

They work together:

- Retries ensure the request eventually gets through (availability)
- Idempotency ensures duplicate deliveries don't cause duplicate side effects (correctness)

**Payment analogy:** Retry is the customer saying "I'll swipe my card again." Idempotency is the terminal saying "I already processed this — here's your receipt again."

---

## 20. Cleanup Strategy

TTL removes old records, but:

- In DynamoDB, TTL deletion is eventual (can take up to 48 hours after expiry)
- In SQL, you need a scheduled job: `DELETE FROM idempotency_store WHERE expires_at < NOW()`

**Important:** Never rely on cleanup for correctness. The system must work correctly whether old records exist or not. Cleanup is purely for storage management.

---

## 21. Multi-Region Challenges

In multi-region deployments:

```
Region A (Mumbai):  Receives pay_abc → inserts to local DB → charges card
Region B (Singapore): Receives pay_abc (retry routed differently) → checks local DB → not found!
```

Because replication between regions is eventual, Region B doesn't see Region A's record yet. Result: double charge.

---

## 22. Multi-Region Solutions

| Approach | Tradeoff |
|----------|----------|
| Route by key | Hash idempotency key to always reach same region. Adds latency for some users. |
| Single write region | All writes go to one region. Simpler but higher latency for distant users. |
| Accept rare duplicates + reconcile | Fastest for users. Requires background reconciliation to detect and refund duplicates. |

**Payment systems typically choose:** Route by key or single write region — because duplicate charges are unacceptable and refunds create bad user experience.

---

## 23. Why In-Memory Locks Fail

```java
// This does NOT work for distributed idempotency
synchronized(idempotencyKey) {
    if (!processed(key)) {
        processPayment();
    }
}
```

**Problems:**

- Only works within one server instance — useless when you have multiple servers behind a load balancer
- Lost on server restart/crash
- Doesn't survive deployments

**What works:** External atomic storage (database with unique constraints, DynamoDB conditional writes, Redis with `SET NX`).

---

## 24. Where to Implement Idempotency

Best place: **service layer** (not controller, not repository).

```
Controller (HTTP layer)
  → Extracts idempotency key from headers
  
Service layer ← IDEMPOTENCY CHECK HERE
  → Checks/inserts key atomically
  → Calls payment gateway
  → Stores response
  
Repository (DB layer)
  → Handles persistence
```

**Why service layer:**

- It understands business logic (what constitutes a "side effect")
- It can manage state transitions (IN_PROGRESS → SUCCESS/FAILED)
- It coordinates between external calls (gateway) and internal storage

---

## 25. Tradeoffs

| Decision | Option A | Option B |
|----------|----------|----------|
| Consistency vs Latency | Check idempotency synchronously (slower, safer) | Check async (faster, risk of duplicates) |
| Storage vs Safety | Keep records forever (safe, expensive) | TTL-based expiry (cheaper, small risk window) |
| Simplicity vs Correctness | Use orderId as key (simple, risky) | Separate idempotency key (complex, correct) |
| Availability vs Correctness | Process if idempotency store is down (available, risky) | Reject requests if store is down (correct, less available) |

**For payment systems:** Always lean toward correctness. A failed payment can be retried. A duplicate charge erodes trust.

---

## 26. Final Mental Model

Idempotency is a mechanism to ensure **exactly-once side effects** in distributed systems by combining:

1. **Atomic state management** — only one request wins the race
2. **Request deduplication** — duplicates are detected, not reprocessed
3. **Deterministic response replay** — duplicates get the same response as the original

```
Client → [Retry 1] → Server: "New request, processing..."     → charges card → ₹500
Client → [Retry 2] → Server: "Seen this before, here you go." → returns stored response
Client → [Retry 3] → Server: "Seen this before, here you go." → returns stored response

Card charged: once.
Client got response: every time.
```

That's idempotency.

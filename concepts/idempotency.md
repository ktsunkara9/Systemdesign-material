📚 Idempotency — Complete Guide with Explanations
1. 🧠 Core Concept

Idempotency means that making the same request multiple times results in the same final outcome as making it once.
The key idea is not “execute once,” but “side effects happen only once.”

2. 🎯 Goal of Idempotency

The goal is to achieve exactly-once side effects in systems where requests may be delivered multiple times (at-least-once delivery).
This is critical in operations like payments, bookings, or order creation.

3. 🔁 Why Idempotency is Needed

In real systems, duplicate requests happen frequently due to:

User double-clicks
Network timeouts
Automatic retries by clients or SDKs
Load balancer retries
Success response lost

Without idempotency, these lead to duplicate operations.

4. 🧾 Idempotency Key (Client Responsibility)

The client sends a unique idempotency key with each request.
This key identifies a specific operation attempt, allowing the server to detect duplicates.

5. ⚠️ Business ID vs Idempotency Key

A business identifier (like orderId) represents an entity, while an idempotency key represents a request attempt.
Using only orderId is risky because:

One order can have multiple operations (pay, refund, retry)

6. 🗄️ Idempotency Storage Model

The server stores the key along with metadata:

Status (IN_PROGRESS, SUCCESS, FAILED)
Response
Request hash
Timestamps

This enables both deduplication and response replay.

7. 🔄 Request Handling Flow

When a request arrives:

If key doesn’t exist → process request
If IN_PROGRESS → return “retry later”
If SUCCESS → return stored response

This ensures consistent behavior across retries.

8. ⚡ Atomicity (Critical Concept)

The check and insert must be atomic.
If you do:

check → then insert

You introduce a race condition.
Instead, use a single atomic operation.

9. 🛑 Race Conditions

When two identical requests arrive simultaneously:

Both may see “key not present”
Both may process

This leads to duplicate side effects unless prevented by atomic operations.

10. 🧱 SQL Implementation

Use a UNIQUE constraint on the idempotency key.

First insert succeeds
Second insert fails
This ensures only one request proceeds.

11. ⚡ DynamoDB Implementation

Use conditional writes:

attribute_not_exists(idempotencyKey)

This ensures:

Only one request inserts the record
Others detect duplication safely

12. 🔄 Response Replay

For duplicate requests, always return the same response payload as the original.
This ensures:

deterministic behavior
predictable client experience

13. ⏳ IN_PROGRESS State

Used when:

request is still being processed
another request arrives

The system responds:

“Request is in progress, retry later”

14. 💥 Failure Handling (Crash Scenario)

If the system crashes after marking IN_PROGRESS:

The record gets “stuck”

Retries will see:

IN_PROGRESS but no completion

15. 🔁 Recovery Strategies

To handle stuck requests:

Retry internally
Mark FAILED
Reprocess safely
Use timestamps to detect stale state

16. 💳 External Reconciliation

In payment systems:

You verify with payment gateway
Check if transaction succeeded

This ensures correctness even if your system crashed.

17. ⏱️ Expiry (TTL)

Idempotency keys should expire to:

prevent storage growth
allow reuse after safe time

The TTL depends on business risk.

18. ⚠️ Payload Validation

If the same key is reused with different payload:

It can corrupt data

Solution:

Store request hash
Reject mismatched requests

19. 🔁 Retry vs Idempotency
Retry = client action
Idempotency = server guarantee

Idempotency makes retries safe and predictable.

20. 🧹 Cleanup Strategy

TTL removes old records, but:

deletion is not immediate
should not be relied on for correctness

21. 🌍 Multi-Region Challenges

In multi-region systems:

no global atomicity
replication is eventual

This can lead to duplicate processing across regions.

22. 🌍 Multi-Region Solutions

Common approaches:

Route requests to a single region
Use a primary write region
Accept rare duplicates and reconcile

23. 🚫 Why In-Memory Locks Fail

Locks like synchronized:

work only within one server
are not shared across instances
are lost on crash

So they don’t solve distributed idempotency.

24. 🧠 Where to Implement Idempotency

Best place: service layer
Because:

it understands business logic
can manage states and failures

25. ⚖️ Tradeoffs

Design involves balancing:

Consistency vs latency
Storage vs safety
Simplicity vs correctness

26. 🎯 Final Mental Model

Idempotency is a mechanism to ensure exactly-once side effects in distributed systems by combining atomic state management, request deduplication, and deterministic response replay.
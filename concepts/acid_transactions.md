# ACID Transactions

## What Is a Transaction?

A database transaction is a group of database operations treated as one logical unit of work.

**Example:**

- Deduct ₹1000 from Account A
- Add ₹1000 to Account B
- Save transaction history

All 3 together form one transaction. If one fails, everything should roll back.

A transaction is usually bounded like this:

```sql
BEGIN TRANSACTION;

UPDATE accounts SET balance = balance - 1000 WHERE id = 'A';
UPDATE accounts SET balance = balance + 1000 WHERE id = 'B';
INSERT INTO transfer_history(...);

COMMIT;
```

If something fails:

```sql
ROLLBACK;
```

The database guarantees correctness.

> **Beginner Note:** Think of `BEGIN TRANSACTION` as saying "I'm about to do a bunch of things — treat them as one." `COMMIT` means "I'm done, save everything." `ROLLBACK` means "Something went wrong, undo everything I just did." The database keeps track of what you did so it can undo it if needed.

---

## Why Transactions Exist

Without transactions:

- Money may get deducted but not credited
- Inventory count may become negative
- Order created but payment missing
- Airline seat double-booked

Transactions exist to protect **data integrity**. This is where ACID comes in.

---

## ACID Explained

### A — Atomicity

Either everything succeeds or nothing succeeds. **"All or nothing."**

**Example:**

1. Debit successful
2. Credit failed

Without atomicity → money disappears.
With atomicity → debit also rolled back.

**Banking Example:**

Transaction steps:

1. Deduct ₹500 from Krishna
2. Add ₹500 to Ravi

If DB crashes after step 1:

- **BAD:** Krishna loses money, Ravi never receives it
- **Atomicity ensures:** rollback happens

**Implementation:**

- Transaction logs
- Undo logs
- Rollback mechanisms

> **Beginner Note:** How does the database "undo" things? Before making any change, it writes down what the original data looked like (this is the "undo log"). If something goes wrong, it reads this log and restores everything to how it was before. Think of it like taking a photo of your room before rearranging furniture — if you don't like the result, you can put everything back using the photo.

---

### C — Consistency

The most misunderstood ACID property.

Consistency means the database moves from one **valid state** to another **valid state**.

**Example rules:**

- Account balance cannot be negative
- Foreign key must exist
- Unique email constraint must hold

If a transaction violates rules → DB rejects it.

> **Important:** ACID consistency is NOT "data is the same across replicas." That is distributed systems consistency. ACID consistency means respecting database constraints and invariants.

> **Beginner Note:** Think of consistency like rules of a board game. The game has rules — you can't place a chess piece on an invalid square. Similarly, a database has rules (constraints) — like "every order must belong to a real customer" or "no two users can have the same email." Consistency means the database will never let a transaction break these rules. If it would, the transaction is rejected.

---

### I — Isolation

Concurrent transactions should not interfere incorrectly.

**Example:** Two users book the last airline seat simultaneously. Without isolation → both may succeed → seat overbooked.

> **Beginner Note:** Imagine two people trying to grab the last item on a shelf at the same time. Without isolation, both think they got it. Isolation is the database's way of making sure only one person gets the item, and the other is told "sorry, it's gone." It creates the illusion that transactions happen one after another, even though they're actually running at the same time.

#### Common Problems Without Isolation

**1. Dirty Read**

```sql
-- Transaction A:
UPDATE accounts SET balance = 500; -- Not committed yet

-- Transaction B reads 500
-- Then A rolls back
-- B read invalid data
```

**2. Non-Repeatable Read**

- First read: `balance = 1000`
- Another transaction updates it
- Second read: `balance = 2000`
- Data changed during your transaction

**3. Phantom Read**

```sql
SELECT * FROM orders WHERE amount > 1000;
-- Another transaction inserts a new row
-- Same query returns more rows later
```

#### Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Notes |
|-------|-----------|-------------------|--------------|-------|
| Read Uncommitted | ✓ | ✓ | ✓ | Fastest. Rarely used. |
| Read Committed | ✗ | ✓ | ✓ | Most common default. |
| Repeatable Read | ✗ | ✗ | ✓ (DB-dependent) | Consistent row reads. |
| Serializable | ✗ | ✗ | ✗ | Strongest. Slowest. |

> **Beginner Note:** Think of isolation levels like privacy settings. "Read Uncommitted" is like having no curtains — everyone can see your unfinished work. "Serializable" is like a locked room — nobody sees anything until you're completely done. Most real applications use "Read Committed" — a good middle ground where others can only see your finished work, but the data might change between your reads.

---

### D — Durability

Once committed, data survives crashes — even if server crashes, power fails, or application dies.

**Implemented using:**

- WAL (Write Ahead Log)
- Disk flush
- Replication

> **Beginner Note:** WAL (Write Ahead Log) works like this — before the database actually changes your data on disk, it first writes "I'm about to make this change" into a separate log file. If the system crashes mid-operation, when it restarts it reads this log and finishes what it started. Think of it like writing a to-do list before doing chores — if you get interrupted, you know exactly where to pick up.

---

## Real Interview Mental Model

ACID = tradeoff between **correctness** vs **performance/concurrency**.

- Higher isolation → safer, slower
- Lower isolation → faster, more anomalies

This tradeoff discussion is what interviewers want.

---

## SQL vs NoSQL Transactions

### SQL Databases

Examples: PostgreSQL, MySQL, Oracle Database

Traditionally offer:

- Strong ACID guarantees
- Multi-row transactions
- Joins
- Relational consistency

Good for: banking, payments, inventory, financial systems.

### NoSQL Databases

Examples: MongoDB, Cassandra, DynamoDB

Originally prioritized:

- Scalability
- Availability
- Partition tolerance

Many early NoSQL systems relaxed ACID guarantees.

### CAP Theorem Connection

NoSQL systems often choose availability and scalability over strong consistency, leading to:

- Eventual consistency
- Weaker transactions

> **Beginner Note:** The CAP theorem says a distributed database can only guarantee two out of three things: **C**onsistency (every read gets the latest write), **A**vailability (every request gets a response), and **P**artition tolerance (system works even if network between nodes breaks). Since network partitions are unavoidable in distributed systems, you're really choosing between consistency and availability. NoSQL databases often pick availability — meaning your data might be slightly stale for a moment, but the system never goes down.

### DynamoDB Example

- Early DynamoDB: mostly single-item atomicity
- Now supports `TransactWriteItems` (up to 100 items, atomic writes)
- But: more latency, more cost

### MongoDB Example

- Originally: atomic only at document level
- Now: supports multi-document ACID transactions
- But: distributed transactions are still heavier than SQL

### Key System Design Understanding

In large-scale distributed systems, full ACID across services is expensive. Companies often use:

- Eventual consistency
- Sagas
- Compensating transactions
- Asynchronous workflows

---

## Why Distributed Transactions Are Hard

Suppose you have:

- Payment Service
- Inventory Service
- Order Service

Each has a separate database. Network failures are possible. Partial success is possible.

### Two-Phase Commit (2PC)

Traditional distributed transaction protocol:

1. **Phase 1 (Prepare):** Coordinator asks all participants: "Can you commit?"
2. **Phase 2 (Commit):** If everyone says yes → coordinator tells everyone to commit. If anyone says no → everyone rolls back.

**Problems:**

- Slow and blocking
- Poor scalability
- Coordinator failure issues

Modern architectures avoid it at scale.

> **Beginner Note:** Think of 2PC like planning a group dinner. One person (coordinator) texts everyone: "Can you all make it Friday?" Everyone replies yes or no. If everyone says yes, the coordinator confirms: "We're on!" If even one person says no, dinner is cancelled for everyone. The problem? If the coordinator's phone dies after asking but before confirming, everyone is stuck waiting — they've blocked their Friday evening but don't know if dinner is happening. That's why 2PC doesn't scale well.

---

## What Big Tech Systems Usually Do

Instead of one giant ACID transaction, they use:

- Event-driven architecture
- Retries
- Idempotency
- Compensation logic

**Example (Saga Pattern):**

1. Create order
2. Reserve inventory
3. Process payment
4. If payment fails → release inventory

> **Beginner Note:** A Saga is like booking a vacation step by step. You book a flight, then a hotel, then a rental car. If the rental car booking fails, you don't just give up — you cancel the hotel and cancel the flight (these are "compensating transactions"). Each step has a corresponding undo step. Unlike a single transaction where the database handles rollback automatically, with Sagas your application code is responsible for undoing previous steps when something fails later.

---

## Interview-Ready Summary

| Concept | Key Point |
|---------|-----------|
| Transaction | A logical unit of DB operations |
| Atomicity | All or nothing |
| Consistency | Database rules/invariants remain valid |
| Isolation | Concurrent transactions don't corrupt each other |
| Durability | Committed data survives crashes |
| Isolation Levels | Tradeoff: stronger correctness ↔ lower concurrency |
| SQL | Strong ACID, relational, good for financial correctness |
| NoSQL | Optimized for scale/availability, weaker consistency historically |
| Distributed Systems | Global ACID is expensive → use sagas, eventual consistency, compensating actions |

---

## Most Important System Design Insight

A junior engineer says: *"Use transactions everywhere."*

A senior engineer asks: *"What consistency guarantees are actually required?"*

**Examples:**

- Bank transfer → strict ACID
- Instagram like count → eventual consistency acceptable
- Analytics dashboard → eventual consistency fine
- Payment ledger → must be strongly consistent

That's the real engineering discussion.

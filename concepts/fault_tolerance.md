# Fault Tolerance

## Why Failures Are Inevitable

Failures will happen despite:

1. Improvements to the code
2. Code reviews and testing
3. Performing ongoing maintenance to hardware

No matter how careful you are, things break — servers crash, networks partition, disks fill up, memory leaks accumulate, third-party services go down. The question isn't "will failures happen?" but "how does the system behave when they do?"

**Real-world examples of inevitable failures:**

| Type | Example |
|------|---------|
| Hardware | Hard drive fails after 3 years of use |
| Software | Memory leak causes OOM crash after 2 weeks of uptime |
| Network | Undersea cable cut disrupts cross-region communication |
| Human | Engineer accidentally deletes production database table |
| External | Payment gateway has an outage |

---

## What Is Fault Tolerance?

Fault Tolerance is the best way to achieve High Availability in a system.

Fault Tolerance enables a system to **remain operational and available to users despite failures within one or multiple of its components**. The system may perform at a reduced level but will stay available.

**Example:**

Netflix has thousands of microservices. If the recommendation service goes down:

- ❌ Without fault tolerance: entire app crashes, users can't watch anything
- ✅ With fault tolerance: recommendations show generic "Popular" titles, everything else works fine

The system is degraded (less personalized) but not down.

> **Beginner Note:** Fault tolerance doesn't mean "nothing ever breaks." It means "when something breaks, users don't notice — or notice only a minor reduction in functionality." It's the difference between a car that stops completely when the AC breaks vs one that keeps driving just without air conditioning.

---

## Tactics for Achieving Fault Tolerance

Three main strategies:

```
1. Failure Prevention     → Stop failures from happening in the first place
2. Failure Detection      → Know when something breaks, isolate it
3. Recovery               → Get back to normal operation quickly
```

---

## 1. Failure Prevention

### Eliminate Single Points of Failure (SPOF)

A Single Point of Failure is any component whose failure brings down the entire system.

**Examples of SPOFs:**

| SPOF | What happens when it fails |
|------|---------------------------|
| Single application server | All users lose access |
| Single database instance | All data becomes unreachable |
| Single load balancer | No traffic can reach any server |
| Single DNS provider | Domain doesn't resolve, site unreachable |
| Single availability zone | All infrastructure in that zone gone |

**Visualizing the problem:**

```
BAD (full of SPOFs):
User → [Single LB] → [Single Server] → [Single DB]
         ↑ SPOF          ↑ SPOF           ↑ SPOF

GOOD (no SPOFs):
User → [LB1 + LB2] → [Server1, Server2, Server3] → [DB Primary + Replica1 + Replica2]
```

### Redundancy Types

The best way to eliminate SPOFs is through **replication and redundancy**:

#### Spatial Redundancy

Running the same component in multiple locations simultaneously.

**Examples:**

- Running your application on 3 servers across different availability zones
- Storing data in a primary database + 2 read replicas
- Using multiple load balancers (active-active)
- Deploying across multiple AWS regions (Mumbai + Singapore)

```
Spatial Redundancy Example — Database:

   Writes → [DB Primary (AZ-1a)]
                    │
              ┌─────┴─────┐
              ↓            ↓
   [DB Replica (AZ-1b)]  [DB Replica (AZ-1c)]
              ↑            ↑
        Reads distributed across replicas
```

#### Time Redundancy

Repeating the same operation or request multiple times until it succeeds.

**Examples:**

- Retrying a failed API call 3 times with exponential backoff
- Re-sending a failed message to a queue
- Re-running a failed batch job

```
Time Redundancy Example — API retry with exponential backoff:

Attempt 1: POST /payments → timeout (fail)
   wait 1 second
Attempt 2: POST /payments → 503 error (fail)
   wait 2 seconds
Attempt 3: POST /payments → 200 OK (success!)
```

> **Important:** Time redundancy must be combined with **idempotency**. If you retry a payment request and it's not idempotent, you might charge the customer multiple times.

---

### Strategies for Redundancy and Replication

#### Active-Active

All instances actively handle traffic simultaneously. If one fails, the others continue without interruption.

```
Active-Active:

User requests → Load Balancer
                    │
          ┌─────────┼─────────┐
          ↓         ↓         ↓
      [Server A] [Server B] [Server C]
       handling    handling    handling
       traffic     traffic     traffic

Server B crashes → traffic redistributes to A and C
                   No failover delay!
```

**Characteristics:**

| Aspect | Detail |
|--------|--------|
| Traffic distribution | All nodes serve traffic |
| Failover time | Near-zero (just stop routing to failed node) |
| Resource utilization | High (all nodes working) |
| Complexity | Higher (must handle concurrent state) |
| Use case | Web servers, stateless APIs, CDNs |

**Real-world example:** A fleet of 10 web servers behind an ALB. Each handles ~10% of traffic. If 2 servers crash, the remaining 8 each handle ~12.5%. Users experience no downtime — at most slightly higher latency under load redistribution.

#### Active-Passive

One instance (active) handles all traffic. The other (passive/standby) sits idle, ready to take over if the active fails.

```
Active-Passive:

All traffic → [Primary DB - Active]
                      │
                replication
                      ↓
              [Standby DB - Passive (idle)]

Primary crashes → Standby promoted to Primary
                  Brief failover window (seconds to minutes)
```

**Characteristics:**

| Aspect | Detail |
|--------|--------|
| Traffic distribution | Only active node serves traffic |
| Failover time | Seconds to minutes (detection + promotion) |
| Resource utilization | Low (passive node is idle) |
| Complexity | Lower (no concurrent state issues) |
| Use case | Databases, stateful services, leader-based systems |

**Real-world example:** AWS RDS Multi-AZ. Your primary PostgreSQL runs in AZ-1a. A standby replica in AZ-1b receives synchronous replication. If the primary fails, RDS automatically promotes the standby (typically 60-120 seconds failover).

#### When to Use Which?

| Scenario | Strategy | Why |
|----------|----------|-----|
| Stateless web servers | Active-Active | No shared state, easy to distribute |
| Database writes | Active-Passive | Only one writer avoids conflicts |
| Cache layer (Redis) | Active-Active (Redis Cluster) | Reads and writes distributed |
| Message broker | Active-Passive (leader election) | One leader coordinates ordering |
| DNS | Active-Active | Multiple nameservers respond |

---

## 2. Failure Detection and Isolation

You can't fix what you can't see. Detection must be fast and automated.

### Health Checks

Periodic probes that verify whether a component is functioning correctly.

**Types of health checks:**

| Type | What it checks | Example |
|------|---------------|---------|
| Liveness | Is the process alive? | TCP connection to port 8080 succeeds |
| Readiness | Can it serve traffic? | `/health` returns 200 and DB connection works |
| Deep health | Are all dependencies OK? | `/health/deep` verifies DB, cache, queue all reachable |

**Example — AWS ALB health check configuration:**

```
Target: HTTP GET /health
Port: 8080
Interval: 30 seconds
Timeout: 5 seconds
Healthy threshold: 3 consecutive successes
Unhealthy threshold: 2 consecutive failures
```

**How it works:**

```
Time 0s:   ALB → GET /health → Server1 responds 200 ✓
Time 30s:  ALB → GET /health → Server1 responds 200 ✓
Time 60s:  ALB → GET /health → Server1 timeout ✗ (failure 1)
Time 90s:  ALB → GET /health → Server1 responds 500 ✗ (failure 2)
Time 91s:  ALB marks Server1 as UNHEALTHY → stops sending traffic
Time 92s:  Auto-scaling launches replacement Server4
```

> **Beginner Note:** A shallow health check (`/health` returns 200) only tells you the process is running. A deep health check verifies the server can actually do useful work (connect to DB, read from cache, etc.). Use deep checks for load balancer routing decisions.

### Failover

The process of switching traffic from a failed component to a healthy one.

**Types of failover:**

#### Automatic Failover

System detects failure and switches without human intervention.

**Example — Database failover:**

```
1. Primary DB stops responding to health checks
2. Monitoring detects failure (after 2 missed checks = 60 seconds)
3. System promotes read replica to new primary
4. DNS/connection string updated to point to new primary
5. Application reconnects automatically

Total downtime: 60-120 seconds (depending on detection + promotion time)
```

#### Manual Failover

Requires human intervention to switch over. Used when automatic failover is risky (e.g., data consistency concerns).

**Example:** DBA manually promotes a replica after verifying replication lag is zero and no data would be lost.

### Isolation (Bulkhead Pattern)

When a failure is detected, **isolate it** so it doesn't cascade to other parts of the system.

**Example — Microservices without isolation:**

```
User → API Gateway → Order Service → Payment Service (DOWN!)
                                           ↓
                          Order Service threads blocked waiting
                                           ↓
                          Order Service runs out of threads
                                           ↓
                          API Gateway times out
                                           ↓
                          ENTIRE SYSTEM DOWN (cascade failure)
```

**With isolation (Circuit Breaker pattern):**

```
User → API Gateway → Order Service → Circuit Breaker → Payment Service (DOWN!)
                                           │
                              Circuit OPEN (after 5 failures)
                                           │
                              Returns fallback immediately:
                              "Payment pending, will retry later"
                                           │
                          Order Service stays healthy ✓
                          Other services unaffected ✓
```

**Circuit Breaker States:**

```
CLOSED (normal) → failures exceed threshold → OPEN (reject immediately)
                                                    │
                                          after timeout period
                                                    ↓
                                              HALF-OPEN (try one request)
                                              ├── success → CLOSED
                                              └── failure → OPEN
```

> **Beginner Note:** Think of a circuit breaker like the one in your home's electrical panel. When too much current flows (too many failures), the breaker trips (opens) and cuts the connection. This protects the rest of your house (system) from damage (cascade failure). After some time, you can flip it back (half-open) to test if the problem is resolved.

---

## 3. Recovery

Once a failure is detected and isolated, the system needs to recover — either automatically or with minimal human intervention.

### Automatic Recovery Strategies

| Strategy | How It Works | Example |
|----------|-------------|---------|
| Auto-restart | Failed process is automatically restarted | Kubernetes restarts crashed pod |
| Auto-scaling | New instances launched to replace failed ones | ASG launches new EC2 when one terminates |
| Self-healing | System detects and corrects its own issues | Database repairs corrupted index automatically |
| Retry with backoff | Failed operations retried after delay | Message reprocessed from dead-letter queue |

**Example — Kubernetes self-healing:**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: payment-service
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
```

What happens:

1. Pod's `/health` endpoint fails 3 times
2. Kubernetes kills the pod
3. Kubernetes starts a new pod
4. New pod passes health check → receives traffic

No human intervention required.

### Graceful Degradation

When full recovery isn't immediately possible, serve users with reduced functionality.

**Example — E-commerce site during partial failures:**

| Component Down | Degraded Behavior | User Impact |
|---------------|-------------------|-------------|
| Recommendation engine | Show generic "bestsellers" | Less personalized, still functional |
| Search service | Show category browsing only | Can't search, but can still shop |
| Review service | Hide reviews section | Missing social proof, still can buy |
| Payment gateway | Show "try again later" | Can't checkout — critical degradation |

The key principle: **fail gracefully in non-critical paths, fail loudly in critical paths**.

### Data Recovery

| Strategy | RPO (data loss) | RTO (time to recover) | Cost |
|----------|----------------|----------------------|------|
| Synchronous replication | 0 (no loss) | Seconds | High |
| Asynchronous replication | Seconds to minutes | Minutes | Medium |
| Point-in-time backups | Hours | Hours | Low |
| Daily snapshots | Up to 24 hours | Hours to days | Lowest |

**Example — Payment system data recovery priorities:**

- Transaction records: synchronous replication (zero data loss acceptable)
- User profiles: asynchronous replication (seconds of lag OK)
- Analytics data: daily backups (hours of loss acceptable)

> **Beginner Note:** RPO (Recovery Point Objective) = how much data you can afford to lose. RTO (Recovery Time Objective) = how quickly you need to be back online. A bank's transaction ledger might have RPO=0 and RTO=30 seconds. A blog might have RPO=24 hours and RTO=4 hours. Your budget and architecture must match these requirements.

---

## Putting It All Together — Real-World Example

**Scenario:** Payment service handling ₹10 crore daily transactions.

```
Architecture with fault tolerance:

Users → [DNS: Route53 with health checks]
              │
     ┌────────┼────────┐
     ↓                  ↓
[ALB Region-1]    [ALB Region-2] (standby)
     │
┌────┼────┐
↓    ↓    ↓
[S1] [S2] [S3]  ← Active-Active servers (3 AZs)
     │
     ↓
[DB Primary] → replicates → [DB Replica 1]
                           → [DB Replica 2]
```

**When Server S2 crashes:**

1. ALB health check detects failure (30 seconds)
2. ALB stops routing to S2 (isolation)
3. Traffic redistributes to S1 and S3 (no user impact)
4. Auto-scaling group launches S4 (recovery)
5. S4 passes health checks → joins the fleet

**When entire Region-1 goes down:**

1. Route53 health check detects ALB-1 failure
2. DNS failover routes traffic to Region-2 ALB
3. Region-2 services handle all traffic
4. Users experience brief DNS propagation delay (~60 seconds)

---

## Summary

| Tactic | Goal | Key Mechanisms |
|--------|------|---------------|
| Prevention | Stop failures from causing outages | Redundancy (spatial + time), eliminate SPOFs |
| Detection | Know when things break, fast | Health checks (liveness + readiness), monitoring |
| Isolation | Prevent cascade failures | Circuit breakers, bulkheads, timeout policies |
| Recovery | Get back to normal | Auto-restart, auto-scaling, failover, graceful degradation |

**The mental model:**

```
Fault Tolerance = Accept that failures WILL happen
               + Prevent what you can
               + Detect what you couldn't prevent
               + Isolate so it doesn't spread
               + Recover automatically and quickly
```

This is how systems like Netflix, Amazon, and Google serve millions of users with 99.99%+ availability — not by preventing every failure, but by building systems that **tolerate** them.

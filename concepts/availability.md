# Availability

## Why Availability Matters

Availability is one of the most important quality attributes of a large-scale system. Arguably, it has the greatest impact on both users and business.

### Impact on Users

- A user tries to purchase something from an online store, but the page doesn't load.
- The page loads, but at checkout they get an error instead of a confirmation.
- An email service goes down — millions of people lose access to their email for hours.

When our software is used for mission-critical services — air traffic control, hospital patient management — system unavailability can put people's lives at risk.

### Impact on Business

System downtime has two consequences:

1. **Revenue stops** — if users can't use the system, the ability to make money goes to zero.
2. **Customer loss** — when users lose access too often or too long, they go to competitors.

**Real-world example:** The AWS S3 outage in February 2017 affected hundreds of companies and over 100,000 websites. Because so many services depended on S3, the outage nearly took down large portions of the internet.

> **Beginner Note:** Availability isn't just about "is the server running?" It's about whether the user can actually complete their task. A server that's running but returning errors or timing out is effectively unavailable.

---

## Defining Availability

Availability is the fraction of time (or probability) that a service is operationally functional and accessible to the user.

- **Uptime** — the time the system is operational and accessible
- **Downtime** — the time the system is unavailable

### Formula 1: Direct Measurement

```
Availability = Uptime / (Uptime + Downtime)
```

**Example:**

Your e-commerce site was operational for 719 hours in a month and down for 1 hour.

```
Availability = 719 / (719 + 1) = 719 / 720 = 99.86%
```

> **Note:** Sometimes "uptime" and "availability" are used interchangeably. If an SLA describes uptime as a percentage, they're talking about availability.

---

## MTBF and MTTR

An alternative way to define and estimate availability uses two statistical metrics:

### MTBF (Mean Time Between Failures)

The average time the system is operational between failures.

**Example:** If your payment service fails 3 times in 30 days, and the total operational time between those failures was 29 days:

```
MTBF = 29 days / 3 failures = ~9.67 days between failures
```

This metric is especially useful when dealing with hardware (servers, hard drives, routers) where each component has a known operational lifespan.

### MTTR (Mean Time to Recovery)

The average time it takes to detect and recover from a failure. Until recovery is complete, the system is non-operational — so MTTR is effectively the average downtime per incident.

**Example:** Your service had 3 outages this month:

- Outage 1: detected in 2 min, fixed in 13 min → 15 min total
- Outage 2: detected in 5 min, fixed in 25 min → 30 min total
- Outage 3: detected in 1 min, fixed in 14 min → 15 min total

```
MTTR = (15 + 30 + 15) / 3 = 20 minutes average recovery time
```

### Formula 2: Estimation

```
Availability = MTBF / (MTBF + MTTR)
```

**Example:**

```
MTBF = 9.67 days = 13,924 minutes
MTTR = 20 minutes

Availability = 13,924 / (13,924 + 20) = 99.86%
```

### Key Insight from This Formula

If you minimize MTTR toward zero, availability approaches 100% — regardless of how often failures occur.

```
If MTTR → 0:  Availability = MTBF / (MTBF + 0) = 100%
```

This tells us something important: **you don't need to prevent all failures to achieve high availability. You need to detect and recover from them fast.**

> **Beginner Note:** This is why companies invest heavily in monitoring, alerting, and automated recovery (auto-scaling, health checks, automatic restarts). The faster you recover, the less downtime users experience — even if things break frequently behind the scenes.

---

## How Much Availability Should We Aim For?

100% availability is what users want, but it's extremely hard to achieve. It leaves zero time for planned maintenance, upgrades, or emergency fixes.

### The Nines Table

| Availability | Called | Downtime/Day | Downtime/Month | Downtime/Year |
|-------------|--------|-------------|----------------|---------------|
| 90% | One nine | 2.4 hours | 3 days | 36.5 days |
| 95% | — | 1.2 hours | 1.5 days | 18.25 days |
| 99% | Two nines | 14.4 min | 7.3 hours | 3.65 days |
| 99.9% | Three nines | 1.44 min | 43.8 min | 8.76 hours |
| 99.99% | Four nines | 8.6 sec | 4.38 min | 52.6 min |
| 99.999% | Five nines | 0.86 sec | 26.3 sec | 5.26 min |

**Reading this table:**

- **90%** — sounds high, but means 36 days of downtime per year. Not acceptable for most services.
- **95%** — still means 1 hour of downtime every day. Not high availability.
- **99.9% (three nines)** — less than 1.5 minutes per day. Users barely notice. Still leaves ~8.7 hours per year for emergency maintenance.
- **99.99% (four nines)** — less than 1 minute per day. Very hard to achieve. Requires significant investment in redundancy and automation.

### Industry Standard

There's no strict definition of "high availability," but the industry standard set by cloud vendors is generally **99.9% (three nines) or higher**.

**Examples of real SLAs:**

| Service | Availability SLA |
|---------|-----------------|
| AWS EC2 | 99.99% |
| AWS S3 | 99.9% (standard), 99.99% (SLA credit threshold) |
| Google Cloud Compute | 99.99% |
| Azure VMs (with availability zones) | 99.99% |
| Stripe API | 99.99% |

> **Beginner Note:** SLAs (Service Level Agreements) are contractual promises. If the provider fails to meet the SLA, you typically get service credits. But credits don't undo the damage of an outage to your users — so design your system to handle provider failures too.

---

## What Makes Achieving High Availability Hard?

Every additional "nine" is exponentially harder and more expensive to achieve:

| Going from | To | What it requires |
|-----------|-----|-----------------|
| 99% → 99.9% | Eliminate 90% of remaining downtime | Redundancy, health checks, auto-restart |
| 99.9% → 99.99% | Eliminate 90% of that remaining downtime | Multi-AZ deployment, automated failover, zero-downtime deploys |
| 99.99% → 99.999% | Eliminate 90% again | Multi-region, chaos engineering, no single points of failure anywhere |

**Example cost perspective:**

A startup might spend ₹50,000/month to run a 99.9% available service. Getting to 99.99% might cost ₹3,00,000/month (redundant infrastructure, on-call engineers, sophisticated monitoring). Getting to 99.999% might cost ₹15,00,000+/month.

---

## Strategies to Achieve High Availability

### 1. Redundancy (Eliminate Single Points of Failure)

If any single component's failure brings down the system, that's a Single Point of Failure (SPOF).

**Example:**

```
BAD:  User → Load Balancer → [Single Server] → [Single Database]
                                    ↑ SPOF            ↑ SPOF

GOOD: User → [LB1, LB2] → [Server1, Server2, Server3] → [DB Primary + DB Replica]
```

### 2. Health Checks and Auto-Recovery

Detect failures automatically and replace unhealthy instances.

**Example:** AWS ALB health checks ping `/health` every 30 seconds. If a server fails 3 consecutive checks, traffic is routed away and a new instance is launched.

### 3. Multi-AZ / Multi-Region Deployment

Spread across multiple data centers so a single facility failure doesn't take you down.

**Example:**

```
Region: ap-south-1 (Mumbai)
├── AZ-1a: Server1, Server2, DB-Primary
├── AZ-1b: Server3, Server4, DB-Replica
└── AZ-1c: Server5, Server6, DB-Replica
```

If AZ-1a goes down, traffic shifts to AZ-1b and AZ-1c automatically.

### 4. Graceful Degradation

When parts of the system fail, continue serving users with reduced functionality rather than going completely down.

**Example:** Netflix during a database outage:
- Movie recommendations stop personalizing → show generic popular titles instead
- User can still browse and watch content
- System is "degraded" but not "down"

### 5. Zero-Downtime Deployments

Deploy new code without taking the system offline.

**Techniques:**
- Rolling deployments (replace instances one at a time)
- Blue-green deployments (switch traffic from old to new)
- Canary deployments (send small % of traffic to new version first)

---

## Calculating Availability of a System with Multiple Components

Real systems have many components. How they're arranged affects overall availability.

### Components in Series (all must work)

```
User → Service A → Service B → Database
```

```
System Availability = A(ServiceA) × A(ServiceB) × A(Database)
```

**Example:**

- Service A: 99.9%
- Service B: 99.9%
- Database: 99.9%

```
System = 0.999 × 0.999 × 0.999 = 99.7%
```

Each component in series reduces overall availability. Three components at 99.9% each give you only 99.7% overall.

### Components in Parallel (redundant — any one can serve)

```
User → Load Balancer → [Server 1 OR Server 2]
```

```
System Availability = 1 - (1 - A₁) × (1 - A₂)
```

**Example:** Two servers, each 99% available:

```
System = 1 - (1 - 0.99) × (1 - 0.99) = 1 - 0.01 × 0.01 = 1 - 0.0001 = 99.99%
```

Two 99% servers in parallel give you 99.99% — better than either alone.

> **Beginner Note:** This is why redundancy is the primary tool for high availability. Adding parallel components multiplies your reliability. But components in series (dependencies) multiply your risk. The lesson: minimize serial dependencies, maximize parallel redundancy.

---

## Summary

| Concept | Key Point |
|---------|-----------|
| Availability | Fraction of time the system is accessible and functional |
| Measurement | `Uptime / (Uptime + Downtime)` |
| Estimation | `MTBF / (MTBF + MTTR)` |
| Key insight | Minimizing recovery time (MTTR) matters more than preventing all failures |
| High availability | Industry standard: 99.9% (three nines) or above |
| Cost of nines | Each additional nine is exponentially harder and more expensive |
| Series components | Multiply availability (reduces overall) |
| Parallel components | Multiply reliability (increases overall) |
| Core strategies | Redundancy, health checks, multi-AZ, graceful degradation, fast recovery |

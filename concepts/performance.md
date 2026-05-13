# Performance

## Performance Metrics

Some people think Response Time is the only performance metric — it's not. There are two primary metrics:

1. **Response Time (Latency)**
2. **Throughput**

Both matter, and depending on the system, one may be more important than the other.

---

## Response Time (Latency)

The time between when a user sends a request and when they receive the response.

```
Response Time = Processing Time + Waiting Time (network delay, queue wait, etc.)
```

**Example:**

You click "Place Order" on an e-commerce site. The server takes 50ms to process your order, and the network round-trip adds 20ms. Your response time is **70ms**.

> **Beginner Note:** Response time isn't just how fast your code runs. It includes everything the request waits for — network hops, load balancer routing, queue time, database queries, and the response traveling back to the user.

---

## Throughput

The amount of work a system performs per unit of time.

Can be measured as:

- **Requests per second** (for APIs/web servers)
- **Transactions per second** (for databases)
- **Bits/sec, bytes/sec, MB/sec** (for data pipelines, streaming)

**Example:**

- A web server handling **5,000 requests/second** has high throughput.
- A video streaming service delivering **500 MB/sec** to users has high data throughput.

**When throughput matters more than response time:**

- Batch processing systems (e.g., processing 1 million records overnight — you care about total time, not individual record latency)
- Data pipelines (e.g., ingesting logs — you care about volume processed per second)
- File upload/download services

---

## Important Considerations

1. Proper measuring of response time
2. Response time percentile distribution
3. Performance degradation

---

## Measuring Response Time Correctly

You cannot just measure one request and call it your response time. You need to measure across many requests and understand the distribution.

**Example:**

Suppose 2 requests are in a queue and each takes 10 seconds to process (one at a time):

- Request 1: waits 0s in queue + 10s processing = **10s response time**
- Request 2: waits 10s in queue + 10s processing = **20s response time**
- Average response time = (10 + 20) / 2 = **15s**

> **Beginner Note:** The second request didn't get slower because it was harder — it got slower because it had to wait. This is why measuring response time must account for queuing. A system might process things fast, but if requests pile up, users still experience slowness.

**Key takeaway:** Always measure response time from the user's perspective (including wait time), not just processing time.

---

## Response Time Distribution

A single average doesn't tell the full story. You need to look at the **distribution** of response times.

**Why?**

- Average can hide outliers. If 99 requests take 50ms and 1 takes 10 seconds, the average is ~150ms — which looks fine but hides a terrible experience for that 1 user.

We use a **histogram** (or percentile chart) to visualize how response times are distributed across all requests.

**Example histogram:**

```
Response Time (ms)    |  Number of Requests
0   - 50             |  ████████████████████  (800)
50  - 100            |  ████████              (150)
100 - 200            |  ██                    (30)
200 - 500            |  █                     (15)
500 - 2000           |                        (5)
```

Most requests are fast, but a few are very slow — those are the tail.

---

## Tail Latency

The small percentage of response times that take the longest compared to the rest.

These are the requests at the 95th, 99th, or 99.9th percentile — the "tail" of the distribution curve.

**Why it matters:**

- These slow requests often hit your most valuable users (users with lots of data, complex accounts, heavy carts).
- In microservice architectures, one slow downstream call can make the entire request slow.

**We define response time goals using percentiles:**

| Goal | Meaning |
|------|---------|
| 30ms at p50 | 50% of requests complete within 30ms |
| 100ms at p95 | 95% of requests complete within 100ms |
| 500ms at p99 | 99% of requests complete within 500ms |

**Example:**

Amazon has found that every 100ms of added latency costs them ~1% in sales. They track tail latency aggressively because even a small percentage of slow requests affects revenue at scale.

> **Beginner Note:** When someone says "our API has p99 latency of 200ms," they mean 99% of all requests finish within 200ms. Only 1% take longer. The higher the percentile you target, the harder (and more expensive) it is to achieve.

---

## Performance Degradation

When system performance gets worse over time or under load.

**Key signal:** If degradation is sudden and steep, it usually means one of your resources has hit its limit (saturation point).

**Potential over-utilized resources:**

| Resource | Symptom |
|----------|---------|
| High CPU utilization | Requests queue up waiting for processing |
| High memory consumption | Garbage collection pauses, swapping to disk, OOM kills |
| Too many connections / IO | Database connection pool exhausted, file descriptor limits hit |
| Message queue at capacity | Producers block or drop messages, consumers can't keep up |

**Example:**

Your API responds in 50ms normally. Traffic spikes 3x. Suddenly response times jump to 2 seconds. You check metrics:

- CPU: 98%
- DB connection pool: 50/50 connections used (full)

The database connection pool is saturated — requests are waiting for a free connection. Fix: increase pool size, add read replicas, or cache frequent queries.

> **Beginner Note:** Performance degradation is rarely linear. Systems often work fine until a resource hits ~70-80% utilization, then performance drops off a cliff. This is why monitoring and alerting on resource utilization matters — you want to catch it before users feel it.

---

## Summary

| Concept | What It Means |
|---------|---------------|
| Response Time | Total time from request sent to response received (includes queuing) |
| Throughput | Work done per unit time (requests/sec, MB/sec) |
| Percentiles | Measure distribution, not just averages (p50, p95, p99) |
| Tail Latency | The slowest requests — often affect your most important users |
| Degradation | Sudden performance drop usually means a resource is saturated |

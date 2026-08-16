# API Design

## Introduction

A system is defined by two things:

- **Behavior** — what it does internally
- **Interface (API)** — how others interact with it

The interface is a **contract** between the engineers who implement the system and the client applications who use it. Since this interface is called by other applications (programmatically, not by humans directly), it's called an **Application Programming Interface (API)**.

APIs are called remotely through the network by:

1. **Front-end clients** — mobile apps, web apps, SPAs
2. **Internal systems** — other services within our organization
3. **External backend systems** — third-party companies integrating with us

Each component of a system typically has its own API, and these component APIs are called by other services within the system.

**Example — E-commerce platform:**

```
┌─────────────────────────────────────────────────────┐
│                     Clients                          │
│  [Mobile App]  [Web App]  [Partner Systems]         │
└──────────┬─────────┬──────────┬─────────────────────┘
           │         │          │
           ↓         ↓          ↓
┌──────────────────────────────────────────────────────┐
│                   API Gateway                         │
└────┬──────────┬──────────┬──────────┬────────────────┘
     ↓          ↓          ↓          ↓
[User API]  [Product API]  [Order API]  [Payment API]
     │          │              │            │
     ↓          ↓              ↓            ↓
  [User DB]  [Product DB]  [Order DB]  [Payment Gateway]
```

Each service exposes its own API. The mobile app doesn't talk directly to the database — it talks to the API.

> **Beginner Note:** Think of an API like a restaurant menu. The menu (API) tells you what you can order (operations) and what you'll get back (responses). You don't need to know how the kitchen (internal implementation) works. You just place your order through the waiter (network request) and get your food (response).

---

## API Categories

APIs are classified into 3 groups:

### 1. Public APIs

Exposed to the general public. Any developer can call them from their application.

**Best practices for public APIs:**

- Require developer registration before allowing requests (API keys)
- Control who uses the system and how they use it
- Rate limit to prevent abuse
- Ability to blacklist users who break rules
- Comprehensive documentation (since you can't control who uses it)

**Examples:**

| Company | Public API | What it does |
|---------|-----------|--------------|
| Google Maps | Maps API | Embed maps, geocoding, directions |
| Twitter/X | Twitter API | Read/post tweets, search |
| OpenWeather | Weather API | Get weather data for any location |
| Stripe | Payments API | Process payments from any app |

**Example — Using a public API:**

```
GET https://api.openweathermap.org/data/2.5/weather?q=Mumbai&appid=YOUR_API_KEY

Response:
{
  "main": {
    "temp": 303.15,
    "humidity": 78
  },
  "weather": [{ "description": "scattered clouds" }]
}
```

The developer registered, got an API key, and can now call this from their app. They have no idea how OpenWeather collects weather data internally.

### 2. Private APIs (Internal APIs)

Exposed only internally within the company. They allow other teams/parts of the organization to:

- Take advantage of the system's capabilities
- Provide bigger value by combining services
- Keep the system hidden from external exposure

**Example — Internal microservices at a company:**

```
[Order Service] calls → [Inventory API] (private) → checks stock
[Order Service] calls → [Notification API] (private) → sends email
[Analytics Dashboard] calls → [Reporting API] (private) → fetches metrics
```

None of these are exposed to the internet. They're only accessible within the company's VPN or internal network.

**Why separate public and private APIs?**

Your internal API might expose sensitive operations (delete user, adjust pricing, override limits). You'd never want these on the public internet. Private APIs can also be less polished — internal teams can handle rougher documentation and breaking changes more easily.

### 3. Partner APIs

Exposed only to companies/users having a business relationship with you — typically through a customer agreement, product subscription, or partnership contract.

**Examples:**

| Provider | Partner API | Who uses it |
|----------|------------|-------------|
| Razorpay | Payment Gateway API | E-commerce sites that signed up as merchants |
| AWS | S3 API | Companies paying for AWS services |
| Shopify | Store Admin API | Apps approved in Shopify's app store |

**Difference from Public APIs:**

- Access requires a signed agreement (not just registration)
- Often includes SLAs (guaranteed uptime, support)
- May offer higher rate limits and premium features
- Tighter security controls and audit logging

---

## Benefits of a Well-Designed API

1. **Immediate integration** — Clients can enhance their business using your system right away without understanding internal details.

2. **Abstraction** — Users don't need to know about your databases, algorithms, or architecture. They just call endpoints.

3. **Parallel development** — Once the API contract is defined, clients can integrate without waiting for full implementation. Frontend and backend teams can work simultaneously.

4. **Internal structure guidance** — Designing the API first helps architect the system. It defines the endpoints and routes users can take.

**Example — Parallel development:**

```
Week 1: Team agrees on API contract
        POST /orders → { orderId, status }
        GET /orders/{id} → { order details }

Week 2-4: 
        Backend team: implements order service, database, business logic
        Frontend team: builds UI using mock API responses
        Mobile team: builds app screens using same mock

Week 5: Connect real API → everything works because contract was agreed upfront
```

---

## Best Practices and Patterns

### 1. Complete Encapsulation

The API should completely hide the internal design and implementation.

**Bad — leaking internal details:**

```json
GET /api/get-user?table=users&db=postgresql&join=addresses

Response:
{
  "rows": [{ "_id": "ObjectId(507f1f77)", "psql_sequence": 42 }]
}
```

This leaks: database type, table names, internal ID formats.

**Good — fully encapsulated:**

```json
GET /api/users/42

Response:
{
  "id": "42",
  "name": "Krishna",
  "email": "krishna@example.com"
}
```

The client has no idea whether you're using PostgreSQL, MongoDB, or flat files behind the scenes.

### 2. Decoupled from Internal Implementation

The API contract should remain stable even when you change the internals.

**Example:**

You start with a monolithic database. Later you split into microservices. The API stays the same:

```
Before (monolith):   GET /orders/123 → queries single DB
After (microservices): GET /orders/123 → calls Order Service → queries Order DB

Client code doesn't change! Same request, same response shape.
```

### 3. Easy to Use, Easy to Understand, Impossible to Misuse

| Principle | Bad Example | Good Example |
|-----------|------------|--------------|
| Descriptive names | `POST /api/do?action=5` | `POST /api/orders` |
| One way to do things | `GET /getUser/42` AND `GET /fetchUser?id=42` | `GET /users/42` (only one way) |
| Expose only what's needed | Returns internal flags, debug info | Returns only relevant user data |
| Consistent patterns | `/getUsers`, `/create_order`, `/DeleteItem` | `/users`, `/orders`, `/items` (consistent nouns) |

**Example — Consistent RESTful naming:**

```
GET    /users          → list all users
GET    /users/42       → get specific user
POST   /users          → create user
PUT    /users/42       → update user
DELETE /users/42       → delete user

GET    /users/42/orders    → list orders for user 42
GET    /orders/789         → get specific order
```

Every developer can guess the pattern without reading documentation.

### 4. Idempotent Operations

Operations that produce the same result regardless of how many times they're executed.

| Method | Idempotent? | Why |
|--------|------------|-----|
| GET | ✅ Yes | Reading data doesn't change anything |
| PUT | ✅ Yes | Setting address to "Mumbai" 5 times → still "Mumbai" |
| DELETE | ✅ Yes | Deleting item 42 five times → item 42 is still deleted |
| POST | ❌ No | Creating an order 5 times → 5 orders created |

**Example — Idempotent PUT vs Non-idempotent POST:**

```
PUT /users/42/address
{ "city": "Mumbai", "pin": "400001" }

Call once  → address is Mumbai 400001
Call again → address is still Mumbai 400001 (same result, safe to retry)
```

```
POST /orders
{ "item": "laptop", "qty": 1 }

Call once  → 1 order created
Call again → 2 orders created! (not idempotent, dangerous to retry)
```

> **Beginner Note:** Idempotency is critical for APIs because network failures cause retries. If the client sends a request but doesn't get a response (timeout), it will retry. If the operation isn't idempotent, the retry creates duplicates. This is why payment APIs use idempotency keys (see idempotency.md for deep dive).

### 5. API Pagination

For endpoints that return large datasets, let clients request small segments.

**Why?**

- A table with 10 million rows can't be returned in one response
- Mobile clients have limited memory
- Network bandwidth has limits
- Response time degrades with size

**Common pagination patterns:**

#### Offset-based pagination:

```
GET /orders?limit=20&offset=0     → first 20 orders
GET /orders?limit=20&offset=20    → next 20 orders
GET /orders?limit=20&offset=40    → next 20 orders
```

**Response:**

```json
{
  "data": [ ... 20 orders ... ],
  "pagination": {
    "total": 5000,
    "limit": 20,
    "offset": 0,
    "hasMore": true
  }
}
```

#### Cursor-based pagination (better for large/real-time datasets):

```
GET /orders?limit=20                          → first page
GET /orders?limit=20&cursor=eyJpZCI6MjB9      → next page (cursor from previous response)
```

**Why cursor is better than offset:**

- Offset breaks if rows are inserted/deleted between pages (you skip or duplicate items)
- Cursor always points to a stable position in the dataset

### 6. Asynchronous Operations

For long-running tasks, the client receives an immediate response with a way to check status later.

**When to use async:**

- Running a big report requiring queries across many databases
- Big data analysis scanning millions of records
- Video compression or image processing
- Sending bulk emails/notifications

**Example — Async video compression:**

```
Step 1: Client submits job
POST /videos/compress
{ "videoId": "vid_123", "targetResolution": "720p" }

Response (immediate):
{
  "jobId": "job_abc",
  "status": "queued",
  "checkStatusAt": "/jobs/job_abc"
}

Step 2: Client polls for status
GET /jobs/job_abc

Response (in progress):
{
  "jobId": "job_abc",
  "status": "processing",
  "progress": 45
}

Step 3: Client checks again later
GET /jobs/job_abc

Response (complete):
{
  "jobId": "job_abc",
  "status": "completed",
  "result": {
    "downloadUrl": "/videos/vid_123/720p.mp4"
  }
}
```

**Alternative to polling — Webhooks:**

Instead of the client repeatedly asking "are you done yet?", the server calls the client when done:

```
POST /videos/compress
{
  "videoId": "vid_123",
  "callbackUrl": "https://myapp.com/webhooks/video-done"
}

// When done, YOUR server calls the client's URL:
POST https://myapp.com/webhooks/video-done
{
  "jobId": "job_abc",
  "status": "completed",
  "downloadUrl": "/videos/vid_123/720p.mp4"
}
```

### 7. API Versioning

Maintain multiple versions simultaneously and deprecate older versions gradually.

**Why versioning?**

Your API is a contract. Hundreds of clients depend on it. If you change the response format, you break their code. Versioning lets you evolve without breaking existing integrations.

**Common versioning strategies:**

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL path | `/v1/users`, `/v2/users` | Clear, easy to understand | URL pollution |
| Header | `Accept: application/vnd.api+json;version=2` | Clean URLs | Hidden, harder to test |
| Query param | `/users?version=2` | Simple | Easy to forget |

**Example — Versioned API evolution:**

```
# Version 1 (original)
GET /v1/users/42
Response: { "name": "Krishna Kumar", "email": "krishna@example.com" }

# Version 2 (split name into first/last)
GET /v2/users/42
Response: { "firstName": "Krishna", "lastName": "Kumar", "email": "krishna@example.com" }
```

Both versions run simultaneously. Clients on v1 continue working. New clients use v2. After 6 months, you deprecate v1 with advance notice.

**Deprecation communication:**

```
# Response header warning
GET /v1/users/42
Headers:
  Sunset: Sat, 01 Mar 2026 00:00:00 GMT
  Deprecation: true
  Link: </v2/users/42>; rel="successor-version"
```

---

## Summary

| Concept | Key Point |
|---------|-----------|
| API | Contract between system implementers and client applications |
| Public API | Open to all developers (with registration) |
| Private API | Internal only — for organizational use |
| Partner API | Business relationship required |
| Encapsulation | Hide all internal details behind the API |
| Decoupling | Change internals without breaking the contract |
| Idempotency | Same request multiple times → same result |
| Pagination | Return data in small, manageable chunks |
| Async operations | Return immediately, let client check status later |
| Versioning | Evolve without breaking existing clients |

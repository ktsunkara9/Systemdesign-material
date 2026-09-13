# REST API

## What Is REST?

**REST** stands for **Representational State Transfer**. It was introduced by Roy Fielding in his 2000 doctoral dissertation. REST is an **architectural style**, not a standard, protocol, or specification. It's a set of constraints and best practices for designing networked applications.

An API that follows the REST constraints is called a **RESTful API**.

REST takes a **resource-oriented** approach:

- Everything is modeled as a **resource** (a user, an order, a product).
- Each resource is **named and addressed using a URI** (Uniform Resource Identifier).
- Clients interact with resources by exchanging **representations** of their state (usually JSON, sometimes XML).

> **Beginner Note:** "Representational State Transfer" sounds intimidating, but the idea is simple. A resource (say, user 42) lives on the server. When you ask for it, the server sends you a *representation* of its current state — typically a JSON document. If you want to change it, you send back a modified representation. You're transferring the state of the resource back and forth. That's the whole idea.

---

## Key Characteristics

| Characteristic | What It Means |
|----------------|---------------|
| Uses HTTP | Built on top of the standard HTTP protocol and its methods |
| Stateless server | The server stores no client session between requests |
| Resource-oriented | Data is exposed as resources identified by URIs |
| Representation-based | Clients exchange representations (JSON/XML) of resource state |
| Uniform interface | Consistent, predictable use of HTTP methods and status codes |
| Cacheable | Responses can be cached to improve performance |

REST naturally supports **Scalability**, **High Availability**, and **Caching** — three qualities that make it a strong fit for large distributed systems.

---

## Statelessness

In REST, the **server is stateless**. Each request from the client must contain all the information the server needs to process it. The server does not remember anything about previous requests.

**Example — stateless request:**

```
GET /orders/789
Authorization: Bearer eyJhbGci...   ← identity sent with every request
```

The server does not keep a "logged-in session" in memory. The client re-sends its credentials (token) on every call.

**Why statelessness matters:**

- **Scalability** — Any server in a cluster can handle any request. No need to route a client back to "its" server.
- **High Availability** — If a server dies, another can take over instantly because there's no session state to lose.
- **Simplicity** — No server-side session management to maintain.

```
        ┌─────────────┐
Client →│Load Balancer│→ [Server 1]   Any request can go to any
        └─────────────┘→ [Server 2]   server because none of them
                       → [Server 3]   hold client session state.
```

> **Beginner Note:** Statelessness is why REST scales so well. Imagine a coat check that remembers who you are (stateful) versus one where you carry a ticket that proves ownership (stateless). With tickets, any attendant can serve you. That's how stateless servers work — the client carries its own "ticket" (token) on every request.

---

## Resources and URIs

A **resource** is any piece of data the API exposes: a user, an order, a product, a collection of comments. Each resource is addressed by a **URI**.

```
https://api.example.com/users            → collection of users
https://api.example.com/users/42         → a single user
https://api.example.com/users/42/orders  → orders belonging to user 42
```

### Best Practices for Naming Resources

1. **Use nouns, not verbs** — A resource is a *thing*, not an action. Use `/users`, not `/getUsers`.
2. **Distinguish collections from single resources** — Use **plural** names for collections (`/orders`) and address individual items by identifier (`/orders/789`).
3. **Use meaningful names** — Names should clearly describe the resource (`/invoices`, `/subscriptions`).
4. **Avoid generic names** — Don't use vague names like `values`, `elements`, `objects`, `items`, or `data`.
5. **Resource identifiers should be unique** — Each resource must be uniquely addressable.

**Bad vs Good naming:**

| Bad | Good | Why |
|-----|------|-----|
| `GET /getUser?id=42` | `GET /users/42` | Nouns + identifier, not a verb |
| `POST /createOrder` | `POST /orders` | The HTTP method already implies "create" |
| `GET /data` | `GET /products` | Meaningful, not generic |
| `GET /user` (for a list) | `GET /users` | Plural for collections |

---

## HTTP Methods

REST maps operations onto standard HTTP methods. This mapping is a big part of what makes a RESTful API predictable.

| Method | Operation | Idempotent? | Safe? | Cacheable? |
|--------|-----------|-------------|-------|------------|
| GET | Read a resource | ✅ Yes | ✅ Yes | ✅ Yes (by default) |
| POST | Create a resource | ❌ No | ❌ No | Only if explicitly allowed |
| PUT | Replace/update a resource | ✅ Yes | ❌ No | ❌ No |
| PATCH | Partially update a resource | ❌ Not guaranteed | ❌ No | ❌ No |
| DELETE | Remove a resource | ✅ Yes | ❌ No | ❌ No |

**Definitions:**

- **Safe** — The operation does not modify server state (read-only).
- **Idempotent** — Making the same request multiple times produces the same result as making it once.
- **Cacheable** — The response can be stored and reused.

**Example — CRUD mapped to HTTP methods:**

```
POST   /users              → create a new user
GET    /users              → list all users
GET    /users/42           → read user 42
PUT    /users/42           → replace user 42 entirely
PATCH  /users/42           → update part of user 42 (e.g. just the email)
DELETE /users/42           → delete user 42
```

> **Beginner Note:** Idempotency is critical because networks fail. If a client sends a request but the response is lost, it will retry. `GET`, `PUT`, and `DELETE` are safe to retry — repeating them causes no harm. `POST` is not, because retrying it can create duplicate resources. This is why creation endpoints often use idempotency keys (see idempotency.md for a deep dive).

---

## HTTP Status Codes

RESTful APIs communicate outcomes using standard HTTP status codes. Using them correctly makes the API self-explanatory.

| Range | Category | Common Codes |
|-------|----------|--------------|
| 2xx | Success | 200 OK, 201 Created, 202 Accepted, 204 No Content |
| 3xx | Redirection | 301 Moved Permanently, 304 Not Modified |
| 4xx | Client error | 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 429 Too Many Requests |
| 5xx | Server error | 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable |

**Example — meaningful status codes:**

```
POST /users        → 201 Created      (new resource made)
GET  /users/42     → 200 OK           (resource returned)
GET  /users/9999   → 404 Not Found    (no such user)
DELETE /users/42   → 204 No Content   (deleted, nothing to return)
POST /users (bad)  → 400 Bad Request  (invalid input)
```

> **Security Note:** Return the same generic response for authentication failures whether the account exists or not, and never expose stack traces or internal error details in 5xx responses. On error, fail closed (deny access) rather than fail open.

---

## Richardson Maturity Model

A useful way to gauge how "RESTful" an API is. It describes four levels of maturity.

| Level | Name | Description |
|-------|------|-------------|
| Level 0 | The Swamp of POX | Single URI, single method (usually POST). Basically RPC over HTTP. |
| Level 1 | Resources | Multiple URIs, one per resource — but still one method. |
| Level 2 | HTTP Verbs | Proper use of HTTP methods (GET, POST, PUT, DELETE) and status codes. **Most real-world APIs live here.** |
| Level 3 | Hypermedia (HATEOAS) | Responses include links guiding the client to related actions. |

**Example — Level 3 (HATEOAS) response:**

```json
{
  "id": "789",
  "status": "pending",
  "total": 500,
  "_links": {
    "self":   { "href": "/orders/789" },
    "pay":    { "href": "/orders/789/payment", "method": "POST" },
    "cancel": { "href": "/orders/789/cancel",  "method": "POST" }
  }
}
```

The client is told what it can do next (pay or cancel) via embedded links, rather than hardcoding those URLs. Most APIs stop at Level 2 because full HATEOAS is complex and few clients take advantage of it.

---

## Anatomy of a REST Request and Response

**Request:**

```
POST /users HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGci...
Content-Type: application/json

{
  "name": "Krishna",
  "email": "krishna@example.com"
}
```

**Response:**

```
HTTP/1.1 201 Created
Content-Type: application/json
Location: /users/42

{
  "id": "42",
  "name": "Krishna",
  "email": "krishna@example.com",
  "createdAt": "2026-09-14T10:30:00Z"
}
```

Notice how the response uses the `201 Created` status and a `Location` header pointing to the newly created resource. This is idiomatic REST.

---

## REST Best Practices

### 1. Use Nouns for Resources, Let Methods Be the Verbs

```
Bad:  GET /getAllUsers, POST /createUser, POST /deleteUser
Good: GET /users, POST /users, DELETE /users/42
```

### 2. Nest Resources to Show Relationships

```
GET /users/42/orders        → orders belonging to user 42
GET /users/42/orders/789    → a specific order for that user
```

Avoid nesting more than 2-3 levels deep — it becomes hard to read.

### 3. Support Filtering, Sorting, and Pagination via Query Parameters

```
GET /orders?status=shipped&sort=-createdAt&limit=20&offset=40
```

Pagination keeps responses small and fast (see api_design.md for offset vs cursor pagination).

### 4. Version Your API

```
/v1/users     ← original contract
/v2/users     ← evolved contract, runs alongside v1
```

Versioning lets you evolve without breaking existing clients (see api_design.md for versioning strategies).

### 5. Use Proper Status Codes and Consistent Error Bodies

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email address is not valid",
    "field": "email"
  }
}
```

Keep error shapes consistent across the whole API so clients can handle them uniformly.

### 6. Secure Every Endpoint

- Enforce authentication and authorization **server-side** on every request. Deny by default.
- Use **TLS (HTTPS)** for all communication — never send tokens or PII over plain HTTP.
- Never put credentials, tokens, or PII in **URL query parameters** (they get logged). Use headers or the request body.
- Apply **rate limiting** on sensitive endpoints and return `429 Too Many Requests` when exceeded.

### 7. Leverage Caching

`GET` responses are cacheable. Use HTTP caching headers to reduce load and latency:

```
Cache-Control: max-age=3600
ETag: "a1b2c3"
```

On the next request, the client sends `If-None-Match: "a1b2c3"`, and the server can reply `304 Not Modified` if nothing changed — saving bandwidth.

---

## Advantages of REST

| Advantage | Why |
|-----------|-----|
| Scalability | Stateless servers scale horizontally with ease |
| High availability | No session state means any server can handle any request |
| Caching | HTTP caching (and CDNs) work naturally with GET requests |
| Simplicity | Just HTTP + JSON — universally understood and tooled |
| Broad support | Every language, browser, and tool speaks HTTP |
| Loose coupling | Clients and servers evolve independently behind a stable contract |

## Limitations of REST

| Limitation | Why |
|------------|-----|
| Over-fetching / under-fetching | A fixed resource shape may return too much or too little data (GraphQL addresses this) |
| Multiple round trips | Fetching related data can require several requests |
| No native streaming | REST is request/response; not ideal for continuous streams (gRPC is better) |
| Text serialization overhead | JSON is larger and slower to parse than binary formats like protobuf |
| Action-oriented operations feel awkward | Operations that are verbs ("send email") don't map cleanly to resources |

---

## REST vs RPC — Quick Comparison

| Aspect | REST | RPC |
|--------|------|-----|
| Focus | Resources (nouns) | Actions (verbs) |
| Style | `POST /payments` | `processPayment()` |
| Serialization | JSON/XML — human-readable | Binary (protobuf) — fast |
| Browser support | Native | Limited |
| Caching | Natural (HTTP GET) | Not built in |
| Best for | Public APIs, CRUD, browser clients | Internal service-to-service, streaming |

(See RPC.md for the full RPC breakdown.)

---

## Summary

| Concept | Key Point |
|---------|-----------|
| REST | An architectural style for networked APIs, introduced in 2000 |
| Resource-oriented | Everything is a resource addressed by a URI |
| Stateless | Server keeps no client session; every request is self-contained |
| HTTP methods | GET (read), POST (create), PUT/PATCH (update), DELETE (remove) |
| Idempotency | GET, PUT, DELETE are safe to retry; POST is not |
| Status codes | 2xx success, 4xx client error, 5xx server error |
| Maturity | Most APIs reach Level 2 (proper verbs); Level 3 adds HATEOAS |
| Strengths | Scalable, highly available, cacheable, simple, universally supported |
| Weaknesses | Over/under-fetching, multiple round trips, no native streaming |

**Mental model:**

- REST = "I want to **access or modify a resource**" (data-centric, nouns)
- RPC = "I want to **do something** on a remote server" (action-centric, verbs)

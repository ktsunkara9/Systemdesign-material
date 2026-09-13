# RPC — Remote Procedure Calls

## What Is RPC?

RPC is the ability of a client application to execute a subroutine (method/function) on a remote server. The remote method invocation looks like calling a normal local method in the developer's code.

This is called **local transparency** — to the developer, a method executed locally or remotely looks the same.

**Example — Local vs Remote call:**

```java
// Local method call (runs in same process)
double tax = taxCalculator.calculateTax(orderAmount, "IN");

// RPC call (runs on a remote server) — looks identical to the developer!
double tax = taxService.calculateTax(orderAmount, "IN");
```

The developer writes the same code. Under the hood, the second call travels across the network to a remote server, executes there, and returns the result. But the developer doesn't see any of that complexity.

> **Beginner Note:** Imagine you have a calculator app on your phone. Normally, pressing "=" runs the calculation on your phone (local). With RPC, pressing "=" sends the numbers to a powerful server somewhere, it calculates, and sends the answer back — but to you, it just feels like pressing "=" on your phone. The network is invisible.

---

## Cross-Language Support

RPC supports multiple programming languages. Applications written in different languages can talk to each other using RPC.

**Example:**

```
[Python Service] ←── RPC ──→ [Java Service] ←── RPC ──→ [Go Service]
```

- Your Order Service is written in Java
- Your Recommendation Service is written in Python
- Your Payment Service is written in Go

With RPC, they all communicate seamlessly. The framework handles translating data between languages.

---

## The 3 Components of RPC

| Component | What It Does |
|-----------|-------------|
| Interface Description Language (IDL) | Defines the API contract — methods, parameters, return types |
| Client Stub | Auto-generated code on the client side that handles serialization and network calls |
| Server Stub | Auto-generated code on the server side that receives requests and routes to actual implementation |

**Example — gRPC with Protocol Buffers (most popular modern RPC framework):**

### Step 1: Define the API using IDL (Protocol Buffers)

```protobuf
// payment_service.proto (IDL file)

syntax = "proto3";

service PaymentService {
  rpc ProcessPayment(PaymentRequest) returns (PaymentResponse);
  rpc RefundPayment(RefundRequest) returns (RefundResponse);
  rpc GetPaymentStatus(StatusRequest) returns (StatusResponse);
}

message PaymentRequest {
  string order_id = 1;
  double amount = 2;
  string currency = 3;
  string customer_id = 4;
}

message PaymentResponse {
  string transaction_id = 1;
  string status = 2;  // "captured", "failed"
  string message = 3;
}
```

### Step 2: Generate stubs (automatic)

```bash
# This generates client and server stub code automatically
protoc --java_out=. --grpc-java_out=. payment_service.proto
protoc --python_out=. --grpc_python_out=. payment_service.proto
```

This produces:
- **Client stub** (Java): `PaymentServiceGrpc.PaymentServiceBlockingStub`
- **Server stub** (Python): `PaymentServiceServicer`

### Step 3: Implement the server (Python)

```python
class PaymentServiceImpl(PaymentServiceServicer):
    def ProcessPayment(self, request, context):
        # Actual business logic here
        result = charge_card(request.customer_id, request.amount)
        return PaymentResponse(
            transaction_id=result.txn_id,
            status="captured",
            message="Payment successful"
        )
```

### Step 4: Call from client (Java)

```java
// This looks like a normal local method call!
PaymentResponse response = paymentStub.processPayment(
    PaymentRequest.newBuilder()
        .setOrderId("order_123")
        .setAmount(500.00)
        .setCurrency("INR")
        .setCustomerId("cust_789")
        .build()
);

System.out.println(response.getTransactionId());  // "txn_98765"
```

The Java client called a Python server — but the code looks like calling a local Java method.

---

## How RPC Works (Step by Step)

```
Client Application                                    Remote Server
       │                                                    │
       │  1. client calls: paymentStub.processPayment()     │
       │                                                    │
       ├──→ [Client Stub]                                   │
       │     2. Serializes data (object → bytes)            │
       │     3. Initiates network connection                │
       │                                                    │
       │  ─────── network ──────→                           │
       │                          [Server Stub]  ←──────────┤
       │                           4. Deserializes bytes    │
       │                              back to objects       │
       │                                                    │
       │                           5. Calls real method:    │
       │                              processPayment()      │
       │                                                    │
       │                           6. Gets result,          │
       │                              serializes response   │
       │                                                    │
       │  ←────── network ───────                           │
       │                                                    │
       ├──→ [Client Stub]                                   │
       │     7. Deserializes response                       │
       │     8. Returns result to calling code              │
       │                                                    │
       ▼                                                    │
  Client gets PaymentResponse object                        │
```

**Serialization formats used by RPC frameworks:**

| Framework | Serialization | Format |
|-----------|--------------|--------|
| gRPC | Protocol Buffers | Binary (compact, fast) |
| Apache Thrift | Thrift Binary | Binary |
| JSON-RPC | JSON | Text (human-readable, slower) |
| XML-RPC | XML | Text (verbose) |

> **Beginner Note:** Serialization is converting an object in memory (like a Java PaymentRequest) into bytes that can travel over the network. Deserialization is the reverse — converting bytes back into an object. Binary formats like Protocol Buffers are much faster and smaller than text formats like JSON, which is why gRPC is preferred for high-performance service-to-service communication.

---

## Benefits

### 1. Developer Convenience

Client developers communicate with the remote system by calling methods on objects — exactly like calling local methods. No need to construct HTTP requests, parse JSON, or manage connections.

**Comparison — REST vs RPC from developer's perspective:**

```java
// REST approach (manual HTTP, JSON parsing)
HttpResponse response = httpClient.post("https://payment-service/api/payments",
    "{\"orderId\":\"order_123\",\"amount\":500}");
PaymentResult result = jsonParser.parse(response.body(), PaymentResult.class);

// RPC approach (feels like a local call)
PaymentResponse result = paymentStub.processPayment(request);
```

### 2. Network Abstraction

All details of connection establishment, data serialization, network transport, timeouts, and retries are abstracted away. The developer focuses only on business logic.

### 3. Type Safety

Because the IDL defines exact types, you get compile-time checks. If you pass the wrong type or forget a required field, your code won't compile.

```java
// Compile error! amount expects double, not String
PaymentRequest.newBuilder()
    .setAmount("five hundred")  // ← compiler catches this
    .build();
```

### 4. Clear Error Handling

Failures in communication result in typed errors or exceptions that the developer can handle:

```java
try {
    PaymentResponse response = paymentStub.processPayment(request);
} catch (StatusRuntimeException e) {
    if (e.getStatus().getCode() == Status.Code.UNAVAILABLE) {
        // Server is down — retry or failover
    } else if (e.getStatus().getCode() == Status.Code.DEADLINE_EXCEEDED) {
        // Request timed out
    }
}
```

---

## Drawbacks

### 1. Remote Calls Are Slower and Less Reliable

A local method call takes nanoseconds. A remote call takes milliseconds (1000x slower minimum) and can fail due to network issues.

**Performance comparison:**

| Call Type | Typical Latency | Can Fail Due To |
|-----------|----------------|-----------------|
| Local method | ~1-10 nanoseconds | Only bugs in code |
| RPC (same data center) | 1-10 milliseconds | Network, server crash, timeout |
| RPC (cross-region) | 50-200 milliseconds | All above + cable issues, routing |

**The danger of local transparency:**

Because RPC looks like local calls, developers sometimes forget they're making network calls and write code like:

```java
// BAD — 100 network round trips! (N+1 problem)
for (Order order : orders) {
    UserInfo user = userService.getUser(order.getUserId());  // RPC call per iteration!
}

// GOOD — batch RPC call
List<UserInfo> users = userService.getUsers(userIds);  // Single RPC call
```

**Mitigation:** Use asynchronous processing, batch calls, and caching.

### 2. Ambiguous Failures

There's no way for the client to know whether:
- The server received the message but the acknowledgment was lost (operation succeeded)
- The server crashed and never received the message (operation never happened)

```
Scenario A:                              Scenario B:
Client → Server (received)               Client → Server (never arrived)
Server processes payment ✓               Server crashed ✗
Server → Client (response LOST) ✗       
                                         
Client sees: TIMEOUT                     Client sees: TIMEOUT
What happened? Payment succeeded!        What happened? Payment never ran!
```

Both look identical to the client. This is called the **Two Generals Problem**.

**Mitigation:** Make operations idempotent. If the client retries, the server detects the duplicate and returns the original result without reprocessing.

---

## When to Use RPC

| Use Case | Why RPC Works Well |
|----------|-------------------|
| Service-to-service communication | High performance, type safety, generated clients |
| Providing API to partner companies | Clean interface, multi-language support, strong contracts |
| Action-oriented operations | RPC naturally models "do something" (verbs) |
| High-throughput internal systems | Binary serialization (protobuf) is faster than JSON |
| Streaming data | gRPC supports bidirectional streaming |

**Example — Where RPC shines (microservices):**

```
[Order Service] ──gRPC──→ [Inventory Service]: reserveStock(orderId, items)
[Order Service] ──gRPC──→ [Payment Service]: processPayment(orderId, amount)
[Order Service] ──gRPC──→ [Notification Service]: sendConfirmation(userId, orderId)
```

Each call is an action. RPC models actions naturally.

**Example — gRPC streaming (real-time):**

```protobuf
service LiveLocationService {
  // Client streams location updates to server
  rpc UpdateLocation(stream LocationUpdate) returns (Acknowledgment);
  
  // Server streams nearby driver locations to client
  rpc WatchNearbyDrivers(AreaRequest) returns (stream DriverLocation);
}
```

This is how ride-sharing apps (Uber/Ola) track drivers in real-time — continuous bidirectional streaming.

---

## When NOT to Use RPC

| Scenario | Why RPC Is a Poor Fit | Better Alternative |
|----------|----------------------|-------------------|
| Browser/frontend clients | Limited browser support, can't use binary protocols easily | REST or GraphQL |
| Need HTTP cookies/headers | RPC abstracts away HTTP — you lose access to these | REST |
| Simple CRUD operations | Overkill for basic create/read/update/delete | REST |
| Data-centric APIs | REST models resources naturally with URIs | REST |
| Public APIs for third-party developers | REST is more widely understood and tooled | REST |
| Caching with CDNs | HTTP GET caching doesn't work with RPC | REST |

**Example — RPC is awkward for CRUD:**

```protobuf
// RPC for CRUD feels unnatural — too many similar methods
service UserService {
  rpc CreateUser(CreateUserRequest) returns (User);
  rpc GetUser(GetUserRequest) returns (User);
  rpc UpdateUser(UpdateUserRequest) returns (User);
  rpc DeleteUser(DeleteUserRequest) returns (Empty);
  rpc ListUsers(ListUsersRequest) returns (UserList);
}
```

vs REST which handles CRUD naturally:

```
POST   /users       → create
GET    /users/42    → read
PUT    /users/42    → update
DELETE /users/42    → delete
GET    /users       → list
```

---

## RPC vs REST — Quick Comparison

| Aspect | RPC | REST |
|--------|-----|------|
| Focus | Actions (verbs) | Resources (nouns) |
| Style | `processPayment()`, `sendEmail()` | `POST /payments`, `POST /emails` |
| Serialization | Binary (protobuf) — fast | JSON/XML — human-readable |
| Browser support | Limited | Native |
| Type safety | Strong (compile-time) | Weak (runtime validation) |
| Performance | Higher (binary, HTTP/2) | Lower (text, HTTP/1.1 typically) |
| Learning curve | Steeper (IDL, code generation) | Lower (just HTTP + JSON) |
| Best for | Internal service-to-service | External/public APIs |

---

## Popular RPC Frameworks

| Framework | By | Language Support | Serialization |
|-----------|-----|-----------------|---------------|
| gRPC | Google | Java, Python, Go, C++, Node, and more | Protocol Buffers |
| Apache Thrift | Facebook (Meta) | Java, Python, C++, PHP, Ruby | Thrift Binary |
| Apache Avro | Apache | Java, Python, C | Avro Binary/JSON |
| JSON-RPC | Community | Any (language-agnostic) | JSON |
| tRPC | Community | TypeScript (full-stack) | JSON |

> **Beginner Note:** If you're starting with RPC today, **gRPC** is the industry standard for backend service-to-service communication. It's used by Google, Netflix, Slack, and many others. If you're building full-stack TypeScript apps, **tRPC** is popular for end-to-end type safety between frontend and backend.

---

## Summary

| Concept | Key Point |
|---------|-----------|
| RPC | Call remote methods as if they were local |
| Local transparency | Network complexity is hidden from the developer |
| IDL | Defines the contract (methods, types) in a language-neutral way |
| Stubs | Auto-generated client/server code that handles serialization and networking |
| Strength | Action-oriented, high performance, type-safe, multi-language |
| Weakness | Slower than local calls, ambiguous failures, poor browser support |
| Best for | Internal microservices, partner APIs, streaming, high-throughput systems |
| Not for | Public APIs, CRUD-heavy apps, browser clients, when you need HTTP features |

**Mental model:**

- RPC = "I want to **do something** on a remote server" (action-centric)
- REST = "I want to **access/modify a resource** on a remote server" (data-centric)

Choose based on whether your API is primarily about actions or about data.

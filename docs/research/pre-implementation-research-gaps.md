# Pre-Implementation Research Gaps: What We Are Still Missing

> Research compiled April 2026. Gap analysis against existing 7-part research system (pre-implementation-research-system.md) and security vulnerability reference (ai-code-security-vulnerabilities.md).
>
> Sources: CWE Top 25 2025, PortSwigger Web Security Academy, OWASP Race Condition slides (Bangkok Chapter 2024), APIsec, Microsoft Azure Architecture Center, GDPR.eu, Vanta, Intel Security Guidelines, Black Hat US-15, Paragonie, Resilience4j, academic papers on saga patterns, distributed transaction failure modes.

---

## Verdict: 8 Genuinely Important Gaps

The current system is strong on **technical injection attacks** (XSS, SQLi, CSRF), **auth/authz basics** (missing auth, IDOR, hardcoded secrets), **AI-specific risks** (slopsquatting, hallucinated APIs), and **code quality** (OX Security anti-patterns, slop detection). What follows are dimensions that are **absent or dangerously thin** -- each one has caused real production incidents and would not be caught by the existing checklist.

---

## Gap 1: Race Conditions and Business Logic Concurrency

**What is missing:** The current system mentions "race conditions" exactly once (Section 2.4, bullet point) but provides zero detection technique, zero prevention pattern, and zero per-feature checklist.

**Why it matters:** Race conditions are now the #1 business logic vulnerability class in web applications. PortSwigger's Web Security Academy documents attacks where a $1,000 item was purchased for $12 by exploiting a checkout race window. OWASP Bangkok Chapter (2024) demonstrated race conditions specifically in **Next.js + Prisma + PostgreSQL on Vercel** -- our exact stack.

**What to research per feature:**

```
RACE CONDITION CHECKLIST (per feature):

1. IDENTIFY SHARED MUTABLE STATE
   - What database rows does this feature read-then-write?
   - Are there any check-then-act sequences? (check balance -> deduct)
   - Are there any single-use resources? (coupon codes, invite links, trial activations)

2. CLASSIFY THE RACE WINDOW
   - Limit overrun: Can this action be performed more times than intended?
     (redeem coupon twice, double-book a slot, exceed rate limit)
   - State manipulation: Can state change between check and use?
     (price changes between cart and checkout, role changes mid-request)
   - Multi-endpoint: Does the business flow span multiple API calls
     where state can be manipulated between them?

3. PREVENTION PATTERNS (choose per scenario)
   - Database-level: SELECT FOR UPDATE, serializable transactions,
     optimistic locking with version columns
   - Application-level: Idempotency keys for mutations,
     atomic compare-and-swap operations
   - Prisma-specific: Use $transaction with isolation level,
     or optimistic concurrency with @updatedAt version field
   - Queue-based: Serialize critical operations through a job queue

4. TESTING
   - Can this endpoint be hit with parallel requests? (Burp Suite Turbo Intruder)
   - What happens if the same mutation is submitted 20 times simultaneously?
   - For single-use tokens: does redemption use DELETE/UPDATE with WHERE
     that atomically checks and consumes?
```

**CWE references:** CWE-367 (TOCTOU), CWE-362 (Race Condition), CWE-609 (Double-Checked Locking)

---

## Gap 2: Mass Assignment / Over-Posting

**What is missing:** Zero mention in either document. This is a critical gap for any framework that auto-maps request bodies to database models.

**Why it matters:** When you spread request body fields directly into a Prisma create() or update() call, the user can inject fields you did not intend them to control -- role: "admin", verified: true, balance: 999999.

**What to research per feature:**

```
MASS ASSIGNMENT CHECKLIST (per feature):

1. For every create/update endpoint:
   - Does the code explicitly pick allowed fields (allowlist)?
   - Or does it spread the entire request body into the query (dangerous)?

2. DANGEROUS PATTERNS TO FLAG:
   - prisma.user.update({ data: req.body })
   - prisma.user.create({ data: { ...body } })
   - Object.assign(existingRecord, req.body)
   - Any spread of user input into a database write without field selection

3. SAFE PATTERN:
   - Zod schema that defines ONLY the fields the user may set
   - Explicit field extraction: { name: body.name, email: body.email }
   - Prisma select or omit on the input side
   - Separate DTOs for create vs update vs admin-update

4. SENSITIVE FIELDS THAT MUST NEVER COME FROM USER INPUT:
   - role, permissions, isAdmin, isVerified
   - balance, credits, quota
   - createdAt, updatedAt (should be DB-managed)
   - userId, ownerId (should come from auth session, not request)
   - subscriptionTier, planId (should come from payment webhook)
```

**CWE reference:** CWE-915 (Improperly Controlled Modification of Dynamically-Determined Object Attributes)

---

## Gap 3: Timing Attacks on Authentication and Token Comparison

**What is missing:** Zero mention in either document. The security checklist covers auth broadly but never addresses the timing side channel.

**Why it matters:** When string comparison short-circuits on the first differing byte, an attacker can recover secrets byte-by-byte by measuring response times. This applies to: API key validation, webhook signature verification, HMAC comparison, password reset tokens, magic link tokens. Intel's security guidelines, Black Hat US-15, and Paragonie all document practical web application timing attacks.

**What to research per feature:**

```
TIMING ATTACK CHECKLIST (per feature):

1. Does this feature compare any secret value?
   - API keys, webhook signatures, HMAC digests
   - Password reset tokens, magic link tokens
   - Session tokens, CSRF tokens
   - License keys, activation codes

2. Is the comparison constant-time?
   - Node.js: crypto.timingSafeEqual(a, b) -- ONLY correct method
   - NEVER use === or == or .includes() for secret comparison
   - NEVER use early-return comparison loops

3. Does the feature leak existence of accounts/resources via timing?
   - Login: "user not found" (fast) vs "wrong password" (slow bcrypt)
   - Fix: Always run the hash comparison even for non-existent users
   - Password reset: Respond identically whether email exists or not

4. HMAC verification (webhooks from Stripe, Clerk, GitHub):
   - Compute HMAC of payload, then compare with crypto.timingSafeEqual
   - Never use string comparison for signature verification
```

**CWE reference:** CWE-208 (Observable Timing Discrepancy)

---

## Gap 4: Data Privacy Impact Per Feature (GDPR/CCPA)

**What is missing:** The current system mentions "PII" once (Section 5.2, item 3) as a bullet in a generic list. There is no per-feature privacy analysis framework, no data retention research, no right-to-deletion implementation guidance, no data minimization checklist.

**Why it matters:** GDPR fines reach 4% of global revenue or 20M EUR. Every feature that touches personal data needs a mini Data Protection Impact Assessment (DPIA). This is not ceremony -- it directly shapes database schema design (soft delete vs hard delete, encryption columns, retention TTLs).

**What to research per feature:**

```
DATA PRIVACY CHECKLIST (per feature):

1. DATA INVENTORY
   - What personal data does this feature collect?
   - What personal data does it process (even if not stored)?
   - What personal data does it display/expose?
   - Classify: name, email, IP, device fingerprint, location,
     health data, financial data, biometric data

2. DATA MINIMIZATION
   - Is every field strictly necessary for the feature's purpose?
   - Can any field be pseudonymized or anonymized?
   - Can you achieve the goal with less data?

3. DATA RETENTION
   - How long must this data be kept? (legal minimum, business need)
   - When should it be auto-deleted?
   - Implementation: Add expires_at column? Cron job for cleanup?
   - Audit logs: separate retention from operational data

4. RIGHT TO DELETION
   - Can this data be fully purged on user request?
   - What about backups? (Must have process to handle)
   - What about derived data? (analytics, aggregates, ML models)
   - What about data shared with third parties? (Stripe, analytics)
   - Foreign key constraints: cascade delete or nullify?

5. RIGHT TO EXPORT (data portability)
   - Can the user download all their data in machine-readable format?
   - What format? (JSON, CSV)

6. ENCRYPTION
   - Is PII encrypted at rest? (column-level or disk-level)
   - Is PII encrypted in transit? (TLS)
   - Are backups encrypted?

7. ACCESS LOGGING
   - Should access to this data be logged? (who viewed what, when)
   - Required for: health data, financial data, employee records
```

**Legal references:** GDPR Art. 5 (data minimization, storage limitation), Art. 17 (right to erasure), Art. 20 (data portability), Art. 35 (DPIA requirement)

---

## Gap 5: Resilience and Graceful Degradation

**What is missing:** Zero mention of circuit breakers, retry strategies, fallback behavior, dead letter queues, or graceful degradation anywhere in the research system. The current system assumes external services are always available.

**Why it matters:** Every feature that calls an external service (Stripe, Clerk, email, file storage, AI APIs) will eventually experience that service being down. Without resilience research, the default AI-generated behavior is: throw an unhandled error and show the user a 500 page. Microsoft Azure Architecture Center, Netflix (Hystrix/Resilience4j), and AWS all document this as a fundamental reliability pattern.

**What to research per feature:**

```
RESILIENCE CHECKLIST (per feature):

1. EXTERNAL DEPENDENCY MAP
   - What external services does this feature call?
   - For each: what happens when it is down? (complete failure? partial?)
   - For each: what is the SLA? (Stripe: 99.999%, email: 99.9%)

2. FAILURE MODE ANALYSIS
   - Timeout: How long before we give up? (set explicit timeouts)
   - Transient failure: Network blip, 503 from provider
   - Sustained outage: Service down for minutes/hours
   - Partial degradation: Service slow but responding

3. RETRY STRATEGY (for transient failures only)
   - Retry 5xx and timeout errors (NOT 4xx -- those are permanent)
   - Exponential backoff with jitter: wait = base * 2^attempt + random
   - Max retries: 3 (most transient issues resolve in 3 attempts)
   - Idempotency: Is this operation safe to retry? If not, use idempotency keys

4. CIRCUIT BREAKER (for sustained outages)
   - After N consecutive failures, stop calling the service (fast-fail)
   - Periodically probe (half-open state) to detect recovery
   - Return cached/fallback response during open state

5. GRACEFUL DEGRADATION
   - What can the app still do without this service?
   - Can we serve stale cached data? (product catalog: yes; auth: no)
   - Can we queue the operation for later? (email: yes; payment: complex)
   - Can we show a meaningful message instead of a 500 error?

6. DISTRIBUTED TRANSACTION FAILURES (the hard one)
   - What if payment succeeds but DB write fails?
   - What if DB write succeeds but email notification fails?
   - Pattern: Saga with compensating transactions
   - Pattern: Outbox pattern (write event to DB in same transaction,
     then process asynchronously)
   - Pattern: Idempotent receivers (handle duplicate deliveries safely)
   - MUST define compensation logic for every multi-service operation:
     "If step 3 fails, undo step 2 by [specific action]"
```

---

## Gap 6: Deserialization of Untrusted Data

**What is missing:** Zero mention. This is CWE-502, ranked #15 in the 2025 CWE Top 25, with 11 CVEs in CISA's Known Exploited Vulnerabilities catalog.

**Why it matters:** CVE-2025-55182 (React Server Components) and CVE-2025-66478 (Next.js) are both **insecure deserialization vulnerabilities** with CVSS 10.0 scores. They allow unauthenticated RCE via crafted HTTP requests against the RSC "Flight" protocol. This is our framework. Palo Alto Unit 42 identified 968,000+ exposed React/Next.js instances. Exploitation began hours after disclosure.

**What to research per feature:**

```
DESERIALIZATION CHECKLIST (per feature):

1. Does this feature accept serialized data from untrusted sources?
   - JSON.parse() of user input (generally safe in JS, but check what
     you do with the result -- prototype pollution via __proto__)
   - FormData parsing
   - URL search params parsed into objects
   - Cookie values deserialized
   - Webhook payloads parsed

2. FRAMEWORK-SPECIFIC
   - Next.js App Router: Keep framework patched (CVE-2025-55182)
   - Server Actions: Input is deserialized -- validate with Zod BEFORE use
   - API routes: Never pass raw parsed body to dynamic code execution

3. PROTOTYPE POLLUTION (JavaScript-specific)
   - Does any code merge user input into objects?
   - Object.assign({}, userInput) -- vulnerable if userInput has __proto__
   - Deep merge libraries: check if they are prototype-pollution safe
   - Fix: Object.create(null) for config objects, or explicit field picking

4. PREVENTION
   - Never deserialize data from untrusted sources without schema validation
   - Use Zod/Yup to validate the SHAPE of deserialized data
   - Never use dynamic code execution (Function constructor, vm module) with user data
   - Pin framework versions and monitor CVE feeds
```

**CWE reference:** CWE-502 (Deserialization of Untrusted Data), CWE-1321 (Prototype Pollution)

---

## Gap 7: Resource Exhaustion and Allocation Without Limits

**What is missing:** Rate limiting is mentioned for API endpoints, but there is no research on **per-feature resource allocation limits** -- unbounded queries, unbounded file uploads, unbounded batch operations, unbounded webhook retries.

**Why it matters:** CWE-770 (Allocation of Resources Without Limits or Throttling) is NEW to the CWE Top 25 in 2025, at position #25. This goes beyond rate limiting: it is about any feature that allows users to trigger unbounded resource consumption.

**What to research per feature:**

```
RESOURCE EXHAUSTION CHECKLIST (per feature):

1. QUERY LIMITS
   - Does this feature allow unbounded SELECT queries?
     (e.g., GET /api/users with no pagination -- returns ALL users)
   - Max page size enforced server-side (not just client default)
   - Complex query prevention: limit JOIN depth, WHERE clause complexity
   - Full-text search: limit query length, result count

2. BATCH OPERATION LIMITS
   - Can users trigger batch operations? (bulk delete, bulk import)
   - Is there a max batch size enforced server-side?
   - Are batch operations async with progress tracking?

3. FILE/DATA LIMITS
   - Upload size limits (express.json({ limit: '10mb' }))
   - Number of files per upload
   - Storage quota per user/organization
   - Zip bomb detection (compressed files that expand to enormous size)

4. COMPUTATION LIMITS
   - Does the feature trigger expensive computation? (report generation,
     image processing, PDF generation)
   - Timeout on expensive operations
   - Queue expensive work with concurrency limits

5. WEBHOOK/RETRY LIMITS
   - If this feature sends webhooks: max retry count, exponential backoff
   - If this feature receives webhooks: dedup by event ID
   - Dead letter queue for permanently failed deliveries
```

**CWE reference:** CWE-770 (Allocation of Resources Without Limits), CWE-400 (Uncontrolled Resource Consumption)

---

## Gap 8: Error Information Leakage (Beyond Stack Traces)

**What is missing:** The current system covers "no stack traces in responses" but misses the broader category of information leakage through error differentiation, HTTP headers, response timing, and API over-fetching.

**Why it matters:** CWE-200 (Exposure of Sensitive Information to an Unauthorized Actor) is ranked #20 in the 2025 CWE Top 25. Information leakage is often the **prerequisite** for other attacks -- it tells the attacker what to attack.

**What to research per feature:**

```
INFORMATION LEAKAGE CHECKLIST (per feature):

1. ERROR MESSAGE DIFFERENTIATION
   - Login: Does "invalid email" vs "invalid password" tell attacker
     which emails are registered? (Fix: "Invalid credentials")
   - Password reset: Does the response differ for existing vs
     non-existing emails? (Fix: Always say "If that email exists...")
   - API 404 vs 403: Does the app reveal resource existence to
     unauthorized users? (Fix: 404 for both "not found" and "not authorized")

2. HTTP HEADER LEAKAGE
   - X-Powered-By header exposes framework (remove it)
   - Server header exposes web server version (remove it)
   - Detailed error headers in development mode leaking to production

3. API OVER-FETCHING
   - Does the API return more fields than the client needs?
   - Does it return internal IDs, timestamps, or metadata the UI ignores?
   - Prisma: Always use select to return only needed fields
   - Never return the full database record when a subset suffices

4. VERBOSE LOGGING
   - Are PII fields (email, name, IP) logged in plaintext?
   - Are request bodies with passwords/tokens logged?
   - Are database queries with sensitive WHERE clauses logged?
   - Fix: Structured logging with PII redaction

5. DEBUG/DEVELOPMENT ARTIFACTS
   - GraphQL introspection enabled in production?
   - API documentation endpoints accessible in production?
   - Source maps deployed to production? (expose source code)
   - .env.example with real-looking values committed?
```

**CWE references:** CWE-200 (Information Exposure), CWE-209 (Error Message Information Exposure), CWE-532 (Insertion of Sensitive Information into Log File)

---

## Gaps We Considered But Are NOT Adding

The following were evaluated and intentionally excluded as either too niche, too infrastructure-level, or already covered implicitly:

| Candidate Gap | Why Excluded |
|--------------|-------------|
| Subdomain takeover | Infrastructure concern, not per-feature research |
| Email header injection | Extremely rare in modern frameworks with library email sending |
| Clickjacking | Already covered by X-Frame-Options in api-security.md |
| CSRF | Already in CWE Top 25 coverage (#3 in 2025); framework default protections sufficient for most cases with SameSite cookies |
| Legal/regulatory per feature | Too domain-specific; covered adequately by the GDPR/privacy gap above plus common sense |
| Offline behavior | PWA concern, not pre-implementation security research |
| Load/stress testing | Operational concern, not research gap; belongs in CI/CD pipeline |
| Mobile responsiveness | UI concern, already in accessibility section |
| Accessibility per feature | Already covered in Section 2.6 of existing doc |

---

## Integration: Where These Gaps Fit in the Research System

These 8 gaps map to existing research system sections as **additions**, not replacements:

| Gap | Integrates Into | New Section Number |
|-----|----------------|-------------------|
| Race Conditions | Section 5 (Security Research) | 5.4 |
| Mass Assignment | Section 5 (Security Research) | 5.5 |
| Timing Attacks | Section 5 (Security Research) | 5.6 |
| Data Privacy/GDPR | NEW top-level section | Section 11 |
| Resilience | NEW top-level section | Section 12 |
| Deserialization | Section 5 (Security Research) | 5.7 |
| Resource Exhaustion | Section 5 (Security Research) | 5.8 |
| Information Leakage | Section 5 (Security Research) | 5.9 |

---

## Updated Quick Reference: Research Checklist Additions

### For Every Feature (add to Section 10)

- [ ] Race condition analysis: identify check-then-act sequences, single-use resources
- [ ] Mass assignment review: verify explicit field allowlists on all create/update
- [ ] Timing attack review: verify constant-time comparison for all secret values
- [ ] Privacy impact: classify PII, define retention, plan for deletion
- [ ] Resilience analysis: map external dependencies, define failure modes and fallbacks
- [ ] Deserialization safety: validate all parsed input with schema before use
- [ ] Resource limits: enforce pagination, batch limits, upload limits, computation timeouts
- [ ] Information leakage: unified error messages, minimal API responses, no PII in logs

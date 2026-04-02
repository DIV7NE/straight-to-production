# AI Code Vulnerabilities — What AI Gets Wrong

45% of AI-generated code contains security vulnerabilities (Veracode 2026).
Security pass rates flat at ~55% since 2023. Read this BEFORE accepting any generated code.

## The 10 Patterns AI Gets Wrong Most Often (OX Security)

| Pattern | Prevalence | What Happens |
|---------|-----------|-------------|
| Comments everywhere | 90-100% | Noise that hides real logic |
| By-the-book fixation | 80-90% | Textbook code that ignores project context |
| Avoiding refactors | 80-90% | Duplicates instead of reusing existing code |
| Happy-path only | 60-70% | No error handling, no edge cases |
| Fake test coverage | 40-50% | Tests that always pass, test implementation not behavior |
| Hallucinated imports | 30-40% | Packages/functions that don't exist |
| God files | 30-40% | 1000+ line files doing everything |
| Generic names | 60-70% | data, result, item, temp, handler |
| Missing cleanup | 40-50% | Event listeners, timers, subscriptions never removed |
| Premature abstraction | 30-40% | DRY taken too far, abstractions for one-time code |

## AI-Specific Insecure Patterns (MUST check for these)

- Math.random() for tokens — use crypto.randomUUID() or crypto.getRandomValues()
- MD5 or SHA1 for passwords — use bcrypt, argon2, or scrypt
- CORS with wildcard origin in production — use explicit origin list
- JWT stored in localStorage — use httpOnly cookies
- Logging passwords or tokens to console — never log secrets
- Rate limiting only on client side — server-side rate limiting required
- Missing WHERE clause in UPDATE/DELETE — always scope mutations
- Dynamic code execution with user input — never do this
- Disabled TLS verification — never disable in production
- Missing request body size limits — set max payload (e.g., 10MB)

## Slopsquatting (AI-Only Attack Vector)

AI hallucinates package names that don't exist. Attackers register those names with malware.
- 38% of AI hallucinations are wrong APIs on real packages
- 13% are APIs on entirely fabricated packages
- 51% are non-existent functions on real packages

**Prevention:** Before every package install:
- Verify the package exists on the official registry
- Check download count (brand new packages with 0 downloads = suspicious)
- Check the publisher matches the expected organization
- Never blindly install a package name from AI output without verification

## 8 Critical Security Gaps AI Misses

**1. Race Conditions (CWE-367)** — double-spend, double-booking, coupon reuse
- Any operation that reads-then-writes must use database-level locking or transactions
- Concurrent users submitting the same form = potential duplicate records
- Use: SELECT FOR UPDATE, database transactions, optimistic locking with version field

**2. Mass Assignment (CWE-915)** — users inject fields they shouldn't control
- NEVER spread request body directly into create/update: `db.create({ ...req.body })`
- ALWAYS pick allowed fields explicitly: `{ name: body.name, email: body.email }`
- A user could send `{ role: "admin" }` in the request and escalate their privileges

**3. Timing Attacks on Auth (CWE-208)** — leaks secrets byte-by-byte
- NEVER compare tokens/API keys with `===` — use `crypto.timingSafeEqual()`
- String comparison returns faster for early mismatches, revealing the correct bytes over many attempts

**4. Data Privacy Per Feature** — GDPR/CCPA shapes your schema
- Every feature that stores user data: what's collected, how long, can it be deleted?
- Soft delete vs hard delete (GDPR right to erasure requires actual deletion)
- PII must be identified and handled (encrypted at rest, excluded from logs)
- Data minimization: don't collect what you don't need

**5. Resilience / Graceful Degradation** — what if external services are down?
- Payment succeeds at Stripe but database write fails = money taken, no record
- Use: saga pattern (compensating transactions), retry with exponential backoff
- Circuit breaker for external service calls (don't hammer a down service)
- Fallback behavior: app should still partially function when non-critical services fail

**6. Insecure Deserialization (CWE-502)** — RCE via untrusted data
- Never deserialize user-controlled data without validation
- Recent CVEs: React RSC (CVE-2025-55182, CVSS 10.0), Next.js (CVE-2025-66478, CVSS 10.0)
- Always validate/sanitize before parsing JSON, YAML, or serialized objects from external sources

**7. Resource Exhaustion (CWE-770)** — unbounded operations crash your server
- Set max payload size on all endpoints (e.g., 10MB)
- Paginate all list endpoints (never return unbounded results)
- Set timeouts on all external calls and database queries
- Limit batch operations (max 100 items per batch, not unlimited)
- Validate file uploads: size limit, type check, no zip bombs

**8. Error Information Leakage (CWE-200)** — errors reveal internal details
- Different error messages for "user not found" vs "wrong password" = user enumeration
- HTTP headers leaking server version, framework info
- API returning more fields than the client needs (over-fetching)
- Stack traces, file paths, database names in error responses
- PII appearing in logs that get shipped to third-party services

## Verification Checklist (Run Before Accepting AI Code)

Before accepting ANY generated code:
- [ ] Every import verified — the package exists, the function exists in that package
- [ ] No hardcoded secrets (Stripe keys, passwords, API tokens)
- [ ] All user inputs validated server-side (not just client-side)
- [ ] All database queries parameterized (no string concatenation)
- [ ] All API endpoints check authentication
- [ ] All data queries scoped to authenticated user (no IDOR)
- [ ] Error handling returns safe messages (no stack traces to users)
- [ ] No sensitive data logged to console
- [ ] Dependencies are real, current, and not deprecated
- [ ] Tests test BEHAVIOR, not implementation details
- [ ] No God files (flag anything over 300 lines)
- [ ] No mass assignment (request body not spread directly into DB operations)
- [ ] Concurrent operations use transactions or locking (no race conditions)
- [ ] Token/secret comparisons use timing-safe functions
- [ ] External service calls have timeouts and fallback behavior
- [ ] All list endpoints are paginated (no unbounded queries)
- [ ] Error messages don't differentiate between user-not-found and wrong-password
- [ ] No generic variable names in business logic

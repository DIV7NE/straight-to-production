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
- [ ] No generic variable names in business logic

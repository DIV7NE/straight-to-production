# OWASP Top 10 — Quick Reference for Web Applications

## A01: Broken Access Control
- Every API route and server action MUST check authentication AND authorization
- Never trust client-side checks — always verify server-side
- Use middleware to protect route groups
- Default deny: block unless explicitly granted

## A02: Cryptographic Failures
- Never store passwords in plain text — use bcrypt or argon2
- Never commit secrets — use environment variables (see env-handling.md)
- Enforce HTTPS everywhere

## A03: Injection
- Use parameterized queries for ALL database operations
- Never concatenate user input into SQL or HTML
- Validate all inputs with Zod schemas (see input-sanitization.md)
- Avoid rendering raw HTML from user input — sanitize with DOMPurify if unavoidable

## A04: Insecure Design
- Rate limit auth endpoints and public APIs (see api-security.md)
- Add CSRF protection for state-changing operations
- Use Content-Security-Policy headers

## A05: Security Misconfiguration
- Remove default credentials and sample data before deploying
- Disable debug endpoints in production
- Set proper CORS origins — never allow all origins in production

## A06: Vulnerable Components
- Run npm audit before every deployment
- Keep dependencies updated with npx npm-check-updates
- Pin dependency versions

## A07: Authentication Failures
- Implement account lockout after repeated failed attempts
- Use MFA for sensitive operations
- Never reveal whether an account exists in error messages
- Set cookie flags: httpOnly, secure, sameSite

## A08: Data Integrity Failures
- Validate all data server-side (see input-sanitization.md)
- Sign and verify webhook payloads (Stripe, Clerk, etc.)

## A09: Logging and Monitoring Failures
- Log auth events (login, logout, failed attempts)
- Never log sensitive data (passwords, tokens, PII)
- Implement error tracking (Sentry recommended)
- Remove debug logging before production deployment

## A10: Server-Side Request Forgery
- Validate all URLs before server-side requests
- Use allowlists for external service URLs
- Never pass user-controlled URLs directly to server-side fetch

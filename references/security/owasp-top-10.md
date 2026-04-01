# OWASP Top 10 — Quick Reference

## A01: Broken Access Control
- Every API endpoint and server-side action MUST check authentication AND authorization
- Never trust client-side checks — always verify server-side
- Use middleware/filters to protect route groups
- Default deny: block unless explicitly granted

## A02: Cryptographic Failures
- Never store passwords in plain text — use bcrypt, argon2, or scrypt
- Never commit secrets — use environment variables (see env-handling.md)
- Enforce HTTPS everywhere
- Use strong, up-to-date TLS configurations

## A03: Injection
- Use parameterized queries / prepared statements for ALL database operations
- Never concatenate user input into SQL, HTML, shell commands, or templates
- Validate all inputs with a schema validation library (Zod, Pydantic, etc.)
- Sanitize user content before rendering as HTML

## A04: Insecure Design
- Rate limit authentication endpoints and public APIs (see api-security.md)
- Add CSRF protection for state-changing operations
- Use Content-Security-Policy headers (web applications)
- Design with the principle of least privilege

## A05: Security Misconfiguration
- Remove default credentials and sample data before deploying
- Disable debug endpoints and verbose error messages in production
- Set proper CORS origins — never allow all origins in production
- Keep frameworks and dependencies updated

## A06: Vulnerable Components
- Run dependency audit before every deployment (npm audit, pip audit, cargo audit, etc.)
- Keep dependencies updated regularly
- Pin dependency versions for reproducible builds
- Monitor for CVEs in your dependency tree

## A07: Authentication Failures
- Implement account lockout after repeated failed attempts
- Use MFA for sensitive operations
- Never reveal whether an account exists in error messages ("Invalid credentials" not "User not found")
- Set cookie/session flags: httpOnly, secure, sameSite (web apps)

## A08: Data Integrity Failures
- Validate all data server-side, not just client-side
- Sign and verify webhook payloads from external services
- Use checksums for critical data transfers
- Implement audit logging for sensitive operations

## A09: Logging and Monitoring Failures
- Log authentication events (login, logout, failed attempts)
- Never log sensitive data (passwords, tokens, PII, credit card numbers)
- Implement error tracking (Sentry, Datadog, or equivalent)
- Remove debug/development logging before production deployment

## A10: Server-Side Request Forgery
- Validate all URLs before making server-side requests
- Use allowlists for external service URLs
- Never pass user-controlled URLs directly to server-side HTTP clients
- Block requests to internal/private IP ranges from user input

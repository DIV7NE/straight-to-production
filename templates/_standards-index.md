# Pilot Standards Index
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# These are constraints, not suggestions. Do not skip them.
# Before implementing framework-specific APIs, resolve and query latest docs via Context7.

## How to Use This Index
When working on code that touches any domain below, READ the referenced file first.
Do NOT rely on training data for security, accessibility, or performance patterns —
the referenced files contain verified, current standards.

## Security Standards
|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration, sensitive data exposure
|env-handling.md — Environment variables, secrets management, never hardcode credentials
|auth-patterns.md — Middleware protection, server-side auth, row-level security, webhook verification
|input-sanitization.md — Input validation at every boundary, parameterized queries, output encoding
|api-security.md — Rate limiting, CORS, security headers, API key rotation, webhook signatures
|ai-code-vulnerabilities.md — AI-specific security mistakes, OX Security 10 anti-patterns, slopsquatting, verification checklist

## Accessibility Standards
|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA: perceivable, operable, understandable, robust
|keyboard-navigation.md — Focus management, tab order, skip links, modal focus trapping
|screen-reader.md — Semantic HTML first, ARIA when needed, live regions, landmark roles
|color-contrast.md — 4.5:1 text ratio, 3:1 UI components, never convey info by color alone

## Performance Standards
|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1, measurement and optimization
|bundle-optimization.md — Tree shaking, code splitting, lazy loading, no barrel imports
|query-optimization.md — Parallel queries, N+1 prevention, indexing strategy, caching layers
|image-optimization.md — Responsive images, lazy loading, format selection, priority hints

## Production Readiness
|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages, server-side logging
|loading-states.md — Skeleton screens, progress indicators, optimistic updates
|empty-states.md — Zero-data states, no-results states, first-run experience
|edge-cases.md — Offline handling, slow connections, concurrent edits, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML, structured data, social sharing
|legal-compliance.md — Privacy policy, terms of service, GDPR, cookie consent, license auditing
|code-hygiene.md — Anti-garbage rules: no unused code, no comment noise, no file pollution, no God files, post-build scan

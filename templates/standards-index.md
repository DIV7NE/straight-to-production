# Pilot Standards Index
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# These are constraints, not suggestions. Do not skip them.

## How to Use This Index
When working on code that touches any domain below, READ the referenced file first.
Do NOT rely on training data for security, accessibility, or performance patterns.
The referenced files contain verified, current standards.

## Security Standards
|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration, sensitive data exposure
|env-handling.md — Environment variables, secrets management, never hardcode credentials
|auth-patterns.md — Session handling, JWT, OAuth flows, RBAC, middleware protection
|input-sanitization.md — User input validation, parameterized queries, output encoding
|api-security.md — Rate limiting, CORS, CSP headers, API key rotation

## Accessibility Standards
|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance checklist, perceivable/operable/understandable/robust
|keyboard-navigation.md — Focus management, tab order, skip links, focus trapping in modals
|screen-reader.md — ARIA labels, semantic HTML, live regions, landmark roles
|color-contrast.md — 4.5:1 text ratio, 3:1 UI components, do not convey info by color alone

## Performance Standards
|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1, measurement and optimization
|bundle-optimization.md — Tree shaking, code splitting, dynamic imports, no barrel file imports
|waterfall-prevention.md — Parallel fetches, Promise.all, no sequential awaits, Suspense boundaries
|image-optimization.md — next/image, WebP/AVIF, responsive sizes, lazy loading, priority hints

## Production Readiness
|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries, try/catch in server actions, user-facing error messages, logging
|loading-states.md — Skeleton screens, Suspense fallbacks, optimistic updates, progress indicators
|empty-states.md — Zero-data states, first-run experience, onboarding flows
|edge-cases.md — Offline handling, slow connections, concurrent edits, session expiry, timezone handling
|seo-basics.md — Meta tags, OG images, sitemap, robots.txt, semantic HTML, structured data

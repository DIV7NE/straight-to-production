# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
- **Framework**: Next.js (App Router, Server Components by default)
- **Database**: Supabase (PostgreSQL)
- **Auth**: Clerk (middleware-protected routes, webhook verification)
- **Styling**: Tailwind CSS + shadcn/ui
- **Validation**: Zod (all API boundaries)
- **Deployment**: Vercel

## Key Decisions
{{DECISIONS}}

## Project Structure
```
src/
├── app/               # Routes and layouts
│   ├── (auth)/        # Sign-in, sign-up
│   ├── (dashboard)/   # Protected app routes
│   ├── api/           # API routes and webhooks
│   ├── error.tsx      # Global error boundary
│   ├── loading.tsx    # Global loading state
│   ├── not-found.tsx  # Custom 404
│   └── layout.tsx     # Root layout
├── components/
│   └── ui/            # shadcn/ui components
├── lib/
│   ├── db.ts          # Supabase client
│   ├── env.ts         # Env validation (Zod)
│   └── utils.ts       # Shared utilities
├── actions/           # Server actions
└── types/             # Shared TypeScript types
```

## Code Standards

### Always Do
- Server Components by default. Only add 'use client' when you need interactivity.
- Validate ALL inputs with Zod at API boundaries (server actions, API routes).
- Wrap server actions and API routes in try/catch. Never expose raw errors to users.
- Use `next/image` for all images. Use `priority` only on above-the-fold.
- Parallelize independent fetches with `Promise.all()`. Never sequential awaits for unrelated data.
- Import from specific paths, not barrel files: `from '@/components/ui/button'` not `from '@/components'`.
- Every list/table needs an empty state. Every async operation needs a loading state.
- Commit atomically — one logical change per commit with a clear message.

### Never Do
- Never hardcode secrets, API keys, or database URLs. Use env vars validated by `src/lib/env.ts`.
- Never use `<div onClick>` — use `<button>` for actions, `<a>` for navigation.
- Never skip alt text on images. Use `alt=""` only for purely decorative images.
- Never use `outline: none` without providing an alternative focus style.
- Never trust client-side validation alone. Always validate server-side.
- Never return raw error objects to the client. Log full errors server-side, return safe messages.

## Pilot Standards Index
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.

|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Clerk middleware, server-side auth, row-level security
|input-sanitization.md — Zod validation, parameterized queries
|api-security.md — Rate limiting, CORS, CSP headers

|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA checklist
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — ARIA, semantic HTML, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — No barrel imports, dynamic imports, tree shaking
|waterfall-prevention.md — Promise.all, Suspense boundaries, parallel fetches
|image-optimization.md — next/image, responsive sizes, priority hints

|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries, try/catch, user-facing messages
|loading-states.md — Skeletons, Suspense, optimistic updates
|empty-states.md — Zero-data, no results, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, OG images, sitemap, semantic HTML

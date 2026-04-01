# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | SvelteKit 2 | File-based routing, SSR/SSG, form actions |
| ORM | Prisma | Type-safe queries, migrations, studio |
| Styling | Tailwind CSS | Utility-first, purged in production |
| Validation | Zod + superforms | Server validation with progressive enhancement |
| Deployment | Vercel / Node adapter | Flexible deployment targets |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
src/
  routes/
    (app)/dashboard/,settings/  # Protected routes (+page.svelte, +page.server.ts)
    (auth)/login/,register/     # Auth routes
    api/webhooks/+server.ts     # API endpoints
    +layout.svelte,+error.svelte
  lib/
    server/prisma.ts,auth.ts    # Server-only modules
    components/ui/,forms/       # Reusable components
    schemas/                    # Zod validation schemas
  hooks.server.ts               # Auth, logging hooks
  app.d.ts                      # Type augmentation
```
## Code Standards
### Always Do
1. Use `+page.server.ts` load functions for data — never fetch in `onMount`
2. Validate all form action inputs with Zod before touching the database
3. Return `fail(400, { form })` from actions — never throw
4. Use `$derived` for computed values; `$state` only for mutable UI
5. Define Prisma client singleton in `$lib/server/prisma.ts`
6. Guard protected routes in `hooks.server.ts` — not per-page
### Never Do
1. Never import `$lib/server/*` in client code — build will fail
2. Never use raw `fetch` in load functions — use the provided `fetch` for cookies
3. Never mutate `$page.data` directly — use form actions or invalidation
4. Never put secrets in `$env/static/public` — use `$env/static/private`
5. Never use `goto()` for form submissions — use progressive form actions
## Stack Patterns
### Load Function + Form Action
```ts
// routes/(app)/projects/+page.server.ts
import { prisma } from "$lib/server/prisma";
import { fail } from "@sveltejs/kit";
import { z } from "zod";
const createSchema = z.object({ name: z.string().min(1).max(100) });
export const load: PageServerLoad = async ({ locals }) => {
  return { projects: await prisma.project.findMany({ where: { userId: locals.user.id } }) };
};
export const actions: Actions = {
  create: async ({ request, locals }) => {
    const parsed = createSchema.safeParse(Object.fromEntries(await request.formData()));
    if (!parsed.success) return fail(400, { errors: parsed.error.flatten() });
    await prisma.project.create({ data: { ...parsed.data, userId: locals.user.id } });
  },
};
```
### Server Hooks (Auth Guard)
```ts
// hooks.server.ts
import { redirect, type Handle } from "@sveltejs/kit";
import { sequence } from "@sveltejs/kit/hooks";
const auth: Handle = async ({ event, resolve }) => {
  const sessionId = event.cookies.get("session_id");
  if (sessionId) {
    const session = await prisma.session.findUnique({ where: { id: sessionId }, include: { user: true } });
    if (session) event.locals.user = session.user;
  }
  return resolve(event);
};
const guard: Handle = async ({ event, resolve }) => {
  if (event.url.pathname.startsWith("/dashboard") && !event.locals.user) throw redirect(303, "/login");
  return resolve(event);
};
export const handle = sequence(auth, guard);
```
## Pilot Standards Index
```
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML
```

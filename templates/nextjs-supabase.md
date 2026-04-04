# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Next.js 15 (App Router) | RSC, server actions, streaming |
| Auth | Clerk | Drop-in auth, org support, middleware |
| Database | Supabase (Postgres) | RLS, realtime, edge functions |
| Styling | Tailwind CSS + shadcn/ui | Utility-first + accessible components |
| Validation | Zod | Runtime type safety, form + env validation |
| Deployment | Vercel | Zero-config Next.js hosting |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
src/
  app/
    (auth)/sign-in,sign-up  # Auth routes
    (dashboard)/             # Protected app routes
    api/                     # Webhooks, cron
    layout.tsx               # Root layout with providers
  components/ui/,forms/,layouts/
  lib/supabase/{client,server,admin}.ts
  lib/validations/           # Zod schemas shared client/server
  actions/                   # Server actions by domain
  hooks/                     # Client-side React hooks
```
## Code Standards
### Always Do
1. Validate ALL env vars at build time with Zod (`env.ts` schema, fail-fast)
2. Use server components by default; add `"use client"` only when needed
3. Colocate Zod schemas in `lib/validations/` — share between forms and actions
4. Create Supabase clients per-request in server components
5. Protect routes via Clerk middleware matcher, not per-page checks
6. Return typed `{ success, data, error }` from server actions — never throw
7. Use `Promise.all()` for independent fetches; avoid sequential awaits
8. Apply Supabase RLS as defense-in-depth alongside Clerk auth
### Never Do
1. Never import `createBrowserClient` in server components or actions
2. Never store secrets in `NEXT_PUBLIC_*` env vars
3. Never skip Zod validation on server action inputs
4. Never use `any` — prefer `unknown` with type narrowing
5. Never fetch in client components when a server component can do it
6. Never use `useEffect` for data derivable during render
7. Never commit `.env.local` — use `.env.example` with placeholders
## Stack Patterns
### Middleware Auth (Clerk)
```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
const isProtected = createRouteMatcher(["/dashboard(.*)", "/api(.*)"]);
export default clerkMiddleware(async (auth, req) => {
  if (isProtected(req)) await auth.protect();
});
export const config = { matcher: ["/((?!_next|.*\\.).*)"] };
```
### Server Action with Zod
```ts
"use server";
import { auth } from "@clerk/nextjs/server";
import { createServerClient } from "@/lib/supabase/server";
import { createProjectSchema } from "@/lib/validations/project";
export async function createProject(formData: FormData) {
  const { userId } = await auth();
  if (!userId) return { success: false, error: "Unauthorized" };
  const parsed = createProjectSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { success: false, error: parsed.error.flatten() };
  const supabase = await createServerClient();
  const { data, error } = await supabase
    .from("projects").insert({ ...parsed.data, user_id: userId }).select().single();
  if (error) return { success: false, error: error.message };
  return { success: true, data };
}
```
### Env Validation
```ts
import { z } from "zod";
const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  CLERK_SECRET_KEY: z.string().min(1),
});
export const env = envSchema.parse(process.env);
```
## STP Standards Index
```
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.stp/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.stp/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.stp/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.stp/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML
```

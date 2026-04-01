# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Nuxt 3 | Auto-imports, SSR/SSG, file-based routing |
| State | Pinia | Official Vue store, devtools integration |
| Styling | Tailwind CSS + NuxtUI | Utility-first + Vue-native components |
| Validation | Zod | Runtime type safety, shared schemas |
| ORM | Drizzle | Lightweight, SQL-first, edge-compatible |
| Deployment | Nitro (any preset) | Universal: Vercel, Cloudflare, Node |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
app/
  pages/index.vue,dashboard/,auth/
  components/ui/,forms/,layouts/
  composables/useAuth.ts,useApi.ts
  layouts/default.vue,dashboard.vue
  middleware/auth.ts
  plugins/01.auth.client.ts
server/
  api/projects/{index.get,index.post,[id].get}.ts
  middleware/auth.ts
  utils/db.ts,auth.ts
  database/schema.ts,migrations/
```
## Code Standards
### Always Do
1. Use `useAsyncData` or `useFetch` for data — they handle SSR hydration
2. Define composables with `use` prefix in `composables/` for auto-import
3. Validate server inputs with Zod via `readValidatedBody` / `getValidatedQuery`
4. Use Pinia stores only for cross-component client state, not server data
5. Define route middleware in `middleware/` for auth guards
6. Type server route responses with `defineEventHandler`
### Never Do
1. Never call `useFetch` inside event handlers or watchers — setup context only
2. Never access `localStorage` without `if (import.meta.client)` guard
3. Never mutate Pinia state outside actions
4. Never use `axios` — `$fetch` / `useFetch` handles SSR, types, and caching
5. Never put database credentials in `runtimeConfig.public`
## Stack Patterns
### Composable + Server Route
```ts
// composables/useProjects.ts
export function useProjects() {
  const { data, status, refresh } = useFetch("/api/projects", { key: "projects", default: () => [] });
  return { projects: data, loading: computed(() => status.value === "pending"), refresh };
}
// server/api/projects/index.post.ts
import { z } from "zod";
import { db } from "~/server/utils/db";
import { projects } from "~/server/database/schema";
const bodySchema = z.object({ name: z.string().min(1).max(100) });
export default defineEventHandler(async (event) => {
  const user = event.context.user;
  if (!user) throw createError({ statusCode: 401, message: "Unauthorized" });
  const body = await readValidatedBody(event, bodySchema.parse);
  const [project] = await db.insert(projects).values({ ...body, userId: user.id }).returning();
  return project;
});
```
### Route Middleware
```ts
// middleware/auth.ts
export default defineNuxtRouteMiddleware(() => {
  const { loggedIn } = useAuth();
  if (!loggedIn.value) return navigateTo("/auth/login");
});
```
### Pinia Store
```ts
export const useAuthStore = defineStore("auth", () => {
  const user = ref<User | null>(null);
  const loggedIn = computed(() => !!user.value);
  async function login(creds: LoginInput) {
    user.value = await $fetch("/api/auth/login", { method: "POST", body: creds });
  }
  function logout() { user.value = null; navigateTo("/auth/login"); }
  return { user, loggedIn, login, logout };
});
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

# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Next.js 15 (App Router) | SSG, ISR, metadata API |
| Content | MDX + contentlayer | Markdown with components, type-safe content |
| Styling | Tailwind CSS + shadcn/ui | Utility-first + accessible components |
| Analytics | Vercel Analytics | Privacy-friendly, zero-config |
| Deployment | Vercel | Edge CDN, automatic ISR |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
src/
  app/
    (marketing)/page.tsx,pricing/,about/
    blog/[slug]/page.tsx     # Blog posts (SSG)
    docs/[...slug]/page.tsx  # Docs catch-all (SSG)
    sitemap.ts, robots.ts    # SEO files
    layout.tsx               # Root layout + metadata
  components/marketing/,blog/,mdx/,ui/
  content/blog/,docs/        # .mdx files
  lib/content.ts,metadata.ts
```
## Code Standards
### Always Do
1. Export `generateStaticParams` for all dynamic routes — SSG by default
2. Define `generateMetadata` on every page with title, description, og:image
3. Use semantic HTML (`<article>`, `<nav>`, `<main>`, `<section>`)
4. Add `alt` to every image; use `next/image` with explicit dimensions
5. Include JSON-LD structured data on blog posts and product pages
6. Keep LCP under 2.5s — inline critical hero content, defer scripts
7. Export `sitemap.ts` and `robots.ts` from app root
### Never Do
1. Never use client components for static content — SSG cannot serialize them
2. Never hardcode URLs — use env vars for `NEXT_PUBLIC_SITE_URL`
3. Never skip `loading.tsx` on dynamic segments
4. Never use `<a>` tags for internal links — use `next/link`
5. Never import heavy libs in the main bundle — lazy load below the fold
6. Never omit Open Graph images — they drive social click-through
## Stack Patterns
### Metadata + Sitemap
```ts
// app/layout.tsx
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL!),
  title: { default: "Site Name", template: "%s | Site Name" },
  description: "Site description for SEO",
  openGraph: { type: "website", locale: "en_US" },
};
// app/sitemap.ts
export default async function sitemap() {
  const posts = await getAllPosts();
  return [
    { url: "https://example.com", lastModified: new Date() },
    ...posts.map((p) => ({ url: `https://example.com/blog/${p.slug}`, lastModified: p.updatedAt })),
  ];
}
```
### Static Blog with MDX
```ts
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  return (await getAllPosts()).map((post) => ({ slug: post.slug }));
}
export async function generateMetadata({ params }: Props) {
  const post = await getPost(params.slug);
  if (!post) return {};
  return { title: post.title, description: post.excerpt };
}
export default async function BlogPost({ params }: Props) {
  const post = await getPost(params.slug);
  if (!post) notFound();
  return <article className="prose mx-auto">{post.content}</article>;
}
```
### Contact Form Server Action
```ts
"use server";
import { z } from "zod";
const contactSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  message: z.string().min(10).max(2000),
});
export async function submitContact(formData: FormData) {
  const parsed = contactSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { success: false, error: "Invalid input" };
  await fetch(process.env.EMAIL_API_URL!, {
    method: "POST",
    headers: { Authorization: `Bearer ${process.env.EMAIL_API_KEY}` },
    body: JSON.stringify(parsed.data),
  });
  return { success: true };
}
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

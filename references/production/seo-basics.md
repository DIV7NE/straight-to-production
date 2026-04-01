# SEO Basics for Web Applications

## Metadata (every page)
```typescript
// app/layout.tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: {
    default: 'App Name',
    template: '%s | App Name',
  },
  description: 'One sentence describing the app.',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    siteName: 'App Name',
  },
}
```

Per-page metadata:
```typescript
// app/dashboard/page.tsx
export const metadata: Metadata = {
  title: 'Dashboard',
  description: 'View your project metrics and activity.',
}
```

## Essential Files
- `app/sitemap.ts` — Auto-generate sitemap from routes
- `app/robots.ts` — Control crawler access
- `app/opengraph-image.tsx` — Dynamic OG images for social sharing
- `public/favicon.ico` — Browser tab icon

## Semantic HTML
- One `<h1>` per page (the page title)
- Heading hierarchy: h1 > h2 > h3 (never skip levels)
- Use `<nav>`, `<main>`, `<article>`, `<aside>`, `<footer>` appropriately
- Use `<a>` for navigation, `<button>` for actions

## Technical SEO
- Pages should be Server Components by default (rendered on server, indexable)
- Avoid client-side-only rendering for important content
- Use `generateStaticParams` for static generation of dynamic routes
- Add structured data (JSON-LD) for rich search results where applicable

## Checklist
- [ ] Every page has unique title and description
- [ ] OG images configured for social sharing
- [ ] sitemap.ts exists and includes all public pages
- [ ] robots.ts exists and allows indexing of public pages
- [ ] Heading hierarchy is correct (one h1, then h2, h3)
- [ ] Semantic HTML used throughout
- [ ] No important content behind client-side-only rendering

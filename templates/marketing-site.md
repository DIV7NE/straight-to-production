# Stack Recipe: Marketing / Landing Site

## When to Use
Landing pages, company sites, blogs, documentation sites. Content-heavy, SEO-critical, mostly static.

## Stack Components
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Next.js (App Router) | SSG/ISR, great SEO, image optimization |
| Content | MDX | Markdown with React components for blog/docs |
| Styling | Tailwind CSS + shadcn/ui | Rapid iteration, consistent design |
| Analytics | Vercel Analytics or PostHog | Privacy-friendly, server-side |
| Forms | React Hook Form + Zod | Validation, no backend needed with Formspree/Resend |
| Email | Resend | Transactional emails (contact forms, newsletters) |
| Deployment | Vercel | Automatic SSG, edge caching, preview URLs |

## Project Structure
```
src/
├── app/
│   ├── page.tsx              # Homepage (hero, features, CTA)
│   ├── about/page.tsx        # About page
│   ├── pricing/page.tsx      # Pricing page
│   ├── blog/
│   │   ├── page.tsx          # Blog listing
│   │   └── [slug]/page.tsx   # Blog post (MDX)
│   ├── contact/page.tsx      # Contact form
│   ├── layout.tsx            # Root layout (nav, footer)
│   ├── sitemap.ts            # Auto-generated sitemap
│   ├── robots.ts             # Crawler rules
│   └── opengraph-image.tsx   # Dynamic OG images
├── components/
│   ├── ui/                   # shadcn/ui
│   ├── hero.tsx              # Hero section
│   ├── features.tsx          # Features grid
│   ├── pricing-table.tsx     # Pricing comparison
│   ├── testimonials.tsx      # Social proof
│   └── cta.tsx               # Call to action
├── content/
│   └── blog/                 # MDX blog posts
│       └── first-post.mdx
└── lib/
    └── utils.ts
```

## Key Patterns

### Static Generation (default for marketing)
All marketing pages should be statically generated. No 'use client' unless interactive (forms, animations).

### SEO (critical for marketing sites)
```typescript
// app/layout.tsx
export const metadata: Metadata = {
  title: { default: 'Product Name — Tagline', template: '%s | Product Name' },
  description: 'Compelling one-sentence description with primary keyword.',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    siteName: 'Product Name',
    images: [{ url: '/og-image.png', width: 1200, height: 630 }],
  },
  twitter: { card: 'summary_large_image' },
}
```

### Contact Form (server action, no API route needed)
```typescript
'use server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function submitContact(formData: FormData) {
  const email = formData.get('email') as string
  const message = formData.get('message') as string
  // Validate with Zod, then send
  await resend.emails.send({
    from: 'contact@yourdomain.com',
    to: 'you@yourdomain.com',
    subject: `Contact from ${email}`,
    text: message,
  })
  return { success: true }
}
```

## Marketing-Specific Standards
- Every page MUST have unique title, description, and OG image
- Homepage should load in < 2 seconds (LCP target: 1.5s for marketing)
- All images use next/image with priority on above-the-fold hero
- No client-side JavaScript for content display — SSG everything
- Sitemap.ts and robots.ts are non-negotiable
- Structured data (JSON-LD) for organization and FAQ pages
- Mobile-first design — most traffic comes from mobile
- Clear CTA above the fold on every page

## Required Environment Variables
```
RESEND_API_KEY=re_... (if contact form)
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

## Initial Setup Commands
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir
npx shadcn@latest init
npm install @mdx-js/loader @mdx-js/react @next/mdx
npm install resend react-hook-form @hookform/resolvers zod
```

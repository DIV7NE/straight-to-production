# Stack Recipe: Next.js + Supabase + Clerk

## When to Use
SaaS web applications, dashboards, CRUD apps, content platforms — anything with users, data, and a web UI.

## Stack Components
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Next.js (App Router) | Server Components, API routes, built-in optimization |
| Database | Supabase (PostgreSQL) | Real-time, auth integration, generous free tier |
| Auth | Clerk | Handles auth complexity you'd forget (MFA, session management, webhooks) |
| Styling | Tailwind CSS + shadcn/ui | Consistent design system without building from scratch |
| Validation | Zod | Runtime type validation at API boundaries |
| Deployment | Vercel | Zero-config Next.js deployment, preview URLs |
| Payments | Stripe (if needed) | Industry standard, excellent docs |

## Project Structure
```
src/
├── app/
│   ├── (auth)/           # Auth pages (sign-in, sign-up)
│   ├── (dashboard)/      # Protected routes
│   │   ├── layout.tsx    # Dashboard layout with sidebar
│   │   └── page.tsx      # Dashboard home
│   ├── api/
│   │   └── webhooks/     # Clerk/Stripe webhooks
│   ├── error.tsx         # Global error boundary
│   ├── loading.tsx       # Global loading state
│   ├── not-found.tsx     # Custom 404
│   └── layout.tsx        # Root layout with providers
├── components/
│   ├── ui/               # shadcn/ui components
│   └── [feature]/        # Feature-specific components
├── lib/
│   ├── db.ts             # Supabase client
│   ├── env.ts            # Env validation with Zod
│   └── utils.ts          # Shared utilities
├── actions/              # Server actions
└── types/                # Shared TypeScript types
```

## Key Patterns

### Database Client
```typescript
// src/lib/db.ts
import { createClient } from '@supabase/supabase-js'
import { env } from './env'

export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY)
```

### Server Actions
```typescript
// src/actions/posts.ts
'use server'
import { auth } from '@clerk/nextjs/server'
import { z } from 'zod'
import { supabase } from '@/lib/db'

const schema = z.object({
  title: z.string().min(1).max(200).trim(),
  content: z.string().min(1).max(10000).trim(),
})

export async function createPost(formData: FormData) {
  const { userId } = await auth()
  if (!userId) return { error: 'Unauthorized' }

  const parsed = schema.safeParse(Object.fromEntries(formData))
  if (!parsed.success) return { error: 'Invalid input' }

  try {
    const { data, error } = await supabase
      .from('posts')
      .insert({ ...parsed.data, user_id: userId })
      .select()
      .single()

    if (error) throw error
    return { data }
  } catch (error) {
    console.error('createPost failed:', error)
    return { error: 'Failed to create post' }
  }
}
```

## Required Environment Variables
```
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
CLERK_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_SUPABASE_URL=https://...supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ... (server-side only)
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Initial Setup Commands
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir
npx shadcn@latest init
npm install @clerk/nextjs @supabase/supabase-js zod
```

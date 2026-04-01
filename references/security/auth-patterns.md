# Authentication & Authorization Patterns

## With Clerk (recommended stack)

### Middleware Protection
```typescript
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhooks(.*)',
])

export default clerkMiddleware(async (auth, request) => {
  if (!isPublicRoute(request)) {
    await auth.protect()
  }
})

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
}
```

### Server-Side Auth Check
```typescript
import { auth } from '@clerk/nextjs/server'

export async function getProtectedData() {
  const { userId } = await auth()
  if (!userId) throw new Error('Unauthorized')
  // now safe to query user's data
}
```

### API Route Protection
EVERY API route that reads/writes user data MUST check auth:
```typescript
import { auth } from '@clerk/nextjs/server'

export async function POST(request: Request) {
  const { userId } = await auth()
  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  // proceed with authenticated request
}
```

## Authorization (who can do what)

### Row-Level Security
Always filter by userId — never trust client-provided user IDs:
```typescript
// CORRECT
const posts = await db.post.findMany({ where: { userId } })

// WRONG — user could request another user's posts
const posts = await db.post.findMany({ where: { userId: params.userId } })
```

### Role-Based Access
```typescript
const { userId, sessionClaims } = await auth()
const role = sessionClaims?.metadata?.role

if (role !== 'admin') {
  return Response.json({ error: 'Forbidden' }, { status: 403 })
}
```

## Webhook Security
Always verify webhook signatures:
```typescript
import { Webhook } from 'svix'

const wh = new Webhook(process.env.CLERK_WEBHOOK_SECRET!)
const payload = await wh.verify(body, headers)
```

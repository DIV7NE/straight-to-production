# Error Handling for Production

## Principle
Users should NEVER see a raw error, a blank screen, or a generic "Something went wrong." Every error state should be designed, informative, and offer a next step.

## Next.js Error Boundaries

### Global Error Boundary (app/error.tsx)
```typescript
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <p>We've been notified and are looking into it.</p>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

### Not Found Page (app/not-found.tsx)
Always create a custom 404. The default is unhelpful.

### Per-Route Error Boundaries
Add `error.tsx` in route segments that have unique error handling needs (checkout, dashboard, etc.)

## Server Action Error Handling
```typescript
'use server'

export async function createPost(formData: FormData) {
  try {
    // validate input
    const parsed = schema.safeParse(Object.fromEntries(formData))
    if (!parsed.success) {
      return { error: 'Invalid input. Please check your fields.' }
    }
    // perform action
    await db.post.create({ data: parsed.data })
    return { success: true }
  } catch (error) {
    console.error('createPost failed:', error)
    return { error: 'Failed to create post. Please try again.' }
  }
}
```

NEVER: `throw error` from a server action without catching it.
NEVER: Return the raw error message to the user (security risk).
ALWAYS: Log the full error server-side, return a safe message client-side.

## API Route Error Handling
```typescript
export async function POST(request: Request) {
  try {
    const body = await request.json()
    const parsed = schema.safeParse(body)
    if (!parsed.success) {
      return Response.json({ error: 'Invalid request' }, { status: 400 })
    }
    // ... handle request
    return Response.json({ data: result })
  } catch (error) {
    console.error('API error:', error)
    return Response.json({ error: 'Internal server error' }, { status: 500 })
  }
}
```

## What "Production Ready" Error Handling Means
- [ ] Global error.tsx exists
- [ ] Custom not-found.tsx exists
- [ ] All server actions wrapped in try/catch
- [ ] All API routes wrapped in try/catch
- [ ] User-facing error messages are helpful, not technical
- [ ] Full errors logged server-side for debugging
- [ ] No raw error objects returned to client
- [ ] Error tracking service connected (Sentry recommended)

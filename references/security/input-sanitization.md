# Input Validation & Sanitization

## Principle
Validate at the boundary. Every piece of data that crosses from client to server must be validated before use. Use Zod for runtime validation — TypeScript types are compile-time only and don't protect at runtime.

## Zod Validation Pattern
```typescript
import { z } from 'zod'

const createPostSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  content: z.string().min(1).max(10000).trim(),
  tags: z.array(z.string().max(50)).max(10).optional(),
})

export async function createPost(formData: FormData) {
  const parsed = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    tags: formData.getAll('tags'),
  })

  if (!parsed.success) {
    return { error: 'Invalid input', details: parsed.error.flatten() }
  }

  // Use parsed.data — guaranteed valid
  await db.post.create({ data: parsed.data })
}
```

## Common Validation Rules
- Strings: `.min(1)` (no empty), `.max(N)` (prevent abuse), `.trim()` (no whitespace padding)
- Emails: `.email()` — but also validate on server, never trust format alone
- URLs: `.url()` — validate protocol is http/https
- Numbers: `.int().positive()` for IDs, `.min(0).max(N)` for quantities
- Arrays: `.max(N)` to prevent payload abuse

## What to Validate
- ALL form submissions
- ALL API request bodies
- ALL URL parameters and query strings
- ALL webhook payloads (after signature verification)
- File uploads: check type, size, extension

## What NOT to Do
- Never use string concatenation for SQL queries
- Never insert user input directly into HTML
- Never pass user input to file system operations without path validation
- Never use user input in shell commands

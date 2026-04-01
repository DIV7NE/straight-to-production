# Environment Variable Handling

## Rules (non-negotiable)
- NEVER hardcode secrets, API keys, database URLs, or tokens in source code
- NEVER commit .env files to git — add `.env*` to .gitignore immediately
- NEVER log environment variables or include them in error messages
- NEVER expose server-side env vars to the client (no NEXT_PUBLIC_ prefix for secrets)

## Next.js Environment Variable Pattern
```
# .env.local (gitignored, local development)
DATABASE_URL=postgresql://...
CLERK_SECRET_KEY=sk_...
STRIPE_SECRET_KEY=sk_...

# .env (committed, non-sensitive defaults)
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
```

## Validation Pattern
Create `src/lib/env.ts` to validate at startup:
```typescript
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  CLERK_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  NEXT_PUBLIC_APP_URL: z.string().url(),
})

export const env = envSchema.parse(process.env)
```

## Deployment Checklist
- Set all required env vars in deployment platform (Vercel/Railway/Cloudflare)
- Use different values per environment (dev/staging/production)
- Rotate secrets regularly
- Use Vercel's env var encryption for sensitive values

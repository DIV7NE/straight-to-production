# API Security

## Rate Limiting
Every public-facing endpoint MUST have rate limiting. Without it, anyone can:
- Brute-force authentication (try millions of passwords)
- Spam data creation endpoints (fill your database, rack up hosting costs)
- DDoS your application (overwhelm your server)

Rate limit tiers:
- Auth endpoints (login, signup, password reset): strict (5-10 per minute)
- Public API endpoints: moderate (60-100 per minute per IP)
- Authenticated endpoints: generous (300+ per minute per user)

Implementation approaches:
- In-memory rate limiting (good for single-server)
- Redis-based rate limiting (good for distributed/serverless)
- API gateway rate limiting (Cloudflare, AWS API Gateway, Nginx)
- Framework middleware (most frameworks have rate limiting middleware)

## CORS (Web Applications)
- NEVER use `Access-Control-Allow-Origin: *` in production
- Explicitly list allowed origins (your frontend domain)
- Restrict allowed methods to what's actually needed
- Restrict allowed headers to what's actually sent

## Security Headers (Web Applications)
Add these via middleware or reverse proxy:
- `Content-Security-Policy` — prevents XSS by controlling what scripts can execute
- `X-Content-Type-Options: nosniff` — prevents MIME type sniffing
- `X-Frame-Options: DENY` — prevents clickjacking
- `Referrer-Policy: strict-origin-when-cross-origin` — controls referrer information
- `Permissions-Policy` — controls browser features (camera, microphone, geolocation)

## API Authentication
For APIs consumed by external clients:
- Use API keys for server-to-server communication
- Use OAuth 2.0 / JWT for user-delegated access
- Rotate API keys regularly
- Hash API keys before storing (treat like passwords)
- Include key scoping (read-only, write, admin)

## Webhook Verification
ALWAYS verify signatures for incoming webhooks. Common providers:
- Stripe: uses HMAC-SHA256 with `stripe-signature` header
- Clerk/Auth providers: typically use Svix with signature verification
- GitHub: uses HMAC-SHA256 with `x-hub-signature-256` header
- Generic: most use HMAC with a shared secret

Never process unverified payloads. Log and discard unsigned webhooks.

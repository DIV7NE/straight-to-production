# Authentication & Authorization Patterns

## Principles

### Authentication (who are you?)
- Protect every non-public route/endpoint with auth middleware or guards
- Verify authentication server-side on EVERY request — never trust client-side state alone
- Use established auth libraries (Clerk, Auth.js, Passport, Devise, Spring Security, etc.) — don't build your own
- Handle session expiry gracefully — redirect to login, preserve intended destination

### Authorization (what can you do?)
- Check authorization AFTER authentication — both are required for protected resources
- Filter data by the authenticated user's ID — never trust user-provided IDs for ownership
- Default deny: users can access nothing unless explicitly granted
- Implement role-based access (RBAC) if different user types exist (admin, user, viewer)

## Row-Level Security
Always filter queries by the authenticated user's identity:

```
CORRECT: Get items WHERE user_id = authenticated_user_id
WRONG:   Get items WHERE user_id = request.params.user_id
```

The second form lets any user request another user's data by changing the parameter.

## Middleware/Guard Pattern
Protect route groups with auth middleware rather than checking auth in every handler:

1. Define which routes are public (login, signup, marketing pages, webhooks)
2. Apply auth middleware to everything else by default
3. Add role checks on top of auth for admin/restricted routes

## Webhook Security
When receiving webhooks from external services (payment providers, auth providers, etc.):
- ALWAYS verify the webhook signature before processing
- Use the provider's SDK/library for verification
- Never process unverified webhook payloads
- Store webhook secrets in environment variables
- Respond with 200 quickly, process asynchronously if needed

## Session/Token Best Practices
- Use httpOnly cookies for session tokens (web apps) — prevents XSS token theft
- Set secure flag on cookies in production (HTTPS only)
- Set sameSite=lax or strict to prevent CSRF
- Use short-lived access tokens + refresh tokens for API auth
- Invalidate sessions on password change
- Store tokens securely (Keychain on iOS, EncryptedSharedPreferences on Android, SecureStore for React Native)

# Error Handling for Production

## Principle
Users should NEVER see a raw error, a stack trace, a blank screen, or a generic "Something went wrong." Every error state should be designed, informative, and offer a next step.

## The Three Layers

### 1. Global Error Handler
Every application needs a top-level catch-all:
- **Web apps**: Error boundary/page (Next.js error.tsx, React ErrorBoundary, Vue errorHandler, SvelteKit handleError)
- **APIs**: Global exception handler/middleware that returns structured error responses
- **Desktop/Mobile**: Crash handler that shows a recovery dialog
- **CLI tools**: Top-level try/catch with user-friendly error message

### 2. Operation-Level Error Handling
Wrap individual operations (API calls, database queries, file operations):
- Catch specific errors, not just generic exceptions
- Log the FULL error server-side (for debugging)
- Return a SAFE message client-side (for users)
- Never expose internal details: database names, file paths, stack traces

### 3. User-Facing Error Messages
- Explain what happened in plain language
- Tell the user what to do next (try again, contact support, refresh)
- Provide a recovery action when possible (retry button, back to safety)

## API Error Response Format
Consistent error responses across all endpoints:
```json
{
  "error": "Brief user-safe message",
  "code": "MACHINE_READABLE_CODE",
  "status": 400
}
```
- 400: Bad request (validation failure)
- 401: Not authenticated
- 403: Not authorized
- 404: Resource not found
- 429: Rate limited
- 500: Internal server error (never expose details)

## Error Logging
- Use structured logging (JSON format for production)
- Include: timestamp, error type, message, stack trace, request ID, user ID
- NEVER log: passwords, tokens, credit card numbers, PII
- Send to error tracking service (Sentry, Datadog, Bugsnag)
- Set up alerts for error rate spikes

## Checklist
- [ ] Global error handler exists
- [ ] Custom "not found" page/response exists
- [ ] All API/server operations wrapped in error handling
- [ ] User-facing error messages are helpful, not technical
- [ ] Full errors logged server-side for debugging
- [ ] No raw error objects or stack traces returned to users
- [ ] Error tracking service connected

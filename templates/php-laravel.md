# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Laravel 11 | Batteries-included, expressive syntax, massive ecosystem |
| ORM | Eloquent | Active Record, relationships, query scopes |
| Database | PostgreSQL | ACID, JSON columns, full-text search |
| Auth | Laravel Sanctum | SPA tokens, API tokens, session-based web |
| Validation | Form Requests | Controller-decoupled, authorization hooks |
| Queue | Laravel Queues (Redis) | Background jobs, retries, rate limiting |
## Key Decisions
{{DECISIONS}}
## Project Structure
```
app/Http/ — Controllers/{Auth}, Requests/
app/ — Models/, Services/, Exceptions/, Policies/, Jobs/
database/migrations/, routes/api.php
tests/Feature/, tests/Unit/
```

## Code Standards
### Always Do
1. Form Requests for all validation; keep controllers thin
2. Eloquent scopes: `scopeActive()`, `scopeOwnedBy()`
3. Policies for auth; `$request->validated()` for mass assignment
4. `config()` for env access; never `env()` outside config files
5. API Resources for response transformation; eager load with `with()`

### Never Do
1. Never put business logic in controllers; extract to Services
2. Never use `$request->all()` for assignment; only `->validated()`
3. Never N+1 query; use `with()` eager loading
4. Never skip `$fillable`/`$guarded` on models
5. Never return raw exception details to clients

## Stack Patterns
### Auth (Sanctum)
```php
Route::post('/auth/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('resources', ResourceController::class);
});
public function login(LoginRequest $request): JsonResponse {
    if (!Auth::attempt($request->validated())) {
        throw ValidationException::withMessages(['email' => ['Invalid credentials.']]);
    }
    $user = Auth::user();
    return response()->json(['user' => new UserResource($user),
        'token' => $user->createToken('api')->plainTextToken]);
}
```
### Input Validation
```php
class CreateUserRequest extends FormRequest {
    public function authorize(): bool { return true; }
    public function rules(): array {
        return [
            'name'     => ['required', 'string', 'min:1', 'max:100'],
            'email'    => ['required', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'max:72', 'confirmed'],
        ];
    }
}
```
### Error Handling
```php
// bootstrap/app.php (Laravel 11)
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->render(function (ModelNotFoundException $e, Request $request) {
        if ($request->expectsJson()) return response()->json(['error' => 'Not found.'], 404);
    });
    $exceptions->render(function (Throwable $e, Request $request) {
        if ($request->expectsJson()) {
            Log::error('Unhandled', ['msg' => $e->getMessage(), 'path' => $request->path()]);
            return response()->json(['error' => 'An unexpected error occurred.'], 500);
        }
    });
})
```

## Pilot Standards Index
```
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML
```

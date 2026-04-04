# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Chi | Lightweight, idiomatic net/http compatible, composable middleware |
| Query Layer | sqlc | SQL-first — write SQL, generate type-safe Go, no ORM overhead |
| DB Driver | pgx v5 | Fastest Postgres driver for Go, connection pooling, batch queries |
| Validation | go-playground/validator | Struct tag validation, custom validators |
| Auth | golang-jwt/jwt | JWT parsing and generation, HMAC/RSA support |
| Config | envconfig | Struct-based env loading, no manual os.Getenv |
| Logging | slog (stdlib) | Structured logging since Go 1.21, zero deps |
| Deployment | Docker multi-stage | Static binary, scratch base, minimal image |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
cmd/server/main.go     # Entrypoint: config, deps, router, shutdown
internal/
├── config/config.go   # Env-based config struct (envconfig tags)
├── database/
│   ├── queries/       # Raw .sql files (sqlc compiles these)
│   ├── models.go      # sqlc-generated structs
│   ├── db.go          # sqlc-generated query methods
│   └── pool.go        # pgx pool setup + health check
├── handler/
│   ├── router.go      # Chi router, middleware stack
│   └── [feature].go   # Feature handlers
├── middleware/
│   ├── auth.go        # JWT extraction, context injection
│   └── logging.go     # Structured request logging
├── service/           # Business logic (handlers call services)
├── dto/               # Request/response structs + validator tags
├── apperror/errors.go # Typed errors, HTTP status mapping
migrations/            # golang-migrate .sql (up/down pairs)
sqlc.yaml
```

## Code Standards
### Always Do
1. `sqlc` for all DB queries — write SQL, get type-safe Go, no runtime reflection
2. Validate all input with `go-playground/validator` struct tags
3. `context.Context` for request-scoped values (user ID, request ID, tracing)
4. `chi.URLParam()` for path params — validate and parse before use
5. Consistent JSON errors: `{"error": "message"}` shape everywhere
6. `pgxpool.Pool` (not single connections) — configure min/max for load
7. Graceful shutdown with `signal.NotifyContext` + `server.Shutdown(ctx)`
8. Keep handlers thin — parse input, call service, write response

### Never Do
1. Never `panic()` for expected errors — return error values up the stack
2. Never `interface{}` / `any` for request data — define typed structs
3. Never ignore `json.Decode` errors — always check and respond 400
4. Never `fmt.Sprintf` for SQL — use sqlc params or pgx args
5. Never store DB pool in globals — pass via dependency struct
6. Never return Go error strings to clients — they leak internals
7. Never skip `defer rows.Close()` — leaked rows exhaust the pool

## Stack Patterns
### Auth Middleware
```go
// internal/middleware/auth.go — Chi-compatible middleware
type contextKey string
const UserIDKey contextKey = "user_id"
func JWTAuth(secret string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            tokenStr, found := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
            if !found {
                http.Error(w, `{"error":"missing token"}`, http.StatusUnauthorized); return
            }
            token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
                return []byte(secret), nil
            })
            if err != nil || !token.Valid {
                http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized); return
            }
            ctx := context.WithValue(r.Context(), UserIDKey, token.Claims.(jwt.MapClaims)["sub"])
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```
### Input Validation
```go
// internal/dto/post.go
var validate = validator.New()
type CreatePostRequest struct {
    Title   string `json:"title"   validate:"required,min=1,max=200"`
    Content string `json:"content" validate:"required,min=1,max=50000"`
}
// In handler: decode, validate, then call service
var req dto.CreatePostRequest
if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    respondError(w, http.StatusBadRequest, "Invalid JSON"); return
}
if err := validate.Struct(&req); err != nil {
    respondError(w, http.StatusUnprocessableEntity, "Validation failed"); return
}
```
### Error Handling
```go
// internal/apperror/errors.go
type AppError struct {
    Code    int    `json:"-"`
    Message string `json:"error"`
}
func (e *AppError) Error() string { return e.Message }
func NotFound(msg string) *AppError   { return &AppError{Code: 404, Message: msg} }
func BadRequest(msg string) *AppError { return &AppError{Code: 400, Message: msg} }
func Unauthorized() *AppError         { return &AppError{Code: 401, Message: "Unauthorized"} }
func Internal(err error) *AppError {
    slog.Error("internal error", "err", err)
    return &AppError{Code: 500, Message: "Internal server error"}
}
func RespondError(w http.ResponseWriter, err *AppError) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(err.Code)
    json.NewEncoder(w).Encode(err)
}
```

## STP Standards Index
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.stp/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.stp/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.stp/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.stp/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML

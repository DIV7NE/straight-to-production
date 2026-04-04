# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Gin | Fast HTTP router, middleware ecosystem, minimal boilerplate |
| ORM | GORM | Auto-migrations, preloading, hooks, PostgreSQL-native |
| Database | PostgreSQL | ACID, JSON support, battle-tested |
| Auth | JWT (golang-jwt) | Stateless tokens, middleware-friendly |
| Validation | go-playground/validator | Struct tag validation, Gin-integrated |
| Config | Viper | Env files, YAML, remote config |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
cmd/server/main.go
internal/
├── handler/       # HTTP handlers (auth.go, resource.go)
├── middleware/     # auth.go, cors.go, recovery.go
├── model/         # GORM models with validation tags
├── repository/    # Database queries, scopes
├── service/       # Business logic
├── dto/           # Request/response structs
└── pkg/apperror/  # Typed application errors
migrations/        # SQL files (golang-migrate)
```

## Code Standards
### Always Do
1. Return typed errors from services; map to HTTP codes in handlers only
2. Use `ShouldBindJSON` with validation tags on every request body
3. Wrap DB calls in repository layer; never call GORM from handlers
4. Propagate `context.Context` for cancellation and tracing
5. Log structured fields: `zap.String("user_id", id)`

### Never Do
1. Never return raw error strings; use the response envelope
2. Never store plaintext passwords; bcrypt cost >= 12
3. Never trust client IDs; verify against JWT claims
4. Never auto-migrate in production; use migration files
5. Never ignore the `error` return value

## Stack Patterns
### Auth Middleware
```go
func AuthRequired(secret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        header := c.GetHeader("Authorization")
        if !strings.HasPrefix(header, "Bearer ") {
            c.AbortWithStatusJSON(401, response.Error("Missing token")); return
        }
        token, err := jwt.Parse(header[7:], func(t *jwt.Token) (interface{}, error) {
            if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok { return nil, fmt.Errorf("bad method") }
            return []byte(secret), nil
        })
        if err != nil || !token.Valid { c.AbortWithStatusJSON(401, response.Error("Invalid token")); return }
        c.Set("user_id", token.Claims.(jwt.MapClaims)["sub"]); c.Next()
    }
}
```
### Input Validation
```go
type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email,max=255"`
    Password string `json:"password" binding:"required,min=8,max=72"`
    Name     string `json:"name" binding:"required,min=1,max=100"`
}
```
### Error Handling
```go
type AppError struct { Code int; Message string }
func (e *AppError) Error() string { return e.Message }
func NotFound(msg string) *AppError { return &AppError{Code: 404, Message: msg} }
func HTTPStatus(err error) int {
    var ae *AppError; if errors.As(err, &ae) { return ae.Code }; return 500
}
```

## STP Standards Index
```
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
```

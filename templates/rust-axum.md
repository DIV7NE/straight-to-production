# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Axum | Tower-based, ergonomic extractors, async-native |
| Database | SQLx | Compile-time query verification, async, no ORM overhead |
| Runtime | Tokio | Industry-standard async runtime, mature ecosystem |
| Validation | validator crate | Derive-based struct validation, custom validators |
| Auth | jsonwebtoken + argon2 | JWT handling, Argon2id password hashing |
| Error Handling | thiserror + anyhow | Typed API errors + internal context |
| Deployment | Docker multi-stage | Static binary, minimal runtime image |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
src/
├── main.rs          # Tokio entrypoint, graceful shutdown
├── config.rs        # Env config (envy/figment)
├── db.rs            # PgPool setup
├── errors.rs        # AppError enum + IntoResponse
├── routes/          # Router composition + handlers
├── models/          # sqlx::FromRow structs
├── schemas/         # Deserialize + Validate types
├── services/        # Business logic
├── extractors/      # Auth, ValidatedJson
├── middleware.rs     # Tower layers
migrations/           # SQLx .sql files
tests/common/mod.rs   # Helpers, app setup
```

## Code Standards
### Always Do
1. `sqlx::query_as!` for compile-time checked queries — catches schema drift at build
2. Validate all input with `validator` crate before processing
3. `#[derive(thiserror::Error)]` for `AppError` — one enum for all error types
4. `State<AppState>` for shared resources — never use global statics
5. `tracing` for structured logging — never `println!` in production
6. Graceful shutdown with `tokio::signal` — let in-flight requests complete

### Never Do
1. Never `unwrap()` or `expect()` in handlers — return proper `AppError`
2. Never clone the DB pool per-request — share via `State<PgPool>`
3. Never block async runtime with sync I/O — use `spawn_blocking`
4. Never return raw DB errors to clients — map to safe messages
5. Never hardcode secrets — load from env at startup
6. Never `tokio::spawn` without error handling — panics crash silently

## Stack Patterns
### Auth Extractor
```rust
// src/extractors/auth.rs
pub struct AuthUser { pub user_id: i64 }
#[async_trait]
impl<S: Send + Sync> FromRequestParts<S> for AuthUser {
    type Rejection = AppError;
    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let token = parts.headers.get("Authorization")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .ok_or(AppError::Unauthorized)?;
        let claims = decode::<Claims>(token,
            &DecodingKey::from_secret(std::env::var("JWT_SECRET")?.as_bytes()),
            &Validation::default(),
        ).map_err(|_| AppError::Unauthorized)?;
        Ok(AuthUser { user_id: claims.claims.sub })
    }
}
```
### Input Validation
```rust
#[derive(Deserialize, Validate)]
pub struct CreatePost {
    #[validate(length(min = 1, max = 200))]
    pub title: String,
    #[validate(length(min = 1, max = 50000))]
    pub content: String,
}
// Custom extractor that deserializes JSON then runs validator
pub struct ValidatedJson<T>(pub T);
#[async_trait]
impl<S, T: DeserializeOwned + Validate> FromRequest<S> for ValidatedJson<T>
where S: Send + Sync {
    type Rejection = AppError;
    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        let Json(value) = Json::<T>::from_request(req, state)
            .await.map_err(|_| AppError::BadRequest("Invalid JSON".into()))?;
        value.validate().map_err(|e| AppError::Validation(e))?;
        Ok(ValidatedJson(value))
    }
}
```
### Error Handling
```rust
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("Unauthorized")] Unauthorized,
    #[error("Not found: {0}")] NotFound(String),
    #[error("Validation error")] Validation(validator::ValidationErrors),
    #[error(transparent)] Internal(#[from] anyhow::Error),
}
impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status, msg) = match &self {
            Self::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".into()),
            Self::NotFound(m) => (StatusCode::NOT_FOUND, m.clone()),
            Self::Validation(e) => (StatusCode::UNPROCESSABLE_ENTITY, e.to_string()),
            Self::Internal(e) => { tracing::error!("Internal: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".into()) }
        };
        (status, Json(json!({ "error": msg }))).into_response()
    }
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

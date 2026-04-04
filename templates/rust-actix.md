# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Actix-web 4 | Battle-tested performance, actor model, middleware ecosystem |
| ORM | Diesel 2 | Compile-time query safety, strong type mapping, migrations |
| Runtime | Tokio | Async runtime required by Actix, shared ecosystem |
| Validation | validator crate | Derive-based struct validation, composable rules |
| Auth | jsonwebtoken + argon2 | JWT tokens, Argon2id password storage |
| Error Handling | thiserror | Typed errors with ResponseError trait impl |
| Deployment | Docker multi-stage | Static binary, minimal runtime image |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
src/
├── main.rs          # HttpServer, workers, shutdown
├── config.rs        # Env config (envy/config)
├── db.rs            # r2d2 + Diesel pool
├── errors.rs        # AppError + ResponseError
├── schema.rs        # Diesel auto-generated
├── routes/          # configure() + handlers
├── models/          # Queryable, Insertable
├── dto/             # Deserialize + Validate
├── services/        # Business logic
├── middleware/       # JWT, logging
migrations/           # Diesel migrations
tests/common/mod.rs   # Helpers, app factory
```

## Code Standards
### Always Do
1. Diesel derive macros (`Queryable`, `Insertable`) — type-safe schema mapping
2. Validate all input with `validator` crate before touching the database
3. `ResponseError` on `AppError` enum — one conversion point for all errors
4. `web::Data<Pool>` for pool sharing — Actix clones Data per worker
5. `web::block` for Diesel calls — Diesel is sync, offload from async runtime
6. `tracing` with `tracing-actix-web` for structured request logging

### Never Do
1. Never `unwrap()` in handlers — return `AppError`, let `ResponseError` convert
2. Never call Diesel on async runtime directly — use `web::block`
3. Never share mutable state between workers without `Arc<Mutex<>>`
4. Never return raw Diesel errors to clients — map to safe messages
5. Never skip `#[derive(Insertable)]` for raw INSERT — lose compile-time safety
6. Never hardcode bind address — read from config for dev/prod flexibility

## Stack Patterns
### Auth Middleware
```rust
// src/middleware/auth.rs
use actix_web_httpauth::extractors::bearer::BearerAuth;
pub async fn jwt_validator(
    req: ServiceRequest, credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    let config = req.app_data::<web::Data<Config>>().expect("Config missing");
    match decode::<Claims>(credentials.token(),
        &DecodingKey::from_secret(config.jwt_secret.as_bytes()),
        &Validation::default(),
    ) {
        Ok(data) => {
            req.extensions_mut().insert(AuthUser { user_id: data.claims.sub });
            Ok(req)
        }
        Err(_) => Err((actix_web::error::ErrorUnauthorized("Invalid token"), req)),
    }
}
```
### Input Validation
```rust
#[derive(Deserialize, Validate)]
pub struct CreatePostDto {
    #[validate(length(min = 1, max = 200, message = "Title must be 1-200 chars"))]
    pub title: String,
    #[validate(length(min = 1, max = 50000))]
    pub content: String,
}
// In handler — validate then offload Diesel to blocking thread
pub async fn create_post(pool: web::Data<DbPool>, user: AuthUser,
                         body: web::Json<CreatePostDto>) -> Result<HttpResponse, AppError> {
    body.validate().map_err(AppError::Validation)?;
    let post = web::block(move || {
        let mut conn = pool.get()?;
        diesel::insert_into(posts::table)
            .values(&NewPost { title: &body.title, content: &body.content, author_id: user.user_id })
            .get_result::<Post>(&mut conn)
    }).await?.map_err(AppError::Database)?;
    Ok(HttpResponse::Created().json(post))
}
```
### Error Handling
```rust
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("Unauthorized")] Unauthorized,
    #[error("Not found: {0}")] NotFound(String),
    #[error("Validation error")] Validation(validator::ValidationErrors),
    #[error("Database error")] Database(#[from] diesel::result::Error),
    #[error("Internal error")] Internal(#[from] anyhow::Error),
}
impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            Self::Unauthorized => HttpResponse::Unauthorized().json(json!({"error":"Unauthorized"})),
            Self::NotFound(m) => HttpResponse::NotFound().json(json!({"error": m})),
            Self::Validation(e) => HttpResponse::UnprocessableEntity()
                .json(json!({"error":"Validation failed","details":e.to_string()})),
            _ => { tracing::error!("Server error: {:?}", self);
                HttpResponse::InternalServerError().json(json!({"error":"Internal server error"})) }
        }
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

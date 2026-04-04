# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Flask | Lightweight, explicit, no hidden magic |
| ORM | SQLAlchemy 2.0 + Flask-SQLAlchemy | Declarative models, relationship control |
| Validation | Marshmallow | Schema-based serialization and validation |
| Migrations | Flask-Migrate (Alembic) | Schema versioning via Flask CLI |
| Auth | Flask-Login + Werkzeug | Session management, password hashing |
| Testing | pytest + Flask test client | Request context fixtures, rollback |
| Deployment | Docker + Gunicorn | Production WSGI, worker processes |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
src/app/
├── __init__.py       # App factory (create_app)
├── config.py         # Config classes (Dev, Prod, Test)
├── extensions.py     # db, migrate, login_manager, ma (init once)
├── models/           # One file per model
├── schemas/          # Marshmallow schemas
├── blueprints/
│   ├── auth.py       # Login, register, logout
│   ├── api/          # Versioned API routes
│   └── [feature].py  # Feature blueprints
├── services/         # Business logic (not in routes)
├── middleware.py      # Error handlers, before_request hooks
migrations/            # Alembic versions
tests/conftest.py      # App fixture, test DB, auth helpers
```

## Code Standards
### Always Do
1. App factory pattern (`create_app`) — never create app at module level
2. Initialize extensions in `extensions.py`, bind in factory — avoids circular imports
3. Marshmallow schemas for ALL input validation — never trust `request.json`
4. Blueprints for all routes — one per feature area
5. Business logic in `services/` — handlers only parse input and return responses
6. `@login_required` on every protected route — never check auth manually

### Never Do
1. Never create app as module-level global — breaks testing and config switching
2. Never `db.session.commit()` without error handling — wrap in try/except
3. Never access `request.json` without schema validation first
4. Never use Flask's built-in server in production — always Gunicorn
5. Never store secrets in `config.py` — read from `os.environ`
6. Never use `@app.route` directly — use blueprints for all routes

## Stack Patterns
### Auth Middleware
```python
# app/middleware.py
from functools import wraps
from flask import jsonify, g
from flask_login import current_user
def api_auth_required(f):
    """Returns JSON 401 instead of redirect for API routes."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify({"error": "Authentication required"}), 401
        g.user = current_user
        return f(*args, **kwargs)
    return decorated
```
### Input Validation
```python
# app/schemas/post.py
from marshmallow import Schema, fields, validate, EXCLUDE
class PostCreateSchema(Schema):
    class Meta:
        unknown = EXCLUDE
    title = fields.String(required=True, validate=[validate.Length(min=1, max=200)])
    content = fields.String(required=True, validate=[validate.Length(min=1, max=50000)])
    is_published = fields.Boolean(load_default=False)

# In handler:
errors = schema.validate(request.json or {})
if errors:
    return jsonify({"errors": errors}), 422
data = schema.load(request.json)
```
### Error Handling
```python
# Inside create_app()
@app.errorhandler(HTTPException)
def handle_http_error(exc):
    return jsonify({"error": exc.description}), exc.code

@app.errorhandler(Exception)
def handle_unexpected_error(exc):
    logger.exception("Unhandled exception: %s", exc)
    return jsonify({"error": "An unexpected error occurred"}), 500
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

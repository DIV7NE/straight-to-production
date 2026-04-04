# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Django 5 | Batteries-included — ORM, admin, auth, forms, migrations |
| API | Django REST Framework | Serializers, viewsets, browsable API, permissions |
| Task Queue | Celery + Redis | Async jobs, scheduled tasks, retry with backoff |
| Database | PostgreSQL | Django's best-supported DB, robust migrations |
| Auth | Django built-in + DRF tokens | Session auth for web, token auth for API |
| Testing | pytest-django | Fixtures, test client, transaction rollback |
| Deployment | Docker + Gunicorn | Production WSGI, containerized with workers |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
config/
├── settings/{base,development,production}.py
├── urls.py           # Root URL config
├── celery.py         # Celery app setup
apps/
├── accounts/         # Custom User model, auth, profiles
├── core/             # Shared mixins, base models, utils
├── [feature]/
│   ├── models.py     # Django ORM models
│   ├── serializers.py# DRF serializers
│   ├── views.py      # DRF viewsets / APIViews
│   ├── urls.py       # App URL patterns
│   ├── permissions.py# Custom permission classes
│   ├── tasks.py      # Celery tasks
│   ├── admin.py      # Admin customization
│   └── tests/
docker-compose.yml    # Postgres + Redis + Celery worker
```

## Code Standards
### Always Do
1. Custom User model from day one — `AbstractUser` minimum
2. DRF serializers for ALL input validation — never trust `request.data` directly
3. Split settings into base/dev/prod — never single settings.py in production
4. `select_related()` and `prefetch_related()` on every queryset with relations
5. Permission classes for every viewset — default to `IsAuthenticated`
6. Celery tasks must be small and idempotent — they will be retried

### Never Do
1. Never use the default User model — create custom before first migration
2. Never put business logic in views — extract to model methods or services
3. Never `objects.all()` without pagination in API endpoints
4. Never ignore `select_related` — the ORM will silently N+1 your database
5. Never `CharField` without `max_length` — unbounded input is a DoS vector
6. Never call `save()` in a loop — use `bulk_create()` or `bulk_update()`

## Stack Patterns
### Auth + Permissions
```python
# apps/posts/permissions.py
from rest_framework.permissions import BasePermission, SAFE_METHODS
class IsOwnerOrReadOnly(BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.author_id == request.user.id

# apps/posts/views.py
class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]
    def get_queryset(self):
        return Post.objects.select_related("author").filter(author=self.request.user)
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```
### Input Validation
```python
# apps/posts/serializers.py
class PostSerializer(serializers.ModelSerializer):
    author = serializers.StringRelatedField(read_only=True)
    class Meta:
        model = Post
        fields = ["id", "title", "content", "author", "created_at"]
        read_only_fields = ["id", "author", "created_at"]
    def validate_title(self, value):
        value = value.strip()
        if Post.objects.filter(title__iexact=value, author=self.context["request"].user).exists():
            raise serializers.ValidationError("You already have a post with this title.")
        return value
```
### Error Handling
```python
# config/exceptions.py — set REST_FRAMEWORK.EXCEPTION_HANDLER to this
import logging
logger = logging.getLogger(__name__)
def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        return response
    logger.exception("Unhandled exception in %s", context.get("view"))
    return Response({"detail": "An unexpected error occurred."}, status=500)
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

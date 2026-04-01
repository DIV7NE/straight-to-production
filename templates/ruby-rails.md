# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Ruby on Rails 7 | Convention-over-configuration, rapid development |
| ORM | ActiveRecord | Migrations, associations, validations built-in |
| Database | PostgreSQL | ACID, JSON columns, Rails-native |
| Auth | Devise + devise-jwt | Battle-tested user management, JWT for APIs |
| Validation | ActiveModel Validations | Model-level constraints, custom validators |
| Background | Sidekiq (Redis) | Threaded jobs, retries, scheduled tasks |
| Serialization | Blueprinter | Fast JSON serialization, conditional fields |
## Key Decisions
{{DECISIONS}}
## Project Structure
```
app/ — controllers/api/v1/, models/, services/, serializers/,
       policies/, validators/, jobs/
config/ — routes.rb, initializers/{devise,cors}.rb
db/migrate/, spec/{models,requests,services}/
```
## Code Standards
### Always Do
1. Service objects for business logic; controllers = auth + params + response only
2. Scopes: `scope :active, -> { where(active: true) }`; Pundit `authorize` in every action
3. `strong_parameters` with explicit `permit`; DB constraints alongside model validations
4. Blueprinter serializers for all responses; `frozen_string_literal: true` everywhere
5. `includes()` or `eager_load()` on every association access

### Never Do
1. Never put logic in models or controllers; use services
2. Never use `update_attribute` (skips validations); use `update!`
3. Never N+1 query; never store secrets in config files
4. Never rescue `StandardError` broadly; rescue specific classes
5. Never expose internal IDs when UUIDs/slugs are appropriate

## Stack Patterns
### Auth (Devise + JWT)
```ruby
class ApplicationController < ActionController::API
  before_action :authenticate_user!
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  private
  def not_found = render(json: { error: "Not found" }, status: :not_found)
  def forbidden = render(json: { error: "Forbidden" }, status: :forbidden)
end
class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]
  def create
    user = User.find_by!(email: params[:email])
    if user.valid_password?(params[:password])
      token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      render json: { user: UserSerializer.render(user), token: token }
    else render json: { error: "Invalid credentials" }, status: :unauthorized end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Invalid credentials" }, status: :unauthorized
  end
end
```
### Input Validation
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 255 }
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :password, length: { minimum: 8, maximum: 72 }, if: :password_required?
end
```
### Error Handling
```ruby
rescue_from ActiveRecord::RecordInvalid do |e|
  render json: { error: "Validation failed", details: e.record.errors.messages }, status: :unprocessable_entity
end
rescue_from ActionController::ParameterMissing do |e|
  render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
end
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

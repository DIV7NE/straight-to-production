# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | ASP.NET Core 8 (Minimal APIs) | High-performance, AOT-ready, enterprise-grade |
| ORM | Entity Framework Core | Migrations, LINQ queries, change tracking |
| Database | PostgreSQL (Npgsql) | Open-source, JSON columns, full-text search |
| Auth | ASP.NET Identity + JWT Bearer | Built-in user management, role-based access |
| Validation | FluentValidation | Expressive rules, testable, pipeline-integrated |
| Logging | Serilog | Structured logging, sinks for Seq/Datadog |

## Key Decisions
{{DECISIONS}}

## Project Structure
```
src/Api/ — Program.cs, Endpoints/, Middleware/, Filters/
src/Application/ — Services/, DTOs/, Validators/
src/Domain/ — Entities/, Interfaces/
src/Infrastructure/ — Data/AppDbContext.cs, Repositories/
```

## Code Standards
### Always Do
1. Minimal APIs with endpoint groups; one file per resource
2. Return `Results.Problem()` with RFC 7807 ProblemDetails for errors
3. `CancellationToken` on every async method; `.RequireAuthorization()` on protected endpoints
4. Map entities to DTOs; never expose domain objects to clients
5. `IOptions<T>` for config with `ValidateOnStart()`

### Never Do
1. Never inject `DbContext` into endpoints directly; use service layer
2. Never use `Task.Result`/`.Wait()`; always `await`
3. Never store secrets in `appsettings.json`; use env vars or Key Vault
4. Never return raw exceptions; log internally, respond with ProblemDetails
5. Never catch `Exception` silently; always log with context

## Stack Patterns
### Auth (JWT Bearer)
```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opts => {
        opts.TokenValidationParameters = new TokenValidationParameters {
            ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });
app.MapGet("/api/resources", async (IService svc, CancellationToken ct) =>
    Results.Ok(await svc.GetAllAsync(ct))).RequireAuthorization();
```
### Input Validation
```csharp
public class CreateUserValidator : AbstractValidator<CreateUserRequest> {
    public CreateUserValidator() {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(255);
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8).MaximumLength(72);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
    }
}
```
### Error Handling
```csharp
public class ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> log) {
    public async Task InvokeAsync(HttpContext ctx) {
        try { await next(ctx); }
        catch (NotFoundException ex) {
            log.LogWarning(ex, "Not found: {Path}", ctx.Request.Path);
            ctx.Response.StatusCode = 404;
            await ctx.Response.WriteAsJsonAsync(new ProblemDetails { Status = 404, Detail = ex.Message });
        } catch (Exception ex) {
            log.LogError(ex, "Unhandled: {Method} {Path}", ctx.Request.Method, ctx.Request.Path);
            ctx.Response.StatusCode = 500;
            await ctx.Response.WriteAsJsonAsync(new ProblemDetails { Status = 500, Title = "Server Error" });
        }
    }
}
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

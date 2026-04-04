# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Blazor (.NET 8, Interactive Server) | C# everywhere, real-time UI via SignalR |
| ORM | Entity Framework Core | Migrations, LINQ, change tracking |
| Database | PostgreSQL (Npgsql) | Open-source, JSON columns, robust |
| Auth | ASP.NET Identity + Blazor Auth | AuthorizeView, cascading auth params |
| Validation | DataAnnotations + FluentValidation | EditForm validation, custom rules |
| UI | MudBlazor | Material Design, accessible components |
## Key Decisions
{{DECISIONS}}
## Project Structure
```
src/App/ — Program.cs, Components/{Layout,Pages,Shared}/, Services/, wwwroot/
Domain/ — Entities/, Interfaces/
Infrastructure/ — Data/AppDbContext.cs, Repositories/
```

## Code Standards
### Always Do
1. Set `@rendermode InteractiveServer` per-page; `EditForm` + `DataAnnotationsValidator` for input
2. Protect pages with `@attribute [Authorize]`; `<AuthorizeView>` for conditional UI
3. Use `IDbContextFactory<T>` for scoped DbContext in Blazor Server
4. Dispose subscriptions in `IDisposable.Dispose()`
5. Show loading spinners during async fetches

### Never Do
1. Never inject scoped `DbContext` directly; circuits outlive scopes
2. Never call `StateHasChanged()` from background threads; use `InvokeAsync()`
3. Never skip `@key` on `@foreach` with stateful components
4. Never put business logic in `.razor` files; extract to services
5. Never expose EF entities to components; map to view models

## Stack Patterns
### Auth (Blazor Identity)
```csharp
@page "/login"
@inject SignInManager<ApplicationUser> SignInManager
@inject NavigationManager Nav
<EditForm Model="model" OnValidSubmit="HandleLogin" FormName="login">
    <DataAnnotationsValidator />
    <MudTextField @bind-Value="model.Email" Label="Email" Required="true" />
    <MudTextField @bind-Value="model.Password" Label="Password" InputType="InputType.Password" />
    <MudButton ButtonType="ButtonType.Submit" Disabled="@loading">Sign In</MudButton>
</EditForm>
@code {
    LoginModel model = new(); bool loading;
    async Task HandleLogin() {
        loading = true;
        var r = await SignInManager.PasswordSignInAsync(model.Email, model.Password, false, true);
        if (r.Succeeded) Nav.NavigateTo("/dashboard"); else model.Error = "Invalid credentials.";
        loading = false;
    }
}
```
### Input Validation
```csharp
public class LoginModel {
    [Required, EmailAddress, MaxLength(255)] public string Email { get; set; } = "";
    [Required, MinLength(8), MaxLength(72)]  public string Password { get; set; } = "";
    public string? Error { get; set; }
}
```
### Error Handling
```csharp
@inherits ErrorBoundary
@inject ILogger<AppError> Logger
@if (CurrentException is not null) {
    <MudAlert Severity="Severity.Error">Something went wrong.</MudAlert>
    <MudButton OnClick="Recover">Retry</MudButton>
} else { @ChildContent }
@code {
    protected override Task OnErrorAsync(Exception ex) {
        Logger.LogError(ex, "Component error: {Source}", ex.TargetSite?.DeclaringType?.Name);
        return Task.CompletedTask;
    }
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

# {{PROJECT_NAME}}
## What We're Building
{{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Spring Boot 3 | Convention-over-config, massive ecosystem |
| ORM | Spring Data JPA (Hibernate) | Repository pattern, query derivation, auditing |
| Database | PostgreSQL | ACID, JSON support, mature tooling |
| Auth | Spring Security + JWT | Filter chain, method security, OAuth2 |
| Validation | Jakarta Bean Validation | Annotation-driven, custom constraints |
| API Docs | SpringDoc OpenAPI | Auto-generated Swagger UI |
## Key Decisions
{{DECISIONS}}
## Project Structure
```
src/main/java/com/example/app/
  config/, controller/, dto/{request,response}/, entity/,
  exception/, repository/, service/, security/
src/main/resources/ — application.yml, db/migration/
```
## Code Standards
### Always Do
1. Constructor injection via `@RequiredArgsConstructor`; `@Valid` on all `@RequestBody`
2. `@ControllerAdvice` for global exceptions; return RFC 7807 ProblemDetail
3. Flyway migrations; never `ddl-auto` in production
4. `@Transactional(readOnly = true)` on reads; `record` types for DTOs
5. `@PreAuthorize` or endpoint security for role-based access

### Never Do
1. Never expose JPA entities in responses; map to DTOs
2. Never use field injection (`@Autowired` on fields)
3. Never hardcode secrets in `application.yml`
4. Never use `Optional.get()` without check; prefer `orElseThrow()`
5. Never lazy-load outside a transaction; use `@EntityGraph`
## Stack Patterns
### Auth (JWT Filter)
```java
@Component @RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtTokenProvider tokenProvider;
    private final UserDetailsService userDetailsService;
    @Override protected void doFilterInternal(HttpServletRequest req,
            HttpServletResponse res, FilterChain chain) throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7), user = tokenProvider.extractUsername(token);
            if (user != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                var details = userDetailsService.loadUserByUsername(user);
                if (tokenProvider.isValid(token, details))
                    SecurityContextHolder.getContext().setAuthentication(
                        new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities()));
            }
        }
        chain.doFilter(req, res);
    }
}
```
### Input Validation
```java
public record CreateUserRequest(
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank @Size(min = 8, max = 72) String password,
    @NotBlank @Size(max = 100) String name) {}
```
### Error Handling
```java
@RestControllerAdvice @Slf4j
public class GlobalExceptionHandler {
    @ExceptionHandler(NotFoundException.class)
    ProblemDetail notFound(NotFoundException ex) { log.warn("Not found: {}", ex.getMessage());
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage()); }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail validation(MethodArgumentNotValidException ex) {
        var pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        pd.setProperty("errors", ex.getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField, FieldError::getDefaultMessage, (a,b)->a)));
        return pd; }
    @ExceptionHandler(Exception.class)
    ProblemDetail unexpected(Exception ex) {
        log.error("Unhandled", ex);
        return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error."); }
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

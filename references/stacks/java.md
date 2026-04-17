# Java Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "java"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `pom.xml` (Maven), `build.gradle` or `build.gradle.kts` (Gradle)
- `src/main/java/` directory structure
- `*.java` files with `package` declarations
- (secondary) `application.properties`, `application.yml` (Spring Boot), `.mvn/wrapper/`, `gradlew`

## Commands
- **test:** `mvn test` (Maven) or `./gradlew test` (Gradle)
- **build:** `mvn package -DskipTests` or `./gradlew build -x test`
- **lint:** `mvn checkstyle:check` or `./gradlew checkstyleMain`
- **type-check:** `—` (compilation is the type check: `mvn compile` or `./gradlew compileJava`)
- **format:** `./gradlew spotlessApply` (if Spotless configured) or `mvn spotless:apply`

## stack.json fields
```json
{
  "primary": "java",
  "ui": false,
  "test_cmd": "./gradlew test",
  "build_cmd": "./gradlew build -x test",
  "lint_cmd": "./gradlew checkstyleMain",
  "type_cmd": "./gradlew compileJava"
}
```

## Idiomatic patterns (what good code looks like)
- Spring beans are constructor-injected, not field-injected — enables immutability and testability without a Spring context
- Entities and DTOs are separate classes — never expose JPA entities directly in API responses
- Repository interfaces extend `JpaRepository` or `CrudRepository` — custom queries use `@Query` with named parameters
- Checked exceptions are used for recoverable conditions; unchecked (`RuntimeException`) for programmer errors
- Records (Java 16+) for immutable data transfer objects — no boilerplate getters/setters needed

## Common gotchas
- `@Transactional` on `private` methods is silently ignored by Spring's proxy — must be `public`
- Lazy-loaded JPA relations accessed outside a transaction throw `LazyInitializationException` — use `@Transactional` on service methods or fetch eagerly
- `Optional.get()` without `isPresent()` check is a hidden `NoSuchElementException` — use `orElseThrow()` with a meaningful message
- SpotBugs/FindBugs flags null-return paths that the compiler accepts — run `./gradlew spotbugsMain` in CI
- Default `HashMap` is not thread-safe — use `ConcurrentHashMap` in shared state

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Use constructor injection for all Spring beans. Never use `@Autowired` on fields."
- "Never expose JPA entities in API responses. Map to DTOs at the service boundary."

## Anti-slop patterns for this stack
- `@Autowired` on fields — slop (use constructor injection)
- `Optional.get()` without guard — slop (use `orElseThrow`)
- `// TODO: implement` — slop
- `catch (Exception e) { e.printStackTrace(); }` — slop (log properly and rethrow or handle)

## Companion plugins / MCP servers
- **Context7** — pull live docs for Spring Boot, Hibernate, Maven, Gradle
- **Tavily** — research CVEs in Spring/Jackson/log4j, JVM tuning, and deployment patterns

## References (external)
- Google Java Style Guide: https://google.github.io/styleguide/javaguide.html
- Spring Boot reference: https://docs.spring.io/spring-boot/docs/current/reference/html/

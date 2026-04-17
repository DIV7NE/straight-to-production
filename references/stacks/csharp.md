# C# Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "csharp"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

> Note: Unity C# projects belong in `game.md`, not here. This file covers ASP.NET Core, console apps, class libraries, and Azure Functions.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `*.csproj`, `*.sln` files (without `UnityEngine` references)
- `Program.cs`, `Startup.cs`, `appsettings.json`
- `global.json`, `NuGet.config`, `.editorconfig` with `[*.cs]` sections
- (secondary) `Dockerfile` with `FROM mcr.microsoft.com/dotnet`, `azure-pipelines.yml`

## Commands
- **test:** `dotnet test`
- **build:** `dotnet build`
- **lint:** `dotnet format --verify-no-changes` (or run Roslyn analyzers via build)
- **type-check:** `—` (build is the type check: `dotnet build`)
- **format:** `dotnet format`

## stack.json fields
```json
{
  "primary": "csharp",
  "ui": false,
  "test_cmd": "dotnet test",
  "build_cmd": "dotnet build",
  "lint_cmd": "dotnet format --verify-no-changes",
  "type_cmd": "dotnet build"
}
```

## Idiomatic patterns (what good code looks like)
- Dependency injection via `IServiceCollection` — no service locator pattern or `new` for dependencies
- `async`/`await` all the way down — never `.Result` or `.Wait()` on tasks in async contexts
- `record` types for immutable DTOs and value objects (C# 9+) — no manual `Equals`/`GetHashCode` override needed
- `IOptions<T>` for configuration binding — strongly-typed config objects validated at startup
- `ILogger<T>` injected for all logging — never `Console.WriteLine` in library or service code

## Common gotchas
- `.Result` or `.Wait()` on a `Task` in an async context deadlocks on ASP.NET's synchronization context — always `await`
- Entity Framework `DbContext` is not thread-safe — never share a `DbContext` across threads or requests
- `using var` in a `switch` expression goes out of scope before the expression result is used — be explicit about lifetime
- Nullable reference types (`#nullable enable`) require annotation discipline — enable project-wide from the start, not mid-flight
- `IEnumerable<T>` returned from a method that queries a DB defers execution — callers who store it materialize the query multiple times

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Never block async code with `.Result` or `.Wait()`. Propagate `async`/`await` through the entire call chain."
- "Enable `#nullable enable` at the project level. All reference types must be explicitly nullable or non-nullable."

## Anti-slop patterns for this stack
- `.Result` or `.Wait()` on tasks — slop (deadlock risk; use `await`)
- `Console.WriteLine` in service/library code — slop (use `ILogger`)
- `// TODO: implement` — slop
- `catch (Exception) { }` (empty catch) — slop

## Companion plugins / MCP servers
- **Context7** — pull live docs for ASP.NET Core, Entity Framework Core, and Azure SDKs
- **Tavily** — research NuGet package advisories, .NET runtime behavior, and deployment patterns

## References (external)
- Microsoft C# Coding Conventions: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions
- .NET API design guidelines: https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/

# How to Add a Stack Template

STP uses one CLAUDE.md template per stack. Adding a new stack means creating one markdown file.

## Quick Start

1. Copy any existing template (e.g., `python-fastapi.md`) as your starting point
2. Rename to `[language]-[framework].md`
3. Replace all stack-specific content
4. Drop it in the `templates/` directory
5. Submit a PR

That's it. No JSON configs, no hook modifications, no plugin code changes.

## Template Structure

Every template must contain these sections in this order:

```markdown
# {{PROJECT_NAME}}

## What We're Building
{{PROJECT_DESCRIPTION}}

## Architecture
- **Framework**: [Name] ([brief what-it-is for non-experts])
- **Database**: [Name] ([brief what-it-is])
- **Auth**: [Name] ([brief what-it-is])
- **Styling**: [Name] ([brief what-it-is])
- **Deployment**: [Name]

## Key Decisions
{{DECISIONS}}

## Project Structure
[Recommended directory layout for this stack]

## Code Standards

### Always Do
[5-10 stack-specific rules, e.g., "Validate ALL inputs with Pydantic at API boundaries"]

### Never Do
[5-10 stack-specific anti-patterns, e.g., "Never use raw SQL string concatenation"]

## Stack Patterns
[2-3 key code examples showing THE RIGHT WAY to do common things in this stack.
Examples: auth middleware, input validation, error handling, database queries.
These should be the patterns a non-expert would get wrong without guidance.]

## Project Conventions (living section — grows during development)
[This section starts empty. STP adds rules here as the project develops:
- /stp:build adds patterns discovered during feature development
- /stp:debug adds lessons learned from bug fixes
- /stp:onboard-existing detects conventions from existing code
- /stp:review adds rules from Critic findings

Format for each convention:
- **[Rule name]**: [What to do / what not to do]
  - Why: [Brief reason — a bug, a decision, a pattern that works]
  - Applies when: [When to think of this rule]
  - Added: [DATE] via [command that discovered it]
]

## STP Standards Index
[Include the full content of _standards-index.md here verbatim.
This is the universal standards section — same for every stack.]
```

## Placeholders

Templates use these placeholders that `/stp:new` fills in:

- `{{PROJECT_NAME}}` — The project name
- `{{PROJECT_DESCRIPTION}}` — What the user is building
- `{{DECISIONS}}` — Architecture decisions from the proposal step

## Guidelines

### Keep It Opinionated
Pick specific tools and explain why. "Use SQLAlchemy for the ORM" not "choose an ORM." The user isn't an expert — they need a decision, not options.

### Code Examples Should Show THE Right Way
Include 2-3 code examples for patterns the user would get wrong:
- How to validate input in this stack
- How to handle errors in this stack
- How to protect routes/endpoints in this stack

These examples teach the pattern. The user and Opus will adapt them to the project.

### Stack-Specific "Always Do / Never Do"
These are the rules that differ by stack. Universal rules (like "never hardcode secrets") are in the standards index. Your template's rules should be things unique to this stack:
- Python: "Always use type hints. Always use async for I/O-bound operations."
- Rust: "Always handle Result types explicitly. Never use unwrap() in production code."
- C#: "Always use dependency injection. Never use static classes for services."

### Project Structure Should Be Conventional
Use the stack's standard conventions. A Django template should show the Django project layout. A Spring Boot template should show the Maven/Gradle structure. Don't invent custom layouts.

## Hook Auto-Detection

The type-check hooks detect stacks by looking at project files:

| File | Detected Stack | Type Check Command |
|------|---------------|-------------------|
| `tsconfig.json` | TypeScript | `npx tsc --noEmit` |
| `pyproject.toml` / `setup.py` | Python | `mypy .` |
| `Cargo.toml` | Rust | `cargo check` |
| `go.mod` | Go | `go vet ./...` |
| `*.csproj` / `*.sln` | C# | `dotnet build --no-restore` |
| `Gemfile` | Ruby | `bundle exec ruby -c` |
| `composer.json` | PHP | `php -l` |
| `pom.xml` / `build.gradle` | Java | `mvn compile` / `gradle compileJava` |

If your stack's config file isn't in this list, the hooks won't run type checking automatically. You have two options:
1. Submit a PR adding detection to `stop-verify.sh` and `post-edit-check.sh`
2. Document in your template that the user should add a project-level hook

## Testing Your Template

1. Create a test project: `/stp:new [description matching your stack]`
2. Verify Opus selects your template
3. Check the generated CLAUDE.md includes your patterns + the universal standards
4. Build a small feature and verify hooks run the right type checker
5. Run `/stp:evaluate` and verify the Critic can assess the project

## Examples of Good Templates

Look at these existing templates for reference:
- `python-fastapi.md` — Clean API stack with Pydantic validation patterns
- `nextjs-supabase.md` — Full SaaS stack with auth middleware patterns
- `rust-axum.md` — Systems-level with Result handling patterns

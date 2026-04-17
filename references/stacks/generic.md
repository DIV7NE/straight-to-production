# Generic Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "generic"` — or when no more specific stack matches. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- No known stack marker files found (generic is the fallback — matched when all other stacks fail to detect)
- Explicitly set via `"primary": "generic"` in `.stp/state/stack.json`
- (secondary) Projects that mix multiple languages at the top level without a dominant primary language

## Commands
- **test:** `—` (ask user: "What command runs your tests?")
- **build:** `—` (ask user: "What command builds your project?")
- **lint:** `—` (ask user: "What linter or static analysis tool does your project use?")
- **type-check:** `—` (ask user: "Does your project have a type-checking step?")
- **format:** `—` (ask user: "What formatter does your project use, if any?")

## stack.json fields
```json
{
  "primary": "generic",
  "ui": false,
  "test_cmd": "",
  "build_cmd": "",
  "lint_cmd": "",
  "type_cmd": ""
}
```

> These fields are intentionally blank. STP will prompt the user to fill them in before running any build or test step. Commands discovered during onboarding are written back to this file.

## Idiomatic patterns (what good code looks like)
- Code is organized by responsibility, not by file type — feature folders over type-based folders (`users/` not `controllers/`)
- Every function or procedure has a single responsibility and a name that describes what it does
- All external I/O (network, disk, env vars) is isolated at the edges of the system — core logic has no side effects
- Tests exist and are runnable with a single command — if there is no test command, the first task is to establish one
- Version control is used, commits are atomic and descriptively named

## Common gotchas
- No defined build or test commands means STP cannot run its verification stack — establish these commands before any feature work begins
- Mixed-language projects may require separate lint/type-check commands per language subdirectory — document each in `stack.json` extended fields
- "It works on my machine" without a reproducible build step means the project is not production-ready — Dockerfile or lockfile is the minimum bar
- Global mutable state shared across modules is the root cause of most hard-to-reproduce bugs regardless of language
- Missing error handling at I/O boundaries (file not found, network timeout) is the most common source of production crashes

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Ask the user to specify test, build, and lint commands before proceeding with any implementation. Do not assume or invent commands for an unknown stack."
- "Without a runnable test command, the 6-layer verification stack cannot proceed past layer 1. Establish test infrastructure as the first task."

## Anti-slop patterns for this stack
- Assuming test/build commands without confirming with the user — slop (wrong commands waste cycles)
- `# TODO: add tests` — slop (no code ships without tests)
- `// hardcoded for now` — slop (hardcoded values are a production bug deferred)
- Inventing a framework or tool name not confirmed to exist in this project — slop (hallucinated tooling)

## Companion plugins / MCP servers
- **Context7** — once the user identifies their stack, use Context7 to pull correct framework docs
- **Tavily** — research the specific language/framework once identified to fill in correct commands

## References (external)
- 12-Factor App (stack-agnostic production principles): https://12factor.net/
- Semantic Versioning: https://semver.org/

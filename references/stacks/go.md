# Go Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "go"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `go.mod`, `go.sum`
- `*.go` files with `package main` or `package <name>` declarations
- `cmd/`, `internal/`, `pkg/` directory structure (idiomatic Go layout)
- (secondary) `Makefile` with `go build`/`go test` targets, `Dockerfile` with `FROM golang:`

## Commands
- **test:** `go test ./...`
- **build:** `go build ./...`
- **lint:** `golangci-lint run` (or `go vet ./...` if golangci-lint not installed)
- **type-check:** `—` (compilation is the type check: `go build ./...`)
- **format:** `gofmt -w .` (or `goimports -w .`)

## stack.json fields
```json
{
  "primary": "go",
  "ui": false,
  "test_cmd": "go test ./...",
  "build_cmd": "go build ./...",
  "lint_cmd": "golangci-lint run",
  "type_cmd": "go build ./..."
}
```

## Idiomatic patterns (what good code looks like)
- Errors are values — return `(T, error)` from every fallible function; check every error at the call site
- Table-driven tests with `t.Run` subtests for all non-trivial functions — covers multiple inputs in one test function
- Interfaces are small and defined at the consumer (not the producer) — `io.Reader`, `io.Writer` patterns
- `context.Context` is the first parameter of every function that does I/O, DB, or HTTP work
- Goroutines are always paired with a clear ownership story — who waits for them, who cancels them

## Common gotchas
- Goroutine leaks: launching a goroutine without a way to stop it leaks for the process lifetime — use `context.Done()` for cancellation
- Loop variable capture: `for _, v := range items { go func() { use(v) }() }` captures the loop var, not a copy — add `v := v` inside the loop
- `nil` maps and slices are readable but `nil` maps panic on assignment — always initialize maps: `make(map[K]V)`
- `panic` in a goroutine that lacks a `recover` crashes the entire program — server handlers must have top-level recover middleware
- `sync.Mutex` must not be copied after first use — pass structs containing mutexes by pointer

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Errors are values — handle every returned error explicitly. Never use `_` to discard an error from a fallible call."
- "Avoid `panic` in library code. Use `panic` only for programmer errors (impossible states), never for runtime input errors."

## Anti-slop patterns for this stack
- `_ = err` (discarded error) — slop (always handle the error)
- `panic(err)` in non-main, non-test code — slop (return the error)
- `// TODO: handle error` — slop
- Missing `context.Context` parameter on I/O functions — slop (always thread context)

## Companion plugins / MCP servers
- **Context7** — pull live docs for the Go standard library, gin, echo, pgx, sqlc
- **Tavily** — research Go module vulnerabilities, concurrency patterns, and deployment tooling

## References (external)
- Effective Go: https://go.dev/doc/effective_go
- Google Go Style Guide: https://google.github.io/styleguide/go/

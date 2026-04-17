# Rust Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "rust"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `Cargo.toml`, `Cargo.lock`
- `src/main.rs`, `src/lib.rs`
- `.cargo/config.toml`, `rust-toolchain.toml`
- (secondary) `build.rs`, `benches/`, `examples/` directories

## Commands
- **test:** `cargo test`
- **build:** `cargo build --release`
- **lint:** `cargo clippy -- -D warnings`
- **type-check:** `cargo check` (fast; no codegen)
- **format:** `cargo fmt`

## stack.json fields
```json
{
  "primary": "rust",
  "ui": false,
  "test_cmd": "cargo test",
  "build_cmd": "cargo build --release",
  "lint_cmd": "cargo clippy -- -D warnings",
  "type_cmd": "cargo check"
}
```

## Idiomatic patterns (what good code looks like)
- Errors propagate via `Result<T, E>` with `?` — panics are reserved for programmer errors, not runtime failures
- Custom error types implement `std::error::Error`; use `thiserror` for library errors, `anyhow` for application errors
- Owned data in structs; borrowed data in function parameters — minimize cloning
- `#[derive(Debug, Clone)]` on all data types by default; add `PartialEq` for testability
- Integration tests live in `tests/`, unit tests in `#[cfg(test)]` modules in the same file

## Common gotchas
- `unwrap()` and `expect()` in non-test code are panics waiting to happen — clippy will flag them; heed the warning
- Lifetimes in async code with `tokio` require `'static` bounds in many executor contexts — use `Arc` when ownership is unclear
- `clone()` in hot loops compiles fine but causes allocations — profile with `cargo flamegraph` before optimizing
- Cargo feature flags can silently disable required dependencies — always test `--no-default-features` in CI
- `std::sync::Mutex` deadlocks if a guard is held across an `.await` point — use `tokio::sync::Mutex` in async code

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Prefer `Result` over panics. Never use `unwrap()` or `expect()` in production code paths without an explicit justification comment explaining why the panic is impossible."
- "Run `cargo clippy -- -D warnings` before declaring any implementation done. Zero warnings is the baseline."

## Anti-slop patterns for this stack
- `.unwrap()` without comment in non-test code — slop (use `?` or handle the error)
- `// TODO: handle error` — slop (handle it now)
- `unsafe { }` without a `// SAFETY:` comment explaining the invariant — slop
- `clone()` inside a loop without a profiling note — slop (document why it's acceptable)

## Companion plugins / MCP servers
- **Context7** — pull live docs for tokio, serde, axum, sqlx, and the standard library
- **Tavily** — research crate alternatives, security advisories, and WASM target constraints

## References (external)
- Rust API Guidelines: https://rust-lang.github.io/api-guidelines/
- The Rust Programming Language book: https://doc.rust-lang.org/book/

# Bundled tree-sitter grammars

This directory ships prebuilt WebAssembly (WASM) parsers for the languages STP supports. They're used by `hooks/scripts/code-graph/build.js` to extract imports / exports / symbols into `.stp/state/code-graph.json` — STP's Aider-style repo map.

**Why bundled:** STP must be runtime-free and offline-capable. No downloads, no unpkg, no grammar compilation at install time. Every grammar here is committed to the plugin repo so `/plugin install stp@stp` gives you a working code-graph out of the box.

## Grammars included

| File | Language | Covers stacks |
|------|----------|---------------|
| `tree-sitter-typescript.wasm` | TypeScript | web, node |
| `tree-sitter-tsx.wasm`        | TSX (React)| web |
| `tree-sitter-javascript.wasm` | JavaScript (ES6 + CommonJS `require()`) | web, node |
| `tree-sitter-python.wasm`     | Python     | python, data-ml |
| `tree-sitter-rust.wasm`       | Rust       | rust, embedded |
| `tree-sitter-go.wasm`         | Go         | go |
| `tree-sitter-java.wasm`       | Java       | java, mod |
| `tree-sitter-c_sharp.wasm`    | C#         | csharp, game, mod |
| `tree-sitter-cpp.wasm`        | C++        | cpp, cheat-pentest, embedded, game, mod |
| `tree-sitter-c.wasm`          | C          | cpp, cheat-pentest, embedded |

Stacks not in this table (`generic`, plus niche languages) fall through to Glob/Grep — `stp-explorer` handles that gracefully.

## Source + license

All grammars were extracted from **[tree-sitter-wasms](https://github.com/Gregoor/tree-sitter-wasms)** v0.1.13 (Unlicense / public domain). The underlying parsers are each maintained by the tree-sitter project or the language's community, universally permissively licensed (MIT / Apache-2.0 / public domain).

Specifically:
- `tree-sitter-typescript` / `tree-sitter-tsx` — [MIT](https://github.com/tree-sitter/tree-sitter-typescript)
- `tree-sitter-javascript` — [MIT](https://github.com/tree-sitter/tree-sitter-javascript)
- `tree-sitter-python` — [MIT](https://github.com/tree-sitter/tree-sitter-python)
- `tree-sitter-rust` — [MIT](https://github.com/tree-sitter/tree-sitter-rust)
- `tree-sitter-go` — [MIT](https://github.com/tree-sitter/tree-sitter-go)
- `tree-sitter-java` — [MIT](https://github.com/tree-sitter/tree-sitter-java)
- `tree-sitter-c-sharp` — [MIT](https://github.com/tree-sitter/tree-sitter-c-sharp)
- `tree-sitter-cpp` — [MIT](https://github.com/tree-sitter/tree-sitter-cpp)
- `tree-sitter-c` — [MIT](https://github.com/tree-sitter/tree-sitter-c)

STP itself is MIT. Using these grammars inside STP does not impose any license obligation on your project beyond attribution (covered by this file + the LICENSE headers inside each grammar repo).

## Runtime

The web-tree-sitter runtime that loads these grammars ships at [`../vendor/web-tree-sitter/`](../vendor/web-tree-sitter/) — also MIT. Version pinned to **0.20.8** because the `tree-sitter-wasms` package bundles ABI-13 WASMs that require the 0.20.x runtime.

## Upgrading grammars

When a language grammar releases a significant improvement (new syntax support, query fixes):

1. Bump `tree-sitter-wasms` version in a temp npm project:
   ```bash
   mkdir /tmp/fetch && cd /tmp/fetch
   npm init -y && npm install tree-sitter-wasms@latest web-tree-sitter@<ABI-compatible>
   ```
2. Copy the updated `.wasm` files into this directory.
3. If the `tree-sitter-wasms` release bumps the ABI, also update `vendor/web-tree-sitter/`.
4. Smoke test: `CLAUDE_PLUGIN_ROOT=$(pwd) node hooks/scripts/code-graph/build.js` in a project of each affected stack.
5. Commit the updated WASMs with a clear message.

Do NOT lazy-download grammars at runtime. The "free to use offline" contract is the whole point.

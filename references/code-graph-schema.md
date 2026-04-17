# Code-Graph Schema (`.stp/state/code-graph.json`)

STP v1.1 ships an Aider-style repo map at `.stp/state/code-graph.json`, rebuilt incrementally on SessionStart (backgrounded via `hooks/scripts/code-graph-update.sh`). The graph is what the `stp-explorer` sub-agent (and skills, and hooks) read BEFORE falling back to Glob/Grep.

**Zero paid APIs. Zero network at runtime.** All tree-sitter grammars ship in `grammars/*.wasm` inside the plugin. All parsing is local, deterministic, and free.

## Top-level shape

```json
{
  "version": 1,
  "generated_at": "2026-04-17T...",
  "root": "/absolute/path/to/project",
  "stats": { "files": 142, "symbols": 1203, "edges": 891 },
  "files": { ... },
  "references": { ... }
}
```

## `files` — per-file entries

```json
{
  "src/api/invoices.ts": {
    "lang": "typescript",
    "size_bytes": 4200,
    "sha1": "abc123...",
    "centrality": 0.87,
    "imports": [
      { "from": "src/lib/db.ts", "symbols": ["prisma"] },
      { "from": "./types",       "symbols": ["Invoice"] }
    ],
    "exports": [
      { "name": "createInvoice", "kind": "function", "line": 47 }
    ],
    "symbols": [
      { "name": "InvoiceSchema", "kind": "const",    "line": 12 },
      { "name": "calcTax",       "kind": "function", "line": 88 }
    ]
  }
}
```

Field semantics:

- **`lang`** — one of `typescript`, `tsx`, `javascript`, `python`, `rust`, `go`, `java`, `c_sharp`, `cpp`, `c`. Matches the bundled grammar.
- **`size_bytes`** — file size, for prioritizing what to read if you need raw source.
- **`sha1`** — content hash. Used by the incremental rebuilder to skip unchanged files.
- **`centrality`** — 0–1 float, degree-based. Files with many incoming+outgoing edges get high centrality (they're "hubs"). Sort descending for most-important files.
- **`imports`** — what this file depends on. `from` is the import source (may be relative path or external package name). `symbols` are the named imports (empty array for bare or default imports).
- **`exports`** — what this file publishes. `kind` is `function | class | variable | interface | type | symbol`.
- **`symbols`** — every top-level (and nested) definition. `kind` is lang-specific: `function | class | method | struct | enum | trait | interface | const | static | variable | namespace | module`.

Optional field: **`parse_error`** — if tree-sitter couldn't query the file (rare; usually malformed syntax). The file still appears in the graph, but with empty arrays.

## `references` — reverse index

```json
{
  "prisma": [
    { "file": "src/api/invoices.ts", "line": 52 },
    { "file": "src/api/orders.ts",   "line": 14 }
  ],
  "createInvoice": [
    { "file": "src/api/invoices.ts", "line": 47, "exported": true },
    { "file": "tests/invoices.test.ts", "line": 8 }
  ]
}
```

Built from all `symbols` + `exports` across all files. Exported symbols get `exported: true`. **Use this for "where is X used" queries instead of grepping the whole repo.**

## `.meta` sidecar (`.stp/state/code-graph.json.meta`)

```json
{
  "version": 1,
  "files": {
    "src/api/invoices.ts": { "sha1": "abc123", "mtime": 1713... }
  },
  "truncated_files": ["src/legacy/mega-util.ts"]   // present only when budget cap triggered
}
```

- **`files.<path>.sha1`** — used by the incremental rebuilder to decide whether a file needs re-parsing.
- **`truncated_files`** — files whose `symbols` array was dropped to keep the graph under 500 KB. `imports` and `exports` are preserved. If you need symbols for a truncated file, fall through to Read/Grep.

## Budget

- **Hard cap: 500 KB JSON.** Enforced at write time.
- **Trimming strategy when over:** drop `symbols` for files with `centrality < 0.1`, sorted lowest-centrality first. Imports/exports stay.
- **Typical sizes:** 50 KB on a 5 K-line project, 150 KB on a 20 K-line project, 400 KB on a 100 K-line project (before trimming).

## Incremental rebuild

On SessionStart, `code-graph-update.sh` runs:
1. Check `.stp/state/stack.json` exists (required — tells us which grammars to load).
2. Check whether any source file is newer than `.stp/state/code-graph.json` (fast `find -newer`).
3. If so, invoke `hooks/scripts/code-graph/build.js`:
   - Load prior `.meta` → per-file SHA-1 table.
   - Walk source files.
   - For each file: compute SHA-1, compare to prior.
   - Unchanged → reuse prior graph entry. Changed → re-parse with tree-sitter.
   - Rebuild `references` and `centrality` from the (mostly-cached) file entries.
   - Write both files.

Typical incremental run on a quiet day: <500 ms.

## When NOT to trust the graph

- **Dynamic imports / runtime reflection** — `require(someString)`, `import(expr)`, Python `importlib`, Java `Class.forName()`. Not captured.
- **Template-literal import paths** — `import(\`./feature-\${flag}\`)`. Not captured.
- **Macros / codegen** — Rust `macro_rules!` expansions, C++ templates instantiated later, code generated at build time. Not in the graph.
- **Call graphs** — the graph tracks symbol *definitions* and *references*, not function *call* relationships. "Who calls `foo()`?" requires Grep.

For those cases, fall through to Glob/Grep as you would without the graph.

## Versioning

The top-level `version` field is incremented when the schema changes in a way that breaks forward compatibility. v1 = the initial ship (STP v1.1). Readers should check `version === 1` before relying on field names.

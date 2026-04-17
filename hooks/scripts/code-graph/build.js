#!/usr/bin/env node
// STP v1.1 — Code-graph builder (Aider-style repo map, tree-sitter based)
//
// Runs on SessionStart (backgrounded via code-graph-update.sh) or on demand.
// Reads .stp/state/stack.json, walks the project's source files, parses them
// with the bundled tree-sitter WASM grammars, extracts imports/exports/symbols,
// writes .stp/state/code-graph.json + .meta.
//
// Incremental: per-file SHA-1 in .meta. Only changed files re-parsed.
//
// Zero network, zero paid API. All grammars ship in grammars/ next to the
// plugin. web-tree-sitter ships in vendor/web-tree-sitter/. Works offline.
//
// Budget: hard cap 500 KB JSON. If exceeded, drop `symbols` array for files
// with centrality < 0.1 (keep imports/exports + file entry).

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ── Config ──────────────────────────────────────────────────────────
const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT
  || path.resolve(__dirname, '..', '..', '..');
const PROJECT_ROOT = process.cwd();
const STACK_JSON  = path.join(PROJECT_ROOT, '.stp', 'state', 'stack.json');
const OUT_JSON    = path.join(PROJECT_ROOT, '.stp', 'state', 'code-graph.json');
const META_JSON   = OUT_JSON + '.meta';
const GRAMMAR_DIR = path.join(PLUGIN_ROOT, 'grammars');
const WTS_DIR     = path.join(PLUGIN_ROOT, 'vendor', 'web-tree-sitter');
const MAX_BYTES   = 500 * 1024; // 500 KB

// Stack → file-extension list + grammar name. Stacks without parseable source
// (or unsupported languages) get an empty list and the graph ends up sparse.
const STACK_PROFILES = {
  web:            { exts: ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs'], langs: ['typescript', 'tsx', 'javascript'] },
  node:           { exts: ['.ts', '.js', '.mjs', '.cjs'],                 langs: ['typescript', 'javascript'] },
  python:         { exts: ['.py'],                                        langs: ['python'] },
  'data-ml':      { exts: ['.py'],                                        langs: ['python'] },
  rust:           { exts: ['.rs'],                                        langs: ['rust'] },
  go:             { exts: ['.go'],                                        langs: ['go'] },
  java:           { exts: ['.java'],                                      langs: ['java'] },
  csharp:         { exts: ['.cs'],                                        langs: ['c_sharp'] },
  cpp:            { exts: ['.cpp', '.cc', '.cxx', '.h', '.hpp', '.c'],    langs: ['cpp', 'c'] },
  'cheat-pentest':{ exts: ['.cpp', '.cc', '.h', '.hpp', '.c'],            langs: ['cpp', 'c'] },
  embedded:       { exts: ['.c', '.cpp', '.h', '.hpp', '.rs'],            langs: ['c', 'cpp', 'rust'] },
  game:           { exts: ['.cs', '.cpp', '.h'],                          langs: ['c_sharp', 'cpp'] },
  mod:            { exts: ['.java', '.cpp', '.py', '.cs'],                langs: ['java', 'cpp', 'python', 'c_sharp'] },
  generic:        { exts: [],                                             langs: [] },
};

// Directories to skip during file walk
const SKIP_DIRS = new Set([
  'node_modules', '.git', '.stp', 'dist', 'build', 'out',
  'target', '.next', '.nuxt', 'coverage', 'vendor', 'grammars',
  '.venv', 'venv', '__pycache__', '.pytest_cache', '.mypy_cache',
  '.cargo', '.rustup',
]);

// ── Utilities ───────────────────────────────────────────────────────
function sha1(buf) {
  return crypto.createHash('sha1').update(buf).digest('hex');
}

function readJSONSafe(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return null; }
}

function walkSource(root, exts, files = []) {
  // Iterative walk, skip heavy dirs.
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { continue; }
    for (const e of entries) {
      if (e.name.startsWith('.') && e.name !== '.stp') {
        // Skip most dotdirs but .stp is ours (though it's also in SKIP_DIRS).
        if (e.isDirectory()) continue;
      }
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (SKIP_DIRS.has(e.name)) continue;
        stack.push(full);
      } else if (e.isFile()) {
        const ext = path.extname(e.name);
        if (exts.includes(ext)) files.push(full);
      }
    }
  }
  return files;
}

function langForExt(ext, stackLangs) {
  switch (ext) {
    case '.ts':
    case '.mts':
    case '.cts': return 'typescript';
    case '.tsx': return 'tsx';
    case '.js':
    case '.jsx':
    case '.mjs':
    case '.cjs': return 'javascript';
    case '.py':  return 'python';
    case '.rs':  return 'rust';
    case '.go':  return 'go';
    case '.java':return 'java';
    case '.cs':  return 'c_sharp';
    case '.cpp':
    case '.cc':
    case '.cxx':
    case '.hpp': return 'cpp';
    case '.c':
    case '.h':   return stackLangs.includes('cpp') ? 'cpp' : 'c';
    default:     return null;
  }
}

function relPath(abs) {
  return path.relative(PROJECT_ROOT, abs).split(path.sep).join('/');
}

// ── Tree-sitter setup (web-tree-sitter@0.20.x API) ─────────────────
let Parser;
async function initParser() {
  if (Parser) return;
  const wtsJs = path.join(WTS_DIR, 'tree-sitter.js');
  if (!fs.existsSync(wtsJs)) {
    throw new Error(`web-tree-sitter not found at ${wtsJs}. Plugin install may be incomplete.`);
  }
  Parser = require(wtsJs);
  await Parser.init({
    locateFile: () => path.join(WTS_DIR, 'tree-sitter.wasm'),
  });
}

const languageCache = new Map();
async function loadLanguage(lang) {
  if (languageCache.has(lang)) return languageCache.get(lang);
  const wasmPath = path.join(GRAMMAR_DIR, `tree-sitter-${lang}.wasm`);
  if (!fs.existsSync(wasmPath)) {
    languageCache.set(lang, null);
    return null;
  }
  const L = await Parser.Language.load(wasmPath);
  languageCache.set(lang, L);
  return L;
}

// ── Query extraction ───────────────────────────────────────────────
const QUERIES = require('./queries.js');

function extractFromFile(source, language, lang) {
  const parser = new Parser();
  parser.setLanguage(language);
  const tree = parser.parse(source);

  const queryStr = QUERIES[lang];
  if (!queryStr) return { imports: [], exports: [], symbols: [], parseError: null };

  let query;
  try {
    query = language.query(queryStr);
  } catch (e) {
    return { imports: [], exports: [], symbols: [], parseError: `query compile failed: ${e.message}` };
  }

  const matches = query.matches(tree.rootNode);
  const imports = [];
  const exports = [];
  const symbols = [];

  for (const m of matches) {
    let importSource = null, importSymbols = [];
    let exportSource = null, exportSymbols = [];
    for (const c of m.captures) {
      const name = c.name;
      const text = c.node.text;
      const line = c.node.startPosition.row + 1;
      if (name === 'import.source') importSource = cleanString(text);
      else if (name === 'import.symbol') importSymbols.push(cleanString(text));
      else if (name === 'export.source') exportSource = cleanString(text);
      else if (name.startsWith('export.')) exportSymbols.push({ name: cleanString(text), kind: name.slice(7), line });
      else if (name.startsWith('symbol.')) symbols.push({ name: cleanString(text), kind: name.slice(7), line });
    }
    if (importSource) imports.push({ from: importSource, symbols: importSymbols });
    if (exportSymbols.length) {
      for (const s of exportSymbols) exports.push(exportSource ? { ...s, from: exportSource } : s);
    }
  }

  // Deduplicate symbols (tree-sitter can capture a symbol via multiple patterns)
  const seen = new Set();
  const dedupedSymbols = [];
  for (const s of symbols) {
    const key = `${s.kind}:${s.name}:${s.line}`;
    if (seen.has(key)) continue;
    seen.add(key);
    dedupedSymbols.push(s);
  }

  // Same for imports + exports
  const seenImports = new Set();
  const dedupedImports = [];
  for (const i of imports) {
    const key = `${i.from}:${i.symbols.join(',')}`;
    if (seenImports.has(key)) continue;
    seenImports.add(key);
    dedupedImports.push(i);
  }

  return { imports: dedupedImports, exports, symbols: dedupedSymbols, parseError: null };
}

function cleanString(s) {
  if (!s) return s;
  // Strip surrounding quotes from string literals
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    return s.slice(1, -1);
  }
  return s;
}

// ── Main ───────────────────────────────────────────────────────────
async function main() {
  const stack = readJSONSafe(STACK_JSON);
  if (!stack) {
    console.error('code-graph: no .stp/state/stack.json — skipping (run /stp:setup welcome first)');
    process.exit(0);
  }
  const profile = STACK_PROFILES[stack.stack];
  if (!profile || profile.exts.length === 0) {
    console.error(`code-graph: stack "${stack.stack}" has no indexable source — skipping`);
    process.exit(0);
  }

  await initParser();

  // Preload all relevant languages for this stack
  const languages = {};
  for (const lang of profile.langs) {
    const L = await loadLanguage(lang);
    if (L) languages[lang] = L;
  }
  if (Object.keys(languages).length === 0) {
    console.error(`code-graph: no grammars loaded for stack ${stack.stack} — skipping`);
    process.exit(0);
  }

  // Load prior meta for incremental rebuild
  const prevMeta = readJSONSafe(META_JSON) || { version: 1, files: {} };
  const prevGraph = readJSONSafe(OUT_JSON) || { version: 1, files: {} };

  // Walk files
  const files = walkSource(PROJECT_ROOT, profile.exts);
  const graph = {
    version: 1,
    generated_at: new Date().toISOString(),
    root: PROJECT_ROOT,
    stats: { files: 0, symbols: 0, edges: 0 },
    files: {},
    references: {},
  };
  const newMeta = { version: 1, files: {} };
  let reparsed = 0;
  let reused = 0;

  for (const file of files) {
    const rel = relPath(file);
    const stat = fs.statSync(file);
    const buf = fs.readFileSync(file);
    const hash = sha1(buf);
    const prev = prevMeta.files[rel];

    let entry;
    if (prev && prev.sha1 === hash && prevGraph.files && prevGraph.files[rel]) {
      // Unchanged — reuse prior entry
      entry = prevGraph.files[rel];
      reused++;
    } else {
      // Changed or new — re-parse
      const ext = path.extname(file);
      const lang = langForExt(ext, profile.langs);
      if (!lang || !languages[lang]) continue;

      let source;
      try {
        source = buf.toString('utf8');
      } catch {
        continue;
      }

      const { imports, exports, symbols, parseError } = extractFromFile(source, languages[lang], lang);
      entry = {
        lang,
        size_bytes: stat.size,
        sha1: hash,
        centrality: 0, // filled in after we have the full edge set
        imports,
        exports,
        symbols,
      };
      if (parseError) entry.parse_error = parseError;
      reparsed++;
    }

    graph.files[rel] = entry;
    newMeta.files[rel] = { sha1: hash, mtime: stat.mtimeMs };
  }

  // Build references table: symbol name → [file:line occurrences]
  for (const [rel, entry] of Object.entries(graph.files)) {
    for (const sym of (entry.symbols || [])) {
      const bucket = graph.references[sym.name] = graph.references[sym.name] || [];
      bucket.push({ file: rel, line: sym.line });
    }
    for (const ex of (entry.exports || [])) {
      if (!ex.name) continue;
      const bucket = graph.references[ex.name] = graph.references[ex.name] || [];
      bucket.push({ file: rel, line: ex.line, exported: true });
    }
  }

  // Compute centrality: degree-based (in + out edges), normalized 0-1
  const inDegree = {};
  const outDegree = {};
  for (const [rel, entry] of Object.entries(graph.files)) {
    outDegree[rel] = (entry.imports || []).length;
    for (const imp of (entry.imports || [])) {
      // Try to resolve the imported source to a known file
      const resolved = resolveImport(imp.from, rel, graph.files);
      if (resolved) {
        inDegree[resolved] = (inDegree[resolved] || 0) + 1;
      }
    }
  }
  const maxDeg = Math.max(
    1,
    ...Object.keys(graph.files).map(f => (inDegree[f] || 0) + (outDegree[f] || 0))
  );
  for (const rel of Object.keys(graph.files)) {
    const deg = (inDegree[rel] || 0) + (outDegree[rel] || 0);
    graph.files[rel].centrality = Math.round((deg / maxDeg) * 1000) / 1000;
  }

  graph.stats.files = Object.keys(graph.files).length;
  graph.stats.symbols = Object.values(graph.files).reduce(
    (s, f) => s + (f.symbols?.length || 0), 0
  );
  graph.stats.edges = Object.values(outDegree).reduce((s, v) => s + v, 0);

  // Enforce 500 KB budget — drop symbols for low-centrality files if over
  let json = JSON.stringify(graph);
  if (json.length > MAX_BYTES) {
    const truncated = [];
    const sortedByCentrality = Object.entries(graph.files)
      .sort(([, a], [, b]) => a.centrality - b.centrality);
    for (const [rel, entry] of sortedByCentrality) {
      if (json.length <= MAX_BYTES) break;
      if (entry.centrality < 0.1 && entry.symbols && entry.symbols.length > 0) {
        entry.symbols = [];
        truncated.push(rel);
        json = JSON.stringify(graph);
      }
    }
    if (truncated.length) newMeta.truncated_files = truncated;
  }

  // Write outputs atomically
  fs.mkdirSync(path.dirname(OUT_JSON), { recursive: true });
  fs.writeFileSync(OUT_JSON, json);
  fs.writeFileSync(META_JSON, JSON.stringify(newMeta, null, 2));

  console.error(
    `code-graph: ${graph.stats.files} files, ${graph.stats.symbols} symbols, ` +
    `${graph.stats.edges} edges. reparsed=${reparsed} reused=${reused}. ` +
    `size=${Math.round(json.length / 1024)} KB${newMeta.truncated_files ? ` (${newMeta.truncated_files.length} truncated)` : ''}`
  );
}

// Best-effort import resolver — strips relative prefixes and matches against known files
function resolveImport(importPath, fromRel, files) {
  if (!importPath) return null;
  // Strip quotes (shouldn't be needed, but defense)
  const cleaned = importPath.replace(/^['"]|['"]$/g, '');
  // Skip non-relative imports (external packages) — they're not in our graph
  if (!cleaned.startsWith('.') && !cleaned.startsWith('/')) return null;
  // Resolve relative to the importing file
  const fromDir = path.dirname(fromRel);
  let candidate = path.posix.normalize(path.posix.join(fromDir, cleaned));
  // Try common extensions
  const exts = ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.py', '.rs', '.go', '.java', '.cs', '.cpp', '.h', '.hpp', '.c'];
  if (files[candidate]) return candidate;
  for (const e of exts) if (files[candidate + e]) return candidate + e;
  // Try index.{ts,js} resolution
  for (const e of exts) if (files[`${candidate}/index${e}`]) return `${candidate}/index${e}`;
  return null;
}

main().catch(err => {
  console.error('code-graph: fatal', err && err.stack || err);
  process.exit(1);
});

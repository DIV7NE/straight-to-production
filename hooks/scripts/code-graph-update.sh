#!/bin/bash
# STP v1.1 — Code-graph SessionStart entry
#
# Runs code-graph/build.js if:
#   - .stp/state/stack.json exists (otherwise we don't know which language)
#   - any source file is newer than the graph (incremental trigger)
#   - OR the graph doesn't exist yet
#
# Runs IN THE BACKGROUND from hooks.json so it doesn't block SessionStart.
# Idempotent — re-running is safe, graph is rebuilt incrementally.
#
# Usage:
#   bash code-graph-update.sh           # background-safe, skips if nothing to do
#   bash code-graph-update.sh --sync    # forces synchronous full rebuild

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
GRAPH=".stp/state/code-graph.json"
STACK_JSON=".stp/state/stack.json"

# ── Precondition: stack must be detected ───────────────────────────
if [ ! -f "$STACK_JSON" ]; then
  exit 0
fi

# ── Precondition: node must be available ───────────────────────────
if ! command -v node >/dev/null 2>&1; then
  echo "[code-graph] Skipping — node not on PATH" >&2
  exit 0
fi

# ── Mode check ─────────────────────────────────────────────────────
MODE="${1:-auto}"

# ── Auto mode: only run if source changed or graph missing ─────────
if [ "$MODE" = "auto" ] && [ -f "$GRAPH" ]; then
  # Check if any source file is newer than the graph. Use the same
  # extensions build.js understands. Skip heavy dirs.
  NEWER=$(find . -type f \( \
      -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
      -o -name "*.mjs" -o -name "*.cjs" -o -name "*.py" -o -name "*.rs" \
      -o -name "*.go" -o -name "*.java" -o -name "*.cs" \
      -o -name "*.cpp" -o -name "*.cc" -o -name "*.hpp" -o -name "*.h" \
      -o -name "*.c" \
    \) \
    -not -path "./node_modules/*" \
    -not -path "./.git/*" \
    -not -path "./.stp/*" \
    -not -path "./dist/*" \
    -not -path "./build/*" \
    -not -path "./target/*" \
    -not -path "./.next/*" \
    -not -path "./grammars/*" \
    -not -path "./vendor/*" \
    -newer "$GRAPH" 2>/dev/null \
    | head -1)
  if [ -z "$NEWER" ]; then
    # Nothing newer — graph is fresh
    exit 0
  fi
fi

# ── Run the builder ────────────────────────────────────────────────
BUILD_JS="${PLUGIN_ROOT}/hooks/scripts/code-graph/build.js"
if [ ! -f "$BUILD_JS" ]; then
  echo "[code-graph] Builder not found at $BUILD_JS — plugin install incomplete" >&2
  exit 0
fi

CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" node "$BUILD_JS"

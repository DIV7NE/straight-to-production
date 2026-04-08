#!/bin/bash
# STP v0.3.3: Whiteboard server pre-gate
# PreToolUse hook that:
#   1. Blocks writes to the FORBIDDEN legacy filename .stp/explore-data.json
#      and similar non-canonical variants (training-data hallucination catch)
#   2. Auto-starts the whiteboard server before any Write to the canonical
#      .stp/whiteboard-data.json
#
# Bug history:
#
# v0.3.0 — server-start and data-write were separable markdown steps. Claude
# would write the data while the server was never started; user opened
# localhost:3333 to nothing.
#
# v0.3.1 — fixed the filename contract (whiteboard-data.json became canonical)
# but the post-mortem CHANGELOG *mentioned* the old name .stp/explore-data.json
# three times while explaining the bug. This taught Claude the wrong name as a
# valid alternative via context-read.
#
# v0.3.2 — introduced this hook, but it only matched the CORRECT filename.
# When Claude hallucinated .stp/explore-data.json (Session 2 reproduction),
# the hook saw a non-matching path and exited 0, allowing the wrong write.
# Data landed in a file the server doesn't watch. Localhost stayed empty.
#
# v0.3.3 (this file) — also match the forbidden name and reject it with a
# clear correction. Defense-in-depth: CLAUDE.md now carries the filename
# contract as an always-loaded rule; this hook is the enforcement backstop.
#
# Behavior:
#   - Write to .stp/explore-data.json (or any forbidden variant) → BLOCK
#     with a correction instruction (use whiteboard-data.json instead)
#   - Write to .stp/whiteboard-data.json with server running → ALLOW
#   - Write to .stp/whiteboard-data.json without server → auto-start, ALLOW
#   - Anything else → ALLOW (not our concern)
#
# EXIT CODE 0 = ALLOW   EXIT CODE 2 = BLOCK

# HOME bypass
if [ "$PWD" = "$HOME" ]; then exit 0; fi
# Only run inside STP projects
if [ ! -d ".stp" ]; then exit 0; fi
# Env escape hatch
if [ "${STP_BYPASS_WHITEBOARD_GATE:-}" = "1" ]; then exit 0; fi

# Read JSON from stdin
if [ -t 0 ]; then exit 0; fi
INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${TOOL_INPUT_file_path:-${TOOL_INPUT_FILE_PATH:-}}"
fi
if [ -z "$FILE_PATH" ]; then exit 0; fi

# ── Part 1: Catch the FORBIDDEN legacy filename (and variants) ───
# Claude sometimes hallucinates the pre-0.3.1 filename .stp/explore-data.json
# because the v0.3.1 post-mortem CHANGELOG mentions it. Also guard against
# other plausible hallucinations: whiteboard.json, board-data.json, etc.
# Canonical path is the literal string .stp/whiteboard-data.json.
if [[ "$FILE_PATH" =~ (^|/)\.stp/explore-data\.json$ ]] || \
   [[ "$FILE_PATH" =~ (^|/)\.stp/whiteboard\.json$ ]] || \
   [[ "$FILE_PATH" =~ (^|/)\.stp/board-data\.json$ ]] || \
   [[ "$FILE_PATH" =~ (^|/)\.stp/design-data\.json$ ]]; then
  {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║ STP WHITEBOARD GATE — wrong filename: $(basename "$FILE_PATH")"
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    echo "║ The canonical whiteboard data file is:                               ║"
    echo "║                                                                      ║"
    echo "║     .stp/whiteboard-data.json                                        ║"
    echo "║                                                                      ║"
    echo "║ The name you tried ($(basename "$FILE_PATH")) is a"
    echo "║ legacy / hallucinated variant. The server does NOT watch it, so any  ║"
    echo "║ data written there will never reach the browser — localhost:3333    ║"
    echo "║ will stay on its 'Waiting...' placeholder.                           ║"
    echo "║                                                                      ║"
    echo "║ Bug history context:                                                 ║"
    echo "║  - Pre-0.3.1: explore-data.json was used in some command docs.      ║"
    echo "║  - v0.3.1: renamed to whiteboard-data.json (canonical).             ║"
    echo "║  - v0.3.2 post-mortem mentions the old name in CHANGELOG.md          ║"
    echo "║    while explaining the bug. That teaches the wrong name.           ║"
    echo "║  - v0.3.3 (now): this hook catches the hallucination.               ║"
    echo "║                                                                      ║"
    echo "║ TO UNBLOCK: retry the Write with file_path set to                   ║"
    echo "║ .stp/whiteboard-data.json (with the same content).                  ║"
    echo "║                                                                      ║"
    echo "║ Escape hatch (power users only): STP_BYPASS_WHITEBOARD_GATE=1       ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
  } >&2
  exit 2
fi

# ── Part 2: Only auto-start server for the canonical filename ────
if [[ ! "$FILE_PATH" =~ (^|/)\.stp/whiteboard-data\.json$ ]]; then
  exit 0
fi

# ── Is the whiteboard server running? ────────────────────────────
# Check 1: process running
if pgrep -f "start-whiteboard\.sh" >/dev/null 2>&1; then
  exit 0
fi

# Check 2: port 3333 listening
if command -v ss >/dev/null 2>&1; then
  if ss -ltn 2>/dev/null | grep -q ":3333 "; then exit 0; fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltn 2>/dev/null | grep -q ":3333 "; then exit 0; fi
elif command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:3333 -sTCP:LISTEN >/dev/null 2>&1; then exit 0; fi
fi

# ── Not running — auto-start it ──────────────────────────────────
WHITEBOARD_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh"
if [ -x "$WHITEBOARD_SCRIPT" ]; then
  # Start in background, fully detached, so the hook doesn't block on it
  nohup bash "$WHITEBOARD_SCRIPT" "${CLAUDE_PLUGIN_ROOT}" "." >/dev/null 2>&1 &
  disown 2>/dev/null || true

  # Brief wait for the server to bind the port
  for i in 1 2 3 4 5; do
    sleep 0.3
    if command -v ss >/dev/null 2>&1; then
      ss -ltn 2>/dev/null | grep -q ":3333 " && break
    elif command -v netstat >/dev/null 2>&1; then
      netstat -ltn 2>/dev/null | grep -q ":3333 " && break
    fi
  done

  {
    echo ""
    echo "ℹ STP: whiteboard server was not running — auto-started it for you."
    echo "  Open http://localhost:3333 to watch the data render live."
    echo ""
  } >&2
  exit 0  # Allow the write to proceed
fi

# ── Fallback: couldn't auto-start, block with manual instructions ─
{
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════════╗"
  echo "║ STP WHITEBOARD GATE — cannot write whiteboard-data.json"
  echo "╠══════════════════════════════════════════════════════════════════════╣"
  echo "║ The whiteboard server is not running and auto-start failed (script  ║"
  echo "║ not found or not executable).                                        ║"
  echo "║                                                                      ║"
  echo "║ Start it manually, then retry:                                       ║"
  echo "║                                                                      ║"
  echo "║   bash \"\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh\" \\  ║"
  echo "║     \"\${CLAUDE_PLUGIN_ROOT}\" \".\" &                                   ║"
  echo "║                                                                      ║"
  echo "║ Then open http://localhost:3333 to watch the data render live.       ║"
  echo "║                                                                      ║"
  echo "║ Escape hatch: STP_BYPASS_WHITEBOARD_GATE=1                           ║"
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo ""
} >&2
exit 2

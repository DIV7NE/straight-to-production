#!/bin/bash
# STP v0.3.2: Whiteboard server pre-gate
# PreToolUse hook that auto-starts the whiteboard server before any
# Write to .stp/whiteboard-data.json.
#
# Why this exists: v0.3.0/0.3.1 failure.
# Commands told Claude "start whiteboard server MUST be first action", but
# the server-start step and the data-write step were separable in markdown.
# Claude would reach the data-write step first while the server was never
# started, and the user would open http://localhost:3333 to nothing.
# The v0.3.1 CLAUDE.md entry closed it "in spirit" but never enforced it.
# This hook makes server-before-data an enforced sequence.
#
# Behavior:
#   - If writing to anything other than .stp/whiteboard-data.json → allow
#   - If server is already running (pgrep OR port listening) → allow
#   - Otherwise → auto-start the server, wait briefly, allow
#   - If auto-start fails → BLOCK with manual instructions
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

# Only gate writes to the whiteboard data file
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

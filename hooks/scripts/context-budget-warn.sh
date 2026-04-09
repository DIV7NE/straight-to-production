#!/bin/bash
# context-budget-warn.sh — Warn when main session approaches the profile's max_main_session_kb.
#
# Fires on Stop event. Reads the active STP profile via the cjs resolver,
# checks the discipline.max_main_session_kb cap, and prints a warning if the
# current main-session size is approaching that cap.
#
# Why: in balanced-profile (cap=120) and budget-profile (cap=100), the main
# Sonnet 200K session must NOT compete for context with sub-agents that hold
# raw research/exploration dumps. This hook surfaces drift early so the user
# can /clear before compaction fires and loses fidelity.
#
# Behavior:
#   - intended-profile (no cap)        → silent, exit 0
#   - balanced-profile (cap = 120 KB)  → WARN at 60% (72 KB), strong warn at 80% (96 KB)
#   - budget-profile   (cap = 100 KB)  → WARN at 60% (60 KB), strong warn at 80% (80 KB)
#
# Size measurement strategy (in order of preference):
#   1. context_window.remaining_percentage from Stop event payload (if Claude Code provides it)
#   2. transcript_path file size × 0.65 (always available — JSONL transcript log)
#   3. Silent skip if neither works (safe fallback — no false positives)
#
# This is a feedback-only hook — never blocks. Stop is allowed regardless.

set -e

# Find the project root (where .stp/ lives)
if [ ! -d ".stp" ]; then
  exit 0
fi

# No cjs resolver = nothing to do
if [ ! -f "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" ] || ! command -v node >/dev/null 2>&1; then
  exit 0
fi

# Resolve discipline rules from active profile
DISC_JSON=$(node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" discipline 2>/dev/null)
if [ -z "$DISC_JSON" ]; then
  exit 0
fi

# Parse max_main_session_kb (null in intended-profile)
MAX_KB=$(echo "$DISC_JSON" | python3 -c "import sys,json; v=json.load(sys.stdin).get('max_main_session_kb'); print(v if v is not None else '')" 2>/dev/null)

# No cap = intended-profile, exit silently
if [ -z "$MAX_KB" ]; then
  exit 0
fi

# Read the hook input (passed via stdin by Claude Code).
# Stop event payload provides: {hook_event_name, session_id, transcript_path, cwd, stop_hook_active, ...}
# It does NOT reliably include context_window — that field is only on the statusline payload.
# We use transcript_path (the JSONL conversation log) as a proxy: byte size ÷ 4 ≈ token count ÷ 1.
INPUT=$(cat 2>/dev/null || echo "{}")
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)

USED_KB=""

# Strategy 1: if context_window is provided (e.g. by future Claude Code versions), use it
USED_PCT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); cw=d.get('context_window',{}); rem=cw.get('remaining_percentage'); print(100-rem if rem is not None else '')" 2>/dev/null)
if [ -n "$USED_PCT" ]; then
  # Scale: Sonnet 200K window ≈ 200 KB of transcript bytes
  TOTAL_KB=200
  USED_KB=$(python3 -c "print(int($USED_PCT * $TOTAL_KB / 100))" 2>/dev/null)
fi

# Strategy 2: fall back to transcript file size (always available on Stop events)
if [ -z "$USED_KB" ] && [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_BYTES=$(wc -c < "$TRANSCRIPT_PATH" 2>/dev/null); TRANSCRIPT_BYTES=${TRANSCRIPT_BYTES:-0}
  # Convert bytes to KB. The transcript JSONL contains tool calls + results which are ~1.5x the
  # actual context size (because Claude Code compresses some fields), so apply a 0.65 factor.
  USED_KB=$(python3 -c "print(int($TRANSCRIPT_BYTES * 0.65 / 1024))" 2>/dev/null)
fi

# If neither strategy worked, exit silently
if [ -z "$USED_KB" ] || [ "$USED_KB" = "0" ]; then
  exit 0
fi

# Compute warn thresholds
WARN_AT=$(python3 -c "print(int($MAX_KB * 0.6))")
STRONG_AT=$(python3 -c "print(int($MAX_KB * 0.8))")

# Get the active profile name for the message
PROFILE=$(node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current 2>/dev/null || echo "unknown")

# Decide warning level
if [ "$USED_KB" -ge "$STRONG_AT" ]; then
  # Strong warning — recommend immediate /clear
  echo "" >&2
  echo "[STP] ⚠⚠⚠ CONTEXT BUDGET CRITICAL ($PROFILE)" >&2
  echo "  Main session using ~${USED_KB}KB / cap ${MAX_KB}KB (${STRONG_AT}KB threshold)" >&2
  echo "  Action: /clear NOW. Compaction will lose fidelity on architecture decisions." >&2
  echo "  Disk state survives /clear: PRD.md, PLAN.md, current-feature.md, design-brief.md, profile.json" >&2
  echo "" >&2
elif [ "$USED_KB" -ge "$WARN_AT" ]; then
  # Soft warning — heads up
  echo "" >&2
  echo "[STP] ⚠ Context budget heads-up ($PROFILE)" >&2
  echo "  Main session using ~${USED_KB}KB / cap ${MAX_KB}KB (${WARN_AT}KB threshold)" >&2
  echo "  Recommendation: /clear at the next natural break (between phases)" >&2
  echo "" >&2
fi

exit 0

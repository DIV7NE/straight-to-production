#!/bin/bash
# Pilot: Session start / post-clear / post-compaction state restore
# Reads handoff note and state files, prints recovery context.
# Output gets injected into Claude's context at session start.

STATE_DIR=".pilot"
HANDOFF_FILE="$STATE_DIR/handoff.md"
STATE_FILE="$STATE_DIR/state.json"
FEATURE_FILE="$STATE_DIR/current-feature.md"

# Only run if .pilot/ exists (project was set up with Pilot)
if [ ! -d "$STATE_DIR" ]; then
  if [ -f "CLAUDE.md" ]; then
    echo "[Pilot] CLAUDE.md found but no .pilot/ directory. Run /pilot:setup to add standards."
  fi
  exit 0
fi

# Priority 1: Handoff note (written intentionally by /pilot:pause)
if [ -f "$HANDOFF_FILE" ]; then
  echo "[Pilot] Found handoff note from previous session. READ .pilot/handoff.md FIRST — it contains:" >&2
  echo "" >&2
  # Show just the section headers so Claude knows what's in it
  grep "^## " "$HANDOFF_FILE" | while read -r line; do
    echo "  $line" >&2
  done
  echo "" >&2
  echo "After reading the handoff, verify current state with the commands listed in 'How to Verify'." >&2
  echo "Then continue from 'What's Next' section." >&2
  exit 0
fi

# Priority 2: Emergency state (written by PreCompact hook)
if [ -f "$STATE_FILE" ]; then
  echo "[Pilot] Restoring from auto-saved state (compaction recovery)." >&2
  echo "" >&2

  BRANCH=$(grep -oP '"branch":\s*"([^"]*)"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  LAST_COMMIT=$(grep -oP '"last_commit":\s*"([^"]*)"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  UNCOMMITTED=$(grep -oP '"uncommitted_files":\s*([0-9]+)' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *//')

  echo "  Branch: $BRANCH" >&2
  echo "  Last commit: $LAST_COMMIT" >&2

  if [ "$UNCOMMITTED" -gt 0 ] 2>/dev/null; then
    echo "  WARNING: $UNCOMMITTED uncommitted files" >&2
  fi
  echo "" >&2
fi

# Priority 3: Active feature checklist
if [ -f "$FEATURE_FILE" ]; then
  FEATURE_TITLE=$(head -1 "$FEATURE_FILE" | sed 's/^#* *//')
  DONE=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  TOTAL=$(grep -c '\[.\]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  echo "[Pilot] Active feature: $FEATURE_TITLE ($DONE/$TOTAL complete)" >&2
  echo "  Read .pilot/current-feature.md for the checklist." >&2
  echo "" >&2
fi

# Always show recovery steps
echo "[Pilot] Recovery steps:" >&2
echo "  1. Read CLAUDE.md (project spec + standards)" >&2

if [ -f "$HANDOFF_FILE" ]; then
  echo "  2. Read .pilot/handoff.md (detailed handoff from last session)" >&2
elif [ -f "$FEATURE_FILE" ]; then
  echo "  2. Read .pilot/current-feature.md (feature checklist)" >&2
fi

echo "  3. git log --oneline -5 (recent work)" >&2
echo "  4. git status (uncommitted changes)" >&2
echo "  5. Continue from where you left off" >&2

exit 0

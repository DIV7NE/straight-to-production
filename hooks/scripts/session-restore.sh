#!/bin/bash
# Pilot v0.2.0: Session start / post-clear / post-compaction restore
# Reads handoff and state files, prints recovery context.

STATE_DIR=".pilot"
HANDOFF_FILE="$STATE_DIR/handoff.md"
STATE_FILE="$STATE_DIR/state.json"
FEATURE_FILE="$STATE_DIR/current-feature.md"

if [ ! -d "$STATE_DIR" ]; then
  if [ -f "CLAUDE.md" ]; then
    echo "[Pilot] CLAUDE.md found but no .pilot/ directory. Run /pilot:setup to add standards." >&2
  fi
  exit 0
fi

# Priority 1: Handoff note (intentional pause via /pilot:pause)
if [ -f "$HANDOFF_FILE" ]; then
  echo "[Pilot] Handoff note from previous session. READ .pilot/handoff.md FIRST:" >&2
  echo "" >&2
  grep "^## " "$HANDOFF_FILE" | while read -r line; do
    echo "  $line" >&2
  done
  echo "" >&2
  echo "Read the handoff, verify state, then continue from 'What's Next'." >&2
  exit 0
fi

# Priority 2: Emergency state (compaction recovery)
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

# Recovery steps
# Show current version
if [ -f "VERSION" ]; then
  VERSION=$(cat VERSION 2>/dev/null)
  echo "[Pilot] Project version: $VERSION" >&2
fi

echo "[Pilot] Recovery:" >&2
echo "  1. Read CHANGELOG.md (what was built, when, and why)" >&2
echo "  2. Read CLAUDE.md (project spec + standards)" >&2
if [ -f "$FEATURE_FILE" ]; then
  echo "  3. Read .pilot/current-feature.md (feature checklist)" >&2
fi
echo "  4. Read PLAN.md (milestones + what's done vs remaining)" >&2
echo "  5. Continue from where you left off" >&2

exit 0

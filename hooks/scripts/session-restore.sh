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

# Project status summary
echo "" >&2
echo "[Pilot] Project Status:" >&2

if [ -f "VERSION" ]; then
  echo "  Version: $(cat VERSION 2>/dev/null)" >&2
fi

if [ -f "PLAN.md" ]; then
  PLAN_DONE=$(grep -c '\[x\]' PLAN.md 2>/dev/null || echo "0")
  PLAN_TOTAL=$(grep -c '\[.\]' PLAN.md 2>/dev/null || echo "0")
  echo "  Plan progress: $PLAN_DONE/$PLAN_TOTAL features complete" >&2
fi

if [ -f "CHANGELOG.md" ]; then
  LAST_ENTRY=$(grep -m1 "^## \[" CHANGELOG.md 2>/dev/null | sed 's/^## //')
  if [ -n "$LAST_ENTRY" ]; then
    echo "  Last change: $LAST_ENTRY" >&2
  fi
fi

echo "" >&2
echo "[Pilot] Recovery — read these in order:" >&2
echo "  1. CONTEXT.md (what exists now — file map, schema, API, patterns)" >&2
echo "  2. CHANGELOG.md (what was built, when, and why)" >&2
echo "  3. PLAN.md (milestones + what's done vs remaining)" >&2
if [ -f "$FEATURE_FILE" ]; then
  echo "  4. .pilot/current-feature.md (active feature checklist)" >&2
fi
if [ -f "$STATE_DIR/handoff.md" ]; then
  echo "  4. .pilot/handoff.md (detailed context from last session)" >&2
fi
echo "  Then continue from where you left off." >&2

exit 0

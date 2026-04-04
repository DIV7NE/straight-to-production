#!/bin/bash
# STP v0.2.0: Session start / post-clear / post-compaction restore
# Reads handoff and state files, prints recovery context.

# Backward compatible: check .stp/ first, fall back to .pilot/ for existing projects
if [ -d ".stp" ]; then
  STATE_DIR=".stp"
elif [ -d ".pilot" ]; then
  STATE_DIR=".pilot"
  echo "[STP] Found legacy .pilot/ directory. Consider renaming to .stp/ for consistency." >&2
else
  if [ -f "CLAUDE.md" ]; then
    echo "[STP] CLAUDE.md found but no .stp/ directory. Run /stp:onboard-existing to add standards." >&2
  fi
  exit 0
fi

DOCS_DIR="$STATE_DIR/docs"
RUNTIME_DIR="$STATE_DIR/state"
HANDOFF_FILE="$RUNTIME_DIR/handoff.md"
STATE_FILE="$RUNTIME_DIR/state.json"
FEATURE_FILE="$RUNTIME_DIR/current-feature.md"

# Priority 1: Handoff note (intentional pause via /stp:pause)
if [ -f "$HANDOFF_FILE" ]; then
  echo "[STP] Handoff note found. Run /stp:continue to resume, or read .stp/state/handoff.md:" >&2
  echo "" >&2
  grep "^## " "$HANDOFF_FILE" | while read -r line; do
    echo "  $line" >&2
  done
  echo "" >&2
  echo "Run /stp:continue to pick up where you left off." >&2
  exit 0
fi

# Priority 2: Emergency state (compaction recovery)
if [ -f "$STATE_FILE" ]; then
  echo "[STP] Restoring from auto-saved state (compaction recovery)." >&2
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
  echo "[STP] Active feature: $FEATURE_TITLE ($DONE/$TOTAL complete)" >&2
  echo "  Read .stp/state/current-feature.md for the checklist." >&2
  echo "" >&2
fi

# Project status summary
echo "" >&2
echo "[STP] Project Status:" >&2

if [ -f "VERSION" ]; then
  echo "  Version: $(cat VERSION 2>/dev/null)" >&2
fi

if [ -f "$DOCS_DIR/PLAN.md" ]; then
  PLAN_DONE=$(grep -c '\[x\]' "$DOCS_DIR/PLAN.md" 2>/dev/null || echo "0")
  PLAN_TOTAL=$(grep -c '\[.\]' "$DOCS_DIR/PLAN.md" 2>/dev/null || echo "0")
  echo "  Plan progress: $PLAN_DONE/$PLAN_TOTAL features complete" >&2
fi

if [ -f "$DOCS_DIR/CHANGELOG.md" ]; then
  LAST_ENTRY=$(grep -m1 "^## \[" "$DOCS_DIR/CHANGELOG.md" 2>/dev/null | sed 's/^## //')
  if [ -n "$LAST_ENTRY" ]; then
    echo "  Last change: $LAST_ENTRY" >&2
  fi
fi

echo "" >&2
echo "[STP] Recovery — read these in order:" >&2
echo "  1. .stp/docs/CONTEXT.md (what exists now — file map, schema, API, patterns)" >&2
echo "  2. .stp/docs/CHANGELOG.md (what was built, when, and why)" >&2
echo "  3. .stp/docs/PLAN.md (milestones + what's done vs remaining)" >&2
if [ -f "$FEATURE_FILE" ]; then
  echo "  4. .stp/state/current-feature.md (active feature checklist)" >&2
fi
if [ -f "$HANDOFF_FILE" ]; then
  echo "  4. .stp/state/handoff.md (detailed context from last session)" >&2
fi
echo "  Or just run /stp:continue to resume automatically." >&2

exit 0

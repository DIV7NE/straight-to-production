#!/bin/bash
# STP v0.2.0: Pre-compaction state save
# Saves current working state to .stp/state/state.json before compaction.
# Must be fast (< 5 seconds).

# Backward compatible: .stp/ or legacy .pilot/
if [ -d ".stp" ]; then STATE_DIR=".stp"; elif [ -d ".pilot" ]; then STATE_DIR=".pilot"; else exit 0; fi
RUNTIME_DIR="$STATE_DIR/state"
STATE_FILE="$RUNTIME_DIR/state.json"

mkdir -p "$RUNTIME_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

ACTIVE_FEATURE=""
if [ -f "$RUNTIME_DIR/current-feature.md" ]; then
  ACTIVE_FEATURE=$(head -5 "$RUNTIME_DIR/current-feature.md" | tr '\n' ' ' | cut -c1-200)
fi

cat > "$STATE_FILE" << STATEEOF
{
  "saved_at": "$TIMESTAMP",
  "reason": "pre-compaction auto-save",
  "git": {
    "branch": "$BRANCH",
    "last_commit": "$LAST_COMMIT",
    "uncommitted_files": $UNCOMMITTED
  },
  "active_feature": "$ACTIVE_FEATURE",
  "recovery": "Run /stp:continue to resume automatically. It reads state.json, current-feature.md, and PLAN.md to pick up where you left off."
}
STATEEOF

echo "STP: State saved to $STATE_FILE before compaction." >&2
exit 0

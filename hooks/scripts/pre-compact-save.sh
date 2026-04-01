#!/bin/bash
# Pilot: Pre-compaction state save
# Saves current working state to .pilot/state.json before compaction destroys it.
# This runs as a command hook on PreCompact — it MUST be fast (< 5 seconds).

STATE_DIR=".pilot"
STATE_FILE="$STATE_DIR/state.json"

# Only run if .pilot/ exists (project was set up with Pilot)
if [ ! -d "$STATE_DIR" ]; then
  exit 0
fi

mkdir -p "$STATE_DIR"

# Gather state
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# Check for active feature file
ACTIVE_FEATURE=""
if [ -f "$STATE_DIR/current-feature.md" ]; then
  ACTIVE_FEATURE=$(head -5 "$STATE_DIR/current-feature.md" | tr '\n' ' ' | cut -c1-200)
fi

# Check for milestones
LAST_MILESTONE=""
if [ -f "$STATE_DIR/MILESTONES.md" ]; then
  LAST_MILESTONE=$(grep "^## " "$STATE_DIR/MILESTONES.md" | tail -1 | cut -c4-100)
fi

# Write state file
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
  "last_milestone": "$LAST_MILESTONE",
  "recovery_instructions": "Read .pilot/state.json and .pilot/current-feature.md to resume. Check git log --oneline -5 for recent work. Read CLAUDE.md for project context."
}
STATEEOF

echo "Pilot: State saved to $STATE_FILE before compaction." >&2

exit 0

#!/bin/bash
# STP: Check if project needs syncing after a plugin update.
# Also detects first-ever install (no .stp/ dir) and nudges /stp:welcome.

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"

# Get current plugin version
PLUGIN_VER=$(grep -m1 '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
[ -z "$PLUGIN_VER" ] && exit 0

# First-ever install: no .stp/ directory anywhere
if [ ! -d ".stp" ]; then
  echo "★ STP v${PLUGIN_VER} installed! Run /stp:welcome for guided setup, or /stp:new-project to start building." >&2
  exit 0
fi

# Existing project: check version mismatch
SYNC_FILE=".stp/state/last-synced-version"
SYNCED_VER=""
[ -f "$SYNC_FILE" ] && SYNCED_VER=$(cat "$SYNC_FILE" 2>/dev/null)

# If versions match, nothing to do
[ "$PLUGIN_VER" = "$SYNCED_VER" ] && exit 0

# Version mismatch — nudge the user
echo "⚠ STP plugin updated to v${PLUGIN_VER}$([ -n "$SYNCED_VER" ] && echo " (project last synced at v${SYNCED_VER})"). Run /stp:upgrade to sync project files." >&2

#!/bin/bash
# STP: Check if project needs syncing after a plugin update.
# Compares plugin version against the last-synced version stored in .stp/state/.
# If mismatched, prints a one-liner nudge to stderr (shows in session output).

# Only run if this is an STP-managed project
[ -d ".stp" ] || exit 0

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
SYNC_FILE=".stp/state/last-synced-version"

# Get current plugin version
PLUGIN_VER=$(grep -m1 '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
[ -z "$PLUGIN_VER" ] && exit 0

# Get last-synced version
SYNCED_VER=""
[ -f "$SYNC_FILE" ] && SYNCED_VER=$(cat "$SYNC_FILE" 2>/dev/null)

# If versions match, nothing to do
[ "$PLUGIN_VER" = "$SYNCED_VER" ] && exit 0

# Version mismatch — nudge the user
echo "⚠ STP plugin updated to v${PLUGIN_VER}$([ -n "$SYNCED_VER" ] && echo " (project last synced at v${SYNCED_VER})"). Run /stp:upgrade to sync project files (CLAUDE.md, references, hooks)." >&2

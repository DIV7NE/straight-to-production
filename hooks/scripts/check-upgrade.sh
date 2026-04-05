#!/bin/bash
# STP: Check if plugin is behind remote origin/main
# Runs once at session start (via SessionStart hook), writes cache for statusline.
# Runs in background (&) so it never blocks session startup.

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
CACHE_FILE="$PLUGIN_DIR/.stp-upgrade-cache.json"

# Skip if cache is fresh (< 1 hour old)
if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0") ))
  if [ "$CACHE_AGE" -lt 3600 ]; then
    exit 0
  fi
fi

# Fetch remote (timeout 5s, silent)
cd "$PLUGIN_DIR" || exit 0
git fetch origin main --quiet 2>/dev/null &
FETCH_PID=$!

# Kill fetch if it takes too long
( sleep 5 && kill "$FETCH_PID" 2>/dev/null ) &
TIMER_PID=$!
wait "$FETCH_PID" 2>/dev/null
kill "$TIMER_PID" 2>/dev/null

# Compare
LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
  # Can't determine — write not-behind
  echo "{\"ts\":$(date +%s)000,\"behind\":false}" > "$CACHE_FILE"
  exit 0
fi

if [ "$LOCAL" != "$REMOTE" ]; then
  echo "{\"ts\":$(date +%s)000,\"behind\":true}" > "$CACHE_FILE"
else
  echo "{\"ts\":$(date +%s)000,\"behind\":false}" > "$CACHE_FILE"
fi

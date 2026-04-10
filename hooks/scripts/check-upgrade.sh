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

# Get local version (always needed regardless of install type)
LOCAL_VER=$(grep -m1 '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')

# ── npm install: check registry ──────────────────────────────────────────────
if [ -f "$PLUGIN_DIR/.install-manifest.json" ]; then
  REMOTE_VER=$(npm view stp-cc version 2>/dev/null)

  if [ -z "$REMOTE_VER" ]; then
    echo "{\"ts\":$(date +%s)000,\"behind\":false,\"version\":\"${LOCAL_VER}\",\"source\":\"npm\"}" > "$CACHE_FILE"
    exit 0
  fi

  if [ "$LOCAL_VER" != "$REMOTE_VER" ]; then
    echo "{\"ts\":$(date +%s)000,\"behind\":true,\"local_ver\":\"${LOCAL_VER}\",\"remote_ver\":\"${REMOTE_VER}\",\"behind_count\":1,\"source\":\"npm\",\"upgrade_cmd\":\"npx stp-cc@latest\"}" > "$CACHE_FILE"
  else
    echo "{\"ts\":$(date +%s)000,\"behind\":false,\"version\":\"${LOCAL_VER}\",\"source\":\"npm\"}" > "$CACHE_FILE"
  fi
  exit 0
fi

# ── git install: check remote ────────────────────────────────────────────────
cd "$PLUGIN_DIR" || exit 0
[ -d ".git" ] || exit 0

# Fetch remote (timeout 5s, silent)
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
  echo "{\"ts\":$(date +%s)000,\"behind\":false,\"version\":\"${LOCAL_VER}\",\"source\":\"git\"}" > "$CACHE_FILE"
  exit 0
fi

# Check if remote has commits we don't have (we're behind)
BEHIND_COUNT=$(git rev-list --count HEAD..origin/main 2>/dev/null)
BEHIND_COUNT=${BEHIND_COUNT:-0}

if [ "$BEHIND_COUNT" -gt 0 ]; then
  # Try to get remote version from origin/main's plugin.json
  REMOTE_VER=$(git show origin/main:.claude-plugin/plugin.json 2>/dev/null | grep -m1 '"version"' | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
  REMOTE_VER=${REMOTE_VER:-"newer"}
  echo "{\"ts\":$(date +%s)000,\"behind\":true,\"local_ver\":\"${LOCAL_VER}\",\"remote_ver\":\"${REMOTE_VER}\",\"behind_count\":${BEHIND_COUNT},\"source\":\"git\"}" > "$CACHE_FILE"
else
  echo "{\"ts\":$(date +%s)000,\"behind\":false,\"version\":\"${LOCAL_VER}\",\"source\":\"git\"}" > "$CACHE_FILE"
fi

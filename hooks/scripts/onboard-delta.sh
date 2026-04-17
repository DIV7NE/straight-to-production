#!/bin/bash
# STP v1.1 — Onboard delta computation
#
# Called by `/stp:setup onboard --refresh`. Returns the list of files that
# have changed since the last onboard marker. If no changes: prints
# "NO_CHANGES" and exits 0.
#
# Usage:
#   bash onboard-delta.sh [SCOPE]
#
# Arguments:
#   SCOPE — optional path prefix to restrict the delta to (e.g. "src/auth").
#           Empty string = whole repo.
#
# Exit codes:
#   0 — success (changed files on stdout, or "NO_CHANGES")
#   2 — no prior onboard marker exists (caller should run fresh onboard first)
#   3 — git not available or not a git repo

set -u

MARKER=".stp/state/onboard-marker.json"
SCOPE="${1:-}"

# ── Precondition: prior onboard must exist ─────────────────────────
if [ ! -f "$MARKER" ]; then
  echo "ERROR: No prior onboard marker found at $MARKER" >&2
  echo "Run /stp:setup onboard (without --refresh) first to establish the baseline." >&2
  exit 2
fi

# ── Precondition: git available ────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not available on PATH" >&2
  exit 3
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 3
fi

# ── Extract last onboard timestamp from marker ─────────────────────
# Prefer last_refresh_at if present (most recent), fall back to last_full_onboard_at
if command -v jq >/dev/null 2>&1; then
  LAST=$(jq -r '.last_refresh_at // .last_full_onboard_at // empty' "$MARKER")
else
  # jq-free fallback — grep for the timestamp. Prefer last_refresh_at.
  LAST=$(grep -oE '"last_refresh_at"[[:space:]]*:[[:space:]]*"[^"]+"' "$MARKER" | sed -E 's/.*"([^"]+)"$/\1/' | head -1)
  if [ -z "$LAST" ]; then
    LAST=$(grep -oE '"last_full_onboard_at"[[:space:]]*:[[:space:]]*"[^"]+"' "$MARKER" | sed -E 's/.*"([^"]+)"$/\1/' | head -1)
  fi
fi

if [ -z "$LAST" ]; then
  echo "ERROR: onboard-marker.json exists but has no last_full_onboard_at / last_refresh_at timestamp" >&2
  exit 2
fi

# ── Compute the delta via git log ───────────────────────────────────
# --since with an ISO timestamp is unambiguous on Git Bash, WSL, Linux, macOS.
# --name-only lists files touched by each commit in range.
# --pretty=format: suppresses commit info; we only want file names.
# -- "$SCOPE" restricts the walk to that pathspec when set.

if [ -n "$SCOPE" ]; then
  CHANGED=$(git log --since="$LAST" --name-only --pretty=format: -- "$SCOPE" 2>/dev/null \
    | sort -u \
    | grep -v '^[[:space:]]*$' \
    || true)
else
  CHANGED=$(git log --since="$LAST" --name-only --pretty=format: 2>/dev/null \
    | sort -u \
    | grep -v '^[[:space:]]*$' \
    || true)
fi

# Strip CRLF artifacts (Windows bash might leave them) and any git noise
CHANGED=$(echo "$CHANGED" | tr -d '\r')

if [ -z "$CHANGED" ]; then
  echo "NO_CHANGES"
  exit 0
fi

echo "$CHANGED"

#!/bin/bash
# STP v0.2.0: Migrate from old layouts to organized directory structure
# Idempotent — safe to run multiple times. Only moves files that exist in old locations.
#
# Migration steps (in order):
#   1. .pilot/ → .stp/          (legacy directory rename)
#   2. Root docs → .stp/docs/   (PRD.md, PLAN.md, CONTEXT.md, CHANGELOG.md)
#   3. Flat state → .stp/state/ (current-feature.md, handoff.md, state.json)

MOVED=0

# ── Step 1: Rename .pilot/ → .stp/ ─────────────────────────────
if [ -d ".pilot" ] && [ ! -d ".stp" ]; then
  mv ".pilot" ".stp"
  echo "[STP] Renamed .pilot/ → .stp/" >&2
  MOVED=$((MOVED + 1))
elif [ -d ".pilot" ] && [ -d ".stp" ]; then
  # Both exist — merge .pilot/ contents into .stp/, then remove .pilot/
  for item in .pilot/*; do
    [ -e "$item" ] || continue
    base=$(basename "$item")
    if [ ! -e ".stp/$base" ]; then
      mv "$item" ".stp/$base"
      MOVED=$((MOVED + 1))
    fi
  done
  rmdir ".pilot" 2>/dev/null
  if [ -d ".pilot" ]; then
    echo "[STP] Warning: .pilot/ still has files — merge manually." >&2
  fi
fi

# Must have .stp/ to continue
[ -d ".stp" ] || exit 0

# ── Step 2: Create organized subdirectories ─────────────────────
mkdir -p ".stp/docs" 2>/dev/null
mkdir -p ".stp/state" 2>/dev/null

# ── Step 3: Migrate root docs → .stp/docs/ ─────────────────────
for doc in PRD.md PLAN.md CONTEXT.md CHANGELOG.md; do
  if [ -f "$doc" ] && [ ! -f ".stp/docs/$doc" ]; then
    mv "$doc" ".stp/docs/$doc"
    MOVED=$((MOVED + 1))
  fi
done

# ── Step 4: Migrate flat state files → .stp/state/ ─────────────
for state_file in current-feature.md handoff.md state.json .stop-retry-count; do
  if [ -f ".stp/$state_file" ] && [ ! -f ".stp/state/$state_file" ]; then
    mv ".stp/$state_file" ".stp/state/$state_file"
    MOVED=$((MOVED + 1))
  fi
done

# ── Report ──────────────────────────────────────────────────────
if [ "$MOVED" -gt 0 ]; then
  echo "[STP] Migrated $MOVED files to organized layout (.stp/docs/ + .stp/state/)." >&2
fi

exit 0

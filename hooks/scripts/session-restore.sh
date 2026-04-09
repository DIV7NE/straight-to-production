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
PROFILE_FILE="$RUNTIME_DIR/profile.json"

# ── Profile display (no auto-init — silent default = intended-profile) ─
# If profile.json exists and is not the default intended-profile, surface it.
# Single source of truth lives in references/model-profiles.cjs (GSD-style).
if [ -f "$PROFILE_FILE" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" ] && command -v node >/dev/null 2>&1; then
  # Source KEY=VALUE lines from the resolver
  PROFILE_RESOLVED=$(STP_PROJECT_ROOT="$(pwd)" node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all 2>/dev/null)
  if [ -n "$PROFILE_RESOLVED" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      export "$line"
    done <<< "$PROFILE_RESOLVED"

    if [ -n "$STP_PROFILE" ] && [ "$STP_PROFILE" != "intended-profile" ]; then
      echo "[STP] Profile: $STP_PROFILE" >&2
      echo "  Executor: $STP_MODEL_EXECUTOR  ·  QA: $STP_MODEL_QA  ·  Critic: $STP_MODEL_CRITIC" >&2
      echo "  Researcher: $STP_MODEL_RESEARCHER  ·  Explorer: $STP_MODEL_EXPLORER" >&2
      echo "  Discipline: /clear=$STP_CLEAR_DISCIPLINE  ·  ctx-mode=$STP_CONTEXT_MODE_LEVEL  ·  researcher-mand=$STP_RESEARCHER_MANDATORY" >&2
      echo "  Switch: /stp:set-profile-model" >&2
      echo "" >&2
    fi
  fi
fi

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
  # NB: `grep -c PATTERN FILE 2>/dev/null || echo 0` is BROKEN — grep prints
  # "0" before exiting non-zero on no-match, so the `||` fallback APPENDS
  # rather than replacing, producing the literal "0\n0" string. Fixed in
  # v0.3.7 across all hook scripts.
  DONE=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null); DONE=${DONE:-0}
  TOTAL=$(grep -c '\[.\]' "$FEATURE_FILE" 2>/dev/null); TOTAL=${TOTAL:-0}
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
  # See note above re: the `grep -c … || echo 0` bug fixed in v0.3.7.
  PLAN_DONE=$(grep -c '\[x\]' "$DOCS_DIR/PLAN.md" 2>/dev/null); PLAN_DONE=${PLAN_DONE:-0}
  PLAN_TOTAL=$(grep -c '\[.\]' "$DOCS_DIR/PLAN.md" 2>/dev/null); PLAN_TOTAL=${PLAN_TOTAL:-0}
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

# ── Global CLAUDE.md STP version check ──────────────────────────
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
if [ -f "$GLOBAL_CLAUDE" ]; then
  # Check if STP sections exist
  STP_VERSION_IN_GLOBAL=$(grep -oP '<!-- STP v\K[0-9.]+' "$GLOBAL_CLAUDE" 2>/dev/null | head -1)
  PLUGIN_VERSION=$(grep -oP '"version":\s*"\K[0-9.]+' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null | head -1)

  if [ -z "$STP_VERSION_IN_GLOBAL" ]; then
    # No STP marker found — global CLAUDE.md exists but has no STP sections
    echo "" >&2
    echo "[STP] Global CLAUDE.md has no STP sections. Run /stp:new-project or /stp:onboard-existing to set it up." >&2
  elif [ -n "$PLUGIN_VERSION" ] && [ "$STP_VERSION_IN_GLOBAL" != "$PLUGIN_VERSION" ]; then
    # STP marker found but version is outdated
    echo "" >&2
    echo "[STP] Global CLAUDE.md has STP v$STP_VERSION_IN_GLOBAL but plugin is v$PLUGIN_VERSION. Run /stp:upgrade to update." >&2
  fi
fi

exit 0

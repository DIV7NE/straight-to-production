#!/bin/bash
# STP v0.3.2: UI work pre-gate
# PreToolUse hook for Write (and Edit|MultiEdit when creating new files).
#
# Purpose: blocks creation of new UI files (*.html, *.tsx, *.jsx, *.vue,
# *.svelte, *.astro, *.css, *.scss, *.sass, *.less) unless the design system
# consultation step has run and written .stp/state/ui-gate-passed.
#
# Why this exists: v0.3.1 post-mortem.
# Step 1b of /stp:work-quick labeled the ui-ux-pro-max consultation MANDATORY
# in markdown, but Claude routed around it and shipped an AI-slop landing page
# (gradient headlines, eyebrow "beta" pills, 3 boxed benefit cards, template
# copy). Markdown "MUST" is a suggestion. This hook is the enforcement.
#
# EXIT CODE 2 = BLOCK (stderr tells Claude exactly how to unblock)
# EXIT CODE 0 = ALLOW
#
# Bypass mechanisms (for power users / debug sessions):
#   - Set STP_BYPASS_UI_GATE=1 in the environment
#   - Touch .stp/state/ui-gate-passed (marker is session-scoped, wiped on /clear)
#   - Run any STP command that includes the design-system consultation step
#
# Safe-by-default carve-outs (never blocks):
#   - Not inside an STP project (no .stp/ dir)
#   - Running at $HOME
#   - File is a test, story, config, or migration
#   - File already exists on disk (Edit/overwrite of approved file)

# HOME bypass
if [ "$PWD" = "$HOME" ]; then exit 0; fi

# Only run inside STP projects
if [ ! -d ".stp" ]; then exit 0; fi

# Env-var escape hatch
if [ "${STP_BYPASS_UI_GATE:-}" = "1" ]; then exit 0; fi

# Read JSON from stdin (PreToolUse payload)
if [ -t 0 ]; then exit 0; fi
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')

# Fallback to env var (older Claude Code versions)
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${TOOL_INPUT_file_path:-${TOOL_INPUT_FILE_PATH:-}}"
fi

# No file path = not a file write, allow
if [ -z "$FILE_PATH" ]; then exit 0; fi

# ── Match UI file extensions ─────────────────────────────────────
UI_EXT_REGEX='\.(html|htm|tsx|jsx|vue|svelte|astro|css|scss|sass|less|styl|stylus)$'
if ! [[ "$FILE_PATH" =~ $UI_EXT_REGEX ]]; then
  exit 0  # Not a UI file
fi

# ── Carve-outs: tests, stories, configs, migrations ──────────────
# These are not user-facing UI and don't need the design gate
if [[ "$FILE_PATH" =~ \.(test|spec|stories|story)\. ]] || \
   [[ "$FILE_PATH" =~ /(test|tests|__tests__|stories|__stories__|migrations|migrate|fixtures|__mocks__)/ ]] || \
   [[ "$FILE_PATH" =~ \.(config|d)\. ]] || \
   [[ "$FILE_PATH" =~ (tsconfig|jsconfig|tailwind\.config|postcss\.config|vite\.config|webpack\.config|next\.config|svelte\.config|nuxt\.config|astro\.config)\. ]]; then
  exit 0
fi

# ── Overwrite-of-existing-file is allowed ─────────────────────────
# If the file already exists on disk, this is an edit of already-approved
# code — don't re-gate. Only new-file creation triggers the gate.
if [ -f "$FILE_PATH" ]; then
  exit 0
fi

# ── Check for gate marker ─────────────────────────────────────────
MARKER_FILE=".stp/state/ui-gate-passed"
if [ -f "$MARKER_FILE" ]; then
  # Marker exists. Verify freshness (max 4h old) to prevent stale approvals
  # leaking across sessions. /clear wipes the marker via SessionStart hook.
  MARKER_AGE=$(( $(date +%s) - $(stat -c %Y "$MARKER_FILE" 2>/dev/null || echo "0") ))
  if [ "$MARKER_AGE" -lt 14400 ]; then
    exit 0  # Fresh marker, allow
  fi
  # Stale marker — fall through to block so user re-confirms design direction
fi

# ── BLOCK ─────────────────────────────────────────────────────────
BASENAME=$(basename "$FILE_PATH")
{
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════════╗"
  echo "║ STP UI GATE BLOCKED — $BASENAME"
  echo "╠══════════════════════════════════════════════════════════════════════╣"
  echo "║ Creating a new UI file requires the design-system consultation step ║"
  echo "║ to run first. Markdown instructions were not enough (v0.3.1          ║"
  echo "║ post-mortem: ui-ux-pro-max gate was MANDATORY in skills/work-*/SKILL.md  ║"
  echo "║ but Claude routed around it and shipped an AI-slop landing page).    ║"
  echo "║                                                                      ║"
  echo "║ TO UNBLOCK (in order):                                               ║"
  echo "║                                                                      ║"
  echo "║  1. Find or generate the design system:                             ║"
  echo "║       find design-system -maxdepth 4 -name 'MASTER.md'              ║"
  echo "║     If none exists, invoke /ui-ux-pro-max to generate one.          ║"
  echo "║                                                                      ║"
  echo "║  2. Read the MASTER.md and state the design direction to the user   ║"
  echo "║     (layout pattern, colors, type, spacing, anti-slop constraints). ║"
  echo "║                                                                      ║"
  echo "║  3. Get user approval via AskUserQuestion — do NOT skip this.       ║"
  echo "║                                                                      ║"
  echo "║  4. Mark the gate as passed:                                        ║"
  echo "║       mkdir -p .stp/state && touch .stp/state/ui-gate-passed        ║"
  echo "║                                                                      ║"
  echo "║  5. Retry the Write.                                                 ║"
  echo "║                                                                      ║"
  echo "║ Escape hatches:                                                      ║"
  echo "║   - STP_BYPASS_UI_GATE=1 env var (power users only)                 ║"
  echo "║   - Editing an existing file (this hook only gates new-file writes) ║"
  echo "╚══════════════════════════════════════════════════════════════════════╝"
  echo ""
} >&2

exit 2

#!/bin/bash
# Pilot: Pre-prompt re-injection
# Fires on UserPromptSubmit — before every user message is processed.
# Injects the current task from .pilot/current-feature.md so Claude never forgets
# what it should be working on, even deep into a long session.
#
# This is the lightweight version of claude-subconscious's UserPromptSubmit hook.
# Instead of an external AI agent, we just read the file and inject the next task.

STATE_DIR=".pilot"
FEATURE_FILE="$STATE_DIR/current-feature.md"

# Only run if there's an active feature
if [ ! -f "$FEATURE_FILE" ]; then
  exit 0
fi

# Find the next unchecked item
NEXT_TASK=$(grep -m1 '\[ \]' "$FEATURE_FILE" 2>/dev/null | sed 's/^[[:space:]]*- \[ \] //')

if [ -z "$NEXT_TASK" ]; then
  # All items checked — feature might be complete
  FEATURE_TITLE=$(head -1 "$FEATURE_FILE" | sed 's/^#* *//')
  echo "[Pilot] All items in '$FEATURE_TITLE' are complete. Run /pilot:evaluate or start the next feature." >&2
  exit 0
fi

# Count progress
CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")
TOTAL=$(grep -c '\[.\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

# Only inject every ~10 prompts to avoid noise (check counter)
COUNTER_FILE="$STATE_DIR/.prompt-count"
if [ -f "$COUNTER_FILE" ]; then
  PCOUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  PCOUNT=$((PCOUNT + 1))
else
  PCOUNT=1
fi
echo "$PCOUNT" > "$COUNTER_FILE"

# Inject at prompts 1, 10, 20, 30... (first prompt + every 10th)
if [ "$PCOUNT" -eq 1 ] || [ $((PCOUNT % 10)) -eq 0 ]; then
  echo "[Pilot] Current task ($CHECKED/$TOTAL): $NEXT_TASK" >&2
fi

exit 0

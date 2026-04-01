#!/bin/bash
# Pilot: Stop verification hook
# EXIT CODE 2 = BLOCK (Claude cannot stop, must continue)
# EXIT CODE 0 = ALLOW (Claude can stop)
#
# This is REAL enforcement, not a suggestion.
# Exit code 2 physically prevents Claude from finishing its response.
#
# Logic:
# 1. TypeScript errors exist → BLOCK (exit 2), feed errors back
# 2. Unchecked feature items AND context < 60% → BLOCK (exit 2)
# 3. Stop hook already active (infinite loop prevention) → ALLOW (exit 0)
# 4. Everything else → ALLOW (exit 0)

# Infinite loop prevention: check if this is a re-fire
INPUT=$(cat 2>/dev/null || echo "{}")
if echo "$INPUT" | grep -q '"stop_hook_active":\s*true' 2>/dev/null; then
  exit 0
fi

STATE_DIR=".pilot"
FEATURE_FILE="$STATE_DIR/current-feature.md"
COUNTER_FILE="$STATE_DIR/.tool-call-count"

# === ENFORCEMENT 1: TypeScript errors ===
if [ -f "tsconfig.json" ]; then
  TS_OUTPUT=$(npx tsc --noEmit --pretty false 2>&1)
  TS_ERRORS=$(echo "$TS_OUTPUT" | grep -c "error TS" 2>/dev/null || echo "0")

  if [ "$TS_ERRORS" -gt 0 ]; then
    echo "BLOCKED: $TS_ERRORS TypeScript error(s). Fix before completing:" >&2
    echo "$TS_OUTPUT" | grep "error TS" | head -10 >&2
    exit 2
  fi
fi

# === ENFORCEMENT 2: Unchecked feature items ===
if [ -f "$FEATURE_FILE" ]; then
  # Check context usage
  CALL_COUNT=0
  if [ -f "$COUNTER_FILE" ]; then
    CALL_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  fi

  # Only block if context isn't too full (< 60%)
  if [ "$CALL_COUNT" -lt 500 ]; then
    UNCHECKED=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || echo "0")
    CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

    if [ "$UNCHECKED" -gt 0 ]; then
      NEXT=$(grep -m1 '\[ \]' "$FEATURE_FILE" | sed 's/^[[:space:]]*- \[ \] //')
      echo "BLOCKED: $UNCHECKED items remain ($CHECKED done). Next: $NEXT" >&2
      echo "Continue working. Run /pilot:pause if you need to stop." >&2
      exit 2
    fi
  fi
fi

# All checks passed — allow stop
exit 0

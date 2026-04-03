#!/bin/bash
# Pilot v0.2.0: Statusline — shows project state + context usage at a glance
# Reads from disk + environment. Zero token cost. Fast (<50ms).

PARTS=()

# Version
if [ -f "VERSION" ]; then
  PARTS+=("v$(cat VERSION 2>/dev/null)")
fi

# Active feature + progress
if [ -f ".pilot/current-feature.md" ]; then
  TITLE=$(head -1 ".pilot/current-feature.md" | sed 's/^#* *//' | cut -c1-25)
  DONE=$(grep -c '\[x\]' ".pilot/current-feature.md" 2>/dev/null || echo "0")
  TOTAL=$(grep -c '\[.\]' ".pilot/current-feature.md" 2>/dev/null || echo "0")
  PARTS+=("${TITLE} [${DONE}/${TOTAL}]")
elif [ -f "PLAN.md" ]; then
  DONE=$(grep -c '\[x\]' "PLAN.md" 2>/dev/null || echo "0")
  TOTAL=$(grep -c '\[.\]' "PLAN.md" 2>/dev/null || echo "0")
  if [ "$TOTAL" -gt 0 ]; then
    PARTS+=("Plan ${DONE}/${TOTAL}")
  fi
fi

# Current milestone
if [ -f "PLAN.md" ]; then
  MILESTONE=$(grep -B1 '\[ \]' "PLAN.md" 2>/dev/null | grep "^### Milestone" | head -1 | sed 's/^### Milestone [0-9]*: //' | cut -c1-20)
  if [ -n "$MILESTONE" ]; then
    PARTS+=("$MILESTONE")
  fi
fi

# Context usage bar with compaction threshold
# Uses CLAUDE_CONTEXT_TOKENS_USED and CLAUDE_CONTEXT_WINDOW_SIZE if available
# Falls back to tool-call counter as rough proxy
TOKENS_USED="${CLAUDE_CONTEXT_TOKENS_USED:-0}"
WINDOW_SIZE="${CLAUDE_CONTEXT_WINDOW_SIZE:-0}"

if [ "$WINDOW_SIZE" -gt 0 ] 2>/dev/null; then
  # Real token data available
  PCT=$((TOKENS_USED * 100 / WINDOW_SIZE))
  COMPACT_PCT=75  # Compaction typically fires at ~75%
  TILL_COMPACT=$((COMPACT_PCT - PCT))
  if [ "$TILL_COMPACT" -lt 0 ]; then TILL_COMPACT=0; fi

  # Build visual bar (20 chars wide)
  BAR_WIDTH=20
  FILLED=$((PCT * BAR_WIDTH / 100))
  COMPACT_POS=$((COMPACT_PCT * BAR_WIDTH / 100))

  BAR=""
  for ((i=0; i<BAR_WIDTH; i++)); do
    if [ "$i" -eq "$COMPACT_POS" ]; then
      BAR="${BAR}|"
    elif [ "$i" -lt "$FILLED" ]; then
      BAR="${BAR}█"
    else
      BAR="${BAR}░"
    fi
  done

  if [ "$PCT" -ge "$COMPACT_PCT" ]; then
    PARTS+=("[${BAR}] ${PCT}% ⚠ compact soon")
  else
    PARTS+=("[${BAR}] ${PCT}% (${TILL_COMPACT}% till compact)")
  fi
else
  # Fallback: use tool-call counter if available
  if [ -f ".pilot/.tool-call-count" ]; then
    COUNT=$(cat ".pilot/.tool-call-count" 2>/dev/null || echo "0")
    if [ "$COUNT" -gt 0 ] 2>/dev/null; then
      # Rough estimate: 800 tool calls ≈ full context
      PCT=$((COUNT * 100 / 800))
      if [ "$PCT" -gt 100 ]; then PCT=100; fi
      COMPACT_PCT=75
      TILL_COMPACT=$((COMPACT_PCT - PCT))
      if [ "$TILL_COMPACT" -lt 0 ]; then TILL_COMPACT=0; fi

      BAR_WIDTH=20
      FILLED=$((PCT * BAR_WIDTH / 100))
      COMPACT_POS=$((COMPACT_PCT * BAR_WIDTH / 100))

      BAR=""
      for ((i=0; i<BAR_WIDTH; i++)); do
        if [ "$i" -eq "$COMPACT_POS" ]; then
          BAR="${BAR}|"
        elif [ "$i" -lt "$FILLED" ]; then
          BAR="${BAR}█"
        else
          BAR="${BAR}░"
        fi
      done

      if [ "$PCT" -ge "$COMPACT_PCT" ]; then
        PARTS+=("[${BAR}] ~${PCT}% ⚠ compact soon")
      else
        PARTS+=("[${BAR}] ~${PCT}% (~${TILL_COMPACT}% till compact)")
      fi
    fi
  fi
fi

# No pilot project detected
if [ ${#PARTS[@]} -eq 0 ]; then
  echo "Pilot"
  exit 0
fi

# Join with separator
IFS=" │ "
echo "${PARTS[*]}"

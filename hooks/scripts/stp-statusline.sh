#!/bin/bash
# STP v0.2.0: Statusline — colored project state + context usage
# Reads from disk + environment. Zero token cost. Fast (<50ms).

# Colors
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
WHITE='\033[97m'
RESET='\033[0m'

OUTPUT=""

# Version (blue)
if [ -f "VERSION" ]; then
  VER=$(cat VERSION 2>/dev/null)
  OUTPUT="${BLUE}v${VER}${RESET}"
fi

# Active feature + progress
if [ -f ".stp/current-feature.md" ]; then
  TITLE=$(head -1 ".stp/current-feature.md" | sed 's/^#* *//' | cut -c1-25)
  DONE=$(grep -c '\[x\]' ".stp/current-feature.md" 2>/dev/null || echo "0")
  TOTAL=$(grep -c '\[.\]' ".stp/current-feature.md" 2>/dev/null || echo "0")

  # Progress color: green if >50%, yellow if >0%, dim if 0%
  if [ "$TOTAL" -gt 0 ] && [ "$DONE" -gt 0 ]; then
    HALF=$((TOTAL / 2))
    if [ "$DONE" -ge "$HALF" ]; then
      PCOLOR="$GREEN"
    else
      PCOLOR="$YELLOW"
    fi
  else
    PCOLOR="$DIM"
  fi

  OUTPUT="${OUTPUT} ${DIM}│${RESET} ${BOLD}${WHITE}${TITLE}${RESET} ${PCOLOR}[${DONE}/${TOTAL}]${RESET}"
elif [ -f "PLAN.md" ]; then
  DONE=$(grep -c '\[x\]' "PLAN.md" 2>/dev/null || echo "0")
  TOTAL=$(grep -c '\[.\]' "PLAN.md" 2>/dev/null || echo "0")
  if [ "$TOTAL" -gt 0 ]; then
    OUTPUT="${OUTPUT} ${DIM}│${RESET} ${DIM}Plan ${GREEN}${DONE}${DIM}/${TOTAL}${RESET}"
  fi
fi

# Current milestone (cyan)
if [ -f "PLAN.md" ]; then
  MILESTONE=$(grep -B1 '\[ \]' "PLAN.md" 2>/dev/null | grep "^### Milestone" | head -1 | sed 's/^### Milestone [0-9]*: //' | cut -c1-20)
  if [ -n "$MILESTONE" ]; then
    OUTPUT="${OUTPUT} ${DIM}│${RESET} ${CYAN}${MILESTONE}${RESET}"
  fi
fi

# Context usage bar with compaction threshold
TOKENS_USED="${CLAUDE_CONTEXT_TOKENS_USED:-0}"
WINDOW_SIZE="${CLAUDE_CONTEXT_WINDOW_SIZE:-0}"

build_bar() {
  local PCT=$1
  local COMPACT_PCT=75
  local TILL_COMPACT=$((COMPACT_PCT - PCT))
  if [ "$TILL_COMPACT" -lt 0 ]; then TILL_COMPACT=0; fi

  # Bar color based on usage
  if [ "$PCT" -ge 75 ]; then
    BCOLOR="$RED"
  elif [ "$PCT" -ge 50 ]; then
    BCOLOR="$YELLOW"
  else
    BCOLOR="$GREEN"
  fi

  # Build visual bar (20 chars)
  local BAR_WIDTH=20
  local FILLED=$((PCT * BAR_WIDTH / 100))
  local COMPACT_POS=$((COMPACT_PCT * BAR_WIDTH / 100))
  local BAR=""

  for ((i=0; i<BAR_WIDTH; i++)); do
    if [ "$i" -eq "$COMPACT_POS" ]; then
      BAR="${BAR}${DIM}│${BCOLOR}"
    elif [ "$i" -lt "$FILLED" ]; then
      BAR="${BAR}█"
    else
      BAR="${BAR}${DIM}░${BCOLOR}"
    fi
  done

  local PREFIX="${2:-}"
  if [ "$PCT" -ge "$COMPACT_PCT" ]; then
    OUTPUT="${OUTPUT} ${DIM}│${RESET} ${BCOLOR}[${BAR}${RESET}${BCOLOR}]${RESET} ${RED}${PREFIX}${PCT}% ⚠ compact${RESET}"
  else
    OUTPUT="${OUTPUT} ${DIM}│${RESET} ${BCOLOR}[${BAR}${RESET}${BCOLOR}]${RESET} ${DIM}${PREFIX}${PCT}%${RESET} ${DIM}(${TILL_COMPACT}% left)${RESET}"
  fi
}

if [ "$WINDOW_SIZE" -gt 0 ] 2>/dev/null; then
  PCT=$((TOKENS_USED * 100 / WINDOW_SIZE))
  build_bar "$PCT" ""
else
  if [ -f ".stp/.tool-call-count" ]; then
    COUNT=$(cat ".stp/.tool-call-count" 2>/dev/null || echo "0")
    if [ "$COUNT" -gt 0 ] 2>/dev/null; then
      PCT=$((COUNT * 100 / 800))
      if [ "$PCT" -gt 100 ]; then PCT=100; fi
      build_bar "$PCT" "~"
    fi
  fi
fi

# Fallback
if [ -z "$OUTPUT" ]; then
  echo -e "${BLUE}Pilot${RESET}"
  exit 0
fi

echo -e "$OUTPUT"

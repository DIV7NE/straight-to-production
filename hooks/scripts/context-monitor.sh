#!/bin/bash
# Pilot: Context monitor
# Tracks tool call count as a proxy for context usage.
# Recommends /pilot:pause then /clear at logical breakpoints.
# Pilot has file-based state that survives /clear — no context is truly lost.

STATE_DIR=".pilot"
COUNTER_FILE="$STATE_DIR/.tool-call-count"

if [ ! -d "$STATE_DIR" ]; then
  exit 0
fi

if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER_FILE"

case $COUNT in
  200)
    echo "[Pilot ~25%] Update .pilot/current-feature.md — mark completed items [x]." >&2
    ;;
  350)
    echo "[Pilot ~40%] Good checkpoint. Commit work and update .pilot/current-feature.md." >&2
    echo "  Switching tasks? Run /pilot:pause then /clear for a fresh context." >&2
    ;;
  500)
    FEATURE=""
    if [ -f "$STATE_DIR/current-feature.md" ]; then
      FEATURE=$(head -1 "$STATE_DIR/current-feature.md" | sed 's/^#* *//')
    fi
    echo "[Pilot ~60%] Quality degrades from here. Time for a fresh start." >&2
    echo "  Run: /pilot:pause (writes handoff note) then /clear" >&2
    if [ -n "$FEATURE" ]; then
      echo "  Next session: 'Continue where I left off' — Pilot restores from disk." >&2
    fi
    echo "  Fresh 50K with sharp attention > 500K with diluted attention." >&2
    ;;
  650)
    echo "[Pilot ~80%] STOP. Run /pilot:pause then /clear NOW." >&2
    echo "  Auto-compact fires soon — lossy summary, you lose control." >&2
    echo "  /pilot:pause writes a proper handoff. /clear gives clean slate." >&2
    echo "  Everything is on disk. Nothing is lost." >&2
    ;;
esac

exit 0

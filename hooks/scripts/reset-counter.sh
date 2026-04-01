#!/bin/bash
# Pilot: Reset all counters
# Called on SessionStart (after /clear or compaction)

STATE_DIR=".pilot"

# Reset tool call counter
if [ -f "$STATE_DIR/.tool-call-count" ]; then
  echo "0" > "$STATE_DIR/.tool-call-count"
fi

# Reset prompt counter
if [ -f "$STATE_DIR/.prompt-count" ]; then
  echo "0" > "$STATE_DIR/.prompt-count"
fi

exit 0

#!/bin/bash
# Pilot: Post-edit TypeScript check
# Runs tsc --noEmit after .ts/.tsx file edits.
#
# For PreToolUse: exit 2 blocks the tool call.
# For PostToolUse: exit 2 does NOT block (action already happened).
# But stderr output IS shown to Claude as feedback.
#
# So we can't PREVENT the edit, but we can force Claude to see the errors
# and the Stop hook will BLOCK completion until they're fixed.

# Try to get file path from stdin JSON
if [ ! -t 0 ]; then
  INPUT=$(cat)
  FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' 2>/dev/null)
fi

# Fallback to env var
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${TOOL_INPUT_file_path:-${TOOL_INPUT_FILE_PATH:-}}"
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check TypeScript files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx)$ ]]; then
  exit 0
fi

if [ ! -f "tsconfig.json" ]; then
  exit 0
fi

# Run type check
ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep "error TS" | head -10)

if [ -n "$ERRORS" ]; then
  echo "Pilot: TypeScript errors after editing $FILE_PATH:" >&2
  echo "$ERRORS" >&2
  echo "Fix these. The Stop hook will BLOCK completion until tsc passes." >&2
fi

exit 0

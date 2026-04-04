#!/bin/bash
# STP: Start the visual whiteboard server
# Usage: bash start-whiteboard.sh [plugin_root] [project_dir] [port]

PLUGIN_ROOT="${1:-$(dirname "$(dirname "$(dirname "$0")")")}"
PROJECT_DIR="${2:-.}"
PORT="${3:-3333}"

SERVE_SCRIPT="$PLUGIN_ROOT/whiteboard/serve.py"

if [ ! -f "$SERVE_SCRIPT" ]; then
  echo "Error: Whiteboard server not found at $SERVE_SCRIPT"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required. Install Python 3 to use the whiteboard."
  exit 1
fi

echo "Starting STP Whiteboard..."
python3 "$SERVE_SCRIPT" "$PORT" "$PROJECT_DIR"

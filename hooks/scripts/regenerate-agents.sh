#!/usr/bin/env bash
# STP — Regenerate agents/*.md from templates with current profile's model assignments.
# Called on: first install, profile change (/stp:setup model), after Opus idiom refresh.
# Substitutes ${STP_MODEL_<NAME>} placeholders. Handles inherit/inline sentinels.

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
TEMPLATE_DIR="$PLUGIN_ROOT/references/agents"
OUT_DIR="$PLUGIN_ROOT/agents"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "[regenerate-agents] template dir not found: $TEMPLATE_DIR" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Resolve current profile's model assignments
RESOLVED=$(node "$PLUGIN_ROOT/references/model-profiles.cjs" resolve-all 2>/dev/null)
if [[ -z "$RESOLVED" ]]; then
  echo "[regenerate-agents] model-profiles.cjs resolve-all returned empty" >&2
  exit 1
fi

# Export STP_* env vars from resolver output (KEY=VALUE lines)
while IFS='=' read -r key value; do
  if [[ -n "$key" ]] && [[ "$key" == STP_* ]]; then
    export "$key=$value"
  fi
done <<< "$RESOLVED"

PROFILE="${STP_PROFILE:-unknown}"

# substitute_template TEMPLATE OUTPUT VAR_NAME AGENT_STUB_NAME
substitute_template() {
  local template="$1"
  local output="$2"
  local agent_var="$3"
  local agent_name="$4"
  local model="${!agent_var:-sonnet}"

  case "$model" in
    inline)
      # Agent disabled in this profile — remove file (prevents accidental spawn)
      rm -f "$output"
      echo "[regenerate-agents] $agent_name: inline (file removed)" >&2
      ;;
    inherit)
      # Omit model line; Claude Code inherits main-session model
      grep -v '^model: \${STP_MODEL_' "$template" > "$output" || cp "$template" "$output"
      # Also strip the placeholder if somehow missed
      sed -i.bak "s|^model: \${$agent_var}\$||g" "$output" 2>/dev/null || true
      rm -f "$output.bak"
      echo "[regenerate-agents] $agent_name: inherit" >&2
      ;;
    sonnet|opus|haiku)
      sed "s|\${$agent_var}|$model|g" "$template" > "$output"
      echo "[regenerate-agents] $agent_name: $model" >&2
      ;;
    *)
      echo "[regenerate-agents] $agent_name: unknown sentinel '$model' — falling back to sonnet" >&2
      sed "s|\${$agent_var}|sonnet|g" "$template" > "$output"
      ;;
  esac
}

substitute_template "$TEMPLATE_DIR/executor.md.template"   "$OUT_DIR/executor.md"   "STP_MODEL_EXECUTOR"   "stp-executor"
substitute_template "$TEMPLATE_DIR/critic.md.template"     "$OUT_DIR/critic.md"     "STP_MODEL_CRITIC"     "stp-critic"
substitute_template "$TEMPLATE_DIR/qa.md.template"         "$OUT_DIR/qa.md"         "STP_MODEL_QA"         "stp-qa"
substitute_template "$TEMPLATE_DIR/researcher.md.template" "$OUT_DIR/researcher.md" "STP_MODEL_RESEARCHER" "stp-researcher"
substitute_template "$TEMPLATE_DIR/explorer.md.template"   "$OUT_DIR/explorer.md"   "STP_MODEL_EXPLORER"   "stp-explorer"

echo "[regenerate-agents] Profile: $PROFILE — done" >&2
exit 0

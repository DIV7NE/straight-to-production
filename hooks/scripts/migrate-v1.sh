#!/usr/bin/env bash
# STP — v1.0 migration (one-shot). Runs on SessionStart after upgrade.
# Renames profiles, creates pace.json, triggers stack detection + agent regen.
# Idempotent — marker file prevents re-run.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || cd "${PWD}"

mkdir -p .stp/state
MARKER=".stp/state/.migrated-v1"

# Skip if already migrated
if [[ -f "$MARKER" ]]; then
  exit 0
fi

# === 1. Profile rename (pre-v1 → v1.0) ===
if [[ -f .stp/state/profile.json ]] && command -v jq > /dev/null 2>&1; then
  CURRENT=$(jq -r '.profile // "balanced"' .stp/state/profile.json 2>/dev/null || echo "balanced")
  NEW="$CURRENT"
  case "$CURRENT" in
    "intended-profile") NEW="opus-cto" ;;
    "balanced-profile") NEW="balanced" ;;
    "budget-profile")   NEW="opus-budget" ;;
    "sonnet-main")      NEW="sonnet-cheap" ;;
    "20-pro-plan")      NEW="pro-plan" ;;
  esac
  if [[ "$NEW" != "$CURRENT" ]]; then
    jq --arg new "$NEW" '.profile = $new' .stp/state/profile.json > .stp/state/profile.json.tmp
    mv .stp/state/profile.json.tmp .stp/state/profile.json
    echo "[STP v1.0] Migrated profile: $CURRENT → $NEW" >&2
  fi
fi

# === 2. Pace default ===
if [[ ! -f .stp/state/pace.json ]]; then
  PACE_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > .stp/state/pace.json <<EOF
{
  "pace": "batched",
  "set_at": "$PACE_AT",
  "set_by": "migrate-v1"
}
EOF
fi

# === 3. Old command names → new in handoff + state files ===
rewrite_commands() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # POSIX sed -i portability: write temp file then move
  sed \
    -e 's|/stp:new-project|/stp:setup new|g' \
    -e 's|/stp:onboard-existing|/stp:setup onboard|g' \
    -e 's|/stp:plan\b|/stp:think --plan|g' \
    -e 's|/stp:research\b|/stp:think --research|g' \
    -e 's|/stp:whiteboard\b|/stp:think --whiteboard|g' \
    -e 's|/stp:work-adaptive|/stp:build|g' \
    -e 's|/stp:work-full|/stp:build --full|g' \
    -e 's|/stp:work-quick|/stp:build --quick|g' \
    -e 's|/stp:autopilot\b|/stp:build --auto|g' \
    -e 's|/stp:continue\b|/stp:session continue|g' \
    -e 's|/stp:pause\b|/stp:session pause|g' \
    -e 's|/stp:progress\b|/stp:session progress|g' \
    -e 's|/stp:upgrade\b|/stp:setup upgrade|g' \
    -e 's|/stp:set-profile-model|/stp:setup model|g' \
    "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

rewrite_commands ".stp/state/handoff.md"
rewrite_commands ".stp/state/current-feature.md"
rewrite_commands ".stp/docs/CHANGELOG.md"

# === 4. Trigger stack detection ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/detect-stack.sh" ]]; then
  bash "$SCRIPT_DIR/detect-stack.sh" 2>/dev/null || true
fi

# === 5. Regenerate agents from templates ===
if [[ -x "$SCRIPT_DIR/regenerate-agents.sh" ]]; then
  bash "$SCRIPT_DIR/regenerate-agents.sh" 2>/dev/null || true
fi

# === 6. Write marker ===
touch "$MARKER"
echo "[STP v1.0] Migration complete." >&2

exit 0

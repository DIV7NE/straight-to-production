#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# STP Release Script — One command: bump, commit, tag, push, npm publish, gh release
#
# Usage:
#   ./scripts/release.sh patch "add npm distribution"
#   ./scripts/release.sh minor "new whiteboard command"
#   ./scripts/release.sh major "breaking state file format change"
#
# What it does (in order):
#   1. Pre-flight checks (clean tree, on main, tools available)
#   2. Bumps version in plugin.json + package.json
#   3. Generates CHANGELOG entry from git log since last tag
#   4. Commits + tags
#   5. Pushes to origin
#   6. Publishes to npm
#   7. Creates GitHub Release
#
# First time? Run `npm login` once before your first release.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()  { echo -e "${CYAN}  ► ${RESET}$1"; }
ok()    { echo -e "${GREEN}  ✓ ${RESET}$1"; }
warn()  { echo -e "${YELLOW}  ⚠ ${RESET}$1"; }
fail()  { echo -e "${RED}  ✗ ${RESET}$1"; exit 1; }

# ── Args ──────────────────────────────────────────────────────────────────────
BUMP_TYPE="${1:-}"
TITLE="${2:-}"

if [[ -z "$BUMP_TYPE" ]]; then
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${BOLD}  STP Release                                  ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo "  Usage: ./scripts/release.sh <bump> \"title\""
  echo ""
  echo "  Bump types:"
  echo "    patch   Bug fixes, perf, docs              (0.3.9 → 0.3.10)"
  echo "    minor   New commands, hooks, profiles       (0.3.9 → 0.4.0)"
  echo "    major   Breaking contract changes           (0.3.9 → 1.0.0)"
  echo ""
  echo "  Example:"
  echo "    ./scripts/release.sh patch \"fix whiteboard gate false positive\""
  echo "    ./scripts/release.sh minor \"add npm distribution\""
  echo ""
  exit 0
fi

if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  fail "Invalid bump type: $BUMP_TYPE (must be patch, minor, or major)"
fi

if [[ -z "$TITLE" ]]; then
  fail "Release title required. Usage: ./scripts/release.sh $BUMP_TYPE \"your title here\""
fi

# ── Resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

PLUGIN_JSON=".claude-plugin/plugin.json"
PACKAGE_JSON="package.json"
CHANGELOG="CHANGELOG.md"

# ── Pre-flight checks ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${BOLD}  STP Release — Pre-flight                     ${RESET}${CYAN}║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${RESET}"
echo ""

# Must be on main
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != "main" ]]; then
  fail "Must be on main branch (currently on: $BRANCH)"
fi
ok "On main branch"

# Must have clean working tree (except untracked files)
if [[ -n "$(git diff --cached --name-only)" ]]; then
  fail "Staged changes exist. Commit or stash first."
fi
if [[ -n "$(git diff --name-only)" ]]; then
  fail "Unstaged changes exist. Commit or stash first."
fi
ok "Clean working tree"

# Must have required tools
command -v npm >/dev/null  || fail "npm not found"
command -v gh >/dev/null   || fail "gh CLI not found (install: https://cli.github.com)"
npm whoami &>/dev/null     || fail "Not logged into npm. Run: npm login"
ok "Tools available (npm, gh, npm auth)"

# ── Read current version ──────────────────────────────────────────────────────
CURRENT=$(grep -m1 '"version"' "$PLUGIN_JSON" | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
if [[ -z "$CURRENT" ]]; then
  fail "Could not read version from $PLUGIN_JSON"
fi

# ── Compute new version ──────────────────────────────────────────────────────
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$BUMP_TYPE" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"
DATE=$(date +%Y-%m-%d)

info "Version: ${BOLD}v${CURRENT}${RESET} → ${BOLD}v${NEW}${RESET}"
info "Title: ${TITLE}"
info "Type: ${BUMP_TYPE}"
echo ""

# ── Get commits since last tag ────────────────────────────────────────────────
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
  COMMITS=$(git log --oneline "${LAST_TAG}..HEAD" 2>/dev/null || echo "")
else
  COMMITS=$(git log --oneline -20 2>/dev/null || echo "")
fi

# ── Generate CHANGELOG entry ─────────────────────────────────────────────────
ENTRY="## [${NEW}] — ${DATE} — ${TITLE}

### Summary

${TITLE}.

### Changes

$(echo "$COMMITS" | sed 's/^/- /' | head -20)
"

# ── Confirm ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}┌─── CHANGELOG entry ────────────────────────────┐${RESET}"
echo "$ENTRY" | sed 's/^/  /'
echo -e "${CYAN}└────────────────────────────────────────────────┘${RESET}"
echo ""

read -p "  Proceed with release v${NEW}? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  warn "Release cancelled."
  exit 0
fi
echo ""

# ── Step 1: Bump versions ────────────────────────────────────────────────────
info "Bumping versions..."

# plugin.json
sed -i "s/\"version\": \"${CURRENT}\"/\"version\": \"${NEW}\"/" "$PLUGIN_JSON"
ok "plugin.json: ${CURRENT} → ${NEW}"

# package.json
sed -i "s/\"version\": \"${CURRENT}\"/\"version\": \"${NEW}\"/" "$PACKAGE_JSON"
ok "package.json: ${CURRENT} → ${NEW}"

# VERSION file (if exists)
if [[ -f "VERSION" ]]; then
  echo "$NEW" > VERSION
  ok "VERSION: ${NEW}"
fi

# ── Step 2: Update CHANGELOG ─────────────────────────────────────────────────
info "Updating CHANGELOG..."

if [[ -f "$CHANGELOG" ]]; then
  # Insert after the first line that starts with "# " (the title)
  # Find the line number of the first "## [" entry
  FIRST_ENTRY_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -1 | cut -d: -f1)

  if [[ -n "$FIRST_ENTRY_LINE" ]]; then
    # Insert before the first existing entry
    head -n $((FIRST_ENTRY_LINE - 1)) "$CHANGELOG" > "${CHANGELOG}.tmp"
    echo "$ENTRY" >> "${CHANGELOG}.tmp"
    tail -n +${FIRST_ENTRY_LINE} "$CHANGELOG" >> "${CHANGELOG}.tmp"
    mv "${CHANGELOG}.tmp" "$CHANGELOG"
  else
    # No existing entries, just append
    echo "" >> "$CHANGELOG"
    echo "$ENTRY" >> "$CHANGELOG"
  fi
else
  # Create new CHANGELOG
  cat > "$CHANGELOG" << HEADER
# Changelog

All notable changes to STP are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

${ENTRY}
HEADER
fi
ok "CHANGELOG.md updated"

# ── Step 3: Commit + tag ─────────────────────────────────────────────────────
info "Committing..."

git add "$PLUGIN_JSON" "$PACKAGE_JSON" "$CHANGELOG"
[[ -f "VERSION" ]] && git add VERSION

# Also stage any other tracked changes (new files from this release cycle)
git add -u

git commit -m "$(cat <<EOF
release(v${NEW}): ${TITLE}

Bump ${BUMP_TYPE} version: ${CURRENT} → ${NEW}
EOF
)"
ok "Committed"

git tag -a "v${NEW}" -m "STP v${NEW} — ${TITLE}"
ok "Tagged v${NEW}"

# ── Step 4: Push ──────────────────────────────────────────────────────────────
info "Pushing to origin..."

git push origin main
git push origin "v${NEW}"
ok "Pushed commits + tag"

# ── Step 5: npm publish ──────────────────────────────────────────────────────
info "Publishing to npm..."

npm publish
ok "Published stp-cc@${NEW} to npm"

# ── Step 6: GitHub Release ───────────────────────────────────────────────────
info "Creating GitHub Release..."

gh release create "v${NEW}" \
  --title "STP v${NEW} — ${TITLE}" \
  --notes "$(cat <<EOF
${ENTRY}

---

**Install / Update:**
\`\`\`bash
npx stp-cc@latest
\`\`\`
EOF
)"
ok "GitHub Release created"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${GREEN}  ✓ STP v${NEW} released ${RESET}${CYAN}║${RESET}"
echo -e "${CYAN}╠───────────────────────────────────────────────╣${RESET}"
echo -e "${CYAN}║${RESET}  git: v${CURRENT} → v${NEW} (${BUMP_TYPE})               ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  npm: stp-cc@${NEW}                        ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  gh:  github.com/DIV7NE/straight-to-production/releases      ${CYAN}║${RESET}"
echo -e "${CYAN}╠───────────────────────────────────────────────╣${RESET}"
echo -e "${CYAN}║${RESET}  Users update with:                         ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}    ${BOLD}npx stp-cc@latest${RESET}                        ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}    ${BOLD}/stp:upgrade${RESET}                              ${CYAN}║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${RESET}"
echo ""

---
description: "Finalize a release. Preflight → version bump → CHANGELOG → git tag → GitHub release → optional publish + deploy hook. Leaves actual deploy to your CI. Zero external services beyond gh (free tier)."
argument-hint: patch | minor | major [--dry-run] [--skip-publish]
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort:** `high` — /stp:ship is an orchestrator, not a deep-reasoning skill. Don't escalate to `xhigh` unless a preflight failure requires analysis.

# STP: Ship

Cuts a release: preflight → version → CHANGELOG finalize → commit → tag → GitHub release → optional publish (npm / crates / PyPI) → optional deploy hook.

**Free-to-use at runtime:** uses the user's existing `gh` CLI auth (GitHub free tier). No paid APIs. Publish steps are always opt-in per release and run the user's local toolchain (`npm publish`, `cargo publish`, etc.) — nothing uploaded to STP servers.

**Scope:** `/stp:ship` handles the release ritual. It does NOT replace your CI — actual deploys happen via your existing GitHub Actions / Vercel / fly.io pipeline, which ship triggers by pushing the tag. If you have a project-local `.stp/deploy.sh` or `scripts/deploy.sh`, ship can invoke it after the GitHub release is published.

## Shared opening

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
STACK=$(jq -r '.stack // "generic"' .stp/state/stack.json 2>/dev/null || echo "generic")
TEST_CMD=$(jq -r '.test_cmd // ""' .stp/state/stack.json 2>/dev/null || echo "")
```

## Flag parsing

```bash
BUMP=""
DRY_RUN=false
SKIP_PUBLISH=false
for arg in $ARGUMENTS; do
  case "$arg" in
    patch|minor|major) BUMP="$arg" ;;
    --dry-run)         DRY_RUN=true ;;
    --skip-publish)    SKIP_PUBLISH=true ;;
  esac
done
```

If `$BUMP` is empty: AskUserQuestion — `patch (Recommended) | minor | major | cancel`.

`--dry-run` runs preflight + shows the release notes preview, then stops before any git/gh action. Nothing is mutated. Use before a real ship.

## Step 1 — Preflight (every gate must pass; halt on failure)

Gates are deterministic, runnable in parallel. Collect results into a table and present before any destructive action.

| Gate | Command | Pass |
|------|---------|------|
| Branch | `git branch --show-current` | equals `main` (or user-configured default) |
| Uncommitted | `git status --porcelain \| wc -l` | equals 0 |
| Remote sync | `git rev-list --count HEAD..@{upstream}` | equals 0 (no commits behind) |
| VERSION sane | `grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION` | matches |
| CHANGELOG unreleased | `grep -c '^## \[Unreleased\]' .stp/docs/CHANGELOG.md` | ≥ 1 |
| Tests pass | `$TEST_CMD` (from stack.json) | exit code 0 |
| `gh` auth | `gh auth status` | "Logged in" |

Fallbacks:
- If `VERSION` file doesn't exist but `package.json` has `.version` — use that.
- If `CHANGELOG.md` is at root (not `.stp/docs/`) — use the root one.
- If `$TEST_CMD` is empty (no stack-specific test runner configured) — warn but don't block. Solo devs sometimes ship without tests; STP notes the gap and continues.

Present the gate table to the user. If any FAIL: AskUserQuestion — `Abort (Recommended) | Override specific gate | Cancel`.

**Overrides must be logged into the release note.** If the user overrides the `Tests pass` gate, the release body gets a `## ⚠ Overrides used` section listing what was bypassed. This leaves an audit trail in the GitHub release — future you reading the release page knows exactly which gates were skipped.

## Step 2 — Finalize VERSION

Compute new version from current + bump type:

```bash
CUR=$(cat VERSION 2>/dev/null || jq -r .version package.json 2>/dev/null)
IFS=. read -r MAJOR MINOR PATCH <<< "$CUR"
case "$BUMP" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac
NEW="${MAJOR}.${MINOR}.${PATCH}"
```

Write back:
- Always update `VERSION` if it exists
- Update `package.json` `.version` if present (via `jq` or `node -e`)
- Update `Cargo.toml` `[package] version` if present
- Update `pyproject.toml` `[project] version` or `[tool.poetry] version` if present
- Update `.claude-plugin/plugin.json` `.version` if the project IS STP itself (repo name check)

## Step 3 — Finalize CHANGELOG

If `## [Unreleased]` exists:
```
sed -i "s/^## \[Unreleased\]$/## [${NEW}] — $(date +%Y-%m-%d) — ${TITLE}/" .stp/docs/CHANGELOG.md
```
Where `${TITLE}` comes from either `$ARGUMENTS` (freeform quoted text after the bump type) or AskUserQuestion asking for the release title.

If `## [Unreleased]` does NOT exist: generate a stub from `git log $LAST_TAG..HEAD --oneline` and prepend it as `## [${NEW}] — ...`. Ask user to review before continuing.

## Step 4 — Commit

```bash
git add VERSION package.json Cargo.toml pyproject.toml .claude-plugin/plugin.json .stp/docs/CHANGELOG.md 2>/dev/null
git commit -m "$(cat <<COMMIT_EOF
release(v${NEW}): ${TITLE}

${ONE_LINE_SUMMARY from CHANGELOG}

🤖 Generated with Claude Code — /stp:ship
COMMIT_EOF
)"
```

## Step 5 — Tag

```bash
git tag -a "v${NEW}" -m "${TITLE}"
```

## Step 6 — Push

```bash
git push origin "$(git branch --show-current)"
git push origin "v${NEW}"
```

## Step 7 — GitHub release

Extract the release body from the CHANGELOG entry:

```bash
# Extract the v${NEW} section up to the next ## [ heading
awk "/^## \[${NEW}\]/,/^## \[/" .stp/docs/CHANGELOG.md \
  | sed '$d' > /tmp/release-notes.md

gh release create "v${NEW}" --title "v${NEW} — ${TITLE}" --notes-file /tmp/release-notes.md
```

If any preflight gates were overridden, append an `## ⚠ Overrides used` section to `/tmp/release-notes.md` before calling `gh release create`.

## Step 8 — Publish offer (stack-aware, opt-in)

Detect publish-capable manifests:

```bash
OFFER=""
if [ -f package.json ] && [ "$(jq -r '.private // false' package.json)" != "true" ]; then
  OFFER="$OFFER npm"
fi
if [ -f Cargo.toml ] && grep -q '^\[package\]' Cargo.toml; then
  OFFER="$OFFER cargo"
fi
if [ -f pyproject.toml ] && grep -qE '^\[project\]|^\[tool\.poetry\]' pyproject.toml; then
  OFFER="$OFFER pypi"
fi
```

If `--skip-publish` was passed OR `$OFFER` is empty: skip this step silently.

Otherwise AskUserQuestion with the detected options:
- `(Recommended) Skip publish` — always first
- `Publish to npm` — if detected
- `Publish to crates.io` — if detected
- `Publish to PyPI` — if detected
- `Cancel` (return without publishing — tag + release are already done)

On selection: run the actual command (`npm publish`, `cargo publish`, `python -m build && twine upload dist/*`). Capture output. If it fails, log the error but don't rollback the tag/release — the user can retry publish manually.

## Step 9 — Deploy hook (optional)

Check for a user-owned deploy script:
```bash
DEPLOY_HOOK=""
[ -f .stp/deploy.sh ] && DEPLOY_HOOK=".stp/deploy.sh"
[ -z "$DEPLOY_HOOK" ] && [ -f scripts/deploy.sh ] && DEPLOY_HOOK="scripts/deploy.sh"
```

If found, AskUserQuestion: `Run $DEPLOY_HOOK (Recommended) | Skip | Cancel`.

On run: `VERSION=${NEW} bash $DEPLOY_HOOK` (pass the new version via env). Stream output. Don't rollback on failure.

If no deploy hook: silently skip. Deploy is not STP's responsibility.

## Step 10 — Completion box

```
╔═══════════════════════════════════════════════════════════════╗
║  ✓ SHIPPED v[NEW] — [TITLE]                                   ║
╠═══════════════════════════════════════════════════════════════╣
║  Tag:     v[NEW]                                              ║
║  Release: [gh release URL]                                    ║
║  Branch:  [branch] (pushed)                                   ║
║  Publish: [npm/cargo/pypi or "skipped"]                       ║
║  Deploy:  [hook path or "no hook found"]                      ║
║                                                               ║
║  Warnings (if any):                                           ║
║  - [e.g. "Tests gate overridden — logged in release notes"]   ║
║                                                               ║
║  ► Next: /clear, then /stp:build [NEXT FEATURE]               ║
║         (CHANGELOG for this version is now final on disk —    ║
║          the next build adds a fresh ## [Unreleased] block.)  ║
╚═══════════════════════════════════════════════════════════════╝
```

## --dry-run mode

Runs steps 1-3 only, then stops. Prints:
- The preflight gate table (pass/fail per gate)
- The computed new version
- The release notes preview (what would go into `gh release create`)
- What would be published/deployed

Nothing is committed, tagged, or pushed. Nothing on GitHub changes. Use this before a real ship to sanity-check.

## Gotchas

- **`/stp:ship` on the STP plugin itself:** it's self-bootstrapping. The plugin's own package.json `.version` + `.claude-plugin/plugin.json` `.version` + `.claude-plugin/marketplace.json` plugins[0].version all need to stay in sync. Step 2 handles all three when the repo name is `straight-to-production`.
- **`gh` not logged in:** step 1 gate catches this. Install with `gh auth login` and retry.
- **Protected main branch:** `git push origin main` fails with `(protected branch hook declined)`. The user's GitHub settings require PRs to main. Solution: push to a release branch, open a PR, merge, then tag after merge. The skill can't fully automate this — it prompts the user to do it manually and resumes after the merge lands.
- **Uncommitted submodule changes:** git status --porcelain reports them. Treat as uncommitted; gate fails. User must commit/stash in the submodule first.
- **Windows line endings in CHANGELOG:** the `sed -i` command works on Git Bash. If you're in a plain cmd.exe shell: use Git Bash or WSL.
- **Publish + 2FA:** `npm publish` with 2FA enabled prompts interactively. The skill can't bypass that — it streams the prompt to the user's terminal, user types OTP, the skill waits.

## What /stp:ship explicitly does NOT do

- **Run your CI pipeline.** Pushing the tag triggers whatever CI hooks the user has set up (GitHub Actions, etc.). STP doesn't manage those.
- **Auto-publish to a registry.** Every publish step is opt-in, AskUserQuestion.
- **Rollback a failed release.** If something fails after the tag is pushed, you manually delete the tag/release. STP tells you where to look; it doesn't undo.
- **Generate release notes from scratch.** The CHANGELOG entry is the source of truth. If `## [Unreleased]` is empty, the release notes will be empty — fix by writing the CHANGELOG first.

---
description: Upgrade STP to the latest version. Pulls the latest from GitHub, syncs companion plugins, updates project CLAUDE.md sections, refreshes hooks, and shows what changed. One command brings everything up to date.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "AskUserQuestion"]
---

> **Recommended effort: `/effort low`** — Mechanical upgrade process, no deep thinking needed.

# STP: Upgrade

Pull the latest version of STP from GitHub and sync EVERYTHING in the current project. This is the single command that brings any STP-managed project fully up to date.

## What Gets Upgraded

| Layer | What | How |
|-------|------|-----|
| **Plugin code** | Commands, agents, hooks, references, templates, whiteboard | Auto-update (git pull, or download + overwrite for marketplace) |
| **Agent prompts** | Critic (Claim Verification Gate), executor, QA | Part of plugin code — auto-updated via `git pull` |
| **Companion plugins** | ui-ux-pro-max and any future required plugins | Auto-install if missing |
| **Project CLAUDE.md** | Philosophy, Required Plugins, Key Rules, Hooks, Directory Map | Refresh STP sections, preserve user's Project Conventions |
| **Global CLAUDE.md** | STP version marker + STP Awareness section | Refresh STP block only |
| **Stop-verify hook** | New enforcement gates (e.g., placeholder scanning) | Hook reads from plugin dir — auto-updated |
| **Project layout** | Old flat layout → organized .stp/docs/ + .stp/state/ | Migration script |

## Process

### Step 1: Update Plugin Code (auto-detects install type)

```bash
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"
```

**Detect install type and update accordingly:**

```bash
if [ -f "$PLUGIN_DIR/.install-manifest.json" ]; then
  echo "install_type: npm"
  # npm-managed install — delegate to npx
  echo "Running npx stp-cc@latest..."
  npx stp-cc@latest
  # npx handles: file copy, manifest update, statusline registration, local patch backup
  # After npx completes, skip to Step 3 (companion plugins) — Steps 2 and 5.5-6 are handled by the installer
elif [ -L "$PLUGIN_DIR" ]; then
  echo "install_type: symlink (developer mode)"
  # Symlink to dev repo — pull from the actual repo
  REAL_DIR=$(readlink -f "$PLUGIN_DIR")
  cd "$REAL_DIR" && git pull origin main 2>/dev/null
elif [ -d "$PLUGIN_DIR/.git" ]; then
  echo "install_type: git clone"
  cd "$PLUGIN_DIR" && git pull origin main
else
  echo "install_type: marketplace (flat copy)"
fi
```

**For each install type:**

**Git repo or symlink → `git pull`:**
```bash
CURRENT=$(cd "$PLUGIN_DIR" && git rev-parse --short HEAD 2>/dev/null)
# pull already done above
NEW_HEAD=$(cd "$PLUGIN_DIR" && git rev-parse --short HEAD 2>/dev/null)
```
Show what changed: `git log --oneline "$CURRENT".."$NEW_HEAD"`

**CRITICAL — capture metadata for the restart-required banner:**
```bash
# 1. Did any hook file change between old and new HEAD?
#    (used to decide whether the restart banner is "mandatory" or "recommended")
HOOK_CHANGED_FILES=$(cd "$PLUGIN_DIR" && git diff --name-only "$CURRENT".."$NEW_HEAD" 2>/dev/null | grep -E "^(hooks/|\.claude-plugin/plugin\.json)" | head -20)

# 2. How many hook files changed?
HOOK_CHANGE_COUNT=$(echo "$HOOK_CHANGED_FILES" | grep -c . 2>/dev/null || echo 0)

# 3. Detect if any PreToolUse / PostToolUse / SessionStart entries in hooks.json changed
HOOKS_JSON_CHANGED=0
if echo "$HOOK_CHANGED_FILES" | grep -q "hooks/hooks.json"; then
  HOOKS_JSON_CHANGED=1
fi

echo "HOOK_CHANGE_COUNT=$HOOK_CHANGE_COUNT"
echo "HOOKS_JSON_CHANGED=$HOOKS_JSON_CHANGED"
echo "HOOK_CHANGED_FILES:"
echo "$HOOK_CHANGED_FILES" | sed 's/^/  /'
```

Capture these values — Step 9's completion banner uses them to decide how loud the restart warning is.

**Also capture the new CHANGELOG entry for the "What's new" section:**
```bash
NEW_VER=$(grep -m1 '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
echo "NEW_VER=$NEW_VER"
```

After capturing, **Read the new CHANGELOG.md** with the Read tool (not grep — you need the full narrative) and locate the `## [NEW_VER]` section. Extract:
- The one-line version tagline (first line after the version heading)
- The `### Summary` paragraph (if present)
- Top 3-5 items from `### Added` / `### Changed` / `### Fixed`
- Any **CRITICAL** or **IMPORTANT** markers in the section

This becomes the "What's new" body in the Step 9 completion box — NOT a placeholder, NOT 2-3 sentences, but an actual faithful summary of what the user is now running. Read real content from the file; don't paraphrase from memory.

**Marketplace install (no .git) → download and overwrite in place:**

No manual steps. No uninstall/reinstall. Just download the latest and swap.

```bash
TEMP_DIR=$(mktemp -d)
OLD_VER=$(cat "$PLUGIN_DIR/VERSION" 2>/dev/null || echo "unknown")

git clone --depth 1 --branch main https://github.com/DIV7NE/straight-to-production.git "$TEMP_DIR/stp" 2>&1
if [ $? -eq 0 ]; then
  rm -rf "$TEMP_DIR/stp/.git"
  # Safe swap: backup → replace → verify → cleanup backup
  cp -r "$PLUGIN_DIR" "${PLUGIN_DIR}.bak"
  find "$PLUGIN_DIR" -mindepth 1 -delete 2>/dev/null
  cp -a "$TEMP_DIR/stp/." "$PLUGIN_DIR/"
  chmod +x "$PLUGIN_DIR/hooks/scripts/"*.sh 2>/dev/null
  NEW_VER=$(cat "$PLUGIN_DIR/VERSION" 2>/dev/null || echo "unknown")
  rm -rf "$TEMP_DIR" "${PLUGIN_DIR}.bak"
  echo "upgrade: $OLD_VER → $NEW_VER"
else
  rm -rf "$TEMP_DIR"
  echo "upgrade: FAILED — network error"
  echo "Manual fallback: /plugin uninstall stp && /plugin install stp@pilot-dev"
fi
```

If the download fails, show the manual fallback as a one-liner — not a multi-step process. Do NOT use AskUserQuestion for the plugin update itself.

Regardless of install type, still run all remaining sync steps — the project may be behind even if the plugin is current.

### Step 2: Run Layout Migration

Migrate old flat layout → organized .stp/docs/ + .stp/state/ (idempotent, safe to re-run):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/migrate-layout.sh"
```

### Step 3: Quick Companion Check

Companion plugins and MCP servers are fully verified by `/stp:welcome`. Upgrade only does a quick status check — no installs, no prompts:

```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```

Report status in the upgrade summary. If anything is missing, note: "Run `/stp:welcome` to verify and install companion plugins."

### Step 4: Sync Project CLAUDE.md (CAREFUL — never destroy user content)

The project CLAUDE.md contains both STP-managed sections AND user-written sections. The upgrade MUST preserve ALL user content while refreshing ONLY STP content.

**Read the current project CLAUDE.md:**
```bash
[ -f "CLAUDE.md" ] && echo "project_claude: exists" || echo "project_claude: none"
```

#### Section Ownership Model

STP uses HTML comment markers to delimit its managed sections. Every STP section is wrapped in:
```
<!-- STP:section-name:start -->
[STP-managed content]
<!-- STP:section-name:end -->
```

**STP-OWNED sections (will be refreshed on upgrade):**
| Marker ID | Section |
|-----------|---------|
| `stp-header` | Title + version + architecture description |
| `stp-confirmation-gate` | Pre-Work Confirmation Gate — MANDATORY AskUserQuestion before any STP work |
| `stp-subagent-cost` | Subagent Cost Discipline — STRICTLY ENFORCED model="sonnet" on all Agent() calls |
| `stp-profile-aware` | Profile-Aware Execution — MANDATORY model resolution for every sub-agent spawn (added v0.3.8) |
| `stp-philosophy` | Philosophy (NON-NEGOTIABLE) — production-only rules |
| `stp-plugins` | Required Companion Plugins table |
| `stp-commands` | Commands list |
| `stp-rules` | Key Rules list |
| `stp-dirmap` | Directory Map tables |
| `stp-memory` | Memory Strategy |
| `stp-statusline` | Statusline description |
| `stp-hooks` | Hooks enforcement gates |
| `stp-research` | Research sources reference |
| `stp-effort` | Effort Levels mapping |
| `stp-output-format` | CLI Output Formatting rules + reference pointer |

**USER-OWNED sections (NEVER touched by upgrade — not even read-and-rewrite):**
- `## Project Conventions` — earned through decisions, bugs, and Critic findings
- `## Standards Index` — project-specific reference file paths
- Any content OUTSIDE of `<!-- STP:*:start/end -->` markers
- Any `## ` heading that doesn't match an STP section name
- Comments, notes, or rules the user added anywhere

**The golden rule: if it's not inside STP markers, DON'T TOUCH IT.**

#### Refresh Algorithm

1. **Read** the entire current CLAUDE.md into memory
2. **For each STP-owned section** (from the table above):
   a. Search for `<!-- STP:section-name:start -->` and `<!-- STP:section-name:end -->`
   b. If found: **replace** everything between the markers with the fresh content from the plugin's canonical CLAUDE.md. Keep the markers.
   c. If NOT found: this section was added in a newer STP version. **Append** it at the logical position (after the last existing STP section, before user sections).
3. **Update** the version marker: `<!-- STP v[NEW_VER] -->`
4. **Write** the merged file back

**CRITICAL: Before writing, diff the old and new content. Show the user what changed:**
```
STP sections refreshed in CLAUDE.md:
  [updated] Philosophy — added "no incomplete output", "override simplification bias"
  [updated] Hooks — added gate #7 (placeholder/mock pattern scanning)
  [added]   Required Companion Plugins — new section
  [unchanged] Project Conventions — preserved (14 rules)
  [unchanged] Standards Index — preserved
  [unchanged] [any other user sections] — preserved
```

#### If project CLAUDE.md has NO STP markers (legacy)

This project was set up before marker-based sections. The ENTIRE file is treated as user content. Handle automatically — no question needed:

1. Read the existing file (all user content preserved at the top)
2. Append all STP marker-wrapped sections at the end
3. Report: "Added STP section markers to CLAUDE.md. Your existing content is preserved above."

This is always safe and reversible — the user's content stays untouched, STP sections go at the bottom with markers for future upgrades.

#### If NO project CLAUDE.md exists

This project hasn't been onboarded. Note: "No project CLAUDE.md found. Run `/stp:onboard-existing` to fully set up this project, or `/stp:new-project` to start fresh."

### Step 5: Sync Global CLAUDE.md

```bash
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
[ -f "$GLOBAL_CLAUDE" ] && echo "global_claude: exists" || echo "global_claude: none"
```

If global CLAUDE.md exists, check for the STP Awareness section and update it:

```bash
grep -q "## STP Awareness" "$GLOBAL_CLAUDE" && echo "stp_awareness: exists" || echo "stp_awareness: MISSING"
```

**If STP Awareness section exists:** refresh it with the latest version from the plugin's CLAUDE.md.

**If STP Awareness section is MISSING:** append the STP Awareness block:
```markdown
## STP Awareness
When working in STP-onboarded projects (identified by `.stp/` directory):
- Read `.stp/docs/CONTEXT.md` for quick project overview before making changes
- Read `.stp/docs/ARCHITECTURE.md` for full codebase map when touching unfamiliar areas
- Check `.stp/docs/AUDIT.md` for known production issues before investigating bugs
- Use `/stp:build` for feature work, `/stp:continue` after context resets
- STP documents supplement (not replace) GSD workflow — both can coexist
```

### Step 5.5: Refresh Reference Files

Re-run `setup-references.sh` to deploy any new or updated reference files (like `cli-output-format.md`) to the project's `.stp/references/`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

This ensures new reference files added in later STP versions get deployed to existing projects. The script is idempotent — it overwrites existing files and creates new directories as needed.

### Step 6: Verify Hooks Are Active

STP hooks are defined in the plugin's `hooks.json` and loaded automatically by Claude Code from the plugin directory. No project-level copy needed. But verify they're functioning:

```bash
# Verify hook scripts exist and are executable
for script in stop-verify.sh post-edit-check.sh pre-compact-save.sh session-restore.sh migrate-layout.sh stp-statusline.sh; do
  [ -x "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/$script" ] && echo "$script: OK" || echo "$script: MISSING/NOT EXECUTABLE"
done

# Verify statusline JS (the actual statusline engine)
[ -f "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-statusline.js" ] && echo "stp-statusline.js: OK" || echo "stp-statusline.js: MISSING"
```

If any are missing or not executable, fix:
```bash
chmod +x "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/"*.sh
```

If `stp-statusline.js` is MISSING → warn: "STP statusline script not found. The status bar won't display project info. The plugin installation may be incomplete — try reinstalling."

### Step 7: Local Patches (npm installs only)

If the install type is `npm` (detected in Step 1), the installer automatically backs up user-modified files to `~/.stp-local-patches/` before overwriting. No manual action needed — just note in the summary: `[✓] Local patches: handled by installer`.

For git/marketplace installs, skip this step — there's no patch tracking.

### Step 8: Migrate Project Docs (if outdated format detected)

Check if existing project docs need format migration:

**PRD.md format check:**
```bash
[ -f ".stp/docs/PRD.md" ] && grep -q "Given.*When.*Then\|SHALL\|MUST NOT" .stp/docs/PRD.md 2>/dev/null && echo "prd_format: structured" || echo "prd_format: legacy_freeform"
```

If `prd_format: legacy_freeform` — the PRD uses old freeform acceptance criteria ("AC: user can log in") instead of structured Given/When/Then scenarios with RFC 2119 keywords.

```
AskUserQuestion(
  question: "Your PRD.md uses the old freeform format. STP now uses structured specs (Given/When/Then + SHALL/MUST/SHOULD) for testable acceptance criteria. Want me to migrate?",
  options: [
    "(Recommended) Migrate now — convert existing ACs to structured scenarios. I'll preserve all requirements, just restructure the format.",
    "Skip — I'll migrate manually later. New features will use the new format, old ones keep freeform.",
    "Chat about this"
  ]
)
```

If migrating: read each freeform AC, convert to Given/When/Then with appropriate RFC 2119 keyword, preserve intent.

**System Constraints section check:**
```bash
[ -f ".stp/docs/PRD.md" ] && grep -q "## System Constraints" .stp/docs/PRD.md 2>/dev/null && echo "constraints_section: exists" || echo "constraints_section: MISSING"
```

If MISSING → append `## System Constraints` section to PRD.md (empty, ready for delta merge-back to populate).

**Command name migration note:**
If the CHANGELOG or any state files reference old command names (`/stp:quick`, `/stp:work`), note:
```
Commands renamed in this version:
  /stp:quick  →  /stp:work-quick
  /stp:work   →  /stp:work-full
  NEW: /stp:work-adaptive (impact scan → auto-routes to quick or full)
```

**Structural changes (v0.4.0 token optimization):**
Surface these to the user if upgrading from pre-v0.4.0:
```
Token optimization changes in this version:

  CLAUDE.md           34.7KB → 19.1KB (compressed index + on-demand refs)
  work-full.md        1027 → 90 lines (6 phase files loaded on demand)
  work-quick.md       932 → 65 lines (4 step files loaded on demand)
  critic.md           392 → 128 lines (all 7 criteria preserved)
  cli-output-format   380 → 79 lines (table specs, not full examples)
  set-profile-model   108 → 82 lines (now shows quality/cost/tradeoffs)

  Default profile     intended → balanced (~50% Opus savings)
  New profile          sonnet-main (no Opus needed, ~85% cheaper)
  New flags            --skip-research, --skip-qa (work-quick)
                       --section-approval (work-full Phase 5)
  New rule             model="sonnet" enforced on all Agent() calls
  Statusline           shows version + commit count when update available
  Phase 5              batch approval by default (1 prompt, not 13)

  Extracted to references/:
    agent-teams-vs-subagents.md, companion-plugins.md,
    gate-audit.md, shared/stp-section-markers.md,
    shared/companion-plugin-checks.md
```

### Step 8b: Profile Migration (if upgrading from pre-v0.4.0)

Check the current profile and whether the user is aware of the new default + new profiles:

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current
```

**If `intended-profile` is active AND the previous STP version was < 0.4.0** (check from CHANGELOG or old VERSION):

The default changed from `intended-profile` to `balanced-profile` in v0.4.0 for token efficiency (~50% Opus savings). The user's explicit choice is preserved — they stay on `intended` — but inform them:

```
AskUserQuestion(
  question: "STP v0.4.0 changed the default profile from intended to balanced (50% cheaper, ~95% quality). Your project is on intended-profile (preserved from before the upgrade). A new sonnet-main profile is also available (no Opus needed, ~85% cheaper). Want to review profiles?",
  header: "Profile",
  options: [
    "(Recommended) Switch to balanced-profile — best cost/quality ratio for most work",
    "Stay on intended-profile — I want maximum quality, cost is fine",
    "Show me all profiles — run /stp:set-profile-model to compare",
    "Skip — I'll decide later"
  ]
)
```

If they pick "Switch to balanced": `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set balanced --raw`
If they pick "Show me all profiles": `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" all-tables`
If they pick "Stay" or "Skip": no change, continue to Step 9.

**If `balanced-profile` or `budget-profile` is active:** no action needed — they're already on an efficient profile. Just note in the upgrade report: `Profile: [current] (no change needed)`.

**If no profile.json exists** (fresh project or pre-profile STP): the new default (`balanced-profile`) will apply automatically. Note: `Profile: balanced-profile (new default applied)`.

### Step 9: Report (three blocks — upgrade summary + what's new + RESTART banner)

Present the summary in **three separate echo -e blocks** so the restart banner is visually impossible to miss.

**Block 1 — Upgrade checklist (cyan double-line box):**
```
╔═══════════════════════════════════════════════════════╗
║  ✓ STP UPGRADE COMPLETE                               ║
║  v[OLD_VER] → v[NEW_VER]                              ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  [✓/✗] Core files updated                             ║
║  [✓/✗] Companion plugins (ui-ux-pro-max v[VER])      ║
║  [✓/✗] MCP servers (Context7, Tavily, Context Mode)  ║
║  [✓/✗] Reference files refreshed (.stp/references/)   ║
║  [✓/✗] Project CLAUDE.md sections refreshed           ║
║  [✓/✗] Global CLAUDE.md (STP Awareness)              ║
║  [✓/─] Profile ([current] — reviewed/default applied) ║
║  [✓/─] PRD.md format (structured / migrated)          ║
║  [✓/─] Layout migration                               ║
║  [✓/─] Hook scripts (all executable)                  ║
║  [✓/✗] Statusline                                     ║
║  [✓/─] Local patches                                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Block 2 — What's new (dim cyan single-line box, pulled from CHANGELOG.md):**

This block must contain the REAL content extracted in Step 1 from the new CHANGELOG.md — not a placeholder, not "2-3 sentences," but a faithful 5-10 line summary of the version's highlights. If the new version has a `### Summary` paragraph, lead with it. Then list the top items from `### Added`, `### Changed`, `### Fixed`. Preserve any **CRITICAL** or **IMPORTANT** markers.

```
┌─── What's new in v[NEW_VER] ─────────────────────────┐
│                                                       │
│  [tagline line from CHANGELOG version heading]        │
│                                                       │
│  [Summary paragraph — 2-4 lines if present]           │
│                                                       │
│  Added:                                               │
│    • [top 3 Added items, one per line, trimmed]       │
│                                                       │
│  Fixed:                                               │
│    • [top 3 Fixed items, one per line, trimmed]       │
│                                                       │
│  Changed:                                             │
│    • [top 2 Changed items if present]                 │
│                                                       │
└───────────────────────────────────────────────────────┘
```

**Block 3 — RESTART REQUIRED (mandatory red/yellow banner, impossible to miss):**

This banner is ALWAYS shown after an upgrade, regardless of whether hook files changed. The reason is that ANY change to `hooks/hooks.json` or any file under `hooks/scripts/` takes effect only after Claude Code session restart — and the user cannot be expected to audit the diff themselves to decide. Erring on the side of showing the banner every upgrade is cheap; missing it once is what caused v0.3.2 post-mortem Bug 1.

If `HOOK_CHANGE_COUNT > 0` (captured in Step 1), the banner is **MANDATORY** with bold yellow `⚠` and cyan double-line borders. If `HOOK_CHANGE_COUNT == 0`, the banner is still shown but with softer "Recommended" language and single-line borders.

**MANDATORY variant (when hooks changed):**
```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  RESTART CLAUDE CODE — HOOKS CHANGED                           ║
╠───────────────────────────────────────────────────────────────────╣
║                                                                   ║
║  v[NEW_VER] changed [HOOK_CHANGE_COUNT] hook file(s):             ║
║    • [list up to 5 changed hook files from HOOK_CHANGED_FILES]    ║
║                                                                   ║
║  Claude Code loads hooks ONCE at session startup. Your current    ║
║  session is still running the OLD hooks from when you launched    ║
║  Claude Code. New hooks will NOT fire until you restart.          ║
║                                                                   ║
║  TO ACTIVATE v[NEW_VER]:                                          ║
║                                                                   ║
║    1. /exit   (or Ctrl+D)                                         ║
║    2. claude  (or: claude --resume [SESSION_ID])                  ║
║    3. Verify new version:                                         ║
║         cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json      ║
║       Should show "version": "[NEW_VER]"                          ║
║                                                                   ║
║  /clear alone is NOT enough. It clears conversation context but   ║
║  keeps the loaded hooks.json from the old version in memory.     ║
║                                                                   ║
║  Why this manual step exists: Claude Code v2.1.x has no           ║
║  hot-reload API for hooks. A plugin-level workaround is not       ║
║  possible — this is a Claude Code platform limitation.            ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

**Recommended variant (when NO hook files changed):**
```
┌─── Restart recommended ─────────────────────────────────────────┐
│                                                                  │
│  No hook files changed in v[NEW_VER], but commands and          │
│  reference files DID update. Some changes take effect           │
│  immediately; others (statusline, settings) may need a          │
│  restart. Safest: /exit and run `claude` again.                 │
│                                                                  │
│  After restart: /clear is optional and clears conversation     │
│  context only — it does NOT reload hooks.                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Finally, the inline `► Next:` line:**

```
  ► Next: /exit → run `claude` again → (optional) /clear to start fresh
          Verify with: cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json
```

Do NOT recommend just `/clear` — that was the pre-v0.3.3 text and it is WRONG for plugin upgrades that touch hooks. `/clear` clears conversation context; it does not reload hook scripts. The user must restart Claude Code for new hooks to take effect.

## Edge Cases

- **No .stp/ directory:** This project isn't STP-managed. Say: "This project doesn't have STP set up. Run `/stp:new-project` or `/stp:onboard-existing` first."
- **Git pull fails (network):** Report the error, still run Steps 3-7 to sync what's already downloaded.
- **Plugin is a fork:** If `git remote -v` shows a different origin than DIV7NE/straight-to-production, warn but still pull.
- **Dirty working tree in plugin dir:** Stash before pull, pop after. If stash conflicts, warn and skip pull.

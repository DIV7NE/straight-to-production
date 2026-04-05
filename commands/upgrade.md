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
| **Plugin code** | Commands, agents, hooks, references, templates, whiteboard | `git pull` on plugin directory |
| **Companion plugins** | ui-ux-pro-max and any future required plugins | Auto-install if missing |
| **Project CLAUDE.md** | Philosophy, Required Plugins, Key Rules, Hooks, Directory Map | Refresh STP sections, preserve user's Project Conventions |
| **Global CLAUDE.md** | STP version marker + STP Awareness section | Refresh STP block only |
| **Stop-verify hook** | New enforcement gates (e.g., placeholder scanning) | Hook reads from plugin dir — auto-updated |
| **Project layout** | Old flat layout → organized .stp/docs/ + .stp/state/ | Migration script |

## Process

### Step 1: Pull Latest Plugin Code

```bash
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"
CURRENT=$(cd "$PLUGIN_DIR" && git rev-parse --short HEAD)
cd "$PLUGIN_DIR" && git pull origin main
NEW_HEAD=$(cd "$PLUGIN_DIR" && git rev-parse --short HEAD)
```

If already up to date (`$CURRENT` == `$NEW_HEAD`), still run the remaining sync steps — the project may be behind even if the plugin is current.

Show what changed:
```bash
cd "$PLUGIN_DIR" && git log --oneline "$CURRENT".."$NEW_HEAD" 2>/dev/null
```

### Step 2: Run Layout Migration

Migrate old flat layout → organized .stp/docs/ + .stp/state/ (idempotent, safe to re-run):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/migrate-layout.sh"
```

### Step 3: Sync Companion Plugins

Check and install all required companion plugins:

```bash
# ui-ux-pro-max (required for UI/UX work)
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```

**If ui-ux-pro-max is MISSING:**
```bash
command -v uipro >/dev/null 2>&1 || npm i -g uipro-cli
uipro init --ai claude
```
Report: "Installed ui-ux-pro-max design intelligence skill."

**If already installed**, check if outdated:
```bash
INSTALLED_VER=$(grep -oP 'version:\s*\K[0-9.]+' .claude/skills/ui-ux-pro-max/SKILL.md 2>/dev/null || echo "unknown")
LATEST_VER=$(npm view uipro-cli version 2>/dev/null || echo "unknown")
```
If `$INSTALLED_VER` != `$LATEST_VER` and both are known:
```bash
uipro init --ai claude
```
Report: "Updated ui-ux-pro-max from v$INSTALLED_VER to v$LATEST_VER."

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

This project was set up before marker-based sections. The ENTIRE file is treated as user content.

```
AskUserQuestion(
  question: "Your project CLAUDE.md doesn't have STP section markers. I need to add STP sections (Philosophy, Plugins, Hooks, etc.) to bring it up to date. Your existing content will be fully preserved.",
  options: [
    "(Recommended) Add STP sections — wrap them in markers and append after your existing content. Nothing you wrote changes.",
    "Replace entirely — generate a fresh STP CLAUDE.md. WARNING: your custom content will be lost.",
    "Skip — don't touch my CLAUDE.md. I'll add STP sections manually.",
    "Chat about this"
  ]
)
```

If "Add STP sections": read the existing file, append all STP marker-wrapped sections at the end. The user's original content remains untouched at the top.

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

### Step 6: Verify Hooks Are Active

STP hooks are defined in the plugin's `hooks.json` and loaded automatically by Claude Code from the plugin directory. No project-level copy needed. But verify they're functioning:

```bash
# Verify hook scripts exist and are executable
for script in stop-verify.sh post-edit-check.sh pre-compact-save.sh session-restore.sh migrate-layout.sh; do
  [ -x "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/$script" ] && echo "$script: OK" || echo "$script: MISSING/NOT EXECUTABLE"
done
```

If any are missing or not executable, fix:
```bash
chmod +x "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/"*.sh
```

### Step 7: Reapply Local Patches (if configured)

Check if the user has local patches configured in their global CLAUDE.md:
```bash
grep -q "Local Patches" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "local_patches: configured" || echo "local_patches: none"
```

If local patches are configured, remind the user:
```
NOTE: You have local patches configured in your global CLAUDE.md.
The git pull may have overwritten patched files. Check your Local Patches
section and reapply if needed (e.g., `cp ~/.claude/gsd-local-patches/... ...`).
```

### Step 8: Report

Present a clean summary:

```
━━━ STP Upgrade Complete ━━━

Plugin: [old commit] → [new commit]
Version: v[NEW_VER]

Changes:
[list of commits, or "Already up to date"]

Synced:
  [✓/✗] Companion plugins (ui-ux-pro-max v[VER])
  [✓/✗] Project CLAUDE.md (Philosophy, Hooks, Required Plugins)
  [✓/✗] Global CLAUDE.md (STP Awareness section)
  [✓/─] Layout migration (already organized / migrated)
  [✓/─] Hook scripts (all executable)
  [✓/─] Local patches (reapply reminder shown / none configured)

What's new:
[2-3 sentence summary of the most important changes from the commit log]

Run /clear to load the new version.
```

## Edge Cases

- **No .stp/ directory:** This project isn't STP-managed. Say: "This project doesn't have STP set up. Run `/stp:new-project` or `/stp:onboard-existing` first."
- **Git pull fails (network):** Report the error, still run Steps 3-7 to sync what's already downloaded.
- **Plugin is a fork:** If `git remote -v` shows a different origin than DIV7NE/stp, warn but still pull.
- **Dirty working tree in plugin dir:** Stash before pull, pop after. If stash conflicts, warn and skip pull.

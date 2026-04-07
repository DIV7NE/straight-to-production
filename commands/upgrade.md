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
if [ -L "$PLUGIN_DIR" ]; then
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

**Marketplace install (no .git) → download and overwrite in place:**

No manual steps. No uninstall/reinstall. Just download the latest and swap.

```bash
TEMP_DIR=$(mktemp -d)
OLD_VER=$(cat "$PLUGIN_DIR/VERSION" 2>/dev/null || echo "unknown")

git clone --depth 1 --branch main https://github.com/DIV7NE/stp.git "$TEMP_DIR/stp" 2>&1
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

**Check required MCP servers and Vercel Agent Browser:**

Attempt tool calls / file checks to verify each is available:
- Context7: try `resolve-library-id`
- Tavily: try `tavily_search`
- Context Mode: try `ctx_stats`
- Vercel Agent Browser: `command -v agent-browser` AND `[ -f ".claude/skills/agent-browser/SKILL.md" ]` (it's a CLI + Claude Code skill, NOT an MCP server)

**Install commands for missing MCP servers** (these are passive — show the command, the user runs it):

```
Context7:       claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
Tavily:         claude mcp add tavily -- npx -y tavily-mcp@latest  (requires TAVILY_API_KEY)
Context Mode:   claude mcp add context-mode -- npx -y context-mode-mcp@latest
```

**Vercel Agent Browser install (active — upgrade can run this):**

If `agent-browser: MISSING` OR `agent-browser-skill: MISSING`, ask the user:
```
AskUserQuestion(
  question: "Vercel Agent Browser is not fully installed. STP's QA agent and /stp:review use it to test apps like a real user. Want me to install/repair it now?",
  options: [
    "(Recommended) Yes — install agent-browser CLI + Chrome for Testing + Claude Code skill",
    "Skip — I'll install later",
    "Already installed differently — let me verify",
    "Chat about this"
  ]
)
```
If "Yes", run the 3-step install and report each step's result:
```bash
# Step 1: install the CLI globally (only if missing)
command -v agent-browser >/dev/null 2>&1 || npm install -g agent-browser

# Step 2: download Chrome for Testing (idempotent — skips if Chrome already detected)
agent-browser install

# Step 3: install/refresh the Claude Code skill (teaches the snapshot-ref workflow)
[ -f ".claude/skills/agent-browser/SKILL.md" ] || npx skills add vercel-labs/agent-browser
```
After install, re-verify both checks (`command -v agent-browser` + skill file presence) and report PASS/FAIL for each step. If any step fails (network, permissions, missing Rust toolchain), surface the error verbatim and link to https://github.com/vercel-labs/agent-browser for manual install.

If the user already has agent-browser working but installed differently (`Already installed differently — let me verify`), just verify both checks pass and skip the install steps.

Report status in the upgrade summary: `[✓/✗] Context7`, `[✓/✗] Tavily`, `[✓/✗] Context Mode`, `[✓/✗] Agent Browser CLI`, `[✓/✗] Agent Browser skill`.

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

### Step 9: Report

Present a clean summary:

```
╔═══════════════════════════════════════════════════════╗
║  ✓ STP UPGRADE COMPLETE                               ║
║  v[OLD_VER] → v[NEW_VER]                              ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  [✓/✗] Core files updated                             ║
║  [✓/✗] Companion plugins (ui-ux-pro-max v[VER])      ║
║  [✓/✗] MCP servers (Context7, Tavily, Context Mode)  ║
║  [✓/✗] Agent Browser (CLI v[VER] + skill)            ║
║  [✓/✗] Reference files refreshed (.stp/references/)   ║
║  [✓/✗] Project CLAUDE.md sections refreshed           ║
║  [✓/✗] Global CLAUDE.md (STP Awareness)              ║
║  [✓/─] PRD.md format (structured / migrated)          ║
║  [✓/─] Layout migration                               ║
║  [✓/─] Hook scripts (all executable)                  ║
║  [✓/✗] Statusline                                     ║
║  [✓/─] Local patches                                  ║
║                                                       ║
║  What's new:                                          ║
║  [2-3 sentence summary of changes]                    ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

  ► Next: /clear to load the new version
```

## Edge Cases

- **No .stp/ directory:** This project isn't STP-managed. Say: "This project doesn't have STP set up. Run `/stp:new-project` or `/stp:onboard-existing` first."
- **Git pull fails (network):** Report the error, still run Steps 3-7 to sync what's already downloaded.
- **Plugin is a fork:** If `git remote -v` shows a different origin than DIV7NE/stp, warn but still pull.
- **Dirty working tree in plugin dir:** Stash before pull, pop after. If stash conflicts, warn and skip pull.

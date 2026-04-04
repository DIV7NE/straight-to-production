---
description: Upgrade STP to the latest version. Pulls the latest from GitHub and shows what changed.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read"]
---

# STP: Upgrade

Pull the latest version of STP from GitHub and show what changed.

## Process

1. Find the plugin directory:
```bash
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT}"
```

2. Save current version:
```bash
CURRENT=$(cd "$PLUGIN_DIR" && git rev-parse --short HEAD)
```

3. Pull latest:
```bash
cd "$PLUGIN_DIR" && git pull origin main
```

4. Show what changed:
```bash
cd "$PLUGIN_DIR" && git log --oneline "$CURRENT"..HEAD
```

5. Show the new version:
```bash
cd "$PLUGIN_DIR" && cat .claude-plugin/plugin.json | grep version
```

6. Run layout migration on the current project (moves files from old flat layout to organized .stp/docs/ + .stp/state/):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/migrate-layout.sh"
```

7. Check if global CLAUDE.md needs updating:
```bash
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
STP_VER_IN_GLOBAL=$(grep -oP '<!-- STP v\K[0-9.]+' "$GLOBAL_CLAUDE" 2>/dev/null | head -1)
NEW_VER=$(grep -oP '"version":\s*"\K[0-9.]+' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null | head -1)
```

If the global CLAUDE.md has an STP version marker that's older than the new plugin version, tell the user:
```
Global CLAUDE.md has STP v[OLD] but plugin is now v[NEW].
Update the STP sections in ~/.claude/CLAUDE.md? (replaces only the <!-- STP --> block)
```
Use AskUserQuestion: "Update global CLAUDE.md STP sections?", options: "(Recommended) Yes — update STP sections to v[NEW]", "No — I'll update manually", "Chat about this".

If yes: update the `<!-- STP v... -->` marker and refresh the STP sections. Preserve all non-STP content.

Also check the project-level CLAUDE.md the same way.

8. Tell the user:
```
STP upgraded.

Previous: [old commit]
Current:  [new commit]

Changes:
[list of commits since last version]

[If migration moved files: "Migrated project files to new organized layout (.stp/docs/ + .stp/state/)."]
[If CLAUDE.md updated: "Updated STP sections in CLAUDE.md to v[NEW]."]

Run /clear to load the new version.
```

If already up to date:
```
STP is already at the latest version.
```

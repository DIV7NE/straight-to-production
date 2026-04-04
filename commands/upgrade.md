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

7. Tell the user:
```
STP upgraded.

Previous: [old commit]
Current:  [new commit]

Changes:
[list of commits since last version]

[If migration moved files: "Migrated project files to new organized layout (.stp/docs/ + .stp/state/)."]

Run /clear to load the new version.
```

If already up to date:
```
STP is already at the latest version.
```

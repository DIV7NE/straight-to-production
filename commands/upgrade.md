---
description: Upgrade Pilot to the latest version. Pulls the latest from GitHub and shows what changed.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read"]
---

# STP: Upgrade

Pull the latest version of Pilot from GitHub and show what changed.

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

6. Tell the user:
```
Pilot upgraded.

Previous: [old commit]
Current:  [new commit]

Changes:
[list of commits since last version]

Run /clear to load the new version.
```

If already up to date:
```
STP is already at the latest version.
```

---
description: Update Pilot reference files in the current project to the latest version from the plugin. Run this after updating the Pilot plugin to get new/updated standards.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# Pilot: Upgrade References

Updates the `.pilot/references/` and `.pilot/scripts/` in the current project with the latest files from the Pilot plugin.

## Process

### Step 1: Check Current State
```bash
# Count current references
echo "Current references:"
find .pilot/references -name "*.md" 2>/dev/null | wc -l

# Check plugin version
cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | grep version
```

### Step 2: Backup Current References
```bash
if [ -d ".pilot/references" ]; then
  cp -r .pilot/references .pilot/references.bak
  echo "Backed up current references to .pilot/references.bak"
fi
```

### Step 3: Run Setup Script (overwrites with latest)
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

### Step 4: Show What Changed
```bash
# Compare old vs new
if [ -d ".pilot/references.bak" ]; then
  echo "=== New files ==="
  diff -rq .pilot/references.bak .pilot/references 2>/dev/null | grep "Only in .pilot/references" || echo "None"

  echo "=== Modified files ==="
  diff -rq .pilot/references.bak .pilot/references 2>/dev/null | grep "differ" || echo "None"

  echo "=== Removed files ==="
  diff -rq .pilot/references.bak .pilot/references 2>/dev/null | grep "Only in .pilot/references.bak" || echo "None"
fi
```

### Step 5: Update CLAUDE.md Standards Index

Read the current CLAUDE.md. If it contains a Pilot Standards Index section, check whether the index references all files now in `.pilot/references/`. If new reference files were added, update the index to include them.

Read the latest index template from `${CLAUDE_PLUGIN_ROOT}/templates/standards-index.md` and compare with what's in CLAUDE.md. Suggest additions if the index is outdated.

### Step 6: Clean Up
```bash
rm -rf .pilot/references.bak
```

### Step 7: Report
Tell the user:
- How many reference files were updated
- Any new standards added
- Whether CLAUDE.md index was updated
- Suggest reviewing changes with `git diff .pilot/` if tracked, or `/pilot:standards` to see all active standards

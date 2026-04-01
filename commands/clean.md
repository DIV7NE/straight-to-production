---
description: Strip dead code from the project to maximize context budget. Removes unused imports, exports, variables, and dependencies. Run this before major building sessions to prevent premature compaction.
argument-hint: Optional scope (e.g., "src/components" to clean a specific directory)
allowed-tools: ["Read", "Bash", "Edit", "Grep", "Glob"]
---

# Pilot: Clean

Remove dead weight from the codebase to preserve context budget. Every unnecessary token in a file that Claude reads is a token wasted toward the compaction threshold.

## Why This Matters
Claude Code's compaction fires at ~70-95% of the effective context window. Every file Claude reads stays in context (frozen via `seenIds`). Dead imports, unused exports, and orphaned code all count toward this limit. Cleaning before building extends your productive session length.

## Process

### Step 1: TypeScript Dead Code
```bash
# Find unused exports
npx ts-prune 2>/dev/null | grep -v "node_modules" | head -30

# If ts-prune isn't installed, use grep to find exports not imported elsewhere
for f in $(find ${1:-.} -name "*.ts" -o -name "*.tsx" | grep -v node_modules | grep -v .next); do
  EXPORTS=$(grep -oP "export (const|function|class|type|interface|enum) \K\w+" "$f" 2>/dev/null)
  for exp in $EXPORTS; do
    COUNT=$(grep -rn "\b$exp\b" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules --exclude-dir=.next . 2>/dev/null | wc -l)
    if [ "$COUNT" -le 1 ]; then
      echo "$f: unused export '$exp'"
    fi
  done
done
```

### Step 2: Unused Dependencies
```bash
npx depcheck 2>/dev/null | head -30
```
Remove any dependencies listed as unused.

### Step 3: Console.log Cleanup
```bash
grep -rn "console\.\(log\|warn\|debug\)" --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.next . | head -20
```
Remove all console statements from production code. Replace with proper error logging if needed.

### Step 4: Dead Files
Look for files not imported by anything:
```bash
for f in $(find ${1:-src} -name "*.ts" -o -name "*.tsx" | grep -v node_modules | grep -v .next | grep -v "layout\|page\|loading\|error\|not-found\|route\|middleware"); do
  BASENAME=$(basename "$f" | sed 's/\.\(ts\|tsx\)$//')
  IMPORTS=$(grep -rn "$BASENAME" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules --exclude-dir=.next . 2>/dev/null | grep -v "^$f:" | wc -l)
  if [ "$IMPORTS" -eq 0 ]; then
    echo "Potentially dead file: $f (not imported anywhere)"
  fi
done
```

### Step 5: Commit Cleanup
After removing dead code:
```bash
git add -A
git commit -m "chore: strip dead code for context optimization"
```

Report what was removed and how many lines/tokens were saved, then give the explicit next step:

```
Cleanup complete. Removed [N] unused exports, [N] dead files, [N] console statements.

━━━ Next step ━━━

Start building with a clean context budget:
   /pilot:feature [NEXT FEATURE — read CLAUDE.md spec to determine this]
```

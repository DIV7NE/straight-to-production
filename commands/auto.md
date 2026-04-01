---
description: Run Pilot in autonomous mode. Works through the feature checklist unattended — each task gets a fresh context via headless Claude. Set it up before bed, wake up to finished work. Requires an active feature checklist (.pilot/current-feature.md).
argument-hint: Optional max iterations (default 30)
allowed-tools: ["Read", "Bash", "Write"]
---

# Pilot: Auto Mode (Overnight Autonomous)

Run the feature checklist autonomously. Each checklist item runs in a fresh Claude Code session (headless -p mode), so there's NO context rot, NO compaction, NO forgetting.

## Prerequisites

1. CLAUDE.md exists with project spec and standards
2. .pilot/current-feature.md exists with a checklist (run /pilot:feature first)
3. .pilot/references/ set up (run /pilot:setup if not)

## How to Run

Tell the user to run this command in their terminal (NOT inside Claude Code):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/pilot-auto.sh" 30
```

Or if they want it to run overnight with output logging:

```bash
nohup bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/pilot-auto.sh" 50 > .pilot/auto.log 2>&1 &
echo "Pilot auto mode running in background. Check progress:"
echo "  tail -f .pilot/auto.log"
echo "  cat .pilot/current-feature.md"
```

## How It Works

```
Iteration 1: fresh claude -p → reads CLAUDE.md + checklist → does task 1 → commits → updates checklist
Iteration 2: fresh claude -p → reads CLAUDE.md + checklist → does task 2 → commits → updates checklist
...
Iteration N: all items [x] → runs /pilot:evaluate → saves report → exits
```

Each iteration:
- Gets a FRESH context (no rot, no compaction)
- Reads standards from CLAUDE.md (always current)
- Reads references from .pilot/references/ (domain-specific standards)
- Does ONE task from the checklist
- Commits atomically
- Updates the checklist on disk

## Safety

- Max iterations cap prevents runaway costs (default 30)
- If a task fails after 3 attempts, it notes the issue and moves on
- All work is committed to git — easy to review and revert
- Final /pilot:evaluate runs automatically when done
- Rate limit: 3-second pause between iterations

## Next Step

After running this command, tell the user EXACTLY:

```
━━━ Run this in your terminal (not in Claude Code) ━━━

bash [PLUGIN_ROOT]/hooks/scripts/pilot-auto.sh 30

To run overnight:
nohup bash [PLUGIN_ROOT]/hooks/scripts/pilot-auto.sh 50 > .pilot/auto.log 2>&1 &

Check progress anytime:
tail -f .pilot/auto.log
cat .pilot/current-feature.md
git log --oneline -10

In the morning:
cat .pilot/auto-eval-report.txt
```

Replace [PLUGIN_ROOT] with the actual resolved path to the plugin.

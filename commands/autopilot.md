---
description: Run STP in autonomous mode. Works through the feature checklist unattended — each task gets a fresh context. Set it up before bed, wake up to a built feature.
argument-hint: Optional max iterations (default 30)
allowed-tools: ["Read", "Bash", "Write"]
---

> **Recommended effort: `/effort medium`** — Efficient thinking for routine execution tasks.



# STP: Auto Mode (Overnight Autonomous)

Run the feature checklist autonomously. Each checklist item runs in a fresh Claude Code session (headless -p mode) for context isolation. No rot, no compaction, no forgetting.

## Prerequisites

1. CLAUDE.md exists with project spec and standards
2. `.stp/current-feature.md` exists with a checklist (run `/stp:build` first)
3. `.stp/references/` set up

## How to Run

Tell the user to run this in their terminal (NOT inside Claude Code):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-auto.sh" 30
```

Overnight with logging:
```bash
nohup bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-auto.sh" 50 > .stp/auto.log 2>&1 &
echo "Pilot auto mode running. Check progress:"
echo "  tail -f .stp/auto.log"
echo "  cat .stp/current-feature.md"
```

## How It Works

```
Iteration 1: fresh claude -p → reads CLAUDE.md + PLAN.md + checklist → writes tests → implements → commits
Iteration 2: fresh claude -p → reads context → next task → tests first → implements → commits
...
Iteration N: all items [x] → verification → critic evaluation → exits
```

Each iteration:
- Fresh context (no rot)
- Reads standards from CLAUDE.md + blueprint from PLAN.md (always current)
- TDD: writes tests FIRST, then implements to pass them
- Does ONE task from the checklist
- Stack-appropriate type check + test verification after each task
- Commits atomically (test commit, then implementation commit)
- Updates checklist on disk

## Safety

- Max iterations cap (default 30)
- Stack-aware verification after each iteration (type check + tests)
- 3-attempt limit per stuck task — skips with note after 3 failures
- All work committed to git (easy to review and revert)
- Critic evaluation runs automatically when checklist completes
- 3-second pause between iterations

## After Completion

```
━━━ Run in your terminal (not in Claude Code) ━━━

bash [PLUGIN_ROOT]/hooks/scripts/stp-auto.sh 30

Overnight:
nohup bash [PLUGIN_ROOT]/hooks/scripts/stp-auto.sh 50 > .stp/auto.log 2>&1 &

Check progress anytime:
  tail -f .stp/auto.log
  cat .stp/current-feature.md
  git log --oneline -10

In the morning:
  cat .stp/auto-eval-report.txt
```

Replace [PLUGIN_ROOT] with the actual resolved path.

---
description: Resume exactly where you left off — after /clear, compaction, or a new session. Reads all state files and picks up the next task automatically.
argument-hint: No arguments needed
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort high`** — Full orchestration depth for resuming work.

# STP: Continue

Resume work from exactly where you left off. This command reads all persisted state and immediately starts working — no questions, no summaries, just action.

## Process

### Step 1: Restore Context (read all in parallel)

Read ALL of these that exist:

| Priority | File | What it tells you |
|----------|------|------------------|
| 1 | `.stp/state/handoff.md` | Intentional pause — has exact next steps |
| 2 | `.stp/state/state.json` | Emergency save from compaction |
| 3 | `.stp/state/current-feature.md` | Active feature checklist with progress |
| 4 | `.stp/docs/CONTEXT.md` | What exists now (file map, schema, API, patterns) |
| 5 | `.stp/docs/PLAN.md` | Architecture, milestones, feature status |
| 6 | `.stp/docs/CHANGELOG.md` | What was built recently |
| 7 | `VERSION` | Current version |
| 8 | `CLAUDE.md` | Stack patterns and standards |

Also run:
```bash
git status --short
git log --oneline -5
```

### Step 2: Determine Resume Point

Follow this priority chain — use the FIRST match:

**Priority 1: Handoff exists (`.stp/state/handoff.md`)**

The user intentionally paused with `/stp:pause`. The handoff has everything:
- What was being done
- Current state
- Key decisions made
- **What's Next** — this is the resume point

Read the "What's Next" section. The first item is your immediate task.

**Before deleting: preserve lessons.** If the handoff has "Key Decisions Made" or "Problems / Things That Didn't Work", append them to `.stp/docs/CHANGELOG.md` under a session entry:

```markdown
## Session — [DATE] — Resumed from handoff

### Decisions Carried Forward
- [Key decisions from handoff that future sessions need to know]

### Failed Approaches (do NOT retry)
- [Approaches that were tried and didn't work, with why]
```

Then delete the handoff — it's been consumed and its lessons are preserved:
```bash
rm .stp/state/handoff.md
```

**Priority 2: Active feature (`.stp/state/current-feature.md`)**

A feature was in progress. Find the first unchecked `[ ]` item — that's your resume point.

Cross-reference with `git log --oneline -5` to understand what was already committed vs what's in progress.

**Priority 3: Between features (no handoff, no active feature)**

Check .stp/docs/PLAN.md for the next unchecked `[ ]` feature in the current milestone. That's what to build next.

**Priority 4: No state files at all**

Nothing to resume. Tell the user:
```
No previous work state found. Nothing to continue from.

Start fresh:
  /stp:new-project — start a new project
  /stp:onboard-existing — take over an existing codebase
```
Stop here.

### Step 3: Verify State Before Resuming

Before diving in, verify the codebase matches expected state:

```bash
# Check for uncommitted work that might conflict
git status --short

# Verify tests still pass (quick check)
# [stack-appropriate test command]
```

If uncommitted changes exist that DON'T match the resume context:
```
AskUserQuestion(
  question: "Found uncommitted changes that don't match the last session's work. What should I do?",
  options: [
    "(Recommended) Commit them first — then continue",
    "Stash them — I'll deal with them later",
    "They're from the previous session — continue as-is",
    "Chat about this"
  ]
)
```

If tests are failing that weren't expected to fail:
```
AskUserQuestion(
  question: "Tests are failing before I resume. Fix them first or continue with the planned work?",
  options: [
    "(Recommended) Fix failing tests first — clean slate",
    "Continue anyway — I know about these failures",
    "Chat about this"
  ]
)
```

### Step 4: Brief Status + Immediate Action

Show a SHORT status (5 lines max), then START WORKING:

```
╔═══════════════════════════════════════════════════════╗
║  STP ► RESUMING                                       ║
║  [Feature Name] — [done]/[total] items complete       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Last commit   [hash] — [message]                     ║
║  Next task     [exact next item]                      ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

[Immediately begin working on the next task — no waiting for user input]
```

**This is the key difference from `/stp:progress`.** Progress shows status. Continue shows status AND immediately starts working.

### Step 5: Continue Building

Now execute based on what the resume point requires:

**If resuming mid-feature (active checklist):**
- Pick up from the first unchecked `[ ]` item in `.stp/state/current-feature.md`
- Follow the same build process as `/stp:work-quick` Step 5 onward
- Opus plans/reviews, Sonnet executes (delegation rules still apply)
- TaskCreate for remaining items
- Continue TDD, hygiene, QA flow as normal

**If resuming between features (next feature in .stp/docs/PLAN.md):**
- This is equivalent to `/stp:work-quick [next feature]`
- Follow the full `/stp:work-quick` process from Step 1
- But skip the user's initial description — you already know from .stp/docs/PLAN.md

**If resuming from handoff with specific instructions:**
- Follow the handoff's "What's Next" items in order
- These may include non-build tasks (fix a bug, update docs, run review)
- Execute them directly

## Rules

- Do NOT ask "what should I work on?" — the state files tell you. Just start.
- Do NOT produce a long status report. 5 lines max, then action.
- Do NOT re-research things the handoff says were already decided. Trust prior session's decisions.
- DO verify the codebase state matches expectations before writing code.
- DO delete `.stp/state/handoff.md` after consuming it — it's a one-time note, not permanent state.
- DO create TaskCreate items for remaining work so the user sees progress.
- If ALL state files are missing, don't guess. Tell the user there's nothing to continue and suggest starting commands.
- The handoff's "Problems / Things That Didn't Work" section is critical — do NOT retry failed approaches.

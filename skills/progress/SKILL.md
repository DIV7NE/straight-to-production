---
description: Check the current state of your project — what's done, what's in progress, what's next. Use anytime you want a status check.
argument-hint: No arguments needed
allowed-tools: ["Read", "Bash", "Glob", "Grep"]
---

> **Recommended effort: `/effort low`** — Read-only status check.

# STP: Progress

Show the user a clear, complete picture of where their project stands. Read everything, summarize concisely.

## Process

### Step 1: Gather State (read all in parallel)

Read ALL of these that exist (skip missing ones silently):

| File | What it tells you |
|------|------------------|
| `VERSION` | Current version |
| `.stp/docs/PLAN.md` | Milestones, features, what's done vs remaining |
| `.stp/docs/PRD.md` | Acceptance criteria — what was promised |
| `.stp/docs/CONTEXT.md` | What exists now (file map, schema, API) |
| `.stp/docs/CHANGELOG.md` | What was built and when |
| `.stp/state/current-feature.md` | Active feature in progress |
| `.stp/state/handoff.md` | Paused session with context |
| `.stp/state/state.json` | Auto-saved state from compaction |

Also run:
```bash
git status --short
git log --oneline -5
```

### Step 2: Analyze Progress

From .stp/docs/PLAN.md, calculate:
- Total milestones and which is current
- Features done `[x]` vs remaining `[ ]` in current milestone
- Features done vs remaining across ALL milestones
- Overall completion percentage

From .stp/docs/PRD.md, check:
- Which acceptance criteria have been met (cross-reference with .stp/docs/CHANGELOG.md and completed features)
- Which acceptance criteria are still pending

From .stp/docs/CHANGELOG.md:
- Last 3 entries (most recent work)
- Last version bump date

### Step 3: Present Status Report

```
╔═══════════════════════════════════════════════════════╗
║  STP ► PROJECT STATUS                                 ║
║  [PROJECT NAME]   v[X.Y.Z]                           ║
╚═══════════════════════════════════════════════════════╝

┌─── Milestone Progress ───────────────────────────────┐
│                                                       │
│  Milestone [N]: [Name] — [done]/[total] ([%])        │
│    ✓ Feature 1 (v0.1.1)                              │
│    ✓ Feature 2 (v0.1.2)                              │
│    ► Feature 3            ← NEXT                      │
│    · Feature 4                                        │
│                                                       │
│  [■■■■■■░░░░] [done]/[total] · [%] complete          │
│                                                       │
└──────────────────────────────────────────────────────┘

┌─── Current State ────────────────────────────────────┐
│                                                       │
│  [ONE of these:]                                      │
│                                                       │
│  Active: [name] — [done]/[total] checklist items     │
│    Next item: [first unchecked item]                  │
│                                                       │
│  OR  Paused: [summary from handoff.md]                │
│       ► Resume: /stp:continue                         │
│                                                       │
│  OR  Ready for next feature:                          │
│       ► /stp:work-quick [NEXT FEATURE NAME]            │
│                                                       │
└──────────────────────────────────────────────────────┘

┌─── Recent Activity ──────────────────────────────────┐
│  [Last 3 CHANGELOG entries, one line each]            │
│  [Last commit: hash — message — time ago]             │
└──────────────────────────────────────────────────────┘

┌─── Git Status ───────────────────────────────────────┐
│  [git status summary, or "Clean — all committed"]     │
└──────────────────────────────────────────────────────┘

  ► Next: [Specific actionable step based on state]
```

### Step 4: Health Warnings (only if applicable)

Append warnings ONLY if real issues exist:

```
┌─── ⚠ Warnings ───────────────────────────────────────┐
│                                                       │
│  [Only show these if they're true:]                   │
│  ⚠ Uncommitted changes: [N] files modified            │
│  ⚠ No tests found — TDD is mandatory                 │
│  ⚠ PLAN.md missing — run /stp:plan                   │
│  ⚠ PRD.md missing — run /stp:new-project              │
│  ⚠ CONTEXT.md outdated — [N] features since update    │
│  ⚠ ARCHITECTURE.md missing — run /stp:onboard-existing│
│  ⚠ AUDIT.md stale — run /stp:review                   │
│  ⚠ Handoff [N] days old — consider deleting            │
│                                                       │
└──────────────────────────────────────────────────────┘
```

## Rules

- This is READ-ONLY. Do not modify any files.
- Be specific with names and numbers. Never say "some features" — say "3 of 7 features."
- If files are missing, don't warn about every one. Just show what exists and suggest the right command to fill gaps.
- Keep the entire output under 40 lines. Dense, not verbose.
- Show the NEXT actionable command the user should run.

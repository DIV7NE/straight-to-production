---
description: "Session lifecycle — pause (save state), continue (resume), progress (dashboard). Use when you're context-pressed, switching tasks, or picking up yesterday's work."
argument-hint: pause | continue | progress
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion"]
---

> **Recommended effort:** `high` for all subcommands. These are lightweight orchestrators, not deep reasoning tasks.

# STP: Session

Three subcommands. Each addresses a different moment in the session lifecycle.

**Reference:** before complex session work, read `${CLAUDE_PLUGIN_ROOT}/references/session-management.md` — covers `/rewind` (Esc Esc), `/compact` vs `/clear` trade-offs, and the context % threshold table (0-40% silent, 40-70% optional compaction, 70-90% pause now, 90%+ imminent autocompact).

## Shared opening

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
```

---

## Subcommand: `pause`

**Purpose:** save everything the next session needs to resume, then exit. Context % is irrelevant — pausing is cheap.

1. **Parallel reads** — gather state:
   - `git status --short` — uncommitted files
   - `git diff --stat` — scale of uncommitted changes
   - `git log --oneline -5` — recent commits
   - `.stp/state/current-feature.md` (if exists) — active work
   - `.stp/state/design-brief.md` (if exists) — design outcome from `/stp:think`
   - `.stp/docs/CHANGELOG.md` (last 20 lines) — recent feature history
2. **Pre-Work Confirmation Gate** — announce plan: "I'll write handoff.md with current state + next steps, commit any WIP, and exit. Uncommitted work becomes a WIP commit."
   - AskUserQuestion:
     - `(Recommended) Save handoff + WIP-commit uncommitted`
     - `Save handoff, don't commit WIP`
     - `Just save handoff (skip commit + discard nothing)`
     - `Cancel`
3. **Write `.stp/state/handoff.md`** — the deep context. Template:
   ```markdown
   # Handoff — [timestamp]

   ## What I was doing
   [one paragraph, past tense]

   ## Where I left off
   [one paragraph — file path + line if mid-edit]

   ## Open decisions
   - [decision 1 deferred to next session]
   - [decision 2]

   ## Next actions
   1. [first concrete step on resume]
   2. [second step]
   3. [third step]

   ## Context that might get lost
   - [any insight or research outcome not yet in CHANGELOG]
   - [any gotcha discovered mid-session]

   ## Recommended resume command
   `/clear, then /stp:session continue`
   ```
3.5. **Write `.stp/state/session-summary.md`** — the TL;DR. This is what `continue` reads FIRST so the resume cost is bounded by ~50 lines, not the full handoff + plan + architecture stack.

   Strict template, hard ceiling ≤50 lines:

   ```markdown
   # Session Summary — [ISO timestamp]

   ## What I was doing
   [ONE sentence, imperative past — "Implementing PRD AC-007: invoice PDF export."]

   ## What's done
   - [checklist item completed this session]
   - [another]

   ## Open decisions
   - [question deferred to next session]

   ## Next action
   [ONE sentence — "Write failing test for AC-007.c (empty line items edge case)."]

   ## Context that might get lost
   - [non-obvious insight]
   - [gotcha discovered]
   - (max 3 bullets — demand brevity)

   ---
   Full context: `.stp/state/handoff.md`
   Resume: `/stp:session continue`
   ```

   Both files exist side-by-side. `handoff.md` is the full context for deep resumes. `summary.md` is the skimmable version for most resumes. `continue` reads `summary.md` first; only loads `handoff.md` when summary is missing or the user asks for deep context.
4. **WIP commit** (if user chose to) — `git add <specific files> && git commit -m "wip: session paused — [brief]"`.
5. **Write `.stp/state/state.json`** — machine-readable summary for SessionStart hook to reload:
   ```json
   {
     "paused_at": "2026-04-17T...",
     "branch": "current",
     "open_feature": "from current-feature.md name field",
     "next_command": "/stp:session continue",
     "context_pct_at_pause": "<estimate 0-100>"
   }
   ```
6. Print completion box: `Paused. Resume with: /clear, then /stp:session continue`.

---

## Subcommand: `continue`

**Purpose:** resume from disk. Assumes fresh session (`/clear` before invocation is common but not required). Uses **lazy read** — load the cheap skim first, only pay for deep context when needed.

1. **Tier-1 read (always)** — fast, ~50 lines total:
   - `.stp/state/session-summary.md` — the TL;DR from the last `pause`
   - `.stp/state/state.json` — machine-readable resume (paused-at, branch, open feature, next command)
   - `git status --short` + `git log --oneline -5`

   If `session-summary.md` exists and is ≤48 hours old: **go to step 2 with just this data.** Do NOT open handoff.md, PLAN.md, CHANGELOG.md, or ARCHITECTURE.md at this point. The summary has what you need for 90% of resumes.

2. **Synthesis** — build a <200 word context summary from tier-1 reads only. Cover: what was active (from summary's "What I was doing"), next action (from summary's "Next action"), any uncommitted changes (from git status).

3. **Pre-Work Confirmation Gate** — announce: "Resuming [feature from summary]. Next action: [summary's next action]. Proceeding?" AskUserQuestion:
   - `(Recommended) Continue with next action`
   - `Different task — let me describe`
   - `Load deep context first (handoff + PLAN + ARCHITECTURE)`
   - `Just show the summary, I'll decide`

4. **Tier-2 read (on demand)** — triggered if any of these happen:
   - User picked `Load deep context first`
   - `session-summary.md` is missing or >48 hours old
   - Summary says "See handoff for details" or similar escape hatch
   - The chained target command (`/stp:build`, `/stp:think`) needs more than summary provides

   Tier-2 parallel read:
   - `.stp/state/handoff.md` — full conversational resume point
   - `.stp/state/current-feature.md` (if exists) — active feature checklist
   - `.stp/state/design-brief.md` (if exists) — upstream design
   - `.stp/docs/CHANGELOG.md` (last 40 lines) — recent feature history
   - `.stp/docs/PLAN.md` (sections 1-3) — goal + constraints
   - `.stp/docs/ARCHITECTURE.md` (if chained into `/stp:build`) — dependency map

5. **Chain into target command** — based on summary's next action or `state.json.next_command`. Typically: `/stp:build` (continue feature) or `/stp:think` (continue planning).

6. Session-start hook (`session-restore.sh`) runs on fresh session — this command is the interactive complement that synthesizes and chains.

> **Why lazy-read:** on a mature project, the full read (PLAN + ARCHITECTURE + CHANGELOG + handoff) can be 10-30 KB of markdown — meaningful context cost on every resume. The summary is typically ~2 KB. Escalate to full only when the summary genuinely isn't enough.

---

## Subcommand: `progress`

**Purpose:** status dashboard. Read-only — no Pre-Work Gate needed.

1. **Parallel reads** — same as `continue` but include:
   - `.stp/docs/PRD.md` (sections 1-3) — requirements overview
   - `.stp/docs/AUDIT.md` (last 20 lines if exists) — known health issues
   - Test suite status: `STACK=$(jq -r .stack .stp/state/stack.json)` → run `.stp/state/stack.json`'s `test_cmd` with a short timeout + capture pass/fail count
   - Hook marker files: `ls .stp/state/*-passed .stp/state/.migrated-v1 2>/dev/null`
2. **Compute metrics:**
   - Features done (CHANGELOG entries this week)
   - Features in progress (current-feature.md + open WIP branches)
   - Tests: pass / fail / skipped
   - Context usage estimate (hard to measure directly — provide a rough guess based on session length + tool-call count if statusline exposes it)
   - Warnings: uncommitted >1 day old, stale `current-feature.md` (>1 week), missing tests for recent source files
3. **Render dashboard** — cyan ╔═╗ banner with ANSI colors:
   ```
   ╔════════════════════════════════════════════════════════════╗
   ║  STP v[version] — Session Progress                         ║
   ╚════════════════════════════════════════════════════════════╝

   ✓ Current profile: [balanced / opus-cto / ...]
   ✓ Pace:            [batched / deep / ...]
   ✓ Stack:           [web / node / python / rust / cpp / ...]
   ✓ UI gate:         [passed / pending]

   Features:
     ✓ Done this week:  [N] ([list last 3 names])
     ► In progress:     [name from current-feature.md]
     • Planned:         [from PLAN.md unfinished]

   Tests:
     ✓ Passing:         [N]
     ✗ Failing:         [N] ([top 3 names])
     ~ Skipped:         [N]

   ⚠ Warnings:
     - [if any, listed]

   ★ Next action: [from handoff.md or current-feature.md — 1 line]
   ```
4. Do NOT write files — this is a read-only dashboard. No commit.

---

## Context-threshold nudges (informational)

The statusline (`hooks/scripts/stp-statusline.js`) surfaces these automatically, but be aware when invoked manually:

| Context % | Nudge |
|---|---|
| 0-40% | (silent) |
| 40-70% | Consider `/compact` (tool-heavy session) or `/stp:session pause → /clear → /stp:session continue` (prose-heavy). |
| 70-90% | Pause NOW. Autocompact is close and will be bad. |
| 90%+ | Autocompact imminent. `/stp:session pause` this turn. |

See `${CLAUDE_PLUGIN_ROOT}/references/session-management.md` for the full framework including subagent litmus test.

---

## Gotchas

- `pause` + `/clear` + `continue` beats `/compact` for prose-heavy sessions (architectural discussion, PRD negotiation). `/compact` summarizes — losing fidelity where you need it. `pause` uses disk (high fidelity).
- `/rewind` (Esc Esc) is a different primitive — surgical do-over within the current session. Use when an approach just failed. Don't use when you want to keep both branches — it's destructive.
- `continue` does NOT auto-start work — it surfaces next action and asks. You stay in control.
- `progress` is read-only. No side effects. Safe to run anytime.
- If state files are missing entirely (fresh project, never paused), `continue` falls back to: "No prior session state. Use `/stp:setup welcome` for first-run or tell me what you want to work on."

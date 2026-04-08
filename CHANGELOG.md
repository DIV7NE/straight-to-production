# Changelog

All notable changes to STP are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] — 2026-04-08 — fix: whiteboard reliability (filename contract + mandatory server start + /clear in handoffs)

### Summary
Three structural bugs ganged up to make the visual whiteboard unreliable for
any user invoking `/stp:whiteboard`:

1. **Filename contract was split.** The server (`whiteboard/serve.py`) watched
   `.stp/whiteboard-data.json` while four command files told the orchestrator
   to write `.stp/explore-data.json`. The rename was half-finished — `plan.md`
   even contradicted itself across three lines. Result: server permanently
   stuck on `{"status":"Waiting..."}`.

2. **Server start was always conditional.** Every single `start-whiteboard.sh`
   call across the entire codebase lived inside an "if they accept" /
   AskUserQuestion gate or after a write. There was zero unconditional start
   anywhere. The agent could (and did) reach the "write the design system
   JSON" step with no server running — the user opened localhost:3333 and
   saw nothing. The command is literally named `/stp:whiteboard`; a whiteboard
   the user can't see is a broken command.

3. **No `/clear` in handoffs.** Completion boxes recommended `/stp:work-quick`,
   `/stp:plan`, etc. as next steps but never told the user to `/clear` first.
   Each STP phase fills context with research and verification noise; the
   next phase reads its inputs from disk, so failing to clear strictly hurts.

### Root Causes
1. Producer/consumer naming drift survived an incomplete rename.
2. The whiteboard offer was modeled as opt-in everywhere, including in the
   command literally named after it.
3. Inter-command handoffs were modeled as command-only ("/stp:next") instead
   of session-transition ("/clear, then /stp:next").

### Files Changed
**Filename contract fix:**
- `whiteboard/serve.py` — added graceful 302 redirect for unknown paths
  (browser autocomplete `/en` no longer shows a raw Python 404 page); real
  files under the plugin dir still serve normally
- `commands/whiteboard.md` — 3 references unified to `whiteboard-data.json`
- `commands/work-quick.md` — 4 references unified (incl. the impact-scan
  existence check)
- `commands/work-full.md` — 3 references unified
- `commands/plan.md` — line 116 unified (lines 59, 454 were already correct)

**Mandatory whiteboard server start:**
- `commands/whiteboard.md` — replaced the optional "## Visual Whiteboard"
  offer with a mandatory "## Start the Whiteboard Server (MANDATORY — your
  FIRST action, before anything else)" block. Server starts unconditionally
  at the top of every `/stp:whiteboard` invocation. No AskUserQuestion gate,
  no "if they accept" branch.
- `commands/plan.md` — same pattern. Server starts at the top of every
  `/stp:plan` invocation.
- `commands/work-full.md` — UI/UX branch (line 263) reordered: server starts
  BEFORE the design system is generated, never after. Step numbering
  adjusted (4 → 5 for the persist step).
- `commands/work-quick.md` — UI/UX branch (line 101) reordered the same way.

**/clear in next-step handoffs:**
- `commands/whiteboard.md` — final completion box now recommends
  "1. /clear, 2. then ONE of: /stp:work-full | /stp:work-quick | /stp:work-adaptive"
- `commands/plan.md` — `► Next: /clear, then /stp:work-quick [FIRST FEATURE]`
- `commands/new-project.md` — `► Next: /clear, then /stp:plan`
- `commands/review.md` — `► Next: /clear, then /stp:work-quick [NEXT FEATURE]`
- `commands/work-quick.md` — both completion boxes (next feature, next
  milestone) prepend `/clear, then`

**Project conventions added (so this can't regress):**
- `CLAUDE.md` — two new entries in `## Key Rules`:
  1. Whiteboard server start is mandatory + first for `/stp:whiteboard` and
     `/stp:plan`; never gated behind AskUserQuestion or "if they accept".
  2. `/clear` must be suggested before every inter-command transition in
     completion boxes.

**Release plumbing:**
- `.claude-plugin/plugin.json` — version 0.3.0 → 0.3.1
- `CHANGELOG.md` — created (this file)

### Verification
**Live server test (filename contract + 404 fallback) — all 6 routes green:**
- `/` → 200 serves `index.html`
- `/data.json` → 200 returns the contents of `.stp/whiteboard-data.json`
- `/codebase-map-template.html` → 200 (real file under plugin dir still served)
- `/en`, `/notafile.xyz`, `/some/deep/path` → 302 to `/`
- End-to-end: agent writes `.stp/whiteboard-data.json` → `/data.json` returns
  the exact payload → previous silent-failure mode is gone

**Codebase grep checks (must-be-empty after fix):**
- `grep -rn "explore-data.json" commands/ whiteboard/` → 0 matches
- `grep -n "Next.*\/stp:" commands/*.md | grep -v "/clear"` → 0 matches
- `grep -B1 -A1 "If they accept" commands/whiteboard.md commands/plan.md` → 0 matches

### Spec Delta
- **Added:**
  - Graceful 404 fallback policy in `serve.py` (unknown paths redirect to
    `/` instead of emitting Python's default 404 HTML).
  - Mandatory unconditional whiteboard server start as the first action of
    `/stp:whiteboard` and `/stp:plan`.
  - `/clear` recommendation before every inter-command transition in
    completion boxes across new-project, plan, whiteboard, work-quick,
    review.
  - Two new entries in CLAUDE.md `## Key Rules` enforcing the above.
- **Changed:**
  - Canonical whiteboard data filename is `.stp/whiteboard-data.json`
    (was ambiguously `explore-data.json` in some command docs).
  - The whiteboard offer is no longer modeled as opt-in for `/stp:whiteboard`
    and `/stp:plan` — it is the literal first action.
  - In `/stp:work-quick` and `/stp:work-full` UI/UX branches, the server
    starts BEFORE design system generation, not after.
- **Constraints introduced:**
  - Any future command that writes live whiteboard data MUST use
    `.stp/whiteboard-data.json`. Single source of truth between producer
    (command agent) and consumer (`whiteboard/serve.py`).
  - The whiteboard server MUST start as the first action of any command
    whose primary purpose is whiteboarding (`/stp:whiteboard`, `/stp:plan`).
    No AskUserQuestion gate, no conditional offer.
  - Any command's completion box that recommends a follow-up `/stp:*`
    command MUST prepend `/clear, then` to the recommendation.
- **Dependencies created:** none — these are protocol fixes, not new modules.

### Lessons
**Lesson 1 — Cross-file contracts.** When renaming a cross-file contract,
grep for BOTH names and keep replacing until zero occurrences of the old name
remain. A half-finished rename that leaves consumer and producer out of sync
fails silently — the system technically "works" but never shows the data,
which is harder to diagnose than a crash. The producer thinks it wrote the
file, the consumer thinks no file exists, and neither complains.

**Applies when:** renaming any filename, env var, URL path, or config key
that crosses a process boundary (writer vs. reader) in an agent pipeline.

**Lesson 2 — Match command name to mandatory action.** If a command's name
declares its primary purpose (`/stp:whiteboard`, `/stp:debug`, `/stp:plan`),
that purpose's enabling action must be unconditional and first. Modeling it
as an "if they accept" offer creates a class of failure where the agent can
reach the work step without the prerequisite running. The user already
answered "do you want this?" by typing the command — re-asking is friction
at best and a footgun at worst.

**Applies when:** writing any orchestrator command that spins up a
long-running side process (server, watcher, dashboard) the user must see.

**Lesson 3 — Inter-command handoffs are session transitions.** Recommending
`/stp:next-command` without `/clear` ignores that each STP phase fills the
context window with research, verification noise, and intermediate state
the next phase doesn't need. Always model handoffs as `(/clear, then
/stp:next)` so the next phase reads its inputs fresh from disk.

**Applies when:** any command's completion box recommends a follow-up STP
command. The convention is now in CLAUDE.md `## Key Rules` and enforced
across all `► Next:` blocks.

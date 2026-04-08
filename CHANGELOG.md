# Changelog

All notable changes to STP are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2] — 2026-04-08 — feat: enforcement layer — markdown "MANDATORY" becomes hook-enforced

### Summary
STP's workflow rules were written as **suggestions in markdown** ("MUST", "MANDATORY", "this is required"). Claude routinely routed around them. The v0.3.1 post-mortem was a landing page shipped with every AI-slop tell the design system explicitly forbade: gradient headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand mark, template copy, center-everything layout. The `/ui-ux-pro-max` skill never fired. Step 1b of `/stp:work-quick` was labelled MANDATORY — and was pure markdown.

This release converts the most load-bearing "MANDATORY" rules into hooks. Per Shrivu Shankar's [Claude Code enterprise guide](https://blog.sshh.io/p/how-i-use-every-claude-code-feature): *"Hooks are the deterministic 'must-do' rules that complement the 'should-do' suggestions in CLAUDE.md."* Per [Knostic's openclaw-shield writeup](https://www.knostic.ai/blog/why-we-built-openclaw-shield-securing-ai-agents-from-themselves): *"prompt injection is a weak guardrail. A tool-based gate where the model gets a real DENIED response is far more effective."*

Three new hooks, three new stop-verify gates, two markdown bug fixes, 49/49 tests green.

### Added

- **`hooks/scripts/ui-gate.sh`** — PreToolUse blocker for new UI file writes (`.html`, `.tsx`, `.jsx`, `.vue`, `.svelte`, `.astro`, `.css`, `.scss`, `.sass`, `.less`). Blocks until `.stp/state/ui-gate-passed` marker exists. Carve-outs: tests, stories, configs, migrations, file overwrites. Escape hatch: `STP_BYPASS_UI_GATE=1`. Closes v0.3.1 AI-slop-landing-page failure.
- **`hooks/scripts/anti-slop-scan.sh`** — PostToolUse deterministic grep scanner for 7 AI-slop patterns: gradient headlines, "Now in beta" eyebrow pills, template hero copy ("without the X headache"), "ship in minutes" speed promises, sparkles brand marks, center-everything defaults, 3+ boxed benefit cards. **1 finding → WARN**. **2+ findings → BLOCK** with exit 2. Escape hatch: `STP_BYPASS_SLOP_SCAN=1`.
- **`hooks/scripts/whiteboard-gate.sh`** — PreToolUse auto-starter for the whiteboard server before writes to `.stp/whiteboard-data.json`. Detects existing process via `pgrep` or listening port via `ss`/`netstat`/`lsof`. If not running, auto-starts `start-whiteboard.sh` in background and waits briefly for the port to bind. Closes the "server-start and data-write are separable steps so Claude reaches data-write first" failure that v0.3.1 only addressed in documentation. Escape hatch: `STP_BYPASS_WHITEBOARD_GATE=1`.
- **`hooks/scripts/stop-verify.sh` — Gate 11 (WARN)** — Spec delta merge-back. When a feature is complete, checks CHANGELOG.md for a `### Spec Delta` block and verifies ARCHITECTURE.md was touched in the last 5 commits. Catches the "built feature, forgot merge-back" failure mode.
- **`hooks/scripts/stop-verify.sh` — Gate 12 (BLOCK)** — Critic required for full-cycle work. When `.stp/docs/PLAN.md` exists AND the feature is complete, requires `.stp/state/critic-report-*.md` newer than the feature file. Workflow gate — doesn't increment the 3-retry technical counter, so it can't brick a session.
- **`hooks/scripts/stop-verify.sh` — Gate 13 (BLOCK)** — QA required for UI features. When `.stp/state/ui-gate-passed` exists AND the feature is complete, requires `.stp/state/qa-report-*.md`. Workflow gate.
- **`hooks/scripts/stop-verify.sh` — `feature_is_complete()` helper** — robust against a latent `grep -c '[ ]' FILE || echo "0"` bug that produces `"0\n0"` when grep matches zero lines AND exits 1, breaking downstream numeric comparisons. The helper strips non-numeric characters and defaults to 0.

### Changed

- **`hooks/hooks.json`** — added `PreToolUse` section with `ui-gate.sh` + `whiteboard-gate.sh` chain. Added `anti-slop-scan.sh` to the existing `PostToolUse` chain. Extended `SessionStart` to wipe `.stp/state/ui-gate-passed` on every `/clear` so fresh sessions re-confirm design direction.
- **`commands/work-quick.md` Step 1b** — (1) replaced hardcoded `[ -f "design-system/MASTER.md" ]` with `find design-system -maxdepth 4 -name "MASTER.md"` to support nested per-page design systems like `design-system/landing/MASTER.md` (the exact path the v0.3.1 user requested that the old check missed); (2) added mandatory design consultation step that runs **even when MASTER.md already exists** — reading tokens is not the same as a consultation; (3) added anti-slop commitment language to the approval `AskUserQuestion`; (4) added marker-write step (`touch .stp/state/ui-gate-passed`) to release the hook gate; (5) added "this is hook-enforced" note pointing at `hooks/scripts/ui-gate.sh`.
- **`commands/work-full.md` Phase 3b** — same five fixes applied symmetrically.

### Fixed

- **v0.3.1 path-glob regression** — `commands/work-quick.md:90` and `commands/work-full.md:251` checked `design-system/MASTER.md` literally, missing nested paths. The v0.3.1 landing page user explicitly said *"using design-system/stp-test-landing/MASTER.md"* — the check returned NONE, Claude rationalized *"user already provided one, I'll just read it"*, and Step 1b was skipped entirely. Fixed in both files via `find` with `-maxdepth 4`.

### Spec Delta

- **Added:**
  - 3 new PreToolUse/PostToolUse hook scripts (`ui-gate.sh`, `anti-slop-scan.sh`, `whiteboard-gate.sh`)
  - 3 new gates in `stop-verify.sh` (Gate 11 WARN, Gate 12 BLOCK, Gate 13 BLOCK)
  - `feature_is_complete()` helper function
  - 3 new session-scoped marker file contracts: `.stp/state/ui-gate-passed`, `.stp/state/critic-report-*.md`, `.stp/state/qa-report-*.md`
  - 3 new environment variable escape hatches: `STP_BYPASS_UI_GATE`, `STP_BYPASS_SLOP_SCAN`, `STP_BYPASS_WHITEBOARD_GATE`

- **Changed:**
  - STP's enforcement model. Previously: rules lived in markdown, Claude chose whether to apply them. Now: load-bearing rules live in hooks, Claude gets a hard DENIED and structured feedback. Markdown labels remain as documentation but are no longer the enforcement surface.
  - `hooks/hooks.json` schema — PreToolUse now present with 2-hook chain; PostToolUse grew from 1 to 2 hooks; SessionStart command is now a compound command (marker wipe + existing session-restore chain).
  - Layer 0 of the verification stack — previously implicit/absent, now explicit as "pre-action gates." Layers 1-6 (executable specs → production verification) remain unchanged as post-hoc stages.

- **Constraints introduced:**
  - New UI file writes (`.html`, `.tsx`, `.jsx`, `.vue`, `.svelte`, `.astro`, `.css`) MUST be preceded by a design-system consultation that touches `.stp/state/ui-gate-passed`. Overwrites of existing files are exempt.
  - Writes to `.stp/whiteboard-data.json` MUST have the whiteboard server running (auto-started if missing).
  - Features built under a `PLAN.md` (i.e., `/stp:work-full` territory) MUST run `/stp:review` before Claude can stop. The Critic can no longer be silently skipped.
  - UI features (identified by the presence of the `ui-gate-passed` marker) MUST have a QA report before Claude can stop. agent-browser QA can no longer be silently skipped.
  - All completed features SHOULD emit a `### Spec Delta` block in CHANGELOG.md and touch ARCHITECTURE.md (Gate 11 warns but does not block).

- **Dependencies created:**
  - `ui-gate.sh` depends on `.stp/state/ui-gate-passed` marker contract. `SessionStart` hook is now responsible for wiping it.
  - `whiteboard-gate.sh` depends on `start-whiteboard.sh` being at `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh` and being executable.
  - `stop-verify.sh` Gates 12/13 depend on filename contracts: `.stp/state/critic-report-*.md` and `.stp/state/qa-report-*.md`. Any command that wants to satisfy the gate writes a file matching those globs newer than `current-feature.md`.
  - `commands/work-quick.md` and `commands/work-full.md` now explicitly depend on `hooks/scripts/ui-gate.sh` for the "mandatory" label to have teeth. The doc references the hook by path so future refactors know they're coupled.

### Deliberately NOT done

- **Pre-work `AskUserQuestion` gate** (audit gap #2) — deferred. Risk of false-triggering on `/stp:continue`, `/stp:resume`, `/stp:autopilot` flows without careful session-scoped carve-outs. Will revisit once the session-ID primitive is more accessible from hooks.
- **Context7/Tavily research gate** (audit gap #3) — deferred. Research is judgment; sometimes legitimately cached from earlier in the session. Transcript parsing is brittle and false positives would train the agent to ignore warnings. Stays as documentation-only.
- **/clear between commands** (audit gap #8) — purely cosmetic, already handled by completion-box templates. No hook needed.

### Research sources behind this release

- [Claude Code hooks docs — deterministic control layer](https://code.claude.com/docs/en/hooks)
- [Claude Code hooks guide](https://code.claude.com/docs/en/hooks-guide)
- [Shrivu Shankar — "Hooks are the deterministic must-do"](https://blog.sshh.io/p/how-i-use-every-claude-code-feature) — block-at-submit not block-at-write insight
- [Knostic openclaw-shield — tool-based gates beat prompt injection](https://www.knostic.ai/blog/why-we-built-openclaw-shield-securing-ai-agents-from-themselves)
- [Claude Code Hooks Reference: All 12 Events — Pixelmojo](https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns)
- [AgentSpec: Runtime Enforcement for LLM Agents (ICSE '26)](https://cposkitt.github.io/files/publications/agentspec_llm_enforcement_icse26.pdf) — neurosymbolic enforcement
- [Anthropic: Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

### Test coverage

- 10 tests for `ui-gate.sh` (match, carve-outs, markers, bypass)
- 8 tests for `anti-slop-scan.sh` (all 7 pattern categories + carve-outs)
- 4 tests for `whiteboard-gate.sh`
- 5 tests for new `stop-verify.sh` gates (11/12/13 + release paths)
- 2 regression tests for existing gates
- 3 end-to-end scenario tests reproducing the exact v0.3.1 failure

**49/49 tests passing. 0 regressions.**

---

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

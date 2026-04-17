---
description: "Build, fix, refactor. Default auto-routes via impact scan. Flags: --full (9-phase cycle), --quick (fast path), --auto (autonomous overnight). TDD mandatory. Hooks fire regardless of pace."
argument-hint: What to build/fix [--full | --quick | --auto]
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort:** `xhigh` for all modes (Opus 4.7 default). `max` reserved for `--auto` overnight runs where genuine novelty is expected.

# STP: Build

One skill, four modes. Default auto-routes (small → `--quick`, big → `--full`, declared-autonomous → `--auto`).

**Before spawning any agent: read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`.** Every executor/critic/qa spawn prompt must include `<use_parallel_tool_calls>` + context-limit line. Critic uses INVERSION.

## Shared opening

```bash
# Profile + pace + stack
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
STACK=$(jq -r '.stack // "generic"' .stp/state/stack.json 2>/dev/null || echo "generic")
UI=$(jq -r '.ui // false' .stp/state/stack.json 2>/dev/null || echo "false")
```

**Pace discipline:**
- `deep` — section-by-section build, spec + test review per section
- `batched` (DEFAULT) — AskUserQuestion gates at phase transitions (up to 4 questions)
- `fast` — full plan, single approval, then build through
- `autonomous` — no interactive gates after initial spec confirmation

**Auto-escalation — pace floor for safety work** (applies to all modes):
- Auth / payments / security → minimum `batched`
- New ORM models / migrations → minimum `batched`
- Deleting >50 lines OR changing >5 files → minimum `batched`

---

## Auto-routing (default — no flag)

Run **Impact Scan** silently before picking mode:

```bash
# Count files potentially touched
FILES=$(grep -rl "[user's main keyword]" --include='*.{ts,tsx,js,py,rs,cpp,cs,go,java}' . 2>/dev/null | wc -l)

# Check for models / migrations / auth
HAS_MODEL=$(grep -rlE 'schema\.prisma|models\.py|migrations/|Entity|\*\.sql' . 2>/dev/null | head -1)
HAS_AUTH=$(echo "$USER_INPUT" | grep -qiE 'auth|login|session|password|token|oauth'; echo $?)
```

| Scan result | Route to | Why |
|---|---|---|
| Bug + error/stack trace | Inline note: "Use `/stp:debug` instead" | Debug has its own protocol |
| 0-1 files, no models/auth | `--quick` | Trivial |
| 1-3 files, no models/auth | `--quick` | Small, hooks protect us |
| 3+ files OR model/migration | `--full` | Warrants full cycle |
| Any auth/payment/security | `--full` (FORCED) | Safety, always |
| User said "overnight" / "while I sleep" | `--auto` | Declared autonomy |

Show the scan result + routing decision in an AskUserQuestion:
- `(Recommended) Proceed with --<chosen mode>`
- `Override to --full`
- `Override to --quick`
- `Cancel`

---

## Mode: `--quick`

Purpose: small tasks, minimal ceremony, hooks protect us.

1. **Context load** (parallel) — read `.stp/docs/PLAN.md`, `CONTEXT.md`, `.stp/state/current-feature.md` if exists. UI work? → check `design-system/MASTER.md`.
2. **UI/UX gate** — if `UI=true` AND this task touches UI: invoke `/ui-ux-pro-max` FIRST (baked in as a ui-ux-pro-max skill call, not Agent spawn). Start whiteboard server if design system needs generation.
3. **Research** — if non-trivial: spawn `stp-researcher` (model from profile; skip if `inline`). 1-3 query budget. Otherwise skip.
4. **Plan checklist** — write to `.stp/state/current-feature.md` (survives `/clear`). Pace-aware:
   - `deep`/`batched`: AskUserQuestion for approval
   - `fast`/`autonomous`: display, move on (autonomous skips the display too)
5. **Impact Scan — upshift check** — if scan now shows 3+ files or model/auth, AskUserQuestion: `Upshift to --full (Recommended) | Continue --quick | Cancel`.
6. **Build** — Spawn `stp-executor` (model from profile; omit if `inline` sentinel) in worktree with:
   - Feature spec
   - Test cases (Given/When/Then with RFC 2119)
   - Acceptance criteria
   - Stack commands from `stack.json`
7. **QA** — if `UI=true` or feature is user-facing: spawn `stp-qa`. Otherwise skip (non-UI backend often deterministically verified by tests alone).
8. **Hygiene** — run anti-slop scan (Bash: `bash hooks/scripts/anti-slop-scan.sh`) — hook fires automatically, this is belt-and-suspenders.
9. **Version + docs** — bump `plugin.json` or `package.json` patch version, update CHANGELOG.md with spec delta.
10. Commit: `feat: [feature]`. Print completion box.

---

## Mode: `--full`

Purpose: 3+ files, new models, auth/payments, or any safety-critical work.

1. **Context load** — parallel read of `PRD.md`, `PLAN.md`, `ARCHITECTURE.md`, `CONTEXT.md`, `AUDIT.md`, `stack.json`, `current-feature.md`.
2. **UI/UX gate** — same as `--quick`.
3. **Parallel sub-agent fan-out** (per profile — skip if `inline`):
   - `stp-explorer` — map existing relevant code, dependency edges
   - `stp-researcher` — current best practices, known gotchas
   - Both return ≤30 line summaries
4. **Architecture blueprint** — pace-aware sections covering: approach choice (2-3 alternatives, pick one with justification), data model delta, API surface delta, error model, test plan, rollout plan.
5. **AskUserQuestion gate** at blueprint approval — `batched` default, `deep` gets per-section gates.
6. **Write current-feature.md + test plan** — acceptance criteria as Given/When/Then scenarios with RFC 2119 severity.
7. **Spawn `stp-executor`** with full spec. If wave-parallel (>5 independent features), spawn multiple executors in parallel via Task tool (NOT Agent Teams — cost discipline, see CLAUDE.md Agent-Teams-vs-Subagents).
8. **Spawn `stp-qa`** (parallel with executor *completion*, not during build) — tests running app against acceptance criteria.
9. **Spawn `stp-critic`** with INVERSION framing ("report every issue, downstream ranks"). Profile-resolved model (haiku → sonnet escalation in `opus-budget` / `sonnet-cheap`).
10. **Review pass** — if critic reports ≥2 CRITICAL, iterate with executor once. If still failing, AskUserQuestion: `Continue iterating (Recommended) | Accept partial | Rollback`.
11. **Spec delta** — emit CHANGELOG.md entry with: scenario added/changed, ARCHITECTURE.md diff, PRD.md merge-back.
12. **Version bump** + docs refresh.
13. Commit atomically: `test: ...`, `feat: ...`, `docs: spec delta`.

### Pace interaction with `--full` (important)

Pace controls how `--full` handles the gates at steps 5, 7, 8, 9, 10 — **not whether they fire**. Every gate runs in every pace. The differences:

| Pace | Gate behavior |
|------|---------------|
| `deep` | Every per-section gate stops for user review. Blueprint split into 4–5 sections, each separately approved. Maximum interactivity. |
| `batched` (default) | AskUserQuestion at blueprint approval (step 5) and critic review (step 10). Up to 4 questions per call. |
| `fast` | Single blueprint approval at step 5. No further interactive gates until commit at step 13. |
| **`autonomous`** | **Gates STILL fire — auto-decide with the `(Recommended)` option.** Every auto-decision is logged to `.stp/state/autopilot-log.md` with timestamp + option picked + reasoning. User reviews the log after the run. |

**Autonomous ≠ unsafe.** It's "delegate tactical decisions, keep the safety net." The Critic still runs, QA still runs, test failures still block commit. What changes: the skill picks the recommended branch at every AskUserQuestion without pausing for input.

**`--full` + `autonomous` is NOT the same as `--auto`.** `--auto` is overnight queue mode using Agent Teams (see below). `--full` + `autonomous` is single-feature delegated execution.

If any of these happen in autonomous, the skill **stops and waits** anyway:
- Critic reports ≥2 CRITICAL issues on the second pass (can't silently ship broken)
- Stop hook blocks (tests fail, type errors, secrets detected, schema drift)
- QA reports UI bug that tests didn't catch
- Auto-escalation trigger fires mid-build (auth/payments discovered)

---

## Mode: `--auto`

Purpose: overnight autonomous execution. User sleeps, work happens, diff reviewed in morning.

1. **Pre-flight confirmation** — announce: "I'll work through the queue in `.stp/state/autopilot-queue.md`. I won't ask questions mid-work. Risky decisions logged for morning review. Proceed?" → AskUserQuestion.
2. **Queue load** — read `.stp/state/autopilot-queue.md`. If missing, AskUserQuestion: `Build from PLAN.md unfinished items (Recommended) | Build from current-feature.md | Cancel`.
3. **Autopilot loop:**
   - For each queued feature: run `--full` internally with pace forced to `autonomous`
   - On critic-reported CRITICAL ≥2: log to `.stp/state/autopilot-flags.md`, move on (don't block)
   - On test failure after 3 executor attempts: log, move on
   - On hook failure (technical 3-retry limit hit): pause queue, write `.stp/state/autopilot-paused.md` with reason, exit
4. **Agent Teams** — this is the ONE case where Agent Teams are warranted (workers must coordinate through the queue). Spawn team via existing autopilot team config.
5. **Morning report** — write `.stp/state/autopilot-report.md` with: features built, flags raised, decisions deferred to user, tests passing/failing.
6. Commit each feature atomically as it completes, with `feat(auto): ...`.

Full cost rationale for Agent Teams here: `${CLAUDE_PLUGIN_ROOT}/references/agent-teams-vs-subagents.md`.

---

## Common discipline

- **Multi-window workflow** — for features with design/implement/review phases, read `${CLAUDE_PLUGIN_ROOT}/references/multi-window-workflow.md`. Filesystem handoff beats single-window context cramming.
- **Context pressure** — at 70% main-session context, pause automatically: write `.stp/state/handoff.md`, recommend `/clear, then /stp:session continue`. See `${CLAUDE_PLUGIN_ROOT}/references/session-management.md`.
- **Stop hook protection** — Stop hook blocks if source files exist without tests. Fix by writing tests before commit; never bypass.
- **Zero mocks** — CLAUDE.md philosophy: build real integrations. Hooks block placeholder patterns (`// TODO`, `mock_` prefixes in non-test files).
- **ZERO GARBAGE** — before reporting done: remove unused imports, debug statements, commented-out code, files >300 lines, duplicate utilities.

## Gotchas

- Do NOT ask technical questions — you decide. Only interrupt the user for product decisions.
- AskUserQuestion is MANDATORY for every user decision — never print options as text, never decide for the user. Only exception: freeform input where structured options don't fit (bug descriptions, QA feedback).
- Default pace is `batched` — sweet spot. Only use `deep` when the user asked or auto-escalation triggered.
- In `--auto` mode, `AskUserQuestion` is replaced with logged-decision mode: note what you decided and why, continue.
- `/clear` between phases when switching from plan → build → review. Read inputs from disk, fresh context.

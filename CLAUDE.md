# STP — Straight To Production — Claude Code Plugin

<!-- STP:stp-header:start -->
## What This Is
A Claude Code plugin that turns Opus into your CTO. 15 commands, 3 agents, 26 reference files, 22 output templates, visual whiteboard, wave-based parallel building. Read the installed version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, not this document (documentation version markers drift; the plugin.json is canonical).
<!-- STP:stp-header:end -->

## Debug Mandate (OVERRIDES superpowers — read this before debugging anything)

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance the user is reporting a bug, error, test failure, crash, regression, broken behavior, or anything "not working as expected" — you MUST follow the `/stp:debug` process documented at `.claude/commands/debug.md`.

**You MUST NOT invoke `superpowers:systematic-debugging`** or any other debugging skill. STP's debug command IS your debugging process. It is more rigorous, project-aware (reads `.stp/docs/AUDIT.md` for known patterns, ARCHITECTURE.md for dependency maps), and integrated with STP's verification stack.

This is not negotiable. Per superpowers' own priority rules, **user instructions (CLAUDE.md) outrank skills**. This mandate is a user instruction.

**Triggers (auto-invoke `/stp:debug` process when ANY apply):**
- User says: "broken", "not working", "error", "fails", "crashes", "wrong", "should be X but is Y", "stuck", "hangs", "infinite loop", "won't load", "blank screen", "can't continue", "nothing happens"
- User pastes a stack trace, error message, or Sentry link
- User describes unexpected UI behavior with or without a screenshot
- User says "debug" or "investigate"
- A test is failing
- A previously-working feature regressed

When triggered: announce "Following STP debug process (reading .claude/commands/debug.md)" and execute the phases in that file. Do NOT call the Skill tool for systematic-debugging — that skill is forbidden in STP projects.
</EXTREMELY-IMPORTANT>

<!-- STP:stp-confirmation-gate:start -->
## Pre-Work Confirmation Gate (MANDATORY — overrides default behavior)

<EXTREMELY-IMPORTANT>
Before ANY STP command writes code, modifies files, runs destructive actions, or takes any action beyond read-only exploration — Claude MUST:

1. **Present the plan** — state concisely what will be done and why
2. **Call AskUserQuestion** with structured options covering the plan + sensible alternatives
3. **Mark the recommended option `(Recommended)`** and place it FIRST in the options list
4. **Wait for user approval** before executing anything

**Applies to every `/stp:*` command.** No silent work. No "I'll just start with X." Even trivial-looking edits get a confirmation prompt unless the user has pre-authorized it in the current session.

**Exception clause — the ONLY cases where confirmation can be skipped:**
- The user explicitly said "just do it", "go", "proceed", "yes to all", "no need to ask", or equivalent in the current session
- The user's current message itself IS the confirmation (e.g., they answered an earlier AskUserQuestion and the work falls within that approved scope)
- The action is strictly read-only (Read, Glob, Grep, LS, ctx searches) — reading never needs confirmation
- The user is inside `/stp:autopilot`, where unattended execution is the explicit goal

**This rule OVERRIDES** any STP command's internal instruction to "start working immediately" or "execute the plan." If a command says "begin implementation," pause and confirm the implementation approach first. Commands describe *what* to do — this gate controls *when*.

**Why this exists:** Users have been surprised by work they didn't approve. The cost of one extra confirmation prompt is seconds. The cost of unwanted file edits, deleted content, or wasted build cycles is hours. Confirmation gates beat rollbacks. Per STP philosophy: constraints beat prompts.
</EXTREMELY-IMPORTANT>
<!-- STP:stp-confirmation-gate:end -->

## Architecture
- **Opus** = CTO (plans, researches, reviews, merges, teaches). Builds foundation work directly (DB, auth, config).
- **stp-executor** = builder sub-agent (features on top of foundation, worktree isolation, parallel one-shot subagents via Task tool for wave parallelism — NOT Agent Teams; see `## Agent Teams vs Subagents` for cost rationale). Model = `sonnet` in all profiles.
- **stp-qa** = independent tester sub-agent (tests running app against PRD acceptance criteria). Model = `sonnet` in all profiles.
- **stp-critic** = code reviewer sub-agent (7 criteria + Double-Check Protocol + Claim Verification Gate + 6-layer verification). Model = `sonnet` in intended/balanced, **`haiku` → sonnet escalation in budget-profile** when ≥2 critical issues found.
- **stp-researcher** = context-isolation sub-agent for external research (Context7/Tavily/WebSearch). Model = `inline` in intended-profile (main session handles it), `sonnet` in balanced/budget.
- **stp-explorer** = context-isolation sub-agent for codebase exploration (Glob/Grep across >5 files). Model = `inline` in intended-profile, `sonnet` in balanced/budget.

> **Profile-dependent model assignments.** The sub-agent models above are NOT hardcoded in STP command files — they're resolved per-profile via `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs`. See `## Profile-Aware Execution` below for the resolver pattern every STP command MUST use.

<!-- STP:stp-profile-aware:start -->
## Profile-Aware Execution (MANDATORY for every STP command)

<EXTREMELY-IMPORTANT>
STP supports three optimization profiles that change which Claude models run sub-agents. Every `/stp:*` command MUST resolve the active profile via the canonical CLI BEFORE spawning any sub-agent. Inspired by [GSD's set-profile design](https://github.com/gsd-build/get-shit-done) which works reliably.

**Single source of truth:** `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs`

**Compressed profile index** (same pattern as Vercel's AGENTS.md docs index):

```
[STP Profile Index]|cli: node ${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs|state: .stp/state/profile.json|default: intended-profile
intended-profile :{stp-executor:sonnet,stp-qa:sonnet,stp-critic:sonnet,stp-critic-escalation:sonnet,stp-researcher:inline,stp-explorer:inline,clear:rec,ctx:rec,res-mand:no,exp-mand:no}
balanced-profile :{stp-executor:sonnet,stp-qa:sonnet,stp-critic:sonnet,stp-critic-escalation:sonnet,stp-researcher:sonnet,stp-explorer:sonnet,clear:mand,ctx:mand,res-mand:yes,exp-mand:yes,max-kb:120}
budget-profile   :{stp-executor:sonnet,stp-qa:sonnet,stp-critic:haiku→escal-sonnet,stp-critic-escalation:sonnet,stp-researcher:sonnet,stp-explorer:sonnet,clear:enforced,ctx:hard-block,res-mand:yes,exp-mand:yes,max-kb:100}
```

> **`inherit` sentinel:** no current profile resolves to it (STP uses Sonnet sub-agents intentionally). Retained for future non-Anthropic runtimes. Commands MUST handle it correctly (omit `model=` from spawn). Known limitation + future-profile migration steps: `${CLAUDE_PLUGIN_ROOT}/references/profiles.md`.

**Sentinel values you must understand:**
- `inherit` → **omit the `model=` parameter from the `Agent()` spawn call entirely**. Claude Code inherits the parent session's model. Works on any runtime (Opus 1M, Sonnet 200K, Codex, OpenCode, Gemini CLI). This is GSD's key insight — it avoids hard-coding model IDs that may not be available.
- `inline` → **do NOT spawn a sub-agent at all**. The main session handles this work directly. Used in `intended-profile` for researcher/explorer because Opus 1M can absorb research/exploration inline without context pressure.
- `sonnet` / `opus` / `haiku` → pass the literal value as the spawn `model=` parameter.

**Profile resolution preamble** — every `/stp:*` command that spawns sub-agents MUST start with this block:

```bash
# Resolve all sub-agent models + discipline rules in one call
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
```

This prints KEY=VALUE lines that you remember for the rest of the command:

```
STP_PROFILE=balanced-profile
STP_MODEL_EXECUTOR=sonnet
STP_MODEL_QA=sonnet
STP_MODEL_CRITIC=sonnet
STP_MODEL_CRITIC_ESCALATION=sonnet
STP_MODEL_RESEARCHER=sonnet
STP_MODEL_EXPLORER=sonnet
STP_CLEAR_DISCIPLINE=mandatory
STP_CONTEXT_MODE_LEVEL=mandatory
STP_RESEARCHER_MANDATORY=true
STP_EXPLORER_MANDATORY=true
STP_MAX_MAIN_KB=120
```

For a single agent's model use:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve stp-executor
```

**Sub-agent spawn pattern** (MANDATORY — branch on the resolved value):
```
# All current profiles (intended / balanced / budget) resolve STP_MODEL_EXECUTOR to "sonnet":
Agent(name="build-X", subagent_type="stp-executor", model="sonnet", prompt="...")

# When STP_MODEL_RESEARCHER == "inline" (intended-profile):
# Do NOT spawn anything. Main session does the research directly.

# Forward-compatible: if STP_MODEL_EXECUTOR ever resolves to "inherit"
# (reserved for future profiles or non-Anthropic runtimes), OMIT the model= param:
Agent(name="build-X", subagent_type="stp-executor", prompt="...")
# NO model param — inherits parent session model
```

**Researcher/explorer mandatory rules:**
- `STP_RESEARCHER_MANDATORY=true` → main session MAY NOT call Context7, Tavily, WebSearch, WebFetch directly. ALL external research MUST be delegated to a fresh `stp-researcher` sub-agent. Sub-agent runs the queries, returns ≤30 line summary.
- `STP_EXPLORER_MANDATORY=true` → main session MAY NOT run Glob/Grep operations touching >5 files. ALL multi-file exploration MUST be delegated to a fresh `stp-explorer` sub-agent that returns ≤30 line file:line map.

**/clear discipline by profile:**
- `recommended` (intended) → suggest /clear in completion boxes, do not enforce
- `mandatory` (balanced) → completion boxes MUST recommend `/clear, then /stp:next-command`
- `enforced` (budget) → same as mandatory + warning hook fires at 60% main-session capacity

**Context Mode discipline by profile:**
- `recommended` (intended) → use `ctx_execute_file` for very large outputs
- `mandatory` (balanced) → use `ctx_execute_file` for any operation producing >50 lines
- `hard-block` (budget) → main session BLOCKED from any operation producing >50 lines

**Critic split (budget-profile only — automatic escalation):**
- Pass 1: spawn `stp-critic` with `model=$STP_MODEL_CRITIC` (= `haiku`) for fast pattern-based scan
- If Pass 1 returns ≥2 CRITICAL/FAIL findings: re-spawn `stp-critic` with `model=$STP_MODEL_CRITIC_ESCALATION` (= `sonnet`) for full Double-Check Protocol
- Most builds don't escalate → average critic cost stays low while keeping deep-reasoning safety net for problem builds

**Why this exists:** STP was built around Anthropic's [harness design research](https://www.anthropic.com/engineering/harness-design-long-running-apps) which assumed Opus 4.6 [1M] context. Not every user has Opus access. The profile system lets STP adapt to Sonnet 200K and Haiku-grade verification without dropping the production-quality bar — by leaning harder on sub-agent isolation, filesystem handoffs, and the deterministic verification layers (1-4) that don't depend on model intelligence.

**Adding a new profile** — extend `MODEL_PROFILES` in `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` (one new column per agent). No other changes needed anywhere in STP. The CLI auto-derives `VALID_PROFILES` from the table.

See `${CLAUDE_PLUGIN_ROOT}/references/profiles.md` for the full profile documentation, trade-off tables, and example workflows.
</EXTREMELY-IMPORTANT>
<!-- STP:stp-profile-aware:end -->

## 6-Layer Verification Stack
Each layer catches what the others miss. LLM review (Critic) is Layer 5, not Layer 1.

| Layer | What | Type | Catches |
|-------|------|------|---------|
| 1. Executable specs | BDD tests from PRD acceptance criteria | Deterministic | Logic errors, boundary bugs, missing features |
| 2. Deterministic analysis | Hollow test detection, ghost coverage, placeholder scanning | AST/grep | AI slop in tests, tautological asserts, mock-only suites |
| 3. Mutation challenge | Flip operators, remove guards, change boundaries — do tests catch it? | Adversarial | Tests that look good but verify nothing (57% kill rate for AI tests) |
| 4. Property-based tests | Invariants for all inputs: round-trip, conservation, idempotency | Automated | Edge cases AI never considered |
| 5. Cross-family AI review | Critic (Claude, with Claim Verification Gate) + non-Claude models with role-specific lenses | LLM | Architectural drift, wrong assumptions, correlated blind spots, false-positive behavioral claims |
| 6. Production verification | Canary deploys, metric monitoring | Runtime | Load failures, emergent interactions |

**Key principle:** The Critic handles Layer 5 (structural/architectural review). Behavioral verification (Layer 1) is deterministic — specs pass or fail, no opinions. Using LLM review for behavioral checking is structurally circular.

## Task Routing (Scale-Adaptive — evidence-based, never overconfident)

When the user describes work WITHOUT specifying an STP command, classify using the **Impact Scan** below — not gut feeling.

### Impact Scan (MANDATORY before routing — run silently, takes <5 seconds)

```bash
# 1. Count files that would be touched
grep -rl "[keyword from user's request]" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.rs" --include="*.go" --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=target . 2>/dev/null | wc -l

# 2. Check if models/schema/migrations are involved
grep -rl "[keyword]" --include="*.prisma" --include="*.sql" --include="*migration*" --include="*schema*" --include="*model*" . 2>/dev/null | head -3

# 3. Check if auth/payments/security paths are involved
grep -rl "[keyword]" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -i "auth\|payment\|stripe\|webhook\|middleware\|permission\|role\|token" | head -3
```

### Routing Table (based on scan results, not vibes)

| Impact Scan Result | Classification | Route to | Confidence |
|---|---|---|---|
| 0-1 files, no models, no auth | Trivial | Inline fix — no command | HIGH |
| Bug keyword + error message/stack trace | Bug | `/stp:debug` | HIGH |
| 1-3 files, no models, no auth | Quick task | `/stp:work-quick` | HIGH |
| 3+ files OR any model/migration change | Serious work | `/stp:work-full` | HIGH |
| Any auth/payment/security path touched | Serious work | `/stp:work-full` (always) | FORCED |
| Vague/exploratory ("should I", "how to", "compare") | Thinking | `/stp:whiteboard` | HIGH |

### Rules to prevent overconfidence

1. **Default to MORE ceremony, not less.** When uncertain between `/quick` and `/work`, pick `/work`. The cost of over-planning is minutes. The cost of under-planning is rework.
2. **Auth/payments/security = always `/stp:work-full`.** No exceptions. No downshift. These areas have the highest blast radius.
3. **Never auto-route without showing the scan results.** Show the user: "Impact scan: [N] files, [models: yes/no], [auth: yes/no] → suggesting `/stp:work-full`." They see WHY you chose it.
4. **AskUserQuestion for EVERY routing decision.** The system suggests, the user confirms. No silent routing.
5. **Scan before downshift.** `/stp:work-full` Phase 1 can only downshift to `/stp:work-quick` if the impact scan shows ≤2 files, zero model changes, zero auth paths. Not based on "this seems simple."
6. **Scan before staying on `/stp:work-quick`.** Step 2 research MUST check the impact scan. If it shows 3+ files or any model/auth involvement, upshift is MANDATORY (not optional).

### Routing presentation format

```
AskUserQuestion(
  question: "Impact scan: [N] files affected, [models: yes/no], [auth/payments: yes/no]. Based on this, I recommend [command] because [reason].",
  options: [
    "(Recommended) [command] — [why]",
    "[alternative] — [when this makes sense]",
    "Chat about this"
  ]
)
```

## Commands
**Getting started:**
- `/stp:new-project` — "I'm starting from scratch." Pre-flight → questions → stack → PRD.md
- `/stp:onboard-existing` — "I have an existing codebase." Full analysis → architecture map → plan
- `/stp:plan` — "Design the architecture." 9-phase blueprint → Critic verifies → PLAN.md

**Doing work:**
- `/stp:work-adaptive` — "Let STP decide." Impact scan → auto-classifies → routes to quick or full mode. Use when unsure about scope.
- `/stp:work-full` — "Full cycle, zero compromise." Understand → tools → research → architecture blueprint (13 sub-phases with section-by-section approval) → TDD build → QA → Critic. For 3+ files, new models, auth/payments.
- `/stp:work-quick` — "Just do it." Context → research → build → QA → ship. For small tasks (≤3 files, no new models). Hooks still fire.
- `/stp:research` — "I need to think first." Investigate approaches, create plan. No code written.
- `/stp:debug` — "Something is broken." Root cause analysis → evidence-based fix → defense-in-depth

**Quality + operations:**
- `/stp:review` — "Grade my work." Separate AI evaluates against 7 criteria
- `/stp:autopilot` — "Build overnight." Same as /stp:work-full but AI decides everything
- `/stp:whiteboard` — "I need to think." Explore ideas, compare options → writes structured design brief → build commands pick it up automatically

**Session management:**
- `/stp:progress` — "Where are we?" Status dashboard — what's done, next, warnings
- `/stp:continue` — "Pick up where I left off." Reads state files, starts working immediately
- `/stp:pause` — "I'm done for now." Saves context for next session
- `/stp:upgrade` — "Update STP." Pulls latest + syncs companion plugins + refreshes CLAUDE.md sections + verifies hooks
- `/stp:set-profile-model` — "Pick how STP allocates models." Switch between intended-profile (Opus 1M main + Sonnet sub-agents, original STP behavior), balanced-profile (Opus plans + Sonnet executes + mandatory researcher/explorer sub-agents), or budget-profile (Sonnet writes + Haiku critic with Sonnet escalation, strict context discipline)

<!-- STP:stp-plugins:start -->
## Required Companion Plugins & MCP Servers
STP requires the following installed for full capability:

### Plugins (installed per project)
| Plugin | Purpose | Install |
|--------|---------|---------|
| **ui-ux-pro-max** (v2.5+) | Design intelligence — 67 styles, 161 palettes, 57 font pairings, product-type-aware recommendations. Generates persistent DESIGN-SYSTEM.md. | `npm i -g uipro-cli && uipro init --ai claude` |

### MCP Servers (installed globally)
| MCP Server | Purpose | Why mandatory |
|------------|---------|---------------|
| **Context7** | Live documentation retrieval — resolve library IDs, query current API docs, verify patterns against latest versions | STP's research phases (Phase 4, Phase 5b) depend on Context7 to prevent building on stale training data. Without it, architecture decisions use potentially outdated API knowledge. |
| **Tavily** | Deep web research — best practices, industry standards, competitive analysis, structured research | STP's research phases use Tavily for implementation patterns, security advisories, and "how do production apps solve this" queries. Without it, research depth is significantly reduced. |
| **Context Mode** | Context window protection — runs commands/searches in sandbox, keeps raw output out of context, indexes results for follow-up queries | STP's subagents and research phases generate large outputs. Context Mode prevents context window flooding, enabling longer sessions before compaction. Essential for `/stp:work-full`'s 22 sub-phases. |

### Browser automation tooling (CLI + Claude Code skill — not an MCP)
| Tool | Purpose | Install |
|------|---------|---------|
| **[Vercel Agent Browser](https://github.com/vercel-labs/agent-browser)** | Native Rust CLI for browser automation. STP's QA agent and `/stp:review` use it via the Bash tool to test running apps like a real user — navigate pages, click elements with snapshot refs, fill forms, verify rendered state, take screenshots, test responsive layouts. Without it, QA is limited to API/curl-only testing. | 3-step install: `npm install -g agent-browser` (CLI), `agent-browser install` (downloads Chrome for Testing), `npx skills add vercel-labs/agent-browser` (installs the Claude Code skill at `.claude/skills/agent-browser/SKILL.md` that teaches the snapshot-ref workflow). |

**Enforcement:** `/stp:new-project` and `/stp:upgrade` preflight checks verify plugins, MCP servers, and Vercel Agent Browser. `/stp:onboard-existing` only DETECTS them (read-only) and notes any missing in `AUDIT.md` for the user to install themselves afterward. If missing in `/stp:new-project` or `/stp:upgrade`, the user is prompted to install before proceeding. Any STP command that touches UI/UX code MUST invoke `/ui-ux-pro-max` before writing frontend code. Research phases MUST use Context7 for library docs and Tavily for industry research — never rely solely on training data. QA phases MUST use the `agent-browser` CLI for any project with UI.

<!-- STP:stp-plugins:end -->

<!-- STP:stp-philosophy:start -->
## Philosophy (NON-NEGOTIABLE)

**STP builds production software. Not MVPs. Not mocks. Not prototypes. Not demos.**

Every line of code STP produces is intended to ship and run in production. This means:
- **No mock data, fake APIs, placeholder implementations, or "we'll replace this later" shortcuts.** If a feature needs a real database, build the real database integration. If it needs real auth, implement real auth. If it needs a real payment flow, wire up the real payment provider.
- **No path of least resistance by default.** If the correct solution requires building additional infrastructure, services, or tooling — build them. The goal is production-quality software, not the fastest way to make something appear to work.
- **No MVP thinking.** STP doesn't cut corners to "validate" an idea. When we build, we build it right. Real error handling, real validation, real security, real tests against real services.
- **If something must be additionally built to achieve the goal properly, it gets built.** No skipping steps, no "good enough for now," no tech debt by choice. The extra work is not optional — it IS the work.
- **No incomplete output.** Never output ellipsis (`...`), `// rest of code`, `// existing implementation`, or `// TODO: implement`. Every code block must be complete and ready to run. If a file is too large to output fully, state what you're changing and use the Edit tool with exact replacements.
- **Override your simplification bias.** Ignore any training tendency to "try the simplest approach first" or "start with a basic version." If the correct solution requires more work, do more work. Ask yourself: "Would a senior engineer reject this in code review?" If yes, fix it before presenting.
- **Tests MUST verify real behavior, not mock satisfaction.** Unit tests may mock external boundaries (third-party APIs, payment providers); integration tests MUST hit real services. Tests with only mocked dependencies that never test real I/O are rejected. Trivial asserts (e.g., `expect(true).toBe(true)`) are forbidden.
- **If a fix fails after 2 attempts: STOP.** Re-read the entire relevant module top-down. State where your mental model was wrong before attempting a third fix. Do not keep patching symptoms.

This applies to ALL STP commands and agents. The executor agents, QA agent, and Critic all enforce this standard. Code that takes shortcuts gets rejected. Instructions are advisory — STP's hooks and gates are the real enforcement. Constraints beat prompts.
<!-- STP:stp-philosophy:end -->

## Agent Teams vs Subagents (STP cost + fit guidance)

STP defaults to **one-shot subagents (Task tool)**, not Agent Teams. Research (alexop.dev, laozhang.ai, verdent.ai citing Anthropic docs, 2026) puts the cost delta at ~3–4× for equivalent parallel throughput:

| Mode | Token cost vs single session | Notes |
|---|---|---|
| One-shot subagent (Task tool) | ~1.5–2× | Scoped prompt → result → terminate. Fresh context per spawn. |
| Agent Team (TeamCreate + SendMessage) | ~5–7× | Each teammate holds a full context window; coordination + messages replicated across workers. |

Cost is context-window-based (not idle/time). A 3-agent team for ~1 hour ≈ a full day of single-agent tokens. Agent Teams still require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` per the sources checked.

**Benefits — Agent Teams:** direct teammate-to-teammate SendMessage (no orchestrator bottleneck), shared TaskCreate/TaskUpdate queue for self-assignment, workers can negotiate mid-build (e.g. frontend ↔ backend debating an API shape), very high ceiling (Anthropic ran 16 parallel agents on a 100K-line Rust C compiler internally).

**Benefits — regular subagents:** 3–4× cheaper for the same parallel throughput, fresh context per spawn (no accumulation), isolated failures (one bad spawn can't poison siblings), simpler lifecycle (no TeamCreate/TeamDelete, no message routing), results return summarized rather than replicated into N contexts.

**STP flow → mode mapping (authoritative):**

| STP flow | Use | Why |
|---|---|---|
| `/stp:work-full` build → QA → Critic | **Subagents** | Sequential, each reads prior output from disk via `.stp/state/` — zero cross-talk needed |
| `/stp:work-full` parallel waves (independent features) | **Subagents** | Wave members are intentionally independent; worktree isolation assumes no mid-build negotiation |
| `/stp:research` + `stp-researcher` + `stp-explorer` | **Subagents** | Pure context isolation, return ≤30-line summary — Teams would just inflate cost |
| `/stp:debug` (tracer + challenger + tester loop) | **Subagents** | Filesystem evidence board works fine; Teams only help if workers must argue in-context |
| `/stp:autopilot` long unattended queue | **Agent Teams justify themselves** | Shared task queue + overnight self-assignment is the canonical Teams use case |
| Frontend ↔ backend negotiating API contracts mid-build | **Agent Teams** | STP doesn't currently do this — if a future flow needs it, use Teams |

**Decision rule:** default to subagents. Only reach for Agent Teams when workers must communicate with *each other*, not just report upward — and even then, only in `/stp:autopilot` or explicitly coordination-heavy flows. STP's existing filesystem handoff pattern (`.stp/docs/`, `.stp/state/`) is strictly cheaper and safer for everything else.

**Caveat:** the 5–7× figure comes from community sources citing Anthropic docs, not a raw Anthropic whitepaper. Directionally solid, exact multiplier varies with team size and model mix.

<!-- STP:stp-rules:start -->
## Key Rules
- Opus NEVER writes implementation code (except foundation: DB, auth, config, one-line fixes)
- ALL features delegate to Sonnet executor sub-agents (Task tool) with worktree isolation — NOT Agent Teams by default (see `## Agent Teams vs Subagents` below for cost rationale)
- AskUserQuestion tool is MANDATORY for ALL user decisions — NEVER print options as text, NEVER skip, NEVER decide for the user. Only exception: freeform input where structured options don't make sense (bug descriptions, QA feedback, feature requests)
- TaskCreate/TaskUpdate tracks ALL progress visibly
- README.md updated + VERIFIED after every feature
- 8-part research before every feature (codebase, impact, feature, security, resilience, edge cases, backward integration, anti-hallucination)
- Spec-first TDD: acceptance criteria → executable spec tests → behavioral tests → property-based tests → implementation. Stop hook blocks if no tests exist. Tests must verify real behavior, not mock satisfaction
- /simplify + hygiene scan after every build
- Version bump + CHANGELOG + CONTEXT.md update after every feature
- **Whiteboard server is MANDATORY and FIRST** for `/stp:whiteboard` and `/stp:plan` — literal first action, no AskUserQuestion gate. Start command: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &`. For `/stp:work-quick`/`/stp:work-full` UI/UX detection, server starts BEFORE design system generation. Reason: a whiteboard the user can't see is broken. (v0.3.1 fix.)
- **FILENAME CONTRACT — whiteboard data file is ALWAYS `.stp/whiteboard-data.json`. NEVER any other name.** Forbidden aliases (all BLOCKED by `hooks/scripts/whiteboard-gate.sh`): `.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`. The server (`whiteboard/serve.py`) polls only the canonical path. Writes to any other name land in a file nothing watches. (v0.3.3 post-mortem: hallucinated `explore-data.json` from training data.)
- **/clear MANDATORY before every inter-command transition.** Completion boxes recommending a follow-up `/stp:*` command MUST say `/clear, then /stp:next-command`, never `/stp:next-command` alone. Reason: next phase reads inputs from disk (PLAN.md, design-brief.md, CHANGELOG.md, current-feature.md), clear context is strictly better. **Exception:** after `/stp:upgrade` with hook file changes, recommend `/exit → restart claude → (optional) /clear` — `/clear` alone does NOT reload hooks.
<!-- STP:stp-rules:end -->

<!-- STP:stp-output-format:start -->
## CLI Output Formatting (ENFORCED)
ALL STP command output MUST use the visual templates in `.stp/references/cli-output-format.md`. Read it before displaying any status, progress, or completion information. Key rules:
- **Output formatted blocks via `echo -e` (Bash tool)** to render ANSI colors — monochrome is NOT acceptable
- Every `/stp:` command starts with a **Command Banner** (╔═╗ cyan double-line box with command name + tagline)
- Major events (feature complete, milestone, bug fixed) use **cyan double-line boxes** (╔═╗)
- Evidence/data (scans, reports, QA) use **dim cyan single-line boxes** (┌─┐)
- Teach moments use **dim magenta prefix** (┊) — subtle, never outshine actual output
- Color palette: cyan borders, bold white titles, green ✓, red ✗, yellow ⚠, bold yellow ★, blue ► next steps
- Always `\033[0m` reset after every colored segment
<!-- STP:stp-output-format:end -->

<!-- STP:stp-dirmap:start -->
## Directory Map, Memory Strategy, Structured Spec Format, Spec Delta System

Full detail lives in **`.stp/CLAUDE.md`** — auto-loads when Claude accesses files under `.stp/` (which is exactly when those sections are needed). Covers: `.stp/docs/` + `.stp/state/` + `.stp/references/` directory maps, file-based memory strategy, Given/When/Then + RFC 2119 spec format, Spec Delta merge-back system.

**Quick reference** (when NOT already under `.stp/`):
- `.stp/docs/` — PRD.md (requirements), PLAN.md (architecture), ARCHITECTURE.md (codebase map), AUDIT.md (production health), CONTEXT.md (<150 lines concise ref), CHANGELOG.md (history with spec deltas)
- `.stp/state/` — current-feature.md, handoff.md, state.json (survive `/clear`)
- `.stp/references/` — security, accessibility, performance, production, cli-output-format.md (read BEFORE writing matching code)
- `.claude/skills/ui-ux-pro-max/` — invoke `/ui-ux-pro-max` BEFORE any UI/UX code
- Memory = file-based, disk is truth. On new session: read CHANGELOG + ARCHITECTURE + PLAN. Project conventions live in this CLAUDE.md's `## Project Conventions` section.
- All PRD.md / PLAN.md acceptance criteria MUST use RFC 2119 keywords (SHALL/MUST/SHOULD/MAY/MUST NOT) + Given/When/Then scenarios. Every feature build MUST emit a Spec Delta in CHANGELOG.md and merge back into ARCHITECTURE.md + PRD.md.

<!-- STP:stp-dirmap:end -->

## Statusline
Node.js statusline (stp-statusline.js) registered in ~/.claude/settings.json globally. Shows: model + effort level, project version, active feature + progress, current milestone, context usage bar with compaction threshold (green/yellow/orange/red).

<!-- STP:stp-hooks:start -->
## Hooks (19 gates — full detail in `.claude/rules/hooks.md`)

**CRITICAL — hooks load at SESSION STARTUP, not hot-reload.** After `/stp:upgrade` or any plugin change touching hooks, you MUST `/exit` and restart Claude Code. `/clear` alone does NOT reload hooks. Cached version check: `cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

**Compressed index** (name|event|action|bypass):
```
ui-gate|PreToolUse|BLOCK new UI files until .stp/state/ui-gate-passed exists|STP_BYPASS_UI_GATE=1
whiteboard-gate|PreToolUse|BLOCK forbidden legacy filenames + auto-start server for canonical path|STP_BYPASS_WHITEBOARD_GATE=1
post-edit-check|PostToolUse|stack-aware type/compile check, stderr feedback only|—
anti-slop-scan|PostToolUse|grep 7 AI-slop patterns, 1=WARN 2+=BLOCK|STP_BYPASS_SLOP_SCAN=1
stop:unchecked-items|Stop|BLOCK workflow, no retry|—
stop:missing-plan|Stop|WARN if PLAN.md missing|—
stop:no-tests|Stop|BLOCK source files without tests|—
stop:secrets|Stop|BLOCK sk_live_/sk_test_/AKIA... patterns|—
stop:placeholders|Stop|WARN on TODO/FIXME/lorem ipsum/mock data|—
stop:hollow-tests|Stop|WARN on tautological/assertion-free tests|—
stop:type-errors|Stop|BLOCK (technical, 3-retry)|—
stop:test-failures|Stop|BLOCK (technical, 3-retry)|—
stop:schema-drift|Stop|BLOCK ORM schema changes without migrations (Prisma/TypeORM/Django/Rails/Drizzle)|—
stop:scope-reduction|Stop|WARN if PRD.md SHALL/MUST coverage in PLAN.md <70%|—
stop:spec-delta|Stop|WARN on missing CHANGELOG spec-delta block or stale ARCHITECTURE.md|—
stop:critic-required|Stop|BLOCK workflow if no critic-report-*.md newer than feature|—
stop:qa-required|Stop|BLOCK workflow for UI features without qa-report-*.md|—
SessionStart|SessionStart|wipe ui-gate-passed, migrate layout, restore context|—
PreCompact|PreCompact|emergency save to .stp/state/state.json|—
```

**3-retry safety valve:** technical BLOCKs (tests, types, schema) count toward a 3-retry limit. Workflow BLOCKs (unchecked, Critic, QA) never count — can't brick the session.

<!-- STP:stp-hooks:end -->

## Research
All research sources in RESEARCH-SOURCES.md. Key: Anthropic harness blog, Vercel AGENTS.md (100% vs 53%), Phil Schmid "Build to Delete", OX Security AI anti-patterns.

<!-- STP:stp-effort:start -->
## Effort Levels
- /stp:new-project, /stp:plan, /stp:debug, /stp:work-full → max
- /stp:research → max
- /stp:whiteboard, /stp:work-quick, /stp:review, /stp:continue → high
- /stp:onboard-existing → max
- /stp:autopilot → medium
- /stp:progress, /stp:pause, /stp:upgrade, /stp:set-profile-model → low
<!-- STP:stp-effort:end -->

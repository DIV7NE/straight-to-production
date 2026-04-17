# STP — Straight To Production — Claude Code Plugin (v1.1)

<!-- STP:stp-header:start -->
## What This Is
Universal Claude Code plugin for production development. **7 skills** (setup, think, build, session, debug, review, ship), **stack-aware** (web, Node, Python, Rust, C++, C#, Java, Go, game cheats, embedded, mods — 14 stacks detected automatically), **pace-aware** (deep / batched / fast / autonomous curiosity dial), **code-graph-aware** (Aider-style repo map via bundled tree-sitter grammars — offline, zero paid APIs), **Opus 4.7 idioms** (parallel tool calls, context-limit, INVERSION critic framing).

Opus 4.7 plans + Sonnet 4.6 executes. Built on STP's production philosophy: no mocks, no placeholders, real tests. Read the installed version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.
<!-- STP:stp-header:end -->

## Debug Mandate (OVERRIDES superpowers — read this before debugging anything)

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance the user is reporting a bug, error, test failure, crash, regression, broken behavior, or anything "not working as expected" — you MUST follow the `/stp:debug` process documented at `skills/debug/SKILL.md`.

**You MUST NOT invoke `superpowers:systematic-debugging`** or any other debugging skill. STP's `/stp:debug` IS your debugging process. It is more rigorous, project-aware (reads `.stp/docs/AUDIT.md` for known patterns, ARCHITECTURE.md for dependency maps), stack-aware (reads `.stp/state/stack.json` for test/typecheck commands), and integrated with STP's verification stack.

This is not negotiable. Per superpowers' own priority rules, **user instructions (CLAUDE.md) outrank skills**. This mandate is a user instruction.

**Triggers (auto-invoke `/stp:debug` process when ANY apply):**
- User says: "broken", "not working", "error", "fails", "crashes", "wrong", "should be X but is Y", "stuck", "hangs", "infinite loop", "won't load", "blank screen", "can't continue", "nothing happens"
- User pastes a stack trace, error message, or Sentry link
- User describes unexpected UI behavior with or without a screenshot
- User says "debug" or "investigate"
- A test is failing
- A previously-working feature regressed

When triggered: announce "Following STP debug process (reading skills/debug/SKILL.md)" and execute the phases in that file. Do NOT call the Skill tool for systematic-debugging — that skill is forbidden in STP projects.
</EXTREMELY-IMPORTANT>

<!-- STP:stp-confirmation-gate:start -->
## Pre-Work Confirmation Gate (MANDATORY — overrides default behavior)

<EXTREMELY-IMPORTANT>
Before ANY STP skill writes code, modifies files, runs destructive actions, or takes any action beyond read-only exploration — Claude MUST:

1. **Present the plan** — state concisely what will be done and why
2. **Call AskUserQuestion** with structured options covering the plan + sensible alternatives
3. **Mark the recommended option `(Recommended)`** and place it FIRST in the options list
4. **Wait for user approval** before executing anything

**Applies to every `/stp:*` skill.** No silent work. No "I'll just start with X." Even trivial-looking edits get a confirmation prompt unless the user has pre-authorized it in the current session.

**Exception clause — the ONLY cases where confirmation can be skipped:**
- The user explicitly said "just do it", "go", "proceed", "yes to all", "no need to ask", or equivalent in the current session
- The user's current message itself IS the confirmation (e.g., they answered an earlier AskUserQuestion and the work falls within that approved scope)
- The action is strictly read-only (Read, Glob, Grep, LS, ctx searches) — reading never needs confirmation
- The user is inside `/stp:build --auto` (autopilot mode), where unattended execution is the explicit goal

**This rule OVERRIDES** any STP skill's internal instruction to "start working immediately" or "execute the plan." If a skill says "begin implementation," pause and confirm the implementation approach first. Skills describe *what* to do — this gate controls *when*.

**Why this exists:** Users have been surprised by work they didn't approve. The cost of one extra confirmation prompt is seconds. The cost of unwanted file edits, deleted content, or wasted build cycles is hours. Confirmation gates beat rollbacks. Per STP philosophy: constraints beat prompts.
</EXTREMELY-IMPORTANT>
<!-- STP:stp-confirmation-gate:end -->

## Architecture
- **Opus 4.7** = CTO (plans, researches, reviews, merges, teaches). Builds foundation work directly (DB, auth, config).
- **stp-executor** = builder sub-agent. Features on top of foundation, worktree isolation, parallel one-shot subagents via Task tool for wave parallelism — NOT Agent Teams; see `## Agent Teams vs Subagents` for cost rationale. Model = `sonnet` in all profiles.
- **stp-qa** = independent tester sub-agent. Tests running app against PRD acceptance criteria. Model = `sonnet` in opus-cto/balanced/sonnet-turbo/opus-budget, `haiku` in sonnet-cheap.
- **stp-critic** = code reviewer sub-agent. INVERSION framing + 7 criteria + Double-Check Protocol + Claim Verification Gate + 6-layer verification. Model = `sonnet` in opus-cto/balanced/sonnet-turbo, **`haiku` → sonnet escalation in opus-budget and sonnet-cheap** when ≥2 critical issues found.
- **stp-researcher** = context-isolation sub-agent for external research (Context7/Tavily/WebSearch). Model = `inline` in opus-cto (main session handles it), `sonnet` in balanced/sonnet-turbo/opus-budget/sonnet-cheap.
- **stp-explorer** = context-isolation sub-agent for codebase exploration (Glob/Grep across >5 files). Model = `inline` in opus-cto, `sonnet` in balanced/sonnet-turbo/opus-budget/sonnet-cheap.

> **Profile-dependent model assignments.** Sub-agent models are NOT hardcoded in STP skill files — they're resolved per-profile via `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` and the `agents/*.md` files are **regenerated from templates** at profile-switch time by `hooks/scripts/regenerate-agents.sh`. See `## Profile-Aware Execution` below.

<!-- STP:stp-subagent-cost:start -->
## Subagent Cost Discipline (STRICTLY ENFORCED)
Every `Agent()` call — whether inside STP skills or freeform conversation — MUST include an explicit `model=` parameter (unless the resolver returns `inherit` or `inline`). **Never silently omit it.** Omitting without a resolver sentinel causes subagents to inherit Opus ($15/MTok) when Sonnet ($3/MTok) handles research, exploration, code review, and building equally well. Default: `model="sonnet"` for all subagent types. Only use `model="opus"` when the user explicitly requests it. Only use `model="haiku"` when the resolved profile says so (opus-budget / sonnet-cheap critic + QA).
<!-- STP:stp-subagent-cost:end -->

<!-- STP:stp-profile-aware:start -->
## Profile-Aware Execution (MANDATORY for every STP skill)

Every `/stp:*` skill MUST run `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all` BEFORE spawning any sub-agent. Outputs KEY=VALUE lines (STP_PROFILE, STP_PACE, STP_MAIN_EFFORT, STP_MODEL_EXECUTOR, etc.). **Sentinels:** `inherit` → omit `model=`; `inline` → no sub-agent spawn; `sonnet`/`opus`/`haiku` → pass literally. If `STP_RESEARCHER_MANDATORY=true`, delegate all research to `stp-researcher`. If `STP_EXPLORER_MANDATORY=true`, delegate multi-file exploration to `stp-explorer`.

```
[STP Profile Index]|cli: node ${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs|state: .stp/state/profile.json|default: balanced
opus-cto     :{executor:sonnet,qa:sonnet,critic:sonnet,critic-esc:sonnet,researcher:inline,explorer:inline,effort:xhigh,clear:rec,ctx:rec,res-mand:no,exp-mand:no}
balanced     :{executor:sonnet,qa:sonnet,critic:sonnet,critic-esc:sonnet,researcher:sonnet,explorer:sonnet,effort:xhigh,clear:mand,ctx:mand,res-mand:yes,exp-mand:yes,max-kb:120}
sonnet-turbo :{executor:sonnet,qa:sonnet,critic:sonnet,critic-esc:sonnet,researcher:sonnet,explorer:sonnet,effort:xhigh,clear:mand,ctx:mand,res-mand:yes,exp-mand:yes,max-kb:150}
opus-budget  :{executor:sonnet,qa:sonnet,critic:haiku→esc-sonnet,critic-esc:sonnet,researcher:sonnet,explorer:sonnet,effort:high,clear:enforced,ctx:hard-block,res-mand:yes,exp-mand:yes,max-kb:100}
sonnet-cheap :{executor:sonnet,qa:haiku,critic:haiku→esc-sonnet,critic-esc:sonnet,researcher:sonnet,explorer:sonnet,effort:high,clear:enforced,ctx:hard-block,res-mand:yes,exp-mand:yes,max-kb:80}
pro-plan     :{ALL:inline,effort:high,clear:enforced,ctx:hard-block,no-subagents:yes,max-kb:60,max-msgs/feature:30,max-msgs/5h:80,verify:deterministic-only,allowed:build--quick+debug+session}
```

Full profile docs + spawn patterns + trade-offs: `${CLAUDE_PLUGIN_ROOT}/references/profiles.md`.
<!-- STP:stp-profile-aware:end -->

<!-- STP:stp-pace:start -->
## Pace-Aware Execution (the curiosity dial)

Every STP skill reads `.stp/state/pace.json` (default: `batched`) and adjusts user-facing questions accordingly. Pace is **orthogonal** to profile — they do not interact. Profile controls *which model runs what*; pace controls *how often you ask the user*.

| Pace | Behavior | When to pick |
|---|---|---|
| `deep` | One question at a time, 200-300 word design sections, validation after each. Maximum curiosity. | Novel problem, learning unfamiliar domain, high-stakes architecture. |
| `batched` (DEFAULT) | AskUserQuestion with up to 4 questions per call, section-by-section validation between calls. | Most work. Sweet spot. |
| `fast` | Full plan in one message, single AskUserQuestion for approval. | Familiar territory, time-boxed. |
| `autonomous` | Pick sensible defaults, proceed without questions after initial scope confirm. | Overnight `/stp:build --auto`, pre-approved scopes. |

**Auto-escalation** (applies to all skills, overrides user pace):
- Auth / payments / security / secrets → minimum `batched`
- New ORM models / migrations → minimum `batched`
- Deleting >50 lines OR changing >5 files → minimum `batched`
- Novel architecture (new service, new data store) → minimum `batched` on first pass

Full pace semantics + examples: `${CLAUDE_PLUGIN_ROOT}/references/pace-picker.md`.
<!-- STP:stp-pace:end -->

<!-- STP:stp-stack:start -->
## Stack-Aware Execution

Every STP skill reads `.stp/state/stack.json` (auto-detected on SessionStart, refreshed if >24h old). 14 stacks supported: `web` (Next/Vite/Remix), `node` (plain Node.js), `python`, `data-ml` (Jupyter/ML), `rust`, `game` (Unity/Unreal/Godot/Bevy), `embedded` (ESP32/Arduino/Zephyr), `cpp` (general C++), `cheat-pentest` (private-server game cheats, CS2 internals, pentest tools), `csharp` (.NET), `java`, `mod` (game mods), `go`, `generic` (fallback).

Stack record fields: `stack`, `language`, `runtime`, `ui` (bool — controls ui-gate / anti-slop), `test_cmd`, `build_cmd`, `lint_cmd`, `typecheck_cmd`, `run_cmd`, `property_lib`, `stack_ref`.

Hooks that read `stack.json`:
- `ui-gate.sh` — skips entirely if `stack.ui=false` (no UI = no gate)
- `anti-slop-scan.sh` — same, skip for non-UI stacks
- `stop-verify.sh` — prefers `test_cmd` + `typecheck_cmd` from stack.json over filesystem detection

Per-stack reference docs: `${CLAUDE_PLUGIN_ROOT}/references/stacks/<stack>.md`.
<!-- STP:stp-stack:end -->

## 6-Layer Verification Stack
1. Executable specs (deterministic) → 2. Hollow test detection (AST/grep) → 3. Mutation challenge (adversarial) → 4. Property-based tests (automated) → 5. Cross-family AI review / Critic (LLM, Layer 5 not Layer 1) → 6. Production canary (runtime). Critic = structural review only; behavioral verification is deterministic (specs pass/fail).

## Task Routing (Scale-Adaptive — evidence-based, never overconfident)

When user describes work WITHOUT specifying a skill, run **Impact Scan** silently: `grep -rl "[keyword]"` to count files, check for model/migration/auth involvement. Then route:

| Scan Result | Route to |
|---|---|
| 0-1 files, no models/auth | Inline fix |
| Bug + error/stack trace | `/stp:debug` |
| 1-3 files, no models/auth | `/stp:build --quick` |
| 3+ files OR model/migration | `/stp:build --full` |
| Any auth/payment/security | `/stp:build --full` (FORCED) |
| Exploratory | `/stp:think --whiteboard` or `/stp:think` |

**Rules:** default to MORE ceremony; auth/payments/security = always build --full; AskUserQuestion for EVERY routing decision showing scan results; scan before any downshift/upshift.

<!-- STP:stp-commands:start -->
## Skills (6 total)

**Setup + lifecycle:**
- `/stp:setup welcome` — first-run. Profile + pace pickers, stack detect, optional chain to `new` / `onboard`.
- `/stp:setup new` — PRD-first project bootstrap.
- `/stp:setup onboard` — analyze existing codebase, write ARCHITECTURE.md + CONTEXT.md + AUDIT.md.
- `/stp:setup model` — switch model profile (opus-cto / balanced / sonnet-turbo / opus-budget / sonnet-cheap / pro-plan).
- `/stp:setup pace` — switch curiosity dial (deep / batched / fast / autonomous).
- `/stp:setup upgrade` — pull latest plugin, sync CLAUDE.md markers, regenerate agents, migrate state.

**Thinking:**
- `/stp:think` (default) — loose brainstorming → design brief.
- `/stp:think --plan` — 9-phase architecture blueprint → PLAN.md.
- `/stp:think --research` — focused external research question.
- `/stp:think --whiteboard` — visual exploration, structured design brief.

**Building:**
- `/stp:build` (default) — auto-routes via impact scan to `--quick`, `--full`, or recommends `--auto`.
- `/stp:build --quick` — small tasks, ≤3 files, no new models. Hooks still fire.
- `/stp:build --full` — 3+ files, new models, auth/payments, safety-critical. Full 9-phase cycle with INVERSION critic.
- `/stp:build --auto` — overnight queue mode. No mid-work questions. Risky decisions flagged for morning review.

**Debugging + review:**
- `/stp:debug` — root cause analysis → evidence-based fix → defense-in-depth.
- `/stp:review` — Critic evaluates against 7 criteria with INVERSION framing + cross-family lens for security-critical code.

**Session management:**
- `/stp:session pause` — save state to disk for next session.
- `/stp:session continue` — resume from disk, synthesize <300 word summary, chain into next action.
- `/stp:session progress` — read-only status dashboard.

**Release:**
- `/stp:ship [patch|minor|major]` — preflight → VERSION bump → CHANGELOG finalize → commit → tag → push → `gh release create` → opt-in publish (npm / cargo / PyPI) → opt-in deploy hook. Free at runtime (uses `gh` CLI free tier).
<!-- STP:stp-commands:end -->

<!-- STP:stp-plugins:start -->
## Required Companion Plugins & MCP Servers
Required: **ui-ux-pro-max** (design, ONLY when `stack.ui=true`), **Context7** (docs), **Tavily** (research), **Context Mode** (context protection). UI code MUST invoke `/ui-ux-pro-max` first. Research MUST use Context7 + Tavily. Full details + install commands: `${CLAUDE_PLUGIN_ROOT}/references/companion-plugins.md`.
<!-- STP:stp-plugins:end -->

<!-- STP:stp-philosophy:start -->
## Philosophy (NON-NEGOTIABLE)

**STP builds production software. Not MVPs. Not mocks. Not prototypes. Not demos.**

- No mock data, fake APIs, placeholders, or "we'll replace this later" shortcuts — build the real thing
- No incomplete output — never `...`, `// rest of code`, `// TODO: implement`. Every block complete and runnable
- Tests MUST verify real behavior, not mock satisfaction. Trivial asserts (`expect(true).toBe(true)`) forbidden
- Override simplification bias — if correct solution requires more work, do more work
- If a fix fails after 2 attempts: STOP, re-read the module, state where mental model was wrong
- Constraints beat prompts — hooks and gates are the real enforcement
<!-- STP:stp-philosophy:end -->

## Agent Teams vs Subagents
**Default to one-shot subagents (Task tool).** Teams cost ~3-4× more. Only use Agent Teams when workers must communicate with *each other* (e.g. `/stp:build --auto` overnight queue). Full cost analysis + flow mapping: `${CLAUDE_PLUGIN_ROOT}/references/agent-teams-vs-subagents.md`.

## Opus 4.7 Idioms (MANDATORY — read before spawning any agent)

Before any `Agent()` spawn, read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`. Covers:
- **`<use_parallel_tool_calls>` block** — every executor / critic / qa spawn prompt MUST include this. Opus 4.7 defaults to fewer parallel calls than 4.6 — you must explicitly opt in per call.
- **Context-limit line** — "Don't stop early due to token budget. If you run out mid-task, report what you have + flag what's unchecked."
- **Critic INVERSION** — "Report every issue including low-severity and uncertain findings. Downstream ranks severity. Your job is recall, not precision."
- **Tool-trigger normalization** — no ALLCAPS "MUST" in prompts; Opus 4.7 follows lowercase specification better than SHOUTED instructions.
- **Explicit scope boundaries** — say what the agent should NOT do, not just what it should do.

<!-- STP:stp-rules:start -->
## Key Rules
- Opus NEVER writes implementation code (except foundation: DB, auth, config, one-line fixes)
- ALL features delegate to Sonnet executor sub-agents (Task tool) with worktree isolation — NOT Agent Teams by default (see `## Agent Teams vs Subagents` above)
- AskUserQuestion tool is MANDATORY for ALL user decisions — NEVER print options as text, NEVER skip, NEVER decide for the user. Only exception: freeform input where structured options don't fit (bug descriptions, QA feedback, feature requests)
- TodoWrite tracks ALL progress visibly
- README.md updated + VERIFIED after every feature
- Spec-first TDD: acceptance criteria → executable spec tests → behavioral tests → property-based tests → implementation. Stop hook blocks if no tests exist. Tests must verify real behavior, not mock satisfaction
- Hygiene scan after every build (anti-slop hook fires automatically)
- Version bump + CHANGELOG + CONTEXT.md update after every feature
- **Whiteboard server is MANDATORY and FIRST** for `/stp:think --whiteboard` — literal first action, no AskUserQuestion gate. Start command: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &`. For `/stp:build` UI detection, server starts BEFORE design system generation. Reason: a whiteboard the user can't see is broken.
- **FILENAME CONTRACT — whiteboard data file is ALWAYS `.stp/whiteboard-data.json`. NEVER any other name.** Forbidden aliases (all BLOCKED by `hooks/scripts/whiteboard-gate.sh`): `.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`.
- **`/clear` MANDATORY before every inter-skill transition.** Completion boxes recommending a follow-up `/stp:*` skill MUST say `/clear, then /stp:next-skill`, never `/stp:next-skill` alone. Reason: next phase reads inputs from disk (PLAN.md, design-brief.md, CHANGELOG.md, current-feature.md) — fresh context is strictly better. **Exception:** after `/stp:setup upgrade` with hook file changes, recommend `/exit → restart claude → (optional) /clear` — `/clear` alone does NOT reload hooks.
- **Stack-awareness is mandatory.** Every skill reads `.stp/state/stack.json` in its shared opening. Commands (test, typecheck, lint, build, run) come from stack.json — don't hardcode `npm test` assumptions.
- **Pace-awareness is mandatory.** Every skill reads `.stp/state/pace.json` in its shared opening. User-facing question cadence follows the pace dial.
<!-- STP:stp-rules:end -->

<!-- STP:stp-output-format:start -->
## CLI Output Formatting (ENFORCED)
Read `${CLAUDE_PLUGIN_ROOT}/references/cli-output-format.md` BEFORE displaying status/progress. Use `echo -e` for ANSI colors (monochrome NOT acceptable). Skills start with cyan ╔═╗ banner. Colors: cyan borders, green ✓, red ✗, yellow ⚠, bold yellow ★, blue ► next steps. Always `\033[0m` reset.
<!-- STP:stp-output-format:end -->

<!-- STP:stp-dirmap:start -->
## Directory Map, Memory Strategy, Structured Spec Format, Spec Delta System

Full detail lives in **`.stp/CLAUDE.md`** — auto-loads when Claude accesses files under `.stp/` (which is exactly when those sections are needed). Covers: `.stp/docs/` + `.stp/state/` + `.stp/references/` directory maps, file-based memory strategy, Given/When/Then + RFC 2119 spec format, Spec Delta merge-back system.

**Quick reference** (when NOT already under `.stp/`):
- `.stp/docs/` — PRD.md (requirements), PLAN.md (architecture), ARCHITECTURE.md (codebase map), AUDIT.md (production health), CONTEXT.md (<150 lines concise ref), CHANGELOG.md (history with spec deltas)
- `.stp/state/` — current-feature.md, handoff.md, state.json, pace.json, stack.json, profile.json, design-brief.md (survive `/clear`)
- `.stp/references/` — security, accessibility, performance, production, cli-output-format.md (read BEFORE writing matching code)
- `${CLAUDE_PLUGIN_ROOT}/references/stacks/` — per-stack reference (14 stacks)
- `skills/` — 6 v1 skills (setup, think, build, session, debug, review)
- Memory = file-based, disk is truth. On new session: read CHANGELOG + ARCHITECTURE + PLAN. Project conventions live in this CLAUDE.md's `## Project Conventions` section.
- All PRD.md / PLAN.md acceptance criteria MUST use RFC 2119 keywords (SHALL/MUST/SHOULD/MAY/MUST NOT) + Given/When/Then scenarios. Every feature build MUST emit a Spec Delta in CHANGELOG.md and merge back into ARCHITECTURE.md + PRD.md.
<!-- STP:stp-dirmap:end -->

<!-- STP:stp-statusline:start -->
## Statusline
Node.js statusline (`hooks/scripts/stp-statusline.js`) registered in plugin manifest. Shows: model + effort (xhigh highlighted), active profile tag (balanced silent, others color-coded), pace tag (◆deep / ▸fast / ●auto — batched silent), stack tag (non-generic only), project version, active feature + progress, current milestone, **context bar with threshold nudges** (0-40% silent, 40-70% cyan `/compact if tool-heavy`, 70-90% yellow `→ /stp:session pause`, 90%+ blinking red `⚠ pause NOW`).
<!-- STP:stp-statusline:end -->

<!-- STP:stp-hooks:start -->
## Hooks (19 gates — full detail in `.claude/rules/hooks.md`)

**CRITICAL — hooks load at SESSION STARTUP, not hot-reload.** After `/stp:setup upgrade` or any plugin change touching hooks, you MUST `/exit` and restart Claude Code. `/clear` alone does NOT reload hooks. Cached version check: `cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

**Compressed index** (name|event|action|bypass):
```
ui-gate|PreToolUse|BLOCK new UI files until .stp/state/ui-gate-passed exists (skip if stack.ui=false)|STP_BYPASS_UI_GATE=1
whiteboard-gate|PreToolUse|BLOCK forbidden legacy filenames + auto-start server for canonical path|STP_BYPASS_WHITEBOARD_GATE=1
post-edit-check|PostToolUse|stack-aware type/compile check, stderr feedback only|—
anti-slop-scan|PostToolUse|grep 7 AI-slop patterns, 1=WARN 2+=BLOCK (skip if stack.ui=false)|STP_BYPASS_SLOP_SCAN=1
stop:unchecked-items|Stop|BLOCK workflow, no retry|—
stop:missing-plan|Stop|WARN if PLAN.md missing|—
stop:no-tests|Stop|BLOCK source files without tests|—
stop:secrets|Stop|BLOCK sk_live_/sk_test_/AKIA... patterns|—
stop:placeholders|Stop|WARN on TODO/FIXME/lorem ipsum/mock data|—
stop:hollow-tests|Stop|WARN on tautological/assertion-free tests|—
stop:type-errors|Stop|BLOCK via stack.json typecheck_cmd (3-retry)|—
stop:test-failures|Stop|BLOCK via stack.json test_cmd (3-retry)|—
stop:schema-drift|Stop|BLOCK ORM schema changes without migrations (Prisma/TypeORM/Django/Rails/Drizzle)|—
stop:scope-reduction|Stop|WARN if PRD.md SHALL/MUST coverage in PLAN.md <70%|—
stop:spec-delta|Stop|WARN on missing CHANGELOG spec-delta block or stale ARCHITECTURE.md|—
stop:critic-required|Stop|BLOCK workflow if no critic-report-*.md newer than feature|—
stop:qa-required|Stop|BLOCK workflow for UI features without qa-report-*.md|—
SessionStart|SessionStart|wipe ui-gate-passed, migrate-layout, migrate-v1 (profile renames), detect-stack, session-restore, check-upgrade|—
PreCompact|PreCompact|emergency save to .stp/state/state.json|—
```

**3-retry safety valve:** technical BLOCKs (tests, types, schema) count toward a 3-retry limit. Workflow BLOCKs (unchecked, Critic, QA) never count — can't brick the session.
<!-- STP:stp-hooks:end -->

<!-- STP:stp-research:start -->
## Research
All research sources in RESEARCH-SOURCES.md. Key: Anthropic Opus 4.7 best-practices, Anthropic harness blog, Anthropic long-context + session management, Vercel AGENTS.md (100% vs 53%), Phil Schmid "Build to Delete", OX Security AI anti-patterns.
<!-- STP:stp-research:end -->

<!-- STP:stp-effort:start -->
## Effort Levels (Opus 4.7 uses `xhigh` as default)
- `/stp:setup new`, `/stp:setup onboard`, `/stp:think --plan`, `/stp:build --full`, `/stp:debug` → **xhigh** (default)
- `/stp:think` (brainstorm), `/stp:think --research`, `/stp:review`, `/stp:build --quick`, `/stp:session continue` → **xhigh** or **high** (per profile)
- `/stp:think --whiteboard` → **high**
- `/stp:build --auto` → **xhigh** (novel work expected overnight) / **max** only on genuine architectural novelty
- `/stp:session pause`, `/stp:session progress`, `/stp:setup model`, `/stp:setup pace` → **low**
- `/stp:setup upgrade` → **low**
- `/stp:ship` → **high** (orchestrator; preflight + git + gh are deterministic — no deep reasoning)

`max` is reserved for genuinely novel architectural work. Overuse causes overthinking.
<!-- STP:stp-effort:end -->

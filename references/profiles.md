# STP Optimization Profiles (v1.0)

STP supports **six profiles** that control which Claude models run which roles (main session + sub-agents) and how aggressively discipline (/clear, context limits, mandatory delegation) is enforced. **Default: `balanced`** — best cost/quality ratio for most users. Switch with `/stp:setup model`.

> **Architecture.** The single source of truth is `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` — a Node.js file holding the canonical `agent × profile → model` table + a CLI that every skill and hook calls to resolve models at spawn time. Adding a profile is one column in that file; no other changes needed.

**Sentinel values you'll see in the tables below:**
- `inherit` — sub-agent omits `model=`; uses the parent session model (Opus on Opus sessions, Sonnet on Sonnet sessions).
- `inline` — no sub-agent spawned; the main session does the work directly.

## Quick comparison

| Sub-agent | opus-cto | balanced | sonnet-turbo | opus-budget | sonnet-cheap | pro-plan |
|---|---|---|---|---|---|---|
| **stp-executor** | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `inline` |
| **stp-qa** | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `haiku` | `inline` |
| **stp-critic** | `sonnet` | `sonnet` | `sonnet` | `haiku` → `sonnet` on ≥2 issues | `haiku` → `sonnet` on ≥2 | `inline` |
| **stp-critic-escalation** | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `inline` |
| **stp-researcher** | `inline` | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `inline` |
| **stp-explorer** | `inline` | `sonnet` | `sonnet` | `sonnet` | `sonnet` | `inline` |

> **Why opus-cto uses `sonnet` (not `inherit`) for sub-agents.** Opus plans + Sonnet executes is the cost optimization at the heart of STP. Opus thinks (architecture, review), Sonnet builds (cheap, equally capable for code writing per Anthropic's SWE-bench data). `inherit` is reserved for future non-Anthropic runtimes (Codex, OpenCode, Gemini CLI) where matching the main-session model is desired.

## Discipline matrix

| Discipline | opus-cto | balanced | sonnet-turbo | opus-budget | sonnet-cheap | pro-plan |
|---|---|---|---|---|---|---|
| **Main effort** | `xhigh` | `xhigh` | `xhigh` | `high` | `high` | `high` |
| **/clear between phases** | recommended | mandatory | mandatory | enforced at 60% | enforced | enforced |
| **Context Mode MCP** | recommended | mandatory | mandatory | hard-block >50 lines | hard-block | hard-block |
| **Researcher mandatory** | false (inline) | true | true | true | true | false (inline) |
| **Explorer mandatory** | false (inline) | true | true | true | true | false (inline) |
| **Sub-agents enabled** | yes | yes | yes | yes | yes | **DISABLED** |
| **Max main session** | ~1M | ~120K | ~150K | ~100K | ~80K | ~60K |
| **Max msgs / feature** | — | — | — | — | — | **≤30** |
| **Max msgs / 5h window** | — | — | — | — | — | **≤80** |
| **Verification** | 6-layer | 6-layer | 6-layer | 6-layer | 6-layer | deterministic only |
| **Allowed skills** | all | all | all | all | all | build --quick, debug, session |
| **Cost vs opus-cto** | 100% (baseline) | ~35-50% | ~25% | ~20% | ~15% | **$20/mo flat** |
| **Quality vs opus-cto** | 100% | ~95% | ~90% (tight context) | ~85-90% | ~80-85% | ~70-75% |

## Which profile should I pick?

**Pick `balanced` (DEFAULT) if:**
- You have Opus access + want the best cost/quality ratio.
- You're doing standard development work — features, fixes, refactors.
- You're comfortable with `/clear` between phases and filesystem-handoff discipline.
- You want ~50% cost savings vs opus-cto with negligible quality drop on routine builds.

**Pick `opus-cto` if:**
- You have Opus 4.7 access AND cost is not a constraint.
- You're building high-stakes production software where maximum quality matters.
- You want research/exploration inline (no delegation overhead) thanks to Opus 1M context.

**Pick `sonnet-turbo` if:**
- You want fast iteration without Opus latency, but still want structured subagents.
- You're OK with Sonnet 4.6 as main session (no 1M context — standard 200K).
- Cost matters but not as much as on opus-budget.
- Good for feature work where deep architectural reasoning isn't critical.

**Pick `opus-budget` if:**
- You have Opus access but want critic cost optimized (Haiku first-pass, Sonnet escalation on ≥2 issues).
- You're willing to accept a slightly looser critic in exchange for ~60% critic-phase savings.
- You follow strict discipline — mandatory researcher/explorer, hard-block on large outputs.

**Pick `sonnet-cheap` if:**
- You're running Claude Code with Sonnet 4.6 as primary (no Opus access).
- You want STP's full workflow on a 200K context budget.
- You accept Haiku for QA + first-pass critic (with Sonnet escalation on critical findings).
- Lowest non-Pro cost — ~85% cheaper than opus-cto.

**Pick `pro-plan` if:**
- You're on the **$20/month Claude Pro plan** (the cheapest paid tier).
- Your hard constraint is **message count** (~45-100 msgs per 5-hour window).
- You can do **1-2 features per session** and need every message to count.
- You're OK with **no AI verification** (critic, QA) — deterministic tests/types/lint only.
- You accept only `/stp:build --quick`, `/stp:debug`, and `/stp:session` (no build --full, think --plan, setup new, etc.).

## Profile details

### opus-cto

> The original STP architecture. Built around Opus 4.7's 1M context window and validated by Anthropic's harness research.

**Main session**: Opus 4.7 [1M] at `xhigh` effort. The main session holds research + planning + build + review history without aggressive offloading. `/clear` between phases is recommended but not required.

**Sub-agents**: Sonnet 4.6 executors in worktrees, Sonnet QA, Sonnet critic. Researcher + explorer stay **inline** in the Opus 1M session — no dedicated sub-agents for those roles.

**Context engineering**: Light-touch. Context Mode MCP recommended for very large outputs but not strictly required. The 1M window absorbs most operations.

**Cost profile**: Highest. Every main-session token is Opus-priced. Worth it when quality matters.

### balanced

> Opus thinks, Sonnet executes. The default and safest starting point.

**Main session**:
- **Planning skills** (`/stp:think`, `/stp:setup new`, `/stp:setup onboard`) → Opus 4.7 [1M]
- **Execution skills** (`/stp:build`, `/stp:debug`) → Sonnet 4.6 [200K]
- **Utility skills** (`/stp:session`, `/stp:setup model`, `/stp:setup pace`) → whatever's currently loaded

This is the trickiest part of the profile: you can't switch a running session's model mid-conversation, so **start a new Claude Code session with the right model for the skill you're about to run.** The statusline shows profile + model.

**Sub-agents**: All Sonnet 4.6 in worktrees. `stp-researcher` + `stp-explorer` fire whenever the main session needs external research or multi-file exploration — keeps the 200K execution session lean.

**Context engineering**: Mandatory. `/clear` between phases is required (Sonnet 200K compacts faster than Opus 1M). Context Mode MCP for any operation >50 lines output. Sub-agent prompts capped at 2K tokens, reports capped at 30 lines.

**Why this works**: Anthropic's harness research shows fresh sub-agents with filesystem handoffs often match or beat a single long-running session. Sonnet 200K is sufficient when each sub-agent task is tightly scoped.

**Cost profile**: ~50% cheaper than opus-cto. Bigger savings on long execution phases.

**Quality drop**: ~5% on architecture-heavy work; negligible on routine CRUD/UI/test builds.

### sonnet-turbo

> Sonnet 4.6 @ xhigh effort as main session. Same sub-agent strategy as balanced, but no Opus anywhere.

**Main session**: Sonnet 4.6 [200K] at `xhigh` effort. Faster iteration than Opus; cheaper; still structured.

**Sub-agents**: Same as balanced — all Sonnet, researcher + explorer mandatory.

**Context engineering**: Same as balanced (mandatory /clear, mandatory Context Mode MCP for large ops).

**Cost profile**: ~25% of opus-cto. Faster than opus-cto for routine work because Sonnet's latency is lower.

**Quality drop**: ~10%. Architectural reasoning is weaker than Opus, but Sonnet 4.6 @ xhigh + the 6-layer verification stack catches most of it. Not recommended for net-new system design; fine for feature work, fixes, refactors.

**When to pick sonnet-turbo over balanced**: You don't have Opus quota / don't want the mental overhead of swapping main-session models between planning and execution. One model, one session.

### opus-budget

> Opus plans, Sonnet executes, Haiku first-pass critic.

**Main session**: Same as balanced (Opus for planning, Sonnet for execution).

**Sub-agents**: Same as balanced EXCEPT the critic:
- **Pass 1 — Haiku 4.5**: pattern-based structural scan (file:line evidence for secrets, schema drift, accessibility, hollow tests, anti-slop). Cheap, fast.
- **Pass 2 — Sonnet 4.6 escalation**: triggers ONLY when Haiku finds ≥2 critical issues or any FAIL. Runs the full Double-Check Protocol with behavioral verification.

**Context engineering**: Hardcore. Main session treated as a thin coordinator holding only decisions + pointers:
1. `/clear` between phases **enforced** (warning hook fires at 60% capacity)
2. Context Mode MCP **hard-blocked** for operations >50 lines
3. Sub-agent prompts capped at 2K tokens, reports capped at **20 lines** (tighter than balanced)
4. Researcher / explorer **mandatory** — main session may NOT do research or multi-file exploration directly
5. Anti-slop scan threshold tightened: 1 hit → BLOCK (vs WARN in other profiles)

**Compensation strategy**: Because the critic is weaker on deep reasoning, opus-budget leans harder on Layers 1-4 of the verification stack (executable specs, deterministic analysis, mutation challenge, property tests). The critic stops being the last safety net and becomes one of five deterministic checks.

**Cost profile**: ~20% of opus-cto.

**Quality drop**: ~10-15% raw model intelligence, pulled back to ~5-8% real-world by tighter discipline + Sonnet escalation.

### sonnet-cheap

> No Opus anywhere. Sonnet main session, Haiku QA + first-pass critic, Sonnet escalation for critical findings.

**Main session**: Sonnet 4.6 [200K] at `high` effort. For users running Claude Code with Sonnet (no Opus access).

**Sub-agents**:
- Executor: Sonnet 4.6
- QA: **Haiku 4.5** — standard test assertions don't need Sonnet-level reasoning
- Critic: **Haiku 4.5** → escalates to Sonnet on ≥2 critical findings
- Researcher: Sonnet 4.6 (mandatory — main session can't afford inline research at 200K)
- Explorer: Sonnet 4.6 (mandatory)

**Context engineering**: Same as opus-budget but tighter main-session cap (80K vs 100K). Reasoning: Sonnet 200K is the hard ceiling; after CLAUDE.md + skill files + state files, usable planning context is ~80K before coherence risk.

**When to use sonnet-cheap over opus-budget**: You don't have Opus access at all. Otherwise opus-budget is strictly better (Opus planning pays for itself).

**Cost profile**: ~15% of opus-cto.

**Quality drop**: ~15-20% raw, compensated to ~8-10% real-world by Layers 1-4 + Sonnet escalation. Adequate for feature work, fixes, refactors. Not recommended for complex multi-system architecture planning.

### pro-plan

> ZERO sub-agents. All work inline in the main session. Designed around the Pro plan's hard constraint: ~45-100 messages per 5-hour window, shared across all Claude surfaces.

**Main session**: Whatever the Pro plan gives you (currently Sonnet 4.6 200K with limited Opus access). Use Sonnet for all STP work — Opus messages count heavier against rate limits.

**Sub-agents**: **None.** Every `Agent()` spawn burns 5-20+ messages from the shared pool. A single `/stp:build --full` with executor + QA + critic could exhaust a 5-hour window. All agents set to `inline`.

**Verification**: **Deterministic only.** No AI critic, no AI QA. Rely entirely on:
- Type checking (`tsc --noEmit`, `mypy`, `cargo check`, etc.)
- Test suite (vitest/jest/pytest/cargo test/etc.)
- Linting (eslint/biome/ruff/clippy/etc.)
- Stop hooks still fire (type-errors, test-failures, secrets, placeholders, hollow-tests)

**Allowed skills**: Only lightweight ones that don't spawn sub-agents:
- `/stp:build --quick` — primary build skill. Inline research → inline build → deterministic verify.
- `/stp:debug` — root cause analysis, all inline.
- `/stp:session` — pause / continue / progress (nearly free).
- `/stp:setup model`, `/stp:setup pace`, `/stp:setup upgrade` — utility.

**Blocked skills** (too message-heavy):
- `/stp:build --full` — spawns executor + QA + critic = 30-60+ messages
- `/stp:build --auto` — designed for unlimited usage
- `/stp:think --plan` — research-heavy
- `/stp:review` — spawns critic sub-agent
- `/stp:think --whiteboard` — research + exploration + server management
- `/stp:setup new`, `/stp:setup onboard` — 30-40+ messages

**Message budget discipline**:
- **≤30 messages per feature** — plan before starting, don't explore aimlessly.
- **≤80 messages per 5-hour window** — leave ~20 for non-STP Claude usage.
- **Every `/clear` saves messages** — smaller context = shorter responses = fewer tokens per message.
- **Read before you grep** — if you know the file, Read it directly.
- **Batch questions** — ask multiple things in one turn.

**Context engineering**: Strictest. `/clear` between EVERY task. 60K main-session cap. No research sub-agents.

**Cost profile**: $20/month flat. Constraint is throughput, not cost.

**Quality drop**: ~25-30% vs opus-cto. No AI code review, no AI QA, no mutation testing. You get: STP's production philosophy (no mocks, no placeholders, real tests), all stop hooks, deterministic verification. Significant reduction but still far better than unstructured development.

## Research / exploration decision (200K-main profiles)

The single biggest risk in 200K profiles is the main session running out of context during research or codebase exploration. STP solves this with two dedicated sub-agents.

### stp-researcher

**Purpose**: External research isolation. Lives in a fresh Sonnet context per call. Returns a tight ≤30 line summary so the main session never holds raw research dumps.

**When to fire**:
- Any Context7 query
- Any Tavily research query
- Any WebSearch / WebFetch call
- Any reading of multi-page external documentation

**Prompt budget**: ≤2K tokens | **Report budget**: ≤30 lines structured (findings, citations, TL;DR)

**Mandatory in**: balanced, sonnet-turbo, opus-budget, sonnet-cheap
**Optional in**: opus-cto (Opus 1M handles inline), pro-plan (inline by necessity)

### stp-explorer

**Purpose**: Codebase exploration isolation. Fresh Sonnet context per call. Runs Glob → Grep → Read, builds a structural map, returns a tight summary.

**When to fire**:
- Any operation touching >5 files
- Any Glob result with >20 matches
- Any Grep with >50 matches
- Any "find where X is used" that requires reading multiple files

**Prompt budget**: ≤2K tokens | **Report budget**: ≤30 lines structured (file:line map, relationships, dependency chain)

**Mandatory in**: balanced, sonnet-turbo, opus-budget, sonnet-cheap
**Optional in**: opus-cto, pro-plan

### Why isolation works (the math)

Without isolation: a research call loading Next.js docs (~50KB) + 10-file exploration (~30KB) + build planning (~20KB) = 100KB consumed BEFORE writing any code. A Sonnet 200K window has ~120KB usable after system prompts + tool definitions. You hit compaction before the first line.

With isolation: the research lives in a fresh 200K window that's garbage-collected after returning a 1KB summary. Main session sees only the summary. Net usage: ~3KB vs 100KB. **33× reduction**, room for the full build.

## What doesn't change across profiles

Regardless of active profile, these always run:

- All 19 hook gates (PreToolUse, PostToolUse, Stop, SessionStart, PreCompact)
- The 6-layer verification stack (where applicable — pro-plan drops Layer 5)
- The Pre-Work Confirmation Gate (AskUserQuestion before any write/edit)
- The Spec Delta merge-back system
- The Given/When/Then + RFC 2119 spec format
- The whiteboard server for `/stp:think --whiteboard`
- Project Conventions enforcement
- The CLI output format (cyan banners, dim cyan evidence boxes, etc.)

The profile system changes **which models run where**, not **what gets enforced**.

## Legacy profile aliases (pre-v1)

For backward-compat, migrate-v1.sh rewrites old profile names on session start. The CLI resolver also accepts either form:

| Legacy name | v1 name |
|---|---|
| `intended-profile` | `opus-cto` |
| `balanced-profile` | `balanced` |
| `budget-profile` | `opus-budget` |
| `sonnet-main` | `sonnet-cheap` |
| `20-pro-plan` | `pro-plan` |

## See also

- `/stp:setup model` — switch profiles
- `/stp:setup pace` — switch curiosity dial (deep / batched / fast / autonomous)
- `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` — single source of truth + CLI (`set` / `current` / `resolve` / `resolve-all` / `table` / `discipline` / `all-tables` / `list` / `help`)
- `${CLAUDE_PLUGIN_ROOT}/references/pace-picker.md` — pace semantics
- `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md` — Opus 4.7 prompting idioms (parallel tool calls, context limit, INVERSION)
- `agents/researcher.md`, `agents/explorer.md`, `agents/critic.md` — generated from templates at profile-switch time
- [Anthropic harness research](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Phil Schmid: Agent Harness 2026](https://www.philschmid.de/agent-harness-2026)

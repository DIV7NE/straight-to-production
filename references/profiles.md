# STP Optimization Profiles

STP supports three optimization profiles that change which Claude models run the sub-agents. **Default: `balanced-profile`** — best cost/quality ratio for most users. Switch with `/stp:set-profile-model`.

> **Architecture:** Inspired by [GSD's `set-profile` design](https://github.com/gsd-build/get-shit-done) which works reliably. The single source of truth is `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` — a Node.js file with the canonical agent × profile → model mapping table, plus a CLI that STP commands and hooks call to resolve models at spawn time. Adding a new profile is one column in that file; no other changes needed.

**Sentinel values you'll see in the tables below:**
- `inherit` — sub-agent omits `model=` parameter; uses parent session model (Opus on Opus, Sonnet on Sonnet)
- `inline` — no sub-agent spawned; main session does the work directly

## Quick Comparison

| Sub-agent | intended-profile | balanced-profile | budget-profile |
|---|---|---|---|
| **stp-executor** (builds features) | `sonnet` | `sonnet` | `sonnet` |
| **stp-qa** (independent tester) | `sonnet` | `sonnet` | `sonnet` |
| **stp-critic** (Double-Check Protocol) | `sonnet` | `sonnet` | `haiku` (→ sonnet escalation on ≥2 issues) |
| **stp-critic-escalation** (Sonnet fallback) | `sonnet` | `sonnet` | `sonnet` |
| **stp-researcher** (Context7/Tavily/Web) | `inline` | `sonnet` | `sonnet` |
| **stp-explorer** (codebase Glob/Grep) | `inline` | `sonnet` | `sonnet` |

> **Why intended-profile uses `sonnet` (not `inherit`):** STP's original architecture deliberately uses Sonnet sub-agents even when the main session is Opus. This is the cost optimization at the heart of STP's design — Opus thinks (architecture, planning, review), Sonnet builds (cheap, equally capable for code writing per the SWE-bench numbers). The `inherit` sentinel is reserved for future profiles or non-Anthropic runtimes (Codex, OpenCode, Gemini CLI) where matching the main session model is the desired behavior.

| Discipline | intended-profile | balanced-profile | budget-profile |
|---|---|---|---|
| **/clear between phases** | recommended | mandatory | enforced (hook warns at 60%) |
| **Context Mode MCP** | recommended | mandatory | hard-block on >50 line ops |
| **Researcher mandatory** | false | true | true |
| **Explorer mandatory** | false | true | true |
| **Max main session** | unlimited | ~120K | ~100K |
| **Cost vs intended** | baseline (100%) | ~35-50% | ~20% |
| **Quality vs intended** | 100% | ~95% | ~85-90% (compensated by stricter Layers 1-4) |

**Reading the table:**
- `inherit` means the sub-agent uses the parent session's model. On an Opus 1M session, `inherit` is Opus. On a Sonnet 200K session, `inherit` is Sonnet. Works on Codex/OpenCode/Gemini CLI too.
- `inline` means no sub-agent is spawned at all — the main session does the work directly. Used in `intended-profile` for researcher/explorer because Opus 1M can absorb research/exploration inline without context pressure.

## Which Profile Should I Use?

**Pick `balanced-profile` (DEFAULT) if:**
- You have Opus access and want the best cost/quality ratio
- You're doing any standard development work — features, fixes, refactors
- You're comfortable with /clear between phases and trust sub-agent delegation
- You want ~50% cost savings with minimal quality drop on routine builds

**Pick `intended-profile` if:**
- You have Claude Code with Opus 4.6 [1M] access AND cost is not a constraint
- You want Opus to handle research/exploration inline (no delegation overhead)
- You're building high-stakes production software where the absolute highest quality bar matters
- You want the original STP architecture as documented in the [Anthropic harness research](https://www.anthropic.com/engineering/harness-design-long-running-apps)

**Pick `budget-profile` if:**
- You only have Sonnet/Haiku access (Pro tier or self-hosted)
- Cost is the primary constraint
- You're willing to trade some architectural depth for ~80% cost savings
- You can tolerate a slightly looser Critic in exchange for tighter deterministic verification (Layers 1-4 catch more)
- You're OK with the strictest context discipline (mandatory researcher/explorer, hard-block on large outputs)

## Profile Details

### intended-profile

> The original STP architecture. Built around Opus 4.6 [1M] context window, validated by Anthropic Labs' research on long-running agent harnesses.

**Main session model**: Opus 4.6 [1M] for every command. The main session can hold the entire research, planning, build, and review history without needing aggressive offloading. /clear is recommended between phases but not required.

**Sub-agent strategy**: Spawn Sonnet executors for parallel feature work (worktree isolation), Sonnet QA for independent testing, Sonnet Critic for the Double-Check Protocol. Researcher and explorer work happens inline in the main Opus session — no dedicated sub-agents for those roles.

**Context engineering**: Light-touch. Context Mode MCP is recommended for very large outputs (codebase analysis, test runs) but not strictly required. The 1M window absorbs the cost of holding raw output for most operations.

**Cost profile**: Highest. Every main-session token is Opus-priced. Worth it when quality matters and the build is complex.

### balanced-profile

> The GSD-style split. Opus does the thinking (planning, research, design), Sonnet does the doing (execution, building, verification).

**Main session model**:
- **Planning commands** (`/stp:plan`, `/stp:research`, `/stp:whiteboard`, `/stp:new-project`, `/stp:onboard-existing`) → Opus 4.6 [1M]
- **Execution commands** (`/stp:work-full`, `/stp:work-quick`, `/stp:debug`, `/stp:autopilot`) → Sonnet 4.6 [200K]

This is the trickiest part of the profile. Because you can't switch a running session's model mid-conversation, the rule is: **start a new Claude Code session with the right model for the command you're about to run.** The statusline shows which profile is active and which model the next command expects.

**Sub-agent strategy**: All sub-agents are Sonnet 4.6. The new `stp-researcher` and `stp-explorer` sub-agents fire whenever the main session needs to gather research or explore the codebase — this keeps the main 200K session lean.

**Context engineering**: Mandatory. /clear between phases is required (the Sonnet main session compacts faster than Opus). Context Mode MCP must be used for any operation that produces >50 lines of output. Sub-agent prompts capped at 2K tokens, reports capped at 30 lines structured.

**Why this works**: The Anthropic harness research shows that fresh sub-agents with structured filesystem handoffs are equivalent to (and sometimes better than) a single long-running session. Sonnet 200K is sufficient when each sub-agent task is tightly scoped and decomposition is rigorous.

**Cost profile**: ~50% cheaper than intended on a typical build. Bigger savings on long-running execution phases.

**Quality drop**: ~5-10% on architecture-heavy work where Opus's deeper reasoning would catch more edge cases. Negligible on routine CRUD/UI/test builds.

### budget-profile

> The lean profile. Sonnet for planning AND execution. Haiku for first-pass verification, with Sonnet escalation when Haiku flags 2+ issues.

**Main session model**: Sonnet 4.6 [200K] for every command. No model switching.

**Sub-agent strategy**:
- Executors: Sonnet 4.6
- QA: Sonnet 4.6
- Critic: Haiku 4.5 (fast pattern scanner) → escalates to Sonnet when Haiku flags ≥2 issues
- Researcher: Sonnet 4.6 — **mandatory** for any research call (Context7, Tavily, web search)
- Explorer: Sonnet 4.6 — **mandatory** for any codebase exploration (Glob/Grep across multiple files)

**Context engineering**: Hardcore. The main session is treated as a thin coordinator that holds only decisions and pointers. Concrete rules:

1. `/clear` between phases is **enforced** (warning hook fires at 60% main-session capacity)
2. Context Mode MCP is **hard-blocked** on operations >50 lines (use `ctx_execute_file` or a sub-agent)
3. Every sub-agent prompt capped at **2K tokens**, report capped at **20 lines** (tighter than balanced)
4. Researcher/explorer mandatory — main session may NOT do research or codebase exploration directly
5. Anti-slop scan threshold tightened: 1 hit → BLOCK (vs WARN in other profiles)

**Critic split (Haiku fast pass + Sonnet escalation)**:
- **Pass 1 — Haiku 4.5**: Pattern-based structural scan. file:line evidence for hardcoded secrets, schema drift, accessibility violations, hollow tests, anti-slop indicators. Cheap, fast, catches surface issues.
- **Pass 2 — Sonnet 4.6 escalation**: Triggers ONLY when Haiku finds ≥2 critical issues or any FAIL. Runs the full Double-Check Protocol with behavioral verification. This keeps the average critic cost low (most builds don't escalate) while preserving the deep-reasoning safety net for problem builds.

**Compensation strategy**: Because the Critic is weaker on deep reasoning, budget-profile leans HARDER on Layers 1-4 of the verification stack:
- **Layer 1 (executable specs)**: All acceptance criteria MUST become BDD tests before any code is written. No exceptions.
- **Layer 2 (deterministic analysis)**: Hollow test detection, ghost coverage, placeholder scanning all run on every commit (tighter than other profiles).
- **Layer 3 (mutation challenge)**: Mandatory mutation-test pass on any new logic. AI tests have a 57% kill rate on average — mutation testing exposes the false-confident ones.
- **Layer 4 (property-based tests)**: Required for any function with >2 input dimensions. Catches edge cases the LLM never considered.

The verification stack as a whole compensates for Haiku's reasoning gap. The Critic stops being the safety net of last resort and becomes one of five deterministic checks.

**Cost profile**: ~20% of intended-profile cost. Best for prototyping, learning STP, or running on a tight budget.

**Quality drop**: ~10-15% on the rawest measure (model intelligence) but the strict context discipline + tighter Layers 1-4 + Sonnet escalation pull most of that back. Real-world quality drop on shipped code is closer to 5-8% if the discipline is followed.

## Research/Exploration Decision (200K profiles)

**The single biggest risk in 200K profiles** is the main session running out of context during research or codebase exploration. STP solves this with two new dedicated sub-agents:

### stp-researcher

**Purpose**: External research isolation. Lives in a fresh Sonnet 200K context per call. Returns a tight ≤30 line summary so the main session never holds raw research dumps.

**When to fire**:
- Any Context7 query (library documentation lookup)
- Any Tavily research query (best practices, comparisons, tutorials)
- Any WebSearch / WebFetch call
- Any reading of multi-page external documentation

**Prompt budget**: ≤2K tokens
**Report budget**: ≤30 lines structured (key findings, citations, TL;DR)
**Mandatory in**: balanced-profile, budget-profile
**Optional in**: intended-profile (Opus 1M handles inline)

### stp-explorer

**Purpose**: Codebase exploration isolation. Lives in a fresh Sonnet 200K context per call. Reads files, runs Glob/Grep, builds a structural map, and returns a tight summary.

**When to fire**:
- Any operation that touches >5 files at once
- Any Glob result with >20 matches
- Any Grep with >50 matches
- Any "find where X is used" task that requires reading multiple files

**Prompt budget**: ≤2K tokens
**Report budget**: ≤30 lines structured (file:line map, key relationships, dependency chain)
**Mandatory in**: balanced-profile, budget-profile
**Optional in**: intended-profile (Opus 1M handles inline)

### Why this works (the math)

Without isolation: a single research call that loads the Next.js docs (~50KB markdown) + a codebase exploration that reads 10 files (~30KB) + the build planning (~20KB) = 100KB consumed in the main session BEFORE any actual building. A Sonnet 200K window has ~120KB of *usable* context after system prompts and tool definitions. You hit compaction before you write the first line of code.

With isolation: the same research lives in a fresh 200K window that gets garbage-collected after returning a 1KB summary. The main session sees only the summary. Net main-session usage: ~3KB instead of 100KB. **33x reduction**, room for the entire build.

This matches the 4x context-token reduction claim from the [Meta-Harness paper](https://arxiv.org/abs/2603.28052) — STP's discipline pushes it further because we explicitly isolate by function (research vs explore vs build vs verify), not just by task chunk.

## What Doesn't Change Across Profiles

Regardless of which profile is active, these always run:

- All 16 hook gates (PreToolUse, PostToolUse, Stop, SessionStart, PreCompact)
- The 6-layer verification stack (executable specs, deterministic analysis, mutation challenge, property tests, cross-family AI review, production verification)
- The Pre-Work Confirmation Gate (AskUserQuestion before any write/edit)
- The Spec Delta merge-back system
- The Given/When/Then RFC 2119 spec format
- The whiteboard server for `/stp:whiteboard` and `/stp:plan`
- Project Conventions enforcement
- The CLI output format (cyan banners, dim cyan evidence boxes, etc.)

The profile system changes **which models run where**, not **what gets enforced**.

## See Also

- `/stp:set-profile-model` — switch profiles
- `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` — single source of truth (MODEL_PROFILES table + CLI: `set`/`current`/`resolve`/`resolve-all`/`table`/`discipline`/`all-tables`/`list`/`help`)
- `agents/researcher.md` — researcher sub-agent definition
- `agents/explorer.md` — explorer sub-agent definition
- `agents/critic.md` — critic with Haiku/Sonnet escalation logic
- `hooks/scripts/context-budget-warn.sh` — Stop hook that warns when main session approaches profile cap
- [Anthropic harness research](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Meta-Harness paper (arXiv 2603.28052)](https://arxiv.org/abs/2603.28052)
- [Phil Schmid: Agent Harness 2026](https://www.philschmid.de/agent-harness-2026)
- [Vercel: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- [GSD: get-shit-done](https://github.com/gsd-build/get-shit-done) — the inspiration for the cjs resolver pattern
- [Vercel: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)

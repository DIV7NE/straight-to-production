# STP — Straight To Production — Claude Code Plugin

## What This Is
A Claude Code plugin (v0.3.0) that turns Opus into your CTO. 15 commands, 3 agents, 26 reference files, 22 output templates, visual whiteboard, wave-based parallel building.

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
- **Sonnet executors** = builders (features on top of foundation, worktree isolation, Agent Teams for parallelism)
- **Sonnet QA** = independent tester (tests running app against PRD acceptance criteria)
- **Sonnet Critic** = code reviewer (7 criteria + Double-Check Protocol + Claim Verification Gate + 6-layer verification)

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

## Key Rules
- Opus NEVER writes implementation code (except foundation: DB, auth, config, one-line fixes)
- ALL features delegate to Sonnet executor via Agent Teams with worktree isolation
- AskUserQuestion tool is MANDATORY for ALL user decisions — NEVER print options as text, NEVER skip, NEVER decide for the user. Only exception: freeform input where structured options don't make sense (bug descriptions, QA feedback, feature requests)
- TaskCreate/TaskUpdate tracks ALL progress visibly
- README.md updated + VERIFIED after every feature
- 8-part research before every feature (codebase, impact, feature, security, resilience, edge cases, backward integration, anti-hallucination)
- Spec-first TDD: acceptance criteria → executable spec tests → behavioral tests → property-based tests → implementation. Stop hook blocks if no tests exist. Tests must verify real behavior, not mock satisfaction
- /simplify + hygiene scan after every build
- Version bump + CHANGELOG + CONTEXT.md update after every feature
- **Whiteboard server is MANDATORY and FIRST** for `/stp:whiteboard` and `/stp:plan`. The server start (`bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &`) MUST be the literal first action of those commands — unconditionally, no AskUserQuestion gate, no "if they accept" branch. For UI/UX detection in `/stp:work-quick` and `/stp:work-full`, the server starts BEFORE the design system is generated, never after. Reason: a whiteboard the user can't see is a broken command. Bug history: v0.3.0 had every server start gated behind `if they accept`, so the agent could reach the "write the data" step with no server running and the user opened localhost:3333 to nothing. Closed in v0.3.1.
- **FILENAME CONTRACT — the whiteboard data file is ALWAYS `.stp/whiteboard-data.json`. NEVER any other name.** Forbidden aliases that Claude sometimes hallucinates (all BLOCKED by `hooks/scripts/whiteboard-gate.sh`): `.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`. The whiteboard server (`whiteboard/serve.py`) polls only the canonical path — writes to any other name land in a file nothing watches and localhost:3333 stays on `{"status": "Waiting..."}` forever. If you find yourself about to write to `explore-data.json`, STOP: that is the pre-0.3.1 name, forbidden since 2026-04-08, retained in CHANGELOG.md only as a historical reference. The canonical name is `.stp/whiteboard-data.json` — nine characters, no dashes between "whiteboard" and "data", hyphen between "data" and "json". Reason: v0.3.3 post-mortem — the agent hallucinated `explore-data.json` from training data + CHANGELOG.md post-mortem references and the whiteboard-gate hook only matched the correct name, so the wrong filename slipped through the enforcement layer.
- **/clear suggested before every inter-command transition.** Whenever an STP command's completion box recommends a follow-up `/stp:*` command, the recommendation MUST be `/clear, then /stp:next-command` — never just `/stp:next-command` alone. Reason: each STP phase fills context with research, generation, and verification noise; the next phase reads its inputs from disk (PLAN.md, design-brief.md, CHANGELOG.md, current-feature.md), so a clear context is strictly better. The `/clear` line goes inside the completion box's `► Next:` block, with a one-line explanation of what survives on disk.

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

## Directory Map (where everything lives, when to read it)

### .stp/docs/ — Project Documents
| File | What | Read when... | Updated by |
|------|------|-------------|------------|
| ARCHITECTURE.md | Full codebase map (models, routes, components, integrations, dependencies) | Before ANY code change — check what exists and what could break | /stp:onboard-existing, milestone refresh |
| AUDIT.md | Production health (Sentry errors, deploy status, billing, performance) | Before fixing bugs, planning remediation | /stp:onboard-existing, /stp:review |
| PRD.md | Requirements + acceptance criteria | Starting features, QA, reviewing | /stp:new-project, /stp:work-quick |
| PLAN.md | Architecture + feature waves | Planning builds, dependency checks | /stp:plan, /stp:work-quick |
| CONTEXT.md | Concise AI reference (<150 lines) | Quick lookup, links to ARCHITECTURE.md for full detail | /stp:work-quick (per feature + milestone refresh) |
| CHANGELOG.md | Versioned history | Checking recent work | /stp:work-quick (per feature + milestone) |

### .stp/state/ — Runtime State (survives /clear + compaction)
| File | Purpose | Created by |
|------|---------|------------|
| current-feature.md | Active feature checklist | /stp:work-quick |
| handoff.md | Pause context for next session | /stp:pause (consumed by /stp:continue) |
| state.json | Emergency auto-save | PreCompact hook |

### .claude/skills/ — Required Companion Skills
| Skill | What | Invoke when... |
|-------|------|---------------|
| ui-ux-pro-max/ | Design intelligence — styles, palettes, fonts, product-type reasoning, DESIGN-SYSTEM.md generation | ANY UI/UX work — invoke `/ui-ux-pro-max` BEFORE writing frontend code |

### .stp/references/ — Production Standards (read BEFORE writing code)
| Directory/File | Read before touching... |
|----------------|----------------------|
| security/ | Auth, user input, API routes, secrets |
| accessibility/ | UI components, forms, navigation |
| performance/ | Data fetching, images, bundles |
| production/ | Error handling, deploy, monitoring, edge cases |
| cli-output-format.md | ANY command output — banners, status blocks, completions, QA reports |

### Root Files
| File | Why at root |
|------|------------|
| CLAUDE.md | Claude Code auto-reads from project root |
| VERSION | Statusline + scripts need instant access |

## Memory Strategy (how STP remembers across sessions)
STP uses file-based memory — everything lives in .stp/docs/. No reliance on Claude's conversation memory.
- **What was built + decisions + spec deltas**: CHANGELOG.md (append per feature — includes spec deltas showing how each feature mutated the system's architectural assumptions)
- **What exists now**: ARCHITECTURE.md (full map) + CONTEXT.md (concise)
- **What's planned**: PLAN.md (milestones, features, status)
- **What was promised**: PRD.md (requirements as structured Given/When/Then scenarios with RFC 2119 keywords)
- **Production health**: AUDIT.md (Sentry, deploy, billing — refreshed by /stp:review)
- **Bug patterns**: AUDIT.md Patterns & Lessons section (every debug writes a generalizable lesson — build reads these to avoid repeating mistakes)
- **Project conventions**: CLAUDE.md `## Project Conventions` section (living rules — grows from build decisions, debug lessons, Critic findings, and onboarding detection. Read on every session, enforced by Critic.)
- **Session continuity**: handoff.md (created by /stp:pause, consumed by /stp:continue — lessons preserved to CHANGELOG before deletion)
- **Session restore**: hook fires on start, reads state files, suggests /stp:continue

## Structured Spec Format (Given/When/Then + RFC 2119)

ALL acceptance criteria in PRD.md and PLAN.md MUST use structured scenarios with RFC 2119 severity keywords. This makes specs testable by design — each scenario maps directly to an executable test.

**Format:**
```markdown
### SPEC: [Feature Name]

**Requirements:**
- The system SHALL [mandatory behavior] (MUST-level)
- The system SHOULD [recommended behavior] (RECOMMENDED-level)
- The system MUST NOT [prohibited behavior]

**Scenarios:**
- Given [precondition], When [action], Then [expected outcome]
- Given [precondition], When [invalid action], Then [error handling]
- Given [edge case], When [action], Then [graceful behavior]
```

**RFC 2119 keywords** (use precisely):
- **SHALL / MUST** — absolute requirement. Tests MUST verify this. Failure = BLOCK.
- **SHOULD / RECOMMENDED** — expected unless good reason to deviate. Tests SHOULD verify.
- **MAY / OPTIONAL** — truly optional. Test if time allows.
- **MUST NOT / SHALL NOT** — absolute prohibition. Tests MUST verify this NEVER happens.

**Why this matters:** Freeform prose like "user can log in" is ambiguous. "Given a user with valid credentials, When they submit login, Then they SHALL receive a session token within 2 seconds" is testable, measurable, and unambiguous. The executor writes tests directly from scenarios. The Critic verifies each scenario has a corresponding test.

## Spec Delta System (tracks HOW the system evolves — with merge-back)

Every feature build produces a **Spec Delta** that captures how the feature mutated the system's architectural assumptions. Deltas are NOT just logged — they **merge back** into canonical docs.

**Spec Delta format (in CHANGELOG.md entries):**
```markdown
### Spec Delta
- **Added:** [new models, routes, integrations, patterns that didn't exist before]
- **Changed:** [existing assumptions that this feature invalidated or replaced]
- **Constraints introduced:** [new rules the system must now follow]
- **Dependencies created:** [what now depends on this feature]
```

**Delta merge-back (MANDATORY after every feature):**
After writing the spec delta to CHANGELOG.md, merge the changes into the canonical docs:
1. **Added** items → add to ARCHITECTURE.md (new models, routes, components sections)
2. **Changed** items → update ARCHITECTURE.md (replace outdated assumptions)
3. **Constraints introduced** → add to PRD.md `## System Constraints` section (append, don't replace)
4. **Dependencies created** → update ARCHITECTURE.md Feature Dependency Map
5. **If a SHOULD/SHALL requirement was added** → add to PRD.md as a new structured scenario

The canonical docs (PRD.md, ARCHITECTURE.md) are always the source of truth. CHANGELOG.md is the history. Spec deltas are the bridge — they describe what changed and drive the merge into canonical docs.

**Update vs New Change heuristic:**
When the user requests work that touches an existing feature:
- **Same intent + >50% overlap** with existing spec → UPDATE the existing scenarios in PRD.md. This is a refinement, not a new feature.
- **New intent or <50% overlap** → ADD new scenarios to PRD.md. This is net-new work.
- When uncertain, default to ADD (safer — doesn't risk losing existing spec intent).

**The Critic reads spec deltas** during verification to check: does the new feature contradict any previously established constraint? Does it create circular dependencies? Are all deltas properly merged back into canonical docs?

On any new session: read CHANGELOG.md (with spec deltas) for evolution history, ARCHITECTURE.md for current state, PLAN.md for what's next. This gives full project memory regardless of /clear, compaction, or machine changes.

## Statusline
Node.js statusline (stp-statusline.js) registered in ~/.claude/settings.json globally. Shows: model + effort level, project version, active feature + progress, current milestone, context usage bar with compaction threshold (green/yellow/orange/red).

## Hooks (16 enforcement gates across 4 events)

**IMPORTANT — hooks load at Claude Code SESSION STARTUP, not hot-reload.** After `/stp:upgrade` or any plugin update that adds or modifies hooks, you MUST exit Claude Code and restart it to pick up the new hooks. A running session keeps whatever hooks.json it loaded at launch. If a hook you expect to fire is silently ignored, this is almost always the cause — check your version with `cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and restart if the cached version is stale. (This is a Claude Code limitation, not fixable at the plugin level.)

**PreToolUse (2 gates — fire BEFORE Write/Edit/MultiEdit):**
1. **ui-gate.sh** → BLOCK new UI-file writes (`*.html`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`, `*.css`, etc.) until `.stp/state/ui-gate-passed` marker exists. Carve-outs: tests, stories, configs, migrations, file overwrites. Escape hatch: `STP_BYPASS_UI_GATE=1`. Closes v0.3.1 AI-slop landing page bug.
2. **whiteboard-gate.sh** → BLOCK writes to forbidden legacy filenames (`.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`) with correction instruction. For the canonical `.stp/whiteboard-data.json`, auto-start the whiteboard server if not running. Escape hatch: `STP_BYPASS_WHITEBOARD_GATE=1`. Closes v0.3.0 empty-localhost bug + v0.3.2 wrong-filename hallucination.

**PostToolUse (2 hooks — fire AFTER Write/Edit/MultiEdit):**
3. **post-edit-check.sh** → Stack-aware type/compile check (tsc, mypy, cargo check, go vet, etc.). Feedback via stderr, never blocks (feedback-only).
4. **anti-slop-scan.sh** → Deterministic grep scanner for 7 AI-slop patterns (gradient headlines, "Now in beta" eyebrow pills, template copy, "ship in minutes", sparkles brand marks, center-everything defaults, 3+ boxed benefit cards). 1 hit → WARN. 2+ hits → BLOCK. Escape hatch: `STP_BYPASS_SLOP_SCAN=1`.

**Stop (12 gates — fire when Claude tries to finish):**
5. Unchecked feature items → BLOCK (workflow gate, no retry)
6. PLAN.md should exist → WARN
7. Source files without tests → BLOCK
8. Hardcoded secrets → BLOCK (matches `sk_live_`, `sk_test_`, `AKIA...` patterns)
9. Placeholder/mock patterns → WARN (scans for `// TODO`, `// FIXME`, `lorem ipsum`, `mock data`, etc.)
10. Hollow test detection → WARN (tautological asserts, assertion-free test files)
11. Type/compile errors → BLOCK (Gate 7 in stop-verify.sh)
12. Test failures → BLOCK (Gate 8 in stop-verify.sh)
13. Schema drift detection → BLOCK (ORM schema files changed without migrations — catches Prisma, TypeORM, Django, Rails, Drizzle)
14. Scope reduction detection → WARN (PRD.md SHALL/MUST coverage in PLAN.md below 70%)
15. **Spec delta merge-back** → WARN (completed feature's CHANGELOG.md missing `### Spec Delta` block OR ARCHITECTURE.md not touched in last 5 commits)
16. **Critic required** → BLOCK (PLAN.md exists + feature complete + no `.stp/state/critic-report-*.md` newer than feature file — workflow gate, no retry count)
17. **QA required for UI features** → BLOCK (`.stp/state/ui-gate-passed` exists + feature complete + no `.stp/state/qa-report-*.md` — workflow gate, no retry count)

**SessionStart (1 hook — fires at every Claude Code session start):**
18. Wipes `.stp/state/ui-gate-passed` (forces re-confirmation of design direction every fresh session) + migrate old layout + restore context from disk.

**PreCompact (1 hook — fires before context compaction):**
19. Saves emergency state to `.stp/state/state.json` + broadcasts "commit your work now" to the active turn.

**3-retry safety valve:** Technical BLOCKs (tests, types, schema) count toward a 3-retry limit to prevent session bricking from stuck states. Workflow BLOCKs (unchecked items, Critic, QA) do NOT count — they require action but can't brick the session.

## Research
All research sources in RESEARCH-SOURCES.md. Key: Anthropic harness blog, Vercel AGENTS.md (100% vs 53%), Phil Schmid "Build to Delete", OX Security AI anti-patterns.

## Effort Levels
- /stp:new-project, /stp:plan, /stp:debug, /stp:work-full → max
- /stp:research → max
- /stp:whiteboard, /stp:work-quick, /stp:review, /stp:continue → high
- /stp:onboard-existing → max
- /stp:autopilot → medium
- /stp:progress, /stp:pause, /stp:upgrade → low

# STP — Ship To Production — Claude Code Plugin

## What This Is
A Claude Code plugin (v0.2.0) that turns Opus into your CTO. 15 commands, 3 agents, 26 reference files, 22 output templates, visual whiteboard, wave-based parallel building.

## Architecture
- **Opus** = CTO (plans, researches, reviews, merges, teaches). Builds foundation work directly (DB, auth, config).
- **Sonnet executors** = builders (features on top of foundation, worktree isolation, Agent Teams for parallelism)
- **Sonnet QA** = independent tester (tests running app against PRD acceptance criteria)
- **Sonnet Critic** = code reviewer (7 criteria + Double-Check Protocol + 6-layer verification)

## 6-Layer Verification Stack
Each layer catches what the others miss. LLM review (Critic) is Layer 5, not Layer 1.

| Layer | What | Type | Catches |
|-------|------|------|---------|
| 1. Executable specs | BDD tests from PRD acceptance criteria | Deterministic | Logic errors, boundary bugs, missing features |
| 2. Deterministic analysis | Hollow test detection, ghost coverage, placeholder scanning | AST/grep | AI slop in tests, tautological asserts, mock-only suites |
| 3. Mutation challenge | Flip operators, remove guards, change boundaries — do tests catch it? | Adversarial | Tests that look good but verify nothing (57% kill rate for AI tests) |
| 4. Property-based tests | Invariants for all inputs: round-trip, conservation, idempotency | Automated | Edge cases AI never considered |
| 5. Cross-family AI review | Critic (Claude) + non-Claude models with role-specific lenses | LLM | Architectural drift, wrong assumptions, correlated blind spots |
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
| **Vercel Agent Browser** | Headless browser for QA — navigate pages, click elements, verify rendered state, take screenshots, test responsive layouts | STP's QA agent (Phase 6g) and `/stp:review` need browser access to test the running application like a real user. Without it, QA is limited to API-level testing. |

**Enforcement:** `/stp:new-project` and `/stp:onboard-existing` preflight checks verify plugins and MCP servers are available. If missing, the user is prompted to install before proceeding. Any STP command that touches UI/UX code MUST invoke `/ui-ux-pro-max` before writing frontend code. Research phases MUST use Context7 for library docs and Tavily for industry research — never rely solely on training data.

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

<!-- STP:stp-output-format:start -->
## CLI Output Formatting (ENFORCED)
ALL STP command output MUST use the visual templates in `.stp/references/cli-output-format.md`. Read it before displaying any status, progress, or completion information. Key rules:
- Every `/stp:` command starts with a **Command Banner** (╔═╗ double-line box with command name + tagline)
- Major events (feature complete, milestone, bug fixed) use **double-line boxes** (╔═╗)
- Evidence/data (scans, reports, QA) use **single-line boxes** (┌─┐)
- Teach moments use **dimmed prefix** (┊) — subtle, never outshine actual output
- Status symbols: ✓ success, ✗ failure, ⚠ warning, ★ milestone, ► next step
- Next steps always use `► Next: /stp:[command]` format
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

## Hooks (8 enforcement gates)
1. Unchecked feature items → BLOCK
2. PLAN.md should exist → WARN
3. Source files without tests → BLOCK
4. Hardcoded secrets → BLOCK
5. Placeholder/mock patterns in source files → WARN (scans for: `// TODO`, `// FIXME`, `// implement`, `lorem ipsum`, `placeholder`, `mock data`, `fake data`, `hardcoded`, `// ...`, `// rest of`)
6. Hollow test detection → WARN (tautological asserts, assertion-free test files)
7. Type/compile errors → BLOCK
8. Test failures → BLOCK

## Research
All research sources in RESEARCH-SOURCES.md. Key: Anthropic harness blog, Vercel AGENTS.md (100% vs 53%), Phil Schmid "Build to Delete", OX Security AI anti-patterns.

## Effort Levels
- /stp:new-project, /stp:plan, /stp:debug, /stp:work-full → max
- /stp:research → max
- /stp:whiteboard, /stp:work-quick, /stp:review, /stp:continue → high
- /stp:onboard-existing → max
- /stp:autopilot → medium
- /stp:progress, /stp:pause, /stp:upgrade → low

# STP — Ship To Production — Claude Code Plugin

## What This Is
A Claude Code plugin (v0.2.0) that turns Opus into your CTO. 14 commands, 3 agents, 25 reference files, 20 templates, visual whiteboard, wave-based parallel building.

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

## Task Routing (Scale-Adaptive — auto-classify before suggesting a command)

When the user describes work WITHOUT specifying an STP command, classify the task and suggest:

| Signal | Classification | Route to |
|--------|---------------|----------|
| 1-line change, typo, config tweak, version bump | Trivial | Just do it inline — no command needed |
| Bug with clear symptoms, error message, stack trace | Bug | `/stp:debug` |
| Small task, <3 files, known scope | Quick task | `/stp:quick` |
| Feature that touches 3+ files, needs research | Serious work | `/stp:work` |
| Vague idea, "should I use X or Y?", exploration | Thinking | `/stp:whiteboard` |
| "Research X before building" | Research only | `/stp:research` |
| New project from scratch | New project | `/stp:new-project` |
| Existing codebase, first time with STP | Onboarding | `/stp:onboard-existing` |

**Adaptive downshift:** If `/stp:work` Phase 1 reveals a trivial task (1-2 files, no architectural impact, no new models/routes), say: "This is a quick fix — dropping to `/stp:quick` mode to skip the full architecture cycle." Don't force 12 planning sub-phases on a CSS change.

**Adaptive upshift:** If `/stp:quick` Step 2 (Research) reveals the task is bigger than expected (needs new models, touches auth, has security implications), say: "This is more complex than a quick task — recommend switching to `/stp:work` for the full cycle. Want to upgrade?"

## Commands
**Getting started:**
- `/stp:new-project` — "I'm starting from scratch." Pre-flight → questions → stack → PRD.md
- `/stp:onboard-existing` — "I have an existing codebase." Full analysis → architecture map → plan
- `/stp:plan` — "Design the architecture." 9-phase blueprint → Critic verifies → PLAN.md

**Doing work:**
- `/stp:work` — "I have serious work to do." Full cycle: understand → tools → research → plan → build
- `/stp:research` — "I need to think first." Investigate approaches, create plan. No code written.
- `/stp:quick` — "Just do it." Jumps into building. For small tasks, fixes, refactors.
- `/stp:debug` — "Something is broken." Root cause analysis → evidence-based fix → defense-in-depth

**Quality + operations:**
- `/stp:review` — "Grade my work." Separate AI evaluates against 7 criteria
- `/stp:autopilot` — "Build overnight." Same as /stp:work but AI decides everything
- `/stp:whiteboard` — "I need to think." Explore ideas, compare options, no commitment

**Session management:**
- `/stp:progress` — "Where are we?" Status dashboard — what's done, next, warnings
- `/stp:continue` — "Pick up where I left off." Reads state files, starts working immediately
- `/stp:pause` — "I'm done for now." Saves context for next session
- `/stp:upgrade` — "Update STP." Pulls latest + syncs companion plugins + refreshes CLAUDE.md sections + verifies hooks

## Required Companion Plugins
STP requires the following plugins installed in every project it manages:

| Plugin | Purpose | Install |
|--------|---------|---------|
| **ui-ux-pro-max** (v2.5+) | Design intelligence — 67 styles, 161 palettes, 57 font pairings, product-type-aware recommendations. Generates persistent DESIGN-SYSTEM.md. | `npm i -g uipro-cli && uipro init --ai claude` |

**Enforcement:** `/stp:new-project` and `/stp:onboard-existing` preflight checks verify these are installed. If missing, the user is prompted to install before proceeding. Any STP command that touches UI/UX code MUST invoke `/ui-ux-pro-max` before writing frontend code — this supplements (not replaces) the `/frontend-design` skill.

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

## Directory Map (where everything lives, when to read it)

### .stp/docs/ — Project Documents
| File | What | Read when... | Updated by |
|------|------|-------------|------------|
| ARCHITECTURE.md | Full codebase map (models, routes, components, integrations, dependencies) | Before ANY code change — check what exists and what could break | /stp:onboard-existing, milestone refresh |
| AUDIT.md | Production health (Sentry errors, deploy status, billing, performance) | Before fixing bugs, planning remediation | /stp:onboard-existing, /stp:review |
| PRD.md | Requirements + acceptance criteria | Starting features, QA, reviewing | /stp:new-project, /stp:quick |
| PLAN.md | Architecture + feature waves | Planning builds, dependency checks | /stp:plan, /stp:quick |
| CONTEXT.md | Concise AI reference (<150 lines) | Quick lookup, links to ARCHITECTURE.md for full detail | /stp:quick (per feature + milestone refresh) |
| CHANGELOG.md | Versioned history | Checking recent work | /stp:quick (per feature + milestone) |

### .stp/state/ — Runtime State (survives /clear + compaction)
| File | Purpose | Created by |
|------|---------|------------|
| current-feature.md | Active feature checklist | /stp:quick |
| handoff.md | Pause context for next session | /stp:pause (consumed by /stp:continue) |
| state.json | Emergency auto-save | PreCompact hook |

### .claude/skills/ — Required Companion Skills
| Skill | What | Invoke when... |
|-------|------|---------------|
| ui-ux-pro-max/ | Design intelligence — styles, palettes, fonts, product-type reasoning, DESIGN-SYSTEM.md generation | ANY UI/UX work — invoke `/ui-ux-pro-max` BEFORE writing frontend code |

### .stp/references/ — Production Standards (read BEFORE writing code)
| Directory | Read before touching... |
|-----------|----------------------|
| security/ | Auth, user input, API routes, secrets |
| accessibility/ | UI components, forms, navigation |
| performance/ | Data fetching, images, bundles |
| production/ | Error handling, deploy, monitoring, edge cases |

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
- **What was promised**: PRD.md (requirements, acceptance criteria)
- **Production health**: AUDIT.md (Sentry, deploy, billing — refreshed by /stp:review)
- **Bug patterns**: AUDIT.md Patterns & Lessons section (every debug writes a generalizable lesson — build reads these to avoid repeating mistakes)
- **Project conventions**: CLAUDE.md `## Project Conventions` section (living rules — grows from build decisions, debug lessons, Critic findings, and onboarding detection. Read on every session, enforced by Critic.)
- **Session continuity**: handoff.md (created by /stp:pause, consumed by /stp:continue — lessons preserved to CHANGELOG before deletion)
- **Session restore**: hook fires on start, reads state files, suggests /stp:continue

## Spec Delta System (tracks HOW the system evolves, not just WHAT was built)

Every feature build appends a **Spec Delta** to its CHANGELOG entry. A spec delta captures how the feature mutated the system's architectural assumptions — not just what code changed, but what the system IS now vs what it WAS.

**Spec Delta format (in CHANGELOG.md entries):**
```markdown
### Spec Delta
- **Added:** [new models, routes, integrations, patterns that didn't exist before]
- **Changed:** [existing assumptions that this feature invalidated or replaced]
- **Constraints introduced:** [new rules the system must now follow — e.g., "all invoices must have at least one line item"]
- **Dependencies created:** [what now depends on this feature — e.g., "PDF export requires invoice.lineItems to be populated"]
```

**Why this matters:** ARCHITECTURE.md shows what exists NOW. CHANGELOG shows what was BUILT. Spec deltas show what CHANGED IN MEANING — the evolution of architectural intent. When a future feature contradicts a past assumption, the delta trail shows exactly when and why that assumption was established.

**The Critic reads spec deltas** during verification to check: does the new feature contradict any previously established constraint? Does it create circular dependencies in the delta trail?

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
- /stp:new-project, /stp:plan, /stp:debug, /stp:work → max
- /stp:research → max
- /stp:whiteboard, /stp:quick, /stp:review, /stp:continue → high
- /stp:onboard-existing → max
- /stp:autopilot → medium
- /stp:progress, /stp:pause, /stp:upgrade → low

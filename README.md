# STP — Straight To Production

**Your CTO in a plugin.**

Picks the stack, walks you through the tradeoffs, builds the thing, and teaches you what it did along the way.

## The Problem

Most Claude Code harnesses were built by senior engineers for senior engineers. They expect you to already know the right stack, the security gotchas, the accessibility rules, and how to tell when something is actually ready to ship.

If you're a solo developer who doesn't know what you don't know, those tools just add ceremony. They don't fill the gap.

## How STP Works

You say what you want. STP picks the stack, walks you through the tradeoffs, points out the things you forgot to think about, and builds it. You handle product calls. Opus handles the rest.

```
YOU: "I want an app where freelancers track invoices"

STP:
├── Decides the entire stack (with alternatives + honest downsides)
├── Asks PRODUCT questions only (one at a time, never technical)
├── Surfaces what you didn't think of (auth, security, empty states...)
├── Creates: .stp/docs/PRD.md, .stp/docs/PLAN.md, .stp/docs/ARCHITECTURE.md,
│   .stp/docs/CONTEXT.md, .stp/docs/CHANGELOG.md, .stp/docs/AUDIT.md, CLAUDE.md
├── Visual whiteboard: live diagrams in your browser (localhost)
├── Impact analysis: checks what existing features each new feature touches
├── Structured specs: Given/When/Then + RFC 2119 (SHALL/MUST/SHOULD) — every scenario
│   maps to an executable test
├── Spec-first TDD: acceptance criteria → executable specs → behavioral tests → build
├── 10 enforcement gates: unchecked items, plan missing, tests exist, no secrets,
│   placeholder scanning, hollow test detection, type/compile errors, test failures,
│   schema drift detection, scope reduction detection
├── 6-layer verification stack (each layer catches what the others miss):
│   1. Executable specs (BDD from PRD acceptance criteria)
│   2. Deterministic analysis (hollow test detection, ghost coverage, placeholder scanning)
│   3. Mutation challenge (flip operators — do tests actually catch it?)
│   4. Property-based tests (invariants for all inputs: round-trip, idempotency)
│   5. Cross-family AI review (Critic + Claim Verification Gate + non-Claude models)
│   6. Production verification (canary deploys, metric monitoring)
├── Auto-Critic at every milestone (Double-Check Protocol, 2-iteration minimum,
│   Claim Verification Gate — traces execution paths before reporting behavioral bugs)
└── STP remembers: each build writes a Spec Delta into CHANGELOG, then propagates
    it back into ARCHITECTURE and PRD. Old bugs end up as System Constraints and
    Project Conventions that the next build has to obey.
```

## Architecture

```
stp/
├── commands/           # 16 commands
│   ├── whiteboard.md       # /stp:whiteboard — Explore ideas + research (design brief output)
│   ├── new-project.md      # /stp:new-project — Start a new project
│   ├── plan.md             # /stp:plan — Design the architecture
│   ├── work-adaptive.md    # /stp:work-adaptive — Impact scan → auto-routes to quick or full
│   ├── work-full.md        # /stp:work-full — Full cycle, zero compromise (22 sub-phases)
│   ├── work-quick.md       # /stp:work-quick — Quick build (≤3 files, no new models)
│   ├── research.md         # /stp:research — "I need to think first" (no code)
│   ├── review.md           # /stp:review — "Grade my work" (7 criteria + 6-layer verification)
│   ├── autopilot.md        # /stp:autopilot — "Build overnight" (AI decides)
│   ├── debug.md            # /stp:debug — Systematic debugging (root cause + full doc cycle)
│   ├── codebase-mapping.md # /stp:codebase-mapping — Export self-contained HTML codebase map
│   ├── progress.md         # /stp:progress — Check project status
│   ├── continue.md         # /stp:continue — Resume where you left off
│   ├── pause.md            # /stp:pause — Save progress, take a break
│   ├── onboard-existing.md # /stp:onboard-existing — Read-only exploration of existing project
│   └── upgrade.md          # /stp:upgrade — Pull latest + sync everything
├── agents/             # 3 independent Sonnet agents
│   ├── executor.md     # Builder — TDD in isolated worktrees
│   ├── qa.md           # QA tester — tests running app against PRD
│   └── critic.md       # Reviewer — grades code against 7 criteria + System Constraint compliance
├── hooks/              # 11 scripts (4 hook-triggered + 5 utilities + 2 statusline)
│   ├── hooks.json
│   └── scripts/
│       ├── stop-verify.sh       # Quality gate: 10 enforcement gates (stack-aware, 3-attempt max)
│       ├── post-edit-check.sh   # Type check after edits (stack-aware)
│       ├── pre-compact-save.sh  # State save before compaction
│       ├── session-restore.sh   # State restore on session start
│       ├── migrate-layout.sh    # Auto-migrate old flat layout → organized
│       ├── setup-references.sh  # Copy reference files into project
│       ├── start-whiteboard.sh  # Launch whiteboard server
│       ├── check-upgrade.sh     # Check for newer STP version
│       ├── stp-auto.sh          # Autonomous loop (overnight mode)
│       ├── stp-statusline.js    # Node.js statusline (primary)
│       └── stp-statusline.sh    # Bash statusline (fallback)
├── references/         # Universal production standards (26 files)
│   ├── security/       # OWASP, env handling, auth, validation, API
│   ├── accessibility/  # WCAG AA, keyboard, screen reader, contrast
│   ├── performance/    # Web Vitals, bundles, queries, images
│   ├── production/     # Errors, loading, empty states, edge cases, SEO, legal
│   └── cli-output-format.md  # ANSI color system — cyan banners, severity colors
├── whiteboard/         # Visual whiteboard (live diagrams in browser)
│   ├── index.html      # Dark-theme dashboard with Mermaid rendering
│   └── serve.py        # Lightweight Python server (zero dependencies)
└── templates/          # 20 stack templates + extensibility guide
    ├── nextjs-supabase.md
    ├── python-fastapi.md
    ├── rust-axum.md
    ├── csharp-aspnet.md
    ├── ... (20 total)
    └── TEMPLATE-GUIDE.md
```

### What STP Creates in Your Project

```
your-project/
├── CLAUDE.md                # Standards + patterns (Claude auto-reads from root)
├── VERSION                  # Current version (e.g., 0.1.3)
├── design-system/           # UI/UX design system (created for frontend projects)
│   ├── MASTER.md            # Global design rules (style, colors, fonts, layout)
│   └── pages/               # Page-specific overrides
└── .stp/
    ├── docs/                # Project documents
    │   ├── ARCHITECTURE.md  # Full codebase map (models, routes, deps)
    │   ├── AUDIT.md         # Production health (Sentry, deploy, billing)
    │   ├── PRD.md           # Requirements + acceptance criteria
    │   ├── PLAN.md          # Architecture blueprint + feature waves
    │   ├── CONTEXT.md       # Concise AI reference (<150 lines)
    │   └── CHANGELOG.md     # Versioned history
    ├── state/               # Runtime state (survives /clear + compaction)
    │   ├── current-feature.md  # Active feature checklist
    │   ├── handoff.md       # Pause context for next session
    │   └── state.json       # Auto-save before compaction
    └── references/          # Production standards (read before coding)
        ├── security/        # OWASP, auth, secrets, API security
        ├── accessibility/   # WCAG AA, keyboard, screen reader
        ├── performance/     # Web Vitals, bundles, queries
        └── production/      # Errors, deploy, monitoring, edge cases
```

Existing projects using the old flat layout (docs at root, state files in `.stp/`) are auto-migrated on first session start after upgrade.

## Required Companion Plugins & MCP Servers

STP checks for these during setup (`/stp:new-project`, `/stp:onboard-existing`) and upgrade (`/stp:upgrade`). Install them for full capability:

### Plugins (per project)
| Plugin | Purpose | Install |
|--------|---------|---------|
| **[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** (v2.5+) | Design intelligence — 67 styles, 161 palettes, 57 font pairings. Generates `design-system/MASTER.md` that all build commands read before writing frontend code. | `npm i -g uipro-cli && uipro init --ai claude` |

### MCP Servers (global — install once)
| MCP Server | Purpose | Install |
|------------|---------|---------|
| **[Context7](https://github.com/upstash/context7)** | Live documentation — query current API docs, verify patterns against latest library versions. Prevents building on stale training data. | `claude mcp add context7 -- npx -y @upstash/context7-mcp@latest` |
| **[Tavily](https://tavily.com)** | Deep web research — best practices, industry standards, security advisories, competitive analysis. | `claude mcp add tavily -- npx -y tavily-mcp@latest` + set `TAVILY_API_KEY` |
| **[Context Mode](https://github.com/context-labs/context-mode)** | Context window protection — runs commands in sandbox, prevents context flooding, enables longer sessions before compaction. | `claude mcp add context-mode -- npx -y context-mode-mcp@latest` |
| **[Vercel Agent Browser](https://github.com/vercel-labs/agent-browser)** | Browser automation CLI for AI agents — navigate pages, click elements, verify rendered state, take screenshots, test responsive layouts. Native Rust CLI + Claude Code skill. | `npm i -g agent-browser && agent-browser install && npx skills add vercel-labs/agent-browser` (the second command downloads Chrome for Testing; the third installs the Claude Code skill that teaches the snapshot-ref workflow) |

When any STP command detects UI/UX work, it:
1. Generates a design system via ui-ux-pro-max
2. Renders a live preview in the whiteboard (color swatches, font samples, layout wireframe)
3. Asks you to approve before any frontend code is written
4. Persists to `design-system/MASTER.md` — the executor agents follow it exactly

## Supported Stacks

| Stack | Template | Use Case |
|-------|----------|----------|
| Next.js + Supabase + Clerk | nextjs-supabase.md | SaaS webapps, dashboards |
| Next.js + MDX | nextjs-marketing.md | Landing pages, blogs |
| Python + FastAPI | python-fastapi.md | REST APIs, microservices |
| Python + Django | python-django.md | Full-stack web, admin-heavy |
| Python + Flask | python-flask.md | Lightweight APIs |
| Rust + Axum | rust-axum.md | High-performance APIs |
| Rust + Actix | rust-actix.md | Web services |
| Go + Chi | go-chi.md | Go REST APIs |
| Go + Gin | go-gin.md | Go web apps |
| C# + ASP.NET Core | csharp-aspnet.md | Enterprise APIs |
| C# + Blazor | csharp-blazor.md | .NET interactive web |
| Java + Spring Boot | java-spring.md | Enterprise Java |
| React Native + Expo | react-native-expo.md | Mobile apps |
| Electron + Vite | electron-vite.md | Desktop apps |
| SvelteKit | svelte-kit.md | Fast web apps |
| Vue + Nuxt | vue-nuxt.md | Vue ecosystem |
| PHP + Laravel | php-laravel.md | PHP web apps |
| Ruby + Rails | ruby-rails.md | Full-stack web |

**Add your own:** Follow `templates/TEMPLATE-GUIDE.md` — one markdown file, no code changes needed.

## Usage

### 0. Whiteboard (optional — use anytime)
```
/stp:whiteboard I have an idea for a fitness tracking app
/stp:whiteboard should we use WebSockets or SSE for real-time?
/stp:whiteboard this payment feature is complex, what's the best approach?
```
A space for thinking out loud. Research approaches, compare options, weigh tradeoffs against industry practice. Nothing gets built. The decisions you make get saved to disk, so they survive `/clear` and the next command can pick them up. Use it before `/stp:new-project` to shape a vague idea, before `/stp:work-quick` for any non-trivial decision, or on its own when you just need a sounding board.

### 1. Start a new project
```
/stp:new-project an app where freelancers track invoices and expenses
```
Opus asks product questions (one at a time), proposes the full stack with alternatives and honest downsides, surfaces what you'd miss. Creates **.stp/docs/PRD.md** (with acceptance criteria), **.stp/docs/CONTEXT.md** (codebase map), **.stp/docs/CHANGELOG.md**, **VERSION**, CI pipeline, and scaffolds the foundation.

### 2. Plan the architecture
```
/stp:plan
```
Researches the domain, designs system architecture, data models, API routes, auth model, error strategy, Feature Touchpoint Map (where each feature appears across the app). Visual whiteboard renders diagrams live. Critic verifies the plan. Writes **.stp/docs/PLAN.md**. No code — just the verified blueprint.

### 3. Develop (full cycle — idea to delivery)
```
/stp:work-full update stripe payments and the entire pricing plan
/stp:work-full add real-time notifications with WebSockets
/stp:work-full rebuild the auth system with role-based access
```
Use this when the work is non-trivial. STP asks product questions to pin down requirements, installs whatever extra tools the work needs (Stripe MCP, CLIs), researches the space using Context7 and Tavily, lays out a few possible approaches, gets your sign-off on a plan, then builds it test-first. If you want it to make the decisions for you, run `/stp:autopilot add payment processing` instead — same flow, the AI just picks the recommended option at every step.

### 3b. Propose work (discuss before building)
```
/stp:research add payment processing
/stp:research refactor the auth system
/stp:research should we migrate to server actions?
```
Full investigation before committing to code. Researches the domain, explores 2-3 approaches with tradeoffs, maps how it fits YOUR codebase (from ARCHITECTURE.md), surfaces risks and what you didn't think of. Saves the plan — `/stp:work-quick` picks it up when you're ready. No code written.

### 4. Build / Fix / Refactor (TDD)
```
/stp:work-quick add Stripe payments
/stp:work-quick fix the 5 critical Sentry errors from AUDIT.md
/stp:work-quick refactor auth middleware to use centralized pattern
/stp:work-quick update invoice PDF export to use new template
```
Handles all work types from one command. Before writing any code it reads four things: ARCHITECTURE.md (so it knows what the change might break), the System Constraints section of PRD.md (rules from past bugs that can't be broken), the Project Conventions section of CLAUDE.md, and the Patterns & Lessons section of AUDIT.md (so it doesn't reintroduce a bug class you've already fixed). Then it writes the tests, builds the implementation, and runs `/simplify` over the result.

Once the code is in, STP runs the full doc cycle: bumps VERSION, adds a CHANGELOG entry with a spec delta, propagates that delta into ARCHITECTURE and PRD, refreshes CONTEXT.md, verifies README claims still match the code, captures any new conventions in CLAUDE.md, and updates AUDIT.md if a bug got fixed along the way. At milestone boundaries it spawns the Critic and runs integration tests. You learn the codebase as you go because STP explains what it's doing.

### 4. Review quality
```
/stp:review
```
A separate Sonnet Critic grades your app against PRD + PLAN + 7 quality criteria with file:line evidence and business impact. Runs the full 6-layer verification stack: executable spec checks, hollow test detection, mutation challenge, **System Constraint compliance** (verifies new code obeys every SHALL/MUST in PRD.md), Claim Verification Gate (traces execution paths before reporting behavioral bugs — eliminates false positives from grep patterns), and the Double-Check Protocol (2-iteration minimum). Refreshes AUDIT.md with current Sentry/Vercel/Stripe data if MCP services are connected.

### 5. Debug (root cause + full doc cycle)
```
/stp:debug the dashboard shows wrong totals after invoice deletion
/stp:debug Sentry: TypeError on /api/checkout
/stp:debug login redirects to /404 for some users
```
Iron Law: no fix without a root cause. Phase 0 auto-gathers everything STP can find without bothering you — the AUDIT.md bug history (which often resolves a known pattern in seconds), the ARCHITECTURE.md dependency map, the System Constraints in PRD.md (the bug might have been *caused* by violating one), error logs, git blame, MCP services. From that material STP traces the defect → infection → failure chain back to its origin. It then looks for pattern siblings (the same bug class hiding somewhere else) and fixes those too, and adds a defense layer so the same failure can't come back through a different code path.

Once the fix is in, STP treats it like any other release. It bumps the patch version, writes a CHANGELOG entry with a spec delta, propagates the delta into ARCHITECTURE.md and PRD.md System Constraints (the rule the bug exposed becomes a SHALL/MUST the codebase can never violate again), extracts a generalizable lesson into AUDIT.md's Patterns & Lessons section, adds a Project Convention to CLAUDE.md if the rule belongs there, updates CONTEXT.md and README.md, marks the bug fixed in PLAN.md, and commits. Next session, every build command reads those updates as input. The bug doesn't come back because the rule that prevents it now lives in the docs the next build reads.

If three different hypotheses fail in a row, the problem is probably structural, not a single bug. STP stops trying patches and escalates to a design discussion.

### 6. Run overnight
```
/stp:autopilot add payment processing with Stripe and webhooks
```
Same flow as `/stp:work-full`, except the AI picks the recommended option at every decision point instead of asking you. It spawns executors in waves, runs QA, runs the Critic, updates the docs, and commits each feature on its own. You can run it before bed and check the result in the morning. Progress streams to `.stp/state/` so `/stp:progress` works from any device.

### 7. Check progress
```
/stp:progress
```
Shows project version, milestone progress (done/total), active feature status, recent activity, uncommitted work, and the exact next command to run. Read-only — doesn't modify anything.

### 8. Resume work
```
/stp:continue
```
Reads all state files (handoff, feature checklist, plan) and immediately picks up where you left off. No questions — just starts working on the next task. Use after `/clear`, compaction, or starting a new session.

### The full flow
```
/stp:whiteboard        → Shape ideas, research approaches (optional, anytime)
/stp:new-project       → Everything needed to start: PRD.md, PLAN.md, CONTEXT.md, CHANGELOG.md, VERSION, CLAUDE.md
/stp:plan              → .stp/docs/PLAN.md (how we're building it — verified by Critic)
/stp:work-full         → Full cycle: understand → tools → research → architecture blueprint → TDD build → QA → Critic → doc cycle
/stp:research          → Research → approaches → architecture fit → impact → saved plan (stops before building)
/stp:work-quick        → Executes plan → TDD → milestone auto-eval → full doc cycle
/stp:review            → Separate AI grades against PRD + PLAN + 7 criteria + System Constraint compliance
/stp:debug             → Systematic root-cause debugging → fix → full doc cycle (bug fix = release: VERSION bump, CHANGELOG, delta merge-back, AUDIT lesson, Patterns extracted)
/stp:codebase-mapping  → Export self-contained HTML map — open in any browser, share via gist, reference offline
/stp:progress          → Check what's done, in progress, and next
/stp:continue          → Resume exactly where you left off (after /clear or new session)
/stp:pause             → Save state → /clear → resume next session
/stp:autopilot         → Overnight autonomous: same as work-full but AI decides every option
/stp:onboard-existing  → READ-ONLY. Explore existing project → map architecture → generate observation report (no fixes, no installs, no edits)
/stp:upgrade           → Pull latest STP version + sync companion plugins + refresh CLAUDE.md sections + verify MCP servers
```

### Working on an existing project

```
Day 1 — Read-only exploration:
  /stp:onboard-existing              → READ-ONLY. Maps the entire codebase, writes
                                        ARCHITECTURE.md, CONTEXT.md, reverse-engineered PRD.md,
                                        and PLAN.md as a numbered OBSERVATION REPORT
                                        (not a remediation plan). DETECTS MCP services
                                        without connecting or installing anything.
                                        Never edits source code, configs, deps, or tests.
                                        The codebase is exactly as you left it.

Day 1 — You decide what to do next:
  /stp:plan                          → Design a remediation plan from the observations
                                        (this is where milestones + checkboxes get created)
  /stp:debug [OBS-007]               → Investigate a specific observation from onboarding
  /stp:work-full [feature]           → Build something using the new architecture map
  /stp:whiteboard                    → Think through tradeoffs before committing to a direction

Day 1+:
  /stp:progress                      → See what's planned, what's next
  /stp:work-quick fix critical Sentry errors → Reads ARCHITECTURE.md, PRD.md System Constraints,
                                                CLAUDE.md Project Conventions, and AUDIT.md
                                                Patterns & Lessons — knows what could break AND
                                                what past bugs to not repeat
  /stp:work-quick add new feature          → Impact analysis against full codebase map
  /stp:work-quick refactor auth module     → Dependency map shows what depends on it
  /stp:debug [bug]                         → Root cause analysis → fix → full doc cycle
                                               (VERSION bump + CHANGELOG + delta merge-back +
                                                AUDIT lesson + README/CONTEXT/PLAN updates)
  /stp:review                        → Refreshes AUDIT.md with latest Sentry/Vercel data

Session breaks:
  /stp:pause                         → Saves context + failed approaches
  (next session)
  /stp:continue                      → Reads handoff, preserves lessons to CHANGELOG, resumes

Everything persisted — the learning system:
  .stp/docs/ARCHITECTURE.md          → Full codebase map (updated per feature via delta merge-back)
  .stp/docs/AUDIT.md                 → Production health + Bug Fixes + Patterns & Lessons
  .stp/docs/PRD.md  ## System Constraints → RFC 2119 SHALL/MUST rules from past features/bugs
  CLAUDE.md  ## Project Conventions  → Living rules earned from decisions, bugs, Critic findings
  .stp/docs/CHANGELOG.md             → Full history + decisions + spec deltas
```

## Quality Enforcement (Hook Gates — Cannot Be Bypassed)

| # | Gate | What It Blocks | Enforcement |
|---|------|---------------|-------------|
| 1 | Unchecked items | Stopping with work remaining | 100% — hook exit 2 |
| 2 | `.stp/docs/PLAN.md` missing | Building features without a plan | Warning (non-blocking) |
| 3 | Tests must exist | Source files without any test files | 100% — hook exit 2 |
| 4 | No hardcoded secrets | Stripe keys, AWS keys, passwords in source | 100% — hook exit 2 |
| 5 | Placeholder/mock patterns | TODO, FIXME, lorem ipsum, mock data in source | Warning (non-blocking) |
| 6 | Hollow test detection | Tautological asserts, assertion-free test files | Warning (non-blocking) |
| 7 | Type/compile errors | Code with errors | 100% — hook exit 2 |
| 8 | Tests must pass | Failing tests | 100% — hook exit 2 |
| 9 | Schema drift detection | ORM schema changed without corresponding migration (Prisma, TypeORM, Django, Rails, Drizzle) | 100% — hook exit 2 |
| 10 | Scope reduction detection | PLAN.md covers <70% of PRD.md SHALL/MUST requirements | Warning (non-blocking) |

3-attempt safety valve prevents session bricking if an issue is truly unfixable.

### Deterministic Checks the Critic Runs (Layer 1–4 of the verification stack)

| # | Check | Catches | Blocking |
|---|-------|---------|----------|
| 1 | Executable specs | Missing tests for SHALL/MUST scenarios (Given/When/Then from PRD.md) | Yes — FAIL |
| 2 | System Constraint compliance | New code violates a previously-recorded constraint (past bug class reintroduced) | Yes — FAIL |
| 3 | Test quality (hollow test scan) | Tautological asserts, mock-only tests, tests that verify mock interactions instead of behavior | Yes — FAIL |
| 4 | Mutation challenge | Tests that look good but don't actually catch bugs (flip operators, remove guards — do tests fail?) | Warn if kill rate < threshold |
| 5 | Claim Verification Gate | Critic reporting behavioral bugs from grep patterns without tracing execution paths | Internal — downgrades unverified findings to NOTE |
| 6 | Spec delta merge-back | Constraints from CHANGELOG spec deltas not reflected in PRD.md / ARCHITECTURE.md | Yes — FAIL |

## Documents Generated (and who keeps them current)

Every command that ships code writes to the same set of docs. That's intentional: the things STP writes here are the things later commands read. Nothing rots, nothing sits unused, and the project memory survives between sessions because it lives on disk instead of in conversation context.

| Document | Created By | Updated By | Read By | Purpose |
|----------|-----------|------------|---------|---------|
| `.stp/docs/ARCHITECTURE.md` | new-project, onboard-existing | work-quick, work-full, debug (delta merge-back + milestone refresh) | work-quick, work-full, debug, research, codebase-mapping, autopilot | Full codebase map — models, routes, components, integrations, Feature Dependency Map |
| `.stp/docs/CONTEXT.md` | new-project, onboard-existing | work-quick, work-full, debug | work-quick, work-full, debug, continue, progress | Concise AI reference (<150 lines) — snapshot of what exists NOW |
| `.stp/docs/PRD.md` | new-project, onboard-existing (reverse-engineered) | plan, work-quick, work-full, debug | all build commands, Critic, review, progress | Requirements + structured Given/When/Then specs (RFC 2119 SHALL/MUST/SHOULD) |
| `.stp/docs/PRD.md` → `## System Constraints` | plan | work-quick, work-full, debug (delta merge-back) | **work-quick, work-full, debug (pre-build enforcement gate), Critic (compliance check)** | RFC 2119 SHALL/MUST rules earned from past features and bug fixes — never violated again |
| `.stp/docs/PLAN.md` | plan, onboard-existing (as observation report) | work-quick, work-full, debug (mark `[x]`) | work-quick, work-full, debug, progress, continue, Critic, work-adaptive | Architecture blueprint + feature waves + status |
| `.stp/docs/CHANGELOG.md` | new-project, onboard-existing | work-quick, work-full, debug (per feature/fix with spec delta) | progress, continue, Critic (reads spec deltas) | Versioned history with Added/Changed/Constraints introduced/Dependencies created |
| `.stp/docs/AUDIT.md` | onboard-existing, review | work-quick, work-full, debug, review | work-quick, work-full, debug, research, autopilot | Production health + `## Bug Fixes` + `## Patterns & Lessons` |
| `.stp/docs/AUDIT.md` → `## Patterns & Lessons` | debug (extracted from every bug) | debug | work-quick, work-full, research, debug (fast-path lookup) | Generalizable bug-prevention rules — "server actions don't inherit auth context" |
| `CLAUDE.md` → `## Project Conventions` | onboard-existing (detected from code) | work-quick, work-full, debug, review | work-quick, work-full, debug, Critic | Living rules grown from decisions, bugs, Critic findings |
| `README.md` | (yours — STP doesn't own it) | work-quick, work-full, debug | end users (humans) | MANDATORY update after every feature/fix — README must always reflect shipped reality |
| `design-system/MASTER.md` | ui-ux-pro-max integration | design review | work-quick, work-full executors | Style, palettes, fonts, layout rules — executors follow it exactly |
| `VERSION` | new-project, onboard-existing | work-quick, work-full, debug (patch bump), milestone boundaries (minor bump) | progress, continue, statusline, commit messages | Current semver version |

The reason every build command writes to the same docs isn't redundancy. The docs form a feedback loop. A bug fix lands a constraint in PRD.md. The next feature build reads that constraint before writing any code. The Critic checks the resulting code against it. The bug class is gone, and you didn't have to remember anything.

## How STP Learns

Most coding agents build whatever you ask for and then forget about it. STP records what just happened in a way the next session has to read. There are four feedback loops doing the work.

### Loop 1: Spec Deltas

Each build (whether it's `work-quick`, `work-full`, or a `debug` fix) writes a Spec Delta into CHANGELOG.md. The format is the same every time:

- **Added:** new models, routes, integrations, patterns
- **Changed:** assumptions this work invalidated
- **Constraints introduced:** rules the codebase now has to follow (RFC 2119 SHALL/MUST)
- **Dependencies created:** what now relies on this work

The delta doesn't stop at the changelog. After the entry is written, the build command propagates it: new models go into ARCHITECTURE.md, constraints go into PRD.md's System Constraints section, and any new SHALL/MUST rule shows up in PRD.md as a Given/When/Then scenario. The Critic checks the merge actually happened during review.

### Loop 2: System Constraints

When `/stp:debug` fixes a bug, the root cause usually points at a rule the codebase should have been following all along. STP writes that rule into PRD.md's `## System Constraints` section using RFC 2119 keywords:

```
SHALL: All multi-tenant queries are scoped by organizationId
SHALL: Uploads validate MIME type server-side, not just extension
MUST NOT: Server actions inherit middleware auth context — always pass orgId explicitly
```

Every build command reads this section before touching code. It's not advisory. If the new code doesn't satisfy a constraint, the Critic flags it as CRITICAL during review. Bugs you've already fixed stay fixed.

### Loop 3: Patterns & Lessons

`/stp:debug` also extracts the underlying pattern, not just the one-off fix:

```
### Server actions don't inherit middleware auth
Symptom: Query returns rows from other orgs
Root cause: Server actions bypass the middleware layer that sets auth context
Rule: Always pass organizationId explicitly in server actions
Applies when: Writing any server action that queries org-specific data
```

Lessons live in AUDIT.md's `## Patterns & Lessons` section. Build commands read them when gathering context, so what you learned the hard way last week ends up baked into next week's code. If AUDIT.md says "server actions need explicit orgId," the next server action you write gets it before anyone files a bug.

### Loop 4: Project Conventions

Sometimes a build, a bug, or a Critic finding reveals a rule worth keeping around. If it's non-obvious enough that the next person (or session) wouldn't figure it out on their own, STP appends it to `CLAUDE.md ## Project Conventions`:

```markdown
- **All API routes use withOrgAuth() wrapper — never raw auth()**
  - Why: Bug v0.3.7 — raw auth() leaked cross-org data
  - Applies when: Writing any API route in a multi-tenant context
  - Added: 2026-03-12 via /stp:debug
```

Build commands read this section before doing anything. The Critic checks compliance afterwards. The upshot is that joining the project (or starting a fresh Claude session) doesn't reset the rulebook — every convention you've earned stays in force.

### What this looks like in practice

| Without the loops | With them |
|---|---|
| A bug comes back three months later because nobody remembered the original fix | The constraint sits in PRD.md and the Critic blocks any code that violates it |
| One developer figures something out and it lives only in their head | The rule lands in CLAUDE.md and every future build reads it |
| Architecture docs drift further from reality each sprint | Each feature pushes its delta into ARCHITECTURE.md as part of the build cycle |
| Tribal knowledge evaporates between sessions | All four loops live on disk, so `/clear` and compaction can't touch them |

The point is that STP's docs aren't a write-only audit log. They're the input to every future build, which is why STP cares so much about keeping them current.

## Design Principles

1. **Opus is the CTO, you're the PM.** STP makes the technical calls and explains them. You make the product calls.
2. **Always-on context beats on-demand.** Rules live in CLAUDE.md (loaded every session) instead of skills (loaded only when triggered). Vercel's evals measured 100% vs 53% adherence, which matches our experience.
3. **Hooks enforce, prose suggests.** The quality gates that actually catch things are scripts, not paragraphs in a markdown file.
4. **Docs feed builds.** Everything STP writes gets read by a later command. If a doc isn't being read by anything, it gets cut.
5. **Old bugs stay fixed.** Every fix records a constraint. The Critic rejects new code that breaks it.
6. **Build to delete.** Every piece of STP can be removed independently without breaking the rest.
7. **Teach as you go.** STP explains what it's doing so you actually learn the codebase, not just inherit it.

## Model Requirements

- **Main session**: Claude Opus 4.6 (1M context)
- **Critic / Autonomous**: Claude Sonnet 4.6 (200K context)

## Research

- [Anthropic: Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Vercel: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- [Phil Schmid: Build to Delete](https://www.philschmid.de/agent-harness-2026)
- [Meta-Harness: Auto-evolved beats hand-engineered](https://arxiv.org/abs/2603.28052)

## License

MIT

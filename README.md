# STP — Ship To Production

**Your CTO in a plugin.**

Makes all technical decisions, explains them with industry backing and honest downsides, builds autonomously, and teaches you your own codebase.

## The Problem

Every existing Claude Code harness was built by expert developers, for expert developers. They assume you know what stack to choose, what security concerns apply, what accessibility requirements exist, and when your code is actually production-ready.

If you're a solo developer who doesn't know what you don't know, those tools add process without adding knowledge.

## How STP Works

You describe what you want to build. STP makes every technical decision, presents each one with alternatives and honest tradeoffs, surfaces everything you'd miss, and builds it. You make product decisions. Opus handles everything else.

```
YOU: "I want an app where freelancers track invoices"

STP:
├── Decides the entire stack (with alternatives + honest downsides)
├── Asks PRODUCT questions only (one at a time, never technical)
├── Surfaces what you didn't think of (auth, security, empty states...)
├── Creates: .stp/docs/PRD.md, .stp/docs/PLAN.md (verified), .stp/docs/CONTEXT.md, .stp/docs/CHANGELOG.md
├── Visual whiteboard: live diagrams in your browser (localhost)
├── Impact analysis: checks what existing features each new feature touches
├── TDD: writes tests before code, /simplify polishes after
├── 6 enforcement gates: type check, tests exist, tests pass, no secrets,
│   unchecked items, plan warning — cannot be bypassed
└── Auto-Critic at every milestone (separate Sonnet AI, not self-grading)
```

## Architecture

```
stp/
├── commands/           # 14 commands
│   ├── whiteboard.md      # /stp:whiteboard — Explore ideas + research
│   ├── new-project.md     # /stp:new-project — Start a new project
│   ├── plan.md            # /stp:plan — Design the architecture
│   ├── work.md            # /stp:work — "I have serious work" (full cycle)
│   ├── research.md        # /stp:research — "I need to think first" (no code)
│   ├── quick.md           # /stp:quick — "Just do it" (small tasks, fixes)
│   ├── review.md          # /stp:review — "Grade my work" (7 criteria)
│   ├── autopilot.md       # /stp:autopilot — "Build overnight" (AI decides)
│   ├── debug.md           # /stp:debug — Systematic debugging (one-shot)
│   ├── progress.md        # /stp:progress — Check project status
│   ├── continue.md        # /stp:continue — Resume where you left off
│   ├── pause.md           # /stp:pause — Save progress, take a break
│   ├── onboard-existing.md # /stp:onboard-existing — Take over existing project
│   └── upgrade.md         # /stp:upgrade — Pull latest from GitHub
├── agents/             # 3 independent Sonnet agents
│   ├── executor.md     # Builder — TDD in isolated worktrees
│   ├── qa.md           # QA tester — tests running app against PRD
│   └── critic.md       # Reviewer — grades code against 7 criteria
├── hooks/              # 10 scripts (5 hook-triggered + 3 utilities + 2 statusline)
│   ├── hooks.json
│   └── scripts/
│       ├── stop-verify.sh      # Quality gate (stack-aware, 3-attempt max)
│       ├── post-edit-check.sh  # Type check after edits (stack-aware)
│       ├── pre-compact-save.sh # State save before compaction
│       ├── session-restore.sh  # State restore on session start
│       ├── migrate-layout.sh   # Auto-migrate old flat layout → organized
│       ├── setup-references.sh # Copy reference files into project
│       ├── start-whiteboard.sh # Launch whiteboard server
│       ├── stp-auto.sh         # Autonomous loop (overnight mode)
│       ├── stp-statusline.js   # Node.js statusline (primary)
│       └── stp-statusline.sh   # Bash statusline (fallback)
├── references/         # Universal production standards (25 files)
│   ├── security/       # OWASP, env handling, auth, validation, API
│   ├── accessibility/  # WCAG AA, keyboard, screen reader, contrast
│   ├── performance/    # Web Vitals, bundles, queries, images
│   └── production/     # Errors, loading, empty states, edge cases, SEO, legal
├── whiteboard/         # Visual whiteboard (live diagrams in browser)
│   ├── index.html      # Dark-theme dashboard with Mermaid rendering
│   └── serve.py        # Lightweight Python server (zero dependencies)
└── templates/          # 18 stack templates + extensibility guide
    ├── nextjs-supabase.md
    ├── python-fastapi.md
    ├── rust-axum.md
    ├── csharp-aspnet.md
    ├── ... (18 total)
    └── TEMPLATE-GUIDE.md
```

### What STP Creates in Your Project

```
your-project/
├── CLAUDE.md                # Standards + patterns (Claude auto-reads from root)
├── VERSION                  # Current version (e.g., 0.1.3)
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
Explore ideas, research approaches, compare options with industry backing. No code — just thinking. Decisions are saved to disk so they survive /clear. Use before /stp:new-project to shape a vague idea, before /stp:quick for complex decisions, or standalone for any technical question.

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
/stp:work update stripe payments and the entire pricing plan
/stp:work add real-time notifications with WebSockets
/stp:work rebuild the auth system with role-based access
```
The command you use when you mean business. Asks you product questions to understand requirements, discovers and installs needed tools (Stripe MCP, CLIs), researches deeply (Context7, Tavily, industry standards), explores approaches, creates a verified plan, then builds with TDD. One command, full cycle. For autopilot: `/stp:autopilot add payment processing` — same flow, AI makes all decisions automatically.

### 3b. Propose work (discuss before building)
```
/stp:research add payment processing
/stp:research refactor the auth system
/stp:research should we migrate to server actions?
```
Full investigation before committing to code. Researches the domain, explores 2-3 approaches with tradeoffs, maps how it fits YOUR codebase (from ARCHITECTURE.md), surfaces risks and what you didn't think of. Saves the plan — `/stp:quick` picks it up when you're ready. No code written.

### 4. Build / Fix / Refactor (TDD)
```
/stp:quick add Stripe payments
/stp:quick fix the 5 critical Sentry errors from AUDIT.md
/stp:quick refactor auth middleware to use centralized pattern
/stp:quick update invoice PDF export to use new template
```
One command for ALL work types. Reads ARCHITECTURE.md first (what exists, what could break). Impact analysis, writes tests FIRST, implements, `/simplify` polishes. Backward integration updates existing features. Auto-Critic + integration tests at milestone boundaries. Teaches you concepts along the way.

### 4. Review quality
```
/stp:review
```
A separate Sonnet AI grades your app against PRD + PLAN + 7 quality criteria with file:line evidence and business impact.

### 5. Run overnight
```
/stp:autopilot
```
Works through the feature checklist unattended. TDD per task. Critic evaluates when done.

### 6. Check progress
```
/stp:progress
```
Shows project version, milestone progress (done/total), active feature status, recent activity, uncommitted work, and the exact next command to run. Read-only — doesn't modify anything.

### 7. Resume work
```
/stp:continue
```
Reads all state files (handoff, feature checklist, plan) and immediately picks up where you left off. No questions — just starts working on the next task. Use after `/clear`, compaction, or starting a new session.

### The full flow
```
/stp:whiteboard        → Shape ideas, research approaches (optional, anytime)
/stp:new-project       → .stp/docs/PRD.md (what we're building)
/stp:plan              → .stp/docs/PLAN.md (how we're building it — verified by Critic)
/stp:work           → Full cycle: understand → tools → research → plan → TDD build (one command)
/stp:research           → Research → approaches → architecture fit → impact → saved plan (stops before building)
/stp:quick             → Executes plan (from /stp:research or its own research) → TDD → milestone auto-eval
/stp:review            → Separate AI grades against PRD + PLAN + 7 criteria
/stp:debug             → Systematic debugging (auto-gather → diagnose → fix → learn)
/stp:progress          → Check what's done, in progress, and next
/stp:continue          → Resume exactly where you left off (after /clear or new session)
/stp:pause             → Save state → /clear → resume next session
/stp:autopilot         → Overnight TDD autonomous with Critic at completion
/stp:onboard-existing  → Take over an existing project → analyze → document → plan
/stp:upgrade           → Pull latest STP version from GitHub
```

### Working on an existing project

```
Day 1:
  /stp:onboard-existing              → Maps everything, writes ARCHITECTURE.md + AUDIT.md
                                        Connects MCP services (Sentry, Stripe, Vercel)
                                        Creates remediation PLAN.md from findings

Day 1+:
  /stp:progress                      → See what's planned, what's next
  /stp:quick fix critical Sentry errors → Reads ARCHITECTURE.md, knows what could break
  /stp:quick add new feature          → Impact analysis against full codebase map
  /stp:quick refactor auth module     → Dependency map shows what depends on it
  /stp:review                        → Refreshes AUDIT.md with latest Sentry/Vercel data

Session breaks:
  /stp:pause                         → Saves context + failed approaches
  (next session)
  /stp:continue                      → Reads handoff, preserves lessons to CHANGELOG, resumes

Everything persisted:
  .stp/docs/ARCHITECTURE.md          → Full codebase map (updated per feature + milestone)
  .stp/docs/AUDIT.md                 → Production health (refreshed by /stp:review)
  .stp/docs/CHANGELOG.md             → Full history + decisions + failed approaches
```

## Quality Enforcement (Hook Gates — Cannot Be Bypassed)

| Gate | What It Blocks | Enforcement |
|------|---------------|-------------|
| Type/compile errors | Code with errors | 100% — hook exit 2 |
| Tests must pass | Failing tests | 100% — hook exit 2 |
| Tests must exist | Source files without any test files | 100% — hook exit 2 |
| No hardcoded secrets | Stripe keys, AWS keys, passwords in source | 100% — hook exit 2 |
| Unchecked items | Stopping with work remaining | 100% — hook exit 2 |
| .stp/docs/PLAN.md missing | Building features without a plan | Warning (non-blocking) |

3-attempt safety valve prevents session bricking if an issue is truly unfixable.

## Documents Generated

| Document | Created By | Updated By | Purpose |
|----------|-----------|------------|---------|
| .stp/docs/ARCHITECTURE.md | /stp:onboard-existing | milestone refresh | Full codebase map (models, routes, components, integrations, dependencies) |
| .stp/docs/AUDIT.md | /stp:onboard-existing | /stp:review | Production health (Sentry errors, deploy status, billing, performance) |
| .stp/docs/PRD.md | /stp:new-project | /stp:quick (decisions log) | What we're building + acceptance criteria |
| .stp/docs/PLAN.md | /stp:plan | /stp:quick (mark [x] + version) | How we're building it (verified blueprint) |
| .stp/docs/CONTEXT.md | /stp:new-project | /stp:quick (incremental), milestone (full refresh) | Concise AI reference (<150 lines, links to ARCHITECTURE.md) |
| .stp/docs/CHANGELOG.md | /stp:new-project | /stp:quick (per feature + milestone) | What happened (versioned history) |
| VERSION | /stp:new-project | /stp:quick (patch bump), milestone (minor bump) | Current version number |
| CLAUDE.md | /stp:new-project | — | Standards + patterns for Claude |

## Design Principles

1. **Opus is the CTO, you are the PM** — All technical decisions are made for you with full justification
2. **Always-on context beats on-demand** — Standards in CLAUDE.md (100% enforcement) over skills (53% per Vercel's research)
3. **Hooks enforce, CLAUDE.md suggests** — Critical quality gates are infrastructure, not instructions
4. **Less is more** — 4 hooks, not 10. Each component justified by research.
5. **Build to delete** — Every component is modular and independently removable
6. **Teach, don't hide** — You learn your own codebase through explanation

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

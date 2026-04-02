# Pilot

**Your CTO in a plugin.**

Makes all technical decisions, explains them with industry backing and honest downsides, builds autonomously, and teaches you your own codebase.

## The Problem

Every existing Claude Code harness was built by expert developers, for expert developers. They assume you know what stack to choose, what security concerns apply, what accessibility requirements exist, and when your code is actually production-ready.

If you're a solo developer who doesn't know what you don't know, those tools add process without adding knowledge.

## How Pilot Works

You describe what you want to build. Pilot makes every technical decision, presents each one with alternatives and honest tradeoffs, surfaces everything you'd miss, and builds it. You make product decisions. Opus handles everything else.

```
YOU: "I want an app where freelancers track invoices"

PILOT:
├── Decides the entire stack (with alternatives + honest downsides)
├── Asks PRODUCT questions only (one at a time, never technical)
├── Surfaces what you didn't think of (auth, security, empty states...)
├── Creates: PRD.md, PLAN.md (verified), CONTEXT.md, CHANGELOG.md
├── Visual whiteboard: live diagrams in your browser (localhost)
├── Impact analysis: checks what existing features each new feature touches
├── TDD: writes tests before code, /simplify polishes after
├── 6 enforcement gates: type check, tests exist, tests pass, no secrets,
│   unchecked items, plan warning — cannot be bypassed
└── Auto-Critic at every milestone (separate Sonnet AI, not self-grading)
```

## Architecture

```
pilot/
├── commands/           # 8 commands
│   ├── whiteboard.md   # /pilot:whiteboard — Explore ideas + research approaches
│   ├── new.md          # /pilot:new — Product discovery + PRD
│   ├── plan.md         # /pilot:plan — Research + Architecture + PLAN.md
│   ├── feature.md      # /pilot:feature — TDD Feature Builder
│   ├── evaluate.md     # /pilot:evaluate — The Critic
│   ├── auto.md         # /pilot:auto — Overnight Autonomous
│   ├── pause.md        # /pilot:pause — Handoff for /clear
│   └── setup.md        # /pilot:setup — Add standards to existing project
├── agents/
│   └── critic.md       # Sonnet evaluator (6 criteria, business impact)
├── hooks/              # 4 hook scripts
│   ├── hooks.json
│   └── scripts/
│       ├── stop-verify.sh      # Quality gate (stack-aware, 3-attempt max)
│       ├── post-edit-check.sh  # Type check after edits (stack-aware)
│       ├── pre-compact-save.sh # State save before compaction
│       └── session-restore.sh  # State restore on session start
├── references/         # Universal production standards (19 files)
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
/pilot:whiteboard I have an idea for a fitness tracking app
/pilot:whiteboard should we use WebSockets or SSE for real-time?
/pilot:whiteboard this payment feature is complex, what's the best approach?
```
Explore ideas, research approaches, compare options with industry backing. No code — just thinking. Decisions are saved to disk so they survive /clear. Use before /pilot:new to shape a vague idea, before /pilot:feature for complex decisions, or standalone for any technical question.

### 1. Start a new project
```
/pilot:new an app where freelancers track invoices and expenses
```
Opus asks product questions (one at a time), proposes the full stack with alternatives and honest downsides, surfaces what you'd miss. Creates **PRD.md** (with acceptance criteria), **CONTEXT.md** (codebase map), **CHANGELOG.md**, **VERSION**, CI pipeline, and scaffolds the foundation.

### 2. Plan the architecture
```
/pilot:plan
```
Researches the domain, designs system architecture, data models, API routes, auth model, error strategy, Feature Touchpoint Map (where each feature appears across the app). Visual whiteboard renders diagrams live. Critic verifies the plan. Writes **PLAN.md**. No code — just the verified blueprint.

### 3. Build features (TDD)
```
/pilot:feature database setup and user model
```
Impact analysis first (what existing features does this touch?). Writes tests FIRST. Implements to make tests pass. `/simplify` polishes code. Checkpoints every 3 items. Backward integration updates existing features. Auto-Critic + integration tests at milestone boundaries. Teaches you concepts along the way.

### 4. Evaluate quality
```
/pilot:evaluate
```
A separate Sonnet AI grades your app against PRD + PLAN + 6 quality criteria with file:line evidence and business impact.

### 5. Run overnight
```
/pilot:auto
```
Works through the feature checklist unattended. TDD per task. Critic evaluates when done.

### The full flow
```
/pilot:whiteboard → Shape ideas, research approaches (optional, anytime)
/pilot:new        → PRD.md (what we're building)
/pilot:plan       → PLAN.md (how we're building it — verified by Critic)
/pilot:feature    → TDD → /simplify → checkpoint → milestone auto-eval
/pilot:evaluate   → Separate AI grades against PRD + PLAN + 6 criteria
/pilot:pause      → Save state → /clear → resume next session
/pilot:auto       → Overnight TDD autonomous with Critic at completion
```

## Quality Enforcement (Hook Gates — Cannot Be Bypassed)

| Gate | What It Blocks | Enforcement |
|------|---------------|-------------|
| Type/compile errors | Code with errors | 100% — hook exit 2 |
| Tests must pass | Failing tests | 100% — hook exit 2 |
| Tests must exist | Source files without any test files | 100% — hook exit 2 |
| No hardcoded secrets | Stripe keys, AWS keys, passwords in source | 100% — hook exit 2 |
| Unchecked items | Stopping with work remaining | 100% — hook exit 2 |
| PLAN.md missing | Building features without a plan | Warning (non-blocking) |

3-attempt safety valve prevents session bricking if an issue is truly unfixable.

## Documents Generated

| Document | Created By | Updated By | Purpose |
|----------|-----------|------------|---------|
| PRD.md | /pilot:new | /pilot:feature (decisions log) | What we're building + acceptance criteria |
| PLAN.md | /pilot:plan | /pilot:feature (mark [x] + version) | How we're building it (verified blueprint) |
| CONTEXT.md | /pilot:new | /pilot:feature (incremental), milestone (full refresh) | What exists RIGHT NOW (codebase map) |
| CHANGELOG.md | /pilot:new | /pilot:feature (per feature + milestone) | What happened (versioned history) |
| VERSION | /pilot:new | /pilot:feature (patch bump), milestone (minor bump) | Current version number |
| CLAUDE.md | /pilot:new | — | Standards + patterns for Claude |

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

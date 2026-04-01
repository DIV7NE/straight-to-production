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
├── Decides the entire stack (with justification)
├── Asks 2-3 PRODUCT questions (not technical ones)
├── Surfaces what you didn't think of (auth, security, empty states...)
├── Generates CLAUDE.md with embedded standards
├── Builds with quality hooks enforcing every edit
└── Evaluates with a separate Critic AI when you're done
```

## Architecture

```
pilot/
├── commands/           # 6 commands
│   ├── new.md          # /pilot:new — The CTO Onboarding
│   ├── feature.md      # /pilot:feature — Autonomous Feature Builder
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
├── references/         # Universal production standards
│   ├── security/       # OWASP, env handling, auth, validation, API
│   ├── accessibility/  # WCAG AA, keyboard, screen reader, contrast
│   ├── performance/    # Web Vitals, bundles, queries, images
│   └── production/     # Errors, loading, empty states, edge cases, SEO
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

### Start a new project
```
/pilot:new an app where freelancers track invoices and expenses
```
Pilot asks product questions, proposes the full stack with alternatives and honest downsides, surfaces what you'd miss, and builds the foundation.

### Build features
```
/pilot:feature add Stripe payments
```
Builds autonomously. Only asks product questions. Teaches you key concepts along the way.

### Evaluate quality
```
/pilot:evaluate
```
A separate Sonnet AI grades your app against 6 criteria with file:line evidence and business impact explanations.

### Run overnight
```
/pilot:auto
```
Works through the feature checklist unattended. Each task gets a fresh context. Critic evaluates when done.

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

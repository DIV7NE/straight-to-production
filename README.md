# Pilot

**Production-quality app builder for solo developers.**

Surfaces what you don't know. Enforces what you'd forget. Evaluates what you can't judge.

## The Problem

Every existing Claude Code harness (GSD, Superpowers, ECC) was built by expert developers, for expert developers. They assume you know what stack to choose, what security concerns apply, what accessibility requirements exist, and when your code is actually production-ready.

If you're a solo developer who doesn't know what you don't know, those tools add process without adding knowledge.

## How Pilot Is Different

Pilot doesn't add orchestration complexity. It adds **knowledge complexity**.

- **Standards as always-on context** — Security, accessibility, performance, and production-readiness standards are embedded in your project's CLAUDE.md as a compressed index (following [Vercel's AGENTS.md research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) showing 100% enforcement vs 53% for on-demand skills)
- **Commands, not auto-triggers** — The Guide (`/pilot:new`) and Critic (`/pilot:evaluate`) are explicitly invoked. No 56% miss rate from unreliable auto-invocation.
- **Hooks for non-negotiable enforcement** — TypeScript checks after every edit, verification prompts before completion claims, state preservation before compaction. These bypass the model's decision-making entirely.
- **The Critic** — A separate Sonnet subagent (200K context) that evaluates your running app against 6 concrete criteria: functionality, design quality, security, accessibility, performance, and production-readiness. Inspired by [Anthropic's GAN-based evaluator research](https://www.anthropic.com/engineering/harness-design-long-running-apps).

## Architecture

```
pilot/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/
│   ├── new.md              # /pilot:new — The Guide
│   ├── evaluate.md         # /pilot:evaluate — The Critic
│   └── standards.md        # /pilot:standards — What's enforced
├── agents/
│   └── critic.md           # Sonnet subagent for quality evaluation
├── hooks/
│   ├── hooks.json          # PostToolUse, Stop, PreCompact
│   └── scripts/
│       └── post-edit-typecheck.sh
├── references/             # The knowledge (copied to each project)
│   ├── security/           # OWASP, env handling, auth, input validation, API security
│   ├── accessibility/      # WCAG AA, keyboard nav, screen reader, contrast
│   ├── performance/        # Core Web Vitals, bundles, waterfalls, images
│   └── production/         # Error handling, loading states, empty states, edge cases, SEO
└── templates/
    ├── standards-index.md          # Compressed index for CLAUDE.md
    └── nextjs-supabase-clerk.md    # Stack recipe
```

## Installation

```bash
# Add the marketplace
/plugin marketplace add /path/to/pilot

# Install the plugin
/plugin install pilot@pilot-dev
```

## Usage

### Start a new project
```
/pilot:new a SaaS app for freelancers to track invoices and expenses
```
The Guide asks 3-5 targeted questions, surfaces everything you'd miss, and generates a CLAUDE.md with embedded standards.

### Build your app
Just describe features naturally. The standards index in CLAUDE.md ensures every session applies security, accessibility, and performance patterns. Hooks catch TypeScript errors after every edit.

### Evaluate when ready
```
/pilot:evaluate
```
The Critic grades your app against 6 criteria and returns a priority-ordered fix list.

### Check what's enforced
```
/pilot:standards
/pilot:standards security
```

## Design Principles

1. **Knowledge, not process** — The model is smart enough to build. It just needs to know what "production-ready" means.
2. **Always-on beats on-demand** — Compressed standards index in CLAUDE.md (100% enforcement) over skills (53% auto-trigger rate).
3. **Commands over auto-triggers** — User-invoked workflows are reliable. Agent-decided invocation has a 56% miss rate.
4. **Hooks over instructions** — Infrastructure that validates is more reliable than instructions the model might ignore.
5. **Designed for 1M Opus + 200K Sonnet** — Main session runs on Opus with full context. Critic subagent runs on Sonnet within 200K.

## Model Requirements

- **Main session**: Claude Opus 4.6 (1M context recommended)
- **Critic subagent**: Claude Sonnet 4.6 (200K context)
- **Exploration**: Claude Haiku (for lightweight lookups)

## Research Behind This

- [Anthropic: Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — The 3-agent architecture and GAN-inspired evaluator
- [Vercel: AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) — Why always-on context beats on-demand retrieval
- [Claude Code source leak analysis](https://layer5.io/blog/engineering/the-claude-code-source-leak-512000-lines-a-missing-npmignore-and-the-fastest-growing-repo-in-github-history) — 29-30% false claims rate, compaction behavior, 5-layer context management
- Community consensus from r/ClaudeCode, HN, and the claude-code-best-practice repo

## License

MIT

# STP v0.2.0 — Research Sources & Key Findings

All research that shaped this plugin's design. Read this to understand WHY every decision was made.

## Primary Research (Verified)

### Anthropic: Harness Design for Long-Running Apps (Mar 2026)
- URL: https://www.anthropic.com/engineering/harness-design-long-running-apps
- Author: Prithvi Rajasekaran
- Key findings:
  - "Every component encodes an assumption about what the model can't do" — stress test each one
  - Sprint constructs dropped with Opus 4.6 — model handles coherence natively
  - Evaluator valuable "at the edge" of model capability, unnecessary for tasks within capability
  - Radical simplification failed; methodical ablation (one piece at a time) worked
  - Planner remained load-bearing even on Opus 4.6 (generator under-scoped without it)
  - Opus 4.5 "largely removed" context anxiety

### Vercel: AGENTS.md Outperforms Skills (Jan 2026)
- URL: https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals
- Author: Jude Gao
- Key findings:
  - AGENTS.md: 100% pass rate. Skills (default): 53%. Skills (explicit trigger): 79%
  - Skills never invoked in 56% of cases — agent chose not to use them
  - Unused skills degraded quality BELOW baseline (58% vs 63% on tests)
  - 40KB → 8KB compressed index with zero performance loss
  - "Prefer retrieval-led reasoning over pre-training" directive was essential

### Phil Schmid: Build to Delete (Jan 2026)
- URL: https://www.philschmid.de/agent-harness-2026
- Three principles: Start Simple, Build to Delete, The Harness is the Dataset

### Meta-Harness (Stanford/MIT, Mar 2026)
- URL: https://arxiv.org/abs/2603.28052
- Auto-evolved harnesses beat hand-engineered: 76.4% vs 74.7% on TerminalBench-2

### Builder.io: 50 Claude Code Tips
- URL: https://www.builder.io/blog/claude-code-tips-best-practices
- "CLAUDE.md is advisory (~80% compliance). Hooks are deterministic (100%)"
- 150-200 instruction budget before compliance drops

## Model Specifications (Verified from Anthropic Docs)

| Model | Context | Cost (in/out) | Training Cutoff | SWE-bench |
|-------|---------|---------------|----------------|-----------|
| Opus 4.6 | 1M | $5/$25 per MTok | Aug 2025 | 80.8% |
| Sonnet 4.6 | 200K (1M on API) | $3/$15 per MTok | Jan 2026 | 79.6% |

- Context awareness NOT on Opus 4.6 (only Sonnet/Haiku)
- Adaptive thinking: max effort is Opus-only
- Fast mode: 6x pricing ($30/$150)
- Sonnet has NEWER training data than Opus

## Security Research

### AI Code Vulnerabilities
- 45% of AI code contains security vulnerabilities (Veracode 2026)
- Security pass rates flat at ~55% since 2023
- Slopsquatting: attackers register AI-hallucinated package names with malware
- OX Security 10 anti-patterns: comments everywhere (90-100%), happy-path only (60-70%), fake tests (40-50%)

### GitHub Issues (Verified)
- #38422: Exit code 2 displays as "Error" — model stops instead of adjusting
- #35086: No UI distinction between blocking/failure/informational hooks
- #24327: PreToolUse exit code 2 causes stop instead of adjustment
- #40705: Model identity mismatch — Opus 4.6 loads Opus 4.5

## Community Consensus (45+ Sources)

- "Start minimal, add complexity only when justified"
- CLAUDE.md < 200 lines (ideally ~60) + hooks for enforcement
- GSD: "1000% better" but token-heavy (30K LOC, 57 commands)
- Superpowers: structured but blocking questions, token burn (17K LOC, 46 skills)
- Token tax: 32.9K baseline before typing (Jamie Ferguson measurement)
- Pi agent: 4 tools, minimal system prompt, viable for daily coding
- "One Task, One Chat" golden rule
- Opus 4.6 1M: accurate to ~400K, fuzzy above 600K

## Design Decisions (Why Pilot Works This Way)

1. **Opus plans, Sonnet builds** — 1.2 point SWE-bench gap, 40% cheaper
2. **Always-on context > skills** — 100% vs 53% (Vercel)
3. **Hooks > CLAUDE.md** — 100% vs 80% (Builder.io)
4. **4 hook gates** — removed 6 dead-weight hooks per Anthropic's ablation guidance
5. **3 independent agents** — builder shouldn't QA own work, QA shouldn't review own code
6. **AskUserQuestion everywhere** — multiple choice > freetext for beginners
7. **8-part research before building** — 45% vulnerability rate demands it
8. **Wave parallelism** — dependency graph from PLAN.md, not arbitrary limits
9. **Agent Teams for waves** — coordinated parallel building with worktree isolation
10. **Foundation stays with Opus** — DB, auth, config too critical for subagents

## Sources Index

- Anthropic harness blog: https://www.anthropic.com/engineering/harness-design-long-running-apps
- Vercel AGENTS.md: https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals
- Phil Schmid: https://www.philschmid.de/agent-harness-2026
- Meta-Harness: https://arxiv.org/abs/2603.28052
- Builder.io tips: https://www.builder.io/blog/claude-code-tips-best-practices
- Anthropic docs: https://docs.anthropic.com/en/docs/about-claude/models/overview
- Opus 4.6 announcement: https://anthropic.com/news/claude-opus-4-6
- shanraisshan best practices: https://github.com/shanraisshan/claude-code-best-practice
- Pi agent: https://lucumr.pocoo.org/2026/1/31/pi/
- OX Security: https://ox.security (AI coding anti-patterns report)
- Veracode 2026 AI code study
- OWASP Top 10 2025
- CWE Top 25 2025

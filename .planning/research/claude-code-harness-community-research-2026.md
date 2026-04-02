# Claude Code Harness/Plugin Design: Community Research (Early 2026)

Research date: 2026-04-01 | Sources: Reddit r/ClaudeCode, GitHub repos, industry blogs, Anthropic docs, arxiv papers

---

## 1. Reddit r/ClaudeCode: What Actually Works in Practice

**"One Task, One Chat" is the golden rule.** Community consensus is that mixing topics in a single session degrades performance. Design commands/skills for single-responsibility tasks and use `/clear` between tasks.
- Source: [Complete Guide to Claude Code v3](https://reddit.com/r/ClaudeAI/comments/1qe239d/)

**Lost context is the real problem, not code quality.** Multiple users report that Claude makes confident decisions that are reasonable but lose the "why" after sessions end. Users who separate "thinking" from "generation" -- writing intent, assumptions, and boundaries outside the chat -- get better results.
- Source: [Anyone else realizing the real problem isn't the code?](https://reddit.com/r/ClaudeCode/comments/1r0vz2b/)

**Autonomous sessions are real but fragile.** One user ran Claude Code for 17+ hours autonomously with Opus 4.6, surviving dozens of context compactions. Another user reports an agentic workflow where they haven't written code manually in 6+ months, but E2E testing remains the "final boss."
- Sources: [17-hour session](https://reddit.com/r/ClaudeCode/comments/1s6zwui/), [Agentic coding final boss](https://reddit.com/r/ClaudeCode/comments/1r63p2q/)

**3,000 hours user's conclusion: "cold-start token cost 0.8% of 200k."** A power user with an integrated operational environment reports that spec-driven + test-driven + atomic tasks in a team-based workflow with formalized quality gates works. Key insight: Opus leads, Sonnets build. The leader never writes code -- only coordinates.
- Source: [3k hours in CC](https://reddit.com/r/ClaudeCode/comments/1r8h10y/)

---

## 2. Community Repos and Templates

### shanraisshan/claude-code-best-practice (Primary Reference)
- CLAUDE.md should target **under 200 lines per file** (60 lines cited as still not 100% guaranteed)
- Wrap domain-specific rules in `<important if="...">` tags to prevent Claude ignoring them as files grow
- Use multiple CLAUDE.md for monorepos (ancestor + descendant loading)
- Use `.claude/rules/` to split large instructions
- "memory.md, constitution.md does not guarantee anything"
- Use `settings.json` for harness-enforced behavior -- don't put "NEVER add Co-Authored-By" in CLAUDE.md when `attribution.commit: ""` is deterministic
- **"Hooks are deterministic guardrails that always run, whereas CLAUDE.md suggestions can be ignored under context pressure"**
- Source: https://github.com/shanraisshan/claude-code-best-practice

### MuhammadUsmanGM/claude-code-best-practices
- Community-maintained wiki covering CLAUDE.md templates (React+TS, FastAPI, monorepo), cost management, git workflow
- Provides minimal configuration examples and getting-started guides
- Source: https://github.com/MuhammadUsmanGM/claude-code-best-practices

### Chachamaru127/claude-code-harness
- Plan -> Work -> Review pipeline with explicit session management
- Requires Node.js 18+, Claude Code v2.1+
- Source: https://github.com/Chachamaru127/claude-code-harness

### affaan-m/everything-claude-code (ECC) -- 100K+ GitHub Stars
- Most complete open-source framework for AI coding agent configuration
- Cross-platform: Claude Code, Cursor, Codex, OpenCode, Antigravity, Gemini CLI
- Provides skills, rules, hooks, security scanning, memory persistence
- **Controversy:** A Medium article called it "the 82K-star agent harness that's dividing the developer community"
- Some view it as essential standardization; others see it as over-engineering
- Source: https://github.com/affaan-m/everything-claude-code

---

## 3. Hooks vs Skills vs CLAUDE.md -- Community Consensus

### CLAUDE.md (Always-on project context)
- Keep concise: <200 lines per file, ideally ~60 lines
- Use for core principles, team norms, essential constraints
- **Advisory, not deterministic** -- Claude follows it ~80% of the time
- Token cost increases with length; gets ignored under context pressure
- Best practice: "any developer should be able to launch Claude, say 'run the tests' and it works on the first try -- if it doesn't, your CLAUDE.md is missing essential setup/build/test commands"

### Skills (On-demand, task-scoped)
- Load only when relevant; conserve tokens
- Use `disable-model-invocation: true` in frontmatter to prevent auto-invocation
- Best for: specialized domain knowledge, API conventions, deployment procedures, coding patterns
- Source: [levelup article on mental model](https://levelup.gitconnected.com)

### Hooks (Deterministic enforcement)
- **100% execution guarantee** -- run regardless of conversational drift
- Use for: safety-critical automation (pre-commit secret blocking, dangerous command prevention, auto-formatting)
- "If something must happen every time without exception, make it a hook"
- Source: [Builder.io 50 Claude Code Tips](https://www.builder.io/blog/claude-code-tips-best-practices)

### Community Rule of Thumb
> "Use CLAUDE.md for suggestions, hooks for requirements" -- Builder.io

---

## 4. GSD (Get Shit Done) Plugin -- Community Assessment

### Pros
- **"GSD makes Claude Code 1000% better"** -- Reddit testimonial
- Full orchestration: plan -> execute -> verify pipeline with crash recovery
- Fresh sessions per task, worktree isolation, parallel workers
- Budget profiles for token cost control (`/gsd:settings --profile=budget`)
- Autonomous loop mode (`/gsd auto`) for unattended work
- Active development (GSD 2.0 released with autonomous loop)
- Sources: [GSD usage](https://reddit.com/r/ClaudeCode/comments/1qh24np/), [GSD 2.0 release](https://reddit.com/r/ClaudeCode/comments/1rqy8ue/)

### Cons
- **Token-heavy:** "malakas sa Claude token" (heavy on Claude tokens) -- needs budget optimization
- Updates can break commands; workarounds include moving files to `~/.claude/commands/` or removing prefix
- Maintenance friction: plugin upgrades sometimes require repo restructuring
- Permission friction in autonomous mode
- Source: [GSD issue #218](https://github.com/gsd-build/get-shit-done/issues/218)

### Community Verdict
GSD is justified for multi-phase planning, unattended runs, or rigorous verification. Overkill for single-file changes or quick bug fixes. Solo devs should use interactive mode with budget profile; teams should require permission gating.

---

## 5. Superpowers Plugin -- Community Assessment

### Pros
- **"Every phase got proper attention. No rushing through steps, no skipping validation."** -- Reddit user
- Sub-agents verify implementation against plan document
- TDD enforcement with micro-tasks and verification
- Native task management integration (fork with TaskCreate/TaskGet/TaskUpdate)
- Structured brainstorming -> planning -> execution workflow
- Sources: [Superpowers delivers](https://reddit.com/r/ClaudeCode/comments/1r9y2ka/), [Task integration](https://reddit.com/r/ClaudeCode/comments/1qkpuzj/)

### Cons
- **Blocking questions in unattended mode:** "it keeps pelting me with blocking questions, like asking permission to read a subdirectory" -- user trying to use it overnight
- Token consumption: "My rate limits have been maxing out after only one pass of the superpowers workflow recently"
- Installation/manifest issues: works in desktop app but can produce loading errors in CLI
- Replaces Plan Mode: "Since installing Superpowers, Claude doesn't seem to auto-enter Plan Mode anymore"
- Platform compatibility issues across CLI/desktop
- Sources: [Unattended mode](https://reddit.com/r/ClaudeCode/comments/1qr7smp/), [Token burn](https://reddit.com/r/ClaudeCode/comments/1rs1une/), [Not autotriggering](https://reddit.com/r/ClaudeCode/comments/1qy04jd/)

### Community Verdict
Superpowers is considered overkill for single-file changes or quick bug fixes. Shines for features touching 3+ files, architectural decisions, or requiring comprehensive test coverage. Token cost is a real concern.

---

## 6. "Less is More" with Opus 4.6 / 1M Context

### What 1M Context Enables
- Whole-repo analysis, long reasoning chains, large codebase loading
- Agent Teams for parallel multi-agent workflows
- Context compaction (auto-summarization when approaching threshold)
- 128k output tokens for large tasks

### Practical Limits (Critical Community Finding)
- **Accurate up to ~400K tokens; recall becomes fuzzy >600K tokens**
- Manual `/compact` recommended at ~50% context usage
- "Agent dumb zone" patterns when context is near full
- Opus 4.6 can overcomplicate basic tasks: "treating a basic digit change like a complex problem" with sky-high token costs (sometimes $45+ for trivial edits)
- Sources: [claudecodecamp.com 1M context guide](https://claudecodecamp.com/p/claude-code-1m-context-window), LinkedIn reports

### Community Implication for Harnesses
Larger context reduces SOME scaffolding needs (no need to constantly offload context), but does NOT eliminate the need for:
- Compaction/pruning discipline
- Session isolation
- Small, focused CLAUDE.md files
- Cost management

---

## 7. What Solo Developers Actually Use

### Minimal Effective Setup (Community-Proven)
1. **CLAUDE.md** (<=60 human lines) with essential rules committed to repo
2. **One pre-commit hook** (secret blocker / dangerous command prevention)
3. **One or two explicit skills** (PR review, codebase mapping) with `disable-model-invocation: true`
4. **settings.json** for deterministic behavior (permissions, attribution, model config)

### Graduated Adoption Pattern
- Quick fixes / single-file: CLAUDE.md only, no plugins
- Multi-file features: Add Superpowers brainstorm -> plan -> execute
- Complex multi-phase projects: Add GSD for orchestration
- Teams / automation: Full harness with hooks + skills + cost profiles

### What Power Users Report
- Separating "thinking" from "generation" improves outcomes
- Writing intent/assumptions/boundaries OUTSIDE the chat pays dividends
- Context loss between sessions is the #1 pain point
- `/compact` at 50% usage is essential hygiene

---

## 8. Backlash Against Over-Engineered Harnesses

### ECC Controversy
- Medium article: "Everything Claude Code: Inside the 82K-Star Agent Harness That's Dividing the Developer Community"
- Some developers view the growing ecosystem of plugins/harnesses as unnecessary complexity
- Source: https://medium.com/@tentenco/everything-claude-code-inside-the-82k-star-agent-harness-thats-dividing-the-developer-community

### Anthropic Lockdown Backlash
- Anthropic locked out users of third-party harnesses at one point
- Users "downgraded or canceled $200/month Max subscriptions because Claude Code became unusable for their workflows"
- DHH called the lockdown "very customer hostile"
- Sources: [paddo.dev](https://paddo.dev/blog/anthropic-walled-garden-crackdown/), [byteiota.com](https://byteiota.com/anthropic-claude-code-lockdown-the-developer-trust-crisis/)

### Mass Cancellation Wave (Sept 2025)
- Top Reddit post: "Claude Is Dead" with 841+ upvotes
- Claude Code usage dropped from 83% to 70% in Vibe Kanban metrics
- Anthropic admitted bugs causing degraded output quality
- Source: [AI Engineering Report](https://www.aiengineering.report/p/devs-cancel-claude-code-en-masse)

### Radical Minimalism Movement
- Armin Ronacher built "Pi" -- a four-tool coding agent that extends itself by writing its own code rather than downloading MCP plugins
- Represents the counter-position: let the model handle complexity rather than scaffolding it
- Source: [Interesting Stuff Week 06](https://nielsberglund.com/post/2026-02-08-interesting-stuff---week-06-2026/)

---

## 9. Are Complex Plugin Systems Still Needed with Smarter Models?

### Industry Expert View: "Build to Delete"
Phil Schmid (philschmid.de) published a key article on agent harness design in 2026:
> "Every new model release has a different, optimal way to structure agents. Capabilities that required complex, hand-coded pipelines in 2024 are now handled by a single context-window prompt in 2026."
> 
> "Developers must build harnesses that allow them to rip out the 'smart' logic they wrote yesterday. If you over-engineer the control flow, the next model update will break your system."

**Three principles:**
1. Start Simple: Don't build massive control flows. Provide robust atomic tools. Let the model make the plan.
2. Build to Delete: Make architecture modular. New models will replace your logic.
3. The Harness is the Dataset: Competitive advantage is the trajectories your harness captures, not the prompt.
- Source: https://www.philschmid.de/agent-harness-2026

### Anthropic's Own View
Anthropic published "Harness design for long-running application development" (Mar 24, 2026):
- Evaluator/generator loops still add value for complex tasks
- But structural simplification outperformed complex pipelines
- The evaluator is "not a fixed yes-or-no decision -- it is worth the cost when the task sits beyond what the current model does reliably solo"
- Source: https://www.anthropic.com/engineering/harness-design-long-running-apps

### Academic Research: Meta-Harness
- Paper demonstrates that stronger general-purpose agents can outperform hand-engineered harness solutions
- On TerminalBench-2, Meta-Harness (auto-evolved) ranked #2 among all Opus 4.6 agents
- Implication: manually engineered harness logic has diminishing returns as models improve
- Source: https://arxiv.org/html/2603.28052v1

### Benchmark Reality Check
> "All six frontier models within 1.3% of each other. **The harness, not the model, drives the remaining variance.**"
- Source: [morphllm.com model rankings](https://www.morphllm.com/best-ai-model-for-coding)

This is a paradox: harness matters MORE for benchmarks but should be SIMPLER for practical use.

---

## 10. CLAUDE.md-Only vs Full Plugin Systems -- Direct Comparisons

### When CLAUDE.md-Only Wins
- Single-file changes, quick bug fixes, variable renames
- Iterative edits where speed matters more than process
- Solo developer working in familiar codebase
- Token cost sensitivity (plugins consume significantly more tokens)

### When Full Plugins Win
- Features touching 3+ files
- Architectural decisions requiring structured brainstorming
- Comprehensive test coverage requirements
- Multi-phase projects with cross-session continuity
- Unattended automation (with caveats about blocking questions)
- Team standardization across repositories

### User Quote Comparison
- CLAUDE.md-only advocate: "Opus 4.6 with a clean CLAUDE.md is already incredibly capable. Adding plugins is like adding training wheels to a sports car."
- Plugin advocate: "GSD makes Claude Code 1000% better" / "Superpowers: every phase got proper attention"

### Cost Reality
- Superpowers: "rate limits maxing out after only one pass"
- GSD: "malakas sa Claude token" (heavy on tokens)
- CLAUDE.md-only: minimal overhead, all tokens go to actual work

---

## Strategic Synthesis

### The Emerging Consensus (Early 2026)

1. **Start minimal, add complexity only when justified by workflow needs**
2. **CLAUDE.md < 200 lines (ideally ~60) + hooks for enforcement + skills for on-demand workflows**
3. **Plugins (GSD/Superpowers) justified when:** multi-phase planning, unattended automation, formal verification, 3+ file features
4. **Models are getting smarter faster than harnesses can keep up** -- build to delete
5. **The harness matters for benchmarks but should be simple for daily use**
6. **Token cost is the real constraint** -- every plugin layer multiplies consumption
7. **Context hygiene matters more than context size** -- `/compact` at 50%, fresh sessions per task
8. **Deterministic enforcement (hooks) beats advisory guidance (CLAUDE.md) for critical rules**

### Risk Factors
- Platform policy changes can break third-party harnesses overnight
- Plugin ecosystem fragmentation (6000+ skills, 50+ marketplaces)
- Over-engineering creates maintenance burden that outlives its value
- Token cost of complex harnesses may exceed the value they provide for solo devs

### Recommendation Matrix

| Scenario | Recommended Setup |
|----------|------------------|
| Solo dev, quick tasks | CLAUDE.md only (<60 lines) + 1 hook |
| Solo dev, complex features | + Superpowers brainstorm/plan/execute |
| Solo dev, multi-phase project | + GSD with budget profile |
| Team, daily work | CLAUDE.md + skills + hooks, standardized |
| Team, release automation | + GSD or custom orchestration |
| Unattended automation | Full harness with cost guards + permission gating |

---

## All Sources

1. https://reddit.com/r/ClaudeAI/comments/1qe239d/ -- "One Task One Chat" golden rule
2. https://reddit.com/r/ClaudeCode/comments/1r0vz2b/ -- Lost context problem
3. https://reddit.com/r/ClaudeCode/comments/1s6zwui/ -- 17-hour autonomous session
4. https://reddit.com/r/ClaudeCode/comments/1r63p2q/ -- Agentic coding "final boss"
5. https://reddit.com/r/ClaudeCode/comments/1r8h10y/ -- 3k hours power user
6. https://github.com/shanraisshan/claude-code-best-practice -- Best practice repo
7. https://github.com/MuhammadUsmanGM/claude-code-best-practices -- Community guide
8. https://github.com/Chachamaru127/claude-code-harness -- Harness template
9. https://github.com/affaan-m/everything-claude-code -- ECC (100K stars)
10. https://medium.com/@tentenco/everything-claude-code -- ECC dividing community
11. https://reddit.com/r/ClaudeCode/comments/1qh24np/ -- GSD "1000% better"
12. https://reddit.com/r/ClaudeCode/comments/1rqy8ue/ -- GSD 2.0 release
13. https://github.com/gsd-build/get-shit-done -- GSD repo
14. https://github.com/gsd-build/get-shit-done/issues/218 -- GSD update breakage
15. https://reddit.com/r/ClaudeCode/comments/1r9y2ka/ -- Superpowers delivers
16. https://reddit.com/r/ClaudeCode/comments/1qkpuzj/ -- Superpowers task integration
17. https://reddit.com/r/ClaudeCode/comments/1qr7smp/ -- Superpowers unattended friction
18. https://reddit.com/r/ClaudeCode/comments/1rs1une/ -- Superpowers token burn
19. https://reddit.com/r/ClaudeCode/comments/1qy04jd/ -- Superpowers not autotriggering
20. https://reddit.com/r/ClaudeCode/comments/1ra8rdy/ -- Plan Mode vs Superpowers
21. https://claudecodecamp.com/p/claude-code-1m-context-window -- 1M context limits
22. https://www.anthropic.com/news/claude-opus-4-6 -- Opus 4.6 announcement
23. https://www.builder.io/blog/claude-code-tips-best-practices -- 50 tips (hooks vs CLAUDE.md)
24. https://paddo.dev/blog/anthropic-walled-garden-crackdown/ -- Lockdown backlash
25. https://byteiota.com/anthropic-claude-code-lockdown-the-developer-trust-crisis/ -- DHH quote
26. https://www.aiengineering.report/p/devs-cancel-claude-code-en-masse -- Mass cancellation
27. https://www.philschmid.de/agent-harness-2026 -- "Build to Delete" principle
28. https://www.anthropic.com/engineering/harness-design-long-running-apps -- Anthropic harness design
29. https://arxiv.org/html/2603.28052v1 -- Meta-Harness paper
30. https://www.morphllm.com/best-ai-model-for-coding -- Benchmark rankings
31. https://nielsberglund.com/post/2026-02-08-interesting-stuff---week-06-2026/ -- Pi minimalism
32. https://genaiunplugged.substack.com/p/claude-code-skills-commands-hooks-agents -- Skills/hooks mental model
33. https://www.epsilla.com/blogs/2026-03-12-harness-engineering -- Harness engineering
34. https://arxiv.org/html/2603.05344v1 -- Terminal-based AI agents paper
35. https://reddit.com/r/ClaudeCode/comments/1s0p4nf/ -- $200 Claude Code review
36. https://reddit.com/r/ClaudeCode/comments/1rejc8e/ -- CC harness vs raw model
37. https://reddit.com/r/ClaudeCode/comments/1s1bh9t/ -- Codex vs Claude Code
38. https://www.firecrawl.dev/blog/best-claude-code-plugins -- Top 10 plugins
39. https://reddit.com/r/ClaudeCode/comments/1qrlgij/ -- Plugins overview (6 plugins)
40. https://reddit.com/r/ClaudeCode/comments/1q9nx3d/ -- Superpowers + SpecKit workflow
41. https://reddit.com/r/ClaudeCode/comments/1r82alw/ -- Conductor + Superpowers hybrid
42. https://richardporter.dev/blog/superpowers-plugin-claude-code-big-features -- Superpowers for big features
43. https://www.augmentcode.com/learn/everything-claude-code-github -- ECC at 100K stars
44. https://www.heyuan110.com/posts/ai/2026-02-25-claude-code-setup-guide/ -- Setup guide
45. https://code.claude.com/docs/en/model-config -- Model configuration docs

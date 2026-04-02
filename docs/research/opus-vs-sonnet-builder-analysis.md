# Opus vs Sonnet as Builder: Research Analysis

**Date:** 2026-04-02
**Question:** Should Opus 4.6 plan and Sonnet 4.6 build? Or should Opus do everything?
**Current setup:** Opus 4.6 (1M) interactive. Sonnet 4.6 (200K) for Critic/overnight only.

---

## 1. SWE-bench Comparison

| Benchmark | Sonnet 4.6 | Opus 4.6 | Gap | Winner |
|---|---|---|---|---|
| SWE-bench Verified | 79.6% | 80.8% | 1.2 pts | Opus (barely) |
| OSWorld-Verified (computer use) | 72.5% | 72.7% | 0.2 pts | Tied |
| Terminal-Bench 2.0 | 59.1% | 65.4% | 6.3 pts | Opus |
| GDPval-AA (office tasks, Elo) | 1633 | 1606 | +27 Sonnet | **Sonnet** |
| Finance Agent v1.1 | 63.3% | 60.1% | +3.2 Sonnet | **Sonnet** |
| GPQA Diamond (expert science) | 89.9% | 91.3% | 1.4 pts | Opus |
| BrowseComp (agentic search) | 74.7% | 84.0% | 9.3 pts | Opus |
| ARC-AGI-2 (novel reasoning) | 58.3% | 68.8% | 10.5 pts | Opus |
| SRE-skills-bench | 90.4% | 94.7% | 4.3 pts | Opus |

**Key insight:** For standard coding (SWE-bench), the gap is 1.2 points -- noise level. For production workloads (office tasks, coding, computer use, finance), Sonnet matches or beats Opus. The gap only opens on frontier tasks: deep search (+9.3), novel reasoning (+10.5), terminal-based multi-step debugging (+6.3).

**Source:** Anthropic announcements, SWE-bench leaderboard, Rootly SRE-skills-bench, r/mlops analysis.

---

## 2. Token Cost Comparison

### API Pricing (Feb 2026)

| Model | Input (<=200K) | Output (<=200K) |
|---|---|---|
| Opus 4.6 | $5/MTok | $25/MTok |
| Sonnet 4.6 | $3/MTok | $15/MTok |

### Per-Task Cost (50K input + 10K output)

- **Opus:** (50K * $5/1M) + (10K * $25/1M) = $0.25 + $0.25 = **$0.50/task**
- **Sonnet:** (50K * $3/1M) + (10K * $15/1M) = $0.15 + $0.15 = **$0.30/task**

### Over 50 Features

| Scenario | Cost | Savings |
|---|---|---|
| All Opus | 50 * $0.50 = **$25.00** | baseline |
| All Sonnet | 50 * $0.30 = **$15.00** | $10.00 (40%) |
| Opus plan + Sonnet build | (50 * $0.05 plan) + (50 * $0.30 build) = **$17.50** | $7.50 (30%) |

**Real-world caveat:** These are per-task estimates. Anthropic's harness design blog shows full-stack app builds costing $9 (solo) to $125-200 (with harness). The planning step itself is cheap ($0.46 in their DAW example). The build phases dominate cost regardless of model.

**Actual savings driver:** Not per-token price but throughput. Sonnet is 30-50% faster than Opus, meaning build tasks complete sooner, reducing wall-clock time.

---

## 3. What Anthropic Recommends (Harness Design Blog, Mar 24, 2026)

Anthropic's official harness uses a **three-agent architecture**:
- **Planner:** Expands 1-4 sentence prompt into full product spec. Stays high-level (what, not how).
- **Generator (Builder):** Implements features, uses React/FastAPI/PostgreSQL stack, git for version control.
- **Evaluator (QA):** Uses Playwright MCP to test the running app, grades against criteria.

### Critical finding: They use Opus for ALL three roles.

From the blog: "For the first version of this harness, I used Claude Opus 4.5... I kept both the planner and evaluator, as each continued to add obvious value." When they upgraded to Opus 4.6, they simplified the harness (removed sprint construct, moved evaluator to single pass) because "Opus 4.6 plans more carefully, sustains agentic tasks for longer, can operate more reliably in larger codebases."

**They never tested Sonnet as the generator.** The blog does not mention using different models for different roles. The entire system runs on Opus.

**Key quote:** "Without the planner, the generator under-scoped: given the raw prompt, it would start building without first speccing its work." This validates the planner's value but says nothing about whether a cheaper model could execute the plan.

---

## 4. What GSD Does

GSD (Get Shit Done) uses **"Opus leads, Sonnets build"** pattern:
- Opus 4.6 (1M context) is the orchestrator/planner
- Sonnet subagents execute isolated tasks in fresh 200K contexts
- Plans are verified before execution (planner -> checker -> revise loop)
- Subagent reports are treated as claims, not facts (anti-hallucination)

### User reports on GSD quality:
- "The absolutely bonkers part is that your main context window stays at 30-40% even after deep research or thousands of lines of code getting written. All heavy lifting happens consistently in fresh 200k subagent contexts."
- Plans get verified before they run, compensating for Sonnet's lower planning ability.
- Automatic debugging when things break -- spawns debug agents if Sonnet makes mistakes.

### GSD's architecture validates the pattern:
The key insight is that **plan quality compensates for builder capability**. GSD invests heavily in plan verification precisely because Sonnet builders need explicit, verified instructions.

---

## 5. Parallel Execution: Risks and Mitigations

### Proven benefits:
- Multiple Sonnet agents CAN build independent features simultaneously
- Each agent gets a fresh context window (no context pollution)
- Git worktrees provide isolation (one branch per agent)
- Throughput scales linearly with agents (up to merge bottleneck)

### Real risks (from Pragmatic Engineer, Augment Code, "Agentic Drift" blog):

| Risk | Severity | Mitigation |
|---|---|---|
| **Merge conflicts** | Medium | Git worktrees, spec-scoped tasks with explicit file boundaries |
| **Pattern drift** | High | Shared CLAUDE.md, architectural constraints in plan, post-merge review |
| **Duplicate code** | High | Coordinator agent, DRY review pass after merge |
| **Semantic conflicts** | Critical | Short integration cycles ("merge early, merge often"), post-merge idealized diffing |
| **Shared file hotspots** | High | Decompose tasks to minimize shared surface area; config files are collision magnets |

**Key quote (Helge Sverre):** "Agentic drift probably can't be eliminated. Parallelism is too useful, and the cost of full coordination between agents would eat the productivity gains. But it can be managed."

**Key quote (Augment Code):** "The multi-agent coding workspace is reliable only when agents work on isolated, spec-scoped tasks."

---

## 6. The Plan Quality Argument

### Does a well-planned task need a smart builder?

**Evidence FOR cheaper builder:**
- GSD proves it works: Opus plans, Sonnet executes, quality is acceptable with verification
- Claude Code's `opusplan` mode exists specifically for this pattern: "Opus-quality planning with Sonnet-speed execution"
- ClaudeFast recommends: "Start with Sonnet, escalate when needed"
- Anthropic's own system card: "Pairing Claude Opus 4.5 with lightweight Claude Haiku 4.5 subagents yielded a 12.2% improvement over Opus 4.5 alone (87.0% vs. 74.8%)" -- even Haiku works as a subagent

**Evidence AGAINST cheaper builder:**
- Anthropic's harness design blog uses Opus for all roles (never tested Sonnet as generator)
- Terminal-Bench 2.0 gap (6.3 pts) suggests Opus is meaningfully better at multi-step agentic coding
- "Plans are prompts" -- a plan can't anticipate every edge case; the builder must reason through unknowns
- Reddit user (Emmanuel Bernard): "I noticed that coding was getting a bit sloppier [with Sonnet default]. I'm shifting back to Opus 4.6. Frontier models make a difference."
- Reddit benchmarker: "For breadth-first adversarial work, Sonnet is genuinely better. Opus earns its premium on depth-first multi-hop reasoning only."

**The consensus:** If the plan is file-level specific with test cases and patterns documented, Sonnet can execute ~80-90% of tasks at equivalent quality. The remaining 10-20% (complex debugging, architectural decisions mid-implementation, novel pattern creation) benefit meaningfully from Opus.

---

## 7. Sonnet 4.6 Context Window

Sonnet 4.6 now has **1M context** (GA since March 13, 2026) at standard pricing with no surcharge. This was previously Opus-only territory.

**Impact on the calculus:** Significant. The old argument was "Sonnet can't see the whole codebase." That's gone. Both models can hold the entire project context. The remaining differentiator is reasoning depth, not context capacity.

**Caveat:** Beyond 200K tokens, pricing doubles ($3->$6 input, $15->$22.50 output for Sonnet). For subagent tasks that fit in 200K, standard pricing applies.

---

## 8. Interleaved Thinking on Sonnet 4.6

Sonnet 4.6 supports **adaptive thinking** (automatically enables interleaved thinking). This means Sonnet can:
- Think between tool calls (not just at the start)
- Adjust strategy mid-execution based on intermediate results
- Chain complex tool calls with reasoning steps between them

**Impact:** This closes a significant gap. Previously, Sonnet would "think once, then act." Now it reasons dynamically during execution, similar to how Opus operates. The Rootly SRE benchmark confirmed: "Sonnet-4.6 performed similarly to Opus-4.6 on root cause accuracy... adaptive thinking allocates reasoning budget dynamically."

**Key limitation:** Sonnet's thinking budget is smaller than Opus's. For tasks requiring deep multi-hop reasoning, Opus still has more headroom.

---

## 9. Real User Reports

### Sonnet 4.6 as builder (positive):
- **Ivan Ivanka (LinkedIn):** "Sonnet 4.6 just... does what you ask. It's noticeably less lazy than Opus. Opus rewrites half the file, adds error handling you never asked for."
- **Anthropic's own testing:** Users preferred Sonnet 4.6 over Opus 4.5 59% of the time. Less overengineering, better instruction following.
- **Reddit benchmarker (agentic PR review):** "We now default to Sonnet 4.6 for the main agent orchestrator... Faster tool calling, slightly more efficient day-to-day work with no drop in quality."
- **Rootly:** "Sonnet-4.6 gained over 4 points on Sonnet-4.5 at the same price. The 4.6 release clearly improved Sonnet more than Opus."

### Sonnet 4.6 as builder (negative):
- **Emmanuel Bernard:** "Coding was getting a bit sloppier [after switch to Sonnet default]. Shifting back to Opus."
- **Tensorlake test:** "Opus is on another level... the gap in implementation quality, token usage, and time spent [is visible]."
- **HN commenter:** "There's little reason to use sonnet anymore. Haiku for summaries, opus for anything else. Sonnet isn't a good model by today's standards." (contrarian minority view)

### The opusplan consensus:
- Multiple LinkedIn/Reddit users recommend `opusplan` mode as "the best of both worlds"
- "Plan with Opus. Execute with Sonnet. Simple."
- Works especially well on Pro plan to conserve Opus token allocation

---

## 10. The "Smart Planner, Cheaper Builder" Pattern

### Is this proven in AI agent design?

**Yes, emphatically.** This is one of the most validated patterns in multi-agent systems:

1. **Anthropic's own "Building Effective Agents" blog** recommends routing: "easy/common questions to smaller, cost-efficient models like Haiku and hard/unusual questions to more capable models like Sonnet"

2. **Hierarchical delegation pattern** (industry standard):
   ```
   Manager Agent (Opus/Sonnet) -> Worker Agents (Sonnet/Haiku)
   ```

3. **Claude Code's `opusplan` mode** is Anthropic's official implementation of this exact pattern.

4. **Cost-tier strategy** (from user who switched agent from Opus to Haiku):
   - Haiku: 95% of tasks (execution, automation)
   - Sonnet: 4% (user-facing, content creation)
   - Opus: 1% (planning, architecture, debugging)
   - Result: "~40% of weekly limit by Friday. Down from 70-80%. Same output."

5. **The Haiku/Sonnet/Opus tiering article** formalizes it:
   ```
   Sonnet creates detailed plan ($0.50) -> Haiku executes ($0.30) -> Sonnet verifies ($0.10)
   = $0.90 total, likely higher quality vs. just Sonnet executing ($2.00)
   ```

6. **Anthropic's system card** proves multi-model orchestration: "Pairing Opus orchestrator with Sonnet subagents achieved 85.4% vs 66.5% with Sonnet as orchestrator." The orchestrator matters more than the worker.

---

## Recommendation

### The verdict: Opus plan + Sonnet build is the right architecture.

**Why:**

1. **The SWE-bench gap is noise (1.2 pts).** For standard feature implementation from a detailed plan, Sonnet produces equivalent output at 40% lower cost.

2. **Anthropic built `opusplan` for this exact use case.** It's a first-party, officially supported mode in Claude Code.

3. **GSD already proves it works.** Your current plugin architecture (Opus orchestrator + Sonnet subagents) is the industry-standard pattern.

4. **Sonnet 4.6 closed most gaps.** 1M context, interleaved thinking, and adaptive reasoning make it a capable builder. Users prefer it over the previous Opus generation.

5. **Parallel execution is the real win.** Multiple Sonnet agents building independent features simultaneously is impossible with a single Opus instance. The throughput gain (3-5x with parallel agents) far exceeds the marginal quality improvement of Opus building.

6. **Anthropic's harness design validates the planner role.** Their key finding was that without a planner, the generator under-scoped. With a planner, even the generator's self-evaluation improved. The plan quality drives the output quality more than the builder's raw intelligence.

### Recommended architecture:

```
Opus 4.6 (interactive, 1M context)
  |-- Thinking: whiteboard, PRD, architecture, plan creation
  |-- Plan verification: checker loop before execution
  |-- Escalation: complex debugging, novel architecture decisions
  |
  +-- Sonnet 4.6 subagents (parallel, fresh 200K contexts)
       |-- Feature implementation from verified PLAN.md
       |-- Test writing (TDD from plan's test specs)
       |-- Code review (adversarial breadth-first)
       |-- Browser QA (identical pass rate at 5.5x cheaper)
       |
       +-- Opus 4.6 (escalation only)
            |-- When Sonnet fails 3+ times on same task
            |-- When task requires multi-hop architectural reasoning
            |-- When debugging crosses 3+ file boundaries
```

### Where Opus stays essential (do NOT delegate to Sonnet):

1. **Initial architecture design** -- the 10.5-point ARC-AGI gap is real
2. **Plan creation and verification** -- under-scoping is the #1 failure mode
3. **Complex debugging** -- Terminal-Bench gap of 6.3 points matters
4. **Cross-cutting refactors** -- when changes touch shared abstractions
5. **Final integration review** -- catching semantic conflicts between parallel branches

### Where Sonnet excels as builder:

1. **Feature implementation from spec** -- 1.2 pts SWE-bench gap = noise
2. **Test writing** -- follows patterns well, less overengineering
3. **Code review** -- "For breadth-first adversarial work, Sonnet is genuinely better"
4. **Routine bug fixes** -- clear scope, clear fix
5. **Documentation and cleanup** -- instruction following is rated higher than Opus

### Cost projection for your plugin:

| Scenario | Monthly estimate (heavy usage) | Notes |
|---|---|---|
| Current (all Opus) | ~$150-300/mo | Single-threaded, high quality |
| Opus plan + Sonnet build | ~$90-180/mo | 30-40% savings + parallel execution |
| With parallel agents (3x) | ~$120-240/mo | Higher throughput, slightly higher total |

The real ROI is not just cost savings -- it's **throughput**. Three Sonnet agents building in parallel, guided by an Opus plan, will ship 3x faster than one Opus doing everything sequentially.

---

## Sources

- [Anthropic Harness Design Blog (Mar 2026)](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Anthropic Effective Harnesses Blog (Nov 2025)](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic Sonnet 4.6 Launch](https://www.anthropic.com/news/claude-sonnet-4-6)
- [Anthropic Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [Anthropic Opus 4.5 System Card (multi-agent benchmarks)](https://www.anthropic.com/claude-opus-4-5-system-card)
- [ClaudeFast Model Selection Guide](https://claudefa.st/blog/models/model-selection)
- [Rootly SRE-skills-bench](https://rootly.com/blog/claude-sonnet-4-6-benchmark-results-and-lessons-for-ai-sre)
- [Morphllm Best AI for Coding Rankings](https://morphllm.com/best-ai-model-for-coding)
- [Reddit: Opus 4.6 vs Sonnet 4.6 Agentic PR Review](https://www.reddit.com/r/ClaudeAI/comments/1r9jf2j/)
- [Reddit: Sonnet 4.6 Benchmarks (r/mlops)](https://www.reddit.com/r/mlops/comments/1r7ignj/)
- [Pragmatic Engineer: Parallel AI Agents](https://blog.pragmaticengineer.com/new-trend-programming-by-kicking-off-parallel-ai-agents/)
- [Augment Code: Multi-Agent Workspace](https://www.augmentcode.com/guides/how-to-run-a-multi-agent-coding-workspace)
- [Agentic Drift (Helge Sverre)](https://helgesver.re/articles/agentic-drift)
- [Lumenalta: 8 Tactics for Context Drift](https://lumenalta.com/insights/8-tactics-to-reduce-context-drift-with-parallel-ai-agents)
- [GSD GitHub](https://github.com/gsd-build/get-shit-done)
- [NxCode Decision Guide](https://www.nxcode.io/resources/news/claude-opus-or-sonnet-for-coding-decision-guide-2026)

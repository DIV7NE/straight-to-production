# Harness Ablation Research: What Happens When You Remove Components

Date: 2026-04-01
Sources: Anthropic Engineering Blog, Meta-Harness (Stanford/MIT arXiv 2603.28052), Phil Schmid, Armin Ronacher, HumanLayer, community reports

---

## 1. What Harness Components Are Still Load-Bearing with Opus 4.6?

### Type-Check Hooks: STILL NEEDED (but differently)
- Opus 4.6 self-corrects more often, but **deterministic type-checking catches what self-correction misses**
- HumanLayer's approach: hook runs on Stop, silent on success, exit code 2 re-engages agent on failure
- Key insight: hooks are zero-cost when they pass (nothing enters context). Cost only on failure.
- The model CAN self-correct type errors, but hooks guarantee it happens 100% of the time vs ~80-90% with advisory rules
- **Verdict: Keep type-check hooks. They're cheap insurance. But move from per-edit to Stop-only to reduce overhead.**

### Task Reminders: LIKELY REMOVABLE for Opus 4.6
- 1M context window is accurate up to ~400K tokens; recall becomes fuzzy >600K tokens
- Anthropic removed the "sprint construct" (work decomposition/reminders) entirely with Opus 4.6 — model handled coherent work natively
- Manual `/compact` at ~50% context usage is more effective than automated reminders
- **Verdict: Remove per-prompt task re-injection. Replace with compact discipline + good initial task framing.**

### Context Monitors: PARTIALLY NEEDED
- Progressive context warnings still useful because "agent dumb zone" patterns are real near context limits
- But Opus 4.6 with 1M context rarely hits dangerous zones in normal sessions
- Community reports Opus sometimes overcomplicates trivial tasks with excessive token use ($45+ for digit changes)
- **Verdict: Keep as lightweight guard (threshold alert at 60%), remove progressive escalation complexity.**

### Separate Evaluators: DEPENDS ON TASK COMPLEXITY
- Direct quote from Anthropic (Prithvi Rajasekaran, March 2026):
  > "On 4.5, that boundary was close: our builds were at the edge of what the generator could do well solo, and the evaluator caught meaningful issues across the build. On 4.6, the model's raw capability increased, so the boundary moved outward. Tasks that used to need the evaluator's check to be implemented coherently were now often within what the generator handled well on its own."
  > "For tasks within that boundary, the evaluator became unnecessary overhead. But for the parts of the build that were still at the edge of the generator's capabilities, the evaluator continued to give real lift."
- The planner remained load-bearing even on Opus 4.6 — without it, the generator under-scoped features
- **Verdict: For solo dev daily work (< 3-file changes), evaluator is overhead. For multi-hour autonomous builds at the edge of capability, evaluator still gives "real lift."**

---

## 2. Anthropic's "Methodical Ablation" Approach

From the Anthropic engineering blog (March 24, 2026):

### What NOT to do:
- "In my first attempt to simplify, I cut the harness back radically and tried a few creative new ideas, but I wasn't able to replicate the performance of the original"
- "It also became difficult to tell which pieces of the harness design were actually load-bearing"

### The correct approach:
1. **Remove ONE component at a time**
2. **Review impact on final result** (not intermediate steps)
3. **Re-test assumptions**: "Every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing, both because they may be incorrect, and because they can quickly go stale as models improve"
4. **Track the evaluator boundary**: the line between what the model handles solo vs. what needs external checking. This boundary moves outward with each model release.

### What they actually removed with Opus 4.6:
- Sprint construct (work decomposition into chunks) -- model handled coherence natively
- Per-sprint evaluation -- moved to single end-of-run pass
- Some context reset logic -- continuous session with SDK compaction worked better

### What they KEPT:
- Planner agent (generator under-scoped without it)
- Evaluator for edge-of-capability tasks
- Structured artifacts for context handoff

---

## 3. Code Quality Without Plugins (CLAUDE.md Only)

### No formal A/B study exists, but converging evidence:

- **Vercel removed 80% of their agent's tools and got better results** (cited in working-ref.com analysis)
- **Manus rewrote their harness 5 times in 6 months** trying to find the right simplification level
- **LangChain redesigned Deep Research 4 times** for the same reason

### The emerging consensus (early 2026):
```
CLAUDE.md < 200 lines (ideally ~60 lines)
  + hooks for deterministic enforcement
  + skills for on-demand workflows
  = the practical sweet spot
```

### Plugin testing (Build to Launch, March 2026):
- Tested 11 plugins, kept 4
- Key finding: most plugins add layers that overlap with existing workflows
- Plugins justified for: multi-phase planning, unattended automation, formal verification, 3+ file features
- For daily solo dev work, CLAUDE.md + hooks is sufficient

---

## 4. Phil Schmid's "Build to Delete" (philschmid.de/agent-harness-2026)

Published January 5, 2026. Three core principles:

### Principle 1: Start Simple
> "Don't build massive control flows. Provide robust atomic tools. Let the model make the plan."

### Principle 2: Build to Delete
> "Every piece of hand-coded logic is a liability when the next model ships."
> "Capabilities that required complex, hand-coded pipelines in 2024 are now handled by a single context-window prompt in 2026."
- Make architecture modular so you can rip out yesterday's logic
- If you over-engineer control flow, the next model update breaks your system

### Principle 3: The Harness is the Dataset
> Competitive advantage is the **trajectories your harness captures**, not the prompt.
- The data about how your agent works (execution traces, failure modes) is more valuable than the harness code itself

### His analogy:
- The Model = CPU (raw processing power)
- The Context Window = RAM (limited, volatile working memory)
- The Agent Harness = Operating System (curates context, handles boot sequence, provides drivers)
- The Agent = Application (specific user logic running on top)

---

## 5. Meta-Harness / TerminalBench Research (arXiv 2603.28052)

**Authors**: Yoonho Lee, Roshen Nair, Qizheng Zhang, Kangwook Lee, Omar Khattab, Chelsea Finn (Stanford + MIT)
**Published**: March 30, 2026

### Core finding:
Auto-evolved harnesses can **match or beat** hand-engineered ones.

### Results:
| Benchmark | Meta-Harness | Best Hand-Engineered | Delta |
|-----------|-------------|---------------------|-------|
| TerminalBench-2 (Opus 4.6) | 76.4% | 74.7% (Terminus-KIRA) | +1.7 |
| TerminalBench-2 (Haiku 4.5) | 37.6% | 35.5% (Goose) | +2.1 |
| Online text classification | +7.7 points over SOTA | — | with 4x fewer tokens |
| Math reasoning (200 IMO problems) | +4.7 points average | — | across 5 held-out models |

### How it works:
- Outer-loop agentic proposer reads source code, scores, and execution traces of all prior harness candidates
- Evolves the FULL coding harness: system prompts, tool definitions, completion-checking logic, and context management
- Reads per-task execution traces (command logs, error messages, timeout behavior) to diagnose failure modes

### Key implication for Pilot:
> Manually engineered harness logic has diminishing returns as models improve. The harness should be **discoverable** (the model figures out what it needs) rather than **prescribed** (you tell it what to do).

---

## 6. The Harness Paradox

### The paradox stated:
> "All six frontier models within 1.3% of each other. The harness, not the model, drives the remaining variance."
> — morphllm.com model rankings

### What this means in practice:
- **For benchmarks**: The scaffold accounts for more of the performance delta than the model. Same model with basic scaffold: 23%. Same model with 250-turn optimized scaffold: 45%+. A 22-point swing dwarfing model differences.
- **For daily use**: Simpler setups win. Complex harnesses optimized for benchmarks add overhead, token cost, and latency without proportional benefit in real workflows.

### The resolution:
- Benchmark-optimized harnesses are over-fit to synthetic tasks
- Daily-use harnesses should be minimal + modular
- Constraining the solution space paradoxically makes agents more productive (less token waste exploring dead ends)
- **Optimize your harness first, not your model selection**

---

## 7. Pi Agent: Radical Minimalism (Armin Ronacher)

**Source**: lucumr.pocoo.org/2026/1/31/pi/
**Author**: Armin Ronacher (creator of Flask, Rye, uv)

### The design:
- **System prompt**: Shortest of any known agent (under 1,000 tokens)
- **Four tools only**: Read, Write, Edit, Bash
- **No MCP support** (deliberate philosophical choice)
- **No pre-built skills/plugins** — the agent extends itself by writing code

### Why it works:
1. **Self-extension**: If the agent needs a capability, it writes it. Not "download a plugin" but "write the code"
2. **Extension persistence**: Extensions persist state into sessions via custom messages
3. **Hot reloading**: Agent writes code, reloads, tests, loops until functional
4. **Session branching**: Sessions are trees — branch for side-quests, navigate back

### What's NOT in Pi (and why):
- No MCP — philosophy says agent should write its own tools
- No downloaded extensions by default — point agent at an example, it builds its own version
- No complex system prompt — frontier models don't need pages of instructions

### Key quote from Ronacher:
> "Pi's entire idea is that if you want the agent to do something that it doesn't do yet, you don't go and download an extension or a skill. You ask the agent to extend itself. It celebrates the idea of code writing and running code."

### Practical evidence:
- Powers OpenClaw (viral autonomous agent)
- Ronacher uses it "almost exclusively" for daily coding
- Lower latency, reduced costs, predictable behavior vs. commercial alternatives

---

## 8. Optimal CLAUDE.md Size

### Proven thresholds:
| Metric | Threshold | Source |
|--------|-----------|--------|
| Modularization trigger | 150-200 lines | Claude Code best practices |
| Hard upper limit | 40,000 characters | GitHub issue (ruflo #585) |
| Ideal core file | ~60 lines | Community consensus |
| Compliance rate | ~80% | Community reports |

### The "lost in the middle" problem:
- Documented cases of agents ignoring CLAUDE.md instructions due to position effects
- Critical rules should be placed EARLY in the file
- In typical sessions, only 14-28% of a monolithic CLAUDE.md is relevant context

### Token waste evidence:
- Progressive disclosure across skills instead of monolithic CLAUDE.md recovers ~15,000 tokens per session (82% improvement)
- Each loaded plugin CLAUDE.md adds to the system prompt (your 143K chars of CLAUDE.md files is significant)

### Recommendation:
```
Core CLAUDE.md: 60-100 lines (critical rules, project identity)
Enforcement: Hooks (deterministic, zero-cost on success)
On-demand context: Skills (loaded only when invoked)
```

---

## 9. Hook Overhead and Diminishing Returns

### Latency budget:
- **500ms max per hook** or workflow feels sluggish
- 5 synchronous hooks at 200ms each = 1 second per event
- 95 hooks without noticeable latency IS achievable if each completes under 200ms

### Token cost hierarchy:
| Hook Type | Token Cost | Execution Cost |
|-----------|-----------|----------------|
| Command hooks (bash scripts) | Zero on success | Shell process spawn |
| Prompt hooks (context injection) | Tokens consumed every turn | Proportional to injected text |
| Agent hooks (spawn Claude sessions) | Full API credits | High — reserve for high-value workflows |

### Diminishing returns curve:
- **Skills 1-10**: Productivity hack (DRY for prompts)
- **Skills 11-30**: Marginal gains, effort ~= savings
- **Skills 30+**: Composition unlock — skills calling skills become exponential
- **Skills 68**: "System is complete not when every task has a skill, but when every task can be assembled from existing skills"

### The architectural principle:
> "Hooks are for deterministic automation; skills are for tasks requiring judgment."
- Hooks: 100% execution guarantee, zero context cost on success, shell-speed
- Skills: LLM-mediated, judgment-capable, but token-consuming

---

## 10. The Evaluator Boundary Concept

### Definition:
The evaluator boundary is the line between what the model handles well solo vs. what needs external checking. It moves outward with each model release.

### How Anthropic tracks it:
1. Start with generator + evaluator architecture
2. After model upgrade, run the same tasks
3. Observe which evaluator catches are now handled natively by the generator
4. For tasks within the new boundary: evaluator is overhead → remove it
5. For tasks still at the edge: evaluator gives "real lift" → keep it

### Practical heuristic for Opus 4.6:
- **Within boundary** (evaluator unnecessary): Single-file changes, standard patterns, well-typed code, < 3 files
- **At the edge** (evaluator helps): Multi-hour autonomous builds, novel architectures, subjective quality (design taste), complex multi-file refactors
- **Beyond boundary** (evaluator essential): Tasks where the model consistently produces incorrect results even with feedback

### The moving target:
> "Every harness component encodes an assumption about what the model can't do alone. When models improve, those assumptions must be re-tested."

---

## Synthesis: What You Don't Know That You Don't Know

### 1. Your task reminders may be HURTING performance
The per-prompt re-injection pattern consumes tokens on every turn. Opus 4.6 with 1M context doesn't need constant reminding for sessions under 400K tokens. The tokens spent on reminders could be better used on actual work.

### 2. The "compliance rate" ceiling is real
CLAUDE.md is followed ~80% of the time regardless of how well-written it is. Hooks enforce 100%. The 20% gap is where bugs come from. This means the RIGHT architecture is: thin CLAUDE.md (identity + critical rules) + hooks (enforcement) + skills (on-demand).

### 3. Auto-evolved harnesses are already beating hand-engineered ones
Meta-Harness (Stanford/MIT) proves the concept. The implication: spending time hand-tuning your harness has diminishing returns. The future is harnesses that optimize themselves from execution traces.

### 4. Pi proves the floor is higher than expected
A 4-tool agent with a <1000 token system prompt is viable for daily coding with frontier models. Everything above that baseline needs to justify its existence against the token/latency/complexity cost.

### 5. The harness paradox resolves toward simplicity for daily use
Complex harnesses win benchmarks but lose in practice. The 22-point benchmark swing from scaffold optimization does NOT translate to 22 points of daily productivity. Constraining the solution space makes agents converge faster.

### 6. Your 143K characters of CLAUDE.md files is a context bomb
At 14-28% relevance per session, you're burning ~100K characters of context on instructions that aren't relevant to the current task. Progressive disclosure (skills loaded on demand) recovers most of this.

### 7. The evaluator boundary moved significantly with Opus 4.6
Tasks that required a separate evaluator on Claude 4.5 are now within the model's solo capability. For a solo developer doing typical feature work, the planner-generator-evaluator architecture is likely overkill. A single agent with type-check hooks at Stop is probably sufficient.

### 8. "Build to Delete" is not advice — it's a prediction
Phil Schmid's principle is descriptive, not prescriptive. Every harness component you build today WILL be obsoleted by model improvements. The question isn't whether to delete, but how easily you can.

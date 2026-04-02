# Claude Code Execution Models: Comparative Analysis

**Date:** 2026-04-02
**Purpose:** Determine the optimal execution model for Pilot's plugin workflow across interactive, autonomous, and parallel scenarios.

---

## 1. The Four Execution Models

### 1A. Main Agent (Single Opus Session)

**How it works:** One Opus 4.6 session with 1M context window handles everything directly — planning, coding, testing, committing. No delegation overhead.

**Strengths:**
- Zero orchestration overhead (no token cost for spawning, prompting, or result parsing)
- Full context continuity — the agent remembers every decision, every file read, every error encountered
- Best quality output — Opus is the strongest model, and it has complete context
- Simplest mental model — one agent, one branch, one commit history
- No merge conflicts, no pattern drift, no duplicate code

**Weaknesses:**
- Serial execution only — cannot parallelize independent work
- Context window fills over long sessions (even with 1M, multi-phase projects accumulate)
- Single point of failure — if the session dies, all in-flight context is lost
- Cannot leverage cost savings from cheaper models on mechanical tasks

**Best for:** Interactive building, complex features touching many files, debugging, architectural work, anything requiring judgment and cross-file understanding.

### 1B. Subagents (Agent/Task Tool)

**How it works:** Main agent spawns child agents via the `Task()` tool. Each subagent gets a fresh context window with an explicit prompt. Subagents can read/write files, run bash, use all standard tools. They inherit the parent's CLAUDE.md and project settings but NOT the parent's conversation history.

**Key mechanics (from tool definitions):**
- `subagent_type` selects the agent definition (e.g., `gsd-executor`, `gsd-verifier`, or built-in types like `general-purpose`, `Explore`)
- `model` parameter controls which model runs the subagent (opus, sonnet, haiku)
- `isolation="worktree"` creates a git worktree so the subagent works on a separate branch in a separate directory (via `EnterWorktree` tool internally)
- Subagents block the parent by default — parent waits for completion, then reads the result
- `run_in_background=true` on the Agent tool allows non-blocking spawning (parent continues while subagent works)
- Fresh context per spawn — no context pollution between tasks

**Token overhead per spawn:**
- The subagent loads: its agent definition prompt (~500 lines for gsd-executor), any files listed in `<files_to_read>`, CLAUDE.md, and the task prompt
- Estimated: 5-15K tokens of boilerplate per spawn before any actual work begins
- For a 3-task plan: ~15-45K tokens of overhead vs zero for main agent doing it inline

**Strengths:**
- Fresh context per task (no accumulated confusion)
- Can run different models for different roles (Opus for planning, Sonnet for execution, Haiku for verification)
- Worktree isolation prevents file conflicts between parallel agents
- Parent stays lean — only tracks high-level coordination

**Weaknesses:**
- Each spawn loses all prior context (must re-read files, re-discover project structure)
- Orchestration tokens add up (parent prompt + subagent prompt + result parsing)
- Background agents have no way to ask clarifying questions (they either succeed or fail)
- Completion signal can be unreliable (GSD has fallback spot-checks for this)

**Best for:** Execution of well-specified plans, parallel independent tasks, cost optimization on mechanical work.

### 1C. Agent Teams (TeamCreate + TaskCreate + SendMessage)

**How it works:** A team is created with `TeamCreate`, producing a shared task list at `~/.claude/tasks/{team-name}/`. Teammates are spawned via the Agent tool with `team_name` and `name` parameters. They can send messages to each other via `SendMessage` and coordinate via the shared task list.

**Key mechanics (from TeamCreate tool definition):**
- Team = TaskList — 1:1 correspondence
- Teammates go idle between turns (this is normal, not an error)
- Messages are automatically delivered to the team lead
- Teammates can DM each other (team lead gets a summary in idle notifications)
- Task ownership via `TaskUpdate` with `owner` parameter
- Teammates discover each other by reading `~/.claude/teams/{team-name}/config.json`
- Broadcast to all teammates: `SendMessage(to="*", ...)` — expensive, linear in team size

**Coordination overhead:**
- Each teammate is a full agent session (same overhead as a subagent, plus message handling)
- Every message exchange costs tokens on both sender and receiver
- Team lead spends significant tokens on coordination (reading messages, routing tasks, resolving conflicts)
- Idle notifications generate noise in the team lead's context

**When teams beat subagents (from CLAUDE.md):**
- 3+ related tasks with potential shared findings
- Coordination-heavy work where agents need to communicate discoveries
- When broadcast of findings is needed across workers

**When NOT to use teams (from CLAUDE.md):**
- Checkpoint-based execution (git safety concerns)
- Sequential wave plans (execute-phase handles this better)
- Isolated exploration tasks

**Strengths:**
- Inter-agent communication (agents can share discoveries, ask each other questions)
- Dynamic task assignment (agents claim work from shared list)
- Good for exploratory/research work where findings in one area inform another

**Weaknesses:**
- Highest coordination overhead of all models
- Message-passing costs tokens on both sides
- Risk of agents stepping on each other's work
- No built-in merge conflict resolution
- Idle notification noise consumes team lead context

**Best for:** Research phases, "go-wide" parallel exploration, multi-domain investigation where findings cross-pollinate.

### 1D. Headless Sessions (claude -p)

**How it works:** Fresh CLI invocations per task. Each is a completely independent session. No shared state except the filesystem. Used by `/pilot:auto`.

**Key mechanics:**
- Each invocation starts cold — reads CLAUDE.md, discovers project from scratch
- No inter-session communication except through files on disk
- Can be orchestrated by a shell script, CI pipeline, or another Claude session
- Each session has its own full context window

**Strengths:**
- Maximum isolation — sessions cannot interfere with each other
- Can run truly in parallel (multiple terminal processes)
- Survives crashes — each session is independent
- Good for CI/CD integration

**Weaknesses:**
- Zero context sharing — each session re-discovers everything
- No coordination mechanism except file locks / git branches
- Highest per-task overhead (full cold start each time)
- Cannot ask questions or communicate between sessions

**Best for:** Overnight autonomous runs, CI/CD pipelines, completely independent tasks.

---

## 2. How GSD Uses These Models

### Wave-Based Parallelization (execute-phase)

GSD's `execute-phase` workflow uses **Model 1B (Subagents)**, not teams. The execution model:

1. **Orchestrator (Opus)** reads all plans, groups them into dependency waves
2. **Wave 1:** Spawn N `gsd-executor` subagents in parallel, one per plan
   - Each agent gets `isolation="worktree"` for git isolation
   - Each agent uses `--no-verify` on commits to avoid pre-commit hook contention
   - Agents run the model specified by the active profile (Opus in quality, Sonnet in balanced/budget)
3. **Wait for all Wave 1 agents to complete** (with spot-check fallback if completion signals fail)
4. **Post-wave hook validation:** Run pre-commit hooks once on merged state
5. **Cross-plan dependency check:** Verify Wave 1 artifacts exist before spawning Wave 2
6. **Wave 2:** Spawn next batch, repeat

**Conflict mitigation strategies:**
- **Worktree isolation** (`isolation="worktree"`): Each agent works in its own git worktree on its own branch, in a separate directory under `.claude/worktrees/`. They literally cannot edit the same files simultaneously.
- **Wave dependency ordering:** Plans that depend on each other are in different waves. Wave 2 only starts after Wave 1 completes.
- **Post-wave hook validation:** Hooks run once after merge, catching integration issues
- **Key-link verification:** Before Wave N+1, GSD verifies that artifacts from Wave N actually exist and are properly wired

**The "Opus orchestrates, Sonnet builds" pattern:**

From `model-profiles.cjs`:
```
gsd-executor:  { quality: 'opus', balanced: 'sonnet', budget: 'sonnet' }
gsd-planner:   { quality: 'opus', balanced: 'opus',   budget: 'sonnet' }
gsd-verifier:  { quality: 'sonnet', balanced: 'sonnet', budget: 'haiku' }
```

In `balanced` profile (the default):
- **Opus** handles: planning (gsd-planner), debugging (gsd-debugger), UI research
- **Sonnet** handles: execution (gsd-executor), verification, plan checking, integration checking
- **Haiku** handles: codebase mapping, Nyquist auditing (lightweight tasks)

This is the established community pattern. The orchestrator (main agent, always Opus) stays lean at ~15% context usage, while Sonnet executors get 100% fresh context per plan.

### Interactive Mode (--interactive flag)

GSD also supports `--interactive` mode which switches to **Model 1A (Single Agent)**: the orchestrator executes plans inline sequentially, no subagent spawning. Benefits: dramatically lower token usage, user catches mistakes early. Best for small phases, bug fixes, and verification gaps.

---

## 3. How Superpowers Uses These Models

### Dispatching Parallel Agents

Superpowers' `dispatching-parallel-agents` skill uses **Model 1B (Subagents)** — same as GSD but simpler:

1. Identify independent problem domains (e.g., 3 failing test files)
2. Dispatch one `Task()` per domain with focused scope
3. All run concurrently
4. Review results, check for conflicts, run full test suite

**Key difference from GSD:** Superpowers does not use wave ordering or worktree isolation by default. It relies on the tasks being truly independent (different files, different subsystems). If agents would edit the same files, Superpowers says "Don't use."

### Subagent-Driven Development

Superpowers' `subagent-driven-development` skill uses **sequential Model 1B**:
- One implementer subagent per task (sequential, not parallel)
- After each task: spec reviewer subagent, then code quality reviewer subagent
- Three subagent invocations per task minimum
- Explicitly warns: "Never dispatch multiple implementation subagents in parallel (conflicts)"

**Model selection guidance from Superpowers:**
- Mechanical tasks (1-2 files, clear spec) → cheap/fast model
- Integration tasks (multi-file) → standard model
- Architecture/design/review → most capable model

---

## 4. Parallel Building Risks and Mitigations

### Risk: Merge Conflicts
- **GSD mitigation:** `isolation="worktree"` — each agent gets its own git worktree and branch. Conflicts only surface at merge time, after the wave completes.
- **Superpowers mitigation:** Only parallelize truly independent domains. If shared files, don't parallelize.
- **Residual risk:** Even with worktrees, if two plans both need to modify a shared config file or type definition, the merge will conflict.

### Risk: Pattern Drift
- **Each subagent gets fresh context** — it reads CLAUDE.md and project conventions, but has no memory of what other agents decided.
- **Mitigation:** Well-specified plans with explicit patterns ("use this naming convention", "follow this file structure"). GSD's planning phase handles this.
- **Residual risk:** If conventions aren't codified in CLAUDE.md or the plan, agents will invent their own.

### Risk: Duplicate Code
- **No built-in dedup mechanism** across parallel agents.
- **Mitigation:** Wave ordering — shared utilities should be in Wave 1, consumers in Wave 2.
- **Residual risk:** Two Wave-1 agents might independently create similar helper functions.

### Risk: Inconsistent Error Handling / Logging / Patterns
- **Same root cause as pattern drift** — agents don't share context.
- **Mitigation:** GSD's post-execution verification phase catches this. The `gsd-verifier` and `gsd-integration-checker` agents review the combined output.

---

## 5. Token Cost Analysis

### Orchestration Overhead

| Model | Overhead per Task | Total for 3-Task Phase |
|-------|------------------|----------------------|
| Main Agent (1A) | 0 tokens | 0 |
| Subagent (1B) | ~10-15K tokens (agent def + file reads + prompt) | ~30-45K |
| Team (1C) | ~15-25K tokens (agent def + team setup + messages) | ~45-75K |
| Headless (1D) | ~20-30K tokens (full cold start + CLAUDE.md + discovery) | ~60-90K |

### Cost Savings from Model Tiering

Using Sonnet instead of Opus for execution:
- Opus: ~$15/M input, ~$75/M output
- Sonnet: ~$3/M input, ~$15/M output
- **5x cost reduction on execution tokens**

For a typical plan execution consuming 50K tokens:
- Opus: ~$4.50
- Sonnet: ~$0.90
- **Savings: $3.60 per plan, minus ~$0.15 orchestration overhead = $3.45 net savings**

The cost savings from Sonnet execution clearly offset orchestration overhead for plans with >15K tokens of actual work.

---

## 6. The `isolation="worktree"` Parameter

**From EnterWorktree tool definition:**
- Creates a new git worktree inside `.claude/worktrees/` with a new branch based on HEAD
- Switches the session's working directory to the new worktree
- On exit, user chooses to keep or remove the worktree
- Requirements: must be in a git repo, must not already be in a worktree

**In GSD's execute-phase:**
- Each `gsd-executor` agent spawned with `isolation="worktree"`
- This means each parallel agent works in its own directory on its own branch
- No file-level conflicts during execution
- Merge happens after the wave completes

**Stability:** The feature is built into Claude Code's core tool set (not a plugin). GSD relies on it for all parallel execution. The fallback spot-check mechanism suggests it has been battle-tested but completion signals can occasionally fail.

---

## 7. Recommendations by Scenario

### Interactive Building (User Present, Iterating)

**Best model: 1A (Main Agent / Opus Direct)**

Rationale:
- User feedback loop is tight — agent needs to incorporate feedback immediately
- Cross-file understanding matters — Opus with full context makes better decisions
- No orchestration overhead — every token goes to actual work
- GSD agrees: `--interactive` mode explicitly bypasses subagents for this reason

### Overnight Autonomous Execution

**Best model: 1B (Subagents) with wave parallelization**

Rationale:
- No user present — agents cannot ask questions anyway
- Well-specified plans exist (created during interactive planning phase)
- Cost optimization matters — Sonnet executors at 5x cheaper than Opus
- Worktree isolation handles parallel safety
- GSD's execute-phase is purpose-built for this

### Parallel Feature Development (Multiple Independent Features)

**Best model: 1B (Subagents) with worktree isolation**

Rationale:
- Features are independent by definition
- Each feature gets a focused agent with full context for that feature
- Worktree isolation prevents conflicts
- Wave ordering handles dependencies if features share infrastructure

### Research / Exploration (Understanding a Codebase or Problem Space)

**Best model: 1C (Agent Teams)**

Rationale:
- Findings in one area inform investigation in another
- Agents can share discoveries via messages
- Dynamic task assignment as new questions emerge
- This is the one scenario where coordination overhead pays for itself

### CI/CD Integration (Automated Checks, Deployment)

**Best model: 1D (Headless Sessions)**

Rationale:
- Maximum isolation and crash resilience
- Each check is independent
- Easy to orchestrate from shell scripts or CI pipelines
- No need for inter-session communication

---

## 8. Implications for Pilot

### Current Pilot Model
Pilot currently uses Model 1A (main Opus agent does everything) for interactive building, and Model 1D (headless `claude -p`) for `/pilot:auto` autonomous execution.

### Recommended Architecture

| Phase | Model | Why |
|-------|-------|-----|
| Planning / Discussion | 1A (Opus direct) | Needs judgment, user interaction, full context |
| Plan Execution (single plan) | 1A or 1B | Simple plans: inline. Complex plans: subagent for fresh context |
| Multi-Plan Phase | 1B (Subagents + waves) | Parallel execution with worktree isolation |
| Verification / Review | 1B (Subagent, read-only) | Fresh eyes on the output, cheap model sufficient |
| Research / Exploration | 1C (Teams) or 1A | Teams if parallelizable, direct if sequential |
| Autonomous Overnight | 1B (Subagents) | Cost-optimized, crash-resilient, well-specified plans |
| CI/CD Integration | 1D (Headless) | Maximum isolation |

### Key Design Decision: When to Parallelize

Parallelize when ALL of these are true:
1. Tasks are specified in detail (a plan exists)
2. Tasks touch different files (or can be isolated via worktrees)
3. No task depends on another task's output
4. The cost savings justify the orchestration overhead (~15K+ tokens of actual work per task)

Do NOT parallelize when:
- Tasks share state or files heavily
- The work requires ongoing judgment calls
- The user needs to review incrementally
- Tasks are small enough that orchestration overhead exceeds execution cost

---

## 9. Summary Table

| Dimension | Main Agent (1A) | Subagents (1B) | Teams (1C) | Headless (1D) |
|-----------|----------------|----------------|------------|---------------|
| Context continuity | Full | None (fresh each) | Partial (messages) | None |
| Parallelism | None | Yes (with waves) | Yes (with messages) | Yes (fully independent) |
| Inter-agent communication | N/A | None | Yes (SendMessage) | None |
| Git isolation | N/A | Worktree per agent | Manual | Manual |
| Token overhead | Zero | Low-Medium | Medium-High | High |
| Cost optimization | No (always Opus) | Yes (model tiering) | Yes (model tiering) | Yes (model tiering) |
| Crash resilience | Low | Medium | Medium | High |
| Quality ceiling | Highest | Depends on model | Depends on model | Depends on model |
| Best for | Interactive, complex | Execution, parallel | Research, exploration | CI/CD, overnight |

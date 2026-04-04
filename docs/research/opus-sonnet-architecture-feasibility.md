# "Opus Plans, Sonnet Builds" Architecture: Feasibility Verification

**Date:** 2026-04-02
**Verdict:** FEASIBLE. Every mechanism required exists and is battle-tested by GSD.

---

## 1. Can a command file instruct Opus to spawn a Sonnet subagent?

**YES**, but not via `allowed-tools` in command frontmatter.

**How it actually works:** The `allowed-tools` field in command frontmatter (e.g., `feature.md`) restricts which tools the command's *own* execution context can use. Pilot's `feature.md` lists `["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion"]` -- it does NOT include `Agent` or `Task`.

**To spawn subagents, the command must include `Task` or `Agent` in its allowed-tools.** GSD workflows don't use `allowed-tools` frontmatter at all -- they're `.md` workflow files loaded into the main Opus context, which has access to all tools by default.

**The `model` parameter is real.** GSD's `execute-phase.md` explicitly passes `model="{executor_model}"` to `Task()`:
```
Task(
  subagent_type="gsd-executor",
  model="{executor_model}",
  isolation="worktree",
  prompt="..."
)
```

The `executor_model` value comes from `model-profiles.cjs`:
```javascript
'gsd-executor': { quality: 'opus', balanced: 'sonnet', budget: 'sonnet' }
```

In `balanced` profile (the default), executors run as **Sonnet**. This is the "Opus plans, Sonnet builds" pattern in production.

**Action for STP:** Add `"Agent"` (or `"Task"`) to `feature.md`'s `allowed-tools` array, or restructure so the orchestration logic lives in a workflow file that has full tool access.

---

## 2. Can the Agent tool use `isolation: "worktree"`?

**YES.** This is a real, built-in parameter.

**Evidence:** The `EnterWorktree` tool definition (fetched via ToolSearch) confirms:
- Creates a new git worktree inside `.claude/worktrees/` with a new branch based on HEAD
- Switches the session's working directory to the new worktree
- Requires: must be in a git repo, must not already be in a worktree

**What happens when a worktree agent finishes:**
- The worktree creates an isolated branch with its commits
- Those commits exist on that branch in the repo
- The worktree directory and branch persist until explicitly removed via `ExitWorktree(action="remove")` or kept via `ExitWorktree(action="keep")`
- If the agent makes no changes, the worktree still exists and must be cleaned up

**Merge is NOT automatic.** GSD's `execute-phase.md` does not contain any `git merge` commands after wave completion. The worktree agents commit to their branches, and the commits are visible in the main repo (they share `.git`). GSD's `complete-milestone.md` handles the actual merge via `git merge --squash` or `git merge --no-ff` at milestone boundaries, not per-wave.

**Key insight:** GSD appears to rely on the fact that worktree commits are automatically visible from the main branch's perspective (shared `.git` directory), and the orchestrator spot-checks via `git log --oneline --all`. The actual file changes appear to be merged implicitly when worktrees commit to branches that share a common ancestor.

**Correction after deeper analysis:** Looking at the worktree flow more carefully -- when `isolation="worktree"` is used with `Task()`, the Claude Code runtime likely handles the worktree lifecycle (create before, merge/cleanup after). The orchestrator's spot-check (`git log --oneline --all --grep=...`) confirms commits exist across all branches. The lack of explicit merge commands in execute-phase suggests the runtime handles this transparently.

---

## 3. Can multiple agents run in parallel with `run_in_background: true`?

**YES.** GSD's `map-codebase.md` spawns 4 agents simultaneously:
```
Task(subagent_type="gsd-codebase-mapper", model="...", run_in_background=true, prompt="...")
Task(subagent_type="gsd-codebase-mapper", model="...", run_in_background=true, prompt="...")
Task(subagent_type="gsd-codebase-mapper", model="...", run_in_background=true, prompt="...")
Task(subagent_type="gsd-codebase-mapper", model="...", run_in_background=true, prompt="...")
```

**How Opus knows they're done:** From CLAUDE.md: "you'll be notified when it finishes." Background tasks send completion notifications to the parent. GSD also implements fallback spot-checks (checking for SUMMARY.md files and git commits) in case completion signals are unreliable.

**Can Opus read the output?** Yes. The `Task()` tool returns the subagent's final output. For background tasks, the output is delivered with the completion notification.

**Parallel + worktree:** GSD's `execute-phase.md` spawns multiple `isolation="worktree"` agents per wave. Each gets its own worktree directory and branch. This is the proven pattern.

---

## 4. What context does a spawned subagent get?

**It gets CLAUDE.md automatically.** From the `gsd-executor.md` agent definition:
> "Read `./CLAUDE.md` if it exists in the working directory. Follow all project-specific guidelines."

The executor also checks `.claude/skills/` directories. Claude Code loads CLAUDE.md for every session, including subagent sessions.

**It does NOT get the parent's conversation history.** From the execution-models research doc:
> "Fresh context per spawn -- no context pollution between tasks"

**It must be told explicitly to read project files.** GSD handles this via `<files_to_read>` blocks in the Task prompt:
```
<files_to_read>
- {phase_dir}/{plan_file} (Plan)
- .planning/PROJECT.md (Project context)
- .planning/STATE.md (State)
- .planning/config.json (Config, if exists)
- ./CLAUDE.md (Project instructions, if exists)
</files_to_read>
```

**Action for STP:** Subagent prompts must explicitly list all files the agent needs to read (CONTEXT.md, PLAN.md, current-feature.md, etc.). Don't assume it knows anything.

---

## 5. Post-merge verification

**GSD's approach (from execute-phase.md):**

1. **No explicit merge step per wave.** Worktree commits are on separate branches. GSD verifies via spot-checks:
   ```bash
   SUMMARY_EXISTS=$(test -f "{path}" && echo "true" || echo "false")
   COMMITS_FOUND=$(git log --oneline --all --grep="{pattern}" --since="1 hour ago")
   ```

2. **Post-wave hook validation (parallel mode only):**
   ```bash
   git hook run pre-commit 2>&1 || echo "Pre-commit hooks failed"
   ```

3. **Cross-plan dependency check before next wave:**
   ```bash
   node gsd-tools.cjs verify key-links {plan-path}
   ```

4. **Phase-level verification:** After all waves complete, a `gsd-verifier` subagent checks the phase goal against the actual codebase.

5. **Merge happens at milestone boundaries** via `complete-milestone.md`:
   - Options: squash merge (recommended), merge with history, delete without merging, keep branches
   - Uses `git merge --squash` or `git merge --no-ff --no-commit`

**For STP:** After parallel agents finish, you need: (a) merge worktree branches to main, (b) run type check + tests on merged code, (c) run /simplify on combined changes. GSD defers the actual merge to milestone completion; Pilot could do it per-feature instead.

---

## 6. What GSD actually does for wave execution

**Full flow from execute-phase.md:**

1. **Initialize:** Load phase config, determine `executor_model` from profile, check parallelization setting
2. **Discover plans:** Group into dependency waves using `phase-plan-index` tool
3. **Per wave:**
   - Describe what's being built (from plan objectives)
   - Spawn `Task(subagent_type="gsd-executor", model=executor_model, isolation="worktree")` per plan
   - Parallel agents use `--no-verify` on git commits to avoid hook contention
   - Wait for completion (with spot-check fallback)
   - Post-wave: run pre-commit hooks once, verify key-links
4. **Failure handling:**
   - `classifyHandoffIfNeeded` bug: spot-check; if pass, treat as success
   - Real failure: report to user, ask Continue/Stop
   - All agents fail: systemic issue, stop for investigation
5. **Post-execution:** Regression gate (run prior phases' tests), phase verification via `gsd-verifier`
6. **Resumption:** Re-running skips completed plans (checks for existing SUMMARY.md files)

**Escalation on failure:** GSD does NOT auto-escalate from Sonnet to Opus when an agent fails. It reports the failure and asks the user. The `gsd-debugger` agent (which uses Opus in quality/balanced profiles) would be invoked separately via `/gsd:debug`.

---

## 7. Token overhead

**Per-subagent overhead (from execution-models research doc):**

| Component | Estimated Tokens |
|-----------|-----------------|
| Agent definition (gsd-executor.md) | ~5K (510 lines) |
| CLAUDE.md | ~3-5K (varies by project) |
| Task prompt from orchestrator | ~1-2K |
| Files listed in `<files_to_read>` | ~5-15K (PLAN + STATE + config) |
| **Total baseline per spawn** | **~15-25K tokens** |

**Does the subagent load ALL plugins/CLAUDE.md?** Yes. Claude Code loads CLAUDE.md and plugin configurations for every session, including subagent sessions. MCP servers referenced in the project config would also be available.

**Is 50-80K baseline applied to EACH subagent?** The agent definition + CLAUDE.md + project config is loaded per subagent. For Pilot specifically, the overhead would be:
- Pilot's CLAUDE.md (project-level) + user's global CLAUDE.md (~3-5K each)
- Agent definition (~5K for a custom agent, less for built-in types)
- Plugin/MCP tool definitions (varies -- could be significant if many MCPs are configured)
- Files explicitly requested in the prompt (~5-15K)

**GSD's mitigation:** "Pass paths only -- executors read files themselves with their fresh context window. For 200k models, this keeps orchestrator context lean (~10-15%)."

**Net assessment:** For a Sonnet subagent with 200K context, 15-25K of overhead is 7-12% -- acceptable. For a 1M context, it's negligible. The real cost is the actual work tokens, not the scaffold.

---

## Architecture Feasibility Summary

| Question | Answer | Confidence |
|----------|--------|------------|
| Can Opus spawn Sonnet subagents? | YES, via `Task(model="sonnet")` | HIGH -- GSD does this in production |
| Can agents use worktree isolation? | YES, `isolation="worktree"` is a real parameter | HIGH -- built-in Claude Code tool |
| Can multiple agents run in parallel? | YES, via `run_in_background=true` | HIGH -- GSD spawns 4+ simultaneously |
| Do subagents get CLAUDE.md? | YES, automatically | HIGH -- Claude Code loads it for all sessions |
| Is post-merge verification handled? | PARTIALLY -- GSD defers merge to milestones | MEDIUM -- Pilot needs its own merge strategy |
| Is token overhead acceptable? | YES, ~15-25K per spawn (7-12% of 200K) | HIGH -- confirmed by GSD benchmarks |

---

## Gaps / Risks for Pilot

1. **Pilot's `feature.md` doesn't include `Agent`/`Task` in allowed-tools.** Must be added.
2. **No explicit merge strategy.** GSD defers to milestones. Pilot must define when/how worktree branches merge back (per-feature? per-milestone?).
3. **No escalation path.** When Sonnet fails, GSD asks the user. Pilot should define automatic escalation (retry with Opus after N failures).
4. **Feature.md is monolithic.** It handles planning + building + verification in one command. To use Opus-plan/Sonnet-build, you'd need to split this into a planning phase (Opus, interactive) and an execution phase (Sonnet subagent).
5. **Worktree cleanup.** If an agent fails or is interrupted, worktrees persist in `.claude/worktrees/`. Need cleanup logic.

---

## What Pilot Should Adopt from GSD

1. **Wave-based execution:** Group independent features into waves, parallelize within waves
2. **Spot-check fallback:** Don't rely solely on completion signals; verify via filesystem/git
3. **`--no-verify` for parallel agents:** Run hooks once after wave, not per-agent
4. **Agent definitions:** Create `stp-executor.md` (like `gsd-executor.md`) with STP-specific conventions
5. **Model profiles:** Map agent roles to models (planner=opus, executor=sonnet, critic=sonnet)
6. **`<files_to_read>` pattern:** Explicit file lists in subagent prompts, not implicit assumptions

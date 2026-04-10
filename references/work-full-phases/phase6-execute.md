### Phase 6: EXECUTE — Build, Verify, Ship (fully self-contained — zero references to other commands)

#### 6a. Save Checklist + Start Dev Server

1. Save the plan to `.stp/state/current-feature.md` with the standard checklist format
2. For multi-feature: also save to `.stp/docs/PLAN.md` with wave execution plan
3. Start the dev server if not already running:
```bash
# Stack-appropriate — npm run dev, python manage.py runserver, cargo run, etc.
npm run dev &
```

#### 6b. Foundation First (Opus builds directly)

Opus builds foundational work that every feature depends on:
- Database setup, migrations, schema changes
- Auth/middleware integration (security-critical)
- Core project configuration (CI, deployment, env setup)
- One-line fixes (typo, config change)

Everything else goes to Sonnet executors.

#### 6c. Wave-Based Parallel Execution

**Wave analysis** (from .stp/docs/PLAN.md dependency graph):
- Read each feature's "Create" and "Modify" file lists
- INDEPENDENT features (zero shared files) → same wave (parallel)
- DEPENDENT features → later wave (sequential)

**Spawn parallel Sonnet executor subagents for each wave — NOT Agent Teams:**

> Wave members are intentionally independent (no shared files, no mid-build negotiation). Parallel one-shot subagents via the Task tool are 3–4× cheaper than `TeamCreate` for the same throughput and isolate failures cleanly. See `CLAUDE.md > ## Agent Teams vs Subagents`. Only reach for Agent Teams when workers must SendMessage each other mid-build — not the case here.

> **Profile-aware spawn — MANDATORY.** Use `STP_MODEL_EXECUTOR` (resolved by the Profile Resolution preamble at the top of this command). If `STP_MODEL_EXECUTOR == "inherit"`, OMIT the `model=` parameter entirely. Otherwise pass it.

```
# Spawn ALL wave members in a single message (parallel tool calls). No TeamCreate.
# All current profiles (intended / balanced / budget) resolve STP_MODEL_EXECUTOR to "sonnet":
Agent(
  name="build-[feature-name]",
  subagent_type="stp-executor",
  model="sonnet",
  isolation="worktree",
  run_in_background=true,
  prompt="[focused spec — under 3K tokens]"
)

# Forward-compatible pattern: if STP_MODEL_EXECUTOR ever resolves to "inherit"
# (reserved for future profiles or non-Anthropic runtimes), OMIT the model= param:
Agent(
  name="build-[feature-name]",
  subagent_type="stp-executor",
  isolation="worktree",
  run_in_background=true,
  prompt="[focused spec — under 3K tokens]"
  # NO model param — inherits parent session model
)
```

**Executor prompt must include ONLY:**
- Feature name + 1-line summary
- Exact files to CREATE and MODIFY
- Test cases to write FIRST (executable specs from acceptance criteria)
- Acceptance criteria (from PRD.md)
- 2-3 key patterns to follow (from CONTEXT.md)
- Reference to design-system/MASTER.md if UI work

**Executor prompt must NOT include:**
- Full CONTEXT.md, PLAN.md, or reference files (agent reads these itself)
- MCP tool instructions (executors use only: Read, Write, Edit, Bash, Glob, Grep)

Wait for all subagents → read each structured report → TaskUpdate each to `completed`. Subagents terminate automatically on return — no shutdown, no team cleanup.

**Merge Wave 1** → verify base SHA → merge → verify (type check + ALL tests) → update CONTEXT.md → **then spawn Wave 2.**

> **Pre-merge base check is mandatory** (see 6d). Never `git merge` a worktree branch without confirming its merge-base equals current trunk HEAD — trunk can shift between spawn and merge, and a silent stale-base merge produces green tests over corrupt state.

#### 6d. Review Executor Work

For each executor report:
- Read the report (files created, modified, test count, decisions, issues)
- Review changes: `git diff main...[worktree-branch]`
- Check: does code follow project patterns? Are tests meaningful? Any red flags?
- If issues: fix directly on the branch before merging

Merge — but verify the worktree base FIRST:
```bash
# Pre-merge safety check: confirm worktree is rooted at current trunk.
# Catches the failure mode where trunk moves between spawn and merge —
# without this check, stale work merges silently into a moved trunk.
TRUNK="main"  # adjust per project (master, develop, etc.)
TRUNK_HEAD=$(git rev-parse "$TRUNK")
WORKTREE_BASE=$(git merge-base "$TRUNK" [worktree-branch])
if [ "$WORKTREE_BASE" != "$TRUNK_HEAD" ]; then
  echo "ABORT: [worktree-branch] is not rooted at current $TRUNK ($TRUNK_HEAD)."
  echo "  merge-base = $WORKTREE_BASE — $TRUNK has moved since spawn."
  echo "  Action: rebase the worktree onto $TRUNK, or skip and re-spawn."
  exit 1
fi

git merge [worktree-branch] --no-ff -m "feat: [feature name] (v[VERSION])"
```

After merge: run full type check + ALL tests (not just new ones — catch regressions).

#### 6e. /simplify + Hygiene Scan

Run `/simplify` on combined changes, then scan:
- Remove unused imports, variables, functions
- Remove console.log / print / debug statements
- Remove commented-out code blocks (git has history)
- Remove TODO/FIXME not in PLAN.md
- Check for God files over 300 lines — split them
- Check for duplicate utility functions — consolidate
- Verify .gitignore covers build output, deps, OS files, env files
- Remove empty placeholder files

#### 6f. Review Checkpoint

Show the user what was built:
```
╔═══════════════════════════════════════════════════════╗
║  ✓ FEATURE COMPLETE                                   ║
║  [Feature Name] (v[X.Y.Z])                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Built:                                               ║
║  · [Summary of what the executor created]             ║
║  · [Backward integration changes]                     ║
║                                                       ║
║  What's different now:                                ║
║  · [What the user would SEE in the app]               ║
║                                                       ║
║  Tests    [N] new · [N] total · all passing           ║
║  Types    clean                                       ║
║  Hooks    8/8 gates passed                            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

```
AskUserQuestion(
  question: "Feature checkpoint — review what was built. Continue or flag issues?",
  options: [
    "(Recommended) Looks good, continue",
    "Something is off — let me explain",
    "Chat about this"
  ]
)
```

#### 6g. Independent QA Agent

Spawn the `stp-qa` agent — it has NEVER seen the build process. Use `STP_MODEL_QA` (resolved by the Profile Resolution preamble). If `STP_MODEL_QA == "inherit"`, omit the `model=` parameter; otherwise pass it.
```
Agent(
  name="qa-[feature-name]",
  subagent_type="stp-qa",
  # Conditional: if STP_MODEL_QA != "inherit", add: model="<STP_MODEL_QA>"
  prompt="QA test this feature:
    Feature: [name]
    URL: [where to find it]
    Acceptance criteria (from .stp/docs/PRD.md):
    - AC1: [testable condition]
    - AC2: [testable condition]
    Test: happy path, empty state, validation, error handling, auth, mobile, keyboard.
    Report every bug with reproduction steps."
)
```

- **PASS**: proceed to user QA
- **NEEDS FIXES**: fix every bug, re-spawn QA to verify

#### 6h. Guided Manual QA

Present a test guide to the user:
```
┌─── Manual QA Guide ──────────────────────────────────┐
│                                                       │
│  What was added/changed:                              │
│  · [File 1] — [what it does]                          │
│                                                       │
│  How to see it:                                       │
│  · [Exact command + URL]                               │
│                                                       │
│  Test these scenarios:                                │
│  1. [Happy path — exact steps]                        │
│  2. [Empty state — what shows with no data?]          │
│  3. [Error case — submit without required fields]     │
│  4. [Edge case — long text, special characters]       │
│  5. [Mobile — resize to phone width]                  │
│  6. [Keyboard — Tab through everything]               │
│                                                       │
│  Look for: loading states, disabled buttons,          │
│  helpful error messages                               │
│                                                       │
└──────────────────────────────────────────────────────┘
```

```
AskUserQuestion(
  question: "Manual QA complete — does everything look right?",
  options: [
    "(Recommended) Approved — everything works",
    "Found an issue — here's what's wrong",
    "Need to test more",
    "Chat about this"
  ]
)
```

This is NOT optional. The user must test and approve.

#### 6i. Version Bump + Documentation Update

1. **Bump patch version.** Read `VERSION`, increment patch, write back.
2. **CHANGELOG entry** in .stp/docs/CHANGELOG.md (newest first): summary, changes, tests, decisions, **spec delta** (Added/Changed/Constraints introduced/Dependencies created), stats.
3. **Delta merge-back (MANDATORY).** Merge spec delta into canonical docs:
   - **Added** items → add to ARCHITECTURE.md (new models, routes, components)
   - **Changed** items → update ARCHITECTURE.md (replace outdated assumptions)
   - **Constraints introduced** → add to PRD.md `## System Constraints` section
   - **Dependencies created** → update ARCHITECTURE.md Feature Dependency Map
   - **New SHALL/MUST requirements** → add as Given/When/Then scenarios to PRD.md
   - **Update vs new:** same intent + >50% overlap → update existing scenarios. New intent → add new scenarios. Uncertain → add.
4. **Update .stp/docs/PLAN.md** — mark feature `[x]` with version.
5. **Update .stp/docs/CONTEXT.md** — add new files, schema, routes, patterns, env vars. Keep under 150 lines.
6. **Update README.md** — features, setup, usage, config. Then VERIFY every claim against actual code.
7. **Capture conventions in CLAUDE.md** — if this feature established a pattern that future development must follow, add it to `## Project Conventions`.
8. **Update AUDIT.md** — if bugs were fixed or lessons learned.
9. Delete `.stp/state/current-feature.md` and `.stp/state/handoff.md`.
10. Commit: `feat: [feature name] (v[VERSION])`

#### 6j. Milestone Check (Automatic)

After completing a feature, check PLAN.md: **is this the last feature in the current milestone?**

If YES:
1. **Bump minor version** (reset patch: 0.1.3 → 0.2.0)
2. **Integration verification** — write and run E2E tests for the milestone's primary workflow
3. **Critic evaluation (Double-Check Protocol):**

   **Profile-aware critic spawn.** Use `STP_MODEL_CRITIC` and `STP_MODEL_CRITIC_ESCALATION` (both resolved by the Profile Resolution preamble). In **budget-profile** the critic resolves to `haiku` for a fast pass; if Haiku flags ≥2 critical issues OR any FAIL, automatically re-spawn with `STP_MODEL_CRITIC_ESCALATION` (= sonnet) for the full Double-Check Protocol. In **intended-profile** and **balanced-profile** there's no escalation — the first call already uses sonnet.

```
# First pass — uses STP_MODEL_CRITIC
Agent(
  name="critic-milestone",
  subagent_type="stp-critic",
  # Conditional: if STP_MODEL_CRITIC != "inherit", add: model="<STP_MODEL_CRITIC>"
  prompt="Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum + claim verification.
  1. Restate the goal, 2. Define 'complete', 3. List angles, 4. Iteration 1, 5. Iteration 2, 5.5. Verify Behavioral Claims (trace execution paths for any 'broken/fails/doesn't work' finding — downgrade unreachable code from FAIL to NOTE), 6. Synthesize.
  Grade against .stp/docs/PRD.md + .stp/docs/PLAN.md + 7 criteria + 6-layer verification.
  Run specification verification, test quality analysis, and mutation challenge.
  Flag NET-NEW GAPS: features where infrastructure exists but no UI/API/purchase flow was wired."
)
```

**Budget-profile escalation logic** (only relevant if `STP_MODEL_CRITIC == "haiku"`):
```bash
# After the Haiku critic returns, parse its report.
# IMPORTANT: use the v0.3.7-fixed grep -c pattern. The naive form
#   COUNT=$(grep -c PATTERN FILE 2>/dev/null || echo 0)
# is broken because grep prints "0" before exiting non-zero on no-match,
# so the `|| echo 0` APPENDS rather than replaces, producing "0\n0".
# Always use the assignment-then-default form.
CRITIC_REPORT=$(ls -t .stp/state/critic-report-*.md 2>/dev/null | head -1)
if [ -n "$CRITIC_REPORT" ] && [ "$STP_MODEL_CRITIC" = "haiku" ]; then
  CRITICAL_COUNT=$(grep -c "^\(CRITICAL\|FAIL\)" "$CRITIC_REPORT" 2>/dev/null); CRITICAL_COUNT=${CRITICAL_COUNT:-0}
  if [ "$CRITICAL_COUNT" -ge 2 ]; then
    echo "Haiku flagged $CRITICAL_COUNT critical issues — escalating to $STP_MODEL_CRITIC_ESCALATION for full Double-Check Protocol"
    # Re-spawn the same agent with the escalation model:
    #
    # Agent(
    #   name="critic-milestone-escalated",
    #   subagent_type="stp-critic",
    #   model="<STP_MODEL_CRITIC_ESCALATION>",   # = "sonnet"
    #   prompt="<same prompt as Pass 1, plus: 'Pass 1 by Haiku flagged $CRITICAL_COUNT critical issues. Run the FULL Double-Check Protocol with deep behavioral verification.'>"
    # )
  fi
fi
```
4. **Milestone CHANGELOG entry** with Critic evaluation results
5. **Cross-family review** for security-critical code (if non-Claude models available)
6. Present Critic report + next milestone to user

**After everything is built:**

```
╔═══════════════════════════════════════════════════════╗
║  ✓ DEVELOPMENT COMPLETE                               ║
║  [Feature Name]   v[X.Y.Z]                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Built          [summary]                             ║
║  Approach       [what was chosen]                     ║
║  Files          [N] created · [N] modified            ║
║  Tests          [N] spec · [N] behavioral ·           ║
║                 [N] property · [N] integration        ║
║  Types          clean                                 ║
║                                                       ║
║  Conventions    [N] new rules in CLAUDE.md            ║
║  Critic         [PASS/NEEDS WORK/FAIL]                ║
║  Cross-family   [done/skipped]                        ║
║  AUDIT.md       [updates made]                        ║
║  ARCHITECTURE   [sections updated]                    ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## Autopilot Mode

When `/stp:autopilot` runs this flow, it operates with these overrides:

| Phase | Interactive mode | Autopilot mode |
|-------|-----------------|----------------|
| Phase 1: Understand | AskUserQuestion | AI interprets from the description. If ambiguous, picks the broadest reasonable scope. |
| Phase 2: Context | Same | Same |
| Phase 3: Tools | AskUserQuestion to install | Auto-install recommended tools. Skip if installation requires interactive auth. |
| Phase 4: Research | AskUserQuestion for approach | AI picks the recommended approach. Logs the decision in the plan. |
| Phase 5: Plan | AskUserQuestion to approve | AI approves its own plan. Logs: "Auto-approved in autopilot mode." |
| Phase 6: Execute | User QA step | Skip user QA. Automated QA agent only. |

The key rule for autopilot: **always pick the recommended option.** Every AskUserQuestion in this flow has a "(Recommended)" choice — autopilot selects it automatically. If no recommendation is clear, pick the safest/most conventional option.

## Rules

- This is the FULL cycle. Do NOT skip phases. Phase 3 (Tools) is new and critical — missing tools mid-build wastes time.
- AskUserQuestion is MANDATORY for all decisions (use the tool, not text).
- The plan from Phase 5 MUST be compatible with /stp:work-quick's checklist format.
- If the user says "just build it" during Phase 1-4, redirect: "Let me finish the investigation — 10 more minutes of research prevents days of rework."
- For multi-feature work, create milestones in .stp/docs/PLAN.md. For single features, use .stp/state/current-feature.md.
- Phase 3 (Tools) should be FAST — check, suggest, install, move on. Don't spend 10 minutes researching tools.
- If a tool installation requires session restart, save ALL progress to handoff.md. Nothing gathered in Phases 1-3 should be lost.
- Read ARCHITECTURE.md in Phase 2 AND Phase 5. Phase 2 for understanding; Phase 5 for planning the changes.
- Every AskUserQuestion must have a "(Recommended)" option for autopilot compatibility.

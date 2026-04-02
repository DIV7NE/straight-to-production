---
description: Build a feature autonomously. Opus makes all technical decisions, only asks product questions, and teaches key concepts along the way. Use before starting any non-trivial feature.
argument-hint: What you want (e.g., "add Stripe payments" or "build the user dashboard")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

# Pilot: Feature Builder

You are building a feature using test-driven development. Tests come BEFORE implementation. Make all technical decisions. Only interrupt the user for PRODUCT decisions. Teach key concepts along the way.

## Process

### Step 1: Context

Read PLAN.md for this feature's requirements, test cases, and dependencies. Read CLAUDE.md for stack patterns. Check existing code for established patterns.

If PLAN.md exists and this feature is listed, use the plan's test cases and dependencies. If PLAN.md doesn't exist or this feature isn't in it, create the plan inline (but recommend running `/pilot:plan` first for complex projects).

If `.pilot/current-feature.md` already exists, ask: "You have an in-progress feature: [title]. Finish that first, or start this new one?"

### Step 2: Impact Analysis (BEFORE building)

Read CONTEXT.md and PLAN.md's Feature Touchpoint Map. Answer these questions:

**What existing features does this new feature touch?**
- Which existing pages need to show data from this feature?
- Which existing API endpoints need to return this feature's data?
- Does the dashboard need updating?
- Does navigation need a new link?
- Does search need to index this?
- Do notifications need to include this?

**What existing code needs backward integration?**
- List every file that needs modification to CONNECT to this new feature
- These become checklist items alongside the new feature's tasks

**What could break?**
- Which existing tests might fail after this change?
- Which existing features share database tables or API endpoints?

Teach: "Before building something new, I check what ALREADY EXISTS that should connect to it. If I add Purchase Orders but don't update the Dashboard to show them and don't update the Supplier page to list order history, the app works but feels disconnected. So I plan the connections upfront."

### Step 3: Enrich

Based on the impact analysis and PLAN.md, identify what the user DIDN'T think of. Read relevant `.pilot/references/` files.

Ask at most ONE product question if a real product decision is needed. If no product decision is needed, skip to the plan.

For significant technical decisions, briefly note them with industry backing.

### Step 4: Present Feature Plan

```
## Feature: [Name]

### What you asked for
[1-2 sentences restating their request in plain language]

### What I'm adding (things you'd miss)
- [ ] [Concern — why it matters to your USERS, one line]
- [ ] [Concern — why it matters to your USERS, one line]

### Impact on existing features (backward integration)
- [ ] [Update: existing page/component — what changes]
- [ ] [Update: existing page/component — what changes]
(These are just as important as the new feature itself.)

### Key decisions
[Brief note on any significant tech choices, with who uses it and why.
Skip this section if no notable decisions beyond what's in CLAUDE.md.]

### Tests to write FIRST
- [ ] [Test case 1 from PLAN.md or identified during enrichment]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Build order (8-layer Definition of Done)
1. [Database — migrations, schema changes]
2. [Write tests FIRST (TDD)]
3. [API / server logic — endpoints, server actions, validation]
4. [Business logic — core feature functionality, make tests pass]
5. [UI — pages, components, forms, connected to API]
6. [Error/edge cases — error handling, loading states, empty states]
7. [Backward integration — update existing features to connect]
8. [Polish — accessibility, /simplify, verify acceptance criteria from PRD]

### Acceptance criteria (from PRD.md)
- [ ] [AC 1 — testable condition that defines "done"]
- [ ] [AC 2 — testable condition]

### Standards I'll check
- .pilot/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

### Step 5: Build (Opus plans, Sonnet builds)

When the user says go:

1. Save the checklist to `.pilot/current-feature.md`

2. **Decide: build directly or delegate.**
   - **Simple task** (1-2 files, quick fix, refactor): Opus builds directly. No subagent overhead.
   - **Standard feature** (3+ files, new functionality): Spawn `pilot-executor` (Sonnet) subagent.
   - **Multiple independent features** in same milestone: Spawn multiple executors in parallel.

3. **For delegated builds — spawn the executor:**

   Compose a focused prompt for the `pilot-executor` agent. Include:
   - Feature name and 1-line summary
   - Exact files to create (from the checklist's 8-layer build order)
   - Exact files to modify (including backward integration)
   - Test cases to write FIRST
   - Acceptance criteria
   - Key patterns to follow (from CONTEXT.md — don't paste the whole file, just the relevant patterns)

   ```
   Agent(
     subagent_type="pilot-executor" or just use the general-purpose agent,
     model="sonnet",
     isolation="worktree",
     run_in_background=false (for single feature) or true (for parallel),
     prompt="[the focused spec above]"
   )
   ```

   **200K context budget for Sonnet.** Keep the prompt under 3K tokens. The executor reads CONTEXT.md + CLAUDE.md itself (they load automatically). Don't paste full file contents — just tell it which files to read.

   Teach: "I'm handing this to a builder agent — it works in its own isolated copy of the code so nothing interferes. It'll write the tests first, then implement, then report back. I'll review its work before merging it into the project."

4. **For parallel builds — maximize safe parallelism.**

   Analyze the milestone's remaining features using PLAN.md's Feature Touchpoint Map and dependency graph. Group them into **waves**:

   **Wave analysis:**
   - Read each feature's "Create" and "Modify" file lists from PLAN.md
   - Two features are INDEPENDENT if they share ZERO files to create or modify
   - Features that depend on each other go in LATER waves
   - Features that modify shared files (e.g., both update the dashboard) go in separate waves

   **Spawn ALL independent features in the wave simultaneously:**
   ```
   # Wave 1: all independent features (no limit — spawn as many as are safe)
   Agent("pilot-executor", model="sonnet", isolation="worktree", run_in_background=true, name="feature-4")
   Agent("pilot-executor", model="sonnet", isolation="worktree", run_in_background=true, name="feature-5")
   Agent("pilot-executor", model="sonnet", isolation="worktree", run_in_background=true, name="feature-6")
   Agent("pilot-executor", model="sonnet", isolation="worktree", run_in_background=true, name="feature-7")
   Agent("pilot-executor", model="sonnet", isolation="worktree", run_in_background=true, name="feature-8")
   # ... as many as are truly independent
   ```

   Wait for all to complete. Each works on its own git branch.

   **Then merge Wave 1** → verify → update CONTEXT.md → **then spawn Wave 2.**
   
   Wave 2 features DEPEND on Wave 1 — they MUST wait. Never spawn a dependent feature in parallel with its dependency. The dependency chain from PLAN.md is the law. If Feature 7 depends on Feature 4, Feature 7 cannot start until Feature 4 is merged and verified.

   **Present the wave plan to the user:**
   ```
   ━━━ Parallel Build Plan ━━━

   Wave 1 (parallel — [N] agents):
   - Feature 4: [name] — [files it touches]
   - Feature 5: [name] — [files it touches]
   - Feature 6: [name] — [files it touches]

   Wave 2 (after Wave 1 merges — depends on Wave 1):
   - Feature 7: [name] — depends on Feature 4
   - Feature 8: [name] — depends on Feature 5

   Launching Wave 1...
   ```

   Teach: "I'm building [N] features simultaneously — each agent works in its own isolated copy of the code. They can't interfere with each other because they each have their own branch. I'll merge them one by one and verify after each merge that everything still works together."

5. **Review the executor's work.**

   When the executor reports back:
   - Read its report (files created, files modified, test count, decisions, issues)
   - Review the changes: `git diff main...[worktree-branch]`
   - Check: does the code follow project patterns? Are tests meaningful? Any red flags?
   - If issues: fix them directly on the branch before merging

6. **Merge and verify.**

   ```bash
   git merge [worktree-branch] --no-ff -m "feat: [feature name] (v0.1.3)"
   ```

   After merge, run full verification:
   - Type check (the stack's checker — tsc, mypy, cargo check, etc.)
   - Run ALL tests (not just new ones — catch regressions)
   - If merge conflicts: resolve them, re-run tests

   For parallel merges: merge one branch at a time, verify after each.

7. **Post-merge polish.**
   - Run `/simplify` on the combined changes
   - Teach: "I'm running /simplify on the merged code — it catches any duplication or inconsistency that happened between the parallel builds."

8. **Review checkpoint.**
   Show the user what was built:
   ```
   ━━━ Feature complete: [Name] ━━━

   What was built:
   - [Summary of what the executor created]
   - [Backward integration changes]

   What's different now:
   [What the user would SEE in the app]

   Tests: [N] new, [N] total, all passing
   Type check: clean

   Does this look right?
   ```

   If the user flags issues, fix them before proceeding.

**Fallback:** If the Sonnet executor gets stuck (reports errors it can't fix, or the merge has complex conflicts), Opus takes over and builds directly. Don't waste time — if delegation fails, do it yourself.

### Step 6: Complete Feature + Version Bump

1. **Bump patch version.** Read `VERSION` file (e.g., `0.1.2`), increment patch → `0.1.3`, write back.

2. **Add CHANGELOG entry.** Prepend to CHANGELOG.md (newest first, below header):
   ```markdown
   ## [0.1.3] — [DATE] — Feature: [Feature Name]
   
   [1-2 sentence summary of what was built]
   
   ### Changes
   - [File created/modified — what it does]
   - [File created/modified — what it does]
   
   ### Tests Added
   - [Test file] — [what it covers] ([N] tests)
   
   ### Decisions Made
   - [Any technical decisions during this feature — why, alternatives]
   
   ### Stats
   - Tests: [N] passing
   - Type check: clean
   ```

3. **Update PLAN.md:**
   - Mark this feature `[x]` with version: `- [x] 3. Ingredient CRUD (v0.1.3)`
   - If this feature was NOT in the original plan (unplanned work), ADD it to the appropriate milestone with `[x]` already checked, and update the Feature Touchpoint Map to include it. PLAN.md must reflect ALL features that exist, not just originally planned ones.

4. Update PRD.md Technical Decisions Log if significant decisions were made.

5. **Update CONTEXT.md** — reflect the current state of the codebase after this feature:
   - Add new files to the file map (with 1-line purpose each)
   - Update data schema if new tables/columns were added
   - Update API endpoints if new routes were created
   - Update patterns section if new conventions were established
   - Update environment variables if new ones are required
   - **Add any deferred issues to Known Issues / Tech Debt** — if /simplify flagged something unfixable, if you noticed something suboptimal but out of scope, or if the Critic previously flagged something the user said "fix later" — record it here so it's not forgotten.
   
   CONTEXT.md is a SNAPSHOT of what exists NOW — not history. Replace outdated info, don't append. Keep it under 150 lines.

6. Delete `.pilot/current-feature.md` and `.pilot/handoff.md` if they exist.
7. Commit: `feat: [feature name] (v0.1.3)`

### Step 7: Milestone Check (Automatic)

After completing a feature, check PLAN.md: **is this the last feature in the current milestone?**

If YES — this milestone is complete:

**1. Bump minor version.** Reset patch: `0.1.3` → `0.2.0`. Write to VERSION.

**2. Integration Verification**
Test that features within this milestone work TOGETHER, not just individually.

Write and run integration/E2E tests for the milestone's primary workflow. Commit them.

**3. Automatic Critic Evaluation**
Spawn the `pilot-critic` agent automatically. Grade against PRD.md + PLAN.md + 6 criteria. Present results.

**4. Milestone CHANGELOG entry.** Add a milestone summary entry:
   ```markdown
   ## [0.2.0] — [DATE] — Milestone 2: [Milestone Name]
   
   ### Summary
   [2-3 sentences: what this milestone achieved, what the app can now do]
   
   ### Features Included
   - v0.1.4: [Feature name]
   - v0.1.5: [Feature name]
   - v0.1.6: [Feature name]
   
   ### Critic Evaluation
   - Functionality: [PASS/PARTIAL/FAIL]
   - Design: [PASS/PARTIAL/FAIL]
   - Security: [PASS/PARTIAL/FAIL]
   - Accessibility: [PASS/PARTIAL/FAIL]
   - Performance: [PASS/PARTIAL/FAIL]
   - Production: [PASS/PARTIAL/FAIL]
   
   ### Integration Tests
   - [Workflow tested] — PASS
   
   ### Key Decisions This Milestone
   - [Decision — why]
   ```

5. **Full CONTEXT.md refresh.** At milestone boundaries, do a complete rewrite of CONTEXT.md — don't just incrementally update. Re-read the entire codebase and regenerate:
   - Full file map (every significant file with purpose)
   - Current data schema (all tables/models as they exist NOW)
   - All API endpoints (with auth requirements)
   - Current patterns and conventions
   - All environment variables
   - Update version number in the header
   
   This ensures CONTEXT.md stays accurate as the codebase grows. Incremental updates during features can miss renames, deletions, or structural changes. The milestone refresh catches everything.

6. Commit: `milestone: [milestone name] (v0.2.0)`
7. Git tag: `git tag v0.2.0`

Then:

```
━━━ Milestone [N] complete ━━━

[N] features built. Integration tests passing.

Critic Report:
[Summary of 6-criteria evaluation]

Priority fixes (if any):
1. [Most critical]
2. [Second]

Fix these now? Or continue to Milestone [N+1]:
   /pilot:feature [FIRST FEATURE of next milestone]
```

If this is the **LAST milestone** (all milestones complete):
```
━━━ ALL MILESTONES COMPLETE ━━━

[Total features] built. [Total tests] passing. Integration verified.

Critic Report:
[Summary of final 6-criteria evaluation]

Priority fixes (if any):
1. [Most critical]
2. [Second]

Your project is feature-complete per the PRD.
Fix any remaining issues, then you're ready to deploy.
```

If NO — more features remain in this milestone:

```
Feature complete: [NAME]
[N] of [M] features done in Milestone [current].

━━━ Next ━━━
/pilot:feature [NEXT FEATURE in this milestone]
```

ALWAYS fill in specific names.

## Gotchas

- Do NOT ask technical questions. You decide.
- ALWAYS save the checklist to `.pilot/current-feature.md` — this survives compaction.
- Do NOT over-scope. "Add a settings page" doesn't mean also add admin tools, themes, and notifications.
- DO check if patterns already exist in the codebase. Follow established patterns.
- DO read reference files before implementing security, accessibility, or performance-sensitive code.
- Keep teach moments to 2-3 sentences. Explain the concept, not the implementation.
- The milestone check is AUTOMATIC — don't ask the user if they want it. Just do it. Quality isn't optional.

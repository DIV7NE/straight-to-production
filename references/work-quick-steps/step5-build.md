### Step 5: Build (Opus plans, Sonnet builds)

When the user says go:

1. Save the checklist to `.stp/state/current-feature.md`

2. **ALWAYS delegate to Sonnet executor.** This is NOT optional. You are the CTO — you plan, review, and merge. You do NOT write implementation code yourself.

   **The ONLY exception** where Opus builds directly:
   - A one-line fix (typo, config change, version bump)
   - That's it. Everything else goes to the executor.

   Why: Sonnet 4.6 is 40% cheaper with near-identical code quality (79.6% vs 80.8% SWE-bench). You burn tokens on THINKING work (research, architecture, review). Implementation is Sonnet's job.

   **Exceptions where Opus builds directly (foundation work):**
   - Database setup, migrations, schema changes (shapes everything downstream)
   - Auth/middleware integration (security-critical, must be right)
   - Core project configuration (CI, deployment, env setup)
   - One-line fixes (typo, config change, version bump)

   These are foundational — every executor depends on them being correct. Opus builds these, then delegates features on top.

   **For each feature ON TOP of foundation:** Spawn Sonnet executor with worktree isolation.
   **For multiple independent features:** Spawn parallel one-shot subagents (Task tool) — NOT Agent Teams. Wave members are independent and share nothing mid-build; parallel `Agent()` spawns are 3–4× cheaper and simpler. See `CLAUDE.md > ## Agent Teams vs Subagents`.

3. **Plan the wave and spawn parallel builders.**

   Spawn one Sonnet executor per wave feature in parallel via the Task tool. Each runs in an isolated worktree, reports back when done, and terminates. No team lifecycle.

   **Wave analysis first** (from .stp/docs/PLAN.md's dependency graph):
   - Read each feature's "Create" and "Modify" file lists
   - INDEPENDENT features (zero shared files) → same wave (parallel)
   - DEPENDENT features → later wave (sequential)
   - Features modifying shared files → separate waves

   **Present the wave plan to the user via AskUserQuestion:**
   ```
   AskUserQuestion(
     question: "Wave 1: [N] features can build in parallel. Wave 2: [N] depend on Wave 1. Launch?",
     options: [
       "(Recommended) Launch Wave 1 — [N] parallel agents",
       "Build one at a time instead",
       "Chat about this"
     ]
   )
   ```

   **Spawn parallel builders (single message, multiple Agent tool calls):**

   > **Profile-aware spawn — MANDATORY.** Use `STP_MODEL_EXECUTOR` (resolved by the Profile Resolution preamble). If `STP_MODEL_EXECUTOR == "inherit"`, OMIT the `model=` parameter entirely. Otherwise pass it.

   ```
   # All current profiles (intended / balanced / budget) resolve STP_MODEL_EXECUTOR to "sonnet".
   # Spawn ALL wave members in a single message — parallel tool calls, NO TeamCreate.
   Agent(
     name="build-[feature-name]",
     subagent_type="stp-executor",
     model="sonnet",
     isolation="worktree",
     run_in_background=true,
     prompt="[focused spec — see below]"
   )
   # ... repeat (in the SAME message) for every feature in the wave

   # Forward-compatible: if STP_MODEL_EXECUTOR ever resolves to "inherit"
   # (reserved for future profiles / non-Anthropic runtimes), OMIT the model= param.
   ```

   **200K context budget — keep each agent LEAN:**

   Each executor prompt must be under 3K tokens. Include ONLY:
   - Feature name + 1-line summary
   - Exact files to CREATE (from .stp/docs/PLAN.md)
   - Exact files to MODIFY (including backward integration)
   - Test cases to write FIRST
   - Acceptance criteria (from .stp/docs/PRD.md)
   - 2-3 key patterns to follow (extracted from .stp/docs/CONTEXT.md — NOT the whole file)

   Do NOT include in the prompt:
   - Full .stp/docs/CONTEXT.md (the agent reads it itself — it loads with CLAUDE.md automatically)
   - Full .stp/docs/PLAN.md (only the relevant feature spec)
   - Reference files (the agent reads .stp/references/ only if needed)
   - Any MCP tool instructions (executors don't use Context7, Tavily, or research tools)
   - Any plugin/skill context (executors just build — Read, Write, Edit, Bash, Glob, Grep only)

   **Agent isolation — keep them clean:**
   - Executors do NOT use MCP servers (no Context7, no Tavily, no Neon, no Stripe)
   - Executors do NOT invoke skills or plugins
   - Executors do NOT spawn sub-agents of their own
   - Executors use ONLY: Read, Write, Edit, Bash, Glob, Grep
   - This keeps their 200K context free for actual code work

     ┊ Launching parallel builder subagents — each in its own isolated copy of the code. They can't interfere with each other. I'll review and merge their work when they're done.

   **Wait for all subagents to complete.** Each one returns a structured report and terminates automatically — no shutdown, no team cleanup. As each reports back:
   - Read their structured report (files, tests, decisions, issues)
   - TaskUpdate the corresponding task to `completed`

   **Merge Wave 1** → verify (type check + ALL tests) → update .stp/docs/CONTEXT.md → **then spawn Wave 2.**

   Wave 2 features DEPEND on Wave 1 — they MUST wait. Never spawn a dependent feature in parallel with its dependency. The dependency chain from .stp/docs/PLAN.md is the law.

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

8. **Hygiene scan.** (read `.stp/references/production/code-hygiene.md` for the full checklist)
   - Remove any unused imports, variables, functions
   - Remove any console.log / print / debug statements
   - Remove any commented-out code blocks (git has the history)
   - Remove any TODO/FIXME that aren't in .stp/docs/PLAN.md
   - Check for God files over 300 lines — split them
   - Check for duplicate utility functions — consolidate
   - Verify no .md files were scattered in random places (plans go in .stp/docs/PLAN.md only)
   - Verify .gitignore covers build output, deps, OS files, env files
   - Remove any empty placeholder files
   
     ┊ Hygiene scan — cleaning up the garbage that accumulates during building. Unused imports, debug logging, commented-out code. Like washing dishes after cooking.

9. **Review checkpoint.**
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

   AskUserQuestion(
     question: "Feature checkpoint — review what was built. Continue or flag issues?",
     options: [
       "(Recommended) Looks good, continue",
       "Something is off — let me explain",
       "Chat about this"
     ]
   )
   ```

   If the user flags issues, fix them before proceeding.

10. **Independent QA — separate agent tests the running app.**

   Same principle as the Critic: the builder should NOT QA its own work. Spawn the `stp-qa` agent — it has NEVER seen the build process and tests purely against acceptance criteria.

   First, ensure the dev server is running:
   ```bash
   # Start if not already running (stack-appropriate)
   npm run dev &  # or python manage.py runserver, cargo run, etc.
   ```

   Then spawn the QA agent. Use `STP_MODEL_QA` (resolved by the Profile Resolution preamble). If `STP_MODEL_QA == "inherit"`, omit the `model=` parameter; otherwise pass it.
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

   When the QA agent reports back:
   - **PASS**: proceed to user QA
   - **NEEDS FIXES**: fix every bug found, then re-spawn QA to verify fixes

   Present the QA report to the user:
   ```
   ┌─── QA Report ────────────────────────────────────────┐
   │  ✓ AC1: User can create invoice                      │
   │  ✓ AC2: Invoice shows in list                        │
   │  ✗ Empty state: blank page instead of prompt → FIXED │
   │  ✓ Auth: redirects without login                     │
   │  ✓ Mobile: works at 375px                            │
   │                                                       │
   │  Result: ALL PASS (1 fixed during QA)                │
   └──────────────────────────────────────────────────────┘
   ```

     ┊ A separate QA tester checked the feature — it hasn't seen how the code was written, so it tests like a real user would. Fresh eyes catch more bugs.

11. **Guided Manual QA — the user tests the feature.**

   Automated tests prove the CODE works. Independent QA proves the FEATURES work. Manual QA proves the PRODUCT feels right. Present a test guide:

   ```
   ┌─── Manual QA Guide ──────────────────────────────────┐
   │                                                       │
   │  What was added/changed:                              │
   │  · [File 1] — [what it does, in plain language]       │
   │  · [File 2] — [what changed]                          │
   │                                                       │
   │  How to see it:                                       │
   │  · [Exact command: npm run dev, etc.]                  │
   │  · [Exact URL or screen to navigate to]                │
   │                                                       │
   │  Test these scenarios:                                │
   │  1. [Happy path] — click X, type Y, expect Z         │
   │  2. [Empty state] — page with no data                │
   │  3. [Error case] — submit without required fields     │
   │  4. [Edge case] — very long text, special chars       │
   │  5. [Mobile] — resize to phone width                  │
   │  6. [Keyboard] — Tab through the feature              │
   │                                                       │
   │  Look for:                                            │
   │  · Loading indicator while data loads?                │
   │  · Buttons disable during submission?                 │
   │  · Error messages helpful (not jargon)?               │
   │  · Does it feel right? (trust your gut)               │
   │                                                       │
   └──────────────────────────────────────────────────────┘

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

   This is NOT optional. The user must test and approve before the feature is marked done.
   
   If the user finds issues:
   - Fix each one
   - Re-run affected tests
   - Show the user the fix
   - Ask them to re-test that specific scenario
   
     ┊ Even though all automated tests pass, YOU need to use the feature. Tests check if code works — but can't tell if the flow is confusing or something feels off. Your eyes catch what code can't.

**Fallback:** If the Sonnet executor gets stuck (reports errors it can't fix, or the merge has complex conflicts), Opus takes over and builds directly. Don't waste time — if delegation fails, do it yourself.

### Step 6: Complete Feature + Version Bump

1. **Bump patch version.** Read `VERSION` file (e.g., `0.1.2`), increment patch → `0.1.3`, write back.

2. **Add CHANGELOG entry.** Prepend to .stp/docs/CHANGELOG.md (newest first, below header):
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
   
   ### Spec Delta
   - **Added:** [new models, routes, integrations, patterns that didn't exist before]
   - **Changed:** [existing assumptions this feature invalidated or replaced]
   - **Constraints introduced:** [new rules the system must now follow]
   - **Dependencies created:** [what now depends on this feature]
   
   ### Stats
   - Tests: [N] passing
   - Type check: clean
   ```

3. **Delta merge-back (MANDATORY).** After writing the spec delta to CHANGELOG, merge changes into canonical docs:
   - **Added** items → add to ARCHITECTURE.md (new models, routes, components sections)
   - **Changed** items → update ARCHITECTURE.md (replace outdated assumptions, not append)
   - **Constraints introduced** → add to PRD.md `## System Constraints` section
   - **Dependencies created** → update ARCHITECTURE.md Feature Dependency Map
   - **If new SHALL/MUST requirements emerged** → add as structured Given/When/Then scenarios to PRD.md
   
   **Update vs new change heuristic:** If this feature modifies an existing spec (same intent, >50% overlap with existing scenarios), UPDATE the existing scenarios in PRD.md. If it's net-new intent, ADD new scenarios. When uncertain, ADD (safer).

4. **Update .stp/docs/PLAN.md:**
   - Mark this feature `[x]` with version: `- [x] 3. Ingredient CRUD (v0.1.3)`
   - If this feature was NOT in the original plan (unplanned work), ADD it to the appropriate milestone with `[x]` already checked, and update the Feature Touchpoint Map to include it. .stp/docs/PLAN.md must reflect ALL features that exist, not just originally planned ones.

5. Update .stp/docs/PRD.md Technical Decisions Log if significant decisions were made. If new structured scenarios emerged during building, add them to the appropriate SPEC section.

6. **Update .stp/docs/CONTEXT.md** — reflect the current state of the codebase after this feature:
   - Add new files to the file map (with 1-line purpose each)
   - Update data schema if new tables/columns were added
   - Update API endpoints if new routes were created
   - Update patterns section if new conventions were established
   - Update environment variables if new ones are required
   - **Add any deferred issues to Known Issues / Tech Debt** — if /simplify flagged something unfixable, if you noticed something suboptimal but out of scope, or if the Critic previously flagged something the user said "fix later" — record it here so it's not forgotten.
   
   .stp/docs/CONTEXT.md is a SNAPSHOT of what exists NOW — not history. Replace outdated info, don't append. Keep it under 150 lines.

7. **Update .stp/docs/ARCHITECTURE.md** (if it exists) — incremental update:
   - Add new models/tables to the Data Models section
   - Add new routes to the API/Page Routes section
   - Add new components to the Components section
   - Update the Feature Dependency Map if this feature creates new dependencies
   - If a bug was fixed that was tracked in AUDIT.md, mark it resolved there too

   Don't rewrite the whole file — just add/update the sections affected by this feature.

8. **Capture project conventions in CLAUDE.md.** After building, ask yourself: did this feature establish a pattern that future development must follow?

   If YES, append to the `## Project Conventions` section:
   ```markdown
   - **[Rule name]**: [What to always/never do]
     - Why: [The reason — a decision, a bug prevention, a pattern that works]
     - Applies when: [When a developer should think of this rule]
     - Added: [DATE] via /stp:work-quick [feature name]
   ```

   Examples of conventions worth capturing:
   - "All API routes use `withOrgAuth()` wrapper — never raw `auth()`" (pattern established)
   - "Invoice calculations go through `calcEngine.ts` — never inline math" (centralization decision)
   - "React Query keys follow `[entity, action, params]` format" (naming convention)
   - "File uploads validate MIME type server-side, not just extension" (security pattern)

   NOT every feature creates a convention. Only add rules that are:
   - **Generalizable** — applies beyond this one feature
   - **Non-obvious** — someone new wouldn't know this without being told
   - **Important** — violating it would cause bugs, inconsistency, or security issues

9. **Update README.md — MANDATORY after EVERY feature.** The project README must always reflect the current state. Update:
   - Feature list / what the app does (if this feature adds visible capability)
   - Setup/install instructions (if dependencies or steps changed)
   - Usage instructions (if new commands, endpoints, or workflows were added)
   - Configuration (if new env vars, config files, or options were added)
   - Architecture section (if project structure changed significantly)
   
   **Then VERIFY the README is accurate:**
   - Every setup command listed in README — run it mentally. Would it work on a fresh clone?
   - Every feature claimed — does it actually exist in the code?
   - Every env var listed — is it real and documented in .env.example?
   - Every endpoint/route documented — does it match what's actually implemented?
   - If README says "supports X" — verify X actually works, don't just trust what was written before
   
   A README that doesn't match the code is WORSE than no README — it wastes the user's time with wrong instructions.

10. Delete `.stp/state/current-feature.md` and `.stp/state/handoff.md` if they exist.
11. Commit: `feat: [feature name] (v0.1.3)`

### Step 7: Milestone Check (Automatic)

After completing a feature, check .stp/docs/PLAN.md: **is this the last feature in the current milestone?**

If YES — this milestone is complete:

**1. Bump minor version.** Reset patch: `0.1.3` → `0.2.0`. Write to VERSION.

**2. Integration Verification**
Test that features within this milestone work TOGETHER, not just individually.

Write and run integration/E2E tests for the milestone's primary workflow. Commit them.

**3. Automatic Critic Evaluation (Double-Check Protocol)**
Spawn the `stp-critic` agent with the Double-Check Protocol enforced:
```
Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum + claim verification.
1. Restate the goal, 2. Define "complete", 3. List angles, 4. Iteration 1, 5. Iteration 2, 5.5. Verify Behavioral Claims (trace execution paths for any "broken/fails/doesn't work" finding — downgrade unreachable code from FAIL to NOTE), 6. Synthesize.
Grade against .stp/docs/PRD.md + .stp/docs/PLAN.md + 7 criteria.
Flag NET-NEW GAPS: features where infrastructure exists but no UI/API/purchase flow was wired.
```
Present results including the Verified Complete table and any net-new gaps found.

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

5. **Full .stp/docs/CONTEXT.md refresh.** At milestone boundaries, do a complete rewrite of .stp/docs/CONTEXT.md — don't just incrementally update. Re-read the entire codebase and regenerate:
   - Full file map (every significant file with purpose)
   - Current data schema (all tables/models as they exist NOW)
   - All API endpoints (with auth requirements)
   - Current patterns and conventions
   - All environment variables
   - Update version number in the header
   
   This ensures .stp/docs/CONTEXT.md stays accurate as the codebase grows. Incremental updates during features can miss renames, deletions, or structural changes. The milestone refresh catches everything.

6. **Full .stp/docs/ARCHITECTURE.md refresh** (if it exists). Same principle as CONTEXT.md — complete rewrite at milestones:
   - Re-scan all models, routes, pages, components
   - Rebuild the Feature Dependency Map
   - Update integrations and state management sections
   - Verify accuracy with spot-checks (same as onboarding Step 4)

7. **Refresh .stp/docs/AUDIT.md** (if MCP services available). Pull fresh production data:
   - Sentry: current unresolved issues (mark previously-tracked issues as fixed if resolved)
   - Vercel: deployment status, recent builds
   - Stripe: subscription/product changes
   - Add a `## Milestone [N] Refresh — [DATE]` entry

8. Commit: `milestone: [milestone name] (v0.2.0)`
7. Git tag: `git tag v0.2.0`

Then:

```
╔═══════════════════════════════════════════════════════╗
║  ★ MILESTONE [N] COMPLETE                             ║
║  "[Milestone Name]"   v[X.Y.0]                       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Features   [N] built · 0 remaining                  ║
║  Tests      [N] passing                               ║
║  E2E        verified                                  ║
║                                                       ║
║  Critic:                                              ║
║  · Functionality    [PASS/PARTIAL/FAIL]               ║
║  · Design           [PASS/PARTIAL/FAIL]               ║
║  · Security         [PASS/PARTIAL/FAIL]               ║
║  · Accessibility    [PASS/PARTIAL/FAIL]               ║
║  · Performance      [PASS/PARTIAL/FAIL]               ║
║  · Production       [PASS/PARTIAL/FAIL]               ║
║                                                       ║
║  Priority fixes (if any):                             ║
║  1. [Most critical]                                   ║
║  2. [Second]                                          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

  ► Next: /clear, then /stp:work-quick [FIRST FEATURE of next milestone]
          (clear frees context between milestones — the next milestone
           reads PLAN.md and CHANGELOG.md fresh from disk)
```

If this is the **LAST milestone** (all milestones complete):
```
╔═══════════════════════════════════════════════════════╗
║  ★ ALL MILESTONES COMPLETE                            ║
║  [Project Name]   v[X.Y.0]                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Total features    [N] built                          ║
║  Total tests       [N] passing                        ║
║  Integration       verified                           ║
║                                                       ║
║  Critic:                                              ║
║  · [Summary of final 6-criteria evaluation]           ║
║                                                       ║
║  Your project is feature-complete per the PRD.        ║
║  Fix remaining issues, then deploy.                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

If NO — more features remain in this milestone:

```
┌─── ✓ Feature Complete ───────────────────────────────┐
│  [NAME] — [N] of [M] done in Milestone [current]    │
└──────────────────────────────────────────────────────┘

  [■■■■■■░░░░] [N]/[M] features · Milestone [N]

  ► Next: /clear, then /stp:work-quick [NEXT FEATURE in this milestone]
          (clear frees context between features — the next feature
           reads current-feature state fresh from disk)
```

ALWAYS fill in specific names.

## Gotchas

- Do NOT ask technical questions. You decide.
- ALWAYS save the checklist to `.stp/state/current-feature.md` — this survives compaction.
- Do NOT over-scope. "Add a settings page" doesn't mean also add admin tools, themes, and notifications.
- DO check if patterns already exist in the codebase. Follow established patterns.
- DO read reference files before implementing security, accessibility, or performance-sensitive code.
- Keep teach moments to 2-3 sentences. Explain the concept, not the implementation.
- The milestone check is AUTOMATIC — don't ask the user if they want it. Just do it. Quality isn't optional.

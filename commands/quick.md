---
description: "Just do it — skip the ceremony." Jumps straight into building with its own research. Use for small-to-medium tasks where you already know what you want and don't need a full investigation. Fixes, refactors, single features, updates. If a plan from /stp:research exists, picks it up and executes immediately.
argument-hint: What you want (e.g., "add Stripe payments", "fix the Sentry errors on /dashboard", "refactor auth middleware", "update invoice PDF export")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort high`** — Standard thinking depth for orchestration and review.



# STP: Builder

You are building, fixing, refactoring, or updating code using test-driven development. Tests come BEFORE implementation. Make all technical decisions. Only interrupt the user for PRODUCT decisions. Teach key concepts along the way.

**This command handles ALL work types:**
- **New feature**: "add Stripe payments" → full research, TDD, architecture integration
- **Bug fix**: "fix the Sentry errors on /dashboard" → reproduce first, write failing test, fix, verify
- **Refactor**: "refactor auth middleware" → read ARCHITECTURE.md for dependency map, ensure nothing breaks
- **Update**: "update invoice PDF export to use new template" → trace existing flow first, modify with tests
- **Remediation**: "fix the 5 critical issues from AUDIT.md" → read AUDIT.md, prioritize, TDD each fix

## Task Tracking (MANDATORY)

Use `TaskCreate` and `TaskUpdate` to track EVERY step visibly. The user sees real-time progress in their terminal.

**At the START, create tasks from the feature checklist:**
```
TaskCreate("Research: codebase + impact + security + resilience")
TaskCreate("Write tests (TDD)")
TaskCreate("[Checklist item 1 from feature plan]")
TaskCreate("[Checklist item 2]")
TaskCreate("[Checklist item 3]")
...
TaskCreate("/simplify code review")
TaskCreate("Hygiene scan")
TaskCreate("QA Agent testing")
TaskCreate("User QA approval")
TaskCreate("Version bump + docs update")
```

**As you work:** `TaskUpdate` each to `in_progress` when starting, `completed` when done. If you discover additional work needed during building (backward integration, unexpected fix, tech debt), `TaskCreate` a new task for it immediately — don't let it slip through.

**When spawning subagents (executor, QA):** The task should show the subagent's `activeForm` (e.g., "Building: Invoice CRUD via executor agent").

## Process

### Step 1: Context

Read .stp/docs/PLAN.md for this feature's requirements, test cases, and dependencies. Read CLAUDE.md for stack patterns AND the `## Project Conventions` section — these are the project-specific rules that MUST be followed. Every convention was earned through a decision or a bug. Violating them means repeating history.

If .stp/docs/PLAN.md exists and this feature is listed, use the plan's test cases and dependencies. If .stp/docs/PLAN.md doesn't exist or this feature isn't in it, create the plan inline (but recommend running `/stp:plan` first for complex projects).

If `.stp/state/current-feature.md` already exists, check if it was created by `/stp:research`:

**If it has research findings + approach + build order (from /stp:research):**
The plan is already done — research, approaches, architecture fit, impact analysis are complete. Skip straight to Step 5 (Build). Tell the user: "Found a plan from /stp:research — picking up where the discussion left off."

**If it's a feature in progress (has [x] checked items):**
```
AskUserQuestion(
  question: "There's an active feature in progress: [name] ([done]/[total] items). What do you want to do?",
  options: [
    "(Recommended) Finish [existing feature] first — picking up is faster than context-switching",
    "Abandon it, start [new feature] — mark old one incomplete",
    "Chat about this"
  ]
)
```

### Step 1b: UI/UX Design System (when building ANY frontend/UI work)

If this feature touches UI (components, pages, layouts, styling, themes, landing pages, dashboards, forms), this step is MANDATORY:

**Check for ui-ux-pro-max (required companion plugin):**
```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```
If MISSING → install automatically: `npm i -g uipro-cli && uipro init --ai claude`. Do NOT proceed with UI work without it.

**Check for existing design system:**
```bash
[ -f "design-system/MASTER.md" ] && echo "design-system: exists" || echo "design-system: NONE"
[ -f ".stp/explore-data.json" ] && grep -q "designSystem" .stp/explore-data.json 2>/dev/null && echo "whiteboard-preview: exists" || echo "whiteboard-preview: NONE"
```

**If design system exists** → Read `design-system/MASTER.md`. ALL UI code MUST follow its style, colors, typography, layout patterns, and anti-patterns. Check for page-specific overrides in `design-system/pages/`.

**If NO design system exists** → Generate one BEFORE writing any frontend code:
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system --persist -p "<Project Name>"
```

Then write a design preview section to `.stp/explore-data.json` (see whiteboard.md for the JSON format) and start the whiteboard so the user can review:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```

Ask the user to approve the design system at localhost:3333 before proceeding to build.

**If the feature is NOT UI-related, skip this step entirely.**

### Step 2: Research (BEFORE building — comprehensive, not optional)

This is the most important step. Skip this and you ship broken, insecure, disconnected code.

**A. Architecture Context — understand what EXISTS before touching anything**

Read `.stp/docs/ARCHITECTURE.md` first (if it exists). This is the full codebase map. From it, identify:
- What directories/files exist near the feature you're building
- What models, routes, components are related to this feature
- What external integrations might be affected
- What patterns and conventions MUST be followed
- What features DEPEND on the code you'll be touching (Feature Dependency Map)

If ARCHITECTURE.md doesn't exist, read `.stp/docs/CONTEXT.md` for the concise version.

Then deep-dive into the actual code:
- Read 3-5 representative files in the area you'll be modifying — learn the ACTUAL patterns, don't assume
- Trace the data flow: UI → API → database for related features
- Find existing functions, types, utilities you should REUSE (don't duplicate)
- Check: does a similar pattern already exist? Follow it, don't invent a new one
- Find existing variables, constants, config that the new feature should reference

**B. Impact Analysis — what does this feature touch?**

Read `.stp/docs/ARCHITECTURE.md`'s Feature Dependency Map + `.stp/docs/PLAN.md`'s Feature Touchpoint Map:
- Which existing features DEPEND on code you'll modify? (these could break)
- Which existing pages need to show data from this feature?
- Which existing API endpoints need to return this feature's data?
- Does the dashboard need updating? Navigation? Search? Notifications?
- List EVERY file that needs modification to connect this feature
- These become checklist items (backward integration)

**C. Research — what's the RIGHT way to do this?**

Research the RIGHT approach for this type of work. Trust hierarchy:
1. Context7 docs (HIGH trust) — query for the specific library/framework pattern
2. Official documentation (HIGH trust) — read the docs, not training data
3. Industry leaders (MEDIUM trust) — how do Stripe/Shopify/Notion solve this exact problem?
4. AI training data (LOWEST trust) — only when nothing else is available

For every significant pattern: verify it works with the CURRENT version of the framework. Your training data may be stale.

**Adapt research to work type:**
- **New feature**: How should this be implemented? What's the industry-standard pattern? What do production apps get wrong?
- **Bug fix**: What's the ROOT CAUSE, not just the symptom? Is this a one-off or a pattern? Are there OTHER places with the same bug? (grep for similar code)
- **Refactor**: What's the target pattern? Research the modern/idiomatic approach. Read the framework's migration guides. Check if the refactor aligns with the framework's direction.
- **Update**: What changed in the external dependency/API? Read the changelog/migration guide. What else in the codebase uses the old pattern?

**D. Learn from Past Bugs — don't repeat known mistakes**

Read `.stp/docs/AUDIT.md` — specifically the `## Patterns & Lessons` and `## Bug Fixes` sections. For the area you're building in:
- Are there KNOWN bug patterns that apply? (e.g., "server actions don't inherit auth context")
- Were there past bugs in related code? What was the root cause?
- What defense layers were added? Make sure your new code respects them.
- Are there rules like "always scope queries by orgId" that apply to your new code?

This is how the codebase learns. Past debugging work becomes a checklist for new development. If you're writing a new server action and AUDIT.md says "server actions need explicit orgId" — you add it from the start, not after a bug report.

**E. Security Research — what can go wrong?**

Read `.stp/references/security/ai-code-vulnerabilities.md` BEFORE writing code. Then for THIS specific feature:
- What OWASP category does this feature touch? (auth → A01, user input → A03, etc.)
- What are the known security mistakes for this type of feature?
- What validation is required? Where? (server-side, always)
- What secrets/credentials does this feature handle? How are they stored?
- Can a user manipulate this feature to access another user's data? (IDOR check)
- **Race conditions:** Can concurrent requests cause double-spend, double-booking, or duplicate records? If yes → database transactions + locking
- **Mass assignment:** Are you spreading request body into DB operations? Pick allowed fields explicitly.
- **Timing attacks:** Are you comparing tokens or secrets? Use timing-safe comparison.
- **Data privacy:** Does this feature collect/store PII? What's the retention period? Can it be fully deleted (GDPR)?
- **Resource exhaustion:** Are all inputs bounded? (max payload, max items, pagination, timeouts)
- **Error leakage:** Do error responses reveal internal state? Different messages for "not found" vs "wrong password"?
- Read `.stp/references/security/` files relevant to this feature

**F. Resilience Research — what if things fail?**

- What happens when the database is slow or down?
- What happens when external services fail? (Stripe, email, storage)
- Is there a failure scenario where money is taken but no record is created? (saga pattern needed)
- Should external calls have retry logic? (exponential backoff, max 3 retries)
- Can the app still function partially if a non-critical service is down? (graceful degradation)
- What's the timeout for every external call? (never infinite — 10-30 seconds max)

**G. Edge Cases + What Could Break**

- What happens when the input is empty? Too large? Malformed?
- What happens during network failure? Database timeout? External service down?
- What happens with concurrent access? (two users editing the same resource)
- Which existing tests might fail after this change?
- What are the 3 most likely failure modes for this feature?

**H. Scope Expansion + Improvement Opportunities**

The user doesn't know what they don't know. YOUR job is to find what they missed:

- **New feature**: Which existing features could BENEFIT from this? What existing code is incomplete that this feature completes? Present improvements: "While building Purchase Orders, I noticed the Supplier page has no order history. I'll add that too — it makes the app feel connected."
- **Bug fix**: Are there OTHER instances of this same bug? (grep for the pattern). Is the bug a symptom of a deeper architectural issue? If so, recommend the structural fix, not a band-aid. Check AUDIT.md — are there related Sentry errors that share the same root cause?
- **Refactor**: What ELSE uses the old pattern? Should the refactor extend to all instances? What downstream code needs updating? Read ARCHITECTURE.md's Feature Dependency Map — what depends on what you're changing?
- **Update**: What other code uses the same dependency/API? Should the update be applied project-wide? Are there deprecated patterns that should be cleaned up while you're here?

Always present scope expansions to the user — don't just silently add work. Explain why it matters.

**I. Anti-Hallucination Verification**

Before finalizing the feature plan:
- Verify every import/package you plan to use actually EXISTS in the registry
- Verify every function/method you plan to call EXISTS in that package's current version
- If using an API, verify the endpoint/method signature against Context7 or official docs
- If using a config option, verify it's real (not hallucinated from training data)

Teach: "I'm doing thorough research before writing any code. I'm checking what already exists in the codebase, researching how this feature should actually work, verifying every package and API I'll use is real, checking for security vulnerabilities specific to this type of feature, and finding opportunities to improve existing features along the way. This takes a few minutes but prevents days of fixing mistakes."

### Step 3: Enrich + Correct the User

Based on ALL the research above, identify what the user DIDN'T think of. Read relevant `.stp/references/` files.

**If the user's approach is wrong, say so.** You are the CTO — don't blindly implement bad ideas. Present the researched, proven approach.

**Examples by work type:**
- **Feature**: "You asked for a simple password field, but the industry standard is OAuth. Here's why: [Stripe/Shopify do it this way because...]. The downside of passwords is [security risk]."
- **Bug fix**: "You asked me to fix the undefined constant on /dashboard. But this is actually 6 related errors across 3 routes, all caused by the same missing export. I'll fix the root cause — not just the one you noticed."
- **Refactor**: "You asked to refactor auth middleware. Looking at ARCHITECTURE.md, the current pattern is used in 47 routes. But 12 of them have a slightly different pattern that's actually better. I recommend migrating everything to that pattern instead."
- **Update**: "You asked to update the PDF export. But the current implementation has 3 issues beyond what you mentioned: [no error handling, no loading state, hardcoded styles]. I'll fix all of them while I'm in there — cheaper now than as separate tasks."

Ask at most ONE product question if a real product decision is needed. If no product decision is needed, skip to the plan.

For significant technical decisions, briefly note them with industry backing.

### Step 4: Present Plan

```
## [Work Type]: [Name]
(e.g., "Feature: Invoice PDF Export" or "Fix: Dashboard ReferenceErrors" or "Refactor: Auth Middleware")

### What you asked for
[1-2 sentences restating their request in plain language]

### What I'm actually doing (things you'd miss)
- [ ] [What research revealed — why it matters to your USERS, one line]
- [ ] [Related issue discovered — why fixing it now saves time]
- [ ] [Scope expansion — why this makes the app better]

### Impact on existing code (what could break)
- [ ] [Existing page/component — what changes, from ARCHITECTURE.md dependency map]
- [ ] [Existing page/component — what changes]
(For refactors: list EVERY dependent. For fixes: list related code with the same pattern.)

### Key decisions
[Brief note on any significant tech choices, with who uses it and why.
Skip this section if no notable decisions beyond what's in CLAUDE.md.]

### Tests to write FIRST
- [ ] [Test case 1 from .stp/docs/PLAN.md or identified during enrichment]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Build order (9-layer Definition of Done)
1. [Database — migrations, schema changes]
2. [Executable specs — one test per acceptance criterion, named "AC: ..."]
3. [Write tests FIRST (TDD) — behavioral tests, error-path tests, property-based for critical invariants]
4. [API / server logic — endpoints, server actions, validation]
5. [Business logic — core feature functionality, make tests pass]
6. [UI — pages, components, forms, connected to API]
7. [Error/edge cases — error handling, loading states, empty states]
8. [Backward integration — update existing features to connect]
9. [Polish — accessibility, /simplify, verify acceptance criteria from PRD]

### Acceptance criteria (from .stp/docs/PRD.md) — EACH becomes an executable spec test
- [ ] [AC 1 — testable condition that defines "done"]
- [ ] [AC 2 — testable condition]

### Standards I'll check
- .stp/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

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
   **For multiple independent features:** Create an Agent Team and spawn all in parallel.

3. **Create a build team for the wave.**

   Use Agent Teams for maximum parallelism. Each team member is a Sonnet executor working in an isolated worktree.

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

   **Create the team and spawn:**
   ```
   TeamCreate(name="wave-1-build", description="Milestone [N] Wave 1 parallel build")

   # Spawn ALL independent features simultaneously
   Agent(
     name="build-[feature-name]",
     model="sonnet",
     isolation="worktree",
     team_name="wave-1-build",
     run_in_background=true,
     prompt="[focused spec — see below]"
   )
   # ... repeat for every feature in the wave
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

   Teach: "I'm launching a team of builder agents — each works in its own isolated copy of the code. They can't interfere with each other. Each one has just the tools it needs to build (read, write, run tests) and nothing else. I'll review and merge their work when they're done."

   **Wait for all team members to complete.** As each reports back:
   - Read their structured report (files, tests, decisions, issues)
   - TaskUpdate the corresponding task to `completed`

   **Then shut down the team:**
   ```
   SendMessage(to="build-[name]", type="shutdown_request") // for each member
   TeamDelete(name="wave-1-build")
   ```

   **Merge Wave 1** → verify (type check + ALL tests) → update .stp/docs/CONTEXT.md → **then create Wave 2 team.**

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
   
   Teach: "I'm doing a hygiene scan — cleaning up the garbage that accumulates during building. Unused imports, debug logging, commented-out code, duplicate functions. Think of it as washing the dishes after cooking — the meal is ready, but the kitchen needs to be clean."

9. **Review checkpoint.**
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

   Then spawn the QA agent:
   ```
   Agent(
     name="qa-[feature-name]",
     model="sonnet",
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
   ━━━ QA Report ━━━
   ✓ AC1: User can create invoice — PASS
   ✓ AC2: Invoice shows in list — PASS
   ✗ Empty state: blank page instead of prompt — FIXED
   ✓ Auth: redirects without login — PASS
   ✓ Mobile: works at 375px — PASS
   
   All issues found were fixed. Ready for your review.
   ```

   Teach: "I had a separate QA tester check the feature — it hasn't seen how the code was written, so it tests like a real user would. Same reason I use a separate Critic for code review — you catch more bugs when fresh eyes look at it."

11. **Guided Manual QA — the user tests the feature.**

   Automated tests prove the CODE works. Independent QA proves the FEATURES work. Manual QA proves the PRODUCT feels right. Present a test guide:

   ```
   ━━━ QA: Test this feature ━━━

   What was added/changed:
   - [File 1] — [what it does, in plain language]
   - [File 2] — [what changed]

   How to see it:
   [Exact command to run the app: npm run dev, python manage.py runserver, etc.]
   [Exact URL or screen to navigate to]

   Test these scenarios (do each one):
   1. [Happy path] — [exact steps: click X, type Y, expect Z]
   2. [Empty state] — [go to the page with no data, what do you see?]
   3. [Error case] — [submit without required fields, what happens?]
   4. [Edge case] — [try very long text, special characters, etc.]
   5. [Mobile] — [resize browser to phone width, does it work?]
   6. [Keyboard] — [Tab through the feature, can you reach everything?]

   Look for:
   - Does loading show while data loads? (not a blank screen)
   - Do buttons disable during submission? (no double-click)
   - Are error messages helpful? (not technical jargon)
   - Does it feel right? (trust your gut — if something feels off, it is)

   Report anything that doesn't look right — I'll fix it.

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
   
   Teach: "Even though all automated tests pass, YOU need to actually use the feature. Automated tests check if the code works correctly — but they can't tell if the flow is confusing, if a button is in the wrong place, or if something just feels off. Your eyes catch what code can't."

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
   
   ### Stats
   - Tests: [N] passing
   - Type check: clean
   ```

3. **Update .stp/docs/PLAN.md:**
   - Mark this feature `[x]` with version: `- [x] 3. Ingredient CRUD (v0.1.3)`
   - If this feature was NOT in the original plan (unplanned work), ADD it to the appropriate milestone with `[x]` already checked, and update the Feature Touchpoint Map to include it. .stp/docs/PLAN.md must reflect ALL features that exist, not just originally planned ones.

4. Update .stp/docs/PRD.md Technical Decisions Log if significant decisions were made.

5. **Update .stp/docs/CONTEXT.md** — reflect the current state of the codebase after this feature:
   - Add new files to the file map (with 1-line purpose each)
   - Update data schema if new tables/columns were added
   - Update API endpoints if new routes were created
   - Update patterns section if new conventions were established
   - Update environment variables if new ones are required
   - **Add any deferred issues to Known Issues / Tech Debt** — if /simplify flagged something unfixable, if you noticed something suboptimal but out of scope, or if the Critic previously flagged something the user said "fix later" — record it here so it's not forgotten.
   
   .stp/docs/CONTEXT.md is a SNAPSHOT of what exists NOW — not history. Replace outdated info, don't append. Keep it under 150 lines.

6. **Update .stp/docs/ARCHITECTURE.md** (if it exists) — incremental update:
   - Add new models/tables to the Data Models section
   - Add new routes to the API/Page Routes section
   - Add new components to the Components section
   - Update the Feature Dependency Map if this feature creates new dependencies
   - If a bug was fixed that was tracked in AUDIT.md, mark it resolved there too

   Don't rewrite the whole file — just add/update the sections affected by this feature.

7. **Capture project conventions in CLAUDE.md.** After building, ask yourself: did this feature establish a pattern that future development must follow?

   If YES, append to the `## Project Conventions` section:
   ```markdown
   - **[Rule name]**: [What to always/never do]
     - Why: [The reason — a decision, a bug prevention, a pattern that works]
     - Applies when: [When a developer should think of this rule]
     - Added: [DATE] via /stp:quick [feature name]
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

8. **Update README.md — MANDATORY after EVERY feature.** The project README must always reflect the current state. Update:
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

7. Delete `.stp/state/current-feature.md` and `.stp/state/handoff.md` if they exist.
8. Commit: `feat: [feature name] (v0.1.3)`

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
Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum.
1. Restate the goal, 2. Define "complete", 3. List angles, 4. Iteration 1, 5. Iteration 2, 6. Synthesize.
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
━━━ Milestone [N] complete ━━━

[N] features built. Integration tests passing.

Critic Report:
[Summary of 6-criteria evaluation]

Priority fixes (if any):
1. [Most critical]
2. [Second]

Fix these now? Or continue to Milestone [N+1]:
   /stp:quick [FIRST FEATURE of next milestone]
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
/stp:quick [NEXT FEATURE in this milestone]
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

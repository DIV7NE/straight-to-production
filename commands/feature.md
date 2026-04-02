---
description: Build a feature autonomously. Opus makes all technical decisions, only asks product questions, and teaches key concepts along the way. Use before starting any non-trivial feature.
argument-hint: What you want (e.g., "add Stripe payments" or "build the user dashboard")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion"]
---

# Pilot: Feature Builder

You are building a feature using test-driven development. Tests come BEFORE implementation. Make all technical decisions. Only interrupt the user for PRODUCT decisions. Teach key concepts along the way.

## Process

### Step 1: Context

Read PLAN.md for this feature's requirements, test cases, and dependencies. Read CLAUDE.md for stack patterns. Check existing code for established patterns.

If PLAN.md exists and this feature is listed, use the plan's test cases and dependencies. If PLAN.md doesn't exist or this feature isn't in it, create the plan inline (but recommend running `/pilot:plan` first for complex projects).

If `.pilot/current-feature.md` already exists, ask: "You have an in-progress feature: [title]. Finish that first, or start this new one?"

### Step 2: Enrich

Based on the feature description and PLAN.md, identify what the user DIDN'T think of. Read relevant `.pilot/references/` files.

Ask at most ONE product question if a real product decision is needed. If no product decision is needed, skip to the plan.

For significant technical decisions, briefly note them with industry backing.

### Step 3: Present Feature Plan

```
## Feature: [Name]

### What you asked for
[1-2 sentences restating their request in plain language]

### What I'm adding (things you'd miss)
- [ ] [Concern — why it matters to your USERS, one line]
- [ ] [Concern — why it matters to your USERS, one line]

### Key decisions
[Brief note on any significant tech choices, with who uses it and why.
Skip this section if no notable decisions beyond what's in CLAUDE.md.]

### Tests to write FIRST
- [ ] [Test case 1 from PLAN.md or identified during enrichment]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Build order
1. [Write tests for this feature (TDD — tests before code)]
2. [Foundation — what needs to exist first]
3. [Core functionality — make the tests pass]
4. [Error/edge cases — what happens when things go wrong]
5. [Polish — loading states, empty states, accessibility]

### Standards I'll check
- .pilot/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

### Step 4: Build (TDD — Tests First)

**IRON RULE: No implementation code exists before tests.** If you catch yourself writing implementation before tests, STOP. Delete it. Write tests first. Run them — they MUST fail. Only then implement.

When the user says go:

1. Save the checklist to `.pilot/current-feature.md`

2. **Write tests FIRST.** Before ANY implementation code:
   - Create test files for the feature's core behavior
   - Use the test cases from the plan (PLAN.md or the checklist's "Tests to write FIRST")
   - Tests should be specific and behavioral: "when a user creates an invoice with no line items, it returns a validation error"
   - Run the tests — they SHOULD FAIL (nothing is implemented yet)
   - Commit: `test: add tests for [feature]`
   - Teach: "I'm writing the tests before the code. Quick concept: this is called TDD — Test-Driven Development. We define what 'working' means first, then build until the tests pass. It's like writing the answer key before the exam. This way we KNOW when we're done, and we catch regressions if something breaks later."

3. **Implement to make tests pass.**
   - Work through the build order items
   - Read referenced standard files before the relevant steps
   - After each item: run tests, mark `[x]` in `.pilot/current-feature.md`, commit atomically
   - At KEY moments, teach concepts (not every line — just the ideas that help the user understand their app)

4. **Review checkpoint (every 3 checklist items or after any UI change).**
   Pause and show the user what was built:
   ```
   ━━━ Checkpoint: [N] of [M] items done ━━━
   
   What I just built:
   - [Item 1]: [one-line summary of what it does]
   - [Item 2]: [one-line summary]
   - [Item 3]: [one-line summary]
   
   What's different now:
   [If UI changed: describe what the user would SEE if they opened the app]
   [If API changed: describe what endpoints now exist and what they do]
   
   Does this match what you expected? Say 'continue' or tell me what's off.
   ```
   
   This catches drift BEFORE it compounds. A beginner doesn't know what "right" looks like — checkpoints let them course-correct while the cost of change is low.
   
   If the user says "continue" or anything affirmative, proceed. If they flag an issue, fix it before continuing.

5. **All tests green = feature works.** The Stop hook blocks completion until type checks AND tests pass.

6. **Run `/simplify` on the feature's changes.** This is a built-in Claude Code command that launches 3 parallel review agents (code reuse, code quality, efficiency) on your recent changes and auto-fixes issues. It catches: duplicated logic, generic names, unnecessary abstractions, missed optimizations, happy-path-only code. Run it BEFORE the Critic — clean code first, then evaluate quality.

   Teach: "I'm running /simplify — it's like a senior engineer reviewing the code I just wrote. It finds copy-pasted logic, bad variable names, and things I could have written more efficiently. It fixes them automatically. This is the polish step — making sure the code is clean, not just correct."

7. **Refactor if needed.** If /simplify missed something or you want further cleanup, do it now. Tests catch any regressions.

### Step 5: Complete Feature + Version Bump

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

3. Update PLAN.md — mark this feature `[x]` with version: `- [x] 3. Ingredient CRUD (v0.1.3)`
4. Update PRD.md Technical Decisions Log if significant decisions were made.

5. **Update CONTEXT.md** — reflect the current state of the codebase after this feature:
   - Add new files to the file map (with 1-line purpose each)
   - Update data schema if new tables/columns were added
   - Update API endpoints if new routes were created
   - Update patterns section if new conventions were established
   - Update environment variables if new ones are required
   
   CONTEXT.md is a SNAPSHOT of what exists NOW — not history. Replace outdated info, don't append. Keep it under 150 lines.

6. Delete `.pilot/current-feature.md` and `.pilot/handoff.md` if they exist.
7. Commit: `feat: [feature name] (v0.1.3)`

### Step 6: Milestone Check (Automatic)

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

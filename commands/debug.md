---
description: Systematic debugging — finds and fixes bugs in one shot. Auto-gathers context (Sentry, architecture, git history), diagnoses with evidence, then fixes with TDD + defense-in-depth. Use for any bug, error, or unexpected behavior.
argument-hint: What's broken (e.g., "dashboard shows wrong totals", "Sentry error on /api/invoices", "tests failing after merge")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Root cause analysis requires maximum thinking depth.

# STP: Debugger

Systematic, evidence-based debugging. You are the CTO diagnosing a production system — not a junior developer trying random fixes. Every change requires evidence. Every hypothesis must be falsifiable. The goal is to find the root cause in one investigation and fix it permanently.

## THE IRON LAW (non-negotiable)

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Before ANY code change, you must have ALL five:
1. **MECHANISM** — You can explain the exact chain: defect → infection → failure
2. **REPRODUCTION** — You can trigger the bug reliably (automated test preferred)
3. **EVIDENCE** — You have file:line proof of where the defect lives
4. **RULED OUT** — You've actively disproven at least one alternative hypothesis
5. **PATTERN ANALYSIS** — You've compared working examples vs broken code

If you can't fill all five, you're not ready to fix. Keep investigating.

## RED FLAGS (stop immediately if you think these)

- "Quick fix for now, investigate later" → You're about to create a worse bug
- "Just try changing X and see if it works" → Shotgun debugging. STOP.
- "Add multiple changes, run tests" → Can't isolate what matters
- "It's probably X, let me fix that" → Premature hypothesis without evidence
- "I don't fully understand but this might work" → You MUST understand first
- "One more fix attempt" (when already tried 2+) → Escalation time

## USER SIGNAL DETECTION

Listen for these — they mean your approach is failing:
- "Is that not happening?" → You assumed without verifying
- "Will it show us...?" → Add evidence gathering, don't guess
- "Stop guessing" → Return to Phase 1, understand before proposing
- "We're stuck?" → Your approach isn't working, change it fundamentally

## Process

### Phase 0: AUTO-GATHER (before asking the user ANYTHING)

Read everything available. The user should NOT need to provide information you can find yourself.

**Fast-path check: have we seen this before?**

Read `.stp/docs/AUDIT.md` first — scan the `## Bug Fixes` and `## Patterns & Lessons` sections. If a past fix matches the current symptoms:
- Read the full fix entry (root cause, chain, defense layers)
- Verify the past fix is still in place (it might have been reverted or overwritten)
- If the same bug recurred despite defense layers: the defense was insufficient — escalate immediately
- If it's a NEW instance of a KNOWN pattern: apply the known fix pattern to the new location

This fast-path can resolve known issues in seconds instead of minutes.

**Always read (in parallel):**

| Source | What you're looking for | How |
|--------|------------------------|-----|
| `.stp/docs/ARCHITECTURE.md` | Dependency map for the affected area — what connects to what | Read the Feature Dependency Map section |
| `.stp/docs/AUDIT.md` | Known issues — is this already tracked? Related errors? | Search for the affected route/component |
| `.stp/docs/CONTEXT.md` | Quick reference — stack, key patterns, build commands | Skim for relevant sections |
| Error message / stack trace | Exact failure point — file, line, function | Read what the user provided or what Sentry shows |
| Source code | The actual code at the failure point + 2 levels up the call chain | Read the files referenced in the stack trace |
| Test files | Existing tests for the affected area — are any already failing? | Glob for *.test.* near the affected files |
| `git log --oneline -10 -- [affected files]` | What changed recently in this area? | Check if the bug correlates with a recent change |
| `git blame [affected file]` | Who changed the failing line and when? | Focus on recent changes to the exact area |

**If MCP services are available:**

| Service | What to pull |
|---------|------------|
| Sentry | Errors on the affected route: stack trace, frequency, first/last seen, browser/OS |
| Vercel | Recent deployments — did a deploy correlate with when the bug started? |
| Stripe | If billing-related: webhook events, subscription state |

**After gathering, identify gaps:**

What do you KNOW vs what do you NEED? Only ask the user for things you genuinely cannot find:

```
AskUserQuestion(
  question: "I've gathered [what you found]. To reproduce this, I need: [specific gap]",
  options: [
    "[Most likely scenario based on evidence]",
    "Let me describe the exact steps",
    "I have a screenshot/video",
    "Chat about this"
  ]
)
```

Things you should NEVER ask the user for:
- Stack traces (read the error output or Sentry)
- Which file is affected (the stack trace tells you)
- What the code does (read it)
- Recent changes (git log/blame)
- Test status (run them)

Things you MAY need to ask:
- Exact reproduction steps (if not obvious from the error + code)
- User role / account state needed to trigger the bug
- Browser / device specifics (if UI-related and not in Sentry)
- "Does this happen every time or intermittently?"
- Business context: "Is this blocking users? How urgent?"

### Phase 1: REPRODUCE

**You cannot fix what you cannot reproduce.** Period.

1. **From gathered evidence, attempt reproduction:**
   - If it's a code error: write a failing test that triggers it
   - If it's a runtime error: run the app and trigger the condition
   - If it's a Sentry error: trace the stack to understand the trigger path

2. **Write the reproduction test IMMEDIATELY:**
   ```
   // This test captures the bug — it MUST fail before the fix and pass after
   test('[BUG] dashboard shows $0 for employer with invoices', () => {
     // Setup: employer with 3 invoices totaling $1,500
     // Action: load dashboard stats
     // Assert: total should be $1,500, not $0
   })
   ```

3. **If you CANNOT reproduce:**
   - Tell the user exactly what you tried and what happened
   - Ask for the specific missing piece
   - Do NOT proceed to Phase 2 without reproduction
   - Exception: if the bug is obvious from code review (e.g., typo, undefined variable), note this and proceed with the code-level evidence

### Phase 2: DIAGNOSE (the IS/IS NOT method)

**Do NOT jump to a fix.** Write your diagnosis first.

**Step 1: IS / IS NOT analysis (Kepner-Tregoe method)**

Map the boundaries of the bug across 4 dimensions:

```
WHAT:
  IS:     [What exactly is broken — specific behavior]
  IS NOT: [What similar things WORK fine — narrows the scope]

WHERE:
  IS:     [Which routes, components, environments show the bug]
  IS NOT: [Which similar routes/components work — constrains location]

WHEN:
  IS:     [When it started, what correlates — deploy? data change? time?]
  IS NOT: [When it does NOT happen — time of day? specific users?]

EXTENT:
  IS:     [How widespread — all users? one role? specific data?]
  IS NOT: [Who is NOT affected — what's different about them?]
```

The root cause MUST explain both the IS and IS NOT columns. If your hypothesis explains why it's broken but NOT why similar things work, your hypothesis is wrong.

**Step 2: Form hypotheses (2-3, falsifiable)**

Each hypothesis must be:
- **Specific**: file:line level, not "something in the API layer"
- **Falsifiable**: you can describe an experiment that would DISPROVE it
- **Consistent**: explains ALL observations (IS and IS NOT)

Bad: "Something is wrong with the dashboard state"
Good: "The `getTotalRevenue` server action at `src/actions/analytics.ts:47` returns 0 because it queries `Invoice` without filtering by `organizationId`, but the dashboard component passes `orgId` as a query param that the action ignores"

**Step 3: Test hypotheses (one at a time)**

For each hypothesis:
1. **Predict**: "If H1 is correct, then [specific observable thing] should be true"
2. **Test**: Check if the prediction holds (read code, add log, run test)
3. **Result**: Confirmed → proceed to evidence gate. Disproved → next hypothesis.

**Change ONE variable at a time.** Never test two hypotheses simultaneously.

**Step 4: Trace the infection chain**

Once you have the right hypothesis, trace the full chain:
```
DEFECT:    [The actual code mistake — wrong query, missing filter, typo]
INFECTION: [How the defect corrupts program state — wrong data returned]
FAILURE:   [What the user sees — $0 on dashboard]
```

This chain must be complete. If there's a gap, keep investigating.

### Phase 2.5: PATTERN ANALYSIS

Before fixing, compare working vs broken:

1. Find a similar feature that WORKS (from ARCHITECTURE.md or code search)
2. Read both implementations completely — the working one and the broken one
3. Identify ALL differences
4. The fix should make the broken code follow the working pattern

Also check: **Is this bug a one-off or a pattern?**
```bash
# Search for the same anti-pattern elsewhere
grep -rn "[the pattern that caused the bug]" --include="*.ts" --include="*.tsx" src/
```

If found in multiple places, ALL instances need fixing — not just the reported one.

### EVIDENCE GATE (Iron Law checkpoint)

Before ANY code change, verify all five:

```
□ MECHANISM:       [Defect → Infection → Failure chain documented]
□ REPRODUCTION:    [Failing test exists OR manual repro steps confirmed]
□ EVIDENCE:        [file:line of the defect, with explanation]
□ RULED OUT:       [At least 1 alternative hypothesis disproven with evidence]
□ PATTERN ANALYSIS:[Working example compared, pattern siblings identified]
```

**If you cannot check all five boxes: DO NOT PROCEED TO THE FIX.** Return to Phase 1 or Phase 2.

### Phase 3: FIX (minimal, tested, defended)

**Step 1: Implement the minimal fix**

Change ONE thing that addresses the root cause. Not two things. Not "while I'm here" improvements. ONE fix for ONE root cause.

**Step 2: Run ALL tests**

Not just the new test. ALL tests. The fix must not cause regressions.

**Step 3: Fix pattern siblings**

If Phase 2.5 found the same bug elsewhere, fix ALL instances now. Each gets its own test.

**Step 4: Defense-in-depth (4 layers)**

Make this bug STRUCTURALLY IMPOSSIBLE to recur:

| Layer | What | Example |
|-------|------|---------|
| 1. Entry validation | Validate at the boundary | Add `organizationId` required check in the action |
| 2. Business logic | Guard in the core logic | `if (!orgId) throw new Error('orgId required')` |
| 3. Environment guard | Type system / schema | Make the param non-optional in the type definition |
| 4. Debug instrumentation | Logging for detection | Add monitoring/alert if this condition ever occurs again |

Not every bug needs all 4 layers — use judgment. But Layer 1 (entry validation) is always required.

**Step 5: Replace arbitrary timeouts with conditions**

If the bug involved timing (race condition, flaky test, animation):
```typescript
// BAD: arbitrary timeout
await new Promise(r => setTimeout(r, 2000));

// GOOD: condition-based waiting
await waitFor(() => expect(screen.getByText('Loaded')).toBeInTheDocument());
```

### Phase 4: VERIFY

1. **Reproduction test passes** — the bug is fixed
2. **All existing tests pass** — no regressions
3. **Pattern siblings fixed** — same bug can't exist elsewhere
4. **Defense layers in place** — bug can't recur

5. **Update .stp/docs/AUDIT.md:**
   ```markdown
   ## Bug Fix — [DATE] — [Bug Title]
   
   ### Symptom
   [What the user reported]
   
   ### Root Cause
   [Defect → Infection → Failure chain]
   
   ### Fix
   [What was changed, file:line]
   
   ### Pattern Siblings
   [Other instances found and fixed, or "None — unique occurrence"]
   
   ### Defense Layers Added
   [What prevents recurrence]
   
   ### Sentry
   [Issue resolved / marked — if applicable]
   ```

6. **Extract the generalizable lesson** and append to AUDIT.md's Patterns & Lessons section:
   ```markdown
   ## Patterns & Lessons
   
   ### [DATE] — [Short pattern name]
   **Symptom**: [What it looked like]
   **Root cause**: [The generalizable mistake — not project-specific, but PATTERN-specific]
   **Rule**: [The rule that prevents this class of bug forever]
   **Applies when**: [When a developer should think of this rule]
   **Example**: [The specific instance that taught us this]
   ```

   Examples of good lessons:
   - "Server actions don't inherit middleware auth context — always pass orgId explicitly. Applies when: migrating from API routes to server actions."
   - "Prisma `findMany` without a `where` clause returns ALL records across organizations — always scope queries. Applies when: writing any multi-tenant database query."
   - "React hooks can't be called conditionally — early returns before hooks cause 'Rendered more hooks' error. Applies when: adding guard clauses to components."

   These lessons are the REAL value. The specific fix matters today; the lesson matters forever.

7. **Capture convention in CLAUDE.md** if this bug reveals a project-specific rule.

   If the root cause was something a developer could easily repeat, add it to `## Project Conventions`:
   ```markdown
   - **[Rule name]**: [What to always/never do]
     - Why: Bug — [brief root cause]
     - Applies when: [When to think of this]
     - Added: [DATE] via /stp:debug
   ```

   Example: "Always scope Prisma queries by `organizationId` in server actions — server actions don't inherit auth middleware context. Applies when: writing any server action that queries org-specific data."

   This is how bugs become RULES. The next developer (or AI session) reads CLAUDE.md and avoids the mistake from day one.

8. **Update .stp/docs/ARCHITECTURE.md** if the fix changed structure (new validation layer, new middleware, changed data flow).

9. **Commit:** `fix: [specific description] — root cause: [1-line explanation]`

### Present to user:

```
━━━ Bug Fixed ━━━

Symptom:    [What they reported]
Root cause: [1-line: the actual defect]
Fix:        [1-line: what was changed]

Chain: [defect] → [infection] → [failure]

Pattern siblings: [N found and fixed / none]
Defense:          [What prevents recurrence]
Tests:            [N] new, [N] total, all passing

━━━ Teach ━━━
[1-2 sentences explaining what went wrong in a way that teaches the user
about their codebase. e.g., "The analytics query wasn't scoped to the
organization because server actions don't automatically inherit the auth
context — unlike API routes which get it from middleware. This is a common
gap when migrating from API routes to server actions."]
```

## ESCALATION

### 3-Attempt Rule

```
Fix attempt 1: Didn't work → Return to Phase 2 with new evidence
Fix attempt 2: Didn't work → Return to Phase 2 with new evidence
Fix attempt 3: STOP.
```

After 3 failed fix attempts: **the hypothesis is wrong.** Not the implementation — the UNDERSTANDING. Return to Phase 2 with a completely different hypothesis.

### 3-Hypothesis Rule

```
Hypothesis 1 (3 attempts): Disproven → New hypothesis
Hypothesis 2 (3 attempts): Disproven → New hypothesis
Hypothesis 3 (3 attempts): STOP.
```

After 3 disproven hypotheses: **this is architectural, not a bug.** Tell the user:

```
AskUserQuestion(
  question: "After investigating 3 different root cause theories, I believe this is a structural issue, not a simple bug. [Explain the architectural problem]. This needs a design change, not a fix. How should we proceed?",
  options: [
    "(Recommended) Redesign this area — /stp:build refactor [area]",
    "Apply a workaround for now and plan the redesign",
    "Let me provide more context that might help",
    "Chat about this"
  ]
)
```

## Rules

- NEVER skip Phase 0. The auto-gather step is what makes this debugger find bugs in one shot.
- NEVER fix without evidence. The Iron Law is absolute.
- NEVER make two changes at once. Change one variable, test, observe.
- NEVER say "seems to work" or "I think it's fixed." PROVE it with tests.
- NEVER ask the user for information you can find by reading code, logs, git, or MCP services.
- ALWAYS trace the full infection chain. Fixing the failure without finding the defect means the bug will return.
- ALWAYS check for pattern siblings. The reported bug is often one instance of many.
- ALWAYS add defense-in-depth. A fix without prevention is a future regression.
- ALWAYS persist findings to AUDIT.md. The next session should know what was investigated and fixed.
- ALWAYS teach. The user should understand their codebase better after every debug session.

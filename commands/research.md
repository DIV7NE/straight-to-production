---
description: "I know what I want, investigate how to build it." Codebase impact analysis → library research (Context7) → industry patterns (Tavily) → security review → 2-3 approaches with tradeoffs → saves build plan → /stp:work-quick picks it up automatically.
argument-hint: What you're thinking about (e.g., "add payment processing", "refactor the auth system", "fix the N+1 query problem")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Maximum thinking depth for research and architecture decisions.

# STP: Propose

You are the CTO evaluating a piece of work before committing resources. Research deeply, explore approaches, map the impact on the existing codebase, and produce a plan. Do NOT build anything — this is discussion and planning only.

## When to Use This (vs other commands)

Use `/stp:research` when you **know WHAT to build but not HOW:**
- "Add Stripe payments" → investigate patterns, codebase impact, security
- "Refactor the auth system" → map dependencies, find the right approach
- "Fix the N+1 query problem" → trace root cause, research solutions

**Don't use this when:**
- You don't know what to build yet → use `/stp:whiteboard` (figures out WHAT)
- You know what AND how → use `/stp:work-quick` or `/stp:work-full`
- You have a bug with a clear error → use `/stp:debug`

**How it connects to building:**
```
/stp:research  →  saves build plan  →  /stp:work-quick picks it up automatically
   (HOW)           (.stp/state/)          (skips research, jumps to building)
```

**This is the "think before you act" command.** Your job is to:
1. Research whether it's the right approach
2. Find the best way (not just the user's first instinct)
3. Map how it fits the existing codebase
4. Surface everything the user didn't think of
5. Produce a plan they can approve, modify, or discard

## Task Tracking (MANDATORY)

```
TaskCreate("Phase 1: Research — how should this be done?")
TaskCreate("Phase 2: Explore approaches — 2-3 options with tradeoffs")
TaskCreate("Phase 3: Architecture fit — how it maps to THIS codebase")
TaskCreate("Phase 4: Impact + risk analysis")
TaskCreate("Phase 5: Produce feature plan")
```

## Process

### Phase 1: Research — How Should This Actually Be Done?

**Read context first (in parallel):**
- `.stp/docs/ARCHITECTURE.md` — what exists, how the codebase works, what patterns are established
- `.stp/docs/AUDIT.md` — any production issues related to this area? Past lessons?
- `.stp/docs/PLAN.md` — is this already planned? Part of a milestone?
- `CLAUDE.md` — project conventions, stack patterns, standards
- `.stp/docs/AUDIT.md` Patterns & Lessons — have we been burned by something similar?

**Research the domain:**
- Context7: query the framework/library docs for the right pattern
- Tavily/WebSearch: how do production apps solve this? What's the industry standard?
- What do Stripe/Shopify/Notion/Linear do? (adapt to the domain)
- What are the common MISTAKES with this type of work?
- What's the current best practice vs what training data might suggest?

**Trust hierarchy:**
1. Context7 docs (HIGH) — current framework APIs
2. Official docs (HIGH) — verified patterns
3. Industry leaders (MEDIUM) — proven at scale
4. Training data (LOWEST) — may be stale

  ┊ Before proposing anything, I research how this is actually done in production — checking current docs, how industry leaders solve this, and what mistakes to avoid.

### Phase 2: Explore Approaches — Present Options, Not Just One Answer

Based on research, present **2-3 genuinely different approaches**. Not one good option and two strawmen — real alternatives with real tradeoffs.

For each approach:
- What it looks like (high level)
- Who uses this approach (industry examples)
- Pros (be specific to THIS project, not generic)
- Cons (be honest — every approach has downsides)
- Effort estimate (small/medium/large relative to each other)
- What it touches in the existing codebase (from ARCHITECTURE.md)

**Offer the whiteboard:**

```
AskUserQuestion(
  question: "Want to see these approaches as diagrams? I can launch the visual whiteboard.",
  options: [
    "Yes — show me the diagrams",
    "No — the descriptions are enough",
    "Chat about this"
  ]
)
```

If yes, write diagram data to `.stp/whiteboard-data.json` and launch the whiteboard server. Show architecture diagrams, data flow, or comparison charts as appropriate.

**Then let them choose:**

```
AskUserQuestion(
  question: "Which approach fits your project best?",
  options: [
    "(Recommended) [Approach A] — [1-line why you recommend it for THIS project]",
    "[Approach B] — [1-line when this makes more sense]",
    "[Approach C] — [1-line when this makes more sense]",
    "None of these — let me describe what I'm thinking",
    "Chat about this — I have questions"
  ]
)
```

### Phase 3: Architecture Fit — How Does This Map to the Existing Codebase?

With the chosen approach, map EXACTLY how it fits the current architecture:

**From ARCHITECTURE.md, trace the integration points:**

```
## Architecture Fit

### New files to create
- [file path] — [purpose]
- [file path] — [purpose]

### Existing files to modify
- [file path] — [what changes and why]
- [file path] — [what changes and why]

### Data model changes
- [New models/tables needed]
- [Existing models that need new fields/relations]

### API changes
- [New routes needed]
- [Existing routes that need updating]

### UI changes
- [New pages/components]
- [Existing pages that need to show new data]

### Integration points
- [External services involved]
- [Existing features that connect to this]

### Dependencies on existing code
- [What existing code this relies on]
- [What existing code relies on what you'll change — from Feature Dependency Map]
```

**Present to user:**

```
AskUserQuestion(
  question: "Here's how [chosen approach] fits your codebase. [N] new files, [N] modified files, [N] model changes. Any concerns?",
  options: [
    "Looks right — continue to impact analysis",
    "I have a concern about [something]",
    "This is bigger than I expected — let's simplify",
    "Chat about this"
  ]
)
```

### Phase 4: Impact + Risk Analysis — What Could Go Wrong?

**Surface everything the user didn't think of.** This is the "you don't know what you don't know" phase.

**Security:**
- Does this introduce new attack surfaces? (new endpoints, user input, data exposure)
- Read relevant `.stp/references/security/` files
- What OWASP categories does this touch?

**Breaking changes:**
- Which existing features DEPEND on code you'll modify? (from ARCHITECTURE.md dependency map)
- Which existing tests might fail?
- Are there backward compatibility concerns?

**Performance:**
- Does this add database queries to hot paths?
- Does this increase bundle size significantly?
- Any N+1 query risks?

**Edge cases:**
- What happens with empty data? Concurrent access? Offline?
- What happens at scale? (100 users vs 10,000)

**Past lessons:**
- Does AUDIT.md's Patterns & Lessons section have relevant warnings?
- Have we been burned by similar changes before?

**What the user didn't ask for but should have:**
- Missing error handling, loading states, empty states
- Accessibility requirements
- Mobile considerations
- Legal/compliance implications (GDPR, billing regulations)

Present findings:
```
┌─── Impact Analysis ──────────────────────────────────┐
│                                                       │
│  Security       [findings or "Clean"]                 │
│  Breaking risk  [N] features could be affected        │
│  Performance    [findings or "No concerns"]            │
│  Edge cases     [top 3]                                │
│  Past lessons   [from AUDIT.md or "New territory"]     │
│                                                       │
│  Things you didn't ask for but need:                  │
│  · [Gap 1 — why it matters to users]                  │
│  · [Gap 2 — why it matters to users]                  │
│  · [Gap 3 — why it matters to users]                  │
│                                                       │
└──────────────────────────────────────────────────────┘
```

```
AskUserQuestion(
  question: "Impact analysis complete. Proceed to the plan, or discuss any concerns?",
  options: [
    "(Recommended) Looks thorough — create the plan",
    "I want to address [specific concern] first",
    "This changes my thinking — go back to approaches",
    "Too risky — let's shelve this for now",
    "Chat about this"
  ]
)
```

### Phase 5: Produce Feature Plan

Save the complete plan to `.stp/state/current-feature.md`:

```markdown
# [Work Type]: [Name]

## Summary
[2-3 sentences: what this does, chosen approach, key tradeoff]

## Research Findings
[Key findings that informed the approach — 3-5 bullets]

## Approach: [Chosen Approach Name]
[Brief description + why this over alternatives]

## What you asked for
- [ ] [Core requirement 1]
- [ ] [Core requirement 2]

## What I'm adding (things you'd miss)
- [ ] [Gap 1 — why it matters]
- [ ] [Gap 2 — why it matters]

## Impact on existing features
- [ ] [Update: existing file/feature — what changes]
- [ ] [Update: existing file/feature — what changes]

## Tests to write FIRST
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

## Build order
1. [Database/schema changes]
2. [Write tests FIRST (TDD)]
3. [API / server logic]
4. [Business logic — make tests pass]
5. [UI — pages, components]
6. [Error/edge cases]
7. [Backward integration]
8. [Polish — accessibility, /simplify]

## Risk mitigation
- [Security: what to watch for]
- [Breaking: which tests to run after each step]
- [Performance: what to measure]

## Conventions to follow (from CLAUDE.md)
- [Relevant convention 1]
- [Relevant convention 2]

## Acceptance criteria
- [ ] [AC 1 — testable condition]
- [ ] [AC 2 — testable condition]
```

**Present to user:**

```
╔═══════════════════════════════════════════════════════╗
║  ✓ PROPOSAL READY                                     ║
║  [Work type]: [Name]                                  ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Approach    [Chosen approach]                        ║
║  Scope       [N] new · [N] modified · [N] tests       ║
║  Checklist   [N] items                                ║
║                                                       ║
║  Saved to .stp/state/current-feature.md               ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

```
AskUserQuestion(
  question: "Plan is ready. What do you want to do?",
  options: [
    "(Recommended) Build it now — /stp:work-quick will pick up this plan",
    "Save for later — I'll run /stp:work-quick when ready",
    "Modify the plan — let me adjust something",
    "Discard — I changed my mind",
    "Chat about this"
  ]
)
```

If "Build it now": tell the user to run `/stp:work-quick`. The build command detects the existing `.stp/state/current-feature.md` and skips straight to execution (Step 5) since research and planning are already done.

If "Save for later": the plan persists in `.stp/state/current-feature.md`. `/stp:continue` or `/stp:work-quick` will find it on the next session.

If "Discard": delete `.stp/state/current-feature.md`.

## Rules

- Do NOT write any code. This is planning only.
- Do NOT skip the research phase. The whole point is informed decision-making.
- ALWAYS present multiple approaches. The user's first instinct may not be the best.
- ALWAYS use AskUserQuestion for every decision point (MUST use the tool, not text).
- ALWAYS read ARCHITECTURE.md before proposing how work fits the codebase.
- ALWAYS check AUDIT.md Patterns & Lessons for relevant past bugs.
- ALWAYS surface what the user didn't think of. That's the CTO's job.
- The plan saved to current-feature.md must be compatible with /stp:work-quick's format — same checklist structure so build can execute it directly.
- If the user asks to "just build it" during discussion, redirect: "Let's finish the plan first — 5 more minutes of thinking saves hours of wrong implementation."

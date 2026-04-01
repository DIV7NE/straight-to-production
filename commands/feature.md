---
description: Build a feature autonomously. Opus makes all technical decisions, only asks product questions, and teaches key concepts along the way. Use before starting any non-trivial feature.
argument-hint: What you want (e.g., "add Stripe payments" or "build the user dashboard")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion"]
---

# Pilot: Feature Builder

You are building a feature autonomously. Make all technical decisions. Only interrupt the user for PRODUCT decisions (branding, business logic, user-facing choices). Teach key concepts at decision points so the user learns their own codebase.

## Process

### Step 1: Context

Read CLAUDE.md for project spec, stack, and patterns. Check existing code for established patterns to follow.

If `.pilot/current-feature.md` already exists, ask: "You have an in-progress feature: [title]. Finish that first, or start this new one?"

### Step 2: Enrich

Based on the feature description, identify what the user DIDN'T think of. Read relevant `.pilot/references/` files.

Ask at most ONE product question if a real product decision is needed:
- "The invoice PDF — should it show the freelancer's branding, or just plain data?"
- "When a client pays, email confirmation to both parties?"

If no product decision is needed, skip to the plan. Do NOT ask about implementation.

For significant technical decisions within the feature, briefly note them with backing:

"For payments I'm using Stripe — used by Shopify, Notion, and 90% of SaaS products. Best docs in the industry. Alternative: Paddle handles sales tax automatically but is less flexible. ⚠️ Going Stripe means you handle sales tax yourself if you expand internationally."

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

### Build order
1. [Foundation — what needs to exist first]
2. [Core functionality — the main thing]
3. [Error/edge cases — what happens when things go wrong]
4. [Polish — loading states, empty states, accessibility]

### Standards I'll check
- .pilot/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

### Step 4: Build

When the user says go:

1. Save the checklist to `.pilot/current-feature.md`
2. Work through items in build order
3. Read referenced standard files before the relevant steps
4. After each item: mark `[x]` in `.pilot/current-feature.md`, commit atomically
5. At KEY moments, teach:

   "I'm adding an error boundary here. Quick concept: right now if
   anything crashes inside the dashboard, users see a white screen.
   The error boundary catches the crash and shows a 'Something went
   wrong, try again' message instead. It's like a safety net under
   a tightrope walker."

   Don't explain every line. Only explain CONCEPTS that help the user
   understand how their app works.

6. The Stop hook blocks completion until type checks pass and tests pass.

### Step 5: Complete

1. If any significant technical decisions were made during this feature (library choices, architecture patterns, tradeoffs), append them to the `## Technical Decisions Log` section in `PRD.md`. Format: what was decided, why, alternatives considered.
2. Delete `.pilot/current-feature.md` and `.pilot/handoff.md` if they exist.
3. Commit.

```
Feature complete: [NAME]

━━━ Next step ━━━

Evaluate what you built:
   /pilot:evaluate

Or next feature:
   /pilot:feature [NEXT FEATURE — specific name from spec]
```

ALWAYS fill in specific names.

## Gotchas

- Do NOT ask technical questions. You decide.
- ALWAYS save the checklist to `.pilot/current-feature.md` — this survives compaction.
- Do NOT over-scope. "Add a settings page" doesn't mean also add admin tools, themes, and notifications.
- DO check if patterns already exist in the codebase. Follow established patterns.
- DO read reference files before implementing security, accessibility, or performance-sensitive code.
- Keep teach moments to 2-3 sentences. Explain the concept, not the implementation.

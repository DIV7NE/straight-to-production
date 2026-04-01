---
description: Save your progress and prepare for /clear. Writes a detailed handoff note so the next session resumes instantly. Use when context is getting large or you're done for the day.
argument-hint: No arguments needed
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Pilot: Pause

Write a handoff note for your future self (who has ZERO memory of this conversation).

## Process

### Step 1: Commit Uncommitted Work

```bash
git add -A && git status --short
```

If changes exist, commit: `git commit -m "wip: [specific description]"`

### Step 2: Update Feature Checklist

If `.pilot/current-feature.md` exists, mark completed items `[x]`.

### Step 3: Write Handoff

Create `.pilot/handoff.md` with ALL of:

```markdown
# Handoff — [timestamp]

## What I Was Doing
[Specific: "Building the Stripe webhook handler in src/app/api/webhooks/stripe/route.ts"]

## Current State
[Exactly where things stand. What works, what doesn't yet.]

## Key Decisions Made This Session
[Every non-obvious choice with brief why]

## What's Next (in order)
1. [Exact next step]
2. [After that]
3. [Then]

## Files Modified
[The important ones with brief status]

## Problems / Things That Didn't Work
[So the next session doesn't retry failed approaches]

## How to Verify Current State
[Exact commands to confirm things still work]
```

### Step 4: Tell the User Exactly What to Do

```
Handoff saved. All work committed.

━━━ Next steps ━━━

1. Run this now:
   /clear

2. Then paste this in the new session:
   Continue working on [FEATURE NAME]. Read .pilot/handoff.md for context.
   Next task: [EXACT NEXT TASK from the handoff].
```

ALWAYS fill in specific names and tasks. NEVER use generic placeholders.

## Rules

- Be SPECIFIC, not generic. "Working on payments" is useless. "Implementing webhook signature verification in route.ts" is useful.
- Include FAILED approaches so you don't retry them.
- Include verification commands so the next session can confirm state.
- Keep it readable in 30 seconds — not a novel, not a tweet.

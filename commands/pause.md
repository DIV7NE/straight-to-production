---
description: Write a handoff note and prepare for /clear. Use when the context monitor suggests clearing, or when you're done for the day. Claude writes a detailed note to itself that it will read in the next session.
argument-hint: No arguments needed
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Pilot: Pause (Write Handoff Before /clear)

You are about to hand off to a future version of yourself that has ZERO memory of this conversation. Write a handoff note that lets you resume instantly.

## Process

### Step 1: Commit Uncommitted Work

```bash
git add -A
git status --short
```

If there are changes, commit them with a descriptive message that captures WHAT and WHY:
```bash
git commit -m "wip: [specific description of current state]"
```

### Step 2: Update Feature Checklist

If `.pilot/current-feature.md` exists, update it:
- Mark completed items `[x]`
- Ensure unchecked items are still accurate

### Step 3: Write the Handoff Note

Create or overwrite `.pilot/handoff.md` with ALL of the following:

```markdown
# Handoff — [timestamp]

## What I Was Doing
[Specific: "Implementing the Stripe webhook handler in src/app/api/webhooks/stripe/route.ts"]

## Current State
[Exactly where things stand: "The checkout flow works. Webhook endpoint exists but signature verification is not yet implemented. The UI shows a success page but doesn't wait for webhook confirmation."]

## Key Decisions Made This Session
[Every non-obvious choice: "Used Stripe Checkout (hosted) instead of Elements because the user doesn't need custom UI for payments. Webhook secret stored in STRIPE_WEBHOOK_SECRET env var. Using the svix library for signature verification per Stripe docs."]

## What's Next (in order)
1. [Specific next step: "Implement webhook signature verification in route.ts using constructEvent()"]
2. [After that: "Handle checkout.session.completed event — update user's subscription status in Supabase"]
3. [Then: "Add error handling for failed payments — webhook event payment_intent.payment_failed"]

## Files Modified This Session
[List the important ones:
- src/app/api/webhooks/stripe/route.ts (created, incomplete)
- src/lib/stripe.ts (created, Stripe client setup)
- src/app/checkout/page.tsx (created, working)
- .env.local (added STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET)
]

## Problems / Things That Didn't Work
[Anything the next session should know: "Initial attempt to use stripe.webhooks.constructEvent failed because the raw body wasn't being passed correctly. Fixed by using request.text() instead of request.json(). Don't make this mistake again."]

## How to Verify Current State
[Commands to run: "npm run dev, then visit /checkout. Click 'Subscribe' — should redirect to Stripe Checkout. Use test card 4242... After payment, check webhook logs with stripe listen --forward-to localhost:3000/api/webhooks/stripe"]
```

### Step 4: Tell the Developer EXACTLY What to Do Next

Read the handoff note you just wrote. Based on the "What's Next" section, construct the exact resume command.

Output this EXACTLY (with the specific details filled in):

```
Handoff saved. All work committed.

━━━ Next steps ━━━

1. Run this now:
   /clear

2. Then paste this in the new session:
   Continue working on [SPECIFIC FEATURE NAME]. Read .pilot/handoff.md for full context.
   Next task: [EXACT NEXT TASK from the handoff's "What's Next" section].
```

Example of good output:
```
Handoff saved. All work committed.

━━━ Next steps ━━━

1. Run this now:
   /clear

2. Then paste this in the new session:
   Continue working on Stripe payment integration. Read .pilot/handoff.md for full context.
   Next task: Implement webhook signature verification in src/app/api/webhooks/stripe/route.ts using constructEvent().
```

NEVER output a generic "continue where I left off." ALWAYS include the specific feature name and the specific next task. The user should be able to copy-paste the line from step 2 verbatim.

## Rules
- The handoff note must be SPECIFIC, not generic. "Working on payments" is useless. "Implementing webhook signature verification in src/app/api/webhooks/stripe/route.ts, using constructEvent() from the stripe package" is useful.
- Include FAILED approaches so you don't retry them.
- Include the exact verification commands so the next session can confirm things still work before continuing.
- The note should be readable in 30 seconds — not a novel, but not a tweet.
- This replaces .pilot/state.json for intentional pauses. state.json is the emergency backup (PreCompact hook). This is the planned handoff.

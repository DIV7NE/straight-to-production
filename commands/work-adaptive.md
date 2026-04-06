---
description: "I have work to do, you figure out how thorough to be." Impact scan (files, models, auth paths) → scores complexity → routes to /stp:work-quick or /stp:work-full with evidence → user confirms.
argument-hint: What you want done (e.g., "fix the billing bug", "add PDF export", "rebuild the auth system")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort high`** — Adapts based on scan results.

# STP: Work Adaptive

You are the CTO making a scope assessment. The user described work but wants YOU to decide how thorough the process should be. Your job: measure the actual impact, classify it, and route to the right level — with full transparency about why.

**This is NOT a guess. This is an evidence-based decision.**

## Process

### Step 1: Understand the Request

Read the user's request. Extract:
- **What** they want (feature, fix, refactor, update)
- **Keywords** for the impact scan (domain terms, file names, feature areas)

Read existing context if available:
- `.stp/state/design-brief.md` — was this brainstormed on the whiteboard? If yes, the understanding phase is already done. Use the brief's requirements and scope to inform the impact scan.
- `.stp/docs/PRD.md` — is this feature already defined?
- `.stp/docs/PLAN.md` — is this already planned? Which milestone?
- `.stp/docs/ARCHITECTURE.md` — what exists in this area?

### Step 2: Impact Scan (MANDATORY — the evidence that drives the decision)

Run these checks silently. This takes <5 seconds.

```bash
# 1. How many files would be touched?
FILE_COUNT=$(grep -rl "[keywords]" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" --include="*.rs" --include="*.go" --include="*.cs" --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=target --exclude-dir=.next --exclude-dir=dist . 2>/dev/null | wc -l)

# 2. Are models/schema/migrations involved?
MODEL_FILES=$(grep -rl "[keywords]" --include="*.prisma" --include="*.sql" --include="*migration*" --include="*schema*" --include="*model*" . 2>/dev/null | head -5)

# 3. Are auth/payment/security paths involved?
SECURITY_FILES=$(grep -rl "[keywords]" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.go" . 2>/dev/null | grep -i "auth\|payment\|stripe\|webhook\|middleware\|permission\|role\|token\|secret\|encrypt" | head -5)

# 4. Are new routes/endpoints needed?
ROUTE_FILES=$(grep -rl "[keywords]" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -i "api/\|route\|endpoint\|handler" | head -5)

# 5. Is this in the PRD with acceptance criteria?
PRD_MATCH=$(grep -ci "[keywords]" .stp/docs/PRD.md 2>/dev/null || echo "0")
```

### Step 3: Classify (deterministic rules, no opinions)

Score the task based on scan results:

```
SCORE = 0

if FILE_COUNT > 3:       SCORE += 3
elif FILE_COUNT > 1:     SCORE += 1

if MODEL_FILES not empty: SCORE += 3
if SECURITY_FILES not empty: SCORE += 5   # security = always heavy
if ROUTE_FILES not empty: SCORE += 2
if PRD_MATCH > 0:        SCORE += 1       # it's a planned feature
```

| Score | Classification | Mode | What Happens |
|-------|---------------|------|-------------|
| 0 | Trivial | Inline | Just do it — no command needed. Fix it directly. |
| 1-3 | Quick | `/stp:work-quick` | Context → research → build → QA → ship |
| 4-6 | Moderate | `/stp:work-quick` with extra research | Quick mode but with deeper research step |
| 7+ | Full | `/stp:work-full` | Full architecture cycle — all 22 sub-phases |
| Any security path | Full (FORCED) | `/stp:work-full` | Auth/payments/security = always full. No override. |

### Step 4: Present the Decision (transparent — show the evidence)

```
AskUserQuestion(
  question: "Impact scan complete:
  
  Files affected: [N]
  Models/migrations: [yes/no — list if yes]
  Auth/payments/security: [yes/no — list if yes]  
  New routes: [yes/no — list if yes]
  PRD match: [yes/no]
  
  Score: [N] → [Classification]
  
  Recommendation: /stp:work-[quick/full] because [specific reason from scan]",
  options: [
    "(Recommended) [mode] — [1-line justification from evidence]",
    "[alternative mode] — [when this makes sense]",
    "Override: use /stp:work-quick regardless — I accept reduced planning",
    "Override: use /stp:work-full regardless — I want maximum thoroughness",
    "Chat about this"
  ]
)
```

### Step 5: Execute the Chosen Mode

**If Quick mode selected:** Follow the `/stp:work-quick` process from Step 1 (context) through Step 7 (milestone check). Read `work-quick.md` for the full process.

**If Full mode selected:** Follow the `/stp:work-full` process from Phase 1 (understand) through Phase 6j (milestone check). Read `work-full.md` for the full process.

**If Trivial:** Just do it inline — make the change, run tests, commit. No ceremony needed. Hooks still fire.

## Rules

- **The scan is the evidence, not your opinion.** Never classify based on "this seems simple." Run the scan.
- **Security paths = always full.** No override possible. If auth/payments/security files are touched, it's `/stp:work-full`. Period.
- **Show the numbers.** The user must see the scan results and understand WHY you chose the mode.
- **User can override.** After seeing the evidence, they can choose a different mode. They're informed, not forced.
- **Hooks fire regardless of mode.** Quick, full, or trivial — the 8 enforcement gates run on all code. The mode affects planning depth, not quality enforcement.
- **When in doubt, go heavier.** If the score is borderline (3-4), recommend full. The cost of over-planning is minutes. The cost of under-planning is rework.

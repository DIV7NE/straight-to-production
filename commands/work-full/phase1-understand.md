### Phase 1: UNDERSTAND — What Exactly Does the User Want?

Before researching anything, understand the requirements. The user has an idea — it might be vague, specific, or somewhere in between. Your job is to get clarity.

**Check for existing design brief (from /stp:whiteboard):**
```bash
[ -f ".stp/state/design-brief.md" ] && echo "design_brief: exists" || echo "design_brief: none"
```

**If a design brief exists:** The user already brainstormed this on the whiteboard. Read `.stp/state/design-brief.md` — it has the problem, decision, structured requirements (Given/When/Then), approaches considered, constraints, and scope. Tell the user: "Found a design brief from `/stp:whiteboard` — picking up where the brainstorming left off." Skip to Phase 2 (Context) with the brief's requirements as your input. The understanding phase is already done.

**If a research plan exists (from /stp:research):**
Check `.stp/state/current-feature.md` — if it has research findings + approach + build order, skip to Phase 5 (Plan). Tell the user: "Found a research plan — skipping straight to architecture."

**If neither exists:** proceed with the understanding phase below.

**Scale-adaptive check (evidence-based — not gut feeling):** After understanding the task, run the Impact Scan from CLAUDE.md's Task Routing section:
```bash
# Count files, check for model/migration/auth involvement
grep -rl "[keyword]" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | wc -l
grep -rl "[keyword]" --include="*.prisma" --include="*.sql" --include="*migration*" . 2>/dev/null | head -3
grep -rl "[keyword]" . 2>/dev/null | grep -i "auth\|payment\|stripe\|webhook\|middleware" | head -3
```

**Downshift rules (ALL must be true):**
- Impact scan shows ≤2 files affected
- Zero model/migration changes
- Zero auth/payment/security paths involved
- No new routes or endpoints needed

If ALL true → AskUserQuestion: "Impact scan: [N] files, no models, no auth. This is a quick fix — recommend dropping to `/stp:work-quick` mode. Want to downshift?"
If ANY false → continue with full `/stp:work-full` cycle. No downshift offered.

**Read existing context first:**
- `.stp/docs/PRD.md` — what was already promised? Does this extend or change the PRD?
- `.stp/docs/PLAN.md` — is this already planned? Which milestone?
- `.stp/docs/ARCHITECTURE.md` — what exists that relates to this work?

**Scope decomposition gate (check BEFORE asking questions):**
Before asking detailed questions, assess scope. If the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately:
```
AskUserQuestion(
  question: "This is a multi-subsystem project. I recommend decomposing it before planning any single part. Here are the independent pieces I see: [list]. Which should we build first?",
  options: [
    "(Recommended) [Subsystem A] first — [why: foundation for others]",
    "[Subsystem B] first — [why: highest user value]",
    "Plan all of them together — I want the full architecture",
    "Chat about this"
  ]
)
```
Each subsystem gets its own spec → plan → build cycle. Don't plan a sprawling system in one pass.

**Then ask focused product questions — ONE AT A TIME, ALWAYS via AskUserQuestion.** The user is the PM — ask about WHAT and WHY, never HOW. **Never print numbered options as chat text** — if you catch yourself typing `1. Option A\n2. Option B`, STOP and call AskUserQuestion instead. The only exception is truly freeform input (describe-your-users, paste-an-error) where structured options can't express the answer.

**ONE question per message. Wait for the answer before asking the next.**

Example flow:
```
AskUserQuestion(
  question: "Let me understand exactly what you need. Which of these describes the scope?",
  options: [
    "Change pricing tiers — update plans, prices, features per tier",
    "Add new payment method — support a new way to pay",
    "Rebuild payments end-to-end — new billing system, migration, the works",
    "Something else — let me describe",
    "Chat about this"
  ]
)
```
Wait. Then:
```
AskUserQuestion(
  question: "What's driving this change?",
  options: [
    "Business pivot — new pricing strategy",
    "User feedback — current pricing is confusing",
    "Compliance — legal/regulatory requirement",
    "Something else — let me explain",
    "Chat about this"
  ]
)
```
Wait. Then ask constraints if needed.

**Fill in these details across 2-4 questions (not all at once):**
- **What** exactly changes (features, behavior, data)
- **Why** (business reason — this shapes technical decisions)
- **Who** is affected (users, admins, API consumers)
- **Constraints** (budget, timeline, backward compatibility, data migration)

If uncertain about a technical detail, make the decision yourself (you're the CTO) and note it in the plan for user review.


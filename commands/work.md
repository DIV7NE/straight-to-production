---
description: "I have serious work to do." Full cycle from idea to finished code — asks you what you need, finds and installs tools, researches the best approach, creates a verified plan, then builds everything with TDD. Use when the task is big, complex, or you want the best possible outcome. This is the main command for getting real work done.
argument-hint: What you want done (e.g., "update stripe payments and pricing", "add real-time notifications", "rebuild the entire auth system")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Full development cycle requires maximum thinking depth throughout.

# STP: Develop

The complete development cycle. One command takes you from idea → understanding → tools → research → plan → verified delivery. This is what you run when you want a piece of work done RIGHT — with full investigation, no shortcuts, and production-quality output.

**This handles ANY scope:**
- Single feature: "add PDF invoice export"
- Multi-feature: "update stripe payments and the entire pricing plan"
- System-wide: "rebuild the auth system with role-based access"
- Full project: "build the MVP" (works with /stp:plan's milestones)

## Task Tracking (MANDATORY)

```
TaskCreate("Phase 1: Understand — product discovery")
TaskCreate("Phase 2: Context — codebase + production state")
TaskCreate("Phase 3: Tools — discover and set up needed tools")
TaskCreate("Phase 4: Research — deep dive on implementation")
TaskCreate("Phase 5: Plan — architecture + verification")
TaskCreate("Phase 6: Execute — TDD build")
```

## Process

### Phase 1: UNDERSTAND — What Exactly Does the User Want?

Before researching anything, understand the requirements. The user has an idea — it might be vague, specific, or somewhere in between. Your job is to get clarity.

**Read existing context first:**
- `.stp/docs/PRD.md` — what was already promised? Does this extend or change the PRD?
- `.stp/docs/PLAN.md` — is this already planned? Which milestone?
- `.stp/docs/ARCHITECTURE.md` — what exists that relates to this work?

**Then ask focused product questions using AskUserQuestion.** The user is the PM — ask about WHAT and WHY, never HOW:

Example for "update stripe payments and pricing":
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

Follow up with specifics until you can fill in:
- **What** exactly changes (features, behavior, data)
- **Why** (business reason — this shapes technical decisions)
- **Who** is affected (users, admins, API consumers)
- **Constraints** (budget, timeline, backward compatibility, data migration)

**Keep it to 2-3 questions max.** Don't interrogate — get enough to proceed, then let research fill the gaps. If uncertain about a technical detail, make the decision yourself (you're the CTO) and note it in the plan for user review.

### Phase 2: CONTEXT — Understand the Current State

**Read everything relevant (in parallel):**

| Source | What you're looking for |
|--------|------------------------|
| `.stp/docs/ARCHITECTURE.md` | Full codebase map — what exists in the affected area, dependencies, integrations |
| `.stp/docs/AUDIT.md` | Production issues in this area, past bugs, Sentry errors, Patterns & Lessons |
| `.stp/docs/CHANGELOG.md` | Recent changes to this area — context for what was built and decided |
| `CLAUDE.md` | Project Conventions — rules that apply to this type of work |
| Actual source code | Read the files in the affected area. Trace data flows. Understand the REAL implementation, not just docs. |
| Git history | `git log --oneline -15 -- [affected paths]` — what changed recently? |

**If MCP services are connected, pull production data:**
- Sentry: errors in the affected area
- Stripe: current products, prices, subscriptions (if payment-related)
- Vercel: deployment status, environment variables
- Analytics: user behavior in the affected area (if available)

**Summarize what you found** (2-3 sentences for the user, full details go into the plan):
```
Context gathered: [N] files in the payment area, [current Stripe setup], [N] related Sentry errors,
[last payment change was v0.3.2 on DATE]. Current patterns: [key conventions].
```

### Phase 3: TOOLS — Discover and Set Up What's Needed

**This phase prevents the "I wish I had X" moment mid-build.** Check what tools are available and what SHOULD be available for this type of work.

**Step 1: Check what's already available:**
```bash
# MCP servers (check Claude's connected services)
# The AI should check what MCP tools are available in its current session

# CLIs
which stripe 2>/dev/null && stripe --version
which vercel 2>/dev/null && vercel --version
which prisma 2>/dev/null && prisma --version
# [add relevant CLIs for the work type]
```

**Step 2: Determine what SHOULD be available:**

Based on the work type, identify tools that would significantly help:

| Work involves... | Useful tool | Check |
|-----------------|------------|-------|
| Stripe/payments | Stripe MCP server OR Stripe CLI | Can read products, create test data, verify webhooks |
| Database changes | Prisma CLI, Neon MCP | Can run migrations, inspect schema |
| Deployment | Vercel MCP OR Vercel CLI | Can check deploys, env vars |
| Email | Resend dashboard or API | Can verify templates, check delivery |
| Auth | Clerk dashboard MCP | Can check user configs |
| Error tracking | Sentry MCP | Can read production errors |
| Analytics | PostHog/Clarity MCP | Can check user behavior |

**Step 3: If a useful tool is missing, search and suggest:**

Research what's available:
```
Context7/Tavily: "Claude Code MCP server for [service]" OR "[service] CLI for development"
```

```
AskUserQuestion(
  question: "For this work, a [tool name] would help because [specific benefit]. It's not currently available. Want me to set it up?",
  options: [
    "(Recommended) Yes — install [tool]. [1-line what it enables]",
    "Skip — I'll work without it. [1-line what we lose]",
    "Chat about this"
  ]
)
```

**Step 4: Install if approved:**

For MCP servers:
```bash
claude plugins install [plugin-name]
# OR
claude mcp add [server-name] -- [command]
```

For CLIs:
```bash
npm install -g [package]  # or pip, cargo, etc.
```

**Step 5: Handle session restart if needed:**

Some MCP installations require a session restart. If so:

```
AskUserQuestion(
  question: "[Tool] is installed but needs a session restart to activate. I'll save our progress so you can resume exactly where we left off.",
  options: [
    "(Recommended) Restart now — I'll save state and you can /stp:continue after /clear",
    "Continue without it — I'll work around it",
    "Chat about this"
  ]
)
```

If restart needed:
1. Save current progress to `.stp/state/handoff.md` with:
   - What we're developing
   - Requirements gathered (Phase 1)
   - Context found (Phase 2)
   - Tools installed (Phase 3)
   - "Resume from Phase 4: Research"
2. Tell the user: "Run `/clear` then `/stp:continue`. The new tool will be active and I'll pick up from research."

### Phase 4: RESEARCH — Deep Dive on Implementation

With context gathered and tools ready, research the RIGHT way to do this work.

**Framework/library research (Context7):**
- Query current API docs for every library you'll use
- Check for breaking changes, deprecations, migration guides
- Verify patterns against CURRENT versions (training data may be stale)

**Industry research (Tavily/WebSearch):**
- How do production apps solve this exact problem?
- What are the common mistakes?
- What's the current best practice (2025-2026)?
- Security considerations specific to this type of work

**Codebase patterns (from Phase 2 context):**
- How does the existing code handle similar work?
- What conventions MUST be followed? (from CLAUDE.md Project Conventions)
- What past bugs apply? (from AUDIT.md Patterns & Lessons)

**If MCP tools are available, use them:**
- Stripe MCP: read current products, prices, webhook configs
- Neon MCP: inspect current schema, run test queries
- Sentry MCP: get detailed stack traces for related errors
- Vercel MCP: check environment variables, deployment config

**Security research (MANDATORY for work involving user input, auth, payments, or data):**
- Read relevant `.stp/references/security/` files
- Check OWASP categories that apply
- Research known vulnerabilities for this type of feature

**Present 2-3 approaches with tradeoffs:**

```
AskUserQuestion(
  question: "Based on my research, here are [N] ways to approach this. [Brief summary of each]",
  options: [
    "(Recommended) [Approach A] — [why, for THIS project specifically]",
    "[Approach B] — [different tradeoff]",
    "[Approach C] — [different tradeoff]",
    "None of these — let me describe what I'm thinking",
    "Chat about this"
  ]
)
```

### Phase 5: PLAN — Architecture + Verification

With the chosen approach, create a comprehensive plan.

**For single features:** Create `.stp/state/current-feature.md` with the standard checklist format (compatible with /stp:quick).

**For multi-feature work:** Create or update `.stp/docs/PLAN.md` with milestones, features, and wave execution plans.

The plan must include:
- **What's being built** (from Phase 1 requirements)
- **Architecture fit** (from ARCHITECTURE.md — new files, modified files, data changes, API changes)
- **Impact on existing features** (from dependency map — what could break)
- **Build order** (dependencies determine sequence — what must come first)
- **Test strategy** (what to test, TDD approach for each part)
- **Risk mitigation** (security, breaking changes, performance)
- **Conventions to follow** (from CLAUDE.md Project Conventions)
- **Acceptance criteria** (from Phase 1 — testable conditions that define "done")
- **Wave analysis** (for multi-feature: which features can build in parallel)

**Verify the plan internally:**
- Does every acceptance criterion have a corresponding test?
- Does the build order respect dependencies?
- Are all impacted existing features accounted for?
- Do the conventions from CLAUDE.md apply correctly?
- Does AUDIT.md's Patterns & Lessons have any relevant warnings?

**Present to user:**

```
━━━ Development Plan ━━━

Scope: [what's being built — 1-2 sentences]
Approach: [chosen approach]
Scale: [N] features, [N] files new, [N] files modified
Tests: [N] test cases planned
Milestones: [N] (if multi-feature)

Build order:
  1. [First thing — why first]
  2. [Second — depends on 1]
  ...

Risk: [top concern and mitigation]
Tools: [what we're using — Stripe MCP, CLI, etc.]
```

```
AskUserQuestion(
  question: "Development plan ready. This covers [scope summary]. Proceed?",
  options: [
    "(Recommended) Approved — start building",
    "Modify — I want to adjust [something]",
    "More detail — show me the full plan",
    "Save for later — I'll run /stp:quick when ready",
    "Discard — changed my mind",
    "Chat about this"
  ]
)
```

### Phase 6: EXECUTE — Build With TDD

**This phase follows the exact same process as `/stp:quick` Step 5 onward.**

For approved plans:
1. Save checklist to `.stp/state/current-feature.md` (if not already)
2. **Opus builds foundation** (DB, auth, config) directly
3. **Delegate features to Sonnet executor** via Agent Teams with worktree isolation
4. **Wave-based parallel execution** for independent features
5. **Post-merge**: /simplify, hygiene scan, QA agent, user QA
6. **Complete**: version bump, CHANGELOG, CONTEXT.md, ARCHITECTURE.md update
7. **Capture conventions** in CLAUDE.md if new patterns were established
8. **Update AUDIT.md** if bugs were fixed or lessons learned

For milestone-level work, repeat Phase 6 per milestone with integration tests and Critic evaluation at each milestone boundary.

**After everything is built:**

```
━━━ Development Complete ━━━

What was built: [summary]
Approach: [what was chosen]
Files: [N] created, [N] modified
Tests: [N] new, [N] total — all passing
Type check: clean

Version: [new version]
Conventions added: [N] new rules in CLAUDE.md (if any)
AUDIT.md: [updates made]
ARCHITECTURE.md: [sections updated]

Teach: "[1-2 sentences explaining something the user learned about their codebase through this process]"
```

## Autopilot Mode

When `/stp:autopilot` runs this flow, it operates with these overrides:

| Phase | Interactive mode | Autopilot mode |
|-------|-----------------|----------------|
| Phase 1: Understand | AskUserQuestion | AI interprets from the description. If ambiguous, picks the broadest reasonable scope. |
| Phase 2: Context | Same | Same |
| Phase 3: Tools | AskUserQuestion to install | Auto-install recommended tools. Skip if installation requires interactive auth. |
| Phase 4: Research | AskUserQuestion for approach | AI picks the recommended approach. Logs the decision in the plan. |
| Phase 5: Plan | AskUserQuestion to approve | AI approves its own plan. Logs: "Auto-approved in autopilot mode." |
| Phase 6: Execute | User QA step | Skip user QA. Automated QA agent only. |

The key rule for autopilot: **always pick the recommended option.** Every AskUserQuestion in this flow has a "(Recommended)" choice — autopilot selects it automatically. If no recommendation is clear, pick the safest/most conventional option.

## Rules

- This is the FULL cycle. Do NOT skip phases. Phase 3 (Tools) is new and critical — missing tools mid-build wastes time.
- AskUserQuestion is MANDATORY for all decisions (use the tool, not text).
- The plan from Phase 5 MUST be compatible with /stp:quick's checklist format.
- If the user says "just build it" during Phase 1-4, redirect: "Let me finish the investigation — 10 more minutes of research prevents days of rework."
- For multi-feature work, create milestones in .stp/docs/PLAN.md. For single features, use .stp/state/current-feature.md.
- Phase 3 (Tools) should be FAST — check, suggest, install, move on. Don't spend 10 minutes researching tools.
- If a tool installation requires session restart, save ALL progress to handoff.md. Nothing gathered in Phases 1-3 should be lost.
- Read ARCHITECTURE.md in Phase 2 AND Phase 5. Phase 2 for understanding; Phase 5 for planning the changes.
- Every AskUserQuestion must have a "(Recommended)" option for autopilot compatibility.

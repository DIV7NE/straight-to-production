---
description: "Full development cycle — zero compromise." Complete cycle from idea to shipped code. Cycle: understand → tools → research → UI/UX design system → full architecture blueprint (12 sub-phases: domain research, technical research, system architecture, data models, API design, auth design, error strategy, cross-cutting concerns, test strategy, wave execution, risk mitigation, self-verification) → TDD build with executor agents → QA → Critic evaluation → version bump. Use for features touching 3+ files, new models, auth/payments, or anything where you want the best possible outcome.
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

### Phase 3b: UI/UX DESIGN SYSTEM (when work involves ANY frontend/UI)

If this work touches UI (components, pages, layouts, styling, themes, landing pages, dashboards, forms), this phase is MANDATORY before research:

**Check for ui-ux-pro-max (required companion plugin):**
```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```
If MISSING → install automatically: `npm i -g uipro-cli && uipro init --ai claude`. Do NOT proceed with UI work without it.

**Check for existing design system:**
```bash
[ -f "design-system/MASTER.md" ] && echo "design-system: exists" || echo "design-system: NONE"
```

**If design system exists** → Read `design-system/MASTER.md`. ALL UI code MUST follow its style, colors, typography, layout patterns, and anti-patterns. Check for page-specific overrides in `design-system/pages/`.

**If NO design system exists** → Generate one:

1. Run ui-ux-pro-max to generate recommendations:
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system -p "<Project Name>"
```

2. Write the design preview to `.stp/explore-data.json` as a `designSystem` section (see whiteboard.md for the full JSON format) and start the whiteboard:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```

3. Ask the user to review the preview at localhost:3333 — color swatches, font previews, layout wireframe, style recommendation, and anti-patterns are all rendered live.

4. After approval, persist:
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "<Project Name>"
```

This creates `design-system/MASTER.md` which Phase 6 (Execute) reads before writing any frontend code.

**If the work is NOT UI-related, skip this phase entirely.**

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

### Phase 5: PLAN — Full Architecture Blueprint (zero compromise)

This is the FULL `/stp:plan` cycle embedded in `/stp:work-full`. No shortcuts. Every sub-phase below is mandatory. Write all findings to `.stp/docs/PLAN.md` as you go — if compaction fires, the plan is already on disk.

**For single features:** Also create `.stp/state/current-feature.md` with the standard checklist format.
**For multi-feature work:** `.stp/docs/PLAN.md` is the primary document.

**Visual whiteboard** — offer the whiteboard for live diagrams during planning:

"I'll be designing the architecture with diagrams — user flows, data models, API sequences. Want me to open the visual whiteboard so you can see them live? (http://localhost:3333)"

If accepted:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```

Throughout Phase 5, push all diagrams to `.stp/explore-data.json` — the whiteboard polls every 2 seconds and renders them live. If UI/UX work is involved, the design system preview (color swatches, font samples, layout wireframe) will also render in the whiteboard.

#### 5a. Domain Research

Research what production versions of this type of feature/product actually need. Not the tech — the DOMAIN.
- What do competitors/existing tools do for this?
- What workflows do users expect?
- What edge cases exist? (partial states, failures, concurrent access, undo)
- Legal/compliance requirements if applicable

#### 5b. Technical Research (Context7 + MCP tools)

Before designing: verify the CURRENT state of every technology you'll use. Training data may be stale.
- Framework: Context7 query for latest patterns, breaking changes
- Database/ORM: latest migration patterns, connection pooling, RLS
- Auth: latest middleware pattern, security advisories
- Integrations: latest API versions, deprecated endpoints
- Record findings in PLAN.md `## Technical Research` section

#### 5c. System Architecture

Design components, connections, and data flow. Produce diagrams (Mermaid — push to whiteboard if running):
- **User flow** — how users move through the feature/app
- **System architecture** — frontend, backend, database, external services
- **State diagrams** — for entities with lifecycles (draft→sent→paid→overdue)

#### 5d. Data Models

Design every table/model with fields, types, relationships, indexes:
- ER diagram (Mermaid `erDiagram`)
- Migration files to create + rollback procedures
- Seed data for development/testing

#### 5e. API/Route Design

Design every endpoint with purpose, auth requirements, request/response shapes:
- Sequence diagrams for complex flows (payments, webhooks, multi-step)
- Validation rules per endpoint
- For non-API apps: design the service layer / data access patterns

#### 5f. Auth & Authorization Design (centralized, not per-endpoint)

- Authentication: provider, protected routes, session handling
- Authorization: who can do what, role-based access, row-level security
- Webhook auth: signature verification per webhook endpoint

#### 5g. Error Handling Strategy (centralized, not per-feature)

- Consistent error response format across ALL endpoints
- Error propagation: DB error → catch → log → safe message
- User-facing messages: never stack traces, always next steps
- Error tracking: Sentry/equivalent config

#### 5h. Cross-Cutting Concerns — Feature Touchpoint Map

Map where every feature appears across the ENTIRE app:

| Feature | Database | API | UI Pages | Navigation | Search | Notifications | Dashboard |
|---------|----------|-----|----------|------------|--------|--------------|-----------|
| [Feature] | [table] | [endpoints] | [pages] | [nav links] | [searchable?] | [triggers?] | [widget?] |

This prevents building features in isolation but forgetting to connect them everywhere.

#### 5i. Test Strategy — Spec-First TDD

- **Acceptance criteria as executable specs** — each AC becomes `test("AC: user can ...")`. PRIMARY quality gate.
- **Behavioral tests** — verify user-visible outcomes, not mock interactions
- **Property-based tests** — for financial, auth, data transform invariants
- **Error-path tests** — every error handler must have a test
- **Integration tests** — at least one test per feature that hits real services

#### 5j. Build Order + Wave Execution

- Dependencies determine sequence — what must come first
- **Wave analysis** (for multi-feature): compare file lists, features sharing modified files → different waves
- Within a wave: all features are independent → parallel via executor agents
- Produce dependency graph diagram for whiteboard

#### 5k. Risk Mitigation

- Security: attack surface, auth requirements, data sensitivity
- Breaking changes: what existing features could break
- Performance: potential bottlenecks, N+1 queries, bundle impact
- Conventions: from CLAUDE.md Project Conventions
- Past lessons: from AUDIT.md Patterns & Lessons

#### 5l. Plan Self-Verification

Before presenting, verify internally:
- Does every acceptance criterion have a corresponding executable spec test?
- Does every feature appear in the touchpoint map?
- Does the build order respect dependencies?
- Are all impacted existing features accounted for?
- Do the conventions from CLAUDE.md apply correctly?
- Does AUDIT.md have any relevant warnings?

**Present to user:**

```
━━━ Architecture Blueprint ━━━

Scope: [what's being built — 1-2 sentences]
Approach: [chosen approach]
Scale: [N] features, [N] files new, [N] files modified, [N] models, [N] endpoints
Tests: [N] spec tests, [N] behavioral, [N] property-based, [N] integration
Milestones: [N] (if multi-feature)
Waves: [N] parallel execution waves

Architecture: [1-sentence summary — e.g., "Next.js app router + Supabase RLS + Stripe webhooks"]

Build order:
  Wave 1: [features — why parallel]
  Wave 2: [features — depends on Wave 1]
  ...

Risk: [top concern and mitigation]
Tools: [what we're using — Stripe MCP, Context7, etc.]

Full plan saved to .stp/docs/PLAN.md
```

```
AskUserQuestion(
  question: "Architecture blueprint ready. [N] features across [N] waves. Full plan saved to .stp/docs/PLAN.md. Proceed to build?",
  options: [
    "(Recommended) Approved — start building",
    "Modify — I want to adjust [something]",
    "Review full plan — open .stp/docs/PLAN.md",
    "Save for later — I'll run /stp:work-quick when ready",
    "Discard — changed my mind",
    "Chat about this"
  ]
)
```

### Phase 6: EXECUTE — Build, Verify, Ship (fully self-contained — zero references to other commands)

#### 6a. Save Checklist + Start Dev Server

1. Save the plan to `.stp/state/current-feature.md` with the standard checklist format
2. For multi-feature: also save to `.stp/docs/PLAN.md` with wave execution plan
3. Start the dev server if not already running:
```bash
# Stack-appropriate — npm run dev, python manage.py runserver, cargo run, etc.
npm run dev &
```

#### 6b. Foundation First (Opus builds directly)

Opus builds foundational work that every feature depends on:
- Database setup, migrations, schema changes
- Auth/middleware integration (security-critical)
- Core project configuration (CI, deployment, env setup)
- One-line fixes (typo, config change)

Everything else goes to Sonnet executors.

#### 6c. Wave-Based Parallel Execution

**Wave analysis** (from .stp/docs/PLAN.md dependency graph):
- Read each feature's "Create" and "Modify" file lists
- INDEPENDENT features (zero shared files) → same wave (parallel)
- DEPENDENT features → later wave (sequential)

**Create Agent Teams for each wave:**
```
TeamCreate(name="wave-1-build", description="Milestone [N] Wave 1 parallel build")

Agent(
  name="build-[feature-name]",
  model="sonnet",
  isolation="worktree",
  team_name="wave-1-build",
  run_in_background=true,
  prompt="[focused spec — under 3K tokens]"
)
```

**Executor prompt must include ONLY:**
- Feature name + 1-line summary
- Exact files to CREATE and MODIFY
- Test cases to write FIRST (executable specs from acceptance criteria)
- Acceptance criteria (from PRD.md)
- 2-3 key patterns to follow (from CONTEXT.md)
- Reference to design-system/MASTER.md if UI work

**Executor prompt must NOT include:**
- Full CONTEXT.md, PLAN.md, or reference files (agent reads these itself)
- MCP tool instructions (executors use only: Read, Write, Edit, Bash, Glob, Grep)

Wait for all team members → read reports → TaskUpdate each → shut down team:
```
SendMessage(to="build-[name]", type="shutdown_request")
TeamDelete(name="wave-1-build")
```

**Merge Wave 1** → verify (type check + ALL tests) → update CONTEXT.md → **then create Wave 2 team.**

#### 6d. Review Executor Work

For each executor report:
- Read the report (files created, modified, test count, decisions, issues)
- Review changes: `git diff main...[worktree-branch]`
- Check: does code follow project patterns? Are tests meaningful? Any red flags?
- If issues: fix directly on the branch before merging

Merge:
```bash
git merge [worktree-branch] --no-ff -m "feat: [feature name] (v[VERSION])"
```

After merge: run full type check + ALL tests (not just new ones — catch regressions).

#### 6e. /simplify + Hygiene Scan

Run `/simplify` on combined changes, then scan:
- Remove unused imports, variables, functions
- Remove console.log / print / debug statements
- Remove commented-out code blocks (git has history)
- Remove TODO/FIXME not in PLAN.md
- Check for God files over 300 lines — split them
- Check for duplicate utility functions — consolidate
- Verify .gitignore covers build output, deps, OS files, env files
- Remove empty placeholder files

#### 6f. Review Checkpoint

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
```

```
AskUserQuestion(
  question: "Feature checkpoint — review what was built. Continue or flag issues?",
  options: [
    "(Recommended) Looks good, continue",
    "Something is off — let me explain",
    "Chat about this"
  ]
)
```

#### 6g. Independent QA Agent

Spawn the `stp-qa` agent — it has NEVER seen the build process:
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

- **PASS**: proceed to user QA
- **NEEDS FIXES**: fix every bug, re-spawn QA to verify

#### 6h. Guided Manual QA

Present a test guide to the user:
```
━━━ QA: Test this feature ━━━

What was added/changed:
- [File 1] — [what it does]

How to see it:
[Exact command + URL]

Test these scenarios:
1. [Happy path — exact steps]
2. [Empty state — what shows with no data?]
3. [Error case — submit without required fields]
4. [Edge case — long text, special characters]
5. [Mobile — resize to phone width]
6. [Keyboard — Tab through everything]

Look for: loading states, disabled buttons during submit, helpful error messages.
```

```
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

This is NOT optional. The user must test and approve.

#### 6i. Version Bump + Documentation Update

1. **Bump patch version.** Read `VERSION`, increment patch, write back.
2. **CHANGELOG entry** in .stp/docs/CHANGELOG.md (newest first): summary, changes, tests, decisions, **spec delta** (Added/Changed/Constraints introduced/Dependencies created), stats.
3. **Update .stp/docs/PLAN.md** — mark feature `[x]` with version.
4. **Update .stp/docs/CONTEXT.md** — add new files, schema, routes, patterns, env vars. Keep under 150 lines.
5. **Update .stp/docs/ARCHITECTURE.md** — add new models, routes, components, dependencies.
6. **Update README.md** — features, setup, usage, config. Then VERIFY every claim against actual code.
7. **Capture conventions in CLAUDE.md** — if this feature established a pattern that future development must follow, add it to `## Project Conventions`.
8. **Update AUDIT.md** — if bugs were fixed or lessons learned.
9. Delete `.stp/state/current-feature.md` and `.stp/state/handoff.md`.
10. Commit: `feat: [feature name] (v[VERSION])`

#### 6j. Milestone Check (Automatic)

After completing a feature, check PLAN.md: **is this the last feature in the current milestone?**

If YES:
1. **Bump minor version** (reset patch: 0.1.3 → 0.2.0)
2. **Integration verification** — write and run E2E tests for the milestone's primary workflow
3. **Critic evaluation (Double-Check Protocol):**
```
Agent(
  name="critic-milestone",
  model="sonnet",
  prompt="Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum.
  1. Restate the goal, 2. Define 'complete', 3. List angles, 4. Iteration 1, 5. Iteration 2, 6. Synthesize.
  Grade against .stp/docs/PRD.md + .stp/docs/PLAN.md + 7 criteria + 6-layer verification.
  Run specification verification, test quality analysis, and mutation challenge.
  Flag NET-NEW GAPS: features where infrastructure exists but no UI/API/purchase flow was wired."
)
```
4. **Milestone CHANGELOG entry** with Critic evaluation results
5. **Cross-family review** for security-critical code (if non-Claude models available)
6. Present Critic report + next milestone to user

**After everything is built:**

```
━━━ Development Complete ━━━

What was built: [summary]
Approach: [what was chosen]
Files: [N] created, [N] modified
Tests: [N] spec, [N] behavioral, [N] property-based, [N] integration — all passing
Type check: clean

Version: [new version]
Conventions added: [N] new rules in CLAUDE.md (if any)
Critic evaluation: [PASS/NEEDS WORK/FAIL]
Cross-family review: [done/skipped]
AUDIT.md: [updates made]
ARCHITECTURE.md: [sections updated]
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
- The plan from Phase 5 MUST be compatible with /stp:work-quick's checklist format.
- If the user says "just build it" during Phase 1-4, redirect: "Let me finish the investigation — 10 more minutes of research prevents days of rework."
- For multi-feature work, create milestones in .stp/docs/PLAN.md. For single features, use .stp/state/current-feature.md.
- Phase 3 (Tools) should be FAST — check, suggest, install, move on. Don't spend 10 minutes researching tools.
- If a tool installation requires session restart, save ALL progress to handoff.md. Nothing gathered in Phases 1-3 should be lost.
- Read ARCHITECTURE.md in Phase 2 AND Phase 5. Phase 2 for understanding; Phase 5 for planning the changes.
- Every AskUserQuestion must have a "(Recommended)" option for autopilot compatibility.

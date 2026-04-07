---
description: "I have serious work to do, do it properly." Understand → tools → research → UI/UX design system → full architecture blueprint (13 sub-phases with section-by-section approval) → TDD build with executor agents → QA agent → manual QA → Critic evaluation (Double-Check Protocol) → version bump + docs.
argument-hint: What you want done (e.g., "update stripe payments and pricing", "add real-time notifications", "rebuild the entire auth system")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Full development cycle requires maximum thinking depth throughout.

# STP: Develop

The complete development cycle. One command takes you from idea → understanding → tools → research → plan → verified delivery. This is what you run when you want a piece of work done RIGHT — with full investigation, no shortcuts, and production-quality output.

**Context window management:** This command runs 22+ sub-phases in a single session. If the Context Mode MCP (`ctx_execute`, `ctx_batch_execute`) is available, use it for any operation that produces large output (codebase analysis, test runs, grep results, subagent reports). This keeps raw data in the sandbox and only your summary enters the context window, extending session life before compaction fires.

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

**Then ask focused product questions — ONE AT A TIME.** The user is the PM — ask about WHAT and WHY, never HOW. Prefer multiple choice when possible.

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

### Phase 2: CONTEXT — Understand the Current State

**Read everything relevant (in parallel):**

| Source | What you're looking for |
|--------|------------------------|
| `.stp/docs/ARCHITECTURE.md` | Full codebase map — what exists in the affected area, dependencies, integrations |
| `.stp/docs/PRD.md` `## System Constraints` | **MANDATORY enforcement gate.** SHALL/MUST rules added by past features and bug fixes via delta merge-back. List every constraint that applies to this feature's surface area — each becomes a non-negotiable check during build AND a verification point during the Critic pass. Constraints are how STP prevents repeating past bugs. |
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

3. **STOP and wait for the user to review.** Do NOT continue until the user has seen the whiteboard and approved.

```
AskUserQuestion(
  question: "Design system preview is live at http://localhost:3333 — take a look at the colors, fonts, layout, and style. Is this how you imagined it?",
  options: [
    "Yes, this is what I had in mind — continue",
    "Close but needs changes — [describe what to adjust]",
    "Not what I imagined — try a different direction",
    "Chat about this"
  ]
)
```

If changes requested → regenerate, update explore-data.json, ask again. Iterate until approved.

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
- **What system constraints MUST be enforced?** (from PRD.md `## System Constraints` — SHALL/MUST rules from past features and bug fixes; each is a non-negotiable check)
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

```
AskUserQuestion(
  question: "I'll be designing the architecture with diagrams — user flows, data models, API sequences. Want me to open the visual whiteboard so you can see them live in your browser?",
  options: [
    "(Recommended) Yes, open the whiteboard at http://localhost:3333",
    "No, just show diagrams in the terminal",
    "Chat about this"
  ]
)
```

If accepted:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```

Wait for the user to confirm they've opened http://localhost:3333 before proceeding. Diagrams will update live as each sub-phase completes — the user watches the architecture take shape in real time. Each section still gets its own approval gate in Phase 5m.

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
- **System constraints: from PRD.md `## System Constraints` — list every SHALL/MUST that applies to this work, and the specific check/test that enforces it**
- Past lessons: from AUDIT.md Patterns & Lessons

#### 5l. Plan Self-Review (automated completeness check before user sees it)

Before presenting ANY section to the user, run this self-review:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, vague requirements like "handle errors appropriately"? Fix them with concrete specifics.
2. **Internal consistency:** Do any sub-phases contradict each other? Does the data model match the API design? Does auth design match the route protection?
3. **Scope check:** Is this focused enough for a single build cycle, or does it need decomposition into sub-projects?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? Pick one and make it explicit.
5. **YAGNI check:** Did you add features the user didn't ask for? Remove them unless they're security/auth/error-handling essentials.
6. **Spec coverage:** Does every acceptance criterion have a corresponding executable spec test in the test strategy?
7. **Touchpoint completeness:** Does every feature appear in the cross-cutting concerns map?
8. **Convention compliance:** Do the conventions from CLAUDE.md apply correctly?
9. **Constraint compliance:** Does the plan satisfy every applicable rule in PRD.md `## System Constraints`? List each constraint and the specific check/test that enforces it. Missing constraint enforcement = REJECT and rework the plan.
10. **Lesson check:** Does AUDIT.md Patterns & Lessons have any relevant warnings?

Fix any issues inline. Don't present known gaps to the user.

#### 5m. Section-by-Section Design Approval (incremental, not dump-all-at-once)

**Do NOT present the entire architecture blueprint in one message.** Present each major section, get approval, then move to the next. This catches misunderstandings early before they compound.

**Present in this order, one section per message:**

**Section 1: System Architecture (5c)**
```
┌─── Architecture: System Design ──────────────────────┐
│                                                       │
│  Components:    [list with 1-line purpose each]       │
│  Data flow:     [how data moves through the system]   │
│  Integrations:  [external services]                   │
│                                                       │
│  [Mermaid diagram pushed to whiteboard if running]    │
│                                                       │
└──────────────────────────────────────────────────────┘
```
```
AskUserQuestion(
  question: "System architecture — does this structure make sense?",
  options: [
    "Looks right, continue to data models",
    "Change something — [describe]",
    "Chat about this"
  ]
)
```

**Section 2: Data Models + API Design (5d + 5e)**
```
┌─── Architecture: Data & API ─────────────────────────┐
│                                                       │
│  Models:      [fields, types, relationships]          │
│  Endpoints:   [routes with auth, request/response]    │
│  Migrations:  [what changes in the database]          │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**Section 3: Auth + Error Handling + Security (5f + 5g + 5k)**
```
┌─── Architecture: Auth & Safety ──────────────────────┐
│                                                       │
│  Auth model:       [provider, routes, authz matrix]   │
│  Error strategy:   [format, propagation, tracking]    │
│  Security risks:   [attack surface, mitigations]      │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**Section 4: Build Plan + Tests (5i + 5j + 5h)**
```
┌─── Architecture: Execution Plan ─────────────────────┐
│                                                       │
│  Tests:    [N] spec · [N] behavioral · [N] property   │
│  Waves:    Wave 1 → Wave 2 → ...                      │
│  Touches:  [touchpoint map summary]                   │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**After all sections approved, present the summary:**
```
╔═══════════════════════════════════════════════════════╗
║  ✓ ARCHITECTURE BLUEPRINT COMPLETE                    ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Scope     [1-2 sentences]                            ║
║  Scale     [N] features · [N] new · [N] modified      ║
║  Models    [N] · Endpoints [N]                        ║
║  Tests     [N] total planned                          ║
║  Waves     [N] parallel execution waves               ║
║                                                       ║
║  Saved to .stp/docs/PLAN.md                           ║
║  All sections approved. Ready to build.               ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

```
AskUserQuestion(
  question: "All architecture sections approved. Proceed to build?",
  options: [
    "(Recommended) Start building — launch Phase 6",
    "Review full plan in .stp/docs/PLAN.md first",
    "Save for later — I'll run /stp:work-quick when ready",
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

**Merge Wave 1** → verify base SHA → merge → verify (type check + ALL tests) → update CONTEXT.md → **then create Wave 2 team.**

> **Pre-merge base check is mandatory** (see 6d). Never `git merge` a worktree branch without confirming its merge-base equals current trunk HEAD — trunk can shift between spawn and merge, and a silent stale-base merge produces green tests over corrupt state.

#### 6d. Review Executor Work

For each executor report:
- Read the report (files created, modified, test count, decisions, issues)
- Review changes: `git diff main...[worktree-branch]`
- Check: does code follow project patterns? Are tests meaningful? Any red flags?
- If issues: fix directly on the branch before merging

Merge — but verify the worktree base FIRST:
```bash
# Pre-merge safety check: confirm worktree is rooted at current trunk.
# Catches the failure mode where trunk moves between spawn and merge —
# without this check, stale work merges silently into a moved trunk.
TRUNK="main"  # adjust per project (master, develop, etc.)
TRUNK_HEAD=$(git rev-parse "$TRUNK")
WORKTREE_BASE=$(git merge-base "$TRUNK" [worktree-branch])
if [ "$WORKTREE_BASE" != "$TRUNK_HEAD" ]; then
  echo "ABORT: [worktree-branch] is not rooted at current $TRUNK ($TRUNK_HEAD)."
  echo "  merge-base = $WORKTREE_BASE — $TRUNK has moved since spawn."
  echo "  Action: rebase the worktree onto $TRUNK, or skip and re-spawn."
  exit 1
fi

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
╔═══════════════════════════════════════════════════════╗
║  ✓ FEATURE COMPLETE                                   ║
║  [Feature Name] (v[X.Y.Z])                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Built:                                               ║
║  · [Summary of what the executor created]             ║
║  · [Backward integration changes]                     ║
║                                                       ║
║  What's different now:                                ║
║  · [What the user would SEE in the app]               ║
║                                                       ║
║  Tests    [N] new · [N] total · all passing           ║
║  Types    clean                                       ║
║  Hooks    8/8 gates passed                            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
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
┌─── Manual QA Guide ──────────────────────────────────┐
│                                                       │
│  What was added/changed:                              │
│  · [File 1] — [what it does]                          │
│                                                       │
│  How to see it:                                       │
│  · [Exact command + URL]                               │
│                                                       │
│  Test these scenarios:                                │
│  1. [Happy path — exact steps]                        │
│  2. [Empty state — what shows with no data?]          │
│  3. [Error case — submit without required fields]     │
│  4. [Edge case — long text, special characters]       │
│  5. [Mobile — resize to phone width]                  │
│  6. [Keyboard — Tab through everything]               │
│                                                       │
│  Look for: loading states, disabled buttons,          │
│  helpful error messages                               │
│                                                       │
└──────────────────────────────────────────────────────┘
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
3. **Delta merge-back (MANDATORY).** Merge spec delta into canonical docs:
   - **Added** items → add to ARCHITECTURE.md (new models, routes, components)
   - **Changed** items → update ARCHITECTURE.md (replace outdated assumptions)
   - **Constraints introduced** → add to PRD.md `## System Constraints` section
   - **Dependencies created** → update ARCHITECTURE.md Feature Dependency Map
   - **New SHALL/MUST requirements** → add as Given/When/Then scenarios to PRD.md
   - **Update vs new:** same intent + >50% overlap → update existing scenarios. New intent → add new scenarios. Uncertain → add.
4. **Update .stp/docs/PLAN.md** — mark feature `[x]` with version.
5. **Update .stp/docs/CONTEXT.md** — add new files, schema, routes, patterns, env vars. Keep under 150 lines.
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
  prompt="Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum + claim verification.
  1. Restate the goal, 2. Define 'complete', 3. List angles, 4. Iteration 1, 5. Iteration 2, 5.5. Verify Behavioral Claims (trace execution paths for any 'broken/fails/doesn't work' finding — downgrade unreachable code from FAIL to NOTE), 6. Synthesize.
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
╔═══════════════════════════════════════════════════════╗
║  ✓ DEVELOPMENT COMPLETE                               ║
║  [Feature Name]   v[X.Y.Z]                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Built          [summary]                             ║
║  Approach       [what was chosen]                     ║
║  Files          [N] created · [N] modified            ║
║  Tests          [N] spec · [N] behavioral ·           ║
║                 [N] property · [N] integration        ║
║  Types          clean                                 ║
║                                                       ║
║  Conventions    [N] new rules in CLAUDE.md            ║
║  Critic         [PASS/NEEDS WORK/FAIL]                ║
║  Cross-family   [done/skipped]                        ║
║  AUDIT.md       [updates made]                        ║
║  ARCHITECTURE   [sections updated]                    ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
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

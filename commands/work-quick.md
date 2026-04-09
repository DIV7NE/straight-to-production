---
description: "Just do it, skip the ceremony." Context → inline research → plan checklist → TDD build → /simplify → QA agent → manual QA → version bump + docs. Hooks still fire. Auto-suggests upgrading to /stp:work-full if research reveals unexpected complexity.
argument-hint: What you want (e.g., "add Stripe payments", "fix the Sentry errors on /dashboard", "refactor auth middleware", "update invoice PDF export")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort high`** — Standard thinking depth for orchestration and review.



# STP: Builder

You are building, fixing, refactoring, or updating code using test-driven development. Tests come BEFORE implementation. Make all technical decisions. Only interrupt the user for PRODUCT decisions. Teach key concepts along the way.

## Profile Resolution (MANDATORY — runs before any sub-agent spawn)

Resolve sub-agent model assignments from the active STP profile. Single source of truth is `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs`. Run **once** at orchestration start:

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
```

Output:
```
STP_PROFILE=...
STP_MODEL_EXECUTOR=...     (sonnet | inherit)
STP_MODEL_QA=...
STP_MODEL_CRITIC=...        (sonnet | haiku | inherit)
STP_MODEL_CRITIC_ESCALATION=...
STP_MODEL_RESEARCHER=...    (sonnet | inline)
STP_MODEL_EXPLORER=...
STP_CLEAR_DISCIPLINE=...
STP_CONTEXT_MODE_LEVEL=...
STP_RESEARCHER_MANDATORY=...
STP_EXPLORER_MANDATORY=...
STP_MAX_MAIN_KB=...
```

**Sentinels:**
- `inherit` → omit `model=` from `Agent()` spawn (use parent session model)
- `inline`  → do NOT spawn a sub-agent; main session does the work
- `sonnet` / `opus` / `haiku` → pass literally as `model=` parameter

If `STP_RESEARCHER_MANDATORY=true`, every Context7/Tavily/WebSearch call MUST be delegated to a fresh `stp-researcher` sub-agent. If `STP_EXPLORER_MANDATORY=true`, every multi-file Glob/Grep MUST be delegated to a fresh `stp-explorer` sub-agent. See `${CLAUDE_PLUGIN_ROOT}/references/profiles.md` for details.

**This command handles ALL work types:**
- **New feature**: "add Stripe payments" → full research, TDD, architecture integration
- **Bug fix**: "fix the Sentry errors on /dashboard" → reproduce first, write failing test, fix, verify
- **Refactor**: "refactor auth middleware" → read ARCHITECTURE.md for dependency map, ensure nothing breaks
- **Update**: "update invoice PDF export to use new template" → trace existing flow first, modify with tests
- **Remediation**: "fix the 5 critical issues from AUDIT.md" → read AUDIT.md, prioritize, TDD each fix

## Task Tracking (MANDATORY)

Use `TaskCreate` and `TaskUpdate` to track EVERY step visibly. The user sees real-time progress in their terminal.

**At the START, create tasks from the feature checklist:**
```
TaskCreate("Research: codebase + impact + security + resilience")
TaskCreate("Write tests (TDD)")
TaskCreate("[Checklist item 1 from feature plan]")
TaskCreate("[Checklist item 2]")
TaskCreate("[Checklist item 3]")
...
TaskCreate("/simplify code review")
TaskCreate("Hygiene scan")
TaskCreate("QA Agent testing")
TaskCreate("User QA approval")
TaskCreate("Version bump + docs update")
```

**As you work:** `TaskUpdate` each to `in_progress` when starting, `completed` when done. If you discover additional work needed during building (backward integration, unexpected fix, tech debt), `TaskCreate` a new task for it immediately — don't let it slip through.

**When spawning subagents (executor, QA):** The task should show the subagent's `activeForm` (e.g., "Building: Invoice CRUD via executor agent").

## Process

### Step 1: Context

Read .stp/docs/PLAN.md for this feature's requirements, test cases, and dependencies. Read CLAUDE.md for stack patterns AND the `## Project Conventions` section — these are the project-specific rules that MUST be followed. Every convention was earned through a decision or a bug. Violating them means repeating history.

**Read .stp/docs/PRD.md `## System Constraints` — MANDATORY enforcement gate.** Every constraint in this section is a SHALL/MUST rule the system must follow forever. They were added by previous features and bug fixes via delta merge-back. Examples: "system MUST scope all multi-tenant queries by `organizationId`", "uploads MUST validate MIME type server-side". Before writing any code, list every constraint that applies to this feature's surface area. Each one becomes a non-negotiable check during build AND a verification point during QA. If a constraint conflicts with the new feature, surface it to the user with `AskUserQuestion` — do not silently violate it. Constraints are how STP prevents repeating past bugs.

If .stp/docs/PLAN.md exists and this feature is listed, use the plan's test cases and dependencies. If .stp/docs/PLAN.md doesn't exist or this feature isn't in it, create the plan inline (but recommend running `/stp:plan` first for complex projects).

**Check for existing design brief (from /stp:whiteboard):**
```bash
[ -f ".stp/state/design-brief.md" ] && echo "design_brief: exists" || echo "design_brief: none"
```
If a design brief exists: read it — the user already brainstormed the problem, decision, structured requirements, and scope. Use the brief's requirements as context and skip directly to Step 2 (Research). Tell the user: "Found a design brief from `/stp:whiteboard` — using its requirements and jumping to research."

If `.stp/state/current-feature.md` already exists, check if it was created by `/stp:research`:

**If it has research findings + approach + build order (from /stp:research):**
The plan is already done — research, approaches, architecture fit, impact analysis are complete. Skip straight to Step 5 (Build). Tell the user: "Found a plan from /stp:research — picking up where the discussion left off."

**If it's a feature in progress (has [x] checked items):**
```
AskUserQuestion(
  question: "There's an active feature in progress: [name] ([done]/[total] items). What do you want to do?",
  options: [
    "(Recommended) Finish [existing feature] first — picking up is faster than context-switching",
    "Abandon it, start [new feature] — mark old one incomplete",
    "Chat about this"
  ]
)
```

### Step 1b: UI/UX Design System (when building ANY frontend/UI work)

If this feature touches UI (components, pages, layouts, styling, themes, landing pages, dashboards, forms), this step is MANDATORY and **enforced by `hooks/scripts/ui-gate.sh`** — Write/Edit on any new `*.html`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`, or `*.css` file will be **BLOCKED by the Claude Code PreToolUse hook** until `.stp/state/ui-gate-passed` exists. Markdown "MUST" is a suggestion; the hook is the enforcement. Closes v0.3.1 AI-slop-landing-page failure.

**Check for ui-ux-pro-max (required companion plugin):**
```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```
If MISSING → install automatically: `npm i -g uipro-cli && uipro init --ai claude`. Do NOT proceed with UI work without it.

**Check for existing design system (glob any nested MASTER.md):**
```bash
# Find ANY design-system/**/MASTER.md — supports nested per-page systems
# like design-system/landing/MASTER.md or design-system/dashboard/MASTER.md
FOUND_MASTER=$(find design-system -maxdepth 4 -name "MASTER.md" -type f 2>/dev/null | head -1)
if [ -n "$FOUND_MASTER" ]; then
  echo "design-system: found at $FOUND_MASTER"
else
  echo "design-system: NONE"
fi
[ -f ".stp/whiteboard-data.json" ] && grep -q "designSystem" .stp/whiteboard-data.json 2>/dev/null && echo "whiteboard-preview: exists" || echo "whiteboard-preview: NONE"
```

Also check whether the user's request explicitly referenced a MASTER.md path (e.g. "using design-system/foo/MASTER.md"). If so, that path is the authoritative design system for this feature — treat it the same as if the find command returned it.

**If a design system exists (either found by find or referenced in the user prompt)** → Read the MASTER.md fully, then proceed to the **design-consultation step** below. You still owe the user a summary and approval even when MASTER.md already exists. Reading tokens is not the same as a design consultation.

**If NO design system exists** → Generate one BEFORE writing any frontend code.

**First, start the whiteboard server** — BEFORE generating anything. The user should have the URL open before any data arrives. Do NOT ask permission; this is mandatory whenever design generation runs:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```
Then print the LOUD unmissable banner via the Bash tool — this MUST be the last thing on screen before the design system generates:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/whiteboard-banner.sh" "Design system will populate in a few seconds."
```

**Then generate the design system:**
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system --persist -p "<Project Name>"
```

**Then write the design preview section to `.stp/whiteboard-data.json`** (see whiteboard.md for the JSON format). The server polls every 2 seconds — the preview will render in the browser within moments of the write.

**Design consultation (REQUIRED even when MASTER.md already exists):**

Before any UI Write can succeed, you must state — in one message to the user — the following:
1. Which MASTER.md you're following (full path)
2. The layout pattern you plan to use (e.g. "Minimal Single Column", "Swiss asymmetric grid", "Bento")
3. The color + typography direction in one sentence
4. A one-line anti-slop commitment: explicitly name the AI-slop tells you will NOT use (gradient text on headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand marks, template copy like "without the X headache", center-everything layouts)

Then **STOP and wait for the user to review**. Do NOT continue until approved.

```
AskUserQuestion(
  question: "Design direction for [feature]: following [MASTER.md path], [layout pattern], [color/type direction]. Anti-slop commitments: no gradient headlines, no beta pills, no boxed benefit cards, no sparkles logo, no template copy, no center-everything. Approve?",
  options: [
    "(Recommended) Approve — proceed with this direction",
    "Close — adjust [describe what to change]",
    "Try a different direction",
    "Chat about this"
  ]
)
```

If changes requested → revise, re-present, ask again. Iterate until approved.

**On approval, release the UI gate** (this is what unblocks `hooks/scripts/ui-gate.sh` for the session):
```bash
mkdir -p .stp/state && touch .stp/state/ui-gate-passed
```
The marker is wiped automatically on `/clear` (via the SessionStart hook), so the next fresh session re-confirms design direction. `hooks/scripts/anti-slop-scan.sh` continues to monitor the actual written output even after the gate is released — any two high-confidence slop tells (gradient headline + template copy, etc.) will block the PostToolUse stage.

**If the feature is NOT UI-related, skip this step entirely.** The ui-gate hook only triggers on UI file types, so non-UI work is never blocked.

### Step 2: Research (BEFORE building — comprehensive, not optional)

This is the most important step. Skip this and you ship broken, insecure, disconnected code.

**Scale-adaptive upshift (evidence-based — MANDATORY check):** After research, run the Impact Scan:
```bash
# How many files will this actually touch?
grep -rl "[feature keywords]" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | wc -l
# Any model/migration/auth involvement?
grep -rl "[feature keywords]" --include="*.prisma" --include="*.sql" --include="*migration*" . 2>/dev/null | head -3
grep -rl "[feature keywords]" . 2>/dev/null | grep -i "auth\|payment\|stripe\|webhook\|middleware" | head -3
```

**Upshift is MANDATORY (not optional) if ANY of these are true:**
- 3+ files affected
- Any model/migration changes needed
- Any auth/payment/security paths involved
- New API routes or endpoints needed

If upshift triggered:
```
AskUserQuestion(
  question: "Impact scan: [N] files, [models: yes], [auth: yes]. This needs the full architecture cycle. Recommend upgrading to /stp:work-full ",
  options: [
    "(Recommended) Upgrade to /stp:work-full — full architecture cycle",
    "Continue with /stp:work-quick — I accept the risk",
    "Chat about this"
  ]
)
```

If the user chooses to continue with `/stp:work-quick` despite the scan, proceed but note: the hooks still fire on all code. The user is accepting reduced planning, not reduced enforcement.

**A. Architecture Context — understand what EXISTS before touching anything**

Read `.stp/docs/ARCHITECTURE.md` first (if it exists). This is the full codebase map. From it, identify:
- What directories/files exist near the feature you're building
- What models, routes, components are related to this feature
- What external integrations might be affected
- What patterns and conventions MUST be followed
- What features DEPEND on the code you'll be touching (Feature Dependency Map)

If ARCHITECTURE.md doesn't exist, read `.stp/docs/CONTEXT.md` for the concise version.

Then deep-dive into the actual code:
- Read 3-5 representative files in the area you'll be modifying — learn the ACTUAL patterns, don't assume
- Trace the data flow: UI → API → database for related features
- Find existing functions, types, utilities you should REUSE (don't duplicate)
- Check: does a similar pattern already exist? Follow it, don't invent a new one
- Find existing variables, constants, config that the new feature should reference

**B. Impact Analysis — what does this feature touch?**

Read `.stp/docs/ARCHITECTURE.md`'s Feature Dependency Map + `.stp/docs/PLAN.md`'s Feature Touchpoint Map:
- Which existing features DEPEND on code you'll modify? (these could break)
- Which existing pages need to show data from this feature?
- Which existing API endpoints need to return this feature's data?
- Does the dashboard need updating? Navigation? Search? Notifications?
- List EVERY file that needs modification to connect this feature
- These become checklist items (backward integration)

**C. Research — what's the RIGHT way to do this?**

> **PROFILE-AWARE RESEARCH ROUTING (MANDATORY).** If `STP_RESEARCHER_MANDATORY=true` (balanced-profile, budget-profile), the main session **MUST NOT** call Context7/Tavily/WebSearch/WebFetch directly. **All external research MUST be delegated** to a fresh `stp-researcher` sub-agent per question. The sub-agent runs in its own 200K context and returns a ≤30 line summary with citations. If `STP_RESEARCHER_MANDATORY=false` (intended-profile), run the queries directly in the main session as described below.

Research the RIGHT approach using STP's required MCP tools:

1. **Context7** (HIGH trust) — query `resolve-library-id` then `query-docs` for every library/framework you'll use. Verify patterns against CURRENT versions.
2. **Tavily** (HIGH trust) — use `tavily_search` or `tavily_research` for: industry best practices, "how do production apps solve [this problem]", security advisories, common mistakes. This is your deep research tool.
3. **Official documentation** (HIGH trust) — read the docs, not training data
4. **AI training data** (LOWEST trust) — only when MCP tools return nothing

**Researcher spawn pattern** (fires only when `STP_RESEARCHER_MANDATORY=true`):
```
Agent(
  name="research-<short-topic>",
  subagent_type="stp-researcher",
  # If STP_MODEL_RESEARCHER == "inherit", omit model. If "sonnet", add: model="sonnet"
  prompt="<specific question, ≤2K tokens, includes: what to look up, why it matters, ≤30 line summary with 3 citations>"
)
```

Accumulate returned summaries into a `Research Notes` section in the main session before proceeding.

**Adapt research to work type:**
- **New feature**: Context7 for API patterns + Tavily for "how do Stripe/Shopify/Notion solve this?" + security considerations
- **Bug fix**: What's the ROOT CAUSE, not just the symptom? Is this a one-off or a pattern? Are there OTHER places with the same bug? (grep for similar code)
- **Refactor**: Context7 for latest framework migration guides + Tavily for modern/idiomatic approach
- **Update**: Context7 for changelog/breaking changes + Tavily for migration patterns others have used

**D. Learn from Past Bugs — don't repeat known mistakes**

Read `.stp/docs/AUDIT.md` — specifically the `## Patterns & Lessons` and `## Bug Fixes` sections. For the area you're building in:
- Are there KNOWN bug patterns that apply? (e.g., "server actions don't inherit auth context")
- Were there past bugs in related code? What was the root cause?
- What defense layers were added? Make sure your new code respects them.
- Are there rules like "always scope queries by orgId" that apply to your new code?

This is how the codebase learns. Past debugging work becomes a checklist for new development. If you're writing a new server action and AUDIT.md says "server actions need explicit orgId" — you add it from the start, not after a bug report.

**E. Security Research — what can go wrong?**

Read `.stp/references/security/ai-code-vulnerabilities.md` BEFORE writing code. Then for THIS specific feature:
- What OWASP category does this feature touch? (auth → A01, user input → A03, etc.)
- What are the known security mistakes for this type of feature?
- What validation is required? Where? (server-side, always)
- What secrets/credentials does this feature handle? How are they stored?
- Can a user manipulate this feature to access another user's data? (IDOR check)
- **Race conditions:** Can concurrent requests cause double-spend, double-booking, or duplicate records? If yes → database transactions + locking
- **Mass assignment:** Are you spreading request body into DB operations? Pick allowed fields explicitly.
- **Timing attacks:** Are you comparing tokens or secrets? Use timing-safe comparison.
- **Data privacy:** Does this feature collect/store PII? What's the retention period? Can it be fully deleted (GDPR)?
- **Resource exhaustion:** Are all inputs bounded? (max payload, max items, pagination, timeouts)
- **Error leakage:** Do error responses reveal internal state? Different messages for "not found" vs "wrong password"?
- Read `.stp/references/security/` files relevant to this feature

**F. Resilience Research — what if things fail?**

- What happens when the database is slow or down?
- What happens when external services fail? (Stripe, email, storage)
- Is there a failure scenario where money is taken but no record is created? (saga pattern needed)
- Should external calls have retry logic? (exponential backoff, max 3 retries)
- Can the app still function partially if a non-critical service is down? (graceful degradation)
- What's the timeout for every external call? (never infinite — 10-30 seconds max)

**G. Edge Cases + What Could Break**

- What happens when the input is empty? Too large? Malformed?
- What happens during network failure? Database timeout? External service down?
- What happens with concurrent access? (two users editing the same resource)
- Which existing tests might fail after this change?
- What are the 3 most likely failure modes for this feature?

**H. Scope Expansion + Improvement Opportunities**

The user doesn't know what they don't know. YOUR job is to find what they missed:

- **New feature**: Which existing features could BENEFIT from this? What existing code is incomplete that this feature completes? Present improvements: "While building Purchase Orders, I noticed the Supplier page has no order history. I'll add that too — it makes the app feel connected."
- **Bug fix**: Are there OTHER instances of this same bug? (grep for the pattern). Is the bug a symptom of a deeper architectural issue? If so, recommend the structural fix, not a band-aid. Check AUDIT.md — are there related Sentry errors that share the same root cause?
- **Refactor**: What ELSE uses the old pattern? Should the refactor extend to all instances? What downstream code needs updating? Read ARCHITECTURE.md's Feature Dependency Map — what depends on what you're changing?
- **Update**: What other code uses the same dependency/API? Should the update be applied project-wide? Are there deprecated patterns that should be cleaned up while you're here?

Always present scope expansions to the user — don't just silently add work. Explain why it matters.

**I. Anti-Hallucination Verification**

Before finalizing the feature plan:
- Verify every import/package you plan to use actually EXISTS in the registry
- Verify every function/method you plan to call EXISTS in that package's current version
- If using an API, verify the endpoint/method signature against Context7 or official docs
- If using a config option, verify it's real (not hallucinated from training data)

  ┊ I'm doing thorough research before writing any code — checking what exists, how this should work, verifying every package is real, checking for security vulnerabilities. Takes minutes, prevents days of fixing mistakes.

### Step 3: Enrich + Correct the User

Based on ALL the research above, identify what the user DIDN'T think of. Read relevant `.stp/references/` files.

**If the user's approach is wrong, say so.** You are the CTO — don't blindly implement bad ideas. Present the researched, proven approach.

**Examples by work type:**
- **Feature**: "You asked for a simple password field, but the industry standard is OAuth. Here's why: [Stripe/Shopify do it this way because...]. The downside of passwords is [security risk]."
- **Bug fix**: "You asked me to fix the undefined constant on /dashboard. But this is actually 6 related errors across 3 routes, all caused by the same missing export. I'll fix the root cause — not just the one you noticed."
- **Refactor**: "You asked to refactor auth middleware. Looking at ARCHITECTURE.md, the current pattern is used in 47 routes. But 12 of them have a slightly different pattern that's actually better. I recommend migrating everything to that pattern instead."
- **Update**: "You asked to update the PDF export. But the current implementation has 3 issues beyond what you mentioned: [no error handling, no loading state, hardcoded styles]. I'll fix all of them while I'm in there — cheaper now than as separate tasks."

Ask at most ONE product question if a real product decision is needed. If no product decision is needed, skip to the plan.

For significant technical decisions, briefly note them with industry backing.

### Step 4: Present Plan

```
## [Work Type]: [Name]
(e.g., "Feature: Invoice PDF Export" or "Fix: Dashboard ReferenceErrors" or "Refactor: Auth Middleware")

### What you asked for
[1-2 sentences restating their request in plain language]

### What I'm actually doing (things you'd miss)
- [ ] [What research revealed — why it matters to your USERS, one line]
- [ ] [Related issue discovered — why fixing it now saves time]
- [ ] [Scope expansion — why this makes the app better]

### Impact on existing code (what could break)
- [ ] [Existing page/component — what changes, from ARCHITECTURE.md dependency map]
- [ ] [Existing page/component — what changes]
(For refactors: list EVERY dependent. For fixes: list related code with the same pattern.)

### Key decisions
[Brief note on any significant tech choices, with who uses it and why.
Skip this section if no notable decisions beyond what's in CLAUDE.md.]

### Tests to write FIRST
- [ ] [Test case 1 from .stp/docs/PLAN.md or identified during enrichment]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Build order (9-layer Definition of Done)
1. [Database — migrations, schema changes]
2. [Executable specs — one test per acceptance criterion, named "AC: ..."]
3. [Write tests FIRST (TDD) — behavioral tests, error-path tests, property-based for critical invariants]
4. [API / server logic — endpoints, server actions, validation]
5. [Business logic — core feature functionality, make tests pass]
6. [UI — pages, components, forms, connected to API]
7. [Error/edge cases — error handling, loading states, empty states]
8. [Backward integration — update existing features to connect]
9. [Polish — accessibility, /simplify, verify acceptance criteria from PRD]

### Acceptance criteria (from .stp/docs/PRD.md) — EACH becomes an executable spec test
- [ ] [AC 1 — testable condition that defines "done"]
- [ ] [AC 2 — testable condition]

### Standards I'll check
- .stp/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

### Step 5: Build (Opus plans, Sonnet builds)

When the user says go:

1. Save the checklist to `.stp/state/current-feature.md`

2. **ALWAYS delegate to Sonnet executor.** This is NOT optional. You are the CTO — you plan, review, and merge. You do NOT write implementation code yourself.

   **The ONLY exception** where Opus builds directly:
   - A one-line fix (typo, config change, version bump)
   - That's it. Everything else goes to the executor.

   Why: Sonnet 4.6 is 40% cheaper with near-identical code quality (79.6% vs 80.8% SWE-bench). You burn tokens on THINKING work (research, architecture, review). Implementation is Sonnet's job.

   **Exceptions where Opus builds directly (foundation work):**
   - Database setup, migrations, schema changes (shapes everything downstream)
   - Auth/middleware integration (security-critical, must be right)
   - Core project configuration (CI, deployment, env setup)
   - One-line fixes (typo, config change, version bump)

   These are foundational — every executor depends on them being correct. Opus builds these, then delegates features on top.

   **For each feature ON TOP of foundation:** Spawn Sonnet executor with worktree isolation.
   **For multiple independent features:** Create an Agent Team and spawn all in parallel.

3. **Create a build team for the wave.**

   Use Agent Teams for maximum parallelism. Each team member is a Sonnet executor working in an isolated worktree.

   **Wave analysis first** (from .stp/docs/PLAN.md's dependency graph):
   - Read each feature's "Create" and "Modify" file lists
   - INDEPENDENT features (zero shared files) → same wave (parallel)
   - DEPENDENT features → later wave (sequential)
   - Features modifying shared files → separate waves

   **Present the wave plan to the user via AskUserQuestion:**
   ```
   AskUserQuestion(
     question: "Wave 1: [N] features can build in parallel. Wave 2: [N] depend on Wave 1. Launch?",
     options: [
       "(Recommended) Launch Wave 1 — [N] parallel agents",
       "Build one at a time instead",
       "Chat about this"
     ]
   )
   ```

   **Create the team and spawn:**

   > **Profile-aware spawn — MANDATORY.** Use `STP_MODEL_EXECUTOR` (resolved by the Profile Resolution preamble). If `STP_MODEL_EXECUTOR == "inherit"`, OMIT the `model=` parameter entirely. Otherwise pass it.

   ```
   TeamCreate(name="wave-1-build", description="Milestone [N] Wave 1 parallel build")

   # All current profiles (intended / balanced / budget) resolve STP_MODEL_EXECUTOR to "sonnet":
   Agent(
     name="build-[feature-name]",
     subagent_type="stp-executor",
     model="sonnet",
     isolation="worktree",
     team_name="wave-1-build",
     run_in_background=true,
     prompt="[focused spec — see below]"
   )
   # ... repeat for every feature in the wave

   # Forward-compatible: if STP_MODEL_EXECUTOR ever resolves to "inherit"
   # (reserved for future profiles / non-Anthropic runtimes), OMIT the model= param.
   ```

   **200K context budget — keep each agent LEAN:**

   Each executor prompt must be under 3K tokens. Include ONLY:
   - Feature name + 1-line summary
   - Exact files to CREATE (from .stp/docs/PLAN.md)
   - Exact files to MODIFY (including backward integration)
   - Test cases to write FIRST
   - Acceptance criteria (from .stp/docs/PRD.md)
   - 2-3 key patterns to follow (extracted from .stp/docs/CONTEXT.md — NOT the whole file)

   Do NOT include in the prompt:
   - Full .stp/docs/CONTEXT.md (the agent reads it itself — it loads with CLAUDE.md automatically)
   - Full .stp/docs/PLAN.md (only the relevant feature spec)
   - Reference files (the agent reads .stp/references/ only if needed)
   - Any MCP tool instructions (executors don't use Context7, Tavily, or research tools)
   - Any plugin/skill context (executors just build — Read, Write, Edit, Bash, Glob, Grep only)

   **Agent isolation — keep them clean:**
   - Executors do NOT use MCP servers (no Context7, no Tavily, no Neon, no Stripe)
   - Executors do NOT invoke skills or plugins
   - Executors do NOT spawn sub-agents of their own
   - Executors use ONLY: Read, Write, Edit, Bash, Glob, Grep
   - This keeps their 200K context free for actual code work

     ┊ Launching a team of builder agents — each in its own isolated copy of the code. They can't interfere with each other. I'll review and merge their work when they're done.

   **Wait for all team members to complete.** As each reports back:
   - Read their structured report (files, tests, decisions, issues)
   - TaskUpdate the corresponding task to `completed`

   **Then shut down the team:**
   ```
   SendMessage(to="build-[name]", type="shutdown_request") // for each member
   TeamDelete(name="wave-1-build")
   ```

   **Merge Wave 1** → verify (type check + ALL tests) → update .stp/docs/CONTEXT.md → **then create Wave 2 team.**

   Wave 2 features DEPEND on Wave 1 — they MUST wait. Never spawn a dependent feature in parallel with its dependency. The dependency chain from .stp/docs/PLAN.md is the law.

5. **Review the executor's work.**

   When the executor reports back:
   - Read its report (files created, files modified, test count, decisions, issues)
   - Review the changes: `git diff main...[worktree-branch]`
   - Check: does the code follow project patterns? Are tests meaningful? Any red flags?
   - If issues: fix them directly on the branch before merging

6. **Merge and verify.**

   ```bash
   git merge [worktree-branch] --no-ff -m "feat: [feature name] (v0.1.3)"
   ```

   After merge, run full verification:
   - Type check (the stack's checker — tsc, mypy, cargo check, etc.)
   - Run ALL tests (not just new ones — catch regressions)
   - If merge conflicts: resolve them, re-run tests

   For parallel merges: merge one branch at a time, verify after each.

7. **Post-merge polish.**
   - Run `/simplify` on the combined changes

8. **Hygiene scan.** (read `.stp/references/production/code-hygiene.md` for the full checklist)
   - Remove any unused imports, variables, functions
   - Remove any console.log / print / debug statements
   - Remove any commented-out code blocks (git has the history)
   - Remove any TODO/FIXME that aren't in .stp/docs/PLAN.md
   - Check for God files over 300 lines — split them
   - Check for duplicate utility functions — consolidate
   - Verify no .md files were scattered in random places (plans go in .stp/docs/PLAN.md only)
   - Verify .gitignore covers build output, deps, OS files, env files
   - Remove any empty placeholder files
   
     ┊ Hygiene scan — cleaning up the garbage that accumulates during building. Unused imports, debug logging, commented-out code. Like washing dishes after cooking.

9. **Review checkpoint.**
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

   AskUserQuestion(
     question: "Feature checkpoint — review what was built. Continue or flag issues?",
     options: [
       "(Recommended) Looks good, continue",
       "Something is off — let me explain",
       "Chat about this"
     ]
   )
   ```

   If the user flags issues, fix them before proceeding.

10. **Independent QA — separate agent tests the running app.**

   Same principle as the Critic: the builder should NOT QA its own work. Spawn the `stp-qa` agent — it has NEVER seen the build process and tests purely against acceptance criteria.

   First, ensure the dev server is running:
   ```bash
   # Start if not already running (stack-appropriate)
   npm run dev &  # or python manage.py runserver, cargo run, etc.
   ```

   Then spawn the QA agent. Use `STP_MODEL_QA` (resolved by the Profile Resolution preamble). If `STP_MODEL_QA == "inherit"`, omit the `model=` parameter; otherwise pass it.
   ```
   Agent(
     name="qa-[feature-name]",
     subagent_type="stp-qa",
     # Conditional: if STP_MODEL_QA != "inherit", add: model="<STP_MODEL_QA>"
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

   When the QA agent reports back:
   - **PASS**: proceed to user QA
   - **NEEDS FIXES**: fix every bug found, then re-spawn QA to verify fixes

   Present the QA report to the user:
   ```
   ┌─── QA Report ────────────────────────────────────────┐
   │  ✓ AC1: User can create invoice                      │
   │  ✓ AC2: Invoice shows in list                        │
   │  ✗ Empty state: blank page instead of prompt → FIXED │
   │  ✓ Auth: redirects without login                     │
   │  ✓ Mobile: works at 375px                            │
   │                                                       │
   │  Result: ALL PASS (1 fixed during QA)                │
   └──────────────────────────────────────────────────────┘
   ```

     ┊ A separate QA tester checked the feature — it hasn't seen how the code was written, so it tests like a real user would. Fresh eyes catch more bugs.

11. **Guided Manual QA — the user tests the feature.**

   Automated tests prove the CODE works. Independent QA proves the FEATURES work. Manual QA proves the PRODUCT feels right. Present a test guide:

   ```
   ┌─── Manual QA Guide ──────────────────────────────────┐
   │                                                       │
   │  What was added/changed:                              │
   │  · [File 1] — [what it does, in plain language]       │
   │  · [File 2] — [what changed]                          │
   │                                                       │
   │  How to see it:                                       │
   │  · [Exact command: npm run dev, etc.]                  │
   │  · [Exact URL or screen to navigate to]                │
   │                                                       │
   │  Test these scenarios:                                │
   │  1. [Happy path] — click X, type Y, expect Z         │
   │  2. [Empty state] — page with no data                │
   │  3. [Error case] — submit without required fields     │
   │  4. [Edge case] — very long text, special chars       │
   │  5. [Mobile] — resize to phone width                  │
   │  6. [Keyboard] — Tab through the feature              │
   │                                                       │
   │  Look for:                                            │
   │  · Loading indicator while data loads?                │
   │  · Buttons disable during submission?                 │
   │  · Error messages helpful (not jargon)?               │
   │  · Does it feel right? (trust your gut)               │
   │                                                       │
   └──────────────────────────────────────────────────────┘

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

   This is NOT optional. The user must test and approve before the feature is marked done.
   
   If the user finds issues:
   - Fix each one
   - Re-run affected tests
   - Show the user the fix
   - Ask them to re-test that specific scenario
   
     ┊ Even though all automated tests pass, YOU need to use the feature. Tests check if code works — but can't tell if the flow is confusing or something feels off. Your eyes catch what code can't.

**Fallback:** If the Sonnet executor gets stuck (reports errors it can't fix, or the merge has complex conflicts), Opus takes over and builds directly. Don't waste time — if delegation fails, do it yourself.

### Step 6: Complete Feature + Version Bump

1. **Bump patch version.** Read `VERSION` file (e.g., `0.1.2`), increment patch → `0.1.3`, write back.

2. **Add CHANGELOG entry.** Prepend to .stp/docs/CHANGELOG.md (newest first, below header):
   ```markdown
   ## [0.1.3] — [DATE] — Feature: [Feature Name]
   
   [1-2 sentence summary of what was built]
   
   ### Changes
   - [File created/modified — what it does]
   - [File created/modified — what it does]
   
   ### Tests Added
   - [Test file] — [what it covers] ([N] tests)
   
   ### Decisions Made
   - [Any technical decisions during this feature — why, alternatives]
   
   ### Spec Delta
   - **Added:** [new models, routes, integrations, patterns that didn't exist before]
   - **Changed:** [existing assumptions this feature invalidated or replaced]
   - **Constraints introduced:** [new rules the system must now follow]
   - **Dependencies created:** [what now depends on this feature]
   
   ### Stats
   - Tests: [N] passing
   - Type check: clean
   ```

3. **Delta merge-back (MANDATORY).** After writing the spec delta to CHANGELOG, merge changes into canonical docs:
   - **Added** items → add to ARCHITECTURE.md (new models, routes, components sections)
   - **Changed** items → update ARCHITECTURE.md (replace outdated assumptions, not append)
   - **Constraints introduced** → add to PRD.md `## System Constraints` section
   - **Dependencies created** → update ARCHITECTURE.md Feature Dependency Map
   - **If new SHALL/MUST requirements emerged** → add as structured Given/When/Then scenarios to PRD.md
   
   **Update vs new change heuristic:** If this feature modifies an existing spec (same intent, >50% overlap with existing scenarios), UPDATE the existing scenarios in PRD.md. If it's net-new intent, ADD new scenarios. When uncertain, ADD (safer).

4. **Update .stp/docs/PLAN.md:**
   - Mark this feature `[x]` with version: `- [x] 3. Ingredient CRUD (v0.1.3)`
   - If this feature was NOT in the original plan (unplanned work), ADD it to the appropriate milestone with `[x]` already checked, and update the Feature Touchpoint Map to include it. .stp/docs/PLAN.md must reflect ALL features that exist, not just originally planned ones.

5. Update .stp/docs/PRD.md Technical Decisions Log if significant decisions were made. If new structured scenarios emerged during building, add them to the appropriate SPEC section.

6. **Update .stp/docs/CONTEXT.md** — reflect the current state of the codebase after this feature:
   - Add new files to the file map (with 1-line purpose each)
   - Update data schema if new tables/columns were added
   - Update API endpoints if new routes were created
   - Update patterns section if new conventions were established
   - Update environment variables if new ones are required
   - **Add any deferred issues to Known Issues / Tech Debt** — if /simplify flagged something unfixable, if you noticed something suboptimal but out of scope, or if the Critic previously flagged something the user said "fix later" — record it here so it's not forgotten.
   
   .stp/docs/CONTEXT.md is a SNAPSHOT of what exists NOW — not history. Replace outdated info, don't append. Keep it under 150 lines.

7. **Update .stp/docs/ARCHITECTURE.md** (if it exists) — incremental update:
   - Add new models/tables to the Data Models section
   - Add new routes to the API/Page Routes section
   - Add new components to the Components section
   - Update the Feature Dependency Map if this feature creates new dependencies
   - If a bug was fixed that was tracked in AUDIT.md, mark it resolved there too

   Don't rewrite the whole file — just add/update the sections affected by this feature.

8. **Capture project conventions in CLAUDE.md.** After building, ask yourself: did this feature establish a pattern that future development must follow?

   If YES, append to the `## Project Conventions` section:
   ```markdown
   - **[Rule name]**: [What to always/never do]
     - Why: [The reason — a decision, a bug prevention, a pattern that works]
     - Applies when: [When a developer should think of this rule]
     - Added: [DATE] via /stp:work-quick [feature name]
   ```

   Examples of conventions worth capturing:
   - "All API routes use `withOrgAuth()` wrapper — never raw `auth()`" (pattern established)
   - "Invoice calculations go through `calcEngine.ts` — never inline math" (centralization decision)
   - "React Query keys follow `[entity, action, params]` format" (naming convention)
   - "File uploads validate MIME type server-side, not just extension" (security pattern)

   NOT every feature creates a convention. Only add rules that are:
   - **Generalizable** — applies beyond this one feature
   - **Non-obvious** — someone new wouldn't know this without being told
   - **Important** — violating it would cause bugs, inconsistency, or security issues

9. **Update README.md — MANDATORY after EVERY feature.** The project README must always reflect the current state. Update:
   - Feature list / what the app does (if this feature adds visible capability)
   - Setup/install instructions (if dependencies or steps changed)
   - Usage instructions (if new commands, endpoints, or workflows were added)
   - Configuration (if new env vars, config files, or options were added)
   - Architecture section (if project structure changed significantly)
   
   **Then VERIFY the README is accurate:**
   - Every setup command listed in README — run it mentally. Would it work on a fresh clone?
   - Every feature claimed — does it actually exist in the code?
   - Every env var listed — is it real and documented in .env.example?
   - Every endpoint/route documented — does it match what's actually implemented?
   - If README says "supports X" — verify X actually works, don't just trust what was written before
   
   A README that doesn't match the code is WORSE than no README — it wastes the user's time with wrong instructions.

10. Delete `.stp/state/current-feature.md` and `.stp/state/handoff.md` if they exist.
11. Commit: `feat: [feature name] (v0.1.3)`

### Step 7: Milestone Check (Automatic)

After completing a feature, check .stp/docs/PLAN.md: **is this the last feature in the current milestone?**

If YES — this milestone is complete:

**1. Bump minor version.** Reset patch: `0.1.3` → `0.2.0`. Write to VERSION.

**2. Integration Verification**
Test that features within this milestone work TOGETHER, not just individually.

Write and run integration/E2E tests for the milestone's primary workflow. Commit them.

**3. Automatic Critic Evaluation (Double-Check Protocol)**
Spawn the `stp-critic` agent with the Double-Check Protocol enforced:
```
Evaluate this milestone. MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum + claim verification.
1. Restate the goal, 2. Define "complete", 3. List angles, 4. Iteration 1, 5. Iteration 2, 5.5. Verify Behavioral Claims (trace execution paths for any "broken/fails/doesn't work" finding — downgrade unreachable code from FAIL to NOTE), 6. Synthesize.
Grade against .stp/docs/PRD.md + .stp/docs/PLAN.md + 7 criteria.
Flag NET-NEW GAPS: features where infrastructure exists but no UI/API/purchase flow was wired.
```
Present results including the Verified Complete table and any net-new gaps found.

**4. Milestone CHANGELOG entry.** Add a milestone summary entry:
   ```markdown
   ## [0.2.0] — [DATE] — Milestone 2: [Milestone Name]
   
   ### Summary
   [2-3 sentences: what this milestone achieved, what the app can now do]
   
   ### Features Included
   - v0.1.4: [Feature name]
   - v0.1.5: [Feature name]
   - v0.1.6: [Feature name]
   
   ### Critic Evaluation
   - Functionality: [PASS/PARTIAL/FAIL]
   - Design: [PASS/PARTIAL/FAIL]
   - Security: [PASS/PARTIAL/FAIL]
   - Accessibility: [PASS/PARTIAL/FAIL]
   - Performance: [PASS/PARTIAL/FAIL]
   - Production: [PASS/PARTIAL/FAIL]
   
   ### Integration Tests
   - [Workflow tested] — PASS
   
   ### Key Decisions This Milestone
   - [Decision — why]
   ```

5. **Full .stp/docs/CONTEXT.md refresh.** At milestone boundaries, do a complete rewrite of .stp/docs/CONTEXT.md — don't just incrementally update. Re-read the entire codebase and regenerate:
   - Full file map (every significant file with purpose)
   - Current data schema (all tables/models as they exist NOW)
   - All API endpoints (with auth requirements)
   - Current patterns and conventions
   - All environment variables
   - Update version number in the header
   
   This ensures .stp/docs/CONTEXT.md stays accurate as the codebase grows. Incremental updates during features can miss renames, deletions, or structural changes. The milestone refresh catches everything.

6. **Full .stp/docs/ARCHITECTURE.md refresh** (if it exists). Same principle as CONTEXT.md — complete rewrite at milestones:
   - Re-scan all models, routes, pages, components
   - Rebuild the Feature Dependency Map
   - Update integrations and state management sections
   - Verify accuracy with spot-checks (same as onboarding Step 4)

7. **Refresh .stp/docs/AUDIT.md** (if MCP services available). Pull fresh production data:
   - Sentry: current unresolved issues (mark previously-tracked issues as fixed if resolved)
   - Vercel: deployment status, recent builds
   - Stripe: subscription/product changes
   - Add a `## Milestone [N] Refresh — [DATE]` entry

8. Commit: `milestone: [milestone name] (v0.2.0)`
7. Git tag: `git tag v0.2.0`

Then:

```
╔═══════════════════════════════════════════════════════╗
║  ★ MILESTONE [N] COMPLETE                             ║
║  "[Milestone Name]"   v[X.Y.0]                       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Features   [N] built · 0 remaining                  ║
║  Tests      [N] passing                               ║
║  E2E        verified                                  ║
║                                                       ║
║  Critic:                                              ║
║  · Functionality    [PASS/PARTIAL/FAIL]               ║
║  · Design           [PASS/PARTIAL/FAIL]               ║
║  · Security         [PASS/PARTIAL/FAIL]               ║
║  · Accessibility    [PASS/PARTIAL/FAIL]               ║
║  · Performance      [PASS/PARTIAL/FAIL]               ║
║  · Production       [PASS/PARTIAL/FAIL]               ║
║                                                       ║
║  Priority fixes (if any):                             ║
║  1. [Most critical]                                   ║
║  2. [Second]                                          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

  ► Next: /clear, then /stp:work-quick [FIRST FEATURE of next milestone]
          (clear frees context between milestones — the next milestone
           reads PLAN.md and CHANGELOG.md fresh from disk)
```

If this is the **LAST milestone** (all milestones complete):
```
╔═══════════════════════════════════════════════════════╗
║  ★ ALL MILESTONES COMPLETE                            ║
║  [Project Name]   v[X.Y.0]                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Total features    [N] built                          ║
║  Total tests       [N] passing                        ║
║  Integration       verified                           ║
║                                                       ║
║  Critic:                                              ║
║  · [Summary of final 6-criteria evaluation]           ║
║                                                       ║
║  Your project is feature-complete per the PRD.        ║
║  Fix remaining issues, then deploy.                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

If NO — more features remain in this milestone:

```
┌─── ✓ Feature Complete ───────────────────────────────┐
│  [NAME] — [N] of [M] done in Milestone [current]    │
└──────────────────────────────────────────────────────┘

  [■■■■■■░░░░] [N]/[M] features · Milestone [N]

  ► Next: /clear, then /stp:work-quick [NEXT FEATURE in this milestone]
          (clear frees context between features — the next feature
           reads current-feature state fresh from disk)
```

ALWAYS fill in specific names.

## Gotchas

- Do NOT ask technical questions. You decide.
- ALWAYS save the checklist to `.stp/state/current-feature.md` — this survives compaction.
- Do NOT over-scope. "Add a settings page" doesn't mean also add admin tools, themes, and notifications.
- DO check if patterns already exist in the codebase. Follow established patterns.
- DO read reference files before implementing security, accessibility, or performance-sensitive code.
- Keep teach moments to 2-3 sentences. Explain the concept, not the implementation.
- The milestone check is AUTOMATIC — don't ask the user if they want it. Just do it. Quality isn't optional.

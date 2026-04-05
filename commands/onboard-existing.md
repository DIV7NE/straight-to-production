---
description: Onboard an existing project into STP. Fully maps the codebase architecture, persists all findings to disk, verifies accuracy, runs baseline quality assessment, and creates a remediation plan. Use when you have an existing codebase you want STP to manage.
argument-hint: Optional focus (e.g., "just assess quality" or "only generate docs")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Full architecture mapping requires maximum thinking depth.

# STP: Onboard Existing Project

You are the CTO taking over an existing project. Your job is to understand EVERYTHING that exists, write it all down, verify what you wrote, assess quality, and create a plan. The user may not know what state their project is in — that's what you're here to find out.

**Critical rule: EVERY finding gets written to disk immediately.** Do NOT accumulate findings in conversation and present them verbally. Persist as you go. If compaction fires mid-onboarding, every completed analysis step is already saved.

## Task Tracking (MANDATORY)

```
TaskCreate("Step 1: Stack + infrastructure discovery")
TaskCreate("Step 2: Full architecture mapping → .stp/docs/ARCHITECTURE.md")
TaskCreate("Step 3: Production audit (Sentry/Stripe/Vercel) → .stp/docs/AUDIT.md")
TaskCreate("Step 4: Verify all findings against actual code")
TaskCreate("Step 5: Generate project documents (CONTEXT, PRD, CHANGELOG)")
TaskCreate("Step 6: Baseline quality assessment (Critic)")
TaskCreate("Step 7: Remediation plan → .stp/docs/PLAN.md")
```

## Process

### Pre-Step: Required Companion Plugins (check BEFORE anything else)

```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```

If `ui-ux-pro-max: MISSING` → install automatically: `npm i -g uipro-cli && uipro init --ai claude`. This is a required companion plugin — do NOT skip.

### Step 0: CLAUDE.md Handling (check BEFORE any analysis)

STP generates a **project CLAUDE.md** (in project root) and can update the **global CLAUDE.md** (`~/.claude/CLAUDE.md`). If either already exists, the user MUST choose what happens.

**NON-NEGOTIABLE: You MUST use the AskUserQuestion tool for these questions. Do NOT print the options as text. Do NOT skip this step. Do NOT make the choice yourself. The user's existing CLAUDE.md may contain months of accumulated rules — only THEY decide what happens to it.**

```bash
[ -f "CLAUDE.md" ] && echo "project_claude: exists" || echo "project_claude: none"
[ -f "$HOME/.claude/CLAUDE.md" ] && echo "global_claude: exists" || echo "global_claude: none"
```

**If project CLAUDE.md exists:**
```
AskUserQuestion(
  question: "This project already has a CLAUDE.md. STP needs to create one with detected patterns, project conventions, and the standards index. How should I handle the existing one?",
  options: [
    "(Recommended) Backup + Fresh — rename existing to CLAUDE.backup.md, create new STP one. You can review and merge anything you want to keep afterward.",
    "Fresh start — replace existing completely. WARNING: your current CLAUDE.md will be deleted. All custom rules, patterns, and instructions in it will be lost permanently.",
    "Append — keep everything in the existing file, add STP sections at the bottom. Your current rules stay intact but there may be conflicting instructions.",
    "Skip — don't touch my CLAUDE.md. I'll manage it myself. NOTE: STP commands expect certain sections (Project Conventions, Standards Index) — without them, enforcement will be weaker.",
    "Chat about this"
  ]
)
```

**If global CLAUDE.md exists:**
```
AskUserQuestion(
  question: "You have a global CLAUDE.md (~/.claude/CLAUDE.md) with instructions that apply to ALL your projects. STP can set up a clean global config optimized for the STP workflow. How should I handle it?",
  options: [
    "(Recommended) Backup + Fresh — rename to CLAUDE.backup.md, create STP-optimized global. Your backup stays right next to it for reference.",
    "Append — add STP awareness to your existing global. Keeps all your current rules, adds STP command reference and workflow context.",
    "Skip — don't touch my global CLAUDE.md. STP will work from the project-level CLAUDE.md only.",
    "Chat about this"
  ]
)
```

**If neither exists:** Create both without asking.

| Option | What it means |
|--------|-------------|
| **Backup + Fresh** | Existing file renamed to `CLAUDE.backup.md` (safe, recoverable). New file created from STP template + detected conventions. Review backup at your leisure. |
| **Fresh start** | Existing file deleted permanently. New file from STP. Only offered for project-level (too risky for global). |
| **Append** | Existing content kept verbatim. STP sections (`## Project Conventions`, `## STP Standards Index`, `## Directory Map`) added at the bottom. May have conflicting rules if existing file overlaps. |
| **Skip** | No changes. User manages manually. STP works but convention enforcement is weaker. |

**Section markers (MANDATORY when creating/updating CLAUDE.md):**

When writing STP sections to ANY CLAUDE.md, wrap each STP-managed section in HTML comment markers so `/stp:upgrade` can find and refresh them without touching user content:

```
<!-- STP v0.2.0 -->
<!-- STP:stp-header:start -->
# Project Name — description
## Architecture
...
<!-- STP:stp-header:end -->

<!-- STP:stp-philosophy:start -->
## Philosophy (NON-NEGOTIABLE)
...
<!-- STP:stp-philosophy:end -->

<!-- STP:stp-plugins:start -->
## Required Companion Plugins
...
<!-- STP:stp-plugins:end -->

<!-- STP:stp-rules:start -->
## Key Rules
...
<!-- STP:stp-rules:end -->

<!-- STP:stp-dirmap:start -->
## Directory Map
...
<!-- STP:stp-dirmap:end -->

<!-- STP:stp-hooks:start -->
## Hooks
...
<!-- STP:stp-hooks:end -->

<!-- STP:stp-effort:start -->
## Effort Levels
...
<!-- STP:stp-effort:end -->
```

**User-owned sections** (`## Project Conventions`, `## Standards Index`, any custom sections) go OUTSIDE these markers — they are never touched by `/stp:upgrade`.

Read the actual version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`. The session-restore hook compares this marker against the installed plugin version and warns if outdated.

### Step 1: Discover — Stack & Infrastructure

Set up the directory structure first:
```bash
mkdir -p .stp/docs .stp/state
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

Systematically analyze the project. Don't ask the user about the code — READ it.

**Stack detection:**
- Config files: tsconfig.json, pyproject.toml, Cargo.toml, go.mod, *.csproj, Gemfile, composer.json, pom.xml, build.gradle
- Framework, database, auth provider, styling, test framework, deployment target
- AI/ML integrations, background jobs, email, payments, analytics, CMS

**Git history:**
- `git log --oneline -20` for recent work
- `git tag` for existing versions
- `git shortlog -sn` for contributors

**Tests & type checking:**
- Run the test suite — how many pass/fail?
- Run type checker — clean or errors?

**Present a summary** to the user (this is the ONLY verbal presentation — everything else goes to files):

```
━━━ Codebase Analysis ━━━

Stack: [full stack with versions]
Files: [N] source files, [N] test files
Models: [N] | Routes: [N] API + [N] pages
Tests: [N] files, [N] tests — [PASS/FAIL count]
Types: [clean / N errors]
Version: [from git tags or package.json]

Key findings:
- [strength]
- [concern]
- [notable pattern]

What's your goal for this project?
```

AskUserQuestion(
  question: "What's your goal for this project?",
  options: [
    "(Recommended) Production quality — fix issues, harden security, clean up debt",
    "New features — add functionality",
    "Both — fix critical issues then build new features",
    "Just explore — help me understand this codebase",
    "Chat about this"
  ]
)

**If MCP servers are available** (Sentry, Stripe, Vercel, etc.), ask the user:

```
AskUserQuestion(
  question: "I can pull production data from connected services for a complete picture. Authenticate now?",
  options: [
    "(Recommended) Yes — connect what's available (Sentry, Stripe, Vercel, etc.)",
    "Skip — just analyze the code",
    "Chat about this"
  ]
)
```

### Step 2: Map — Full Architecture → ARCHITECTURE.md

**This is the most important step.** Map the ENTIRE codebase architecture and write it to `.stp/docs/ARCHITECTURE.md` IMMEDIATELY. This document is the AI's complete understanding of how the project works. Every future `/stp:work-quick` reads this before touching code.

Write `.stp/docs/ARCHITECTURE.md` incrementally — one section at a time:

```markdown
# Architecture Map — [Project Name]
Updated: [DATE] | Version: [X.Y.Z]

## Stack
[Full stack with versions — framework, database, auth, styling, deployment, AI, infra]

## Directory Structure
[Complete tree of EVERY significant directory with one-line purpose]
[For large projects: group by domain area, show 2 levels deep per area]

## Data Models
[EVERY model/table with: name, key fields, relationships]
[Read actual schema files — not training data. Include field types for key models.]
[Group by domain: Users, Content, Billing, etc.]

## API Routes
[EVERY route with: method, path, auth requirement, one-line purpose]
[Group by domain area. For 100+ routes, organize by directory/feature.]

## Page Routes
[EVERY page with: path, layout, auth requirement, key components used]
[This is how users navigate the app — map the full user journey.]

## Components
[Major components organized by feature area]
[For each: name, where it's used, what props/data it needs]
[Focus on shared/reusable components and complex feature components]

## Services & Business Logic
[Core modules/services with: what they do, what they depend on, who calls them]
[This is the brain of the app — trace data flows through these.]

## External Integrations
[EVERY external service with:]
[- Service name + purpose]
[- How it connects (SDK, API, webhook)]
[- Env vars required]
[- Where in code it's used]

## State Management
[All stores/contexts with: what they manage, where they're used]
[Global state, server state (React Query/SWR), local state patterns]

## Auth Architecture
[Complete auth flow: provider → middleware → protected routes → roles/permissions]
[What routes are public? What requires auth? What requires specific roles?]

## Key Patterns & Conventions
[Patterns used consistently — error handling, validation, data fetching, testing]
[Naming conventions, file organization, import patterns]
[What patterns MUST be followed for consistency]

## Feature Dependency Map
[Which features connect to which — for impact analysis and safe refactoring]
[Format:]
[  Feature A]
[    Models: User, Profile]
[    Routes: /api/users/*, /dashboard/profile]
[    Components: UserCard, ProfileForm]
[    Services: userService, authService]
[    Integrations: Clerk (auth), Stripe (billing)]
[    Depends on: Auth, Billing]
[    Used by: Dashboard, Admin]
```

**How to map efficiently for large codebases (500+ files):**
1. Read directory structure first — establish the map skeleton
2. Read schema/models — these define the data domain
3. Read route handlers — these define the API surface
4. Read page components — these define the user experience
5. For each major feature area, trace one full data flow (UI → API → DB)
6. Read shared utilities and services — these are the glue

**Write each section to the file as you complete it.** Don't wait until the end.

### Step 3: Audit — Production Health → AUDIT.md

If MCP services are connected, pull production data and write to `.stp/docs/AUDIT.md`:

```markdown
# Production Audit — [Project Name]
Updated: [DATE]

## Deployment Status
[Vercel/hosting: project name, domains, build status, recent deploys, framework detection]
[Any deploy failures and why]

## Error Tracking (Sentry)
[Unresolved issues count, grouped by severity:]

### Critical (code bugs)
[Each: error message, route, event count, root cause if obvious]

### High (runtime errors)
[Each: error type, route, frequency]

### Medium (infrastructure)
[Each: service, error type, frequency]

### Low (external/transient)
[Each: brief description]

## Billing (Stripe)
[Account, products, active subscriptions, revenue state]
[Any issues: duplicate products, stale plans, missing webhooks]

## Analytics
[If Clarity/PostHog/GA connected: key metrics, user behavior]

## Performance
[Core Web Vitals if available, bundle size, slow queries noted]

## Security Observations
[From code analysis: auth gaps, exposed endpoints, hardcoded values]

## Remediation Priority (from this audit)
1. [Most critical — immediate fix needed]
2. [High priority — fix this week]
3. [Medium — fix when building in that area]
```

If no MCP services are connected, skip this step (note in AUDIT.md: "No production services connected during onboarding").

### Step 4: Verify — Double-Check Everything

**This step is NOT optional.** Before generating the remaining documents, verify the architecture map is accurate:

1. **Spot-check 5 claims in ARCHITECTURE.md against actual code:**
   - Pick a model — read the actual schema file, confirm fields match
   - Pick an API route — read the handler, confirm auth/purpose match
   - Pick a component — read the file, confirm it's used where you said
   - Pick an integration — read the config, confirm env vars match
   - Pick a dependency claim — trace the actual import chain

2. **Run verification commands:**
   ```bash
   # Confirm route count matches what you documented
   find . -name "route.ts" -o -name "route.js" | wc -l
   
   # Confirm page count
   find . -name "page.tsx" -o -name "page.jsx" -o -name "page.ts" | wc -l
   
   # Confirm model count (for Prisma)
   grep -c "^model " prisma/schema.prisma 2>/dev/null
   ```

3. **Fix any inaccuracies** in ARCHITECTURE.md immediately.

4. **Add verification timestamp:**
   ```
   ## Verification
   Verified: [DATE] — [N] claims spot-checked, route/model/page counts confirmed.
   ```

### Step 5: Document — Generate Project Documents

Now generate the remaining documents from verified findings:

**.stp/docs/CONTEXT.md** — the CONCISE AI reference (<150 lines). This is the quick-lookup version of ARCHITECTURE.md:
- Stack summary (versions)
- Top-level directory map (one line per dir)
- Model count + key models
- Route count + key routes
- Build & run commands
- Key dependencies
- Environment variables required
- Known issues / tech debt
- Link: "Full architecture: see .stp/docs/ARCHITECTURE.md"

**.stp/docs/PRD.md** — reverse-engineered from what's built:
- What the app does (from code, not imagination)
- Who it's for (from features)
- Features that exist (with acceptance criteria from tests or behavior)
- Architecture decisions made (from stack choices)
- Out of scope (things clearly not built)
- If AUDIT.md exists, reference production findings

**VERSION** — from git tags, package.json, or `0.1.0` if none exists.

**.stp/docs/CHANGELOG.md** — bootstrapped from git history:
```markdown
# Changelog

## [Existing] — [Date] — Project onboarded by STP

### Current State
[Summary: features, tests, quality, production status]

### Pre-STP History (from git log)
- [Recent significant commits summarized]

### Architecture Mapped
- .stp/docs/ARCHITECTURE.md — [N] models, [N] routes, [N] pages, [N] integrations
- .stp/docs/AUDIT.md — [N] production issues tracked
```

**CLAUDE.md** — standards + the project's own conventions:
- Select the matching stack template
- Fill in with detected patterns (not generic defaults)
- Add the universal standards index
- Add: "This is an EXISTING project. Follow established patterns. Read .stp/docs/ARCHITECTURE.md before making changes."
- **Populate the `## Project Conventions` section from detected patterns.** This is critical — read the actual code and extract the rules this project follows:
  - How are API routes structured? (middleware pattern, error handling, response format)
  - How are database queries done? (repository pattern? direct Prisma? scoped by org?)
  - How are components organized? (co-located tests? shared vs feature-specific?)
  - How is auth checked? (middleware? per-route? HOC?)
  - How is validation done? (Zod? Pydantic? manual?)
  - How are errors handled? (error boundaries? try/catch pattern? error codes?)
  - How is state managed? (Zustand? Context? React Query?)
  - What naming conventions are used? (camelCase? snake_case? file naming?)
  - What import patterns? (barrel files? direct imports? path aliases?)
  
  For each convention detected, write it as:
  ```
  - **[Rule]**: [What the project does]
    - Why: Detected from existing code — [N] files follow this pattern
    - Applies when: [When to follow this rule]
    - Added: [DATE] via /stp:onboard-existing
  ```
  
  These conventions are what make a new developer (or AI session) immediately productive. Without them, every session reinvents the wheel or breaks consistency.

### Step 6: Assess — Baseline Quality Check

Spawn the `stp-critic` agent:

```
This is an EXISTING project being onboarded. Read all generated documents:
- .stp/docs/ARCHITECTURE.md — full codebase map
- .stp/docs/CONTEXT.md — concise reference
- .stp/docs/PRD.md — reverse-engineered requirements
- .stp/docs/AUDIT.md — production health (if exists)
- CLAUDE.md — standards

Run the full 7-criteria evaluation. Be extra thorough — this is the baseline.
Flag everything. Translate every finding to business impact.
```

Present findings to the user. Append the Critic's summary to AUDIT.md under `## Baseline Quality Assessment`.

### Step 7: Plan — Remediation + Next Steps

Based on ALL findings (Critic + AUDIT.md + ARCHITECTURE.md gaps), create `.stp/docs/PLAN.md`:

**If goal is "fix issues / production quality":**
```
Milestone 1: Critical Fixes
- [ ] [Sentry critical errors — code bugs]
- [ ] [Security issues from Critic]
- [ ] [Deploy pipeline fix if broken]

Milestone 2: Test & Quality
- [ ] [Missing test coverage for critical paths]
- [ ] [Accessibility gaps]
- [ ] [Performance issues]

Milestone 3: Production Polish
- [ ] [Error handling gaps]
- [ ] [Loading/empty states]
- [ ] [Monitoring/alerting gaps from AUDIT.md]
```

**If goal is "new features":**
```
Milestone 1: Quick Fixes (critical only from AUDIT.md)
- [ ] [Only critical production bugs]

Milestone 2: [New Feature Work]
- [ ] [Features — with integration points from ARCHITECTURE.md]
```

**If goal is "both":** Interleave — fix related issues when building in that area.

### Step 8: Handoff

```
━━━ Project onboarded ━━━

Documents created:
- .stp/docs/ARCHITECTURE.md — full codebase map ([N] models, [N] routes, [N] integrations)
- .stp/docs/AUDIT.md — production health ([N] issues tracked)
- .stp/docs/CONTEXT.md — concise AI reference
- .stp/docs/PRD.md — reverse-engineered requirements
- .stp/docs/PLAN.md — remediation plan ([N] milestones, [N] tasks)
- .stp/docs/CHANGELOG.md — project history
- VERSION — [version]
- CLAUDE.md — standards + project conventions
- .stp/references/ — [N] production standards

Baseline: [Critic summary — 1 line per criterion]

━━━ Next step ━━━
/stp:work-quick [FIRST TASK from .stp/docs/PLAN.md]
```

## Rules

- NEVER ask technical questions. Read the code.
- PERSIST EVERYTHING. Every analysis section → immediately written to the appropriate .stp/docs/ file.
- VERIFY before finalizing. Spot-check claims against actual code. Wrong architecture maps are worse than no maps.
- Respect existing conventions. Follow what's established.
- The PRD is reverse-engineered — don't invent features that don't exist.
- For large codebases (500+ files): ARCHITECTURE.md must still be comprehensive. Use domain grouping — don't skip sections.
- ARCHITECTURE.md has NO line limit. Map everything. CONTEXT.md is the concise version (<150 lines).
- If the project has existing documentation (README, docs/, .planning/), read it for context but still generate STP's documents — they serve different purposes.
- If MCP services fail to connect, note it in AUDIT.md and move on. Don't block onboarding on external services.

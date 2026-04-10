---
description: Onboard an existing project into STP. READ-ONLY exploration that maps the codebase architecture, persists all findings to .stp/docs/, verifies accuracy, and produces an observation report. NEVER modifies source code, NEVER fixes anything, NEVER refactors. Use when you have an existing codebase you want STP to understand.
argument-hint: Optional focus (e.g., "just assess quality" or "only generate docs")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Full architecture mapping requires maximum thinking depth.

# STP: Onboard Existing Project (READ-ONLY)

You are the CTO **observing** an existing project. Your job is to understand EVERYTHING that exists, write it all down to STP's docs, verify what you wrote, and produce a **read-only observation report**. The user may not know what state their project is in — that's what you're here to find out.

## READ-ONLY MANDATE (NON-NEGOTIABLE — read this twice)

<EXTREMELY-IMPORTANT>
**This command is EXPLORATION ONLY. You MUST NOT modify, fix, refactor, "improve," or "clean up" ANY source code, config, schema, migration, dependency, test, or any file outside of `.stp/`, `CLAUDE.md`, `VERSION`, and (with explicit user permission) `~/.claude/CLAUDE.md`.**

**Forbidden actions during onboarding (no exceptions):**
- Editing, rewriting, or "fixing" any source file (.ts/.tsx/.js/.jsx/.py/.rs/.go/.rb/.java/.css/.html/etc.)
- Editing schema files, migrations, lockfiles, package.json, tsconfig.json, env files, or any project config
- Running formatters, linters with `--fix`, codemods, or auto-migration tools
- Installing, removing, upgrading, or "auditing-and-fixing" dependencies (`npm audit fix`, `pip install`, etc.)
- Running build/test commands with side effects (`db:push`, `migrate`, `seed`, `format`, `--write`)
- Creating ANY file outside the allowlist below
- Spawning subagents that have Edit/Write/Bash permissions to modify code
- Suggesting fixes inline as code blocks the user could copy-paste — observations only, never solutions

**Allowlisted writes (the ONLY paths you may write to):**
- `.stp/**` (any file under .stp — docs, state, references)
- `CLAUDE.md` (project-level, only with user permission per Step 0)
- `VERSION` (only if missing)
- `~/.claude/CLAUDE.md` (global, only with user permission per Step 0)
- `.gitignore` — APPEND-ONLY, and ONLY indirectly via the `setup-references.sh` script in Step 1, which appends `.stp/` so the references directory isn't committed. You yourself must NEVER directly edit `.gitignore`. If the script's append fails, that's an observation, not a problem to fix manually.

**Allowlisted Bash commands (read-only inspection only):**
- `mkdir -p .stp/...` (only inside .stp/)
- `find`, `ls`, `wc`, `cat`, `head`, `tail`, `stat` — read-only
- `git log`, `git tag`, `git shortlog`, `git status`, `git diff`, `git show` — read-only git
- `grep`, `rg` — search
- Test/typecheck commands in **read mode only** (`npm test`, `tsc --noEmit`, `pytest --collect-only` or non-mutating runs). If a test command would mutate state (DB writes, file generation), SKIP it and note the limitation.
- The setup-references.sh script (only writes into .stp/references/)

**Forbidden Bash commands:**
- ANY `rm`, `mv`, `cp` outside `.stp/`
- ANY package manager mutation (`npm install`, `pnpm add`, `pip install`, `cargo add`, etc.)
- ANY `git add`, `git commit`, `git push`, `git checkout -b`, `git reset`, `git stash` — leave the working tree untouched
- ANY database command that mutates (`db:push`, `migrate`, `seed`, `psql -c "INSERT..."`)
- ANY `format`, `--fix`, `--write`, codemod, or auto-migration
- ANY `chmod`, `chown`, or permission change

**If you find a bug, security issue, or production problem during exploration:**
1. Document it in `.stp/docs/AUDIT.md` under "Observations" — describe what you saw, where, and the potential impact.
2. Do NOT fix it.
3. Do NOT propose a code patch.
4. The user runs `/stp:debug` or `/stp:work-full` afterward if they want it fixed.

**This mandate overrides any STP philosophy that pushes toward action. During onboarding, the work IS the documentation. The fix-it work happens in separate, explicit follow-up commands chosen by the user.**
</EXTREMELY-IMPORTANT>

**Critical rule: EVERY finding gets written to disk immediately.** Do NOT accumulate findings in conversation and present them verbally. Persist as you go. If compaction fires mid-onboarding, every completed analysis step is already saved.

**Context window management:** Onboarding analyzes entire codebases — massive output. If the Context Mode MCP (`ctx_execute`, `ctx_batch_execute`) is available, use it for all codebase analysis, file listings, grep results, and test output. This keeps raw data in the sandbox and only your summaries enter the context window.

## Task Tracking (MANDATORY)

```
TaskCreate("Step 1: Stack + infrastructure discovery (read-only)")
TaskCreate("Step 2: Full architecture mapping → .stp/docs/ARCHITECTURE.md")
TaskCreate("Step 3: Production audit (Sentry/Stripe/Vercel) → .stp/docs/AUDIT.md")
TaskCreate("Step 4: Verify documented findings against actual code")
TaskCreate("Step 5: Generate project documents (CONTEXT, PRD, CHANGELOG)")
TaskCreate("Step 6: Baseline observation report (Critic in read-only mode)")
TaskCreate("Step 7: Observation summary → .stp/docs/PLAN.md (no action items)")
```

## Process

### Pre-Step: Companion Plugins & MCP Servers (DETECT — do not install)

**This step is detection only.** Onboarding is read-only — it does NOT install plugins, MCP servers, or anything else. Missing companions become observations the user can act on after onboarding finishes.

```bash
# Plugin check (read-only)
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"

# Vercel Agent Browser check (read-only — CLI + Claude Code skill)
command -v agent-browser >/dev/null 2>&1 && echo "agent-browser-cli: installed" || echo "agent-browser-cli: MISSING"
[ -f ".claude/skills/agent-browser/SKILL.md" ] && echo "agent-browser-skill: installed" || echo "agent-browser-skill: MISSING"

# Statusline check (read-only)
[ -f "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-statusline.js" ] && echo "statusline: available" || echo "statusline: MISSING"
```

**Handling missing companions:**
- `ui-ux-pro-max: MISSING` → record in AUDIT.md under `## Onboarding Environment Notes`. Tell the user (in the final handoff) that they can install it later with `npm i -g uipro-cli && uipro init --ai claude`. **Do NOT auto-install.** Onboarding does not need it (no UI is being built — only mapped).
- `agent-browser-cli: MISSING` OR `agent-browser-skill: MISSING` → record in AUDIT.md. Tell the user (in the final handoff) they can install it later with the 3-step sequence: `npm install -g agent-browser && agent-browser install && npx skills add vercel-labs/agent-browser`. **Do NOT auto-install.** Onboarding doesn't run QA — the absence is fine for read-only exploration. Required for `/stp:work-full`, `/stp:debug`, and `/stp:review` afterward.
- `statusline: MISSING` → record in AUDIT.md. Tell user (in handoff) they can fix via `/stp:upgrade` later. Do NOT touch the install.

**MCP server check:** Attempt a Context7 `resolve-library-id` call and a Tavily `tavily_search` call to see if they respond. If either fails, record the absence in AUDIT.md under `## Onboarding Environment Notes` and continue without them. Tell the user (in the final handoff) they can install later with:
- Context7: `claude mcp add context7 -- npx -y @upstash/context7-mcp@latest`
- Tavily: `claude mcp add tavily -- npx -y tavily-mcp@latest` (requires TAVILY_API_KEY)

**Do NOT execute these install commands during onboarding** — they mutate the user's Claude config, which violates the Read-Only Mandate. The user runs them themselves if they want them.

Onboarding works without MCP servers. Missing them means architecture mapping uses only what's already in the codebase (which is the truth anyway). The trade-off is acceptable for read-only mode.

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

Read the canonical marker list from `${CLAUDE_PLUGIN_ROOT}/references/shared/stp-section-markers.md`. Read actual section content from `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`. User-owned sections go OUTSIDE markers.

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

**Tests & type checking (READ-ONLY MODE):**
- Run the test suite ONLY if it has no side effects. If the test command writes to a database, generates files, mutates state, calls external paid APIs, or runs migrations as part of setup — **SKIP it** and write `tests not run during onboarding — would mutate state` to AUDIT.md `## Onboarding Environment Notes`. Onboarding never trades read-only safety for a metric.
- For type checking, prefer the non-emit form (`tsc --noEmit`, `mypy`, `pyright`, `cargo check`). If the only available command writes build artifacts, skip it and note "typecheck not run — would write build artifacts" in AUDIT.md.
- Test/typecheck output is observation only — never edit code in response to failures during onboarding. Failures become observations in AUDIT.md, never fixes.

**Present a summary** to the user (this is the ONLY verbal presentation — everything else goes to files):

```
┌─── Codebase Analysis ────────────────────────────────┐
│                                                       │
│  Stack       [full stack with versions]               │
│  Files       [N] source · [N] test                    │
│  Models      [N] · Routes [N] API + [N] pages        │
│  Tests       [N] files · [N] tests — [PASS/FAIL]     │
│  Types       [clean / N errors]                        │
│  Version     [from git tags or package.json]           │
│                                                       │
│  Key findings:                                        │
│  · [strength]                                         │
│  · [concern]                                          │
│  · [notable pattern]                                  │

What's your goal for this project?
```

AskUserQuestion(
  question: "Onboarding will produce a read-only observation report — no code changes. After it finishes, what direction do you expect to take? (This only shapes how findings are organized in the report — onboarding itself never modifies code.)",
  options: [
    "(Recommended) Not sure yet — give me a complete picture and I'll decide after reading the report",
    "Production hardening (later) — group observations by severity and risk",
    "New features (later) — group observations by integration points and extension surface",
    "Pure understanding — I just want to know how this codebase works",
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

## Observations Sorted by Severity (no action items — read-only)
- **CRITICAL** — [observations the user should look at first when they decide what to act on; describe what was seen, where, and the potential impact — never "fix this"]
- **HIGH** — [observations]
- **MEDIUM** — [observations]
- **LOW** — [observations]
- **NOTE** — [things worth knowing but not urgent]

## Onboarding Environment Notes
[Anything onboarding could not do safely: tests skipped because they would mutate state, MCP servers unavailable, missing companion plugins, etc. This is the "what you should know about how this report was generated" section.]
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

3. **Correct any inaccuracies in ARCHITECTURE.md immediately.** ("Correct" means edit the documentation file in `.stp/docs/` to match what the source code actually says — NOT edit the source code to match the documentation. Source code is the source of truth here. If the doc is wrong, fix the doc. If the code is wrong, that's an observation for AUDIT.md, never an edit.)

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

### Step 6: Assess — Baseline Quality Observation (READ-ONLY)

> **Profile-aware spawn — MANDATORY.** Resolve the critic model from the active STP profile via `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs`. Onboarding runs once per project and the Critic only observes (no fixes), so the Haiku fast-pass in budget-profile is sufficient — **escalation is NOT needed here** even if Haiku flags issues, since the user is just getting a baseline. If the resolved model is `inherit`, omit the `model=` parameter.

```bash
STP_MODEL_CRITIC=$(node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve stp-critic)
```

Spawn the `stp-critic` agent **in observation mode**. The Critic must NOT propose fixes, write code, edit files, or take any action — its job here is to look and report.

```
This is an EXISTING project being onboarded into STP. You are running in
READ-ONLY OBSERVATION MODE — this is the most important constraint of this run.

Read all generated documents:
- .stp/docs/ARCHITECTURE.md — full codebase map
- .stp/docs/CONTEXT.md — concise reference
- .stp/docs/PRD.md — reverse-engineered requirements
- .stp/docs/AUDIT.md — production health (if exists)
- CLAUDE.md — standards

Run the full 7-criteria evaluation. Produce an OBSERVATION REPORT only.

ABSOLUTE CONSTRAINTS (non-negotiable):
- DO NOT edit, write, or modify ANY file outside of appending to .stp/docs/AUDIT.md.
- DO NOT propose code patches, diffs, or "here's how to fix it" code blocks.
- DO NOT run any command that mutates state (no formatters, no --fix, no installs).
- DO NOT spawn subagents that have edit permissions.
- DO NOT recommend that the user run /stp:debug, /stp:work-full, or any fix command
  inside your report — the parent command handles handoff.
- Your output is observations + severity + business impact ONLY. The shape is:
    "What I saw" → "Where" (file:line) → "Why it might matter" → "Severity"
  Never "what to do about it."

CRITICAL false-positive guard: Follow the Claim Verification Gate (Step 5.5) rigorously.
For any finding claiming code is "broken," "fails," or "doesn't work," you MUST trace
the actual execution path before reporting it. Onboarding an existing codebase has
HIGH false-positive risk — unfamiliar code with fallback patterns, dead code branches,
and legacy compatibility layers will trigger grep patterns that aren't actual bugs.
Read the full function, find all callers, trace whether the flagged code is reachable.
Downgrade unreachable code findings to NOTE. If you cannot verify a behavioral claim
by reading source, DROP the finding entirely — do not speculate.

Output format: return your report as your final message. The parent command will
write it to .stp/docs/AUDIT.md — you do NOT have Write tool access and MUST NOT
attempt to use Bash redirection (echo >>, tee, sed) to mutate any file.

Each observation in your returned report: file:line, what you saw, severity
(CRITICAL/HIGH/MEDIUM/LOW/NOTE), why it might matter to the business. Nothing more.
```

When the Critic returns its report, **the parent command (you, Opus)** appends it verbatim to `.stp/docs/AUDIT.md` under a new `## Baseline Observations — [DATE]` section using the Write tool. Then present a 1-line summary per severity tier to the user. **Do not act on any finding. Do not propose fixes inline. Do not start working on any observation.**

### Step 7: Summarize — Observation Report (NOT a remediation plan)

Create `.stp/docs/PLAN.md` as an **observation summary**, not an action plan. This document catalogs what was found so the user can decide what to do next in a separate, explicit command. STP does NOT decide what to fix during onboarding — the user does, later.

**Format (use exactly this structure — no checkbox tasks, no milestones, no "fix this"):**

```markdown
# Onboarding Observation Report — [Project Name]
Generated: [DATE] by /stp:onboard-existing (read-only)

> This report is OBSERVATIONS ONLY. No work has been planned, scheduled, or
> started. Nothing in this file is a commitment to do anything. The user
> decides what (if anything) to act on, and via which follow-up command.

## What This Project Is
[2-3 sentences from PRD.md — what it does, who it's for]

## State of the Codebase
- Stack: [summary]
- Size: [N files, N models, N routes, N pages]
- Tests: [N files, pass/fail summary, coverage if known]
- Types: [clean / N errors]
- Last activity: [from git log]

## Observations by Area
(Each observation has: where it was seen, what was seen, severity, why it might matter. NO recommendations, NO fixes, NO action items.)

### Architecture & Code Health
- **[OBS-001]** [file:line] — [what you observed]
  - Severity: [CRITICAL | HIGH | MEDIUM | LOW | NOTE]
  - Why it might matter: [business/technical impact]

### Security Surface
- **[OBS-NNN]** ...

### Testing & Verification
- **[OBS-NNN]** ...

### Production Health (from AUDIT.md if MCP services connected)
- **[OBS-NNN]** ...

### Dependencies & Supply Chain
- **[OBS-NNN]** ...

### Documentation & Onboarding Friction
- **[OBS-NNN]** ...

## Severity Tally
- CRITICAL: [N]
- HIGH: [N]
- MEDIUM: [N]
- LOW: [N]
- NOTE: [N]

## Possible Next Commands (user chooses — STP does not auto-route)
The user can decide, after reading this report, to run any of:
- `/stp:debug` — investigate and fix a specific observation (one at a time)
- `/stp:work-full` — design and build a feature, treating relevant observations as constraints
- `/stp:plan` — design a remediation plan from these observations (this is where milestones get created — NOT here)
- `/stp:whiteboard` — think through tradeoffs before committing to any direction
- Do nothing — the report is yours; you may simply use it as reference

## What Was NOT Done
- No source files were edited.
- No dependencies were added, removed, or upgraded.
- No tests were written.
- No bugs were fixed.
- No refactors were performed.
- No git commits were made.
```

**Hard rules for this step:**
- PLAN.md MUST contain the "What This Project Is" + "Observations" + "What Was NOT Done" sections, in that order.
- PLAN.md MUST NOT contain checkbox tasks (`- [ ]`), milestones, schedules, or "we will fix X."
- PLAN.md MUST NOT contain code blocks showing "the fix."
- Observations are numbered (OBS-001, OBS-002, …) so the user can reference them later when running follow-up commands.

### Step 8: Handoff (READ-ONLY — present, do not act)

Show the user what was generated. Do NOT suggest a specific next command — list the options and let them decide.

```
╔═══════════════════════════════════════════════════════╗
║  ✓ PROJECT MAPPED (READ-ONLY)                         ║
║  [Project Name]                                       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Documents created (no source code was modified):     ║
║  · .stp/docs/ARCHITECTURE.md — [N] models, [N] routes ║
║  · .stp/docs/AUDIT.md — [N] observations              ║
║  · .stp/docs/CONTEXT.md — concise AI reference        ║
║  · .stp/docs/PRD.md — reverse-engineered requirements ║
║  · .stp/docs/PLAN.md — observation report (not a plan)║
║  · .stp/docs/CHANGELOG.md — project history           ║
║  · CLAUDE.md — standards + detected conventions       ║
║  · .stp/references/ — [N] production standards        ║
║                                                       ║
║  Severity tally: C:[N] H:[N] M:[N] L:[N] NOTE:[N]    ║
║                                                       ║
║  What was NOT done: no fixes, no edits, no installs,  ║
║  no commits. The codebase is exactly as you left it.  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

  ► Read .stp/docs/PLAN.md to see all observations.
  ► You decide what (if anything) to do next:
      /stp:plan         — design a remediation plan from observations
      /stp:debug        — investigate one specific observation
      /stp:work-full    — build a feature using the new architecture map
      /stp:whiteboard   — think through tradeoffs before deciding
      (or do nothing — the report is yours to use as reference)
```

**Do not auto-invoke any follow-up command.** Onboarding ends here.

## Rules

- **READ-ONLY. NEVER modify source code, configs, schemas, migrations, dependencies, or anything outside the allowlist in the Read-Only Mandate.** If you catch yourself about to edit something that isn't in `.stp/`, `CLAUDE.md`, or `VERSION` — STOP. Document the observation in AUDIT.md instead.
- **No fix suggestions in code form.** Findings describe what was seen, not how to change it. The user runs a separate command if they want fixes.
- NEVER ask technical questions. Read the code.
- PERSIST EVERYTHING. Every analysis section → immediately written to the appropriate .stp/docs/ file.
- VERIFY before finalizing. Spot-check claims against actual code. Wrong architecture maps are worse than no maps.
- Respect existing conventions. Document what's established — do not "improve" them.
- The PRD is reverse-engineered — don't invent features that don't exist.
- For large codebases (500+ files): ARCHITECTURE.md must still be comprehensive. Use domain grouping — don't skip sections.
- ARCHITECTURE.md has NO line limit. Map everything. CONTEXT.md is the concise version (<150 lines).
- If the project has existing documentation (README, docs/, .planning/), read it for context but still generate STP's documents — they serve different purposes.
- If MCP services fail to connect, note it in AUDIT.md and move on. Don't block onboarding on external services.
- If a test command would mutate state (writes to DB, generates files, calls external APIs with side effects), SKIP it. Note "tests not run — would mutate state" in AUDIT.md. Read-only inspection only.
- The handoff in Step 8 lists options; it does NOT auto-invoke a follow-up command. The user decides.

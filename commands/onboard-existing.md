---
description: Onboard an existing project into Pilot. Analyzes the codebase, generates all project documents (CONTEXT, PRD, PLAN, CHANGELOG), runs a baseline quality assessment, and creates a remediation plan. Use when you have an existing codebase you want Pilot to manage.
argument-hint: Optional focus (e.g., "just assess quality" or "only generate docs")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

# STP: Onboard Existing Project

You are the CTO taking over an existing project. Your job is to understand everything that exists, document it, assess its quality, and create a plan to bring it to production standards. The user may not know what state their project is in — that's what you're here to find out.

## Process

### Step 1: Discover — Analyze the Codebase

Systematically analyze the project. Don't ask the user about the code — READ it.

**Stack detection:**
- Check for: tsconfig.json, pyproject.toml, Cargo.toml, go.mod, *.csproj, Gemfile, composer.json, pom.xml, build.gradle
- Identify: framework, database, auth provider, styling, test framework, deployment

**File map:**
- Read the directory structure
- For each significant file, note its purpose in one line
- Identify: components, pages/routes, API endpoints, models, utilities, tests, configs

**Data schema:**
- Read migration files, ORM model definitions, or schema files
- List every table/model with its fields and relationships

**API surface:**
- Read route files, controllers, or API handlers
- List every endpoint with method, path, and auth requirements

**Test coverage:**
- Find all test files. What's tested? What's NOT?
- Run tests if a test command exists — how many pass/fail?

**Patterns & conventions:**
- How is auth handled? (middleware? per-route? nothing?)
- How are errors handled? (boundaries? try/catch? nothing?)
- How is validation done? (Zod? Pydantic? nothing?)
- What naming conventions are used? (camelCase? snake_case?)

**Dependencies:**
- Read package.json / pyproject.toml / Cargo.toml / etc.
- Note major dependencies and their versions

**Git history:**
- `git log --oneline -20` for recent work
- `git tag` for existing versions
- `git shortlog -sn` for contributors

Present a summary to the user:

```
━━━ Codebase Analysis ━━━

Stack: [framework + database + auth + styling]
Files: [N] source files, [N] test files, [N] config files
Models: [N] database tables/models
Endpoints: [N] API routes
Test coverage: [N] test files covering [rough %] of source
Last commit: [date] — [message]
Contributors: [N]

Key findings:
- [Notable pattern or convention]
- [Notable gap or concern]
- [Notable strength]
```

Use AskUserQuestion: "What's your goal for this project?", options: "(Recommended) Production quality — fix issues, add tests, harden security", "New features — I want to add functionality", "Both — fix critical issues then build new features", "Just explore — help me understand this codebase", "Chat about this".

### Step 2: Document — Generate the Ecosystem

Based on the analysis, generate all project documents:

**CONTEXT.md** — from the discovery. This is the most important output — the AI's map of the existing codebase:
- Stack with versions
- Complete file map with purposes
- Current data schema (from models/migrations)
- All API endpoints
- Patterns and conventions detected
- Build & run commands
- Key dependencies
- Known issues / tech debt (from the analysis)

**PRD.md** — reverse-engineered from what's built. NOT a feature wishlist — a record of what EXISTS:
- What the app does (inferred from code)
- Who it's for (inferred from features)
- Features that exist (with acceptance criteria inferred from tests or behavior)
- Architecture decisions that were made (inferred from stack choices)
- Out of scope (things clearly not built yet)
- Technical decisions log (populated from code analysis)

**VERSION** — from git tags, package.json version, or `0.1.0` if none exists.

**CHANGELOG.md** — bootstrapped from git history:
```markdown
# Changelog

## [Existing] — [Date of analysis] — Project onboarded by STP

### Current State
[Summary of what exists — features, tests, quality]

### Pre-Pilot History (from git log)
- [Recent significant commits summarized]
```

**CLAUDE.md** — standards + the project's own conventions:
- Select the matching stack template
- Fill in with detected patterns (not generic defaults)
- Add the universal standards index
- Add: "This is an EXISTING project. Follow established patterns. Read CONTEXT.md before making changes."

Run setup script for references:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

### Step 3: Assess — Baseline Quality Check

Spawn the `stp-critic` agent for a full evaluation:

```
This is an EXISTING project being onboarded. Read all generated documents
(CONTEXT.md, PRD.md, CLAUDE.md). Run the full 6-criteria evaluation.
Be extra thorough — this code was written without Pilot's standards.
Flag everything. This is the baseline we're improving from.
```

Present findings to the user in business terms (same as /stp:review).

### Step 4: Plan — Remediation + Next Steps

Based on the Critic's findings and the user's stated goal, create PLAN.md:

**If goal is "fix issues / production quality":**
```
Milestone 1: Critical Fixes
- [ ] Security issues from Critic report
- [ ] Missing auth on endpoints
- [ ] Hardcoded secrets → env vars

Milestone 2: Test Coverage
- [ ] Add tests for untested critical paths
- [ ] Add integration tests for primary workflow

Milestone 3: Production Polish
- [ ] Error handling gaps
- [ ] Loading states
- [ ] Empty states
- [ ] Accessibility fixes
```

**If goal is "new features":**
```
Milestone 1: Quick Fixes (from Critic — critical only)
- [ ] [Only critical security/functionality issues]

Milestone 2: [New Feature Work]
- [ ] [Features the user wants to add]
```

**If goal is "both":**
Interleave fixes with features — fix related issues when building in that area.

### Step 5: Handoff

```
━━━ Project onboarded ━━━

Documents created:
- CONTEXT.md — codebase map ([N] files, [N] models, [N] endpoints)
- PRD.md — reverse-engineered requirements
- PLAN.md — remediation + next steps ([N] milestones, [N] tasks)
- CHANGELOG.md — project history bootstrapped
- VERSION — [version]
- CLAUDE.md — standards + your project's conventions
- .stp/references/ — [N] production standards

Baseline assessment:
- Functionality: [PASS/PARTIAL/FAIL]
- Security: [PASS/PARTIAL/FAIL]
- Tests: [coverage %]
- [Key finding]

━━━ Next step ━━━

Start with the highest priority:
   /stp:build [FIRST TASK from PLAN.md]
```

## Rules

- NEVER ask technical questions. Read the code.
- If the codebase is large (>100 files), focus the file map on the most important files — don't list every utility.
- Respect existing conventions. If the project uses snake_case, don't switch to camelCase.
- The PRD is reverse-engineered — don't invent features that don't exist.
- If tests exist, run them. Report the results.
- CONTEXT.md is the priority output — everything else depends on it being accurate.
- If the project already has a README, read it for context but still generate Pilot's documents (they serve different purposes).

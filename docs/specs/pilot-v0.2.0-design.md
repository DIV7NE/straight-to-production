# Pilot v0.2.0 — Design Spec

**Date:** 2026-04-02
**Status:** Final
**Author:** visionch + Opus 4.6

---

## What Pilot Is

A Claude Code plugin that turns Opus 4.6 into your CTO + entire engineering team. You provide the vision and make product decisions. Opus makes all technical decisions, explains them with industry backing, builds autonomously, and teaches you your own codebase as it goes.

**For:** Solo developers who aren't fullstack experts but want production-quality applications.

**Tagline:** Surfaces what you don't know. Enforces what you'd forget. Evaluates what you can't judge.

## Design Principles

1. **Opus is the CTO, you are the PM** — Opus makes all technical decisions. You make product decisions. Opus explains every choice with alternatives, industry backing, and honest downsides so you learn and can push back.
2. **Always-on context beats on-demand retrieval** — Standards live in CLAUDE.md (100% enforcement per Vercel's research). Not in skills the model might forget to invoke (53%).
3. **Hooks enforce, CLAUDE.md suggests** — CLAUDE.md compliance caps at ~80%. Hooks execute 100% of the time. Critical quality gates are hooks, not instructions.
4. **Less is more for Opus 4.6** — Every component encodes an assumption about what the model can't do (Anthropic). Opus 4.6 dropped sprint constructs entirely. Only keep what's proven load-bearing.
5. **Build to delete** — Every piece of harness logic will be obsoleted by the next model. Keep components modular and independently removable (Phil Schmid).
6. **Teach, don't hide** — The user is learning. Explain key concepts at decision points and during building. Not every line — just the concepts that help them understand what they own.

## Research Backing

| Finding | Source | How Pilot Uses It |
|---------|--------|-------------------|
| AGENTS.md 100% vs skills 53% | Vercel (Jan 2026) | Standards index lives in CLAUDE.md, not skills |
| Skills unused 56% of time, degrade quality below baseline | Vercel (Jan 2026) | Zero auto-trigger skills. Commands only. |
| "Every component encodes an assumption" | Anthropic (Mar 2026) | 4 hooks, not 10. Each justified. |
| Sprint constructs dropped with Opus 4.6 | Anthropic (Mar 2026) | No task decomposition/reminders |
| Evaluator valuable "at the edge" of model capability | Anthropic (Mar 2026) | Critic for subjective quality, not basic checks |
| Radical simplification failed; methodical ablation worked | Anthropic (Mar 2026) | Removed 3 hooks with evidence, kept 4 |
| CLAUDE.md compliance ~80%, hooks 100% | Builder.io | Quality gates are hooks, not CLAUDE.md rules |
| 40KB → 8KB compressed index, zero loss | Vercel (Jan 2026) | Compressed standards index pointing to retrievable files |
| "Prefer retrieval-led reasoning" directive | Vercel (Jan 2026) | Embedded in every generated CLAUDE.md |
| Exit code 2 displayed as "Error", can brick sessions | GitHub #38422, #35086, #24327 | Stop hook has 3-attempt max-retry guard |
| Auto-evolved harnesses beat hand-engineered | Meta-Harness (arXiv 2603.28052) | Keep harness minimal, let model figure out the path |
| Pi: 4 tools, minimal prompt, viable for daily coding | Armin Ronacher | Everything above baseline must justify its cost |
| Sonnet 4.6 SWE-bench 79.6% vs Opus 80.8% | Benchmark data | Sonnet for Critic + autonomous mode, Opus for interactive |
| Context awareness NOT on Opus 4.6 | Anthropic docs | Hooks compensate for missing native budget tracking |

---

## Architecture

```
pilot/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/                    # 7 commands (down from 10)
│   ├── new.md                   # /pilot:new — Product Discovery + PRD.md
│   ├── plan.md                  # /pilot:plan — Research + Architecture + Verified PLAN.md
│   ├── feature.md               # /pilot:feature — TDD Feature Builder + Auto-Critic at Milestones
│   ├── evaluate.md              # /pilot:evaluate — Manual Critic (grades against PRD + PLAN)
│   ├── auto.md                  # /pilot:auto — Overnight TDD Autonomous
│   ├── pause.md                 # /pilot:pause — Handoff for /clear
│   └── setup.md                 # /pilot:setup — Add standards to existing project
├── agents/
│   └── critic.md                # Sonnet 4.6 evaluator (6 criteria, business terms)
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── stop-verify.sh       # Stack-aware quality gate + 3-attempt max
│       ├── post-edit-check.sh   # Stack-aware type check after edits
│       ├── pre-compact-save.sh  # State save before compaction
│       └── session-restore.sh   # State restore on session start
├── references/                  # Universal standards (stack-agnostic)
│   ├── security/
│   │   ├── owasp-top-10.md
│   │   ├── env-handling.md
│   │   ├── auth-patterns.md
│   │   ├── input-sanitization.md
│   │   └── api-security.md
│   ├── accessibility/
│   │   ├── wcag-aa-essentials.md
│   │   ├── keyboard-navigation.md
│   │   ├── screen-reader.md
│   │   └── color-contrast.md
│   ├── performance/
│   │   ├── core-web-vitals.md
│   │   ├── bundle-optimization.md
│   │   ├── query-optimization.md
│   │   └── image-optimization.md
│   └── production/
│       ├── error-handling.md
│       ├── loading-states.md
│       ├── empty-states.md
│       ├── edge-cases.md
│       └── seo-basics.md
└── templates/                   # One CLAUDE.md template per stack
    ├── _standards-index.md      # Universal index (all templates include this)
    ├── nextjs-supabase.md
    ├── nextjs-marketing.md
    ├── python-fastapi.md
    ├── python-django.md
    ├── python-flask.md
    ├── rust-axum.md
    ├── rust-actix.md
    ├── go-chi.md
    ├── go-gin.md
    ├── csharp-aspnet.md
    ├── csharp-blazor.md
    ├── java-spring.md
    ├── react-native-expo.md
    ├── electron-vite.md
    ├── svelte-kit.md
    ├── vue-nuxt.md
    ├── php-laravel.md
    ├── ruby-rails.md
    └── TEMPLATE-GUIDE.md        # How to add your own stack
```

### What Changed From v0.1.0

| Component | v0.1.0 | v0.2.0 | Why |
|-----------|--------|--------|-----|
| Commands | 10 | 7 | Removed 4 (milestone, clean, standards, upgrade). Added 1 (plan). Net -3. |
| Hook scripts | 10 | 4 | Removed: prompt-reinject (hurts Opus 4.6), context-monitor (crude proxy), reset-counter (no longer needed). Added: max-retry on Stop, stack detection |
| Skills | 1 (auto-trigger) | 0 | Auto-trigger skills fail 56% of time (Vercel). Commands only. |
| References | 18 (Next.js-centric) | 18 (universal) | Rewritten to be stack-agnostic. Principles not patterns. |
| Templates | 6 | 19+ | One CLAUDE.md template per stack. Extensible. |
| Interaction model | Semi-technical questions | Product-only questions + teach moments | Opus is CTO. User is PM who learns. |
| Build model | Implicit (Opus in session) | Explicit: Opus interactive, Sonnet autonomous/evaluation | Research-informed model routing |
| PRD | None | PRD.md generated by /pilot:new | Human-readable requirements doc, Critic grades against it |
| Planning | None | PLAN.md with verified architecture, data models, API, file-level features | Critic verifies plan before execution |
| TDD | None | Tests written BEFORE code in /pilot:feature and /pilot:auto | Stop hook blocks until tests pass |
| Integration testing | None | Automatic at milestone boundaries | Verifies features work together, not just individually |
| Auto-evaluation | On-demand only | Automatic at milestone completion + on-demand | Quality isn't optional |

---

## Commands

### /pilot:new — The CTO Onboarding

**Purpose:** Turn a product idea into a production-ready project foundation with full technical justification.

**Allowed tools:** Read, Write, Bash, Glob, Grep, AskUserQuestion, Agent

**Interaction model:** Opus acts as CTO presenting to the CEO/PM. Makes all technical decisions. Only asks product/business questions. Explains every choice with industry backing and honest downsides. Teaches key concepts.

**Process:**

#### Step 1: Understand the Product (2-4 product questions only)

Parse the user's description. Identify the product domain. Ask ONLY business/product questions:

- "Who uses this and what's the one thing they need to accomplish?"
- "Will users pay? If yes — subscription, one-time, or freemium?"
- "Any integrations with external services? (payments, email, file storage, maps, etc.)"
- "Just you building this, or will others join later?"

NEVER ask technical questions. Opus decides:
- Stack and framework
- Database and ORM
- Auth provider
- Styling approach
- Deployment target
- All architecture patterns

#### Step 2: Research Current State

Before presenting decisions, Opus queries its own knowledge and optionally Context7 for the detected stack's latest documentation. This is NOT a separate agent — Opus does this inline as part of its thinking.

The CLAUDE.md will include: `Prefer retrieval-led reasoning over pre-training for framework-specific APIs. Resolve and query latest docs via Context7 before implementing.`

#### Step 3: Present Architecture Proposal

Present every major technical decision in this format:

```
DECISION: [Technology]
├── What this is: [1-2 sentence explanation a non-expert understands]
├── Why for your project: [Business benefit, not technical benefit]
├── Who uses this: [Real companies. Not "it's popular" — names.]
├── vs [Alternative 1]: [Why not, in business terms]
├── vs [Alternative 2]: [Why not, in business terms]
├── vs [Alternative 3]: [Why not, in business terms]
└── ⚠️ Honest downside: [Lock-in risk, pricing risk, limitations. Brutal.]
```

Cover at minimum: Framework, Database, Auth, Styling, Deployment. Add Payments, Email, Storage, Real-time as relevant to the project.

Wait for user approval. Accept pushback: "I've heard Firebase is good" → Opus explains honestly why it disagrees or agrees and switches.

#### Step 4: Surface What They Didn't Think Of

Based on the product description and decisions, identify everything a production app needs that wasn't mentioned:

- Authentication & authorization (if users exist)
- Input validation and sanitization
- Error handling (boundaries, try/catch, user-facing messages)
- Loading states and skeleton screens
- Empty states (zero-data, first-run)
- Mobile responsiveness
- SEO basics (if web-facing)
- Accessibility (keyboard nav, screen reader, contrast)
- Environment variable handling
- Rate limiting on public endpoints
- Proper error logging

Present as: "Here's everything I'm including that you didn't ask for, and why each matters to your users."

#### Step 5: Set Up Project

1. Select the matching template from `templates/`
2. Run `setup-references.sh` to copy universal references to `.pilot/references/`
3. Generate CLAUDE.md by filling the template with:
   - Project spec (from user's answers)
   - Architecture decisions (from the proposal)
   - Stack-specific patterns (from the template)
   - Universal standards index (from `_standards-index.md`)
   - Retrieval-led reasoning directive
4. Scaffold the project (run framework's init commands)
5. Initialize git, first commit: `chore: initialize project with Pilot standards`

#### Step 6: Handoff

```
Project ready. Here's what was created:
- CLAUDE.md with your spec + standards (the brain)
- .pilot/references/ with production standards (the knowledge)
- Hooks active: type checking + test enforcement (the enforcement)

━━━ Start building ━━━

/pilot:feature [SPECIFIC FIRST FEATURE from the spec]
```

ALWAYS fill in the specific feature name.

---

### /pilot:plan — Research + Architecture + Verified Blueprint

**Purpose:** Research the domain, design the architecture, and create a verified implementation plan. Run after /pilot:new, before /pilot:feature. No code is written — only documents.

**Allowed tools:** Read, Write, Bash, Glob, Grep, AskUserQuestion, Agent

**Process:**

1. **Domain Research** — What do production versions of this product need? Workflows, edge cases, legal/compliance.
2. **System Architecture** — Components, data flow, integrations.
3. **Data Models** — Every table, field, relationship, index.
4. **API/Route Design** — Every endpoint with auth, validation, request/response shapes.
5. **Feature Breakdown** — File-level specificity per feature. Exact files to create/modify. Test cases per feature. Dependencies between features. Checkbox format (`- [ ]`) for tracking completion.
6. **Save** — Write to PLAN.md at project root.
7. **Self-Review** — Scan for placeholders, contradictions, missing tests, dependency issues.
8. **Plan Verification** — Spawn Critic to verify: PRD coverage, data model integrity, API consistency, dependency graph, test coverage, security review, missing concerns. Fix issues and re-verify until PASS.
9. **User Review** — User approves the written PLAN.md before any code is written.

---

### /pilot:feature — TDD Feature Builder

**Purpose:** Build a feature using TDD. Tests come BEFORE implementation. Auto-evaluates at milestone boundaries.

**Allowed tools:** Read, Write, Bash, Glob, Grep, AskUserQuestion

**Interaction model:** Opus builds autonomously. Reads PLAN.md for this feature's requirements, files, and test cases. Only asks PRODUCT decisions. Teaches key concepts. Tests first, implement second.

**Process:**

1. **Context** — Read PLAN.md for feature requirements + test cases. Read CLAUDE.md for patterns.
2. **Enrich** — 0-1 product questions. Read relevant `.pilot/references/`.
3. **Present checklist** — Includes "Tests to write FIRST" section with specific test cases.
4. **Build (TDD)** — Write tests → run (should fail) → implement → run (should pass) → refactor. Hooks block completion until type checks AND tests pass.
5. **Complete** — Update PLAN.md (mark `[x]`), append decisions to PRD.md, delete current-feature.md, commit.
6. **Milestone check (automatic)** — If last feature in milestone: write integration/E2E tests for the milestone workflow, spawn Critic automatically against PRD + PLAN + 6 criteria, present results with priority fixes. If last milestone in project: announce feature-complete.

```
## Feature: [Name]

### What you asked for
[1-2 sentences restating their request]

### What I'm adding (things you'd miss)
- [ ] [Concern — why it matters to your users]
- [ ] [Concern — why it matters to your users]

### Key decisions
[Brief: "For payments I'm using Stripe — Shopify, Notion, and 90%
of SaaS products use it. Alternative: Paddle handles sales tax
automatically but is less flexible. ⚠️ Going Stripe means you
handle sales tax yourself if you expand internationally."]

### Build order
1. [Foundation]
2. [Core functionality]
3. [Error/edge cases]
4. [Polish: loading states, empty states, accessibility]
```

Save to `.pilot/current-feature.md` when user says go.

#### Step 4: Build

Work through the checklist. For each item:
1. Read relevant reference files before implementing
2. Build it
3. Mark `[x]` in `.pilot/current-feature.md`
4. Commit atomically
5. At key moments, teach: "I'm adding a loading skeleton here — this is what users see while data loads instead of a blank screen. Without it, the page flashes white for 200ms and feels broken."

The Stop hook blocks completion until type checks pass and tests pass.

#### Step 5: Complete

```
Feature complete: [NAME]

━━━ Next step ━━━

Evaluate what you built:
   /pilot:evaluate

Or next feature:
   /pilot:feature [NEXT FEATURE — specific name]
```

Delete `.pilot/current-feature.md` and `.pilot/handoff.md` if they exist.

---

### /pilot:evaluate — The Critic

**Purpose:** Separate evaluation by a different model instance. Self-evaluation is broken — agents "reliably skew positive when grading their own work" (Anthropic).

**Allowed tools:** Read, Bash, Grep, Glob, Agent

**Process:**

1. Read CLAUDE.md for project context
2. Spawn the `pilot-critic` agent (Sonnet 4.6)
3. Present the Critic's report to the user with findings translated to business impact
4. Offer to fix issues or continue to next feature

If there are fixes, work through them in the current session (Opus fixes, not Sonnet). After all fixes, optionally re-run the Critic.

---

### /pilot:auto — Overnight Autonomous

**Purpose:** Build the feature checklist unattended. Each checklist item runs in a fresh Sonnet session for context isolation.

**Allowed tools:** Read, Bash, Write

**Prerequisites:** CLAUDE.md exists, `.pilot/current-feature.md` exists with checklist.

**Process:**

Each iteration:
1. Fresh `claude -p` session (Sonnet-class, cost-efficient)
2. Reads CLAUDE.md + checklist + references
3. Does ONE task
4. Commits atomically
5. Updates checklist on disk
6. Hook verifies (type check + tests)
7. 3-second pause, next iteration

When checklist complete:
1. Run verification (type check, lint, build, tests)
2. If pass → run Critic evaluation → save report
3. If fail → fix iteration, then re-verify

**Safety:** Max iterations cap (default 30). 3-attempt limit per stuck task. All work committed to git. Human reviews `git log` and `.pilot/auto-eval-report.txt` in the morning.

---

### /pilot:pause — Handoff for /clear

**Purpose:** Write a handoff note so the next session can resume instantly.

**Allowed tools:** Read, Write, Bash, Grep, Glob

**Process:**

1. Commit uncommitted work
2. Update `.pilot/current-feature.md` (mark completed items)
3. Write `.pilot/handoff.md` with: what was being done, current state, key decisions, what's next, files modified, problems encountered, how to verify
4. Give the user exact resume instructions

---

### /pilot:setup — Add Standards to Existing Project

**Purpose:** Add Pilot standards to a project that already exists without running `/pilot:new`.

**Allowed tools:** Bash, Read, Write

**Process:**

1. Detect the stack from project files
2. Copy universal references to `.pilot/references/`
3. Suggest adding the standards index to existing CLAUDE.md
4. Report what was added

---

## Agent: The Critic

```yaml
name: pilot-critic
model: sonnet
tools: Read, Grep, Glob, Bash
```

**Personality:** Ruthlessly strict. NOT helpful. NOT encouraging. Evidence-based. Every finding must reference a specific file and line.

**Key change from v0.1.0:** Findings are translated into business impact terms alongside technical details.

### 6 Criteria

**1. Functionality** — Can users complete their primary goals? Do all interactive elements work?

**2. Design Quality** — Coherent visual identity or generic AI slop? Look for: purple gradients on white cards, centered everything, excessive whitespace, stock placeholder text.

**3. Security** — Env vars handled properly? User input validated? API routes protected? Rate limiting present?

**4. Accessibility** — Heading hierarchy? Alt text? Keyboard accessible? Form labels? Color contrast?

**5. Performance** — Sequential awaits that should be parallel? Images optimized? Heavy components lazy loaded? Barrel imports?

**6. Production Readiness** — Error boundaries? Loading states? Empty states? Custom 404? Console.logs removed?

### Report Format

Each finding has BOTH a technical reference AND a business impact:

```
### 3. Security: PARTIAL

- api/payments/route.ts:15 — No rate limiting on payment endpoint
  → Someone could spam this and rack up your Stripe processing fees

- lib/db.ts:8 — Database URL in source code, not environment variable
  → If this code is public on GitHub, anyone can access your database
```

### Priority Fixes

Ordered by business impact severity, not technical severity.

---

## Hooks

### hooks.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/post-edit-check.sh\"",
            "timeout": 30
          }
        ],
        "description": "Stack-aware type/compile check after editing source files"
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stop-verify.sh\"",
            "timeout": 60
          }
        ],
        "description": "Quality gate: type check + tests. Exit 2 blocks stop. 3-attempt max prevents bricking."
      }
    ],
    "PreCompact": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/pre-compact-save.sh\"",
            "timeout": 10
          },
          {
            "type": "prompt",
            "prompt": "Context compaction is about to fire. Commit any uncommitted work now. State saved to .pilot/state.json. After compaction, read .pilot/current-feature.md and .pilot/handoff.md to resume."
          }
        ],
        "description": "Save state to disk before compaction destroys conversation context"
      }
    ],
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-restore.sh\"",
            "timeout": 10
          }
        ],
        "description": "Restore context from disk after /clear or compaction"
      }
    ]
  }
}
```

### Hook: stop-verify.sh

**Purpose:** The enforcement backbone. Blocks Claude from stopping unless quality gates pass.

**Stack detection via filesystem:**

```
tsconfig.json        → npx tsc --noEmit
pyproject.toml       → mypy . (or python -m py_compile)
setup.py             → mypy . (or python -m py_compile)
Cargo.toml           → cargo check
go.mod               → go vet ./...
*.csproj / *.sln     → dotnet build --no-restore
Gemfile              → bundle exec ruby -c (syntax check)
composer.json        → php -l (lint)
```

**Three enforcement gates:**

1. Type/compile errors → BLOCK (exit 2) + feed errors back
2. Test failures (if test script exists and isn't default "no test") → BLOCK (exit 2) + feed failures back
3. Unchecked feature items (if `.pilot/current-feature.md` exists and context isn't exhausted) → BLOCK (exit 2) + show next task

**3-attempt max-retry guard:**

```bash
RETRY_FILE=".pilot/.stop-retry-count"
RETRY_COUNT=0
if [ -f "$RETRY_FILE" ]; then
  RETRY_COUNT=$(cat "$RETRY_FILE" 2>/dev/null || echo "0")
fi

if [ "$RETRY_COUNT" -ge 3 ]; then
  echo "WARNING: 3 stop attempts blocked. Allowing stop to prevent session bricking." >&2
  echo "Unresolved issues exist. Run /pilot:evaluate to see them." >&2
  rm -f "$RETRY_FILE"
  exit 0
fi

# ... run checks ...

if [ "$HAS_ERRORS" = true ]; then
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "$RETRY_COUNT" > "$RETRY_FILE"
  exit 2
fi

# All passed — reset counter and allow stop
rm -f "$RETRY_FILE"
exit 0
```

This prevents the exit code 2 bricking bug documented in GitHub #38422, #24327.

### Hook: post-edit-check.sh

**Purpose:** Immediate feedback on type/compile errors after editing source files. Same stack detection as stop-verify.sh but only runs on relevant file extensions.

**Behavior:** Exit 0 always (PostToolUse can't block). Errors shown via stderr so Claude sees and fixes them before the Stop hook blocks.

### Hook: pre-compact-save.sh

**Purpose:** Emergency state snapshot before compaction. Same as v0.1.0.

**Saves to `.pilot/state.json`:** timestamp, git branch, last commit, uncommitted file count, active feature excerpt, last milestone.

### Hook: session-restore.sh

**Purpose:** Restore context after /clear or compaction. Same as v0.1.0.

**Priority:** handoff.md (intentional pause) → state.json (emergency compaction) → current-feature.md (active work)

---

## Templates

### Template Structure

Each template is a single markdown file that becomes the project's CLAUDE.md when filled in by `/pilot:new`. Every template includes the universal `_standards-index.md` content.

A template contains:

1. **Project header** — `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}` placeholders
2. **Architecture section** — Stack-specific: framework, database, auth, styling, deployment with brief rationale
3. **Project structure** — Recommended directory layout for that stack
4. **Code standards** — "Always do" and "Never do" lists specific to the stack
5. **Stack-specific patterns** — Key code examples (e.g., server action pattern for Next.js, dependency injection for C#, error handling in Rust)
6. **Universal standards index** — Included from `_standards-index.md`, pointing to `.pilot/references/`
7. **Retrieval directive** — `Prefer retrieval-led reasoning over pre-training for framework-specific APIs. Query Context7 before implementing patterns.`

### Stack Templates Included

| Template | Stack | Primary Use Case |
|----------|-------|-----------------|
| nextjs-supabase.md | Next.js + Supabase + Clerk | SaaS webapps, dashboards |
| nextjs-marketing.md | Next.js + MDX | Landing pages, blogs, docs |
| python-fastapi.md | FastAPI + SQLAlchemy + Pydantic | REST APIs, microservices |
| python-django.md | Django + DRF | Full-stack web apps, admin-heavy |
| python-flask.md | Flask + SQLAlchemy | Lightweight APIs, prototypes |
| rust-axum.md | Axum + SQLx + Tokio | High-performance APIs |
| rust-actix.md | Actix-web + Diesel | Web services, performance-critical |
| go-chi.md | Chi + sqlc + pgx | Go REST APIs, microservices |
| go-gin.md | Gin + GORM | Go web apps, rapid prototyping |
| csharp-aspnet.md | ASP.NET Core + EF Core | Enterprise APIs, .NET ecosystem |
| csharp-blazor.md | Blazor + EF Core | .NET interactive web apps |
| java-spring.md | Spring Boot + JPA | Enterprise Java applications |
| react-native-expo.md | Expo + Expo Router | Mobile apps (iOS + Android) |
| electron-vite.md | Electron + Vite + React | Desktop apps (macOS, Windows, Linux) |
| svelte-kit.md | SvelteKit + Prisma | Fast web apps, lighter alternative to Next.js |
| vue-nuxt.md | Nuxt 3 + Pinia | Vue ecosystem web apps |
| php-laravel.md | Laravel + Eloquent | PHP web apps, rapid development |
| ruby-rails.md | Ruby on Rails + ActiveRecord | Full-stack web apps, startups |

### Community Extensibility

Anyone can add a stack by creating a new template file following `TEMPLATE-GUIDE.md`. No code changes needed. The hook auto-detects stacks from the filesystem — if the new stack has a recognizable config file (e.g., `deno.json` for Deno), it works automatically.

If the stack's type checker isn't in the hook's detection list, the template should document this and the user can add the detection to their project-level settings.

---

## References (Universal)

References are stack-agnostic PRINCIPLES, not stack-specific PATTERNS. They describe WHAT to do, not HOW to do it in a specific language.

### Security (5 files)
- **owasp-top-10.md** — The 10 categories with universal guidance (not framework-specific code)
- **env-handling.md** — Never hardcode secrets, validation pattern concept, deployment checklist
- **auth-patterns.md** — Middleware protection, server-side auth checks, row-level security, webhook verification (concepts, not code)
- **input-sanitization.md** — Validate at the boundary, common validation rules, what to validate, what not to do
- **api-security.md** — Rate limiting, CORS, security headers, webhook verification

### Accessibility (4 files)
- **wcag-aa-essentials.md** — POUR principles, implementation checklist
- **keyboard-navigation.md** — Focus management, skip links, modal trapping, testing
- **screen-reader.md** — Semantic HTML > ARIA, live regions, form associations
- **color-contrast.md** — Required ratios, common failures, testing methods

### Performance (4 files)
- **core-web-vitals.md** — LCP/INP/CLS targets, optimization strategies
- **bundle-optimization.md** — Tree shaking, code splitting, lazy loading (concepts)
- **query-optimization.md** — N+1 prevention, parallel queries, indexing strategy, caching (replaces waterfall-prevention.md — now universal, not just web)
- **image-optimization.md** — Responsive images, lazy loading, format selection

### Production (5 files)
- **error-handling.md** — Error boundaries/handlers, user-facing messages, logging
- **loading-states.md** — Skeleton screens, progress indicators, optimistic updates
- **empty-states.md** — Zero data, no results, error state, permission denied
- **edge-cases.md** — Offline, slow connections, concurrent edits, session expiry, timezone
- **seo-basics.md** — Meta tags, sitemaps, semantic HTML, structured data

---

## State Management (.pilot/ directory)

Created per-project, gitignored. Survives /clear and compaction.

| File | Written By | Read By | Purpose |
|------|-----------|---------|---------|
| `current-feature.md` | /pilot:feature | stop-verify, session-restore, pilot-auto | Active feature checklist |
| `handoff.md` | /pilot:pause | session-restore | Detailed handoff for next session |
| `state.json` | pre-compact-save | session-restore | Emergency compaction backup |
| `references/` | /pilot:new, /pilot:setup | Opus during building | Universal standards files |
| `.stop-retry-count` | stop-verify | stop-verify | Max-retry counter (prevents bricking) |

---

## Execution Model

```
INTERACTIVE (user present):
┌──────────────────────────────────────┐
│  Opus 4.6 — main session             │
│  Builds directly. Full context.       │
│  Makes all technical decisions.       │
│  Asks only product questions.         │
│  Teaches key concepts as it builds.   │
│  Hooks enforce quality at every edit. │
│  Stop blocks until clean.             │
└──────────────────────────────────────┘

EVALUATION (on-demand via /pilot:evaluate):
┌──────────────────────────────────────┐
│  Sonnet 4.6 — Critic subagent        │
│  Separate model prevents self-grading.│
│  6 criteria with business impact.     │
│  file:line evidence for every finding.│
└──────────────────────────────────────┘

AUTONOMOUS (overnight via /pilot:auto):
┌──────────────────────────────────────┐
│  Fresh claude -p per checklist item   │
│  Context isolation prevents rot.      │
│  Hook verification after each task.   │
│  Critic evaluation when all done.     │
│  Human reviews git log in morning.    │
└──────────────────────────────────────┘
```

---

## The /pilot:new Interaction (Example)

```
USER: /pilot:new an app where freelancers can track invoices and expenses

OPUS: I'll be your tech lead for this. Let me ask a few things about
your PRODUCT — I'll handle all the technical decisions.

1. Will freelancers pay for this? If yes — monthly subscription,
   one-time purchase, or freemium with upgrades?

USER: Monthly subscription, maybe a free tier with limits

OPUS: 2. Do freelancers send invoices TO their clients from the app
(generate PDFs, email them, track payment status)? Or just log
invoices they created elsewhere?

USER: They should send them from the app

OPUS: 3. Just USD, or multiple currencies?

USER: USD only for now but maybe international later

OPUS: Got it. Here's my architecture proposal:

━━━ Architecture Proposal ━━━

FRAMEWORK: Next.js (App Router)

What this is: A React-based framework that renders pages on the server
before sending them to the browser. Think of it as the skeleton that
holds your entire app together — every page, every button, every API
endpoint lives here.

Why for your project: Your freelancers will Google "invoice tracking app"
— server rendering means Google can actually read your pages and rank
them. Built-in API routes mean no separate backend server to manage.
Deploys to Vercel with zero configuration.

Who uses this: Notion, TikTok, Hulu, ChatGPT's web interface. The React
team (at Meta) officially recommends it as the production React framework.

vs SvelteKit: Genuinely faster to write code in. But smaller ecosystem —
fewer component libraries, fewer tutorials, harder to find answers when
stuck. If you scale and hire, the talent pool is 10x smaller.

vs Ruby on Rails: Incredible for rapid prototyping (Shopify, GitHub,
Basecamp built on it). But you'd be learning a completely new language
(Ruby) and ecosystem. AI coding tools understand JavaScript better in
2026.

vs Laravel (PHP): Huge community, cheapest hosting of any framework.
But real-time features (live invoice status updates) require additional
setup. The ecosystem is mature but not growing as fast.

⚠️ Honest downside: Vercel lock-in for some deployment features. The
framework changes patterns between major versions — what you learn today
may shift in 12 months. If Vercel raises prices, migrating requires
work.

[... continues for Database, Auth, Payments, Styling, Deployment ...]

━━━
Change anything? Or should I build this?
━━━
```

---

## Migration From v0.1.0

For projects already using Pilot v0.1.0:

1. Old hooks in `.claude/settings.json` still work but should be replaced
2. Run `/pilot:setup` to update `.pilot/references/` with universal versions
3. The CLAUDE.md standards index format is compatible — no changes needed
4. `.pilot/current-feature.md` and `.pilot/handoff.md` formats are unchanged
5. Old commands (`/pilot:milestone`, `/pilot:clean`, `/pilot:standards`, `/pilot:upgrade`) will no longer exist — their functionality is absorbed into the remaining 6 commands

---

## What Pilot Is NOT

- **Not a workflow engine.** No phases, milestones, sprints, workspaces. GSD does this (30K LOC). Pilot is 3K LOC.
- **Not a skills library.** No 46 on-demand skills. Superpowers does this (17K LOC). Pilot has 0 skills.
- **Not a process framework.** No mandatory TDD, no mandatory brainstorming, no mandatory planning documents. Opus decides what process is appropriate.
- **Not a prompt engineering framework.** Pilot doesn't try to make the model smarter through prompting. It gives the model KNOWLEDGE it doesn't have and ENFORCEMENT it can't self-impose.

Pilot is knowledge + enforcement + evaluation. Nothing more.

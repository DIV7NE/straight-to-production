# STP — Ship To Production — Claude Code Plugin

## What This Is
A Claude Code plugin (v0.2.0) that turns Opus into your CTO. 14 commands, 3 agents, 25 reference files, 20 templates, visual whiteboard, wave-based parallel building.

## Architecture
- **Opus** = CTO (plans, researches, reviews, merges, teaches). Builds foundation work directly (DB, auth, config).
- **Sonnet executors** = builders (features on top of foundation, worktree isolation, Agent Teams for parallelism)
- **Sonnet QA** = independent tester (tests running app against PRD acceptance criteria)
- **Sonnet Critic** = code reviewer (7 criteria including AI slop detection)

## Commands
- `/stp:whiteboard` — explore ideas
- `/stp:new-project` — start from scratch (pre-flight → constraint detection → 3-axis questions → 2-3 approaches → sectioned architecture → PRD.md)
- `/stp:plan` — architecture blueprint (9 phases → Critic verifies → whiteboard diagrams → PLAN.md)
- `/stp:develop` — full development cycle (understand → tools → research → plan → build) in one flow
- `/stp:propose` — discuss, research, and plan work before building (stops before execution)
- `/stp:build` — build, fix, refactor, or update (picks up existing plan if exists, or does its own research)
- `/stp:review` — 7-criteria evaluation
- `/stp:autopilot` — overnight autonomous (full cycle OR checklist, AI picks recommended choices)
- `/stp:debug` — systematic debugging (auto-gather → reproduce → diagnose → fix → verify)
- `/stp:progress` — check project status (what's done, in progress, next)
- `/stp:continue` — resume exactly where you left off after /clear or new session
- `/stp:pause` — handoff for /clear
- `/stp:onboard-existing` — take over existing codebase
- `/stp:upgrade` — pull latest from GitHub

## Key Rules
- Opus NEVER writes implementation code (except foundation: DB, auth, config, one-line fixes)
- ALL features delegate to Sonnet executor via Agent Teams with worktree isolation
- AskUserQuestion tool is MANDATORY for ALL user decisions — NEVER print options as text, NEVER skip, NEVER decide for the user. Only exception: freeform input where structured options don't make sense (bug descriptions, QA feedback, feature requests)
- TaskCreate/TaskUpdate tracks ALL progress visibly
- README.md updated + VERIFIED after every feature
- 8-part research before every feature (codebase, impact, feature, security, resilience, edge cases, backward integration, anti-hallucination)
- TDD mandatory — stop hook blocks if no tests exist
- /simplify + hygiene scan after every build
- Version bump + CHANGELOG + CONTEXT.md update after every feature

## Directory Map (where everything lives, when to read it)

### .stp/docs/ — Project Documents
| File | What | Read when... | Updated by |
|------|------|-------------|------------|
| ARCHITECTURE.md | Full codebase map (models, routes, components, integrations, dependencies) | Before ANY code change — check what exists and what could break | /stp:onboard-existing, milestone refresh |
| AUDIT.md | Production health (Sentry errors, deploy status, billing, performance) | Before fixing bugs, planning remediation | /stp:onboard-existing, /stp:review |
| PRD.md | Requirements + acceptance criteria | Starting features, QA, reviewing | /stp:new-project, /stp:build |
| PLAN.md | Architecture + feature waves | Planning builds, dependency checks | /stp:plan, /stp:build |
| CONTEXT.md | Concise AI reference (<150 lines) | Quick lookup, links to ARCHITECTURE.md for full detail | /stp:build (per feature + milestone refresh) |
| CHANGELOG.md | Versioned history | Checking recent work | /stp:build (per feature + milestone) |

### .stp/state/ — Runtime State (survives /clear + compaction)
| File | Purpose | Created by |
|------|---------|------------|
| current-feature.md | Active feature checklist | /stp:build |
| handoff.md | Pause context for next session | /stp:pause (consumed by /stp:continue) |
| state.json | Emergency auto-save | PreCompact hook |

### .stp/references/ — Production Standards (read BEFORE writing code)
| Directory | Read before touching... |
|-----------|----------------------|
| security/ | Auth, user input, API routes, secrets |
| accessibility/ | UI components, forms, navigation |
| performance/ | Data fetching, images, bundles |
| production/ | Error handling, deploy, monitoring, edge cases |

### Root Files
| File | Why at root |
|------|------------|
| CLAUDE.md | Claude Code auto-reads from project root |
| VERSION | Statusline + scripts need instant access |

## Memory Strategy (how STP remembers across sessions)
STP uses file-based memory — everything lives in .stp/docs/. No reliance on Claude's conversation memory.
- **What was built + decisions**: CHANGELOG.md (append per feature, includes failed approaches from handoff)
- **What exists now**: ARCHITECTURE.md (full map) + CONTEXT.md (concise)
- **What's planned**: PLAN.md (milestones, features, status)
- **What was promised**: PRD.md (requirements, acceptance criteria)
- **Production health**: AUDIT.md (Sentry, deploy, billing — refreshed by /stp:review)
- **Bug patterns**: AUDIT.md Patterns & Lessons section (every debug writes a generalizable lesson — build reads these to avoid repeating mistakes)
- **Project conventions**: CLAUDE.md `## Project Conventions` section (living rules — grows from build decisions, debug lessons, Critic findings, and onboarding detection. Read on every session, enforced by Critic.)
- **Session continuity**: handoff.md (created by /stp:pause, consumed by /stp:continue — lessons preserved to CHANGELOG before deletion)
- **Session restore**: hook fires on start, reads state files, suggests /stp:continue

On any new session: read CHANGELOG.md for history, ARCHITECTURE.md for context, PLAN.md for what's next. This gives full project memory regardless of /clear, compaction, or machine changes.

## Statusline
Node.js statusline (stp-statusline.js) registered in ~/.claude/settings.json globally. Shows: model + effort level, project version, active feature + progress, current milestone, context usage bar with compaction threshold (green/yellow/orange/red).

## Hooks (6 enforcement gates)
1. Unchecked feature items → BLOCK
2. Source files without tests → BLOCK
3. Hardcoded secrets → BLOCK
4. Type/compile errors → BLOCK
5. Test failures → BLOCK
6. Missing PLAN.md → WARN

## Research
All research sources in RESEARCH-SOURCES.md. Key: Anthropic harness blog, Vercel AGENTS.md (100% vs 53%), Phil Schmid "Build to Delete", OX Security AI anti-patterns.

## Effort Levels
- /stp:new-project, /stp:plan, /stp:debug, /stp:develop → max
- /stp:propose → max
- /stp:whiteboard, /stp:build, /stp:review, /stp:continue → high
- /stp:onboard-existing → max
- /stp:autopilot → medium
- /stp:progress, /stp:pause, /stp:upgrade → low

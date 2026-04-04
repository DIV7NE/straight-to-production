# Pilot — Claude Code Plugin

## What This Is
A Claude Code plugin (v0.2.0) that turns Opus into your CTO. 9 commands, 3 agents, 25 reference files, 20 templates, visual whiteboard, wave-based parallel building.

## Architecture
- **Opus** = CTO (plans, researches, reviews, merges, teaches). Builds foundation work directly (DB, auth, config).
- **Sonnet executors** = builders (features on top of foundation, worktree isolation, Agent Teams for parallelism)
- **Sonnet QA** = independent tester (tests running app against PRD acceptance criteria)
- **Sonnet Critic** = code reviewer (7 criteria including AI slop detection)

## Commands
- `/pilot:whiteboard` — explore ideas
- `/pilot:new-project` — start from scratch (pre-flight → constraint detection → 3-axis questions → 2-3 approaches → sectioned architecture → PRD.md)
- `/pilot:plan` — architecture blueprint (9 phases → Critic verifies → whiteboard diagrams → PLAN.md)
- `/pilot:build` — TDD feature building (8-part research → Sonnet executor → QA agent → user QA → hygiene → version bump)
- `/pilot:review` — 7-criteria evaluation
- `/pilot:autopilot` — overnight autonomous (Sonnet, --model sonnet --effort medium)
- `/pilot:pause` — handoff for /clear
- `/pilot:onboard-existing` — take over existing codebase
- `/pilot:upgrade` — pull latest from GitHub

## Key Rules
- Opus NEVER writes implementation code (except foundation: DB, auth, config, one-line fixes)
- ALL features delegate to Sonnet executor via Agent Teams with worktree isolation
- AskUserQuestion for ALL user interactions (except manual QA freetext)
- TaskCreate/TaskUpdate tracks ALL progress visibly
- README.md updated + VERIFIED after every feature
- 8-part research before every feature (codebase, impact, feature, security, resilience, edge cases, backward integration, anti-hallucination)
- TDD mandatory — stop hook blocks if no tests exist
- /simplify + hygiene scan after every build
- Version bump + CHANGELOG + CONTEXT.md update after every feature

## Documents
- PRD.md = what we're building (acceptance criteria per feature)
- PLAN.md = how (architecture, data models, API, waves, verified by Critic)
- CONTEXT.md = what exists NOW (file map, schema, API, patterns — <150 lines)
- CHANGELOG.md = what happened (versioned history)
- VERSION = current version
- CLAUDE.md = standards + patterns for Claude

## Statusline
Node.js statusline (pilot-statusline.js) registered in ~/.claude/settings.json globally. Shows: model + effort level, project version, active feature + progress, current milestone, context usage bar with compaction threshold (green/yellow/orange/red).

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
- /pilot:new-project, /pilot:plan → max
- /pilot:whiteboard, /pilot:build, /pilot:review → high
- /pilot:autopilot → medium

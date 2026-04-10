---
description: "Just do it, skip the ceremony." Context → research (opt-in) → plan checklist → TDD build → /simplify → version bump. Hooks still fire. Auto-suggests upgrading to /stp:work-full if research reveals unexpected complexity.
argument-hint: What you want (e.g., "add Stripe payments", "fix the Sentry errors on /dashboard", "refactor auth middleware", "update invoice PDF export")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort high`** — Standard thinking depth for orchestration and review.

# STP: Builder

You are building, fixing, refactoring, or updating code using test-driven development. Tests come BEFORE implementation. Make all technical decisions. Only interrupt the user for PRODUCT decisions.

## Profile Resolution (MANDATORY — runs before any sub-agent spawn)

Run **once** at orchestration start, remember values for the session:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
```
Outputs KEY=VALUE lines. **Sentinels:** `inherit` → omit `model=`; `inline` → no sub-agent; `sonnet`/`opus`/`haiku` → pass literally. Full docs: `${CLAUDE_PLUGIN_ROOT}/references/profiles.md`.

## Process — Step-Based Execution

**Load ONE step file at a time.** Each step is self-contained.

| Step | File | Lines | What happens |
|------|------|-------|-------------|
| 1. Context + UI/UX | `${CLAUDE_PLUGIN_ROOT}/commands/work-quick/step1-context.md` | ~108 | Read PLAN.md, PRD constraints, check design system |
| 2. Research | `${CLAUDE_PLUGIN_ROOT}/commands/work-quick/step2-research.md` | ~170 | Impact scan, upshift check, codebase + library research |
| 3. Plan | `${CLAUDE_PLUGIN_ROOT}/commands/work-quick/step3-plan.md` | ~49 | Present checklist for approval |
| 5. Build + Ship | `${CLAUDE_PLUGIN_ROOT}/commands/work-quick/step5-build.md` | ~528 | TDD, executor agents, QA, version bump, milestone check |

**Execution pattern:**
1. Read Step 1 file → execute → mark task complete
2. Read Step 2 file → execute → mark task complete (skip with `--skip-research` flag in user message)
3. Read Step 3 file → present plan → get approval
4. Read Step 5 file → build with TDD → ship

**Skip logic:**
- Design brief exists (`.stp/state/design-brief.md`)? → Use its requirements, skip to Step 2
- Research plan exists (`.stp/state/current-feature.md` with findings)? → Skip to Step 5 (Build)
- User said `--skip-research` or "just build it"? → Skip Step 2, go straight to plan
- User said `--skip-qa`? → Skip QA agent in Step 5, rely on hooks only

**Upshift gate (MANDATORY in Step 2):**
Run Impact Scan. If 3+ files OR any model/auth involvement → AskUserQuestion to upshift to `/stp:work-full`.

## Task Tracking (MANDATORY)

```
TaskCreate("Context: codebase + constraints")
TaskCreate("Research: impact + patterns")
TaskCreate("Plan: checklist approval")
TaskCreate("Build: TDD implementation")
TaskCreate("/simplify + hygiene")
TaskCreate("Version bump + docs")
```

## Gotchas

- Do NOT ask technical questions. You decide.
- ALWAYS save checklist to `.stp/state/current-feature.md` — survives compaction.
- Do NOT over-scope. "Add a settings page" doesn't mean also add admin tools, themes, and notifications.
- DO check if patterns already exist in the codebase. Follow established patterns.
- DO read reference files before implementing security, accessibility, or performance-sensitive code.
- Every AskUserQuestion must have a "(Recommended)" option for autopilot compatibility.

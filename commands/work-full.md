---
description: "I have serious work to do, do it properly." Understand → tools → research → UI/UX design system → full architecture blueprint (13 sub-phases with section-by-section approval) → TDD build with executor agents → QA agent → manual QA → Critic evaluation (Double-Check Protocol) → version bump + docs.
argument-hint: What you want done (e.g., "update stripe payments and pricing", "add real-time notifications", "rebuild the entire auth system")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort: `/effort max`** — Full development cycle requires maximum thinking depth throughout.

# STP: Develop

The complete development cycle. One command takes you from idea → understanding → tools → research → plan → verified delivery. This is what you run when you want a piece of work done RIGHT — with full investigation, no shortcuts, and production-quality output.

**Context window management:** This command runs 22+ sub-phases in a single session. If the Context Mode MCP (`ctx_execute`, `ctx_batch_execute`) is available, use it for any operation that produces large output (codebase analysis, test runs, grep results, subagent reports). This keeps raw data in the sandbox and only your summary enters the context window, extending session life before compaction fires.

## Profile Resolution (MANDATORY — runs before any sub-agent spawn)

Run **once** at orchestration start, remember values for the session:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
```
Outputs KEY=VALUE lines (STP_PROFILE, STP_MODEL_EXECUTOR, STP_MODEL_QA, etc.). **Sentinels:** `inherit` → omit `model=` from spawn; `inline` → no sub-agent, main session does work; `sonnet`/`opus`/`haiku` → pass literally. **Discipline:** if `STP_RESEARCHER_MANDATORY=true`, delegate all research to `stp-researcher` sub-agent; if `STP_EXPLORER_MANDATORY=true`, delegate multi-file exploration to `stp-explorer` sub-agent. Full sentinel docs + spawn patterns + examples: `${CLAUDE_PLUGIN_ROOT}/references/profiles.md`.

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

## Process — Phase-Based Execution

**CRITICAL: Load ONE phase file at a time.** Read only the phase you're currently executing. This keeps the main context lean — each phase file is self-contained with all instructions needed for that phase.

| Phase | File | Lines | What happens |
|-------|------|-------|-------------|
| 1. Understand | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase1-understand.md` | ~93 | Requirements, scope, downshift check |
| 2. Context | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase2-context.md` | ~40 | Codebase + production state |
| 3. Tools + UI/UX | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase3-tools.md` | ~168 | Tool discovery, design system |
| 4. Research | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase4-research.md` | ~63 | Deep dive, approach selection |
| 5. Plan | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase5-plan.md` | ~226 | 13 sub-phase architecture blueprint |
| 6. Execute | `${CLAUDE_PLUGIN_ROOT}/commands/work-full/phase6-execute.md` | ~335 | TDD build → QA → Critic → ship |

**Execution pattern:**
1. Read Phase 1 file → execute Phase 1 → mark task complete
2. Read Phase 2 file → execute Phase 2 → mark task complete
3. Continue sequentially through all phases
4. State passes through `.stp/state/` and `.stp/docs/` — each phase reads prior outputs from disk

**Skip logic (check BEFORE reading phase files):**
- Design brief exists (`.stp/state/design-brief.md`)? → Skip Phase 1, start at Phase 2
- Research plan exists (`.stp/state/current-feature.md` with research findings)? → Skip to Phase 5
- Impact scan shows ≤2 files, no models/auth? → AskUserQuestion to downshift to `/stp:work-quick`


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

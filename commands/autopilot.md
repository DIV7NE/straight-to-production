---
description: Run STP in autonomous mode. Full development cycle OR checklist execution — unattended. AI makes all decisions automatically, picking recommended choices. Set it up before bed, wake up to delivered work.
argument-hint: What to build (e.g., "add payment processing") OR "continue" to resume existing checklist. Optional --max flag (default 30 iterations).
allowed-tools: ["Read", "Bash", "Write"]
---

> **Recommended effort: `/effort medium`** — Efficient thinking for routine execution tasks.

# STP: Autopilot Mode

Autonomous development. Same quality as interactive mode — full research, TDD, verification — but the AI makes every decision automatically. Every `AskUserQuestion` call → AI picks the `(Recommended)` option.

## Two Modes

### Mode 1: Full Cycle Autopilot (has a description)
```
/stp:autopilot add payment processing with Stripe
```
Runs the FULL `/stp:develop` cycle autonomously:
- Phase 1 (Understand): AI interprets requirements from the description
- Phase 2 (Context): reads ARCHITECTURE.md, AUDIT.md, codebase
- Phase 3 (Tools): auto-installs recommended tools (skips if interactive auth needed)
- Phase 4 (Research): full Context7 + Tavily research, picks recommended approach
- Phase 5 (Plan): creates plan, auto-approves with "Auto-approved in autopilot mode"
- Phase 6 (Execute): TDD build, automated QA (no user QA step)

### Mode 2: Checklist Execution (no description, or "continue")
```
/stp:autopilot
/stp:autopilot continue
```
Requires `.stp/state/current-feature.md` to already exist (from `/stp:propose`, `/stp:develop`, or `/stp:build`). Works through the checklist item by item.

## How It Works

Each checklist item runs in a fresh Claude Code session (headless `-p` mode) for context isolation. No context rot, no compaction, no forgetting.

```
Mode 1: Full cycle
  Session 0: Opus -p --effort high → runs /stp:develop phases 1-5 → creates plan + checklist
  Session 1: Sonnet -p --effort medium → reads checklist → task 1 → TDD → commit
  Session 2: Sonnet -p → task 2 → TDD → commit
  ...
  Session N: all [x] → verification → Critic evaluation → done

Mode 2: Checklist only
  Session 1: Sonnet -p → reads checklist → task 1 → TDD → commit
  Session 2: Sonnet -p → task 2 → TDD → commit
  ...
  Session N: all [x] → verification → Critic evaluation → done
```

## Prerequisites

**Mode 1 (full cycle):** Just CLAUDE.md and a description.
**Mode 2 (checklist):** `.stp/state/current-feature.md` with a checklist.

## How to Run

Tell the user to run this in their terminal (NOT inside Claude Code):

**Full cycle:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-auto.sh" --develop "add payment processing" 30
```

**Checklist only:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-auto.sh" 30
```

**Overnight with logging:**
```bash
nohup bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stp-auto.sh" 50 > .stp/auto.log 2>&1 &
echo "STP auto mode running. Check progress:"
echo "  tail -f .stp/auto.log"
echo "  cat .stp/state/current-feature.md"
```

## Autopilot Decision Rules

When the AI encounters a decision point (any place that would use AskUserQuestion interactively):

| Decision type | Autopilot behavior |
|--------------|-------------------|
| Approach selection | Pick `(Recommended)` option |
| Scope question | Pick broadest reasonable scope |
| Tool installation | Install if non-interactive, skip if needs auth |
| Plan approval | Auto-approve, log "Auto-approved in autopilot mode" |
| Architecture choice | Pick the most conventional/proven option |
| Risk tradeoff | Pick the safer option |
| User QA | Skip — automated QA agent only |
| Session restart needed | Skip the tool, continue without it |

**Key rule:** Every `AskUserQuestion` in every STP command has a `(Recommended)` option. Autopilot selects it. If no recommendation is clear, pick the safest/most conventional option. Log every auto-decision to `.stp/auto-decisions.log`.

## Safety

- Max iterations cap (default 30)
- Stack-aware verification after each iteration (type check + tests)
- 3-attempt limit per stuck task — skips with note after 3 failures
- All work committed to git (easy to review and revert)
- Critic evaluation runs automatically when complete
- 3-second pause between iterations
- Auto-decisions logged for user review

## After Completion

```
━━━ Run in your terminal (not in Claude Code) ━━━

Full cycle:
bash [PLUGIN_ROOT]/hooks/scripts/stp-auto.sh --develop "description" 30

Checklist only:
bash [PLUGIN_ROOT]/hooks/scripts/stp-auto.sh 30

Overnight:
nohup bash [PLUGIN_ROOT]/hooks/scripts/stp-auto.sh 50 > .stp/auto.log 2>&1 &

Check progress anytime:
  tail -f .stp/auto.log
  cat .stp/state/current-feature.md
  git log --oneline -10

In the morning:
  cat .stp/auto-eval-report.txt
  cat .stp/auto-decisions.log      # Review what the AI decided
```

Replace [PLUGIN_ROOT] with the actual resolved path.

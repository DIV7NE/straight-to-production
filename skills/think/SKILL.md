---
description: "Think before you build. Default = brainstorming dialogue. Flags: --plan (architecture), --research (focused lookup), --whiteboard (visual exploration). No code written."
argument-hint: [topic] [--plan | --research | --whiteboard]
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort:** `xhigh` for `--plan`, `max` for novel architecture; `xhigh` for `--research`; `high` for default brainstorming and `--whiteboard`. Opus 4.7 default — `max` only when genuinely warranted.

# STP: Think

Four modes. Default is loose brainstorming; flags escalate into formal planning, focused research, or visual whiteboarding. **No code is written** — outputs are design documents.

**Before spawning any agent: read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`.** Every sub-agent spawn must include the `<use_parallel_tool_calls>` XML block and context-limit line. Critic invocation must use the INVERSION framing ("report every issue").

## Shared opening

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
STACK=$(jq -r '.stack // "generic"' .stp/state/stack.json 2>/dev/null || echo "generic")
```

**Pace discipline for `/stp:think`:**
- `deep` — one question per decision, 200-300 word design sections, validation after each. Maximum curiosity.
- `batched` (DEFAULT) — AskUserQuestion with up to 4 questions per call, section-by-section validation between calls.
- `fast` — full plan in one message, single AskUserQuestion for approval.
- `autonomous` — pick sensible defaults, write the plan, ask once before commit.

**Auto-escalation:** `--plan` always runs at *minimum* `batched`. Work touching auth/payments/models auto-escalates to `batched` regardless of setting. Novel architecture (new service, new data store) auto-escalates to `deep` on first pass.

---

## Mode: default (no flag) — brainstorming

Purpose: turn a fuzzy idea into a validated design brief. Matches the superpowers:brainstorming skill's feel.

1. **Read current state** in parallel:
   - `.stp/docs/PRD.md`, `PLAN.md`, `ARCHITECTURE.md`, `CLAUDE.md` (if present)
   - `.stp/state/stack.json`
   - Recent git log: `git log --oneline -10`
2. **Pre-Work Confirmation Gate** — announce: "I'll ask questions to refine the idea, propose 2-3 approaches, then write a design brief to `.stp/state/design-brief.md`. No code." AskUserQuestion: `Proceed (Recommended) | Adjust | Cancel`.
3. **Understanding loop** (pace-driven):
   - `deep`: ask one question at a time, each building on the last answer. Focus on purpose, constraints, success criteria.
   - `batched`: ask up to 4 questions per AskUserQuestion call. Cover scope, constraints, priorities, success metric.
   - `fast`/`autonomous`: skip loop — go straight to proposal.
4. **Approach exploration** — propose 2-3 approaches with trade-offs. Lead with recommended. Show as `(Recommended)`, `(Alternative A)`, `(Alternative B)`.
5. **Design sections** (pace-driven):
   - `deep`: present 200-300 word sections, AskUserQuestion after each: `Continue | Clarify | Revise`. Cover architecture, components, data flow, error handling, testing.
   - `batched`: present full design in one message with AskUserQuestion covering 2-4 open decisions.
   - `fast`: present full design, single approval gate.
6. **Write** `.stp/state/design-brief.md` — pickupable by `/stp:build`.
7. Commit: `docs: design brief via /stp:think`.

Reference: `${CLAUDE_PLUGIN_ROOT}/references/pace-picker.md`.

---

## Mode: `--plan`

Purpose: formal architecture plan. Replaces legacy `/stp:plan`. Always runs at minimum `batched`.

1. Pre-Work Confirmation Gate.
2. Read `.stp/docs/PRD.md` if it exists. If missing, AskUserQuestion: `Draft a brief PRD first (Recommended) | Work from prompt only | Cancel`.
3. **Parallel context load:**
   - Spawn `stp-explorer` (model from profile, skip if `inline`) with scope: "Map existing relevant code; identify dependency edges; flag integration points for the proposed plan."
   - Spawn `stp-researcher` in parallel with scope: "Current best-practice for [problem] in [STACK]; top 3 production patterns; known gotchas."
4. **9-phase blueprint** (pace-driven sections):
   1. Goal restatement + success criteria
   2. System constraints (SHALL/MUST/SHOULD from PRD)
   3. Proposed architecture (2-3 alternatives, pick one)
   4. Data model + schema
   5. API / interface surface
   6. Error model + edge cases
   7. Testing strategy (unit / integration / property / spec-level)
   8. Rollout + backward compatibility
   9. Risks + open questions
5. **Validation** — spawn `stp-critic` (model from profile) with INVERSION: "Report every gap, every contradiction, every weak argument. Include uncertain findings. Downstream ranks."
6. Write `.stp/docs/PLAN.md`.
7. Commit: `docs: plan via /stp:think --plan`.
8. Next-step box: `/clear, then /stp:build` (read PLAN.md from disk, fresh context).

---

## Mode: `--research`

Purpose: focused external research, answer a specific question. No plan, no brief — just an answer.

1. Pre-Work Confirmation Gate (quick — just confirm the question).
2. **Spawn `stp-researcher`** (model from profile, SKIP if `inline` — do inline in main session instead) with scope:
   - **Research question** — user's prompt verbatim
   - **Why it matters** — one sentence from user context
   - **Output format** — 5 bullets + TL;DR + 3 citations
   - **Stop criteria** — "3 sources agree or 60% context spent"
3. Researcher returns ≤30 line summary.
4. Main session reviews: if the answer is load-bearing for a future decision, prompt user: `Save as .stp/docs/research/<topic>.md (Recommended) | Just display | Discard`.
5. If saved, commit: `docs: research — [topic]`.

If `STP_RESEARCHER_MANDATORY=false` (e.g. `opus-cto` profile), still use `stp-researcher` when the question touches >2 URLs or a large docset. The mandate is a floor, not a ceiling.

---

## Mode: `--whiteboard`

Purpose: visual exploration. Start the whiteboard server, iterate on ideas graphically.

1. **Whiteboard server start — MANDATORY FIRST ACTION.** No AskUserQuestion gate before this step:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
   ```
   Reason: a whiteboard the user can't see is broken. This runs silently in background.
2. Pre-Work Confirmation Gate — now that server is starting, confirm scope.
3. **Filename contract** — whiteboard data file is ALWAYS `.stp/whiteboard-data.json`. Never `.stp/explore-data.json`, never `.stp/whiteboard.json`, never `.stp/board-data.json`. The `whiteboard-gate` hook blocks forbidden aliases.
4. Explore modes (pace-driven):
   - `deep`: iterate on one node at a time, 200-300 word node bodies
   - `batched`: add multiple related nodes per turn, ask 2-4 questions about them
   - `fast`: sketch the full board, single confirmation
5. When the user signals done (e.g. "looks good"), write `.stp/state/design-brief.md` from the whiteboard's final state. This is pickupable by `/stp:build`.
6. Commit: `design: whiteboard brief via /stp:think --whiteboard`.

---

## Gotchas

- **No code is written in this skill.** If the user says "just build it," suggest `/stp:build` instead.
- `--plan` always runs at minimum `batched` pace — this auto-escalation is non-negotiable.
- AskUserQuestion max is 4 options. If a decision has more than 4 answers, pack the 5th+ into an `other` option that re-prompts.
- Every AskUserQuestion must have a `(Recommended)` option placed FIRST.
- Whiteboard mode's server-start is LITERAL FIRST ACTION — even before the confirmation gate. User seeing the whiteboard appear is the signal that the command is working.
- For `fast` pace, present the full design in one message with ONE approval gate. Don't micro-gate inside it.

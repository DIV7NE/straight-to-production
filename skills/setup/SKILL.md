---
description: "Setup + lifecycle — welcome, new project, onboard existing, switch model profile, switch pace, upgrade plugin. One skill, six subcommands."
argument-hint: welcome | new | onboard | model | pace | upgrade
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

> **Recommended effort:** `xhigh` for `new` and `onboard`; `high` for `welcome`, `model`, `pace`; `low` for `upgrade`. Opus 4.7 default — do not escalate to `max` without cause.

# STP: Setup

Single skill, six subcommands, one shared opening. `$ARGUMENTS` picks the subcommand — default is `welcome` if none given.

**Before spawning any agent: read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`.** It covers `<use_parallel_tool_calls>`, context-limit, critic inversion, tool-trigger normalization, explicit scope.

## Shared opening (runs before every subcommand)

1. **Resolve profile + pace + stack** — parallel reads:
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
   PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
   STACK=$(jq -r '.stack // "generic"' .stp/state/stack.json 2>/dev/null || echo "generic")
   ```
2. **Pre-Work Confirmation Gate** — if the subcommand will write files or run destructive ops, announce the plan and call AskUserQuestion with options (first option marked `(Recommended)`). Read-only subcommands (`welcome` first-run banner, `progress`) skip the gate.

---

## Subcommand: `welcome` (default)

**Purpose:** First-run onboarding. Pick profile + pace, detect stack, optionally chain into `new` or `onboard`.

1. Print the v1.0 banner (cyan ╔═╗) — version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.
2. If `.stp/state/stack.json` missing: run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-stack.sh"` silently.
3. **AskUserQuestion — profile pick** (4 options, first is recommended):
   - `balanced` — DEFAULT. Opus plans, Sonnet executes. `(Recommended)`
   - `opus-cto` — Opus 4.7 1M main. Loose discipline. Max cost.
   - `sonnet-turbo` — Sonnet 4.6 @ xhigh. Fast + cheaper than Opus.
   - `other` — Show full table (`node ${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs all-tables`), ask again.
4. Write profile: `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <choice> --raw`
5. Run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/regenerate-agents.sh"` to update `agents/*.md`.
6. **AskUserQuestion — pace pick** (4 options):
   - `batched` — DEFAULT. Up to 4 questions per call. `(Recommended)`
   - `deep` — One question per decision, 200-300 word design sections (today's brainstorming feel).
   - `fast` — Single plan, single approval.
   - `autonomous` — Zero questions after initial spec.
7. Write pace: `jq -n --arg p "<choice>" '{pace: $p, set_at: now|todate, set_by: "stp:setup welcome"}' > .stp/state/pace.json`
8. **AskUserQuestion — next step:**
   - `new` — "I'm starting from scratch" → chain into `setup new` `(Recommended for fresh repos)`
   - `onboard` — "I have an existing codebase" → chain into `setup onboard`
   - `nothing` — "Just wanted to set up" → exit with summary box

Reference: `${CLAUDE_PLUGIN_ROOT}/references/pace-picker.md` explains pace semantics.

---

## Subcommand: `new`

**Purpose:** PRD-first project bootstrap from scratch.

1. Announce plan: "I'll ask questions about the product, draft PRD.md + PLAN.md, and scaffold based on your stack. No code yet."
2. Pre-Work Confirmation Gate — AskUserQuestion: `Proceed (Recommended) | Adjust scope | Cancel`.
3. **Stack-aware questions** — read `references/stacks/<STACK>.md` for stack-specific questions (framework, runtime, test library, entry points).
4. **Product questions** — pace-aware:
   - `deep`: one question at a time, 200-300 word sections per decision
   - `batched`: AskUserQuestion with up to 4 questions per call
   - `fast`: single plan presented for approval
   - `autonomous`: ask the minimum, default the rest
5. Write `.stp/docs/PRD.md` with RFC 2119 keywords (SHALL/MUST/SHOULD/MAY) + Given/When/Then scenarios.
6. Write `.stp/docs/PLAN.md` — architecture blueprint (9 phases if `batched`/`deep`, compressed if `fast`).
7. Auto-escalate to at least `batched` pace if PRD mentions auth, payments, models, or migrations (pace-picker rule).
8. Spawn `stp-critic` (model from profile) to verify PRD ↔ PLAN coverage. Non-negotiable — the Critic's job is recall, it reports every gap.
9. Commit: `feat: PRD + PLAN via /stp:setup new`.

---

## Subcommand: `onboard`

**Purpose:** Analyze an existing codebase, build architecture map.

1. Announce plan: "I'll map the repo, detect conventions, write ARCHITECTURE.md + CONTEXT.md. No code changes."
2. Pre-Work Confirmation Gate.
3. Run `detect-stack.sh` force-refresh (`rm -f .stp/state/stack.json && bash hooks/scripts/detect-stack.sh`).
4. Spawn `stp-explorer` (model from profile, omit if `inline`) with scope: "Map the top-level structure — entry points, routes, models, tests, CI config. Return file:line references per category."
5. Spawn `stp-researcher` in parallel if `STP_RESEARCHER_MANDATORY=true` with scope: "What's the current best-practice shape for a [STACK] project? What's the minimum viable AUDIT set?"
6. Consolidate findings into:
   - `.stp/docs/ARCHITECTURE.md` — file-system + dependency map
   - `.stp/docs/CONTEXT.md` — <150 lines concise reference
   - `.stp/docs/AUDIT.md` — known production health gaps (security, performance, tests, docs)
7. Commit: `docs: onboarding via /stp:setup onboard`.

---

## Subcommand: `model`

**Purpose:** Switch active STP model profile.

1. Announce current profile: `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current`.
2. Print table: `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" all-tables`.
3. **AskUserQuestion** — show 4 most common, + `other` for full list:
   - `balanced` `(Recommended — default)`
   - `opus-cto` — maximum power, 1M context, most expensive
   - `sonnet-turbo` — fast Sonnet-only workflow
   - `other` — show sonnet-cheap / opus-budget / pro-plan
4. Write profile: `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <choice> --raw`.
5. Regenerate agents: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/regenerate-agents.sh"`.
6. Print completion box showing old → new + notice: "New profile active on next `/stp:*` command."

---

## Subcommand: `pace`

**Purpose:** Switch curiosity dial.

1. Read current pace, print it.
2. Print `${CLAUDE_PLUGIN_ROOT}/references/pace-picker.md` "When to pick which" section.
3. **AskUserQuestion** — 4 options, current pace marked `(Current)`:
   - `batched` `(Recommended)` — up to 4 questions per AskUserQuestion call
   - `deep` — section-by-section validation
   - `fast` — one plan, one approval
   - `autonomous` — zero questions after spec
4. Write to `.stp/state/pace.json`:
   ```bash
   jq -n --arg p "<choice>" '{pace: $p, set_at: (now|todate), set_by: "stp:setup pace"}' > .stp/state/pace.json
   ```
5. Print completion box.

Auto-escalation reminder: `deep` always applies to `/stp:setup new` first run; auth/payments/schema work auto-escalates to at least `batched` regardless.

---

## Subcommand: `upgrade`

**Purpose:** Pull latest plugin, sync CLAUDE.md markers, regenerate agents, migrate state if pre-v1.

1. Announce plan: "I'll check for updates, pull if newer, regenerate agents, and verify hooks. No code changes."
2. Pre-Work Confirmation Gate.
3. Fetch latest plugin.json from marketplace, compare to local `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.
4. If upgrade available: `claude plugin upgrade stp@stp-marketplace` (ask user to confirm the exact command — plugin upgrades are outside our tool scope).
5. Run migration: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/migrate-v1.sh"` (idempotent, safe to re-run).
6. Regenerate agents: `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/regenerate-agents.sh"`.
7. Sync CLAUDE.md markers — read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-markers/` if exists, update `<!-- STP:stp-*:start -->` ... `<!-- STP:stp-*:end -->` sections in project CLAUDE.md.
8. Print completion box with version bump + **notice**: "Hooks load at session start — restart Claude Code (`/exit` then relaunch) to reload."

---

## Gotchas

- Every subcommand that writes files goes through the Pre-Work Confirmation Gate. No silent work.
- AskUserQuestion max is 4 options — pack the fifth into an `other` option that re-prompts with the full list.
- `welcome` is idempotent — running twice is fine, it re-asks all the pickers.
- `upgrade` + hook changes require `/exit` and Claude Code restart. `/clear` alone does NOT reload hooks.
- If pace is `autonomous`, skip confirmation gates inside pre-approved scopes (but still ask once at the start).

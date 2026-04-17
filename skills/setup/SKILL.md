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
6. Write `.stp/docs/PLAN.md` **outline only** — milestone list + feature waves + dependency order. NOT the full architecture blueprint — that's `/stp:think --plan`'s job (9 phases, Critic-verified). This stub gives `/stp:think --plan` somewhere to start.
7. Auto-escalate to at least `batched` pace if PRD mentions auth, payments, models, or migrations (pace-picker rule).
8. Spawn `stp-critic` (model from profile) to verify PRD covers the product scope the user described. Non-negotiable — the Critic's job is recall, it reports every gap. (PLAN is a stub at this point, not graded here.)
9. Commit: `feat: PRD + PLAN outline via /stp:setup new`.
10. **Print completion box** (cyan ╔═╗):
    ```
    ╔══════════════════════════════════════════════════════════════╗
    ║  ✓ NEW PROJECT BOOTSTRAPPED                                  ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Written + committed:                                        ║
    ║    .stp/docs/PRD.md       (requirements, RFC 2119, G/W/T)    ║
    ║    .stp/docs/PLAN.md      (milestone + wave outline)         ║
    ║    .stp/docs/CHANGELOG.md (versioned history)                ║
    ║    VERSION                (0.1.0)                            ║
    ║                                                              ║
    ║  ► Next: /clear, then /stp:think --plan                      ║
    ║         Fresh context reads PRD.md from disk, writes the     ║
    ║         formal 9-phase architecture, Critic-verified.        ║
    ║         Only after that does /stp:build have what it needs.  ║
    ╚══════════════════════════════════════════════════════════════╝
    ```
    **Do NOT skip the `/clear` step.** `/stp:think --plan` reads fresh from disk; a fat conversation context hurts its Opus 4.7 planning.

---

## Subcommand: `onboard`

**Purpose:** Analyze an existing codebase. Writes ARCHITECTURE.md + CONTEXT.md + AUDIT.md + reverse-engineered PRD.md + observation-report PLAN.md. Read-only — never edits source.

**Flags:**
- `--scope <path>` — restrict analysis to files under `<path>`. Subsequent `/stp:build` etc. still work project-wide; this just narrows the onboard pass.
- `--refresh` — incremental re-onboard. Uses git log delta since last onboard marker. Preserves existing OBS-XXX IDs for unchanged observations.
- `--scope <path> --refresh` — combined: delta within scope only.

---

### Flag parsing (step 0)

```bash
SCOPE=""
REFRESH=false
args="$ARGUMENTS"
while [ -n "$args" ]; do
  case "$args" in
    --scope=*)      SCOPE="${args#--scope=}";  args="" ;;
    --scope\ *)     SCOPE=$(echo "$args" | awk '{print $2}'); args="${args#--scope * }" ;;
    --refresh*)     REFRESH=true;              args="${args#--refresh}" ;;
    *)              args="${args# }" ;;
  esac
done
```

---

### Steps (common to fresh + --refresh, divergence noted)

1. **Announce plan** (pace-aware wording):
   - Fresh onboard: "I'll map the repo, detect conventions, reverse-engineer PRD + observation-report PLAN. Read-only. No code changes."
   - `--scope <path>`: "…scoped to `<path>`. Onboarding everything under that tree only."
   - `--refresh`: "…incremental re-onboard — only files changed since [last-onboarded-at]. Preserving OBS IDs."

2. **Pre-Work Confirmation Gate** — AskUserQuestion:
   `Proceed (Recommended) | Adjust scope | Cancel`

3. **Stack detect** — force-refresh the first time, use cached for `--refresh` within 24h:
   ```bash
   if [ "$REFRESH" = false ] || [ ! -f .stp/state/stack.json ]; then
     rm -f .stp/state/stack.json
     bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-stack.sh"
   fi
   ```

4. **Delta computation** (only if `--refresh`):
   ```bash
   CHANGED_FILES=$(bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/onboard-delta.sh" "$SCOPE")
   if [ "$CHANGED_FILES" = "NO_CHANGES" ]; then
     echo "No changes since last onboard. Nothing to refresh."
     exit 0
   fi
   ```
   For fresh onboard: `CHANGED_FILES=""` (Explorer reads everything in scope).

5. **Spawn `stp-explorer`** (model from profile, omit if `inline`). Scope depends on flags:

   **Fresh / no scope:** "Map the entire top-level structure — entry points, routes, models, tests, CI config. Build observations."

   **`--scope <path>`:** "Map the structure under `<path>` only. Entry points, routes, models, tests, CI config within this scope. Build observations."

   **`--refresh` with CHANGED_FILES:** "Re-analyze these specific files: [list]. Update observations for files that changed. Preserve OBS-XXX IDs for unchanged observations (read `.stp/docs/PLAN.md` first to know existing IDs, match by `(file, category, summary-hash)`)."

   Explorer MUST return structured output alongside the prose map:

   ```json
   {
     "observations": [
       {
         "id": "OBS-001",
         "file": "src/api/invoices.ts:47",
         "severity": "P0 | P1 | P2 | P3",
         "category": "bug | tech-debt | missing-feature | security",
         "summary": "…",
         "suggested_remediation": "…"
       }
     ],
     "inferences": [
       {
         "confidence": "HIGH | MEDIUM | LOW",
         "kind": "behavior | constraint | user-story | acceptance-criterion | data-model | api-surface",
         "text": "…",
         "source": "tests/auth.test.ts:42 | comment at src/api.ts:80 | shape of src/billing.ts:110"
       }
     ]
   }
   ```

   **Confidence rubric for inferences:**
   - Behavior has an explicit test asserting it → **HIGH** → emit as `SHALL` / `MUST`
   - Behavior is described in JSDoc / docstring / comment → **MEDIUM** → emit as `SHOULD`
   - Pure code-shape inference (type name, field name, function signature) → **LOW** → emit as `MAY`, lives under `## Low-Confidence Inferences` section

6. **Spawn `stp-researcher`** in parallel if `STP_RESEARCHER_MANDATORY=true`. Scope: "What's the current best-practice shape for a [STACK] project? What's the minimum viable AUDIT set for this stack?"

7. **Consolidate outputs** — write/update:
   - `.stp/docs/ARCHITECTURE.md` — file-system + dependency map. `--scope` entries get `(scoped: <path>)` tag. `--refresh` mode: diff-merge against existing file, don't rewrite whole.
   - `.stp/docs/CONTEXT.md` — <150 lines concise reference. On `--refresh`, update only affected sections.
   - `.stp/docs/AUDIT.md` — production health gaps. Append-only — prior AUDIT entries stay.
   - `.stp/docs/PRD.md` — reverse-engineered (template below). `--refresh` mode: insert/update Given/When/Then scenarios for changed behaviors, preserve unchanged.
   - `.stp/docs/PLAN.md` — observation report (template below). `--refresh` mode: preserve OBS-XXX IDs for unchanged, add new OBS-NNN for net-new findings.

8. **Write the reverse-engineered PRD** to `.stp/docs/PRD.md`:

   ```markdown
   # Product Requirements Document (reverse-engineered)

   > Source: `/stp:setup onboard` at [ISO timestamp]
   > This PRD was inferred from an existing codebase. Sections marked
   > LOW CONFIDENCE may not reflect original product intent — validate
   > before using this doc to drive `/stp:build`.

   ## Product Summary (inferred)
   [one paragraph]

   ## System Constraints (HIGH + MEDIUM confidence only)
   - [S-001] The system SHALL […] — source: `tests/auth.test.ts:42` (test asserts this)
   - [S-002] The system SHOULD […] — source: comment at `src/api.ts:80`

   ## User Stories (inferred from routes/UI)
   - As a [role], I can [action] via `[route/component:line]`

   ## Acceptance Criteria (Given/When/Then, from existing tests)
   ### AC-001 — [title]
   Given […] When […] Then […]  — source test: `path:line`

   ## Data Model (from schema/migrations)
   [ORM model summary with file:line]

   ## API Surface (from route files)
   [HTTP verb + path + handler location]

   ## Low-Confidence Inferences
   <!-- Everything below is shape-inference only. Validate before relying on any of it. -->
   - [S-003] The system MAY […] — inferred from shape of `src/billing.ts:110`, not validated
   - (expand as needed)

   ## Out of Scope
   - (inferred; verify these haven't been descoped accidentally)
   ```

9. **Write the observation report PLAN** to `.stp/docs/PLAN.md`:

   ```markdown
   # Observation Report (reverse-engineered)

   > Source: `/stp:setup onboard` at [ISO timestamp]
   > PLAN.md from onboard is an OBSERVATION REPORT — not a forward plan.
   > Run `/stp:think --plan` to write a formal forward plan from these
   > observations.

   ## OBS-001 — [short title]
   - Location: `src/api/invoices.ts:47`
   - Severity: P0
   - Category: bug
   - Observation: [what is]
   - Suggested remediation: [what could be]

   ## OBS-002 — […]
   …
   ```

   Ordering: P0 first, then P1, P2, P3. Numbering monotonic (OBS-001, OBS-002, …). On `--refresh`, preserve existing IDs for observations whose `(file, category, summary-hash)` is unchanged; mint new IDs for genuinely new findings.

10. **Validation prompt** — AskUserQuestion before committing:

    ```
    question: "I wrote PRD.md (reverse-engineered, [H] HIGH / [M] MEDIUM /
              [L] LOW-confidence inferences) and PLAN.md ([N] observations,
              [p0] P0 / [p1] P1). Review before committing?"
    options:
      - (Recommended) Accept as-is — commit and continue
      - Edit specific items — I'll open .stp/docs/PRD.md for you first
      - Discard and re-run onboard with different scope
      - Cancel
    ```

    On `Edit specific items`: open PRD.md in the user's editor, wait for them to save+close, then re-prompt (`Accept | Edit again | Cancel`). Same for PLAN.md if they choose to edit that next.

11. **Update trackers:**
    - `.stp/state/onboard-marker.json`:
      ```json
      {
        "version": 1,
        "last_full_onboard_at": "ISO",
        "last_refresh_at": "ISO"
      }
      ```
    - `.stp/state/onboarded-scopes.json` (only if `--scope` was used):
      ```json
      {
        "scopes": [
          {
            "path": "src/auth",
            "last_onboarded_at": "ISO",
            "observation_count": 12
          }
        ],
        "last_full_onboard_at": "ISO"
      }
      ```

12. **Commit:**
    - Fresh: `docs: onboarding via /stp:setup onboard (PRD + PLAN + ARCH + CONTEXT + AUDIT)`
    - `--scope`: `docs: scoped onboarding (scope=<path>) via /stp:setup onboard`
    - `--refresh`: `docs: refresh onboarding ([N] files changed since [LAST]) via /stp:setup onboard --refresh`

13. **Completion box:**
    ```
    ╔═══════════════════════════════════════════════════════════════╗
    ║  ✓ ONBOARDING COMPLETE                                        ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  Written + committed:                                         ║
    ║    .stp/docs/ARCHITECTURE.md  (codebase map)                  ║
    ║    .stp/docs/CONTEXT.md       (<150 line concise ref)         ║
    ║    .stp/docs/AUDIT.md         (production health)             ║
    ║    .stp/docs/PRD.md           (reverse-engineered)            ║
    ║    .stp/docs/PLAN.md          (observation report, [N] items) ║
    ║                                                               ║
    ║  ► Next options:                                              ║
    ║    /clear, then /stp:think --plan      (formal forward plan)  ║
    ║    /clear, then /stp:debug OBS-007     (fix specific finding) ║
    ║    /clear, then /stp:build --quick ... (spot fix, no plan)    ║
    ╚═══════════════════════════════════════════════════════════════╝
    ```

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

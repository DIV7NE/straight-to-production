# Changelog

All notable changes to STP are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-04-17 — workflow polish + code-graph + /stp:ship

### Summary

v1.1 closes the 9 workflow frictions surfaced in post-v1.0 review, adds an Aider-style code-graph (tree-sitter-based repo map, runtime-free and offline-capable), and ships a new 7th skill `/stp:ship` for the release + tag + optional-publish ritual. Total: 7 fix commits + 1 feature commit + 1 release skill + this changelog entry.

**Headline additions:**
- **Code-graph** (`.stp/state/code-graph.json`) — incrementally rebuilt on SessionStart. `stp-explorer` reads it FIRST before Glob/Grep for all structural questions. Expected 60–80% fewer tool calls on mature codebases. 10 languages bundled as WASM (~17 MB): TS / TSX / JS / Python / Rust / Go / Java / C# / C++ / C.
- **`/stp:ship`** — new skill. Preflight → VERSION bump → CHANGELOG finalize → commit → tag → push → `gh release create` → opt-in publish. No paid services (`gh` uses free tier). Publish steps are always AskUserQuestion, never automatic.
- **Onboard finally writes PRD.md + PLAN.md** — v1.0 silently skipped these despite README claiming otherwise. Now writes a reverse-engineered PRD with HIGH/MEDIUM/LOW confidence rubric + observation-report PLAN with OBS-NNN numbering + `--scope` + `--refresh` flags + validation AskUserQuestion.

**Runtime-free guarantee (hardened):** no paid APIs, no external services, no API keys, no cloud lookups at runtime. Code-graph grammars ship in `grammars/`, web-tree-sitter runtime ships in `vendor/`. Works fully offline after plugin install.

### Added

**Fix 2+3+4+5: `/stp:setup onboard` — full rewrite:**
- Writes reverse-engineered PRD.md with `## Low-Confidence Inferences` section
- Writes observation-report PLAN.md with OBS-NNN numbering (P0 first)
- Confidence rubric: HIGH = test-asserted → SHALL, MEDIUM = docstring/comment → SHOULD, LOW = pure code-shape → MAY
- New `--scope <path>` flag — restricts Explorer Glob to the subtree
- New `--refresh` flag — incremental re-onboard via `hooks/scripts/onboard-delta.sh` (git log delta since last marker)
- Scope tracker: `.stp/state/onboarded-scopes.json`
- Marker: `.stp/state/onboard-marker.json` with `last_full_onboard_at` + `last_refresh_at`
- Validation AskUserQuestion: Accept / Edit / Discard+rescope / Cancel
- Observation IDs preserved across `--refresh` runs (diff by `file+category+summary-hash`)

**Fix 10: Code-graph (`hooks/scripts/code-graph/`):**
- `build.js` — orchestrator. Walks source files, parses via tree-sitter, extracts imports/exports/symbols, computes degree-based centrality, writes JSON + `.meta` sidecar with SHA-1 per file for incremental rebuild
- `queries.js` — per-language tree-sitter query strings. TS/JS covers ES6 imports AND CommonJS `require()`. v0.20-ABI compatible
- `code-graph-update.sh` — SessionStart bash wrapper. Skips cleanly if stack.json missing or no source newer than graph
- Hard cap 500 KB JSON. Drops `symbols` for low-centrality files if over
- Bundled grammars at `grammars/*.wasm` (10 languages) + web-tree-sitter runtime at `vendor/web-tree-sitter/` (v0.20.8)
- Schema docs at `references/code-graph-schema.md`
- Grammar README with licenses at `grammars/README.md`

**Fix 11: `/stp:ship` skill (new 7th skill):**
- `skills/ship/SKILL.md` — preflight + version + CHANGELOG + commit + tag + push + release + publish + deploy
- 7 preflight gates: branch=main, zero uncommitted, in-sync with upstream, VERSION sane semver, CHANGELOG has `## [Unreleased]`, tests pass, `gh auth status` OK
- Overrides allowed but logged into the GitHub release body under `## ⚠ Overrides used`
- Stack-aware publish detection: `package.json` (if not private) / `Cargo.toml` / `pyproject.toml`
- Optional deploy hook: looks for `.stp/deploy.sh` or `scripts/deploy.sh`
- `--dry-run` mode for sanity-check before real ship

**`stp-explorer` agent template — Code-Graph First rule:**
- New MANDATORY section in `references/agents/explorer.md.template`
- Explorer reads `.stp/state/code-graph.json` before any Glob/Grep
- Documents the 4 cases when graph is insufficient: missing, symbol not indexed, truncated file, behavior-not-structure question

### Changed

**Fix 1: `/stp:setup new` completion box + PRD/PLAN split:**
- New step 10 prints cyan ╔═╗ box recommending `/clear, then /stp:think --plan`
- Step 6 rewritten — `setup new` now writes PLAN.md as a milestone outline only, not the full 9-phase architecture. The architecture is `/stp:think --plan`'s job. This fixes a silent double-write where both skills claimed ownership of PLAN.md
- Step 8 Critic now grades PRD scope coverage, not PLAN (which is a stub at this point)

**Fix 9: `/stp:build --full` — pace=autonomous documentation:**
- New explicit table in `skills/build/SKILL.md` showing gate behavior per pace
- `autonomous` gates STILL fire — they auto-decide with `(Recommended)` option, log every decision to `.stp/state/autopilot-log.md`
- Explicit contrast between `--full` + `autonomous` (single-feature delegated) and `--auto` (overnight queue with Agent Teams)
- Lists 4 conditions where autonomous halts anyway (critic critical on 2nd pass, stop hook block, QA UI bug, mid-build auto-escalation)

**Fix 6: `/stp:review` — pre-spawn digest + persist output:**
- New step 3 reads the most recent CHANGELOG entry, AUDIT.md's last Review Refresh + Critic Evaluation blocks, and the newest `.stp/state/critic-report-*.md`
- Digest inserted into Critic's spawn prompt under `## Prior Context (do NOT re-flag unchanged items)` block
- New step 4.5 persists every Critic run to `.stp/state/critic-report-<ISO>.md` — this is what the NEXT review's digest reads
- Fixed pre-existing bug: two steps were both numbered "3"

**Fix 7+8: `/stp:session` — summary + lazy-read:**
- `pause` new step 3.5: writes `.stp/state/session-summary.md` (strict ≤50-line template)
- Both `handoff.md` (deep) and `summary.md` (skim) coexist
- `continue` rewritten with tier-1 / tier-2 lazy read
- Tier-1 (always): summary.md + state.json + git status — ~50 lines
- Tier-2 (on demand): handoff.md + PLAN + CHANGELOG + ARCHITECTURE — only when summary missing, stale (>48h), or user requests deep context
- On mature projects, resume cost drops from 10–30 KB to ~2 KB

**SessionStart hook chain:**
- Appended `code-graph-update.sh` to the backgrounded chain
- Timeout raised 20→25s to accommodate first-run graph build on large projects
- Full chain: migrate-layout → migrate-v1 → detect-stack → session-restore → check-project-sync → check-upgrade → code-graph-update

**CLAUDE.md:**
- Header bumped to v1.1, skill count 6→7, added "code-graph-aware" adjective
- New `**Release:**` block in Skills section with `/stp:ship`
- Effort Levels added `/stp:ship → high`
- All STP marker blocks preserved so `/stp:setup upgrade` sync still works

### Constraints introduced (v1.1 System Constraints)

- **SHALL:** `stp-explorer` reads `.stp/state/code-graph.json` before any Glob/Grep when the graph exists.
- **SHALL:** `/stp:ship` preflight gates must all pass or be explicitly overridden by the user with the override logged into the release notes.
- **SHALL:** Every `/stp:review` Critic spawn receives a `## Prior Context` digest block when prior review artifacts exist on disk.
- **SHALL:** `/stp:session pause` writes both `handoff.md` (deep) and `session-summary.md` (skim). `continue` reads summary first, falls back to full context only when needed.
- **MUST NOT:** Depend on paid APIs or cloud services for code-graph or release features at runtime. All such deps must be bundled in the plugin repo or use the user's existing free-tier tooling (e.g. `gh` CLI).
- **MUST NOT:** Lazy-download tree-sitter grammars at runtime. The offline-capability contract is load-bearing.

### Dependencies created

- `hooks/scripts/code-graph-update.sh` depends on `hooks/scripts/code-graph/build.js` + `queries.js` + bundled grammars + vendored `web-tree-sitter`
- `stp-explorer` agent depends on the code-graph JSON schema in `references/code-graph-schema.md`
- `/stp:setup onboard --refresh` depends on `hooks/scripts/onboard-delta.sh` + the `.stp/state/onboard-marker.json` format
- `/stp:ship` depends on `gh` CLI being installed and authed (free tier)
- `/stp:ship` depends on `.stp/state/stack.json.test_cmd` for the test-pass preflight gate

### Breaking changes

None. v1.1 is strictly additive over v1.0 — no command renames, no profile renames, no hook behavior changes that affect existing projects.

First-time post-upgrade SessionStart will build the code-graph in the background (~1–5 seconds on typical projects). Subsequent sessions reuse cached graph unless source changed.

## [1.0.0] — 2026-04-17 — v1: universal, stack-aware, pace-aware

### Summary

STP v1.0 is a ground-up rework. The goal: make STP genuinely universal across any development domain (web, CRM, C++, C#, Rust, game cheats, embedded, mods, data/ML) instead of being a Next.js/React harness with token accommodations for other stacks. It ships three big shifts: **stack detection** that rewires every hook to match the project's toolchain, a **pace dial** that turns the AskUserQuestion-driven curiosity into a first-class setting (deep / batched / fast / autonomous), and **Opus 4.7 idiom adoption** everywhere agents are spawned. The 18 skill dirs collapse into 6 skills with subcommands. Two new profiles land: `sonnet-turbo` for cost-sensitive fast iteration, `pro-plan` for Pro-tier subscribers with message-rate limits.

Hard cutover — no command aliases, no profile aliases beyond the SessionStart migration. Pre-v1 users get auto-migrated once at session start by `hooks/scripts/migrate-v1.sh`.

### Added

**Skills (6, replacing 18 command dirs):**
- `/stp:setup` — lifecycle: `welcome | new | onboard | model | pace | upgrade`
- `/stp:think` — design mode: default brainstorming, `--plan`, `--research`, `--whiteboard`
- `/stp:build` — execution: default auto-route, `--full`, `--quick`, `--auto`
- `/stp:debug` — root cause + defense-in-depth (unchanged intent, Opus 4.7 idioms added)
- `/stp:review` — Critic with INVERSION framing
- `/stp:session` — lifecycle: `pause | continue | progress`

**Model profiles (2 new, 6 total):**
- `sonnet-turbo` — Sonnet 4.6 @ xhigh as main and sub-agents. ~25% the cost of opus-cto for most work. Chosen when the user is on a Pro plan or wants fast iteration without Opus latency.
- `pro-plan` — Sonnet 4.6 @ high, NO sub-agents, deterministic verification only. Hard caps: 30 messages/feature, 80 messages/5h. Built for Claude Pro subscribers hitting 20-message limits.

**Pace dial (`.stp/state/pace.json`):**
- `deep` — one question per decision, 200–300 word design sections, AskUserQuestion after each. Maximum curiosity — preserves the section-by-section brainstorming feel.
- `batched` (default) — up to 4 questions per AskUserQuestion call, phase-transition gates.
- `fast` — full plan in one message, single approval gate.
- `autonomous` — zero questions after initial spec confirmation.
- Auto-escalation: auth/payments/security auto-floors at `batched`. Novel architecture auto-escalates to `deep`. Deleting >50 lines or touching >5 files auto-floors at `batched`.

**Stack detection (`.stp/state/stack.json`, 14 stacks):**
- `hooks/scripts/detect-stack.sh` — runs on SessionStart (if stack.json missing or >24h stale)
- Stacks: web, node, python, go, rust, csharp, java, cpp, game, cheat-pentest, embedded, mod, data-ml, generic
- Each stack.json carries: `stack` name, `ui` boolean, `typecheck_cmd`, `test_cmd`, `build_cmd`, `entrypoints`
- Stack reference files: `references/stacks/*.md` (14 files) — toolchain, project layout, test/build conventions

**Opus 4.7 idioms (`references/opus-4.7-idioms.md`):**
- `<use_parallel_tool_calls>` XML block required in every sub-agent spawn prompt
- Context-limit prompt required ("don't stop early due to token budget") — counters Opus 4.7's more literal self-truncation
- Critic INVERSION framing required ("report every issue, downstream ranks severity")
- Tool-trigger normalization — uniform phrasing across skills so literal matching fires reliably
- Explicit scope boundaries — each rule carries applicability so Opus 4.7 doesn't over-apply

**Session management (`references/session-management.md`):**
- `/rewind` (Esc Esc) vs `/compact` vs `/clear` decision table
- Context % threshold nudges: 0-40% silent, 40-70% optional compaction, 70-90% pause now, 90%+ imminent autocompact
- 1M context guidance for `opus-cto` profile

**Statusline updates (`hooks/scripts/stp-statusline.js`):**
- `xhigh` (magenta) and `max` (bold magenta) effort level colors for Opus 4.7
- Profile tags: `opus-cto` (cyan), `sonnet-turbo` (green), `opus-budget` (orange), `sonnet-cheap` (magenta), `pro-plan` (red), `balanced` (silent default)
- Pace tags: `◆deep` (cyan), `▸fast` (yellow), `●auto` (blinking red), `batched` (silent default)
- Stack tag (dim, only shown when non-generic)
- Context-threshold nudges appended to context bar label — surfaces the session-management guidance to Claude on every tool call

**Migration (`hooks/scripts/migrate-v1.sh`):**
- Runs once at SessionStart after upgrade to v1.0
- Renames legacy profile names: `intended` → `opus-cto`, `balanced` → `balanced` (unchanged), `budget` → `opus-budget`, `sonnet-main` → `sonnet-cheap`, `20-pro-plan` → `pro-plan`
- Idempotent — safe to run on every session

**Agent regeneration (`hooks/scripts/regenerate-agents.sh`):**
- Templates at `references/agents/*.md.template` with `${STP_MODEL_<AGENT>}` placeholders
- Runs after every profile switch (`/stp:setup model`)
- Substitutes resolved models into `agents/*.md` from the active profile

### Changed

**Hooks are now stack-aware:**
- `ui-gate.sh` — exits early if `stack.ui == false` (C++ daemons, Rust libs, CLI tools no longer get blocked by frontend rules)
- `anti-slop-scan.sh` — same stack-aware skip; AI-slop patterns were tuned for frontend code
- `stop-verify.sh` — `run_type_check()` and `run_tests()` now prefer `stack.typecheck_cmd` / `stack.test_cmd` from stack.json. Falls back to language detection only if stack.json missing.

**SessionStart hook chain rewritten:**
```
rm -f .stp/state/ui-gate-passed 2>/dev/null;
bash migrate-layout.sh && bash migrate-v1.sh && bash detect-stack.sh &&
bash session-restore.sh && bash check-project-sync.sh && bash check-upgrade.sh &
```
Timeout raised 15→20 seconds to accommodate detect-stack.

**Profile resolver (`references/model-profiles.cjs`):**
- Added `sonnet-turbo` profile entry
- `pro-plan` renamed from `20-pro-plan` (resolver accepts both)
- `resolve-all` output unchanged (KEY=VALUE lines) — existing skills read it the same way

**CLAUDE.md:**
- New sections: `## Pace-Aware Execution`, `## Stack-Aware Execution`, `## Opus 4.7 Idioms (MANDATORY)`
- Updated Task Routing table to use `/stp:build --quick` / `/stp:build --full`
- Updated Skills section (6 skills with subcommand syntax, not 18 commands)
- Updated Effort Levels — xhigh is now the default for Opus 4.7; `max` reserved for genuinely novel architecture
- Updated Hooks index with stack-aware annotations
- All marker blocks (`<!-- STP:section:start -->` / `end`) preserved so upgrade hook can diff sections

**Skills reuse existing reference files:**
- Every skill's "shared opening" reads `.stp/state/pace.json`, `.stp/state/stack.json`, and resolves profile via the .cjs resolver — in parallel
- Every skill that spawns an agent reads `references/opus-4.7-idioms.md` first

**`references/profiles.md` full rewrite:**
- 6 profiles (was 4)
- New discipline matrix with `main_effort` column
- Legacy profile name aliases table for migration reference
- Command references updated to v1 syntax (`/stp:setup model`, `/stp:think --plan`, `/stp:build --quick`)

### Removed

**Skill directories (16 of 18 dropped — consolidated into the 6 new skills):**
- `welcome`, `new-project`, `onboard-existing`, `set-profile-model`, `upgrade` → `/stp:setup` subcommands
- `whiteboard`, `plan`, `research` → `/stp:think` modes
- `work-quick`, `work-full`, `work-adaptive`, `autopilot` → `/stp:build` flags
- `progress`, `continue`, `pause` → `/stp:session` subcommands
- `codebase-mapping` → absorbed into `/stp:setup onboard`

**Dead hook scripts:**
- `stp-statusline.sh` (bash fallback — Node.js statusline is universal)
- Old profile-switch helpers that pre-dated the .cjs resolver

**Dead reference dirs:**
- `references/phases/` (work-full internal step files — now inline in `/stp:build`)
- `references/steps/` (work-quick internal step files — now inline in `/stp:build`)

**Old profile names (hard cutover, migrated once):**
- `intended-profile` → `opus-cto`
- `budget-profile` → `opus-budget`
- `sonnet-main` → `sonnet-cheap`
- `20-pro-plan` → `pro-plan`

### Constraints introduced (v1.0 System Constraints)

- **SHALL:** Every STP skill reads `.stp/state/pace.json` and `.stp/state/stack.json` in its shared opening.
- **SHALL:** Every sub-agent spawn prompt includes the `<use_parallel_tool_calls>` XML block and the context-limit line from `references/opus-4.7-idioms.md`.
- **SHALL:** Every Critic invocation uses the INVERSION framing ("report every issue, downstream ranks severity").
- **SHALL:** Hooks check `.stp/state/stack.json` before enforcing UI-specific or frontend-tuned rules.
- **SHALL:** Every `Agent()` spawn carries an explicit `model=` parameter (never inherit Opus implicitly).
- **MUST NOT:** Ship new command aliases for v0 names. Hard cutover — legacy names are migrated once by `migrate-v1.sh`, then removed.

### Dependencies created

- All 6 skills depend on `references/model-profiles.cjs resolve-all` output
- All 6 skills depend on `.stp/state/pace.json` (written by `/stp:setup welcome` or `/stp:setup pace`)
- All hooks depend on `.stp/state/stack.json` (written by `detect-stack.sh` at SessionStart)
- `regenerate-agents.sh` depends on `references/agents/*.md.template` existing
- `migrate-v1.sh` depends on prior `.stp/state/profile.json` shape

### Breaking changes

- **All 18 v0 commands removed.** Must use v1 skills (`/stp:setup`, `/stp:think`, `/stp:build`, `/stp:debug`, `/stp:review`, `/stp:session`).
- **Profile names renamed.** Migrated automatically by `migrate-v1.sh` once at SessionStart after upgrade.
- **Default effort is `xhigh` (Opus 4.7), not `high` (Opus 4.6).** Effort levels per skill updated in CLAUDE.md.
- **Hook SessionStart chain timeout raised** — hook runner must support 20-second chains (all recent Claude Code versions do).

See `MIGRATION-v1.md` for the full pre-v1 → v1 migration path.

## [0.5.11] — 2026-04-12 — session nudges + complete marketplace migration

### Summary

STP now fully operates through Claude Code's plugin marketplace. SessionStart hook detects first-ever installs and plugin version mismatches, nudging users to run `/stp:welcome` or `/stp:setup upgrade` as needed. All install references updated from `npx stp-cc` to `/plugin install stp@stp`. Release pipeline no longer publishes to npm.

### Added
- `check-project-sync.sh`: SessionStart hook detects first install (no `.stp/` dir) → prints `★ Run /stp:welcome`
- `check-project-sync.sh`: detects plugin version > last-synced version → prints `⚠ Run /stp:setup upgrade`
- `/stp:setup upgrade` Step 8c: writes `.stp/state/last-synced-version` marker after sync
- `/stp:welcome` Phase 5: writes sync marker after setup

### Changed
- README.md: install/update/uninstall sections now use `/plugin` commands
- `skills/upgrade/SKILL.md`: npm installs detected and redirected to plugin system
- `hooks/scripts/check-upgrade.sh`: upgrade notification points to `/plugin install stp@stp`
- `scripts/release.sh`: stripped npm publish, added marketplace.json bump
- `.claude/commands/release.md`: stripped npm publish, updated completion report

## [0.5.10] — 2026-04-12 — deprecate npx stp-cc in favor of plugin system

### Summary

`npx stp-cc` now prints the correct install instructions instead of performing the broken file-copy install. The npm package is deprecated — STP installs through Claude Code's native plugin system.

### Changed
- `bin/cli.js`: replaced file-copy installer with deprecation notice + correct install commands
- Install flow: `/plugin marketplace add DIV7NE/straight-to-production` → `/plugin install stp@stp`

## [0.5.9] — 2026-04-12 — fix: proper plugin system registration via marketplace

### Summary

The npm installer and manual file edits cannot replicate the opaque internal state that only `/plugin install` creates. STP now ships as a proper self-hosted marketplace (same pattern as `mksglu/context-mode`). Added the missing `"skills": "./skills/"` field to `plugin.json` — required for the plugin system to discover skills. Renamed marketplace from `pilot-dev` to `stp` so the install flow is `/plugin marketplace add DIV7NE/straight-to-production` → `/plugin install stp@stp`.

### Fixed
- `plugin.json`: added `"skills": "./skills/"` — the field context-mode has that STP was missing
- `marketplace.json`: renamed from `pilot-dev` to `stp` for clean `stp@stp` install path

### Changed
- Install flow is now marketplace-based: `/plugin marketplace add` + `/plugin install stp@stp`
- npm installer (`npx stp-cc`) is supplementary — the plugin system is the canonical install path

## [0.5.8] — 2026-04-12 — fix: remove skill symlinks, rely on plugin system

### Summary

Reverts the symlink approach from v0.5.6-0.5.7. Symlinks in `~/.claude/skills/` registered skills as bare names (`/welcome`, `/upgrade`) instead of with the `stp:` prefix (`/stp:welcome`, `/stp:setup upgrade`), polluting the command picker. The actual fix was updating `installed_plugins.json` to point to the live source directory instead of a stale v0.2.0 cache — the plugin system handles the `stp:` prefix correctly.

### Fixed
- Removed symlink creation from `bin/install.js`, `bin/uninstall.js`, `welcome/SKILL.md`, `upgrade/SKILL.md`
- `bin/install.js`: COPY_ITEMS now includes `skills` + `agents` (was stale `commands` ref from pre-v0.5.5)

### Removed
- Skill symlink logic from installer, uninstaller, welcome, and upgrade commands

## [0.5.5] — 2026-04-12 — fix: slash commands now register in Claude Code

### Summary

Slash commands (`/stp:debug`, `/stp:build --full`, etc.) were invisible because Claude Code discovers skills from `skills/*/SKILL.md`, not `commands/*.md`. Restructured all 18 commands to the correct layout. Also fixed the Context Mode install instructions — the old MCP command didn't work; replaced with the correct marketplace plugin flow.

### Fixed
- `commands/*.md` → `skills/*/SKILL.md` — all 18 slash commands now register in the command picker
- Context Mode install command updated in 4 files: was `claude mcp add context-mode -- npx -y context-mode-mcp@latest`, now `/plugin marketplace add mksglu/context-mode` + `/plugin install context-mode@context-mode`

### Changed
- `README.md` — directory tree updated to reflect `skills/` structure
- `hooks/scripts/ui-gate.sh` — cosmetic path reference updated

## [0.5.4] — 2026-04-11 — fix: hide internal phase/step files from slash command picker

### Summary

`work-full` and `work-quick` phase/step files were showing up as user-facing slash commands (`/stp:build --full:phase5-plan` etc.) because Claude Code registers every `.md` file in `commands/` subdirectories. Moved to `references/` where they're implementation details, not commands.

### Fixed
- `commands/work-full/` → `references/work-full-phases/` — phases no longer appear in the command picker
- `commands/work-quick/` → `references/work-quick-steps/` — steps no longer appear in the command picker
- `work-full.md` + `work-quick.md`: updated all phase/step file paths to new locations

## [0.5.3] — 2026-04-11 — fix: 20-pro-plan now visible in /stp:welcome profile picker

### Summary

`AskUserQuestion` has a hard cap of 4 user-defined options — a 5th is silently dropped. The `budget` and `sonnet-main` options are merged into one slot with a follow-up question to disambiguate, freeing the 4th slot for `20-pro-plan`.

### Fixed
- Welcome Phase 3: `budget` and `sonnet-main` merged into one picker option; follow-up `AskUserQuestion` asks whether user has Opus access before setting the profile
- `20-pro-plan` now visible as option 4 in the welcome profile picker

## [0.5.2] — 2026-04-11 — 20-pro-plan in set-profile-model + lean planning step

### Summary

Two fixes from the 0.5.1 release: the `/stp:setup model` command was missing `20-pro-plan` from its comparison banner and picker, and `/stp:build --quick`'s planning step had no awareness of the Pro plan's message constraints.

### Fixed
- `set-profile-model`: added `20-pro-plan` to comparison banner (echo block), profile picker `AskUserQuestion`, and argument-hint

### Added
- `step3-plan`: profile-aware planning — on `20-pro-plan`, outputs a lean 15-line plan (what/files/approach/risks/tests) with a hard `AskUserQuestion` approval gate before building; all other profiles use the existing 30-line 9-layer checklist

## [0.5.1] — 2026-04-11 — add 20-pro-plan profile for $20/mo Claude Pro subscribers

### Summary

New profile targeting the $20/month Claude Pro plan, where the hard constraint is message count (~45-100 msgs per 5-hour window shared across all Claude surfaces), not token cost. Every sub-agent spawn costs 5-20+ messages — so this profile eliminates sub-agents entirely and enforces strict per-feature message budgets.

### Added
- `20-pro-plan` profile in `references/model-profiles.cjs`: all 6 agents set to `inline` (zero sub-agents), new discipline fields: `no_subagents`, `max_messages_per_feature: 30`, `max_messages_per_5h: 80`, `allowed_commands`, `blocked_commands`, `verification: deterministic-only`, 60K main session cap
- `references/profiles.md`: full profile documentation — message budgets, allowed/blocked commands, verification strategy, message-stretching tips, who it's for
- `CLAUDE.md` profile index: `20-pro-plan` row added
- `commands/welcome.md`: Pro-plan-specific tour in Phase 4, constrained next-steps in Phase 5 (blocked commands not suggested)

### Changed
- `resolve-all` CLI output now emits `STP_NO_SUBAGENTS`, `STP_MAX_MSGS_PER_FEATURE`, `STP_MAX_MSGS_PER_5H`, `STP_VERIFICATION`, `STP_ALLOWED_COMMANDS`, `STP_BLOCKED_COMMANDS` when profile is `20-pro-plan`
- `formatTable` CLI output shows sub-agent, message budget, and command allow/block fields for `20-pro-plan`

## [0.4.5] — 2026-04-10 — remove GSD references from upgrade command

### Summary

The `/stp:setup upgrade` command was incorrectly picking up GSD local patches from the user's global CLAUDE.md and surfacing them as STP upgrade actions. Removed the naive "Local Patches" grep — npm installs now handle patch backup automatically via the SHA manifest.

### Fixed
- Upgrade Step 7: no longer greps global CLAUDE.md for "Local Patches" (was showing GSD paths)
- npm installs handle local patches via installer manifest — no manual reapply needed

## [0.4.4] — 2026-04-10 — statusline reliability + upgrade notifications

### Summary

Users now get a visible stderr notification at session start when an STP update is available — no statusline dependency. The statusline script itself is hardened with fallback output on timeout/error. Welcome command now auto-registers the statusline in settings.json during first-time setup.

### Fixed
- Statusline script: timeout and stdin error now output "STP" fallback instead of silent exit
- Upgrade check: prints `⬆ STP update available: vX → vY. Run /stp:setup upgrade` to stderr (always visible)

### Added
- Welcome Phase 1: auto-checks and registers statusline in `~/.claude/settings.json` if missing

## [0.4.3] — 2026-04-10 — welcome command polish + deduplicated plugin checks

### Summary

Welcome command now shows whiteboard as the daily starting point (not new-project/plan). All output displays as text instead of bash echo to prevent Claude Code from collapsing it. Plugin/MCP checks removed from new-project, onboard-existing, and upgrade — welcome is now the single source of truth for setup.

### Changed
- Welcome tour: whiteboard is the daily entry point, work commands are the shortcut
- Welcome output: all boxes/tours rendered as text, not bash echo (prevents collapse)
- README: whiteboard-first flow, one-time setup separated from recurring workflow
- new-project: stripped MCP/plugin pre-flight (welcome handles it, -30 lines)
- onboard-existing: stripped companion plugin detection (-20 lines)
- upgrade: slimmed companion check to status-only, no installs/prompts

### Fixed
- Tavily repo URL (tavily.com → github.com/tavily-ai/tavily-mcp)
- Context Mode repo URL (context-labs → mksglu/context-mode)

## [0.4.2] — 2026-04-10 — public release prep: hygiene, agent-browser removal, README accuracy

### Summary

Pre-public release cleanup. Removed Vercel Agent Browser dependency (10 files), added LICENSE + SECURITY.md, expanded .gitignore, scrubbed personal email from git history, renamed repo to `straight-to-production`, and brought README fully in sync with the codebase (badges, architecture tree, hook gates table, command lists, profile docs).

### Changed
- README: badges updated (commands 16→18, hook gates 10→19, references 26→33, templates 20→18)
- README: architecture tree now shows bin/, welcome.md, work-full/work-quick subdirs, all 16 hook scripts
- README: hook gates table expanded from 10 rows to 19 with event types and enforcement levels
- README: full flow list includes work-adaptive, set-profile-model shows all 4 profiles
- README: logo uses absolute GitHub raw URL (renders on npm)
- All repo URLs updated from DIV7NE/stp to DIV7NE/straight-to-production

### Removed
- Vercel Agent Browser dependency from 10 files (QA agent, review, new-project, upgrade, onboard-existing, hooks, references, CLAUDE.md)

### Added
- MIT LICENSE file
- SECURITY.md with vulnerability reporting policy
- .gitignore: .env, .DS_Store, *.log, __pycache__, settings.local.json

## [0.4.1] — 2026-04-10 — onboarding: /stp:welcome + enhanced installer

### Summary

New `/stp:welcome` command walks first-time users through system checks, live MCP server verification, profile selection, and a quick tour. The npm installer (`npx stp-cc`) now shows environment checks, MCP install commands, and points users to `/stp:welcome` for full guided setup.

### Added
- `/stp:welcome` command — 5-phase onboarding: system check, live MCP audit, profile selection, workflow tour, smart next-step detection
- Installer environment check — verifies Node.js and Python 3 after install
- Installer MCP server checklist — copy-paste install commands for Context7, Tavily, Context Mode

### Changed
- Installer "first-time" output — replaced basic box with environment check + MCP commands + get started guide

## [0.4.0] — 2026-04-10 — npm distribution, token optimization, sonnet-main profile

### Summary

STP is now installable via `npx stp-cc`. Users can install, update, and uninstall with one command. Token usage cut ~50% through CLAUDE.md compression (34.7KB → 19.1KB), work-full/work-quick monolith splits, and a new balanced-profile default. New sonnet-main profile runs without Opus for ~85% cost reduction.

### Added
- npm distribution: `npx stp-cc` to install, `npx stp-cc@latest` to update, `npx stp-cc --uninstall` to remove
- SHA-256 install manifest for tracking files + local patch backup on upgrade
- Statusline upgrade indicator (magenta pulse when update available on npm/git)
- sonnet-main profile (Sonnet 200K primary, no Opus needed)
- Subagent cost discipline: `model="sonnet"` enforced on all Agent() calls
- Profile migration step in `/stp:setup upgrade` for pre-v0.4.0 projects
- `scripts/release.sh` for one-command releases
- Gate audit reference (`references/gate-audit.md`)
- Extracted shared references (`references/shared/`)

### Changed
- Default profile: intended → balanced (~50% Opus token savings)
- CLAUDE.md: 34.7KB → 19.1KB (compressed index + on-demand references)
- work-full.md: 966 → 90 lines (6 phase files loaded on demand)
- work-quick.md: 909 → 65 lines (4 step files loaded on demand)
- critic.md: 392 → 128 lines (all 7 criteria preserved)
- cli-output-format.md: 380 → 79 lines
- set-profile-model: full quality/cost/tradeoff comparison guide
- check-upgrade.sh: auto-detects npm vs git install for version checks
- `/stp:setup upgrade`: auto-detects npm/git/marketplace install type

### Fixed
- 4 missing STP section markers in CLAUDE.md (upgrade-compat)
- 5 cross-reference issues from post-implementation audit

## [0.3.9] — 2026-04-09 — perf: parallel subagent waves + CLAUDE.md compression (cost + token savings)

### Summary

Two cost-cutting changes informed by external research. Wave-based parallel builds in `/stp:build --full` and `/stp:build --quick` now spawn one-shot subagents via parallel `Agent()` tool calls instead of `TeamCreate` + `SendMessage` Agent Teams. Research (alexop.dev, laozhang.ai citing Anthropic docs) puts the cost delta at ~3–4× — Agent Teams cost ~5–7× a single session because each teammate holds its own full context window plus coordination overhead, while one-shot subagents cost ~1.5–2×. STP's wave members are intentionally independent (no shared files, no mid-build negotiation), so the Teams pattern was unjustified overhead.

CLAUDE.md compressed from 44.6k to 34.7k chars to clear Claude Code's "Large CLAUDE.md will impact performance (40k threshold)" warning. Strategy preserves all `MANDATORY`/`ENFORCED`/`CRITICAL`/`EXTREMELY-IMPORTANT` signal words (per Anthropic memory docs research — GitHub issue #32543 confirms stripping these degrades adherence after context compaction). Verbose sections compressed to pipe-delimited indexes (Vercel AGENTS.md pattern: 40KB → 8KB → 100% pass rate vs 53% baseline).

### Added

- **`## Agent Teams vs Subagents` section in CLAUDE.md** — codifies the cost research with a decision matrix mapping every STP flow (`/stp:build --full`, `/stp:build --quick`, `/stp:think --research`, `/stp:debug`, `/stp:build --auto`) to the right execution mode. Default rule: subagents for everything except `/stp:build --auto` (where shared task queue + overnight self-assignment justifies the Teams cost).

### Changed

- **`commands/work-full.md` section 6c** — replaced `TeamCreate(name="wave-1-build", ...)` + `team_name="wave-1-build"` + `SendMessage(type="shutdown_request")` + `TeamDelete(name="wave-1-build")` with parallel `Agent()` tool calls in a single message. Subagents return their structured report and terminate automatically.
- **`commands/work-quick.md` step 3-4** — same wave spawn pattern rewrite. No team lifecycle. Wave members spawn in parallel, each runs in worktree isolation, results merge after all complete.
- **`CLAUDE.md` Hooks section** — 19 gates compressed from per-gate prose paragraphs to a pipe-delimited index (`name|event|action|bypass`). Reload warning + 3-retry safety valve preserved verbatim.
- **`CLAUDE.md` Whiteboard rules** — server-MANDATORY paragraph and FILENAME CONTRACT compressed. Kept the rule + canonical name + forbidden alias list. Dropped the v0.3.0/0.3.1/0.3.3 historical post-mortem narrative (it lives in CHANGELOG.md already).
- **`CLAUDE.md` Profile-Aware `inherit` sentinel block** — verbose KNOWN LIMITATION block replaced with a one-line pointer to `${CLAUDE_PLUGIN_ROOT}/references/profiles.md` where the migration steps already live.
- **`CLAUDE.md` Directory Map / Memory Strategy / Structured Spec Format / Spec Delta System** — full detail offloaded to a subdirectory `CLAUDE.md` (lazy-loads when Claude touches `.stp/` files, which is exactly when those sections are needed). A tight 8-line quick-reference pointer remains in the main file for when Claude isn't yet in `.stp/`.
- **CLAUDE.md line 55 + Key Rules** — stp-executor description and Key Rules now correctly say "parallel one-shot subagents via Task tool" instead of "Agent Teams". Removes the contradiction with the new cost guidance.

### Fixed

- **Marker contract preserved** — kept `<!-- STP:stp-dirmap:start/end -->` markers around the new compressed Directory Map pointer so `/stp:setup upgrade`'s section-injection logic continues to work for users on prior versions.

### Token math

For a typical 50-turn session with Claude Code's automatic prompt caching:
- Before: ~11.1k tokens × (1 write + 49 cached reads) = ~66k tokens consumed by CLAUDE.md per session
- After: ~8.7k tokens × (1 write + 49 cached reads) = ~52k tokens consumed by CLAUDE.md per session
- Savings: **~14k cached / ~120k uncached tokens per session**, plus Agent Teams cost savings on every wave-based build

## [0.3.8] — 2026-04-09 — feat: optimization profiles (intended/balanced/budget) — GSD-style model selection

### Summary

STP now supports three optimization profiles that control which Claude model runs each sub-agent. Pick `intended-profile` (Opus 1M main session + Sonnet sub-agents — byte-identical to pre-0.3.8 behavior), `balanced-profile` (Opus plans + Sonnet executes/verifies + mandatory researcher/explorer sub-agents), or `budget-profile` (Sonnet writes + Haiku critic with Sonnet escalation, strict context discipline). The default stays on `intended-profile` for zero behavior change on upgraded projects. Switch with `/stp:setup model intended|balanced|budget`.

The architecture is inspired by [GSD's `/gsd:set-profile`](https://github.com/gsd-build/get-shit-done) which is the most reliable model-profile system in the Claude Code ecosystem. Single source of truth lives in `references/model-profiles.cjs` — a Node.js file with the canonical agent × profile → model mapping table, plus a CLI that STP commands and hooks call to resolve models at spawn time. Adding a new profile is one column in that file; no other changes needed anywhere in STP.

**Two key insights from GSD**, both adopted:
1. **`inherit` sentinel** — when a profile says an agent should use the parent session's model (e.g. "use opus when running on opus, sonnet on sonnet"), the resolver returns the literal string `"inherit"`. STP commands interpret this as: omit the `model=` parameter from the `Agent()` spawn call entirely, which causes Claude Code to inherit the parent session's model. Avoids hard-coding model IDs that may not be available, and works on any runtime (Opus 1M, Sonnet 200K, Codex, OpenCode, Gemini CLI).
2. **Tiny command file delegates to a CLI** — `commands/set-profile-model.md` is ~80 lines instead of ~250. All the heavy lifting lives in `references/model-profiles.cjs`. Same pattern as GSD's `commands/gsd/set-profile.md` which is just `!`-prefix bash calling `gsd-tools.cjs`.

### Research Foundation

Re-read four sources to validate the approach for Sonnet 200K and Haiku verification:
- **[Anthropic harness research](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — context resets via fresh sub-agents > compaction; decompose into tractable chunks with filesystem handoffs. STP's three-agent pattern (planner/executor/critic) already matches.
- **[Vercel AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)** — persistent context (CLAUDE.md) beats on-demand skills 100% vs 79%. Profile selection MUST live in CLAUDE.md as a compressed index, NOT a skill the agent might forget to invoke.
- **[Phil Schmid: Agent Harness 2026](https://www.philschmid.de/agent-harness-2026)** — three context engineering strategies: compaction, offload-to-storage, sub-agent isolation. Budget profile leans hard into all three.
- **[Meta-Harness (arXiv 2603.28052)](https://arxiv.org/abs/2603.28052)** — auto-discovered harnesses use 4x fewer context tokens with no quality loss on TerminalBench-2. Confirms the headroom exists.

**Verdict on Sonnet 4.6 (200K) viability:** ✅ works for both `balanced-profile` and `budget-profile` — but only with rigorous context discipline. Specifically: (1) every operation producing >50 lines goes to a sub-agent or `ctx_execute_file`, (2) sub-agent prompts ≤2K tokens with reports ≤30 lines, (3) `/clear` is mandatory (not "recommended") between phases, (4) state lives 100% on disk, (5) research/exploration is always delegated to fresh sub-agents.

**Verdict on Haiku 4.5 for verification:** ✅ works for STRUCTURAL/PATTERN scans (file:line evidence, hardcoded secrets, schema drift, accessibility violations). NOT good enough for behavioral verification with execution path tracing. **Solution:** Critic split — Haiku for first pass, automatic Sonnet escalation when ≥2 critical issues found. Compensate with stricter Layers 1-4 (executable specs, deterministic analysis, mutation challenge, property-based tests).

### What Got Built

**New canonical resolver** (single source of truth, GSD-style):
- `references/model-profiles.cjs` — JS file with `MODEL_PROFILES` table mapping each STP sub-agent (`stp-executor`, `stp-qa`, `stp-critic`, `stp-critic-escalation`, `stp-researcher`, `stp-explorer`) to its model under each profile. Includes CLI commands: `set`, `current`, `resolve <agent>`, `resolve-all`, `discipline`, `table`, `all-tables`, `list`, `help`. Ships with normalized profile names, malformed JSON backup, error handling.

**New command:**
- `commands/set-profile-model.md` — tiny (80 lines), supports three UX modes:
  1. Argument shortcut: `/stp:setup model balanced` — skips picker, just calls cjs CLI
  2. Interactive picker: `/stp:setup model` (no args) — calls AskUserQuestion with the 3 profile options
  3. Optional walkthrough — after setting, asks if user wants explanation of the new context discipline rules

**New sub-agents** (mandatory in balanced/budget profiles, inline in intended):
- `agents/researcher.md` — `stp-researcher`. Lives in fresh context per call. Runs Context7/Tavily/WebSearch in isolation. Returns ≤30 line structured summary so the main session never holds raw research dumps. ~100x context reduction.
- `agents/explorer.md` — `stp-explorer`. Lives in fresh context per call. Runs Glob/Grep/Read in isolation. Returns ≤30 line file:line map. ~45x context reduction.

**New hook:**
- `hooks/scripts/context-budget-warn.sh` — fires on Stop event for balanced/budget profiles. Reads the active profile via the cjs resolver, checks `discipline.max_main_session_kb`, and warns when the main session approaches 60% (soft warn) or 80% (strong warn — recommend immediate `/clear`). Silent on intended-profile (no cap). Feedback-only, never blocks.

**Refactored command files** to use the resolver instead of hardcoded `model="sonnet"`:
- `commands/work-full.md` — added Profile Resolution preamble (calls `resolve-all`); replaced 3 hardcoded model spawns with the inherit/sonnet conditional pattern
- `commands/work-quick.md` — same pattern (preamble + 2 spawn refactors)
- `commands/plan.md` — added profile-aware critic spawn (inherit/sonnet/haiku branching)
- `commands/review.md` — same
- `commands/onboard-existing.md` — same (note: no escalation in onboarding since it's read-only)

**Updated infrastructure:**
- `CLAUDE.md` — new `## Profile-Aware Execution` section with compressed index (Vercel AGENTS.md style), sentinel value docs, sub-agent spawn patterns, discipline rules, critic split logic, "adding a new profile" instructions
- `hooks/scripts/session-restore.sh` — reads active profile via cjs resolver; surfaces non-default profiles in the SessionStart banner
- `hooks/scripts/stp-statusline.js` — displays active profile tag (`balanced` in yellow, `budget` in orange) when not on default
- `hooks/hooks.json` — registers context-budget-warn.sh as a Stop hook (alongside stop-verify.sh)
- `references/profiles.md` — full profile documentation, trade-off tables, example workflows, citations to all 4 research sources

### Profile Mapping (the canonical table)

| Sub-agent | intended-profile | balanced-profile | budget-profile |
|---|---|---|---|
| `stp-executor` | `sonnet` | `sonnet` | `sonnet` |
| `stp-qa` | `sonnet` | `sonnet` | `sonnet` |
| `stp-critic` | `sonnet` | `sonnet` | `haiku` (→ sonnet escalation on ≥2 issues) |
| `stp-critic-escalation` | `sonnet` | `sonnet` | `sonnet` |
| `stp-researcher` | `inline` | `sonnet` | `sonnet` |
| `stp-explorer` | `inline` | `sonnet` | `sonnet` |

**Why `intended-profile` does NOT use `inherit`:** STP's original architecture deliberately uses Sonnet sub-agents (executor/qa/critic) even when the main session is Opus, for cost reasons. The user explicitly said intended-profile is "as is — we do nothing" — so the resolved values must match the pre-0.3.8 hardcoded `model="sonnet"` behavior. The `inherit` sentinel is supported in code but reserved for future profiles or non-Anthropic runtimes (Codex, OpenCode, Gemini CLI) where matching the parent session model is the desired behavior.

| Discipline | intended | balanced | budget |
|---|---|---|---|
| `/clear` between phases | recommended | mandatory | enforced (60% warn, 80% strong warn) |
| Context Mode MCP | recommended | mandatory (>50 lines) | hard-block (>50 lines) |
| Researcher mandatory | false | true | true |
| Explorer mandatory | false | true | true |
| Max main session | unlimited | ~120 KB | ~100 KB |
| Cost vs intended | 100% | ~35-50% | ~20% |

### Key Design Decisions

1. **Default to `intended-profile`** — zero behavior change for existing users on upgrade. Profile becomes opt-in via `/stp:setup model`.
2. **`inherit` sentinel for opus-tier agents** — instead of hard-coding `model="opus"`, we return `"inherit"` and command code OMITS the `model=` parameter from the spawn call. This is the GSD insight that makes profiles work cleanly across all runtimes.
3. **`inline` sentinel for intended-profile researcher/explorer** — Opus 1M can absorb research/exploration directly in the main session, no sub-agent needed. The `inline` value tells commands to skip the spawn entirely.
4. **Critic split with automatic escalation** — budget-profile spawns Haiku first; commands check the report and auto-respawn with Sonnet on ≥2 critical findings. Average critic cost stays low while preserving the deep-reasoning safety net.
5. **Single source of truth in JS** — adding a new profile is one column in `MODEL_PROFILES`. No other code changes needed in STP because everything reads from the resolver.
6. **CLI-driven, not bash-parsed** — STP commands call `node references/model-profiles.cjs <verb>` instead of parsing `.stp/state/profile.json` with awk/jq/python. One interface, no drift.

### Spec Delta

- **Added:**
  - New command: `/stp:setup model` (entry point, picker + arg + walkthrough modes)
  - New canonical resolver: `references/model-profiles.cjs` (data + CLI)
  - New sub-agents: `stp-researcher`, `stp-explorer` (context isolation)
  - New hook: `context-budget-warn.sh` (warns at 60%/80% capacity for non-intended profiles)
  - New state file: `.stp/state/profile.json` (minimal: `{profile, version, set_at, set_by}`)
  - New CLAUDE.md section: `## Profile-Aware Execution` (compressed index + sentinel docs)
  - New reference doc: `references/profiles.md` (full profile documentation)

- **Changed:**
  - `commands/work-full.md`, `commands/work-quick.md`, `commands/plan.md`, `commands/review.md`, `commands/onboard-existing.md` now read sub-agent models from the resolver instead of hardcoding `model="sonnet"`
  - `hooks/scripts/session-restore.sh` now surfaces active profile in SessionStart banner
  - `hooks/scripts/stp-statusline.js` now displays profile tag (yellow `balanced`, orange `budget`) when non-default
  - `hooks/hooks.json` adds context-budget-warn.sh to Stop event (alongside stop-verify.sh)

- **Constraints introduced:**
  - Every `/stp:*` command MUST resolve sub-agent models from the active profile via `node references/model-profiles.cjs resolve-all` or `resolve <agent>` before spawning. Hardcoding `model="sonnet"` is forbidden.
  - When the resolver returns `"inherit"`, commands MUST omit the `model=` parameter from `Agent()` spawn calls.
  - When the resolver returns `"inline"`, commands MUST NOT spawn a sub-agent at all — the main session handles the work directly.
  - In balanced/budget profiles, all external research (Context7/Tavily/WebSearch/WebFetch) MUST be delegated to a fresh `stp-researcher` sub-agent. The main session may not call these tools directly when `STP_RESEARCHER_MANDATORY=true`.
  - In balanced/budget profiles, all multi-file Glob/Grep operations (>5 files) MUST be delegated to a fresh `stp-explorer` sub-agent when `STP_EXPLORER_MANDATORY=true`.

- **Dependencies created:**
  - All STP commands depend on `references/model-profiles.cjs` being present and `node` being on PATH. Falls back to defaults (intended-profile) if either is missing.
  - `hooks/scripts/session-restore.sh` and `hooks/scripts/context-budget-warn.sh` depend on the cjs resolver. Both fail silently (exit 0) if it's missing.
  - `hooks/scripts/stp-statusline.js` reads `.stp/state/profile.json` directly (no dependency on the cjs file at runtime — both write/read the same JSON shape).

### Files Touched

**Created (6):**
- `commands/set-profile-model.md` — tiny GSD-style command, delegates to cjs CLI
- `references/model-profiles.cjs` — single source of truth (MODEL_PROFILES table + CLI)
- `references/profiles.md` — full profile documentation + trade-off tables
- `agents/researcher.md` — context-isolation sub-agent for external research
- `agents/explorer.md` — context-isolation sub-agent for codebase exploration
- `hooks/scripts/context-budget-warn.sh` — Stop hook warning at 60%/80% main session capacity (uses transcript_path strategy)

**Modified (13):**
- `.claude-plugin/plugin.json` — version bump 0.3.7 → 0.3.8
- `CHANGELOG.md` — this entry
- `CLAUDE.md` — new Profile-Aware Execution section + commands listing + effort levels + inherit sentinel limitation note + rewritten Architecture section (each sub-agent documented with its per-profile model + Haiku escalation)
- `README.md` — directory tree updated (16→17 commands, 3→5 sub-agents) + flat command listing includes new command
- `commands/upgrade.md` — added stp-profile-aware to STP-OWNED sections sync table (so /stp:setup upgrade syncs the new section)
- `commands/work-full.md` — Profile Resolution preamble + 3 spawn refactors + critic escalation logic (using v0.3.7-fixed grep -c pattern) + Phase 2 explorer routing + Phase 4 researcher routing
- `commands/work-quick.md` — Profile Resolution preamble + 2 spawn refactors + researcher routing in research step
- `commands/plan.md` — profile-aware critic spawn
- `commands/review.md` — profile-aware critic spawn
- `commands/onboard-existing.md` — profile-aware critic spawn (no escalation in onboarding — observation mode)
- `hooks/hooks.json` — register context-budget-warn.sh on Stop event (alongside stop-verify.sh)
- `hooks/scripts/session-restore.sh` — surface active profile in SessionStart banner via cjs resolver
- `hooks/scripts/stp-statusline.js` — profile tag display (yellow `balanced`, orange `budget`)

### Testing

Smoke-tested the cjs CLI end-to-end with 9 scenarios:
1. `set balanced` → writes `.stp/state/profile.json`, returns `balanced-profile`
2. `current` → reads back `balanced-profile`
3. `resolve stp-executor` → returns `sonnet`
4. Switch to `budget`, `resolve stp-critic` → returns `haiku`
5. `resolve-all` → prints all 12 KEY=VALUE lines including discipline rules
6. `table intended` → renders ASCII table with `inherit`/`inline` correctly
7. `set intended --raw` → prints cyan banner + table + save confirmation
8. `set foo` → errors with valid profile list
9. Confirms `.stp/state/profile.json` contents are valid minimal JSON

All 9 pass. Errors are handled. Sentinels (`inherit`, `inline`) resolve correctly per profile.

### Known Limitations

- **You can't change the running session's model** — profile takes effect on the NEXT command, not the current one. This is a Claude Code limitation, not fixable at the plugin level.
- **Hooks load at session startup** — after upgrading from 0.3.7 to 0.3.8, you must exit Claude Code and restart it to pick up the new context-budget-warn hook. `/clear` alone does NOT reload hooks.
- **Sentinel-based spawns require command discipline** — commands must check the resolved value and conditionally include/omit the `model=` parameter. The cjs resolver tells you what to do, but the command file is responsible for actually doing it. The CLAUDE.md `## Profile-Aware Execution` section documents the pattern.
- **Critic escalation is opt-in per command** — `/stp:build --full` includes the bash escalation logic; other commands (`/stp:review`, `/stp:think --plan`) don't auto-escalate. This is intentional — escalation only matters for builds, not for read-only reviews.

### Migration Notes

**For users staying on intended-profile (default):** No action required. Everything works exactly as before. Optional: run `/stp:setup model intended` to confirm the default.

**For users switching to balanced or budget:**
1. Run `/stp:setup model balanced` (or `budget`)
2. Confirm via the picker or `--raw` flag
3. Exit Claude Code and restart with the appropriate model (Opus for planning commands, Sonnet for execution commands)
4. Read the optional walkthrough after switching for the discipline rules

**If you see unexpected behavior:** Run `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current` to confirm the active profile, then `... table` to see the model assignments. Check `.stp/state/profile.json` for the raw state.

---

## [0.3.7] — 2026-04-09 — fix: stop-verify hook integer-comparison crash + 4 false-positive gates

### Summary
The Stop hook (`hooks/scripts/stop-verify.sh`) was crashing with `[: 0\n0: integer expression expected` and false-flagging legitimate code in five different ways, locking users into Stop loops. Five real bugs in one script — all fixed in a single pass with a centralized `clean_count` helper, narrower regexes, and a smarter schema-drift gate.

### Root Causes

**1. The `grep -c … || echo "0"` idiom is broken (Gates 1, 6, 10).** `grep -c PATTERN FILE` always prints `"0\n"` when there are zero matches AND exits with status 1. The naive fallback `COUNT=$(grep -c … || echo "0")` fires the `|| echo "0"` AFTER grep has already printed its `"0"`. Bash command substitution captures BOTH outputs and joins them with a literal newline, so `COUNT` becomes the two-byte string `"0\n0"`. The next `[ "$COUNT" -gt 0 ]` errors out and the gate's logic falls through to whatever default the surrounding code assumes — usually "fail closed = block". Three gates carried this same bug. The correct pattern was already used in `feature_is_complete()` (lines 296–305) but had never been applied elsewhere.

**2. Placeholder scanner matched legitimate domain code (Gate 5).** The regex included bare `placeholder`, `mock data`, and `fake data`, plus `-i`. Real-world false positives:
- HTML `<input placeholder="…" />` form attributes — every form-heavy app
- Type names like `EmailTemplatePlaceholderValues`
- Library files literally named `template-utils.ts` documenting placeholder substitution
- Seed scripts (`prisma/seed.ts`) populating realistic data — the entire purpose of a seed script
- Staged-delivery comments like `// placeholder — employer schedules in Phase 59 UI`

**3. Hollow-test regex flagged real assertions (Gate 6).** The regex ended with `\|\.toBe(true)\|\.toBe(false)`. Those alternatives matched every `expect(realFn(input)).toBe(true)` call — one of the most common valid Jest assertions there is. The actual hollow patterns the gate wants to catch (`expect(true).toBe(true)`, `expect(1).toBe(1)`) were already covered by earlier alternatives in the same regex.

**4. Schema-drift gate ignored committed history (Gate 9).** The gate only inspected `git diff HEAD` (uncommitted changes). On a branch where a previous atomic commit had paired `schema.prisma` with its migration, any later commit that re-touched the schema would trigger the block, because the migration was now "committed, not changed."

**5. `.clone/worktrees/` was scanned (Gates 3, 4, 5, 6).** STP creates Sonnet executor worktrees in `.clone/worktrees/`. These contain files belonging to other parallel sessions, not the current workspace. None of the scanner gates excluded this directory, so any user with active worktrees got false-positives flagging code they don't own.

### Fixed
- `hooks/scripts/stop-verify.sh`
  - Added `clean_count()` helper that wraps `grep -c` and always returns a single integer to stdout. Single source of truth — future gates can't reintroduce the same bug.
  - Gate 1: `UNCHECKED`/`CHECKED` now use `clean_count`
  - Gate 6: `TESTS_COUNT`/`ASSERTS_COUNT` now use `clean_count`
  - Gate 10: `PRD_MUSTS` cleaned via parameter expansion
  - Gate 5: removed `placeholder|mock data|fake data` from the regex; switched to `grep -nE` with explicit anchors (`// (TODO|FIXME)`, `// implement\b`, etc.); dropped `-i`; added file-name carve-outs for `seed.*`, `seeds/`, `template-utils`
  - Gate 6 (hollow tests): dropped `\.toBe(true)\|\.toBe(false)` — only literal-vs-literal patterns remain
  - Gate 9: added per-schema commit-history check via `git log -1 -- $schema_path` + `git show --name-only`. For each uncommitted ORM schema file, look up the most recent commit that touched it and check whether that commit ALSO included a migration. Only block when neither uncommitted nor recent-commit migration is present.
  - Gates 3, 4, 5, 6 now exclude `.clone/` and `.git/`

### Spec Delta
- **Added:** `clean_count()` helper, per-schema commit-history check, `.clone/` exclusion across scanner gates, file-name carve-outs for legitimate template/seed files
- **Changed (assumptions invalidated):**
  - "`grep -c PATTERN FILE || echo 0` is a safe default-to-zero idiom" — it is NOT, because grep prints "0" before exiting non-zero, so the fallback APPENDS rather than replacing. Replace with `clean_count` everywhere.
  - "Schema-drift detection only needs uncommitted state" — branches with atomic schema+migration commits get re-touched and the gate must look at recent commit history.
- **Constraints introduced:**
  - The system MUST use `clean_count` for any `grep -c` count consumed by an integer comparison in `stop-verify.sh`. Bare `grep -c … || echo "0"` is a recurrence and SHALL be rejected in code review.
  - Scanner gates in `stop-verify.sh` MUST exclude `.clone/`. Any new scanner gate SHALL inherit this exclusion.
  - Placeholder/slop scanners SHALL NOT match bare words like `placeholder`, `mock`, or `fake` — only structured comment markers (`// TODO`, `// FIXME`, etc.) and ALL-CAPS slop tokens (`REPLACE_ME`, `NOT_IMPLEMENTED`, `lorem ipsum`).

### Verified
9-case verification harness (`/tmp/verify-stop-verify-fix.sh`):
1. `bash -n` syntax check — clean
2. `clean_count` no-match returns single `"0"` — pass
3. `clean_count` no-match passes integer compare — pass
4. `clean_count` 3-match returns `"3"` — pass
5. Hollow regex does NOT flag valid `expect(realFn()).toBe(true)` — pass
6. Hollow regex DOES flag real `expect(true).toBe(true)` (negative control) — pass
7. Placeholder regex does NOT flag HTML attrs/imports/staged comments — pass
8. Placeholder regex DOES flag real `// TODO`/`REPLACE_ME` (negative control) — pass
9. End-to-end hook run on a clean throwaway repo — zero `integer expression expected` errors

Reproduction script (`/tmp/repro-stop-verify-bug.sh`) confirmed the `0\n0` corruption deterministically before the fix.

### Migration Notes
Sessions running cached versions older than 0.3.7 may already be stuck in this Stop loop. Three options:
1. `/stp:setup upgrade` — pulls 0.3.7, restarts hooks (still requires Claude Code restart for new hooks to load)
2. Hot-patch the cached file: copy `${REPO}/hooks/scripts/stop-verify.sh` over `~/.claude/plugins/cache/<marketplace>/stp/<old>/hooks/scripts/stop-verify.sh` and exit/restart Claude Code
3. `/stp:session pause` — the hook's own escape hatch is still respected

**IMPORTANT:** Hooks load at session start, not hot-reload. Even after the file is replaced, the running session keeps whatever it loaded at launch. Restart Claude Code to pick up the fix.

## [0.3.6] — 2026-04-09 — feat: loud unmissable whiteboard banner (yellow box + classic-blue URL)

### Summary
The `http://localhost:3333` whiteboard URL was getting lost in the middle of agent output. Users missed it and opened empty browser tabs. New shared helper `hooks/scripts/whiteboard-banner.sh` prints a bold yellow bordered box with a blinking `★ OPEN THE WHITEBOARD NOW ★` header and the URL in bold, underlined, classic bright-blue — designed to be impossible to miss and placed as the last line before handing control back.

### Added
- `hooks/scripts/whiteboard-banner.sh` — reusable loud banner, accepts optional subtitle arg.

### Changed
- `commands/whiteboard.md`, `commands/plan.md`, `commands/work-quick.md`, `commands/work-full.md` — replaced the old one-line "Whiteboard is live at..." statement with a call to the shared banner helper, with explicit instructions that it MUST be the last thing printed before control is returned or any follow-up question.

### Notes
- `/stp:setup new`, `/stp:setup onboard`, and `/stp:setup upgrade` don't start the whiteboard, so no integration needed there.
- Hooks/commands only reload on Claude Code restart — exit and relaunch to pick this up.

## [0.3.5] — 2026-04-09 — fix: plugin CLAUDE.md section markers — v0.3.3/0.3.4 content can now sync into projects

### Summary

Every project onboarded with `/stp:setup new` — and every existing project that runs `/stp:setup upgrade` — reads its CLAUDE.md from the plugin's canonical CLAUDE.md via a section-sync mechanism. Sections are wrapped in `<!-- STP:stp-*:start -->` / `<!-- STP:stp-*:end -->` HTML comment markers; the upgrade engine replaces the content between matching marker pairs when the plugin ships new content.

**The problem:** `commands/new-project.md` documented nine marker pairs (`stp-header`, `stp-confirmation-gate`, `stp-philosophy`, `stp-plugins`, `stp-rules`, `stp-dirmap`, `stp-hooks`, `stp-effort`, `stp-output-format`) — but only **two** of those markers actually existed in plugin CLAUDE.md (`stp-confirmation-gate` and `stp-output-format`). The other seven sections were living in plugin CLAUDE.md without markers, so the sync engine could not find them and could not propagate their content.

**The consequence:** every project created or upgraded since v0.3.3 — when the filename contract and 16-gate hooks taxonomy were added to plugin CLAUDE.md — received a project CLAUDE.md missing those new rules. Projects stayed on whatever content their CLAUDE.md had when they were first created (or last touched a marker that happened to exist). Specifically, this meant v0.3.3's filename contract (blocking `.stp/explore-data.json`), v0.3.3's hot-reload warning, and v0.3.3's 16-gate hooks taxonomy never reached any real project that used `/stp:setup upgrade`.

**The fix:** wrap the seven missing sections in proper marker pairs inside plugin CLAUDE.md. Zero content changes. Zero command-file changes. The sync engine already worked — it just had nothing to sync.

### Added

- **`CLAUDE.md` — 7 new section marker pairs** wrapping existing content (14 single-line insertions total):
  - `stp-header` → wraps `## What This Is`
  - `stp-plugins` → wraps `## Required Companion Plugins & MCP Servers`
  - `stp-philosophy` → wraps `## Philosophy (NON-NEGOTIABLE)`
  - `stp-rules` → wraps `## Key Rules` (contains the v0.3.3 filename contract)
  - `stp-dirmap` → wraps `## Directory Map`
  - `stp-hooks` → wraps `## Hooks (16 enforcement gates across 4 events)` (contains the v0.3.3 hot-reload warning)
  - `stp-effort` → wraps `## Effort Levels`

  All 9 marker pairs now present and matched (the 2 existing `stp-confirmation-gate` and `stp-output-format` are unchanged).

- **`CLAUDE.md` `stp-rules` — exception clause for /clear after /stp:setup upgrade** — the existing "/clear suggested before every inter-command transition" rule now has an explicit exception: *"after `/stp:setup upgrade` when hook files changed, the recommendation is `/exit → run claude again → (optional) /clear` — because `/clear` alone does NOT reload hooks."* This keeps the two rules consistent and points readers at the Hooks section for the full explanation. Because this rule lives inside `stp-rules` which is now wrapped, the exception clause will also sync into projects on upgrade.

### Changed

- **`CLAUDE.md` `## What This Is` — version marker removed, canonical source cited** — the old text hardcoded "v0.3.0" which drifted with every release. New text instructs the reader to read the installed version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`. This prevents the `stp-header` block from going stale whenever the plugin version bumps.

### Fixed

- **v0.3.3 content never reached onboarded projects** — projects that ran `/stp:setup upgrade` between v0.3.3 and v0.3.4 saw the upgrade complete successfully but the new content (filename contract, hot-reload warning, 16-gate taxonomy) was not added to their CLAUDE.md. After v0.3.5, the next `/stp:setup upgrade` run on those projects will replace the contents of `stp-rules` and `stp-hooks` (and the 5 other newly-marked blocks) with the latest content from the plugin.
- **`commands/new-project.md` template referenced nonexistent markers** — the template at line 151-159 listed 9 marker pairs as the canonical structure for a project CLAUDE.md. Only 2 of them actually existed in the plugin. New projects created after v0.3.5 will now find all 9 markers in the plugin source and can inject the real content.

### Spec Delta

- **Added:**
  - 7 new marker pairs in plugin CLAUDE.md: `stp-header`, `stp-plugins`, `stp-philosophy`, `stp-rules`, `stp-dirmap`, `stp-hooks`, `stp-effort`
  - Exception clause inside `stp-rules` that distinguishes `/clear` (normal inter-command) from `/exit + restart` (post-plugin-upgrade when hooks changed)

- **Changed:**
  - The contract for adding new content to plugin CLAUDE.md — any new `## Section` header that should propagate to project CLAUDE.md MUST be inside a `<!-- STP:stp-*:start -->` / `<!-- STP:stp-*:end -->` marker pair. Content outside markers is plugin-level documentation that does NOT reach onboarded projects. This is now a contributor rule, not an accidental property.
  - The `## What This Is` section — removed hardcoded version string, added pointer to canonical `plugin.json`.

- **Constraints introduced:**
  - Plugin CLAUDE.md MUST maintain at least 9 matched marker pairs: the 9 listed in `commands/new-project.md:151-159`. A CI check (not yet wired) should validate this.
  - Any new marker added to the plugin CLAUDE.md MUST also be documented in `commands/new-project.md`'s template block — the two files are coupled and must stay in sync.
  - CHANGELOG.md entries for any v0.3.6+ release that adds content to plugin CLAUDE.md MUST indicate which marker block received the content (so downstream projects know what their next `/stp:setup upgrade` will refresh).

- **Dependencies created:**
  - `commands/new-project.md` Step 6 (project CLAUDE.md generation) now depends on the 9 markers being present in plugin CLAUDE.md. If future refactors remove a marker, the template's corresponding line must also be removed.
  - `commands/upgrade.md` Step 4 (project CLAUDE.md sync) iterates over whatever markers exist in plugin CLAUDE.md. It is tolerant of missing markers (just skips them) but now has 9 marker pairs to potentially update instead of 2.

### Deliberately NOT done

- **Marker validation CI check** — a 5-line script that confirms all 9 markers are present in plugin CLAUDE.md and that each marker pair is balanced. Useful for catching regressions, but this release already ships the fix; the CI check is a preventive follow-up, not part of the immediate patch.
- **Auto-migration of existing project CLAUDE.md files** — users who currently have a project CLAUDE.md without the 7 new markers will still only have those 2 markers. The `/stp:setup upgrade` Step 4 "legacy project CLAUDE.md" path handles this: if a marker is missing in the project, the upgrade appends it with the new content. This means the first `/stp:setup upgrade` after v0.3.5 on an existing project will ADD the 7 missing sections (not replace them). Users who manually edited those sections will see an append, not an overwrite — which is the safer default.

### Test coverage

Validated via bash script:
- All 9 `stp-*:start` markers present in plugin CLAUDE.md
- All 9 `stp-*:end` markers present
- Start/end pairs match (9 starts, 9 ends, same names)
- Each marker block contains real content (line counts: stp-header 4, stp-confirmation-gate 24, stp-plugins 24, stp-philosophy 17, stp-rules 15, stp-output-format 11, stp-dirmap 41, stp-hooks 37, stp-effort 9)
- v0.3.3 FILENAME CONTRACT text is inside `stp-rules` block ✓
- v0.3.3 "SESSION STARTUP" hot-reload warning is inside `stp-hooks` block ✓
- v0.3.3 "16 enforcement gates" taxonomy is inside `stp-hooks` block ✓
- CLAUDE.md still renders as valid markdown (384 lines total)

---

## [0.3.4] — 2026-04-09 — feat: `/stp:setup upgrade` surfaces restart-required banner + CHANGELOG-driven "what's new"

### Summary

v0.3.3 fixed the whiteboard-gate hallucination bug and added the hot-reload warning to CLAUDE.md, but the warning only helps users who happen to be reading CLAUDE.md. The `/stp:setup upgrade` command itself still ended with the old `► Next: /clear to load the new version` hint — which is **wrong**: `/clear` clears conversation context but does NOT reload hooks. After `/stp:setup upgrade`, users were following the displayed instruction, running `/clear`, and then wondering why the new hooks weren't firing. This is exactly the failure mode that caused the v0.3.2 post-mortem Bug 1 to hit a second time.

v0.3.4 pushes the restart-required directive into the command output itself, where the user cannot miss it, and extracts the new version's CHANGELOG entry dynamically so every upgrade ends with a faithful "what's new" summary instead of a 2-3-sentence placeholder.

### Added

- **`commands/upgrade.md` — hook-change detection in Step 1** — after the git pull, the command now captures three new variables via `git diff --name-only`:
  - `HOOK_CHANGED_FILES` — list of files under `hooks/` or `.claude-plugin/plugin.json` that changed between old HEAD and new HEAD
  - `HOOK_CHANGE_COUNT` — how many such files changed
  - `HOOKS_JSON_CHANGED` — boolean, whether `hooks/hooks.json` specifically was modified
  These values feed the Step 9 restart banner's loudness (mandatory vs recommended variant).

- **`commands/upgrade.md` — CHANGELOG extraction instruction in Step 1** — after capturing the new version number from `plugin.json`, the command now instructs Claude to Read the new `CHANGELOG.md` and extract the `## [NEW_VER]` section's tagline, `### Summary`, and top items from `### Added` / `### Changed` / `### Fixed`. This replaces the old "[2-3 sentence summary of changes]" placeholder with a real extraction from the version's canonical release notes.

- **`commands/upgrade.md` — Block 3: RESTART REQUIRED banner** — new loud banner displayed on every upgrade, with two visual variants:
  - **MANDATORY variant** (cyan double-line box, bold yellow `⚠`) — shown when `HOOK_CHANGE_COUNT > 0`. Lists the changed hook files, explains that Claude Code loads hooks only at session startup, gives explicit 3-step restart instructions, and explains why `/clear` alone is not sufficient.
  - **Recommended variant** (dim cyan single-line box) — shown when no hook files changed. Softer tone: "safest to restart anyway."

- **`commands/upgrade.md` — three-block Step 9 structure** — the single completion box is split into three visually-distinct blocks echoed sequentially: (1) upgrade checklist, (2) what's new pulled from CHANGELOG, (3) restart banner. The restart banner is always the LAST thing the user sees, so it's impossible to scroll past.

### Changed

- **`commands/upgrade.md` Step 9 inline `► Next:` line** — rewritten from `► Next: /clear to load the new version` to `► Next: /exit → run \`claude\` again → (optional) /clear to start fresh`. The old phrasing was actively wrong for any upgrade that modified hooks (/clear does not reload hooks). The new phrasing tells the user to exit + relaunch + verify with `cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

- **`commands/upgrade.md` Step 9 "What's new" semantics** — the old template said `[2-3 sentence summary of changes]`, which encouraged Claude to paraphrase from memory. The new template explicitly instructs Claude to Read the new CHANGELOG.md and extract real content: tagline, summary paragraph, top 3-5 Added/Changed/Fixed items. Preserves any **CRITICAL** or **IMPORTANT** markers from the source. Faithful extraction, not generation.

### Fixed

- **v0.3.3 upgrade UX gap** — v0.3.3 added the hot-reload warning to `CLAUDE.md` but the `/stp:setup upgrade` command itself still ended with `/clear` as the next step. Users reading the command output followed it literally, ran `/clear`, and then hit stale hooks without knowing why. This release closes that gap by making the upgrade command's output itself carry the restart instruction.

### Spec Delta

- **Added:**
  - `HOOK_CHANGED_FILES`, `HOOK_CHANGE_COUNT`, `HOOKS_JSON_CHANGED` metadata captured in Step 1 of `commands/upgrade.md`
  - CHANGELOG.md-driven extraction step for the "What's new" block
  - Two-variant restart banner (MANDATORY when hooks changed, Recommended otherwise)
  - Three-block completion output structure (checklist → what's new → restart)

- **Changed:**
  - `/stp:setup upgrade` completion semantics — was "show checklist, say /clear". Now "show checklist, show faithful CHANGELOG extract, show restart banner". The command is now self-sufficient for teaching the user the post-upgrade workflow.
  - The `► Next:` line convention after plugin upgrades — always includes exit+relaunch, never just `/clear` alone.

- **Constraints introduced:**
  - After `/stp:setup upgrade`, the completion output MUST include a restart banner (MANDATORY or Recommended variant, depending on hook changes). The banner MUST reference `/exit` and relaunching `claude`, not just `/clear`.
  - "What's new" in the upgrade completion MUST be extracted from the real CHANGELOG.md for the new version, not paraphrased from memory.
  - Any command file that recommends `/clear` as a post-plugin-upgrade action MUST also include exit+relaunch, or the recommendation is actively misleading.

- **Dependencies created:**
  - The restart banner's "hooks changed" detection depends on the git diff between old and new HEAD being available. For marketplace installs (no .git history), the detection falls back to showing the MANDATORY variant unconditionally (safer default).

### Deliberately NOT done

- **Automatic session restart via a SIGTERM hook** — would require a Claude Code capability that doesn't exist (process can't signal its own parent to restart cleanly). Also dangerous: a background restart could discard the user's unsaved state.
- **In-session hot-reload workaround** — genuinely impossible at the plugin level; hooks are registered at Claude Code process startup and the registration surface has no invalidation API in v2.1.x.
- **Bumping the banner to always-MANDATORY even when hooks didn't change** — considered, rejected. Banner fatigue is real; if users see the same loud banner every upgrade, they learn to ignore it. The two-variant design reserves the MANDATORY banner for cases where restart actually matters for correctness.

### Test coverage

Manual verification of the bash snippets added to Step 1:
- `git diff --name-only [old]..[new] | grep -E "^(hooks/|\\.claude-plugin/plugin\\.json)"` — runs cleanly against the v0.3.2→v0.3.3 diff and correctly lists `hooks/scripts/whiteboard-gate.sh`, `hooks/hooks.json` (from v0.3.2), `.claude-plugin/plugin.json`
- CHANGELOG.md extraction — the `## [NEW_VER]` pattern is unambiguous and each version section is self-contained, so Read + section slicing is reliable
- No runtime tests for the Step 9 banner itself because it's a template Claude fills in, not executable code

---

## [0.3.3] — 2026-04-08 — fix: filename hallucination catch + hot-reload docs + hooks taxonomy refresh

### Summary

**v0.3.2 post-mortem** — the v0.3.2 enforcement layer shipped with three bugs that together recreated the v0.3.1 failure mode in a fresh form. A user ran `/stp:build --quick` and `/stp:think --whiteboard` back-to-back and hit all three:

**Bug 1 — Session 1 stale hooks.** Plugin cache `0.3.2` was only created 43 minutes after I committed v0.3.2 to source. Any Claude Code session started in that window loaded the pre-v0.3.2 hooks.json (no PreToolUse entries). The user's `/stp:build --quick` session had no ui-gate loaded, so it built the exact same AI-slop landing page that motivated the v0.3.2 release. **Root cause:** Claude Code loads hooks at session startup and does not hot-reload when source changes. This is a Claude Code limitation, not fixable in the plugin — but it was undocumented.

**Bug 2 — Whiteboard-gate matched only the canonical filename.** In Session 2, the user ran `/stp:think --whiteboard`. Claude wrote the data to `.stp/explore-data.json` (a pre-0.3.1 legacy name) instead of `.stp/whiteboard-data.json`. The whiteboard-gate hook checked only the canonical name — the wrong filename passed through as "not my problem" and exited 0. Data landed in a file the server does not watch. localhost:3333 stayed on `{"status": "Waiting..."}` for the entire session. The user was correct to say "it never deployed."

**Bug 3 — CHANGELOG.md teaching the wrong filename.** The v0.3.1 post-mortem CHANGELOG mentioned the legacy filename three times while explaining the old bug. With no counter-balancing filename contract in CLAUDE.md, Claude's context-read treated the legacy name as a valid alternative. The v0.3.2 CHANGELOG also inherited the references. **The documentation of a fixed bug was actively training the agent to reproduce it.**

Fixing this requires defense-in-depth across three layers: the hook must catch hallucinated names, CLAUDE.md must carry an always-loaded filename contract, and the CHANGELOG references must be defused so they read as negative examples instead of valid alternatives.

### Added

- **`CLAUDE.md` `## Key Rules` — Filename Contract** — new always-loaded rule pinning the whiteboard data file to the canonical `.stp/whiteboard-data.json` and explicitly naming four forbidden aliases (`.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`). The rule includes a loud "STOP" directive if the agent catches itself about to write a forbidden name and cites the post-mortem reason. Since CLAUDE.md is loaded on every session start, this becomes a hard context-level constraint that sits above training-data hallucination.
- **`CLAUDE.md` `## Hooks` — hot-reload warning** — explicit prose at the top of the section: *"Hooks load at Claude Code SESSION STARTUP, not hot-reload. After `/stp:setup upgrade` or any plugin update that adds or modifies hooks, you MUST exit Claude Code and restart it to pick up the new hooks. A running session keeps whatever hooks.json it loaded at launch."* Closes Bug 1 at the documentation layer (can't fix Claude Code itself, but users can now diagnose the "my hooks aren't firing" symptom).
- **`CLAUDE.md` `## Hooks` — complete taxonomy refresh** — the section was stale since before v0.3.2, still listing "10 enforcement gates." It now documents all 19 hooks across 5 events (PreToolUse ×2, PostToolUse ×2, Stop ×13, SessionStart ×1, PreCompact ×1) with a note on the 3-retry technical safety valve and the workflow-vs-technical block distinction.
- **`hooks/scripts/whiteboard-gate.sh` — forbidden-filename detection (4 variants)** — the hook now matches `.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, and `.stp/design-data.json` in addition to the canonical name. Wrong filename → BLOCK with exit 2 and a correction message telling Claude exactly what path to use, including the historical context (why the wrong name exists, why it's forbidden, how to unblock). Canonical filename → existing auto-start-server behavior unchanged.

### Changed

- **`CHANGELOG.md` v0.3.1 section — three forbidden-name references defused** — the three literal `.stp/explore-data.json` mentions in the v0.3.1 post-mortem entry have been rewritten to use the phrase "pre-0.3.1 legacy name" or "FORBIDDEN legacy name" with explicit "DO NOT use this" / "blocked by `hooks/scripts/whiteboard-gate.sh`" markers. The literal forbidden string has been removed from the historical record so that Claude's context-read of the CHANGELOG no longer trains the hallucination. The factual narrative of the bug is preserved.
- **`.claude-plugin/plugin.json`** — `0.3.2` → `0.3.3`.

### Fixed

- **v0.3.2 whiteboard-gate false-negative** — `hooks/scripts/whiteboard-gate.sh:47` matched `(^|/)\.stp/whiteboard-data\.json$` literally. This was correct for the canonical name but blind to hallucinated variants. The fix adds four additional regex branches (one per forbidden alias) and keeps the canonical branch unchanged. All 10 hook tests still pass, plus 4 new tests for the forbidden-name branches.
- **v0.3.1 → v0.3.2 CHANGELOG training-data bleed** — removed the literal forbidden-filename string from the v0.3.1 post-mortem entry. The post-mortem's explanatory power is preserved (the narrative still says "filename contract was split, rename was half-finished, server stuck on Waiting..."), but the specific legacy name no longer appears as a grep-able string that Claude can learn as valid.

### Spec Delta

- **Added:**
  - Filename contract in CLAUDE.md `## Key Rules` — canonical path + 4 forbidden aliases
  - Hot-reload warning in CLAUDE.md `## Hooks` — documents the "restart Claude Code after /stp:setup upgrade" requirement
  - Updated `## Hooks` taxonomy listing all 19 hooks across 5 lifecycle events
  - Forbidden-name detection in `whiteboard-gate.sh` (4 new regex branches)
  - Correction-message BLOCK response with historical context and remediation steps

- **Changed:**
  - `whiteboard-gate.sh` semantics — now also a filename validator, not just a server-start auto-initializer. Before: "auto-start server when needed." After: "validate filename AND auto-start server when needed." The hook's concern has broadened from runtime state to filename contract enforcement.
  - CHANGELOG.md content discipline — historical bug references to forbidden strings must be defused, not quoted verbatim. Any future "the old name was X" reference must be written as "the pre-<version> legacy name" and cite the blocking hook.
  - The "hook = runtime enforcement" model — hooks are now also documentation of forbidden names that the always-loaded CLAUDE.md can point at. `whiteboard-gate.sh` is cited by CLAUDE.md:194 as the authoritative enforcement reference.

- **Constraints introduced:**
  - Writes to `.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json` MUST be blocked and corrected to `.stp/whiteboard-data.json`.
  - CHANGELOG entries documenting bugs involving forbidden strings MUST use defused references ("pre-<version> legacy name") rather than quoting the forbidden string verbatim.
  - CLAUDE.md MUST carry the whiteboard filename contract as an always-loaded rule.
  - After any `/stp:setup upgrade` that modifies hooks, the upgrade's completion message MUST instruct the user to restart Claude Code (follow-up task — not wired in this release).

- **Dependencies created:**
  - CLAUDE.md `## Key Rules` filename contract references `hooks/scripts/whiteboard-gate.sh` by path — future refactors of the hook must keep it at that location or update the citation.
  - CLAUDE.md `## Hooks` taxonomy references specific gate numbers in `hooks/scripts/stop-verify.sh` — future gate additions must update both.

### Deliberately NOT done

- **SessionStart version banner** — user declined ("just document it"). A banner printing "STP hooks v0.3.3 loaded" would make the stale-hook symptom visually obvious on every session start, but adds noise and maintenance cost for a rare failure mode that documentation can cover.
- **Claude Code hot-reload fix** — not fixable at the plugin level. Hooks are loaded by the Claude Code process at startup; there is no hook API to invalidate the loaded set mid-session. Users must restart. Documented as a known limitation.
- **Rewrite of v0.3.2 CHANGELOG references to forbidden string** — the v0.3.2 entry's post-mortem narrative has been scanned but not edited; the v0.3.2 entry in this CHANGELOG cites the filename bug as an abstract concept without the literal string, so defusing-in-place is unnecessary. Only the v0.3.1 section had the literal string three times.

### Test coverage delta

- 10 new `whiteboard-gate.sh` tests (v2): 4 forbidden-name BLOCK tests, 1 canonical-name ALLOW test, 1 non-whiteboard file ALLOW test, 1 non-STP project test, 1 env-bypass test, 2 false-positive-guard tests (`.stp/docs/whiteboard.md` and `.stp/state/critic-report.json` must not match). All 10 pass.
- Existing v0.3.2 test suite: still 49/49 green (regression-checked).

---

## [0.3.2] — 2026-04-08 — feat: enforcement layer — markdown "MANDATORY" becomes hook-enforced

### Summary
STP's workflow rules were written as **suggestions in markdown** ("MUST", "MANDATORY", "this is required"). Claude routinely routed around them. The v0.3.1 post-mortem was a landing page shipped with every AI-slop tell the design system explicitly forbade: gradient headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand mark, template copy, center-everything layout. The `/ui-ux-pro-max` skill never fired. Step 1b of `/stp:build --quick` was labelled MANDATORY — and was pure markdown.

This release converts the most load-bearing "MANDATORY" rules into hooks. Per Shrivu Shankar's [Claude Code enterprise guide](https://blog.sshh.io/p/how-i-use-every-claude-code-feature): *"Hooks are the deterministic 'must-do' rules that complement the 'should-do' suggestions in CLAUDE.md."* Per [Knostic's openclaw-shield writeup](https://www.knostic.ai/blog/why-we-built-openclaw-shield-securing-ai-agents-from-themselves): *"prompt injection is a weak guardrail. A tool-based gate where the model gets a real DENIED response is far more effective."*

Three new hooks, three new stop-verify gates, two markdown bug fixes, 49/49 tests green.

### Added

- **`hooks/scripts/ui-gate.sh`** — PreToolUse blocker for new UI file writes (`.html`, `.tsx`, `.jsx`, `.vue`, `.svelte`, `.astro`, `.css`, `.scss`, `.sass`, `.less`). Blocks until `.stp/state/ui-gate-passed` marker exists. Carve-outs: tests, stories, configs, migrations, file overwrites. Escape hatch: `STP_BYPASS_UI_GATE=1`. Closes v0.3.1 AI-slop-landing-page failure.
- **`hooks/scripts/anti-slop-scan.sh`** — PostToolUse deterministic grep scanner for 7 AI-slop patterns: gradient headlines, "Now in beta" eyebrow pills, template hero copy ("without the X headache"), "ship in minutes" speed promises, sparkles brand marks, center-everything defaults, 3+ boxed benefit cards. **1 finding → WARN**. **2+ findings → BLOCK** with exit 2. Escape hatch: `STP_BYPASS_SLOP_SCAN=1`.
- **`hooks/scripts/whiteboard-gate.sh`** — PreToolUse auto-starter for the whiteboard server before writes to `.stp/whiteboard-data.json`. Detects existing process via `pgrep` or listening port via `ss`/`netstat`/`lsof`. If not running, auto-starts `start-whiteboard.sh` in background and waits briefly for the port to bind. Closes the "server-start and data-write are separable steps so Claude reaches data-write first" failure that v0.3.1 only addressed in documentation. Escape hatch: `STP_BYPASS_WHITEBOARD_GATE=1`.
- **`hooks/scripts/stop-verify.sh` — Gate 11 (WARN)** — Spec delta merge-back. When a feature is complete, checks CHANGELOG.md for a `### Spec Delta` block and verifies ARCHITECTURE.md was touched in the last 5 commits. Catches the "built feature, forgot merge-back" failure mode.
- **`hooks/scripts/stop-verify.sh` — Gate 12 (BLOCK)** — Critic required for full-cycle work. When `.stp/docs/PLAN.md` exists AND the feature is complete, requires `.stp/state/critic-report-*.md` newer than the feature file. Workflow gate — doesn't increment the 3-retry technical counter, so it can't brick a session.
- **`hooks/scripts/stop-verify.sh` — Gate 13 (BLOCK)** — QA required for UI features. When `.stp/state/ui-gate-passed` exists AND the feature is complete, requires `.stp/state/qa-report-*.md`. Workflow gate.
- **`hooks/scripts/stop-verify.sh` — `feature_is_complete()` helper** — robust against a latent `grep -c '[ ]' FILE || echo "0"` bug that produces `"0\n0"` when grep matches zero lines AND exits 1, breaking downstream numeric comparisons. The helper strips non-numeric characters and defaults to 0.

### Changed

- **`hooks/hooks.json`** — added `PreToolUse` section with `ui-gate.sh` + `whiteboard-gate.sh` chain. Added `anti-slop-scan.sh` to the existing `PostToolUse` chain. Extended `SessionStart` to wipe `.stp/state/ui-gate-passed` on every `/clear` so fresh sessions re-confirm design direction.
- **`commands/work-quick.md` Step 1b** — (1) replaced hardcoded `[ -f "design-system/MASTER.md" ]` with `find design-system -maxdepth 4 -name "MASTER.md"` to support nested per-page design systems like `design-system/landing/MASTER.md` (the exact path the v0.3.1 user requested that the old check missed); (2) added mandatory design consultation step that runs **even when MASTER.md already exists** — reading tokens is not the same as a consultation; (3) added anti-slop commitment language to the approval `AskUserQuestion`; (4) added marker-write step (`touch .stp/state/ui-gate-passed`) to release the hook gate; (5) added "this is hook-enforced" note pointing at `hooks/scripts/ui-gate.sh`.
- **`commands/work-full.md` Phase 3b** — same five fixes applied symmetrically.

### Fixed

- **v0.3.1 path-glob regression** — `commands/work-quick.md:90` and `commands/work-full.md:251` checked `design-system/MASTER.md` literally, missing nested paths. The v0.3.1 landing page user explicitly said *"using design-system/stp-test-landing/MASTER.md"* — the check returned NONE, Claude rationalized *"user already provided one, I'll just read it"*, and Step 1b was skipped entirely. Fixed in both files via `find` with `-maxdepth 4`.

### Spec Delta

- **Added:**
  - 3 new PreToolUse/PostToolUse hook scripts (`ui-gate.sh`, `anti-slop-scan.sh`, `whiteboard-gate.sh`)
  - 3 new gates in `stop-verify.sh` (Gate 11 WARN, Gate 12 BLOCK, Gate 13 BLOCK)
  - `feature_is_complete()` helper function
  - 3 new session-scoped marker file contracts: `.stp/state/ui-gate-passed`, `.stp/state/critic-report-*.md`, `.stp/state/qa-report-*.md`
  - 3 new environment variable escape hatches: `STP_BYPASS_UI_GATE`, `STP_BYPASS_SLOP_SCAN`, `STP_BYPASS_WHITEBOARD_GATE`

- **Changed:**
  - STP's enforcement model. Previously: rules lived in markdown, Claude chose whether to apply them. Now: load-bearing rules live in hooks, Claude gets a hard DENIED and structured feedback. Markdown labels remain as documentation but are no longer the enforcement surface.
  - `hooks/hooks.json` schema — PreToolUse now present with 2-hook chain; PostToolUse grew from 1 to 2 hooks; SessionStart command is now a compound command (marker wipe + existing session-restore chain).
  - Layer 0 of the verification stack — previously implicit/absent, now explicit as "pre-action gates." Layers 1-6 (executable specs → production verification) remain unchanged as post-hoc stages.

- **Constraints introduced:**
  - New UI file writes (`.html`, `.tsx`, `.jsx`, `.vue`, `.svelte`, `.astro`, `.css`) MUST be preceded by a design-system consultation that touches `.stp/state/ui-gate-passed`. Overwrites of existing files are exempt.
  - Writes to `.stp/whiteboard-data.json` MUST have the whiteboard server running (auto-started if missing).
  - Features built under a `PLAN.md` (i.e., `/stp:build --full` territory) MUST run `/stp:review` before Claude can stop. The Critic can no longer be silently skipped.
  - UI features (identified by the presence of the `ui-gate-passed` marker) MUST have a QA report before Claude can stop. agent-browser QA can no longer be silently skipped.
  - All completed features SHOULD emit a `### Spec Delta` block in CHANGELOG.md and touch ARCHITECTURE.md (Gate 11 warns but does not block).

- **Dependencies created:**
  - `ui-gate.sh` depends on `.stp/state/ui-gate-passed` marker contract. `SessionStart` hook is now responsible for wiping it.
  - `whiteboard-gate.sh` depends on `start-whiteboard.sh` being at `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh` and being executable.
  - `stop-verify.sh` Gates 12/13 depend on filename contracts: `.stp/state/critic-report-*.md` and `.stp/state/qa-report-*.md`. Any command that wants to satisfy the gate writes a file matching those globs newer than `current-feature.md`.
  - `commands/work-quick.md` and `commands/work-full.md` now explicitly depend on `hooks/scripts/ui-gate.sh` for the "mandatory" label to have teeth. The doc references the hook by path so future refactors know they're coupled.

### Deliberately NOT done

- **Pre-work `AskUserQuestion` gate** (audit gap #2) — deferred. Risk of false-triggering on `/stp:session continue`, `/stp:resume`, `/stp:build --auto` flows without careful session-scoped carve-outs. Will revisit once the session-ID primitive is more accessible from hooks.
- **Context7/Tavily research gate** (audit gap #3) — deferred. Research is judgment; sometimes legitimately cached from earlier in the session. Transcript parsing is brittle and false positives would train the agent to ignore warnings. Stays as documentation-only.
- **/clear between commands** (audit gap #8) — purely cosmetic, already handled by completion-box templates. No hook needed.

### Research sources behind this release

- [Claude Code hooks docs — deterministic control layer](https://code.claude.com/docs/en/hooks)
- [Claude Code hooks guide](https://code.claude.com/docs/en/hooks-guide)
- [Shrivu Shankar — "Hooks are the deterministic must-do"](https://blog.sshh.io/p/how-i-use-every-claude-code-feature) — block-at-submit not block-at-write insight
- [Knostic openclaw-shield — tool-based gates beat prompt injection](https://www.knostic.ai/blog/why-we-built-openclaw-shield-securing-ai-agents-from-themselves)
- [Claude Code Hooks Reference: All 12 Events — Pixelmojo](https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns)
- [AgentSpec: Runtime Enforcement for LLM Agents (ICSE '26)](https://cposkitt.github.io/files/publications/agentspec_llm_enforcement_icse26.pdf) — neurosymbolic enforcement
- [Anthropic: Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

### Test coverage

- 10 tests for `ui-gate.sh` (match, carve-outs, markers, bypass)
- 8 tests for `anti-slop-scan.sh` (all 7 pattern categories + carve-outs)
- 4 tests for `whiteboard-gate.sh`
- 5 tests for new `stop-verify.sh` gates (11/12/13 + release paths)
- 2 regression tests for existing gates
- 3 end-to-end scenario tests reproducing the exact v0.3.1 failure

**49/49 tests passing. 0 regressions.**

---

## [0.3.1] — 2026-04-08 — fix: whiteboard reliability (filename contract + mandatory server start + /clear in handoffs)

### Summary
Three structural bugs ganged up to make the visual whiteboard unreliable for
any user invoking `/stp:think --whiteboard`:

1. **Filename contract was split.** The server (`whiteboard/serve.py`) watched
   `.stp/whiteboard-data.json` while four command files told the orchestrator
   to write a different, now-**FORBIDDEN** legacy name (the pre-0.3.1 path —
   DO NOT use this; it is blocked by `hooks/scripts/whiteboard-gate.sh` in
   v0.3.3+ and mentioned here only as historical record). The rename was
   half-finished — `plan.md` even contradicted itself across three lines.
   Result: server permanently stuck on `{"status":"Waiting..."}`.

2. **Server start was always conditional.** Every single `start-whiteboard.sh`
   call across the entire codebase lived inside an "if they accept" /
   AskUserQuestion gate or after a write. There was zero unconditional start
   anywhere. The agent could (and did) reach the "write the design system
   JSON" step with no server running — the user opened localhost:3333 and
   saw nothing. The command is literally named `/stp:think --whiteboard`; a whiteboard
   the user can't see is a broken command.

3. **No `/clear` in handoffs.** Completion boxes recommended `/stp:build --quick`,
   `/stp:think --plan`, etc. as next steps but never told the user to `/clear` first.
   Each STP phase fills context with research and verification noise; the
   next phase reads its inputs from disk, so failing to clear strictly hurts.

### Root Causes
1. Producer/consumer naming drift survived an incomplete rename.
2. The whiteboard offer was modeled as opt-in everywhere, including in the
   command literally named after it.
3. Inter-command handoffs were modeled as command-only ("/stp:next") instead
   of session-transition ("/clear, then /stp:next").

### Files Changed
**Filename contract fix:**
- `whiteboard/serve.py` — added graceful 302 redirect for unknown paths
  (browser autocomplete `/en` no longer shows a raw Python 404 page); real
  files under the plugin dir still serve normally
- `commands/whiteboard.md` — 3 references unified to `whiteboard-data.json`
- `commands/work-quick.md` — 4 references unified (incl. the impact-scan
  existence check)
- `commands/work-full.md` — 3 references unified
- `commands/plan.md` — line 116 unified (lines 59, 454 were already correct)

**Mandatory whiteboard server start:**
- `commands/whiteboard.md` — replaced the optional "## Visual Whiteboard"
  offer with a mandatory "## Start the Whiteboard Server (MANDATORY — your
  FIRST action, before anything else)" block. Server starts unconditionally
  at the top of every `/stp:think --whiteboard` invocation. No AskUserQuestion gate,
  no "if they accept" branch.
- `commands/plan.md` — same pattern. Server starts at the top of every
  `/stp:think --plan` invocation.
- `commands/work-full.md` — UI/UX branch (line 263) reordered: server starts
  BEFORE the design system is generated, never after. Step numbering
  adjusted (4 → 5 for the persist step).
- `commands/work-quick.md` — UI/UX branch (line 101) reordered the same way.

**/clear in next-step handoffs:**
- `commands/whiteboard.md` — final completion box now recommends
  "1. /clear, 2. then ONE of: /stp:build --full | /stp:build --quick | /stp:build"
- `commands/plan.md` — `► Next: /clear, then /stp:build --quick [FIRST FEATURE]`
- `commands/new-project.md` — `► Next: /clear, then /stp:think --plan`
- `commands/review.md` — `► Next: /clear, then /stp:build --quick [NEXT FEATURE]`
- `commands/work-quick.md` — both completion boxes (next feature, next
  milestone) prepend `/clear, then`

**Project conventions added (so this can't regress):**
- `CLAUDE.md` — two new entries in `## Key Rules`:
  1. Whiteboard server start is mandatory + first for `/stp:think --whiteboard` and
     `/stp:think --plan`; never gated behind AskUserQuestion or "if they accept".
  2. `/clear` must be suggested before every inter-command transition in
     completion boxes.

**Release plumbing:**
- `.claude-plugin/plugin.json` — version 0.3.0 → 0.3.1
- `CHANGELOG.md` — created (this file)

### Verification
**Live server test (filename contract + 404 fallback) — all 6 routes green:**
- `/` → 200 serves `index.html`
- `/data.json` → 200 returns the contents of `.stp/whiteboard-data.json`
- `/codebase-map-template.html` → 200 (real file under plugin dir still served)
- `/en`, `/notafile.xyz`, `/some/deep/path` → 302 to `/`
- End-to-end: agent writes `.stp/whiteboard-data.json` → `/data.json` returns
  the exact payload → previous silent-failure mode is gone

**Codebase grep checks (must-be-empty after fix):**
- grep for the pre-0.3.1 legacy filename across `commands/` and `whiteboard/` → 0 matches (legacy name is FORBIDDEN and blocked by `hooks/scripts/whiteboard-gate.sh` in v0.3.3+)
- `grep -n "Next.*\/stp:" commands/*.md | grep -v "/clear"` → 0 matches
- `grep -B1 -A1 "If they accept" commands/whiteboard.md commands/plan.md` → 0 matches

### Spec Delta
- **Added:**
  - Graceful 404 fallback policy in `serve.py` (unknown paths redirect to
    `/` instead of emitting Python's default 404 HTML).
  - Mandatory unconditional whiteboard server start as the first action of
    `/stp:think --whiteboard` and `/stp:think --plan`.
  - `/clear` recommendation before every inter-command transition in
    completion boxes across new-project, plan, whiteboard, work-quick,
    review.
  - Two new entries in CLAUDE.md `## Key Rules` enforcing the above.
- **Changed:**
  - Canonical whiteboard data filename is `.stp/whiteboard-data.json`
    (was ambiguously a different legacy name in some pre-0.3.1 command docs —
    that legacy name is now FORBIDDEN and blocked by the v0.3.3 whiteboard-gate
    hook; do NOT reference it).
  - The whiteboard offer is no longer modeled as opt-in for `/stp:think --whiteboard`
    and `/stp:think --plan` — it is the literal first action.
  - In `/stp:build --quick` and `/stp:build --full` UI/UX branches, the server
    starts BEFORE design system generation, not after.
- **Constraints introduced:**
  - Any future command that writes live whiteboard data MUST use
    `.stp/whiteboard-data.json`. Single source of truth between producer
    (command agent) and consumer (`whiteboard/serve.py`).
  - The whiteboard server MUST start as the first action of any command
    whose primary purpose is whiteboarding (`/stp:think --whiteboard`, `/stp:think --plan`).
    No AskUserQuestion gate, no conditional offer.
  - Any command's completion box that recommends a follow-up `/stp:*`
    command MUST prepend `/clear, then` to the recommendation.
- **Dependencies created:** none — these are protocol fixes, not new modules.

### Lessons
**Lesson 1 — Cross-file contracts.** When renaming a cross-file contract,
grep for BOTH names and keep replacing until zero occurrences of the old name
remain. A half-finished rename that leaves consumer and producer out of sync
fails silently — the system technically "works" but never shows the data,
which is harder to diagnose than a crash. The producer thinks it wrote the
file, the consumer thinks no file exists, and neither complains.

**Applies when:** renaming any filename, env var, URL path, or config key
that crosses a process boundary (writer vs. reader) in an agent pipeline.

**Lesson 2 — Match command name to mandatory action.** If a command's name
declares its primary purpose (`/stp:think --whiteboard`, `/stp:debug`, `/stp:think --plan`),
that purpose's enabling action must be unconditional and first. Modeling it
as an "if they accept" offer creates a class of failure where the agent can
reach the work step without the prerequisite running. The user already
answered "do you want this?" by typing the command — re-asking is friction
at best and a footgun at worst.

**Applies when:** writing any orchestrator command that spins up a
long-running side process (server, watcher, dashboard) the user must see.

**Lesson 3 — Inter-command handoffs are session transitions.** Recommending
`/stp:next-command` without `/clear` ignores that each STP phase fills the
context window with research, verification noise, and intermediate state
the next phase doesn't need. Always model handoffs as `(/clear, then
/stp:next)` so the next phase reads its inputs fresh from disk.

**Applies when:** any command's completion box recommends a follow-up STP
command. The convention is now in CLAUDE.md `## Key Rules` and enforced
across all `► Next:` blocks.

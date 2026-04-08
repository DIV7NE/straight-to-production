# Changelog

All notable changes to STP are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.5] — 2026-04-09 — fix: plugin CLAUDE.md section markers — v0.3.3/0.3.4 content can now sync into projects

### Summary

Every project onboarded with `/stp:new-project` — and every existing project that runs `/stp:upgrade` — reads its CLAUDE.md from the plugin's canonical CLAUDE.md via a section-sync mechanism. Sections are wrapped in `<!-- STP:stp-*:start -->` / `<!-- STP:stp-*:end -->` HTML comment markers; the upgrade engine replaces the content between matching marker pairs when the plugin ships new content.

**The problem:** `commands/new-project.md` documented nine marker pairs (`stp-header`, `stp-confirmation-gate`, `stp-philosophy`, `stp-plugins`, `stp-rules`, `stp-dirmap`, `stp-hooks`, `stp-effort`, `stp-output-format`) — but only **two** of those markers actually existed in plugin CLAUDE.md (`stp-confirmation-gate` and `stp-output-format`). The other seven sections were living in plugin CLAUDE.md without markers, so the sync engine could not find them and could not propagate their content.

**The consequence:** every project created or upgraded since v0.3.3 — when the filename contract and 16-gate hooks taxonomy were added to plugin CLAUDE.md — received a project CLAUDE.md missing those new rules. Projects stayed on whatever content their CLAUDE.md had when they were first created (or last touched a marker that happened to exist). Specifically, this meant v0.3.3's filename contract (blocking `.stp/explore-data.json`), v0.3.3's hot-reload warning, and v0.3.3's 16-gate hooks taxonomy never reached any real project that used `/stp:upgrade`.

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

- **`CLAUDE.md` `stp-rules` — exception clause for /clear after /stp:upgrade** — the existing "/clear suggested before every inter-command transition" rule now has an explicit exception: *"after `/stp:upgrade` when hook files changed, the recommendation is `/exit → run claude again → (optional) /clear` — because `/clear` alone does NOT reload hooks."* This keeps the two rules consistent and points readers at the Hooks section for the full explanation. Because this rule lives inside `stp-rules` which is now wrapped, the exception clause will also sync into projects on upgrade.

### Changed

- **`CLAUDE.md` `## What This Is` — version marker removed, canonical source cited** — the old text hardcoded "v0.3.0" which drifted with every release. New text instructs the reader to read the installed version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`. This prevents the `stp-header` block from going stale whenever the plugin version bumps.

### Fixed

- **v0.3.3 content never reached onboarded projects** — projects that ran `/stp:upgrade` between v0.3.3 and v0.3.4 saw the upgrade complete successfully but the new content (filename contract, hot-reload warning, 16-gate taxonomy) was not added to their CLAUDE.md. After v0.3.5, the next `/stp:upgrade` run on those projects will replace the contents of `stp-rules` and `stp-hooks` (and the 5 other newly-marked blocks) with the latest content from the plugin.
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
  - CHANGELOG.md entries for any v0.3.6+ release that adds content to plugin CLAUDE.md MUST indicate which marker block received the content (so downstream projects know what their next `/stp:upgrade` will refresh).

- **Dependencies created:**
  - `commands/new-project.md` Step 6 (project CLAUDE.md generation) now depends on the 9 markers being present in plugin CLAUDE.md. If future refactors remove a marker, the template's corresponding line must also be removed.
  - `commands/upgrade.md` Step 4 (project CLAUDE.md sync) iterates over whatever markers exist in plugin CLAUDE.md. It is tolerant of missing markers (just skips them) but now has 9 marker pairs to potentially update instead of 2.

### Deliberately NOT done

- **Marker validation CI check** — a 5-line script that confirms all 9 markers are present in plugin CLAUDE.md and that each marker pair is balanced. Useful for catching regressions, but this release already ships the fix; the CI check is a preventive follow-up, not part of the immediate patch.
- **Auto-migration of existing project CLAUDE.md files** — users who currently have a project CLAUDE.md without the 7 new markers will still only have those 2 markers. The `/stp:upgrade` Step 4 "legacy project CLAUDE.md" path handles this: if a marker is missing in the project, the upgrade appends it with the new content. This means the first `/stp:upgrade` after v0.3.5 on an existing project will ADD the 7 missing sections (not replace them). Users who manually edited those sections will see an append, not an overwrite — which is the safer default.

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

## [0.3.4] — 2026-04-09 — feat: `/stp:upgrade` surfaces restart-required banner + CHANGELOG-driven "what's new"

### Summary

v0.3.3 fixed the whiteboard-gate hallucination bug and added the hot-reload warning to CLAUDE.md, but the warning only helps users who happen to be reading CLAUDE.md. The `/stp:upgrade` command itself still ended with the old `► Next: /clear to load the new version` hint — which is **wrong**: `/clear` clears conversation context but does NOT reload hooks. After `/stp:upgrade`, users were following the displayed instruction, running `/clear`, and then wondering why the new hooks weren't firing. This is exactly the failure mode that caused the v0.3.2 post-mortem Bug 1 to hit a second time.

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

- **v0.3.3 upgrade UX gap** — v0.3.3 added the hot-reload warning to `CLAUDE.md` but the `/stp:upgrade` command itself still ended with `/clear` as the next step. Users reading the command output followed it literally, ran `/clear`, and then hit stale hooks without knowing why. This release closes that gap by making the upgrade command's output itself carry the restart instruction.

### Spec Delta

- **Added:**
  - `HOOK_CHANGED_FILES`, `HOOK_CHANGE_COUNT`, `HOOKS_JSON_CHANGED` metadata captured in Step 1 of `commands/upgrade.md`
  - CHANGELOG.md-driven extraction step for the "What's new" block
  - Two-variant restart banner (MANDATORY when hooks changed, Recommended otherwise)
  - Three-block completion output structure (checklist → what's new → restart)

- **Changed:**
  - `/stp:upgrade` completion semantics — was "show checklist, say /clear". Now "show checklist, show faithful CHANGELOG extract, show restart banner". The command is now self-sufficient for teaching the user the post-upgrade workflow.
  - The `► Next:` line convention after plugin upgrades — always includes exit+relaunch, never just `/clear` alone.

- **Constraints introduced:**
  - After `/stp:upgrade`, the completion output MUST include a restart banner (MANDATORY or Recommended variant, depending on hook changes). The banner MUST reference `/exit` and relaunching `claude`, not just `/clear`.
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

**v0.3.2 post-mortem** — the v0.3.2 enforcement layer shipped with three bugs that together recreated the v0.3.1 failure mode in a fresh form. A user ran `/stp:work-quick` and `/stp:whiteboard` back-to-back and hit all three:

**Bug 1 — Session 1 stale hooks.** Plugin cache `0.3.2` was only created 43 minutes after I committed v0.3.2 to source. Any Claude Code session started in that window loaded the pre-v0.3.2 hooks.json (no PreToolUse entries). The user's `/stp:work-quick` session had no ui-gate loaded, so it built the exact same AI-slop landing page that motivated the v0.3.2 release. **Root cause:** Claude Code loads hooks at session startup and does not hot-reload when source changes. This is a Claude Code limitation, not fixable in the plugin — but it was undocumented.

**Bug 2 — Whiteboard-gate matched only the canonical filename.** In Session 2, the user ran `/stp:whiteboard`. Claude wrote the data to `.stp/explore-data.json` (a pre-0.3.1 legacy name) instead of `.stp/whiteboard-data.json`. The whiteboard-gate hook checked only the canonical name — the wrong filename passed through as "not my problem" and exited 0. Data landed in a file the server does not watch. localhost:3333 stayed on `{"status": "Waiting..."}` for the entire session. The user was correct to say "it never deployed."

**Bug 3 — CHANGELOG.md teaching the wrong filename.** The v0.3.1 post-mortem CHANGELOG mentioned the legacy filename three times while explaining the old bug. With no counter-balancing filename contract in CLAUDE.md, Claude's context-read treated the legacy name as a valid alternative. The v0.3.2 CHANGELOG also inherited the references. **The documentation of a fixed bug was actively training the agent to reproduce it.**

Fixing this requires defense-in-depth across three layers: the hook must catch hallucinated names, CLAUDE.md must carry an always-loaded filename contract, and the CHANGELOG references must be defused so they read as negative examples instead of valid alternatives.

### Added

- **`CLAUDE.md` `## Key Rules` — Filename Contract** — new always-loaded rule pinning the whiteboard data file to the canonical `.stp/whiteboard-data.json` and explicitly naming four forbidden aliases (`.stp/explore-data.json`, `.stp/whiteboard.json`, `.stp/board-data.json`, `.stp/design-data.json`). The rule includes a loud "STOP" directive if the agent catches itself about to write a forbidden name and cites the post-mortem reason. Since CLAUDE.md is loaded on every session start, this becomes a hard context-level constraint that sits above training-data hallucination.
- **`CLAUDE.md` `## Hooks` — hot-reload warning** — explicit prose at the top of the section: *"Hooks load at Claude Code SESSION STARTUP, not hot-reload. After `/stp:upgrade` or any plugin update that adds or modifies hooks, you MUST exit Claude Code and restart it to pick up the new hooks. A running session keeps whatever hooks.json it loaded at launch."* Closes Bug 1 at the documentation layer (can't fix Claude Code itself, but users can now diagnose the "my hooks aren't firing" symptom).
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
  - Hot-reload warning in CLAUDE.md `## Hooks` — documents the "restart Claude Code after /stp:upgrade" requirement
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
  - After any `/stp:upgrade` that modifies hooks, the upgrade's completion message MUST instruct the user to restart Claude Code (follow-up task — not wired in this release).

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
STP's workflow rules were written as **suggestions in markdown** ("MUST", "MANDATORY", "this is required"). Claude routinely routed around them. The v0.3.1 post-mortem was a landing page shipped with every AI-slop tell the design system explicitly forbade: gradient headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand mark, template copy, center-everything layout. The `/ui-ux-pro-max` skill never fired. Step 1b of `/stp:work-quick` was labelled MANDATORY — and was pure markdown.

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
  - Features built under a `PLAN.md` (i.e., `/stp:work-full` territory) MUST run `/stp:review` before Claude can stop. The Critic can no longer be silently skipped.
  - UI features (identified by the presence of the `ui-gate-passed` marker) MUST have a QA report before Claude can stop. agent-browser QA can no longer be silently skipped.
  - All completed features SHOULD emit a `### Spec Delta` block in CHANGELOG.md and touch ARCHITECTURE.md (Gate 11 warns but does not block).

- **Dependencies created:**
  - `ui-gate.sh` depends on `.stp/state/ui-gate-passed` marker contract. `SessionStart` hook is now responsible for wiping it.
  - `whiteboard-gate.sh` depends on `start-whiteboard.sh` being at `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh` and being executable.
  - `stop-verify.sh` Gates 12/13 depend on filename contracts: `.stp/state/critic-report-*.md` and `.stp/state/qa-report-*.md`. Any command that wants to satisfy the gate writes a file matching those globs newer than `current-feature.md`.
  - `commands/work-quick.md` and `commands/work-full.md` now explicitly depend on `hooks/scripts/ui-gate.sh` for the "mandatory" label to have teeth. The doc references the hook by path so future refactors know they're coupled.

### Deliberately NOT done

- **Pre-work `AskUserQuestion` gate** (audit gap #2) — deferred. Risk of false-triggering on `/stp:continue`, `/stp:resume`, `/stp:autopilot` flows without careful session-scoped carve-outs. Will revisit once the session-ID primitive is more accessible from hooks.
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
any user invoking `/stp:whiteboard`:

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
   saw nothing. The command is literally named `/stp:whiteboard`; a whiteboard
   the user can't see is a broken command.

3. **No `/clear` in handoffs.** Completion boxes recommended `/stp:work-quick`,
   `/stp:plan`, etc. as next steps but never told the user to `/clear` first.
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
  at the top of every `/stp:whiteboard` invocation. No AskUserQuestion gate,
  no "if they accept" branch.
- `commands/plan.md` — same pattern. Server starts at the top of every
  `/stp:plan` invocation.
- `commands/work-full.md` — UI/UX branch (line 263) reordered: server starts
  BEFORE the design system is generated, never after. Step numbering
  adjusted (4 → 5 for the persist step).
- `commands/work-quick.md` — UI/UX branch (line 101) reordered the same way.

**/clear in next-step handoffs:**
- `commands/whiteboard.md` — final completion box now recommends
  "1. /clear, 2. then ONE of: /stp:work-full | /stp:work-quick | /stp:work-adaptive"
- `commands/plan.md` — `► Next: /clear, then /stp:work-quick [FIRST FEATURE]`
- `commands/new-project.md` — `► Next: /clear, then /stp:plan`
- `commands/review.md` — `► Next: /clear, then /stp:work-quick [NEXT FEATURE]`
- `commands/work-quick.md` — both completion boxes (next feature, next
  milestone) prepend `/clear, then`

**Project conventions added (so this can't regress):**
- `CLAUDE.md` — two new entries in `## Key Rules`:
  1. Whiteboard server start is mandatory + first for `/stp:whiteboard` and
     `/stp:plan`; never gated behind AskUserQuestion or "if they accept".
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
    `/stp:whiteboard` and `/stp:plan`.
  - `/clear` recommendation before every inter-command transition in
    completion boxes across new-project, plan, whiteboard, work-quick,
    review.
  - Two new entries in CLAUDE.md `## Key Rules` enforcing the above.
- **Changed:**
  - Canonical whiteboard data filename is `.stp/whiteboard-data.json`
    (was ambiguously a different legacy name in some pre-0.3.1 command docs —
    that legacy name is now FORBIDDEN and blocked by the v0.3.3 whiteboard-gate
    hook; do NOT reference it).
  - The whiteboard offer is no longer modeled as opt-in for `/stp:whiteboard`
    and `/stp:plan` — it is the literal first action.
  - In `/stp:work-quick` and `/stp:work-full` UI/UX branches, the server
    starts BEFORE design system generation, not after.
- **Constraints introduced:**
  - Any future command that writes live whiteboard data MUST use
    `.stp/whiteboard-data.json`. Single source of truth between producer
    (command agent) and consumer (`whiteboard/serve.py`).
  - The whiteboard server MUST start as the first action of any command
    whose primary purpose is whiteboarding (`/stp:whiteboard`, `/stp:plan`).
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
declares its primary purpose (`/stp:whiteboard`, `/stp:debug`, `/stp:plan`),
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

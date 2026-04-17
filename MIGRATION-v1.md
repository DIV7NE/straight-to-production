# Migration — pre-v1 → v1.0

STP v1.0 is a hard cutover. Command names changed, profile names changed, and the skill layout collapsed from 18 dirs into 6. This document describes what changed, what happens automatically, and what (if anything) you need to do by hand.

## TL;DR

Run `/stp:setup upgrade` once after pulling v1.0. The migration script runs automatically on the next SessionStart. After that, use the new command names.

```
/plugin install stp@stp     # pull v1.0
# (restart Claude Code so hooks reload)
/stp:setup upgrade          # regenerate agents, refresh hook manifests
```

Legacy profile names are renamed automatically by `hooks/scripts/migrate-v1.sh` on the next SessionStart. The script is idempotent — it's safe to run every session.

## What's automatic

### 1. Profile name migration

`migrate-v1.sh` runs at SessionStart and rewrites `.stp/state/profile.json` if it holds a legacy name:

| Pre-v1 name | v1 name |
|-------------|---------|
| `intended-profile` | `opus-cto` |
| `balanced-profile` | `balanced` |
| `budget-profile` | `opus-budget` |
| `sonnet-main` | `sonnet-cheap` |
| `20-pro-plan` | `pro-plan` |

The resolver (`references/model-profiles.cjs`) also accepts the legacy names during the grace period, so nothing breaks if migration hasn't run yet on a specific machine.

### 2. Layout migration

`migrate-layout.sh` (pre-existing from v0.3.x) runs alongside `migrate-v1.sh` and handles any projects still using the pre-v0.3 flat layout — docs at project root, state files mixed in. It moves them into `.stp/docs/` and `.stp/state/` respectively.

### 3. Stack detection

`detect-stack.sh` runs at SessionStart if `.stp/state/stack.json` is missing or older than 24 hours. First run after upgrade will produce it. The hooks that check stack (UI gate, anti-slop, stop-verify) all handle a missing stack.json gracefully — they fall back to the v0 behavior (run every check).

### 4. Agent regeneration

`/stp:setup upgrade` runs `regenerate-agents.sh`, which rewrites `agents/*.md` from `references/agents/*.md.template` using the resolved profile models. Necessary because agent files are committed with resolved models, not placeholders.

### 5. SessionStart hook chain

The hook chain adds `migrate-v1.sh` and `detect-stack.sh` between `migrate-layout.sh` and `session-restore.sh`. Timeout is raised from 15 seconds to 20. All recent Claude Code versions handle this fine.

## What you need to change by hand

### Command names

All 18 pre-v1 commands are gone. Use the v1 skills:

| Pre-v1 command | v1 equivalent |
|----------------|---------------|
| `/stp:welcome` | `/stp:setup welcome` (or `/stp:setup` — `welcome` is the default) |
| `/stp:new-project` | `/stp:setup new` |
| `/stp:onboard-existing` | `/stp:setup onboard` |
| `/stp:set-profile-model` | `/stp:setup model` |
| `/stp:upgrade` | `/stp:setup upgrade` |
| `/stp:whiteboard` | `/stp:think --whiteboard` |
| `/stp:plan` | `/stp:think --plan` |
| `/stp:research` | `/stp:think --research` |
| (new) free-form brainstorming | `/stp:think` (no flag — default mode) |
| `/stp:work-quick` | `/stp:build --quick` |
| `/stp:work-full` | `/stp:build --full` |
| `/stp:work-adaptive` | `/stp:build` (no flag — auto-routes) |
| `/stp:autopilot` | `/stp:build --auto` |
| `/stp:debug` | `/stp:debug` (unchanged) |
| `/stp:review` | `/stp:review` (unchanged) |
| `/stp:progress` | `/stp:session progress` |
| `/stp:continue` | `/stp:session continue` |
| `/stp:pause` | `/stp:session pause` |
| `/stp:codebase-mapping` | Absorbed into `/stp:setup onboard` |

**No aliases.** Typing an old command name will fail — Claude Code doesn't have registered skills matching those names anymore. This is intentional (hard cutover = less ambiguity, cleaner docs, no silent drift).

### Notes in CLAUDE.md / docs

If you've got project-specific notes in your `CLAUDE.md` or other docs referencing old command names, update them. The v1 skill names are the canonical ones now.

Grep your project for old names:

```
grep -rnE '/stp:(welcome|new-project|onboard-existing|set-profile-model|upgrade|whiteboard|plan|research|work-quick|work-full|work-adaptive|autopilot|progress|continue|pause|codebase-mapping)\b' .
```

Common replacements land in under 15 minutes for a normal project.

### Project memory

Your `.stp/docs/*` files are unchanged. PRD.md, PLAN.md, ARCHITECTURE.md, CHANGELOG.md, AUDIT.md, CONTEXT.md — all carry over as-is. v1.0 reads and writes the same structure.

### Design system

`design-system/MASTER.md` is unchanged. `/stp:build` still reads it on UI stacks. Non-UI stacks (detected via `stack.json`) skip design-system loading entirely — that's new behavior, but it's strictly additive (nothing that worked before stops working).

## New concepts you should know about

### 1. Pace dial

`/stp:setup pace` sets how much STP asks you before acting. Default is `batched` (up to 4 questions per AskUserQuestion call). If you liked the section-by-section feel pre-v1, switch to `deep`:

```
/stp:setup pace
# pick: deep
```

### 2. Stack awareness

If you're on a non-web stack (Rust, C++, C#, Python CLI, etc.), v1.0 behaves better than v0.5 did:
- UI gate doesn't fire on new source files
- Anti-slop scanner skips (its patterns are tuned for frontend code)
- Type check uses the stack's real compiler (cargo check, tsc, mypy, cmake, dotnet, go vet)
- Test runner uses the stack's convention (cargo test, pytest, vitest, ctest, dotnet test, go test)

Check what STP detected:

```
cat .stp/state/stack.json
```

If it's wrong, edit the file by hand or run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-stack.sh" --force` to re-run detection.

### 3. Opus 4.7 idioms

v1.0 targets Opus 4.7 as the default planning model. Every sub-agent spawn carries the `<use_parallel_tool_calls>` XML block and the context-limit prompt. The Critic always gets the INVERSION framing. You don't do anything — it's automatic — but your agents will feel snappier and the Critic will catch more issues.

### 4. Profile matrix expanded

Two new profiles:

- **`sonnet-turbo`** — Sonnet 4.6 @ xhigh as main and all sub-agents. ~25% the cost of `opus-cto` for most work. Pick this if you're on Claude Pro without heavy Opus quota, or if you want fast iteration without Opus latency.
- **`pro-plan`** — Sonnet 4.6 @ high, NO sub-agents, deterministic verification only. Hard caps: 30 messages/feature, 80 messages/5h. Built for Claude Pro subscribers who hit the 20-message 5h limit.

Switch anytime:

```
/stp:setup model
```

## Rollback

If v1.0 breaks something for you:

```
# Pin to the last v0 release
/plugin install stp@stp --version 0.5.11
```

Pre-v1 profile names still work if you roll back — `migrate-v1.sh` renaming is one-way but the pre-v1 commands all read `profile.json` via the resolver, and the resolver accepts both name sets.

Please file an issue at [github.com/DIV7NE/straight-to-production/issues](https://github.com/DIV7NE/straight-to-production/issues) if you have to roll back. v1.0 is meant to be strictly better and we want to fix whatever's wrong.

## FAQ

**Q: Do I have to run `/stp:setup welcome` again?**
No. Your existing profile, state, and docs carry over. The migration is transparent.

**Q: Will my CI / automation scripts break?**
Yes if they reference old command names. Update references to v1 skill names (see the table above).

**Q: Can I opt out of stack detection?**
Delete `.stp/state/stack.json` and add `STP_STACK=generic` to your shell environment. Hooks will fall back to running every check.

**Q: Can I opt out of the pace dial?**
The default (`batched`) behaves very close to pre-v1 — the AskUserQuestion gates are still phase-transition-based. If that's still too curious for you, switch to `fast` or `autonomous`.

**Q: What about the whiteboard?**
Still works. `/stp:think --whiteboard` starts the server and opens the UI in your browser, same as the old `/stp:whiteboard`. The canonical filename contract (`.stp/whiteboard-data.json`) is unchanged.

**Q: Are there any changes to project docs on disk?**
No. PRD.md, PLAN.md, ARCHITECTURE.md, CHANGELOG.md, AUDIT.md all use the same format. Spec Deltas in CHANGELOG are unchanged. System Constraints in PRD.md are unchanged. Project Conventions in CLAUDE.md are unchanged.

**Q: I'm on Windows and the migration script errors with "bash: command not found".**
Run from inside Claude Code — bash runs via Git Bash (bundled with Git for Windows) or WSL. If neither is installed, install Git for Windows from [git-scm.com](https://git-scm.com/download/win).

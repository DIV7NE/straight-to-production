# Multi-Window Workflow (Canonical — v1.0)

**Read when** you want to parallelize work across concurrent Claude Code sessions — or when a single session is hitting context pressure and splitting the work is cheaper than compacting.

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices · https://claude.com/blog/using-claude-code-session-management-and-1m-context

---

## The pattern

**First window** = setup window. Writes:
- `tests/` — acceptance tests + behavioral tests for the feature
- `.stp/state/current-feature.md` — spec, test cases, acceptance criteria
- Scripts and fixtures the build will need

**Concurrent window(s)** = build window(s). Reads from disk:
- `.stp/state/current-feature.md` to know what to build
- `tests/*` to know when done
- `.stp/docs/CHANGELOG.md` + `ARCHITECTURE.md` for patterns

No window holds the other's context in memory. **Disk is the source of truth.** Windows communicate only through files.

---

## Why this beats cramming

A single 200K session that holds both the planning phase and the building phase inevitably rots — the architectural discussion at turn 3 competes with the test output at turn 97 for attention. Splitting them gives each window a tight context:

- Setup window stays focused on requirements + test design
- Build window stays focused on code generation, reading tests as the spec

When build window finishes, the setup window — still fresh in context — reviews the diff. Feedback is crisp because the reviewer hasn't been through the building pain.

---

## Mechanical setup

1. **Open first window** (setup). Run `/stp:think --plan` + `/stp:build --quick` up to the "write tests" step.
2. Commit: `.stp/state/current-feature.md` + `tests/*`.
3. **Open second window** (build) — fresh Claude Code session in the same repo. Run `/stp:build` — it reads the feature spec + test files from disk and implements.
4. **Back to first window**: run `/stp:review` on the diff.

Three separate windows, three clean contexts, one coherent feature.

---

## STP hooks that make this work

- **PreCompact hook** (`hooks/scripts/pre-compact-save.sh`) dumps state to `.stp/state/state.json` before Claude Code autocompacts. Either window can read it back.
- **SessionStart hook** (`hooks/scripts/session-restore.sh`) auto-reads `.stp/state/handoff.md` + `current-feature.md` on fresh session start.
- **Stop hook** (`hooks/scripts/stop-verify.sh`) enforces "tests exist before main work closes" — stops you from committing code ahead of the spec window.

---

## When NOT to multi-window

- Tiny fix (< 3 files, no new tests) — overhead not worth it
- Quick exploration — session closure between windows kills the debugging flow
- You're solo on one monitor and context-switching is expensive for YOU

The win is when the task has phases (design → implement → review) and each phase benefits from a fresh context. Not when the task is one tight loop.

---

## Extreme-context variant (opus-cto profile)

If you're on `opus-cto` (Opus 4.7 with 1M context), you can hold multi-phase work in ONE window. 1M absorbs the planning → implementation → review arc without context pressure.

But:
- Attention still rots. 800K of accumulated tool output burns quality at the edges.
- Cost per token is high. One 1M session costs more than three 200K sessions with filesystem handoff.
- If you `/clear` between phases even on opus-cto (STP's default recommendation), you get the best of both: multi-phase coherence + clean context per phase.

`opus-cto` is a bigger hammer, not a substitute for pause+clear+continue.

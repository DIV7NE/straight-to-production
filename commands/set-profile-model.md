---
description: Switch STP between intended-profile (Opus 1M main + Sonnet sub-agents, original STP architecture), balanced-profile (Opus plans + Sonnet executes/verifies + mandatory researcher/explorer sub-agents), or budget-profile (Sonnet writes + Haiku verifies with Sonnet escalation, strict context discipline). Pass the profile name as an argument or invoke with no args for the picker.
argument-hint: <intended | balanced | budget>  (or no arg for interactive picker)
allowed-tools: ["Bash", "Read", "AskUserQuestion"]
model: haiku
---

> **Recommended effort: `/effort low`** — Mechanical state-file write + visual confirmation.

# STP: Set Profile Model

Pick the optimization profile for this project. The active profile determines which Claude model is spawned for each STP sub-agent (`stp-executor`, `stp-qa`, `stp-critic`, `stp-researcher`, `stp-explorer`). The setting is saved to `.stp/state/profile.json` and read by every other STP command before spawning sub-agents.

## Profile Summary

| Profile | stp-executor | stp-qa | stp-critic | stp-researcher | stp-explorer | Discipline |
|---|---|---|---|---|---|---|
| **intended-profile** | sonnet | sonnet | sonnet | inline | inline | recommended |
| **balanced-profile** (default) | sonnet | sonnet | sonnet | sonnet (sub) | sonnet (sub) | mandatory |
| **budget-profile** | sonnet | sonnet | haiku → sonnet escalation | sonnet (sub) | sonnet (sub) | enforced |
| **sonnet-main** | sonnet | haiku | haiku → sonnet escalation | sonnet (sub) | sonnet (sub) | enforced |

- **sonnet / opus / haiku** — pass the literal value as the spawn `model=` parameter
- **inline** — no sub-agent spawned; main session does the work directly (intended-profile only, because Opus 1M can absorb research/exploration inline)
- **(sub)** — fresh sub-agent with isolated context; returns ≤30 line summary
- **inherit** — sentinel for future profiles or non-Anthropic runtimes (Codex, OpenCode, Gemini CLI); not used by any current profile because STP intentionally uses Sonnet sub-agents even when main is Opus for cost reasons

See `${CLAUDE_PLUGIN_ROOT}/references/profiles.md` for the full profile documentation, trade-off tables, and example workflows.

## Process

**If the user passed a profile name as `$ARGUMENTS` (e.g. `/stp:set-profile-model balanced`)**, run this single command and show its output verbatim — no extra commentary, no AskUserQuestion picker. **IMPORTANT: always quote `$ARGUMENTS` to prevent shell injection** — if the user's input contains shell metacharacters, an unquoted expansion would let them run arbitrary commands:

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set "$ARGUMENTS" --raw
```

**If `$ARGUMENTS` is empty**, first read the current profile and present a picker via `AskUserQuestion`:

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current
```

Then call `AskUserQuestion` with three options. Mark the currently active profile with `(Current)` and `intended-profile` with `(Recommended)`. Place the recommended option first.

```
AskUserQuestion(
  question: "Which optimization profile should STP use for this project? Profiles control which Claude model runs each STP sub-agent.",
  header: "Profile",
  options: [
    {
      label: "intended-profile (Recommended)",
      description: "Original STP architecture — byte-identical to pre-0.3.8 behavior. Main session = whatever Claude Code is running (Opus 1M recommended). Sub-agents (stp-executor, stp-qa, stp-critic) all spawn with model='sonnet' for cost reasons. Researcher/explorer run INLINE in main session (no sub-agent) because Opus 1M absorbs them without context pressure. Light context discipline. Zero behavior change on upgrade."
    },
    {
      label: "balanced-profile",
      description: "Opus for planning, Sonnet for execution + verification. All sub-agents = sonnet (consistent regardless of main session). Mandatory researcher/explorer sub-agents to keep main session lean. ~50-65% cost savings vs intended."
    },
    {
      label: "budget-profile",
      description: "Sonnet for everything except Critic. Critic = Haiku 4.5 first pass; auto-escalates to Sonnet on ≥2 critical issues. Strict context discipline (mandatory researcher/explorer, hard-block on >50 line ops). ~80% cost savings, leans on Layers 1-4 deterministic verification to compensate."
    }
  ]
)
```

After the user picks, run the same command with `--raw` and show its output verbatim:

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <picked-profile> --raw
```

**Optional walkthrough.** After the profile is set, ask if the user wants a walkthrough of how the new profile changes STP's behavior:

```
AskUserQuestion(
  question: "Want a quick walkthrough of how this profile changes STP's behavior? Useful if you just switched to balanced or budget — explains the new context discipline rules.",
  header: "Walkthrough",
  options: [
    {
      label: "(Recommended) Yes, walk me through it",
      description: "I'll explain: (1) which sub-agents fire and when, (2) /clear discipline, (3) the new researcher/explorer sub-agents, (4) cost vs quality trade-offs."
    },
    {
      label: "No, I know what I'm doing",
      description: "Skip the walkthrough. Just confirm and exit."
    },
    {
      label: "Show me the trade-off table only",
      description: "Print all 3 profile tables side-by-side and exit."
    }
  ]
)
```

- **Yes, walk me through it** → Read `${CLAUDE_PLUGIN_ROOT}/references/profiles.md` and present a 5-bullet summary of what changed.
- **Show the trade-off table** → Run `node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" all-tables`
- **No** → Print one line: `► Profile active. Run any /stp:* command to use the new model mapping.`

## Why It's This Simple

The heavy lifting lives in `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs` — a single Node.js file that's the canonical mapping table, the resolver, the writer, and the CLI. STP commands and hooks call it the same way GSD's `/gsd:set-profile` calls `gsd-tools.cjs`. This pattern works reliably because:

1. **Single source of truth** — the agent → profile → model table lives in exactly one file. No drift between docs and runtime.
2. **CLI-driven** — every consumer (commands, hooks, statusline) calls the same `node model-profiles.cjs <verb>` interface. No bash parsing of JSON.
3. **`inherit` sentinel** — opus-tier agents return `"inherit"` so spawn calls omit the model parameter and let the parent session's model take over. This works on any runtime (Opus, Sonnet, Codex, OpenCode, Gemini CLI).
4. **Adding a profile = adding a column** — extend `MODEL_PROFILES` in the cjs file. No other changes needed anywhere in STP.

Inspired by [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)'s `/gsd:set-profile` which uses the same architecture.

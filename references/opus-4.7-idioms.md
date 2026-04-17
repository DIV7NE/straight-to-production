# Opus 4.7 Prompt Idioms (Canonical — v1.0)

**Read this before spawning any agent or writing any system prompt.** Every STP skill references this file. When the Opus 4.7 behavior changes, update this file once and every skill inherits the fix.

Source: https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code · https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

---

## 1. Effort level defaults

Opus 4.7 introduced `xhigh` as the new default for coding/agentic work. `max` now shows diminishing returns and an overthinking risk. Use:

- `xhigh` — default for `/stp:build`, `/stp:think`, `/stp:debug`, `/stp:review`
- `max` — reserve for novel architecture / PRD crafting / hardest planning only
- `high` — `/stp:session continue`/`pause`/`progress`, `/stp:setup`
- `medium` — autopilot status updates, routine reads
- `low` — statusline, health checks

Do not set `max` "to be safe." Set `xhigh` and escalate only when the task genuinely warrants it.

## 2. Parallel tool calls — mandatory XML block

Every executor/subagent system prompt MUST include this block verbatim:

```xml
<use_parallel_tool_calls>
Send independent tool calls in the SAME message, not sequentially. Dependent calls go sequentially only when a later call consumes an earlier call's output.

Parallel-eligible examples:
- Reading multiple files you already know the paths of
- Running Glob and Grep on unrelated patterns
- Fan-out of subagents across independent features
- Multiple bash commands that don't share state

Sequential-required examples:
- Read a file, then edit that same file
- Grep for a symbol, then filter the results
- Run a test, then read its output
</use_parallel_tool_calls>
```

Anthropic measured this as going from ~random to ~100% parallel-call reliability on 4.6+. Free performance win.

## 3. Context-limit discipline

Every long-running subagent (executor, critic, qa, researcher, explorer) opens with:

> *Your context window auto-compacts as it fills. Do not stop tasks early due to token-budget concerns. Continue until the task is complete or you hit an actual blocker. If you're uncertain whether you have budget, continue — compaction will handle it.*

Without this line, Opus 4.7 wraps up work prematurely near the limit.

## 4. Adaptive thinking (replaces `budget_tokens`)

`budget_tokens` is deprecated. Errors on Mythos Preview. Use:

```
thinking: { type: "adaptive" }
```

Effort parameter (`xhigh`/`max`/etc.) now controls thinking depth. Migration: remove all `budget_tokens` references from spawn configs and system prompts.

## 5. max_tokens floor for Opus 4.7

When spawning Opus 4.7 subagents at `xhigh` or `max`:

```
max_tokens: 64000
```

Below 64k, you starve the thinking + tool-call budget and the model truncates. Never go below 32k for Opus 4.7 subagents.

## 6. Prefill is deprecated

Never prefill the assistant turn on Claude 4.6+. Returns 400 on Mythos Preview. Replace with:
- Structured outputs (JSON schema)
- XML tags in the system prompt (`<output_format>...</output_format>`)
- Explicit system-prompt instructions about format

## 7. Critic inversion — MANDATORY

**Old (broken on 4.7):** *"Report only high-severity issues. Filter out noise."*
**New:** *"Report every issue you find, including low-severity, uncertain, and potentially-false-positive findings. A downstream filter ranks severity. Your job is recall, not precision."*

Opus 4.7 follows "high-severity only" too faithfully and silently drops real bugs. Inversion restores recall. Applied in: `agents/critic.md`, `skills/review/`, any skill that asks for code review output.

## 8. Tool-trigger language — normalize

Remove ALLCAPS "CRITICAL: MUST use X", "YOU MUST CALL Y", etc. On 4.6+ these cause overtriggering (model invokes tools even when inappropriate). Normalize to:

- ❌ "CRITICAL: MUST use /ui-ux-pro-max first"
- ✅ "Use /ui-ux-pro-max when the task involves UI/UX code"

Keep the rule. Drop the scream.

## 9. Explicit rule scope

Opus 4.7 is more literal than 4.6 — it no longer silently generalizes a rule from one item to all. State scope explicitly:

- ❌ "Validate the input"
- ✅ "Validate every field in the input, not just the first one"

- ❌ "Update the docs"
- ✅ "Update every doc that references this function, not only the top-level README"

If you want a rule applied universally, say "universally" or "to every X". If scoped, name the scope.

## 10. Long-context document order

Put reference documents ABOVE the user query, not below. Measured ~30% quality improvement for multi-document inputs.

Pattern:
```
<system>
<reference_docs>
[PRD.md content]
[PLAN.md content]
[ARCHITECTURE.md content]
</reference_docs>

<task>
[actual query]
</task>
</system>
```

---

## Enforcement

- Every agent file (`agents/*.md`) has a `## Opus 4.7 Idioms` section that bakes in idioms 2, 3, 7, 8, 9.
- Every skill file (`skills/*/SKILL.md`) opens with: *"Before spawning any agent: read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`."*
- `stp-critic` gets idiom 7 inversion in its system prompt AND the spawn prompt double-enforces it.
- When a new Opus version ships, update this file only. Run `hooks/scripts/regenerate-agents.sh` to propagate idiom changes into agent frontmatter where needed.

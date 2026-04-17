# Session Management & Long-Context Workflow (Canonical — v1.0)

**Read this when you hit 40% context, when the user says "how do I continue this tomorrow", or when an approach went sideways mid-session.**

Source: https://claude.com/blog/using-claude-code-session-management-and-1m-context

---

## The three primitives

Claude Code gives you three ways to reset session state. Each is right for a different situation.

### `/rewind` (keyboard: Esc Esc)

Jumps back to a prior message in the current session and re-prompts from that point. The messages you skip over are discarded.

**Use when:**
- You tried an approach, it failed, and you want to restart from before the bad attempt — without the failed attempt polluting context
- The conversation took a wrong turn 3 messages ago and you want a clean do-over
- You got a long tool result you didn't need and want it gone

**Don't use when:**
- You've already committed code based on the messages you're rewinding over (the code stays; the conversation about it doesn't)
- You want to keep both branches of the conversation for comparison — rewind is destructive

### `/compact`

Model-driven summarization. Claude writes a summary of the conversation, then the full history is replaced with that summary.

**Use when:**
- Session was tool-heavy (lots of file reads, grep output, bash results)
- You'll keep working on the same task
- You don't need the exact phrasing of earlier messages, just the conclusions

**Don't use when:**
- Session was prose-heavy (architectural discussion, PRD negotiation) — summarization loses fidelity exactly where you need it
- Autocompact is already imminent (Claude's self-summarization under pressure is often bad)

### `/clear`

Wipe the session and start fresh. Higher fidelity than compact because YOU control what survives (via `/stp:session pause` writing `.stp/state/handoff.md` first).

**Use when:**
- Starting a genuinely new task
- Prose-heavy session is getting bloated
- Autocompact is about to fire and you want control over what context survives

**STP pattern:** always `/stp:session pause` → `/clear` → `/stp:session continue`. Pause writes `.stp/state/handoff.md` with exactly what the next session needs. Continue reads it back.

---

## The critical failure mode: autocompact

When context fills, Claude Code autocompacts automatically. This fires at peak context rot — the worst moment for the model to self-summarize, because recent messages are competing for the model's attention with the oldest. Autocompact summaries drop load-bearing details.

**Prevent it:** take manual control before you hit the cliff.

| Context % | Action |
|---|---|
| 0–40% | Silent. Work normally. |
| 40–70% | Consider `/compact` (tool-heavy) or `/clear + continue` (prose-heavy). |
| 70–90% | Save state now: `/stp:session pause` → `/clear` → `/stp:session continue`. |
| 90%+ | Pause immediately. Autocompact is imminent and will be bad. |

STP's statusline (`hooks/scripts/stp-statusline.js`) shows these nudges automatically at threshold crossings.

---

## 1M context ≠ unlimited context

Opus 4.7 supports 1M tokens (`opus-cto` profile). It does not eliminate context rot. Attention quality still degrades as older irrelevant content accumulates.

**Use 1M for:**
- Single long task where you want every file in one session
- Analysis of a large codebase
- Long-running autopilot work where compaction would lose state

**Don't use 1M for:**
- Holding unrelated tasks open
- "Just in case I need it later" — fresh sessions are cheaper and cleaner
- Avoiding learning `/stp:session pause`

If you're hitting 800k+ regularly, you're not using session management — you're accumulating. Pause.

---

## Multi-window workflow

See `references/multi-window-workflow.md` for the concurrent-session pattern: first window writes tests + setup, second window iterates against filesystem state. Disk is the source of truth; neither window relies on the other's context.

---

## Subagent litmus test

When deciding whether to delegate to a subagent, ask: *"Will I need this tool output verbatim again, or just the conclusion?"*

- **Conclusion only** → delegate. Subagent does the work in isolation; only the summary returns to parent context.
- **Verbatim needed** → keep it inline.

Examples:
- "What files use this function?" → conclusion only → `stp-explorer`
- "What does this test do?" → verbatim → inline Read
- "What's in the Stripe docs?" → conclusion only → `stp-researcher`
- "What does my current `auth.ts` look like?" → verbatim → inline Read

---

## Where to intervene

- **Within a session, wrong turn:** `/rewind` (Esc Esc)
- **Within a session, getting full:** `/compact` (tool-heavy) or pause+clear+continue (prose-heavy)
- **Task changing:** `/stp:session pause` → `/clear` → work on new task
- **Multi-day pause:** `/stp:session pause` before closing Claude
- **Stuck or confused:** start a fresh session, read `.stp/state/handoff.md` and `.stp/docs/CHANGELOG.md`

# Pace Picker — Curiosity Dial (v1.0)

**What this is:** STP's curiosity dial. Controls how many AskUserQuestion gates you hit between idea and code. Chosen by the user per project, stored in `.stp/state/pace.json`, overridable per-command with a flag.

---

## The four paces

| Pace | AskUserQuestion frequency | Design sections | Best for |
|---|---|---|---|
| `deep` | One question per decision, one at a time | 200-300 word sections, validated after each | Novel architecture, security-critical work, any time you want rigor |
| `batched` (default) | Up to 4 questions per AskUserQuestion call | Full section presented, multi-question validation | Daily-driver — most features |
| `fast` | One plan, one approval, execute | Full plan in one message | Well-understood tasks, repeat patterns |
| `autonomous` | Zero questions after initial spec | No sections — just do it | Autopilot, overnight work, fully-specced tasks |

**Default:** `batched`. User picks during `/stp:setup welcome` or first `/stp:think` call.

---

## Per-command defaults

Certain commands auto-escalate pace regardless of setting:

- `/stp:think --plan` — always at least `batched` (architecture decisions benefit from validation)
- `/stp:build` touching auth/payments/models/migrations — auto-escalates to at least `batched`
- `/stp:debug` — stays at setting (root cause analysis doesn't need UI-level confirmation)
- `/stp:setup new` — always `deep` on first run (PRD crafting needs every decision caught)
- `/stp:review` — stays at setting
- `/stp:autopilot` equivalent (`/stp:build --auto`) — always `autonomous`

Rationale: pace shouldn't override safety. Auth, payments, schema changes warrant ceremony regardless of user preference.

---

## Per-call overrides

Every STP command accepts `--pace=<deep|batched|fast|autonomous>` to override for one call. Example: `/stp:build auth --pace=deep` forces section-by-section even if project default is `fast`.

---

## Storage format

`.stp/state/pace.json`:
```json
{
  "pace": "batched",
  "set_at": "2026-04-17T...",
  "set_by": "/stp:setup"
}
```

Missing file → default `batched`.

---

## How skills read pace

In skill bodies:

```bash
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo batched)

case "$PACE" in
  deep)       # section-by-section AskUserQuestion loop
  batched)    # up to 4 questions per call, still structured
  fast)       # present full plan once, one approval gate
  autonomous) # skip gates; pre-authorized scope only
esac
```

Every skill opens by reading pace. The skill body then branches on it. Deep mode uses the brainstorming-style loop (one question, 200-300 word sections). Batched uses AskUserQuestion's max-4-questions capacity. Fast presents the full plan in one message + single AskUserQuestion approval. Autonomous skips straight to execution.

---

## When to pick which

- **Deep:** "I'm designing something novel," "this is security-critical," "I want to learn by being walked through it."
- **Batched:** "I know what I want, but I'd like to catch decisions I hadn't considered." — the sweet spot for most work.
- **Fast:** "I've done this 10 times, just write the plan and let me approve." — fits monorepo refactors, repeated feature shapes.
- **Autonomous:** "Run overnight; I'll review the diff in the morning." — matches old `/stp:autopilot` flow.

---

## Changing pace mid-project

Run `/stp:setup pace` to switch. Takes effect on the next command. The safety auto-escalation rules (auth/payments/schema) still apply regardless.

---

## Philosophical note

The pace dial respects user agency without compromising production safety. You can choose less ceremony for trivial work — but STP still forces ceremony where mistakes are expensive. **Constraints beat prompts**; pace is preference, safety is constraint.

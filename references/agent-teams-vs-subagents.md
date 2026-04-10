# Agent Teams vs Subagents (STP cost + fit guidance)

STP defaults to **one-shot subagents (Task tool)**, not Agent Teams. Research (alexop.dev, laozhang.ai, verdent.ai citing Anthropic docs, 2026) puts the cost delta at ~3–4× for equivalent parallel throughput:

| Mode | Token cost vs single session | Notes |
|---|---|---|
| One-shot subagent (Task tool) | ~1.5–2× | Scoped prompt → result → terminate. Fresh context per spawn. |
| Agent Team (TeamCreate + SendMessage) | ~5–7× | Each teammate holds a full context window; coordination + messages replicated across workers. |

Cost is context-window-based (not idle/time). A 3-agent team for ~1 hour ≈ a full day of single-agent tokens. Agent Teams still require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` per the sources checked.

**Benefits — Agent Teams:** direct teammate-to-teammate SendMessage (no orchestrator bottleneck), shared TaskCreate/TaskUpdate queue for self-assignment, workers can negotiate mid-build (e.g. frontend ↔ backend debating an API shape), very high ceiling (Anthropic ran 16 parallel agents on a 100K-line Rust C compiler internally).

**Benefits — regular subagents:** 3–4× cheaper for the same parallel throughput, fresh context per spawn (no accumulation), isolated failures (one bad spawn can't poison siblings), simpler lifecycle (no TeamCreate/TeamDelete, no message routing), results return summarized rather than replicated into N contexts.

## STP flow → mode mapping (authoritative)

| STP flow | Use | Why |
|---|---|---|
| `/stp:work-full` build → QA → Critic | **Subagents** | Sequential, each reads prior output from disk via `.stp/state/` — zero cross-talk needed |
| `/stp:work-full` parallel waves (independent features) | **Subagents** | Wave members are intentionally independent; worktree isolation assumes no mid-build negotiation |
| `/stp:research` + `stp-researcher` + `stp-explorer` | **Subagents** | Pure context isolation, return ≤30-line summary — Teams would just inflate cost |
| `/stp:debug` (tracer + challenger + tester loop) | **Subagents** | Filesystem evidence board works fine; Teams only help if workers must argue in-context |
| `/stp:autopilot` long unattended queue | **Agent Teams justify themselves** | Shared task queue + overnight self-assignment is the canonical Teams use case |
| Frontend ↔ backend negotiating API contracts mid-build | **Agent Teams** | STP doesn't currently do this — if a future flow needs it, use Teams |

**Decision rule:** default to subagents. Only reach for Agent Teams when workers must communicate with *each other*, not just report upward — and even then, only in `/stp:autopilot` or explicitly coordination-heavy flows. STP's existing filesystem handoff pattern (`.stp/docs/`, `.stp/state/`) is strictly cheaper and safer for everything else.

**Caveat:** the 5–7× figure comes from community sources citing Anthropic docs, not a raw Anthropic whitepaper. Directionally solid, exact multiplier varies with team size and model mix.

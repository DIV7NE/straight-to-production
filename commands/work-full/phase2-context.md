### Phase 2: CONTEXT — Understand the Current State

> **PROFILE-AWARE EXPLORATION ROUTING (MANDATORY).** If `STP_EXPLORER_MANDATORY=true` (balanced-profile, budget-profile), the main session **MUST NOT** run multi-file Glob/Grep operations touching >5 files directly. **All multi-file codebase exploration MUST be delegated** to a fresh `stp-explorer` sub-agent with a specific scope. The sub-agent runs the searches in its own 200K context and returns a ≤30 line file:line map. The main session consumes only the map, never raw Glob/Grep dumps. Reading single targeted files (e.g. ARCHITECTURE.md, PRD.md, CHANGELOG.md — files you know the path to) stays in the main session regardless of profile. If `STP_EXPLORER_MANDATORY=false` (intended-profile), explore inline as described below.

**Read everything relevant (in parallel):**

| Source | What you're looking for |
|--------|------------------------|
| `.stp/docs/ARCHITECTURE.md` | Full codebase map — what exists in the affected area, dependencies, integrations |
| `.stp/docs/PRD.md` `## System Constraints` | **MANDATORY enforcement gate.** SHALL/MUST rules added by past features and bug fixes via delta merge-back. List every constraint that applies to this feature's surface area — each becomes a non-negotiable check during build AND a verification point during the Critic pass. Constraints are how STP prevents repeating past bugs. |
| `.stp/docs/AUDIT.md` | Production issues in this area, past bugs, Sentry errors, Patterns & Lessons |
| `.stp/docs/CHANGELOG.md` | Recent changes to this area — context for what was built and decided |
| `CLAUDE.md` | Project Conventions — rules that apply to this type of work |
| Actual source code | Read the files in the affected area. Trace data flows. Understand the REAL implementation, not just docs. **If explorer is mandatory:** spawn `stp-explorer` with a specific scope ("map all files in the auth flow and their call order") instead of reading directly. |
| Git history | `git log --oneline -15 -- [affected paths]` — what changed recently? |

**Explorer spawn pattern** (fires only when `STP_EXPLORER_MANDATORY=true` AND exploration touches >5 files):
```
Agent(
  name="explore-<scope>",
  subagent_type="stp-explorer",
  # If STP_MODEL_EXPLORER == "inherit", omit model. If "sonnet", add: model="sonnet"
  prompt="<specific scope: what to map, what format to return (file:line list + one-line desc each), stop criteria (e.g. 'stay at top-level handlers, don't recurse into utilities')>"
)
```

Accumulate the explorer's map into a `Phase 2 Codebase Map` section in the main session before proceeding to Phase 3.

**If MCP services are connected, pull production data:**
- Sentry: errors in the affected area
- Stripe: current products, prices, subscriptions (if payment-related)
- Vercel: deployment status, environment variables
- Analytics: user behavior in the affected area (if available)

**Summarize what you found** (2-3 sentences for the user, full details go into the plan):
```
Context gathered: [N] files in the payment area, [current Stripe setup], [N] related Sentry errors,
[last payment change was v0.3.2 on DATE]. Current patterns: [key conventions].
```


---
description: Run the STP Critic — a separate AI that evaluates your app against 7 quality criteria. Use when you think a feature is done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Bash", "Grep", "Glob", "Agent"]
---

> **Recommended effort: `/effort high`** — Standard thinking depth for orchestration and review.



# STP: Evaluate

Dispatch the `stp-critic` agent (Sonnet 4.6) to evaluate the project. Self-evaluation is broken — agents reliably skew positive when grading their own work. The Critic is a SEPARATE model that hasn't seen the building process.

## Process

1. Check which planning documents exist:
   - .stp/docs/PRD.md — if missing, note: "No PRD found. Evaluating code quality only, not spec compliance. Run /stp:new-project for full evaluation."
   - .stp/docs/PLAN.md — if missing, note: "No PLAN found. Evaluating code quality only, not architectural compliance. Run /stp:plan for full evaluation."
   - CLAUDE.md — if missing, note: "No CLAUDE.md found. Run /stp:new-project or /stp:onboard-existing."
   
   Proceed with whatever documents exist. The Critic adapts — it grades what it can.

2. Spawn the `stp-critic` agent:

```
Evaluate this project against its requirements and technical plan.

Read these documents FIRST:
- .stp/docs/PRD.md — what was supposed to be built (features, scope, architecture decisions)
- .stp/docs/PLAN.md — how it was supposed to be built (data models, API design, milestones)
- CLAUDE.md — stack patterns and quality standards

Grade against all 7 criteria. Every finding needs a file:line reference AND business impact.
Project directory: [cwd]
Focus area: $ARGUMENTS (if provided, go deeper on this but still check everything)
```

3. **Refresh .stp/docs/AUDIT.md** — pull fresh production data if MCP services are available:
   - Sentry: current unresolved issues (update severity counts, mark fixed issues)
   - Vercel: deployment status, recent build results
   - Stripe: subscription/product state
   - If AUDIT.md doesn't exist, create it. If MCP services aren't connected, skip silently.
   - Add a `## Review Refresh — [DATE]` entry with current findings.

4. When the Critic returns, present the report to the user. Append the Critic's summary to AUDIT.md under `## Critic Evaluation — [DATE]`. Translate any remaining technical jargon into business terms:

   Technical: "No rate limiting on POST /api/invoices"
   Business: "Someone could spam your invoice endpoint and rack up your database/hosting costs"

   Technical: "Missing aria-label on icon buttons"
   Business: "Users who rely on screen readers (visual impairments) can't tell what these buttons do"

5. **Capture new conventions from Critic findings.** If the Critic found a pattern violation that should become a project rule, add it to CLAUDE.md's `## Project Conventions`:
   - "Critic found 3 API routes without rate limiting → Convention: All POST endpoints must use `withRateLimit()` middleware"
   - "Critic found inconsistent error response format → Convention: All API errors return `{ error: string, code: string }`"
   
   Not every finding becomes a convention — only patterns that apply project-wide.

6. **CRITICAL SECURITY — auto-fix, don't ask.** If the Critic finds hardcoded secrets, exposed API keys, or auth bypasses: fix them IMMEDIATELY without waiting for user approval. Say: "SECURITY: [issue] at [file:line]. Fixing now — this can't wait." Then fix and commit.

7. End with explicit next step:

If FAIL/PARTIAL issues exist:
```
━━━ Next step ━━━

Use AskUserQuestion with options:
   yes

Or skip to next feature:
   /stp:build [NEXT FEATURE]
```

If everything PASSED:
```
━━━ Next step ━━━

All 7 criteria passed. Next feature:
   /stp:build [NEXT FEATURE]
```

5. If the user says yes to fixes, work through them in severity order, committing each atomically. After all fixes, offer to re-run the Critic.

## Focus Areas

If the user specified a focus, still run all 7 criteria but go deeper on the focused area:
- "security" → additional grep for common vulnerabilities, check every API route
- "accessibility" → check every page for heading hierarchy, focus management, ARIA
- "performance" → analyze bundle, check for query waterfalls, review caching

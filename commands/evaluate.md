---
description: Run the Pilot Critic — a separate AI that evaluates your app against 6 quality criteria. Use when you think a feature is done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Bash", "Grep", "Glob", "Agent"]
---

# Pilot: Evaluate

Dispatch the `pilot-critic` agent (Sonnet 4.6) to evaluate the project. Self-evaluation is broken — agents reliably skew positive when grading their own work. The Critic is a SEPARATE model that hasn't seen the building process.

## Process

1. Check which planning documents exist:
   - PRD.md — if missing, note: "No PRD found. Evaluating code quality only, not spec compliance. Run /pilot:new for full evaluation."
   - PLAN.md — if missing, note: "No PLAN found. Evaluating code quality only, not architectural compliance. Run /pilot:plan for full evaluation."
   - CLAUDE.md — if missing, note: "No CLAUDE.md found. Run /pilot:new or /pilot:setup."
   
   Proceed with whatever documents exist. The Critic adapts — it grades what it can.

2. Spawn the `pilot-critic` agent:

```
Evaluate this project against its requirements and technical plan.

Read these documents FIRST:
- PRD.md — what was supposed to be built (features, scope, architecture decisions)
- PLAN.md — how it was supposed to be built (data models, API design, milestones)
- CLAUDE.md — stack patterns and quality standards

Grade against all 6 criteria. Every finding needs a file:line reference AND business impact.
Project directory: [cwd]
Focus area: $ARGUMENTS (if provided, go deeper on this but still check everything)
```

3. When the Critic returns, present the report to the user. Translate any remaining technical jargon into business terms:

   Technical: "No rate limiting on POST /api/invoices"
   Business: "Someone could spam your invoice endpoint and rack up your database/hosting costs"

   Technical: "Missing aria-label on icon buttons"
   Business: "Users who rely on screen readers (visual impairments) can't tell what these buttons do"

4. **CRITICAL SECURITY — auto-fix, don't ask.** If the Critic finds hardcoded secrets, exposed API keys, or auth bypasses: fix them IMMEDIATELY without waiting for user approval. Say: "SECURITY: [issue] at [file:line]. Fixing now — this can't wait." Then fix and commit.

5. End with explicit next step:

If FAIL/PARTIAL issues exist:
```
━━━ Next step ━━━

Fix the priority issues (I'll work through them in order):
   yes

Or skip to next feature:
   /pilot:feature [NEXT FEATURE]
```

If everything PASSED:
```
━━━ Next step ━━━

All 6 criteria passed. Next feature:
   /pilot:feature [NEXT FEATURE]
```

5. If the user says yes to fixes, work through them in severity order, committing each atomically. After all fixes, offer to re-run the Critic.

## Focus Areas

If the user specified a focus, still run all 6 criteria but go deeper on the focused area:
- "security" → additional grep for common vulnerabilities, check every API route
- "accessibility" → check every page for heading hierarchy, focus management, ARIA
- "performance" → analyze bundle, check for query waterfalls, review caching

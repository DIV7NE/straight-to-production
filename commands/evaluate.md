---
description: Run the Pilot Critic — a separate AI that evaluates your app against 6 quality criteria. Use when you think a feature is done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Bash", "Grep", "Glob", "Agent"]
---

# Pilot: Evaluate

Dispatch the `pilot-critic` agent (Sonnet 4.6) to evaluate the project. Self-evaluation is broken — agents reliably skew positive when grading their own work. The Critic is a SEPARATE model that hasn't seen the building process.

## Process

1. Read CLAUDE.md to get project context
2. Spawn the `pilot-critic` agent:

```
Evaluate this project. Read CLAUDE.md for the spec.
Grade against all 6 criteria.
Project directory: [cwd]
Focus area: $ARGUMENTS (if provided, go deeper on this but still check everything)
Be ruthlessly strict. Every finding needs a file:line reference AND a business impact explanation.
```

3. When the Critic returns, present the report to the user. Translate any remaining technical jargon into business terms:

   Technical: "No rate limiting on POST /api/invoices"
   Business: "Someone could spam your invoice endpoint and rack up your database/hosting costs"

   Technical: "Missing aria-label on icon buttons"
   Business: "Users who rely on screen readers (visual impairments) can't tell what these buttons do"

4. End with explicit next step:

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

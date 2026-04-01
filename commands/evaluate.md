---
description: Run the Pilot Critic to evaluate your app against 6 quality criteria (functionality, design, security, accessibility, performance, production-readiness). Use when you think you're done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Bash", "Grep", "Glob", "Agent"]
---

# Pilot: Evaluate

Dispatch the `pilot-critic` agent to evaluate the current project.

## Process

1. Read CLAUDE.md to get project context
2. Spawn the pilot-critic agent with this prompt:

```
Evaluate this project. Read CLAUDE.md for the spec, then grade against all 6 criteria.

Project directory: [current working directory]
Focus area: $ARGUMENTS (if provided, prioritize this but still check everything)

Be ruthlessly strict. Every finding must have a file:line reference.
Return the structured evaluation report.
```

3. When the critic returns its report, present it to the user
4. End with an explicit next step based on the results:

If there are FAIL/PARTIAL issues:
```
━━━ Next step ━━━

Fix the priority issues (I'll work through them in order):
   yes

Or skip to your next feature:
   /pilot:feature [NEXT FEATURE NAME from spec]
```

If everything PASSED:
```
━━━ Next step ━━━

All 6 criteria passed. Ready for next feature:
   /pilot:milestone [MILESTONE NAME, e.g., "auth complete"]

Or start the next feature directly:
   /pilot:feature [NEXT FEATURE NAME from spec]
```

5. If the user says yes to fixes, work through them one at a time, committing each atomically. After all fixes, re-run the critic to verify.

## If the user specified a focus area

Still run all 6 criteria but expand the focused area with deeper checks. For example:
- "security only" → run additional grep patterns for common vulnerabilities
- "accessibility" → check every page for heading hierarchy, focus management, ARIA
- "performance" → analyze bundle size, check for waterfalls, review caching strategy

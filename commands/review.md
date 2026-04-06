---
description: Run the STP Critic — a separate AI that evaluates your app against 7 quality criteria. Use when you think a feature is done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
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

MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum.
1. Restate the goal from the PRD in your own words
2. Define every condition that makes this "complete"
3. List every verification angle BEFORE checking anything
4. Execute Iteration 1 — check every angle
5. Execute Iteration 2 — re-check with deeper understanding, find what Iteration 1 missed
6. Synthesize — Verified Complete (with evidence), Gaps (regressions), Gaps (net-new)

Read these documents FIRST:
- .stp/docs/PRD.md — what was supposed to be built (features, scope, architecture decisions)
- .stp/docs/PLAN.md — how it was supposed to be built (data models, API design, milestones)
- CLAUDE.md — stack patterns and quality standards

Grade against all 7 criteria. Every finding needs a file:line reference AND business impact.
Pay special attention to NET-NEW GAPS: features where types/config/Stripe products exist
but no purchase flow, no UI, or no API route was wired up.
Project directory: [cwd]
Focus area: $ARGUMENTS (if provided, go deeper on this but still check everything)
```

3. **Refresh .stp/docs/AUDIT.md** — pull fresh production data if MCP services are available:
   - Sentry: current unresolved issues (update severity counts, mark fixed issues)
   - Vercel: deployment status, recent build results
   - Stripe: subscription/product state
   - If AUDIT.md doesn't exist, create it. If MCP services aren't connected, skip silently.
   - Add a `## Review Refresh — [DATE]` entry with current findings.

4. **Cross-Family Verification (Layer 5 — for security-critical, auth, payments, data integrity code)**

   After the Critic returns, check if the reviewed code touches auth, payments, data integrity, or security-critical paths. If it does, run a cross-family review to decorrelate blind spots:

   **Why:** Claude reviewing Claude-generated code has correlated blind spots — same training data, same systematic misses. Cross-family review catches 3-5x more bugs (Zylos 2026 research).

   **How:** Send the Critic's findings + the relevant source files to 1-2 non-Claude models with role-specific lenses. Use any available AI provider MCP tools or API keys:

   ```
   CROSS-FAMILY REVIEW PROMPT (send to each non-Claude model):
   
   Review this code. The code was written by Claude and reviewed by Claude.
   Your job is to find what Claude missed — you have different blind spots.
   
   Focus on your specific lens:
   - Lens A (Assumptions): "What assumptions does this code make that could be wrong?"
   - Lens B (Adversarial): "If I wanted to break this code, how would I do it?"
   - Lens C (Ground Truth): "Does this code match the actual API/library behavior?"
   
   Code files: [attached]
   Claude's findings: [attached]
   PRD acceptance criteria: [attached]
   
   Report ONLY findings Claude missed. Do not repeat what Claude already found.
   ```

   **If no non-Claude models are available** (no API keys, no MCP tools): skip this step but note in the report: "Cross-family review skipped — no non-Claude models available. Consider adding an OpenAI or Gemini API key for deeper security-critical verification."

   **Deduplicate** findings by root cause before presenting. Cross-family findings get their own section in the report.

5. **CRITICAL SECURITY — auto-fix, don't ask.** If the Critic (or cross-family review) finds hardcoded secrets, exposed API keys, or auth bypasses: fix them IMMEDIATELY without waiting for user approval. Say: "SECURITY: [issue] at [file:line]. Fixing now — this can't wait." Then fix and commit. This happens BEFORE the report so the user sees the fixed state, not the vulnerable state.

6. When all reviews complete (Critic + cross-family + security fixes), present the report to the user. Append the Critic's summary to AUDIT.md under `## Critic Evaluation — [DATE]`. Translate any remaining technical jargon into business terms:

   Technical: "No rate limiting on POST /api/invoices"
   Business: "Someone could spam your invoice endpoint and rack up your database/hosting costs"

   Technical: "Missing aria-label on icon buttons"
   Business: "Users who rely on screen readers (visual impairments) can't tell what these buttons do"

7. **Capture new conventions from Critic findings.** If the Critic found a pattern violation that should become a project rule, add it to CLAUDE.md's `## Project Conventions`:
   - "Critic found 3 API routes without rate limiting → Convention: All POST endpoints must use `withRateLimit()` middleware"
   - "Critic found inconsistent error response format → Convention: All API errors return `{ error: string, code: string }`"
   
   Not every finding becomes a convention — only patterns that apply project-wide.

8. End with explicit next step:

If FAIL/PARTIAL issues exist:

AskUserQuestion(
  question: "Critic found issues. Fix them now or continue to next feature?",
  options: [
    "(Recommended) Fix issues now — work through them in severity order",
    "Skip to next feature — /stp:work-quick [NEXT FEATURE]",
    "Fix only critical/security issues, skip the rest",
    "Chat about this"
  ]
)

If everything PASSED:
```
╔═══════════════════════════════════════════════════════╗
║  ✓ REVIEW COMPLETE — ALL 7 CRITERIA PASSED            ║
╚═══════════════════════════════════════════════════════╝

  ► Next: /stp:work-quick [NEXT FEATURE]
```

9. If the user says yes to fixes,, work through them in severity order, committing each atomically. After all fixes, offer to re-run the Critic.

## Browser Verification (for web projects)

If the Agent Browser MCP (`use_browser`) is available and the project has UI, use it to visually verify:
- Pages load without errors (check console)
- Navigation works (click through primary user flow)
- Responsive layout (test at 375px, 768px, 1280px)
- Forms submit correctly (fill and submit a test form)
- Error states render properly (trigger a validation error)
- Take screenshots of any visual issues for the report

This supplements the Critic's code-level review with real rendered-state verification.

## Focus Areas

If the user specified a focus, still run all 7 criteria but go deeper on the focused area:
- "security" → additional grep for common vulnerabilities, check every API route
- "accessibility" → check every page for heading hierarchy, focus management, ARIA + browser verification of keyboard navigation
- "performance" → analyze bundle, check for query waterfalls, review caching + browser verification of load times

---
description: Run the STP Critic — a separate AI that evaluates your app against 7 quality criteria. Use when you think a feature is done or want a quality check.
argument-hint: Optional focus area (e.g., "security only" or "just check accessibility")
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
---

> **Recommended effort:** `xhigh` (Opus 4.7 default). Only escalate to `max` for cross-family security reviews where blind-spot coverage is load-bearing.

# STP: Evaluate

Dispatch the `stp-critic` agent to evaluate the project. Self-evaluation is broken — agents reliably skew positive when grading their own work. The Critic is a SEPARATE model that hasn't seen the building process.

**Before spawning the critic: read `${CLAUDE_PLUGIN_ROOT}/references/opus-4.7-idioms.md`.** Critical for review: the **INVERSION framing** ("report every issue you find, including low-severity and uncertain findings — downstream ranks severity, your job is recall not precision") and parallel-tool-call idiom for reading multiple source files simultaneously.

## Shared opening

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" resolve-all
PACE=$(jq -r '.pace // "batched"' .stp/state/pace.json 2>/dev/null || echo "batched")
STACK=$(jq -r '.stack // "generic"' .stp/state/stack.json 2>/dev/null || echo "generic")
```

> **Profile-aware spawn — MANDATORY.** The critic model resolves from the active profile (see `${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs`):
> - `opus-cto` / `balanced` / `sonnet-turbo` → `sonnet` (full Double-Check Protocol on first call)
> - `opus-budget` / `sonnet-cheap` → `haiku` first pass; auto-escalate to `sonnet` via `STP_MODEL_CRITIC_ESCALATION` if Haiku flags ≥2 critical issues
> - `pro-plan` → `inline` (main session plays critic role — no sub-agent spawned)
>
> Sentinels: `inherit` → omit `model=`; `inline` → no sub-agent spawn at all, main session performs the review with INVERSION framing applied to itself.

## Process

1. Check which planning documents exist:
   - `.stp/docs/PRD.md` — if missing, note: "No PRD found. Evaluating code quality only, not spec compliance. Run `/stp:setup new` for full evaluation."
   - `.stp/docs/PLAN.md` — if missing, note: "No PLAN found. Evaluating code quality only, not architectural compliance. Run `/stp:think --plan` for full evaluation."
   - `CLAUDE.md` — if missing, note: "No CLAUDE.md found. Run `/stp:setup new` or `/stp:setup onboard`."

   Proceed with whatever documents exist. The Critic adapts — it grades what it can.

2. **Pre-Work Confirmation Gate** — announce: "I'll spawn the critic with INVERSION framing against the current state. Review is read-only until findings come back. Proceed?" AskUserQuestion: `(Recommended) Run review | Scope to [area] only | Cancel`.

3. Spawn the `stp-critic` agent with INVERSION framing + `<use_parallel_tool_calls>`:

```
<use_parallel_tool_calls>
You have parallel tool-call capability. Read PRD.md + PLAN.md + CLAUDE.md + the most-recently-changed source files in a single parallel batch. Run grep patterns in parallel. Do not serialize read operations.
</use_parallel_tool_calls>

INVERSION FRAMING — RECALL OVER PRECISION:
Report every issue you find, including low-severity, uncertain, and potentially-false-positive
findings. A downstream filter ranks severity. Your job is recall, not precision. Err toward
over-reporting. If you are 40% confident something is a bug, report it with confidence:LIKELY.
Do NOT suppress findings because they "might not matter" — that's the downstream's call.

CONTEXT LIMIT:
Don't stop early due to token budget. If you run out of budget mid-review, report what you
found + explicitly flag which criteria remain unchecked. Partial coverage with transparency
beats pretending completeness.

Evaluate this project against its requirements and technical plan.

MANDATORY: Follow the Double-Check Protocol — 2 iteration minimum + claim verification.
1. Restate the goal from the PRD in your own words
2. Define every condition that makes this "complete"
3. List every verification angle BEFORE checking anything
4. Execute Iteration 1 — check every angle
5. Execute Iteration 2 — re-check with deeper understanding, find what Iteration 1 missed
5.5. Verify Behavioral Claims — for any finding claiming code is "broken/fails/doesn't work," TRACE the execution path: read the full function, find all callers, check reachability. Downgrade unreachable code from FAIL to NOTE. Pattern findings (console.log, hardcoded secrets) are exempt.
6. Synthesize — Verified Complete (with evidence), Gaps (regressions), Gaps (net-new), Behavioral Claims Verified

Read these documents FIRST (in parallel):
- .stp/docs/PRD.md — what was supposed to be built (features, scope, architecture decisions)
- .stp/docs/PLAN.md — how it was supposed to be built (data models, API design, milestones)
- .stp/docs/ARCHITECTURE.md — current codebase map
- .stp/docs/AUDIT.md — known production health gaps
- .stp/state/stack.json — stack metadata (which lint/test/typecheck commands apply)
- CLAUDE.md — stack patterns and quality standards

Grade against all 7 criteria. Every finding needs a file:line reference AND business impact.
Pay special attention to NET-NEW GAPS: features where types/config/products exist
but no purchase flow, no UI, or no API route was wired up.
Project directory: [cwd]
Stack: [STACK from .stp/state/stack.json]
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
    "Skip to next feature — /clear then /stp:build [NEXT FEATURE]",
    "Fix only critical/security issues, skip the rest",
    "Chat about this"
  ]
)

If everything PASSED:
```
╔═══════════════════════════════════════════════════════╗
║  ✓ REVIEW COMPLETE — ALL 7 CRITERIA PASSED            ║
╚═══════════════════════════════════════════════════════╝

  ► Next: /clear, then /stp:build [NEXT FEATURE]
          (clear frees context after the review pass — the next build
           phase reads CHANGELOG/PLAN/CONTEXT fresh from disk)
```

9. If the user says yes to fixes,, work through them in severity order, committing each atomically. After all fixes, offer to re-run the Critic.

## Focus Areas

If the user specified a focus, still run all 7 criteria but go deeper on the focused area:
- "security" → additional grep for common vulnerabilities, check every API route
- "accessibility" → check every page for heading hierarchy, focus management, ARIA + browser verification of keyboard navigation
- "performance" → analyze bundle, check for query waterfalls, review caching + browser verification of load times

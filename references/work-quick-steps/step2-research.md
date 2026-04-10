### Step 2: Research (BEFORE building — comprehensive, not optional)

This is the most important step. Skip this and you ship broken, insecure, disconnected code.

**Scale-adaptive upshift (evidence-based — MANDATORY check):** After research, run the Impact Scan:
```bash
# How many files will this actually touch?
grep -rl "[feature keywords]" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules . 2>/dev/null | wc -l
# Any model/migration/auth involvement?
grep -rl "[feature keywords]" --include="*.prisma" --include="*.sql" --include="*migration*" . 2>/dev/null | head -3
grep -rl "[feature keywords]" . 2>/dev/null | grep -i "auth\|payment\|stripe\|webhook\|middleware" | head -3
```

**Upshift is MANDATORY (not optional) if ANY of these are true:**
- 3+ files affected
- Any model/migration changes needed
- Any auth/payment/security paths involved
- New API routes or endpoints needed

If upshift triggered:
```
AskUserQuestion(
  question: "Impact scan: [N] files, [models: yes], [auth: yes]. This needs the full architecture cycle. Recommend upgrading to /stp:work-full ",
  options: [
    "(Recommended) Upgrade to /stp:work-full — full architecture cycle",
    "Continue with /stp:work-quick — I accept the risk",
    "Chat about this"
  ]
)
```

If the user chooses to continue with `/stp:work-quick` despite the scan, proceed but note: the hooks still fire on all code. The user is accepting reduced planning, not reduced enforcement.

**A. Architecture Context — understand what EXISTS before touching anything**

Read `.stp/docs/ARCHITECTURE.md` first (if it exists). This is the full codebase map. From it, identify:
- What directories/files exist near the feature you're building
- What models, routes, components are related to this feature
- What external integrations might be affected
- What patterns and conventions MUST be followed
- What features DEPEND on the code you'll be touching (Feature Dependency Map)

If ARCHITECTURE.md doesn't exist, read `.stp/docs/CONTEXT.md` for the concise version.

Then deep-dive into the actual code:
- Read 3-5 representative files in the area you'll be modifying — learn the ACTUAL patterns, don't assume
- Trace the data flow: UI → API → database for related features
- Find existing functions, types, utilities you should REUSE (don't duplicate)
- Check: does a similar pattern already exist? Follow it, don't invent a new one
- Find existing variables, constants, config that the new feature should reference

**B. Impact Analysis — what does this feature touch?**

Read `.stp/docs/ARCHITECTURE.md`'s Feature Dependency Map + `.stp/docs/PLAN.md`'s Feature Touchpoint Map:
- Which existing features DEPEND on code you'll modify? (these could break)
- Which existing pages need to show data from this feature?
- Which existing API endpoints need to return this feature's data?
- Does the dashboard need updating? Navigation? Search? Notifications?
- List EVERY file that needs modification to connect this feature
- These become checklist items (backward integration)

**C. Research — what's the RIGHT way to do this?**

> **PROFILE-AWARE RESEARCH ROUTING (MANDATORY).** If `STP_RESEARCHER_MANDATORY=true` (balanced-profile, budget-profile), the main session **MUST NOT** call Context7/Tavily/WebSearch/WebFetch directly. **All external research MUST be delegated** to a fresh `stp-researcher` sub-agent per question. The sub-agent runs in its own 200K context and returns a ≤30 line summary with citations. If `STP_RESEARCHER_MANDATORY=false` (intended-profile), run the queries directly in the main session as described below.

Research the RIGHT approach using STP's required MCP tools:

1. **Context7** (HIGH trust) — query `resolve-library-id` then `query-docs` for every library/framework you'll use. Verify patterns against CURRENT versions.
2. **Tavily** (HIGH trust) — use `tavily_search` or `tavily_research` for: industry best practices, "how do production apps solve [this problem]", security advisories, common mistakes. This is your deep research tool.
3. **Official documentation** (HIGH trust) — read the docs, not training data
4. **AI training data** (LOWEST trust) — only when MCP tools return nothing

**Researcher spawn pattern** (fires only when `STP_RESEARCHER_MANDATORY=true`):
```
Agent(
  name="research-<short-topic>",
  subagent_type="stp-researcher",
  # If STP_MODEL_RESEARCHER == "inherit", omit model. If "sonnet", add: model="sonnet"
  prompt="<specific question, ≤2K tokens, includes: what to look up, why it matters, ≤30 line summary with 3 citations>"
)
```

Accumulate returned summaries into a `Research Notes` section in the main session before proceeding.

**Adapt research to work type:**
- **New feature**: Context7 for API patterns + Tavily for "how do Stripe/Shopify/Notion solve this?" + security considerations
- **Bug fix**: What's the ROOT CAUSE, not just the symptom? Is this a one-off or a pattern? Are there OTHER places with the same bug? (grep for similar code)
- **Refactor**: Context7 for latest framework migration guides + Tavily for modern/idiomatic approach
- **Update**: Context7 for changelog/breaking changes + Tavily for migration patterns others have used

**D. Learn from Past Bugs — don't repeat known mistakes**

Read `.stp/docs/AUDIT.md` — specifically the `## Patterns & Lessons` and `## Bug Fixes` sections. For the area you're building in:
- Are there KNOWN bug patterns that apply? (e.g., "server actions don't inherit auth context")
- Were there past bugs in related code? What was the root cause?
- What defense layers were added? Make sure your new code respects them.
- Are there rules like "always scope queries by orgId" that apply to your new code?

This is how the codebase learns. Past debugging work becomes a checklist for new development. If you're writing a new server action and AUDIT.md says "server actions need explicit orgId" — you add it from the start, not after a bug report.

**E. Security Research — what can go wrong?**

Read `.stp/references/security/ai-code-vulnerabilities.md` BEFORE writing code. Then for THIS specific feature:
- What OWASP category does this feature touch? (auth → A01, user input → A03, etc.)
- What are the known security mistakes for this type of feature?
- What validation is required? Where? (server-side, always)
- What secrets/credentials does this feature handle? How are they stored?
- Can a user manipulate this feature to access another user's data? (IDOR check)
- **Race conditions:** Can concurrent requests cause double-spend, double-booking, or duplicate records? If yes → database transactions + locking
- **Mass assignment:** Are you spreading request body into DB operations? Pick allowed fields explicitly.
- **Timing attacks:** Are you comparing tokens or secrets? Use timing-safe comparison.
- **Data privacy:** Does this feature collect/store PII? What's the retention period? Can it be fully deleted (GDPR)?
- **Resource exhaustion:** Are all inputs bounded? (max payload, max items, pagination, timeouts)
- **Error leakage:** Do error responses reveal internal state? Different messages for "not found" vs "wrong password"?
- Read `.stp/references/security/` files relevant to this feature

**F. Resilience Research — what if things fail?**

- What happens when the database is slow or down?
- What happens when external services fail? (Stripe, email, storage)
- Is there a failure scenario where money is taken but no record is created? (saga pattern needed)
- Should external calls have retry logic? (exponential backoff, max 3 retries)
- Can the app still function partially if a non-critical service is down? (graceful degradation)
- What's the timeout for every external call? (never infinite — 10-30 seconds max)

**G. Edge Cases + What Could Break**

- What happens when the input is empty? Too large? Malformed?
- What happens during network failure? Database timeout? External service down?
- What happens with concurrent access? (two users editing the same resource)
- Which existing tests might fail after this change?
- What are the 3 most likely failure modes for this feature?

**H. Scope Expansion + Improvement Opportunities**

The user doesn't know what they don't know. YOUR job is to find what they missed:

- **New feature**: Which existing features could BENEFIT from this? What existing code is incomplete that this feature completes? Present improvements: "While building Purchase Orders, I noticed the Supplier page has no order history. I'll add that too — it makes the app feel connected."
- **Bug fix**: Are there OTHER instances of this same bug? (grep for the pattern). Is the bug a symptom of a deeper architectural issue? If so, recommend the structural fix, not a band-aid. Check AUDIT.md — are there related Sentry errors that share the same root cause?
- **Refactor**: What ELSE uses the old pattern? Should the refactor extend to all instances? What downstream code needs updating? Read ARCHITECTURE.md's Feature Dependency Map — what depends on what you're changing?
- **Update**: What other code uses the same dependency/API? Should the update be applied project-wide? Are there deprecated patterns that should be cleaned up while you're here?

Always present scope expansions to the user — don't just silently add work. Explain why it matters.

**I. Anti-Hallucination Verification**

Before finalizing the feature plan:
- Verify every import/package you plan to use actually EXISTS in the registry
- Verify every function/method you plan to call EXISTS in that package's current version
- If using an API, verify the endpoint/method signature against Context7 or official docs
- If using a config option, verify it's real (not hallucinated from training data)

  ┊ I'm doing thorough research before writing any code — checking what exists, how this should work, verifying every package is real, checking for security vulnerabilities. Takes minutes, prevents days of fixing mistakes.

### Step 3: Enrich + Correct the User

Based on ALL the research above, identify what the user DIDN'T think of. Read relevant `.stp/references/` files.

**If the user's approach is wrong, say so.** You are the CTO — don't blindly implement bad ideas. Present the researched, proven approach.

**Examples by work type:**
- **Feature**: "You asked for a simple password field, but the industry standard is OAuth. Here's why: [Stripe/Shopify do it this way because...]. The downside of passwords is [security risk]."
- **Bug fix**: "You asked me to fix the undefined constant on /dashboard. But this is actually 6 related errors across 3 routes, all caused by the same missing export. I'll fix the root cause — not just the one you noticed."
- **Refactor**: "You asked to refactor auth middleware. Looking at ARCHITECTURE.md, the current pattern is used in 47 routes. But 12 of them have a slightly different pattern that's actually better. I recommend migrating everything to that pattern instead."
- **Update**: "You asked to update the PDF export. But the current implementation has 3 issues beyond what you mentioned: [no error handling, no loading state, hardcoded styles]. I'll fix all of them while I'm in there — cheaper now than as separate tasks."

Ask at most ONE product question if a real product decision is needed. If no product decision is needed, skip to the plan.

For significant technical decisions, briefly note them with industry backing.


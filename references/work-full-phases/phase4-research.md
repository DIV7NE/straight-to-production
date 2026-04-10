### Phase 4: RESEARCH — Deep Dive on Implementation

With context gathered and tools ready, research the RIGHT way to do this work.

> **PROFILE-AWARE RESEARCH ROUTING (MANDATORY).** If `STP_RESEARCHER_MANDATORY=true` (balanced-profile, budget-profile), the main session **MUST NOT** call Context7, Tavily, WebSearch, or WebFetch directly. **All external research in this phase MUST be delegated** to a fresh `stp-researcher` sub-agent per research question. The sub-agent runs the queries in its own 200K context and returns a ≤30 line structured summary. The main session consumes only summaries, never raw research dumps. If `STP_RESEARCHER_MANDATORY=false` (intended-profile — Opus 1M absorbs it inline), run the queries directly in the main session as described below.

**Framework/library research (Context7):**
- Query current API docs for every library you'll use
- Check for breaking changes, deprecations, migration guides
- Verify patterns against CURRENT versions (training data may be stale)
- **If researcher is mandatory:** spawn `stp-researcher` with a specific question like "Query Context7 for the current [library] patterns: [specific topic]. Return ≤30 line summary with file:line or doc URL citations."

**Industry research (Tavily/WebSearch):**
- How do production apps solve this exact problem?
- What are the common mistakes?
- What's the current best practice (2025-2026)?
- Security considerations specific to this type of work
- **If researcher is mandatory:** spawn `stp-researcher` with a specific question like "Run Tavily research on [topic]: current best practices + common mistakes + security concerns. Return ≤30 line summary with 3 citations."

**Researcher spawn pattern** (fires only when `STP_RESEARCHER_MANDATORY=true`):
```
Agent(
  name="research-<short-topic>",
  subagent_type="stp-researcher",
  # If STP_MODEL_RESEARCHER == "inherit", omit model. If "sonnet", add: model="sonnet"
  prompt="<specific question, ≤2K tokens, includes: what to look up, why it matters, what format to return, stop criteria>"
)
```

Accumulate summaries into a `Phase 4 Research Notes` section in the main session before proceeding to Phase 5.

**Codebase patterns (from Phase 2 context):**
- How does the existing code handle similar work?
- What conventions MUST be followed? (from CLAUDE.md Project Conventions)
- **What system constraints MUST be enforced?** (from PRD.md `## System Constraints` — SHALL/MUST rules from past features and bug fixes; each is a non-negotiable check)
- What past bugs apply? (from AUDIT.md Patterns & Lessons)

**If MCP tools are available, use them:**
- Stripe MCP: read current products, prices, webhook configs
- Neon MCP: inspect current schema, run test queries
- Sentry MCP: get detailed stack traces for related errors
- Vercel MCP: check environment variables, deployment config

**Security research (MANDATORY for work involving user input, auth, payments, or data):**
- Read relevant `.stp/references/security/` files
- Check OWASP categories that apply
- Research known vulnerabilities for this type of feature

**Present 2-3 approaches with tradeoffs:**

```
AskUserQuestion(
  question: "Based on my research, here are [N] ways to approach this. [Brief summary of each]",
  options: [
    "(Recommended) [Approach A] — [why, for THIS project specifically]",
    "[Approach B] — [different tradeoff]",
    "[Approach C] — [different tradeoff]",
    "None of these — let me describe what I'm thinking",
    "Chat about this"
  ]
)
```


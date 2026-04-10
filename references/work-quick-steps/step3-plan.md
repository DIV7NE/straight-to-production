### Step 3: Present Plan

**Check active profile first:**
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current
```

---

#### If profile is `20-pro-plan` — use the LEAN plan format

Output this plan as direct text in your response (≤15 lines). No bash echo — must be visible:

```
## [Work Type]: [Name]

### What I'll do
[1-2 sentences. Exactly what changes, nothing more.]

### Files
- [path/to/file.ts] — [create / modify: what changes]
- [path/to/file.ts] — [create / modify: what changes]

### Approach
- [Key decision 1 — e.g. "extend existing X rather than create new Y"]
- [Key decision 2]

### Risks
- [What could break and why — 1-2 lines max]

### Tests I'll write first
- [Test case 1 — what behavior it verifies]
- [Test case 2]
```

Then immediately call:
```
AskUserQuestion(
  question: "Plan looks good? I'll start building once you confirm.",
  header: "Approve Plan",
  options: [
    "(Recommended) Yes — build it",
    "Change the approach — [user types what]",
    "Scope it down — too much"
  ]
)
```

Do NOT proceed to build until the user approves. Every message counts — the plan is the checkpoint.

---

#### If profile is anything else — use the STANDARD plan format

```
## [Work Type]: [Name]
(e.g., "Feature: Invoice PDF Export" or "Fix: Dashboard ReferenceErrors" or "Refactor: Auth Middleware")

### What you asked for
[1-2 sentences restating their request in plain language]

### What I'm actually doing (things you'd miss)
- [ ] [What research revealed — why it matters to your USERS, one line]
- [ ] [Related issue discovered — why fixing it now saves time]
- [ ] [Scope expansion — why this makes the app better]

### Impact on existing code (what could break)
- [ ] [Existing page/component — what changes, from ARCHITECTURE.md dependency map]
- [ ] [Existing page/component — what changes]
(For refactors: list EVERY dependent. For fixes: list related code with the same pattern.)

### Key decisions
[Brief note on any significant tech choices, with who uses it and why.
Skip this section if no notable decisions beyond what's in CLAUDE.md.]

### Tests to write FIRST
- [ ] [Test case 1 from .stp/docs/PLAN.md or identified during enrichment]
- [ ] [Test case 2]
- [ ] [Test case 3]

### Build order (9-layer Definition of Done)
1. [Database — migrations, schema changes]
2. [Executable specs — one test per acceptance criterion, named "AC: ..."]
3. [Write tests FIRST (TDD) — behavioral tests, error-path tests, property-based for critical invariants]
4. [API / server logic — endpoints, server actions, validation]
5. [Business logic — core feature functionality, make tests pass]
6. [UI — pages, components, forms, connected to API]
7. [Error/edge cases — error handling, loading states, empty states]
8. [Backward integration — update existing features to connect]
9. [Polish — accessibility, /simplify, verify acceptance criteria from PRD]

### Acceptance criteria (from .stp/docs/PRD.md) — EACH becomes an executable spec test
- [ ] [AC 1 — testable condition that defines "done"]
- [ ] [AC 2 — testable condition]

### Standards I'll check
- .stp/references/[domain]/[file].md before: [specific step]
```

Keep the plan UNDER 30 lines. This is a checklist, not a document.

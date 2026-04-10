### Phase 5: PLAN — Full Architecture Blueprint (zero compromise)

This is the FULL `/stp:plan` cycle embedded in `/stp:work-full`. No shortcuts. Every sub-phase below is mandatory. Write all findings to `.stp/docs/PLAN.md` as you go — if compaction fires, the plan is already on disk.

**For single features:** Also create `.stp/state/current-feature.md` with the standard checklist format.
**For multi-feature work:** `.stp/docs/PLAN.md` is the primary document.

**Visual whiteboard** — offer the whiteboard for live diagrams during planning:

```
AskUserQuestion(
  question: "I'll be designing the architecture with diagrams — user flows, data models, API sequences. Want me to open the visual whiteboard so you can see them live in your browser?",
  options: [
    "(Recommended) Yes, open the whiteboard at http://localhost:3333",
    "No, just show diagrams in the terminal",
    "Chat about this"
  ]
)
```

If accepted:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```

Wait for the user to confirm they've opened http://localhost:3333 before proceeding. Diagrams will update live as each sub-phase completes — the user watches the architecture take shape in real time. Each section still gets its own approval gate in Phase 5m.

Throughout Phase 5, push all diagrams to `.stp/whiteboard-data.json` — the whiteboard polls every 2 seconds and renders them live. If UI/UX work is involved, the design system preview (color swatches, font samples, layout wireframe) will also render in the whiteboard.

#### 5a. Domain Research

Research what production versions of this type of feature/product actually need. Not the tech — the DOMAIN.
- What do competitors/existing tools do for this?
- What workflows do users expect?
- What edge cases exist? (partial states, failures, concurrent access, undo)
- Legal/compliance requirements if applicable

#### 5b. Technical Research (Context7 + MCP tools)

Before designing: verify the CURRENT state of every technology you'll use. Training data may be stale.
- Framework: Context7 query for latest patterns, breaking changes
- Database/ORM: latest migration patterns, connection pooling, RLS
- Auth: latest middleware pattern, security advisories
- Integrations: latest API versions, deprecated endpoints
- Record findings in PLAN.md `## Technical Research` section

#### 5c. System Architecture

Design components, connections, and data flow. Produce diagrams (Mermaid — push to whiteboard if running):
- **User flow** — how users move through the feature/app
- **System architecture** — frontend, backend, database, external services
- **State diagrams** — for entities with lifecycles (draft→sent→paid→overdue)

#### 5d. Data Models

Design every table/model with fields, types, relationships, indexes:
- ER diagram (Mermaid `erDiagram`)
- Migration files to create + rollback procedures
- Seed data for development/testing

#### 5e. API/Route Design

Design every endpoint with purpose, auth requirements, request/response shapes:
- Sequence diagrams for complex flows (payments, webhooks, multi-step)
- Validation rules per endpoint
- For non-API apps: design the service layer / data access patterns

#### 5f. Auth & Authorization Design (centralized, not per-endpoint)

- Authentication: provider, protected routes, session handling
- Authorization: who can do what, role-based access, row-level security
- Webhook auth: signature verification per webhook endpoint

#### 5g. Error Handling Strategy (centralized, not per-feature)

- Consistent error response format across ALL endpoints
- Error propagation: DB error → catch → log → safe message
- User-facing messages: never stack traces, always next steps
- Error tracking: Sentry/equivalent config

#### 5h. Cross-Cutting Concerns — Feature Touchpoint Map

Map where every feature appears across the ENTIRE app:

| Feature | Database | API | UI Pages | Navigation | Search | Notifications | Dashboard |
|---------|----------|-----|----------|------------|--------|--------------|-----------|
| [Feature] | [table] | [endpoints] | [pages] | [nav links] | [searchable?] | [triggers?] | [widget?] |

This prevents building features in isolation but forgetting to connect them everywhere.

#### 5i. Test Strategy — Spec-First TDD

- **Acceptance criteria as executable specs** — each AC becomes `test("AC: user can ...")`. PRIMARY quality gate.
- **Behavioral tests** — verify user-visible outcomes, not mock interactions
- **Property-based tests** — for financial, auth, data transform invariants
- **Error-path tests** — every error handler must have a test
- **Integration tests** — at least one test per feature that hits real services

#### 5j. Build Order + Wave Execution

- Dependencies determine sequence — what must come first
- **Wave analysis** (for multi-feature): compare file lists, features sharing modified files → different waves
- Within a wave: all features are independent → parallel via executor agents
- Produce dependency graph diagram for whiteboard

#### 5k. Risk Mitigation

- Security: attack surface, auth requirements, data sensitivity
- Breaking changes: what existing features could break
- Performance: potential bottlenecks, N+1 queries, bundle impact
- Conventions: from CLAUDE.md Project Conventions
- **System constraints: from PRD.md `## System Constraints` — list every SHALL/MUST that applies to this work, and the specific check/test that enforces it**
- Past lessons: from AUDIT.md Patterns & Lessons

#### 5l. Plan Self-Review (automated completeness check before user sees it)

Before presenting ANY section to the user, run this self-review:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, vague requirements like "handle errors appropriately"? Fix them with concrete specifics.
2. **Internal consistency:** Do any sub-phases contradict each other? Does the data model match the API design? Does auth design match the route protection?
3. **Scope check:** Is this focused enough for a single build cycle, or does it need decomposition into sub-projects?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? Pick one and make it explicit.
5. **YAGNI check:** Did you add features the user didn't ask for? Remove them unless they're security/auth/error-handling essentials.
6. **Spec coverage:** Does every acceptance criterion have a corresponding executable spec test in the test strategy?
7. **Touchpoint completeness:** Does every feature appear in the cross-cutting concerns map?
8. **Convention compliance:** Do the conventions from CLAUDE.md apply correctly?
9. **Constraint compliance:** Does the plan satisfy every applicable rule in PRD.md `## System Constraints`? List each constraint and the specific check/test that enforces it. Missing constraint enforcement = REJECT and rework the plan.
10. **Lesson check:** Does AUDIT.md Patterns & Lessons have any relevant warnings?

Fix any issues inline. Don't present known gaps to the user.

#### 5m. Section-by-Section Design Approval (incremental, not dump-all-at-once)

**Do NOT present the entire architecture blueprint in one message.** Present each major section, get approval, then move to the next. This catches misunderstandings early before they compound.

**Present in this order, one section per message:**

**Section 1: System Architecture (5c)**
```
┌─── Architecture: System Design ──────────────────────┐
│                                                       │
│  Components:    [list with 1-line purpose each]       │
│  Data flow:     [how data moves through the system]   │
│  Integrations:  [external services]                   │
│                                                       │
│  [Mermaid diagram pushed to whiteboard if running]    │
│                                                       │
└──────────────────────────────────────────────────────┘
```
```
AskUserQuestion(
  question: "System architecture — does this structure make sense?",
  options: [
    "Looks right, continue to data models",
    "Change something — [describe]",
    "Chat about this"
  ]
)
```

**Section 2: Data Models + API Design (5d + 5e)**
```
┌─── Architecture: Data & API ─────────────────────────┐
│                                                       │
│  Models:      [fields, types, relationships]          │
│  Endpoints:   [routes with auth, request/response]    │
│  Migrations:  [what changes in the database]          │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**Section 3: Auth + Error Handling + Security (5f + 5g + 5k)**
```
┌─── Architecture: Auth & Safety ──────────────────────┐
│                                                       │
│  Auth model:       [provider, routes, authz matrix]   │
│  Error strategy:   [format, propagation, tracking]    │
│  Security risks:   [attack surface, mitigations]      │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**Section 4: Build Plan + Tests (5i + 5j + 5h)**
```
┌─── Architecture: Execution Plan ─────────────────────┐
│                                                       │
│  Tests:    [N] spec · [N] behavioral · [N] property   │
│  Waves:    Wave 1 → Wave 2 → ...                      │
│  Touches:  [touchpoint map summary]                   │
│                                                       │
└──────────────────────────────────────────────────────┘
```
Ask for approval. Wait.

**After all sections approved, present the summary:**
```
╔═══════════════════════════════════════════════════════╗
║  ✓ ARCHITECTURE BLUEPRINT COMPLETE                    ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Scope     [1-2 sentences]                            ║
║  Scale     [N] features · [N] new · [N] modified      ║
║  Models    [N] · Endpoints [N]                        ║
║  Tests     [N] total planned                          ║
║  Waves     [N] parallel execution waves               ║
║                                                       ║
║  Saved to .stp/docs/PLAN.md                           ║
║  All sections approved. Ready to build.               ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

```
AskUserQuestion(
  question: "All architecture sections approved. Proceed to build?",
  options: [
    "(Recommended) Start building — launch Phase 6",
    "Review full plan in .stp/docs/PLAN.md first",
    "Save for later — I'll run /stp:work-quick when ready",
    "Chat about this"
  ]
)
```


---
description: Research the domain, design the architecture, and create a detailed implementation plan. Run after /pilot:new and before /pilot:feature. This is where all the thinking happens before any code is written.
argument-hint: Optional focus (e.g., "just the database schema" or "API design only")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

# Pilot: Plan

You are the CTO doing the real engineering work BEFORE any code is written. This command produces the complete technical blueprint that /pilot:feature executes against.

No code is written during this command. Only documents.

## Prerequisites

Check that PRD.md exists. If it doesn't:
```
No PRD.md found. Run /pilot:new first to define what you're building.
The plan needs a PRD to design against.
```
Stop here — do not proceed without a PRD.

If PRD.md exists, read it along with CLAUDE.md for context.

## Process

### Phase 1: Domain Research

Research what a production version of this product actually needs. This is NOT about the tech stack (decided in /pilot:new) — it's about the DOMAIN.

For an invoicing app, research:
- What do existing invoice tools do? (FreshBooks, Wave, Invoice Ninja)
- What are the legal requirements? (invoice numbering, tax handling, retention)
- What workflows do users expect? (create → send → track → get paid)
- What edge cases exist? (partial payments, refunds, overdue handling, recurring)

For a fitness app, research:
- What do existing apps track? (exercises, sets, reps, weight, cardio)
- What data structures do they use?
- What workflows do users expect?

Use your training knowledge. If Context7 or web search would help for specific technical patterns, use them. Present the research as:

```
## Domain Research

### What [product type] tools typically include
- [Feature 1 — why users expect it]
- [Feature 2 — why users expect it]

### Workflows users expect
1. [Primary workflow: e.g., Create invoice → Send → Track → Get paid]
2. [Secondary workflow]

### Edge cases we need to handle
- [Edge case 1 — what happens when...]
- [Edge case 2]

### Legal/compliance requirements (if applicable)
- [Requirement — why it matters]
```

Ask the user: "Based on this research, anything you want to add or cut?" One question, then move on.

### Phase 2: System Architecture

Design the system components, how they connect, and how data flows.

```
## System Architecture

### Components
[List every major component with one-line purpose]

### Data Flow
[How data moves through the system — user action → frontend → API → database → response]

### Integrations
[External services and how they connect — Stripe, email, storage, etc.]
```

For the user's understanding, explain each component in plain terms:
"The **API layer** is like a receptionist — it receives requests from the app, validates them, does the work, and sends back a response. Nothing touches the database directly."

### Phase 3: Data Models

Design every database table/model, its fields, relationships, and indexes.

```
## Data Models

### [Model Name] (e.g., Invoice)
| Field | Type | Purpose |
|-------|------|---------|
| id | UUID | Unique identifier |
| user_id | UUID (FK → Users) | Who owns this |
| ... | ... | ... |

Relationships:
- Invoice has many LineItems
- Invoice belongs to User
- Invoice belongs to Client

Indexes:
- user_id (all queries filter by user)
- status + created_at (dashboard sorting)
```

Explain key design decisions:
"I'm using UUIDs instead of auto-incrementing numbers for IDs. This means someone can't guess invoice URLs by incrementing numbers — if invoice #5 exists, they can't just try #6 to see someone else's invoice."

### Phase 4: API/Route Design (if applicable)

Design every endpoint or route with its purpose, auth requirements, and request/response shape.

```
## API Design

### POST /api/invoices
Auth: Required (user must be logged in)
Purpose: Create a new invoice
Request: { client_id, line_items[], due_date, notes }
Response: { invoice }
Validation: client_id must belong to user, line_items non-empty, due_date in future

### GET /api/invoices
Auth: Required
Purpose: List user's invoices (paginated)
Query params: status, page, per_page, sort
Response: { invoices[], total, page }
```

For desktop/mobile apps without APIs, design the service layer / data access patterns instead.

### Phase 5: Feature Breakdown + Milestones

Break the PRD's features into implementation order with dependencies.

```
## Implementation Plan

Status key: [ ] pending, [x] complete, [!] blocked

### Milestone 1: Foundation
Goal: Core data models, database, and basic CRUD

Features:
- [ ] 1. Database setup + migrations
   - Create: src/db/schema.ts (or models.py, schema.rs, etc.)
   - Create: src/db/migrations/001_initial.sql
   - Tests: tests/db.test.ts — connection, schema validation
   - Dependencies: none
   
- [ ] 2. User model + auth integration
   - Create: src/models/user.ts
   - Create: src/middleware/auth.ts
   - Modify: src/app/layout.tsx (add auth provider)
   - Tests: tests/auth.test.ts — signup, login, session, protected routes
   - Dependencies: database

- [ ] 3. [Core model] CRUD
   - Create: src/models/[model].ts
   - Create: src/app/api/[model]/route.ts
   - Create: src/components/[model]-form.tsx
   - Tests: tests/[model].test.ts — create, read, update, delete, validation, auth
   - Dependencies: user model

### Milestone 2: Core Workflow
Goal: The primary user workflow works end-to-end

Features:
- [ ] 4. [Primary workflow step 1]
   - Create: [specific files]
   - Modify: [specific files]
   - Tests: [specific test file] — [specific test cases]
   - Dependencies: [which features must exist first]

- [ ] 5. [Primary workflow step 2]
   ...

### Milestone 3: Polish + Production
Goal: Error handling, loading states, empty states, edge cases

Features:
- [ ] 8. Error handling across all operations
   - Create: src/app/error.tsx (or equivalent)
   - Modify: [every API route / server action for try/catch]
- [ ] 9. Loading states for all async operations
   - Create: src/app/loading.tsx + per-route loading files
- [ ] 10. Empty states for all lists/views
    - Modify: [every list component]
- [ ] 11. Edge cases from domain research
    - [Specific files per edge case]
```

Every feature specifies exact files to create/modify and exact test files to write.
This prevents drift during implementation — Opus follows the blueprint, not improvisation.

### Phase 6: Save the Plan

Write everything to `PLAN.md` at the project root. This is the technical blueprint that `/pilot:feature` executes against.

Structure:
```markdown
# [Project Name] — Technical Plan

## Domain Research
[Phase 1 output]

## System Architecture  
[Phase 2 output]

## Data Models
[Phase 3 output]

## API / Route Design
[Phase 4 output]

## Implementation Plan
[Phase 5 output — milestones + features + files + tests + dependencies]
```

Commit: `docs: add technical plan`

### Phase 7: Self-Review (Catch Your Own Mistakes)

Before any external verification, review with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", "[fill in]", or incomplete sections? Fix them now.
2. **Consistency check:** Do data models match the API design? Do API routes reference models that exist? Do test cases match the features they test?
3. **Dependency check:** Can features be built in the specified order? Does feature 3 depend on something not yet built? Are there circular dependencies?
4. **File check:** Does every feature specify which files to create/modify? No vague "implement the feature" — specific file paths.
5. **Test check:** Does every feature have at least one test case? No features without tests. Are there integration tests for cross-feature workflows?
6. **Scope check:** Does the plan match the PRD? Nothing missing, nothing added that wasn't discussed?

Fix issues inline. Don't re-present — just fix and move on.

### Phase 8: Plan Verification (Separate Evaluator)

Spawn the `pilot-critic` agent to verify the plan BEFORE any code is written. Finding an architecture mistake now saves 10x vs finding it after 5 features are built on top.

Prompt the Critic:

```
Verify PLAN.md against PRD.md. You are reviewing a PLAN, not code. Check:

1. **PRD coverage** — Does every feature in PRD.md have a corresponding
   milestone/feature in PLAN.md? List any gaps.

2. **Data model integrity** — Are all relationships valid? Are foreign keys
   pointing to tables that exist? Are there missing indexes for common queries?

3. **API/model consistency** — Does every API endpoint reference models that
   exist in the data model section? Do request/response shapes match the models?

4. **Dependency graph** — Can features be built in the listed order? Does any
   feature depend on something scheduled later? Are there circular dependencies?

5. **Test coverage** — Does every feature have specific test cases? Are there
   integration tests for end-to-end workflows (not just unit tests)?

6. **Security review** — Are all authenticated endpoints marked as such? Is input
   validation specified for every endpoint accepting user data? Are there rate
   limits on public endpoints?

7. **Missing concerns** — Based on the project type, is anything obviously missing?
   (error handling strategy, migration plan, deployment requirements, monitoring)

Report: PASS / ISSUES FOUND with specific findings.
```

If the Critic finds issues, fix them in PLAN.md and re-run verification. Iterate until PASS.

### Phase 9: User Reviews the Written Plan

After verification passes, ask the user to review:

```
━━━ Plan ready (verified) ━━━

PLAN.md saved and verified by the Critic:
- [N] milestones, [N] features, [N] files to create
- Milestone 1 (Foundation): [brief]
- Milestone 2 (Core): [brief]
- Milestone 3 (Polish): [brief]
- Verification: PASS — [any notes]

Please review PLAN.md — this is the blueprint I'll build against.
Let me know if you want to change anything before we start.

When ready:
/pilot:feature [FIRST FEATURE from Milestone 1]
```

Wait for the user to approve. If they request changes, make them, re-verify, and ask again. Do NOT proceed to building until the user has approved the verified plan.
```

## Rules

- NO CODE during /pilot:plan. Only documents.
- Every feature in the plan MUST include what tests to write BEFORE implementation.
- Dependencies between features must be explicit — can't build invoices before the database exists.
- Data models must include indexes — query performance is designed, not discovered.
- The plan is a LIVING document — /pilot:feature updates it as decisions change.
- If the user has a focus argument (e.g., "just the database schema"), only do that phase and return. Don't force the full process for partial updates.
- Teach throughout. Explain WHY the architecture is shaped this way, not just what it is.

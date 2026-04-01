---
description: Research the domain, design the architecture, and create a detailed implementation plan. Run after /pilot:new and before /pilot:feature. This is where all the thinking happens before any code is written.
argument-hint: Optional focus (e.g., "just the database schema" or "API design only")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion", "Agent"]
---

# Pilot: Plan

You are the CTO doing the real engineering work BEFORE any code is written. Read PRD.md and CLAUDE.md for context. This command produces the complete technical blueprint that /pilot:feature executes against.

No code is written during this command. Only documents.

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

### Milestone 1: Foundation
Goal: Core data models, database, and basic CRUD

Features:
1. Database setup + migrations
   - Tests: connection, schema validation
   - Dependencies: none
   
2. User model + auth integration
   - Tests: signup, login, session, protected routes
   - Dependencies: database

3. [Core model] CRUD
   - Tests: create, read, update, delete, validation, auth
   - Dependencies: user model

### Milestone 2: Core Workflow
Goal: The primary user workflow works end-to-end

Features:
4. [Primary workflow step 1]
   - Tests: [specific test cases]
   - Dependencies: [which features must exist first]

5. [Primary workflow step 2]
   ...

### Milestone 3: Polish + Production
Goal: Error handling, loading states, empty states, edge cases

Features:
8. Error handling across all operations
9. Loading states for all async operations
10. Empty states for all lists/views
11. Edge cases from domain research
```

Each feature includes what tests to write BEFORE implementation (TDD).

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
[Phase 5 output — milestones + features + tests + dependencies]
```

Commit: `docs: add technical plan`

### Phase 7: Present + Approve

Summarize the plan for the user. Highlight:
1. How many milestones and features
2. What gets built first and why
3. Any decisions that need their product input
4. Estimated complexity (small / medium / large per milestone)

```
━━━ Plan ready ━━━

PLAN.md has the full technical blueprint:
- [N] milestones, [N] features
- Milestone 1 (Foundation): [brief]
- Milestone 2 (Core): [brief]  
- Milestone 3 (Polish): [brief]

Review PLAN.md if you want to see the details.
Start building:

/pilot:feature [FIRST FEATURE from Milestone 1]
```

## Rules

- NO CODE during /pilot:plan. Only documents.
- Every feature in the plan MUST include what tests to write BEFORE implementation.
- Dependencies between features must be explicit — can't build invoices before the database exists.
- Data models must include indexes — query performance is designed, not discovered.
- The plan is a LIVING document — /pilot:feature updates it as decisions change.
- If the user has a focus argument (e.g., "just the database schema"), only do that phase and return. Don't force the full process for partial updates.
- Teach throughout. Explain WHY the architecture is shaped this way, not just what it is.

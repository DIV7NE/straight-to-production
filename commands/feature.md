---
description: Plan a new feature with Pilot. Surfaces what you'd miss for THIS specific feature, checks relevant standards, and creates a focused build checklist. Use before starting any non-trivial feature.
argument-hint: Description of the feature (e.g., "add Stripe payments" or "build the user dashboard")
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "AskUserQuestion"]
---

# Pilot: Feature Planning

You are helping a solo developer plan a new feature. They don't know what they don't know — your job is to surface the concerns specific to THIS feature before they start building.

This is NOT a heavy planning process. No phases, no roadmaps. Just: what does this feature actually require that the developer hasn't thought of?

## Process

### Step 1: Understand Context

Read the project's CLAUDE.md to understand:
- What the app is and what already exists
- The tech stack in use
- Any existing patterns or conventions

Then ask ONE question if needed: "Anything specific about how you want this to work, or should I design it?"

Most features don't need more than that. The developer described what they want — your job is to enrich it, not interrogate them.

### Step 2: Identify Feature-Specific Concerns

Based on the feature description, identify what standards and concerns are relevant. Examples:

| Feature | Concerns to Surface |
|---------|-------------------|
| Payments/Stripe | Webhook verification, idempotency, test mode keys, PCI compliance (don't store card data), refund handling, failed payment states |
| File uploads | Max file size, allowed types, storage strategy (Supabase Storage/S3), malware scanning, progress indicators, image optimization |
| User dashboard | Loading states for each data section, empty states, error boundaries, data fetching waterfalls (parallelize!), responsive layout |
| Real-time features | WebSocket vs SSE vs polling, reconnection handling, optimistic updates, offline queuing, connection state UI |
| Search | Server-side vs client-side, debouncing, empty results state, indexing strategy, pagination |
| Email/notifications | Transactional vs marketing, unsubscribe compliance, rate limiting, template system, queue for reliability |
| Admin panel | RBAC authorization, audit logging, separate middleware protection, cannot share auth with user routes |
| API/webhooks | Rate limiting, authentication (API keys), idempotency keys, retry handling, request validation, versioning |
| Social/sharing | OG images, meta tags per page, share URL structure, content sanitization |
| Multi-tenancy | Tenant isolation in database queries, subdomain/path routing, tenant-scoped auth |

Read the relevant `.pilot/references/` files for the domains this feature touches. For example:
- Feature involves user input → read `security/input-sanitization.md`
- Feature involves new pages → read `production/loading-states.md`, `production/empty-states.md`, `accessibility/wcag-aa-essentials.md`
- Feature involves API routes → read `security/api-security.md`, `security/auth-patterns.md`
- Feature involves images → read `performance/image-optimization.md`
- Feature involves data fetching → read `performance/waterfall-prevention.md`

### Step 3: Present the Enriched Plan

Present a focused checklist — NOT a long document. Format:

```
## Feature: [Name]

### What you asked for
[1-2 sentences restating their request]

### What I'm adding (that you didn't ask for)
- [ ] [Concern 1 — why it matters in one line]
- [ ] [Concern 2 — why it matters in one line]
- [ ] [Concern 3 — why it matters in one line]

### Build order
1. [First thing to build — the foundation]
2. [Second — core functionality]
3. [Third — error/edge cases]
4. [Fourth — polish: loading states, empty states, accessibility]

### Relevant standards
- Read `.pilot/references/[domain]/[file].md` before: [specific step]
```

Keep the plan SHORT. Under 30 lines. This is a checklist, not a spec.

### Step 4: Ask for Go-Ahead

"Does this look right? Say 'go' and I'll start building, or tell me what to change."

When they say go:
1. Save the checklist to `.pilot/current-feature.md` — this file survives compaction and session restarts
2. Start building from the checklist
3. Follow the build order. Read the referenced standard files before the relevant steps.
4. After completing each checklist item, update `.pilot/current-feature.md` (change `- [ ]` to `- [x]`)
5. Commit after each logical unit

When the feature is complete:
1. Delete `.pilot/current-feature.md`
2. Delete `.pilot/handoff.md` if it exists
3. Commit with a clear message
4. End with explicit next step:

```
Feature complete: [FEATURE NAME]

━━━ Next step ━━━

Evaluate what you built:
   /pilot:evaluate

Or jump to the next feature:
   /pilot:feature [NEXT FEATURE from the spec — be specific]

Or mark a milestone:
   /pilot:milestone [MILESTONE NAME]
```

ALWAYS fill in specific names. NEVER use generic placeholders.

## Gotchas
- Do NOT turn this into a 20-question discovery session. One question max, then present the plan.
- ALWAYS save the checklist to `.pilot/current-feature.md` — this is how state survives compaction. If compaction fires mid-feature, the SessionStart hook reads this file to restore context.
- Do NOT over-scope. If the developer said "add a settings page", don't also add admin tools, notification preferences, and theme switching unless they asked.
- DO check if similar patterns already exist in the codebase. If there's already a form pattern, follow it. If there's already an API route pattern, match it.
- If `.pilot/current-feature.md` already exists when this command runs, ask: "You have an in-progress feature: [title]. Want to finish that first, or start this new one?"

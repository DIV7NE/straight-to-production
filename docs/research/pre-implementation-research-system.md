# Pre-Implementation Research System: Comprehensive Framework

> Research compiled April 2026. Sources: OX Security (300+ repo analysis), Amazon Science (Code LLM hallucination study), Morphik AI, Snyk, OWASP 2025, OpenSSF, AWS Prescriptive Guidance, Martin Fowler (ADRs), Google/Stripe/Uber engineering blogs, PostHog engineering, Addy Osmani, CodePrism, Neo4j Codebase Knowledge Graphs, academic papers on change-impact analysis (William & Mary CS), GitClear AI code quality data, Augment Code COD Model, Anthropic Claude Code community (Reddit 25-tip post), SEI/CMU.

---

## Overview: Why Pre-Implementation Research Prevents Every Mistake

The core insight from all research: **AI-generated code is not inherently less secure or lower quality than human code, but it removes every natural bottleneck that controlled what reaches production** (OX Security, Oct 2025). The solution is not to slow down AI -- it is to front-load research so thoroughly that the AI builds on a foundation of verified truth rather than statistical guesses.

This document defines the complete research system for the STP plugin. Research results flow into PLAN.md as the single source of truth during building.

---

## 1. Existing Codebase Research (Projects That Already Have Code)

### 1.1 Systematic Codebase Mapping

Before adding any feature to an existing codebase, build a complete map. This is not optional -- it is the difference between "feature works in isolation" and "feature integrates seamlessly."

**What to map:**

| Layer | What to Discover | Technique |
|-------|------------------|-----------|
| Routes/Pages | Every URL the app serves | `find` for page/route files, grep for router definitions, framework-specific patterns (Next.js `app/` dir, Express `router.`) |
| API Endpoints | Every endpoint with method, auth, request/response shape | Grep for route handlers, controller definitions, server action exports |
| Components | Every UI component with its props interface | Grep for `export.*function\|export.*const`, component file naming patterns |
| Data Models | Every database table/model with fields and relationships | Read schema files (Prisma schema, migrations, model definitions), query `information_schema` |
| Utilities/Helpers | Every shared function, hook, type, constant | Grep for exports in `lib/`, `utils/`, `hooks/`, `types/` directories |
| External Integrations | Every third-party service connection | Grep for SDK imports (stripe, supabase, clerk, aws), env var references |
| Middleware/Hooks | Every interceptor, middleware, lifecycle hook | Framework-specific patterns (Next.js middleware.ts, Express app.use, React useEffect patterns) |

**Graph-based analysis (state of the art, 2025-2026):**

CodePrism and similar tools build a Universal AST + graph representation. Instead of analyzing files in isolation, they create a unified graph of the entire codebase enabling:
- Symbol resolution across files (47x faster than traditional AST, per CodePrism benchmarks)
- Call graph traversal (who calls whom)
- Dependency graph (who depends on whom)
- Inheritance trees (class hierarchies)

For AI agents without graph DB access, approximate this with:
1. **Import tracing:** For each file, extract all imports and build an adjacency list
2. **Export mapping:** For each module, catalog what it exports (functions, types, constants)
3. **Usage search:** For each export, find all consumers via grep/ripgrep
4. **Dead code detection:** Exports with zero consumers = dead code candidates

### 1.2 Pattern and Convention Detection

**What patterns to detect and follow:**

- **Naming conventions:** How are files, functions, variables, types named? (camelCase, PascalCase, kebab-case, prefixes like `use`, `is`, `get`, `create`)
- **File organization:** Where do different types of code live? (co-location vs separation)
- **Data fetching patterns:** Server components vs client fetch, SWR vs React Query, server actions vs API routes
- **Error handling patterns:** How does existing code handle errors? (try/catch style, error boundaries, Result types)
- **State management:** What state management exists? (React Context, Zustand, Redux, URL state)
- **Auth patterns:** How is authentication/authorization checked in existing code?
- **Testing patterns:** What test framework, what naming, what assertion style, what mocking approach?

**Detection technique:** Read 3-5 representative files from each layer. Extract the pattern. Document it. New code MUST follow existing patterns -- consistency trumps personal preference.

### 1.3 Reusability Discovery

Before writing ANY new function, type, or utility:

1. **Search for existing implementations:** Grep the codebase for the concept (e.g., before writing `formatCurrency`, search for `format`, `currency`, `money`, `price`)
2. **Check shared types:** Look in `types/`, `interfaces/`, `models/` for existing type definitions that cover the new feature's data
3. **Check shared utilities:** Look in `lib/`, `utils/`, `helpers/` for existing functions that do part of what you need
4. **Check shared UI components:** Before creating a new button/modal/form component, check if one exists with configurable props

**Anti-pattern to avoid (OX Security "Vanilla Style", 40-50% prevalence):** AI reimplements functionality from scratch instead of using existing code or proven libraries. This introduces unnecessary risk and violates DRY.

### 1.4 Broken/Incomplete Code Detection

Systematically find what is not working:

- **TypeScript errors:** Run `tsc --noEmit` and catalog every error
- **Lint errors:** Run the project linter and catalog violations
- **Failed tests:** Run the full test suite and catalog failures
- **Console errors:** Start the dev server and check browser console
- **Unused exports:** Find exports with zero imports (potential dead code)
- **TODO/FIXME/HACK comments:** Grep for these markers -- they indicate known incomplete work
- **Empty catch blocks:** Grep for `catch.*\{[\s]*\}` -- errors being silently swallowed
- **Hardcoded values:** Grep for magic numbers, hardcoded URLs, inline credentials

### 1.5 Backward Integration Opportunities

**The question:** What EXISTING features would benefit from the new feature?

**Technique (from feature-integration-practices.md research):**

1. **Feature Touchpoint Map:** For each new data entity, list every existing page/component/endpoint that should display or interact with it
2. **Navigation audit:** Does the nav menu need a new link? Does the dashboard need a new widget?
3. **Search integration:** Should the new entity be searchable? Does the existing search need updating?
4. **Notification integration:** Should existing notification systems reference the new feature?
5. **Analytics integration:** Do existing analytics events need new dimensions?
6. **Cross-feature data flow:** Does the new feature produce data that existing features should consume?

**Stripe's approach:** Every RFC has a mandatory "What existing systems does this affect?" section. Teams at Google, Uber, and Shopify do the same in their design docs.

### 1.6 Gap Detection

**Layer Connectivity Audit (Database-to-UI completeness):**

| Gap Type | Detection Method | Why It Matters |
|----------|-----------------|----------------|
| DB tables with no API endpoint | Compare schema entities against route handlers | Data exists but is inaccessible |
| API endpoints with no UI consumer | Compare route handlers against fetch/API calls in UI | Functionality exists but is invisible |
| Components with no error handling | Grep for components without try/catch, error boundaries, or error state | Silent failures in production |
| Routes with no loading states | Check page/route components for Suspense, loading.tsx, skeleton states | Users see blank screens during data fetches |
| Models with no validation | Check if input data is validated before DB writes (Zod, Yup, manual checks) | Invalid data enters the database |
| Features with no tests | Cross-reference feature files against test files | No regression protection |
| Endpoints with no auth check | Check if protected routes verify authentication/authorization | Security vulnerability |

**Meta's SCARF system** (Systematic Code and Asset Removal Framework) automated deletion of 100M+ lines of dead code over 5 years. The principle: systematically audit for orphaned assets.

---

## 2. Feature Research (How the Proposed Feature Should Actually Work)

### 2.1 Industry Leader Analysis

Before implementing any feature, research how proven companies implement it:

**Research protocol:**
1. **Identify 3-5 industry leaders** who have this exact feature in production
2. **Study their UX:** What is the user flow? What options do they expose? What do they hide?
3. **Study their API design:** What endpoints do they expose? What data shapes do they use?
4. **Study their edge cases:** What happens with empty states, errors, limits, concurrent users?
5. **Study their pricing/business model implications** (if applicable)

**Example -- subscription management:**
- Stripe: upgrade/downgrade with proration, trial periods, cancellation with retention flow
- Paddle: localized pricing, tax handling, dunning management
- Chargebee: plan migration paths, grandfather pricing, usage-based billing

**Example -- authentication:**
- Clerk: multi-factor, social login, organization switching, session management
- Auth0: universal login, passwordless, adaptive MFA, breached password detection
- Supabase Auth: row-level security integration, magic links, phone auth

### 2.2 Proven Patterns (Not Invented Here)

**Research hierarchy (from GSD phase-researcher):**

| Priority | Source | Trust Level |
|----------|--------|-------------|
| 1st | Context7 (library docs) | HIGH -- current API, verified |
| 2nd | Official documentation | HIGH -- authoritative |
| 3rd | WebSearch (verified with official source) | MEDIUM -- needs cross-reference |
| 4th | WebSearch (single source) | LOW -- flag as needing validation |
| 5th | AI training data | LOWEST -- may be stale or wrong |

**Never rely solely on pre-training for implementation patterns.** Context7 resolve-library-id then query-docs BEFORE planning. Tavily/WebSearch for ecosystem research.

### 2.3 Edge Case Research

Common edge cases by feature type:

**Forms/Input:**
- Empty submission, partial submission, duplicate submission (double-click)
- Extremely long input, special characters, Unicode, RTL text
- Browser autofill interference, paste from clipboard
- Mobile keyboard behavior, screen reader interaction

**Payments:**
- Failed charge, partial payment, refund, chargeback, dispute
- Currency conversion, tax calculation, receipt generation
- Subscription upgrade/downgrade proration
- Webhook delivery failure, idempotency

**File Upload:**
- Zero-byte file, oversized file, wrong file type
- Interrupted upload (network failure mid-upload)
- Malicious file (executable disguised as image)
- Concurrent uploads, storage quota exceeded

**Authentication:**
- Expired session, concurrent sessions, session fixation
- Account lockout, password reset race condition
- OAuth provider downtime, token refresh failure
- Organization switching, role changes mid-session

### 2.4 Common Implementation Mistakes

Research what goes WRONG with this feature type. Search for:
- `"[feature type] common mistakes"`
- `"[feature type] production issues"`
- `"[feature type] post-mortem"`
- `"[feature type] security vulnerability"`

**Universal mistakes (from OX Security + GitClear research):**
- Not handling the error path (happy-path-only code)
- Not validating input on both client AND server
- Not considering concurrent access / race conditions
- Not testing with real-world data volumes
- Not planning for the feature to be REMOVED (cleanup)

### 2.5 Security Implications Per Feature

Every feature has a unique attack surface. Research it:

| Feature Type | Key Security Concerns | OWASP Reference |
|-------------|----------------------|-----------------|
| Auth/Login | Credential stuffing, session fixation, weak MFA | A07:2025 Authentication Failures |
| API endpoints | BOLA, injection, excessive data exposure | A01:2025 Broken Access Control, A05:2025 Injection |
| File upload | Path traversal, malicious content, storage abuse | A01:2025, A02:2025 Security Misconfiguration |
| Payments | PCI compliance, webhook verification, idempotency | A04:2025 Cryptographic Failures |
| User input/forms | XSS, SQL injection, CSRF | A05:2025 Injection |
| Search | Query injection, data exposure, DoS via complex queries | A05:2025, A01:2025 |
| Admin panels | Privilege escalation, IDOR, mass assignment | A01:2025, A06:2025 Insecure Design |
| Webhooks | Signature verification, replay attacks, timing attacks | A08:2025 Integrity Failures |

### 2.6 Accessibility Requirements

Every feature must meet WCAG 2.1 AA minimum:
- **Keyboard navigation:** Every interactive element reachable and operable via keyboard
- **Screen reader compatibility:** Proper ARIA labels, roles, live regions
- **Color contrast:** 4.5:1 for normal text, 3:1 for large text
- **Focus management:** Logical focus order, visible focus indicators
- **Error identification:** Errors described in text, not just color

Research feature-specific a11y requirements (e.g., modal dialogs need focus trapping, data tables need proper header associations, charts need text alternatives).

---

## 3. Anti-Hallucination Research

### 3.1 Most Common AI Code Hallucination Patterns

**From Amazon Science (2025) -- three categories of API hallucination:**

1. **Usage of incorrect existing API:** The LLM suggests an API that exists but does not fulfill the task (wrong method for the purpose)
2. **Usage of non-existent API from existing library:** The LLM invents a method on a real library (e.g., `Server::terminate_debuggee()` -- sounds plausible, does not exist)
3. **Usage of entirely non-existent library:** The LLM suggests importing a library that does not exist at all (slopsquatting risk)

**Package hallucination (Snyk, 2025-2026):**
- AI suggests plausible-sounding but non-existent npm/PyPI packages (e.g., `@utils/string-helper`, `pandas-advanced-analytics`)
- Attackers register these hallucinated names with malicious code ("slopsquatting")
- Mitigation: verify every package exists in the registry before `npm install`

**Code behavior hallucination (Undo.io):**
- AI fabricates cause-and-effect stories about code execution paths
- Confidently states "this function returns X when Y" without verifying
- Invents configuration options that do not exist in the library

### 3.2 Verification Protocol (Zero-Trust Code Generation)

**Every import must be verified:**
```
For each import in generated code:
1. Does this package exist in package.json / requirements.txt?
2. If new package: does it exist on npm/PyPI? Check with `npm info` or `pip index versions`
3. Does this specific export exist in the package? Check with Context7 or official docs
4. Is the API signature correct? (parameter names, types, return type)
```

**Every function call must be verified:**
```
For each API/library call in generated code:
1. Does this method exist on this object/class?
2. Are the parameters in the correct order with correct types?
3. Is the return type what the code expects?
4. Has this API been deprecated or changed in the version we're using?
```

**Every config option must be verified:**
```
For each configuration value:
1. Is this a real config key for this tool/framework?
2. Is the value format correct (string vs number vs boolean)?
3. Is this config key still valid in our version?
```

### 3.3 State of the Art: Grounding AI Code in Reality (2025-2026)

**Five core techniques with credible evidence (Medium/AI Hallucination survey):**

1. **Entity-level real-time detection with probes:** Detect hallucination as it is generated
2. **Cross-model validation (multi-LLM consensus):** Ask a second model to verify the first
3. **Knowledge graphs & graph-based fact-checking:** Structured, verifiable data eliminates fabrication
4. **Self-consistency + confidence scoring:** Generate multiple responses and check agreement
5. **Advanced RAG with multi-evidence refinement:** Ground every claim in retrieved documents

**For AI coding specifically:**
- **Documentation Augmented Generation (DAG):** When uncertain about API usage, retrieve official documentation (Amazon Science paper). This is exactly what Context7 does.
- **Build/test verification loops:** The code must compile, pass type-checking, and pass tests. These are non-negotiable automated checks.
- **TDD as anti-hallucination:** Writing tests FIRST forces the AI to define expected behavior before generating implementation. If the test is wrong, the implementation will be wrong but at least we catch it.

### 3.4 How Teams Using Claude Code / Cursor / Copilot Prevent Hallucination

**From Addy Osmani's 2026 LLM coding workflow:**
- Prepend prompts with: "If you are unsure about something or the codebase context is missing, ask for clarification rather than making up an answer"
- Feed the AI ALL the information it needs: code it should modify, technical constraints, known pitfalls
- Load spec.md or plan.md into context before telling it to execute
- Use Context7 MCP or manually copy API docs into the conversation

**From PostHog engineering (8,984 files, 1.6M LOC codebase):**
- Treat large codebases differently from greenfield -- be explicit about what files to read
- Don't trust AI to find the right files -- point it directly
- Always verify AI output against actual codebase state

**From Claude Code community (Reddit 25-tip post):**
- Use `/clear` when the AI gets stuck in a loop (context pollution)
- Write-test-verify cycle: write code, run it, check output, repeat
- Let AI write tests for its own code, then run them independently
- If stuck, use a DIFFERENT model to analyze the bug (breaks the hallucination cycle)

**From ApexData Claude Code workshop:**
- CLAUDE.md files limit scope and hallucinations
- TDD-first approach prevents vague requests from causing hallucinations
- Planning phase (brainstorm, clarify, plan) BEFORE any code generation
- Context7 for library docs prevents stale API knowledge

### 3.5 Verification Steps That Catch Hallucination Before Production

| Step | What It Catches | When to Run |
|------|----------------|-------------|
| TypeScript `tsc --noEmit` | Wrong types, non-existent properties, wrong import paths | After every file change |
| Linter (ESLint/Biome) | Style violations, common errors, unused variables | After every file change |
| Unit tests | Wrong behavior, incorrect return values | After every function |
| Integration tests | Wrong API contracts, broken data flow | After every feature |
| `npm info [package]` | Non-existent packages (slopsquatting) | Before adding any dependency |
| Context7 query | Stale API patterns, deprecated methods | Before using any library API |
| Manual build + run | Runtime errors, SSR/CSR mismatch | Before committing |
| Critic agent review | Architecture mistakes, missing concerns | Before executing plan |

---

## 4. AI Slop Patterns to Avoid

### 4.1 OX Security 10 Critical Anti-Patterns (300+ repo analysis, Oct 2025)

| # | Anti-Pattern | Prevalence | Description | Prevention |
|---|-------------|------------|-------------|------------|
| 1 | **Comments Everywhere** | 90-100% | AI generates excessive inline comments explaining obvious code. Increases cognitive burden, makes review harder. | Strip comments that explain WHAT (obvious). Keep only WHY (non-obvious). |
| 2 | **By-The-Book Fixation** | 80-90% | Rigid adherence to standard patterns even when innovative solutions would be more effective. | Evaluate if the standard pattern fits THIS use case. Allow deviation when justified. |
| 3 | **Over-Specification** | 80-90% | Hyper-specific, single-use solutions that cannot be adapted for other purposes. | Design for reuse. Extract shared logic. Parameterize where reasonable. |
| 4 | **Avoidance of Refactors** | 80-90% | AI excels at generating new code but never refactors existing code. | Explicitly prompt for refactoring. Review for duplication after each feature. |
| 5 | **Bugs Deja-Vu** | 70-80% | Identical bugs appear repeatedly because code is duplicated instead of reused. | Extract shared functions. Fix bugs in ONE place. |
| 6 | **"Worked on My Machine" Syndrome** | 60-70% | Code runs in dev but fails in production (env differences, missing configs). | Test with production-like config. Check env variables, CORS, CSP headers. |
| 7 | **Return of Monoliths** | 40-50% | AI defaults to tightly-coupled monolithic architecture. | Design module boundaries explicitly. Use dependency injection. Keep modules independent. |
| 8 | **Fake Test Coverage** | 40-50% | Tests that inflate coverage metrics but don't validate real logic. | Review test assertions. Tests must fail when behavior changes. Never test implementation details. |
| 9 | **Vanilla Style** | 40-50% | Reimplements functionality from scratch instead of using proven libraries. | Search for existing solutions first. Use established libraries for non-trivial functionality. |
| 10 | **Phantom Bugs** | 20-30% | Over-engineers for improbable edge cases, causing performance degradation. | Focus on REAL edge cases from production data, not imagined ones. |

### 4.2 Additional AI Slop Indicators (Beyond OX Security)

**Design slop:**
- Purple/blue gradients on white cards (the "AI default aesthetic")
- Excessive border-radius, drop shadows, and glassmorphism
- Stock placeholder images and lorem ipsum in committed code
- Inconsistent spacing, padding, typography scale

**Code quality slop:**
- `console.log` statements left in production code
- `try { ... } catch (e) { }` -- empty catch blocks that swallow errors
- `try { ... } catch (e) { console.log(e) }` -- logging but not handling
- Generic variable names: `data`, `result`, `item`, `temp`, `value`, `info`, `stuff`
- God files (1000+ lines), god functions (100+ lines)
- Deeply nested conditionals (3+ levels)
- Copy-pasted code blocks with minor variations (DRY violation)
- Missing cleanup: event listeners, subscriptions, timers, intervals never cleaned up
- Hardcoded strings that should be constants or i18n keys
- `any` type in TypeScript (defeats the purpose of type safety)
- Default exports everywhere (makes refactoring and tree-shaking harder)

**Test slop:**
- Tests that always pass regardless of implementation (`expect(true).toBe(true)`)
- Tests that test the mock, not the behavior
- Tests with no assertions
- Tests that test implementation details (coupling test to internal structure)
- Snapshot tests that nobody reviews
- Missing edge case tests (only happy path)

**Architecture slop:**
- No separation of concerns (business logic mixed with UI rendering)
- Direct database queries in route handlers (no service layer)
- Authentication checks scattered per-route instead of centralized middleware
- Error handling per-endpoint instead of centralized error handler
- No input validation layer (trusting client-side validation alone)

### 4.3 The Senior Engineer Test

AI-generated code must be indistinguishable from senior engineer output. A senior engineer would:
- Delete unnecessary comments
- Extract repeated logic into shared functions
- Name variables after their domain meaning, not their data type
- Handle errors specifically (not generic catch-all)
- Write tests that test behavior, not implementation
- Consider what happens when things fail, not just when they succeed
- Consider concurrent access, not just single-user scenarios
- Clean up resources (listeners, subscriptions, connections)
- Use existing patterns in the codebase, not introduce new ones

---

## 5. Security Research Per Feature

### 5.1 OWASP Top 10 2025 (Updated List)

| # | Category | What to Check |
|---|----------|---------------|
| A01 | Broken Access Control | Object-level auth, function-level auth, CORS, directory traversal. Now includes SSRF. |
| A02 | Security Misconfiguration | Default credentials, unnecessary features enabled, missing security headers, verbose errors. |
| A03 | Software Supply Chain Failures | Vulnerable dependencies, unverified packages, compromised build pipelines. NEW in 2025. |
| A04 | Cryptographic Failures | Weak algorithms, exposed keys, missing encryption at rest/transit. |
| A05 | Injection | SQL, NoSQL, OS command, LDAP, XSS. Use parameterized queries, escape output. |
| A06 | Insecure Design | Missing threat modeling, insecure business logic, no abuse case analysis. |
| A07 | Authentication Failures | Weak passwords, missing MFA, session fixation, credential stuffing. Now covers SSO/federated login. |
| A08 | Integrity Failures | Missing code signing, insecure CI/CD, unverified updates. |
| A09 | Logging & Alerting Failures | Missing audit logs, no alerting on failures, logs stored only locally. |
| A10 | Mishandling of Exceptional Conditions | NEW in 2025. Unhandled exceptions, missing error boundaries, error info leakage. |

### 5.2 Per-Feature Security Research Protocol

For EACH feature, before implementation:

```
SECURITY RESEARCH CHECKLIST:

1. ATTACK SURFACE: What new attack surface does this feature create?
   - New endpoints? New input fields? New file handling? New auth flows?

2. AUTH REQUIREMENTS: What authentication/authorization does this feature need?
   - Who should access this? What role? What object-level permissions?
   - Is there a privilege escalation path?

3. SENSITIVE DATA: Does this feature handle sensitive data?
   - PII? Payment info? Health data? Credentials?
   - How is it encrypted in transit and at rest?
   - Is it logged? (It shouldn't be)

4. TRUST BOUNDARIES: Where does trust change?
   - Client to server? Server to third-party API? User input to database?
   - Each boundary needs validation

5. OWASP MAPPING: Which OWASP Top 10 categories apply?
   - Map each concern to specific OWASP category
   - Apply the prevention strategies from that category

6. DEPENDENCY RISK: What new dependencies does this feature add?
   - Run `npm audit` / `pip audit` after adding
   - Check package download counts, maintenance status, known CVEs
   - Verify package exists (anti-slopsquatting)

7. SUPPLY CHAIN: Are build/deploy pipelines affected?
   - New env variables? New secrets? New third-party integrations?
```

### 5.3 Known Vulnerability Patterns by Stack

**Next.js specific:**
- Server action input not validated (direct database mutation)
- `"use server"` on functions that should be client-only
- Sensitive data in RSC props serialized to client
- Missing `revalidatePath`/`revalidateTag` after mutations (stale cache)

**Supabase specific:**
- Row Level Security (RLS) not enabled on tables
- RLS policies too permissive (checking user_id but not org membership)
- Service role key exposed to client
- Realtime subscriptions without proper auth filtering

**Clerk specific:**
- Missing middleware protection on API routes
- `auth()` not checked in server actions
- Organization-level permissions not enforced
- Webhook signature verification missing

---

## 6. Architecture Research

### 6.1 Architecture Decision Records (ADRs)

**From Martin Fowler, AWS Prescriptive Guidance, Microsoft Well-Architected:**

Every architecturally significant decision must be documented:

```markdown
# ADR-NNN: [Decision Title]

## Status: proposed | accepted | superseded

## Context
[What problem needs solving? What forces are at play?]

## Decision
[What is the change that we're making?]

## Alternatives Considered
[What other options were evaluated? Why were they rejected?]

## Consequences
[What are the positive and negative results of this decision?]

## Confidence Level
[HIGH | MEDIUM | LOW -- how certain are we this is right?]
```

**What constitutes an architecturally significant decision (AWS):**
- Structure (patterns like microservices, monolith, serverless)
- Non-functional requirements (security, availability, scalability)
- Dependencies (coupling between components)
- Interfaces (APIs and published contracts)
- Construction techniques (libraries, frameworks, tools)

### 6.2 Architecture Pattern Selection

**Before choosing, research:**

| Decision | Research Questions | Sources |
|----------|-------------------|---------|
| Monolith vs microservices | Team size? Deployment frequency? Domain boundaries clear? | Context7 for framework patterns |
| Server actions vs API routes | Need external consumers? Need caching? Complex auth? | Framework docs via Context7 |
| SQL vs NoSQL | Data relationships? Query patterns? Consistency requirements? | Database benchmarks, stack-specific docs |
| Normalization vs denormalization | Read-heavy or write-heavy? Need joins? Analytics use case? | DigitalOcean DB guide, CelerData comparison |
| Caching strategy | What data is read-frequently/write-rarely? Consistency requirements? | Cache-aside vs read-through vs write-through analysis |

### 6.3 Database Design Research

**Normalization (from DigitalOcean, CelerData, academic research):**
- **Normalize for OLTP** (transactional systems): reduces redundancy, enforces integrity, better for writes
- **Denormalize for OLAP** (analytics/reporting): faster reads, fewer joins, better for dashboards
- **Hybrid approach:** Normalized core tables + denormalized views/materialized views for read-heavy paths
- **Before deciding:** Map your query patterns. If 80% of queries need joins across 4+ tables, consider strategic denormalization for those paths.

### 6.4 Caching Strategy Research

**Five caching strategies (choose based on workload):**

| Strategy | How It Works | Best For | Trade-off |
|----------|-------------|----------|-----------|
| Cache-aside | App checks cache, falls back to DB, populates cache | General purpose, read-heavy | Cache can be stale |
| Read-through | Cache loads from DB on miss automatically | Simplified read path | Cache must know DB schema |
| Write-through | Write to cache AND DB simultaneously | Strong consistency needed | Higher write latency |
| Write-behind | Write to cache, async persist to DB | Write-heavy workloads | Risk of data loss on cache failure |
| Write-around | Write to DB only, cache populates on read | Infrequently-read writes | First read is always slow |

**Layer-by-layer caching (from Budiwidhiyanto, Vijay research):**
- Browser cache: static assets, API responses with proper Cache-Control headers
- CDN cache: static content, edge-cached API responses
- Application cache: in-memory LRU for hot data (React.cache() for per-request dedup)
- Database cache: query result caching, connection pooling

### 6.5 Performance Research Before Building

Before committing to an architecture:
1. **Estimate data volumes:** How many records in year 1? Year 3? Year 5?
2. **Estimate query patterns:** Which queries run most frequently? Which are most expensive?
3. **Estimate concurrent users:** Peak load? Burst patterns?
4. **Research comparable systems:** How do similar products handle this scale?
5. **Identify bottleneck candidates:** Which component will fail first at 10x load?

---

## 7. Backward Integration Research

### 7.1 Finding All Consumers of a Data Model

When adding a new feature that touches an existing data model:

```
CONSUMER DISCOVERY PROTOCOL:

1. Find the model/schema definition
2. Search for ALL imports of that model/type across the codebase
3. For each consumer, determine:
   - Does it READ from this model? (needs to display new data?)
   - Does it WRITE to this model? (needs to include new fields?)
   - Does it VALIDATE this model? (Zod schemas, form validators need updating?)
   - Does it SERIALIZE this model? (API responses, webhook payloads need updating?)
4. List every consumer with the specific update needed
```

### 7.2 Tracing UI to API to Database Chains

For each existing feature that might be affected:

```
CHAIN TRACE (top-down):
UI Component → API fetch/server action → Route handler/Server action → Service/Business logic → Database query → Table

CHAIN TRACE (bottom-up):
Table → Which queries read/write → Which services use those queries → Which handlers call those services → Which UI components call those handlers
```

**Tooling:** Grep for the table name, then trace outward through the call chain. Every link in the chain may need updating.

### 7.3 Detecting Features That Should Be Connected But Are Not

**Signals of missing connections:**
- A dashboard that does not display ALL entity types in the system
- A search feature that does not index ALL searchable entities
- A notification system that does not cover ALL user-affecting events
- An activity log that does not track ALL significant actions
- An admin panel that does not manage ALL user-created entities
- A permissions system that does not protect ALL sensitive operations

**The Coherence Test:** Open the app. Create a new [entity from new feature]. Now navigate to EVERY existing page. Does the new entity appear where it should? If not, those are backward integration tasks.

### 7.4 Improvement Opportunities in Existing Code

When adding a new feature, look for:
- **Shared abstractions:** Could the new feature and an existing feature share a component, hook, or utility?
- **Performance improvements:** Does the new feature enable batch operations where existing features do N+1 queries?
- **UX improvements:** Does the new feature provide context that makes existing features more useful?
- **Data enrichment:** Does the new feature's data make existing reports/dashboards more valuable?

---

## 8. Gap Analysis

### 8.1 Systematic Completeness Audit

**The Full-Stack Feature Completeness Matrix:**

For EACH feature in the application, check every layer:

| Layer | Question | Gap if Missing |
|-------|----------|----------------|
| Database | Schema defined? Migrations exist? Indexes on query columns? | Data layer incomplete |
| Validation | Input validated on server? Zod/Yup schemas? | Invalid data enters DB |
| API/Routes | Endpoints exist? Auth protected? Rate limited? | Feature inaccessible or insecure |
| Business Logic | Core operations implemented? Edge cases handled? | Feature partially works |
| UI - Happy Path | Main flow works? Forms submit? Data displays? | Feature non-functional |
| UI - Empty State | What shows when there's no data? | Blank screen confusion |
| UI - Loading State | Skeleton/spinner during fetch? | Perceived performance issue |
| UI - Error State | Error messages shown? Retry option? | Silent failures |
| Error Handling | Errors caught? Logged? User-friendly messages? | Production debugging impossible |
| Tests - Unit | Core functions tested? Edge cases tested? | Regression risk |
| Tests - Integration | API contracts verified? Data flow tested? | Integration breakage risk |
| Accessibility | Keyboard nav? Screen reader? Color contrast? | Excludes users, legal risk |
| Security | Auth checked? Input sanitized? CORS configured? | Vulnerability |
| Observability | Errors logged? Metrics tracked? Alerts configured? | Blind to production issues |

### 8.2 Automated Gap Detection Commands

```bash
# Database tables with no corresponding API endpoint
# Compare schema entities against route handler files
diff <(grep -oP 'model \K\w+' prisma/schema.prisma | sort) \
     <(grep -rloP 'findMany|findFirst|create|update|delete' app/api/ | xargs grep -oP '\.\K\w+(?=\.)' | sort -u) 

# API endpoints with no UI consumer
# Find all API routes, then search for fetch calls to each
find app/api -name 'route.ts' -exec echo {} \; | while read route; do
  endpoint=$(echo $route | sed 's|app/api||;s|/route.ts||')
  grep -rl "$endpoint" app/ --include='*.tsx' --include='*.ts' | grep -v api | wc -l
done

# Components with no tests
# Compare component files against test files
diff <(find app components -name '*.tsx' | sort) \
     <(find __tests__ tests -name '*.test.*' | sed 's/.test//' | sort)

# Routes with no loading state
find app -name 'page.tsx' | while read page; do
  dir=$(dirname $page)
  [ ! -f "$dir/loading.tsx" ] && echo "Missing loading.tsx: $dir"
done

# Find empty catch blocks
grep -rn 'catch.*{' --include='*.ts' --include='*.tsx' -A 1 | grep -B 1 '^\s*}'
```

### 8.3 Priority-Based Gap Remediation

Not all gaps are equal. Prioritize by:

1. **Security gaps** (CRITICAL): Missing auth, unsanitized input, exposed secrets
2. **Data integrity gaps** (HIGH): Missing validation, no migration rollback plan
3. **User experience gaps** (MEDIUM): Missing loading states, empty states, error states
4. **Test coverage gaps** (MEDIUM): Features with no tests, critical paths untested
5. **Observability gaps** (MEDIUM): No error logging, no performance monitoring
6. **Accessibility gaps** (MEDIUM-HIGH): Legal requirement (EAA, ADA), excludes users
7. **Documentation gaps** (LOW): Missing API docs, missing ADRs

---

## 9. Integration Into Pilot Workflow

### 9.1 Research Flow

```
/stp:new (NEW project)
  └── Domain research (Phase 1 of /stp:plan)
       └── Technical research via Context7 (Phase 1b)
            └── Architecture research (Phase 2-4)
                 └── All research → PLAN.md

/stp:feature (EXISTING codebase)
  └── Step 1: Context (read PLAN.md, CLAUDE.md)
       └── Step 2: Impact Analysis
            ├── Codebase mapping (1.1)
            ├── Backward integration discovery (1.5)
            ├── Gap detection (1.6)
            └── Feature research (2.1-2.6)
                 ├── Industry leader analysis
                 ├── Edge case research
                 ├── Security research (5.1-5.3)
                 └── Anti-hallucination verification (3.1-3.5)
                      └── All findings → Feature plan → Build
```

### 9.2 Research Output Format (for PLAN.md)

Every research finding must include:

```markdown
## Research: [Topic]

### Finding
[What was discovered]

### Source
[HIGH/MEDIUM/LOW confidence] — [Source name and URL/reference]

### Implication for This Project
[How this finding affects our implementation]

### Action Item
[Specific thing to do or verify during implementation]
```

### 9.3 The Research-to-Build Bridge

Research is only valuable if it reaches the builder. Every research finding must map to:
1. A specific PLAN.md section (architecture, data model, API design, etc.)
2. A specific test case (edge cases become test assertions)
3. A specific checklist item (security concerns become verification steps)
4. A specific code pattern (proven patterns become implementation guidance)

---

## 10. Quick Reference: Research Checklist by Scenario

### Adding a Feature to an Existing Codebase
- [ ] Map existing routes, endpoints, components, models
- [ ] Detect existing patterns and conventions
- [ ] Search for reusable code before writing new
- [ ] Run full codebase health check (types, lint, tests)
- [ ] Build Feature Touchpoint Map (backward integration)
- [ ] Run Layer Connectivity Audit (gap detection)
- [ ] Research how industry leaders implement this feature
- [ ] Research edge cases specific to this feature type
- [ ] Research security implications (OWASP mapping)
- [ ] Verify all dependencies exist and are not hallucinated
- [ ] Document architecture decisions as ADRs

### Starting a New Project
- [ ] Research domain requirements (legal, compliance, user expectations)
- [ ] Research comparable products (3-5 industry leaders)
- [ ] Research tech stack via Context7 (current APIs, not stale)
- [ ] Research architecture patterns for this project type
- [ ] Research database design (normalize vs denormalize)
- [ ] Research caching needs
- [ ] Research security requirements per OWASP 2025
- [ ] Research accessibility requirements (WCAG 2.1 AA)
- [ ] Document all decisions as ADRs with alternatives considered
- [ ] Verify plan with Critic agent before building

### Before Every Code Generation Session
- [ ] Context7: resolve + query for every library being used
- [ ] Read PLAN.md and CLAUDE.md into context
- [ ] Read existing code patterns (3-5 representative files)
- [ ] Verify imports: does every package exist? Does every export exist?
- [ ] Run type-check and linter after generation
- [ ] Run tests after generation
- [ ] Check for AI slop: comments, names, error handling, cleanup

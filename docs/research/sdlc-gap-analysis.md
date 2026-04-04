# STP v0.2.0 SDLC Gap Analysis

**Date:** 2026-04-01
**Methodology:** Compared Pilot's current workflow against modern SDLC practices from DORA, OWASP SAMM, Shape Up, YC practices, AWS/Google Cloud architecture guides, and 2025-2026 industry research.

---

## Executive Summary

STP v0.2.0 covers the core build loop well: requirements (PRD.md), architecture (PLAN.md), TDD implementation (/stp:feature), and quality evaluation (/stp:evaluate). The primary gaps are in **what happens before first deploy** (CI/CD, deployment readiness) and **what happens after deploy** (monitoring, maintenance, compliance). These are precisely the areas where a solo developer most often fails -- not because they can't code, but because they forget to set up the infrastructure around the code.

14 gaps identified. 6 are critical for solo developers shipping to production.

---

## Gap Analysis by Priority

### TIER 1: CRITICAL -- Will cause production incidents or legal liability if missing

---

#### Gap 1: CI/CD Pipeline Setup
**What's Missing:** STP has zero CI/CD. No GitHub Actions workflow, no pre-deploy checks, no automated test runs on push. The Stop hook runs locally, but nothing prevents deploying broken code.

**Why It Matters for Solo Devs:** You are the only person who will catch a broken deploy. Without CI, you WILL push untested code at 11pm when tired. GitHub Actions is free for 2,000 min/month on public repos. DORA 2025 research shows deployment frequency is the #1 predictor of software delivery performance. Solo devs who deploy manually deploy less often, accumulate bigger changesets, and have higher change failure rates.

**What Industry Says:**
- DORA 2025: Teams with CI/CD have 46x more frequent deployments and 440x faster lead time.
- GitHub Actions dominates personal projects (free tier, tight integration). Runner pricing dropped 39% in Jan 2026.
- CircleCI AI and Harness identified as leading CI/CD-AI tools for 2026.

**Current Pilot Coverage:** The Stop hook (type check + tests) runs locally only. No remote verification.

**Recommendation:** **Bake into /stp:new** -- generate a minimal CI workflow file (.github/workflows/ci.yml) during project setup. Contents: run type check + tests + lint on push/PR. Stack-detected (same logic as stop-verify.sh). Add a `/stp:deploy` command or bake deploy config into /stp:plan.

**Effort:** LOW -- template a GitHub Actions YAML per stack. The stop-verify.sh logic already exists.

---

#### Gap 2: Monitoring & Error Tracking Setup
**What's Missing:** Pilot mentions "error tracking service connected" in the error-handling reference checklist, and OWASP A09 says "implement error tracking (Sentry, Datadog, or equivalent)." But nothing in /stp:new, /stp:plan, or /stp:feature actually sets up monitoring.

**Why It Matters for Solo Devs:** You have no team watching dashboards. If your app breaks in production at 3am, you won't know until users complain (or leave). Sentry has a free tier (5K errors/month). Without it, you're flying blind.

**What Industry Says:**
- "Observability is no longer optional -- it must exist from day one" (2026 production readiness guides).
- SRE Golden Signals: latency, traffic, errors, saturation.
- Sentry for solo devs (transparent pricing, spike protection). Datadog for scale (but complex pricing).
- SigNoz production readiness checklist: error tracking, structured logging, health checks, alerting.

**Current Pilot Coverage:** Reference file mentions it. Critic criterion 6 (Production Readiness) checks if error handling exists but NOT if monitoring is connected.

**Recommendation:** **Add to /stp:plan** as a required section: "Monitoring & Observability" with specific tools chosen per stack. Add a checklist item in /stp:feature for the Foundation milestone: "Set up error tracking (Sentry/equivalent)." Add to Critic criterion 6: "Error tracking service configured and receiving events?"

**Effort:** LOW -- add a section to plan.md template and a reference file.

---

#### Gap 3: Database Migration & Rollback Strategy
**What's Missing:** /stp:plan designs data models (tables, fields, relationships, indexes) but says nothing about: migration files, migration ordering, rollback procedures, seed data for development, backup strategy before schema changes.

**Why It Matters for Solo Devs:** Your first production database migration WILL go wrong. Without a rollback plan, you lose user data. Without seed data, every new dev environment starts empty and you can't reproduce bugs. ORM migration features are convenient but "schema getting out of sync between dev and production" is the #1 migration problem for solo devs.

**What Industry Says:**
- Execute schema changes in stages: add new columns, migrate data, drop old columns in separate migrations.
- Before any migration: take a complete, verified backup stored in at least two locations.
- Migrations should be reversible with explicit up/down or do/undo steps.
- Phased (trickle) migration reduces risk vs. big-bang migration.

**Current Pilot Coverage:** PLAN.md designs the schema. Nothing about migrations, rollbacks, or seed data.

**Recommendation:** **Add to /stp:plan Phase 3 (Data Models):** After designing the schema, specify: migration strategy (framework's migration tool), seed data script, backup-before-migrate procedure. Add a reference file: `references/production/database-migrations.md`.

**Effort:** LOW -- add to plan template and one reference file.

---

#### Gap 4: Dependency Security & Supply Chain
**What's Missing:** No dependency auditing (npm audit, pip audit, cargo audit). No lockfile verification. No license compliance checking. OWASP A06 (Vulnerable Components) is in the reference file but nothing enforces it.

**Why It Matters for Solo Devs:** npm supply chain attacks doubled in 2025. In Sept 2025, attackers hijacked 18 popular npm packages (debug, chalk) with 2.6B+ weekly downloads. In Jan 2026, "PackageGate" disclosed 6 zero-days in npm/pnpm/bun. You install packages constantly with AI-assisted coding -- each one is an attack surface. A single vulnerable dependency can expose your users' data.

**What Industry Says:**
- CISA 2025: SBOMs (Software Bills of Materials) moving from optional to required.
- Run audits in CI/CD and fail builds on high-severity issues.
- Evaluate new dependencies before adding: check maintainers, recent activity, download patterns.
- License compliance matters: GPL in your MIT project = legal liability.

**Current Pilot Coverage:** OWASP reference file A06 mentions "keep dependencies updated, monitor for CVEs." Nothing enforces it.

**Recommendation:** **Add to CI pipeline** (Gap 1): `npm audit --audit-level=high` (or equivalent) as a CI step. **Add to /stp:plan**: dependency review section. **Consider a reference file:** `references/security/dependency-security.md` covering audit commands per stack, lockfile hygiene, license checking.

**Effort:** LOW -- one CI step per stack + one reference file.

---

#### Gap 5: E2E Testing for Critical User Journeys
**What's Missing:** Pilot does TDD (unit tests first) and integration tests at milestone boundaries. But there's no automated E2E browser testing (Playwright/Cypress). The Critic checks if tests exist but doesn't verify user journeys work end-to-end in a real browser.

**Why It Matters for Solo Devs:** Unit tests verify functions work. Integration tests verify features connect. Neither verifies that a real user can sign up, create an invoice, and send it -- in an actual browser, with actual auth flows, across actual page navigations. The testing trophy/pyramid in 2026: 70% unit, 20% integration, 10% E2E -- that 10% catches the bugs that matter most to users.

**What Industry Says:**
- Playwright is the dominant E2E framework in 2026, with Vitest for unit/integration.
- "E2E tests should cover user journeys, not implementation details."
- Best practice: 3-5 critical path E2E tests, not 100. Happy path + one error path per core workflow.
- Playwright + Vitest together: Vitest for speed, Playwright for real-world coverage.

**Current Pilot Coverage:** /stp:feature Step 6 mentions "integration/E2E tests for the milestone workflow" at milestone boundaries. But no tooling setup, no browser automation, and the Critic doesn't verify E2E coverage.

**Recommendation:** **Add to /stp:plan:** E2E test strategy section. Which user journeys get E2E tests? **Add to /stp:new:** Install E2E framework (Playwright) during project setup for web projects. **Add to milestone completion:** Explicit E2E test execution, not just integration tests. Modify the Critic to check for E2E test files.

**Effort:** MEDIUM -- requires E2E framework setup per stack template.

---

#### Gap 6: Legal/Compliance Baseline (EAA, GDPR, Licenses)
**What's Missing:** No mention of GDPR, European Accessibility Act (EAA), privacy policy, terms of service, cookie consent, or data processing agreements.

**Why It Matters for Solo Devs:** The European Accessibility Act became mandatory June 2025 across 27 EU states. It mandates EN 301 549 (WCAG 2.1 AA) for any SaaS accessible to EU consumers. Microbusinesses (<10 employees, <2M EUR revenue) have limited exceptions, but all are encouraged to comply. GDPR fines are real. If your SaaS collects any user data (email, name, usage analytics), you need a privacy policy and data handling practices. Cookie consent is legally required in the EU.

**What Industry Says:**
- EAA is "the next GDPR" for digital accessibility. Enforcement agencies across 27 states are actively investigating.
- Unlike GDPR (policies + procedures), EAA requires your actual code to be accessible.
- License compliance: GPL in your MIT project = legal liability. AI-generated code may include snippets from GPL-licensed sources.

**Current Pilot Coverage:** WCAG AA reference files exist (accessibility). OWASP covers security. Nothing covers legal compliance, privacy, or license auditing.

**Recommendation:** **Add a reference file:** `references/legal/compliance-baseline.md` covering: privacy policy requirements, cookie consent, GDPR data handling basics, EAA accessibility mandate, license auditing for dependencies. **Add to /stp:new Step 3** (Surface What They Didn't Think Of): include legal compliance items. **Add to /stp:plan:** compliance section with specific requirements per market (EU, US, global).

**Effort:** LOW -- one reference file + additions to existing templates.

---

### TIER 2: HIGH -- Significant quality or velocity impact

---

#### Gap 7: Code Quality Automation (Lint, Format, Complexity)
**What's Missing:** Pilot type-checks after edits and runs tests before stop. But there's no linting (ESLint, Ruff, clippy), no formatting (Prettier, Black, rustfmt), no complexity analysis, no dead code detection.

**Why It Matters for Solo Devs:** AI-generated code accumulates inconsistency. One session uses single quotes, the next double quotes. Function complexity creeps up without anyone noticing. Dead code accumulates. Linting catches bugs type checkers miss (unused variables, unreachable code, unsafe patterns). Formatting removes all style debates from your brain.

**What Industry Says:**
- "Integrate linters, formatters, and security scanners into your CI pipeline" (SmartSDLC.dev 2026).
- Lint + format on save is the minimum. Lint in CI is the standard.
- Complexity analysis (cognitive complexity) catches functions that are too complex to maintain.

**Current Pilot Coverage:** Type checking only. The Critic visually inspects code quality but doesn't run linters.

**Recommendation:** **Add to /stp:new:** Set up linter + formatter during project scaffolding (ESLint + Prettier for JS/TS, Ruff for Python, clippy for Rust, etc.). **Add to post-edit hook or CI:** Run linter. **Add to stop-verify.sh:** Run lint check alongside type check.

**Effort:** LOW -- add to stack templates and extend hooks.

---

#### Gap 8: Architecture Decision Records (ADRs)
**What's Missing:** Pilot captures architecture decisions in PRD.md (the proposal) and PLAN.md (the design). But as the project evolves, decisions change. There's no structured record of WHY a decision changed, what was considered, and what was rejected.

**Why It Matters for Solo Devs:** Three months later, you won't remember why you chose Supabase over Firebase, or why you structured the API that way. ADRs are "short documents that capture and explain a single decision" (Martin Fowler). They're your future self's lifeline.

**What Industry Says:**
- ADRs adopted by AWS Well-Architected Framework (2024), Google Cloud Architecture Center, and Azure.
- "Documents should be short, just a couple of pages" -- not heavyweight.
- Key components: decision, context, alternatives considered, consequences, status.
- Pilot's PRD.md already captures initial decisions with alternatives -- it just doesn't evolve.

**Current Pilot Coverage:** PRD.md captures initial architecture proposal with alternatives. PLAN.md has a "Technical Decisions Log" placeholder. But nothing enforces updates when decisions change during /stp:feature.

**Recommendation:** **Lightweight ADR tracking in PRD.md**: When /stp:feature changes a technical decision, append to the Technical Decisions Log in PRD.md with date, decision, context, alternatives. This is already half-built -- just needs enforcement. No separate ADR files needed for solo devs.

**Effort:** VERY LOW -- add instruction to /stp:feature to update PRD.md when decisions change.

---

#### Gap 9: Deployment Readiness Checklist
**What's Missing:** No `/stp:deploy` command. No pre-deploy checklist. No environment variable validation. No health check endpoint verification. No rollback plan.

**Why It Matters for Solo Devs:** First deploy is terrifying. You forget environment variables, the health check endpoint doesn't exist, there's no rollback plan. Vercel/Railway/Fly.io make deploys easy but don't verify your app is READY to deploy.

**What Industry Says:**
- Production readiness checklists: health checks, structured logging, environment validation, graceful shutdown, rate limiting, CORS, security headers.
- Vercel supports instant rollbacks and Rolling Releases (gradual rollout) natively.
- Feature flags decouple deployment from release -- deploy code, enable features separately.

**Current Pilot Coverage:** /stp:plan doesn't include deployment planning. The Critic checks production readiness (error handling, loading states) but not deployment infrastructure.

**Recommendation:** **Add to /stp:plan:** Deployment section (target platform, environment variables needed, health check endpoint, rollback plan). **Consider /stp:deploy or a deployment reference file** with pre-deploy checklist per platform.

**Effort:** MEDIUM -- reference file + additions to plan template.

---

#### Gap 10: Acceptance Criteria & User Stories in PRD
**What's Missing:** PRD.md captures features as bullet points. There are no formal acceptance criteria (Given/When/Then), no user stories, no personas beyond "who it's for."

**Why It Matters for Solo Devs:** Without acceptance criteria, the Critic has nothing specific to verify against. "User can create an invoice" vs. "Given a logged-in user, when they submit an invoice with at least one line item, then the invoice is created with status 'draft' and appears in their dashboard within 2 seconds." The second is testable. The first is vague.

**What Industry Says:**
- Agile: Every feature needs acceptance criteria that define "done."
- Shape Up: "Appetites" + "bets" -- define the shape of the solution, not a backlog of stories. But still define what's in scope and what's out.
- BDD (Behavior-Driven Development): Given/When/Then format bridges product requirements and test cases.

**Current Pilot Coverage:** PRD.md has features as bullets. PLAN.md has test cases per feature. The test cases ARE implicit acceptance criteria -- but they live in PLAN.md, not PRD.md, and the Critic grades against PRD.md.

**Recommendation:** **Enhance /stp:plan Phase 5**: Each feature's test cases should explicitly map to acceptance criteria in the PRD. Or simpler: add acceptance criteria to PRD.md during /stp:plan, derived from the test cases. This creates a traceable chain: PRD requirement -> acceptance criteria -> test cases -> implementation.

**Effort:** LOW -- modify plan.md and PRD.md templates.

---

### TIER 3: MEDIUM -- Quality of life and professional maturity

---

#### Gap 11: API Documentation (OpenAPI/Swagger)
**What's Missing:** /stp:plan designs APIs with endpoints, auth, request/response shapes. But no OpenAPI spec is generated. No Swagger UI. No API documentation for consumers.

**Why It Matters for Solo Devs:** If your SaaS has a public API, or if you ever want a mobile app to consume your backend, you need API docs. OpenAPI specs can auto-generate client SDKs, validate requests, and serve as living documentation. For internal-only APIs, this is nice-to-have. For any API with external consumers, it's essential.

**Current Pilot Coverage:** PLAN.md has API design with endpoints and shapes. Not in a machine-readable format.

**Recommendation:** **Add to /stp:plan Phase 4:** Generate an OpenAPI spec alongside the API design. For many frameworks (FastAPI, Spring Boot), this is auto-generated from code annotations. Add to Critic: check if API documentation matches implementation.

**Effort:** MEDIUM -- stack-dependent. Some stacks auto-generate, others need manual spec files.

---

#### Gap 12: Performance Testing (Lighthouse, Bundle Analysis)
**What's Missing:** STP has performance reference files (Core Web Vitals, bundle optimization). The Critic checks for sequential queries and lazy loading. But no automated performance testing: no Lighthouse CI, no bundle size tracking, no load testing.

**Why It Matters for Solo Devs:** Performance degrades gradually. Each feature adds JavaScript, each query adds latency. Without automated measurement, you don't notice until the app feels slow. Lighthouse CI in GitHub Actions is free and catches regressions.

**Current Pilot Coverage:** Reference files with targets. Critic manual inspection.

**Recommendation:** **Add to CI pipeline** (Gap 1): Lighthouse CI for web projects, bundle size check. Not a separate command -- just CI steps. Add to Critic: check bundle size, check Lighthouse score if available.

**Effort:** LOW in CI -- one Action step.

---

#### Gap 13: Automated Accessibility Testing
**What's Missing:** STP has excellent WCAG AA reference files (4 files covering POUR, keyboard nav, screen reader, color contrast). The Critic visually checks heading hierarchy, alt text, keyboard access. But no automated a11y testing tool runs.

**Why It Matters for Solo Devs:** The EAA (Gap 6) mandates WCAG 2.1 AA compliance. Manual Critic checks catch obvious issues but miss subtle ones. axe-core catches 57% of WCAG issues automatically. Playwright has built-in axe integration. Running axe in E2E tests (Gap 5) catches accessibility regressions automatically.

**Current Pilot Coverage:** Reference files + Critic manual checking.

**Recommendation:** **Combine with Gap 5 (E2E):** Add axe-core to Playwright E2E tests. One line: `await expect(page).toPassAxeTests()`. Add to Critic: check if axe is configured in E2E tests.

**Effort:** VERY LOW if E2E testing is added.

---

#### Gap 14: Changelog & Release Notes
**What's Missing:** No changelog generation. No version tagging strategy. Git commits exist but no user-facing release notes.

**Why It Matters for Solo Devs:** If users are paying (SaaS), they expect to know what changed. A changelog also helps YOU remember what shipped when. Conventional Commits + auto-generated changelogs are near-zero effort.

**Current Pilot Coverage:** Atomic git commits per feature. No changelog.

**Recommendation:** **Add to CLAUDE.md templates:** Conventional Commits format (feat:, fix:, docs:). **Add to /stp:plan or a future /stp:ship command:** Auto-generate CHANGELOG.md from git log before release. This is low-priority and can be a reference file, not a command.

**Effort:** VERY LOW -- commit format + one script.

---

## Gaps NOT Recommended for Pilot

These are real SDLC concerns but not appropriate for Pilot's scope:

| Practice | Why NOT for Pilot |
|----------|-------------------|
| **Threat modeling / STRIDE** | Opus can do this when told to. Heavy process for solo dev pre-launch. Add as a /stp:plan Phase 1.5 for apps handling sensitive data, not for all projects. |
| **Load/stress testing** | Pre-launch solo dev won't have enough traffic to matter. Revisit post-traction. |
| **Visual regression testing** | Nice but not critical. Chromatic/Percy add complexity. The Critic's design quality check covers the 80%. |
| **Contract testing** | Only matters with multiple services/teams. Solo dev = one service. |
| **SBOM generation** | CISA guidance is evolving. Not enforced for solo devs yet. Mention in dependency-security reference file. |
| **Blue-green / canary deployment** | Vercel/Railway handle this natively. No Pilot involvement needed. |
| **Incident response runbook** | Pre-launch, monitoring (Gap 2) is sufficient. Add after first incident. |
| **Contributing guide** | Solo dev. Add when team grows. |

---

## Implementation Priority Matrix

| Priority | Gap | Effort | Recommendation |
|----------|-----|--------|----------------|
| 1 | CI/CD Pipeline (Gap 1) | LOW | Bake into /stp:new -- generate CI workflow per stack |
| 2 | Monitoring Setup (Gap 2) | LOW | Add to /stp:plan + Critic + reference file |
| 3 | DB Migration Strategy (Gap 3) | LOW | Add to /stp:plan Phase 3 + reference file |
| 4 | Dependency Security (Gap 4) | LOW | Add to CI + reference file |
| 5 | Legal/Compliance (Gap 6) | LOW | Reference file + additions to /stp:new and /stp:plan |
| 6 | Code Quality Automation (Gap 7) | LOW | Add lint/format to /stp:new + hooks |
| 7 | E2E Testing (Gap 5) | MEDIUM | Add to /stp:new + /stp:plan + milestone completion |
| 8 | ADRs (Gap 8) | VERY LOW | Add instruction to /stp:feature |
| 9 | Deploy Readiness (Gap 9) | MEDIUM | Add to /stp:plan + reference file |
| 10 | Acceptance Criteria (Gap 10) | LOW | Enhance PRD.md + PLAN.md templates |
| 11 | A11y Testing (Gap 13) | VERY LOW | Piggyback on Gap 5 (E2E) |
| 12 | Changelog (Gap 14) | VERY LOW | Commit format + reference file |
| 13 | API Docs (Gap 11) | MEDIUM | Add to /stp:plan Phase 4 |
| 14 | Perf Testing (Gap 12) | LOW | Add to CI pipeline |

---

## How Gaps Map to Pilot Commands

### /stp:new (augment)
- Generate CI workflow file (Gap 1)
- Set up linter + formatter (Gap 7)
- Install E2E framework for web projects (Gap 5)
- Surface legal/compliance requirements (Gap 6)

### /stp:plan (augment)
- Add Monitoring & Observability section (Gap 2)
- Add Migration & Rollback Strategy to Data Models phase (Gap 3)
- Add Dependency Review section (Gap 4)
- Add Compliance Requirements section (Gap 6)
- Add E2E Test Strategy section (Gap 5)
- Add Deployment Planning section (Gap 9)
- Add Acceptance Criteria to features (Gap 10)
- Generate OpenAPI spec for APIs (Gap 11)

### /stp:feature (augment)
- Update PRD.md Technical Decisions Log when decisions change (Gap 8)
- Write E2E tests for critical paths at milestone boundaries (Gap 5)
- Include axe-core in E2E tests (Gap 13)

### Critic (augment)
- Check: error tracking configured? (Gap 2)
- Check: migrations reversible? (Gap 3)
- Check: E2E tests exist for critical paths? (Gap 5)
- Check: lint/format passes? (Gap 7)
- Check: bundle size reasonable? (Gap 12)
- Check: axe-core configured? (Gap 13)

### New reference files needed
- `references/production/database-migrations.md` (Gap 3)
- `references/security/dependency-security.md` (Gap 4)
- `references/legal/compliance-baseline.md` (Gap 6)
- `references/production/monitoring-setup.md` (Gap 2)
- `references/production/deploy-checklist.md` (Gap 9)

### New template additions needed
- `.github/workflows/ci.yml` per stack (Gap 1)
- Linter + formatter config per stack (Gap 7)
- E2E test setup per stack (Gap 5)

---

## Research Sources

- [DORA Metrics Guide](https://dora.dev/guides/dora-metrics-four-keys/)
- [OWASP SAMM Threat Modeling](https://owaspsamm.org/model/design/threat-assessment/stream-b/)
- [STRIDE Threat Model](https://www.practical-devsecops.com/what-is-stride-threat-model/)
- [European Accessibility Act Compliance](https://www.accessibility.works/blog/eaa-european-accessibility-act-compliance-standards-requirements/)
- [SaaS EAA Compliance](https://www.accessibility.works/blog/saas-eaa-compliance-european-accessibility-act-en-301-549-requirements/)
- [Production Readiness Checklist (SigNoz)](https://signoz.io/guides/production-readiness-checklist/)
- [Production Readiness Checklist (GoReplay)](https://goreplay.org/blog/production-readiness-checklist-20250808133113/)
- [GitHub Actions CI/CD Guide](https://github.blog/enterprise-software/ci-cd/build-ci-cd-pipeline-github-actions-four-steps/)
- [Sentry vs Datadog vs New Relic](https://apptension.com/guides/best-saas-error-monitoring-and-observability-tools-sentry-vs-datadog-vs-new-relic)
- [npm Supply Chain Attacks 2026](https://bastion.tech/blog/npm-supply-chain-attacks-2026-saas-security-guide)
- [2026 Supply Chain Security Report](https://bastion.tech/blog/2026-supply-chain-security-report/)
- [Playwright E2E Best Practices](https://elionavarrete.com/blog/e2e-best-practices-playwright.html)
- [ADRs (Martin Fowler)](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html)
- [ADRs (AWS)](https://aws.amazon.com/blogs/architecture/master-architecture-decision-records-adrs-best-practices-for-effective-decision-making/)
- [DORA Metrics in AI Age](https://www.future-processing.com/blog/dora-devops-metrics/)
- [AI-Powered SDLC Framework](https://smartsdlc.dev/blog/ai-powered-sdlc-building-an-ai-framework-for-developer-experience/)
- [AWS AI-Driven SDLC](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/)
- [Database Migration Best Practices](https://dev.to/pipipi-dev/database-migration-safely-managing-dev-and-production-environments-2nfh)
- [Database Rollback Strategies](https://www.harness.io/harness-devops-academy/database-rollback-strategies-in-devops)
- [Feature Flags & Deployment Strategies](https://stonetusker.com/advanced-deployment-strategies-blue-green-canary-releases-and-feature-flags/)
- [Vercel Rolling Releases](https://vercel.com/kb/guide/how-to-gradually-roll-out-new-versions-of-your-backend)
- [SDLC Best Practices 2026 (Waydev)](https://waydev.co/sdlc-best-practices/)

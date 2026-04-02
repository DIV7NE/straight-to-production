# AI Code Security Vulnerabilities: Comprehensive Research Reference

> **Purpose**: Reference document for a development workflow that proactively PREVENTS security mistakes made by AI coding assistants (Claude, Copilot, Cursor, ChatGPT).
>
> **Last Updated**: 2026-04-02
>
> **Research Sources**: Stanford/NYU studies, OX Security, OWASP, Veracode, CodeRabbit, Escape.tech, Snyk, Apiiro, Pillar Security, Trend Micro, Socket.dev, Kaspersky

---

## Table of Contents

1. [Key Statistics](#1-key-statistics)
2. [Documented Research Studies](#2-documented-research-studies)
3. [OX Security: 10 Critical Anti-Patterns](#3-ox-security-10-critical-anti-patterns)
4. [Security Vulnerabilities by Category](#4-security-vulnerabilities-by-category)
5. [The Slopsquatting Attack Vector](#5-the-slopsquatting-attack-vector-hallucinated-packages)
6. [AI-Specific Insecure Code Patterns](#6-ai-specific-insecure-code-patterns)
7. [IDE/Agent-Level Vulnerabilities](#7-ideagent-level-vulnerabilities)
8. [OWASP Top 10 for LLM Applications 2025](#8-owasp-top-10-for-llm-applications-2025)
9. [Prevention Checklist](#9-prevention-checklist)
10. [Automated Security Pipeline](#10-automated-security-pipeline)
11. [Per-Category Automated Checks](#11-per-category-automated-checks)

---

## 1. Key Statistics

| Metric | Finding | Source |
|--------|---------|--------|
| AI code vulnerability rate | **45% of AI-generated code contains security flaws** | Veracode 2025 GenAI Code Security Report (100+ LLMs, 80 tasks) |
| Security vs syntax improvement | Syntax correctness >95%, but **security pass rate stuck at ~55%** since 2023 | Veracode Spring 2026 Update (150+ LLMs tested) |
| Copilot vulnerability rate | **~40% of Copilot-generated programs had exploitable vulnerabilities** | NYU CCS 2021 (89 scenarios, 1,692 programs) |
| AI vs human code issues | **AI code has 1.7x more issues** than human-written code overall | CodeRabbit Dec 2025 (470 GitHub PRs) |
| Security vulnerabilities specifically | **2.74x more security vulnerabilities** in AI-generated code | CodeRabbit Dec 2025 |
| XSS vulnerabilities | **2.74x higher** in AI-generated code | CodeRabbit Dec 2025 |
| Performance inefficiencies | **~8x more often** in AI-generated code | CodeRabbit Dec 2025 |
| Logic/correctness issues | **75% more frequent** in AI-generated code | CodeRabbit Dec 2025 |
| Readability problems | **3x higher** in AI-generated code | CodeRabbit Dec 2025 |
| Privilege escalation paths | **322% increase** in AI-generated code | Apiiro 2025 (Fortune 50 enterprises) |
| Design flaws | **153% increase** in AI-generated code | Apiiro 2025 |
| Secrets exposure | **40% increase** in AI-generated code | Apiiro 2025 |
| AI-authored CVEs (Mar 2026) | **35 new CVEs** directly from AI-generated code in one month | Vibe Security Radar (Georgia Tech) |
| Vibe-coded apps with vulns | **2,000+ high-impact vulnerabilities** in 5,600 publicly deployed apps | Escape.tech 2025 |
| Exposed secrets in vibe apps | **400+ exposed secrets** across 5,600 apps | Escape.tech 2025 |
| Supabase RLS flaws | **10.3% of Lovable-generated apps** had critical RLS misconfigurations | Escape.tech 2025 |
| Developer false confidence | Developers with AI assistants **believed they wrote more secure code** while actually writing less secure code | Stanford/Perry et al. 2022 |
| Best AI model security rate | Even best models (GPT-5 reasoning) only achieve **70-72% security pass rate** | Veracode Spring 2026 |
| Claude security performance | Claude 4.5/4.6 security performance **remained flat** vs earlier generations | Veracode Spring 2026 |

---

## 2. Documented Research Studies

### Stanford Study (Perry et al., 2022)
- **Title**: "Do Programmers Write More Insecure Code with AI Assistants?"
- **Authors**: Neil Perry, Megha Srivastava, Deepak Kumar, Dan Boneh (Stanford)
- **Key Finding**: Participants with access to AI assistants wrote significantly less secure code than those without, while simultaneously believing their code was more secure
- **Scope**: 47 developers (students to industry professionals), Python/JavaScript/C, using OpenAI Codex

### NYU "Asleep at the Keyboard" (Pearce et al., 2021)
- **Title**: "Asleep at the Keyboard? Assessing the Security of GitHub Copilot's Code Contributions"
- **Key Finding**: ~40% of Copilot-generated programs had potentially exploitable vulnerabilities
- **Scope**: 89 scenarios, 1,692 programs generated

### arXiv: Security Weaknesses of Copilot Generated Code in GitHub (2023)
- Studied real-world Copilot code in GitHub repositories
- Found recurring CWE patterns matching MITRE CWE Top-25
- Most common: CWE-94 (code injection), CWE-78 (OS command injection), CWE-190 (integer overflow), CWE-306 (missing authentication), CWE-434 (unrestricted file upload)

### Veracode 2025 GenAI Code Security Report
- Tested 100+ LLMs across 80 coding tasks in 4 languages
- 45% of AI-generated code introduced OWASP Top 10 vulnerabilities
- Java had the highest risk: >70% security failure rate
- Python, C#, JavaScript: 38-45% failure rates
- XSS (CWE-80): 86% failure rate; Log injection (CWE-117): 88% failure rate

### Veracode Spring 2026 Update
- 150+ LLMs tested longitudinally since 2023
- Security pass rate has not improved despite massive syntax/functional gains
- Claude 4.5 and 4.6: "demonstrably excellent at functional tasks" but security flat
- Only OpenAI reasoning models (GPT-5 series) showed improvement: 70-72% (still 28-30% vulnerability rate)

### CodeRabbit "State of AI vs Human Code Generation" (Dec 2025)
- 470 real-world open-source GitHub pull requests analyzed
- AI-generated PRs: 1.7x more issues, 2.74x more security vulnerabilities
- Critical/major defects up to 1.7x higher
- Performance inefficiencies ~8x more frequent

### Apiiro Fortune 50 Enterprise Study (2025)
- By June 2025, AI-generated code was adding 10,000+ new security findings per month (10x increase from Dec 2024)
- CVSS 7.0+ vulnerabilities: 2.5x more frequent in AI code
- 322% more privilege escalation paths, 153% more design flaws

### Escape.tech Vibe-Coded Apps Study (2025)
- Scanned 5,600 publicly deployed vibe-coded applications
- Found 2,000+ high-impact vulnerabilities, 400+ exposed secrets, 175 PII instances
- Platforms: Lovable (~4,000 apps), Base44 (~159), Create.xyz (~449), Bolt.new
- 10.3% of Lovable apps had critical Supabase RLS flaws

### OX Security "Army of Juniors" (Oct 2025)
- Analyzed 300+ open-source repositories (50+ using AI coding tools)
- Identified 10 critical anti-patterns in 40-100% of AI-generated code

### USENIX Security 2025: Package Hallucination Study
- Tested 16 LLMs across 576,000 code samples
- Hallucination patterns: 38% conflations (e.g., express-mongoose), 13% typo variants, 51% pure fabrications

### Tenzai AI Coding Tools Security Test (Dec 2025)
- Tested Claude Code, Cursor, Windsurf, Replit, Devin
- Generated 69 vulnerabilities, 6 critical
- Finding: AI avoids generic mistakes but fails at authorization and business logic

### SoftwareMill: Vibe Coding Against OWASP Top 10 (2025)
- Tested AI-generated code against all 10 OWASP categories
- AI failed on 7/10 categories

---

## 3. OX Security: 10 Critical Anti-Patterns

Source: OX Security "Army of Juniors" Report, October 2025, 300+ repositories analyzed

| # | Anti-Pattern | Prevalence | Core Issue | Security Impact |
|---|-------------|------------|------------|-----------------|
| 1 | **Comments Everywhere** ("Note to Future AI Self") | 90-100% | Excessive inline commenting beyond human norms | Increases attack surface review burden; comments serve as AI navigation breadcrumbs |
| 2 | **Avoidance of Refactors** ("Missing 'Who Wrote This?' Reflex") | 80-90% | No instinctive code improvement process | Technical debt accumulation; security issues persist across iterations |
| 3 | **Over-Specification** ("Dispose-After-Use Code") | 70-80% | Hyper-specific solutions lacking generalization | Code reuse impossible; each feature introduces new attack surface |
| 4 | **The Return of the Monoliths** | 40-50% | Tightly-coupled monolithic architectures | Single vulnerability compromises entire system; blast radius maximized |
| 5 | **Fake Test Coverage** ("Quantity Not Quality") | 40-50% | Inflated coverage metrics with meaningless tests | False confidence; tests validate happy paths, not attack vectors |
| 6 | **Phantom Bugs** ("When Machines Chase Ghosts") | 20-30% | Over-engineering for improbable edge cases | Performance degradation; complexity hides real vulnerabilities |
| 7 | **Vanilla Style** ("Reinventing the Wheel") | 40-50% | Reimplements functionality instead of using proven libraries | Custom crypto/auth/validation introduces vulnerabilities |
| 8 | **"Worked on My Machine" Syndrome** | 60-70% | No awareness of deployment environments | Code works in dev, fails in prod; security configs missing |
| 9 | **Overly Permissive Error Handling** | 70-80% | Catches errors too broadly or silently swallows them | Stack traces leak; errors ignored; security failures undetected |
| 10 | **Inconsistent Architecture** | 60-70% | No coherent architectural vision | Mixed patterns create security gaps; auth applied inconsistently |

Key Insight: "The problem isn't that AI writes worse code, it's that vulnerable systems now reach production at unprecedented speed, and proper code review simply cannot scale to match the new output velocity." -- Eyal Paz, VP Research, OX Security

---

## 4. Security Vulnerabilities by Category

### 4.1 Authentication

| Vulnerability | CWE | How AI Creates It |
|--------------|-----|-------------------|
| Missing auth on API routes | CWE-306 | AI generates functional endpoints without auth middleware unless explicitly prompted |
| Weak session management | CWE-384 | AI uses default session configs, no rotation, no expiry |
| Exposed user IDs in URLs | CWE-639 | AI uses sequential/predictable IDs in routes |
| Improper JWT validation | CWE-347 | AI generates JWT creation but skips verification, uses weak secrets |
| Missing password requirements | CWE-521 | AI sets minimal validation (6+ chars) |
| Default admin role assignment | CWE-269 | Registration route assigns admin role to new users |

Vulnerable Pattern (JWT): AI hardcodes weak secret string, uses HS256 instead of RS256, omits token verification, issuer validation, audience check. Secure: use env var for secret, RS256 algorithm, full validation.

### 4.2 Input Validation and Injection

| Vulnerability | CWE | Veracode Failure Rate |
|--------------|-----|-----------------------|
| SQL Injection | CWE-89 | ~45% |
| Cross-Site Scripting (XSS) | CWE-80 | **86% failure rate** |
| OS Command Injection | CWE-78 | Common in file processing |
| Log Injection | CWE-117 | **88% failure rate** |
| Code Injection | CWE-94 | Most common CWE in Copilot code |
| Path Traversal | CWE-22 | ../../etc/passwd in upload handlers |
| Unrestricted File Upload | CWE-434 | AI accepts anything |

Vulnerable Pattern (SQL): AI uses string concatenation instead of parameterized queries. Secure: use PreparedStatement or parameterized queries.

### 4.3 Secrets Management

| Vulnerability | CWE | How AI Creates It |
|--------------|-----|-------------------|
| Hardcoded API keys | CWE-798 | AI copies patterns from training data (40% increase per Apiiro) |
| Secrets in client-side code | CWE-200 | AI puts keys in React/Next.js client components |
| Predictable tokens | CWE-330 | AI uses Math.random() for security tokens |
| Committed .env files | CWE-538 | AI creates .env without adding to .gitignore |
| Shared secrets across services | CWE-321 | Same JWT secret across microservices |

Vulnerable Pattern: Math.random() for tokens (not cryptographically secure). Secure: crypto.randomBytes(32).

### 4.4 Error Handling

| Vulnerability | CWE | How AI Creates It |
|--------------|-----|-------------------|
| Stack trace exposure | CWE-209 | AI returns raw error objects to client |
| Silent error swallowing | CWE-390 | Empty catch blocks |
| Raw database errors to client | CWE-209 | Unfiltered ORM errors in API responses |
| Missing logging on auth failures | CWE-778 | Login returns 401 but logs nothing |

Vulnerable Pattern: Error handler returns str(e) to client, exposing internals. Secure: log the error server-side, return generic message to client.

### 4.5 Authorization and Access Control

| Vulnerability | CWE | How AI Creates It |
|--------------|-----|-------------------|
| IDOR | CWE-639 | AI fetches by ID without checking ownership |
| Client-provided user IDs | CWE-284 | AI trusts req.body.userId |
| Missing role checks | CWE-862 | Admin endpoints without role verification |
| Broken row-level security | CWE-863 | 10.3% of Lovable apps had critical RLS flaws |
| Privilege escalation by default | CWE-269 | 322% increase per Apiiro |

Vulnerable Pattern (IDOR): Document.findById(req.params.id) without ownership check. Secure: Document.findOne({ _id: id, owner: req.user.id }).

### 4.6 Dependencies

| Vulnerability | How AI Creates It |
|--------------|-------------------|
| Outdated/vulnerable packages | AI trained on older code suggests older versions |
| Hallucinated packages (slopsquatting) | AI invents non-existent package names |
| Deprecated APIs | AI uses deprecated methods from training data |
| Excessive dependencies | AI adds packages for trivial functionality |

---

## 5. The Slopsquatting Attack Vector (Hallucinated Packages)

### What It Is

Slopsquatting is a supply chain attack where attackers register package names that AI models commonly hallucinate. When a developer trusts the AI's suggestion and runs an install command, they download the attacker's malicious package.

### Research Data (USENIX Security 2025)

- 16 LLMs tested across 576,000 code samples
- Hallucination breakdown: 38% conflations, 13% typo variants, 51% pure fabrications
- These hallucinated names bypass npm's typosquatting protection

### Real-World Incidents

1. Google AI Overview recommended @async-mutex/mutex (Jan 2025): malicious typosquat that stole Solana private keys via Gmail SMTP
2. LLM-generated Agent Skills committed hallucinated packages to GitHub: 47 AI-generated files, no human review
3. Malicious eslint-plugin-unicorn-ts-2 contained hidden prompt to fool AI security scanners
4. npm malicious package surge (2025): 3,180 confirmed malicious packages in one year

### How to Defend

1. VERIFY every AI-suggested package exists BEFORE installing: npm view <pkg> name
2. Check package age and download stats
3. Use Socket.dev for supply chain analysis
4. Lock dependencies and audit regularly: npm audit, pip-audit
5. Use allowlists for approved packages in CI/CD

CRITICAL RULE: NEVER blindly install a package suggested by AI without verifying it exists, checking download count, inspecting GitHub repo, and reviewing publication date.

---

## 6. AI-Specific Insecure Code Patterns

These patterns look correct to casual review but are insecure:

### 6.1 Weak Cryptography
- INSECURE: Math.random() for tokens, MD5/SHA1 for passwords
- SECURE: crypto.randomBytes(32) for tokens, bcrypt/argon2 for passwords

### 6.2 CORS Misconfiguration
- INSECURE: cors() with no origin (allows ALL), cors({ origin: '*' }), cors({ origin: true })
- SECURE: cors({ origin: process.env.ALLOWED_ORIGINS.split(',') })

### 6.3 JWT in localStorage
- INSECURE: localStorage.setItem('token', jwt) -- accessible to XSS
- SECURE: httpOnly cookies with secure, sameSite: 'strict'

### 6.4 Client-Side Only Validation
- INSECURE: validate on client only -- attacker bypasses with curl
- SECURE: always validate on server (client validation is UX only)

### 6.5 Client-Side Rate Limiting
- INSECURE: useState counter in React -- trivially bypassed
- SECURE: express-rate-limit on server

### 6.6 Missing Request Body Size Limits
- INSECURE: express.json() with no limit -- DoS vector
- SECURE: express.json({ limit: '10kb' })

### 6.7 Missing Security Headers
- INSECURE: Express without helmet -- no security headers
- SECURE: app.use(helmet())

### 6.8 Disabled TLS Verification
- INSECURE: requests.get(url, verify=False) -- common in training data
- SECURE: requests.get(url, verify=True)

### 6.9 Debug Mode in Production
- INSECURE: app.run(debug=True, host='0.0.0.0')
- SECURE: read debug flag from environment variable

### 6.10 Missing WHERE Clauses
- INSECURE: UPDATE users SET role = 'admin'; -- affects ALL users
- SECURE: UPDATE users SET role = 'admin' WHERE id = $1;

---

## 7. IDE/Agent-Level Vulnerabilities

Beyond code generation, the AI coding tools themselves have vulnerabilities:

### Rules File Backdoor (Pillar Security, Apr 2025)
- Affects: GitHub Copilot, Cursor
- Attack: Invisible unicode characters in rule files inject malicious instructions
- Impact: AI generates code with backdoors, insecure crypto, auth bypasses
- Both Cursor and GitHub dismissed it

### CurXecute (CVE-2025-54135)
- Affects: Cursor
- Attack: Arbitrary command execution via compromised MCP servers
- Impact: Full RCE on developer's machine

### EscapeRoute (CVE-2025-53109)
- Affects: Anthropic's MCP server (Claude Desktop, Cursor, Windsurf)
- Attack: File access restrictions didn't work
- Impact: Full filesystem access

### Claude Code DNS Exfiltration (CVE-2025-55284)
- Affects: Claude Code agent
- Attack: Prompt injection via analyzed code exfiltrates data through DNS
- Impact: Data theft from developer's machine

### Cursor Environment Variable Poisoning (CVE-2026-22708)
- Affects: Cursor
- Attack: Shell built-ins manipulate env vars that poison legitimate tools
- Impact: git branch or python3 script.py could run attacker code

### CamoLeak (GitHub Copilot)
- CVSS: 9.6
- Impact: Silent exfiltration of private repository code

### Amazon Q Developer Incident
- Malicious prompt inserted into extension instructions
- Instructions to wipe all developer data (stopped by unrelated bug)

### Nx Build System ("s1ngularity" Attack, Aug 2025)
- AI coding assistants hijacked to steal credentials from 1,400+ build systems

---

## 8. OWASP Top 10 for LLM Applications 2025

| # | Risk | Relevance to AI Code Generation |
|---|------|--------------------------------|
| LLM01 | Prompt Injection | Rules file backdoor; poisoned context; MCP manipulation |
| LLM02 | Sensitive Information Disclosure | AI leaks secrets; training data memorization |
| LLM03 | Supply Chain Vulnerabilities | Hallucinated packages; poisoned data; compromised MCP |
| LLM04 | Data and Model Poisoning | Insecure patterns seeded in public repos |
| LLM05 | Improper Output Handling | Generated code used without sanitization |
| LLM06 | Excessive Agency | Agentic tools run generated code with too many permissions |
| LLM07 | System Prompt Leakage | Security rules can be extracted |
| LLM08 | Vector and Embedding Weaknesses | RAG manipulated to serve insecure patterns |
| LLM09 | Misinformation | AI recommends deprecated/insecure approaches |
| LLM10 | Unbounded Consumption | Inefficient code causes resource exhaustion |

### OWASP Guidance for AI-Generated Code

1. Treat ALL LLM output as untrusted input
2. Use parameterized queries for all database operations
3. Encode model output back to users (prevent XSS)
4. Context-aware output encoding
5. Strict Content Security Policies (CSP)
6. Robust logging and monitoring
7. Verify all suggested packages
8. Thorough code review of all AI-generated code

---

## 9. Prevention Checklist

### BEFORE Accepting AI-Generated Code

- [ ] Auth Check: Does every API route have authentication middleware?
- [ ] Authorization Check: Does every data access verify ownership (no IDOR)?
- [ ] Input Validation: Is ALL user input validated on the server side?
- [ ] Output Encoding: Is output properly encoded for its context?
- [ ] No Hardcoded Secrets: Zero hardcoded API keys, passwords, or tokens?
- [ ] No Client Secrets: Secrets kept server-side only?
- [ ] Parameterized Queries: ALL database queries parameterized?
- [ ] Proper Crypto: No Math.random() for tokens, no MD5/SHA1 for passwords?
- [ ] Secure Headers: helmet() or equivalent applied?
- [ ] CORS Restricted: Explicit origins (no wildcard)?
- [ ] JWT Secure: httpOnly cookies (not localStorage)?
- [ ] Rate Limiting: Server-side (not client)?
- [ ] Error Handling: Generic messages (no stack traces)?
- [ ] Logging: Security events logged?
- [ ] Body Limits: Request body size limits set?
- [ ] File Upload Validation: Type, size, filename validated?
- [ ] Dependencies Verified: ALL packages actually exist?
- [ ] Dependencies Audited: No known vulnerabilities?
- [ ] TLS Enabled: Verification not disabled?
- [ ] Debug Off: Debug mode disabled for production?
- [ ] RLS Configured: Row-level security correct (Supabase)?
- [ ] No Dynamic Code Execution: Zero dangerous dynamic execution with user data?
- [ ] Path Traversal Safe: File paths sanitized?
- [ ] WHERE Clauses: All UPDATE/DELETE properly scoped?

### BEFORE Committing AI-Generated Code

- [ ] Secret Scan: gitleaks -- zero findings
- [ ] Static Analysis: Semgrep OWASP rules -- zero high/critical
- [ ] Dependency Audit: npm audit -- zero high/critical
- [ ] Package Verification: Every new import verified
- [ ] Test Coverage: Security-relevant tests exist
- [ ] No .env Files: .env in .gitignore

---

## 10. Automated Security Pipeline

### Minimum Viable Security Pipeline (GitHub Actions)

```yaml
name: Security Checks
on: [pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/nodejs
            p/typescript
            p/security-audit
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
      - name: NPM Audit
        run: npm audit --audit-level=high
      - name: Verify Dependencies Exist
        run: |
          for pkg in $(jq -r '.dependencies // {} | keys[]' package.json); do
            npm view "$pkg" name 2>/dev/null || echo "WARNING: $pkg not found!"
          done
```

### Pre-Commit Hook Security

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
  - repo: https://github.com/returntocorp/semgrep
    rev: v1.90.0
    hooks:
      - id: semgrep
        args: ['--config', 'p/owasp-top-ten', '--error']
```

### Tools by Category

| Category | Tool | Purpose | License |
|----------|------|---------|---------|
| SAST | Semgrep | Pattern-based static analysis, OWASP rules | Free + Commercial |
| SAST | CodeQL | Deep semantic analysis (GitHub) | Free for public repos |
| SAST | ESLint Security | JS/TS security linting | Free |
| Secret Scanning | Gitleaks | Pre-commit + CI, 150+ patterns | MIT (Free) |
| Secret Scanning | TruffleHog | Deep scan + credential verification, 800+ detectors | AGPL / Commercial |
| Secret Scanning | GitGuardian | Managed platform with dashboards | Free + Commercial |
| Dependency Audit | npm audit / pip-audit | Known vulnerability detection | Built-in |
| Dependency Audit | Snyk | Deep analysis + fix PRs | Free + Commercial |
| Dependency Audit | Socket.dev | Supply chain + slopsquatting | Free + Commercial |
| DAST | OWASP ZAP | Runtime vulnerability scanning | Free |
| DAST | Nuclei | Template-based scanner | Free |
| Package Verify | Socket Verify | Suspicious/malicious package check | Free |

---

## 11. Per-Category Automated Checks

### Authentication
- Semgrep: p/owasp-top-ten, p/jwt
- Verify auth middleware on every route
- No hardcoded JWT secrets
- JWT expiry < 24h for access tokens

### Input Validation
- Semgrep: p/sql-injection, p/xss, p/command-injection
- No string concatenation in SQL
- No dynamic code execution with user input
- No unsanitized HTML rendering

### Secrets
- Gitleaks pre-commit: gitleaks detect --source .
- TruffleHog history scan: trufflehog git file://. --results=verified
- Patterns: sk_live, sk_test, AKIA, BEGIN PRIVATE KEY

### Dependencies
- Anti-slopsquatting: npm view <pkg> name
- Vulnerability audit: npm audit --audit-level=high
- Deprecated check: npx depcheck

### Error Handling
- Pattern check: error details returned to client
- Pattern check: empty catch blocks
- Verify: generic messages only in responses

### CORS
- Pattern check: cors() with no origin
- Pattern check: origin: '*' or origin: true
- Verify: origin from environment variable

---

## Appendix A: Most Dangerous CWEs in AI-Generated Code

Ranked by frequency (from multiple studies):

1. CWE-89: SQL Injection
2. CWE-79/80: Cross-Site Scripting -- 86% failure rate
3. CWE-306: Missing Authentication
4. CWE-798: Hardcoded Credentials
5. CWE-78: OS Command Injection
6. CWE-94: Code Injection
7. CWE-434: Unrestricted File Upload
8. CWE-862: Missing Authorization
9. CWE-639: IDOR
10. CWE-209: Sensitive Error Messages
11. CWE-117: Log Injection -- 88% failure rate
12. CWE-190: Integer Overflow
13. CWE-330: Insufficiently Random Values
14. CWE-284: Improper Access Control
15. CWE-269: Improper Privilege Management (322% increase)

## Appendix B: Language-Specific Risks

| Language | Failure Rate | Highest Risks |
|----------|-------------|---------------|
| Java | >70% | Injection, deserialization, XML parsing |
| JavaScript | 38-45% | XSS, prototype pollution, CORS, JWT |
| Python | 38-45% | Command injection, unsafe deserialization, SSRF |
| C# | 38-45% | SQL injection, XML injection, auth bypass |
| C/C++ | Mixed | Buffer overflow, format string, memory corruption |

## Appendix C: The False Confidence Effect

The Stanford study (Perry et al.) revealed a critical meta-vulnerability: developers who use AI assistants believe their code is more secure while it is actually less secure. This creates a dangerous feedback loop:

1. AI generates functional code quickly -> developer feels productive
2. Code appears well-structured -> developer assumes it's secure
3. Developer reduces manual review -> vulnerabilities slip through
4. Code ships to production -> vulnerabilities are exploitable
5. Developer continues trusting AI -> cycle repeats at scale

Mitigation: Treat AI-generated code with MORE scrutiny than human-written code, not less. Automation bias is the single biggest enabler of AI code vulnerabilities reaching production.

---

## Sources

- Stanford/Perry et al.: https://www.neilaperry.com/presentations/AISoLA_23.pdf
- NYU CCS "Asleep at the Keyboard": https://cyber.nyu.edu/2021/10/15/ccs-researchers-find-github-copilot-generates-vulnerable-code-40-of-the-time/
- arXiv Copilot Security: https://arxiv.org/html/2310.02059v2
- OX Security "Army of Juniors": https://www.ox.security/wp-content/uploads/2025/10/Army-of-Juniors-The-AI-Code-Security-Crisis.pdf
- Veracode 2025/2026 Reports: https://www.veracode.com/blog/spring-2026-genai-code-security/
- CodeRabbit Study: https://finance.yahoo.com/news/coderabbit-state-ai-vs-human-160000111.html
- Escape.tech Vibe Apps: https://escape.tech/state-of-security-of-vibe-coded-apps
- OWASP Top 10 LLMs 2025: https://owasp.org/www-project-top-10-for-large-language-model-applications/assets/PDF/OWASP-Top-10-for-LLMs-v2025.pdf
- Socket.dev Slopsquatting: https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks
- Trend Micro Slopsquatting: https://www.trendmicro.com/vinfo/us/security/news/cybercrime-and-digital-threats/slopsquatting-when-ai-agents-hallucinate-malicious-packages
- Pillar Security Rules Backdoor: https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents
- Pillar Security CVE-2026-22708: https://www.pillar.security/blog/the-agent-security-paradox-when-trusted-commands-in-cursor-become-attack-vectors
- Forbes Vibe Coding: https://www.forbes.com/sites/jodiecook/2026/03/20/vibe-coding-has-a-massive-security-problem/
- Kaspersky Vibe Coding: https://www.kaspersky.com/blog/vibe-coding-2025-risks/54584/
- SoftwareMill OWASP: https://softwaremill.com/vibe-coding-against-owasp-top-10-2025/
- Apiiro AI Security: https://apiiro.com/blog/ai-generated-code-security/
- Endor Labs Vulnerabilities: https://www.endorlabs.com/learn/the-most-common-security-vulnerabilities-in-ai-generated-code
- Endor Labs Design Flaws: https://www.endorlabs.com/learn/design-flaws-in-ai-generated-code
- Aikido Slopsquatting: https://www.aikido.dev/blog/slopsquatting-ai-package-hallucination-attacks
- Vibe Security Audit Checklist: https://www.codewithseb.com/blog/vibe-coding-security-audit-checklist
- 30+ Flaws in AI Tools: https://thehackernews.com/2025/12/researchers-uncover-30-flaws-in-ai.html
- 69 Vulnerabilities in 5 Platforms: https://www.pixee.ai/weekly-briefings/ai-coding-platforms-vulnerabilities-scanners-miss-2026-01-21
- Claude vs Cursor vs Copilot: https://www.mintmcp.com/blog/claude-code-cursor-vs-copilot
- The Register AI Security: https://www.theregister.com/2026/03/26/ai_coding_assistant_not_more_secure/

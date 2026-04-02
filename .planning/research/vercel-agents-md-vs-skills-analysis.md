# Vercel Blog Analysis: AGENTS.md Outperforms Skills in Agent Evals

**Source:** https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals
**Author:** Jude Gao, Software Engineer, Next.js
**Published:** January 27, 2026
**Read time:** 7 min

---

## 1. Evaluation Methodology

### Eval Suite Hardening
Their initial test suite had problems: ambiguous prompts, tests validating implementation details rather than observable behavior, and focus on APIs already in model training data. They hardened it by:
- Removing test leakage
- Resolving contradictions
- Shifting to **behavior-based assertions**
- Adding tests targeting **Next.js 16 APIs not in model training data**
- Running **retries to rule out model variance**

### APIs Tested (Focused Eval Suite)
- `connection()` for dynamic rendering
- `'use cache'` directive
- `cacheLife()` and `cacheTag()`
- `forbidden()` and `unauthorized()`
- `proxy.ts` for API proxying
- Async `cookies()` and `headers()`
- `after()`, `updateTag()`, `refresh()`

### Key Methodology Principle
> "Most importantly, we added tests targeting Next.js 16 APIs that aren't in model training data."

The rationale: doc access only matters for APIs the model doesn't already know. Testing known APIs just measures the model, not the docs delivery mechanism.

### Validation
- All configurations judged against the **same tests**
- **Retries** used to rule out model variance
- Three gate categories: **Build, Lint, and Test**

---

## 2. The Specific Numbers

### Four Configurations Tested

| Configuration | Pass Rate | vs Baseline |
|---|---|---|
| Baseline (no docs) | **53%** | -- |
| Skill (default behavior) | **53%** | +0pp |
| Skill with explicit instructions | **79%** | +26pp |
| **AGENTS.md docs index** | **100%** | **+47pp** |

### AGENTS.md achieved 100% across Build, Lint, AND Test categories.

### Skill Invocation Failure Rate
- In **56% of eval cases**, the skill was **never invoked**
- The agent had access to the documentation but **chose not to use it**
- Skills with default behavior produced **zero improvement** over baseline

### Skills Were Actually Harmful When Unused
> "On the detailed Build/Lint/Test breakdown, the skill actually performed worse than baseline on some metrics (58% vs 63% on tests), suggesting that an unused skill in the environment may introduce noise or distraction."

### Instruction Wording Sensitivity
When they added explicit AGENTS.md instructions to trigger skill use:
- Trigger rate improved to **95%+**
- Pass rate improved to **79%**
- But **wording was extremely fragile** -- different phrasings produced "dramatically different results"

The winning instruction was:
```
Before writing code, first explore the project structure,
then invoke the nextjs-doc skill for documentation.
```

Even with 95%+ trigger rate and the best wording, skills still only hit 79% vs AGENTS.md's 100%.

---

## 3. Always-On Context vs On-Demand Retrieval

### Core Finding
> "For general framework knowledge, passive context currently outperforms on-demand retrieval."

### Why Skills Failed
Skills require two decisions from the agent:
1. **Recognize** it needs framework-specific help
2. **Choose** to invoke the skill

Agents failed at step 1 in 56% of cases. This is described as a **known limitation** of current models (they link to OpenAI's blog on eval skills as corroboration).

### Why AGENTS.md Succeeded
AGENTS.md removes the decision entirely:
> "What if we removed the decision entirely? Instead of hoping agents would invoke a skill, we could embed a docs index directly in AGENTS.md."

The content is available **on every turn** without the agent needing to decide to load it. The key insight is **passive context** (always loaded) vs **active retrieval** (agent must choose to load).

### Hybrid Approach: Index + Retrieval
They did NOT put full docs in AGENTS.md. They put a **compressed index** that tells the agent **where to find** specific doc files. The agent then reads those files as needed.

> "The agent knows where to find docs without having full content in context. When it needs specific information, it reads the relevant file from the `.next-docs/` directory."

---

## 4. CLAUDE.md / AGENTS.md as Primary Instruction Mechanism

### Direct Equivalence Stated
> "AGENTS.md is a markdown file in your project root that provides persistent context to coding agents. Whatever you put in AGENTS.md is available to the agent on every turn, without the agent needing to decide to load it. Claude Code uses CLAUDE.md for the same purpose."

### The "Retrieval-Led Reasoning" Directive
A critical instruction they embedded in the docs index:
```
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
for any Next.js tasks.
```

This tells the agent to consult docs rather than rely on potentially outdated training data.

### The Goal
> "The goal is to shift agents from pre-training-led reasoning to retrieval-led reasoning. AGENTS.md turns out to be the most reliable way to make that happen."

---

## 5. Findings About Hooks, Commands, and Harness Components

The article does not extensively discuss hooks or other harness components. The focus is narrowly on skills vs AGENTS.md for docs delivery. However:

- The CLI tool `npx @next/codemod@canary agents-md` automates the setup (detects version, downloads docs, injects index)
- The tool is part of the official `@next/codemod` package
- The approach works for any agent that respects AGENTS.md/CLAUDE.md

---

## 6. Recommendations for Newer Models with Larger Context Windows

### Context Bloat Solution: Compression
- Initial docs injection was **~40KB**
- Compressed to **8KB** (an **80% reduction**)
- Maintained the **100% pass rate** after compression
- Format: pipe-delimited structure mapping directory paths to doc files

Example of compressed format:
```
[Next.js Docs Index]|root: ./.next-docs
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
|01-app/01-getting-started:{01-installation.mdx,02-project-structure.mdx,...}
|01-app/02-building-your-application/01-routing:{01-defining-routes.mdx,...}
```

### Forward-Looking Note on Skills
> "Don't wait for skills to improve. The gap may close as models get better at tool use, but results matter now."

This implies they believe future models with better tool use may close the gap, but they recommend not waiting for that.

---

## 7. "Less Is More" / Simplicity-Focused Findings

### Compression Works
40KB -> 8KB with zero performance loss. You do NOT need full docs, just an index pointing to retrievable files.

### Removing Agent Decisions Improves Outcomes
The single biggest finding: removing the agent's decision about whether to look up docs (passive context) outperformed requiring the agent to decide (active skill invocation).

### Skills Can Be Harmful When Present But Unused
An unused skill in the environment may introduce noise or distraction, actually degrading performance below baseline on some metrics.

### Instruction Wording Fragility
Even when skills are explicitly triggered, minor wording changes produce dramatically different results. This fragility is itself an argument for the simpler AGENTS.md approach which has no such sensitivity.

---

## 8. Practical Recommendations (Verbatim)

1. **Don't wait for skills to improve.** The gap may close as models get better at tool use, but results matter now.
2. **Compress aggressively.** You don't need full docs in context. An index pointing to retrievable files works just as well.
3. **Test with evals.** Build evals targeting APIs not in training data. That's where doc access matters most.
4. **Design for retrieval.** Structure your docs so agents can find and read specific files rather than needing everything upfront.

---

## 9. Skills vs AGENTS.md: When to Use Each

### AGENTS.md (Passive Context)
- Best for: **broad, horizontal improvements** to how agents work with a framework across all tasks
- Best for: general framework knowledge
- Mechanism: always loaded, no agent decision required

### Skills (Active Retrieval)
- Best for: **vertical, action-specific workflows** that users explicitly trigger
- Examples: "upgrade my Next.js version", "migrate to the App Router", applying framework best practices
- Skills are NOT useless -- the two approaches **complement each other**

---

## 10. Key Quotes Summary

| Quote | Context |
|---|---|
| "A compressed 8KB docs index embedded directly in AGENTS.md achieved a 100% pass rate" | Headline finding |
| "Skills maxed out at 79% even with explicit instructions telling the agent to use them" | Best-case skills |
| "Without those instructions, skills performed no better than having no documentation at all" | Default skills = useless |
| "In 56% of eval cases, the skill was never invoked" | Core failure mode |
| "An unused skill in the environment may introduce noise or distraction" | Skills can be harmful |
| "Prefer retrieval-led reasoning over pre-training-led reasoning" | Key AGENTS.md instruction |
| "The goal is to shift agents from pre-training-led reasoning to retrieval-led reasoning" | Design philosophy |
| "Passive context currently outperforms on-demand retrieval" | Core recommendation |
| "Don't wait for skills to improve" | Practical advice |

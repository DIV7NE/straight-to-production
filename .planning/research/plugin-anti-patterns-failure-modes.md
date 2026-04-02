# Claude Code Plugin Anti-Patterns & Failure Modes

> Research compiled April 2026. Sources: GitHub issues, Reddit r/ClaudeCode, Tavily deep search, Anthropic docs, Vercel blog, community repos, developer reports, and live analysis of a heavily-instrumented setup (~30 plugins enabled).

---

## 1. Token Tax of Plugins

**The problem:** Before the user types a single character, plugins have already consumed a significant portion of the context budget.

**Measured data:**
- A developer reported **32.9K tokens baseline** on Sonnet 4.5 before saying "Hi" -- that is system prompts + CLAUDE.md + tool definitions + plugin context. Source: [Jamie Ferguson LinkedIn](https://www.linkedin.com/posts/jamiejferguson_when-i-first-started-using-claude-code-he-activity-7392297798127243264-eJVS)
- Cursor forum users reported **13,000-20,000 tokens** just from internal system prompts and tool definitions saying "hello" to a new chat. Source: [tokenoptimize.dev](https://www.tokenoptimize.dev/guides/reduce-tool-overhead-mcp-tokens)
- Anthropic's own November 2025 analysis found tool definition overhead of **55K-134K tokens** when multiple MCP servers are connected. Source: [Anthropic Token-Saving Updates](https://www.tokenoptimize.dev/guides/reduce-tool-overhead-mcp-tokens)
- The claude-docu-optimizer plugin recommends CLAUDE.md stay at **~2.5K tokens ideal, 4K max, 5K+ causes "context rot."** Source: [kojott/claude-docu-optimizer](https://github.com/kojott/claude-docu-optimizer)
- A 3,000-hour power user measured cold-start token cost at **0.8% of 200K** (~1.6K tokens) with a minimal setup. Heavy plugin setups burn 15-20x more.

**Live measurement from THIS setup (your ~/.claude):**
- `~/.claude/CLAUDE.md`: 14,577 bytes (~4K tokens)
- Vercel plugin CLAUDE.md: 11,698 bytes each (3 cached copies = ~10K tokens)
- GSD gstack CLAUDE.md: 20,677 bytes (~6K tokens)
- Superpowers-chrome CLAUDE.md: 9,803 bytes (~3K tokens)
- Neon plugin CLAUDE.md: 11,919 bytes (~3.5K tokens)
- GSD templates total: 979,836 bytes across all .md files
- **Total CLAUDE.md ecosystem: 143,128 bytes (~42K tokens) across all plugin CLAUDE.md files**
- Plus: 100+ skill descriptions in system-reminder (visible in this conversation), 60+ deferred tool names, hook configurations, MCP server instructions

**Estimated total plugin token tax for this setup: 50K-80K tokens before first user message on a 200K window (25-40% consumed). On 1M Opus, still 5-8% baseline.**

---

## 2. Hook Interference

**The problem:** Multiple hooks from different plugins fire on the same events, creating cumulative latency and potential conflicts.

**Your current hook stack (from ~/.claude/settings.json):**
| Event | Hooks Registered | Sources |
|-------|-----------------|---------|
| PostToolUse (Bash\|Edit\|Write\|MultiEdit\|Agent\|Task) | gsd-context-monitor.js (10s timeout) | GSD |
| PostToolUse (Edit\|MultiEdit) | `npx tsc --noEmit` (30s timeout) | User/GSD |
| PreToolUse (Write\|Edit) | gsd-prompt-guard.js (5s timeout) | GSD |
| UserPromptSubmit | token-optimizer measure.py | Token Optimizer plugin |
| SessionStart | gsd-check-update.js | GSD |
| SessionEnd | tmux kill-session | GSD |
| StatusLine | gsd-statusline.js | GSD |

**Plus Pilot's hooks (hooks.json) would add:**
| Event | Hooks | Source |
|-------|-------|--------|
| UserPromptSubmit | prompt-reinject.sh (5s) | Pilot |
| PostToolUse (Edit\|Write) | post-edit-typecheck.sh (30s) | Pilot |
| PostToolUse (*) | context-monitor.sh (5s) | Pilot |
| Stop | stop-verify.sh (30s) | Pilot |
| PreCompact | pre-compact-save.sh (10s) | Pilot |
| SessionStart | session-restore.sh (10s) + reset-counter.sh (5s) | Pilot |

**Conflict patterns identified:**
1. **Duplicate typecheck hooks:** Both GSD and Pilot register PostToolUse hooks that run `tsc --noEmit`. If both are installed, every Edit triggers TWO TypeScript compilations (60s combined timeout).
2. **Context monitor collision:** Both GSD (`gsd-context-monitor.js`) and Pilot (`context-monitor.sh`) monitor context on PostToolUse. Double monitoring, double overhead, potentially conflicting advice.
3. **UserPromptSubmit stacking:** Token Optimizer's measure.py fires on EVERY user message. If Pilot's prompt-reinject.sh also fires, every prompt has 10s+ of hook overhead before Claude even sees the message.
4. **No hook deduplication:** Claude Code runs ALL registered hooks for a matching event. There is no mechanism to detect or prevent duplicates across plugins.

**Performance impact:** Community reports that hooks with `npx tsc` can add **2-30 seconds per tool call** depending on project size. On a monorepo, this creates a perceptible delay on every single edit.

---

## 3. The Context Pollution Problem

**The tipping point is real and documented:**

- **~100 lines in CLAUDE.md:** Multiple sources (bswen.com, 32blog.com, SmartScope) converge on this as the ceiling where instructions start being ignored. "After about 100 lines, I hit a ceiling -- Claude started ignoring instructions and making the same mistakes repeatedly." Source: [docs.bswen.com](https://docs.bswen.com/blog/2026-03-21-claude-infrastructure-progression)
- **200K window degrades gradually, not suddenly.** Quality degrades as context fills -- "inconsistency and forgetfulness appear well before the hard limit." Source: [mindstudio.ai](https://www.mindstudio.ai/blog/context-window-claude-code-manage-consistent-results)
- **1M window: accurate up to ~400K, fuzzy recall >600K.** Community finding from Opus 4.6 users. Source: [claudecodecamp.com](https://claudecodecamp.com/p/claude-code-1m-context-window)
- **Three root causes of CLAUDE.md failure** (32blog.com):
  1. Too many rules -- attention spreads thin, important rules stop being followed
  2. Vague instructions -- model can't act on ambiguity
  3. @-file references that embed entire files -- bloats context with every session
- **JetBrains Research finding:** "Agent-generated context actually quickly turns into noise instead of being useful information." Context grows so fast it becomes expensive yet doesn't deliver better performance. Source: [JetBrains Research blog](https://blog.jetbrains.com/research/2025/12/efficient-context-management/)

**The over-prescription cascade:** Your CLAUDE.md alone has 75 lines of dense instruction including GSD commands, quality rules, anti-hallucination rules, React best practices, git rules, context rules, and agent team rules. Each plugin adds its own CLAUDE.md. The model receives ALL of this before every interaction.

---

## 4. Skill Invocation Interference (Vercel's Finding)

**Mechanism documented by Vercel's eval suite:**

- **56% of eval cases:** The skill was NEVER invoked. The agent had access to documentation but chose not to use it. Source: Vercel blog analysis (in your `.planning/research/vercel-agents-md-vs-skills-analysis.md`)
- **Skills with default behavior produced ZERO improvement** over baseline.
- **Unused skills are actively harmful:** "An unused skill in the environment may introduce noise or distraction, actually degrading performance below baseline on some metrics."
- **The mechanism:** Skills appear in the system prompt as a list of available capabilities. The model must decide whether to consult each one. More skills = more decision overhead = more chances to make wrong routing decisions. The skill descriptions compete for attention with actual task instructions.
- **Instruction wording fragility:** Minor wording changes in skill descriptions caused significant performance swings -- the model is hypersensitive to how skills are described.
- **Vercel's conclusion:** AGENTS.md (always-on passive context) achieved 100% across Build, Lint, AND Test categories. Skills underperformed it consistently. "Removing agent decisions improves outcomes."

**How it affects multi-plugin setups:** Look at this conversation's system-reminder. There are **160+ skills** listed. Each one's description consumes tokens AND creates a routing decision the model must make. Skills from GSD, Superpowers, Vercel, Stripe, Neon, context-mode, token-optimizer, and more all compete for the model's attention.

---

## 5. The Harness Lock-In Problem

**Observed patterns:**

- **GSD dependency depth:** GSD introduces its own file structure (`.planning/`), state files (`STATE.md`, `CODEBASE-CONTEXT.md`), command vocabulary (`/gsd:*`), agent orchestration, and workflow assumptions. Removing GSD means losing the planning directory convention, state tracking, and all accumulated project context.
- **Superpowers behavioral replacement:** "Since installing Superpowers, Claude doesn't seem to auto-enter Plan Mode anymore." The plugin hijacks built-in behaviors. Source: [Reddit](https://reddit.com/r/ClaudeCode/comments/1qy04jd/)
- **Permission accumulation:** Your settings.json has 100+ entries in `permissions.allow`, many tied to specific plugin patterns. Removing a plugin leaves orphaned permissions.
- **Hook dependency chains:** Pilot's PreCompact hook saves state to `.pilot/state.json`. Its SessionStart hook reads it back. Remove Pilot, and the state files become orphans that confuse other plugins reading the project directory.
- **CLAUDE.md instruction coupling:** When your CLAUDE.md references specific plugin commands (`/gsd:*`, `/superpowers:*`), removing the plugin breaks the instruction set. The model will attempt to invoke commands that no longer exist.

**The compound effect:** Each plugin adds its own conventions, file formats, and assumptions. After 6 months, the accumulated weight of 10+ plugins creates a setup that is irreducible -- you cannot remove any single plugin without breaking something else.

---

## 6. Compaction + Plugin Interaction

**What happens when compaction fires:**

1. **Conversation history is summarized.** The summary is generated by the model under pressure (high context usage). It preserves WHAT happened but loses WHY decisions were made.
2. **Plugin state in conversation is lost.** If a plugin injected context via hooks (e.g., Pilot's prompt-reinject.sh), that injected state exists only in conversation turns. Compaction summarizes it away.
3. **CLAUDE.md and system prompts survive.** These are re-injected fresh after compaction. But conversation-embedded plugin state does not.
4. **PreCompact hook is the mitigation.** Pilot's approach (save state to `.pilot/state.json` before compaction, restore on SessionStart) is the correct pattern. But most plugins do NOT implement PreCompact hooks.

**Failure modes:**
- **Morph plugin's compaction hack:** The Morph compaction plugin literally prompt-injects Claude's own summarization model to "not waste time summarizing, instead only output a few words" -- acknowledged as unreliable. Source: [morphllm/morph-claude-code-plugin](https://github.com/morphllm/morph-claude-code-plugin)
- **Supermemory's finding:** "Most tools wait until `context_length_exceeded`, then squeeze the thread into a summary. This is reactive compaction, and it's broken. By the time the error arrives, the model is already degraded: truncating system prompts, garbling tool outputs, hallucinating constraints you never stated." Source: [supermemory.ai](https://supermemory.ai/blog/infinitely-running-stateful-coding-agents/)
- **Compaction at 75% not 90%+:** VSCode extension auto-compacts at ~25% remaining context (75% usage). This means compaction fires earlier than expected, potentially mid-task.
- **GSD's approach:** Forces `/clear` between command transitions and maintains state on disk (`.planning/STATE.md`). This sidesteps compaction entirely but at the cost of losing conversation continuity.

---

## 7. The False Safety Problem

**Documented by Anthropic themselves:**

- **"Agents reliably skew positive when grading their own work."** When asked to evaluate work they produced, agents "confidently praise the work -- even when, to a human observer, the quality is obviously mediocre." Source: Anthropic harness design blog (in your `.planning/research/anthropic-harness-design-analysis.md`)
- **tsc passes but app doesn't work:** TypeScript type-checking (used by both GSD and Pilot as PostToolUse hooks) catches type errors but misses:
  - Runtime errors (null references in dynamic data)
  - Logic errors (correct types, wrong behavior)
  - Integration errors (API contract mismatches)
  - UI/UX issues (component renders but looks wrong)
  - State management bugs (race conditions, stale closures)
- **E2E testing is the "final boss":** Community consensus that automated checks give false confidence. One user reports "not writing code manually in 6+ months" but E2E testing remains unsolved. Source: [Reddit](https://reddit.com/r/ClaudeCode/comments/1r63p2q/)
- **Stop hook limitations:** Pilot's Stop hook blocks on TypeScript errors OR unchecked feature items. But it cannot verify:
  - Whether the feature actually works as intended
  - Whether the implementation matches the spec
  - Whether edge cases are handled
  - Whether the code is maintainable

**The illusion:** Hooks create a sense of "the system is checking quality" while only covering a narrow slice of what matters. Users trust the green checkmarks and skip manual verification.

---

## 8. Multi-Plugin Conflicts

**Your current setup has 30+ enabled plugins including GSD, Superpowers, Superpowers-chrome, Vercel, Stripe, Neon, context-mode, token-optimizer, context7, episodic-memory, ast-grep, elements-of-style, and more.**

**Observed conflicts:**

1. **Skill namespace collision:** When GSD, Superpowers, and Vercel all register skills for similar concepts (brainstorming, planning, verification), the model must choose between them. With 160+ skills visible, the routing decision becomes noisy.
2. **CLAUDE.md instruction conflicts:** GSD's CLAUDE.md says "WORK DIRECTLY: Opus should do tasks directly whenever practical." Superpowers says "You MUST use this before any creative work." These are contradictory directives for simple tasks.
3. **Hook execution order is undefined:** When GSD's PostToolUse hook and Pilot's PostToolUse hook both match the same event, execution order is not guaranteed. If one hook's output affects the other's input, behavior becomes non-deterministic.
4. **Context budget competition:** Each plugin's CLAUDE.md consumes tokens. With 30+ plugins, the cumulative CLAUDE.md weight can exceed the actual task context. The plugins consume more context than the work.
5. **Superpowers blocking in unattended mode:** "It keeps pelting me with blocking questions, like asking permission to read a subdirectory." This breaks autonomous workflows that other plugins (like GSD's `/gsd:auto`) depend on. Source: [Reddit](https://reddit.com/r/ClaudeCode/comments/1qr7smp/)
6. **Token burn stacking:** "My rate limits have been maxing out after only one pass of the superpowers workflow recently." Multiple plugins each adding their own overhead compounds quickly. Source: [Reddit](https://reddit.com/r/ClaudeCode/comments/1rs1une/)

---

## 9. UserPromptSubmit Hook Overhead

**Every user message triggers ALL registered UserPromptSubmit hooks before Claude processes the message.**

**Current overhead in your setup:**
- Token Optimizer's `measure.py quality-cache --quiet` runs on every prompt
- If Pilot is also installed, `prompt-reinject.sh` also runs on every prompt
- Each hook has a timeout (5-10s) but adds subprocess spawn overhead

**The cumulative cost:**
- Subprocess spawn: ~50-200ms per hook (Python interpreter startup, bash startup)
- Script execution: variable, but measure.py reads/writes cache files
- Total per-prompt overhead: 200ms-10s depending on hook complexity
- Over a 100-message session: 20s-1000s of pure hook overhead
- **This overhead is invisible to the user** -- it manifests as "Claude seems slow to respond"

**Community reports:** The Compaction Advisor plugin advertises "Zero tokens when healthy. ~20 tokens when warning needed" for its UserPromptSubmit hook -- indicating awareness that per-prompt hooks must be extremely lightweight. Source: [Reddit](https://www.reddit.com/r/ClaudeAI/comments/1q7vv1l/)

---

## 10. Reference File Staleness

**The problem:** Plugin-provided reference files are snapshots from the plugin's release date. They become outdated but continue being fed to the model as authoritative.

**Examples in your setup:**
- Pilot's `references/security/owasp-top-10.md` -- OWASP updates annually. Plugin references may lag.
- Pilot's `references/performance/core-web-vitals.md` -- Google updates CWV metrics. INP replaced FID in March 2024.
- Vercel plugin's cached CLAUDE.md (3 copies at different commits) -- may contain outdated Next.js guidance
- GSD's `react-best-practices.md` reference -- React evolves; patterns from 6 months ago may be wrong
- Context7 mitigates this by fetching live docs, but only when explicitly invoked

**Why it matters:** The model treats reference files with the same authority as live documentation. If a reference says "use getStaticProps" (removed in Next.js 15+), the model will confidently use the deprecated API. The reference file's authority actually overrides the model's training knowledge, which may be more current.

**No staleness detection exists.** No plugin checks whether its reference files are still accurate. There is no expiry mechanism, no version tracking, no diff against current documentation.

---

## 11. The Over-Prescription Problem

**When too many rules make the model worse:**

- **Superpowers skill description:** "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior." This means a simple button color change must go through a full brainstorming skill invocation.
- **GSD quality rules:** "TDD: no prod code without failing test. VERIFY: run command -> read output -> check exit code -> claim." For a one-line typo fix, this mandates a full TDD cycle.
- **Anti-slop rules:** "Planner MUST include code quality analysis. Verifier MUST scan for OX Security 10 anti-patterns + slop indicators." Every plan, even for trivial changes.
- **Research rules:** "MUST research best approaches via Context7 + Tavily MCP + WebSearch for industry standards." Even for well-understood patterns.

**The cascade:** The model reads ALL rules, determines it MUST follow ALL of them, and transforms a 30-second fix into a 15-minute ceremony. Users report Opus 4.6 "treating a basic digit change like a complex problem" with costs of $45+ for trivial edits.

**Community observation (bswen.com):** "Adding every rule instead of creating skills" is listed as the #1 common mistake. The solution is progressive disclosure -- rules that load only when relevant (via glob-scoped rule files or skills with `disable-model-invocation: true`).

---

## 12. Exit Code 2 (Blocking Hook) Failure Modes

**This is a well-documented pain point with multiple open GitHub issues:**

- **Issue #38422:** Exit code 2 blocks are displayed as "Error: PreToolUse:Bash hook error" -- the "Error" framing causes the model to treat intentional blocks as failures and sometimes STOP entirely instead of acting on the feedback. Source: [GitHub #38422](https://github.com/anthropics/claude-code/issues/38422)
- **Issue #24327:** "PreToolUse hook exit code 2 causes Claude to stop instead of acting on error feedback." The model sees "error" and gives up rather than adjusting its approach. Source: referenced in #38422
- **Issue #35086:** No UI distinction between blocking (exit 2), failure (exit 1), and informational (exit 0 with stderr). All show as "hook error." This makes debugging impossible when hooks are used heavily. Source: [GitHub #35086](https://github.com/anthropics/claude-code/issues/35086)
- **Issue #21988:** "PreToolUse hooks exit code ignored - operations proceed after hook failure." In some versions, exit code 1 was supposed to block but didn't, completely defeating security hooks. Source: [GitHub #21988](https://github.com/anthropics/claude-code/issues/21988)

**The loop scenario:** If a Stop hook with exit code 2 blocks Claude from stopping, and Claude's retry attempt triggers the same block condition, the session enters a loop:
1. Claude tries to stop
2. Stop hook blocks with exit 2
3. Claude tries to fix the issue
4. Claude tries to stop again
5. Stop hook blocks again (if the fix didn't address the hook's check)
6. Repeat until the user manually intervenes or the context fills up

**This is NOT theoretical.** Pilot's Stop hook (`stop-verify.sh`) blocks on TypeScript errors OR unchecked feature items. If a TypeScript error is unfixable (e.g., a dependency type mismatch), the hook will block every stop attempt indefinitely.

---

## 13. Reports of Plugins REDUCING Quality

**Direct evidence:**

1. **Vercel's eval data:** Skills present but unused degraded performance BELOW baseline. Not just neutral -- actively harmful. Source: Vercel blog
2. **Skill trigger failure rate:** A developer tested a carefully crafted skill with 20 obvious trigger prompts. Trigger rate: ZERO out of 20. The skill existed, consumed tokens, added noise, but never fired. Source: [Corporate Waters Substack](https://corpwaters.substack.com/p/the-ultimate-guide-to-claude-code)
3. **Superpowers replacing built-in behaviors:** "Since installing Superpowers, Claude doesn't seem to auto-enter Plan Mode anymore." The plugin overrides superior built-in functionality. Source: [Reddit](https://reddit.com/r/ClaudeCode/comments/1qy04jd/)
4. **Mass cancellation wave (Sept 2025):** Claude Code usage dropped from 83% to 70%. While partly due to model degradation, users specifically cited "plugin fatigue" as a contributing factor. Source: [AI Engineering Report](https://www.aiengineering.report/p/devs-cancel-claude-code-en-masse)
5. **The "radical minimalism" movement:** A counter-trend emerged where users deliberately strip ALL plugins and work with bare Claude Code + minimal CLAUDE.md. These users report BETTER outcomes for straightforward coding tasks. Source: Community research in `.planning/research/claude-code-harness-community-research-2026.md`
6. **Ralph plugin author's observation:** "The claude code plugin lets a single session grow until it inevitably rots, with no real visibility into when context has gone bad." Source: [Twitter/X](https://x.com/UK_Daniel_Card/status/2010469802993991796)
7. **Corporate Waters finding:** "Why not just stick with a well-written system prompt in your CLAUDE.md? It's simpler, always loads, doesn't have trigger reliability issues, and is easier to iterate on. Anyone telling you [skills are] a slam-dunk upgrade over a good system prompt is selling something."

---

## Synthesis: The Anti-Pattern Taxonomy

| Category | Severity | Detection Difficulty | Mitigation |
|----------|----------|---------------------|------------|
| Token tax (baseline overhead) | HIGH | Easy (`/context` command) | Audit plugin count, use `--bare` for scripts |
| Hook interference (duplicate/conflicting) | MEDIUM | Hard (no dedup detection) | Manual audit of settings.json |
| Context pollution (bloated CLAUDE.md) | HIGH | Medium (line count check) | Keep under 100 lines, use rule files |
| Skill noise (unused skills degrading quality) | HIGH | Hard (requires eval suite) | Disable unused plugins, minimize skill count |
| Harness lock-in | LOW (until removal) | Easy (try removing a plugin) | Design for removability from day 1 |
| Compaction state loss | MEDIUM | Hard (only visible mid-session) | Implement PreCompact hooks, use disk state |
| False safety | HIGH | Very Hard (requires manual QA) | Add E2E tests, don't trust hook checks alone |
| Multi-plugin conflicts | HIGH | Medium (observe behavior) | Limit to 3-5 plugins max |
| UserPromptSubmit overhead | LOW-MEDIUM | Hard (invisible latency) | Keep hooks under 100ms, minimize count |
| Reference staleness | MEDIUM | Hard (requires version tracking) | Use Context7 for live docs, add expiry dates |
| Over-prescription | HIGH | Medium (observe model behavior) | Progressive disclosure, glob-scoped rules |
| Exit code 2 loops | CRITICAL | Easy (session hangs) | Add max-retry logic, timeout fallbacks |
| Plugins reducing quality | HIGH | Very Hard (requires A/B testing) | Baseline eval before adding any plugin |

---

## Recommendations for Pilot

1. **Measure your own token tax.** Add a `/pilot:context-audit` command that reports Pilot's contribution to baseline overhead.
2. **Detect hook conflicts at install time.** Check for duplicate PostToolUse typecheckers, duplicate context monitors.
3. **Add a max-retry to Stop hook.** Prevent the exit code 2 infinite loop. After 3 blocks, warn and allow stop.
4. **Version-stamp reference files.** Add `last-verified: 2026-04-01` to each reference. Warn when stale.
5. **Implement progressive disclosure.** Only load references relevant to current file types (glob-scoped rules).
6. **Test with AND without Pilot.** Establish baseline eval scores, then measure delta. Ship the numbers.
7. **Design for removability.** Document what Pilot creates, and provide a clean `/pilot:uninstall` that removes all artifacts.

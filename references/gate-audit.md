# STP Gate Audit — Stress-Testing Scaffolding

> Per Anthropic's harness design guidance: "every component in a harness encodes an assumption
> about what the model can't do on its own, and those assumptions are worth stress testing."
> Remove one at a time, measure quality impact.

Audit date: 2026-04-10
Model baseline: Opus 4.6 [1M], Sonnet 4.6 [200K]

## Gate Assessment

| # | Gate | Event | Assumption it encodes | Still load-bearing? | Recommendation |
|---|------|-------|----------------------|--------------------|----|
| 1 | ui-gate | PreToolUse | Model will write UI without design system | **YES** — v0.3.1 failure proved this | Keep |
| 2 | whiteboard-gate | PreToolUse | Model hallucinates filenames from training data | **YES** — v0.3.3 post-mortem: `explore-data.json` | Keep |
| 3 | post-edit-check | PostToolUse | Model doesn't always run type-check after edits | **YES** — catches errors before they compound | Keep |
| 4 | anti-slop-scan | PostToolUse | Model produces AI-slop patterns (gradient headlines, etc.) | **YES** — still common with Sonnet executors | Keep |
| 5 | stop:unchecked-items | Stop | Model claims done with unchecked checklist items | **YES** — models routinely skip items | Keep |
| 6 | stop:missing-plan | Stop | Model starts coding without a plan | **MAYBE** — Opus 4.6 rarely does this, Sonnet still does | Keep as WARN (current) |
| 7 | stop:no-tests | Stop | Model writes code without tests | **YES** — core TDD enforcement | Keep |
| 8 | stop:secrets | Stop | Model hardcodes API keys | **YES** — non-negotiable security gate | Keep |
| 9 | stop:placeholders | Stop | Model leaves TODO/FIXME/mock data | **YES** — production philosophy enforcement | Keep as WARN (current) |
| 10 | stop:hollow-tests | Stop | Model writes tautological tests | **YES** — 57% AI test kill rate confirms | Keep as WARN (current) |
| 11 | stop:type-errors | Stop | Model produces code with type errors | **YES** — deterministic, no model can bypass | Keep |
| 12 | stop:test-failures | Stop | Model claims tests pass when they don't | **YES** — deterministic | Keep |
| 13 | stop:schema-drift | Stop | Model changes ORM without migration | **YES** — catches real production bugs | Keep |
| 14 | stop:scope-reduction | Stop | Model drops PRD requirements from plan | **MAYBE** — useful during planning, noisy during quick fixes | Consider: disable for /stp:work-quick |
| 15 | stop:spec-delta | Stop | Model doesn't update CHANGELOG/ARCHITECTURE after features | **MAYBE** — good discipline but adds ceremony | Consider: downgrade to WARN for work-quick |
| 16 | stop:critic-required | Stop | Model ships without Critic review | **YES** — core quality gate | Keep |
| 17 | stop:qa-required | Stop | Model ships UI without QA testing | **YES** — for UI features | Keep |
| 18 | SessionStart | SessionStart | Context needs cleanup between sessions | **YES** — infrastructure | Keep |
| 19 | PreCompact | PreCompact | State must survive compaction | **YES** — infrastructure | Keep |

## Candidates for Removal/Relaxation

### Phase 3: Tools Discovery (work-full Phase 3)
**Not a hook but a phase.** Opus 4.6 checks available MCP tools natively via the tool list. 
The "check which stripe / vercel / prisma CLIs are installed" pattern is useful but could be 
a 10-line checklist rather than a 168-line phase file. 
**Recommendation:** Compress phase3-tools.md from 168 to ~60 lines. Remove MCP server 
installation guidance (Opus handles this). Keep UI/UX design system gate (hook-enforced).

### 13 Sub-Phase Section-by-Section Approval (work-full Phase 5)
**Not a hook but a UX pattern.** Most users approve all 13 sections. 
**Recommendation:** Default to show-all-approve-once. Add `--section-approval` flag for users 
who want per-section review. This cuts 13 AskUserQuestion round-trips to 1.

### stop:scope-reduction + stop:spec-delta in work-quick
**These gates enforce plan/doc discipline that's overkill for quick fixes.**
**Recommendation:** Add profile-aware gate sensitivity. In work-quick context, downgrade both to 
WARN (from BLOCK/WARN). They still fire, but don't interrupt quick work.

## Gates Confirmed Load-Bearing (DO NOT REMOVE)

1. **ui-gate** — proven by v0.3.1 incident
2. **whiteboard-gate** — proven by v0.3.3 incident
3. **stop:no-tests** — core TDD enforcement
4. **stop:secrets** — non-negotiable security
5. **stop:type-errors / stop:test-failures** — deterministic, always correct
6. **stop:schema-drift** — catches real production bugs
7. **stop:critic-required / stop:qa-required** — core verification stack
8. **anti-slop-scan** — Sonnet executors still produce slop patterns
9. **post-edit-check** — catches errors before they compound

## Action Items

1. [ ] Compress phase3-tools.md (168 → ~60 lines) — remove MCP installation ceremony
2. [ ] Default Phase 5 to show-all-approve-once (add --section-approval flag)
3. [ ] Add work-quick context awareness to scope-reduction and spec-delta gates
4. [ ] Test: disable stop:missing-plan for 10 builds, measure if quality drops

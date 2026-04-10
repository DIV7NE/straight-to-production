# STP CLI Output Formatting Guide

## Design Language

| Element | Characters | Use for |
|---------|-----------|---------|
| Double-line box | `╔═╗║╚═╝╠╣` | Major events: command start, feature complete, milestone, bug fixed |
| Single-line box | `┌─┐│└─┘` | Information: evidence, scans, reports, decisions |
| Dimmed teach | `┊` | Subtle: teach moments, context notes (2-3 sentences max) |
| Symbols | `✓ ✗ ⚠ ★ ► ◆` | Status: success, failure, warning, milestone, next, key point |

## Color Palette (ANSI)

Output ALL formatted blocks via `echo -e` (Bash tool). Monochrome is NOT acceptable.

| Element | Code | Color |
|---------|------|-------|
| Borders (double) | `\033[36m` | Cyan |
| Borders (single) | `\033[2;36m` | Dim cyan |
| Brand + command | `\033[1;36m` | Bold cyan |
| Titles | `\033[1;37m` | Bold white |
| Success ✓ | `\033[32m` | Green |
| Error ✗ | `\033[31m` | Red |
| Warning ⚠ | `\033[33m` | Yellow |
| Milestone ★ | `\033[1;33m` | Bold yellow |
| Next ► | `\033[34m` | Blue |
| Teach ┊ | `\033[2;35m` | Dim magenta |
| Reset | `\033[0m` | — (after every colored segment) |

## Rendering

```bash
# Double-line box example (major event):
echo -e "\033[36m╔═══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║\033[0m  \033[1;36mSTP ► COMMAND-NAME\033[0m                                  \033[36m║\033[0m"
echo -e "\033[36m╚═══════════════════════════════════════════════════════╝\033[0m"

# Single-line info box:
echo -e "\033[2;36m┌─── \033[0;37mTitle\033[2;36m ────────────────────────────────────────────┐\033[0m"
echo -e "\033[2;36m│\033[0m  \033[37mKey\033[0m    value                                        \033[2;36m│\033[0m"
echo -e "\033[2;36m└──────────────────────────────────────────────────────┘\033[0m"
```

## Templates (22 total — all ~55 char inner width)

| # | Template | Box type | Content spec |
|---|----------|----------|-------------|
| 1 | Command Banner | Double ╔═╗ | `STP ► [COMMAND]` + tagline. EVERY command starts with this. |
| 2 | Phase/Step Header | Single `┌───` | `Step [N]: [Name]` — one line, no closing box |
| 3 | Info Block | Single ┌─┐ | Title + key-value rows (aligned). For evidence, scans, status. |
| 4 | Success Block | Single ┌─✓ | `✓ [Title]` + detail lines |
| 5 | Warning Block | Single ┌─⚠ | `⚠ [Title]` + warning + recommendation |
| 6 | Error Block | Single ┌─✗ | `✗ [Title]` + error + suggested fix |
| 7 | Feature Complete | Double ╔═╗ | `✓ FEATURE COMPLETE` + name + version + Built list + Tests/Types/Hooks |
| 8 | Milestone Complete | Double ╔═╗ | `★ MILESTONE [N]` + name + version + Features/Tests/E2E + Critic 7-criteria |
| 9 | All Milestones | Double ╔═╗ | `★ ALL MILESTONES COMPLETE` + totals + "feature-complete per PRD" |
| 10 | QA Report | Single ┌─┐ | `QA Report` + ✓/✗ per acceptance criterion + result line |
| 11 | Option Comparison | Single ┌─┐ | Per option: How it works, Who uses this, Best for, ⚠ Downside |
| 12 | Recommendation | Single ┌─◆ | `◆ Recommendation` + option name + 1-2 sentence reasoning |
| 13 | Architecture Section | Single ┌─┐ | `Architecture: [Section]` + section content |
| 14 | Teach Moment | `┊` prefix | 2-3 sentences max. Subtle, never outshines output. |
| 15 | Progress Bar | Inline | `[■■■■░░░░] [N]/[M] features · Milestone [N]` |
| 16 | Next Step | Inline | `► Next: /stp:[command] [args]` |
| 17 | Decision Context | Single ┌─┐ | Context about what needs deciding. Before AskUserQuestion. |
| 18 | Bug Fixed | Double ╔═╗ | `✓ BUG FIXED` + description + Root cause/Fix/Defense + Tests |
| 19 | Project Onboarded | Double ╔═╗ | `✓ PROJECT [ONBOARDED/CREATED]` + Stack/Files/Models/Routes + docs list |
| 20 | Upgrade Report | Double ╔═╗ | `✓ STP UPGRADE` + version + ✓/✗ checklist (core/plugins/MCP/CLAUDE.md/hooks) |
| 21 | Review/Critic | Double ╔═╗ | `REVIEW COMPLETE` + 7 criteria PASS/FAIL + Overall |
| 22 | Resuming Session | Double ╔═╗ | `RESUMING` + feature + progress + Last activity/Next step/Blockers |

## Rules

1. EVERY `/stp:` command starts with Template 1 (Command Banner)
2. Major events (complete, milestone, bug fixed) = double-line ╔═╗
3. Evidence/data = single-line ┌─┐ Info Blocks, never raw text
4. Teach moments = `┊` prefix, subtle
5. Next steps = `►` indicator
6. Keep box widths ~55 chars. Align key-value pairs.
7. Every AskUserQuestion preceded by Decision Context (Template 17)

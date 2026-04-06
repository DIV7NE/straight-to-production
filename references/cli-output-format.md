# STP CLI Output Formatting Guide

All STP command output MUST use these templates for a consistent, polished CLI experience. This is the visual design system for every `/stp:` command.

## Design Language

| Element | Characters | Use for |
|---------|-----------|---------|
| Double-line box | `╔═╗║╚═╝╠╣` | Major events: command start, feature complete, milestone complete |
| Single-line box | `┌─┐│└─┘` | Information: evidence, scans, reports, decisions, options |
| Dimmed teach | `┊` | Subtle: teach moments, context notes |
| Symbols | `✓ ✗ ⚠ ★ ► ◆` | Status: success, failure, warning, milestone, next, key point |

## Color Palette (ANSI — professional, not garish)

Output ALL formatted blocks via `echo -e` through the Bash tool to render colors. This is MANDATORY — monochrome box-drawing is not enough.

| Element | ANSI Code | Color | Use for |
|---------|-----------|-------|---------|
| Borders (double-line) | `\033[36m` | Cyan | ╔═╗║╚═╝ on major event boxes |
| Borders (single-line) | `\033[2;36m` | Dim cyan | ┌─┐│└─┘ on info boxes |
| STP brand + command name | `\033[1;36m` | Bold cyan | "STP ►" and command name in banners |
| Titles / key values | `\033[1;37m` | Bold white | Feature names, project names, headings inside boxes |
| Success | `\033[32m` | Green | ✓ symbols, "PASS", "COMPLETE" |
| Error | `\033[31m` | Red | ✗ symbols, "FAIL", "BLOCK" |
| Warning | `\033[33m` | Yellow | ⚠ symbols, "PARTIAL", "WARN" |
| Milestone star | `\033[1;33m` | Bold yellow | ★ symbol |
| Next step arrow | `\033[34m` | Blue | ► symbol and command text |
| Teach moment | `\033[2;35m` | Dim magenta | ┊ prefix and teach text |
| Labels (left column) | `\033[37m` | White | Key names in key-value pairs |
| Values (right column) | `\033[0m` | Default | Values after labels |
| Reset | `\033[0m` | — | After every colored segment |

### How to Render

Use `echo -e` via the Bash tool for ALL formatted output blocks. Build the string with embedded ANSI codes:

```bash
echo -e "\033[36m╔═══════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║\033[0m  \033[1;36mSTP ► WORK-QUICK\033[0m                                    \033[36m║\033[0m"
echo -e "\033[36m║\033[0m  \033[2m\"Just do it, skip the ceremony.\"\033[0m                     \033[36m║\033[0m"
echo -e "\033[36m╚═══════════════════════════════════════════════════════╝\033[0m"
```

For single-line info boxes:
```bash
echo -e "\033[2;36m┌─── \033[0;37mImpact Scan\033[2;36m ──────────────────────────────────────┐\033[0m"
echo -e "\033[2;36m│\033[0m  \033[37mFiles affected\033[0m     7                                 \033[2;36m│\033[0m"
echo -e "\033[2;36m│\033[0m  \033[37mModels\033[0m             \033[32mno\033[0m                                \033[2;36m│\033[0m"
echo -e "\033[2;36m│\033[0m  \033[37mAuth/security\033[0m      \033[31myes (middleware.ts)\033[0m               \033[2;36m│\033[0m"
echo -e "\033[2;36m└──────────────────────────────────────────────────────┘\033[0m"
```

For success symbols: `\033[32m✓\033[0m` (green check)
For error symbols: `\033[31m✗\033[0m` (red cross)
For warnings: `\033[33m⚠\033[0m` (yellow warning)
For next steps: `\033[34m► Next:\033[0m /stp:work-quick [feature]`
For teach moments: `\033[2;35m  ┊ Explanation text here\033[0m`

### Fallback

If `echo -e` is not available or output must be inline text (not via Bash), fall back to the monochrome box-drawing templates below. The structure is the same — just without color.

## Templates

### 1. Command Banner (EVERY command start)

```
╔═══════════════════════════════════════════════════════╗
║  STP ► [COMMAND NAME]                                 ║
║  "[tagline from command description]"                 ║
╚═══════════════════════════════════════════════════════╝
```

Example:
```
╔═══════════════════════════════════════════════════════╗
║  STP ► WORK-QUICK                                     ║
║  "Just do it, skip the ceremony."                     ║
╚═══════════════════════════════════════════════════════╝
```

### 2. Phase / Step Header

```
┌─── Step [N]: [Name] ─────────────────────────────────┐
```

Example: `┌─── Step 2: Research ─────────────────────────────────┐`

### 3. Info Block (evidence, scan results, status)

```
┌─── [Title] ──────────────────────────────────────────┐
│  [Key]              [Value]                           │
│  [Key]              [Value]                           │
│  [Key]              [Value]                           │
└──────────────────────────────────────────────────────┘
```

Example:
```
┌─── Impact Scan ──────────────────────────────────────┐
│  Files affected     7                                 │
│  Models             yes (schema.prisma)               │
│  Auth/security      no                                │
│  New routes         2 endpoints                       │
│  Score              8 → Full cycle                    │
└──────────────────────────────────────────────────────┘
```

### 4. Success Block

```
┌─── ✓ [Title] ────────────────────────────────────────┐
│  [Details line 1]                                     │
│  [Details line 2]                                     │
└──────────────────────────────────────────────────────┘
```

### 5. Warning Block

```
┌─── ⚠ [Title] ────────────────────────────────────────┐
│  [Warning details]                                    │
│  [Recommendation]                                     │
└──────────────────────────────────────────────────────┘
```

### 6. Error Block

```
┌─── ✗ [Title] ────────────────────────────────────────┐
│  [Error details]                                      │
│  [Suggested fix]                                      │
└──────────────────────────────────────────────────────┘
```

### 7. Feature Complete

```
╔═══════════════════════════════════════════════════════╗
║  ✓ FEATURE COMPLETE                                   ║
║  [Feature Name] (v[X.Y.Z])                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Built:                                               ║
║  · [Item 1]                                           ║
║  · [Item 2]                                           ║
║  · [Item 3]                                           ║
║                                                       ║
║  Tests    [N] new · [N] total · all passing           ║
║  Types    clean                                       ║
║  Hooks    8/8 gates passed                            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 8. Milestone Complete

```
╔═══════════════════════════════════════════════════════╗
║  ★ MILESTONE [N] COMPLETE                             ║
║  "[Milestone Name]"   v[X.Y.0]                       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Features   [N] built · 0 remaining                  ║
║  Tests      [N] passing                               ║
║  E2E        verified                                  ║
║                                                       ║
║  Critic:                                              ║
║  · Functionality    [PASS/PARTIAL/FAIL]               ║
║  · Design           [PASS/PARTIAL/FAIL]               ║
║  · Security         [PASS/PARTIAL/FAIL]               ║
║  · Accessibility    [PASS/PARTIAL/FAIL]               ║
║  · Performance      [PASS/PARTIAL/FAIL]               ║
║  · Production       [PASS/PARTIAL/FAIL]               ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 9. All Milestones Complete

```
╔═══════════════════════════════════════════════════════╗
║  ★ ALL MILESTONES COMPLETE                            ║
║  [Project Name]   v[X.Y.0]                           ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Total features    [N] built                          ║
║  Total tests       [N] passing                        ║
║  Integration       verified                           ║
║                                                       ║
║  Your project is feature-complete per the PRD.        ║
║  Fix remaining issues, then deploy.                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 10. QA Report

```
┌─── QA Report ────────────────────────────────────────┐
│  ✓ [AC1 description]                                  │
│  ✓ [AC2 description]                                  │
│  ✗ [AC3 description]            → FIXED               │
│  ✓ [AC4 description]                                  │
│                                                       │
│  Result: [ALL PASS / N issues fixed during QA]        │
└──────────────────────────────────────────────────────┘
```

### 11. Option Comparison (whiteboard / research)

```
┌─── Option A: [Name] ────────────────────────────────┐
│                                                       │
│  How it works:   [2-3 sentences]                      │
│  Who uses this:  [Real companies]                     │
│  Best for:       [When to pick this]                  │
│  ⚠ Downside:    [Honest limitation]                  │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### 12. Recommendation Block

```
┌─── ◆ Recommendation ────────────────────────────────┐
│  [Option name] — [1-2 sentence reasoning]             │
└──────────────────────────────────────────────────────┘
```

### 13. Architecture Section (work-full blueprint approval)

```
┌─── Architecture: [Section Name] ─────────────────────┐
│                                                       │
│  [Section content — models, routes, auth, etc.]       │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### 14. Teach Moment

Subtle — never outshines actual output. 2-3 sentences max.

```
  ┊ [Concept explanation in plain language]
```

### 15. Progress Indicator

```
  [■■■■■■░░░░] [N]/[M] features · Milestone [N]
```

### 16. Next Step

```
  ► Next: /stp:[command] [arguments]
```

### 17. Decision Context (before AskUserQuestion)

```
┌─── Decision ─────────────────────────────────────────┐
│  [Context about what needs deciding]                  │
└──────────────────────────────────────────────────────┘
```

### 18. Bug Fixed (debug)

```
╔═══════════════════════════════════════════════════════╗
║  ✓ BUG FIXED                                         ║
║  [Bug description]                                    ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Root cause:  [What was actually wrong]               ║
║  Fix:         [What was changed]                      ║
║  Defense:     [What prevents recurrence]              ║
║                                                       ║
║  Tests    [N] new · all passing                       ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 19. Project Onboarded / Created

```
╔═══════════════════════════════════════════════════════╗
║  ✓ PROJECT [ONBOARDED/CREATED]                        ║
║  [Project Name]                                       ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Stack       [detected stack]                         ║
║  Files       [N] analyzed                             ║
║  Models      [N] detected                             ║
║  Routes      [N] mapped                               ║
║  Components  [N] cataloged                            ║
║                                                       ║
║  Documents created:                                   ║
║  · .stp/docs/ARCHITECTURE.md                          ║
║  · .stp/docs/CONTEXT.md                               ║
║  · .stp/docs/PRD.md                                   ║
║  · CLAUDE.md                                          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 20. Upgrade Report

```
╔═══════════════════════════════════════════════════════╗
║  ✓ STP UPGRADE COMPLETE                               ║
║  v[old] → v[new]                                      ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  [✓/✗] Core files updated                             ║
║  [✓/✗] Companion plugins verified                     ║
║  [✓/✗] MCP servers verified                           ║
║  [✓/✗] CLAUDE.md sections refreshed                   ║
║  [✓/✗] Hooks verified                                 ║
║  [✓/✗] Local patches restored                         ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 21. Review / Critic Report

```
╔═══════════════════════════════════════════════════════╗
║  STP ► REVIEW COMPLETE                                ║
║  [Feature/Milestone Name]                             ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  1. Functionality     [PASS/PARTIAL/FAIL]  [notes]    ║
║  2. Design            [PASS/PARTIAL/FAIL]  [notes]    ║
║  3. Security          [PASS/PARTIAL/FAIL]  [notes]    ║
║  4. Accessibility     [PASS/PARTIAL/FAIL]  [notes]    ║
║  5. Performance       [PASS/PARTIAL/FAIL]  [notes]    ║
║  6. Production        [PASS/PARTIAL/FAIL]  [notes]    ║
║  7. Code Quality      [PASS/PARTIAL/FAIL]  [notes]    ║
║                                                       ║
║  Overall: [PASS/NEEDS WORK]                           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

### 22. Resuming Session

```
╔═══════════════════════════════════════════════════════╗
║  STP ► RESUMING                                       ║
║  [Feature Name] — [N]/[M] items complete              ║
╠───────────────────────────────────────────────────────╣
║                                                       ║
║  Last activity:  [date + what was done]               ║
║  Next step:      [what to do now]                     ║
║  Blockers:       [any issues noted in handoff]        ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## Formatting Rules

1. **EVERY** `/stp:` command starts with a Command Banner (template 1)
2. Major transitions within commands use Phase Headers (template 2)
3. Evidence and data ALWAYS go in Info Blocks — never raw text dumps
4. Use the correct status block: ✓ success, ⚠ warning, ✗ error
5. Feature Complete and Milestone Complete are ALWAYS double-line boxes
6. Teach moments use `┊` prefix — subtle, never outshine actual output
7. QA results always in QA Report blocks with ✓/✗ per criterion
8. Whiteboard options always in Option Comparison blocks with structured fields
9. Next steps always use `►` indicator
10. Progress bars for multi-step processes with more than 3 steps
11. Keep box widths consistent at ~55 characters for the inner content
12. Align key-value pairs in Info Blocks for scanability
13. Every AskUserQuestion is preceded by a Decision Context block (template 17)

---
description: "First-time STP setup. Checks system, installs companion plugins, picks your profile, and shows you around."
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "AskUserQuestion"]
---

> **Recommended effort: `/effort low`** — Guided checklist, no deep thinking needed.

# /stp:welcome — First-Time Setup

Walk a new user through everything they need before their first `/stp:new-project` or `/stp:onboard-existing`. Five phases, fully guided.

## Phase 1 — System Check (silent, then report)

Run in parallel:
```bash
node --version
python3 --version 2>/dev/null || echo "python3: NOT FOUND"
cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | grep version
```

Display results as direct text output in your response (NOT via bash echo — Claude Code collapses long bash output):
```
╔═══════════════════════════════════════════════╗
║  STP Welcome — System Check                   ║
╠═══════════════════════════════════════════════╣
║  STP        : v0.X.X ✓                        ║
║  Node.js    : v22.x ✓                         ║
║  Python 3   : v3.12 ✓ / ⚠ missing             ║
║  Claude Code: active ✓                         ║
╚═══════════════════════════════════════════════╝
```

If Python is missing, note: "Python 3 is needed for `/stp:whiteboard` (visual diagrams). STP works fine without it — whiteboard just won't be available. Install with your package manager if you want it."

**Statusline check:** Verify the STP statusline is registered in `~/.claude/settings.json`:
```bash
grep -q "stp-statusline" ~/.claude/settings.json 2>/dev/null && echo "statusline: registered" || echo "statusline: MISSING"
```

If `statusline: MISSING`, register it automatically:
```bash
# Read current settings.json, add statusline entry, write back
node -e "
const fs = require('fs');
const p = require('path').join(process.env.HOME, '.claude', 'settings.json');
let s = {};
try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch {}
s.statusLine = { type: 'command', command: 'node \"' + process.env.CLAUDE_PLUGIN_ROOT + '/hooks/scripts/stp-statusline.js\"' };
fs.writeFileSync(p, JSON.stringify(s, null, 2));
"
```
Report: "✓ Statusline registered — restart Claude Code to activate."

If already registered, report: "✓ Statusline: registered"

Don't stop. Continue to Phase 2.

## Phase 2 — Companion Plugin Audit

Test each required MCP server by making a real tool call. Report results as a checklist.

**Context7** — try:
```
mcp__plugin_context7_context7__resolve-library-id(libraryName: "react")
```
If it returns a result → ✓ installed. If tool not found → ✗ missing.

**Tavily** — try:
```
mcp__tavily__tavily_search(query: "test", max_results: 1)
```
If it returns → ✓ installed. If tool not found → ✗ missing.

**Context Mode** — try:
```
mcp__plugin_context-mode_context-mode__ctx_stats()
```
If it returns → ✓ installed. If tool not found → ✗ missing.

**ui-ux-pro-max** — check:
```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "installed" || echo "missing"
```

Display as direct text output in your response:
```
╔═══════════════════════════════════════════════╗
║  Companion Plugins                             ║
╠═══════════════════════════════════════════════╣
║  Context7      : ✓ / ✗                        ║
║  Tavily        : ✓ / ✗                        ║
║  Context Mode  : ✓ / ✗                        ║
║  ui-ux-pro-max : ✓ / ✗                        ║
╚═══════════════════════════════════════════════╝
```

If ANY are missing, show:

```
AskUserQuestion(
  question: "Some companion plugins are missing. Want me to show install commands?",
  header: "Plugins",
  options: [
    "(Recommended) Show install commands for missing plugins",
    "Skip — I'll install them later",
    "I don't need these — continue without them"
  ]
)
```

If "Show install commands", print the relevant commands:
```
  Missing plugin install commands (run in your terminal):

  Context7:      claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
  Tavily:        claude mcp add tavily -- npx -y tavily-mcp@latest
                 (requires TAVILY_API_KEY — get one at https://tavily.com)
  Context Mode:  claude mcp add context-mode -- npx -y context-mode-mcp@latest
  ui-ux-pro-max: npm i -g uipro-cli && uipro init --ai claude

  After installing, restart Claude Code (/exit → claude) and run /stp:welcome again to verify.
```

If all installed → skip the prompt, just show the green checklist and continue.

## Phase 3 — Profile Selection

```
AskUserQuestion(
  question: "Which model profile should STP use? This controls how work is split between models — and how many messages you'll burn per feature.",
  header: "Profile",
  options: [
    "(Recommended) balanced — Opus plans, Sonnet builds. Best cost/quality ratio. ~50% cheaper than intended.",
    "intended — Opus does everything inline. Maximum quality, highest cost. For critical/complex projects.",
    "budget — Sonnet builds, Haiku reviews. Cheapest option (~70% savings). Good for iteration-heavy work.",
    "sonnet-main — Sonnet 200K only, no Opus. ~85% cheaper. For when you don't have Opus access.",
    "20-pro-plan — $20/mo Claude Pro plan. ZERO sub-agents, ≤30 msgs/feature. Stripped-down but real production workflow."
  ]
)
```

Apply the chosen profile:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <chosen-profile> --raw
```

Confirm (adapt message to chosen profile):

For `20-pro-plan`:
```
  ✓ Profile set: 20-pro-plan
    $20/mo Pro plan mode. Zero sub-agents. All work inline.
    Budget: ≤30 messages/feature, ≤80 messages per 5h window.
    Allowed: /stp:work-quick, /stp:debug, session commands.
    Blocked: work-full, autopilot, plan, review, whiteboard, new-project, onboard-existing.
```

For all other profiles:
```
  ✓ Profile set: <profile-name>
    <one-line description from profile>.
```

## Phase 4 — Quick Tour

Display the STP workflow as direct text output in your response. Don't explain everything — just enough to orient them. This MUST be fully visible — never behind a collapsed bash output.

**If the user chose `20-pro-plan`, show THIS tour instead of the standard one:**

```
╔═══════════════════════════════════════════════════════════╗
║  How STP Works — $20/mo Pro Plan                          ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  ⚠ You're on the Pro plan (~45-100 msgs per 5h window).  ║
║  Every message counts. STP adapts: zero sub-agents,       ║
║  deterministic verification only, ≤30 msgs per feature.   ║
║                                                           ║
║  ★ Your workflow:                                         ║
║                                                           ║
║  1. Describe what you want to build in ONE message.       ║
║     Be specific — include file paths, behavior, edge      ║
║     cases. The more detail upfront, the fewer follow-up   ║
║     messages you'll burn.                                 ║
║                                                           ║
║  2. /stp:work-quick — your main build command.            ║
║     Builds the feature inline (no sub-agents).            ║
║     Verifies with tests + types + lint (no AI critic).    ║
║     Target: done in ≤30 messages.                         ║
║                                                           ║
║  3. /stp:debug — when something breaks.                   ║
║     Root cause analysis, all inline. Fix + verify.        ║
║                                                           ║
║  Session commands (nearly free):                          ║
║    /stp:progress  — what's done, what's next              ║
║    /stp:continue  — resume after /clear or new session    ║
║    /stp:pause     — save state, come back later           ║
║                                                           ║
║  ✗ NOT available on Pro plan (too message-heavy):         ║
║    work-full, autopilot, plan, review, whiteboard,        ║
║    new-project, onboard-existing, research                ║
║                                                           ║
║  Tips to stretch your messages:                           ║
║    • /clear after every task (smaller context = faster)   ║
║    • Use Sonnet, not Opus (Opus burns msgs 2-3× faster)  ║
║    • Batch questions — ask multiple things per message    ║
║    • Be specific — "add a login form to app/login/page   ║
║      .tsx with email+password fields" beats "add login"   ║
║    • Don't explore — if you know the file, say so         ║
║                                                           ║
║  The philosophy stays: no mocks, no placeholders, real    ║
║  tests, production-quality code. Just fewer AI guardrails.║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

**For all other profiles, show the standard tour:**

```
╔═══════════════════════════════════════════════════════════╗
║  How STP Works                                            ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  One-time setup (you already did this):                   ║
║    /stp:welcome → /stp:new-project or /stp:onboard       ║
║                                                           ║
║  ★ Your daily starting point:                             ║
║                                                           ║
║    /stp:whiteboard  — start almost every feature here.    ║
║      Shape the idea, explore tradeoffs, research options. ║
║      Hands off to work-full or work-quick when ready.     ║
║                                                           ║
║  Shortcut (you already know exactly what + how):          ║
║    /stp:work-quick   — small task, ≤3 files              ║
║    /stp:work-full    — big feature, multi-file            ║
║    /stp:work-adaptive — let STP decide which              ║
║                                                           ║
║  Other commands:                                          ║
║    plan       — architecture blueprint (after whiteboard) ║
║    research   — investigate without building              ║
║    debug      — something broke? root cause analysis      ║
║    review     — grade your work (7 criteria + Critic)     ║
║    autopilot  — build overnight, AI decides everything    ║
║    progress   — what's done, what's next                  ║
║    continue   — resume after /clear or new session        ║
║    pause      — save state, come back later               ║
║                                                           ║
║  Every build updates your docs automatically.             ║
║  Every bug fix becomes a rule that prevents recurrence.   ║
║  Progress survives /clear and session breaks.             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

## Phase 5 — Ready

Detect the current project state:
```bash
# Is this a git repo with code?
[ -d ".git" ] && echo "git_repo: yes" || echo "git_repo: no"
# Has source files?
ls *.py *.ts *.js *.go *.rs src/ app/ 2>/dev/null | head -1
# Has package.json or equivalent?
ls package.json requirements.txt Cargo.toml go.mod Gemfile 2>/dev/null | head -1
# Already onboarded?
[ -d ".stp" ] && echo "stp: exists" || echo "stp: none"
```

Based on results:

**If the user is on `20-pro-plan`:**

Skip the new-project/onboard detection. Those commands are blocked on Pro plan. Instead:

```
  ✓ STP is ready — Pro Plan mode.

  Your budget: ~45-100 messages per 5-hour window.
  STP will use ≤30 of those per feature. /clear between tasks.

  ► Getting started:
    Just describe what you want to build, then run:
    /clear, then /stp:work-quick

  ► If something breaks:
    /clear, then /stp:debug

  ► Session management:
    /stp:pause     — save and stop
    /stp:continue  — resume later
    /stp:progress  — check status

  Tip: Use Sonnet (not Opus) to stretch your message budget.
  Tip: Run /stp:welcome again anytime to re-check your setup.
```

**For all other profiles, use the standard detection:**

**If `.stp/` already exists:**
```
  You're already set up in this project.

  ► Next: /stp:progress    — see where you are
          /stp:work-quick   — start building
          /stp:continue     — resume previous work
```

**If existing code detected (git repo + source files):**
```
  This looks like an existing project.

  ► Next: /stp:onboard-existing
    Maps your entire codebase, writes ARCHITECTURE.md, CONTEXT.md,
    reverse-engineered PRD.md. Read-only — doesn't change your code.
```

**If empty or new directory:**
```
  Fresh start detected.

  ► Next: /stp:new-project
    Tell STP what you want to build. It picks the stack, asks product
    questions, and scaffolds the foundation.
```

**Always end with:**
```
  ✓ STP is ready.

  Tip: Run /stp:welcome again anytime to re-check your setup.
```

## Rules

- **NEVER use `echo -e` / Bash for displaying results, boxes, tours, or checklists.** Claude Code collapses long bash outputs behind "ctrl+o to expand" — the user misses everything. Instead, output ALL formatted results as direct text in your response using markdown code blocks. Bash is ONLY for running actual commands (version checks, profile set, file checks). Results go in your response text.
- Never install MCP servers without showing the command first. The user runs them in their terminal.
- Don't block on missing plugins — STP works without them, just with reduced capability.
- Don't over-explain. This is onboarding, not documentation. Keep each phase under 30 seconds.
- If the user says "skip" at any phase, skip it and move on.

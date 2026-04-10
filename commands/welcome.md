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

Display results in a banner:
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

Display:
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
  question: "Which model profile should STP use? This controls how work is split between Opus and Sonnet.",
  header: "Profile",
  options: [
    "(Recommended) balanced — Opus plans, Sonnet builds. Best cost/quality ratio. ~50% cheaper than intended.",
    "intended — Opus does everything inline. Maximum quality, highest cost. For critical/complex projects.",
    "budget — Sonnet builds, Haiku reviews. Cheapest option (~70% savings). Good for iteration-heavy work.",
    "sonnet-main — Sonnet 200K only, no Opus. ~85% cheaper. For when you don't have Opus access."
  ]
)
```

Apply the chosen profile:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <chosen-profile> --raw
```

Confirm:
```
  ✓ Profile set: balanced-profile
    Opus plans and reviews. Sonnet builds and tests.
    Estimated cost: ~50% less than intended-profile.
```

## Phase 4 — Quick Tour

Display the STP workflow as a clean overview. Don't explain everything — just enough to orient them.

```
╔═══════════════════════════════════════════════════════════╗
║  How STP Works                                            ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  First time only:                                         ║
║    new-project / onboard-existing                         ║
║                                                           ║
║  Every feature (whiteboard first):                        ║
║    whiteboard → plan → work-full / work-quick             ║
║                                                           ║
║  Think         Build              Verify                  ║
║  ─────         ─────              ──────                  ║
║  whiteboard    work-full          review                  ║
║  plan          work-quick         (auto-Critic)           ║
║  research      debug / autopilot                          ║
║                                                           ║
║  Session: continue, pause, progress                       ║
║  Update:  upgrade, set-profile-model                      ║
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

- Never install MCP servers without showing the command first. The user runs them in their terminal.
- Don't block on missing plugins — STP works without them, just with reduced capability.
- Don't over-explain. This is onboarding, not documentation. Keep each phase under 30 seconds.
- If the user says "skip" at any phase, skip it and move on.
- Use `echo -e` with ANSI colors per STP CLI output format (cyan borders, green ✓, red ✗, yellow ⚠).

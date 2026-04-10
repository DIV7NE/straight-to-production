### Phase 3: TOOLS — Discover and Set Up What's Needed

**This phase prevents the "I wish I had X" moment mid-build.** Check what tools are available and what SHOULD be available for this type of work.

**Step 1: Check what's already available:**
```bash
# MCP servers (check Claude's connected services)
# The AI should check what MCP tools are available in its current session

# CLIs
which stripe 2>/dev/null && stripe --version
which vercel 2>/dev/null && vercel --version
which prisma 2>/dev/null && prisma --version
# [add relevant CLIs for the work type]
```

**Step 2: Determine what SHOULD be available:**

Based on the work type, identify tools that would significantly help:

| Work involves... | Useful tool | Check |
|-----------------|------------|-------|
| Stripe/payments | Stripe MCP server OR Stripe CLI | Can read products, create test data, verify webhooks |
| Database changes | Prisma CLI, Neon MCP | Can run migrations, inspect schema |
| Deployment | Vercel MCP OR Vercel CLI | Can check deploys, env vars |
| Email | Resend dashboard or API | Can verify templates, check delivery |
| Auth | Clerk dashboard MCP | Can check user configs |
| Error tracking | Sentry MCP | Can read production errors |
| Analytics | PostHog/Clarity MCP | Can check user behavior |

**Step 3: If a useful tool is missing, search and suggest:**

Research what's available:
```
Context7/Tavily: "Claude Code MCP server for [service]" OR "[service] CLI for development"
```

```
AskUserQuestion(
  question: "For this work, a [tool name] would help because [specific benefit]. It's not currently available. Want me to set it up?",
  options: [
    "(Recommended) Yes — install [tool]. [1-line what it enables]",
    "Skip — I'll work without it. [1-line what we lose]",
    "Chat about this"
  ]
)
```

**Step 4: Install if approved:**

For MCP servers:
```bash
claude plugins install [plugin-name]
# OR
claude mcp add [server-name] -- [command]
```

For CLIs:
```bash
npm install -g [package]  # or pip, cargo, etc.
```

**Step 5: Handle session restart if needed:**

Some MCP installations require a session restart. If so:

```
AskUserQuestion(
  question: "[Tool] is installed but needs a session restart to activate. I'll save our progress so you can resume exactly where we left off.",
  options: [
    "(Recommended) Restart now — I'll save state and you can /stp:continue after /clear",
    "Continue without it — I'll work around it",
    "Chat about this"
  ]
)
```

If restart needed:
1. Save current progress to `.stp/state/handoff.md` with:
   - What we're developing
   - Requirements gathered (Phase 1)
   - Context found (Phase 2)
   - Tools installed (Phase 3)
   - "Resume from Phase 4: Research"
2. Tell the user: "Run `/clear` then `/stp:continue`. The new tool will be active and I'll pick up from research."

### Phase 3b: UI/UX DESIGN SYSTEM (when work involves ANY frontend/UI)

If this work touches UI (components, pages, layouts, styling, themes, landing pages, dashboards, forms), this phase is MANDATORY before research and **enforced by `hooks/scripts/ui-gate.sh`** — Write/Edit on any new `*.html`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`, or `*.css` file will be **BLOCKED by the Claude Code PreToolUse hook** until `.stp/state/ui-gate-passed` exists. Markdown "MUST" is a suggestion; the hook is the enforcement. Closes v0.3.1 AI-slop-landing-page failure.

**Check for ui-ux-pro-max (required companion plugin):**
```bash
[ -f ".claude/skills/ui-ux-pro-max/SKILL.md" ] && echo "ui-ux-pro-max: installed" || echo "ui-ux-pro-max: MISSING"
```
If MISSING → install automatically: `npm i -g uipro-cli && uipro init --ai claude`. Do NOT proceed with UI work without it.

**Check for existing design system (glob any nested MASTER.md):**
```bash
# Find ANY design-system/**/MASTER.md — supports nested per-page systems
# like design-system/landing/MASTER.md or design-system/dashboard/MASTER.md
FOUND_MASTER=$(find design-system -maxdepth 4 -name "MASTER.md" -type f 2>/dev/null | head -1)
if [ -n "$FOUND_MASTER" ]; then
  echo "design-system: found at $FOUND_MASTER"
else
  echo "design-system: NONE"
fi
```

Also check whether the user's request explicitly referenced a MASTER.md path (e.g. "using design-system/foo/MASTER.md"). If so, that path is the authoritative design system for this feature — treat it the same as if the find command returned it.

**If a design system exists (either found by find or referenced in the user prompt)** → Read the MASTER.md fully, then proceed to the **design consultation step** below. You still owe the user a summary and approval even when MASTER.md already exists. Reading tokens is not the same as a design consultation.

**If NO design system exists** → Generate one:

1. **Start the whiteboard server FIRST** — BEFORE generating anything. The user should have the URL open before any data arrives, so they watch the design system populate live instead of opening an empty page. Do NOT ask permission; this is mandatory whenever design generation is triggered:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```
Then print the LOUD unmissable banner via the Bash tool — this MUST be the last thing on screen before the design system generates:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/whiteboard-banner.sh" "Design system will populate in a few seconds."
```

2. Run ui-ux-pro-max to generate recommendations:
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system -p "<Project Name>"
```

3. Write the design preview to `.stp/whiteboard-data.json` as a `designSystem` section (see whiteboard.md for the full JSON format). The server polls every 2 seconds — the preview will render in the browser within moments of the write.

**Design consultation (REQUIRED even when MASTER.md already exists):**

Before any UI Write can succeed, state — in one message to the user — the following:
1. Which MASTER.md you're following (full path)
2. The layout pattern you plan to use (e.g. "Minimal Single Column", "Swiss asymmetric grid", "Bento")
3. The color + typography direction in one sentence
4. A one-line anti-slop commitment: explicitly name the AI-slop tells you will NOT use (gradient text on headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand marks, template copy like "without the X headache", center-everything layouts)

Then **STOP and wait for the user to review**. Do NOT continue until the user has approved.

```
AskUserQuestion(
  question: "Design direction for [feature]: following [MASTER.md path], [layout pattern], [color/type direction]. Anti-slop commitments: no gradient headlines, no beta pills, no boxed benefit cards, no sparkles logo, no template copy, no center-everything. Approve?",
  options: [
    "(Recommended) Approve — proceed with this direction",
    "Close — adjust [describe what to change]",
    "Try a different direction",
    "Chat about this"
  ]
)
```

If changes requested → regenerate, update whiteboard-data.json, re-present, ask again. Iterate until approved.

**After approval, persist + release the UI gate:**
```bash
# Persist the generated design system to disk (if one was generated)
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "<Project Name>"
# Release the UI gate — this unblocks hooks/scripts/ui-gate.sh for the session
mkdir -p .stp/state && touch .stp/state/ui-gate-passed
```

The marker is wiped automatically on `/clear` (via the SessionStart hook), so the next fresh session re-confirms design direction. `hooks/scripts/anti-slop-scan.sh` continues to monitor the actual written output even after the gate is released — any two high-confidence slop tells (gradient headline + template copy, etc.) will block the PostToolUse stage.

This creates or updates `design-system/MASTER.md` which Phase 6 (Execute) reads before writing any frontend code.

**If the work is NOT UI-related, skip this phase entirely.** The ui-gate hook only triggers on UI file types, so non-UI work is never blocked.


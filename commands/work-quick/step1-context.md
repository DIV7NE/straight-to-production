### Step 1: Context

Read .stp/docs/PLAN.md for this feature's requirements, test cases, and dependencies. Read CLAUDE.md for stack patterns AND the `## Project Conventions` section — these are the project-specific rules that MUST be followed. Every convention was earned through a decision or a bug. Violating them means repeating history.

**Read .stp/docs/PRD.md `## System Constraints` — MANDATORY enforcement gate.** Every constraint in this section is a SHALL/MUST rule the system must follow forever. They were added by previous features and bug fixes via delta merge-back. Examples: "system MUST scope all multi-tenant queries by `organizationId`", "uploads MUST validate MIME type server-side". Before writing any code, list every constraint that applies to this feature's surface area. Each one becomes a non-negotiable check during build AND a verification point during QA. If a constraint conflicts with the new feature, surface it to the user with `AskUserQuestion` — do not silently violate it. Constraints are how STP prevents repeating past bugs.

If .stp/docs/PLAN.md exists and this feature is listed, use the plan's test cases and dependencies. If .stp/docs/PLAN.md doesn't exist or this feature isn't in it, create the plan inline (but recommend running `/stp:plan` first for complex projects).

**Check for existing design brief (from /stp:whiteboard):**
```bash
[ -f ".stp/state/design-brief.md" ] && echo "design_brief: exists" || echo "design_brief: none"
```
If a design brief exists: read it — the user already brainstormed the problem, decision, structured requirements, and scope. Use the brief's requirements as context and skip directly to Step 2 (Research). Tell the user: "Found a design brief from `/stp:whiteboard` — using its requirements and jumping to research."

If `.stp/state/current-feature.md` already exists, check if it was created by `/stp:research`:

**If it has research findings + approach + build order (from /stp:research):**
The plan is already done — research, approaches, architecture fit, impact analysis are complete. Skip straight to Step 5 (Build). Tell the user: "Found a plan from /stp:research — picking up where the discussion left off."

**If it's a feature in progress (has [x] checked items):**
```
AskUserQuestion(
  question: "There's an active feature in progress: [name] ([done]/[total] items). What do you want to do?",
  options: [
    "(Recommended) Finish [existing feature] first — picking up is faster than context-switching",
    "Abandon it, start [new feature] — mark old one incomplete",
    "Chat about this"
  ]
)
```

### Step 1b: UI/UX Design System (when building ANY frontend/UI work)

If this feature touches UI (components, pages, layouts, styling, themes, landing pages, dashboards, forms), this step is MANDATORY and **enforced by `hooks/scripts/ui-gate.sh`** — Write/Edit on any new `*.html`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`, or `*.css` file will be **BLOCKED by the Claude Code PreToolUse hook** until `.stp/state/ui-gate-passed` exists. Markdown "MUST" is a suggestion; the hook is the enforcement. Closes v0.3.1 AI-slop-landing-page failure.

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
[ -f ".stp/whiteboard-data.json" ] && grep -q "designSystem" .stp/whiteboard-data.json 2>/dev/null && echo "whiteboard-preview: exists" || echo "whiteboard-preview: NONE"
```

Also check whether the user's request explicitly referenced a MASTER.md path (e.g. "using design-system/foo/MASTER.md"). If so, that path is the authoritative design system for this feature — treat it the same as if the find command returned it.

**If a design system exists (either found by find or referenced in the user prompt)** → Read the MASTER.md fully, then proceed to the **design-consultation step** below. You still owe the user a summary and approval even when MASTER.md already exists. Reading tokens is not the same as a design consultation.

**If NO design system exists** → Generate one BEFORE writing any frontend code.

**First, start the whiteboard server** — BEFORE generating anything. The user should have the URL open before any data arrives. Do NOT ask permission; this is mandatory whenever design generation runs:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/start-whiteboard.sh" "${CLAUDE_PLUGIN_ROOT}" "." &
```
Then print the LOUD unmissable banner via the Bash tool — this MUST be the last thing on screen before the design system generates:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/whiteboard-banner.sh" "Design system will populate in a few seconds."
```

**Then generate the design system:**
```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system --persist -p "<Project Name>"
```

**Then write the design preview section to `.stp/whiteboard-data.json`** (see whiteboard.md for the JSON format). The server polls every 2 seconds — the preview will render in the browser within moments of the write.

**Design consultation (REQUIRED even when MASTER.md already exists):**

Before any UI Write can succeed, you must state — in one message to the user — the following:
1. Which MASTER.md you're following (full path)
2. The layout pattern you plan to use (e.g. "Minimal Single Column", "Swiss asymmetric grid", "Bento")
3. The color + typography direction in one sentence
4. A one-line anti-slop commitment: explicitly name the AI-slop tells you will NOT use (gradient text on headlines, "Now in public beta" eyebrow pills, 3 boxed benefit cards, sparkles brand marks, template copy like "without the X headache", center-everything layouts)

Then **STOP and wait for the user to review**. Do NOT continue until approved.

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

If changes requested → revise, re-present, ask again. Iterate until approved.

**On approval, release the UI gate** (this is what unblocks `hooks/scripts/ui-gate.sh` for the session):
```bash
mkdir -p .stp/state && touch .stp/state/ui-gate-passed
```
The marker is wiped automatically on `/clear` (via the SessionStart hook), so the next fresh session re-confirms design direction. `hooks/scripts/anti-slop-scan.sh` continues to monitor the actual written output even after the gate is released — any two high-confidence slop tells (gradient headline + template copy, etc.) will block the PostToolUse stage.

**If the feature is NOT UI-related, skip this step entirely.** The ui-gate hook only triggers on UI file types, so non-UI work is never blocked.


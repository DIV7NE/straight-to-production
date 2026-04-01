---
description: Mark a project milestone — evaluate current state, document what's done and what's next, create a checkpoint commit. Use when you've completed a significant chunk of work and want to take stock before continuing.
argument-hint: Optional milestone name (e.g., "MVP complete" or "auth and dashboard done")
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Agent"]
---

# Pilot: Milestone

Create a project checkpoint. This is NOT project management — it's a pause to evaluate, document, and plan the next push.

## Process

### Step 1: Evaluate Current State

Run the Critic to get a quality snapshot:
- Dispatch the `pilot-critic` agent to evaluate the project
- This gives you the 6-criteria grade (functionality, design, security, accessibility, performance, production-readiness)

### Step 2: Document What's Done

Read the CLAUDE.md project spec and compare against what actually exists in the codebase.

Create or update `.pilot/MILESTONES.md` with:

```markdown
## [Date] — [Milestone Name or "Checkpoint"]

### Completed
- [Feature/component 1 — brief status]
- [Feature/component 2 — brief status]

### Quality Snapshot
- Functionality: [PASS/PARTIAL/FAIL]
- Design: [PASS/PARTIAL/FAIL]
- Security: [PASS/PARTIAL/FAIL]
- Accessibility: [PASS/PARTIAL/FAIL]
- Performance: [PASS/PARTIAL/FAIL]
- Production: [PASS/PARTIAL/FAIL]

### Outstanding Issues
- [Issue 1 from critic report]
- [Issue 2 from critic report]

### Next Up
- [What to build next based on the original spec]
- [What to fix from the critic report]
```

### Step 3: Commit the Checkpoint

```bash
git add -A
git commit -m "milestone: [milestone name]"
```

### Step 4: Report to Developer

Summarize in 5 lines:
1. What's done (count of features/pages)
2. Overall quality grade
3. Top 3 issues to address
4. What's next to build
5. Estimated remaining scope (small/medium/large based on spec vs done)

### Step 5: Continue or Pause

Ask: "Want to tackle the next feature, fix the issues from the report, or call it for today?"

- If next feature → **recommend /clear first**, then `/pilot:feature [next thing]` in the fresh session. A fresh context with sharp attention beats continuing in a bloated one.
- If fix issues → work through the critic's priority list in the current session (fixes are focused, context is still relevant)
- If pause → commit everything and note they can resume anytime. SessionStart hook will restore context.

After completing a milestone is the BEST time to /clear. All state is on disk (MILESTONES.md, CLAUDE.md, git). Starting the next feature fresh gives you full context budget and zero accumulated noise.

## Gotchas
- This is a CHECKPOINT, not a ceremony. Keep it under 5 minutes.
- The MILESTONES.md file is append-only — never edit previous entries, just add new ones.
- Don't create milestones for trivial work. This is for "I finished the auth system" not "I added a button."
- If the Critic finds critical security issues, surface those FIRST regardless of what else is done.
- ALWAYS recommend /clear after a milestone. The next feature deserves a clean context.
- ALWAYS end with an explicit next step block with specific command to run.

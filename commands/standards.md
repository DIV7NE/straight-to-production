---
description: Show what Pilot standards are currently enforced in this project and why. Use when you want to understand what quality gates are active.
argument-hint: Optional filter (e.g., "security" or "accessibility")
allowed-tools: ["Read", "Glob", "Grep"]
---

# Pilot: Standards Overview

Show the developer what standards Pilot is enforcing in their project.

## Process

1. Check if `.pilot/references/` exists in the current project
   - If not: "No Pilot standards installed. Run `/pilot:new` to set up your project."

2. List all reference files found in `.pilot/references/` grouped by domain

3. For each domain, show:
   - What's enforced (brief summary from each file's first heading)
   - Why it matters (one sentence)
   - How it's enforced (CLAUDE.md index → retrieval-led reasoning → hooks catch violations)

4. Show active hooks:
   - PostToolUse: TypeScript check after every .ts/.tsx edit
   - Stop: Verification prompt before claiming completion
   - PreCompact: State save before context compaction

5. If $ARGUMENTS specifies a domain (e.g., "security"), read and display that domain's reference files in full.

Keep the overview concise — one line per standard. Only expand when the user asks for a specific domain.

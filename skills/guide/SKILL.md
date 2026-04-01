---
name: pilot-guide
description: This skill should be used when the user says "start a new project", "build me an app", "I want to create", "new project", "build a SaaS", "build a webapp", "create an app", "I have an idea for", or describes an app idea they want to build from scratch. Surfaces what the developer doesn't know they need and generates a standards-enforced CLAUDE.md.
---

# Pilot Guide

When this skill triggers, redirect to the `/pilot:new` command which contains the full Guide workflow.

Tell the user: "I'll use Pilot to set up this project properly. Running `/pilot:new`..."

Then invoke the `/pilot:new` command with the user's description as the argument.

This skill exists as an auto-trigger fallback. The preferred invocation is `/pilot:new` directly.

## Gotchas

- This skill only triggers on NEW project descriptions. If the user is asking about an EXISTING project, do NOT trigger this skill. Look for signals like "in this codebase", "fix this bug", "add a feature to" — those are existing project work.
- If the user provides only a vague idea ("something with AI"), still trigger but the Guide will ask clarifying questions. Don't wait for a perfect description.
- If `.pilot/references/` already exists in the current directory, the project was already set up with Pilot. Don't re-run setup — instead say "This project already has Pilot standards. Just start describing what you want to build."
- If CLAUDE.md already exists, the Guide should ADD the standards index to it, not overwrite the whole file.

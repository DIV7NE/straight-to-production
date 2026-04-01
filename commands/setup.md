---
description: Add Pilot standards to an existing project. Copies universal reference files and suggests adding the standards index to your CLAUDE.md. Use when you want Pilot quality enforcement without running /pilot:new.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read", "Write", "Glob"]
---

# Pilot: Setup

Add Pilot's reference files and hook enforcement to an existing project.

## Process

1. Detect the stack from project files (tsconfig.json, pyproject.toml, Cargo.toml, etc.)

2. Run the setup script:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

3. Confirm what was copied:
```bash
find .pilot/references -name "*.md" | wc -l
```

4. Check if CLAUDE.md has a standards index. If not, read `${CLAUDE_PLUGIN_ROOT}/templates/_standards-index.md` and suggest adding it to the existing CLAUDE.md.

5. Tell the user:
   - Reference files in `.pilot/references/` (security, accessibility, performance, production)
   - Hooks active: type checking after edits, quality gate before completion
   - Run `/pilot:standards` or read CLAUDE.md to see what's enforced
   - For the full guided setup with architecture proposal: `/pilot:new`

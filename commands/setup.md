---
description: Copy Pilot reference files into the current project. Run this if you want Pilot standards in an existing project without running /pilot:new.
argument-hint: No arguments needed
allowed-tools: ["Bash", "Read", "Write"]
---

# Pilot: Setup References

Copy Pilot's reference files into the current project for retrieval-led reasoning.

## Process

1. Run the setup script:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/setup-references.sh" "${CLAUDE_PLUGIN_ROOT}" "."
```

2. Confirm what was copied:
```bash
find .pilot/references -name "*.md" | wc -l
```

3. Tell the user:
- Reference files are now in `.pilot/references/`
- The standards index in CLAUDE.md will point to these files
- Run `/pilot:standards` to see what's enforced
- These files are gitignored by default (Pilot manages them)

If the project doesn't have a CLAUDE.md with the standards index yet, suggest running `/pilot:new` for the full setup, or manually add the standards index from `${CLAUDE_PLUGIN_ROOT}/templates/standards-index.md` to the existing CLAUDE.md.

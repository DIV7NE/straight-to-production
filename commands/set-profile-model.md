---
description: Switch STP optimization profile. Controls which Claude model runs each sub-agent. Pass profile name as argument or invoke bare to see all profiles.
argument-hint: <intended | balanced | budget | sonnet-main>  (or no arg to see profiles)
allowed-tools: ["Bash", "AskUserQuestion"]
model: haiku
---

# STP: Set Profile

**If `$ARGUMENTS` is not empty:** set it directly, show output:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set "$ARGUMENTS" --raw
```
Then print: `► Active for all /stp:* commands. /clear, then continue.`

**If `$ARGUMENTS` is empty:** first show all profiles with `all-tables`, then show the picker below.

```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" all-tables
```

Then display a brief "when to use each" guide via echo:
```bash
echo -e "\n\033[1mWhen to use each:\033[0m"
echo -e "  \033[36mbalanced\033[0m (default) — Best cost/quality ratio. Opus plans, Sonnet builds. Good for all standard work."
echo -e "  \033[36mintended\033[0m — Opus does everything inline. Maximum quality, highest cost. For critical production work."
echo -e "  \033[38;5;208mbudget\033[0m   — Cheapest. Haiku critic + Sonnet escalation. For prototyping or tight budgets."
echo -e "  \033[35msonnet-main\033[0m — No Opus needed. Sonnet 200K main session. For users without Opus access.\n"
```

Then present the picker:
```
AskUserQuestion(
  question: "Which profile? Current: [read from `current` command above]",
  header: "Profile",
  options: [
    { label: "balanced-profile (Recommended)", description: "Opus plans + Sonnet subagents. ~50% savings. Best for most work." },
    { label: "intended-profile", description: "Opus inline research/exploration. Highest quality, highest cost." },
    { label: "budget-profile", description: "Haiku critic + Sonnet escalation. ~80% savings. Strict context discipline." },
    { label: "sonnet-main", description: "Sonnet 200K primary, Haiku QA/critic. ~85% savings. No Opus needed." }
  ]
)
```

After pick:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <picked> --raw
```
Print: `► Active for all /stp:* commands. /clear, then continue.`

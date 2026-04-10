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

**If `$ARGUMENTS` is empty:** show the full profile comparison, then the picker.

**Step 1:** Show the agent-model tables:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" all-tables
```

**Step 2:** Show the comparison guide via echo:
```bash
echo -e "\n\033[1;36m╔════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║\033[0m  \033[1mProfile Comparison — Quality, Cost & Tradeoffs\033[0m                       \033[1;36m║\033[0m"
echo -e "\033[1;36m╠════════════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[1;36m● balanced\033[0m (DEFAULT) — Best cost/quality ratio                       \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Opus plans, Sonnet builds/researches/explores via subagents          \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Quality: \033[32m~95%\033[0m  Cost: \033[32m~35-50%\033[0m  Est: \033[1m\$0.65-0.95/feature\033[0m              \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Tradeoff: research summarized to 30 lines (rare nuance loss)         \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Best for: \033[1mall standard work\033[0m — features, fixes, refactors              \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[36m● intended\033[0m — Maximum quality, highest cost                            \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Opus does research + exploration inline (no delegation)              \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Quality: \033[32m100%\033[0m  Cost: \033[31m100%\033[0m  Est: \033[1m\$1.50-2.10/feature\033[0m               \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Tradeoff: Opus reads every doc/grep at \$15/MTok                     \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Best for: \033[1mcritical production work\033[0m where budget doesn't matter       \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[38;5;208m● budget\033[0m — Cheapest with Opus main                                   \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Haiku critic (auto-escalates to Sonnet on ≥2 critical issues)       \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Quality: \033[33m~85-90%\033[0m  Cost: \033[32m~20%\033[0m  Est: \033[1m\$0.30-0.45/feature\033[0m            \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Tradeoff: weaker architectural feedback, more false positives        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Best for: \033[1mprototyping, learning STP, tight budgets\033[0m                   \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[35m● sonnet-main\033[0m — No Opus needed at all                                 \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Sonnet 200K main session, Haiku QA + critic                         \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Quality: \033[33m~80-85%\033[0m  Cost: \033[32m~15%\033[0m  Est: \033[1m\$0.20-0.35/feature\033[0m            \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Tradeoff: less creative architecture, 80K context cap                \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m    Best for: \033[1musers without Opus access\033[0m, simple features               \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[2mQuality gap is smaller than it looks — Layers 1-4 of STP's\033[0m           \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[2mverification stack are deterministic and don't depend on model.\033[0m      \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m  \033[2mOnly the Critic (Layer 5) degrades across profiles.\033[0m                  \033[1;36m║\033[0m"
echo -e "\033[1;36m║\033[0m                                                                        \033[1;36m║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════════════════════════╝\033[0m\n"
```

**Step 3:** Read current profile and present the picker:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" current
```

```
AskUserQuestion(
  question: "Which profile? Current: [result from above]",
  header: "Profile",
  options: [
    { label: "balanced-profile (Recommended)", description: "Opus plans + Sonnet subagents. ~95% quality, ~50% cost. Best for all standard work." },
    { label: "intended-profile", description: "Opus inline research/exploration. 100% quality, 100% cost. For critical production." },
    { label: "budget-profile", description: "Haiku critic + Sonnet escalation. ~85-90% quality, ~20% cost. Prototyping/tight budget." },
    { label: "sonnet-main", description: "Sonnet 200K primary, no Opus. ~80-85% quality, ~15% cost. No Opus access needed." }
  ]
)
```

After pick:
```bash
node "${CLAUDE_PLUGIN_ROOT}/references/model-profiles.cjs" set <picked> --raw
```
Print: `► Active for all /stp:* commands. /clear, then continue.`

#!/bin/bash
# STP v0.3.2: AI-slop pattern scanner
# PostToolUse hook for Write|Edit|MultiEdit.
#
# Purpose: after Claude writes a UI file, grep for the well-known signatures
# of LLM-generated landing-page slop and feed findings back so Claude rewrites
# them. Deterministic (no LLM cost), shell-only, runs in <100ms.
#
# Block semantics:
#   - HIGH confidence slop (2+ tells present) → EXIT 2 (Claude must fix)
#   - LOW  confidence slop (1 tell present)   → EXIT 0 with stderr warning
#
# Why it's bash not prompt: free, fast, reliable, portable. A prompt hook
# using Haiku can be added later for semantic cases the grep patterns miss.
#
# Pattern catalog (from v0.3.1 landing page post-mortem + AI-slop research):
#   1. Gradient text on headlines (#1 LLM signature)
#   2. "Now in public beta" eyebrow pills
#   3. 3-boxed-benefit-card layout
#   4. Sparkles SVG brand mark
#   5. Template copy ("without the X headache", "built for modern teams")
#   6. "Ship X in (minutes|hours|days)" hero promises
#   7. Center-everything default (text-align:center on body/main/hero)
#
# Exit 0 carve-outs:
#   - Not inside an STP project
#   - File isn't HTML/JSX/TSX/Vue/Svelte/Astro
#   - STP_BYPASS_SLOP_SCAN=1 in the environment

# HOME bypass
if [ "$PWD" = "$HOME" ]; then exit 0; fi
# Only run inside STP projects
if [ ! -d ".stp" ]; then exit 0; fi
# Env escape hatch
if [ "${STP_BYPASS_SLOP_SCAN:-}" = "1" ]; then exit 0; fi

# Stack-awareness: skip if stack has no UI (CLI tools, daemons, cheats, libraries)
if [ -f ".stp/state/stack.json" ] && command -v jq >/dev/null 2>&1; then
  STACK_UI=$(jq -r '.ui // "false"' .stp/state/stack.json 2>/dev/null)
  if [ "$STACK_UI" = "false" ]; then exit 0; fi
fi

# Read stdin JSON
if [ -t 0 ]; then exit 0; fi
INPUT=$(cat)

# Extract file_path
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${TOOL_INPUT_file_path:-${TOOL_INPUT_FILE_PATH:-}}"
fi
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then exit 0; fi

# Only scan UI markup files
UI_REGEX='\.(html|htm|tsx|jsx|vue|svelte|astro)$'
if ! [[ "$FILE_PATH" =~ $UI_REGEX ]]; then exit 0; fi

# Skip tests, stories, configs
if [[ "$FILE_PATH" =~ \.(test|spec|stories|story)\. ]] || \
   [[ "$FILE_PATH" =~ /(test|tests|__tests__|stories|__stories__|fixtures|__mocks__)/ ]]; then
  exit 0
fi

FINDINGS=()
HIT_COUNT=0

# ── Pattern 1: Gradient text on headlines ────────────────────────
# linear-gradient + background-clip:text is THE #1 LLM landing page signature.
# We grep for the combo within close proximity.
if grep -qiE 'background-clip:\s*text|-webkit-background-clip:\s*text' "$FILE_PATH" 2>/dev/null && \
   grep -qiE 'linear-gradient' "$FILE_PATH" 2>/dev/null; then
  LINE=$(grep -niE 'background-clip:\s*text' "$FILE_PATH" | head -1 | cut -d: -f1)
  FINDINGS+=("  [slop] gradient text on headline (line ~$LINE) — linear-gradient + background-clip:text is the #1 LLM tell. Use solid color + tonal opacity for contrast instead.")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 2: "Now in beta" eyebrow pills ───────────────────────
if grep -qiE 'now in (public |private )?(beta|early access|preview)|currently in beta|public beta|early access' "$FILE_PATH" 2>/dev/null; then
  LINE=$(grep -niE 'now in (public |private )?(beta|early access|preview)' "$FILE_PATH" | head -1 | cut -d: -f1)
  FINDINGS+=("  [slop] 'Now in beta' eyebrow pill (line ~$LINE) — generic SaaS template cliché. Replace with concrete copy or remove entirely.")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 3: Template hero copy ────────────────────────────────
# "without the X headache" / "built for modern teams" / "ship X in minutes"
if grep -qiE 'without the [a-z -]{3,25} headache|built for (the )?modern (teams?|developers?|founders?|startups?|businesses?)|designed for (teams?|developers?|founders?|makers?)|the easiest way to' "$FILE_PATH" 2>/dev/null; then
  MATCH=$(grep -niE 'without the [a-z -]{3,25} headache|built for (the )?modern|designed for (teams?|developers?|founders?)|the easiest way to' "$FILE_PATH" | head -1)
  FINDINGS+=("  [slop] template hero copy — '$MATCH'. Be specific: what does the product actually do, in the user's words?")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 4: "Ship in minutes/hours/days" speed promises ───────
if grep -qiE 'ship (your |it )?[a-z ]{0,30}in (minutes|seconds|hours|days)|launch in (minutes|seconds|hours|days)|(up and running|get started|go live) in (minutes|seconds|under)|in just (minutes|seconds|a few clicks)' "$FILE_PATH" 2>/dev/null; then
  LINE=$(grep -niE 'ship.*in (minutes|seconds|hours)|launch in (minutes|seconds)|in just (minutes|seconds)' "$FILE_PATH" | head -1 | cut -d: -f1)
  FINDINGS+=("  [slop] 'ship in minutes' hero promise (line ~$LINE) — overused SaaS template copy. Prefer concrete outcome ('query Postgres in 4 steps' > 'ship in minutes').")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 5: Sparkles/star brand mark SVG ──────────────────────
# Lucide "sparkles" path. The exact d attribute varies but contains M9.94 14.34.
if grep -qE 'M9\.94 14\.34 12 20|sparkles|Sparkles' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("  [slop] sparkles/star SVG used as brand mark — generic AI-starter-kit logo. Prefer a wordmark or a custom shape derived from the product.")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 6: Center-everything default ─────────────────────────
# text-align: center on body, main, or .hero is a centering-everything tell.
if grep -qiE '(body|main|\.hero|\.container|\.wrapper)\s*\{[^}]*text-align:\s*center' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("  [slop] text-align:center on body/main/hero — AI default is center-everything. Consider left-aligned hero for Swiss/asymmetric layouts.")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Pattern 7: 3 identical benefit cards ─────────────────────────
# Hard to detect perfectly with grep, but: a common shape is 3+ instances of
# a structure like <div class="...card..."><svg>...</svg><h3>...</h3><p>
# NB: `grep -c PATTERN FILE 2>/dev/null || echo 0` is BROKEN — grep prints
# "0" before exiting non-zero on no-match, so the `||` fallback APPENDS
# rather than replacing, producing the literal "0\n0" string. The next
# integer comparison errors with `integer expression expected` and the
# whole detection silently misfires. Fixed in v0.3.7 across all hook scripts.
CARD_COUNT=$(grep -cE 'class="[^"]*(card|benefit|feature)[^"]*"' "$FILE_PATH" 2>/dev/null); CARD_COUNT=${CARD_COUNT:-0}
SVG_ICON_COUNT=$(grep -cE '<svg[^>]*width="(16|20|22|24|44|48)"' "$FILE_PATH" 2>/dev/null); SVG_ICON_COUNT=${SVG_ICON_COUNT:-0}
if [ "$CARD_COUNT" -ge 3 ] && [ "$SVG_ICON_COUNT" -ge 3 ]; then
  FINDINGS+=("  [slop] 3+ boxed benefit cards with icons — most predictable AI landing page layout. Try numbered rows with hairline separators or an asymmetric grid.")
  HIT_COUNT=$((HIT_COUNT + 1))
fi

# ── Report ───────────────────────────────────────────────────────
if [ "$HIT_COUNT" -eq 0 ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

if [ "$HIT_COUNT" -ge 2 ]; then
  # HIGH confidence — block until fixed
  {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║ STP ANTI-SLOP BLOCK — $HIT_COUNT findings in $BASENAME"
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    for finding in "${FINDINGS[@]}"; do
      echo "║"
      echo "$finding" | fold -s -w 68 | sed 's/^/║ /'
    done
    echo "║"
    echo "║ Two or more AI-slop signatures present. Rewrite the affected        ║"
    echo "║ sections before continuing. If any finding is a false positive,    ║"
    echo "║ explain why in your next message and set                            ║"
    echo "║ STP_BYPASS_SLOP_SCAN=1 to override for this session.                ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
  } >&2
  exit 2
else
  # LOW confidence — warn, don't block
  {
    echo ""
    echo "⚠ STP slop scan — 1 finding in $BASENAME:"
    for finding in "${FINDINGS[@]}"; do
      echo "$finding"
    done
    echo "  (warning only — not blocking. Consider revising if it's a landing page.)"
    echo ""
  } >&2
  exit 0
fi

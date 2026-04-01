#!/bin/bash
# Pilot: Autonomous loop (Ralph Wiggum pattern + Pilot verification)
#
# Core loop is Ralph Wiggum — we don't pretend otherwise.
# What Pilot adds: enriched specs (from /pilot:feature) and
# real verification (critic-checks.sh + tsc + lint, not self-reported checklist).
#
# Usage: bash pilot-auto.sh [max_iterations]

MAX_ITERATIONS=${1:-30}
ITERATION=0
FEATURE_FILE=".pilot/current-feature.md"
CHECKS_SCRIPT=".pilot/scripts/critic-checks.sh"

# Verify prerequisites
if [ ! -f "CLAUDE.md" ]; then
  echo "Error: No CLAUDE.md found. Run /pilot:new first."
  exit 1
fi

if [ ! -f "$FEATURE_FILE" ]; then
  echo "Error: No .pilot/current-feature.md found. Run /pilot:feature first."
  exit 1
fi

FEATURE_TITLE=$(head -1 "$FEATURE_FILE" | sed 's/^#* *//')
echo "=== Pilot Auto Mode ==="
echo "Feature: $FEATURE_TITLE"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))

  # Count remaining items
  UNCHECKED=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

  if [ "$UNCHECKED" -eq 0 ]; then
    echo ""
    echo "=== CHECKLIST COMPLETE ($CHECKED items) ==="
    echo "Running verification..."

    # REAL verification — not self-reported
    VERIFY_PASS=true

    # 1. TypeScript check
    if [ -f "tsconfig.json" ]; then
      echo "--- TypeScript check ---"
      TS_ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep -c "error TS" || echo "0")
      if [ "$TS_ERRORS" -gt 0 ]; then
        echo "FAIL: $TS_ERRORS TypeScript errors"
        VERIFY_PASS=false
      else
        echo "PASS: zero type errors"
      fi
    fi

    # 2. Lint check
    if [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
      echo "--- Lint check ---"
      if npm run lint --silent 2>&1 | tail -3; then
        echo "PASS: lint clean"
      else
        echo "FAIL: lint errors"
        VERIFY_PASS=false
      fi
    fi

    # 3. Build check
    if [ -f "package.json" ] && grep -q '"build"' package.json 2>/dev/null; then
      echo "--- Build check ---"
      if npm run build --silent 2>&1 | tail -5; then
        echo "PASS: build succeeds"
      else
        echo "FAIL: build broken"
        VERIFY_PASS=false
      fi
    fi

    # 4. Test check
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
      echo "--- Test check ---"
      if npm test --silent 2>&1 | tail -5; then
        echo "PASS: tests pass"
      else
        echo "FAIL: tests failing"
        VERIFY_PASS=false
      fi
    fi

    if [ "$VERIFY_PASS" = true ]; then
      echo ""
      echo "=== ALL VERIFICATION PASSED ==="
      echo "Running Critic evaluation..."

      # Run the full 6-criteria evaluation
      claude -p "Run /pilot:evaluate on this project. Read CLAUDE.md for context. Be ruthlessly strict." 2>&1 | tee .pilot/auto-eval-report.txt

      echo ""
      echo "=== PILOT AUTO COMPLETE ==="
      echo "Feature: $FEATURE_TITLE"
      echo "Items completed: $CHECKED"
      echo "Iterations used: $ITERATION"
      echo "Evaluation: .pilot/auto-eval-report.txt"
      exit 0
    else
      echo ""
      echo "Verification FAILED. Sending back to Claude to fix..."
      # Don't count this as a "stuck" — it's a fix iteration
    fi
  fi

  # Get next task (or fix verification failures)
  NEXT_TASK=$(grep -m1 '\[ \]' "$FEATURE_FILE" 2>/dev/null | sed 's/^[[:space:]]*- \[ \] //')

  if [ -z "$NEXT_TASK" ] && [ "$VERIFY_PASS" = false ]; then
    NEXT_TASK="Fix the verification failures: run npx tsc --noEmit, npm run lint, npm run build, npm test — fix all errors"
  fi

  echo "--- Iteration $ITERATION/$MAX_ITERATIONS ($CHECKED done, $UNCHECKED remaining) ---"
  echo "Task: ${NEXT_TASK:-fix verification failures}"

  # Fresh Claude context each iteration
  OUTPUT=$(claude -p "
You are working on: $FEATURE_TITLE
Read CLAUDE.md for project context and standards.
Read .pilot/current-feature.md for the checklist.

YOUR TASK:
${NEXT_TASK:-Fix all TypeScript, lint, and build errors. Run npx tsc --noEmit and fix every error.}

RULES:
1. Do ONE task only. Do not skip ahead.
2. After implementing, run: npx tsc --noEmit
3. Fix any type errors before committing.
4. Update .pilot/current-feature.md — mark completed item [x]
5. Commit: git add -A && git commit -m 'feat: [description]'
6. If stuck after 3 attempts, add a note to .pilot/current-feature.md and move on.
" 2>&1)

  echo "$OUTPUT" | tail -15
  echo ""

  # Real verification after each iteration (not trusting Claude's self-report)
  if [ -f "tsconfig.json" ]; then
    POST_ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep -c "error TS" || echo "0")
    if [ "$POST_ERRORS" -gt 0 ]; then
      echo "[Pilot] WARNING: $POST_ERRORS TypeScript errors after this iteration."
    fi
  fi

  sleep 3
done

echo ""
echo "=== ITERATION LIMIT REACHED ==="
echo "Completed: $CHECKED items. Remaining: $UNCHECKED."
echo "Run again to continue, or work manually."
exit 1

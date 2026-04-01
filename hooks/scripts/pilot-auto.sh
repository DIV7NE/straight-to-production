#!/bin/bash
# Pilot v0.2.0: Autonomous loop
# Each checklist item runs in a fresh claude -p session.
# Stack-aware verification after each iteration.
# Usage: bash pilot-auto.sh [max_iterations]

MAX_ITERATIONS=${1:-30}
ITERATION=0
FEATURE_FILE=".pilot/current-feature.md"

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

# Stack detection for verification (must match stop-verify.sh coverage)
detect_type_check() {
  if [ -f "tsconfig.json" ]; then
    echo "npx tsc --noEmit --pretty false"
  elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    if command -v mypy &>/dev/null; then echo "mypy ."; else echo "python3 -m py_compile"; fi
  elif [ -f "Cargo.toml" ]; then
    echo "cargo check"
  elif [ -f "go.mod" ]; then
    echo "go vet ./..."
  elif ls *.csproj &>/dev/null 2>&1 || ls *.sln &>/dev/null 2>&1; then
    echo "dotnet build --no-restore --verbosity quiet"
  elif [ -f "Gemfile" ]; then
    echo "ruby -c"
  elif [ -f "composer.json" ]; then
    echo "php -l"
  elif [ -f "pom.xml" ]; then
    echo "mvn compile -q"
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "gradle compileJava -q"
  else
    echo ""
  fi
}

TYPE_CMD=$(detect_type_check)
VERIFY_PASS=true

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))

  UNCHECKED=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

  if [ "$UNCHECKED" -eq 0 ]; then
    echo ""
    echo "=== CHECKLIST COMPLETE ($CHECKED items) ==="
    echo "Running verification..."

    VERIFY_PASS=true

    if [ -n "$TYPE_CMD" ]; then
      echo "--- Type/compile check ---"
      # Use precise error detection matching stop-verify.sh patterns
      TYPE_OUTPUT=$($TYPE_CMD 2>&1)
      TYPE_ERRORS=$(echo "$TYPE_OUTPUT" | grep -c -E "^error|error TS|error:|error\[" || echo "0")
      if [ "$TYPE_ERRORS" -gt 0 ]; then
        echo "FAIL: type/compile errors"
        VERIFY_PASS=false
      else
        echo "PASS"
      fi
    fi

    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
      if ! grep -q '"test".*"echo.*no test' package.json 2>/dev/null; then
        echo "--- Tests ---"
        if npm test --silent 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
      fi
    elif [ -f "pyproject.toml" ] && command -v pytest &>/dev/null; then
      echo "--- Tests ---"
      if pytest --tb=short -q 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif [ -f "Cargo.toml" ]; then
      echo "--- Tests ---"
      if cargo test --quiet 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif [ -f "go.mod" ]; then
      echo "--- Tests ---"
      if go test ./... 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif ls *.csproj &>/dev/null 2>&1 || ls *.sln &>/dev/null 2>&1; then
      echo "--- Tests ---"
      if dotnet test --no-build --verbosity quiet 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif [ -f "Gemfile" ] && command -v bundle &>/dev/null; then
      echo "--- Tests ---"
      if bundle exec rspec --format progress 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif [ -f "composer.json" ] && [ -f "vendor/bin/phpunit" ]; then
      echo "--- Tests ---"
      if vendor/bin/phpunit 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif [ -f "pom.xml" ] && command -v mvn &>/dev/null; then
      echo "--- Tests ---"
      if mvn test -q 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    elif { [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; } && command -v gradle &>/dev/null; then
      echo "--- Tests ---"
      if gradle test -q 2>&1 | tail -3; then echo "PASS"; else echo "FAIL"; VERIFY_PASS=false; fi
    fi

    if [ "$VERIFY_PASS" = true ]; then
      echo ""
      echo "=== ALL VERIFICATION PASSED ==="
      echo "Running Critic evaluation..."
      claude -p "Run /pilot:evaluate on this project. Read CLAUDE.md for context. Be ruthlessly strict." 2>&1 | tee .pilot/auto-eval-report.txt
      echo ""
      echo "=== PILOT AUTO COMPLETE ==="
      echo "Feature: $FEATURE_TITLE"
      echo "Items completed: $CHECKED"
      echo "Iterations used: $ITERATION"
      echo "Evaluation: .pilot/auto-eval-report.txt"
      exit 0
    else
      echo "Verification FAILED. Sending back to fix..."
    fi
  fi

  NEXT_TASK=$(grep -m1 '\[ \]' "$FEATURE_FILE" 2>/dev/null | sed 's/^[[:space:]]*- \[ \] //')

  if [ -z "$NEXT_TASK" ] && [ "$VERIFY_PASS" = false ]; then
    NEXT_TASK="Fix all type/compile and test errors."
  fi

  echo "--- Iteration $ITERATION/$MAX_ITERATIONS ($CHECKED done, $UNCHECKED remaining) ---"
  echo "Task: ${NEXT_TASK:-fix verification failures}"

  OUTPUT=$(claude -p "
You are working on: $FEATURE_TITLE
Read CLAUDE.md for project context and standards.
Read .pilot/current-feature.md for the checklist.

YOUR TASK:
${NEXT_TASK:-Fix all type, compile, and test errors.}

RULES:
1. Do ONE task only.
2. After implementing, run the type checker for this project.
3. Fix any errors before committing.
4. Update .pilot/current-feature.md — mark completed item [x]
5. Commit: git add -A && git commit -m 'feat: [description]'
6. If stuck after 3 attempts, add a note and move on.
" 2>&1)

  echo "$OUTPUT" | tail -15
  echo ""

  if [ -n "$TYPE_CMD" ]; then
    POST_ERRORS=$($TYPE_CMD 2>&1 | grep -c -E "^error|error TS|error:|error\[" || echo "0")
    if [ "$POST_ERRORS" -gt 0 ]; then
      echo "[Pilot] WARNING: type/compile errors after this iteration."
    fi
  fi

  sleep 3
done

echo ""
echo "=== ITERATION LIMIT REACHED ==="
echo "Completed: $CHECKED items. Remaining: $UNCHECKED."
echo "Run again to continue, or work manually."
exit 1

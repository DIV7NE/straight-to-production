#!/bin/bash
# STP v0.2.0: Stop verification hook
# EXIT CODE 2 = BLOCK (Claude cannot stop, must continue)
# EXIT CODE 0 = ALLOW (Claude can stop)
#
# Stack-aware: detects project type from filesystem.
# 3-attempt max-retry: prevents exit code 2 bricking (GitHub #38422, #24327).
# Retry only counts TECHNICAL gates (1-4), not WORKFLOW gates (5-6).
#
# Gate order: fast checks first (fail fast), slow checks last.
#
# FAST (instant):
#   Gate 1: Unchecked feature items → BLOCK
#   Gate 2: PLAN.md warning → WARN (non-blocking)
#   Gate 3: Test files must exist → BLOCK
#   Gate 4: No hardcoded secrets → BLOCK
#   Gate 5: Placeholder/mock patterns → WARN
#   Gate 6: Hollow test detection → WARN (tautological asserts, assertion-free tests)
# SLOW (seconds):
#   Gate 7: Type/compile errors → BLOCK
#   Gate 8: Test failures → BLOCK (skipped if Gate 7 failed)
#
# Safety valve: after 3 TECHNICAL blocks → ALLOW with warning

# Backward compatible: .stp/ or legacy .pilot/
if [ -d ".stp" ]; then STATE_DIR=".stp"; elif [ -d ".pilot" ]; then STATE_DIR=".pilot"; else STATE_DIR=".stp"; fi
DOCS_DIR="$STATE_DIR/docs"
RUNTIME_DIR="$STATE_DIR/state"
FEATURE_FILE="$RUNTIME_DIR/current-feature.md"
RETRY_FILE="$RUNTIME_DIR/.stop-retry-count"

# ── Pause bypass: if handoff.md was JUST written, allow stop ─────
# /stp:pause writes handoff.md before stopping. TDD red phase may have
# intentionally failing tests. The handoff means the user CHOSE to pause.
if [ -f "$RUNTIME_DIR/handoff.md" ]; then
  HANDOFF_AGE=$(( $(date +%s) - $(stat -c %Y "$RUNTIME_DIR/handoff.md" 2>/dev/null || echo "0") ))
  if [ "$HANDOFF_AGE" -lt 30 ]; then
    # Handoff written in last 30 seconds = /stp:pause in progress, allow stop
    exit 0
  fi
fi

# ── Max-retry guard ──────────────────────────────────────────────
mkdir -p "$RUNTIME_DIR" 2>/dev/null

RETRY_COUNT=0
if [ -f "$RETRY_FILE" ]; then
  RAW=$(cat "$RETRY_FILE" 2>/dev/null || echo "0")
  if [[ "$RAW" =~ ^[0-9]+$ ]]; then
    RETRY_COUNT=$RAW
  fi
fi

if [ "$RETRY_COUNT" -ge 3 ]; then
  echo "WARNING: 3 technical blocks hit. Allowing stop to prevent session bricking." >&2
  echo "Unresolved issues may exist. Run /stp:review to check." >&2
  rm -f "$RETRY_FILE"
  exit 0
fi

HAS_ERRORS=false
HAS_TECHNICAL_ERRORS=false

# ══════════════════════════════════════════════════════════════════
# FAST GATES (instant — run these first)
# ══════════════════════════════════════════════════════════════════

# ── Gate 1: Unchecked feature items ──────────────────────────────
if [ -f "$FEATURE_FILE" ]; then
  UNCHECKED=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

  if [ "$UNCHECKED" -gt 0 ]; then
    NEXT=$(grep -m1 '\[ \]' "$FEATURE_FILE" | sed 's/^[[:space:]]*- \[ \] //')
    echo "BLOCKED: $UNCHECKED items remain ($CHECKED done). Next: $NEXT" >&2
    echo "Continue working. Run /stp:pause if you need to stop." >&2
    HAS_ERRORS=true
    # NOTE: does NOT increment retry counter — this is a workflow gate, not technical
  fi
fi

# ── Gate 2: PLAN.md should exist if building features (warn only) ─
if [ -f "$FEATURE_FILE" ] && [ ! -f "$DOCS_DIR/PLAN.md" ]; then
  echo "WARNING: Building features without PLAN.md. Run /stp:plan for better results." >&2
fi

# ── Gate 3: Tests must EXIST for new code ────────────────────────
if [ -f "$FEATURE_FILE" ]; then
  SRC_FILES=$(find . -type f \( \
    -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o \
    -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.cs" -o \
    -name "*.java" -o -name "*.rb" -o -name "*.php" \
  \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/vendor/*" \
     -not -path "*/target/*" -not -path "*/.next/*" -not -path "*/migrations/*" \
     -not -path "*/dist/*" -not -path "*/build/*" \
     -not -name "*.config.*" -not -name "*.d.ts" -not -name "*.config.ts" \
     -not -name "*.config.js" -not -name "*.config.mjs" -not -name "*.config.cjs" \
  2>/dev/null | head -3)

  if [ -n "$SRC_FILES" ]; then
    TEST_FILES=$(find . -type f \( \
      -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" -o \
      -name "*_test.go" -o -name "*Test.java" -o -name "*_test.rs" -o \
      -name "*Tests.cs" -o -name "*_spec.rb" -o -name "*Test.php" \
    \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/vendor/*" \
       -not -path "*/target/*" 2>/dev/null | head -5)

    if [ -z "$TEST_FILES" ]; then
      echo "BLOCKED: Source files exist but no test files found." >&2
      echo "TDD: write tests before implementation is considered done." >&2
      HAS_ERRORS=true
      HAS_TECHNICAL_ERRORS=true
    fi
  fi
fi

# ── Gate 4: No hardcoded secrets ─────────────────────────────────
SECRETS=$(grep -rn \
  "sk_live_[a-zA-Z0-9]\{20,\}\|sk_test_[a-zA-Z0-9]\{20,\}\|AKIA[0-9A-Z]\{16\}" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.rs" --include="*.go" --include="*.cs" \
  --include="*.java" --include="*.rb" --include="*.php" \
  --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
  --exclude-dir=target --exclude-dir=.next --exclude-dir=dist \
  . 2>/dev/null | \
  grep -v "\.env" | grep -v "example" | grep -v "\.test\." | grep -v "\.spec\." | \
  grep -v "test_" | grep -v "_test\." | grep -v "mock" | grep -v "fixture" | head -5)

if [ -n "$SECRETS" ]; then
  echo "BLOCKED: Potential hardcoded secrets found:" >&2
  echo "$SECRETS" >&2
  echo "Move secrets to environment variables. See .stp/references/security/env-handling.md" >&2
  HAS_ERRORS=true
  HAS_TECHNICAL_ERRORS=true
fi

# ── Gate 5: Placeholder/mock patterns in source files (WARN) ────
if [ -f "$FEATURE_FILE" ]; then
  PLACEHOLDERS=$(grep -rn \
    "// TODO\|// FIXME\|// implement\|// \.\.\.\|// rest of\|lorem ipsum\|placeholder\|mock data\|fake data\|REPLACE_ME\|NOT_IMPLEMENTED" \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --include="*.py" --include="*.rs" --include="*.go" --include="*.cs" \
    --include="*.java" --include="*.rb" --include="*.php" \
    --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
    --exclude-dir=target --exclude-dir=.next --exclude-dir=dist \
    -i . 2>/dev/null | \
    grep -v "\.test\." | grep -v "\.spec\." | grep -v "test_" | grep -v "_test\." | \
    grep -v "__mocks__" | grep -v "fixtures" | grep -v "\.d\.ts" | head -10)

  if [ -n "$PLACEHOLDERS" ]; then
    echo "WARNING: Placeholder/mock patterns found in source files:" >&2
    echo "$PLACEHOLDERS" >&2
    echo "STP builds production code. Replace placeholders with real implementations." >&2
    # WARN only — does not block
  fi
fi

# ── Gate 6: Hollow test detection (WARN) ───────────────────────
if [ -f "$FEATURE_FILE" ]; then
  # Check for tautological assertions: expect(true), expect(1).toBe(1), assert True
  HOLLOW_TESTS=$(grep -rn \
    "expect(true)\|expect(false)\|expect(1)\.toBe(1)\|expect(0)\.toBe(0)\|assert True\|assert False\|assertEqual(True\|\.toBe(true)\|\.toBe(false)" \
    --include="*.test.*" --include="*.spec.*" --include="test_*.py" \
    --include="*_test.go" --include="*Test.java" --include="*_test.rs" \
    --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
    --exclude-dir=target \
    . 2>/dev/null | head -5)

  if [ -n "$HOLLOW_TESTS" ]; then
    echo "WARNING: Hollow/tautological test assertions found:" >&2
    echo "$HOLLOW_TESTS" >&2
    echo "Tests must verify real behavior. expect(true).toBe(true) proves nothing." >&2
  fi

  # Check for assertion-free test functions
  # Look for test/it blocks that have no expect/assert/should
  ASSERTION_FREE=""
  TEST_FILES=$(find . -type f \( \
    -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \
  \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/vendor/*" \
     -not -path "*/target/*" 2>/dev/null | head -10)

  for tf in $TEST_FILES; do
    # Count test blocks vs assertion blocks
    TESTS_COUNT=$(grep -c "it(\|test(\|def test_\|func Test" "$tf" 2>/dev/null || echo "0")
    ASSERTS_COUNT=$(grep -c "expect(\|assert\|should\.\|\.to\.\|\.toBe\|\.toEqual\|\.toThrow\|assertEqual\|assertRaises" "$tf" 2>/dev/null || echo "0")
    if [ "$TESTS_COUNT" -gt 0 ] && [ "$ASSERTS_COUNT" -eq 0 ]; then
      ASSERTION_FREE="$ASSERTION_FREE\n  $tf: $TESTS_COUNT test(s) with 0 assertions"
    fi
  done

  if [ -n "$ASSERTION_FREE" ]; then
    echo "WARNING: Test files with zero assertions found:" >&2
    echo -e "$ASSERTION_FREE" >&2
    echo "Tests without assertions are not testing anything." >&2
  fi
fi

# ══════════════════════════════════════════════════════════════════
# SLOW GATES (seconds — only run if fast gates passed or partially)
# ══════════════════════════════════════════════════════════════════

# ── Gate 7: Stack-aware type/compile check ───────────────────────
run_type_check() {
  if [ -f "tsconfig.json" ]; then
    npx tsc --noEmit --pretty false 2>&1 | grep "error TS" | head -10
  elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
    if command -v mypy &>/dev/null; then
      mypy . --no-error-summary 2>&1 | grep "error:" | head -10
    elif command -v python3 &>/dev/null; then
      find . -name "*.py" -not -path "*/venv/*" -not -path "*/.venv/*" -not -path "*/node_modules/*" | head -20 | xargs python3 -m py_compile 2>&1 | head -10
    fi
  elif [ -f "Cargo.toml" ]; then
    cargo check --message-format=short 2>&1 | grep "^error" | head -10
  elif [ -f "go.mod" ]; then
    go vet ./... 2>&1 | head -10
  elif ls *.csproj &>/dev/null 2>&1 || ls *.sln &>/dev/null 2>&1; then
    dotnet build --no-restore --verbosity quiet 2>&1 | grep -i ": error" | head -10
  elif [ -f "Gemfile" ]; then
    find . -name "*.rb" -not -path "*/vendor/*" | head -20 | xargs ruby -c 2>&1 | grep -i "syntax error" | head -10
  elif [ -f "composer.json" ]; then
    find . -name "*.php" -not -path "*/vendor/*" | head -20 | xargs -I{} php -l {} 2>&1 | grep -i "error" | head -10
  elif [ -f "pom.xml" ]; then
    mvn compile -q 2>&1 | grep -i "error" | head -10
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    gradle compileJava -q 2>&1 | grep -i "error" | head -10
  fi
}

TYPE_ERRORS=$(run_type_check)

if [ -n "$TYPE_ERRORS" ]; then
  echo "BLOCKED: Type/compile errors. Fix before completing:" >&2
  echo "$TYPE_ERRORS" >&2
  HAS_ERRORS=true
  HAS_TECHNICAL_ERRORS=true
fi

# ── Gate 8: Test failures (skip if type check already failed) ────
if [ -z "$TYPE_ERRORS" ]; then
  run_tests() {
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
      if ! grep -q '"test".*"echo.*no test' package.json 2>/dev/null; then
        npm test --silent 2>&1
        return $?
      fi
    elif [ -f "pyproject.toml" ] && command -v pytest &>/dev/null; then
      pytest --tb=short -q 2>&1
      return $?
    elif [ -f "Cargo.toml" ]; then
      cargo test --quiet 2>&1
      return $?
    elif [ -f "go.mod" ]; then
      go test ./... 2>&1
      return $?
    elif ls *.csproj &>/dev/null 2>&1 || ls *.sln &>/dev/null 2>&1; then
      dotnet test --no-build --verbosity quiet 2>&1
      return $?
    elif [ -f "Gemfile" ] && command -v bundle &>/dev/null; then
      if bundle exec rspec --dry-run &>/dev/null 2>&1; then
        bundle exec rspec --format progress 2>&1
        return $?
      elif bundle exec rake test &>/dev/null 2>&1; then
        bundle exec rake test 2>&1
        return $?
      fi
    elif [ -f "composer.json" ] && command -v php &>/dev/null; then
      if [ -f "vendor/bin/phpunit" ]; then
        vendor/bin/phpunit 2>&1
        return $?
      elif [ -f "phpunit.xml" ] || [ -f "phpunit.xml.dist" ]; then
        php vendor/bin/phpunit 2>&1
        return $?
      fi
    elif [ -f "pom.xml" ] && command -v mvn &>/dev/null; then
      mvn test -q 2>&1
      return $?
    elif { [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; } && command -v gradle &>/dev/null; then
      gradle test -q 2>&1
      return $?
    fi
    return 0
  }

  TEST_OUTPUT=$(run_tests)
  TEST_EXIT=$?

  if [ "$TEST_EXIT" -ne 0 ]; then
    echo "BLOCKED: Tests failing. Fix before completing:" >&2
    echo "$TEST_OUTPUT" | tail -15 >&2
    HAS_ERRORS=true
    HAS_TECHNICAL_ERRORS=true
  fi
else
  echo "(Skipping test run — fix type errors first)" >&2
fi

# ══════════════════════════════════════════════════════════════════
# FINAL DECISION
# ══════════════════════════════════════════════════════════════════

if [ "$HAS_ERRORS" = true ]; then
  # Only increment retry for TECHNICAL errors (not workflow items)
  if [ "$HAS_TECHNICAL_ERRORS" = true ]; then
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "$RETRY_COUNT" > "$RETRY_FILE"
  fi
  exit 2
fi

# All passed — reset counter and allow stop
rm -f "$RETRY_FILE"
exit 0

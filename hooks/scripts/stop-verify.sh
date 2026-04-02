#!/bin/bash
# Pilot v0.2.0: Stop verification hook
# EXIT CODE 2 = BLOCK (Claude cannot stop, must continue)
# EXIT CODE 0 = ALLOW (Claude can stop)
#
# Stack-aware: detects project type from filesystem.
# 3-attempt max-retry: prevents exit code 2 bricking (GitHub #38422, #24327).
#
# Gates:
# 1. Type/compile errors → BLOCK
# 2. Test failures (if test runner exists) → BLOCK
# 3. Unchecked feature items → BLOCK
# 4. After 3 blocked attempts → ALLOW with warning

STATE_DIR=".pilot"
FEATURE_FILE="$STATE_DIR/current-feature.md"
RETRY_FILE="$STATE_DIR/.stop-retry-count"

# ── Max-retry guard ──────────────────────────────────────────────
mkdir -p "$STATE_DIR" 2>/dev/null

RETRY_COUNT=0
if [ -f "$RETRY_FILE" ]; then
  RAW=$(cat "$RETRY_FILE" 2>/dev/null || echo "0")
  # Sanitize: only accept numeric values
  if [[ "$RAW" =~ ^[0-9]+$ ]]; then
    RETRY_COUNT=$RAW
  fi
fi

if [ "$RETRY_COUNT" -ge 3 ]; then
  echo "WARNING: 3 stop attempts blocked. Allowing stop to prevent session bricking." >&2
  echo "Unresolved issues may exist. Run /pilot:evaluate to check." >&2
  rm -f "$RETRY_FILE"
  exit 0
fi

HAS_ERRORS=false

# ── Gate 1: Stack-aware type/compile check ───────────────────────
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
    dotnet build --no-restore --verbosity quiet 2>&1 | grep -i "error" | head -10
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
fi

# ── Gate 2: Test failures ────────────────────────────────────────
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
fi

# ── Gate 3: Tests must EXIST for new code ────────────────────────
# If we're building a feature AND source files exist, test files must too.
# Skip this check if the project only has config/migration files (no testable code yet).
if [ -f "$FEATURE_FILE" ]; then
  # Check if any source files exist (not just config/migrations)
  SRC_FILES=$(find . -type f \( \
    -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o \
    -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.cs" -o \
    -name "*.java" -o -name "*.rb" -o -name "*.php" \
  \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/vendor/*" \
     -not -path "*/target/*" -not -path "*/.next/*" -not -path "*/migrations/*" \
     -not -name "*.config.*" -not -name "*.d.ts" 2>/dev/null | head -3)

  if [ -n "$SRC_FILES" ]; then
    # Source files exist — test files must too
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
    fi
  fi
fi

# ── Gate 4: No hardcoded secrets ─────────────────────────────────
SECRETS=$(grep -rn "sk_live_\|sk_test_\|password\s*=\s*[\"'][^\"']\{8,\}\|AKIA[0-9A-Z]\{16\}" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --include="*.rs" --include="*.go" --include="*.cs" --include="*.java" \
  --include="*.rb" --include="*.php" \
  --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
  --exclude-dir=target --exclude-dir=.next . 2>/dev/null | \
  grep -v "\.env" | grep -v "example" | grep -v "test" | grep -v "mock" | head -5)

if [ -n "$SECRETS" ]; then
  echo "BLOCKED: Potential hardcoded secrets found:" >&2
  echo "$SECRETS" >&2
  echo "Move secrets to environment variables. See .pilot/references/security/env-handling.md" >&2
  HAS_ERRORS=true
fi

# ── Gate 5: PLAN.md should exist if building features ────────────
if [ -f "$FEATURE_FILE" ] && [ ! -f "PLAN.md" ]; then
  echo "WARNING: Building features without PLAN.md. Run /pilot:plan for better results." >&2
  # Warning only, not blocking — user might be doing a quick fix
fi

# ── Gate 6: Unchecked feature items ──────────────────────────────
if [ -f "$FEATURE_FILE" ]; then
  UNCHECKED=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || echo "0")
  CHECKED=$(grep -c '\[x\]' "$FEATURE_FILE" 2>/dev/null || echo "0")

  if [ "$UNCHECKED" -gt 0 ]; then
    NEXT=$(grep -m1 '\[ \]' "$FEATURE_FILE" | sed 's/^[[:space:]]*- \[ \] //')
    echo "BLOCKED: $UNCHECKED items remain ($CHECKED done). Next: $NEXT" >&2
    echo "Continue working. Run /pilot:pause if you need to stop." >&2
    HAS_ERRORS=true
  fi
fi

# ── Final decision ───────────────────────────────────────────────
if [ "$HAS_ERRORS" = true ]; then
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "$RETRY_COUNT" > "$RETRY_FILE"
  exit 2
fi

# All passed — reset counter and allow stop
rm -f "$RETRY_FILE"
exit 0

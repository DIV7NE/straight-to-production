#!/bin/bash
# HOME bypass — STP hook should never run at $HOME, allow stop immediately
if [ "$PWD" = "$HOME" ]; then exit 0; fi

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
#   Gate 9: Schema drift detection → BLOCK (ORM schema changed without migration)
#   Gate 10: Scope reduction detection → WARN (PRD requirements missing from PLAN)
#   Gate 11: Spec delta merge-back → WARN (completed feature missing ### Spec Delta in CHANGELOG or ARCHITECTURE update)
#   Gate 12: Critic must run on PLAN-backed features → BLOCK (workflow gate, no retry count)
#   Gate 13: QA must run on UI features → BLOCK (workflow gate, no retry count)
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

# ── Helper: clean_count ────────────────────────────────────────
# Wraps `grep -c` so it always returns a single integer to stdout, even
# when grep finds zero matches. The naive idiom
#   N=$(grep -c PATTERN FILE 2>/dev/null || echo "0")
# is BROKEN: grep -c prints "0\n" on no-match AND exits 1, so the `|| echo`
# fires AFTER grep already wrote "0", and the variable ends up containing
# the literal "0\n0". The next `[ "$N" -gt 0 ]` errors with
#   integer expression expected
# Use this helper everywhere instead.
#
# CONTRACT: SINGLE FILE ONLY. With multiple files, `grep -c` prefixes each
# count with the filename (`file1:N\nfile2:M`), and this helper would
# strip the colons and concatenate the digits ("NM"), producing wrong
# results. If you need a multi-file count, sum them separately. The
# stop-verify gates only ever pass one file, so this constraint is safe.
clean_count() {
  local n
  n=$(grep -c "$@" 2>/dev/null)
  n=${n:-0}
  n=${n//[!0-9]/}
  printf '%s' "${n:-0}"
}

# ══════════════════════════════════════════════════════════════════
# FAST GATES (instant — run these first)
# ══════════════════════════════════════════════════════════════════

# ── Gate 1: Unchecked feature items ──────────────────────────────
if [ -f "$FEATURE_FILE" ]; then
  UNCHECKED=$(clean_count '\[ \]' "$FEATURE_FILE")
  CHECKED=$(clean_count '\[x\]' "$FEATURE_FILE")

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
     -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.clone/*" -not -path "*/.git/*" \
     -not -name "*.config.*" -not -name "*.d.ts" -not -name "*.config.ts" \
     -not -name "*.config.js" -not -name "*.config.mjs" -not -name "*.config.cjs" \
  2>/dev/null | head -3)

  if [ -n "$SRC_FILES" ]; then
    TEST_FILES=$(find . -type f \( \
      -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" -o \
      -name "*_test.go" -o -name "*Test.java" -o -name "*_test.rs" -o \
      -name "*Tests.cs" -o -name "*_spec.rb" -o -name "*Test.php" \
    \) -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/vendor/*" \
       -not -path "*/target/*" -not -path "*/.clone/*" -not -path "*/.git/*" 2>/dev/null | head -5)

    if [ -z "$TEST_FILES" ]; then
      echo "BLOCKED: Source files exist but no test files found." >&2
      echo "TDD: write tests before implementation is considered done." >&2
      HAS_ERRORS=true
      HAS_TECHNICAL_ERRORS=true
    fi
  fi
fi

# ── Gate 4: No hardcoded secrets ─────────────────────────────────
# Only runs inside an actual STP project, never at $HOME — otherwise grep -rn
# walks the entire home dir and false-positives on Bun types, pipx caches,
# PIL font blobs, and the project's own secret-detector fixtures.
if [ -f "$FEATURE_FILE" ] && [ "$PWD" != "$HOME" ]; then
  SECRETS=$(grep -rn \
    "sk_live_[a-zA-Z0-9]\{20,\}\|sk_test_[a-zA-Z0-9]\{20,\}\|AKIA[0-9A-Z]\{16\}" \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --include="*.py" --include="*.rs" --include="*.go" --include="*.cs" \
    --include="*.java" --include="*.rb" --include="*.php" \
    --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
    --exclude-dir=target --exclude-dir=.next --exclude-dir=dist \
    --exclude-dir=.bun --exclude-dir=.local --exclude-dir=.cache \
    --exclude-dir=.git --exclude-dir=.npm --exclude-dir=.pnpm-store \
    --exclude-dir=.yarn --exclude-dir=.rustup --exclude-dir=.cargo \
    --exclude-dir=.clone \
    --exclude="*.d.ts" --exclude="ImageFont.py" --exclude="detect-secrets.*" \
    . 2>/dev/null | \
    grep -iv "example" | grep -v "\.env" | grep -v "\.test\." | grep -v "\.spec\." | \
    grep -v "test_" | grep -v "_test\." | grep -iv "mock" | grep -iv "fixture" | \
    grep -v "AKIAXXX" | grep -v "AKIAIOSFODNN7EXAMPLE" | head -5)

  if [ -n "$SECRETS" ]; then
    echo "BLOCKED: Potential hardcoded secrets found:" >&2
    echo "$SECRETS" >&2
    echo "Move secrets to environment variables. See .stp/references/security/env-handling.md" >&2
    HAS_ERRORS=true
    HAS_TECHNICAL_ERRORS=true
  fi
fi

# ── Gate 5: Placeholder/mock patterns in source files (WARN) ────
# Only flags HIGH-CONFIDENCE slop markers. Bare "placeholder", "mock data",
# and "fake data" were removed in v0.3.7 because they false-flagged:
#   • HTML form attributes  (placeholder="Enter your name")
#   • Type/symbol names      (EmailTemplatePlaceholderValues)
#   • Domain libraries       (template-utils.ts handling placeholder substitution)
#   • Seed scripts           (prisma/seed.ts populating fake data IS its job)
#   • Staged-delivery comments (// placeholder — employer schedules in Phase 59)
# What remains is unambiguous: TODO/FIXME comments, ellipsis-stub markers,
# lorem ipsum filler, and ALL-CAPS REPLACE_ME / NOT_IMPLEMENTED tokens.
if [ -f "$FEATURE_FILE" ]; then
  # `-i` preserves coverage of lowercase variants (`// todo`, `// fixme`).
  # The patterns themselves are unambiguous enough that case-insensitive
  # matching doesn't introduce false positives.
  PLACEHOLDERS=$(grep -rniE \
    "// (TODO|FIXME)|// implement\b|// \.\.\.|// rest of|lorem ipsum|REPLACE_ME|NOT_IMPLEMENTED" \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --include="*.py" --include="*.rs" --include="*.go" --include="*.cs" \
    --include="*.java" --include="*.rb" --include="*.php" \
    --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
    --exclude-dir=target --exclude-dir=.next --exclude-dir=dist \
    --exclude-dir=.clone --exclude-dir=.git --exclude-dir=build \
    . 2>/dev/null | \
    grep -v "\.test\." | grep -v "\.spec\." | grep -v "test_" | grep -v "_test\." | \
    grep -v "__mocks__" | grep -v "fixtures" | grep -v "\.d\.ts" | \
    grep -v "/seed\." | grep -v "/seeds/" | grep -v "template-utils" | head -10)

  if [ -n "$PLACEHOLDERS" ]; then
    echo "WARNING: Placeholder/mock patterns found in source files:" >&2
    echo "$PLACEHOLDERS" >&2
    echo "STP builds production code. Replace placeholders with real implementations." >&2
    # WARN only — does not block
  fi
fi

# ── Gate 6: Hollow test detection (WARN) ───────────────────────
if [ -f "$FEATURE_FILE" ]; then
  # Tautological-assertion regex. v0.3.7: removed the trailing
  #   \.toBe(true)\|\.toBe(false)
  # alternatives — they matched every `expect(realFunction()).toBe(true)`
  # call, which IS a real behavioral assertion. The remaining patterns
  # all require BOTH sides to be literals (expect(true).toBe(true),
  # expect(1).toBe(1), assert True) — those are unambiguously hollow.
  HOLLOW_TESTS=$(grep -rn \
    "expect(true)\|expect(false)\|expect(1)\.toBe(1)\|expect(0)\.toBe(0)\|assert True\|assert False\|assertEqual(True" \
    --include="*.test.*" --include="*.spec.*" --include="test_*.py" \
    --include="*_test.go" --include="*Test.java" --include="*_test.rs" \
    --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=vendor \
    --exclude-dir=target --exclude-dir=.clone --exclude-dir=.git \
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
     -not -path "*/target/*" -not -path "*/.clone/*" -not -path "*/.git/*" 2>/dev/null | head -10)

  for tf in $TEST_FILES; do
    # Count test blocks vs assertion blocks (clean_count avoids the
    # `grep -c || echo 0` bug that produces "0\n0" on zero matches).
    TESTS_COUNT=$(clean_count "it(\|test(\|def test_\|func Test" "$tf")
    ASSERTS_COUNT=$(clean_count "expect(\|assert\|should\.\|\.to\.\|\.toBe\|\.toEqual\|\.toThrow\|assertEqual\|assertRaises" "$tf")
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

# ── Gate 9: Schema drift detection (ORM schema changed without migration) ──
# v0.3.7: rewritten to consider committed history, not just uncommitted state.
# OLD behavior: only looked at `git diff HEAD` — false-flagged when a previous
# commit on the branch atomically paired schema + migration, then a later
# commit re-touched the schema, even though every schema change was covered
# by a migration in its own commit.
# NEW behavior: for each ORM schema file in the uncommitted set, check whether
# a migration file exists in EITHER (a) the uncommitted change set, or
# (b) the most recent commit that touched that schema file. Only block when
# neither is true.
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  # All uncommitted changes (staged + unstaged) vs last commit
  CHANGED_FILES=$( { git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only HEAD 2>/dev/null; } | sort -u )

  if [ -n "$CHANGED_FILES" ]; then
    # Known ORM schema file patterns (specific to avoid matching Zod/form/API schemas)
    SCHEMA_CHANGED=$(echo "$CHANGED_FILES" | grep -iE \
      '\.prisma$|\.entity\.(ts|js)$|/models\.py$|schema\.rb$|drizzle/.*schema|db/schema\.(ts|js)$|database/schema\.(ts|js)$' | \
      grep -v "node_modules" | grep -v ".venv" | grep -v "test" | grep -v "spec" | grep -v "mock" | head -5)

    if [ -n "$SCHEMA_CHANGED" ]; then
      # (a) Are there uncommitted migration files alongside the schema change?
      MIGRATION_CHANGED=$(echo "$CHANGED_FILES" | grep -iE 'migration|migrate|alembic/versions' | head -5)

      UNPAIRED_SCHEMAS=""
      if [ -z "$MIGRATION_CHANGED" ]; then
        # (b) For each schema file, check the most recent commit that touched
        # it. If that commit ALSO contained a migration file, it's covered.
        while IFS= read -r schema_path; do
          [ -z "$schema_path" ] && continue
          last_commit=$(git log -1 --format="%H" -- "$schema_path" 2>/dev/null)
          if [ -n "$last_commit" ]; then
            files_in_commit=$(git show --name-only --format= "$last_commit" 2>/dev/null)
            if echo "$files_in_commit" | grep -qiE 'migration|migrate|alembic/versions'; then
              # Schema's last-touching commit included a migration — covered.
              continue
            fi
          fi
          UNPAIRED_SCHEMAS="${UNPAIRED_SCHEMAS}${schema_path}"$'\n'
        done <<< "$SCHEMA_CHANGED"
      fi

      if [ -z "$MIGRATION_CHANGED" ] && [ -n "$UNPAIRED_SCHEMAS" ]; then
        echo "BLOCKED: ORM schema files changed without corresponding migrations:" >&2
        printf '%s' "$UNPAIRED_SCHEMAS" | sed '/^$/d; s/^/  /' >&2
        echo "Generate migrations before completing. Schema drift causes silent data bugs." >&2
        echo "(Checked: uncommitted migration files + the most recent commit touching each schema.)" >&2
        HAS_ERRORS=true
        HAS_TECHNICAL_ERRORS=true
      fi
    fi
  fi
fi

# ── Gate 10: Scope reduction detection (PRD requirements vs PLAN coverage) ──
if [ -f "$DOCS_DIR/PRD.md" ] && [ -f "$DOCS_DIR/PLAN.md" ]; then
  # Count mandatory requirements (SHALL/MUST per RFC 2119)
  PRD_MUSTS=$(grep -cE '\bSHALL\b|\bMUST\b' "$DOCS_DIR/PRD.md" 2>/dev/null)
  PRD_MUSTS=${PRD_MUSTS:-0}
  PRD_MUSTS=${PRD_MUSTS//[!0-9]/}
  PRD_MUSTS=${PRD_MUSTS:-0}

  # Only check when PRD has enough requirements to be meaningful
  if [ "$PRD_MUSTS" -gt 2 ]; then
    COVERED=0
    UNCOVERED_REQS=""

    while IFS= read -r line; do
      # Extract key terms (3+ char words, skip stop words and RFC 2119 keywords)
      TERMS=$(echo "$line" | tr '[:upper:]' '[:lower:]' | \
        grep -oE '\b[a-z]{3,}\b' | \
        grep -vE '^(the|and|for|with|that|this|from|shall|must|when|then|given|have|been|will|are|not|any|all|each|can|may|should|system|user|before|after|during)$' | \
        head -5)

      FOUND=false
      for term in $TERMS; do
        if grep -qi "$term" "$DOCS_DIR/PLAN.md" 2>/dev/null; then
          FOUND=true
          break
        fi
      done

      if [ "$FOUND" = true ]; then
        COVERED=$((COVERED + 1))
      else
        UNCOVERED_REQS="$UNCOVERED_REQS\n  $(echo "$line" | sed 's/^[[:space:]]*//' | head -c 120)"
      fi
    done < <(grep -E '\bSHALL\b|\bMUST\b' "$DOCS_DIR/PRD.md" 2>/dev/null)

    COVERAGE_PCT=0
    if [ "$PRD_MUSTS" -gt 0 ]; then
      COVERAGE_PCT=$(( (COVERED * 100) / PRD_MUSTS ))
    fi

    if [ "$COVERAGE_PCT" -lt 70 ]; then
      echo "WARNING: Possible scope reduction — $COVERED/$PRD_MUSTS PRD requirements (${COVERAGE_PCT}%) found in PLAN.md." >&2
      if [ -n "$UNCOVERED_REQS" ]; then
        echo "Potentially dropped:" >&2
        echo -e "$UNCOVERED_REQS" | head -5 >&2
      fi
      echo "Verify PLAN.md covers all mandatory (SHALL/MUST) requirements from PRD.md." >&2
    fi
  fi
fi

# ── Helper: feature_is_complete ────────────────────────────────
# Returns 0 if current-feature.md exists AND has zero unchecked items.
# Robust against grep -c exit behavior: grep -c prints "0" on no-match
# BUT also exits 1, which makes naive `grep -c ... || echo 0` produce
# "0\n0" and break numeric comparisons downstream. Using a clean capture.
feature_is_complete() {
  [ -f "$FEATURE_FILE" ] || return 1
  local count
  count=$(grep -c '\[ \]' "$FEATURE_FILE" 2>/dev/null || true)
  count=${count:-0}
  # Strip anything non-numeric (defense against multi-line output)
  count=${count//[!0-9]/}
  count=${count:-0}
  [ "$count" -eq 0 ]
}

# ── Gate 11: Spec delta merge-back (WARN) ──────────────────────
# When a feature is marked complete, verify CHANGELOG.md has a
# ### Spec Delta block for it AND ARCHITECTURE.md was touched recently.
# Without merge-back, canonical docs drift from reality.
if feature_is_complete; then
  if [ -f "$DOCS_DIR/CHANGELOG.md" ]; then
    # Check the last 80 lines of CHANGELOG for a "### Spec Delta" block
    RECENT_CHANGELOG=$(tail -80 "$DOCS_DIR/CHANGELOG.md" 2>/dev/null)
    if ! echo "$RECENT_CHANGELOG" | grep -q "### Spec Delta"; then
      echo "WARNING: Completed feature has no ### Spec Delta block in CHANGELOG.md." >&2
      echo "Add one describing: Added / Changed / Constraints introduced / Dependencies created." >&2
      echo "Then merge the deltas back into ARCHITECTURE.md and PRD.md." >&2
    fi
  fi

  # Check if ARCHITECTURE.md was updated in the last 5 commits (proxy for merge-back)
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    if [ -f "$DOCS_DIR/ARCHITECTURE.md" ]; then
      # Clean capture: use wc -l on the filtered output, which always returns a number
      ARCH_RECENT=$(git log -5 --name-only --pretty=format: 2>/dev/null | grep -c "ARCHITECTURE\.md")
      UNSTAGED_ARCH=$(git diff --name-only HEAD 2>/dev/null | grep -c "ARCHITECTURE\.md")
      # grep -c outputs a single number to stdout; empty input → "0"
      if [ "${ARCH_RECENT:-0}" -eq 0 ] && [ "${UNSTAGED_ARCH:-0}" -eq 0 ]; then
        echo "WARNING: Feature complete but ARCHITECTURE.md has not been updated in the last 5 commits." >&2
        echo "If this feature added models/routes/components, merge the spec delta into ARCHITECTURE.md." >&2
      fi
    fi
  fi
fi

# ── Gate 12: Critic must run on PLAN-backed features (BLOCK) ──
# If PLAN.md exists (meaning this is full-cycle work) AND the feature is
# complete, require a recent Critic report before allowing stop.
# Workflow gate — does not increment retry counter.
if feature_is_complete && [ -f "$DOCS_DIR/PLAN.md" ]; then
  # Look for a Critic report newer than the feature file
  CRITIC_REPORT=$(find "$RUNTIME_DIR" -maxdepth 1 -name "critic-report*.md" -newer "$FEATURE_FILE" 2>/dev/null | head -1)
  # Also check the docs dir in case reports land there
  if [ -z "$CRITIC_REPORT" ] && [ -d "$DOCS_DIR" ]; then
    CRITIC_REPORT=$(find "$DOCS_DIR" -maxdepth 1 -name "critic-report*.md" -newer "$FEATURE_FILE" 2>/dev/null | head -1)
  fi
  if [ -z "$CRITIC_REPORT" ]; then
    echo "BLOCKED: Feature complete but no recent Critic report found." >&2
    echo "Full-cycle work (with PLAN.md) requires /stp:review before stop." >&2
    echo "Run /stp:review to generate a Critic report, then try again." >&2
    echo "Workflow gate — does not count toward the 3-retry technical limit." >&2
    HAS_ERRORS=true
    # Intentionally NOT setting HAS_TECHNICAL_ERRORS — workflow gates don't retry-count
  fi
fi

# ── Gate 13: QA must run on UI features (BLOCK) ───────────────
# If the UI gate was passed this session (meaning this was UI work) AND
# the feature is complete, require a QA report before stop.
# Workflow gate — does not increment retry counter.
if feature_is_complete && [ -f "$RUNTIME_DIR/ui-gate-passed" ]; then
  QA_REPORT=$(find "$RUNTIME_DIR" -maxdepth 1 -name "qa-report*.md" -newer "$FEATURE_FILE" 2>/dev/null | head -1)
  if [ -z "$QA_REPORT" ] && [ -d "$DOCS_DIR" ]; then
    QA_REPORT=$(find "$DOCS_DIR" -maxdepth 1 -name "qa-report*.md" -newer "$FEATURE_FILE" 2>/dev/null | head -1)
  fi
  if [ -z "$QA_REPORT" ]; then
    echo "BLOCKED: UI feature complete but no recent QA report found." >&2
    echo "UI work requires a QA report before stop." >&2
    echo "Run the QA agent or write qa-report-<feature>.md to .stp/state/." >&2
    echo "Workflow gate — does not count toward the 3-retry technical limit." >&2
    HAS_ERRORS=true
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

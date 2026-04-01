#!/bin/bash
# Pilot v0.2.0: Post-edit type/compile check
# Stack-aware: detects project type from filesystem.
# Runs after Edit/Write on source files. Feedback only (exit 0 always).
# Errors shown via stderr so Claude sees and fixes them before Stop blocks.

# Try to get file path from stdin JSON
if [ ! -t 0 ]; then
  INPUT=$(cat)
  FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' 2>/dev/null)
fi

# Fallback to env var
if [ -z "$FILE_PATH" ]; then
  FILE_PATH="${TOOL_INPUT_file_path:-${TOOL_INPUT_FILE_PATH:-}}"
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ── Match file extension to stack and run appropriate check ──────

# TypeScript / JavaScript
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]] && [ -f "tsconfig.json" ]; then
  ERRORS=$(npx tsc --noEmit --pretty false 2>&1 | grep "error TS" | head -10)
  if [ -n "$ERRORS" ]; then
    echo "Pilot: TypeScript errors after editing $FILE_PATH:" >&2
    echo "$ERRORS" >&2
    echo "Fix these. The Stop hook will BLOCK completion until tsc passes." >&2
  fi

# Python
elif [[ "$FILE_PATH" =~ \.py$ ]]; then
  if command -v mypy &>/dev/null && { [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "mypy.ini" ]; }; then
    ERRORS=$(mypy "$FILE_PATH" --no-error-summary 2>&1 | grep "error:" | head -10)
    if [ -n "$ERRORS" ]; then
      echo "Pilot: mypy errors after editing $FILE_PATH:" >&2
      echo "$ERRORS" >&2
      echo "Fix these. The Stop hook will BLOCK completion until mypy passes." >&2
    fi
  else
    # Fallback: syntax check only
    ERRORS=$(python3 -m py_compile "$FILE_PATH" 2>&1)
    if [ -n "$ERRORS" ]; then
      echo "Pilot: Python syntax error in $FILE_PATH:" >&2
      echo "$ERRORS" >&2
    fi
  fi

# Rust
elif [[ "$FILE_PATH" =~ \.rs$ ]] && [ -f "Cargo.toml" ]; then
  ERRORS=$(cargo check --message-format=short 2>&1 | grep "^error" | head -10)
  if [ -n "$ERRORS" ]; then
    echo "Pilot: Rust compile errors after editing $FILE_PATH:" >&2
    echo "$ERRORS" >&2
    echo "Fix these. The Stop hook will BLOCK completion until cargo check passes." >&2
  fi

# Go
elif [[ "$FILE_PATH" =~ \.go$ ]] && [ -f "go.mod" ]; then
  ERRORS=$(go vet ./... 2>&1 | head -10)
  if [ -n "$ERRORS" ]; then
    echo "Pilot: Go vet errors after editing $FILE_PATH:" >&2
    echo "$ERRORS" >&2
    echo "Fix these. The Stop hook will BLOCK completion until go vet passes." >&2
  fi

# C#
elif [[ "$FILE_PATH" =~ \.cs$ ]] && { ls *.csproj &>/dev/null 2>&1 || ls *.sln &>/dev/null 2>&1; }; then
  ERRORS=$(dotnet build --no-restore --verbosity quiet 2>&1 | grep -i "error" | head -10)
  if [ -n "$ERRORS" ]; then
    echo "Pilot: C# build errors after editing $FILE_PATH:" >&2
    echo "$ERRORS" >&2
    echo "Fix these. The Stop hook will BLOCK completion until dotnet build passes." >&2
  fi

# Ruby
elif [[ "$FILE_PATH" =~ \.rb$ ]] && [ -f "Gemfile" ]; then
  ERRORS=$(ruby -c "$FILE_PATH" 2>&1 | grep -i "syntax error")
  if [ -n "$ERRORS" ]; then
    echo "Pilot: Ruby syntax error in $FILE_PATH:" >&2
    echo "$ERRORS" >&2
  fi

# PHP
elif [[ "$FILE_PATH" =~ \.php$ ]] && [ -f "composer.json" ]; then
  ERRORS=$(php -l "$FILE_PATH" 2>&1 | grep -i "error")
  if [ -n "$ERRORS" ]; then
    echo "Pilot: PHP syntax error in $FILE_PATH:" >&2
    echo "$ERRORS" >&2
  fi

# Java
elif [[ "$FILE_PATH" =~ \.java$ ]]; then
  if [ -f "pom.xml" ]; then
    ERRORS=$(mvn compile -q 2>&1 | grep -i "error" | head -10)
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    ERRORS=$(gradle compileJava -q 2>&1 | grep -i "error" | head -10)
  fi
  if [ -n "$ERRORS" ]; then
    echo "Pilot: Java compile errors after editing $FILE_PATH:" >&2
    echo "$ERRORS" >&2
  fi
fi

# Always exit 0 — PostToolUse hooks provide feedback, never block
exit 0

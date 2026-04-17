#!/usr/bin/env bash
# STP — Stack Detection (v1.0)
# Runs on SessionStart. Writes .stp/state/stack.json with language/build/test/lint commands.
# Silent on success. Fresh <24h stack.json is reused — delete the file to force re-detection.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || cd "${PWD}"

mkdir -p .stp/state
STACK_FILE=".stp/state/stack.json"

# Freshness gate — skip if stack.json <24h old
if [[ -f "$STACK_FILE" ]]; then
  NOW=$(date +%s)
  MTIME=$(stat -c %Y "$STACK_FILE" 2>/dev/null || stat -f %m "$STACK_FILE" 2>/dev/null || echo 0)
  AGE=$((NOW - MTIME))
  if [[ $AGE -lt 86400 ]]; then
    exit 0
  fi
fi

# Defaults — fall through to "generic" if nothing matches
STACK="generic"
LANGUAGE="mixed"
RUNTIME=""
UI="false"
TEST_CMD=""
BUILD_CMD=""
LINT_CMD=""
TYPECHECK_CMD=""
RUN_CMD=""
PROPERTY_LIB=""

# ==== NODE / WEB ==== (package.json)
if [[ -f package.json ]]; then
  STACK="node"
  LANGUAGE="javascript"
  [[ -f tsconfig.json ]] || grep -q '"typescript"' package.json 2>/dev/null && LANGUAGE="typescript" || true
  if [[ -f bun.lockb ]] || [[ -f bun.lock ]]; then RUNTIME="bun"
  elif [[ -f pnpm-lock.yaml ]]; then RUNTIME="pnpm"
  elif [[ -f yarn.lock ]]; then RUNTIME="yarn"
  else RUNTIME="npm"; fi
  if grep -qE '"(next|react|vue|svelte|solid|astro|nuxt|remix|preact|qwik)"' package.json 2>/dev/null; then
    STACK="web"; UI="true"
  fi
  TEST_CMD="$RUNTIME test"
  BUILD_CMD="$RUNTIME run build"
  LINT_CMD="$RUNTIME run lint"
  if [[ "$LANGUAGE" == "typescript" ]]; then
    TYPECHECK_CMD="$RUNTIME exec tsc --noEmit"
  fi
  RUN_CMD="$RUNTIME run dev"
  PROPERTY_LIB="fast-check"
fi

# ==== PYTHON ==== (pyproject.toml / requirements.txt / setup.py)
if [[ -f pyproject.toml ]] || [[ -f requirements.txt ]] || [[ -f setup.py ]]; then
  STACK="python"
  LANGUAGE="python"
  if grep -qE '(torch|tensorflow|scikit-learn|sklearn|pandas|numpy|jax|transformers)' requirements.txt pyproject.toml 2>/dev/null; then
    STACK="data-ml"
  fi
  if grep -qE '(django|flask|fastapi|starlette|aiohttp)' requirements.txt pyproject.toml 2>/dev/null; then
    UI="true"
  fi
  if [[ -f poetry.lock ]]; then RUNTIME="poetry"
  elif [[ -f uv.lock ]]; then RUNTIME="uv"
  else RUNTIME="pip"; fi
  TEST_CMD="pytest"
  LINT_CMD="ruff check ."
  TYPECHECK_CMD="mypy ."
  PROPERTY_LIB="hypothesis"
fi

# ==== RUST ==== (Cargo.toml)
if [[ -f Cargo.toml ]]; then
  STACK="rust"
  LANGUAGE="rust"
  RUNTIME="cargo"
  TEST_CMD="cargo test"
  BUILD_CMD="cargo build --release"
  LINT_CMD="cargo clippy -- -D warnings"
  TYPECHECK_CMD="cargo check"
  RUN_CMD="cargo run"
  PROPERTY_LIB="proptest"
  if grep -qE '(bevy|wgpu|winit|ggez|piston|macroquad)' Cargo.toml 2>/dev/null; then STACK="game"
  elif grep -qE '(embedded-hal|cortex-m|no_std|esp-idf|rp2040|stm32)' Cargo.toml 2>/dev/null; then STACK="embedded"
  fi
fi

# ==== C++ ==== (CMakeLists.txt / Makefile / *.cpp)
if [[ -f CMakeLists.txt ]] || compgen -G "*.cpp" > /dev/null || compgen -G "*.cc" > /dev/null || compgen -G "*.hpp" > /dev/null; then
  if [[ "$STACK" == "generic" ]]; then
    STACK="cpp"
    LANGUAGE="cpp"
    # Cheat / pentest detection (authorized-use scope; see stacks/cheat-pentest.md)
    if grep -rqE '(CCSPlayer|IClientEntity|Source ?Engine|CUtlVector|veh_hook|CreateRemoteThread|LoadLibraryA.*dll|aimbot|triggerbot|esp_render)' --include='*.cpp' --include='*.h' --include='*.hpp' . 2>/dev/null | head -1 > /dev/null; then
      STACK="cheat-pentest"
    fi
    if [[ -f CMakeLists.txt ]]; then
      BUILD_CMD="cmake -B build && cmake --build build"
      TEST_CMD="ctest --test-dir build --output-on-failure"
    elif [[ -f Makefile ]]; then
      BUILD_CMD="make"
      TEST_CMD="make test"
    else
      BUILD_CMD="g++ -O2 -std=c++20 *.cpp -o out"
    fi
    LINT_CMD="clang-tidy"
    TYPECHECK_CMD="$BUILD_CMD"
    PROPERTY_LIB="rapidcheck"
  fi
fi

# ==== CSHARP ==== (*.csproj / *.sln)
if compgen -G "*.csproj" > /dev/null || compgen -G "*.sln" > /dev/null; then
  STACK="csharp"
  LANGUAGE="csharp"
  if grep -rqE '(UnityEngine|Godot\.|MonoGame)' --include='*.cs' . 2>/dev/null | head -1 > /dev/null; then
    STACK="game"
  fi
  TEST_CMD="dotnet test"
  BUILD_CMD="dotnet build"
  LINT_CMD="dotnet format --verify-no-changes"
  TYPECHECK_CMD="dotnet build --no-restore"
  RUN_CMD="dotnet run"
  PROPERTY_LIB="FsCheck"
fi

# ==== JAVA ==== (pom.xml / build.gradle)
if [[ -f pom.xml ]] || [[ -f build.gradle ]] || [[ -f build.gradle.kts ]]; then
  STACK="java"
  LANGUAGE="java"
  if [[ -f pom.xml ]]; then
    RUNTIME="maven"
    TEST_CMD="mvn test"
    BUILD_CMD="mvn package"
    TYPECHECK_CMD="mvn compile"
  else
    RUNTIME="gradle"
    TEST_CMD="./gradlew test"
    BUILD_CMD="./gradlew build"
    TYPECHECK_CMD="./gradlew compileJava"
  fi
  LINT_CMD="checkstyle"
  if grep -rqE '(net\.minecraft|net\.minecraftforge|net\.fabricmc)' . 2>/dev/null | head -1 > /dev/null; then
    STACK="mod"
  fi
  PROPERTY_LIB="jqwik"
fi

# ==== GO ==== (go.mod)
if [[ -f go.mod ]]; then
  STACK="go"
  LANGUAGE="go"
  RUNTIME="go"
  TEST_CMD="go test ./..."
  BUILD_CMD="go build ./..."
  LINT_CMD="golangci-lint run"
  TYPECHECK_CMD="go vet ./..."
  RUN_CMD="go run ."
  PROPERTY_LIB="gopter"
fi

# Write stack.json
DETECTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cat > "$STACK_FILE" <<EOF
{
  "stack": "$STACK",
  "language": "$LANGUAGE",
  "runtime": "$RUNTIME",
  "ui": $UI,
  "test_cmd": "$TEST_CMD",
  "build_cmd": "$BUILD_CMD",
  "lint_cmd": "$LINT_CMD",
  "typecheck_cmd": "$TYPECHECK_CMD",
  "run_cmd": "$RUN_CMD",
  "property_lib": "$PROPERTY_LIB",
  "stack_ref": "references/stacks/$STACK.md",
  "detected_at": "$DETECTED_AT"
}
EOF

exit 0

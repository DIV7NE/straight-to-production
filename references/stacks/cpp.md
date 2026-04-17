# C++ Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "cpp"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `CMakeLists.txt`, `meson.build`, `Makefile` with `.cpp`/`.cc` sources
- Files with `.cpp`, `.cxx`, `.cc`, `.hpp`, `.hxx` extensions in `src/` or `include/`
- `vcpkg.json`, `conanfile.txt`, `conanfile.py`
- (secondary) `.clang-tidy`, `.clang-format`, `compile_commands.json`

## Commands
- **test:** `ctest --test-dir build` (or `./build/tests/run_tests`)
- **build:** `cmake -S . -B build && cmake --build build`
- **lint:** `clang-tidy src/**/*.cpp -- -I include`
- **type-check:** `—` (compilation is the type check: `cmake --build build 2>&1`)
- **format:** `clang-format -i src/**/*.cpp include/**/*.hpp`

## stack.json fields
```json
{
  "primary": "cpp",
  "ui": false,
  "test_cmd": "ctest --test-dir build",
  "build_cmd": "cmake -S . -B build && cmake --build build",
  "lint_cmd": "clang-tidy src/**/*.cpp -- -I include",
  "type_cmd": "cmake --build build"
}
```

## Idiomatic patterns (what good code looks like)
- RAII everywhere — resources (files, sockets, locks, memory) are owned by objects whose destructors release them
- Rule of Five: if any of destructor, copy constructor, copy assignment, move constructor, or move assignment is defined, define all five (or `= delete` / `= default` explicitly)
- Smart pointers over raw owning pointers — `std::unique_ptr` for sole ownership, `std::shared_ptr` only when shared ownership is genuinely needed
- Forward declarations in headers to minimize include chains; include full headers only in `.cpp` files
- `[[nodiscard]]` on functions whose return value must not be ignored (errors, resource handles)

## Common gotchas
- Including headers with `#pragma once` vs include guards: both work, but mixing them in a project causes confusion — pick one and enforce it
- Undefined behavior from signed integer overflow, null pointer dereference, and out-of-bounds access compiles silently — use `-fsanitize=address,undefined` in CI
- `std::string_view` pointing to a temporary string that goes out of scope is a dangling reference with no compiler warning
- Linking order matters with `g++`/`clang++` — libraries must come after the objects that use them
- Thread safety: `std::shared_ptr` ref-count operations are atomic, but the pointed-to object is not — protect shared state with `std::mutex`

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Apply RAII for every resource. Apply the Rule of Five whenever any special member function is user-defined. Use `std::unique_ptr` by default; justify every `std::shared_ptr`."
- "Add `#pragma once` or include guards to every header. Use forward declarations to minimize header coupling."

## Anti-slop patterns for this stack
- `new` without a corresponding `delete` — slop (use smart pointers)
- `// TODO: add error handling` — slop (handle it now)
- Raw `char*` for strings in new code — slop (use `std::string` or `std::string_view`)
- `using namespace std;` in headers — slop (pollutes every including translation unit)

## Companion plugins / MCP servers
- **Context7** — pull live docs for C++ standard library, Boost, and CMake
- **Tavily** — research CVEs in third-party libs, compiler-specific behavior, and platform ABI differences

## References (external)
- C++ Core Guidelines: https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines
- cppreference (standard library): https://en.cppreference.com/

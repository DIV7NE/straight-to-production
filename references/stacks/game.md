# Game Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "game"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `ProjectSettings/ProjectVersion.txt` (Unity), `*.uproject` (Unreal), `project.godot` (Godot)
- `Assets/` directory with `*.unity` scenes, `*.prefab`, `*.asset` files
- `Source/` directory with `*.Build.cs` files (Unreal)
- (secondary) `Packages/manifest.json` (Unity Package Manager), `GDScript` files (`*.gd`), `*.tscn` scene files

## Commands
- **test (Unity):** `Unity -batchmode -runTests -testPlatform EditMode -testResults results.xml`
- **test (Godot):** `godot --headless --quit --script tests/run_tests.gd`
- **test (Unreal):** `RunUAT.bat RunTests -project=MyGame.uproject -run=MyGame.Tests`
- **build (Unity):** `Unity -batchmode -buildLinuxPlayer ./Build/`
- **build (Unreal):** `RunUAT.bat BuildCookRun -project=MyGame.uproject -platform=Win64`
- **lint:** `—` (use Roslyn analyzers for Unity C#; Unreal uses clang-tidy)
- **type-check:** `—` (Unity: `dotnet build` on the generated `.csproj`; Unreal: UHT compilation)
- **format:** `dotnet format` (Unity C#) or `clang-format` (Unreal C++)

## stack.json fields
```json
{
  "primary": "game",
  "ui": true,
  "test_cmd": "Unity -batchmode -runTests -testPlatform EditMode",
  "build_cmd": "Unity -batchmode -buildLinuxPlayer ./Build/",
  "lint_cmd": "dotnet format --verify-no-changes",
  "type_cmd": "dotnet build"
}
```

## Idiomatic patterns (what good code looks like)
- Component-based design: MonoBehaviours (Unity) and Actors/Components (Unreal) are small and focused; game logic lives in separate manager/system classes
- Engine lifecycle methods (`Start`, `Awake`, `Update`, `BeginPlay`, `Tick`) are thin — delegate to domain classes
- `ScriptableObject` (Unity) for configuration data instead of hardcoded constants in MonoBehaviours
- Object pooling for frequently spawned/destroyed objects (bullets, particles) — `Instantiate`/`Destroy` in tight loops causes GC spikes
- Separate game logic from rendering logic — makes headless testing and porting possible

## Common gotchas
- Referencing destroyed Unity objects throws `MissingReferenceException` at runtime, not compile time — check `obj != null` (which uses Unity's overloaded `==`)
- `Update()` called every frame without frame-rate independence: multiply movement by `Time.deltaTime` or physics jitters at different FPS
- Unreal `UFUNCTION` / `UPROPERTY` macros must be on the line immediately before the declaration — blank lines break Unreal Header Tool
- Godot `await` on a signal from a freed node throws — store node references weakly or check `is_instance_valid(node)`
- Unity serialized fields not reset when a prefab is modified — always test prefab instances, not just scene objects

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Respect engine lifecycle: never access scene objects in constructors (Unity) or constructors/CDO (Unreal). Use the correct initialization callback (`Awake`/`Start` in Unity, `BeginPlay` in Unreal)."
- "Frame-rate-independent movement always multiplies velocity by `Time.deltaTime` (Unity) or `DeltaTime` (Unreal). Flag any positional update that does not."

## Anti-slop patterns for this stack
- Movement code without `Time.deltaTime` multiplication — slop (frame-rate dependent)
- `FindObjectOfType<T>()` in `Update()` — slop (expensive every frame; cache in `Awake`/`Start`)
- `// TODO: add object pooling` — slop (pool from the start if spawn rate > 5/second)
- Hardcoded magic numbers for damage, speed, HP — slop (use `ScriptableObject` / config data)

## Companion plugins / MCP servers
- **ui-ux-pro-max** — HUD/menu/UI canvas layout design before implementation
- **Context7** — pull live Unity, Unreal, or Godot API docs
- **Tavily** — research engine-specific performance patterns, platform submission requirements

## References (external)
- Unity best practices: https://unity.com/how-to/programming-unity
- Unreal Engine coding standards: https://dev.epicgames.com/documentation/en-us/unreal-engine/epic-cplusplus-coding-standard-for-unreal-engine

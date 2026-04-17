# Mod Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "mod"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `fabric.mod.json`, `mods.toml` (Forge), `bepinex/` directory (BepInEx Unity mods)
- `*.esp`, `*.esm`, `*.esl` (Bethesda plugin files), `*.psc` (Papyrus source), `SKSE/Plugins/` directory
- `gradle.properties` with `minecraft_version`, `modId` in any config
- (secondary) `mixins.json` (Fabric/Forge mixins), `SMAPI` references in manifests

## Commands
- **test (Fabric/Forge):** `./gradlew test`
- **test (BepInEx):** `dotnet test`
- **test (Bethesda/Papyrus):** `—` (no automated test runner; manual in-game verification)
- **build (Fabric):** `./gradlew build` (outputs to `build/libs/*.jar`)
- **build (Forge):** `./gradlew build`
- **build (BepInEx):** `dotnet build`
- **lint:** `./gradlew checkstyleMain` (Fabric/Forge) or `dotnet format --verify-no-changes` (BepInEx)
- **type-check:** `./gradlew compileJava` (Fabric/Forge) or `dotnet build` (BepInEx)
- **format:** `./gradlew spotlessApply` (Fabric/Forge) or `dotnet format` (BepInEx)

## stack.json fields
```json
{
  "primary": "mod",
  "ui": false,
  "test_cmd": "./gradlew test",
  "build_cmd": "./gradlew build",
  "lint_cmd": "./gradlew checkstyleMain",
  "type_cmd": "./gradlew compileJava"
}
```

## Idiomatic patterns (what good code looks like)
- Fabric: use `@Mixin` with `@Inject` at safe `HEAD`/`TAIL` targets — avoid `OVERWRITE` which breaks compatibility with other mods
- Forge: prefer `@SubscribeEvent` on `@Mod.EventBusSubscriber` classes over anonymous handlers; use `ForgeRegistries` for all registry operations
- BepInEx: all patches via `Harmony.PatchAll()` with `[HarmonyPatch]` attributes; store the `Harmony` instance on the plugin class for unpatching
- Bethesda/Papyrus: all scripts extend the correct base type (`Actor`, `Quest`, `ObjectReference`); use `RegisterForUpdate` sparingly — polling in `OnUpdate` is expensive
- Config/options live in the mod's standard config system (Cloth Config for Fabric, Forge Config API, ConfigurationManager for BepInEx) — never hardcoded

## Common gotchas
- Mixin targeting a method that gets renamed or inlined between game versions breaks silently at load — verify mixin targets after every game update
- Accessing game registries too early (before `FMLCommonSetupEvent` in Forge / `onInitialize` in Fabric) causes `NullPointerException` or empty registries
- BepInEx plugin `Awake()` runs before the game finishes loading — delay game-object access to `SceneManager.sceneLoaded` events
- Papyrus `GetActorOwner()` on a cell can return `None` — always null-check before property access in Papyrus
- Shipping decompiled or extracted game assets in your mod repo violates most game EULAs — use only your own assets or properly licensed ones

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Check mod compatibility: prefer non-destructive mixin strategies (Inject/Redirect) over Overwrite. State which game version and loader version the code targets."
- "Respect mod loader lifecycle. Never access game state before the loader's initialization callback fires."

## Anti-slop patterns for this stack
- `@Overwrite` mixin without justification comment — slop (breaks compatibility; use Inject/Redirect)
- Hardcoded item/block IDs — slop (use registry lookups by `ResourceLocation`)
- Bundled game assets in the mod jar — slop (copyright/EULA violation risk)
- `// TODO: localize` — slop (add lang file entries from the start)

## Companion plugins / MCP servers
- **Context7** — pull live docs for Fabric API, Forge MDK, BepInEx, and SKSE
- **Tavily** — research mod compatibility issues, loader migration guides, game update changelogs

## References (external)
- Fabric wiki: https://fabricmc.net/wiki/
- Forge documentation: https://docs.minecraftforge.net/en/latest/

# Embedded Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "embedded"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `platformio.ini` (PlatformIO), `CMakeLists.txt` with `arm-none-eabi` or `avr-gcc` toolchain
- `Cargo.toml` with `[profile.release] panic = "abort"` and no-std targets (`thumbv7em-none-eabihf`)
- `boards/`, `src/main.c`, `src/main.cpp` in a PlatformIO or STM32CubeMX project
- (secondary) `linker.ld` or `*.ld` linker scripts, `openocd.cfg`, `west.yml` (Zephyr RTOS)

## Commands
- **test (host simulation):** `cmake -S . -B build-host -DPLATFORM=host && cmake --build build-host && ctest --test-dir build-host`
- **test (PlatformIO):** `pio test -e native` (native environment for host tests)
- **test (Rust no-std):** `cargo test --target x86_64-unknown-linux-gnu` (host tests only; device tests via `cargo-embed`)
- **build:** `pio run` (PlatformIO) or `cmake --build build` or `cargo build --release --target thumbv7em-none-eabihf`
- **lint:** `clang-tidy src/**/*.c src/**/*.cpp` or `cargo clippy --target thumbv7em-none-eabihf`
- **type-check:** `cmake --build build 2>&1` (C/C++) or `cargo check --target thumbv7em-none-eabihf` (Rust)
- **format:** `clang-format -i src/**/*.c src/**/*.cpp` or `cargo fmt`

## stack.json fields
```json
{
  "primary": "embedded",
  "ui": false,
  "test_cmd": "pio test -e native",
  "build_cmd": "pio run",
  "lint_cmd": "clang-tidy src/**/*.c",
  "type_cmd": "cmake --build build"
}
```

## Idiomatic patterns (what good code looks like)
- No heap allocation in interrupt service routines (ISRs) or hard real-time paths — use static buffers and memory pools
- Volatile-correct register access: all peripheral-mapped memory accessed through `volatile` pointers or CMSIS register structs
- HAL abstraction layer: hardware-specific code isolated behind a thin interface so logic can be tested on the host without hardware
- Deterministic timing: use hardware timers for timing-critical code, never `delay()` or busy-wait loops in production firmware
- Watchdog timer always enabled in production builds — ensures the device recovers from hangs without human intervention

## Common gotchas
- Stack overflow on microcontrollers is silent — there is no segfault; the device corrupts memory or resets. Set stack canaries and size accordingly.
- `float` and `double` operations on MCUs without an FPU (e.g., Cortex-M0) silently use slow software emulation — check your target's FPU and use integer math where timing matters
- UART/SPI/I2C peripherals share DMA channels on some MCUs — configuring two peripherals on the same DMA channel causes silently wrong data
- Rust no-std: `panic` in firmware with `panic = "halt"` halts silently — always add a debug LED blink or RTT log in the panic handler
- Arduino `delay()` blocks all execution including interrupt-driven code — use non-blocking state machines with `millis()` for concurrent behavior

## Opus 4.7 prompt adjustments (inject when stack matches)
- "No heap allocation (`malloc`, `Box::new`, `Vec::new` on the heap) in interrupt handlers or hard real-time paths. Use static allocation or pre-allocated pools."
- "All peripheral register access must be `volatile`-correct. Never let the compiler optimize away hardware register reads."

## Anti-slop patterns for this stack
- `delay()` in production firmware outside of init — slop (blocks interrupts; use non-blocking timers)
- `malloc`/`free` in ISRs — slop (heap is not ISR-safe; use static buffers)
- `printf` to UART in timing-critical loops — slop (synchronous; use DMA or RTT)
- `// TODO: add watchdog` — slop (add it now; missing watchdog is a reliability bug)

## Companion plugins / MCP servers
- **Context7** — pull live docs for STM32 HAL, Zephyr RTOS, Arduino framework, and embedded-hal (Rust)
- **Tavily** — research MCU errata, peripheral timing constraints, and RTOS scheduling algorithms

## References (external)
- Embedded Rust book: https://docs.rust-embedded.org/book/
- Zephyr RTOS docs: https://docs.zephyrproject.org/latest/

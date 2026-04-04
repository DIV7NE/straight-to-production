# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Shell | Electron 33+ | Cross-platform desktop, native APIs, auto-update |
| Bundler | Vite | Fast HMR, ESM-native, simple config |
| UI | React + Tailwind + shadcn/ui | Component ecosystem, consistent with web |
| Database | SQLite (better-sqlite3) | Local-first, zero-latency, no server needed |
| ORM | Drizzle | Type-safe queries, SQLite support, lightweight |
| Build | electron-builder | Produces .dmg, .exe, .AppImage |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
src/
  main/
    index.ts               # App entry, window management
    ipc/handlers.ts        # IPC handler registration
    db/{client,schema}.ts  # SQLite + Drizzle
    services/              # Business logic (file I/O, system)
  renderer/
    App.tsx                # Root React component
    components/ui/,layouts/
    pages/                 # App views
    hooks/useIpc.ts        # Type-safe IPC hook
    lib/ipc.ts             # Typed invoke wrapper
  preload/index.ts         # contextBridge — expose only what's needed
  shared/types.ts          # IPC channel type map
```
## Code Standards
### Always Do
1. Use `contextBridge` in preload — never enable `nodeIntegration`
2. Define all IPC channels in `shared/types.ts` — single source of truth
3. Run all file system and database operations in main process via IPC
4. Validate IPC inputs in main process — renderer is untrusted
5. Store user data in `app.getPath("userData")`, never the install dir
6. Use worker threads for CPU-heavy work — keep main responsive
7. Sign and notarize builds for distribution
### Never Do
1. Never set `nodeIntegration: true` — exposes Node.js to renderer
2. Never set `contextIsolation: false` — disables security boundary
3. Never expose raw `ipcRenderer` — wrap channels through contextBridge
4. Never run SQLite queries in the renderer process
5. Never use `remote` module — deprecated, security risk
6. Never block main process with synchronous I/O in handlers
## Stack Patterns
### Type-Safe IPC
```ts
// shared/types.ts
export type IpcChannelMap = {
  "db:projects:list": { input: void; output: Project[] };
  "db:projects:create": { input: { name: string }; output: Project };
  "fs:open-file": { input: { filters: FileFilter[] }; output: string | null };
};
// renderer/lib/ipc.ts
export async function invoke<K extends keyof IpcChannelMap>(
  channel: K,
  ...args: IpcChannelMap[K]["input"] extends void ? [] : [IpcChannelMap[K]["input"]]
): Promise<IpcChannelMap[K]["output"]> {
  return window.electron.invoke(channel, ...args);
}
```
### Preload Security Boundary
```ts
import { contextBridge, ipcRenderer } from "electron";
const ALLOWED = ["db:projects:list", "db:projects:create", "fs:open-file"] as const;
contextBridge.exposeInMainWorld("electron", {
  invoke: (channel: string, data?: unknown) => {
    if (!ALLOWED.includes(channel as any)) throw new Error(`Channel "${channel}" not allowed`);
    return ipcRenderer.invoke(channel, data);
  },
});
```
### Main Process Handlers + Drizzle
```ts
import { ipcMain } from "electron";
import { db } from "../db/client";
import { projects } from "../db/schema";
export function registerHandlers() {
  ipcMain.handle("db:projects:list", () =>
    db.select().from(projects).orderBy(projects.createdAt)
  );
  ipcMain.handle("db:projects:create", async (_e, input: { name: string }) => {
    const [project] = await db.insert(projects).values({ name: input.name }).returning();
    return project;
  });
}
```
## STP Standards Index
```
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.stp/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.stp/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.stp/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.stp/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML
```

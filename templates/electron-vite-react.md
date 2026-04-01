# Stack Recipe: Electron + Vite + React

## When to Use
Desktop applications (macOS, Windows, Linux). Native file system access, system tray apps, offline-first tools, local-first data.

## Stack Components
| Layer | Technology | Why |
|-------|-----------|-----|
| Shell | Electron | Cross-platform desktop, native APIs, auto-update |
| Bundler | Vite | Fast HMR, ESM-native, simple config |
| UI | React + Tailwind + shadcn/ui | Consistent with web stack |
| Database | SQLite (better-sqlite3) | Local-first, no server dependency, fast |
| ORM | Drizzle | Type-safe queries, SQLite support, lightweight |
| IPC | Electron IPC | Type-safe main/renderer communication |
| Deployment | electron-builder | Builds .dmg, .exe, .AppImage |

## Project Structure
```
src/
├── main/                # Electron main process (Node.js)
│   ├── index.ts         # App entry, window management
│   ├── ipc.ts           # IPC handlers (file system, DB)
│   └── db.ts            # SQLite database
├── renderer/            # Electron renderer (React)
│   ├── App.tsx          # Root component
│   ├── components/
│   │   └── ui/          # shadcn/ui components
│   ├── pages/           # App pages/views
│   ├── hooks/           # Custom React hooks
│   └── lib/
│       ├── ipc.ts       # Type-safe IPC calls from renderer
│       └── utils.ts
├── shared/              # Shared types between main and renderer
│   └── types.ts
└── preload/
    └── index.ts         # Secure context bridge
```

## Key Patterns

### Type-Safe IPC
```typescript
// shared/types.ts
export type IpcChannels = {
  'db:query': { input: { sql: string; params?: unknown[] }; output: unknown[] }
  'fs:read-file': { input: { path: string }; output: string }
  'fs:save-file': { input: { path: string; content: string }; output: boolean }
}

// main/ipc.ts
import { ipcMain } from 'electron'
ipcMain.handle('db:query', async (_event, { sql, params }) => {
  return db.prepare(sql).all(...(params ?? []))
})

// renderer/lib/ipc.ts
export async function invoke<T extends keyof IpcChannels>(
  channel: T,
  input: IpcChannels[T]['input']
): Promise<IpcChannels[T]['output']> {
  return window.electron.invoke(channel, input)
}
```

### Preload Script (security boundary)
```typescript
// preload/index.ts
import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electron', {
  invoke: (channel: string, data: unknown) => ipcRenderer.invoke(channel, data),
})
```

## Desktop-Specific Standards
- NEVER use nodeIntegration: true — always use preload scripts with contextBridge
- All file system / database operations happen in main process via IPC
- Renderer process is treated like a browser — same security rules as web
- Handle app updates with electron-updater (auto-update on launch)
- Minimize main process work — heavy computation in worker threads
- Store user data in app.getPath('userData'), not app directory
- Sign your app for distribution (macOS notarization, Windows code signing)

## Required Environment Variables
```
# Typically none for local-first desktop apps
# If connecting to a backend:
VITE_API_URL=https://your-api.com
```

## Initial Setup Commands
```bash
npm create electron-vite@latest . -- --template react-ts
npm install better-sqlite3 drizzle-orm
npm install -D drizzle-kit @types/better-sqlite3
npx shadcn@latest init
```

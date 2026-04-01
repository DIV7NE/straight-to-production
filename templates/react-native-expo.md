# Stack Recipe: React Native + Expo

## When to Use
Mobile applications (iOS and Android) with shared codebase. Cross-platform apps, internal tools, consumer apps.

## Stack Components
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Expo (managed workflow) | Handles native complexity, OTA updates, build service |
| Navigation | Expo Router | File-based routing (same mental model as Next.js) |
| Database | Supabase | Real-time, auth, REST/GraphQL, works from mobile |
| Auth | Clerk or Supabase Auth | Clerk for consistency with web stack, Supabase Auth for simpler setup |
| Styling | NativeWind (Tailwind for RN) | Same Tailwind classes, works with React Native |
| State | Zustand or TanStack Query | Zustand for local state, TanStack Query for server state |
| Deployment | EAS Build + EAS Submit | Builds for App Store and Google Play |

## Project Structure
```
app/
├── (tabs)/              # Tab-based navigation
│   ├── index.tsx        # Home tab
│   ├── explore.tsx      # Browse/search tab
│   └── profile.tsx      # User profile tab
├── (auth)/              # Auth screens
│   ├── sign-in.tsx
│   └── sign-up.tsx
├── _layout.tsx          # Root layout with providers
└── +not-found.tsx       # 404 screen
components/
├── ui/                  # Reusable UI components
└── [feature]/           # Feature-specific components
lib/
├── db.ts                # Supabase client
├── env.ts               # Env validation
└── utils.ts             # Shared utilities
```

## Key Patterns

### Supabase Client
```typescript
// lib/db.ts
import { createClient } from '@supabase/supabase-js'
import * as SecureStore from 'expo-secure-store'

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    storage: {
      getItem: (key) => SecureStore.getItemAsync(key),
      setItem: (key, value) => SecureStore.setItemAsync(key, value),
      removeItem: (key) => SecureStore.deleteItemAsync(key),
    },
  },
})
```

### Secure Storage (never use AsyncStorage for tokens)
```typescript
import * as SecureStore from 'expo-secure-store'
// SecureStore uses Keychain (iOS) and EncryptedSharedPreferences (Android)
```

## Mobile-Specific Standards
- Use SecureStore for tokens/secrets, never AsyncStorage
- Handle offline state gracefully (mobile loses network frequently)
- Request permissions progressively (camera, location, notifications — only when needed)
- Support both light and dark mode (useColorScheme)
- Test on both iOS and Android — behavior differs
- Handle safe area insets (notches, home indicators)
- Optimize list rendering with FlashList instead of FlatList for large lists

## Required Environment Variables
```
EXPO_PUBLIC_SUPABASE_URL=https://...supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_... (if using Clerk)
```

## Initial Setup Commands
```bash
npx create-expo-app@latest . --template tabs
npx expo install expo-secure-store expo-router
npm install @supabase/supabase-js nativewind tailwindcss
npm install zustand @tanstack/react-query
```

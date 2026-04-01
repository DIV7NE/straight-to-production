# {{PROJECT_NAME}}
## What We're Building — {{PROJECT_DESCRIPTION}}
## Architecture
| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Expo SDK 52+ | Managed workflow, OTA updates, EAS builds |
| Navigation | Expo Router | File-based routing, deep linking, typed routes |
| Backend | Supabase | Auth, Postgres, realtime, storage |
| Styling | NativeWind v4 | Tailwind for React Native, universal styles |
| Storage | expo-secure-store | Encrypted token storage on device |
| Validation | Zod | Shared schemas between app and API |
## Key Decisions — {{DECISIONS}}
## Project Structure
```
app/
  (tabs)/index.tsx,profile.tsx,_layout.tsx
  (auth)/sign-in.tsx,sign-up.tsx,_layout.tsx
  _layout.tsx              # Root layout (providers, auth gate)
  +not-found.tsx
components/ui/,forms/,platform/
lib/supabase.ts,auth.ts,api.ts,validations/
hooks/useAuth.ts,useSupabase.ts
constants/colors.ts,layout.ts
types/database.ts          # Supabase generated types
```
## Code Standards
### Always Do
1. Store auth tokens in `SecureStore` — never `AsyncStorage` for sensitive data
2. Use `_layout.tsx` for navigation structure and auth gates
3. Test on both iOS and Android — use `Platform.select()` for divergence
4. Handle offline state — check `NetInfo` before network requests
5. Validate forms and API responses with Zod schemas
6. Wrap screens in `SafeAreaView` — respect notches and status bars
7. Use `expo-image` over `Image` for caching and performance
### Never Do
1. Never store tokens in `AsyncStorage` — unencrypted plaintext
2. Never hardcode API URLs — use `expo-constants` and app config
3. Never use `console.log` in production — use a proper logger
4. Never ignore keyboard avoidance — `KeyboardAvoidingView` on forms
5. Never skip loading/error states — mobile users expect feedback
6. Never request all permissions on launch — ask when needed
## Stack Patterns
### Supabase with SecureStore
```ts
import { createClient } from "@supabase/supabase-js";
import * as SecureStore from "expo-secure-store";
import type { Database } from "@/types/database";
const storage = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};
export const supabase = createClient<Database>(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  { auth: { storage, autoRefreshToken: true } }
);
```
### Auth Gate (Expo Router)
```tsx
import { Slot, useRouter, useSegments } from "expo-router";
import { useAuth } from "@/hooks/useAuth";
import { useEffect } from "react";
export default function RootLayout() {
  const { session, loading } = useAuth();
  const segments = useSegments();
  const router = useRouter();
  useEffect(() => {
    if (loading) return;
    const inAuth = segments[0] === "(auth)";
    if (!session && !inAuth) router.replace("/(auth)/sign-in");
    if (session && inAuth) router.replace("/(tabs)");
  }, [session, loading]);
  if (loading) return <LoadingScreen />;
  return <Slot />;
}
```
### Platform-Specific Code
```tsx
import { Pressable, Platform } from "react-native";
import * as Haptics from "expo-haptics";
export function HapticButton({ onPress, children }: { onPress: () => void; children: React.ReactNode }) {
  const handlePress = () => {
    if (Platform.OS !== "web") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress();
  };
  return <Pressable onPress={handlePress}>{children}</Pressable>;
}
```
## Pilot Standards Index
```
# IMPORTANT: Prefer retrieval-led reasoning over pre-training for ALL standards below.
# Read the referenced files BEFORE writing code that touches these domains.
# Before implementing framework-specific APIs, query Context7 for latest docs.

## Security Standards
|domain:security|root:.pilot/references/security
|owasp-top-10.md — Injection, XSS, CSRF, broken auth, security misconfiguration
|env-handling.md — Environment variables, secrets management
|auth-patterns.md — Middleware protection, server-side auth, row-level security
|input-sanitization.md — Input validation at every boundary
|api-security.md — Rate limiting, CORS, security headers

## Accessibility Standards
|domain:accessibility|root:.pilot/references/accessibility
|wcag-aa-essentials.md — WCAG 2.1 AA compliance
|keyboard-navigation.md — Focus management, tab order, skip links
|screen-reader.md — Semantic HTML, ARIA, live regions
|color-contrast.md — 4.5:1 text, 3:1 UI, no color-only meaning

## Performance Standards
|domain:performance|root:.pilot/references/performance
|core-web-vitals.md — LCP < 2.5s, INP < 200ms, CLS < 0.1
|bundle-optimization.md — Tree shaking, code splitting, lazy loading
|query-optimization.md — Parallel queries, N+1 prevention, indexing
|image-optimization.md — Responsive images, lazy loading, format selection

## Production Readiness
|domain:production|root:.pilot/references/production
|error-handling.md — Error boundaries/handlers, user-facing messages
|loading-states.md — Skeleton screens, progress indicators
|empty-states.md — Zero-data states, first-run experience
|edge-cases.md — Offline, slow connections, session expiry, timezone
|seo-basics.md — Meta tags, sitemaps, semantic HTML
```

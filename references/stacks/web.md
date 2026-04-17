# Web Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "web"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `package.json` + any of: `next`, `react`, `vue`, `svelte`, `astro`, `vite` in dependencies
- `next.config.js`, `next.config.ts`, `vite.config.ts`, `astro.config.mjs`, `svelte.config.js`
- `tsconfig.json` alongside a `src/` or `app/` directory
- (secondary) `tailwind.config.*`, `postcss.config.*`

## Commands
- **test:** `npm test` (or `npx vitest`, `npx jest` — check `package.json` scripts)
- **build:** `npm run build`
- **lint:** `npx eslint . --ext .ts,.tsx,.js,.jsx`
- **type-check:** `npx tsc --noEmit`
- **format:** `npx prettier --write .`

## stack.json fields
```json
{
  "primary": "web",
  "ui": true,
  "test_cmd": "npm test",
  "build_cmd": "npm run build",
  "lint_cmd": "npx eslint . --ext .ts,.tsx,.js,.jsx",
  "type_cmd": "npx tsc --noEmit"
}
```

## Idiomatic patterns (what good code looks like)
- Components are small, single-responsibility, colocated with their tests and styles
- Data fetching lives in server components or dedicated hooks — never inline in render
- Form state uses controlled inputs or a form library (react-hook-form, Formik) — never raw DOM manipulation
- Env vars are validated at startup (zod/t3-env) — never scattered `process.env.X` without fallback handling
- CSS uses utility classes (Tailwind) or CSS modules — no global style pollution

## Common gotchas
- `useEffect` with missing deps causes stale closure bugs; always run eslint-plugin-react-hooks
- Next.js App Router: server components cannot use hooks or browser APIs — mixing them causes cryptic errors
- Missing `key` props on list items causes React reconciliation bugs that only show in production
- Bundling large libraries (lodash, moment) without tree-shaking balloons the bundle — check with `npx bundlephobia`
- `process.env` is not available client-side in Next.js unless prefixed `NEXT_PUBLIC_`

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Always invoke `/ui-ux-pro-max` before generating any component or page layout. Never write UI code without design system approval."
- "Prefer server components over client components for data-heavy views. Default to RSC unless interactivity requires 'use client'."

## Anti-slop patterns for this stack
- `// mock data` — slop (ship real data-fetching from day one)
- `TODO: implement` — slop (never leave unimplemented blocks)
- `Lorem ipsum` — slop (use realistic fixture content)
- `fetch('/api/fake')` — slop (wire real endpoints)
- `Math.random()` for IDs — slop (use crypto.randomUUID or DB-generated keys)

## Companion plugins / MCP servers
- **ui-ux-pro-max** — MANDATORY before any UI component work; generates design tokens and layout specs
- **Context7** — pull live framework docs (Next.js, React, Vite, Tailwind) to avoid stale API patterns
- **Tavily** — research component patterns, accessibility standards, and browser compatibility

## References (external)
- React: https://react.dev/learn (official, always current)
- Web Vitals / performance: https://web.dev/explore/learn-core-web-vitals

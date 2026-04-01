# Core Web Vitals & Performance

## Target Metrics
- **LCP** (Largest Contentful Paint): < 2.5 seconds
- **INP** (Interaction to Next Paint): < 200 milliseconds
- **CLS** (Cumulative Layout Shift): < 0.1

## LCP Optimization
- Use `priority` prop on above-the-fold images: `<Image priority />`
- Preload critical fonts with `next/font`
- Avoid client-side data fetching for initial content — use Server Components
- Minimize redirect chains
- Use `loading="lazy"` only for below-the-fold images

## INP Optimization
- Use `useTransition` for non-urgent state updates
- Debounce expensive event handlers (search, resize, scroll)
- Use `startTransition` for state updates that trigger expensive re-renders
- Move heavy computation to Web Workers or server actions
- Use `passive: true` for scroll/touch event listeners

## CLS Prevention
- Always set explicit width/height on images and videos
- Use `aspect-ratio` CSS for responsive media
- Reserve space for dynamic content (ads, embeds, lazy-loaded components)
- Use CSS `content-visibility: auto` for long lists
- Never inject content above existing content after load

## Bundle Size
- NEVER import from barrel files (index.ts): `import { X } from '@/components'`
- DO import directly: `import { X } from '@/components/X'`
- Use `next/dynamic` for heavy components not needed on initial render
- Analyze with: `npx @next/bundle-analyzer`
- Lazy load third-party scripts: analytics, chat widgets, social embeds

## Data Fetching
- Parallelize independent fetches: `const [a, b] = await Promise.all([fetchA(), fetchB()])`
- NEVER: `const a = await fetchA(); const b = await fetchB();` (sequential waterfall)
- Use React `cache()` for per-request deduplication
- Use `after()` for non-blocking side effects (analytics, logging)
- Strategic Suspense boundaries to stream parallel data

## Caching
- Use appropriate cache headers for static assets
- Leverage ISR (Incremental Static Regeneration) for semi-static pages
- Use SWR or React Query for client-side cache with stale-while-revalidate
